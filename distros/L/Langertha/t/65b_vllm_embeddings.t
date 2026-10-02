#!/usr/bin/env perl
# ABSTRACT: Offline tests for vLLM Embedding role composition (karr #70) and the self-hosted model rule (k297)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::vLLM;
use Langertha::Engine::VLLMHook;
use Langertha::Engine::LlamaCpp;
use Langertha::Engine::LMStudioOpenAI;

# k297: the self-hosted embedding engines used to send model => 'default'.
# vLLM 0.10/0.11 answer 404 "The model `default` does not exist." unless it is
# the --served-model-name, while a request without a model is always accepted
# (the server embeds with what it serves). So the body carries the caller's
# embedding_model, else the caller's model, else no model field at all — never
# the 'default' placeholder.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Engine construction ---

my $vllm = Langertha::Engine::vLLM->new(
  url => 'http://test.invalid:8000/v1',
);

is($vllm->default_embedding_model, undef,
  'vLLM has no fixed default_embedding_model');
is($vllm->embedding_model, undef,
  'embedding_model stays unset without a caller model');

ok($vllm->does('Langertha::Role::Embedding'),
  'vLLM composes Langertha::Role::Embedding');

# --- Supported operations include createEmbedding ---

my $ops = $vllm->_build_supported_operations;
ok((grep { $_ eq 'createEmbedding' } @$ops),
  '_build_supported_operations contains createEmbedding');

# --- Request generation ---

my $req = $vllm->embedding('hello world');
is($req->method, 'POST', 'embedding request method is POST');
is($req->uri, 'http://test.invalid:8000/v1/embeddings',
  'embedding request hits /v1/embeddings');
is($req->header('Content-Type'),
  'application/json; charset=utf-8',
  'embedding request sets JSON Content-Type');

is_deeply($json->decode($req->content), {
  input => 'hello world',
}, 'without a caller model the body has no model field');

# --- Explicit embedding_model flows through ---

my $custom = Langertha::Engine::vLLM->new(
  url             => 'http://test.invalid:8000/v1',
  embedding_model => 'BAAI/bge-large-en-v1.5',
);
is($custom->embedding_model, 'BAAI/bge-large-en-v1.5',
  'explicit embedding_model is preserved');
my $custom_data = $json->decode($custom->embedding('hi')->content);
is($custom_data->{model}, 'BAAI/bge-large-en-v1.5',
  'explicit embedding_model flows into request body');
is($custom_data->{input}, 'hi',
  'explicit embedding input is preserved');

# --- The rule on every self-hosted embedding engine ---

for my $class (qw(
  Langertha::Engine::vLLM
  Langertha::Engine::VLLMHook
  Langertha::Engine::LlamaCpp
  Langertha::Engine::LMStudioOpenAI
)) {
  my %url = ( url => 'http://test.invalid:8000/v1' );
  my $body = sub { $json->decode($_[0]->embedding('x')->content) };

  ok(!exists $body->($class->new(%url))->{model},
    "$class: no caller model -> no model field");
  is($body->($class->new(%url, model => 'bge-m3'))->{model}, 'bge-m3',
    "$class: the caller's model is sent");
  is($body->($class->new(%url, model => 'bge-m3', embedding_model => 'e5-large'))->{model},
    'e5-large', "$class: embedding_model beats model");
  ok(!exists $body->($class->new(%url, model => 'default'))->{model},
    "$class: the 'default' placeholder is never sent");
}

done_testing;
