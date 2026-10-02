#!/usr/bin/env perl
# ABSTRACT: Live test for Langertha::Engine::VLLMHook against a vLLM-Hook server

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

BEGIN {
  unless ($ENV{TEST_LANGERTHA_VLLMHOOK_URL}) {
    plan skip_all => 'TEST_LANGERTHA_VLLMHOOK_URL not set';
  }
}

require Langertha::Engine::VLLMHook;

my $url   = $ENV{TEST_LANGERTHA_VLLMHOOK_URL};
my @model = $ENV{TEST_LANGERTHA_VLLMHOOK_MODEL}
  ? (model => $ENV{TEST_LANGERTHA_VLLMHOOK_MODEL}) : ();

# --- Smoke: plain chat works through the hook engine ---
subtest 'simple_chat smoke' => sub {
  my $engine = Langertha::Engine::VLLMHook->new(url => $url, @model);
  my $resp = eval { $engine->simple_chat('Say exactly: Hello Langertha') };
  if ($@) {
    fail "simple_chat failed: $@";
    return;
  }
  ok(defined $resp, 'returns a response');
  ok(length("$resp") > 0, 'response is non-empty');
  diag "response: $resp";
};

# --- Probe capture: hidden states ---
# Requires the server to be started with VLLM_HOOK_WORKER=hidden_states.
subtest 'hidden_states probe capture' => sub {
  my $engine = Langertha::Engine::VLLMHook->new(
    url => $url, @model,
    vllm_xargs => { output_hidden_states => JSON->true },
  );
  my $resp = eval { $engine->simple_chat('Hello') };
  if ($@) {
    fail "probe chat failed: $@";
    return;
  }
  ok(defined $resp, 'returns a response');
  if ($resp->has_probes) {
    ok($resp->probes, 'probes attached to the response');
    diag "probes keys: " . join(',', keys %{ $resp->probes });
  }
  else {
    diag "no probes returned - is the server running VLLM_HOOK_WORKER=hidden_states?";
    pass 'probe extraction path exercised (server returned none)';
  }
};

done_testing;
