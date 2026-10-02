#!/usr/bin/env perl
# ABSTRACT: Gemini thinking and tool-use prompt tokens reach Usage output/input counts (k299)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Usage;
use Langertha::Pricing;
use Langertha::Engine::Gemini;

# karr k299, ADR 0018 tier 1. Gemini's usageMetadata reports thinking beside
# the answer: thoughtsTokenCount is NOT part of candidatesTokenCount, and
# totalTokenCount = promptTokenCount + candidatesTokenCount + thoughtsTokenCount
# (+ toolUsePromptTokenCount). Thinking is billed at the output rate, so an
# output_tokens that holds only candidatesTokenCount makes Pricing charge a
# thinking model for 1 token where the provider bills 501. Usage->from_hash is
# the door every path goes through (Response BUILDARGS, a streamed chunk's raw
# usageMetadata, from_raw for sibling dists), so the fold lives there;
# output_tokens then means what OpenAI's completion_tokens means (reasoning
# included) and reasoning_tokens reports the thinking share on both wires.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub http_json {
  my ($body) = @_;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->header( 'Content-Type' => 'application/json' );
  $res->content($body);
  return $res;
}

# The ticket's repro: shape per ai.google.dev/api/generate-content
# (UsageMetadata). No verbatim Gemini thinking capture exists in t/data.
my $body = {
  candidates => [ {
    content      => { parts => [ { text => '4' } ], role => 'model' },
    finishReason => 'STOP',
  } ],
  usageMetadata => {
    promptTokenCount     => 10,
    candidatesTokenCount => 1,
    thoughtsTokenCount   => 500,
    totalTokenCount      => 511,
  },
  modelVersion => 'gemini-2.5-pro',
};

sub counts {
  my ($usage) = @_;
  return [ map { $usage->$_ } qw( input_tokens output_tokens total_tokens reasoning_tokens ) ];
}

subtest 'chat_response: thoughts are output tokens (ticket repro)' => sub {
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro' );
  my $resp = $engine->chat_response( http_json( $json->encode($body) ) );
  is_deeply( counts( $resp->usage ), [ 10, 501, 511, 500 ],
    'input=10 output=501 total=511 reasoning=500' );
  is( $resp->usage->input_tokens + $resp->usage->output_tokens, $resp->usage->total_tokens,
    'input + output adds up to the wire total' );

  # The back-compat snake_case hash follows OpenAI's meaning: completion_tokens
  # includes reasoning, the share sits under completion_tokens_details.
  is( $resp->usage->{completion_tokens}, 501, 'usage->{completion_tokens} includes thoughts' );
  is( $resp->usage->{completion_tokens_details}{reasoning_tokens}, 500,
    'usage->{completion_tokens_details}{reasoning_tokens}' );

  my $pricing = Langertha::Pricing->new(
    rules => { 'gemini-2.5-pro' => { input_per_million => 0, output_per_million => 1_000_000 } } );
  is( $pricing->cost_for( $resp->usage, $resp->model )->output_usd, 501,
    'Pricing charges the thinking tokens at the output rate' );
};

subtest 'raw usageMetadata (from_raw / from_hash): same counts' => sub {
  is_deeply( counts( Langertha::Usage->from_raw($body) ), [ 10, 501, 511, 500 ], 'from_raw' );
  is_deeply( counts( Langertha::Usage->from_hash( { %{ $body->{usageMetadata} } } ) ),
    [ 10, 501, 511, 500 ], 'from_hash on the camelCase block' );
};

subtest 'stream: final chunk usage carries the same counts' => sub {
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro' );
  my $chunk = $engine->parse_stream_chunk($body);
  ok( $chunk->has_usage, 'final chunk has usage' );
  is_deeply( counts( Langertha::Usage->from_hash( $chunk->usage ) ), [ 10, 501, 511, 500 ],
    'Usage from the streamed usageMetadata' );
};

subtest 'thought-only answer: candidatesTokenCount omitted' => sub {
  # proto3 JSON drops zero fields, so a response that spent everything on
  # thinking (e.g. MAX_TOKENS) arrives without candidatesTokenCount.
  my $usage = Langertha::Usage->from_hash(
    { promptTokenCount => 7, thoughtsTokenCount => 64, totalTokenCount => 71 } );
  is_deeply( counts($usage), [ 7, 64, 71, 64 ], 'output = thoughts alone' );
};

subtest 'toolUsePromptTokenCount is prompt-side input' => sub {
  my %um = ( promptTokenCount => 10, toolUsePromptTokenCount => 30,
    candidatesTokenCount => 5, thoughtsTokenCount => 20, totalTokenCount => 65 );
  is_deeply( counts( Langertha::Usage->from_hash( {%um} ) ), [ 40, 25, 65, 20 ], 'from_hash' );

  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro' );
  my $resp = $engine->chat_response( http_json( $json->encode( { %$body, usageMetadata => {%um} } ) ) );
  is_deeply( counts( $resp->usage ), [ 40, 25, 65, 20 ], 'chat_response' );
  is( $resp->usage->{prompt_tokens}, 40, 'usage->{prompt_tokens} includes tool-use prompt' );
};

subtest 'no thinking: counts unchanged, reasoning_tokens undef' => sub {
  my $usage = Langertha::Usage->from_hash(
    { promptTokenCount => 300, candidatesTokenCount => 120, totalTokenCount => 420 } );
  is_deeply( counts($usage), [ 300, 120, 420, undef ], 'plain Gemini block' );

  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  my %plain = ( %$body, usageMetadata => { promptTokenCount => 3, candidatesTokenCount => 2, totalTokenCount => 5 } );
  my $resp = $engine->chat_response( http_json( $json->encode( \%plain ) ) );
  ok( !exists $resp->usage->{completion_tokens_details}, 'no phantom completion_tokens_details' );
};

subtest 'OpenAI wire: reasoning_tokens read, already inside completion_tokens' => sub {
  my $usage = Langertha::Usage->from_hash( {
    prompt_tokens => 12, completion_tokens => 80, total_tokens => 92,
    completion_tokens_details => { reasoning_tokens => 64 },
  } );
  is_deeply( counts($usage), [ 12, 80, 92, 64 ], 'output not inflated by reasoning_tokens' );

  my $resp_usage = Langertha::Usage->from_hash( {
    input_tokens => 12, output_tokens => 80, total_tokens => 92,
    output_tokens_details => { reasoning_tokens => 64 },
  } );
  is( $resp_usage->reasoning_tokens, 64, 'Open-Responses output_tokens_details' );
};

subtest 'merge sums reasoning_tokens' => sub {
  my $one = Langertha::Usage->from_hash( { promptTokenCount => 1, candidatesTokenCount => 1, thoughtsTokenCount => 4 } );
  my $two = Langertha::Usage->from_hash( { promptTokenCount => 1, candidatesTokenCount => 1 } );
  is( $one->merge($two)->reasoning_tokens, 4, 'one side reported' );
  is( $two->merge($two)->reasoning_tokens, undef, 'neither side reported' );
  is( $one->merge($two)->output_tokens, 6, 'output summed' );
};

done_testing;
