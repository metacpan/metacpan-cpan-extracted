#!/usr/bin/env perl
# ABSTRACT: Perplexity Agent API client function tools: Role::Tools, no tool_choice, echo filter (k213)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Future;
use HTTP::Response;
use Path::Tiny qw( path );

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::Perplexity;
use Langertha::Engine::OpenAIResponses;

# karr k213 / ADR 0020 (k213 Update), ADR 0005: the Agent API (POST /v1/agent)
# takes client-executed type:function tools. The model answers with a top-level
# function_call output item; the client sends back function_call_output items by
# call_id. Engine::Perplexity said "NO tool calling" -- stale since the move to
# /v1/agent (k139). What has to hold, and why:
#
#   - Perplexity composes Role::Tools (tools_native, the 'responses' tool wire),
#     so chat_f and chat_with_tools_f send the tools and read the calls back.
#   - The Agent request schema has NO tool_choice and NO parallel_tool_calls,
#     so every tool_choice_* flag and parallel_tool_use are cleared and neither
#     field ever reaches the wire. With tool_choice_named cleared, the ADR 0005
#     direction-1 rewrite (forced tool -> json_schema + synthetic ToolCall) still
#     fires: Perplexity stays its exemplar.
#   - The Agent input is a closed oneOf: message | function_call |
#     function_call_output, message parts only input_text / input_image. The
#     plain Responses echo replays every output[] item, which on a preset turn
#     includes search_results / fetch_url_results / mcp_* items and an assistant
#     message whose parts are output_text -- all off-schema as input. The
#     ResponsesCompatible hook _responses_echo_item filters them on Perplexity;
#     OpenAIResponses keeps the verbatim echo.
#
# The hand-written payloads in the first half are built from the documented
# shapes (the OpenAPI for POST /v1/agent and
# docs.perplexity.ai/docs/agent-api/tools/custom-functions, fetched 2026-09-25,
# karr k213). They keep covering what the live model did not produce on its own:
# fetch_url_results / mcp_* items, a thought_signature, a nested call.
#
# The second half replays verbatim live captures (karr k232, 2026-09-29, preset
# fast -> openai/gpt-6-luna, t/data/perplexity_agent_*): the function_call turn,
# its echo turn, the same echo with no tools (the k233 question), the streamed
# function_call turn, a search turn with a function tool offered, and the echo
# of a mixed preset turn. Each .request.json is the body Langertha built and
# Perplexity answered with HTTP 200, so the request tests assert Langertha still
# builds exactly that body: the echo shapes are live-verified, not just
# documented.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub ppx { Langertha::Engine::Perplexity->new( api_key => 'test-key', model => 'sonar', @_ ) }
sub body_of { $json->decode( $_[0]->content ) }

my $mcp_tool = {
    name        => 'get_weather',
    description => 'Weather for a city',
    inputSchema => { type => 'object', properties => { city => { type => 'string' } },
                     required => ['city'] },
};

# Documented function_call output item (custom-functions docs): top-level,
# fc_ id, call_id, JSON-string arguments, status, optional thought_signature.
my $fc_item = {
    type => 'function_call', id => 'fc_001', call_id => 'call_abc',
    name => 'get_weather', arguments => '{"city":"Berlin"}', status => 'completed',
    thought_signature => 'sig-xyz',
};

# A preset turn: presets merge their web_search with the caller's function tool,
# so one turn can carry search results, a message preamble and the call.
my $turn1 = {
    id => 'resp_1', object => 'response', model => 'openai/gpt-5.6-luna', status => 'completed',
    output => [
        { type => 'search_results', results => [ { id => 1, url => 'https://w.example/berlin', title => 'Berlin weather' } ] },
        { type => 'fetch_url_results', contents => [ { url => 'https://w.example/berlin', text => '...' } ] },
        { type => 'message', id => 'msg_1', role => 'assistant', status => 'completed',
          content => [ { type => 'output_text', text => 'Let me check.', annotations => [] } ] },
        $fc_item,
    ],
    usage => { input_tokens => 10, output_tokens => 5, total_tokens => 15 },
};
my $turn2 = {
    id => 'resp_2', object => 'response', model => 'openai/gpt-5.6-luna', status => 'completed',
    output => [ { type => 'message', id => 'msg_2', role => 'assistant', status => 'completed',
        content => [ { type => 'output_text', text => 'Sunny, 21C.', annotations => [] } ] } ],
    usage => { input_tokens => 20, output_tokens => 4, total_tokens => 24 },
};

subtest 'composition and capabilities' => sub {
    my $engine = ppx();
    ok( $engine->does('Langertha::Role::Tools'), 'Perplexity composes Role::Tools' );
    is( $engine->tool_wire_format, 'responses', 'tool wire is responses (ResponsesCompatible builder wins)' );
    my $caps = $engine->engine_capabilities;
    ok( $caps->{tools_native}, 'tools_native' );
    ok( !$caps->{$_}, "$_ cleared (no tool_choice in the Agent schema)" )
        for qw( tool_choice_auto tool_choice_any tool_choice_none tool_choice_named );
    ok( !$caps->{parallel_tool_use}, 'parallel_tool_use cleared (no parallel_tool_calls field)' );
    ok( !$caps->{server_tools}, 'no server_tools (built-ins are k206 Phase 2)' );
    ok( $caps->{response_format_json_schema}, 'json_schema stays (direction-1 target)' );
};

subtest 'request: flat function tools, never tool_choice or parallel_tool_calls' => sub {
    for my $builder (qw( chat_request chat_stream_request )) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $body = body_of( ppx()->$builder( [ { role => 'user', content => 'weather?' } ],
            tools => [$mcp_tool], tool_choice => 'auto',
            controls => { parallel_tool_use => 1 } ) );
        is_deeply( $body->{tools}, [ { type => 'function', name => 'get_weather',
            description => 'Weather for a city', parameters => $mcp_tool->{inputSchema} } ],
            "$builder: MCP tool formatted to the flat function shape" );
        ok( !exists $body->{tool_choice}, "$builder: tool_choice auto not sent" );
        ok( !exists $body->{parallel_tool_calls}, "$builder: parallel_tool_calls not sent" );
        ok( !( grep { /tool_choice/ } @warns ), "$builder: dropping auto is silent (it is the default)" )
            or diag @warns;
        # A parallel_tool_use the caller set is dropped loudly (k241, ADR 0025 drop+carp).
        ok( ( grep { /dropping parallel_tool_use/ } @warns ), "$builder: dropping a set parallel_tool_use carps" )
            or diag @warns;

        @warns = ();
        $body = body_of( ppx()->$builder( [ { role => 'user', content => 'weather?' } ],
            tools => [$mcp_tool], tool_choice => { type => 'tool', name => 'get_weather' } ) );
        ok( !exists $body->{tool_choice}, "$builder: forced tool_choice not sent" );
        ok( ( grep { /dropping tool_choice/ } @warns ), "$builder: dropping a forced choice carps" );
    }
    # OpenAIResponses supports tool_choice: unchanged, still sent.
    my $body = body_of( Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6-luna' )
        ->chat_request( [ { role => 'user', content => 'x' } ], tools => [$mcp_tool], tool_choice => 'auto' ) );
    is( $body->{tool_choice}, 'auto', 'OpenAIResponses still sends tool_choice' );
};

# karr k233 / ADR 0020 (k233 Update): tool_choice => 'none' means "call no
# tool". An engine that cannot send 'none' (Perplexity has no tool_choice
# field) would otherwise ship the tools with no restriction, and the model could
# call a tool the caller ruled out. The caller's intent is honored by
# withholding every tool for that request -- function tools, native built-in
# hashes and server-tool defaults alike, since 'none' covers them all.
{
    package K233::NoNone;
    use Moose;
    extends 'Langertha::Engine::OpenAIResponses';
    around engine_capabilities => sub {
        my ( $orig, $self, @rest ) = @_;
        my $caps = $self->$orig(@rest);
        delete $caps->{tool_choice_none};
        return $caps;
    };
    __PACKAGE__->meta->make_immutable;
}

subtest "tool_choice 'none' the engine cannot send withholds the tools (k233)" => sub {
    for my $builder (qw( chat_request chat_stream_request )) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $body = body_of( ppx()->$builder( [ { role => 'user', content => 'weather?' } ],
            tools => [ $mcp_tool, { type => 'web_search' } ], tool_choice => 'none',
            controls => { parallel_tool_use => 1 } ) );
        ok( !exists $body->{tools}, "$builder: no tools sent" );
        ok( !exists $body->{tool_choice}, "$builder: no tool_choice sent" );
        ok( !exists $body->{parallel_tool_calls}, "$builder: no parallel_tool_calls sent" );
        ok( ( grep { /tool_choice 'none'.*withh[oe]ld/ } @warns ), "$builder: carps that the tools were withheld" )
            or diag @warns;
    }

    # Server-tool defaults are withheld as well: 'none' rules out every tool call.
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $body = body_of( K233::NoNone->new( api_key => 'k', model => 'gpt-5.6-luna',
        server_tools => [ { type => 'web_search' } ] )
        ->chat_request( [ { role => 'user', content => 'x' } ], tools => [$mcp_tool], tool_choice => 'none' ) );
    ok( !exists $body->{tools}, 'no function tools and no server-tool defaults' );
    ok( !exists $body->{tool_choice}, 'no tool_choice' );

    # Where 'none' can be sent, it is, with the tools: unchanged.
    $body = body_of( Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6-luna' )
        ->chat_request( [ { role => 'user', content => 'x' } ], tools => [$mcp_tool], tool_choice => 'none' ) );
    is( $body->{tool_choice}, 'none', "OpenAIResponses sends tool_choice 'none'" );
    is( scalar @{ $body->{tools} }, 1, 'OpenAIResponses keeps the tools alongside it' );
};

# karr k233 / ADR 0020 (k233 Update): a tool_choice ToolChoice cannot read
# (a provider-native hosted-tool choice such as web_search_preview) is the
# provider's to judge -- but only where the wire has a tool_choice field. On
# Perplexity there is none, so passing it through is a certain 400: drop + carp.
subtest 'unreadable tool_choice: dropped where there is no field, passed through elsewhere (k233)' => sub {
    my $native = { type => 'web_search_preview' };
    for my $builder (qw( chat_request chat_stream_request )) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $body = body_of( ppx()->$builder( [ { role => 'user', content => 'x' } ],
            tools => [$mcp_tool], tool_choice => $native ) );
        ok( !exists $body->{tool_choice}, "$builder: unreadable choice not sent on Perplexity" );
        ok( ( grep { /dropping tool_choice/ } @warns ), "$builder: dropping it carps" ) or diag @warns;
        is( scalar @{ $body->{tools} }, 1, "$builder: tools still sent" );
    }
    my $body = body_of( Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6-luna' )
        ->chat_request( [ { role => 'user', content => 'x' } ], tools => [$mcp_tool], tool_choice => $native ) );
    is_deeply( $body->{tool_choice}, $native, 'OpenAIResponses passes the unreadable choice through' );
};

subtest 'chat_f: native tools, function_call lands on Response.tool_calls' => sub {
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($turn1) ] );
    my $resp = ppx( _async_http => $mock )->chat_f(
        messages => [ { role => 'user', content => 'weather in Berlin?' } ],
        tools    => [$mcp_tool],
    )->get;
    my ($sent) = $mock->requests;
    my $body = body_of($sent);
    is( $body->{tools}[0]{name}, 'get_weather', 'tool on the wire' );
    ok( !exists $body->{response_format}, 'not rewritten: no forced choice' );
    ok( !exists $body->{tool_choice}, 'no tool_choice' );
    my $tc = $resp->tool_call('get_weather');
    ok( $tc, 'ToolCall present' );
    ok( !$tc->synthetic, 'native, not synthetic' );
    is( $tc->id, 'call_abc', 'id is the call_id' );
    is_deeply( $tc->arguments, { city => 'Berlin' }, 'JSON-string arguments decoded' );
    is( $resp->finish_reason, 'tool_calls', 'finish_reason tool_calls' );
    is( scalar @{ $resp->citations // [] }, 1, 'search_results still lift to citations' );
};

subtest 'ADR 0005 direction 1 still fires with Role::Tools composed' => sub {
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( {
        id => 'resp_3', model => 'sonar', status => 'completed',
        output => [ { type => 'message', status => 'completed',
            content => [ { type => 'output_text', text => '{"city":"Berlin"}' } ] } ],
        usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 },
    } ) ] );
    my $engine = ppx( _async_http => $mock );
    ok( $engine->supports('tools_native') && !$engine->supports('tool_choice_named'),
        'precondition: tools yes, named choice no' );
    my $resp = $engine->chat_f(
        messages    => [ { role => 'user', content => 'Which city?' } ],
        tools       => [$mcp_tool],
        tool_choice => { type => 'tool', name => 'get_weather' },
    )->get;
    my $body = body_of( ( $mock->requests )[0] );
    ok( !exists $body->{tools} && !exists $body->{tool_choice}, 'tools and tool_choice rewritten away' );
    is( $body->{response_format}{type}, 'json_schema', 'top-level response_format json_schema' );
    my $tc = $resp->tool_call('get_weather');
    ok( $tc && $tc->synthetic, 'synthetic ToolCall' );
    is_deeply( $tc && $tc->arguments, { city => 'Berlin' }, 'structured args' );
};

sub assert_agent_input {
    my ( $input, $label ) = @_;
    my %allowed = map { $_ => 1 } qw( message function_call function_call_output );
    for my $item (@$input) {
        ok( $allowed{ $item->{type} // '' }, "$label: input item type '" . ( $item->{type} // 'undef' ) . "' is on the Agent schema" );
        next unless ( $item->{type} // '' ) eq 'message' && ref $item->{content} eq 'ARRAY';
        for my $part ( @{ $item->{content} } ) {
            like( $part->{type} // '', qr/\Ainput_(?:text|image)\z/, "$label: message part $part->{type}" );
        }
    }
}

subtest 'echo filter: format_tool_results on Perplexity' => sub {
    my $engine  = ppx();
    my @results = ( { tool_call => $fc_item,
        result => { content => [ { type => 'text', text => 'Sunny, 21C' } ] } } );
    my @echo = $engine->format_tool_results( $turn1, \@results );
    is_deeply( \@echo, [
        { type => 'message', role => 'assistant', content => 'Let me check.' },
        $fc_item,
        { type => 'function_call_output', call_id => 'call_abc',
          output => 'Sunny, 21C' },
    ], 'search/fetch results dropped, message flattened to text, function_call kept verbatim (thought_signature too)' );

    # mcp_* items and an empty preamble are dropped; a legacy nested call is hoisted then kept.
    my $data = { output => [
        { type => 'mcp_list_tools', server_label => 's', tools => [] },
        { type => 'mcp_call', id => 'mcp_1', name => 'x', arguments => '{}', output => 'y' },
        { type => 'finance_results', results => [] },
        { type => 'message', role => 'assistant', status => 'completed', content => [ $fc_item ] },
    ] };
    @echo = $engine->format_tool_results( $data, \@results );
    is_deeply( [ map { $_->{type} } @echo ], [qw( function_call function_call_output )],
        'mcp_* / *_results dropped, empty message dropped, nested call hoisted' );

    # OpenAIResponses keeps the verbatim echo (default hook passes through).
    my @verbatim = Langertha::Engine::OpenAIResponses->new( api_key => 'k' )
        ->format_tool_results( $turn1, \@results );
    is_deeply( \@verbatim, [
        @{ $turn1->{output} },
        { type => 'function_call_output', call_id => 'call_abc',
          output => 'Sunny, 21C' },
    ], 'OpenAIResponses echoes all four output items verbatim, in order, plus the result' );
};

{
    package K213::MCP;
    sub new { bless { calls => [] }, shift }
    sub list_tools { Future->done( [$mcp_tool] ) }
    sub call_tool {
        my ( $self, $name, $input ) = @_;
        push @{ $self->{calls} }, [ $name, $input ];
        return Future->done( { content => [ { type => 'text', text => 'Sunny, 21C' } ] } );
    }
}

subtest 'chat_with_tools_f end to end (mocked HTTP)' => sub {
    my $mcp  = K213::MCP->new;
    my $mock = Test::MockAsyncHTTP->new( responses => [
        Test::MockAsyncHTTP->mock_json_response($turn1),
        Test::MockAsyncHTTP->mock_json_response($turn2),
    ] );
    my $engine = ppx( _async_http => $mock, mcp_servers => [$mcp] );
    my $text = $engine->chat_with_tools_f('Weather in Berlin?')->get;
    is( $text, 'Sunny, 21C.', 'final text after one tool round' );
    is_deeply( $mcp->{calls}, [ [ get_weather => { city => 'Berlin' } ] ], 'tool executed once with decoded args' );
    is( $mock->request_count, 2, 'two Agent requests' );

    my ( $r1, $r2 ) = map { body_of($_) } $mock->requests;
    for my $pair ( [ first => $r1 ], [ second => $r2 ] ) {
        my ( $label, $body ) = @$pair;
        is( $body->{preset}, 'fast', "$label: preset" );
        is( $body->{tools}[0]{type}, 'function', "$label: function tool sent" );
        ok( !exists $body->{tool_choice} && !exists $body->{parallel_tool_calls},
            "$label: no tool_choice / parallel_tool_calls" );
        assert_agent_input( $body->{input}, $label );
    }
    is_deeply( [ map { $_->{type} } @{ $r2->{input} } ],
        [qw( message message function_call function_call_output )],
        'second turn: user, assistant preamble, the call, its output' );
    is( $r2->{input}[1]{content}, 'Let me check.', 'assistant preamble echoed as text' );
    is( $r2->{input}[2]{thought_signature}, 'sig-xyz', 'thought_signature kept on the echoed call' );
    is( $r2->{input}[3]{call_id}, $r2->{input}[2]{call_id}, 'output answers the call by call_id' );
};

# --- Live captures (karr k232) --------------------------------------------

my $data_dir = path(__FILE__)->parent->child('data');
sub capture_bytes { $data_dir->child( $_[0] )->slurp_raw }
sub capture       { $json->decode( capture_bytes("$_[0].json") ) }
sub capture_req   { $json->decode( capture_bytes("$_[0].request.json") ) }
sub http_ok { HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $_[0] ) }
# A captured reply as it arrived: its recorded status, headers and body bytes.
sub capture_http {
    my ($name) = @_;
    my $headers = $json->decode( capture_bytes("$name.headers.json") );
    return HTTP::Response->new( 200, 'OK', [ %$headers ], capture_bytes("$name.json") );
}

# The tool the captures offered, in the MCP shape the tool loop formats, and
# the result the capture script answered the call with.
my $cap_tool = {
    name        => 'get_weather',
    description => 'Get the current weather for a city.',
    inputSchema => { type => 'object',
        properties => { city => { type => 'string', description => 'City name' } },
        required => ['city'] },
};
my $cap_result = '{"city":"Berlin","temp_c":21,"conditions":"sunny"}';
my $cap_prompt = capture_req('perplexity_agent_function_call')->{input}[0]{content};

sub cap_ppx { ppx( response_size => 300, @_ ) }

sub reply_text { join '', map { $_->{text} } map { @{ $_->{content} } } grep { $_->{type} eq 'message' } @{ $_[0]{output} } }

# The conversation the tool loop builds for the second turn: the prompt, then
# the echo of $turn with one result per call.
sub echo_conversation {
    my ( $engine, $turn, $prompt ) = @_;
    my $reply = $engine->chat_response( http_ok( $json->encode($turn) ) );
    my @results = map { { tool_call => $_,
        result => { content => [ { type => 'text', text => $cap_result } ] } } } @{ $reply->tool_calls };
    my $conv = $engine->chat_messages( $prompt // $cap_prompt );
    push @$conv, $engine->format_tool_results( $turn, \@results );
    return $conv;
}

subtest 'capture: the function_call turn (k232)' => sub {
    my $engine = cap_ppx();
    my $req = $engine->build_tool_chat_request( $engine->chat_messages($cap_prompt),
        $engine->format_tools([$cap_tool]) );
    is_deeply( body_of($req), capture_req('perplexity_agent_function_call'),
        'Langertha builds the body Perplexity answered with a function_call' );

    my $resp = $engine->chat_response( capture_http('perplexity_agent_function_call') );
    my $tc = $resp->tool_call('get_weather');
    ok( $tc && !$tc->synthetic, 'the top-level function_call item is a native ToolCall' );
    is( $tc && $tc->id, 'call_jYNSwNK1Hq1n90240LgqMsP0', 'its id is the call_id, not the fc_ item id' );
    is_deeply( $tc && $tc->arguments, { city => 'Berlin' }, 'the JSON-string arguments decode' );
    is( $resp->finish_reason, 'tool_calls', 'finish_reason tool_calls' );
    is( $resp->content, '', 'a call-only turn carries no text' );
    is( $resp->model, 'openai/gpt-6-luna', 'the model the preset ran' );
    ok( !$resp->has_citations, 'no search ran, no citations invented' );
};

{
    package K232::MCP;
    sub new { bless { calls => [] }, shift }
    sub list_tools { Future->done( [$cap_tool] ) }
    sub call_tool {
        my ( $self, $name, $input ) = @_;
        push @{ $self->{calls} }, [ $name, $input ];
        return Future->done( { content => [ { type => 'text', text => $cap_result } ] } );
    }
}

subtest 'capture: chat_with_tools_f sends the captured turn and echo bodies (k232)' => sub {
    my $mcp  = K232::MCP->new;
    my $mock = Test::MockAsyncHTTP->new( responses => [
        capture_http('perplexity_agent_function_call'),
        capture_http('perplexity_agent_function_call_echo'),
    ] );
    my $text = cap_ppx( _async_http => $mock, mcp_servers => [$mcp] )->chat_with_tools_f($cap_prompt)->get;
    is( $text, reply_text( capture('perplexity_agent_function_call_echo') ), 'the echo turn\'s answer' );
    is_deeply( $mcp->{calls}, [ [ get_weather => { city => 'Berlin' } ] ], 'the tool ran once' );

    my @sent = map { body_of($_) } $mock->requests;
    is( scalar @sent, 2, 'two Agent requests' );
    is_deeply( $sent[0], capture_req('perplexity_agent_function_call'), 'turn 1: the captured body' );
    is_deeply( $sent[1], capture_req('perplexity_agent_function_call_echo'),
        'turn 2: the captured echo body, which Perplexity accepted' );
    # The two shapes k213 only had from the docs: the call echoed with its fc_
    # id and status, and the result as a function_call_output string.
    is_deeply( $sent[1]{input}[1], capture('perplexity_agent_function_call')->{output}[0],
        'the function_call item goes back verbatim, id and status included' );
    is_deeply( $sent[1]{input}[2], { type => 'function_call_output',
        call_id => 'call_jYNSwNK1Hq1n90240LgqMsP0', output => $cap_result },
        'the result answers it by call_id with the tool text as a string' );
    assert_agent_input( $sent[1]{input}, 'echo turn' );
};

# karr k233 asked whether the Agent API accepts earlier function_call /
# function_call_output input items when the request carries no tools -- the body
# an unsendable tool_choice 'none' produces. Live answer: yes (HTTP 200); the
# preset then ran its own web search.
subtest "capture: the echo with no tools, as tool_choice 'none' sends it (k233, k232)" => sub {
    my $engine = cap_ppx();
    my $conv = echo_conversation( $engine, capture('perplexity_agent_function_call') );
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $req = $engine->chat_request( $conv, tools => $engine->format_tools([$cap_tool]), tool_choice => 'none' );
    is_deeply( body_of($req), capture_req('perplexity_agent_function_call_echo_notools'),
        'no tools, the echo items kept: the body Perplexity accepted' );
    ok( ( grep { /tool_choice 'none'.*withh[oe]ld/ } @warns ), 'withholding the tools carps' ) or diag @warns;

    my $data = capture('perplexity_agent_function_call_echo_notools');
    my $resp = $engine->chat_response( capture_http('perplexity_agent_function_call_echo_notools') );
    is( $resp->content, reply_text($data), 'the answer' );
    ok( !$resp->has_tool_calls, 'no tool calls' );
    is( $resp->finish_reason, 'stop', 'finish_reason stop' );
    my ($search) = grep { $_->{type} eq 'search_results' } @{ $data->{output} };
    is( scalar @{ $resp->citations // [] }, scalar @{ $search->{results} }, 'the preset search lifts to citations' );
};

subtest 'capture: the streamed function_call turn (k232)' => sub {
    my $engine = cap_ppx();
    my $req = $engine->chat_stream_request( $engine->chat_messages($cap_prompt),
        tools => $engine->format_tools([$cap_tool]) );
    is_deeply( body_of($req), capture_req('perplexity_agent_function_call_stream'), 'the captured stream body' );

    # The stream sends the whole call on output_item.added and .done (no
    # arguments deltas) and again in response.completed's output[]; only the
    # terminal frame is read, so the call arrives exactly once.
    my $chunks = $engine->process_stream_data( capture_bytes('perplexity_agent_function_call_stream.sse') );
    my $calls  = $engine->aggregate_tool_calls($chunks);
    is( scalar @$calls, 1, 'one call, not three' );
    is( $calls->[0]->name, 'get_weather', 'its name' );
    is( $calls->[0]->id, 'call_8RqgmDOEQfr1nSRZIuuskyr2', 'its call_id' );
    is_deeply( $calls->[0]->arguments, { city => 'Berlin' }, 'its arguments' );
    my ($final) = grep { $_->is_final } @$chunks;
    ok( $final, 'response.completed gives the final chunk' );
    is( $final && $final->finish_reason, 'tool_calls', 'finish_reason tool_calls' );
    is( $final && $final->model, 'openai/gpt-6-luna', 'the resolved model, not the "fast" label of response.created' );
    is( join( '', map { $_->content } @$chunks ), '', 'no text' );
};

# One sample: with a function tool offered, the preset ran its web search and
# answered in text without calling the tool. The loop must end on that reply.
subtest 'capture: a preset search turn with a function tool offered (k232)' => sub {
    my $want   = capture_req('perplexity_agent_search_function_call');
    my $prompt = $want->{input}[0]{content};
    my $engine = cap_ppx();
    is_deeply( body_of( $engine->build_tool_chat_request( $engine->chat_messages($prompt),
        $engine->format_tools([$cap_tool]) ) ), $want, 'the captured body' );

    my $data = capture('perplexity_agent_search_function_call');
    my $resp = $engine->chat_response( capture_http('perplexity_agent_search_function_call') );
    ok( !$resp->has_tool_calls, 'no tool calls' );
    is( $resp->finish_reason, 'stop', 'finish_reason stop' );
    my ($search) = grep { $_->{type} eq 'search_results' } @{ $data->{output} };
    is( scalar @{ $resp->citations // [] }, scalar @{ $search->{results} }, 'search_results lift to citations' );

    my $mcp  = K232::MCP->new;
    my $mock = Test::MockAsyncHTTP->new( responses => [
        capture_http('perplexity_agent_search_function_call') ] );
    my $text = cap_ppx( _async_http => $mock, mcp_servers => [$mcp] )->chat_with_tools_f($prompt)->get;
    is( $text, reply_text($data), 'chat_with_tools_f returns the text' );
    is( scalar @{ $mcp->{calls} }, 0, 'no tool ran' );
    is( $mock->request_count, 1, 'one request' );
};

# The echo filter's case: a preset turn with search_results, an assistant
# preamble and the call. The model did not produce one live, so the turn is the
# function_call capture with the search_results item of the search capture and
# a preamble message spliced in before the call. Its echo -- search_results
# dropped, preamble flattened to string content -- was sent live: HTTP 200.
subtest 'capture: the echo of a mixed preset turn (k232)' => sub {
    my $turn = capture('perplexity_agent_function_call');
    my ($search) = grep { $_->{type} eq 'search_results' }
        @{ capture('perplexity_agent_search_function_call')->{output} };
    unshift @{ $turn->{output} }, $search,
        { type => 'message', id => 'msg_k232_preamble', role => 'assistant', status => 'completed',
          content => [ { type => 'output_text', text => 'Let me check the weather tool.', annotations => [] } ] };

    my $engine = cap_ppx();
    my $conv = echo_conversation( $engine, $turn );
    my $req = $engine->build_tool_chat_request( $conv, $engine->format_tools([$cap_tool]) );
    my $body = body_of($req);
    is_deeply( $body, capture_req('perplexity_agent_mixed_echo'), 'the body Perplexity accepted' );
    is_deeply( [ map { $_->{type} } @{ $body->{input} } ],
        [qw( message message function_call function_call_output )],
        'user, flattened preamble, the call, its output: search_results left out' );
    is( $body->{input}[1]{content}, 'Let me check the weather tool.', 'the preamble as a string' );

    my $resp = $engine->chat_response( capture_http('perplexity_agent_mixed_echo') );
    is( $resp->content, reply_text( capture('perplexity_agent_mixed_echo') ), 'the answer' );
};

# karr k356, ADR 0022: every captured Agent reply carries x-ratelimit-limit /
# -remaining / -reset / -used with no -requests / -tokens suffix, and no
# Retry-After -- so the Remote fallback parser built no RateLimit and
# Response.rate_limit stayed undef on a provider that does report its limit.
# The family is read on Perplexity only: its -reset is an epoch instant (the
# captures put it a second after their own Date header), while other senders of
# the same unsuffixed names use other kinds (OpenRouter an unofficial epoch-ms,
# the IETF RateLimit draft delta-seconds). A shared parser would have to guess
# the kind by magnitude, which ADR 0022 declines. used=1 after one request is
# why the bucket is requests, not tokens.
my @rl_captures = qw(
    perplexity_agent_function_call perplexity_agent_function_call_echo
    perplexity_agent_function_call_echo_notools perplexity_agent_function_call_stream
    perplexity_agent_mixed_echo perplexity_agent_search_function_call
);

subtest 'capture: x-ratelimit-* headers become Response.rate_limit (k356)' => sub {
    require HTTP::Date;
    for my $name (@rl_captures) {
        my $h = $json->decode( capture_bytes("$name.headers.json") );
        my $rl = cap_ppx()->_parse_rate_limit_headers(
            HTTP::Response->new( 200, 'OK', [ %$h ], '' ) );
        ok( $rl, "$name: a RateLimit without Retry-After" ) or next;
        is( $rl->requests_limit, $h->{'x-ratelimit-limit'}, "$name: requests_limit" );
        is( $rl->requests_remaining, $h->{'x-ratelimit-remaining'}, "$name: requests_remaining" );
        is( $rl->requests_reset, $h->{'x-ratelimit-reset'}, "$name: requests_reset verbatim" );
        ok( $rl->has_requests_reset_at, "$name: the instant half is what the wire spoke" );
        is( 0 + ( $rl->requests_reset_at // 0 ), $h->{'x-ratelimit-reset'}, "$name: requests_reset_at is the epoch" );
        my $ahead = $h->{'x-ratelimit-reset'} - HTTP::Date::str2time( $h->{date} );
        ok( $ahead >= 0 && $ahead <= 60, "$name: reset is ${ahead}s after the reply's Date, an instant" );
        ok( !defined $rl->tokens_limit && !defined $rl->tokens_reset_at, "$name: no tokens bucket invented" );
        ok( !defined $rl->retry_after, "$name: no retry_after invented" );
        is( $rl->raw->{'x-ratelimit-used'}, $h->{'x-ratelimit-used'}, "$name: used stays in raw" );
    }

    my $mock = Test::MockAsyncHTTP->new( responses => [ capture_http('perplexity_agent_function_call') ] );
    my $engine = cap_ppx( _async_http => $mock );
    my $resp = $engine->chat_f( messages => $engine->chat_messages($cap_prompt),
        tools => $engine->format_tools([$cap_tool]) )->get;
    ok( $resp->has_rate_limit, 'chat_f: the Response carries the rate limit' );
    is( $resp->has_rate_limit && $resp->rate_limit->requests_remaining, 0, 'chat_f: remaining 0 of 1' );
    is( $resp->has_rate_limit && 0 + $resp->rate_limit->requests_reset_at, 1790714944, 'chat_f: the reset instant' );

    # The shared OpenAI dialect keeps its suffixed reading: the same headers do
    # not turn into a reset instant there.
    my $oai = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' )
        ->_parse_rate_limit_headers( capture_http('perplexity_agent_function_call') );
    ok( !defined $oai->requests_reset_at && !defined $oai->requests_limit,
        'OpenAIResponses: unsuffixed x-ratelimit-* are not read as requests' );
};

done_testing;
