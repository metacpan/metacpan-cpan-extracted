package Langertha::Knarr;
our $VERSION = '0.004';
# ABSTRACT: LLM Proxy with Langfuse Tracing
use strict;
use warnings;
use Mojolicious::Lite -signatures;
use Mojo::URL;
use JSON::MaybeXS qw( decode_json encode_json );
use Log::Any qw( $log );
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::Proxy::OpenAI;
use Langertha::Knarr::Proxy::Anthropic;
use Langertha::Knarr::Proxy::Ollama;


sub build_app {
  my ( $class, %opts ) = @_;
  my $config_obj = $opts{config}
    || Langertha::Knarr::Config->new(file => $opts{config_file});
  my $router = Langertha::Knarr::Router->new(config => $config_obj);
  my $tracing = Langertha::Knarr::Tracing->new(config => $config_obj);

  my $app = Mojolicious->new;
  $app->secrets(['knarr-llm-proxy']);

  # Configure user agent for passthrough proxying
  $app->ua->connect_timeout(10);
  $app->ua->request_timeout(300);

  # Store objects in app helper
  $app->helper(knarr_config  => sub { $config_obj });
  $app->helper(knarr_router  => sub { $router });
  $app->helper(knarr_tracing => sub { $tracing });

  # Auth middleware
  if ($config_obj->has_proxy_api_key) {
    $app->hook(before_dispatch => sub ($c) {
      my $path = $c->req->url->path->to_string;
      return if $path eq '/health';
      my $auth = $c->req->headers->header('Authorization')
              // $c->req->headers->header('x-api-key')
              // '';
      my $key = $config_obj->proxy_api_key;
      $auth =~ s/^Bearer\s+//i;
      unless ($auth eq $key) {
        $c->render(json => { error => { message => 'Invalid API key', type => 'authentication_error' } }, status => 401);
        return $c->rendered;
      }
    });
  }

  # Health check
  $app->routes->get('/health' => sub ($c) {
    $c->render(json => { status => 'ok', proxy => 'knarr' });
  });

  # --- OpenAI format routes ---
  $app->routes->post('/v1/chat/completions' => sub ($c) {
    _handle_request($c, 'Langertha::Knarr::Proxy::OpenAI', 'chat');
  });

  $app->routes->get('/v1/models' => sub ($c) {
    _handle_models_request($c, 'Langertha::Knarr::Proxy::OpenAI');
  });

  $app->routes->post('/v1/embeddings' => sub ($c) {
    _handle_request($c, 'Langertha::Knarr::Proxy::OpenAI', 'embedding');
  });

  # --- Anthropic format routes ---
  $app->routes->post('/v1/messages' => sub ($c) {
    _handle_request($c, 'Langertha::Knarr::Proxy::Anthropic', 'chat');
  });

  # --- Ollama format routes ---
  $app->routes->post('/api/chat' => sub ($c) {
    _handle_request($c, 'Langertha::Knarr::Proxy::Ollama', 'chat');
  });

  $app->routes->get('/api/tags' => sub ($c) {
    _handle_models_request($c, 'Langertha::Knarr::Proxy::Ollama');
  });

  $app->routes->get('/api/ps' => sub ($c) {
    $c->render(json => { models => [] });
  });

  return $app;
}


sub _handle_request ($c, $proxy_class, $type) {
  my $router  = $c->knarr_router;
  my $tracing = $c->knarr_tracing;
  my $body    = $c->req->json;

  unless ($body) {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  my $model_name = $proxy_class->extract_model($body);
  my $stream     = $proxy_class->extract_stream($body);
  my $messages   = $proxy_class->extract_messages($body);
  my $params     = $proxy_class->extract_params($body);

  # 1. Try explicit config / discovered models first
  my ($engine, $resolved_model) = eval { $router->resolve($model_name, skip_default => 1) };

  if ($engine) {
    _route_to_engine($c, $proxy_class, $engine, $resolved_model, $messages, $params, $stream, $tracing, $type);
    return;
  }

  # 2. Try passthrough (before default engine — passthrough uses client's own API key)
  my $pt_format = $proxy_class->passthrough_format;
  my $upstream   = $pt_format ? $c->knarr_config->passthrough_url_for($pt_format) : undef;

  if ($upstream) {
    my $trace_id = $tracing->start_trace(
      model    => $model_name,
      engine   => "passthrough:$pt_format",
      messages => $messages,
      params   => $params,
      format   => $proxy_class->format_name,
    );
    _handle_passthrough($c, $proxy_class, $upstream, $body, $model_name, $tracing, $trace_id);
    return;
  }

  # 3. Try default engine as last resort
  ($engine, $resolved_model) = eval { $router->resolve($model_name) };

  if ($engine) {
    _route_to_engine($c, $proxy_class, $engine, $resolved_model, $messages, $params, $stream, $tracing, $type);
    return;
  }

  my $err = $@ || "Model '$model_name' not configured and passthrough disabled";
  $c->render(json => $proxy_class->format_error($err, 'model_not_found'), status => 404);
}

sub _route_to_engine ($c, $proxy_class, $engine, $resolved_model, $messages, $params, $stream, $tracing, $type) {
  my $trace_id = $tracing->start_trace(
    model    => $resolved_model,
    engine   => ref($engine),
    messages => $messages,
    params   => $params,
    format   => $proxy_class->format_name,
  );

  if ($stream) {
    _handle_streaming($c, $proxy_class, $engine, $messages, $params, $resolved_model, $tracing, $trace_id);
  } else {
    _handle_sync($c, $proxy_class, $engine, $messages, $params, $resolved_model, $tracing, $trace_id, $type);
  }
}

sub _handle_sync ($c, $proxy_class, $engine, $messages, $params, $model, $tracing, $trace_id, $type) {
  my $result = eval {
    if ($type eq 'embedding') {
      my $input = $params->{input};
      $engine->simple_embedding($input);
    } else {
      my @chat_messages = map { ref $_ ? $_ : { role => 'user', content => $_ } } @$messages;
      $engine->simple_chat(@chat_messages);
    }
  };

  if ($@) {
    $log->errorf("Engine error: %s", $@);
    $tracing->end_trace($trace_id, error => "$@");
    $c->render(json => $proxy_class->format_error("$@", 'server_error'), status => 500);
    return;
  }

  my $response_data = $proxy_class->format_response($result, $model);

  $tracing->end_trace($trace_id,
    output => "$result",
    model  => $model,
    usage  => (ref $result && $result->isa('Langertha::Response') && $result->has_usage)
      ? { input => $result->prompt_tokens, output => $result->completion_tokens, total => $result->total_tokens }
      : undef,
  );

  $c->render(json => $response_data);
}

sub _handle_streaming ($c, $proxy_class, $engine, $messages, $params, $model, $tracing, $trace_id) {
  $c->res->headers->content_type($proxy_class->streaming_content_type);
  $c->res->headers->cache_control('no-cache');
  $c->res->headers->header('Connection' => 'keep-alive');
  $c->res->headers->header('X-Accel-Buffering' => 'no');

  my $full_content = '';
  my $usage;

  my $write = $c->res->content->write_body_data('');
  $c->res->code(200);

  eval {
    my @chat_messages = map { ref $_ ? $_ : { role => 'user', content => $_ } } @$messages;
    $engine->simple_chat_stream(sub {
      my ($chunk) = @_;
      my $chunk_data = $proxy_class->format_stream_chunk($chunk, $model);
      $full_content .= $chunk->content;
      if ($chunk->can('usage') && $chunk->usage) {
        $usage = $chunk->usage;
      }
      for my $line (@$chunk_data) {
        $c->write_chunk($line);
      }
    }, @chat_messages);
  };

  if ($@) {
    $log->errorf("Streaming error: %s", $@);
    $tracing->end_trace($trace_id, error => "$@");
  } else {
    $tracing->end_trace($trace_id,
      output => $full_content,
      model  => $model,
      usage  => $usage,
    );
  }

  # Write stream end marker
  my $end_marker = $proxy_class->stream_end_marker;
  $c->write_chunk($end_marker) if $end_marker;
  $c->write_chunk('');
}

sub _handle_passthrough ($c, $proxy_class, $upstream_base, $body, $model_name, $tracing, $trace_id) {
  my $path  = $c->req->url->path->to_string;
  my $query = $c->req->url->query->to_string;
  my $url   = Mojo::URL->new("$upstream_base$path");
  $url->query($query) if $query;

  $log->infof("Passthrough: %s %s -> %s", $c->req->method, $path, $url);

  # Forward client headers (auth, content-type, etc.)
  # Strip encoding headers — proxy handles data uncompressed
  my %fwd_headers;
  for my $name (@{$c->req->headers->names}) {
    my $lc = lc($name);
    next if $lc eq 'host' || $lc eq 'content-length' || $lc eq 'transfer-encoding'
         || $lc eq 'accept-encoding';
    $fwd_headers{$name} = $c->req->headers->header($name);
  }

  $c->render_later;
  my $ua = $c->app->ua;

  my $tx = $ua->build_tx(
    $c->req->method => $url,
    \%fwd_headers,
    json => $body,
  );

  my $stream = $body->{stream};

  if ($stream) {
    # Streaming passthrough: pipe response chunks to client as they arrive
    my $full_response = '';
    my $headers_sent  = 0;

    $tx->res->content->unsubscribe('read')->on(read => sub {
      my ($content, $bytes) = @_;

      unless ($headers_sent) {
        $c->res->code($tx->res->code // 200);
        for my $name (@{$tx->res->headers->names}) {
          my $lc = lc($name);
          next if $lc eq 'content-length' || $lc eq 'transfer-encoding'
               || $lc eq 'content-encoding';
          $c->res->headers->header($name => $tx->res->headers->header($name));
        }
        $c->res->headers->header('X-Accel-Buffering' => 'no');
        $headers_sent = 1;
      }

      $full_response .= $bytes;
      $c->write($bytes);
    });

    $ua->start($tx => sub {
      my ($ua, $tx) = @_;

      if (my $err = $tx->error) {
        unless ($headers_sent) {
          $tracing->end_trace($trace_id, error => $err->{message}) if $trace_id;
          $c->render(json => $proxy_class->format_error(
            "Upstream error: " . ($err->{message} // 'unknown'), 'upstream_error',
          ), status => 502);
          return;
        }
      }

      $c->finish;
      if ($trace_id) {
        $tracing->end_trace($trace_id,
          output => $full_response,
          model  => $model_name,
        );
      }
    });
  } else {
    # Non-streaming passthrough: wait for full response, forward it
    $ua->start($tx => sub {
      my ($ua, $tx) = @_;

      if (my $err = $tx->error) {
        $tracing->end_trace($trace_id, error => $err->{message}) if $trace_id;
        $c->render(json => $proxy_class->format_error(
          "Upstream error: " . ($err->{message} // 'unknown'), 'upstream_error',
        ), status => $err->{code} // 502);
        return;
      }

      my $res = $tx->res;
      $c->res->code($res->code);
      for my $name (@{$res->headers->names}) {
        my $lc = lc($name);
        next if $lc eq 'content-length' || $lc eq 'transfer-encoding'
             || $lc eq 'content-encoding';
        $c->res->headers->header($name => $res->headers->header($name));
      }
      $c->res->body($res->body);
      $c->rendered;

      if ($trace_id) {
        my $output = eval { decode_json($res->body) };
        $tracing->end_trace($trace_id,
          output => $output // $res->body,
          model  => $model_name,
        );
      }
    });
  }
}

sub _handle_models_request ($c, $proxy_class) {
  my $router = $c->knarr_router;
  my $models = $router->list_models;
  $c->render(json => $proxy_class->format_models_response($models));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr - LLM Proxy with Langfuse Tracing

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # 1. Create a .env with your Langfuse credentials
    #    (free tier at https://cloud.langfuse.com)
    LANGFUSE_PUBLIC_KEY=pk-lf-...
    LANGFUSE_SECRET_KEY=sk-lf-...
    LANGFUSE_BASE_URL=https://cloud.langfuse.com

    # 2. Start the proxy
    docker run --env-file .env -p 8080:8080 raudssus/langertha-knarr

    # 3. Point your client at it
    ANTHROPIC_BASE_URL=http://localhost:8080 claude    # Claude Code
    OPENAI_BASE_URL=http://localhost:8080/v1 my-app    # OpenAI SDK apps

    # Every API call is now traced in Langfuse.
    # The proxy forwards requests 1:1 using the client's own API key.
    # Knarr doesn't need one.

=head1 DESCRIPTION

Knarr is an LLM proxy that sits between your client and the API, forwarding
requests transparently while recording everything in Langfuse. The client's
own API key is used — Knarr doesn't need API keys for the LLM providers, only
Langfuse credentials to write the traces.

The simplest use case: debug your AI coding agent. Start Knarr, point Claude
Code or any other LLM client at it, and see every prompt, response, token
count and error in your Langfuse dashboard.

Named after the Norse cargo ship, Knarr carries your LLM calls safely to their
destination — with full cargo documentation.

=head2 Quick Start

Create a C<.env> file with your Langfuse credentials:

    LANGFUSE_PUBLIC_KEY=pk-lf-...
    LANGFUSE_SECRET_KEY=sk-lf-...
    LANGFUSE_BASE_URL=https://cloud.langfuse.com

Start the proxy:

    docker run --env-file .env -p 8080:8080 raudssus/langertha-knarr

Use it with Claude Code:

    ANTHROPIC_BASE_URL=http://localhost:8080 claude

Use it with any OpenAI SDK application:

    OPENAI_BASE_URL=http://localhost:8080/v1 python my_app.py

Every API call now shows up in your Langfuse dashboard with full input,
output, token usage, latency, and error tracking. The proxy doesn't touch
the API key — it just passes it through to the upstream API.

=head2 Additional Docker Examples

With provider API keys for engine routing (not just passthrough):

    docker run --env-file .env \
      -e OPENAI_API_KEY=sk-... \
      -p 8080:8080 \
      raudssus/langertha-knarr

With a mounted config file:

    docker run --env-file .env \
      -v ./knarr.yaml:/app/knarr.yaml \
      -p 8080:8080 \
      raudssus/langertha-knarr \
      container

Local usage (without Docker):

    knarr init > knarr.yaml
    knarr start

Programmatic usage:

    use Langertha::Knarr;
    my $app = Langertha::Knarr->build_app(config_file => 'knarr.yaml');

=head2 Request Flow

                       ┌─────────────────────────────────┐
  Client               │           Knarr Proxy           │           Backend
  ──────               │           ────────────          │           ───────
  OpenAI format   ───► │  /v1/chat/completions           │
  Anthropic format───► │  /v1/messages        ──Router──►│ ──► Langertha Engine ──► API
  Ollama format   ───► │  /api/chat                      │
                       │         │                       │
                       │         ▼                       │
                       │   Langfuse Tracing              │
                       └─────────────────────────────────┘

Every request is traced: the model name, engine used, full message input, output
text, token usage, and any errors are sent to Langfuse automatically.

=head2 API Formats and Routes

Knarr listens on port 8080 for OpenAI and Anthropic requests, and port 11434
for Ollama requests (matching the Ollama default).

B<OpenAI format> (port 8080):

=over

=item * C<POST /v1/chat/completions> — Chat completions

=item * C<POST /v1/embeddings> — Embeddings

=item * C<GET /v1/models> — List available models

=back

B<Anthropic format> (port 8080):

=over

=item * C<POST /v1/messages> — Messages API

=back

B<Ollama format> (port 11434):

=over

=item * C<POST /api/chat> — Chat

=item * C<GET /api/tags> — List models

=item * C<GET /api/ps> — Running models (always returns empty)

=back

B<Health check> (any port):

=over

=item * C<GET /health> — Returns C<{"status":"ok","proxy":"knarr"}>

=back

=head2 Passthrough Mode

By default, when C<passthrough: true> is set (the default in container mode),
requests are forwarded transparently to the upstream API using the client's own
API key. This means you can point any OpenAI or Anthropic client at Knarr and
it will just work, while Knarr adds Langfuse tracing on top.

Passthrough defaults:

=over

=item * C<openai> passthrough → C<https://api.openai.com>

=item * C<anthropic> passthrough → C<https://api.anthropic.com>

=back

Ollama requests are never passed through (no upstream Ollama passthrough URL).

=head2 Engine Routing

When a model is explicitly configured in the config file (or discovered via
C<auto_discover>), Knarr routes requests through the corresponding Langertha
engine. This allows routing to alternative backends, local models, or services
that do not natively speak the protocol the client is using.

Example: an Ollama client can request C<gpt-4o>, and Knarr will route it
through the OpenAI Langertha engine, returning an Ollama-formatted response.

=head2 Routing Priority

For each incoming request, Knarr resolves the target in this order:

=over

=item 1. Explicit model config or auto-discovered model → route via Langertha engine

=item 2. Passthrough enabled for this format → forward to upstream API

=item 3. Default engine configured → route via default Langertha engine

=item 4. None of the above → 404 error

=back

=head2 Streaming

All three formats support streaming:

=over

=item * OpenAI — SSE (Server-Sent Events), ends with C<data: [DONE]>

=item * Anthropic — SSE, ends with C<event: message_stop>

=item * Ollama — NDJSON (newline-delimited JSON), ends with C<{"done":true}>

=back

For passthrough requests, the stream is piped byte-for-byte from the upstream
API to the client with no buffering.

=head2 Configuration File

The config file is YAML. All string values support C<${ENV_VAR}> interpolation.

    listen:
      - "127.0.0.1:8080"
      - "127.0.0.1:11434"

    models:
      gpt-4o:
        engine: OpenAI
        model: gpt-4o
        api_key_env: OPENAI_API_KEY
      local:
        engine: OllamaOpenAI
        url: http://localhost:11434/v1
        model: llama3.2

    default:
      engine: OpenAI

    auto_discover: true

    passthrough:
      openai: https://api.openai.com
      anthropic: https://api.anthropic.com

    proxy_api_key: ${KNARR_API_KEY}

    langfuse:
      url: https://cloud.langfuse.com
      public_key: ${LANGFUSE_PUBLIC_KEY}
      secret_key: ${LANGFUSE_SECRET_KEY}
      trace_name: my-app

Model config keys:

=over

=item * C<engine> (required) — Langertha engine name (e.g. C<OpenAI>, C<Anthropic>, C<OllamaOpenAI>)

=item * C<model> — Model name to pass to the engine

=item * C<api_key_env> — Environment variable name holding the API key

=item * C<api_key> — Literal API key (prefer C<api_key_env>)

=item * C<url> — Custom base URL (for self-hosted or OpenAI-compatible endpoints)

=item * C<system_prompt> — Default system prompt for all requests to this model

=item * C<temperature> — Default temperature

=item * C<response_size> — Default max response tokens

=back

=head2 Langfuse Tracing

When C<LANGFUSE_PUBLIC_KEY> and C<LANGFUSE_SECRET_KEY> are set (or configured
in the config file), Knarr automatically traces every request:

=over

=item * Trace created with model name, engine, format, and input messages

=item * Generation recorded with start time, end time, output, and token usage

=item * Errors recorded with level ERROR and the error message

=item * Tags: C<knarr> added to every trace

=back

Traces are sent synchronously after each request. Configure the trace name with
C<KNARR_TRACE_NAME> or C<langfuse.trace_name> in the config file.

=head2 Programmatic Usage

    use Langertha::Knarr;
    use Langertha::Knarr::Config;

    # From a config file
    my $app = Langertha::Knarr->build_app(config_file => 'knarr.yaml');

    # From a pre-built config object
    my $config = Langertha::Knarr::Config->new(file => 'knarr.yaml');
    my $app = Langertha::Knarr->build_app(config => $config);

    # Use with any Mojolicious server
    use Mojo::Server::Daemon;
    my $daemon = Mojo::Server::Daemon->new(
      app    => $app,
      listen => ['http://127.0.0.1:8080'],
    );
    $daemon->run;

=head2 Environment Variables

=over

=item * C<OPENAI_API_KEY> — OpenAI API key (auto-detected by C<knarr container>)

=item * C<ANTHROPIC_API_KEY> — Anthropic API key (auto-detected)

=item * C<GROQ_API_KEY> — Groq API key (auto-detected)

=item * C<MISTRAL_API_KEY> — Mistral API key (auto-detected)

=item * C<DEEPSEEK_API_KEY> — DeepSeek API key (auto-detected)

=item * C<GEMINI_API_KEY> — Google Gemini API key (auto-detected)

=item * C<OPENROUTER_API_KEY> — OpenRouter API key (auto-detected)

=item * C<LANGFUSE_PUBLIC_KEY> — Langfuse public key (enables tracing)

=item * C<LANGFUSE_SECRET_KEY> — Langfuse secret key (enables tracing)

=item * C<LANGFUSE_URL> — Langfuse server URL (default: C<https://cloud.langfuse.com>)

=item * C<KNARR_TRACE_NAME> — Name for Langfuse traces (default: C<knarr-proxy>)

=item * C<KNARR_API_KEY> — Require this key in C<Authorization> or C<x-api-key> headers

=back

For CLI documentation, see L<knarr>.

=head1 SEE ALSO

=over

=item * L<knarr> — Command-line interface

=item * L<Langertha::Knarr::Config> — Configuration loading and validation

=item * L<Langertha::Knarr::Router> — Model-to-engine routing

=item * L<Langertha::Knarr::Tracing> — Langfuse tracing

=item * L<Langertha::Knarr::Proxy::OpenAI> — OpenAI format handler

=item * L<Langertha::Knarr::Proxy::Anthropic> — Anthropic format handler

=item * L<Langertha::Knarr::Proxy::Ollama> — Ollama format handler

=item * L<Langertha::Knarr::CLI> — CLI entry point

=back

=head2 build_app

    my $app = Langertha::Knarr->build_app(%opts);

Build and return a L<Mojolicious> application with all proxy routes wired up.

Options:

=over

=item * C<config> — A pre-built L<Langertha::Knarr::Config> object

=item * C<config_file> — Path to a YAML config file (used if C<config> not given)

=back

Returns a L<Mojolicious> application ready to be passed to C<Mojo::Server::Daemon>
or any other Mojolicious-compatible server.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
