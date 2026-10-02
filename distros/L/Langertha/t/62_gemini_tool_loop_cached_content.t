#!/usr/bin/env perl
# ABSTRACT: A Gemini tool loop with a bound cachedContent sends no tools and still runs the calls

use strict;
use warnings;

use Test2::Bundle::More;

# karr k340, ADR 0035: a bound Gemini cachedContent owns systemInstruction,
# tools and toolConfig -- generateContent rejects a request that names a
# cache and sets them. In a tool loop the tools come from the cache, so the
# loop must leave its own tool list off every turn, and a functionCall the
# model makes from the cache's tool definitions must still run on the MCP
# server that offers the name. One carp per engine says what was not sent.

use lib 't/lib';
use Test::MockMCP;
use Test::ToolLoop qw( run_loop loop_names );

use Langertha::CachedContent;
use Langertha::Engine::Gemini;

sub make_engine {
  Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro',
    system_prompt => 'Be brief.',
    cached_content => Langertha::CachedContent->new(
      name => 'cachedContents/abc', model => 'models/gemini-2.5-pro' ),
    @_ );
}

my $tool_turn = { responseId => 'r1', modelVersion => 'gemini-2.5-pro', candidates => [ {
  finishReason => 'STOP', content => { role => 'model', parts => [
    { functionCall => { name => 'lookup', args => { key => 'k1' } } } ] } } ] };
my $done = { responseId => 'r2', modelVersion => 'gemini-2.5-pro', candidates => [ {
  finishReason => 'STOP', content => { role => 'model', parts => [ { text => 'value is 42' } ] } } ] };

for my $loop ( loop_names() ) {
  subtest $loop => sub {
    my @calls;
    my $server = Test::MockMCP->new( tools => [ { name => 'lookup', description => 'Look up a key',
      input_schema => { type => 'object', properties => { key => { type => 'string' } } },
      code => sub { push @calls, $_[1]; $_[0]->text_result('42') } } ] );
    my $out = run_loop( $loop, engine => \&make_engine,
      bodies => [ $tool_turn, $done ], servers => [$server] );

    is( $out->{ok}, 'value is 42', 'final text' ) or diag( $out->{died} // '' );
    is_deeply( \@calls, [ { key => 'k1' } ], 'the call from the cached tool definitions ran' );
    is( scalar @{ $out->{requests} }, 2, 'two turns' );
    for my $i ( 0, 1 ) {
      my $body = $out->{requests}[$i];
      is( $body->{cachedContent}, 'cachedContents/abc', "turn $i names the cache" );
      ok( !exists $body->{$_}, "turn $i sends no $_" )
        for qw( tools toolConfig tool_config systemInstruction system_instruction );
    }
    my ($response_part) = grep { $_->{functionResponse} }
      map { @{ $_->{parts} // [] } } @{ $out->{requests}[1]{contents} };
    is( $response_part->{functionResponse}{name}, 'lookup', 'turn 2 carries the result' );
    my @carps = grep { /not sending .*tools.* cached_content cachedContents\/abc is bound/ }
      @{ $out->{warnings} };
    is( scalar @carps, 1, 'one carp for the whole loop' ) or diag explain $out->{warnings};
  };
}

done_testing;
