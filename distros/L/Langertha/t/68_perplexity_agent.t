#!/usr/bin/env perl
# ABSTRACT: Perplexity Agent API engine (Open-Responses envelope, k139)

# Sonar Chat Completions reached EOL 2026-09-27; Engine::Perplexity now speaks
# the Agent API (POST /v1/agent), the Open-Responses wire envelope shared with
# Engine::OpenAIResponses via Langertha::Role::ResponsesCompatible. This test
# pins the Perplexity-specific behaviour: model->preset selection, the typed
# input, the TOP-LEVEL response_format slot (not OpenAI's text.format),
# search_results -> citations, the capability corrections, the typed-SSE parser,
# and the ADR 0005 direction-1 rewrite for which Perplexity is the exemplar.

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::Perplexity;
use Langertha::Stream;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub ppx { Langertha::Engine::Perplexity->new( api_key => 'test-key', @_ ) }

sub body_of {
    my ($request) = @_;
    return $json->decode( $request->content );
}

subtest 'endpoint, auth, and Bearer header' => sub {
    my $engine  = ppx( model => 'sonar' );
    my $request = $engine->chat_request( [ { role => 'user', content => 'Hi' } ] );
    is( $request->method, 'POST', 'POST' );
    like( $request->uri, qr{^https://api\.perplexity\.ai/v1/agent$},
        'endpoint is /v1/agent, not /chat/completions' );
    is( $request->header('Authorization'), 'Bearer test-key',
        'Bearer auth unchanged from Sonar' );
};

subtest 'model -> preset selection' => sub {
    my %expect = (
        'sonar'               => 'fast',
        'sonar-pro'           => 'low',
        'sonar-reasoning-pro' => 'medium',
        'sonar-deep-research' => 'high',
    );
    for my $model ( sort keys %expect ) {
        my $body = body_of( ppx( model => $model )->chat_request( [ { role => 'user', content => 'Hi' } ] ) );
        is( $body->{preset}, $expect{$model}, "$model -> preset $expect{$model}" );
        ok( !exists $body->{model}, "$model: no model key when a preset is used" );
        ok( !exists $body->{models}, "$model: no models[] key either" );
    }

    # Default model is sonar -> fast.
    my $default = body_of( ppx()->chat_request( [ { role => 'user', content => 'Hi' } ] ) );
    is( $default->{preset}, 'fast', 'default model sonar -> preset fast' );

    # An unknown id is passed through as `model` so a caller can target an
    # explicit Agent model/preset by name.
    my $unknown = body_of( ppx( model => 'perplexity/some-future-model' )
        ->chat_request( [ { role => 'user', content => 'Hi' } ] ) );
    is( $unknown->{model}, 'perplexity/some-future-model', 'unknown id passes through as model' );
    ok( !exists $unknown->{preset}, 'no preset for an unknown id' );
};

subtest 'input items are typed, system lifted to instructions' => sub {
    my $engine = ppx( model => 'sonar', system_prompt => 'You are helpful' );
    my $body   = body_of( $engine->chat_request( [
        { role => 'system', content => 'You are helpful' },
        { role => 'user',   content => 'Hi' },
        { role => 'assistant', content => 'Hello' },
    ] ) );

    is( $body->{instructions}, 'You are helpful', 'system prompt -> instructions' );
    ok( !grep( { ( $_->{role} // '' ) eq 'system' } @{ $body->{input} } ),
        'no system message left in input' );
    is( scalar @{ $body->{input} }, 2, 'two non-system input items' );
    is( $body->{input}[0]{type}, 'message', 'input item carries type:message' );
    is( $body->{input}[0]{role}, 'user', 'role preserved' );
    is( $body->{input}[0]{content}, 'Hi', 'content preserved' );
    is( $body->{input}[1]{type}, 'message', 'assistant item also type:message' );
};

subtest 'reasoning.effort, temperature, optional max_output_tokens' => sub {
    my $body = body_of( ppx(
        model            => 'sonar-reasoning-pro',
        reasoning_effort => 'high',
        temperature      => 0.5,
        response_size    => 512,
    )->chat_request( [ { role => 'user', content => 'Hi' } ] ) );

    is_deeply( $body->{reasoning}, { effort => 'high' },
        'reasoning:{effort} via the responses format' );
    is( $body->{temperature}, 0.5, 'temperature present' );
    is( $body->{max_output_tokens}, 512, 'response_size -> max_output_tokens (renamed)' );
    ok( !exists $body->{max_tokens}, 'no legacy max_tokens key' );

    # max_output_tokens is optional: absent when no response_size is set (presets
    # do not require it). LIVE-CONFIRM (k139) point 5.
    my $bare = body_of( ppx( model => 'sonar' )->chat_request( [ { role => 'user', content => 'Hi' } ] ) );
    ok( !exists $bare->{max_output_tokens}, 'no max_output_tokens when unset' );
    ok( !exists $bare->{reasoning}, 'no reasoning when reasoning_effort unset' );
    is( $bare->{stream}, JSON->false, 'stream:false on the non-streaming path' );
};

subtest 'response_format sits TOP-LEVEL (not text.format)' => sub {
    my $schema = { type => 'object', properties => { answer => { type => 'string' } } };
    my $rf = {
        type        => 'json_schema',
        json_schema => { name => 'answer', schema => $schema, strict => JSON->true },
    };
    my $body = body_of( ppx( model => 'sonar', response_format => $rf )
        ->chat_request( [ { role => 'user', content => 'Hi' } ] ) );

    ok( exists $body->{response_format}, 'top-level response_format present' );
    ok( !exists $body->{text}, 'NOT under text.format (that is the OpenAI Responses slot)' );
    is( $body->{response_format}{type}, 'json_schema', 'Chat-Completions json_schema shape kept' );
    is( $body->{response_format}{json_schema}{name}, 'answer', 'nested json_schema.name preserved' );
    ok( $body->{response_format}{json_schema}{strict}, 'strict preserved' );
};

subtest 'chat_response: content, usage, created, finish_reason, thinking' => sub {
    my $payload = {
        id     => 'resp_1', object => 'response', model => 'sonar-pro',
        status => 'completed', created_at => 1777949583,
        output => [
            { type => 'reasoning', summary => [ { text => 'thinking about it' } ] },
            { type => 'message', status => 'completed', content => [
                { type => 'output_text', text => 'Perl 5.42 is out [1].' },
            ] },
        ],
        usage => { input_tokens => 10, output_tokens => 20, total_tokens => 30 },
    };
    my $resp = ppx()->chat_response( _http( $payload ) );

    is( "$resp", 'Perl 5.42 is out [1].', 'content from output_text (stringifies)' );
    is( $resp->model, 'sonar-pro', 'model' );
    is( $resp->finish_reason, 'stop', 'completed message -> finish_reason stop' );
    is( $resp->prompt_tokens, 10, 'input_tokens -> prompt_tokens' );
    is( $resp->completion_tokens, 20, 'output_tokens -> completion_tokens' );
    is( $resp->total_tokens, 30, 'total_tokens' );
    is( $resp->thinking, 'thinking about it', 'reasoning summary -> thinking' );
    ok( $resp->has_created, 'created present' );
    is( 0 + $resp->created, 1777949583, 'created_at epoch -> Moment (numeric)' );
};

subtest 'citations lifted from search_results' => sub {
    my $payload = {
        id => 'resp_2', model => 'sonar', status => 'completed',
        output => [
            { type => 'message', status => 'completed', content => [
                { type => 'output_text', text => 'Answer [1][2].' },
            ] },
            { type => 'search_results', results => [
                { id => 1, url => 'https://perl.org',     title => 'Perl.org' },
                { id => 2, url => 'https://metacpan.org', title => 'MetaCPAN' },
            ] },
        ],
        usage => { input_tokens => 5, output_tokens => 5, total_tokens => 10 },
    };
    my $resp = ppx()->chat_response( _http( $payload ) );

    ok( $resp->has_citations, 'citations present' );
    is( scalar @{ $resp->citations }, 2, 'two citations' );
    is( $resp->citations->[0]{url}, 'https://perl.org', 'first citation url' );
    is( $resp->citations->[1]{title}, 'MetaCPAN', 'second citation title' );

    # No search_results -> no citations (not an empty arrayref).
    my $none = ppx()->chat_response( _http( {
        model => 'sonar', status => 'completed',
        output => [ { type => 'message', status => 'completed',
            content => [ { type => 'output_text', text => 'no sources' } ] } ],
    } ) );
    ok( !$none->has_citations, 'no citations when no search_results block' );
};

subtest 'capability corrections (k139)' => sub {
    my $caps = ppx()->engine_capabilities;

    # Client function tools since k213, but no tool_choice field on the Agent
    # schema (t/68_perplexity_function_tools.t); no Role::PromptCache:
    ok( $caps->{tools_native},       'native function tools (k213)' );
    ok( !$caps->{tool_choice_named}, 'no named tool_choice (ADR 0005 dir-1 exemplar)' );
    ok( !$caps->{prompt_cache},      'no cache enable' );
    ok( !$caps->{prompt_cache_key},  'no prompt_cache_key (caching automatic)' );

    # Present:
    ok( $caps->{chat},                        'chat' );
    ok( $caps->{streaming},                   'streaming' );
    ok( $caps->{response_format_json_schema}, 'json_schema stays' );
    ok( $caps->{reasoning_effort},            'reasoning_effort restored (Agent accepts reasoning.effort)' );

    # Corrected off:
    ok( !$caps->{response_format_json_object},
        'json_object flipped off (Agent enum is json_schema-only)' );
};

subtest 'typed-SSE stream parsing' => sub {
    my $engine = ppx();
    is( $engine->stream_format, 'sse', 'stream_format is sse' );

    my $delta = $engine->parse_stream_chunk(
        { type => 'response.output_text.delta', delta => 'Hel' } );
    ok( $delta, 'output_text.delta produces a chunk' );
    is( $delta->content, 'Hel', 'delta text becomes chunk content' );
    ok( !$delta->is_final, 'delta is not final' );

    my $done = $engine->parse_stream_chunk( {
        type     => 'response.completed',
        response => { model => 'sonar-pro',
            usage => { input_tokens => 3, output_tokens => 7, total_tokens => 10 } },
    } );
    ok( $done->is_final, 'response.completed is final' );
    is( $done->model, 'sonar-pro', 'final chunk carries model' );

    # Non-text typed events carry no content.
    is( $engine->parse_stream_chunk( { type => 'response.created' } ), undef,
        'response.created -> undef (no content)' );

    # End-to-end through Role::Streaming: assemble the deltas, stop at [DONE].
    my $sse = join( "\n",
        'event: response.output_text.delta',
        'data: {"type":"response.output_text.delta","delta":"Hello "}',
        '',
        'data: {"type":"response.output_text.delta","delta":"world"}',
        '',
        'data: [DONE]',
        '',
    );
    my $chunks = $engine->process_stream_data($sse);
    my $text = join( '', map { $_->content } @$chunks );
    is( $text, 'Hello world', 'typed deltas concatenate, [DONE] terminates' );
};

subtest 'chat_f direction-1 rewrite: forced tool -> response_format (ADR 0005 exemplar)' => sub {
    # The Agent API has no tool_choice_named but has response_format_json_schema,
    # so a forced named tool is rerouted through a top-level response_format and
    # the structured content is re-attached as a synthetic ToolCall.
    my $tool = {
        name        => 'extract',
        description => 'extract a city',
        input_schema => {
            type => 'object', properties => { city => { type => 'string' } },
            required => ['city'],
        },
    };

    # The mocked Agent response returns the structured JSON as output_text.
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( {
        id => 'resp_3', model => 'sonar', status => 'completed',
        output => [ { type => 'message', status => 'completed',
            content => [ { type => 'output_text', text => '{"city":"Berlin"}' } ] } ],
        usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 },
    } ) ] );

    my $engine = ppx( model => 'sonar', _async_http => $mock );
    my $resp = $engine->chat_f(
        messages    => [ { role => 'user', content => 'Which city?' } ],
        tools       => [ $tool ],
        tool_choice => { type => 'tool', name => 'extract' },
    )->get;

    # The request that actually went out: tools/tool_choice gone, top-level
    # response_format=json_schema present.
    my ($sent) = $mock->requests;
    my $body = body_of($sent);
    ok( !exists $body->{tools}, 'tools cleared from the wire' );
    ok( !exists $body->{tool_choice}, 'tool_choice cleared (Agent has no such field anyway)' );
    is( $body->{response_format}{type}, 'json_schema', 'rewritten to top-level response_format json_schema' );

    # The synthetic ToolCall is on Response.tool_calls (single source of truth).
    my $tc = $resp->tool_call('extract');
    ok( $tc, 'synthetic ToolCall present under the forced name' );
    ok( $tc->synthetic, 'flagged synthetic' );
    is_deeply( $tc->arguments, { city => 'Berlin' }, 'loose-parsed structured args' );
};

# --- Real captured wire (k147) --------------------------------------------
# The fixtures below are trimmed but otherwise verbatim Agent-API responses
# captured from live calls on 2026-09-14 (karr #147, de-risking #139). They pin
# the parser against the wire reality the eight LIVE-CONFIRM points resolved to,
# so a future refactor of Role::ResponsesCompatible cannot silently drift from
# what Perplexity actually returns.

subtest 'real captured Agent response (fixture, k147)' => sub {
    my $data = $json->decode( path('t/data/perplexity_agent_search.json')->slurp_raw );
    my $resp = ppx()->chat_response( _http( $data ) );

    is( "$resp", 'Paris is the capital of France.[1]',
        'content from output_text; the inline citation marker is [1] (not [web:1])' );
    is( $resp->model, 'openai/gpt-5.6-luna',
        'preset "fast" resolved to openai/gpt-5.6-luna on the wire' );
    is( $resp->finish_reason, 'stop', 'completed message -> finish_reason stop' );
    is( $resp->prompt_tokens, 4071, 'input_tokens -> prompt_tokens' );
    is( $resp->completion_tokens, 13, 'output_tokens -> completion_tokens' );
    is( 0 + $resp->created, 1789422365, 'created_at epoch -> Moment (numeric)' );

    ok( $resp->has_citations, 'search_results block lifted to citations' );
    is( scalar @{ $resp->citations }, 2, 'both search results present' );
    my $cite = $resp->citations->[0];
    is( $cite->{url}, 'https://en.wikipedia.org/wiki/Paris', 'first citation url' );
    ok( ( exists $cite->{snippet} && exists $cite->{date}
          && exists $cite->{source} && exists $cite->{last_updated} ),
        'real citation carries snippet/date/source/last_updated verbatim' );

    # The message output_text part carries an (empty) annotations[] on the wire;
    # the authoritative source list is the search_results block, not annotations.
    my ($msg) = grep { ( $_->{type} // '' ) eq 'message' } @{ $resp->raw->{output} };
    is_deeply( $msg->{content}[0]{annotations}, [],
        'output_text annotations[] present but empty' );
};

subtest 'usage carries prompt-cache tokens + cost (fixture, k159)' => sub {
    my $data = $json->decode( path('t/data/perplexity_agent_search.json')->slurp_raw );
    my $resp = ppx()->chat_response( _http( $data ) );

    # The Agent wire nests the automatic prompt-cache counts under
    # usage.input_tokens_details (caching is automatic on every call).
    # Langertha::Usage->from_hash now parses them onto the value object the same
    # way it does the chat wire's prompt_tokens_details, so cache read/write
    # observability reaches Responses-envelope engines too (karr #159).
    is( $resp->usage->cache_write_tokens, 4068,
        'input_tokens_details.cache_creation_input_tokens -> Usage.cache_write_tokens' );
    is( $resp->usage->cached_tokens, 0,
        'input_tokens_details cache read count -> Usage.cached_tokens (0 preserved)' );
    ok( $resp->has_cached_tokens, 'cached_tokens surfaces on the Response (defined 0)' );
    is( $resp->cached_tokens, 0, 'Response.cached_tokens lifted off the Usage object' );

    # The chat-spelled overload keys stay for existing callers (t/60, t/91), and
    # the raw Responses detail block survives verbatim under the usage overload.
    is( $resp->usage->{prompt_tokens},     4071, 'chat-spelled prompt_tokens overload kept' );
    is( $resp->usage->{completion_tokens}, 13,   'chat-spelled completion_tokens overload kept' );
    is( $resp->usage->{input_tokens_details}{cache_creation_input_tokens}, 4068,
        'input_tokens_details survives verbatim under the usage overload' );

    # The per-call cost block rides along under usage.cost (passthrough).
    is( ref $resp->usage->{cost}, 'HASH', 'usage.cost block passed through' );
    is( $resp->usage->{cost}{currency}, 'USD', 'cost currency preserved' );
    cmp_ok( $resp->usage->{cost}{total_cost}, '>', 0, 'cost.total_cost is a real number' );
};

subtest 'real captured typed-SSE stream (fixture, k147)' => sub {
    my $engine = ppx();
    my $sse    = path('t/data/perplexity_agent_stream.sse')->slurp_raw;
    my $chunks = $engine->process_stream_data($sse);

    my $text = join( '', map { $_->content } @$chunks );
    is( $text, '7', 'response.output_text.delta increments concatenate to the answer' );

    my ($final) = grep { $_->is_final } @$chunks;
    ok( $final, 'response.completed produced a final chunk' );
    is( $final->model, 'openai/gpt-5.6-luna',
        'final chunk model is the resolved model, not the "medium" preset label' );
    ok( $final->has_usage, 'usage rides on response.completed (no trailing frame)' );
    is( $final->usage->{prompt_tokens}, 1353, 'input_tokens from response.completed' );
    is( $final->usage->{completion_tokens}, 5, 'output_tokens from response.completed' );

    # k158: the captured stream is a non-search reply (the trimmed fixture holds
    # no search_results frame), so it must NOT invent citations.
    ok( !$final->has_citations, 'no search_results -> final chunk carries no citations' );
    my $stream = Langertha::Stream->new( chunks => $chunks );
    is( $stream->citations, undef, 'Stream->citations undef when the stream had no sources' );
};

subtest 'streamed search_results lift to citations (k158)' => sub {
    my $engine = ppx();

    # The trimmed live stream fixture captured a non-search reply, so it cannot
    # exercise the search path. This constructs a response.completed frame whose
    # output[] carries the search_results block VERBATIM from the non-streaming
    # fixture (t/data/perplexity_agent_search.json) — the same shape the Agent
    # wire delivers in the terminal frame's output[] — to exercise the parser.
    my $search = $json->decode( path('t/data/perplexity_agent_search.json')->slurp_raw );
    my ($search_results) = grep { ( $_->{type} // '' ) eq 'search_results' }
        @{ $search->{output} };
    ok( $search_results, 'search_results block sourced 1:1 from the non-streaming fixture' );

    my $frame = {
        type     => 'response.completed',
        response => {
            model  => 'openai/gpt-5.6-luna',
            output => [
                { type => 'message', status => 'completed', content => [
                    { type => 'output_text', text => 'Paris is the capital of France.[1]' },
                ] },
                $search_results,
            ],
            usage => { input_tokens => 4071, output_tokens => 13, total_tokens => 4084 },
        },
    };

    my $final = $engine->parse_stream_chunk($frame);
    ok( $final->is_final, 'response.completed with search_results is still the final chunk' );
    ok( $final->has_citations, 'search_results lifted onto the final chunk' );
    is( scalar @{ $final->citations }, 2, 'both search results present' );
    is( $final->citations->[0]{url}, 'https://en.wikipedia.org/wiki/Paris',
        'first citation url matches the non-streaming source list' );
    is( $final->citations->[1]{title}, 'What is the Capital of France?',
        'second citation title preserved' );

    # And the ergonomic streaming surface: Stream->citations reassembles them.
    my $stream = Langertha::Stream->new( chunks => [
        $engine->parse_stream_chunk( { type => 'response.output_text.delta', delta => 'Paris' } ),
        $final,
    ] );
    is( scalar @{ $stream->citations }, 2, 'Stream->citations surfaces the streamed sources' );
};

subtest 'chat_f direction-1 rewrite: non-object result yields no false-success ToolCall (k170)' => sub {
    # The model can return valid JSON that is NOT an object — a bare array here.
    # Tool arguments must be an object, and Response coerces non-hash args to {},
    # so a synthetic ToolCall built from an array would falsely claim success
    # with empty arguments. chat_f must instead attach NO tool_call, leaving the
    # raw content on Response so the caller sees the gap.
    my $tool = {
        name        => 'extract',
        description => 'extract a city',
        input_schema => {
            type => 'object', properties => { city => { type => 'string' } },
            required => ['city'],
        },
    };

    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( {
        id => 'resp_4', model => 'sonar', status => 'completed',
        output => [ { type => 'message', status => 'completed',
            content => [ { type => 'output_text', text => '["Berlin","Paris"]' } ] } ],
        usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 },
    } ) ] );

    my $engine = ppx( model => 'sonar', _async_http => $mock );
    my $resp = $engine->chat_f(
        messages    => [ { role => 'user', content => 'Which city?' } ],
        tools       => [ $tool ],
        tool_choice => { type => 'tool', name => 'extract' },
    )->get;

    # The rewrite still fired on the wire (tools cleared, response_format set)...
    my ($sent) = $mock->requests;
    my $body = body_of($sent);
    is( $body->{response_format}{type}, 'json_schema', 'still rewritten to response_format json_schema' );

    # ...but the non-object result produces NO synthetic ToolCall.
    ok( !$resp->has_tool_calls, 'no synthetic ToolCall for a non-object result' );
    is( $resp->tool_call('extract'), undef, 'named lookup finds nothing' );
    is( "$resp", '["Berlin","Paris"]', 'raw non-object content stays on Response.content' );
};

# k160: the terminal response.completed frame carries the prefix-cache read
# count under usage.input_tokens_details.cached_tokens and a usage.cost block.
# The streamed final chunk must surface both -- cached_tokens on the dedicated
# Stream::Chunk attribute (symmetric to the non-streaming path and the
# OpenAI-compatible chat wire), cost through the usage hash -- rather than
# dropping them the way the prompt/completion/total normalization used to.
subtest 'streamed response.completed lifts cached_tokens and cost (k160)' => sub {
    my $engine = ppx();

    # Real captured wire: the k147 fixture's terminal frame carries
    # input_tokens_details.cached_tokens = 0 (a cache write, not read) and a full
    # cost block. Zero is a real count, so it surfaces (defined, not truthy-gated).
    my $sse    = path('t/data/perplexity_agent_stream.sse')->slurp_raw;
    my $chunks = $engine->process_stream_data($sse);
    my ($final) = grep { $_->is_final } @$chunks;

    ok( $final->has_cached_tokens,
        'cached_tokens surfaced on the final chunk (0 is a real count)' );
    is( $final->cached_tokens, 0,
        'cached_tokens lifted from usage.input_tokens_details.cached_tokens' );
    is( ref $final->usage->{cost}, 'HASH', 'cost block carried through the usage hash' );
    is( $final->usage->{cost}{currency}, 'USD', 'cost.currency preserved' );
    cmp_ok( $final->usage->{cost}{total_cost}, '>', 0, 'cost.total_cost is a real number' );
    is( $final->usage->{prompt_tokens}, 1353, 'usage still normalized to prompt_tokens' );

    # A non-zero cache read surfaces the same way.
    my $hit = $engine->parse_stream_chunk( {
        type     => 'response.completed',
        response => { model => 'sonar', usage => {
            input_tokens         => 100,
            input_tokens_details => { cached_tokens => 64 },
            output_tokens        => 20,
            total_tokens         => 120,
        } },
    } );
    is( $hit->cached_tokens, 64, 'non-zero cache read count surfaced' );

    # No detail block: no cached_tokens, and the source usage is not polluted by
    # an autovivified input_tokens_details.
    my $bare = $engine->parse_stream_chunk( {
        type     => 'response.completed',
        response => { model => 'sonar', usage => {
            input_tokens => 3, output_tokens => 7, total_tokens => 10 } },
    } );
    ok( !$bare->has_cached_tokens, 'no cached_tokens when no input_tokens_details' );
    ok( !exists $bare->raw->{response}{usage}{input_tokens_details},
        'input_tokens_details not autovivified into raw when the frame omits it' );
    ok( !exists $bare->usage->{cost}, 'no cost key when the frame carries none' );
};

sub _http {
    my ($data) = @_;
    return HTTP::Response->new( 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $json->encode($data) );
}

done_testing;
