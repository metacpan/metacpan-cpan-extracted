#!/usr/bin/env perl
# ABSTRACT: Test AKI.IO Anthropic-compatible request envelope, auth and models

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::AKIAnthropic;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Composition: the fifth consumer of Role::AnthropicCompatible (ADR 0013) ---

ok(Langertha::Engine::AKIAnthropic->isa('Langertha::Engine::AnthropicBase'), 'AKIAnthropic isa AnthropicBase');
ok(Langertha::Engine::AKIAnthropic->isa('Langertha::Engine::Remote'), 'AKIAnthropic isa Remote');
ok(!Langertha::Engine::AKIAnthropic->isa('Langertha::Engine::OpenAIBase'), 'AKIAnthropic is NOT OpenAIBase');
ok(Langertha::Engine::AKIAnthropic->does('Langertha::Role::AnthropicCompatible'), 'AKIAnthropic does AnthropicCompatible');
ok(Langertha::Engine::AKIAnthropic->does('Langertha::Role::Chat'), 'AKIAnthropic does Chat');
ok(Langertha::Engine::AKIAnthropic->does('Langertha::Role::Streaming'), 'AKIAnthropic does Streaming');
ok(Langertha::Engine::AKIAnthropic->does('Langertha::Role::Tools'), 'AKIAnthropic does Tools');
ok(Langertha::Engine::AKIAnthropic->does('Langertha::Role::StaticModels'), 'AKIAnthropic does StaticModels');

# --- Request envelope ---

my $aki = Langertha::Engine::AKIAnthropic->new(
  api_key => 'testkey',
  model => 'gemma4-26b',
  system_prompt => 'systemprompt',
  response_size => 2048,
  temperature => 0.5,
);

is($aki->url, 'https://aki.io/anthropic', 'AKIAnthropic url default stops at /anthropic');
is($aki->default_model, 'gpt-oss-120b', 'AKIAnthropic default_model matches the AKIOpenAI sibling (gpt-oss-120b; llama3-chat-8b EOL 2026-09-30, karr k132)');
is(Langertha::Engine::AKIAnthropic->api_key_env, 'LANGERTHA_AKI_API_KEY', 'AKIAnthropic advertises the shared AKI key env');

my $request = $aki->chat('testprompt');
is($request->method, 'POST', 'AKIAnthropic chat request is POST');
# AnthropicBase appends /v1/messages, so the composed URL must carry exactly
# one /v1 - the same double-/v1 404 trap as MiniMaxAnthropic (karr #18).
is($request->uri, 'https://aki.io/anthropic/v1/messages', 'AKIAnthropic composed URL has a single /v1');
unlike($request->uri, qr{/v1/v1/}, 'AKIAnthropic URL has no double /v1');

# AKI.IO documents the key as a RAW x-api-key value: "NO 'Bearer' prefix."
is($request->header('x-api-key'), 'testkey', 'AKIAnthropic sends the raw key as x-api-key');
ok(!$request->header('Authorization'), 'AKIAnthropic sends no Authorization header');
is($request->header('anthropic-version'), '2023-06-01', 'AKIAnthropic sends anthropic-version (accepted, not required, by AKI)');

is_deeply($json->decode($request->content), {
  max_tokens => 2048,
  temperature => 0.5,
  messages => [{
    content => 'testprompt',
    role => 'user',
  }],
  system => 'systemprompt',
  model => 'gemma4-26b',
}, 'AKIAnthropic request body is the Anthropic Messages envelope');

# --- max_tokens is required by the dialect; AKI documents 8192 as its default ---

{
  my $default_size = Langertha::Engine::AKIAnthropic->new(api_key => 'testkey');
  my $data = $json->decode($default_size->chat('testprompt')->content);
  is($data->{max_tokens}, 8192, 'AKIAnthropic defaults max_tokens to AKI-documented 8192');
  is($data->{model}, 'gpt-oss-120b', 'AKIAnthropic always sends an explicit model (unknown ids silently fall back)');
}

# --- API key resolution ---

{
  local $ENV{LANGERTHA_AKI_API_KEY} = 'env-key-12345';
  my $from_env = Langertha::Engine::AKIAnthropic->new;
  is($from_env->api_key, 'env-key-12345', 'AKIAnthropic reads api_key from LANGERTHA_AKI_API_KEY');
}

{
  delete local $ENV{LANGERTHA_AKI_API_KEY};
  my $no_key = Langertha::Engine::AKIAnthropic->new;
  eval { $no_key->api_key };
  like($@, qr/LANGERTHA_AKI_API_KEY/, 'AKIAnthropic croaks without an api_key');
}

# --- Static model list mirrors the documented AKI.IO ids ---

{
  my $models = Langertha::Engine::AKIAnthropic->new(api_key => 'testkey')->list_models;
  is(ref $models, 'ARRAY', 'list_models returns an ArrayRef without HTTP');
  my %ids = map { $_ => 1 } @$models;
  ok($ids{'gemma4-26b'}, 'model list carries gemma4-26b');
  ok($ids{'minimax-m2.5-230b'}, 'model list carries the silent-fallback model minimax-m2.5-230b');
  ok($ids{'gpt-oss-120b'}, 'model list carries the default model gpt-oss-120b (karr k132)');
  # Claude ids are accepted by the endpoint but silently answered by MiniMax
  # M2.5, so they must never be advertised as available here.
  ok(!(grep { /^claude/ } @$models), 'model list advertises no Claude model names');
}

done_testing;
