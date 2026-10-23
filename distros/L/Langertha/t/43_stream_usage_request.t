#!/usr/bin/env perl
# ABSTRACT: chat_stream_request asks for the stream's token usage where supports('stream_usage') says the wire takes stream_options

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use LWP::Protocol;
use Module::Runtime qw( use_module );

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::vLLM;
use Langertha::Engine::SGLang;
use Langertha::Engine::Mistral;
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer );

# On the OpenAI chat wire a stream reports its token usage only when the
# request carries stream_options.include_usage; the usage then arrives as a
# last frame with an empty choices list, which parse_stream_chunk already reads
# (karr k298). Langertha never sent the option, so every streamed answer --
# including the ones langertha-knarr routes to an engine -- came without
# usage. Some OpenAI-compatible servers reject a field they do not know, so the
# option goes on the body only where the engine composes Role::StreamUsage
# (ADR 0038). A stream_options the caller passes is the caller's wire intent
# and replaces the engine's.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $msgs = [ { role => 'user', content => 'hi' } ];

sub body_of {
  my ( $engine, $builder, %extra ) = @_;
  return $json->decode( $engine->$builder( $msgs, %extra )->content );
}

my %with = (
  OpenAI  => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' ) },
  vLLM    => sub { Langertha::Engine::vLLM->new( url => 'http://h.example:1/v1', model => 'm' ) },
  SGLang  => sub { Langertha::Engine::SGLang->new( url => 'http://h.example:1/v1', model => 'm' ) },
  Virtual => sub { Langertha::Engine::Virtual->new( rules => [ 'hi' => 'hello' ], langfuse_enabled => 0 ) },
);

subtest 'an engine with stream_usage asks for the usage on the stream request' => sub {
  for my $name ( sort keys %with ) {
    my $engine = $with{$name}->();
    ok( $engine->supports('stream_usage'), "$name claims stream_usage" );
    my $body = body_of( $engine, 'chat_stream_request' );
    is_deeply( $body->{stream_options}, { include_usage => JSON->true },
      "$name: stream_options.include_usage is true" );
    ok( JSON::MaybeXS::is_bool( $body->{stream_options}{include_usage} ), "$name: ... as a JSON boolean" );
    ok( !exists body_of( $engine, 'chat_request' )->{stream_options},
      "$name: the non-streaming request carries no stream_options" );
  }
};

# The per-engine decision of ADR 0038: on only where the provider's API
# reference (or, for a self-hosted server, its request schema in the source)
# names stream_options.include_usage for chat completions. A flip here is a
# decision change and belongs in the ADR's table.
my %DECISION = (
  OpenAI         => 1, vLLM          => 1, VLLMHook  => 1, SGLang   => 1,
  Virtual        => 1, Mock          => 1, DeepSeek  => 1, XAI      => 1,
  Groq           => 1, OllamaOpenAI  => 1, LlamaCpp  => 1, Moonshot => 1,
  MiniMax        => 1, Scaleway      => 1, TSystems  => 1, HuggingFace => 1,
  Mistral        => 0, Cerebras      => 0, OpenRouter => 0, LMStudioOpenAI => 0,
  NousResearch   => 0, Hetzner       => 0, AKIOpenAI => 0, Replicate => 0,
  OpenAIResponses => 0,
  # Wires with their own chat_stream_request: no stream_options at all.
  Anthropic => 0, MiniMaxAnthropic => 0, Gemini => 0, Ollama => 0, LMStudio => 0,
  Perplexity => 0, AKI => 0,
);

subtest 'every engine has its stream_usage decision' => sub {
  for my $name ( sort keys %DECISION ) {
    my $class = use_module("Langertha::Engine::$name");
    my $engine = $class->new( api_key => 'k', url => 'http://h.example:1/v1', model => 'm',
      ( $class->isa('Langertha::Engine::Virtual') ? ( rules => [ 'hi' => 'hello' ] ) : () ),
      langfuse_enabled => 0 );
    is( $engine->supports('stream_usage') ? 1 : 0, $DECISION{$name}, "$name: stream_usage $DECISION{$name}" );
    next unless $engine->does('Langertha::Role::OpenAICompatible') && $engine->supports('streaming');
    is( exists body_of( $engine, 'chat_stream_request' )->{stream_options} ? 1 : 0, $DECISION{$name},
      "$name: stream_options on the stream request follows the flag" );
  }
};

subtest 'an engine without stream_usage sends no stream_options' => sub {
  my $engine = Langertha::Engine::Mistral->new( api_key => 'k', model => 'mistral-large-latest' );
  ok( !$engine->supports('stream_usage'), 'Mistral does not claim stream_usage' );
  ok( !exists body_of( $engine, 'chat_stream_request' )->{stream_options}, 'no stream_options on its stream request' );
  ok( $engine->supports('streaming'), '... though it streams' );
};

subtest 'OpenAIResponses inherits from OpenAI but its wire has no stream_options' => sub {
  my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' );
  ok( $engine->does('Langertha::Role::StreamUsage'), 'the role comes along from OpenAI' );
  ok( !$engine->supports('stream_usage'), '... but the flag is cleared' );
  ok( !$engine->supports('streaming'), '... as streaming is' );
};

subtest "the caller's stream_options wins" => sub {
  my $engine = $with{OpenAI}->();
  my $off = body_of( $engine, 'chat_stream_request', stream_options => { include_usage => JSON->false } );
  ok( !$off->{stream_options}{include_usage}, 'include_usage false stays false' );
  my $other = body_of( $engine, 'chat_stream_request', stream_options => { include_obfuscation => JSON->false } );
  is_deeply( $other->{stream_options}, { include_obfuscation => JSON->false },
    "a caller's stream_options replaces the engine's whole" );
  my $plain = body_of( Langertha::Engine::Mistral->new( api_key => 'k', model => 'm' ),
    'chat_stream_request', stream_options => { include_usage => JSON->true } );
  is_deeply( $plain->{stream_options}, { include_usage => JSON->true },
    'an engine without the flag passes the caller\'s stream_options through' );
};

subtest 'Virtual end to end: a stream without stream_options reports its usage' => sub {
  no warnings 'redefine';
  local *LWP::Protocol::create = sub { die "Langertha::Engine::Virtual opened a network protocol\n" };
  my $engine = Langertha::Engine::Virtual->new(
    rules => [ 'Hello' => answer( 'Hi there!', usage => { prompt_tokens => 4, completion_tokens => 6 } ) ],
    langfuse_enabled => 0,
  );
  my ( $content, $chunks ) = $engine->chat_stream_realtime_f(
    messages => [ { role => 'user', content => 'Hello' } ],
  )->get;
  is( $content, 'Hi there!', 'the text' );
  ok( $engine->requests->[-1]{body}{stream_options}{include_usage}, 'the request asked for the usage' );
  is_deeply( $engine->aggregate_usage($chunks), { prompt_tokens => 4, completion_tokens => 6, total_tokens => 10 },
    'aggregate_usage finds the prompt and completion tokens' );
  my $last = $chunks->[-1];
  ok( $last->has_usage && !$last->is_final, 'the usage is on a non-final chunk after the final one' );
  ok( $chunks->[-2]->is_final, '... the final chunk is the one before' );

  my ( undef, $opted_out ) = $engine->chat_stream_realtime_f(
    messages       => [ { role => 'user', content => 'Hello' } ],
    stream_options => { include_usage => JSON->false },
  )->get;
  is( $engine->aggregate_usage($opted_out), undef, 'include_usage false from the caller: no usage' );
};

done_testing;
