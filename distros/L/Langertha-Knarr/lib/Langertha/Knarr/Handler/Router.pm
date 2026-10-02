package Langertha::Knarr::Handler::Router;
# ABSTRACT: Knarr handler that resolves model names via Langertha::Knarr::Router and dispatches to engines
our $VERSION = '1.102';
use Moose;
use Future;
use Future::AsyncAwait;
use Future::Exception;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


# Wraps a Langertha::Knarr::Router (which is Moo) and uses it to resolve
# incoming model names to Langertha engine instances. Also keeps the
# upstream Knarr::Config visible for the rest of the request lifecycle.

has router => ( is => 'ro', required => 1 );

# Optional Passthrough handler used as fallback when the router can't
# resolve a model. Allows mixed mode: configured models go via Langertha
# engines (with tracing/middleware support), unknown models tunnel straight
# to the upstream API the client thinks they're talking to.
has passthrough => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

# The engine for a request, or () when it goes to the passthrough. Unknown
# models go to the passthrough only when it can forward the client's
# protocol; otherwise to the default engine (k41). With neither, the
# failure carries the category 'model_not_found', which Knarr answers as a
# 404 in the client protocol's error shape.
#
# A request without a model (A2A never names one) is resolved as such, not
# as a placeholder name: the default engine then answers with its own
# configured model instead of being sent a model called 'default' (k42).
sub _resolve {
  my ($self, $request) = @_;
  my $model  = $request->model;
  my $router = $self->router;
  if ( $self->_passthrough_serves( $request->protocol ) ) {
    # With passthrough: try without default engine first so unknown models
    # go to passthrough instead of being routed to the default engine.
    my @r = eval { $router->resolve($model, skip_default => 1) };
    return @r if @r;
    return ();  # not found or error → passthrough
  }
  my @r = $router->resolve($model, skip_default => 1);
  return @r if @r;
  return $router->resolve($model) if $router->config->default_engine;
  die Future::Exception->new(
    ( defined $model && length $model ? "Model '$model' is not configured" : 'The request names no model' )
    . ' and there is no default engine'
    . ( $self->passthrough ? ' (no passthrough upstream for '.$request->protocol.')' : '' ),
    'model_not_found' );
}

sub _passthrough_serves {
  my ($self, $protocol) = @_;
  my $pt = $self->passthrough or return 0;
  return $pt->can('serves_protocol') ? $pt->serves_protocol($protocol) : 1;
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my ($engine, $canonical_model, $alias_only) = $self->_resolve($request);
  unless ( $engine ) {
    return Langertha::Knarr::Response->coerce(
      await $self->passthrough->handle_chat_f( $session, $request )
    );
  }
  my $response = await $engine->chat_f( $request->chat_f_args($engine) );
  my $r = Langertha::Knarr::Response->coerce($response);
  # An alias without a configured model: the provider default answered, so
  # report the model that answered, never the alias (k22).
  if ( $alias_only ) {
    return $r if defined $r->model;
    my $chat_model = $engine->can('chat_model') ? $engine->chat_model : undef;
    return defined $chat_model ? $r->clone_with( model => $chat_model ) : $r;
  }
  # The client sees the configured name, as /v1/models lists it; the model
  # the upstream reported goes to the trace (k70).
  return $r->clone_with( model => $canonical_model, upstream_model => $r->model );
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my ($engine, $canonical_model, $alias_only) = $self->_resolve($request);

  unless ( $engine ) {
    return await $self->passthrough->handle_stream_f( $session, $request );
  }

  unless ( _supports_streaming($engine) ) {
    my $r = await $self->handle_chat_f($session, $request);
    my $stream = Langertha::Knarr::Stream->from_list( $r->content );
    $stream->finish_reason( $r->finish_reason );
    $stream->tool_calls( $r->tool_calls );
    $stream->usage( $r->usage ) if $r->usage;
    $stream->model( $r->model );
    $stream->upstream_model( $r->upstream_model );
    return $stream;
  }

  my $stream = Langertha::Knarr::Stream->from_callback( sub {
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
  # Labeled like the non-streaming answer: the configured model, unless the
  # config names none and the provider default answers (k22).
  $stream->model($canonical_model) unless $alias_only;
  return $stream;
}

sub _supports_streaming {
  my ($engine) = @_;
  return $engine->supports('streaming') if $engine->can('supports');
  return $engine->can('simple_chat_stream_realtime_f') && $engine->can('chat_stream_request');
}

sub list_models {
  my ($self) = @_;
  my $models = $self->router->list_models;
  return [ map { ref $_ eq 'HASH' ? $_ : { id => "$_", object => 'model' } } @{ $models || [] } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Router - Knarr handler that resolves model names via Langertha::Knarr::Router and dispatches to engines

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Config;
    use Langertha::Knarr::Router;
    use Langertha::Knarr::Handler::Router;
    use Langertha::Knarr::Handler::Passthrough;

    my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
    my $router = Langertha::Knarr::Router->new(config => $config);

    my $handler = Langertha::Knarr::Handler::Router->new(
        router      => $router,
        passthrough => Langertha::Knarr::Handler::Passthrough->new(
            upstreams => $config->passthrough,
        ),
    );

=head1 DESCRIPTION

Resolves incoming model names against a L<Langertha::Knarr::Router>
(which knows your C<knarr.yaml>) and dispatches to the matched
L<Langertha::Engine>. When a passthrough fallback handler is supplied,
unknown model names in a protocol it serves tunnel through to it instead
of falling back to the default engine — this preserves the classic Knarr
behaviour where configured models go via Langertha and everything else
passes straight to the upstream API.

Non-streaming answers are labeled with the configured model. For a model
config without a C<model> key the provider's default answers, so the
response keeps the model the upstream reported, else the engine's
C<chat_model>; it is never relabeled with the alias.

The client keeps seeing the configured name -- the id C</v1/models> lists
and the one it can ask for again -- even where the upstream reported a more
concrete one (C<gpt-4o> answering as C<gpt-4o-2024-08-06>). No protocol
requires otherwise: Ollama echoes the name asked for, and the C<model> of an
OpenAI or Anthropic answer, where the provider puts its concrete name, is
informational -- clients do not match it against the request. The
reported model is kept as L<Langertha::Knarr::Response/upstream_model> (on a
stream L<Langertha::Knarr::Stream/upstream_model>, the configured name as
its C<model>), and L<Langertha::Knarr::Handler::Tracing> records it as the
Langfuse generation's model, the configured name in its metadata.

A request that names no model (A2A always; ACP without C<agent_name>, and
any other protocol whose body leaves the model out) goes to the default
engine with the C<model> configured under C<default:>, or with the
provider's default when none is configured -- see
L<Langertha::Knarr::Router/resolve>. A model the client does name reaches
the default engine as asked.

Streaming responses are pumped via the engine's
C<chat_stream_realtime_f> for native token-by-token delivery, with the
same capability-filtered generation parameters as the non-streaming path.

=head2 router

Required. A L<Langertha::Knarr::Router> instance.

=head2 passthrough

Optional. Any L<Langertha::Knarr::Handler> consumer used as a fallback
when the router can't resolve a model. A handler with a C<serves_protocol>
method (L<Langertha::Knarr::Handler::Passthrough>) only gets requests in the
protocols it can forward; an unknown model in any other protocol goes to the
default engine instead.

When the router can't resolve a model, no passthrough serves the request's
protocol and there is no default engine, the handler fails with the
category C<model_not_found>; L<Langertha::Knarr> answers that with a C<404>
in the client protocol's error shape.

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
