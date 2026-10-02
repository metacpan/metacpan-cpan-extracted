package Langertha;
# ABSTRACT: The clan of fierce vikings with 🪓 and 🛡️ to AId your rAId
our $VERSION = '0.503';
use utf8;
use strict;
use warnings;

use Carp ();
use Import::Into;
use Module::Pluggable::Object ();
use Module::Runtime qw( require_module use_module );

my %_sugar_plugins;  # per-class plugin accumulator

my %setup = (
  Raider => sub {
    my ( $caller ) = @_;
    Moose->import::into($caller);
    Future::AsyncAwait->import::into($caller);
    $caller->meta->superclasses('Langertha::Raider');
    $_sugar_plugins{$caller} = [];
    no strict 'refs';
    *{"${caller}::plugin"} = sub {
      push @{$_sugar_plugins{$caller}}, @_;
    };
    $caller->meta->add_method('_sugar_plugins' => sub {
      return [@{$_sugar_plugins{$caller} // []}];
    });
  },
  Plugin => sub {
    my ( $caller ) = @_;
    Moose->import::into($caller);
    Future::AsyncAwait->import::into($caller);
    $caller->meta->superclasses('Langertha::Plugin');
  },
);

sub import {
  my ( $class, @args ) = @_;
  return unless @args;
  my $caller = caller;
  for my $arg (@args) {
    my $setup = $setup{$arg}
      or Carp::croak("Unknown Langertha import '$arg' (known: ".join(', ', sort keys %setup).")");
    require Moose;
    require Future::AsyncAwait;
    use_module('Langertha::Raider') if $arg eq 'Raider';
    use_module('Langertha::Plugin') if $arg eq 'Plugin';
    $setup->($caller);
  }
}

sub _module_path {
  my ($module) = @_;
  my $path = $module;
  $path =~ s{::}{/}g;
  return $path . '.pm';
}

sub _is_missing_module_error {
  my ($err, $module) = @_;
  return 0 unless defined $err && length $err;
  my $pm_path = _module_path($module);
  return index($err, "Can't locate $pm_path in \@INC") >= 0 ? 1 : 0;
}

sub discover_modules_in_scope {
  my ($class, %args) = @_;
  my $search_path = $args{search_path};
  $search_path = ['Langertha::Engine', 'LangerthaX::Engine']
    unless ref($search_path) eq 'ARRAY' && @$search_path;

  my $finder = Module::Pluggable::Object->new(
    search_path => $search_path,
    require     => 0,
    inner       => 0,
  );

  my %seen;
  my @modules = grep { defined $_ && length $_ && !$seen{$_}++ } $finder->plugins;
  return [ sort @modules ];
}

sub available_engine_classes {
  my ($class) = @_;
  return $class->discover_modules_in_scope(
    search_path => ['Langertha::Engine', 'LangerthaX::Engine'],
  );
}

sub available_engine_ids {
  my ($class) = @_;
  my %ids;
  for my $module (@{$class->available_engine_classes}) {
    next unless $module =~ /::([^:]+)\z/;
    $ids{lc($1)} = 1;
  }
  return [ sort keys %ids ];
}

sub resolve_engine_class {
  my ($class, $engine) = @_;
  Carp::croak("No engine specified") unless defined($engine) && length($engine);

  my @candidates;
  if ($engine =~ /::/) {
    @candidates = ($engine);
  } else {
    my @ordered = ("Langertha::Engine::$engine", "LangerthaX::Engine::$engine");
    my %available = map { $_ => 1 } @{$class->available_engine_classes};
    @candidates = grep { $available{$_} } @ordered;
    @candidates = @ordered unless @candidates;
  }

  my @errors;
  for my $candidate (@candidates) {
    my $ok = eval {
      require_module($candidate);
      1;
    };
    return $candidate if $ok;
    my $err = $@;
    if (!_is_missing_module_error($err, $candidate)) {
      Carp::croak($err);
    }
    push @errors, $candidate;
  }

  Carp::croak(
    "Engine '$engine' not found (tried: " . join(', ', @errors) . ")"
  );
}

sub new_engine {
  my ($class, $engine, @args) = @_;
  Carp::croak("No engine specified") unless defined($engine) && length($engine);
  Carp::croak("Engine constructor arguments must be key/value pairs")
    if @args % 2;

  my $engine_class = $class->resolve_engine_class($engine);
  return $engine_class->new(@args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha - The clan of fierce vikings with 🪓 and 🛡️ to AId your rAId

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $system_prompt = 'You are a helpful assistant.';

    # Local models via Ollama
    use Langertha::Engine::Ollama;

    my $ollama = Langertha::Engine::Ollama->new(
        url           => 'http://127.0.0.1:11434',
        model         => 'a small chat model you have pulled locally',
        system_prompt => $system_prompt,
    );
    print $ollama->simple_chat('Do you wanna build a snowman?');

    # OpenAI
    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key       => $ENV{OPENAI_API_KEY},
        model         => 'a small fast model from your provider',
        system_prompt => $system_prompt,
    );
    print $openai->simple_chat('Do you wanna build a snowman?');

    # Anthropic Claude
    use Langertha::Engine::Anthropic;

    my $claude = Langertha::Engine::Anthropic->new(
        api_key => $ENV{ANTHROPIC_API_KEY},
        model   => 'a frontier chat model from your provider',
    );
    print $claude->simple_chat('Generate Perl Moose classes to represent GeoJSON data.');

    # Google Gemini
    use Langertha::Engine::Gemini;

    my $gemini = Langertha::Engine::Gemini->new(
        api_key => $ENV{GEMINI_API_KEY},
        model   => 'a fast model from your provider',
    );
    print $gemini->simple_chat('Explain the difference between Moose and Moo.');

=head1 DESCRIPTION

Langertha provides a unified Perl interface for interacting with various Large
Language Model (LLM) APIs. It abstracts away provider-specific differences,
giving you a consistent API whether you're using OpenAI, Anthropic Claude,
Ollama, Groq, Mistral, or other providers.

B<THIS API IS WORK IN PROGRESS.>

=head2 Key Features

=over 4

=item * B<35 engines> -- unified API across cloud and local LLM providers

=item * B<Chat, streaming, embeddings, transcription, image generation>

=item * B<MCP tool calling> -- automatic multi-round tool loops over any
L<Net::Async::MCP>-compatible client (see L<Langertha::Role::Tools>)

=item * B<Raider> -- autonomous agent with history, compression, and plugins,
shipped separately in the L<langertha-raider|Langertha::Raider> distribution

=item * B<Response metadata> -- token usage, model, timing, rate limits

=item * B<Async/await> via L<Future::AsyncAwait>, sync via L<LWP::UserAgent>

=item * B<Langfuse observability> -- traces, generations, and tool spans

=item * B<Dynamic model discovery> -- query provider APIs with caching

=item * B<Chain-of-thought> -- native extraction and C<E<lt>thinkE<gt>> tag filtering

=item * B<Plugin system> for extending Chat, Embedder, ImageGen, and Raider

=back

=head2 Class Sugar

Langertha can set up your package as a Raider subclass or Plugin role:

    # Build a custom Raider agent
    package MyAgent;
    use Langertha qw( Raider );
    plugin 'Langfuse';

    around plugin_before_llm_call => async sub {
        my ($orig, $self, $conversation, $iteration) = @_;
        $conversation = await $self->$orig($conversation, $iteration);
        # ... custom logic ...
        return $conversation;
    };

    __PACKAGE__->meta->make_immutable;

    # Build a custom Plugin
    package MyApp::Guardrails;
    use Langertha qw( Plugin );

    around plugin_before_tool_call => async sub {
        my ($orig, $self, $name, $input) = @_;
        my @result = await $self->$orig($name, $input);
        return unless @result;
        return if $name eq 'dangerous_tool';
        return @result;
    };

C<use Langertha qw( Raider )> imports L<Moose> and L<Future::AsyncAwait>,
sets L<Langertha::Raider> as superclass, and provides the C<plugin>
function for applying plugins by short name. L<Langertha::Raider> ships in
the separate C<langertha-raider> distribution, which must be installed for
this sugar to load.

C<use Langertha qw( Plugin )> imports L<Moose> and
L<Future::AsyncAwait>, and sets L<Langertha::Plugin> as superclass.

=head2 Engine Discovery

Langertha discovers engine modules in scope via L<Module::Pluggable> across
both namespaces:

=over 4

=item * C<Langertha::Engine::*>

=item * C<LangerthaX::Engine::*>

=back

Useful class methods:

=over 4

=item * C<< Langertha->available_engine_classes >>

Returns discovered fully-qualified engine class names.

=item * C<< Langertha->available_engine_ids >>

Returns discovered engine IDs (lowercased short names).

=item * C<< Langertha->resolve_engine_class($name_or_class) >>

Resolves short names (for example C<OpenAI>) with core-first lookup,
or accepts fully-qualified class names.

=item * C<< Langertha->new_engine($name_or_class, %args) >>

Resolves and constructs an engine instance in one call.

=back

=head2 Engine Modules

Each module below is a ready-to-use engine. They are built on the abstract
bases L<Langertha::Engine::Remote>, L<Langertha::Engine::OpenAIBase> and
L<Langertha::Engine::AnthropicBase>, which are not listed here because they
are meant for subclassing (including third-party engines in the C<LangerthaX>
namespace) rather than for direct use.

=over 4

=item * L<Langertha::Engine::Anthropic> - Claude models (Sonnet, Opus, Haiku)

=item * L<Langertha::Engine::OpenAI> - frontier GPT models, embeddings, Whisper transcription

=item * L<Langertha::Engine::OpenAIResponses> - OpenAI Responses API for reasoning models

=item * L<Langertha::Engine::Ollama> - Local LLM hosting via L<https://ollama.com/>

=item * L<Langertha::Engine::Groq> - Fast inference API

=item * L<Langertha::Engine::Mistral> - Mistral AI models, embeddings, Voxtral transcription

=item * L<Langertha::Engine::DeepSeek> - DeepSeek models

=item * L<Langertha::Engine::MiniMax> - MiniMax large language models via OpenAI-compatible endpoint (coding, reasoning, agentic tool use)

=item * L<Langertha::Engine::MiniMaxAnthropic> - MiniMax via legacy Anthropic-compatible endpoint

=item * L<Langertha::Engine::Moonshot> - Moonshot AI Kimi models via OpenAI-compatible endpoint

=item * L<Langertha::Engine::MoonshotAnthropic> - Moonshot AI Kimi via Anthropic-compatible endpoint

=item * L<Langertha::Engine::Gemini> - Google Gemini models (Flash, Pro), embeddings

=item * L<Langertha::Engine::XAI> - xAI Grok models, Imagine image generation

=item * L<Langertha::Engine::vLLM> - vLLM inference server

=item * L<Langertha::Engine::VLLMHook> - vLLM inference server with vLLM-Hook probe capture

=item * L<Langertha::Engine::SGLang> - SGLang inference server (chat, embeddings)

=item * L<Langertha::Engine::HuggingFace> - HuggingFace Inference Providers

=item * L<Langertha::Engine::Perplexity> - Perplexity AI models

=item * L<Langertha::Engine::NousResearch> - Nous Research (Hermes models)

=item * L<Langertha::Engine::Cerebras> - Cerebras (wafer-scale, fastest inference)

=item * L<Langertha::Engine::OpenRouter> - OpenRouter (300+ models, meta-provider)

=item * L<Langertha::Engine::Replicate> - Replicate (thousands of open-source models)

=item * L<Langertha::Engine::OllamaOpenAI> - Ollama via OpenAI-compatible API

=item * L<Langertha::Engine::LlamaCpp> - llama.cpp server (chat, embeddings)

=item * L<Langertha::Engine::LMStudio> - LM Studio native local REST API

=item * L<Langertha::Engine::LMStudioOpenAI> - LM Studio via OpenAI-compatible API

=item * L<Langertha::Engine::LMStudioAnthropic> - LM Studio via Anthropic-compatible API

=item * L<Langertha::Engine::AKI> - AKI.IO native API (EU/Germany)

=item * L<Langertha::Engine::AKIOpenAI> - AKI.IO via OpenAI-compatible API

=item * L<Langertha::Engine::AKIAnthropic> - AKI.IO via Anthropic-compatible API

=item * L<Langertha::Engine::TSystems> - T-Systems AI Foundation Services / LLM Hub (EU/Germany)

=item * L<Langertha::Engine::Scaleway> - Scaleway Generative APIs (EU)

=item * L<Langertha::Engine::Hetzner> - Hetzner Inference API (EU/Germany, OpenAI-compatible)

=item * L<Langertha::Engine::TranscriptionBase> - Slim base for OpenAI-shape
transcription-only engines (no chat / tools / embeddings / image generation).
L<Langertha::Engine::OpenAI> exposes a C<whisper> attribute returning an
instance of this class bound to the parent's C<api_key> / C<url>.

=item * L<Langertha::Engine::Whisper> - Self-hosted Whisper-compatible
transcription server (extends TranscriptionBase)

=back

=head2 Roles

Roles provide composable functionality to engines and to the wrapper classes:

=over 4

=item * L<Langertha::Role::Capabilities> - C<engine_capabilities> registry
plus C<supports($cap)> helper, composed by L<Langertha::Role::Chat>

=item * L<Langertha::Role::Chat> - Synchronous and async chat methods,
including C<chat_f(messages =E<gt> [...], tools =E<gt> [...], tool_choice
=E<gt> ..., response_format =E<gt> ...)> for single-turn structured
calls and C<aggregate_tool_calls(\@chunks)> for streaming

=item * L<Langertha::Role::ThinkTag> - Configurable C<E<lt>thinkE<gt>> tag
filtering for reasoning models, composed by L<Langertha::Role::Chat>

=item * L<Langertha::Role::HTTP> - HTTP request/response handling

=item * L<Langertha::Role::AsyncHTTP> - Async HTTP backend selection (injected client / Net::Async::HTTP / synchronous LWP fallback), composed by L<Langertha::Role::Chat>, L<Langertha::Role::Embedding>, L<Langertha::Role::Transcription>, L<Langertha::Role::ImageGeneration> and L<Langertha::Role::Runtime::MetricsPoll>

=item * L<Langertha::Role::Streaming> - Streaming response processing

=item * L<Langertha::Role::JSON> - JSON encode/decode

=item * L<Langertha::Role::OpenAICompatible> - OpenAI-compatible API behaviour

=item * L<Langertha::Role::AnthropicCompatible> - Anthropic-compatible API behaviour

=item * L<Langertha::Role::ResponsesCompatible> - Open-Responses wire envelope (OpenAI /v1/responses, Perplexity Agent API)

=item * L<Langertha::Role::SystemPrompt> - System prompt attribute

=item * L<Langertha::Role::Temperature> - Temperature parameter

=item * L<Langertha::Role::ResponseSize> - Max response size parameter

=item * L<Langertha::Role::ResponseFormat> - Response format (JSON mode)

=item * L<Langertha::Role::ReasoningEffort> - Request-side reasoning-effort control

=item * L<Langertha::Role::PromptCache> - Request-side prompt-caching control

=item * L<Langertha::Role::CachedContent> - Explicit cached-content resource
lifecycle (create/get/list/update/delete)

=item * L<Langertha::Role::ContextSize> - Context window size parameter

=item * L<Langertha::Role::Seed> - Deterministic seed parameter

=item * L<Langertha::Role::Models> - Model listing

=item * L<Langertha::Role::StaticModels> - Model listing from a hardcoded list,
for providers without a models endpoint

=item * L<Langertha::Role::Embedding> - Embedding generation

=item * L<Langertha::Role::Transcription> - Audio transcription

=item * L<Langertha::Role::Tools> - Tool/function calling

=item * L<Langertha::Role::HermesTools> - Hermes-style tool calling via
C<E<lt>tool_callE<gt>> XML tags for models without native API tool support

=item * L<Langertha::Role::ParallelToolUse> - Parallel tool calling control

=item * L<Langertha::Role::ServerTools> - Provider-native server-side tools
(C<server_tools> capability and per-engine defaults)

=item * L<Langertha::Role::ImageGeneration> - Image generation

=item * L<Langertha::Role::ImageInput> - Image input (vision), claimed per model

=item * L<Langertha::Role::KeepAlive> - Keep-alive duration for local models

=item * L<Langertha::Role::RuntimeKnobs> - Per-request prefix-cache runtime knobs
for self-hosted engines

=item * L<Langertha::Role::Runtime::MetricsPoll> - Async Prometheus C</metrics>
scraper for self-hosted engines

=item * L<Langertha::Role::PluginHost> - Plugin system for the wrapper classes
(and for L<Langertha::Raider> from the langertha-raider distribution)

=item * L<Langertha::Role::Runnable> - Generic C<run_f($ctx)> execution contract,
a dependency-free core primitive (consumed by the Raid/Raider nodes in the
langertha-raider distribution)

=item * L<Langertha::Role::Langfuse> - Engine-level Langfuse observability,
composed by L<Langertha::Role::Chat>

=item * L<Langertha::Role::OpenAPI> - OpenAPI spec support

=back

=head2 Wrapper Classes

These classes wrap an engine with optional overrides and plugin lifecycle hooks:

=over 4

=item * L<Langertha::Chat> - Chat wrapper with system prompt, model, and temperature overrides

=item * L<Langertha::Embedder> - Embedding wrapper with optional model override

=item * L<Langertha::ImageGen> - Image generation wrapper with model, size, and quality overrides

=back

=head2 Plugins

=over 4

=item * L<Langertha::Plugin> - Base class for all plugins

=item * L<Langertha::Plugin::Langfuse> - Langfuse observability (traces, generations, spans)

=back

=head2 Data Objects

=over 4

=item * L<Langertha::Response> - LLM response with content, usage, and rate
limit metadata; C<tool_calls> is an ArrayRef of L<Langertha::ToolCall> and
the single source of truth for both native and synthesized tool calls

=item * L<Langertha::Usage> - Token usage of one call (L<Langertha::Response/usage>),
normalized across providers, with cache reads/writes and whether the wire
counts them inside C<input_tokens>

=item * L<Langertha::CallResult> - Result of an embedding, transcription or
image call (C<simple_embedding_result>, C<simple_transcription_call>,
C<simple_image_result>): the value plus usage, rate limit, model and timing

=item * L<Langertha::Pricing> - Model-to-price catalogue that turns a
L<Langertha::Usage> into a L<Langertha::Cost>, with optional cache rates

=item * L<Langertha::Cost> - Monetary cost of one call (input, output, cache
read/write, total)

=item * L<Langertha::UsageRecord> - Ledger entry combining a
L<Langertha::Usage>, its L<Langertha::Cost> and request metadata

=item * L<Langertha::ToolCall> - Canonical tool invocation produced by an
LLM, with C<synthetic> flag for forced-tool fallbacks

=item * L<Langertha::ToolChoice> - Canonical tool-selection policy with
per-provider serializers (C<to_openai>, C<to_anthropic>, C<to_gemini>,
legacy C<to_perplexity>)

=item * L<Langertha::Tool> - Canonical tool definition with cross-provider
serializers (C<to_openai>, C<to_anthropic>, C<to_gemini>, C<to_mcp>,
C<to_json_schema>) and accepting constructors (C<from_openai>,
C<from_anthropic>, C<from_mcp>, C<from_gemini>, C<from_hash>)

=item * L<Langertha::ServerTool> - Provider-native server-side tool (web
search, file search, remote MCP, ...), pinned to its C<tool_wire_format>

=item * L<Langertha::ServerToolCall> - Record of a tool call the provider ran
itself, on L<Langertha::Response/server_tool_calls> (never on C<tool_calls>)

=item * L<Langertha::Content> / L<Langertha::Content::Image> -
Provider-agnostic vision input

=item * L<Langertha::ModelProbe> - Reads model-scoped capability facts
(C<image_input>) from a provider's own model metadata, for
L<Langertha::Role::Capabilities/probe_model_capabilities_f>

=item * L<Langertha::Manifest> - Provider manifest
(C</.well-known/langertha.json>) value object, parser and validator

=item * L<Langertha::Manifest::Builder> - Builds a L<Langertha::Manifest>
offline from configured engines, never copying a secret

=item * L<Langertha::RateLimit> - Normalized rate limit data from HTTP response headers

=item * L<Langertha::Moment> - Instant reported by a provider
(L<Langertha::Response/created>); a L<Time::Moment> subclass that keeps the
sub-seconds and numifies to the Unix epoch

=item * L<Langertha::Stream> - Iterator over streaming chunks

=item * L<Langertha::Stream::Chunk> - A single chunk from a streaming
response (with optional C<tool_calls> for engines that emit them mid-stream)

=item * L<Langertha::Request::HTTP> - Internal HTTP request object

=back

=head2 Streaming

All engines that implement L<Langertha::Role::Chat> support streaming. There
are several ways to consume a stream:

B<Synchronous with callback:>

    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

B<Synchronous with iterator (L<Langertha::Stream>):>

    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

B<Async with Future (traditional):>

    my $future = $engine->simple_chat_f('Hello');
    my $response = $future->get;

    my $future = $engine->simple_chat_stream_f('Tell me a story');
    my ($content, $chunks) = $future->get;

B<Async with Future::AsyncAwait (recommended):>

    use Future::AsyncAwait;

    async sub chat_with_ai {
        my ($engine) = @_;
        my $response = await $engine->simple_chat_f('Hello');
        say "AI says: $response";
        return $response;
    }

    async sub stream_chat {
        my ($engine) = @_;
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            'Tell me a story',
        );
        say "\nReceived ", scalar(@$chunks), " chunks";
        return $content;
    }

    chat_with_ai($engine)->get;
    stream_chat($engine)->get;

The C<_f> methods pick their HTTP backend through L<Langertha::Role::AsyncHTTP>:
an injected C<_async_http> client, else L<Net::Async::HTTP> on an L<IO::Async>
loop (both loaded lazily only when you call them), else a synchronous
L<LWP::UserAgent> fallback. The fallback keeps every C<_f> method working and
returning a L<Future>, but blocking and sequential, with no concurrency; install
L<Net::Async::HTTP> + L<IO::Async> for real async. See C<examples/async_await_example.pl> for
complete working examples.

B<Using with Mojolicious:>

    use Mojo::Base -strict;
    use Future::Mojo;
    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'a small fast model from your provider',
    );

    my $future = $openai->simple_chat_stream_realtime_f(
        sub { print shift->content },
        'Hello!',
    );
    $future->on_done(sub {
        my ($content, $chunks) = @_;
        say "Done: $content";
    });
    Mojo::IOLoop->start;

=head2 Response Metadata

C<simple_chat> returns L<Langertha::Response> objects that stringify to text
content (backward compatible) but carry full metadata:

    my $r = $engine->simple_chat('Hello!');
    print $r;                    # prints the text
    say $r->model;               # actual model used
    say $r->prompt_tokens;       # input tokens
    say $r->completion_tokens;   # output tokens
    say $r->total_tokens;        # total
    say $r->finish_reason;       # stop, end_turn, tool_calls, ...
    say $r->thinking;            # chain-of-thought (if available)

=head2 Rate Limiting

Rate limit information from HTTP response headers is extracted automatically
into L<Langertha::RateLimit> objects. Available per-response and on the engine:

    if ($r->has_rate_limit) {
        say $r->requests_remaining;
        say $r->tokens_remaining;
        say $r->rate_limit->requests_reset;
    }

    # Engine always reflects the latest response
    say $engine->rate_limit->requests_remaining
        if $engine->has_rate_limit;

Supported: OpenAI, Groq, Cerebras, OpenRouter, Replicate, HuggingFace
(C<x-ratelimit-*>) and Anthropic (C<anthropic-ratelimit-*>).

=head2 MCP Tool Calling

Integrates with any L<Net::Async::MCP>-compatible client (for example a
L<Net::Async::MCP> client as used by the C<langertha-raider> distribution)
for automatic multi-round tool calling:

    my $engine = Langertha::Engine::OpenAI->new(
        api_key     => $ENV{OPENAI_API_KEY},
        mcp_servers => [$mcp],
    );

    my $response = await $engine->chat_with_tools_f('Search for Perl modules');

Works with all engines that support tool calling. See L<Langertha::Role::Tools>.

=head2 Raider (Autonomous Agent)

L<Langertha::Raider> is a stateful agent with conversation history, MCP tool
calling, context compression, session history, and a plugin system. It ships
in the separate C<langertha-raider> distribution; install it to use the agent
and the C<use Langertha qw( Raider )> sugar:

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        mission => 'You are a code explorer.',
    );

    my $r1 = await $raider->raid_f('What files are in lib/?');
    my $r2 = await $raider->raid_f('Read the main module.');

=head2 Langfuse Observability

L<Langfuse|https://langfuse.com/> observability comes in two complementary
flavours. Both read C<LANGFUSE_PUBLIC_KEY>, C<LANGFUSE_SECRET_KEY> and the
optional C<LANGFUSE_URL> from the environment, and both stay inactive until
that key pair is set.

=over 4

=item * B<Engine level> -- L<Langertha::Role::Langfuse> is composed by
L<Langertha::Role::Chat>, so every chat engine carries it. It auto-instruments
the synchronous C<simple_chat> call and offers C<langfuse_trace>,
C<langfuse_span> and C<langfuse_generation> for instrumenting anything else.
L<Langertha::Raider> uses those to trace raids, iterations and tool calls.

=item * B<Plugin level> -- L<Langertha::Plugin::Langfuse> attaches to any
L<Langertha::Role::PluginHost>, which is what the wrapper classes
L<Langertha::Chat>, L<Langertha::Embedder> and L<Langertha::ImageGen> are (as
is L<Langertha::Raider>). It needs no engine-level configuration and covers
the embedding and image-generation calls the engine role does not see:

    my $chat = Langertha::Chat->new(
        engine  => $engine,
        plugins => ['Langfuse'],
    );

=back

Transcription-only engines (L<Langertha::Engine::Whisper> and other
L<Langertha::Engine::TranscriptionBase> subclasses) compose neither
L<Langertha::Role::Chat> nor a plugin host, and so are not instrumented.

=head2 Extensions

The C<LangerthaX> namespace is reserved for third-party extensions. See
L<LangerthaX>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
