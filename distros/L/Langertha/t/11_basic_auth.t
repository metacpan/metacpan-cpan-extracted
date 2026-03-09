#!/usr/bin/env perl
# ABSTRACT: Test HTTP Basic Authentication via URL userinfo

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use MIME::Base64;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# ======================================================================
# Basic auth via user:pass@host in URL
# ======================================================================

# --- vLLM: self-hosted, no api_key, basic auth from URL ---

use Langertha::Engine::vLLM;

{
  my $v = Langertha::Engine::vLLM->new(
    url => 'http://myuser:mypass@localhost:8000/v1',
  );
  my $req = $v->chat('hello');

  # URL should NOT contain credentials
  unlike($req->uri, qr/myuser/, 'vLLM: userinfo stripped from request URI');
  unlike($req->uri, qr/mypass/, 'vLLM: password stripped from request URI');
  like($req->uri, qr{^http://localhost:8000/v1/}, 'vLLM: clean URL preserved');
  like($req->uri, qr{/chat/completions$}, 'vLLM: endpoint path correct');

  # Authorization header should be Basic
  my $auth = $req->header('Authorization');
  ok($auth, 'vLLM: Authorization header is set');
  like($auth, qr/^Basic /, 'vLLM: Authorization is Basic scheme');

  # Verify credentials
  my ($scheme, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'myuser:mypass',
    'vLLM: Basic auth credentials are correct');
}

# --- LlamaCpp: same pattern, self-hosted ---

use Langertha::Engine::LlamaCpp;

{
  my $l = Langertha::Engine::LlamaCpp->new(
    url => 'https://admin:secret123@gpu-server.local:8080/v1',
  );
  my $req = $l->chat('hello');

  unlike($req->uri, qr/admin/, 'LlamaCpp: userinfo stripped from URI');
  like($req->uri, qr{^https://gpu-server.local:8080/v1/}, 'LlamaCpp: clean URL');

  my $auth = $req->header('Authorization');
  like($auth, qr/^Basic /, 'LlamaCpp: Basic auth set');
  my (undef, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'admin:secret123',
    'LlamaCpp: credentials decoded correctly');
}

# --- OllamaOpenAI: self-hosted with basic auth ---

use Langertha::Engine::OllamaOpenAI;

{
  my $o = Langertha::Engine::OllamaOpenAI->new(
    url   => 'http://user:pass@ollama.internal:11434/v1',
    model => 'llama3.3',
  );
  my $req = $o->chat('hello');

  unlike($req->uri, qr/user:pass/, 'OllamaOpenAI: userinfo stripped');
  like($req->uri, qr{^http://ollama.internal:11434/v1/}, 'OllamaOpenAI: clean URL');

  my $auth = $req->header('Authorization');
  like($auth, qr/^Basic /, 'OllamaOpenAI: Basic auth set');
  my (undef, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'user:pass',
    'OllamaOpenAI: credentials correct');
}

# --- LMStudio native: self-hosted with basic auth ---

use Langertha::Engine::LMStudio;

{
  my $lm = Langertha::Engine::LMStudio->new(
    url => 'http://alice:secret@lmstudio.internal:1234',
    model => 'test-model',
  );
  my $req = $lm->chat('hello');

  unlike($req->uri, qr/alice:secret/, 'LMStudio: userinfo stripped');
  like($req->uri, qr{^http://lmstudio\.internal:1234/api/v1/chat$}, 'LMStudio: native endpoint path');

  my $auth = $req->header('Authorization');
  like($auth, qr/^Basic /, 'LMStudio: Basic auth set');
  my (undef, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'alice:secret',
    'LMStudio: credentials correct');
}

# --- LMStudioAnthropic: self-hosted with basic auth ---

use Langertha::Engine::LMStudioAnthropic;

{
  my $lm = Langertha::Engine::LMStudioAnthropic->new(
    url => 'http://alice:secret@lmstudio.internal:1234',
    model => 'test-model',
  );
  my $req = $lm->chat('hello');

  unlike($req->uri, qr/alice:secret/, 'LMStudioAnthropic: userinfo stripped');
  like($req->uri, qr{^http://lmstudio\.internal:1234/v1/messages$}, 'LMStudioAnthropic: endpoint path');

  my $auth = $req->header('Authorization');
  like($auth, qr/^Basic /, 'LMStudioAnthropic: Basic auth set');
  my (undef, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'alice:secret',
    'LMStudioAnthropic: credentials correct');

  is($req->header('x-api-key'), 'lmstudio', 'LMStudioAnthropic: x-api-key header set');
}

# --- LMStudioOpenAI: self-hosted with basic auth ---

use Langertha::Engine::LMStudioOpenAI;

{
  my $lm = Langertha::Engine::LMStudioOpenAI->new(
    url => 'http://alice:secret@lmstudio.internal:1234/v1',
    model => 'test-model',
  );
  my $req = $lm->chat('hello');

  unlike($req->uri, qr/alice:secret/, 'LMStudioOpenAI: userinfo stripped');
  like($req->uri, qr{^http://lmstudio\.internal:1234/v1/chat/completions$}, 'LMStudioOpenAI: endpoint path');

  # Default LMStudioOpenAI api_key=lmstudio overrides Basic auth
  my $auth = $req->header('Authorization');
  is($auth, 'Bearer lmstudio', 'LMStudioOpenAI: default Bearer auth takes precedence over Basic');
}

# --- Ollama native: non-OpenAI engine also supports basic auth ---

use Langertha::Engine::Ollama;

{
  my $o = Langertha::Engine::Ollama->new(
    url   => 'http://admin:ollama@localhost:11434',
    model => 'llama3.3',
  );
  my $req = $o->chat('hello');

  unlike($req->uri, qr/admin:ollama/, 'Ollama native: userinfo stripped');
  like($req->uri, qr{^http://localhost:11434/}, 'Ollama native: clean URL');

  my $auth = $req->header('Authorization');
  like($auth, qr/^Basic /, 'Ollama native: Basic auth set');
  my (undef, $encoded) = split(' ', $auth, 2);
  is(decode_base64($encoded), 'admin:ollama',
    'Ollama native: credentials correct');
}

# ======================================================================
# Cloud engine with api_key: Bearer overwrites Basic auth
# ======================================================================

# When both userinfo AND api_key are present, Bearer wins because
# update_request() runs after basic auth is set. This is expected
# behavior — cloud engines use Bearer tokens, not basic auth.

use Langertha::Engine::OpenAI;

{
  my $o = Langertha::Engine::OpenAI->new(
    url     => 'http://user:pass@custom-proxy.example.com/v1',
    api_key => 'sk-test-key',
  );
  my $req = $o->chat('hello');

  unlike($req->uri, qr/user:pass/, 'OpenAI+proxy: userinfo stripped from URI');
  like($req->uri, qr{^http://custom-proxy.example.com/v1/}, 'OpenAI+proxy: clean URL');

  # Bearer token takes precedence
  my $auth = $req->header('Authorization');
  is($auth, 'Bearer sk-test-key',
    'OpenAI+proxy: Bearer auth takes precedence over Basic');
}

# ======================================================================
# URL without userinfo: no Basic auth header
# ======================================================================

{
  my $v = Langertha::Engine::vLLM->new(
    url => 'http://localhost:8000/v1',
  );
  my $req = $v->chat('hello');

  is($req->header('Authorization'), undef,
    'vLLM without userinfo: no Authorization header');
}

# ======================================================================
# Edge case: userinfo with only user (no password)
# ======================================================================

{
  my $v = Langertha::Engine::vLLM->new(
    url => 'http://onlyuser@localhost:8000/v1',
  );
  my $req = $v->chat('hello');

  # No basic auth should be set (requires both user and pass)
  is($req->header('Authorization'), undef,
    'URL with user but no password: no Basic auth set');
  unlike($req->uri, qr/onlyuser/, 'userinfo still stripped from URI');
}

done_testing;
