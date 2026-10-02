package Langertha::Knarr::Stream;
# ABSTRACT: Async chunk iterator returned by streaming Knarr handlers
our $VERSION = '1.102';
use Moose;
use Future;
use Scalar::Util qw( blessed weaken );
use Langertha::Usage;


sub from_callback {
  my ($class, $setup) = @_;
  my @queue;
  my $pending;
  my $finished = 0;
  my @error;

  my $deliver = sub {
    my ($v) = @_;
    if ( $pending ) { my $p = $pending; $pending = undef; $p->done($v) }
    else            { push @queue, $v }
  };

  my $emit = sub {
    my ($chunk) = @_;
    return unless defined $chunk && length $chunk;
    $deliver->($chunk);
  };
  my $done = sub { $finished = 1; $deliver->(undef) };
  # The whole failure is kept, not just its message: a timeout's category
  # (the second value, k36) has to reach the protocol. A read already
  # waiting gets the failure too, not an undef that would end the stream
  # as if it were complete.
  my $fail = sub {
    @error = ( $_[0] // 'unknown error', @_[ 1 .. $#_ ] );
    $finished = 1;
    if ( $pending && $error[0] ) { my $p = $pending; $pending = undef; $p->fail(@error) }
    else                         { $deliver->(undef) }
  };

  my $stream = $class->new(
    source => sub {
      if ( @queue )    { return Future->done( shift @queue ) }
      if ( $finished ) { return $error[0] ? Future->fail(@error) : Future->done(undef) }
      $pending = Future->new;
      return $pending;
    },
  );

  # The producer may outlive a consumer that dropped the stream; it must
  # not keep the stream alive for it.
  my $weak = $stream;
  weaken $weak;
  my $finish = sub {
    my ($reason) = @_;
    $weak->finish_reason($reason) if $weak && defined $reason;
  };
  my $tool_call = sub {
    my @calls = grep { defined } @_;
    $weak->tool_calls( [ @{ $weak->_tool_calls // [] }, @calls ] ) if $weak && @calls;
  };
  # Every dialect reports cumulative usage, the last report being the
  # stream's totals -- not always on the final chunk: OpenAI's include_usage
  # frame comes after it.
  my $usage = sub {
    my ($u) = @_;
    $weak->usage($u) if $weak && $weak->_usable_usage($u);
  };

  my $model = sub {
    my ($name) = @_;
    $weak->upstream_model($name) if $weak && defined $name && length $name;
  };

  $setup->($emit, $done, $fail, $finish, $tool_call, $usage, $model);

  return $stream;
}

# Two ways to construct:
#  1) generator => sub { ... }     — sync coderef returning next string or undef
#  2) source    => sub { ... }     — coderef returning a Future[string|undef]
has generator => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has source    => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has upstream  => ( is => 'ro', isa => 'Maybe[Object]' );

has _finish_reason => (
  is       => 'rw',
  isa      => 'Maybe[Str]',
  init_arg => 'finish_reason',
);

sub finish_reason {
  my $self = shift;
  return $self->_finish_reason(@_) if @_;
  my $own = $self->_finish_reason;
  return $own if defined $own;
  my $up = $self->upstream;
  return $up && $up->can('finish_reason') ? $up->finish_reason : undef;
}

has _tool_calls => (
  is       => 'rw',
  isa      => 'Maybe[ArrayRef]',
  init_arg => 'tool_calls',
);

sub tool_calls {
  my $self = shift;
  return $self->_tool_calls(@_) if @_;
  my $own = $self->_tool_calls;
  return $own if $own && @$own;
  my $up = $self->upstream;
  return $up->tool_calls if $up && $up->can('tool_calls');
  return [];
}

sub has_tool_calls { scalar @{ $_[0]->tool_calls } > 0 }

has _usage => (
  is       => 'rw',
  isa      => 'Maybe[Object]',
  init_arg => undef,
);

sub usage {
  my $self = shift;
  if (@_) {
    my ($u) = @_;
    return $self->_usage( ref $u eq 'HASH' ? ( %$u ? Langertha::Usage->from_hash($u) : undef ) : $u );
  }
  my $own = $self->_usage;
  return $own if $own;
  my $up = $self->upstream;
  return $up && $up->can('usage') ? $up->usage : undef;
}

has _model => (
  is       => 'rw',
  isa      => 'Maybe[Str]',
  init_arg => 'model',
);

sub model {
  my $self = shift;
  return $self->_model(@_) if @_;
  my $own = $self->_model;
  return $own if defined $own;
  my $up = $self->upstream;
  return $up && $up->can('model') ? $up->model : undef;
}

has _upstream_model => (
  is       => 'rw',
  isa      => 'Maybe[Str]',
  init_arg => 'upstream_model',
);

sub upstream_model {
  my $self = shift;
  return $self->_upstream_model(@_) if @_;
  my $own = $self->_upstream_model;
  return $own if defined $own;
  my $up = $self->upstream;
  return $up && $up->can('upstream_model') ? $up->upstream_model : undef;
}

sub _usable_usage {
  my ($self, $u) = @_;
  return ref $u eq 'HASH' ? ( %$u ? 1 : 0 ) : blessed($u) ? 1 : 0;
}

sub BUILD {
  my ($self, $args) = @_;
  $self->usage( $args->{usage} ) if defined $args->{usage};
}

sub next_chunk_f {
  my ($self) = @_;
  if ( my $g = $self->generator ) {
    my $v = $g->();
    return Future->done($v);
  }
  if ( my $s = $self->source ) {
    return $s->();
  }
  return Future->done(undef);
}

# Convenience: build a stream from a fixed list of chunks
sub from_list {
  my ($class, @chunks) = @_;
  my @queue = @chunks;
  return $class->new( generator => sub { @queue ? shift @queue : undef } );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Stream - Async chunk iterator returned by streaming Knarr handlers

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Stream;

    # From a fixed list of strings
    my $stream = Langertha::Knarr::Stream->from_list('hel', 'lo');

    # From a sync generator
    my @parts = ('hel', 'lo');
    my $stream = Langertha::Knarr::Stream->new(
        generator => sub { @parts ? shift @parts : undef },
    );

    # From a future-yielding source (real async)
    my $stream = Langertha::Knarr::Stream->new(
        source => sub { $next_chunk_future },
    );

    # Drain it
    while ( defined( my $chunk = $stream->next_chunk_f->get ) ) {
        print $chunk;
    }

=head1 DESCRIPTION

The chunk iterator that streaming Knarr handlers return. Supports two
construction modes: a sync C<generator> coderef that returns the next
chunk string each call (or C<undef> for end), or a C<source> coderef
that returns a L<Future> resolving to the next chunk string. The
Future form is the one real async backends like L<Net::Async::HTTP>
use; the generator form is for tests and simple cases.

=head2 generator

Optional. CodeRef returning the next chunk synchronously.

=head2 source

Optional. CodeRef returning a L<Future> that resolves to the next
chunk.

=head2 finish_reason

Optional. The backend's terminal finish reason, verbatim (C<stop>,
C<length>, C<tool_calls>, C<end_turn>, C<MAX_TOKENS>, ...), or C<undef>
when the backend reported none. Known once the stream is exhausted; the
protocol maps it into its own vocabulary when it closes the stream.
Settable, since a producer learns it only at the end. A stream that
wraps another (see L</upstream>) and has none of its own answers with
its upstream's.

=head2 tool_calls

ArrayRef of complete L<Langertha::ToolCall> objects the backend emitted,
empty when it emitted none. Like L</finish_reason> it is known once the
stream is exhausted: the protocol emits the calls in its own framing when
it closes the stream. Settable; a stream that wraps another and has none
of its own answers with its upstream's.

=head2 has_tool_calls

True when L</tool_calls> holds at least one call.

=head2 usage

The backend's token usage for the whole stream as a L<Langertha::Usage>, or
C<undef> when it reported none. Like L</finish_reason> it is known once the
stream is exhausted: the protocol puts it on its terminal frames and the
tracing and request-log decorators record it. Settable; a provider usage
HashRef (OpenAI C<prompt_tokens>, Anthropic C<input_tokens>, Ollama
C<prompt_eval_count>, ...) is upgraded through
L<Langertha::Usage/from_hash>, an empty one is no usage. A stream that wraps
another and has none of its own answers with its upstream's.

=head2 model

Optional. The model name a handler routes the stream to, as the
non-streaming L<Langertha::Knarr::Response/model>:
L<Langertha::Knarr::Handler::Router> sets the model of the config entry.
Settable; a stream that wraps another and has none of its own answers with
its upstream's.

=head2 upstream_model

The model the backend reported on its stream chunks, or C<undef> when it
reported none. Known once the stream is exhausted; the tracing decorator
records it as the generation's model. Settable; a stream that wraps another
and has none of its own answers with its upstream's.

=head2 upstream

Optional. The stream this one wraps, as the tracing and request-log
decorators do. Only consulted by L</finish_reason>, L</tool_calls>,
L</usage>, L</model> and L</upstream_model>.

=head2 next_chunk_f

Returns a L<Future> resolving to the next chunk string, or C<undef>
when the stream is exhausted.

=head2 from_list

    my $stream = Langertha::Knarr::Stream->from_list(@chunks);

Convenience constructor that builds a stream from a fixed list of
chunk strings.

=head2 from_callback

    my $stream = Langertha::Knarr::Stream->from_callback( sub {
        my ($emit, $done, $fail, $finish, $tool_call, $usage, $model) = @_;
        my $f = $engine->simple_chat_stream_realtime_f(
            sub {
                $emit->( $_[0]->content );
                $finish->( $_[0]->finish_reason ) if $_[0]->has_finish_reason;
                $tool_call->( @{ $_[0]->tool_calls } ) if $_[0]->has_tool_calls;
                $usage->( $_[0]->usage ) if $_[0]->has_usage;
                $model->( $_[0]->model ) if $_[0]->has_model;
            },
            @messages,
        );
        $f->on_done( $done );
        $f->on_fail( $fail );
        $f->retain;
    });

Builds a stream backed by a callback-driven producer. The setup sub
receives seven callbacks — C<$emit-E<gt>($chunk)>, C<$done-E<gt>()>,
C<$fail-E<gt>($err)>, C<$finish-E<gt>($finish_reason)>,
C<$tool_call-E<gt>(@tool_calls)>, C<$usage-E<gt>($usage)>,
C<$model-E<gt>($model)> — and is expected to wire them to the underlying
async source. C<$finish> sets L</finish_reason>; an C<undef> reason is
ignored, a later one wins. C<$tool_call> appends complete
L<Langertha::ToolCall> objects to L</tool_calls>. C<$usage> sets L</usage>;
streamed usage is cumulative, so a later report wins, and an C<undef> or
empty one is ignored. C<$model> sets L</upstream_model>; an C<undef> or
empty name is ignored, a later one wins. Internally maintains a queue and
pending Future so the consumer side can sit on C<next_chunk_f> without
polling.

This is the canonical replacement for the queue/pending/finished/error
pump that engine-backed handlers used to inline.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
