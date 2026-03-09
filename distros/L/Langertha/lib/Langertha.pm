package Langertha;
# ABSTRACT: The clan of fierce vikings with 🪓 and 🛡️ to AId your rAId
our $VERSION = '0.305';
use utf8;
use strict;
use warnings;

use Import::Into;
use Module::Runtime qw( use_module );

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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha - The clan of fierce vikings with 🪓 and 🛡️ to AId your rAId

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    my $system_prompt = 'You are a helpful assistant.';

    # Local models via Ollama
    use Langertha::Engine::Ollama;

    my $ollama = Langertha::Engine::Ollama->new(
        url           => 'http://127.0.0.1:11434',
        model         => 'llama3.1',
        system_prompt => $system_prompt,
    );
    print $ollama->simple_chat('Do you wanna build a snowman?');

    # OpenAI
    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key       => $ENV{OPENAI_API_KEY},
        model         => 'gpt-4o-mini',
        system_prompt => $system_prompt,
    );
    print $openai->simple_chat('Do you wanna build a snowman?');

    # Anthropic Claude
    use Langertha::Engine::Anthropic;

    my $claude = Langertha::Engine::Anthropic->new(
        api_key => $ENV{ANTHROPIC_API_KEY},
        model   => 'claude-sonnet-4-6',
    );
    print $claude->simple_chat('Generate Perl Moose classes to represent GeoJSON data.');

    # Google Gemini
    use Langertha::Engine::Gemini;

    my $gemini = Langertha::Engine::Gemini->new(
        api_key => $ENV{GEMINI_API_KEY},
        model   => 'gemini-2.5-flash',
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

=item * B<23 engines> -- unified API across cloud and local LLM providers

=item * B<Chat, streaming, embeddings, transcription, image generation>

=item * B<MCP tool calling> -- automatic multi-round tool loops via L<Net::Async::MCP>

=item * B<Raider> -- autonomous agent with history, compression, and plugins

=item * B<Response metadata> -- token usage, model, timing, rate limits

=item * B<Async/await> via L<Future::AsyncAwait>, sync via L<LWP::UserAgent>

=item * B<Langfuse observability> -- traces, generations, and tool spans

=item * B<Dynamic model discovery> -- query provider APIs with caching

=item * B<Chain-of-thought> -- native extraction and C<E<lt>thinkE<gt>> tag filtering

=item * B<Plugin system> for extending Raider, Chat, Embedder, and ImageGen

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
function for applying plugins by short name.

C<use Langertha qw( Plugin )> imports L<Moose> and
L<Future::AsyncAwait>, and sets L<Langertha::Plugin> as superclass.

=head2 Engine Modules

=over 4

=item * L<Langertha::Engine::Anthropic> - Claude models (Sonnet, Opus, Haiku)

=item * L<Langertha::Engine::OpenAI> - GPT-4, GPT-4o, GPT-3.5, o1, embeddings

=item * L<Langertha::Engine::Ollama> - Local LLM hosting via L<https://ollama.com/>

=item * L<Langertha::Engine::Groq> - Fast inference API

=item * L<Langertha::Engine::Mistral> - Mistral AI models

=item * L<Langertha::Engine::DeepSeek> - DeepSeek models

=item * L<Langertha::Engine::MiniMax> - MiniMax AI models (M2.5, M2.1)

=item * L<Langertha::Engine::Gemini> - Google Gemini models (Flash, Pro)

=item * L<Langertha::Engine::vLLM> - vLLM inference server

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

=item * L<Langertha::Engine::Whisper> - OpenAI Whisper speech-to-text

=back

=head2 Roles

Roles provide composable functionality to engines:

=over 4

=item * L<Langertha::Role::Chat> - Synchronous and async chat methods

=item * L<Langertha::Role::HTTP> - HTTP request/response handling

=item * L<Langertha::Role::Streaming> - Streaming response processing

=item * L<Langertha::Role::JSON> - JSON encode/decode

=item * L<Langertha::Role::OpenAICompatible> - OpenAI-compatible API behaviour

=item * L<Langertha::Role::SystemPrompt> - System prompt attribute

=item * L<Langertha::Role::Temperature> - Temperature parameter

=item * L<Langertha::Role::ResponseSize> - Max response size parameter

=item * L<Langertha::Role::ResponseFormat> - Response format (JSON mode)

=item * L<Langertha::Role::ContextSize> - Context window size parameter

=item * L<Langertha::Role::Seed> - Deterministic seed parameter

=item * L<Langertha::Role::Models> - Model listing

=item * L<Langertha::Role::Embedding> - Embedding generation

=item * L<Langertha::Role::Transcription> - Audio transcription

=item * L<Langertha::Role::Tools> - Tool/function calling

=item * L<Langertha::Role::ImageGeneration> - Image generation

=item * L<Langertha::Role::KeepAlive> - Keep-alive duration for local models

=item * L<Langertha::Role::PluginHost> - Plugin system for wrapper classes and Raider

=item * L<Langertha::Role::Langfuse> - Langfuse observability integration (engine-level)

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

=item * L<Langertha::Response> - LLM response with content, usage, and rate limit metadata

=item * L<Langertha::RateLimit> - Normalized rate limit data from HTTP response headers

=item * L<Langertha::Stream> - Iterator over streaming chunks

=item * L<Langertha::Stream::Chunk> - A single chunk from a streaming response

=item * L<Langertha::Raider> - Autonomous agent with history and tool calling

=item * L<Langertha::Raider::Result> - Typed raid result (final, question, pause, abort)

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

The C<_f> methods use L<IO::Async> and L<Net::Async::HTTP> internally, loaded
lazily only when you call them. See C<examples/async_await_example.pl> for
complete working examples.

B<Using with Mojolicious:>

    use Mojo::Base -strict;
    use Future::Mojo;
    use Langertha::Engine::OpenAI;

    my $openai = Langertha::Engine::OpenAI->new(
        api_key => $ENV{OPENAI_API_KEY},
        model   => 'gpt-4o-mini',
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

Integrates with L<Net::Async::MCP> for automatic multi-round tool calling:

    my $engine = Langertha::Engine::OpenAI->new(
        api_key     => $ENV{OPENAI_API_KEY},
        mcp_servers => [$mcp],
    );

    my $response = await $engine->chat_with_tools_f('Search for Perl modules');

Works with all engines that support tool calling. See L<Langertha::Role::Tools>.

=head2 Raider (Autonomous Agent)

L<Langertha::Raider> is a stateful agent with conversation history, MCP tool
calling, context compression, session history, and a plugin system:

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        mission => 'You are a code explorer.',
    );

    my $r1 = await $raider->raid_f('What files are in lib/?');
    my $r2 = await $raider->raid_f('Read the main module.');

=head2 Langfuse Observability

Every engine has L<Langfuse|https://langfuse.com/> observability built in.
Set C<LANGFUSE_PUBLIC_KEY> and C<LANGFUSE_SECRET_KEY> env vars to enable
auto-instrumented traces and generations. See L<Langertha::Role::Langfuse>.

=head2 Extensions

The C<LangerthaX> namespace is reserved for third-party extensions. See
L<LangerthaX>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
