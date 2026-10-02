#!/usr/bin/env perl
# ABSTRACT: Batch embeddings return one vector per input, ordered by data[].index; base64 is decoded
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use MIME::Base64 qw( encode_base64 );

use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;

# karr k289: an ArrayRef input goes out as a batch, so the caller pays for N
# embeddings and must get N vectors back, in input order. The OpenAI wire
# carries data[].index and does not promise the array is in input order, so
# picking data[0] handed back the vector of some other input. A single string
# still returns one vector (Raider and every existing caller rely on that).
# encoding_format => 'base64' answers with a string of little-endian float32
# per entry; the documented return is an ArrayRef of floats, so it is decoded.
#
# The payloads are hand-written in the documented OpenAI / Ollama shapes: no
# live capture exists and live calls need approval.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub http_ok {
  my ($body) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'application/json');
  $http->content(ref $body ? $json->encode($body) : $body);
  return $http;
}

# The request carries its own response parser; running it is how a real
# simple_embedding call reads the answer, input shape included.
sub run_embedding {
  my ($engine, $input, $body, %extra) = @_;
  my $request = $engine->embedding_request($input, %extra);
  return $request->response_call->(http_ok($body));
}

my $openai = Langertha::Engine::OpenAI->new( api_key => 'k' );

my $out_of_order = {
  object => 'list',
  data   => [
    { object => 'embedding', index => 1, embedding => [ 2, 2 ] },
    { object => 'embedding', index => 0, embedding => [ 1, 1 ] },
  ],
};

subtest 'OpenAI-compatible batch' => sub {
  is_deeply(
    run_embedding($openai, [qw( a b )], $out_of_order),
    [ [ 1, 1 ], [ 2, 2 ] ],
    'ArrayRef input returns one vector per input, sorted by data[].index',
  );

  is_deeply(
    run_embedding($openai, ['only'], { data => [ { index => 0, embedding => [ 7 ] } ] }),
    [ [ 7 ] ],
    'a one-element ArrayRef still returns an ArrayRef of vectors',
  );

  my $got = eval {
    run_embedding($openai, [qw( a b c )], $out_of_order);
  };
  like($@, qr/\ALangertha::Engine::OpenAI embedding response returned 2 vectors for 3 inputs/,
    'a vector count that does not match the input count croaks, naming the engine');
};

subtest 'OpenAI-compatible single input' => sub {
  is_deeply(
    run_embedding($openai, 'x', $out_of_order),
    [ 1, 1 ],
    'a string input returns the vector of index 0, not data[0]',
  );
  is_deeply(
    $openai->embedding_response(http_ok($out_of_order)),
    [ 1, 1 ],
    'embedding_response without the input still returns the index-0 vector',
  );
  is_deeply(
    run_embedding($openai, 'x', { data => [ { embedding => [ 3 ] } ] }),
    [ 3 ],
    'entries without index are taken in array order',
  );
};

subtest 'base64 encoding_format' => sub {
  my @floats_a = ( 0.5, -1.25, 2 );
  my @floats_b = ( 0.25, 8 );
  my $b64 = sub { my $s = encode_base64(pack('f<*', @_), ''); $s };
  my $body = { data => [
    { index => 1, embedding => $b64->(@floats_b) },
    { index => 0, embedding => $b64->(@floats_a) },
  ] };

  my $request = $openai->embedding_request('x', encoding_format => 'base64');
  is($json->decode($request->content)->{encoding_format}, 'base64',
    'encoding_format goes on the wire unchanged');

  is_deeply(run_embedding($openai, 'x', $body, encoding_format => 'base64'),
    \@floats_a, 'a base64 vector is decoded to floats (little-endian float32)');
  is_deeply(run_embedding($openai, [qw( a b )], $body, encoding_format => 'base64'),
    [ \@floats_a, \@floats_b ], 'a base64 batch is decoded per input, in index order');
};

my $ollama = Langertha::Engine::Ollama->new( url => 'http://test.invalid:11434' );

subtest 'Ollama native batch' => sub {
  my $body = { model => 'mxbai-embed-large', embeddings => [ [ 1, 1 ], [ 2, 2 ] ] };

  is_deeply($json->decode($ollama->embedding_request([qw( a b )])->content)->{input},
    [qw( a b )], 'an ArrayRef input goes out as an /api/embed input array');
  is_deeply(run_embedding($ollama, [qw( a b )], $body), [ [ 1, 1 ], [ 2, 2 ] ],
    'ArrayRef input returns every vector, by position');
  is_deeply(run_embedding($ollama, 'a', $body), [ 1, 1 ],
    'a string input still returns one vector');

  eval { run_embedding($ollama, [qw( a b c )], $body) };
  like($@, qr/\ALangertha::Engine::Ollama embedding response returned 2 vectors for 3 inputs/,
    'a vector count mismatch croaks, naming the engine');
};

done_testing;
