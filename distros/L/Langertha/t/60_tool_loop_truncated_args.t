#!/usr/bin/env perl
# ABSTRACT: The tool loops never run a call whose arguments were cut off by the token limit

use strict;
use warnings;

use Test2::Bundle::More;

# karr k324: a reply cut off by its token limit (finish_reason length,
# Anthropic stop_reason max_tokens, Gemini MAX_TOKENS) can carry a tool call
# whose arguments JSON string was cut too. ToolCall decoded it to {} and the
# loops ran the -- possibly side-effecting -- tool on empty input. The stream
# parser already drops an unfinished call; the loops now do the same: a lone
# truncated call croaks and tells the caller to raise response_size, a
# truncated call beside complete ones is dropped with a carp, and the
# assistant echo leaves it out so the next turn pairs every call with a result.

use lib 't/lib';
use Test::MockMCP;
use Test::ToolLoop qw( run_loop loop_names );

use Langertha::ToolCall;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Engine::NousResearch;

my %engine = (
  openai    => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x', @_ ) },
  anthropic => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x', response_size => 256, @_ ) },
  gemini    => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x', @_ ) },
  responses => sub { Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-x', @_ ) },
  perplexity => sub { Langertha::Engine::Perplexity->new( api_key => 'k', @_ ) },
);

sub echo_server {
  my ( $calls ) = @_;
  return Test::MockMCP->new( tools => [ { name => 'echo', description => 'Echo',
    input_schema => { type => 'object', properties => { m => { type => 'string' } } },
    code => sub { push @$calls, $_[1]; $_[0]->text_result('ok') } } ] );
}

sub openai_turn {
  my ( $finish, @calls ) = @_;
  return { id => 'c1', choices => [ { index => 0, finish_reason => $finish,
    message => { role => 'assistant', content => undef, tool_calls => [
      map { { id => $_->[0], type => 'function', function => { name => 'echo', arguments => $_->[1] } } } @calls,
    ] } } ] };
}

my $openai_done = { id => 'c2', choices => [ { index => 0, finish_reason => 'stop',
  message => { role => 'assistant', content => 'done' } } ] };

subtest 'ToolCall records arguments that do not decode' => sub {
  my $cut = Langertha::ToolCall->from_openai(
    { id => 'a', function => { name => 'echo', arguments => '{"m":"hello wor' } } );
  ok( $cut->arguments_undecodable, 'a cut-off JSON string' );
  is_deeply( $cut->arguments, {}, 'arguments are {}' );
  for my $case ( [ 'complete string', '{"m":"x"}' ], [ 'empty string', '' ], [ 'no arguments', undef ] ) {
    my $call = Langertha::ToolCall->from_openai(
      { id => 'a', function => { name => 'echo', arguments => $case->[1] } } );
    ok( !$call->arguments_undecodable, "$case->[0] is not undecodable" );
  }
  ok( Langertha::ToolCall->from_anthropic(
    { type => 'tool_use', id => 't', name => 'echo', input => '{"m":' } )->arguments_undecodable,
    'Anthropic string input (the /anthropic shims)' );
  ok( Langertha::ToolCall->from_gemini(
    { functionCall => { name => 'echo', args => '{"m":' } } )->arguments_undecodable,
    'Gemini string args (proxies)' );
  ok( Langertha::ToolCall->from_responses(
    { type => 'function_call', call_id => 'r', name => 'echo', arguments => '{"m":' } )->arguments_undecodable,
    'Responses arguments' );
};

my @lone = (
  [ openai => 'length', openai_turn( length => [ call_1 => '{"m":"hello wor' ] ) ],
  [ anthropic => 'max_tokens',
    { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
      stop_reason => 'max_tokens', content => [
        { type => 'tool_use', id => 'toolu_1', name => 'echo', input => '{"m":"hel' } ] } ],
  [ gemini => 'MAX_TOKENS',
    { responseId => 'r1', modelVersion => 'gemini-x', candidates => [ { finishReason => 'MAX_TOKENS',
      content => { role => 'model', parts => [ { functionCall => { name => 'echo', args => '{"m":"hel' } } ] } } ] } ],
);

for my $case (@lone) {
  my ( $dialect, $reason, $body ) = @$case;
  subtest "$dialect: the only call was cut off ($reason)" => sub {
    for my $loop ( loop_names() ) {
      my @calls;
      my $out = run_loop( $loop, engine => $engine{$dialect},
        bodies => [ $body ], servers => [ echo_server( \@calls ) ] );
      like( $out->{died},
        qr/\ALangertha::Engine::\w+ tool call arguments truncated \(finish_reason \Q$reason\E\); raise response_size\z/,
        "$loop croaks" );
      is( scalar @calls, 0, "$loop ran no tool on {}" );
    }
  };
}

# karr k349: the Responses envelope (OpenAIResponses, Perplexity) decoded
# function_call arguments itself and died on a cut-off string with a raw JSON
# error, and a max_output_tokens reply holding only function calls reported
# finish_reason tool_calls, so the k324 drop never applied. The cut is
# reported on the envelope: status incomplete, incomplete_details.reason
# max_output_tokens (OpenAI Responses API reference).
my $responses_cut = { id => 'resp_1', object => 'response', status => 'incomplete', model => 'gpt-x',
  incomplete_details => { reason => 'max_output_tokens' },
  output => [ { type => 'function_call', id => 'fc_1', call_id => 'call_1', name => 'echo',
    arguments => '{"m":"hel', status => 'incomplete' } ] };

subtest 'responses: a max_output_tokens cut reads as length with the flag set' => sub {
  for my $dialect (qw( responses perplexity )) {
    my $r = eval { $engine{$dialect}->()->chat_response( Test::ToolLoop::http_for($responses_cut) ) };
    ok( defined $r, "$dialect: chat_response does not die" ) or diag($@);
    next unless $r;
    is( $r->finish_reason, 'length', "$dialect: finish_reason length" );
    ok( $r->tool_calls->[0]->arguments_undecodable, "$dialect: the call is flagged" );
  }
  my %complete = ( %$responses_cut, status => 'completed', incomplete_details => undef );
  is( $engine{responses}->()->chat_response( Test::ToolLoop::http_for( \%complete ) )->finish_reason,
    'tool_calls', 'a completed reply of function calls stays tool_calls' );
  my %filtered = ( %$responses_cut, incomplete_details => { reason => 'content_filter' } );
  is( $engine{responses}->()->chat_response( Test::ToolLoop::http_for( \%filtered ) )->finish_reason,
    'tool_calls', 'another incomplete reason is not a token limit' );
  my $chunk = $engine{perplexity}->()->parse_stream_chunk(
    { type => 'response.incomplete', response => $responses_cut }, 'response.incomplete' );
  is( $chunk->finish_reason, 'length', 'the terminal stream event reads the same' );
};

# karr k350: reasoning can eat the whole output budget, leaving output => []
# -- no message and not even a function_call to carry a status. The envelope
# still says status incomplete / max_output_tokens, so finish_reason is
# 'length', the same value the truncated-function-call case above reports
# (k349); the walker derived none because its length mapping was gated on there
# being tool-call items. Affects Perplexity too (same role) and chat_f.
my $responses_empty = { id => 'resp_2', object => 'response', status => 'incomplete', model => 'gpt-x',
  incomplete_details => { reason => 'max_output_tokens' }, output => [] };

subtest 'responses: a max_output_tokens cut with an empty output reads as length' => sub {
  for my $dialect (qw( responses perplexity )) {
    my $r = eval { $engine{$dialect}->()->chat_response( Test::ToolLoop::http_for($responses_empty) ) };
    ok( defined $r, "$dialect: chat_response does not die on empty output" ) or diag($@);
    next unless $r;
    is( $r->finish_reason, 'length', "$dialect: finish_reason length" );
    is( $r->content, '', "$dialect: no content" );
    ok( !$r->has_tool_calls, "$dialect: no tool calls" );
  }
  # A completed empty reply is not a token-limit cut: no finish_reason invented.
  my %done = ( %$responses_empty, status => 'completed', incomplete_details => undef );
  ok( !defined $engine{responses}->()->chat_response( Test::ToolLoop::http_for( \%done ) )->finish_reason,
    'a completed empty reply invents no finish_reason' );
};

for my $dialect (qw( responses perplexity )) {
  subtest "$dialect: the only call was cut off (max_output_tokens)" => sub {
    for my $loop ( loop_names() ) {
      my @calls;
      my $out = run_loop( $loop, engine => $engine{$dialect},
        bodies => [ $responses_cut ], servers => [ echo_server( \@calls ) ] );
      like( $out->{died},
        qr/\ALangertha::Engine::\w+ tool call arguments truncated \(finish_reason length\); raise response_size\z/,
        "$loop croaks" );
      is( scalar @calls, 0, "$loop ran no tool on {}" );
    }
  };
}

subtest 'openai: a complete call beside a cut-off one runs alone' => sub {
  my $turn = openai_turn( length => [ call_1 => '{"m":"first"}' ], [ call_2 => '{"m":"sec' ] );
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => $engine{openai},
      bodies => [ $turn, $openai_done ], servers => [ echo_server( \@calls ) ] );
    is( $out->{ok}, 'done', "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@calls, [ { m => 'first' } ], "$loop ran only the complete call" );
    my @carps = grep { /dropped 1 tool call\(s\) with truncated arguments \(finish_reason length\): echo; raise response_size/ }
      @{ $out->{warnings} };
    is( scalar @carps, 1, "$loop carps once about the dropped call" );
    my $messages = $out->{requests}[1]{messages};
    my ($echo) = grep { ( $_->{role} // '' ) eq 'assistant' } @$messages;
    is_deeply( [ map { $_->{id} } @{ $echo->{tool_calls} } ], ['call_1'],
      "$loop: the echo carries only the call that ran" );
    is_deeply( [ map { $_->{tool_call_id} } grep { ( $_->{role} // '' ) eq 'tool' } @$messages ],
      ['call_1'], "$loop: one result, paired with it" );
  }
};

subtest 'openai: a length finish with complete arguments still runs' => sub {
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => $engine{openai},
      bodies => [ openai_turn( length => [ call_1 => '{"m":"whole"}' ] ), $openai_done ],
      servers => [ echo_server( \@calls ) ] );
    is( $out->{ok}, 'done', "$loop finishes" ) or diag( $out->{died} // '' );
    is_deeply( \@calls, [ { m => 'whole' } ], "$loop ran the call" );
    is_deeply( $out->{warnings}, [], "$loop does not warn" );
  }
};

# karr k345: arguments that do not decode on a reply that was NOT cut off are
# no truncation to drop -- but running the tool on {} is still wrong. The
# loops answer the call with an error result naming the parse error and go on,
# so the model sees why and can retry.
subtest 'ToolCall records why the arguments did not decode' => sub {
  my $bad = Langertha::ToolCall->from_openai(
    { id => 'a', function => { name => 'echo', arguments => '{"m":' } } );
  like( $bad->arguments_error, qr/\A\S.*\S\z/s, 'the parser message' );
  unlike( $bad->arguments_error, qr/ line \d+/, 'without a source location' );
  is( Langertha::ToolCall->from_openai(
    { id => 'a', function => { name => 'echo', arguments => '[1]' } } )->arguments_error,
    'not a JSON object', 'a JSON array' );
  ok( !Langertha::ToolCall->from_openai(
    { id => 'a', function => { name => 'echo', arguments => '{"m":"x"}' } } )->has_arguments_error,
    'none for arguments that decode' );
};

my $anthropic_done = { id => 'msg_2', type => 'message', role => 'assistant', model => 'claude-x',
  stop_reason => 'end_turn', content => [ { type => 'text', text => 'done' } ] };

my @garbage = (
  [ openai => openai_turn( tool_calls => [ call_1 => '{"m":' ], [ call_2 => '{"m":"fine"}' ] ), $openai_done,
    sub { my ($messages) = @_;
      my %by_id = map { $_->{tool_call_id} => $_->{content} } grep { ( $_->{role} // '' ) eq 'tool' } @$messages;
      return ( $by_id{call_1}, undef, $by_id{call_2} ) } ],
  [ anthropic => { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
      stop_reason => 'tool_use', content => [
        { type => 'tool_use', id => 'toolu_1', name => 'echo', input => '{"m":' },
        { type => 'tool_use', id => 'toolu_2', name => 'echo', input => { m => 'fine' } } ] },
    $anthropic_done,
    sub { my ($messages) = @_;
      my ($user) = grep { ( $_->{role} // '' ) eq 'user' && ref $_->{content} eq 'ARRAY' } @$messages;
      my %by_id = map { $_->{tool_use_id} => $_ } grep { ( $_->{type} // '' ) eq 'tool_result' } @{ $user->{content} };
      my $text = sub { my $c = $_[0]{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c };
      return ( $text->( $by_id{toolu_1} ), $by_id{toolu_1}{is_error}, $text->( $by_id{toolu_2} ) ) } ],
);

for my $case (@garbage) {
  my ( $dialect, $turn, $done, $results ) = @$case;
  subtest "$dialect: undecodable arguments on a finished reply get an error result" => sub {
    for my $loop ( loop_names() ) {
      my @calls;
      my $out = run_loop( $loop, engine => $engine{$dialect},
        bodies => [ $turn, $done ], servers => [ echo_server( \@calls ) ] );
      is( $out->{ok}, 'done', "$loop continues to the final answer" ) or diag( $out->{died} // '' );
      is_deeply( \@calls, [ { m => 'fine' } ], "$loop ran only the call that decoded" );
      my ( $error, $is_error, $fine ) = $results->( $out->{requests}[1]{messages} );
      like( $error, qr/\Aarguments are not valid JSON: \S/, "$loop answers the bad call with the parse error" );
      ok( $is_error, "$loop marks it an error" ) if $dialect eq 'anthropic';
      is( $fine, 'ok', "$loop answers the good call with its result" );
    }
  };
}

# karr k350: on a hermes engine the <tool_call> arguments are lifted by
# extract_hermes_from_text, which dropped a non-object / undecodable arguments
# to {} WITHOUT the k345 flag -- so the error result never reached hermes
# engines and the loop ran the tool on {}. The flag now rides through
# _hermes_split_text and the Response tool_calls upgrade, so the loop answers a
# bad hermes call the same error result it answers an openai one.
subtest 'hermes: undecodable arguments on a finished reply get an error result' => sub {
  my $nous = sub { Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', @_ ) };
  my $turn = { id => 'c1', choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content =>
        qq(<tool_call>\n{"name":"echo","arguments":[1,2]}\n</tool_call>\n)
      . qq(<tool_call>\n{"name":"echo","arguments":{"m":"fine"}}\n</tool_call>) } } ] };
  my $done = { id => 'c2', choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'done' } } ] };
  for my $loop ( loop_names() ) {
    my @calls;
    my $out = run_loop( $loop, engine => $nous,
      bodies => [ $turn, $done ], servers => [ echo_server( \@calls ) ] );
    is( $out->{ok}, 'done', "$loop continues to the final answer" ) or diag( $out->{died} // '' );
    is_deeply( \@calls, [ { m => 'fine' } ], "$loop ran only the call that decoded" );
    my @tool_msgs = grep { ( $_->{role} // '' ) eq 'tool' } @{ $out->{requests}[1]{messages} };
    my @errors = grep { $_->{content} =~ /arguments are not valid JSON: not a JSON object/ } @tool_msgs;
    is( scalar @errors, 1, "$loop answered the bad call with the parse error" );
    my @good = grep { $_->{content} =~ /"content":"ok"/ } @tool_msgs;
    is( scalar @good, 1, "$loop answered the good call with its result" );
  }
};

done_testing;
