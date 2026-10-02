#!/usr/bin/env perl
# ABSTRACT: /anthropic shims that count the cache inside input_tokens are priced once; Usage->merge keeps cache counts
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny qw( path );

use Langertha::Usage;
use Langertha::Pricing;
use Langertha::Engine::Anthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::AKIOpenAI;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::MoonshotAnthropic;
use Langertha::Engine::LMStudioAnthropic;

# Why (k265, ADR 0031 Update, ADR 0018 tier 3): Usage reads the flat Anthropic
# cache keys as "beside input_tokens", which is first-party Anthropic's truth
# (and MiniMax's and Moonshot's, per their docs). AKI.IO's /anthropic shim uses
# the spelling but counts the reads inside input_tokens — the two captures below
# are the same request on AKI.IO's two faces: 65 input / 64 cached on both. Left
# uninferred, Pricing with a cache rate bills those 64 tokens twice on
# AKIAnthropic. The correction is one hook on Role::AnthropicCompatible that
# AKIAnthropic answers with 1; it must reach Usage on the non-streaming and the
# streaming path alike, and must not leak onto the other Anthropic engines.
# Usage->merge used to drop the cache counts and the flag, so a summed Usage
# priced every cached token at the full input rate.

my $data_dir = path(__FILE__)->parent->child('data');
my $json     = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub fixture_http {
  my ($name) = @_;
  my $http = HTTP::Response->new( 200, 'OK' );
  $http->header( 'Content-Type' => 'application/json' );
  $http->content( $data_dir->child("$name.json")->slurp_raw );
  return $http;
}

sub usd_is {
  my ( $got, $want, $name ) = @_;
  ok( abs( $got - $want ) < 1e-12, $name ) or diag "got $got, want $want";
}

my %rule = ( input_per_million => 2, output_per_million => 8, cached_input_per_million => 0.5 );
my $pricing = Langertha::Pricing->new( default_rule => {%rule} );

my %args = ( api_key => 'testkey', model => 'llama3-chat-8b' );
my $aki_anthropic = Langertha::Engine::AKIAnthropic->new(%args);
my $aki_openai    = Langertha::Engine::AKIOpenAI->new(%args);

subtest 'AKIAnthropic: cached reads counted inside input_tokens, priced once' => sub {
  my $resp  = $aki_anthropic->chat_response( fixture_http('akianthropic_chat_response') );
  my $usage = $resp->usage;
  is( $usage->input_tokens, 65, 'input_tokens as the wire says' );
  is( $usage->cached_tokens, 64, 'cache_read_input_tokens' );
  is( $usage->input_includes_cache, 1, 'engine-scoped correction marks the reads as included' );
  is( $usage->uncached_input_tokens, 1, '65 - 64' );

  my $openai_usage = $aki_openai->chat_response( fixture_http('akiopenai_chat_response') )->usage;
  my $shim   = $pricing->cost_for( $usage, 'llama3-chat-8b' );
  my $openai = $pricing->cost_for( $openai_usage, 'llama3-chat-8b' );
  usd_is( $shim->total_usd, $openai->total_usd, 'same request costs the same on both AKI.IO faces' );
  usd_is( $shim->total_usd, ( 1 * 2 + 64 * 0.5 + 10 * 8 ) / 1e6, 'each token once' );

  ok( !exists $resp->raw->{usage}{input_includes_cache}, 'the wire body is not modified' );
};

subtest 'the correction is engine-scoped' => sub {
  for my $class (qw( Anthropic MiniMaxAnthropic MoonshotAnthropic LMStudioAnthropic )) {
    my $engine = "Langertha::Engine::$class"->new( %args, url => 'http://127.0.0.1:1' );
    my $usage  = $engine->chat_response( fixture_http('akianthropic_chat_response') )->usage;
    is( $usage->input_includes_cache, 0, "$class keeps the flat-key inference (beside)" );
    is( $usage->uncached_input_tokens, 65, "$class: input_tokens untouched" );
  }
};

subtest 'streaming: the final chunk usage carries the same flag' => sub {
  # No streamed shim capture exists; the usage numbers are the non-streamed
  # capture's, on the message_delta event where Anthropic streams usage.
  my $sse = <<'SSE';
event: message_start
data: {"type":"message_start","message":{"id":"1"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"OK."}}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"input_tokens":65,"output_tokens":10,"cache_read_input_tokens":64}}

event: message_stop
data: {"type":"message_stop"}

SSE
  my $chunks = $aki_anthropic->process_stream_data($sse);
  my ($final) = grep { $_->is_final } @$chunks;
  ok( $final && $final->has_usage, 'is_final chunk carries usage' );
  my $usage = Langertha::Usage->from_hash( $final->usage );
  is( $usage->input_includes_cache, 1, 'AKIAnthropic stream: included' );
  my $non_stream = $aki_anthropic->chat_response( fixture_http('akianthropic_chat_response') )->usage;
  usd_is( $pricing->cost_for( $usage, 'm' )->total_usd, $pricing->cost_for( $non_stream, 'm' )->total_usd,
    'streamed and non-streamed usage cost the same' );

  my $first_party = Langertha::Engine::Anthropic->new( api_key => 'testkey' );
  my ($fp_final) = grep { $_->is_final } @{ $first_party->process_stream_data($sse) };
  is( Langertha::Usage->from_hash( $fp_final->usage )->input_includes_cache, 0,
    'first-party Anthropic stream: beside' );
};

subtest 'Moonshot per-TTL write split without the flat total' => sub {
  my $usage = Langertha::Usage->from_hash( { input_tokens => 10, output_tokens => 2,
    cache_creation => { ephemeral_5m_input_tokens => 300, ephemeral_1h_input_tokens => 20 } } );
  is( $usage->cache_write_tokens, 320, 'tiers summed' );
  is( $usage->input_includes_cache, 0, 'beside input_tokens, like the flat key' );
  my $both = Langertha::Usage->from_hash( { input_tokens => 10, cache_creation_input_tokens => 7,
    cache_creation => { ephemeral_5m_input_tokens => 7 } } );
  is( $both->cache_write_tokens, 7, 'flat total wins, the split is not added on top' );
};

subtest 'merge carries cache counts and the flag' => sub {
  my $nested = sub { Langertha::Usage->from_hash( { prompt_tokens => $_[0], completion_tokens => 1,
    prompt_tokens_details => { cached_tokens => $_[1] } } ) };
  my $flat = Langertha::Usage->from_hash( { input_tokens => 5, output_tokens => 1,
    cache_read_input_tokens => 40, cache_creation_input_tokens => 3 } );
  my $plain = Langertha::Usage->from_hash( { prompt_tokens => 7, completion_tokens => 2 } );

  my $sum = $nested->( 65, 64 )->merge( $nested->( 30, 20 ) );
  is( $sum->input_tokens, 95, 'input summed' );
  is( $sum->cached_tokens, 84, 'cached summed' );
  is( $sum->cache_write_tokens, undef, 'no write count on either side stays undef' );
  is( $sum->input_includes_cache, 1, 'both included: kept' );
  is( $sum->uncached_input_tokens, 11, 'priced as the parts: 1 + 10' );

  my $with_plain = $flat->merge($plain);
  is( $with_plain->cached_tokens, 40, 'a side without cache counts adds nothing' );
  is( $with_plain->cache_write_tokens, 3, 'write count carried' );
  is( $with_plain->input_includes_cache, 0, 'flag from the only side that reported a cache count' );
  is( $with_plain->uncached_input_tokens, 12, '5 + 7, cache beside' );

  my $flat_too = Langertha::Usage->from_hash( { input_tokens => 2, output_tokens => 1,
    cache_read_input_tokens => 10 } );
  my $both_beside = $flat->merge($flat_too);
  is( $both_beside->input_tokens, 7, 'both beside: input_tokens only summed' );
  is( $both_beside->input_includes_cache, 0, 'both beside: flag stays 0' );

  # Mixed wires: the beside side is normalized to inside before summing, so
  # pricing the sum costs exactly what pricing the parts costs.
  my $cache_rates = Langertha::Pricing->new( default_rule => { input_per_million => 3,
    output_per_million => 15, cached_input_per_million => 0.3, cache_write_per_million => 3.75 } );
  my $inside = $nested->( 65, 64 );
  my $undef_inside = Langertha::Usage->new( input_tokens => 30, output_tokens => 1, cached_tokens => 20 );
  for my $case ( [ 'flag 1', $inside ], [ 'undef flag with counts', $undef_inside ] ) {
    my ( $label, $in ) = @$case;
    for my $pair ( [ $flat, $in ], [ $in, $flat ] ) {
      my $mixed = $pair->[0]->merge( $pair->[1] );
      is( $mixed->input_includes_cache, 1, "$label + beside: flag 1" );
      is( $mixed->input_tokens, $in->input_tokens + 5 + 40 + 3, "$label: beside cache folded into input_tokens" );
      is( $mixed->cached_tokens, $in->cached_tokens + 40, "$label: reads summed" );
      usd_is( $cache_rates->cost_for( $mixed, 'm' )->total_usd,
        $cache_rates->cost_for( $flat, 'm' )->total_usd + $cache_rates->cost_for( $in, 'm' )->total_usd,
        "$label: cost of the sum equals the sum of the costs" );
    }
  }

  my $none = $plain->merge($plain);
  is( $none->cached_tokens, undef, 'no cache anywhere: undef' );
  is( $none->input_includes_cache, undef, 'no cache anywhere: flag undef' );
};

done_testing;
