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

# Load fixtures. Convention (karr k101, mirroring the Ollama block in
# t/70_response.t): the file bytes go into the HTTP body verbatim via
# slurp_raw, so chat_response is fed what a server sends rather than a
# decode + re-encode round trip that quietly normalizes the wire. The decoded
# copies below exist only for the assertions that take a HashRef directly
# (response_tool_calls, format_tool_results, ToolCall->extract).
my $data_dir = path(__FILE__)->parent->child('data');

my $text_bytes             = $data_dir->child('responses_api_text.json')->slurp_raw;
my $toolcall_bytes         = $data_dir->child('responses_api_toolcall.json')->slurp_raw;
my $toolcall_toplevel_bytes = $data_dir->child('responses_api_toolcall_toplevel.json')->slurp_raw;

my $text_fixture              = $json->decode($text_bytes);
my $toolcall_fixture          = $json->decode($toolcall_bytes);
my $toolcall_toplevel_fixture = $json->decode($toolcall_toplevel_bytes);

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
    # A gpt-5.x reasoning model 400s on a non-default temperature while reasoning
    # is active (karr k155), so temperature only reaches the wire once reasoning
    # is turned off. gpt-5.5-pro accepts reasoning_effort=none, which is exactly
    # that escape; the temperature gate is exercised in full in
    # t/79_openai_temperature_reasoning_gate.t.
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key          => 'test-key',
        model            => 'gpt-5.5-pro',
        temperature      => 0.7,
        reasoning_effort => 'none',
        response_size    => 1024,
    );
    my $request = $engine->chat_request([
        { role => 'user', content => 'Hello' },
    ]);
    my $body = $json->decode( $request->content );
    is( $body->{temperature}, 0.7, 'temperature in body (reasoning disabled)' );
    is( $body->{max_output_tokens}, 1024, 'Responses API uses max_output_tokens' );
    ok( !exists $body->{max_tokens}, 'no legacy max_tokens key (Responses wants max_output_tokens)' );
};

subtest 'chat_request - reasoning_effort (nested)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key          => 'test-key',
        model            => 'gpt-5.5-pro',
        reasoning_effort => 'high',
    );
    my $body = $json->decode(
        $engine->chat_request([{ role => 'user', content => 'Hello' }])->content
    );
    is_deeply( $body->{reasoning}, { effort => 'high' },
        'Responses emits nested reasoning:{effort}' );

    my $plain = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key', model => 'gpt-5.5-pro',
    );
    my $pbody = $json->decode(
        $plain->chat_request([{ role => 'user', content => 'Hello' }])->content
    );
    ok( !exists $pbody->{reasoning}, 'no reasoning when reasoning_effort unset' );
};

# karr #141 part 1: the Responses API has no response_format param. Structured
# output goes under text.format, and the json_schema object is FLAT there (the
# Chat Completions json_schema wrapper is pulled up one level).
subtest 'chat_request - response_format json_schema -> text.format (flat)' => sub {
    my $schema = {
        type       => 'object',
        properties => { answer => { type => 'string' } },
        required   => ['answer'],
        additionalProperties => JSON->false,
    };
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
        response_format => {
            type        => 'json_schema',
            json_schema => {
                name   => 'answer_schema',
                schema => $schema,
                strict => JSON->true,
            },
        },
    );
    my $body = $json->decode(
        $engine->chat_request([{ role => 'user', content => 'Hi' }])->content
    );

    ok( !exists $body->{response_format},
        'no response_format key on the Responses wire' );
    ok( $body->{text}{format}, 'text.format present' );
    is( $body->{text}{format}{type}, 'json_schema', 'text.format.type is json_schema' );
    is( $body->{text}{format}{name}, 'answer_schema', 'json_schema name lifted flat' );
    ok( $body->{text}{format}{strict}, 'strict lifted flat and true' );
    ok( !exists $body->{text}{format}{json_schema},
        'no nested json_schema wrapper on the Responses wire' );
    is( $json->encode( $body->{text}{format}{schema} ), $json->encode($schema),
        'schema lifted flat (not nested), byte-identical to the input schema' );
};

# JSON-mode: text.format carries a bare type, still no response_format key.
subtest 'chat_request - response_format json_object -> text.format' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
        response_format => { type => 'json_object' },
    );
    my $body = $json->decode(
        $engine->chat_request([{ role => 'user', content => 'Hi' }])->content
    );
    ok( !exists $body->{response_format}, 'no response_format key' );
    is( $body->{text}{format}{type}, 'json_object', 'text.format.type is json_object' );
};

# Per-request control beats the engine attribute (same precedence as before),
# and with no response_format at all there is no text field on the wire.
subtest 'chat_request - response_format via controls, and absent' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $body = $json->decode(
        $engine->chat_request(
            [{ role => 'user', content => 'Hi' }],
            controls => { response_format => { type => 'json_object' } },
        )->content
    );
    is( $body->{text}{format}{type}, 'json_object',
        'per-request control response_format lands under text.format' );
    ok( !exists $body->{response_format}, 'no response_format key from the control path' );

    my $plain = $json->decode(
        $engine->chat_request([{ role => 'user', content => 'Hi' }])->content
    );
    ok( !exists $plain->{text}, 'no text field when no response_format is set' );
    ok( !exists $plain->{response_format}, 'no response_format field either' );
};

# karr #141 part 2: stream_format returns undef, so the engine must not
# advertise streaming even though it inherits Role::Streaming via Engine::OpenAI.
subtest 'streaming capability is off (stream_format undef)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    ok( !$engine->supports('streaming'), 'streaming capability off' );
    ok( !$engine->engine_capabilities->{streaming}, 'no streaming flag in registry' );
    # The json_schema structured-output capability is genuinely native here and
    # must remain advertised (it was only emitted under the wrong wire key).
    ok( $engine->supports('response_format_json_schema'),
        'response_format_json_schema stays advertised' );
    ok( $engine->supports('chat'), 'chat capability intact' );
};

subtest 'chat_response - text response' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    # Build a mock HTTP response object from the fixture bytes
    my $mock_response = _build_mock_response($text_bytes);

    my $resp = eval { $engine->chat_response($mock_response) };
    # Definedness, not truth: a tool-call-only Response has empty content and
    # stringifies false, so ok($resp) would be the wrong gate here (karr k101).
    ok( defined $resp, 'Response constructed, no type-constraint croak' ) or diag($@);
    return unless defined $resp;

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

    my $mock_response = _build_mock_response($text_bytes);
    my $resp = eval { $engine->chat_response($mock_response) };
    ok( defined $resp, 'Response constructed, no type-constraint croak' ) or diag($@);
    return unless defined $resp;

    is( $resp->thinking, 'The user is asking for a simple greeting',
        'thinking from reasoning summary' );
};

subtest 'chat_response - tool call extraction' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $mock_response = _build_mock_response($toolcall_bytes);
    my $resp = eval { $engine->chat_response($mock_response) };
    ok( defined $resp, 'Response constructed, no type-constraint croak' ) or diag($@);
    return unless defined $resp;

    ok( $resp->has_tool_calls, 'tool_calls present' );
    is( scalar @{$resp->tool_calls}, 1, 'one tool call' );

    my $tc = $resp->tool_call;
    is( $tc->name, 'get_weather', 'tool name extracted' );
    is_deeply( $tc->arguments, { location => 'Paris, France', units => 'celsius' },
        'arguments parsed from JSON string' );
    is( $tc->id, 'call_abc123', 'call_id from function_call block' );
    ok( !$tc->synthetic, 'not synthetic (native tool call)' );

    # k171: this fixture wraps the function_call in a status:completed message
    # item. The completed message would set finish_reason 'stop', but a response
    # carrying a tool call must report 'tool_calls' (OpenAI convention).
    is( $resp->finish_reason, 'tool_calls',
        'tool call in a completed message reports finish_reason tool_calls, not stop' );
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
    my @tcs = Langertha::ToolCall->extract('responses', $toolcall_fixture);
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

    my $mock_response = _build_mock_response($toolcall_toplevel_bytes);
    my $resp = eval { $engine->chat_response($mock_response) };
    ok( defined $resp, 'Response constructed, no type-constraint croak' ) or diag($@);
    return unless defined $resp;

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
    my @tcs = Langertha::ToolCall->extract('responses', $toolcall_toplevel_fixture);
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

# karr #85: format_tool_results returns a LIST for every tool_wire_format --
# all three tool loops do `push @$conversation, $engine->format_tool_results(...)`.
# The Responses envelope is a flat item list: the model's own output items echoed
# back (the assistant echo), then one function_call_output per result. The API
# rejects a function_call_output whose call_id was never announced by a
# preceding TOP-LEVEL function_call item, so a call nested inside a message item
# (the legacy shape ToolCall->locate also walks) must be hoisted out.
subtest 'format_tool_results - nested function_call shape' => sub {
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

    my @messages = $engine->format_tool_results($toolcall_fixture, $results);
    ok( scalar @messages, 'returns a list, not a single arrayref' );
    is( scalar( grep { ref $_ ne 'HASH' } @messages ), 0,
        'every element is a plain hashref the input builder can walk' );

    is( scalar @messages, 2, 'assistant echo + one function_call_output' );
    is( $messages[0]{type}, 'function_call',
        'echo hoists the nested function_call to a top-level item' );
    is( $messages[0]{call_id}, 'call_abc123', 'echo carries the call_id' );
    is( $messages[0]{name}, 'get_weather', 'echo carries the tool name' );

    is( $messages[1]{type}, 'function_call_output', 'result is a function_call_output item' );
    is( $messages[1]{call_id}, 'call_abc123', 'call_id preserved' );
    ok( !exists $messages[1]{role}, 'no role key -- input items are not chat messages' );
    like( $messages[1]{output}, qr/Sunny, 22C/, 'tool output encoded into output' );
};

subtest 'format_tool_results - top-level function_call shape' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $results = [
        {
            tool_call => { call_id => 'call_real789', name => 'get_weather' },
            result    => { content => [{ type => 'text', text => 'Rainy, 9C' }] },
        },
    ];

    my @messages = $engine->format_tool_results($toolcall_toplevel_fixture, $results);
    is( scalar @messages, 3, 'reasoning + function_call echoed, then the output' );
    is( $messages[0]{type}, 'reasoning',
        'reasoning item echoed in place -- it must keep its following item' );
    is( $messages[1]{type}, 'function_call', 'function_call echoed verbatim' );
    is( $messages[1]{call_id}, 'call_real789', 'echoed call_id' );
    is( $messages[2]{type}, 'function_call_output', 'then the matching output' );
    is( $messages[2]{call_id}, 'call_real789', 'output pairs with the echoed call' );
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

# k171: a text preamble message coexisting with a tool call. The real Responses
# API emits an assistant text message and then a function_call in the same
# output[] (the model narrates before calling). The completed message sets
# finish_reason 'stop', but the tool call must win -> 'tool_calls', independent
# of output[] ordering. Regression: the message branch used to overwrite the
# tool-call finish_reason unconditionally.
subtest 'chat_response - message preamble + function_call -> tool_calls (k171)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    # message BEFORE the call (the common ordering: narrate, then call).
    my $before = {
        id => 'resp_mix1', model => 'gpt-5.5-pro', status => 'completed',
        output => [
            { type => 'message', status => 'completed', role => 'assistant',
              content => [ { type => 'output_text', text => 'Let me check the weather.' } ] },
            { type => 'function_call', id => 'fc1', call_id => 'call_mix1',
              name => 'get_weather', arguments => '{"location":"Paris"}', status => 'completed' },
        ],
        usage => { input_tokens => 5, output_tokens => 5, total_tokens => 10 },
    };
    my $resp = $engine->chat_response( _build_mock_response( $json->encode($before) ) );
    is( $resp->content, 'Let me check the weather.', 'preamble text preserved' );
    ok( $resp->has_tool_calls, 'tool call present alongside the message' );
    is( $resp->finish_reason, 'tool_calls',
        'message-then-call reports tool_calls, not the message stop' );

    # message AFTER the call (ordering-independence: the fix must not depend on
    # the call coming first).
    my $after = {
        id => 'resp_mix2', model => 'gpt-5.5-pro', status => 'completed',
        output => [
            { type => 'function_call', id => 'fc2', call_id => 'call_mix2',
              name => 'get_weather', arguments => '{"location":"Berlin"}', status => 'completed' },
            { type => 'message', status => 'completed', role => 'assistant',
              content => [ { type => 'output_text', text => 'Done.' } ] },
        ],
        usage => { input_tokens => 5, output_tokens => 5, total_tokens => 10 },
    };
    my $resp2 = $engine->chat_response( _build_mock_response( $json->encode($after) ) );
    is( $resp2->finish_reason, 'tool_calls',
        'call-then-message also reports tool_calls (no output[] ordering dependence)' );

    # No tool call: a plain completed message still reports stop.
    my $plain = {
        id => 'resp_plain', model => 'gpt-5.5-pro', status => 'completed',
        output => [
            { type => 'message', status => 'completed', role => 'assistant',
              content => [ { type => 'output_text', text => 'Hi.' } ] },
        ],
        usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 },
    };
    my $resp3 = $engine->chat_response( _build_mock_response( $json->encode($plain) ) );
    is( $resp3->finish_reason, 'stop', 'plain message without a tool call stays stop' );
};

# k168: a Responses payload without output_tokens_details must not autovivify an
# empty output_tokens_details block into raw.usage (the trace hash). chat_response
# read $usage->{output_tokens_details}{reasoning_tokens} directly, autovivifying
# the missing intermediate into $data->{usage} (the same ref as Response.raw).
subtest 'chat_response - no output_tokens_details, no raw.usage autoviv (k168)' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );

    my $payload = {
        id => 'resp_noreason', model => 'gpt-5.5-pro', status => 'completed',
        output => [
            { type => 'message', status => 'completed', role => 'assistant',
              content => [ { type => 'output_text', text => 'plain' } ] },
        ],
        usage => { input_tokens => 3, output_tokens => 4, total_tokens => 7 },
    };
    my $resp = $engine->chat_response( _build_mock_response( $json->encode($payload) ) );

    ok( $resp->has_raw, 'raw present' );
    ok( !exists $resp->raw->{usage}{output_tokens_details},
        'output_tokens_details NOT autovivified into raw.usage when absent' );
    ok( !exists $resp->usage->{completion_tokens_details},
        'no phantom completion_tokens_details when no reasoning_tokens' );

    # The reasoning-carrying fixture still normalizes reasoning_tokens.
    my $with = $engine->chat_response( _build_mock_response($text_bytes) );
    is( $with->usage->{completion_tokens_details}{reasoning_tokens}, 18,
        'reasoning_tokens still normalized when output_tokens_details IS present' );
};

# Helper to build a mock HTTP::Response from the fixture bytes verbatim.
# karr k211: a reasoning output item that carries no summary text must reach
# Response.raw exactly as the server sent it. chat_response used to read
# $item->{summary}[0]{text} as a chained rvalue, which autovivified
# summary => [{}] into the item -- raw is the same ref as the decoded body, so
# the trace claimed a summary block the provider never sent (the k168 bug
# class). OpenAI sends summary => [] when it has no summary (the verbatim
# capture responses_api_toolcall_toplevel.json); xAI's encrypted-only
# reasoning omits the field altogether. No capture of the omitted case exists,
# so the second case is derived from that same capture by deleting "summary".
subtest 'chat_response - summary-less reasoning item is not rewritten in raw' => sub {
    my $engine = Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key',
        model   => 'gpt-5.5-pro',
    );
    my $absent = $json->decode($toolcall_toplevel_bytes);
    delete $absent->{output}[0]{summary};

    for my $case (
        [ 'summary => [] (verbatim capture)' => $toolcall_toplevel_bytes ],
        [ 'summary omitted (derived)'        => $json->encode($absent) ],
    ) {
        my ( $label, $bytes ) = @$case;
        my $want = $json->decode($bytes)->{output}[0];
        my $resp = $engine->chat_response( _build_mock_response($bytes) );
        is_deeply( $resp->raw->{output}[0], $want, "$label: reasoning item unchanged in raw" );
        ok( !$resp->has_thinking, "$label: no thinking invented" );
    }
};

sub _build_mock_response {
    my ($body) = @_;
    require HTTP::Response;
    return HTTP::Response->new(
        200,
        'OK',
        [ 'Content-Type' => 'application/json' ],
        $body,
    );
}

done_testing;