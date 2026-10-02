package Langertha::Knarr::Handler::Tracing;
# ABSTRACT: Decorator handler that records every request as a Langfuse trace
our $VERSION = '1.102';
use Moose;
use Future;
use Future::AsyncAwait;
use Time::HiRes qw( gettimeofday tv_interval );
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

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
    # A raw passthrough the upstream refused (k66): this is its one trace.
    ( defined $request->extra->{passthrough_fallback}
      ? ( passthrough_fallback => $request->extra->{passthrough_fallback} ) : () ),
  );
}

# The generation's model is the one the backend reported answering with; the
# name the handler labeled the answer with (the configured model a Router
# relabels it to, k70) goes into the metadata when it differs.
sub _model_opts {
  my ($self, $label, $reported, $fallback) = @_;
  my $model = $reported // $label // $fallback;
  return (
    model => $model,
    ( defined $reported && defined $label && $label ne $reported
      ? ( configured_model => $label ) : () ),
  );
}

sub _close_trace {
  my ($self, $trace, $r) = @_;
  my $resp = Langertha::Knarr::Response->coerce($r);
  # timing is the engine's own measurement (ttft/total); passing it lets
  # Tracing anchor endTime/completionStartTime to the real call window
  # instead of the proxy's wall clock. Streaming and passthrough have no
  # response object and keep the wall-clock fallback.
  $self->tracing->end_trace(
    $trace,
    output => $resp->content,
    $self->_model_opts( $resp->model, $resp->upstream_model ),
    ( $resp->usage              ? ( usage       => $resp->usage )      : () ),
    ( $resp->timing             ? ( timing      => $resp->timing )     : () ),
    ( defined $resp->id         ? ( response_id => $resp->id )         : () ),
    ( defined $resp->thinking   ? ( thinking    => $resp->thinking )   : () ),
    ( $resp->rate_limit         ? ( rate_limit  => $resp->rate_limit ) : () ),
    ( $resp->has_tool_calls     ? ( tool_calls  => $resp->tool_calls ) : () ),
  );
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
    $self->_close_trace( $trace, $r );
    return Future->done($r);
  })->else( sub {
    my ($err) = @_;
    $self->tracing->end_trace( $trace, error => "$err" );
    # The whole failure: a timeout's category rides along (k36).
    return Future->fail(@_);
  });
  return await $f;
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $trace = $self->_open_trace($request);

  # TTFT for the routed streaming path is measured here, in the proxy: the
  # decorator only ever sees deltas and never a Langertha::Response, so unlike
  # the non-streaming path there is no engine-measured timing to hand off. The
  # clock starts before the upstream stream is opened, so this ttft includes
  # the proxy's own dispatch overhead.
  my $stream_start = [ gettimeofday ];

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
  my $ttft;
  my $closed = 0;

  return Langertha::Knarr::Stream->new(
    upstream => $upstream_stream,
    source => sub {
      $upstream_stream->next_chunk_f->then( sub {
        my ($delta) = @_;
        if ( defined $delta ) {
          $ttft = tv_interval($stream_start) unless defined $ttft;
          $accumulated .= $delta;
          return Future->done($delta);
        }
        unless ( $closed ) {
          $closed = 1;
          # Only claim a ttft when a delta actually arrived; an empty stream
          # leaves $ttft undef and end_trace keeps its wall-clock fallback.
          $self->tracing->end_trace(
            $trace,
            output => $accumulated,
            $self->_model_opts(
              ( $upstream_stream->can('model')          ? $upstream_stream->model          : undef ),
              ( $upstream_stream->can('upstream_model') ? $upstream_stream->upstream_model : undef ),
              $request->model,
            ),
            ( defined $ttft ? ( timing => { ttft_seconds => $ttft } ) : () ),
            # The complete tool calls, known once the stream is exhausted (k19).
            ( $upstream_stream->can('has_tool_calls') && $upstream_stream->has_tool_calls
                ? ( tool_calls => $upstream_stream->tool_calls ) : () ),
            # So is the token usage the backend reported on its chunks.
            ( $upstream_stream->can('usage') && $upstream_stream->usage
                ? ( usage => $upstream_stream->usage ) : () ),
          );
        }
        return Future->done(undef);
      })->else( sub {
        my ($e) = @_;
        unless ( $closed ) {
          $closed = 1;
          $self->tracing->end_trace( $trace, error => "$e" );
        }
        return Future->fail(@_);
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

version 1.102

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
view shows the full assembled response, with the token usage the backend
reported on its stream (L<Langertha::Knarr::Stream/usage>).

The generation's C<model> is the model the backend reported answering with
(L<Langertha::Knarr::Response/upstream_model>,
L<Langertha::Knarr::Stream/upstream_model>), which can be more concrete than
the one asked for. When a handler labeled the answer with another name --
L<Langertha::Knarr::Handler::Router> answers under the configured model --
that name is recorded as C<configured_model> in the generation's metadata.
Without a reported model the generation gets the label, and a stream without
either the model the client asked for.

C<knarr start> mounts this automatically when
the config supplies Langfuse credentials.

A raw passthrough request that L<Langertha::Knarr> answers through the
handler chain after the upstream refused the client's key (see
L<Langertha::Knarr/raw_passthrough>) is traced here only, once, with the
refusing status as C<passthrough_fallback> in the trace's metadata.

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
