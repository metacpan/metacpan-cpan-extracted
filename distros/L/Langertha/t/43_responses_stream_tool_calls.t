#!/usr/bin/env perl
# ABSTRACT: the Open-Responses typed-SSE parser delivers streamed function calls and fails loudly on response.failed
use strict;
use warnings;

use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use Path::Tiny;

use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Request::SyncHTTP;

# Role::ResponsesCompatible::parse_stream_chunk used to read only text deltas
# and the terminal usage: a streamed function call was dropped on the floor,
# and a response.failed / error event ended the stream with no final chunk and
# no error (karr k212). Harmless while OpenAIResponses does not stream, but
# XAIResponses (k206) streams with function tools, and a lost tool call there
# silently ends an agent loop. The terminal response.completed must go through
# the SAME output[] walker chat_response uses, so the streaming and the
# non-streaming path can never disagree about which calls the model made.
#
# No real SSE capture of a Responses tool-call stream exists. The event
# sequence and shapes below follow OpenAI's streaming-events reference
# (developers.openai.com/api/reference/resources/responses/streaming-events,
# fetched 2026-09-25); the `response` object inside response.completed is the
# verbatim non-streaming capture t/data/responses_web_search_function_call.json
# (a web_search_call item followed by a get_weather function_call item).

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $capture_raw = path('t/data/responses_web_search_function_call.json')->slurp_raw;
my $capture     = $json->decode($capture_raw);
my ($fc_item)   = grep { $_->{type} eq 'function_call' } @{ $capture->{output} };
my ($ws_item)   = grep { $_->{type} eq 'web_search_call' } @{ $capture->{output} };

# OpenAIResponses opts out of streaming on the wire; this subclass restores the
# typed-SSE stream so the parser runs as it will on a streaming Responses
# consumer (XAIResponses, k206), through process_stream_data and behind the
# real transport.
{
    package Test::StreamingResponses;
    use Moose;
    extends q{Langertha::Engine::OpenAIResponses};
    sub stream_format { q{sse} }
    __PACKAGE__->meta->make_immutable;
}

sub sse {
    my ( $type, %fields ) = @_;
    return "event: $type\ndata: " . $json->encode( { type => $type, %fields } ) . "\n\n";
}

# The documented frame order for a web_search + function_call turn: the
# function call is announced (output_item.added, arguments empty), its
# arguments stream as deltas, then .done, output_item.done with the finished
# item, and finally response.completed with the whole response.
sub tool_call_events {
    my ( %opt ) = @_;
    my $in_progress = { %$capture, status => 'in_progress', output => [], usage => undef };
    my $seq = 0;
    my $args = $fc_item->{arguments};
    my $half = int( length($args) / 2 );
    return (
        sse( 'response.created',     sequence_number => $seq++, response => $in_progress ),
        sse( 'response.in_progress', sequence_number => $seq++, response => $in_progress ),
        sse( 'response.output_item.added', sequence_number => $seq++, output_index => 0,
            item => { %$ws_item, status => 'in_progress' } ),
        sse( 'response.output_item.done', sequence_number => $seq++, output_index => 0, item => $ws_item ),
        sse( 'response.output_item.added', sequence_number => $seq++, output_index => 1,
            item => { %$fc_item, status => 'in_progress', arguments => '' } ),
        sse( 'response.function_call_arguments.delta', sequence_number => $seq++,
            item_id => $fc_item->{id}, output_index => 1, delta => substr( $args, 0, $half ) ),
        sse( 'response.function_call_arguments.delta', sequence_number => $seq++,
            item_id => $fc_item->{id}, output_index => 1, delta => substr( $args, $half ) ),
        sse( 'response.function_call_arguments.done', sequence_number => $seq++,
            item_id => $fc_item->{id}, output_index => 1, name => $fc_item->{name}, arguments => $args ),
        sse( 'response.output_item.done', sequence_number => $seq++, output_index => 1, item => $fc_item ),
        $opt{failed}
          ? sse( 'response.failed', sequence_number => $seq++, response => {
                %$in_progress, status => 'failed',
                error => { code => 'server_error', message => 'The web_search tool run failed.' } } )
          : sse( 'response.completed', sequence_number => $seq++, response => $capture ),
    );
}

sub responses_engine { Test::StreamingResponses->new( api_key => 'test-key', model => 'gpt-5.6-luna', @_ ) }

subtest 'response.completed carries the function call, once, on the final chunk' => sub {
    my $engine = responses_engine();
    my $chunks = $engine->process_stream_data( join '', tool_call_events() );

    my @with_tc = grep { $_->has_tool_calls } @$chunks;
    is( scalar @with_tc, 1, 'exactly one chunk carries tool calls (no duplicate from the incremental events)' );
    ok( $with_tc[0] && $with_tc[0]->is_final, 'it is the is_final chunk' );

    my $tcs = $engine->aggregate_tool_calls($chunks);
    is( scalar @$tcs, 1, 'aggregate_tool_calls collects one call' );
    my ($tc) = @$tcs;
    isa_ok( $tc, 'Langertha::ToolCall' );
    is( $tc->name, 'get_weather', 'name' );
    is( $tc->id, $fc_item->{call_id}, 'id is the call_id (what a function_call_output answers)' );
    is_deeply( $tc->arguments, { city => 'Greenville, South Carolina' }, 'arguments decoded' );

    my $final = $chunks->[-1];
    is( $final->finish_reason, 'tool_calls', 'final chunk reports finish_reason tool_calls' );
    is( $final->model, 'gpt-5.6-luna', 'model from response.completed' );
    is( $final->usage->{prompt_tokens}, 8748, 'usage still lifted' );
    is( join( '', map { $_->content } @$chunks ), '', 'no text content invented from output[]' );
};

subtest 'stream and non-streaming path agree (one walker)' => sub {
    my $engine   = responses_engine();
    my $response = $engine->chat_response(
        HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $capture_raw ) );
    my $chunks   = $engine->process_stream_data( join '', tool_call_events() );
    my $final    = $chunks->[-1];

    is_deeply(
        [ map { +{ name => $_->name, id => $_->id, arguments => $_->arguments } } @{ $final->tool_calls } ],
        [ map { +{ name => $_->name, id => $_->id, arguments => $_->arguments } } @{ $response->tool_calls } ],
        'streamed tool calls equal chat_response tool calls for the same response object' );
    is( $final->finish_reason, $response->finish_reason, 'same finish_reason' );
};

subtest 'response.incomplete goes through the same walker' => sub {
    my $engine = responses_engine();
    my $chunk  = $engine->parse_stream_chunk( {
        type     => 'response.incomplete',
        response => { %$capture, status => 'incomplete' },
    } );
    ok( $chunk->is_final, 'final' );
    is( scalar @{ $chunk->tool_calls // [] }, 1, 'tool call lifted from response.incomplete too' );
};

subtest 'response.failed and error fail loudly with the provider message' => sub {
    my $engine = responses_engine();

    my $failed = eval { $engine->process_stream_data( join '', tool_call_events( failed => 1 ) ); 1 };
    ok( !$failed, 'a response.failed stream dies instead of ending without a final chunk' );
    like( $@, qr/The web_search tool run failed\./, 'with the provider error message' );
    like( $@, qr/server_error/, 'and the provider error code' );

    my $err = eval {
        $engine->parse_stream_chunk( { type => 'error', sequence_number => 3,
            code => 'rate_limit_exceeded', message => 'Rate limit reached.', param => undef } );
        1;
    };
    ok( !$err, 'a top-level error event dies' );
    like( $@, qr/Rate limit reached\./, 'with the provider error message' );

    my $bare = eval { $engine->parse_stream_chunk( { type => 'response.failed', response => {} } ); 1 };
    ok( !$bare, 'a response.failed without an error object still dies' );
    like( $@, qr/stream failed/, 'with a generic message' );
};

# karr k222: a text-only stream's final chunk now carries the same
# finish_reason chat_response reads off the same response object -- 'stop' for
# a completed message, the message status ('incomplete') for a truncated one --
# like the Chat-Completions, Anthropic, Gemini and Ollama streams already do on
# their last chunk. Before k222 it was set only alongside tool calls, so a
# text-only Responses stream never said how it ended. This is an intended,
# additive change to Perplexity's final chunk (golden in
# t/data/stream_text_only_golden.json regenerated for it).
subtest 'Perplexity text-only capture: final chunk reports stop' => sub {
    my $engine = Langertha::Engine::Perplexity->new( api_key => 'test-key', model => 'sonar' );
    my $sse    = path('t/data/perplexity_agent_stream.sse')->slurp_raw;
    my $chunks = $engine->process_stream_data($sse);
    my $final  = $chunks->[-1];
    ok( $final->is_final, 'final chunk present' );
    ok( !$final->has_tool_calls, 'no tool_calls on a text-only stream' );
    is( $final->finish_reason, 'stop', 'finish_reason stop on a completed text-only stream' );
    ok( !$final->has_thinking, 'no thinking added' );
    is( join( '', map { $_->content } @$chunks ), '7', 'content unchanged' );

    # The same response object read non-streaming gives the same value.
    my ($completed) = grep { ( $_->{type} // '' ) eq 'response.completed' }
        map { eval { $json->decode($_) } // () } $sse =~ /^data: (\{.*\})$/mg;
    my $response = $engine->chat_response( HTTP::Response->new( 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $json->encode( $completed->{response} ) ) );
    is( $final->finish_reason, $response->finish_reason, 'stream and chat_response agree' );
};

subtest 'text-only response.incomplete reports incomplete' => sub {
    my $engine = Langertha::Engine::Perplexity->new( api_key => 'test-key', model => 'sonar' );
    # Shape per the documented Responses object: a truncated run ends with
    # response.incomplete, status incomplete, and the message item's own status
    # incomplete (no capture of a truncated stream exists).
    my $resp = {
        id => 'resp_1', object => 'response', status => 'incomplete',
        incomplete_details => { reason => 'max_output_tokens' },
        output => [ { type => 'message', id => 'msg_1', role => 'assistant', status => 'incomplete',
            content => [ { type => 'output_text', text => 'The ans', annotations => [] } ] } ],
        usage => { input_tokens => 5, output_tokens => 3, total_tokens => 8 },
    };
    my $chunk = $engine->parse_stream_chunk( { type => 'response.incomplete', response => $resp } );
    ok( $chunk->is_final, 'final' );
    ok( !$chunk->has_tool_calls, 'no tool calls' );
    is( $chunk->finish_reason, 'incomplete', 'finish_reason incomplete' );
    my $response = $engine->chat_response( HTTP::Response->new( 200, 'OK',
        [ 'Content-Type' => 'application/json' ], $json->encode($resp) ) );
    is( $chunk->finish_reason, $response->finish_reason, 'same as chat_response' );
};

# The same contract across the real transport: chat_stream_realtime_f over the
# sync LWP shim and (when installed) Net::Async::HTTP against a local daemon.

SKIP: {
    skip 'fork-based HTTP::Daemon test not supported on Windows', 1 if $^O eq 'MSWin32';
    require Test::LocalHTTPDaemon;

    my $server = Test::LocalHTTPDaemon->start( sub {
        my ($request) = @_;
        # scalar(): a failed match in list context is the empty list, which
        # would leave `failed` without a value (odd-sized option list).
        my @events = ( tool_call_events( failed => scalar( $request->uri->path =~ m{^/failed/} ) ),
            "data: [DONE]\n\n" );
        return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ], sub {
            return shift(@events) // '';
        } );
    } );
    my $base = $server->url;

    my @backends = ( [ 'sync LWP shim', sub {
        ( _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new( timeout => 10 ) ) ) } ] );
    push @backends, [ 'Net::Async::HTTP', sub { () } ]
        if eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };

    for my $backend (@backends) {
        my ( $label, $args ) = @$backend;
        subtest "$label: chat_stream_realtime_f" => sub {
            my $ok = Test::StreamingResponses->new( api_key => 'k', model => 'gpt-5.6-luna',
                url => "$base/ok/v1", $args->() );
            my ( $content, $chunks ) = $ok->chat_stream_realtime_f( messages => ['weather?'] )->get;
            my $tcs = $ok->aggregate_tool_calls($chunks);
            is( scalar @$tcs, 1, 'one streamed tool call' );
            is( $tcs->[0] && $tcs->[0]->name, 'get_weather', 'named get_weather' );

            my $bad = Test::StreamingResponses->new( api_key => 'k', model => 'gpt-5.6-luna',
                url => "$base/failed/v1", $args->() );
            my $f = $bad->chat_stream_realtime_f( messages => ['weather?'] );
            my $died = eval { $f->get; 1 } ? '' : $@;
            ok( $f->is_failed, 'response.failed fails the stream future' );
            like( $died, qr/The web_search tool run failed\./, 'with the provider message' );
        };
    }
}

done_testing;
