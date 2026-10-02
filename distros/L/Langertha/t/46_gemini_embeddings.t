#!/usr/bin/env perl
# ABSTRACT: Gemini embeddings: embedContent / batchEmbedContents request building and response parsing (k309)

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny;
use Test::MockAsyncHTTP;

use Langertha::Engine::Gemini;

# k309 (sources on k297): Gemini had no embeddings at all. A string goes to
# models/{m}:embedContent, an ArrayRef to models/{m}:batchEmbedContents, with
# the k289 contract every other engine keeps: ArrayRef in -> ArrayRef of
# vectors in input order, a count mismatch croaks, and a body without a vector
# croaks instead of returning undef (k290). Auth is the Gemini ?key= seam.
# taskType / title / outputDimensionality live under embedContentConfig (the
# top-level spellings are deprecated), so the snake_case extras are placed
# there; any other extra passes into the request body verbatim (ADR 0004).
#
# The fixtures in t/data/gemini_embed_content.json and
# t/data/gemini_batch_embed_contents.json are NOT live captures: they are
# written from Google's reference (ai.google.dev/api/embeddings,
# EmbedContentResponse / BatchEmbedContentsResponse, fetched 2026-09-25) with
# shortened vectors. No live call was made.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub http_ok {
  my ($raw) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'application/json');
  $http->content($raw);
  return $http;
}

my $single_raw = path('t/data/gemini_embed_content.json')->slurp_raw;
my $batch_raw  = path('t/data/gemini_batch_embed_contents.json')->slurp_raw;

my $gemini = Langertha::Engine::Gemini->new( api_key => 'test-key' );

subtest 'capability and model' => sub {
  ok($gemini->does('Langertha::Role::Embedding'), 'Gemini composes Role::Embedding');
  ok($gemini->supports('embedding'), 'embedding lights up from the role (ADR 0002)');
  is($gemini->embedding_model, 'gemini-embedding-001', 'default embedding model');
  is(Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' )->embedding_model,
    'gemini-embedding-001', 'the chat model is not used for embeddings');
  is(Langertha::Engine::Gemini->new( api_key => 'k', embedding_model => 'gemini-embedding-2' )->embedding_model,
    'gemini-embedding-2', 'embedding_model is settable');
};

subtest 'single string -> embedContent' => sub {
  my $req = $gemini->embedding('What is the meaning of life?');
  is($req->method, 'POST', 'POST');
  is($req->uri->as_string,
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=test-key',
    'embedContent endpoint with ?key= auth');
  is_deeply($json->decode($req->content), {
    model   => 'models/gemini-embedding-001',
    content => { parts => [ { text => 'What is the meaning of life?' } ] },
  }, 'body is one EmbedContentRequest');
  is_deeply($req->response_call->(http_ok($single_raw)), [ -0.0127, 0.0041, 0.0132, -0.0629 ],
    'embedding.values is the vector');
};

subtest 'ArrayRef -> batchEmbedContents' => sub {
  my $req = $gemini->embedding([ 'first', 'second' ]);
  is($req->uri->as_string,
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:batchEmbedContents?key=test-key',
    'batchEmbedContents endpoint with ?key= auth');
  is_deeply($json->decode($req->content), { requests => [
    { model => 'models/gemini-embedding-001', content => { parts => [ { text => 'first' } ] } },
    { model => 'models/gemini-embedding-001', content => { parts => [ { text => 'second' } ] } },
  ] }, 'one request per input, each naming the model');
  is_deeply($req->response_call->(http_ok($batch_raw)),
    [ [ 0.0213, -0.0084, 0.0151 ], [ -0.0302, 0.0117, 0.0049 ] ],
    'embeddings[].values in input order');

  my $three = $gemini->embedding([qw( a b c )]);
  eval { $three->response_call->(http_ok($batch_raw)) };
  like($@, qr/\ALangertha::Engine::Gemini embedding response returned 2 vectors for 3 inputs/,
    'a count mismatch croaks, naming the engine');
};

subtest 'extras: embedContentConfig placement and verbatim passthrough' => sub {
  my $req = $gemini->embedding_request('doc text',
    task_type             => 'RETRIEVAL_DOCUMENT',
    output_dimensionality => 768,
    title                 => 'A title',
  );
  is_deeply($json->decode($req->content)->{embedContentConfig}, {
    taskType => 'RETRIEVAL_DOCUMENT', outputDimensionality => 768, title => 'A title',
  }, 'snake_case extras land in embedContentConfig, camelCase');
  ok(!exists $json->decode($req->content)->{task_type}, 'no dead snake_case key on the wire');

  my $merged = $gemini->embedding_request('x',
    embedContentConfig => { autoTruncate => JSON::MaybeXS::true },
    task_type => 'RETRIEVAL_QUERY',
  );
  is_deeply($json->decode($merged->content)->{embedContentConfig},
    { autoTruncate => 1, taskType => 'RETRIEVAL_QUERY' },
    'a caller embedContentConfig is merged with the snake_case extras');

  my $batch = $gemini->embedding_request([qw( a b )], task_type => 'CLUSTERING');
  is_deeply([ map { $_->{embedContentConfig} } @{ $json->decode($batch->content)->{requests} } ],
    [ { taskType => 'CLUSTERING' }, { taskType => 'CLUSTERING' } ],
    'in a batch every request carries the config');
};

subtest 'no vector croaks (k290)' => sub {
  eval { $gemini->embedding('x')->response_call->(http_ok('{"embedding":{}}')) };
  like($@, qr/\ALangertha::Engine::Gemini embedding response contained no vector/,
    'embedding without values croaks');
  eval { $gemini->embedding([qw( a b )])->response_call->(http_ok('{"embeddings":[{"values":[1]},{}]}')) };
  like($@, qr/contained no vector/, 'a batch entry without values croaks');
  eval { $gemini->embedding('x')->response_call->(http_ok('{"error":{"message":"quota","code":429}}')) };
  like($@, qr/contained no vector \(error: quota\)/, 'a 200 body with an error names it');
};

subtest 'simple_embedding_f over the async backend (k292)' => sub {
  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response($json->decode($single_raw)),
    Test::MockAsyncHTTP->mock_json_response($json->decode($batch_raw)),
  ] );
  my $e = Langertha::Engine::Gemini->new( api_key => 'test-key', _async_http => $mock );
  is_deeply($e->simple_embedding_f('hi')->get, [ -0.0127, 0.0041, 0.0132, -0.0629 ], 'string -> vector');
  is_deeply($e->simple_embedding_f([qw( a b )])->get,
    [ [ 0.0213, -0.0084, 0.0151 ], [ -0.0302, 0.0117, 0.0049 ] ], 'ArrayRef -> vectors');
  my ($first, $second) = $mock->requests;
  like($first->uri->as_string, qr{/models/gemini-embedding-001:embedContent\?key=test-key\z}, 'embedContent sent');
  like($second->uri->as_string, qr{:batchEmbedContents\?key=test-key\z}, 'batchEmbedContents sent');
};

done_testing;
