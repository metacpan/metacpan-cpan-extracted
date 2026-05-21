#!/usr/bin/env perl
# ABSTRACT: Test OpenAI Responses API engine

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny qw( path );

use Langertha::Engine::OpenAIResponses;
use Langertha::ToolCall;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# Load fixtures
my $text_fixture    = $json->decode( path('t/data/responses_api_text.json')->slurp );
my $toolcall_fixture = $json->decode( path('t/data/responses_api_toolcall.json')->slurp );
my $toolcall_toplevel_fixture
    = $json->decode( path('t/data/responses_api_toolcall_toplevel.json')->slurp );

subtest 'engine creation' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    ok( $engine->isa('Langertha::Engine::OpenAIResponses'), 'correct class' );
    ok( $engine->isa('Langertha::Engine::OpenAI'),         'inherits from OpenAI' );
    is( $engine->chat_operation_id, 'createResponse', 'operation_id is createResponse' );
    is( $engine->stream_format, undef, 'streaming not supported' );
};

subtest 'chat_operation_id' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    is( $engine->chat_operation_id, 'createResponse' );
};

subtest 'chat_request - basic structure' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key       => 'test-key',
        model         => 'gpt-5.5-pro',
        system_prompt => 'You are a helpful assistant',
    );
    my $request = $engine->chat_request([
        { role => 'system', content => 'You are a helpful assistant' },
        { role => 'user',   content => 'Hello' },
    ]);
    is( $request->method, 'POST', 'POST method' );
    like( $request->uri, qr|/v1/responses$|, 'correct URI' );

    my $body = $json->decode( $request->content );
    is( $body->{instructions}, 'You are a helpful assistant', 'instructions from system_prompt' );
    is( $body->{input}[0]{role}, 'user', 'input has user message' );
    is( $body->{input}[0]{content}, 'Hello', 'input has correct content' );
    ok( !grep( { $_->{role} eq 'system' } @{$body->{input}} ), 'system not in input array' );
    is( $body->{model}, 'gpt-5.5-pro', 'model in body' );
};

subtest 'chat_request - no system prompt' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    my $request = $engine->chat_request([
        { role => 'user', content => 'Hello' },
    ]);
    my $body = $json->decode( $request->content );
    ok( !$body->{instructions}, 'no instructions when no system_prompt' );
    is( $body->{input}[0]{role}, 'user', 'input has user message' );
};

subtest 'chat_request - with tools (flat format)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    my $tools = [
        {
            name        => 'echo',
            description => 'Echo the input text',
            inputSchema => {
                type       => 'object',
                properties => { message => { type => 'string' } },
                required   => ['message'],
            },
        },
    ];
    my $request = $engine->chat_request(
        [{ role => 'user', content => 'Use echo' }],
        tools => $tools,
    );
    my $body = $json->decode( $request->content );
    ok( $body->{tools}, 'tools field present' );
    is( scalar @{$body->{tools}}, 1, 'one tool' );
    is( $body->{tools}[0]{type}, 'function', 'type is function' );
    is( $body->{tools}[0]{name}, 'echo', 'tool name is echo' );
    ok( !exists $body->{tools}[0]{function}, 'no nested function wrapper' );
    is( $body->{tools}[0]{description}, 'Echo the input text', 'tool description preserved' );
};

subtest 'chat_request - with tool_choice (Responses format)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    my $request = $engine->chat_request(
        [{ role => 'user', content => 'Use echo' }],
        tools      => [{ name => 'echo', description => 'Echo', input_schema => { type => 'object' } }],
        tool_choice => { type => 'tool', name => 'echo' },
    );
    my $body = $json->decode( $request->content );
    is( $body->{tool_choice}{type}, 'function', 'tool_choice type is function' );
    is( $body->{tool_choice}{name}, 'echo', 'tool_choice name is top-level' );
    ok( !exists $body->{tool_choice}{function}, 'no nested function wrapper' );
};

subtest 'chat_request - temperature and max_tokens' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key       => 'test-key',
        model         => 'gpt-5.5-pro',
        temperature   => 0.7,
        response_size => 1024,
    );
    my $request = $engine->chat_request([
        { role => 'user', content => 'Hello' },
    ]);
    my $body = $json->decode( $request->content );
    is( $body->{temperature}, 0.7, 'temperature in body' );
    is( $body->{max_tokens}, 1024, 'max_tokens in body' );
};

subtest 'chat_response - text response' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    # Build a mock HTTP response object
    my $mock_response = _build_mock_response($text_fixture);

    my $resp = $engine->chat_response($mock_response);
    is( $resp->content, 'Hello! How are you?', 'content extracted from output_text' );
    is( $resp->id, 'resp_abc123', 'id from response' );
    is( $resp->model, 'gpt-5.5-pro', 'model from response' );
    is( $resp->finish_reason, 'stop', 'finish_reason normalized to stop' );
    ok( $resp->has_usage, 'usage present' );
    is( $resp->usage->{prompt_tokens}, 25, 'prompt_tokens from input_tokens' );
    is( $resp->usage->{completion_tokens}, 42, 'completion_tokens from output_tokens' );
    is( $resp->usage->{completion_tokens_details}{reasoning_tokens}, 18,
        'reasoning_tokens normalized to completion_tokens_details' );
};

subtest 'chat_response - with thinking' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $mock_response = _build_mock_response($text_fixture);
    my $resp = $engine->chat_response($mock_response);
    is( $resp->thinking, 'The user is asking for a simple greeting',
        'thinking from reasoning summary' );
};

subtest 'chat_response - tool call extraction' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $mock_response = _build_mock_response($toolcall_fixture);
    my $resp = $engine->chat_response($mock_response);

    ok( $resp->has_tool_calls, 'tool_calls present' );
    is( scalar @{$resp->tool_calls}, 1, 'one tool call' );

    my $tc = $resp->tool_call;
    is( $tc->name, 'get_weather', 'tool name extracted' );
    is_deeply( $tc->arguments, { location => 'Paris, France', units => 'celsius' },
        'arguments parsed from JSON string' );
    is( $tc->id, 'call_abc123', 'call_id from function_call block' );
    ok( !$tc->synthetic, 'not synthetic (native tool call)' );
};

subtest 'response_tool_calls method' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $tcs = $engine->response_tool_calls($toolcall_fixture);
    is( scalar @$tcs, 1, 'one raw tool call block' );
    is( $tcs->[0]{name}, 'get_weather', 'name from raw block' );
    is( $tcs->[0]{call_id}, 'call_abc123', 'call_id from raw block' );
};

subtest 'extract_tool_call method' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my ( $name, $args ) = $engine->extract_tool_call({
        name      => 'get_weather',
        arguments => '{"location":"Paris","units":"celsius"}',
    });
    is( $name, 'get_weather', 'name extracted' );
    is_deeply( $args, { location => 'Paris', units => 'celsius' }, 'args decoded from JSON string' );

    # Already decoded args
    ( $name, $args ) = $engine->extract_tool_call({
        name      => 'echo',
        arguments => { message => 'hello' },
    });
    is( $name, 'echo', 'name extracted' );
    is_deeply( $args, { message => 'hello' }, 'args passed through when HashRef' );
};

subtest 'ToolCall->extract works on Responses format' => sub {
    my @tcs = Langertha::ToolCall->extract($toolcall_fixture);
    is( scalar @tcs, 1, 'one ToolCall extracted' );
    is( $tcs[0]->name, 'get_weather', 'name correct' );
    is_deeply( $tcs[0]->arguments, { location => 'Paris, France', units => 'celsius' },
        'arguments correct' );
};

# The shape the real OpenAI Responses endpoint returns for gpt-5.5-pro:
# function_call is a top-level output[] entry, NOT nested under message.content[].
# Regression test for the 0.501 bug where this shape returned 0 tool calls.
subtest 'chat_response handles top-level function_call (real API shape)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $mock_response = _build_mock_response($toolcall_toplevel_fixture);
    my $resp = $engine->chat_response($mock_response);

    ok( $resp->has_tool_calls, 'top-level function_call produces tool_calls' );
    is( scalar @{$resp->tool_calls}, 1, 'exactly one tool call' );

    my $tc = $resp->tool_call;
    is( $tc->name, 'get_weather', 'name extracted from top-level item' );
    is_deeply( $tc->arguments, { location => 'Berlin, Germany', units => 'celsius' },
        'arguments parsed' );
    is( $tc->id, 'call_real789', 'call_id from top-level item' );
};

subtest 'response_tool_calls handles top-level function_call' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $tcs = $engine->response_tool_calls($toolcall_toplevel_fixture);
    is( scalar @$tcs, 1, 'one raw tool call collected' );
    is( $tcs->[0]{name}, 'get_weather', 'name from top-level item' );
    is( $tcs->[0]{call_id}, 'call_real789', 'call_id from top-level item' );
};

subtest 'ToolCall->extract handles top-level function_call' => sub {
    my @tcs = Langertha::ToolCall->extract($toolcall_toplevel_fixture);
    is( scalar @tcs, 1, 'one ToolCall extracted from top-level shape' );
    is( $tcs[0]->name, 'get_weather', 'name correct' );
    is( $tcs[0]->id, 'call_real789', 'call_id correct' );
};

subtest 'response_text_content' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $text = $engine->response_text_content($text_fixture);
    is( $text, 'Hello! How are you?', 'text extracted from output_text blocks' );
};

subtest 'format_tool_results' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $results = [
        {
            tool_call => { call_id => 'call_abc123', name => 'get_weather' },
            result    => { content => [{ type => 'text', text => 'Sunny, 22C' }] },
        },
    ];

    my $messages = $engine->format_tool_results($toolcall_fixture, $results);
    is( scalar @$messages, 1, 'one result message' );
    is( $messages->[0]{role}, 'tool', 'role is tool' );
    is( $messages->[0]{call_id}, 'call_abc123', 'call_id preserved' );
};

subtest 'format_tools - flat tool format' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $mcp_tools = [
        {
            name        => 'echo',
            description => 'Echo the input',
            inputSchema => {
                type       => 'object',
                properties => { msg => { type => 'string' } },
            },
        },
    ];

    my $formatted = $engine->format_tools($mcp_tools);
    is( scalar @$formatted, 1, 'one tool' );
    is( $formatted->[0]{type}, 'function', 'type is function' );
    is( $formatted->[0]{name}, 'echo', 'name top-level' );
    ok( !exists $formatted->[0]{function}, 'no nested function wrapper' );
    is( $formatted->[0]{parameters}{type}, 'object', 'parameters passed through' );
};

subtest 'no tools in request when not provided' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    my $request = $engine->chat_request([
        { role => 'user', content => 'Hello' },
    ]);
    my $body = $json->decode( $request->content );
    ok( !$body->{tools}, 'no tools when not provided' );
    ok( !$body->{tool_choice}, 'no tool_choice when not provided' );
};

# Helper to build a mock HTTP::Response-like object
sub _build_mock_response {
    my ($data) = @_;
    require HTTP::Response;
    my $json_text = $json->encode($data);
    return HTTP::Response->new(
        200,
        'OK',
        [ 'Content-Type' => 'application/json' ],
        $json_text,
    );
}

done_testing;