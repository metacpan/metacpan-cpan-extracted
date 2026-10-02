#!/usr/bin/env perl
# ABSTRACT: Gemini and Ollama tool results carry the correlation key their wire offers
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::ToolResult;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;

# Why (karr k328): two parallel calls to the same function come back as two
# results with the same name. Gemini 3 returns a unique functionCall.id and its
# guides require the matching functionResponse.id; without it same-name results
# are mis-mapped. Ollama's Message struct has tool_name and tool_call_id, and its
# tool-calling docs send tool_name on every tool message; without them only the
# order correlates the results. The id is echoed only when the call had one --
# Gemini 2.5 may send none, and inventing one is worse than omitting it.

sub result {
  my ( $tool_call, $text ) = @_;
  return { tool_call => $tool_call, result => { content => [ { type => 'text', text => $text } ] } };
}

subtest 'ToolResult->to(gemini) id' => sub {
  is( Langertha::ToolResult->new( name => 'echo', id => 'fc-1' )->to('gemini')
      ->{functionResponse}{id}, 'fc-1', 'id emitted when set' );
  ok( !exists Langertha::ToolResult->new( name => 'echo' )->to('gemini')->{functionResponse}{id},
    'no id key without an id' );
};

subtest 'ToolResult->to(ollama) tool_name and tool_call_id' => sub {
  my $with = Langertha::ToolResult->new( name => 'echo', id => 'call_1' )->to('ollama');
  is( $with->{tool_name}, 'echo', 'tool_name' );
  is( $with->{tool_call_id}, 'call_1', 'tool_call_id' );
  my $without = Langertha::ToolResult->new( name => 'echo' )->to('ollama');
  is( $without->{tool_name}, 'echo', 'tool_name without an id' );
  ok( !exists $without->{tool_call_id}, 'no tool_call_id without an id' );
};

subtest 'Gemini format_tool_results echoes functionCall.id' => sub {
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash' );
  my @calls = (
    { functionCall => { id => 'fc-1', name => 'echo', args => { m => 'a' } } },
    { functionCall => { id => 'fc-2', name => 'echo', args => { m => 'b' } } },
    { functionCall => { name => 'echo', args => { m => 'c' } } },
  );
  my $data = { candidates => [ { content => { role => 'model', parts => \@calls } } ] };
  my @msgs = $gemini->format_tool_results( $data,
    [ result( $calls[0], 'r1' ), result( $calls[1], 'r2' ), result( $calls[2], 'r3' ) ] );
  my @fr = map { $_->{functionResponse} } @{ $msgs[1]{parts} };
  is_deeply( [ map { $_->{id} } @fr[ 0, 1 ] ], [ 'fc-1', 'fc-2' ], 'ids in call order' );
  is_deeply( [ map { $_->{response}{result} } @fr ], [qw( r1 r2 r3 )], 'results in call order' );
  ok( !exists $fr[2]{id}, 'a call without id gets no invented id' );
  is( $fr[2]{name}, 'echo', 'name stays' );
};

subtest 'Ollama format_tool_results emits tool_name and tool_call_id' => sub {
  my $ollama = Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'm' );
  my @calls = (
    { id => 'call_a', function => { name => 'echo', arguments => { m => 'a' } } },
    { id => 'call_b', function => { name => 'echo', arguments => { m => 'b' } } },
    { function => { name => 'time', arguments => {} } },
  );
  my $data = { message => { role => 'assistant', content => '', tool_calls => \@calls } };
  my ( undef, @tools ) = $ollama->format_tool_results( $data,
    [ result( $calls[0], 'r1' ), result( $calls[1], 'r2' ), result( $calls[2], 'r3' ) ] );
  is_deeply( [ map { $_->{tool_name} } @tools ], [qw( echo echo time )], 'tool_name per result' );
  is_deeply( [ map { $_->{tool_call_id} } @tools[ 0, 1 ] ], [qw( call_a call_b )],
    'tool_call_id from the call id' );
  ok( !exists $tools[2]{tool_call_id}, 'no tool_call_id when the call had none' );
  is_deeply( [ map { $_->{content} } @tools ],
    [qw( r1 r2 r3 )], 'results in call order' );
};

# The tool loops hand format_tool_results Langertha::ToolCall objects (k321);
# the correlation key must survive that path as well as the raw one.
subtest 'ToolCall objects carry the id and name too' => sub {
  require Langertha::ToolCall;
  my @calls = map { Langertha::ToolCall->new( name => 'echo', id => $_, arguments => {} ) }
    qw( fc-1 fc-2 );
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash' );
  my $gdata = { candidates => [ { content => { role => 'model', parts => [] } } ] };
  my @gmsgs = $gemini->format_tool_results( $gdata, [ map { result( $_, 'r' ) } @calls ] );
  is_deeply( [ map { $_->{functionResponse}{id} } @{ $gmsgs[1]{parts} } ], [qw( fc-1 fc-2 )],
    'gemini ids from ToolCall objects' );
  my $ollama = Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'm' );
  my ( undef, @tools ) = $ollama->format_tool_results(
    { message => { role => 'assistant', content => '' } }, [ map { result( $_, 'r' ) } @calls ] );
  is_deeply( [ map { [ $_->{tool_name}, $_->{tool_call_id} ] } @tools ],
    [ [qw( echo fc-1 )], [qw( echo fc-2 )] ], 'ollama tool_name and tool_call_id from ToolCall objects' );
};

done_testing;
