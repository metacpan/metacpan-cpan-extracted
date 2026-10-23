#!/usr/bin/env perl
# ABSTRACT: Langertha::Engine::Virtual drives the real MCP tool loops: core's, Langertha::Chat's and a raider-style one

use strict;
use warnings;

use Test2::Bundle::More;
use Path::Tiny;

use lib path(__FILE__)->parent->child('lib')->stringify;

use Future::AsyncAwait;
use Test::MockMCP;

use Langertha::Chat;
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool after );

# The point of a virtual engine is to stand in for the model inside a tool
# loop (t/64 needed captured Ollama fixtures and a scripted HTTP mock for the
# same round trip; langertha-raider carries its own MockAI engine). The rules
# pick the calls, the loop runs them on a real (duck-typed) MCP server, and
# the next request carries the results back -- through the same request
# builder, parser and result envelope as a real OpenAI-dialect engine. These
# tests pin that round trip for the three loops that exist: core's
# chat_with_tools_f, Langertha::Chat's, and the public-hook loop
# langertha-raider runs (async_request_f, parse_response, tool_loop_response,
# tool_loop_calls, format_tool_results; ADR 0028).

my $calculator = Test::MockMCP->new(
  tools => [ {
    name         => 'add',
    description  => 'Add two numbers',
    input_schema => {
      type       => 'object',
      properties => { a => { type => 'number' }, b => { type => 'number' } },
      required   => [qw( a b )],
    },
    code => sub { my ( $self, $args ) = @_; return $self->text_result( $args->{a} + $args->{b} ) },
  } ],
);

sub calculator_rules {
  return (
    rules => [
      qr/\AAdd (\d+) and (\d+)\z/ => sub {
        my ( $request, $first, $second ) = @_;
        return tool( add => { a => $first, b => $second } );
      },
      after('add') => sub {
        my ($request) = @_;
        return answer( 'The sum is '.$request->{tool_results}[0]{content}.'.' );
      },
    ],
    fallback => answer('I can only add.'),
  );
}

# An in-memory stand-in for langertha-raider's stock file tools.
sub file_server {
  my ($files) = @_;
  return Test::MockMCP->new( tools => [
    { name => 'read_file', description => 'Read a file', input_schema => { type => 'object' },
      code => sub {
        my ( $self, $args ) = @_;
        return exists $files->{ $args->{path} } ? $self->text_result( $files->{ $args->{path} } )
          : $self->text_result( "no such file: $args->{path}", 1 );
      } },
    { name => 'write_file', description => 'Write a file', input_schema => { type => 'object' },
      code => sub {
        my ( $self, $args ) = @_;
        $files->{ $args->{path} } = $args->{content};
        return $self->text_result( 'Wrote '.length( $args->{content} ).' bytes to '.$args->{path} );
      } },
    { name => 'bash', description => 'Run a command', input_schema => { type => 'object' },
      code => sub { my ( $self, $args ) = @_; return $self->text_result("Exit code: 0\nran $args->{command}") } },
  ] );
}

subtest 'chat_with_tools_f: the rule calls the tool, the after rule answers with its result' => sub {
  my $engine = Langertha::Engine::Virtual->new( calculator_rules(), mcp_servers => [$calculator] );
  my $answer = $engine->chat_with_tools_f('Add 7 and 15')->get;
  is( $answer, 'The sum is 22.', 'final text' );

  is( scalar @{ $engine->requests }, 2, 'two model requests: the call, then the answer' );
  my ( $first, $second ) = @{ $engine->requests };
  is( $first->{tools}[0]{function}{name}, 'add', 'the tools went along with the request' );
  is_deeply( [ map { $_->{role} } @{ $second->{messages} } ], [qw( user assistant tool )],
    'the second request carries the call and its result' );
  is( $second->{messages}[1]{tool_calls}[0]{function}{name}, 'add', 'the assistant echo names the call' );
  is_deeply( $engine->calls, [ [ add => { a => 7, b => 15 } ] ], 'calls: what the engine asked for' );
  is( scalar @{ $engine->results }, 1, 'results: one tool result came back' );
  is( $engine->results->[0]{tool_call}->name, 'add', '... for the add call' );
  is_deeply( $engine->results->[0]{result}{content}, [ { type => 'text', text => '22' } ],
    '... with the MCP result the tool really returned' );

  is( $engine->chat_with_tools_f('Hello')->get, 'I can only add.', 'no call: the fallback is the final text' );
};

subtest 'script mode in the loop, with a tool the server does not have' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    mcp_servers => [$calculator],
    script      => [
      { tool_calls => [ [ add => { a => 1, b => 2 } ], [ no_such_tool => {} ] ] },
      { text => 'weiter' },
    ],
  );
  is( $engine->chat_with_tools_f('Go')->get, 'weiter', 'the script runs to its last step' );
  my @results = @{ $engine->results };
  is( scalar @results, 2, 'both calls got a result' );
  is( $results[0]{result}{content}[0]{text}, '3', 'the known tool ran' );
  ok( $results[1]{result}{isError}, 'the unknown one is an error result, the loop went on' );
  like( $results[1]{result}{content}[0]{text}, qr/unknown tool no_such_tool/, '... saying why' );
  my $back = $engine->requests->[1]{tool_results};
  is_deeply( [ map { $_->{name} } @$back ], [qw( add no_such_tool )], 'the rules saw both results by name' );
};

subtest 'preset files writes and reads through the tool loop' => sub {
  my %files;
  my $engine = Langertha::Engine::Virtual->preset( files => mcp_servers => [ file_server( \%files ) ] );
  is( $engine->chat_with_tools_f('Write the file notes.txt: hello world')->get,
    'Wrote 11 bytes to notes.txt', 'the write ran and the answer is its result' );
  is( $files{'notes.txt'}, 'hello world', 'the file exists on the server' );
  is( $engine->chat_with_tools_f('Read the file notes.txt')->get, 'hello world', 'read it back' );
  like( $engine->chat_with_tools_f('Run the command ls')->get, qr/\AExit code: 0\nran ls\z/, 'bash' );
  is_deeply( [ map { $_->[0] } @{ $engine->calls } ], [qw( write_file read_file bash )], 'calls in order' );
};

subtest 'Langertha::Chat runs its tool loop over the engine' => sub {
  my $engine = Langertha::Engine::Virtual->new( calculator_rules() );
  my $chat = Langertha::Chat->new( engine => $engine, mcp_servers => [$calculator] );
  is( $chat->simple_chat_with_tools('Add 2 and 3'), 'The sum is 5.', 'sync wrapper loop' );
  is( $chat->simple_chat_with_tools_f('Add 4 and 4')->get, 'The sum is 8.', 'async wrapper loop' );
  is( scalar @{ $engine->results }, 2, 'both loops handed their results to the engine' );
};

# What langertha-raider's raid loop does with an engine, through the public
# hooks only (ADR 0028): one async request per turn, the decoded body read by
# tool_loop_response, the results appended with format_tool_results.
async sub raider_style_loop {
  my ( $engine, $prompt ) = @_;
  my $formatted   = $engine->format_tools( await $calculator->list_tools );
  my $conversation = $engine->chat_messages($prompt);
  for my $turn ( 1 .. 5 ) {
    my $request  = $engine->build_tool_chat_request( $conversation, $formatted );
    my $response = await $engine->async_request_f($request);
    my $data     = $engine->parse_response($response);
    my $reply    = $engine->tool_loop_response($data);
    my ( $calls, $echo ) = $engine->tool_loop_calls( $reply, $data );
    return $reply->content unless @$calls;
    my @results;
    for my $call (@$calls) {
      push @results, { tool_call => $call, result => await $calculator->call_tool( $call->name, $call->arguments ) };
    }
    push @$conversation, $engine->format_tool_results( $echo, \@results );
  }
  die "raider_style_loop: no answer after 5 turns\n";
}

subtest 'a raider-style loop over the public hooks' => sub {
  my $engine = Langertha::Engine::Virtual->new( calculator_rules() );
  is( $engine->async_loop, undef, 'no loop: a raider brings its own' );
  is( raider_style_loop( $engine, 'Add 20 and 22' )->get, 'The sum is 42.', 'same round trip' );
  is( scalar @{ $engine->results }, 1, 'format_tool_results recorded the result' );
};

done_testing;
