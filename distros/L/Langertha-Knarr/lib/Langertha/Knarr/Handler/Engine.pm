package Langertha::Knarr::Handler::Engine;
# ABSTRACT: Knarr handler that proxies directly to a Langertha engine
our $VERSION = '1.102';
use Moose;
use Future;
use Future::AsyncAwait;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


has engine => (
  is => 'ro',
  required => 1,
);

has model_id => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

sub _model_id {
  my ($self) = @_;
  return $self->model_id if $self->model_id;
  my $e = $self->engine;
  return $e->chat_model if $e->can('chat_model') && $e->chat_model;
  return ( ref($e) =~ /::([^:]+)$/ ) ? lc($1) : 'engine';
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $response = await $self->engine->chat_f( $request->chat_f_args($self->engine) );
  my $r = Langertha::Knarr::Response->coerce($response);
  return $r->clone_with( model => $r->model // $self->_model_id );
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $engine = $self->engine;
  unless ( _supports_streaming($engine) ) {
    # Engine doesn't support native streaming — fall back to single-chunk.
    my $r = await $self->handle_chat_f($session, $request);
    my $stream = Langertha::Knarr::Stream->from_list( $r->content );
    $stream->finish_reason( $r->finish_reason );
    $stream->tool_calls( $r->tool_calls );
    $stream->usage( $r->usage ) if $r->usage;
    $stream->model( $r->model );
    $stream->upstream_model( $r->upstream_model );
    return $stream;
  }

  return Langertha::Knarr::Stream->from_callback( sub {
    my ($emit, $done, $fail, $finish, $tool_call, $usage, $model) = @_;
    my $cb = sub {
      my ($chunk) = @_;
      my $text = ref $chunk && $chunk->can('content') ? $chunk->content : "$chunk";
      $emit->($text);
      # Langertha::Stream::Chunk carries the backend's finish_reason on the
      # terminal chunk; the protocol maps it when it closes the stream.
      $finish->( $chunk->finish_reason )
        if ref $chunk && $chunk->can('has_finish_reason') && $chunk->has_finish_reason;
      # Core assembles streamed tool-call fragments and attaches the finished
      # Langertha::ToolCall objects to a chunk (Role::Chat::aggregate_tool_calls
      # collects the same); a core whose parser attaches none yields none. The
      # protocol emits them when it closes the stream (k19).
      $tool_call->( @{ $chunk->tool_calls } )
        if ref $chunk && $chunk->can('has_tool_calls') && $chunk->has_tool_calls;
      # The token usage rides on a chunk too, cumulative (the last report is
      # the stream's totals); the protocol puts it on its terminal frames and
      # the tracing decorator on the generation.
      $usage->( $chunk->usage )
        if ref $chunk && $chunk->can('has_usage') && $chunk->has_usage;
      # The model the backend reports answering with, for the trace.
      $model->( $chunk->model )
        if ref $chunk && $chunk->can('has_model') && $chunk->has_model;
    };
    my $f = $engine->chat_stream_realtime_f( chunk_callback => $cb, $request->chat_f_args($engine) );
    $f->on_done( $done );
    $f->on_fail( $fail );
    $f->retain;
  });
}

sub _supports_streaming {
  my ($engine) = @_;
  return $engine->supports('streaming') if $engine->can('supports');
  return $engine->can('simple_chat_stream_realtime_f') && $engine->can('chat_stream_request');
}

sub list_models {
  my ($self) = @_;
  return [ { id => $self->_model_id, object => 'model' } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Engine - Knarr handler that proxies directly to a Langertha engine

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Engine::Groq;
    use Langertha::Knarr::Handler::Engine;

    my $engine = Langertha::Engine::Groq->new(
        api_key    => $ENV{GROQ_API_KEY},
        chat_model => 'llama-3.3-70b-versatile',
    );

    my $handler = Langertha::Knarr::Handler::Engine->new(
        engine   => $engine,
        model_id => 'groq-llama-3.3-70b',
    );

=head1 DESCRIPTION

Wraps a single L<Langertha::Engine::*> instance and exposes it as a
Knarr handler. Non-streaming requests are dispatched via
C<< $engine->chat_f >> with the full set of generation parameters
(C<tools>, C<tool_choice>, C<response_format>, C<temperature>,
C<max_tokens>) forwarded from the client request — subject to the
engine's reported capabilities. Streaming requests use
C<chat_stream_realtime_f> with the same capability-filtered generation
parameters for native token-by-token delivery; engines that don't
support streaming fall back to a single-chunk emission.

For routing across multiple engines based on model name, use
L<Langertha::Knarr::Handler::Router> with a L<Langertha::Knarr::Router>
config instead.

=head2 engine

Required. Any object consuming L<Langertha::Role::Chat>. Streaming
support is detected via C<< $engine->supports('streaming') >> (Langertha
0.500+) or the presence of C<simple_chat_stream_realtime_f>.

=head2 model_id

Optional. The id reported by L</list_models> and surfaced in responses.
Defaults to the engine's C<chat_model>, falling back to a derived name
from the engine class.

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
