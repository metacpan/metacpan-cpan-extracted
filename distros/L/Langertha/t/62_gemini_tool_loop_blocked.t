#!/usr/bin/env perl
# ABSTRACT: A Gemini prompt blocked inside a tool loop croaks with the blockReason

use strict;
use warnings;

use Test2::Bundle::More;

# karr k339: Gemini answers a prompt it refuses with no candidate and a
# promptFeedback.blockReason. chat_f reports that as an answer (k301:
# finish_reason SAFETY, content ''), but the tool loops return only text, so
# they ended with '' and the reason was lost -- a caller could not tell a
# block from a model that said nothing. The loops croak
# "<class> prompt blocked: <blockReason>"; chat_f keeps returning the Response.

use lib 't/lib';
use Test::MockMCP;
use Test::MockAsyncHTTP;
use Test::ToolLoop qw( run_loop loop_names http_for );

use Langertha::Engine::Gemini;

sub make_engine { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x', @_ ) }

sub echo_server {
  my ( $calls ) = @_;
  return Test::MockMCP->new( tools => [ { name => 'echo', description => 'Echo',
    input_schema => { type => 'object', properties => {} },
    code => sub { push @$calls, $_[1]; $_[0]->text_result('ok') } } ] );
}

my $blocked = { promptFeedback => { blockReason => 'PROHIBITED_CONTENT' },
  usageMetadata => { promptTokenCount => 7, totalTokenCount => 7 }, modelVersion => 'gemini-x' };

subtest 'chat_f still answers with the Response (k301)' => sub {
  my $response = make_engine( _async_http => Test::MockAsyncHTTP->new( responses => [ http_for($blocked) ] ) )
    ->chat_f( messages => [ { role => 'user', content => 'hi' } ] )->get;
  is( $response->finish_reason, 'PROHIBITED_CONTENT', 'finish_reason is the blockReason' );
  is( $response->content, '', 'no content' );
};

subtest 'every tool loop croaks with the reason' => sub {
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => \&make_engine,
      bodies => [ $blocked ], servers => [ echo_server( \@calls ) ] );
    is( $out->{died}, 'Langertha::Engine::Gemini prompt blocked: PROHIBITED_CONTENT',
      "$loop croaks instead of answering ''" );
  }
};

subtest 'a blocked prompt on a later turn croaks too' => sub {
  my $tool_turn = { responseId => 'r1', modelVersion => 'gemini-x', candidates => [ {
    finishReason => 'STOP', content => { role => 'model', parts => [
      { functionCall => { name => 'echo', args => {} } } ] } } ] };
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => \&make_engine,
      bodies => [ $tool_turn, $blocked ], servers => [ echo_server( \@calls ) ] );
    is( scalar @calls, 1, "$loop ran the first turn's call" );
    is( $out->{died}, 'Langertha::Engine::Gemini prompt blocked: PROHIBITED_CONTENT', "$loop croaks" );
  }
};

subtest 'a candidate with finish_reason SAFETY is an answer, not a blocked prompt' => sub {
  my $safety = { responseId => 'r2', modelVersion => 'gemini-x', candidates => [ {
    finishReason => 'SAFETY', content => { role => 'model', parts => [ { text => 'partial' } ] } } ] };
  for my $loop ( loop_names() ) {
    my $out = run_loop( $loop, engine => \&make_engine,
      bodies => [ $safety ], servers => [ echo_server( [] ) ] );
    is( $out->{ok}, 'partial', "$loop answers the candidate's text" ) or diag( $out->{died} // '' );
  }
};

done_testing;
