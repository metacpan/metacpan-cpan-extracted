#!/usr/bin/env perl
# ABSTRACT: Pricing prices prompt-cache reads and writes once each, per wire
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Usage;
use Langertha::Pricing;
use Langertha::Cost;

# Why (k263, ADR 0031, needed by skeid k28): a pricing rule may carry
# cached_input_per_million / cache_write_per_million. Whether a cache count is
# already part of input_tokens differs per wire (OpenAI Chat, Open-Responses,
# Gemini, AKI native: inside; Anthropic: beside), so pricing it naively either
# bills a cached token twice or not at all. Each token must be priced exactly
# once, a missing cache rate must fall back to the input rate (no invented
# discount), and a rule without cache keys must cost exactly what it did before.
# The OpenAI-Chat, Responses, Perplexity and AKI cases replay verbatim captures
# from t/data/; Anthropic and Gemini have no capture with non-zero cache counts,
# so their usage blocks are the documented shapes.

my $json = JSON::MaybeXS->new( utf8 => 1 );
sub capture_usage {
  my ($name) = @_;
  my $data = $json->decode( path( 't', 'data', "$name.json" )->slurp_raw );
  return Langertha::Usage->from_raw($data);
}

sub usd_is {
  my ( $got, $want, $name ) = @_;
  ok( abs( $got - $want ) < 1e-12, $name ) or diag "got $got, want $want";
}

# The pre-k263 formula, spelled out so "unchanged" is checked against it.
sub legacy_total {
  my ( $usage, $rule ) = @_;
  return ( $usage->input_tokens / 1_000_000 ) * $rule->{input_per_million}
       + ( $usage->output_tokens / 1_000_000 ) * $rule->{output_per_million};
}

sub price {
  my ( $usage, $rule ) = @_;
  return Langertha::Pricing->new( default_rule => $rule )->cost_for( $usage, 'm' );
}

my %plain = ( input_per_million => 2, output_per_million => 8 );

subtest 'OpenAI Chat (AKIOpenAI capture): cached reads are inside prompt_tokens' => sub {
  my $u = capture_usage('akiopenai_chat_response');
  is( $u->input_tokens, 65, 'prompt_tokens' );
  is( $u->cached_tokens, 64, 'prompt_tokens_details.cached_tokens' );
  is( $u->input_includes_cache, 1, 'nested count is part of prompt_tokens' );
  is( $u->uncached_input_tokens, 1, '65 - 64 cached' );

  my $c = price( $u, { %plain, cached_input_per_million => 0.5 } );
  usd_is( $c->input_usd, 1 * 2 / 1e6, 'the one uncached token at the input rate' );
  usd_is( $c->cache_read_usd, 64 * 0.5 / 1e6, '64 cached tokens at the cached rate' );
  usd_is( $c->cache_write_usd, 0, 'no write count, no write cost' );
  usd_is( $c->output_usd, 10 * 8 / 1e6, 'output' );
  usd_is( $c->total_usd, ( 1 * 2 + 64 * 0.5 + 10 * 8 ) / 1e6, 'total: each token once' );

  my $w = price( $u, { %plain, cache_write_per_million => 99 } );
  usd_is( $w->cache_read_usd, 64 * 2 / 1e6, 'no cached rate: reads fall back to the input rate' );
  usd_is( $w->total_usd, legacy_total( $u, \%plain ), 'so the total is the undiscounted one' );
};

subtest 'Open-Responses (OpenAI capture): cache writes are inside input_tokens' => sub {
  my $u = capture_usage('responses_web_search');
  is( $u->input_tokens, 8542, 'input_tokens' );
  is( $u->cache_write_tokens, 4394, 'input_tokens_details.cache_write_tokens' );
  is( $u->cached_tokens, 0, 'input_tokens_details.cached_tokens' );
  is( $u->input_includes_cache, 1, 'nested counts are part of input_tokens' );
  is( $u->uncached_input_tokens, 8542 - 4394, 'writes taken out' );

  my $rule = { input_per_million => 1.25, output_per_million => 10,
               cached_input_per_million => 0.125, cache_write_per_million => 1.5 };
  my $c = price( $u, $rule );
  usd_is( $c->input_usd, 4148 * 1.25 / 1e6, 'uncached input' );
  usd_is( $c->cache_write_usd, 4394 * 1.5 / 1e6, 'writes at the write rate' );
  usd_is( $c->cache_read_usd, 0, 'zero reads' );
  usd_is( $c->total_usd, ( 4148 * 1.25 + 4394 * 1.5 + 87 * 10 ) / 1e6, 'total' );
};

subtest 'Perplexity Agent API capture: Anthropic-named keys nested, so inside' => sub {
  my $u = capture_usage('perplexity_agent_search');
  is( $u->input_tokens, 4071, 'input_tokens' );
  is( $u->cache_write_tokens, 4068, 'input_tokens_details.cache_creation_input_tokens' );
  is( $u->input_includes_cache, 1, 'nested in input_tokens_details' );
  is( $u->uncached_input_tokens, 3, '4071 - 4068' );

  my %rule = ( %plain, cached_input_per_million => 0.2, cache_write_per_million => 2 );
  usd_is( price( $u, \%rule )->total_usd, legacy_total( $u, \%plain ),
    'write rate equal to the input rate: total equals pricing input_tokens once' );
};

subtest 'Anthropic (documented shape): cache counts are beside input_tokens' => sub {
  my $u = Langertha::Usage->from_hash( {
    input_tokens => 9, output_tokens => 4,
    cache_read_input_tokens => 1000, cache_creation_input_tokens => 200,
  } );
  is( $u->input_includes_cache, 0, 'flat Anthropic keys are not part of input_tokens' );
  is( $u->uncached_input_tokens, 9, 'nothing taken out of input_tokens' );

  my $rule = { input_per_million => 3, output_per_million => 15,
               cached_input_per_million => 0.3, cache_write_per_million => 3.75 };
  my $c = price( $u, $rule );
  usd_is( $c->input_usd, 9 * 3 / 1e6, 'input_tokens at the input rate' );
  usd_is( $c->cache_read_usd, 1000 * 0.3 / 1e6, 'reads added at the cached rate' );
  usd_is( $c->cache_write_usd, 200 * 3.75 / 1e6, 'writes added at the write rate' );
  usd_is( $c->total_usd, ( 27 + 300 + 750 + 60 ) / 1e6, 'total' );

  my $r = price( $u, { input_per_million => 3, output_per_million => 15,
                       cached_input_per_million => 0.3 } );
  usd_is( $r->cache_write_usd, 200 * 3 / 1e6, 'no write rate: writes at the input rate' );
};

subtest 'Gemini: cachedContentTokenCount is inside promptTokenCount' => sub {
  my $raw = Langertha::Usage->from_raw( { usageMetadata => {
    promptTokenCount => 1000, cachedContentTokenCount => 800,
    candidatesTokenCount => 50, totalTokenCount => 1050 } } );
  my $renamed = Langertha::Usage->from_hash( {
    prompt_tokens => 1000, cached_content_token_count => 800, completion_tokens => 50 } );
  for my $u ( $raw, $renamed ) {
    is( $u->input_includes_cache, 1, 'included' );
    is( $u->uncached_input_tokens, 200, '1000 - 800' );
    usd_is( price( $u, { %plain, cached_input_per_million => 0.5 } )->total_usd,
      ( 200 * 2 + 800 * 0.5 + 50 * 8 ) / 1e6, 'total' );
  }
};

subtest 'AKI native capture: num_cached_tokens is a subset of prompt_length' => sub {
  my $u = capture_usage('aki_chat_response');
  is( $u->input_tokens, 38, 'prompt_length' );
  is( $u->cached_tokens, 16, 'num_cached_tokens' );
  is( $u->input_includes_cache, 1, 'included' );
  is( $u->uncached_input_tokens, 22, '38 - 16' );
};

subtest 'a rule without cache keys costs exactly what it did before' => sub {
  for my $u (
    capture_usage('akiopenai_chat_response'),
    capture_usage('responses_web_search'),
    capture_usage('perplexity_agent_search'),
    Langertha::Usage->from_hash( { input_tokens => 9, output_tokens => 4,
      cache_read_input_tokens => 1000, cache_creation_input_tokens => 200 } ),
  ) {
    my $c = price( $u, \%plain );
    ok( $c->input_usd == ( $u->input_tokens / 1_000_000 ) * 2, 'input_usd unchanged' );
    ok( $c->total_usd == legacy_total( $u, \%plain ), 'total unchanged' );
    is( $c->cache_read_usd + 0, 0, 'no cache read amount' );
    is( $c->cache_write_usd + 0, 0, 'no cache write amount' );
  }
};

subtest 'Usage built with new' => sub {
  my $u = Langertha::Usage->new( input_tokens => 100, cached_tokens => 30 );
  is( $u->input_includes_cache, undef, 'flag not passed' );
  is( $u->uncached_input_tokens, 70, 'undef flag reads as included' );
  my $beside = Langertha::Usage->new( input_tokens => 100, cached_tokens => 30,
    input_includes_cache => 0 );
  is( $beside->uncached_input_tokens, 100, 'false flag: input_tokens untouched' );
  my $odd = Langertha::Usage->new( input_tokens => 10, cached_tokens => 20,
    input_includes_cache => 1 );
  is( $odd->uncached_input_tokens, 0, 'never below zero' );
  is( Langertha::Usage->from_hash( { prompt_tokens => 5 } )->input_includes_cache, undef,
    'no cache count reported: flag stays undef' );
};

subtest 'Cost carries the cache amounts' => sub {
  my $c = Langertha::Cost->new( input_usd => 1, output_usd => 2,
    cache_read_usd => 0.25, cache_write_usd => 0.5 );
  is( $c->total_usd + 0, 3.75, 'total includes both cache amounts' );
  my $h = $c->to_hash;
  is( $h->{cache_read_cost_usd} + 0, 0.25, 'to_hash cache_read_cost_usd' );
  is( $h->{cache_write_cost_usd} + 0, 0.5, 'to_hash cache_write_cost_usd' );
  is( $h->{total_cost_usd} + 0, 3.75, 'to_hash total_cost_usd' );
};

done_testing;
