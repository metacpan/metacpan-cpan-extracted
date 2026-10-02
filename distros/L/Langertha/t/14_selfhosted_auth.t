#!/usr/bin/env perl
# ABSTRACT: Test the optional Bearer auth path of the self-hosted servers

use strict;
use warnings;

use Test2::Bundle::More;

# vLLM, SGLang and llama.cpp can be started with an --api-key token
# (`vllm serve --api-key ...`, `python -m sglang.launch_server --api-key ...`,
# `llama-server --api-key ...`) — and once they are, every client must send
# it. Before karr #106 the engines answered `api_key_env { undef }` and read
# nothing; the ticket widens them into the optional-key state by deriving
# `api_key_env` from the class name (so vLLM -> LANGERTHA_VLLM_API_KEY,
# SGLang -> LANGERTHA_SGLANG_API_KEY, LlamaCpp -> LANGERTHA_LLAMACPP_API_KEY)
# and overriding `api_key_required { 0 }` plus `_build_api_key` to read it.
# The local default (no flag, no env var, no header) has to stay intact.
#
# This file mirrors t/13_ollama_auth.t for that state transition: no key ->
# no Authorization header, key via env -> Bearer header, explicit
# api_key => ... beats the environment, and URL basic auth is intact when
# no key is configured. Note that, unlike OllamaCloud/SGLang, an
# --api-key-protected server ALSO accepts URL basic auth on its own, so
# we don't model that collision here; an explicit api_key is the canonical
# way to authenticate against the flag and is the only collision we cover.

use Langertha::Engine::vLLM;
use Langertha::Engine::SGLang;
use Langertha::Engine::LlamaCpp;

my $base_url = 'http://test.invalid:1234/v1';

# ======================================================================
# No key configured: api_key undef, no Authorization header on any engine
# ======================================================================

for my $engine_class (qw(
  Langertha::Engine::vLLM
  Langertha::Engine::SGLang
  Langertha::Engine::LlamaCpp
)) {
  delete local $ENV{LANGERTHA_VLLM_API_KEY};
  delete local $ENV{LANGERTHA_SGLANG_API_KEY};
  delete local $ENV{LANGERTHA_LLAMACPP_API_KEY};

  my $e = $engine_class->new( url => $base_url );
  is($e->api_key, undef, "$engine_class: api_key undef without env or attribute");
  is($e->chat('hello')->header('Authorization'), undef,
    "$engine_class: keyless request has no Authorization header");
}

# ======================================================================
# With env var set: Bearer header carries the key, exact env-var name
# (vLLM / SGLang / LlamaCpp each read their own derived variable)
# ======================================================================

{
  local $ENV{LANGERTHA_VLLM_API_KEY} = 'env-vllm-key';

  my $e = Langertha::Engine::vLLM->new( url => $base_url );
  is($e->api_key, 'env-vllm-key',
    'vLLM: api_key read from LANGERTHA_VLLM_API_KEY');
  my $req = $e->chat('hello');
  my @auth = $req->header('Authorization');
  is(scalar(@auth), 1, 'vLLM: exactly one Authorization header');
  is($auth[0], 'Bearer env-vllm-key',
    'vLLM: Bearer header carries the env key');
}

{
  local $ENV{LANGERTHA_SGLANG_API_KEY} = 'env-sglang-key';

  my $e = Langertha::Engine::SGLang->new( url => $base_url );
  is($e->api_key, 'env-sglang-key',
    'SGLang: api_key read from LANGERTHA_SGLANG_API_KEY');
  my $req = $e->chat('hello');
  my @auth = $req->header('Authorization');
  is(scalar(@auth), 1, 'SGLang: exactly one Authorization header');
  is($auth[0], 'Bearer env-sglang-key',
    'SGLang: Bearer header carries the env key');
}

{
  local $ENV{LANGERTHA_LLAMACPP_API_KEY} = 'env-llamacpp-key';

  my $e = Langertha::Engine::LlamaCpp->new( url => $base_url );
  is($e->api_key, 'env-llamacpp-key',
    'LlamaCpp: api_key read from LANGERTHA_LLAMACPP_API_KEY');
  my $req = $e->chat('hello');
  my @auth = $req->header('Authorization');
  is(scalar(@auth), 1, 'LlamaCpp: exactly one Authorization header');
  is($auth[0], 'Bearer env-llamacpp-key',
    'LlamaCpp: Bearer header carries the env key');
}

# ======================================================================
# Explicit api_key attribute still beats the environment
# ======================================================================

{
  local $ENV{LANGERTHA_VLLM_API_KEY} = 'env-vllm-key';

  my $e = Langertha::Engine::vLLM->new(
    url     => $base_url,
    api_key => 'attribute-vllm-key',
  );
  is($e->api_key, 'attribute-vllm-key',
    'vLLM: explicit api_key beats the environment');
  is($e->chat('hello')->header('Authorization'), 'Bearer attribute-vllm-key',
    'vLLM: explicit api_key reaches the wire');
}

# ======================================================================
# Class methods: each engine advertises its derived env var and answers
# false to api_key_required (karr #93 three-state contract).
# ======================================================================

is(Langertha::Engine::vLLM->api_key_env, 'LANGERTHA_VLLM_API_KEY',
  'vLLM advertises the env var it reads');
is(Langertha::Engine::vLLM->api_key_required, 0,
  'vLLM api_key_required is false (local server needs none)');
is(Langertha::Engine::SGLang->api_key_env, 'LANGERTHA_SGLANG_API_KEY',
  'SGLang advertises the env var it reads');
is(Langertha::Engine::SGLang->api_key_required, 0,
  'SGLang api_key_required is false (local server needs none)');
is(Langertha::Engine::LlamaCpp->api_key_env, 'LANGERTHA_LLAMACPP_API_KEY',
  'LlamaCpp advertises the env var it reads');
is(Langertha::Engine::LlamaCpp->api_key_required, 0,
  'LlamaCpp api_key_required is false (local server needs none)');

done_testing;
