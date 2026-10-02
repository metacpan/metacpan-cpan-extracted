#!/usr/bin/env perl
# ABSTRACT: prompt_cache_key is advertised and emitted only where the server honors it

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Module::Runtime qw( use_module );

use Langertha::Manifest::Builder;

# Why (karr k200, ADR 0009 Update): prompt_cache_key is OpenAI's cache-routing
# hint. Engine::OpenAIBase used to advertise it for every subclass, so the
# self-hosted servers (vLLM, SGLang, llama.cpp, Ollama's /v1, LM Studio's /v1)
# claimed it too -- and the provider manifest (ADR 0029) published the claim on
# their model entries. None of those servers reads the field on
# /v1/chat/completions (vLLM and SGLang drop unknown fields, Ollama's Go struct
# has no such field, llama.cpp and LM Studio document their own parameter sets
# without it); their prefix-cache levers are the Runtime::Knobs (ADR 0012).
# A caller who trusts supports('prompt_cache_key') would believe it steers a
# cache that is never steered. The capability and the wire must agree: where
# the flag is cleared, the field is not sent either.

delete @ENV{ grep { /\ALANGERTHA_/ } keys %ENV };

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my @NOT_HONORED = qw( vLLM VLLMHook SGLang LlamaCpp OllamaOpenAI LMStudioOpenAI );
# Documented to read prompt_cache_key on chat completions.
my @HONORED     = qw( OpenAI OpenRouter );
# No documentary evidence either way: left as the base advertises it (k200
# report). Pinned so a blanket clear on OpenAIBase cannot slip in unnoticed.
my @UNVERIFIED  = qw(
  DeepSeek Groq XAI Mistral MiniMax Moonshot NousResearch Cerebras Replicate
  HuggingFace AKIOpenAI TSystems Scaleway Hetzner
);

sub engine {
  my ($name) = @_;
  return use_module("Langertha::Engine::$name")->new(
    api_key => 'k', url => 'http://h.example:1/v1', model => 'm', @_[ 1 .. $#_ ] );
}

sub body_of {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_request( [ { role => 'user', content => 'hi' } ], %extra )->content );
}

subtest 'capability' => sub {
  ok !engine($_)->supports('prompt_cache_key'), "$_ does not advertise prompt_cache_key"
    for @NOT_HONORED;
  ok engine($_)->supports('prompt_cache_key'), "$_ advertises prompt_cache_key"
    for @HONORED, @UNVERIFIED;
  ok !engine($_)->supports('prompt_cache'), "$_ still has no cache enable flag"
    for @NOT_HONORED, @HONORED;
};

subtest 'wire agrees with the capability' => sub {
  for my $name (@NOT_HONORED) {
    my $attr = body_of( engine( $name, prompt_cache_key => 'route-x' ) );
    ok !exists $attr->{prompt_cache_key}, "$name: engine attribute is not sent";
    my $ctl = body_of( engine($name), controls => { prompt_cache_key => 'route-y' } );
    ok !exists $ctl->{prompt_cache_key}, "$name: per-request control is not sent";
    my $stream = $json->decode( engine( $name, prompt_cache_key => 'route-x' )
      ->chat_stream_request( [ { role => 'user', content => 'hi' } ] )->content );
    ok !exists $stream->{prompt_cache_key}, "$name: streaming body does not carry it";
  }
  for my $name (@HONORED) {
    is body_of( engine( $name, prompt_cache_key => 'route-x' ) )->{prompt_cache_key},
      'route-x', "$name: engine attribute is sent";
    is body_of( engine($name), controls => { prompt_cache_key => 'route-y' } )->{prompt_cache_key},
      'route-y', "$name: per-request control is sent";
  }
};

# The gate covers prompt_cache_key only. cache_wire_format is a public,
# constructor-settable attribute: an OpenAI-family engine told to speak the
# Anthropic cache dialect (an OpenAI-compatible proxy in front of Claude) must
# keep sending cache_control even though the family clears the prompt_cache
# flag (k200 review I1).
subtest 'cache_wire_format override still sends cache_control' => sub {
  for my $name (@HONORED) {
    my $body = body_of( engine( $name, cache_wire_format => 'anthropic', prompt_cache => 1 ) );
    is_deeply $body->{cache_control}, { type => 'ephemeral' },
      "$name with cache_wire_format => 'anthropic' sends cache_control";
  }
};

subtest 'manifest does not publish it for the corrected engines' => sub {
  for my $name (@NOT_HONORED) {
    my $m = Langertha::Manifest::Builder->from_engine( engine($name), models => ['m'] );
    ok !$m->models->[0]->supports('prompt_cache_key'), "$name model entry: no prompt_cache_key";
  }
  for my $name (@HONORED) {
    my $m = Langertha::Manifest::Builder->from_engine( engine($name), models => ['m'] );
    ok $m->models->[0]->supports('prompt_cache_key'), "$name model entry: prompt_cache_key";
  }
};

done_testing;
