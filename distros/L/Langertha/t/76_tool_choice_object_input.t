#!/usr/bin/env perl
# ABSTRACT: A Langertha::ToolChoice object is valid tool_choice input on every wire (k235)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::ToolChoice;
# Input::Tools warns it is a legacy facade on load; its helpers are still an entry point.
BEGIN {
    local $SIG{__WARN__} = sub { return if $_[0] =~ /backwards-compatibility facade/; warn @_ };
    require Langertha::Input::Tools;
}
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Cerebras;
use Langertha::Engine::NousResearch;

# karr k235 / ADR 0001, ADR 0010: the ToolChoice value object is the canonical
# selection policy, so passing one as tool_choice must mean exactly what the
# equivalent string / hash means. Before k235, ToolChoice->from_hash returned
# undef for an already-blessed ToolChoice, so every request builder treated the
# object as "unreadable": the object leaked onto the wire through TO_JSON in
# the canonical {type => ...} shape (a 400 on OpenAI / Responses, which take
# 'none' / 'required' strings), and on Perplexity a ToolChoice->none carped and
# still sent the tools, bypassing the k233 none-withhold (ADR 0020 k233 Update).
# Every entry point funnels through from_hash, so the object is serialized by
# ->to($fmt) for its wire, never by TO_JSON.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
sub body_of { $json->decode( $_[0]->content ) }

my $tool = {
    name        => 'get_weather',
    description => 'Weather for a city',
    inputSchema => { type => 'object', properties => { city => { type => 'string' } },
                     required => ['city'] },
};
my $msgs = [ { role => 'user', content => 'weather?' } ];

my %choice = (
    none  => sub { Langertha::ToolChoice->none },
    any   => sub { Langertha::ToolChoice->any },
    auto  => sub { Langertha::ToolChoice->auto },
    named => sub { Langertha::ToolChoice->specific('get_weather') },
);

subtest 'from_hash returns a ToolChoice object as-is' => sub {
    my $tc = Langertha::ToolChoice->specific('get_weather');
    my $got = Langertha::ToolChoice->from_hash($tc);
    ok( defined $got, 'object input is readable' );
    is( $got, $tc, 'the same object comes back' );
    ok( !defined Langertha::ToolChoice->from_hash( bless {}, 'Some::Other' ),
        'a foreign object is still unreadable' );
};

subtest 'openai wire: object serialized by to(openai)' => sub {
    my %want = ( none => 'none', any => 'required', auto => 'auto',
        named => { type => 'function', function => { name => 'get_weather' } } );
    my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
    for my $builder (qw( chat_request chat_stream_request )) {
        for my $kind ( sort keys %want ) {
            my $body = body_of( $engine->$builder( $msgs, tools => [ $engine->format_tools([$tool]) ],
                tool_choice => $choice{$kind}->() ) );
            is_deeply( $body->{tool_choice}, $want{$kind}, "$builder: $kind" );
        }
        # The streaming builder normalizes a foreign-shaped hash as well.
        my $body = body_of( $engine->$builder( $msgs, tools => [ $engine->format_tools([$tool]) ],
            tool_choice => { type => 'tool', name => 'get_weather' } ) );
        is_deeply( $body->{tool_choice}, $want{named}, "$builder: anthropic-shaped hash" );
    }
};

subtest 'anthropic wire: object serialized by to(anthropic)' => sub {
    my %want = ( none => { type => 'none' }, any => { type => 'any' }, auto => { type => 'auto' },
        named => { type => 'tool', name => 'get_weather' } );
    my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-5' );
    for my $builder (qw( chat_request chat_stream_request )) {
        for my $kind ( sort keys %want ) {
            my $body = body_of( $engine->$builder( $msgs, tools => $engine->format_tools([$tool]),
                tool_choice => $choice{$kind}->() ) );
            is_deeply( $body->{tool_choice}, $want{$kind}, "$builder: $kind" );
        }
        # The cases above cannot tell a fix from a leak: TO_JSON's canonical
        # shape happens to equal Anthropic's. The parallel_tool_use fold can:
        # it replaced a non-HASH tool_choice with {type => 'auto'}, so before
        # k235 a ToolChoice object lost its forced tool here.
        my $body = body_of( $engine->$builder( $msgs, tools => $engine->format_tools([$tool]),
            tool_choice => Langertha::ToolChoice->specific('get_weather'),
            controls    => { parallel_tool_use => 0 } ) );
        is_deeply( $body->{tool_choice},
            { type => 'tool', name => 'get_weather', disable_parallel_tool_use => JSON::MaybeXS::true() },
            "$builder: named + parallel_tool_use => 0 keeps the forced tool" );
    }
};

subtest 'gemini wire: object becomes toolConfig, no tool_choice field' => sub {
    my %want = (
        none  => { functionCallingConfig => { mode => 'NONE' } },
        any   => { functionCallingConfig => { mode => 'ANY' } },
        auto  => { functionCallingConfig => { mode => 'AUTO' } },
        named => { functionCallingConfig => { mode => 'ANY', allowed_function_names => ['get_weather'] } },
    );
    my $engine = Langertha::Engine::Gemini->new( api_key => 'k' );
    for my $builder (qw( chat_request chat_stream_request )) {
        for my $kind ( sort keys %want ) {
            my $body = body_of( $engine->$builder( $msgs, tools => $engine->format_tools([$tool]),
                tool_choice => $choice{$kind}->() ) );
            is_deeply( $body->{toolConfig}, $want{$kind}, "$builder: $kind" );
            ok( !exists $body->{tool_choice}, "$builder: $kind leaves no tool_choice field" );
        }
    }
};

subtest 'responses wire (OpenAIResponses): object serialized by to(responses)' => sub {
    my %want = ( none => 'none', any => 'required', auto => 'auto',
        named => { type => 'function', name => 'get_weather' } );
    my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.6-luna' );
    for my $builder (qw( chat_request chat_stream_request )) {
        for my $kind ( sort keys %want ) {
            my $body = body_of( $engine->$builder( $msgs, tools => [$tool],
                tool_choice => $choice{$kind}->() ) );
            is_deeply( $body->{tool_choice}, $want{$kind}, "$builder: $kind" );
        }
    }
};

subtest 'responses wire (Perplexity): ToolChoice->none withholds the tools (k233)' => sub {
    my $engine = Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar' );
    for my $builder (qw( chat_request chat_stream_request )) {
        my @warns;
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $body = body_of( $engine->$builder( $msgs, tools => [$tool],
            tool_choice => Langertha::ToolChoice->none ) );
        ok( !exists $body->{tools}, "$builder: no tools sent" );
        ok( !exists $body->{tool_choice}, "$builder: no tool_choice sent" );
        ok( ( grep { /tool_choice 'none'.*withh[oe]ld/ } @warns ), "$builder: carps the withhold" )
            or diag @warns;
        ok( !( grep { /not one Langertha can read/ } @warns ), "$builder: object is not 'unreadable'" )
            or diag @warns;
    }
};

subtest 'hermes wire (NousResearch): ToolChoice->none withholds the tools from the prompt (k231)' => sub {
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $reply = { choices => [ { message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' } ] };
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response($reply) ] );
    my $engine = Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', _async_http => $mock );
    $engine->chat_f( messages => ['weather?'], tools => [$tool],
        tool_choice => Langertha::ToolChoice->none )->get;
    my $body = body_of( ( $mock->requests )[0] );
    ok( !exists $body->{tools} && !exists $body->{tool_choice}, 'neither key in the body' );
    is_deeply( $body->{messages}, [ { role => 'user', content => 'weather?' } ], 'no tool prompt' );
    ok( ( grep { /none.*withheld/ } @warns ), 'carps that the tools were withheld' ) or diag @warns;
    ok( !( grep { /ignored on the hermes/ } @warns ), 'the object is not read as an ignored choice' )
        or diag @warns;
};

subtest 'chat_f: named ToolChoice object drives the ADR 0005 rewrite on Perplexity' => sub {
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( {
        id => 'resp_3', model => 'sonar', status => 'completed',
        output => [ { type => 'message', status => 'completed',
            content => [ { type => 'output_text', text => '{"city":"Berlin"}' } ] } ],
        usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 },
    } ) ] );
    my $engine = Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar', _async_http => $mock );
    my $resp = $engine->chat_f( messages => $msgs, tools => [$tool],
        tool_choice => Langertha::ToolChoice->specific('get_weather') )->get;
    my ($sent) = $mock->requests;
    my $body = body_of($sent);
    ok( !exists $body->{tools}, 'tools rewritten away' );
    ok( !exists $body->{tool_choice}, 'no tool_choice' );
    my $tc = $resp->tool_call('get_weather');
    ok( $tc && $tc->synthetic, 'synthetic ToolCall on Response.tool_calls' );
};

subtest 'chat_f: named ToolChoice object trips the Cerebras exclusion guard' => sub {
    # The mock keeps a guard miss from reaching the network.
    my $mock = Test::MockAsyncHTTP->new( responses => [] );
    my $ok = eval {
        Langertha::Engine::Cerebras->new( api_key => 'k', _async_http => $mock )->chat_f(
            messages        => $msgs,
            tool_choice     => Langertha::ToolChoice->specific('get_weather'),
            response_format => { type => 'json_object' },
        )->get;
        1;
    };
    my $err = $@;
    ok( !$ok, 'croaks like the equivalent hash does' );
    like( $err, qr/Cerebras cannot combine tools and response_format/, 'the exclusion guard croaks' );
    is( $mock->request_count, 0, 'nothing sent' );
};

subtest 'Input::Tools helpers accept the object' => sub {
    my $tc = Langertha::ToolChoice->specific('get_weather');
    is_deeply( Langertha::Input::Tools->normalize_tool_choice($tc),
        { type => 'tool', name => 'get_weather' }, 'normalize_tool_choice' );
    is_deeply( Langertha::Input::Tools->to_openai_tool_choice($tc),
        { type => 'function', function => { name => 'get_weather' } }, 'to_openai_tool_choice' );
    is_deeply( Langertha::Input::Tools->to_anthropic_tool_choice($tc),
        { type => 'tool', name => 'get_weather' }, 'to_anthropic_tool_choice' );
};

done_testing;
