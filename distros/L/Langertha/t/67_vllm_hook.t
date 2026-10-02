#!/usr/bin/env perl
# ABSTRACT: Unit tests for Langertha::Engine::VLLMHook and its config loader

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::VLLMHook;
use Langertha::VLLMHook::Config;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Engine: url is required (inherited from vLLM) ---
eval { Langertha::Engine::VLLMHook->new() };
like($@, qr/url/, 'url is required');

# --- Engine: basic shape ---
{
  my $engine = Langertha::Engine::VLLMHook->new(url => 'http://test.invalid:8770/v1');
  ok($engine->isa('Langertha::Engine::vLLM'), 'extends vLLM');
  ok($engine->does('Langertha::Role::OpenAICompatible'), 'composes OpenAICompatible');
  is_deeply($engine->vllm_xargs, {}, 'vllm_xargs defaults to empty hash');
  is($engine->model, 'default', 'model defaults to default (single-model server)');
}

# --- chat_request: vllm_xargs lands at top level of the body ---
# NOTE: vLLM reads vllm_xargs from the body ROOT (the OpenAI Python SDK's
# extra_body wrapper is a client-only convenience that flattens into the root).
# Langertha encodes %extra straight into the JSON body, so we inject a
# top-level vllm_xargs key, NOT a literal extra_body wrapper.
{
  my $engine = Langertha::Engine::VLLMHook->new(
    url        => 'http://test.invalid:8770/v1',
    vllm_xargs => {
      output_qk  => { 6 => [9], 7 => [20], 8 => [1, 13] },  # nested -> JSON string
      hookq_mode => 'last_token',                           # scalar -> passthrough
    },
  );
  my $request = $engine->chat('Hello');
  my $body    = $json->decode($request->content);

  ok($body->{vllm_xargs}, 'vllm_xargs present at body top level');
  ok(!exists $body->{extra_body}, 'no literal extra_body wrapper on the wire');
  is($body->{vllm_xargs}{hookq_mode}, 'last_token', 'scalar xarg passes through');
  ok(!ref $body->{vllm_xargs}{output_qk}, 'nested xarg encoded to a JSON string');
  is_deeply(
    $json->decode($body->{vllm_xargs}{output_qk}),
    { 6 => [9], 7 => [20], 8 => [1, 13] },
    'nested xarg JSON-decodes back to the original structure',
  );
}

# --- worker_name derives a default xargs when vllm_xargs is empty ---
{
  my $engine = Langertha::Engine::VLLMHook->new(
    url         => 'http://test.invalid:8770/v1',
    worker_name => 'hidden_states',
  );
  is_deeply($engine->vllm_xargs, {}, 'explicit vllm_xargs still empty');
  my $body = $json->decode($engine->chat('Hello')->content);
  ok($body->{vllm_xargs}, 'worker_name produced a vllm_xargs');
  # output_hidden_states rides as a native JSON boolean (matches vLLM-Hook's own
  # HookClient, which sends Python True for the default hidden-states case).
  ok($body->{vllm_xargs}{output_hidden_states}, 'hidden_states default is truthy');
  is(
    $json->encode({ v => $body->{vllm_xargs}{output_hidden_states} }),
    '{"v":true}',
    'hidden_states default rendered as native JSON boolean true',
  );
}

# --- explicit vllm_xargs wins over worker_name ---
{
  my $engine = Langertha::Engine::VLLMHook->new(
    url         => 'http://test.invalid:8770/v1',
    worker_name => 'hidden_states',
    vllm_xargs  => { output_qk => { 1 => [2] } },
  );
  my $xargs = $engine->resolved_xargs;
  ok(exists $xargs->{output_qk}, 'explicit vllm_xargs takes precedence');
  ok(!exists $xargs->{output_hidden_states}, 'worker_name default suppressed');
}

# --- chat_response: probes are lifted from raw->{probes} ---
{
  my $engine = Langertha::Engine::VLLMHook->new(url => 'http://test.invalid:8770/v1');
  my $payload = {
    id      => 'chatcmpl-1',
    model   => 'default',
    choices => [{ message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' }],
    probes  => {
      hs_cache => { 'model.layers.1' => { hidden_states => [[0.1, 0.2], [0.3, 0.4]] } },
      config   => { mode => 'last_token' },
    },
  };
  my $http = HTTP::Response->new(
    200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode($payload),
  );
  my $resp = $engine->chat_response($http);
  is($resp->content, 'hi', 'content preserved');
  ok($resp->has_probes, 'probes attached');
  is_deeply($resp->probes->{config}, { mode => 'last_token' }, 'config block passed through');
  is_deeply(
    $resp->probes->{hs_cache}{'model.layers.1'}{hidden_states},
    [[0.1, 0.2], [0.3, 0.4]],
    'serialized tensor (JSON list) preserved',
  );
}

# --- chat_response without probes behaves like the parent ---
{
  my $engine = Langertha::Engine::VLLMHook->new(url => 'http://test.invalid:8770/v1');
  my $payload = {
    choices => [{ message => { role => 'assistant', content => 'plain' }, finish_reason => 'stop' }],
  };
  my $http = HTTP::Response->new(
    200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode($payload),
  );
  my $resp = $engine->chat_response($http);
  is($resp->content, 'plain', 'content preserved without probes');
  ok(!$resp->has_probes, 'no probes when server returned none');
}

# --- Config: attention tracker / CoRer -> qk worker ---
{
  my $cfg = Langertha::VLLMHook::Config->new(data => {
    model_info => { model_id => 'ibm-granite/granite-3.1-8b-instruct', provider => 'attn-hf' },
    params     => { important_heads => [[6, 9], [7, 20], [8, 1], [8, 13]] },
    hookq      => { hookq_mode => 'last_token' },
  });
  is($cfg->worker, 'qk', 'attention_tracker config maps to qk worker');
  is($cfg->model_id, 'ibm-granite/granite-3.1-8b-instruct', 'model_id read from model_info');
  my $x = $cfg->xargs;
  is($x->{hookq_mode}, 'last_token', 'hookq_mode carried through');
  ok(!ref $x->{output_qk}, 'output_qk is a JSON string');
  is_deeply(
    $json->decode($x->{output_qk}),
    { 6 => [9], 7 => [20], 8 => [1, 13] },
    'important_heads grouped into layer -> [heads]',
  );
}

# --- Config: hidden states with explicit layers ---
{
  my $cfg = Langertha::VLLMHook::Config->new(data => {
    model_info    => { name => 'Qwen/Qwen2.5-3B-Instruct' },
    hidden_states => { layers => [1, 2, 3, 4], mode => 'last_token' },
  });
  is($cfg->worker, 'hidden_states', 'hidden_states config maps to hidden_states worker');
  is($cfg->model_id, undef, 'model_id undef when model_info has no model_id');
  my $x = $cfg->xargs;
  ok(!ref $x->{output_hidden_states}, 'output_hidden_states is a JSON string for a layer list');
  is_deeply($json->decode($x->{output_hidden_states}), [1, 2, 3, 4], 'layer list decodes back');
}

# --- Config: hidden states with empty/missing layers -> boolean true ---
{
  my $cfg = Langertha::VLLMHook::Config->new(data => {
    hidden_states => { layers => [] },
  });
  is($cfg->worker, 'hidden_states', 'empty-layers config still hidden_states');
  my $x = $cfg->xargs;
  ok($x->{output_hidden_states}, 'output_hidden_states truthy for empty layers');
  is($json->encode({ v => $x->{output_hidden_states} }), '{"v":true}', 'rendered as JSON boolean true');
}

# --- Config: activation steering -> steer worker ---
{
  my $cfg = Langertha::VLLMHook::Config->new(data => {
    steering => {
      method                 => 'adjust_rs',
      coefficient            => 1,
      optimal_layer          => 8,
      vector_path            => 'steering_vectors/phi3_format.pt',
      apply_at_all_positions => JSON->true,
    },
  });
  is($cfg->worker, 'steer', 'steering config maps to steer worker');
  my $x = $cfg->xargs;
  ok(!ref $x->{steer}, 'steer is a single JSON string of the whole steering dict');
  my $decoded = $json->decode($x->{steer});
  is($decoded->{method}, 'adjust_rs', 'steering method preserved');
  is($decoded->{coefficient}, 1, 'steering coefficient preserved');
  is($decoded->{optimal_layer}, 8, 'steering optimal_layer preserved');
}

# --- Config: unrecognised shape -> empty xargs, undef worker ---
{
  my $cfg = Langertha::VLLMHook::Config->new(data => { model_info => { name => 'x' } });
  is($cfg->worker, undef, 'unrecognised config has no worker');
  is_deeply($cfg->xargs, {}, 'unrecognised config yields empty xargs');
}

done_testing;
