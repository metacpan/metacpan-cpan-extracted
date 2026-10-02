#!/usr/bin/env perl
# ABSTRACT: Usage reads the provider-reported cost (xAI ticks / nano-USD, Perplexity and OpenRouter usage.cost) as cost_usd

use strict;
use warnings;

use Test2::Bundle::More;
use HTTP::Response;
use Path::Tiny qw( path );

use Langertha::Usage;
use Langertha::Engine::XAI;
use Langertha::Engine::Perplexity;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::OpenAI;

# karr k354, ADR 0031 / ADR 0018 tier 1. xAI reports what a request was
# actually billed (after cache discounts, including server-side tool fees) in
# the usage block: cost_in_usd_ticks on chat/completions, Responses, images
# and video (1 USD = 10^10 ticks), and on Responses also cost_in_nano_usd
# (1 USD = 10^9 nano-USD), both nullable there. Langertha only kept the numbers
# in the raw usage hash, so a caller had to know the provider's unit to read
# the one figure that needs no price table. Usage->cost_usd is that figure in
# USD, read at the universal door so Response, stream chunks and from_raw all
# get it; unknown stays undef, never 0 (a 0 would read as "free").
#
# The fixtures are NOT live captures (no xAI key; live calls need the
# maintainer's approval). They are shaped from the xAI REST reference
# (docs.x.ai/developers/rest-api-reference/inference/chat-completions.md,
# .../responses.md, .../images.md) and the cost-tracking guide
# (docs.x.ai/developers/cost-tracking, last updated 2026-09-03), whose
# example 37756000 ticks is $0.0038.

my $data_dir = path(__FILE__)->parent->child('data');

sub http_json {
  my ($name) = @_;
  my $res = HTTP::Response->new( 200, 'OK' );
  $res->header( 'Content-Type' => 'application/json' );
  $res->content( $data_dir->child($name)->slurp_raw );
  return $res;
}

sub near { abs( $_[0] - $_[1] ) < 1e-12 }

subtest 'XAI chat/completions: cost_in_usd_ticks reaches Response->usage->cost_usd' => sub {
  my $xai  = Langertha::Engine::XAI->new( api_key => 'k' );
  my $resp = $xai->chat_response( http_json('xai_chat_cost_doc.json') );
  my $usage = $resp->usage;
  ok defined $usage->cost_usd, 'cost_usd is reported';
  ok near( $usage->cost_usd, 0.0037756 ), '37756000 ticks / 1e10 = $0.0037756'
    or diag $usage->cost_usd;
  is $usage->{cost_in_usd_ticks}, 37756000, 'the integer ticks stay verbatim in the usage hash';
  is $usage->input_tokens, 199, 'token counts unchanged';
  is $usage->cached_tokens, 128, 'cache count unchanged';
};

subtest 'XAI stream: the include_usage frame carries the cost' => sub {
  my $xai = Langertha::Engine::XAI->new( api_key => 'k' );
  my $buf = $data_dir->child('xai_stream_cost_doc.sse')->slurp_raw;
  my $chunks = $xai->_process_stream_buffer( \$buf, 'sse', 1, {} );
  my $usage  = Langertha::Usage->from_hash( $xai->aggregate_usage($chunks) );
  ok near( $usage->cost_usd, 0.0037756 ), 'streamed cost_usd from the usage-only frame';
};

subtest 'xAI Responses usage block: both spellings, ticks first' => sub {
  my $nano = Langertha::Usage->from_hash( {
    input_tokens => 10, output_tokens => 2, cost_in_nano_usd => 3775600 } );
  ok near( $nano->cost_usd, 0.0037756 ), 'cost_in_nano_usd alone: nano / 1e9';

  my $both = Langertha::Usage->from_hash( {
    input_tokens => 10, output_tokens => 2,
    cost_in_usd_ticks => 37756123, cost_in_nano_usd => 3775612 } );
  ok near( $both->cost_usd, 0.0037756123 ), 'both present: the finer ticks win';

  my $null_ticks = Langertha::Usage->from_hash( {
    input_tokens => 10, output_tokens => 2,
    cost_in_usd_ticks => undef, cost_in_nano_usd => 3775600 } );
  ok near( $null_ticks->cost_usd, 0.0037756 ), 'null ticks fall back to nano';

  my $null_both = Langertha::Usage->from_hash( {
    input_tokens => 10, output_tokens => 2,
    cost_in_usd_ticks => undef, cost_in_nano_usd => undef } );
  is $null_both->cost_usd, undef, 'both null: not reported';

  my $zero = Langertha::Usage->from_hash( { input_tokens => 1, cost_in_usd_ticks => 0 } );
  ok defined $zero->cost_usd && $zero->cost_usd == 0, 'a reported 0 stays a defined 0';
};

subtest 'xAI image body via from_raw' => sub {
  my $usage = Langertha::Usage->from_raw( {
    data  => [ { url => 'https://imgen.x.ai/x.jpeg' } ],
    usage => { cost_in_usd_ticks => 400000000 } } );
  ok near( $usage->cost_usd, 0.04 ), '400000000 ticks = $0.04';
};

subtest 'no provider cost: undef, not 0' => sub {
  is( Langertha::Usage->from_hash( { prompt_tokens => 5, completion_tokens => 1 } )->cost_usd,
    undef, 'OpenAI usage block has no cost' );
  is( Langertha::Usage->new( input_tokens => 5 )->cost_usd, undef, 'new without cost_usd' );
  ok near( Langertha::Usage->new( cost_usd => 0.5 )->cost_usd, 0.5 ), 'new takes cost_usd';
};

subtest 'merge: summed only when both sides report a cost' => sub {
  my $one = Langertha::Usage->from_hash( { input_tokens => 1, cost_in_usd_ticks => 10_000_000 } );
  my $two = Langertha::Usage->from_hash( { input_tokens => 2, cost_in_usd_ticks => 30_000_000 } );
  ok near( $one->merge($two)->cost_usd, 0.004 ), 'both reported: summed';
  my $none = Langertha::Usage->from_hash( { input_tokens => 3 } );
  is $one->merge($none)->cost_usd, undef, 'one side unknown: the sum is unknown';
  is $none->merge($one)->cost_usd, undef, 'either order';
};

# karr k363, ADR 0031 (Update k363) / ADR 0018. Two more providers state what
# they billed, both under the generic name usage.cost, in two shapes:
#
# - Perplexity's Agent API (Open-Responses envelope) sends an object that names
#   its unit: { currency => 'USD', total_cost => ..., input_cost => ..., ... }.
#   The Perplexity fixtures below are REAL captures (t/data/perplexity_agent_*,
#   k147 / k232). A self-describing USD amount is unambiguous on any wire, so
#   Usage->from_hash reads it (tier 1) -- but only when currency says USD and
#   total_cost is there: anything else would be a guess.
# - OpenRouter sends a bare number, usage.cost, in its credits; the OpenRouter
#   FAQ (openrouter.ai/docs/faq, read 2026-09-30): "OpenRouter uses a credit
#   system where the base currency is US dollars." The number carries no unit
#   on the wire and "cost" is too generic a name to read as USD from every
#   OpenAI-compatible server, so the OpenRouter engine states the unit (tier 3):
#   it copies the number to the canonical cost_usd key of the usage block. The
#   OpenRouter fixtures are NOT captures (no approved live call); they are
#   shaped from openrouter.ai/docs/use-cases/usage-accounting, whose example
#   usage block (cost 0.95, cost_details.upstream_inference_cost 19) is used
#   verbatim. upstream_inference_cost is what a BYOK key's own provider charged,
#   not what OpenRouter billed, so it is not folded in.

subtest 'Perplexity Agent capture: usage.cost {currency USD, total_cost} is cost_usd' => sub {
  my $ppx = Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar' );
  my $search = $ppx->chat_response( http_json('perplexity_agent_search.json') );
  ok near( $search->usage->cost_usd // -1, 0.00456 ), 'search reply: total_cost 0.00456 (tool fee included)'
    or diag $search->usage->cost_usd;
  is $search->usage->{cost}{currency}, 'USD', 'the cost block stays verbatim in the usage hash';

  my $call = $ppx->chat_response( http_json('perplexity_agent_function_call.json') );
  ok near( $call->usage->cost_usd // -1, 0.00024 ), 'function-call reply: total_cost 0.00024';
};

subtest 'Perplexity Agent capture: the streamed response.completed usage carries the cost' => sub {
  my $ppx = Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar' );
  my $chunks = $ppx->process_stream_data( $data_dir->child('perplexity_agent_stream.sse')->slurp_raw );
  my $usage  = Langertha::Usage->from_hash( $ppx->aggregate_usage($chunks) );
  ok near( $usage->cost_usd // -1, 0.00035 ), 'streamed cost_usd = total_cost 0.00035'
    or diag $usage->cost_usd;
};

subtest 'usage.cost object: read only when it names USD and a total' => sub {
  my $usd = Langertha::Usage->from_hash( { input_tokens => 1,
    cost => { currency => 'USD', total_cost => 0.25 } } );
  ok near( $usd->cost_usd // -1, 0.25 ), 'currency USD: total_cost';

  is( Langertha::Usage->from_hash( { input_tokens => 1,
    cost => { currency => 'EUR', total_cost => 0.25 } } )->cost_usd,
    undef, 'another currency is not a USD figure' );
  is( Langertha::Usage->from_hash( { input_tokens => 1,
    cost => { total_cost => 0.25 } } )->cost_usd,
    undef, 'no currency: the unit is unknown' );
  is( Langertha::Usage->from_hash( { input_tokens => 1,
    cost => { currency => 'USD', input_cost => 0.25 } } )->cost_usd,
    undef, 'no total_cost: the parts are not summed into a guess' );

  my $zero = Langertha::Usage->from_hash( { input_tokens => 1,
    cost => { currency => 'USD', total_cost => 0 } } );
  ok defined $zero->cost_usd && $zero->cost_usd == 0, 'a reported 0 stays a defined 0';
};

subtest 'OpenRouter (docs-derived): usage.cost credits are cost_usd' => sub {
  my $router = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o' );
  my $resp   = $router->chat_response( http_json('openrouter_chat_cost_doc.json') );
  ok near( $resp->usage->cost_usd // -1, 0.95 ), 'usage.cost 0.95 credits = $0.95'
    or diag $resp->usage->cost_usd;
  is $resp->usage->{cost}, 0.95, 'the wire number stays in the usage hash';
  is $resp->usage->{cost_details}{upstream_inference_cost}, 19,
    'the BYOK upstream cost stays verbatim, not folded into cost_usd';
  is $resp->usage->input_tokens, 194, 'token counts unchanged';
  is $resp->usage->cache_write_tokens, 100, 'cache-write count unchanged';
};

subtest 'OpenRouter (docs-derived): the streamed usage frame carries the cost' => sub {
  my $router = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o' );
  my $chunks = $router->process_stream_data( $data_dir->child('openrouter_stream_cost_doc.sse')->slurp_raw );
  is join( '', map { $_->content } @$chunks ), 'Hi', 'the processing comment is skipped';
  my $usage = Langertha::Usage->from_hash( $router->aggregate_usage($chunks) );
  ok near( $usage->cost_usd // -1, 0.95 ), 'streamed cost_usd from the usage-only frame'
    or diag $usage->cost_usd;
};

subtest 'a bare usage.cost number is not read unless the engine states its unit' => sub {
  is( Langertha::Usage->from_hash( { prompt_tokens => 1, cost => 0.95 } )->cost_usd,
    undef, 'Usage->from_hash: a unit-less number is not assumed to be USD' );
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k' );
  is( $openai->chat_response( http_json('openrouter_chat_cost_doc.json') )->usage->cost_usd,
    undef, 'the same body through another OpenAI-compatible engine: not read' );
  ok near( Langertha::Usage->from_hash( { prompt_tokens => 1, cost_usd => 0.5 } )->cost_usd // -1, 0.5 ),
    'the canonical cost_usd key is read as it says';
};

done_testing;
