package Langertha::Knarr::Handler::Tracing;
# ABSTRACT: Decorator handler that records every request as a Langfuse trace
our $VERSION = '1.001';
use Moose;
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Langertha::Knarr::Stream;

with 'Langertha::Knarr::Handler';


# Wraps an inner Knarr::Handler with Langfuse tracing. Each chat or stream
# request opens a trace+generation via $tracing->start_trace, then closes
# it with the assistant text via end_trace once the wrapped handler is done.
# The attribute is named "wrapped" rather than "inner" because Moose
# imports an inner() keyword used for augmented methods.

has wrapped => (
  is       => 'ro',
  required => 1,
);

# Anything implementing start_trace($opts) → $info / end_trace($info, %opts).
# In production this is a Langertha::Knarr::Tracing instance; tests can
# pass a mock that records calls.
has tracing => (
  is       => 'ro',
  required => 1,
);

# Optional: a label injected into the trace metadata's "engine" field when
# the wrapped handler doesn't have a more specific name.
has engine_label => (
  is      => 'ro',
  isa     => 'Maybe[Str]',
  default => sub { undef },
);

sub _open_trace {
  my ($self, $request) = @_;
  return $self->tracing->start_trace(
    model    => ( $request->model // '' ),
    engine   => ( $self->engine_label // ref( $self->wrapped ) ),
    messages => $request->messages,
    params   => {
      temperature => $request->temperature,
      max_tokens  => $request->max_tokens,
      tools       => $request->tools,
    },
    format   => $request->protocol,
  );
}

sub _result_text {
  my ($self, $r) = @_;
  return ''  unless defined $r;
  return $r  unless ref $r;
  return $r->{content} // '' if ref $r eq 'HASH';
  return blessed($r) ? "$r" : '';
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $trace = $self->_open_trace($request);
  my $result = eval { $self->wrapped->handle_chat_f( $session, $request ) };
  if ( my $err = $@ ) {
    $self->tracing->end_trace( $trace, error => "$err" );
    die $err;
  }
  my $f = $result->then( sub {
    my ($r) = @_;
    $self->tracing->end_trace(
      $trace,
      output => $self->_result_text($r),
      model  => ( ref($r) eq 'HASH' ? $r->{model} : undef ),
    );
    return Future->done($r);
  })->else( sub {
    my ($err) = @_;
    $self->tracing->end_trace( $trace, error => "$err" );
    return Future->fail($err);
  });
  return await $f;
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $trace = $self->_open_trace($request);

  my $upstream_stream;
  my $err = do {
    local $@;
    eval { $upstream_stream = $self->wrapped->handle_stream_f( $session, $request )->get; };
    $@;
  };
  if ($err) {
    $self->tracing->end_trace( $trace, error => "$err" );
    die $err;
  }

  my $accumulated = '';
  my $closed = 0;

  return Langertha::Knarr::Stream->new(
    source => sub {
      $upstream_stream->next_chunk_f->then( sub {
        my ($delta) = @_;
        if ( defined $delta ) {
          $accumulated .= $delta;
          return Future->done($delta);
        }
        unless ( $closed ) {
          $closed = 1;
          $self->tracing->end_trace(
            $trace,
            output => $accumulated,
            model  => $request->model,
          );
        }
        return Future->done(undef);
      })->else( sub {
        my ($e) = @_;
        unless ( $closed ) {
          $closed = 1;
          $self->tracing->end_trace( $trace, error => "$e" );
        }
        return Future->fail($e);
      });
    },
  );
}

sub list_models { $_[0]->wrapped->list_models }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Tracing - Decorator handler that records every request as a Langfuse trace

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Langertha::Knarr::Tracing;
    use Langertha::Knarr::Handler::Tracing;

    my $tracing = Langertha::Knarr::Tracing->new(config => $config);
    $handler = Langertha::Knarr::Handler::Tracing->new(
        wrapped => $handler,
        tracing => $tracing,
    );

=head1 DESCRIPTION

Decorator handler that opens a Langfuse trace + generation around every
chat or stream request and closes it with the assistant text once the
inner handler resolves (or fails). Streaming requests accumulate every
delta into a single output before closing the trace, so the Langfuse
view shows the full assembled response.

C<knarr start> mounts this automatically when
the config supplies Langfuse credentials.

=head2 wrapped

Required. The inner L<Langertha::Knarr::Handler> being decorated. The
attribute is named C<wrapped> rather than C<inner> because Moose
imports an C<inner()> keyword used for augmented methods.

=head2 tracing

Required. A L<Langertha::Knarr::Tracing> instance (or any object
implementing C<start_trace> / C<end_trace>).

=head2 engine_label

Optional. A string injected into the trace metadata's C<engine> field.
Defaults to C<< ref($self->wrapped) >>.

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
