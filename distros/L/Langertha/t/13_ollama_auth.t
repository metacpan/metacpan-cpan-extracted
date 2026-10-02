#!/usr/bin/env perl
# ABSTRACT: Test the optional Bearer auth path of the Ollama engines

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::Ollama;
use Langertha::Engine::OllamaOpenAI;

# Ollama Cloud (https://ollama.com) serves the same native dialect as a local
# server -- POST /api/chat, GET /api/tags, verified live 2026-08-17 -- but
# answers HTTP 401 {"error":"Unauthorized"} without
# `Authorization: Bearer <key>`. The key therefore has to exist, and it has to
# stay optional: the normal case is an unauthenticated local server at
# http://localhost:11434, which must never see an Authorization header and
# must never croak for a missing key. (karr #87)

my $local_url = 'http://test.invalid:11434';
my $cloud_url = 'https://ollama.com';

# ======================================================================
# Native engine: no key configured -> no header, no croak
# ======================================================================

{
  delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

  my $o = Langertha::Engine::Ollama->new( url => $local_url, model => 'llama3.3' );
  is($o->api_key, undef, 'Ollama: api_key undef without env or attribute');

  my @requests = (
    [ chat   => $o->chat('hello') ],
    [ tags   => $o->tags ],
    [ ps     => $o->ps ],
    [ stream => $o->chat_stream_request([{ role => 'user', content => 'hello' }]) ],
  );
  for my $case (@requests) {
    my ( $name, $req ) = @$case;
    is($req->header('Authorization'), undef,
      "Ollama: keyless $name request has no Authorization header");
  }
}

# ======================================================================
# Native engine: key configured -> exactly one Bearer header
# ======================================================================

{
  local $ENV{LANGERTHA_OLLAMA_API_KEY} = 'env-ollama-key';

  my $o = Langertha::Engine::Ollama->new( url => $cloud_url, model => 'gpt-oss:120b' );
  is($o->api_key, 'env-ollama-key', 'Ollama: api_key read from LANGERTHA_OLLAMA_API_KEY');

  my $req = $o->chat('hello');
  is($req->uri, $cloud_url.'/api/chat', 'Ollama: cloud keeps the native /api/chat path');
  my @auth = $req->header('Authorization');
  is(scalar(@auth), 1, 'Ollama: exactly one Authorization header');
  is($auth[0], 'Bearer env-ollama-key', 'Ollama: Bearer header carries the key');

  # The GET endpoints authenticate too -- /api/tags is how Ollama Cloud
  # advertises its model list.
  is($o->tags->header('Authorization'), 'Bearer env-ollama-key',
    'Ollama: tags request carries the Bearer header');
}

{
  local $ENV{LANGERTHA_OLLAMA_API_KEY} = 'env-ollama-key';

  my $o = Langertha::Engine::Ollama->new(
    url     => $cloud_url,
    model   => 'gpt-oss:120b',
    api_key => 'attribute-key',
  );
  is($o->api_key, 'attribute-key', 'Ollama: explicit api_key beats the environment');
  is($o->chat('hello')->header('Authorization'), 'Bearer attribute-key',
    'Ollama: explicit api_key reaches the wire');
}

# ======================================================================
# Native engine: the Bearer path must not break URL userinfo basic auth
# ======================================================================

{
  delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

  my $o = Langertha::Engine::Ollama->new(
    url   => 'http://admin:ollama@test.invalid:11434',
    model => 'llama3.3',
  );
  like($o->chat('hello')->header('Authorization'), qr/^Basic /,
    'Ollama: keyless update_request leaves URL basic auth intact');
}

{
  my $o = Langertha::Engine::Ollama->new(
    url     => 'http://admin:ollama@test.invalid:11434',
    model   => 'llama3.3',
    api_key => 'attribute-key',
  );
  is($o->chat('hello')->header('Authorization'), 'Bearer attribute-key',
    'Ollama: api_key takes precedence over URL basic auth');
}

# ======================================================================
# openai() carries the key over to the OpenAI-compatible sub-engine
# ======================================================================

{
  delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

  my $oai = Langertha::Engine::Ollama->new( url => $local_url, model => 'llama3.3' )->openai;
  is($oai->api_key, undef, 'Ollama->openai: no key without env or attribute');
  is($oai->chat('hello')->header('Authorization'), undef,
    'Ollama->openai: keyless request has no Authorization header');
}

{
  delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

  my $oai = Langertha::Engine::Ollama->new(
    url     => $cloud_url,
    model   => 'gpt-oss:120b',
    api_key => 'attribute-key',
  )->openai;
  is($oai->url, $cloud_url.'/v1', 'Ollama->openai: cloud /v1 endpoint');
  is($oai->api_key, 'attribute-key', 'Ollama->openai: carries the api_key');
  is($oai->chat('hello')->header('Authorization'), 'Bearer attribute-key',
    'Ollama->openai: Bearer header carries the key');
}

# ======================================================================
# OllamaOpenAI standalone: same optional key, from the same env var
# ======================================================================

{
  delete local $ENV{LANGERTHA_OLLAMA_API_KEY};

  my $oai = Langertha::Engine::OllamaOpenAI->new(
    url   => $local_url.'/v1',
    model => 'llama3.3',
  );
  is($oai->api_key, undef, 'OllamaOpenAI: api_key undef without env or attribute');
  is($oai->chat('hello')->header('Authorization'), undef,
    'OllamaOpenAI: keyless request has no Authorization header');
}

{
  local $ENV{LANGERTHA_OLLAMA_API_KEY} = 'env-ollama-key';

  my $oai = Langertha::Engine::OllamaOpenAI->new(
    url   => $cloud_url.'/v1',
    model => 'gpt-oss:120b',
  );
  is($oai->api_key, 'env-ollama-key',
    'OllamaOpenAI: api_key read from LANGERTHA_OLLAMA_API_KEY');

  my $req = $oai->chat('hello');
  is($req->uri, $cloud_url.'/v1/chat/completions',
    'OllamaOpenAI: cloud keeps the /v1/chat/completions path');
  my @auth = $req->header('Authorization');
  is(scalar(@auth), 1, 'OllamaOpenAI: exactly one Authorization header');
  is($auth[0], 'Bearer env-ollama-key', 'OllamaOpenAI: Bearer header carries the key');
}

# ======================================================================
# Both engines advertise the key they read, neither requires it (karr #93)
# ======================================================================

is(Langertha::Engine::Ollama->api_key_env, 'LANGERTHA_OLLAMA_API_KEY',
  'Ollama advertises the env var it reads');
is(Langertha::Engine::Ollama->api_key_required, 0,
  'Ollama api_key_required is false (local server needs none)');
is(Langertha::Engine::OllamaOpenAI->api_key_env, 'LANGERTHA_OLLAMA_API_KEY',
  'OllamaOpenAI advertises the shared Ollama env var');
is(Langertha::Engine::OllamaOpenAI->api_key_required, 0,
  'OllamaOpenAI api_key_required is false (local server needs none)');

done_testing;
