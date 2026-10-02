#!/usr/bin/env perl
# ABSTRACT: SGLang serves /v1/embeddings: Embedding role, self-hosted model rule, batch contract (k309)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::SGLang;

# k309 (sources on k297): SGLang serves the OpenAI-shape /v1/embeddings when
# launched with an embedding model, but the engine did not compose
# Role::Embedding, so supports('embedding') was false and simple_embedding did
# not exist. The model rule is vLLM's (k297): the caller's embedding_model,
# else the caller's model, else no model field — never the 'default'
# placeholder, which older OpenAI-compatible servers answer with a 404.
# The response payload is hand-written in the documented OpenAI shape (SGLang
# answers with it): no live capture exists and live calls need approval.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
my %url  = ( url => 'http://test.invalid:30000/v1' );

my $sglang = Langertha::Engine::SGLang->new(%url);

ok($sglang->does('Langertha::Role::Embedding'), 'SGLang composes Role::Embedding');
ok($sglang->supports('embedding'), 'the embedding capability lights up from the role (ADR 0002)');
ok((grep { $_ eq 'createEmbedding' } @{ $sglang->_build_supported_operations }),
  'createEmbedding is a supported operation');

my $req = $sglang->embedding('hello');
is($req->method, 'POST', 'POST');
is($req->uri, 'http://test.invalid:30000/v1/embeddings', 'hits /v1/embeddings');
is_deeply($json->decode($req->content), { input => 'hello' },
  'without a caller model the body has no model field');

my $body = sub { $json->decode($_[0]->embedding('x')->content) };
is($body->(Langertha::Engine::SGLang->new(%url, model => 'gte-qwen2'))->{model},
  'gte-qwen2', "the caller's model is sent");
is($body->(Langertha::Engine::SGLang->new(%url, model => 'gte-qwen2', embedding_model => 'bge-m3'))->{model},
  'bge-m3', 'embedding_model beats model');
ok(!exists $body->(Langertha::Engine::SGLang->new(%url, model => 'default'))->{model},
  "the 'default' placeholder is never sent");

# Batch: one vector per input, in input order (k289), sorted by data[].index.
my $batch_req = $sglang->embedding([qw( a b )]);
is_deeply($json->decode($batch_req->content)->{input}, [qw( a b )], 'ArrayRef goes out as one input array');
my $http = HTTP::Response->new(200, 'OK');
$http->header('Content-Type' => 'application/json');
$http->content($json->encode({ object => 'list', data => [
  { object => 'embedding', index => 1, embedding => [ 0.2 ] },
  { object => 'embedding', index => 0, embedding => [ 0.1 ] },
] }));
is_deeply($batch_req->response_call->($http), [ [ 0.1 ], [ 0.2 ] ],
  'batch answer comes back in input order');

done_testing;
