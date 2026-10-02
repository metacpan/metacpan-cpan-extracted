#!/usr/bin/env perl
# ABSTRACT: A hermes <tool_call> inside <think> is never run by the tool loops

use strict;
use warnings;

use Test2::Bundle::More;

# karr k323: the tool loops lifted hermes calls from the raw reply text,
# thinking included, so chat_with_tools_f and both Langertha::Chat loops ran a
# tool the model only considered in its reasoning. chat_f lifts from the
# think-filtered content and the stream lift treats a call inside <think> as
# no call (k302), so the same reply ran a side-effecting tool on one path and
# answered text on the others. A call in the thinking is not a call, on every
# path -- including response_tool_calls, which langertha-raider's loop reads.

use lib 't/lib';
use JSON::MaybeXS;
use Future;
use Test::MockMCP;
use Test::MockAsyncHTTP;
use Test::ToolLoop qw( run_loop loop_names http_for );

use Langertha::Engine::NousResearch;

my $CALL = '<tool_call>{"name":"echo","arguments":{"m":"x"}}</tool_call>';

sub reply {
  my ( $text ) = @_;
  return { id => 'c1', choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => $text } } ] };
}

sub make_engine { Langertha::Engine::NousResearch->new( api_key => 'k', @_ ) }

sub echo_server {
  my ( $calls ) = @_;
  return Test::MockMCP->new( tools => [ { name => 'echo', description => 'Echo',
    input_schema => { type => 'object', properties => { m => { type => 'string' } } },
    code => sub { push @$calls, $_[1]; $_[0]->text_result('ok') } } ] );
}

sub chat_f_content {
  my ( $body ) = @_;
  my $engine = make_engine( _async_http => Test::MockAsyncHTTP->new( responses => [ http_for($body) ] ) );
  my $response = $engine->chat_f( messages => [ { role => 'user', content => 'hi' } ],
    tools => [ { name => 'echo', description => 'Echo', input_schema => { type => 'object' } } ] )->get;
  return ( $response->content, scalar @{ $response->tool_calls // [] } );
}

my @cases = (
  [ 'a call inside a <think> block',
    "<think>I could call $CALL but no need.</think>The answer is 4.",
    'The answer is 4.' ],
  [ 'a call before an orphan </think> (the template opened the thought)',
    "I could call $CALL but no need.</think>The answer is 4.",
    'The answer is 4.' ],
);

for my $case (@cases) {
  my ( $label, $text, $want ) = @$case;
  subtest $label => sub {
    my ( $content, $n_calls ) = chat_f_content( reply($text) );
    is( $content, $want, 'chat_f: the answer text' );
    is( $n_calls, 0, 'chat_f: no tool call' );
    for my $loop ( loop_names() ) {
      my @calls;
      my $out = run_loop( $loop, engine => \&make_engine,
        bodies => [ reply($text) ], servers => [ echo_server( \@calls ) ] );
      is( $out->{ok}, $want, "$loop answers chat_f's text" ) or diag( $out->{died} // '' );
      is( scalar @calls, 0, "$loop ran no tool" );
    }
    is_deeply( make_engine()->response_tool_calls( reply($text) ), [],
      'response_tool_calls finds no call in the thinking' );
  };
}

# The control: the same call outside the thinking is a call, and runs.
subtest 'a call after the thinking still runs' => sub {
  my $text = "<think>I should echo.</think>$CALL";
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => \&make_engine,
      bodies => [ reply($text), reply('done') ], servers => [ echo_server( \@calls ) ] );
    is( $out->{ok}, 'done', "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@calls, [ { m => 'x' } ], "$loop ran the call once" );
  }
  is( scalar @{ make_engine()->response_tool_calls( reply($text) ) }, 1,
    'response_tool_calls finds it' );
};

done_testing;
