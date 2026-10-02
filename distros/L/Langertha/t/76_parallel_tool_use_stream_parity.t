#!/usr/bin/env perl
# ABSTRACT: parallel_tool_use reaches the wire identically on the streaming and non-streaming builders (k240)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;

# karr k240 / ADR 0009, ADR 0010: parallel_tool_use is a canonical control
# (chat_f `controls`, or the engine attribute from Role::ParallelToolUse). Each
# dialect builds two request bodies, chat_request and chat_stream_request, and a
# setting the caller made must not silently vanish because the call was
# streamed (chat_stream_realtime_f). Before k240 the OpenAI-compatible streaming
# builder dropped it (no parallel_tool_calls on the body), and so did the
# Responses one. The golden here is the non-streaming body: the streaming body
# must be the same apart from the `stream` flag, so the two builders cannot
# drift on this control again.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub body_of { $json->decode( $_[0]->content ) }

sub bodies {
    my ( $engine, @args ) = @_;
    my $msgs = [ { role => 'user', content => 'weather?' } ];
    my $sync   = body_of( $engine->chat_request( $msgs, @args ) );
    my $stream = body_of( $engine->chat_stream_request( $msgs, @args ) );
    delete $_->{stream} for $sync, $stream;
    return ( $sync, $stream );
}

my $tool = {
    name        => 'get_weather',
    description => 'Weather for a city',
    inputSchema => { type => 'object', properties => { city => { type => 'string' } },
                     required => ['city'] },
};

# [ label, constructor args, request args (tools filled in), wire value or undef (absent),
#   drop carps over both builders on an engine without the flag ]
# The last column is ADR 0025 drop+carp as k241/k247 shaped it: a per-request
# control carps on every request (two builders = 2), an engine attribute once
# per engine instance (1), and nothing set or no tools stays silent (0).
sub cases {
    my ($tools) = @_;
    return (
        [ 'control true',            {},                         [ tools => $tools, controls => { parallel_tool_use => 1 } ], 1, 2 ],
        [ 'control false',           {},                         [ tools => $tools, controls => { parallel_tool_use => 0 } ], 0, 2 ],
        [ 'engine attribute false',  { parallel_tool_use => 0 }, [ tools => $tools ], 0, 1 ],
        [ 'control beats attribute', { parallel_tool_use => 0 }, [ tools => $tools, controls => { parallel_tool_use => 1 } ], 1, 2 ],
        [ 'unset',                   {},                         [ tools => $tools ], undef, 0 ],
        [ 'no tools',                { parallel_tool_use => 0 }, [ controls => { parallel_tool_use => 1 } ], undef, 0 ],
    );
}

subtest 'openai-compatible: parallel_tool_calls on both builders' => sub {
    my $tools = [ Langertha::Engine::OpenAI->new( api_key => 'k' )->format_tools([$tool]) ];
    for my $case ( cases($tools) ) {
        my ( $label, $ctor, $args, $want ) = @$case;
        my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6', %$ctor );
        my ( $sync, $stream ) = bodies( $engine, @$args );
        if ( defined $want ) {
            ok( exists $sync->{parallel_tool_calls}, "$label: chat_request sends parallel_tool_calls" );
            is( !!$sync->{parallel_tool_calls}, !!$want, "$label: chat_request value" );
        }
        else {
            ok( !exists $sync->{parallel_tool_calls}, "$label: chat_request sends no parallel_tool_calls" );
        }
        is_deeply( $stream, $sync, "$label: stream body matches the non-streaming body" );
    }
    # An explicit wire-native kwarg passes through untouched on both.
    my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6', parallel_tool_use => 1 );
    my ( $sync, $stream ) = bodies( $engine, tools => $tools,
        parallel_tool_calls => JSON::MaybeXS->false );
    ok( !$sync->{parallel_tool_calls}, 'explicit parallel_tool_calls wins over the attribute' );
    is_deeply( $stream, $sync, 'explicit parallel_tool_calls: stream body matches' );
};

subtest 'anthropic: disable_parallel_tool_use folded on both builders' => sub {
    my $tools = [ Langertha::Engine::Anthropic->new( api_key => 'k' )->format_tools([$tool]) ];
    for my $case ( cases($tools) ) {
        my ( $label, $ctor, $args, $want ) = @$case;
        my $engine = Langertha::Engine::Anthropic->new( api_key => 'k', %$ctor );
        my ( $sync, $stream ) = bodies( $engine, @$args );
        if ( defined $want ) {
            is( !!$sync->{tool_choice}{disable_parallel_tool_use}, !$want, "$label: chat_request value" );
        }
        is_deeply( $stream, $sync, "$label: stream body matches the non-streaming body" );
    }
};

subtest 'responses: parallel_tool_calls on both builders' => sub {
    # OpenAIResponses opts out of streaming at the capability layer, but the
    # envelope's streaming builder is shared by every Responses consumer.
    for my $case ( cases( [ $tool ] ) ) {
        my ( $label, $ctor, $args, $want ) = @$case;
        my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k', %$ctor );
        my ( $sync, $stream ) = bodies( $engine, @$args );
        if ( defined $want ) {
            ok( exists $sync->{parallel_tool_calls}, "$label: chat_request sends parallel_tool_calls" );
            is( !!$sync->{parallel_tool_calls}, !!$want, "$label: chat_request value" );
        }
        else {
            ok( !exists $sync->{parallel_tool_calls}, "$label: chat_request sends no parallel_tool_calls" );
        }
        is_deeply( $stream, $sync, "$label: stream body matches the non-streaming body" );
    }
};

subtest 'perplexity: no parallel_tool_calls field on either builder' => sub {
    # The Agent API has no such field (k213); the capability gate holds on both.
    for my $case ( cases( [ $tool ] ) ) {
        my ( $label, $ctor, $args, undef, $want_carps ) = @$case;
        my $engine = Langertha::Engine::Perplexity->new( api_key => 'k', %$ctor );
        # The drop is loud (k241): collect that carp, pass anything else on.
        my @drop_carps;
        local $SIG{__WARN__} = sub {
            return push @drop_carps, $_[0] if $_[0] =~ /dropping parallel_tool_use/;
            warn @_;
        };
        my ( $sync, $stream ) = bodies( $engine, @$args );
        ok( !exists $sync->{parallel_tool_calls}, "$label: chat_request sends none" );
        ok( !exists $stream->{parallel_tool_calls}, "$label: chat_stream_request sends none" );
        is( scalar @drop_carps, $want_carps, "$label: $want_carps drop carp(s) over both builders" )
            or diag @drop_carps;
        like( $_, qr/\ALangertha::Engine::Perplexity: dropping parallel_tool_use/,
            "$label: the carp names the engine" ) for @drop_carps;
    }
};

done_testing;
