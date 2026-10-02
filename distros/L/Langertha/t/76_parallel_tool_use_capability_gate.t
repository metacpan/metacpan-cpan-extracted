#!/usr/bin/env perl
# ABSTRACT: parallel_tool_calls reaches the body only where supports('parallel_tool_use') says the wire has it (k241)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::Scaleway;
use Langertha::Engine::MiniMax;
use Langertha::Engine::Hetzner;
use Langertha::Engine::Perplexity;
use Langertha::Engine::OpenAI;

# karr k241 (ADR 0002): a capability flag is what the wire accepts, and since
# k241 it also decides what goes on the body. Gemini (FunctionCallingConfig has
# no parallel knob), Ollama native and Ollama's /v1 (no parallel_tool_calls
# field; the Go decoder drops it) claimed parallel_tool_use through
# Role::Tools and silently lost the setting. The OpenAI-compatible envelope put
# parallel_tool_calls on the body even where the engine had cleared the flag
# (Scaleway ignores it and acts as true, MiniMax and Hetzner do not document
# it). Now the flag gates emission on both the Chat Completions and the
# Responses envelope; a setting the caller made that the gate drops carps
# (ADR 0025 drop+carp), nothing set stays silent, and an explicit
# parallel_tool_calls kwarg is the caller's wire intent and still passes.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $msgs = [ { role => 'user', content => 'weather?' } ];
my $tool = {
    name        => 'get_weather',
    description => 'Weather for a city',
    inputSchema => { type => 'object', properties => { city => { type => 'string' } },
                     required => ['city'] },
};

sub build {
    my ( $engine, $builder, @args ) = @_;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $body = $json->decode( $engine->$builder( $msgs, @args )->content );
    return ( $body, \@warns );
}

subtest 'native wires without a parallel knob claim none' => sub {
    ok( !Langertha::Engine::Gemini->new( api_key => 'k' )->supports('parallel_tool_use'), 'gemini' );
    ok( !Langertha::Engine::Ollama->new( url => 'http://h:1', model => 'm' )->supports('parallel_tool_use'),
        'ollama native' );
    ok( !Langertha::Engine::OllamaOpenAI->new( url => 'http://h:1/v1', model => 'm' )->supports('parallel_tool_use'),
        'ollama /v1' );
    ok( Langertha::Engine::OpenAI->new( api_key => 'k' )->supports('parallel_tool_use'), 'openai keeps it' );
};

my %make = (
    ollama_openai => sub { Langertha::Engine::OllamaOpenAI->new( url => 'http://h:1/v1', model => 'm', @_ ) },
    scaleway      => sub { Langertha::Engine::Scaleway->new( api_key => 'k', model => 'm', @_ ) },
    minimax       => sub { Langertha::Engine::MiniMax->new( api_key => 'k', @_ ) },
    hetzner       => sub { Langertha::Engine::Hetzner->new( api_key => 'k', @_ ) },
    perplexity    => sub { Langertha::Engine::Perplexity->new( api_key => 'k', @_ ) },
);

for my $name ( sort keys %make ) {
    subtest "$name: no parallel_tool_calls without the flag" => sub {
        my $tools = $make{$name}->()->format_tools([$tool]);
        ok( !$make{$name}->()->supports('parallel_tool_use'), "$name clears parallel_tool_use" );
        for my $builder (qw( chat_request chat_stream_request )) {
            for my $case (
                [ 'control', {}, [ controls => { parallel_tool_use => 0 } ] ],
                [ 'engine attribute', { parallel_tool_use => 0 }, [] ],
            ) {
                my ( $label, $ctor, $args ) = @$case;
                my ( $body, $warns ) = build( $make{$name}->(%$ctor), $builder, tools => $tools, @$args );
                ok( !exists $body->{parallel_tool_calls}, "$builder: $label not sent" );
                ok( ( grep { /dropping parallel_tool_use/ } @$warns ), "$builder: dropping a set $label carps" )
                    or diag @$warns;
            }
            my ( $body, $warns ) = build( $make{$name}->(), $builder, tools => $tools );
            ok( !exists $body->{parallel_tool_calls} && !@$warns, "$builder: nothing set, nothing sent, silent" )
                or diag @$warns;
            ( $body, $warns ) = build( $make{$name}->( parallel_tool_use => 0 ), $builder,
                controls => { parallel_tool_use => 0 } );
            ok( !@$warns, "$builder: no tools, nothing to drop, silent" ) or diag @$warns;
            ( $body, $warns ) = build( $make{$name}->(), $builder, tools => $tools,
                parallel_tool_calls => JSON::MaybeXS->false );
            ok( exists $body->{parallel_tool_calls} && !$body->{parallel_tool_calls},
                "$builder: an explicit parallel_tool_calls kwarg still passes" );
            ok( !@$warns, "$builder: silently" ) or diag @$warns;
        }
    };
}

# Ollama native and Gemini have no parallel knob at all: a set value is only
# dropped, loudly, the same carp as the envelopes.
for my $native (
    [ ollama => sub { Langertha::Engine::Ollama->new( url => 'http://h:1', model => 'm', @_ ) } ],
    [ gemini => sub { Langertha::Engine::Gemini->new( api_key => 'k', @_ ) } ],
) {
    my ( $name, $make ) = @$native;
    subtest "$name native: a set parallel_tool_use carps, nothing reaches the body" => sub {
        my $tools = $make->()->format_tools([$tool]);
        for my $builder (qw( chat_request chat_stream_request )) {
            for my $case (
                [ 'control', {}, [ controls => { parallel_tool_use => 0 } ] ],
                [ 'engine attribute', { parallel_tool_use => 0 }, [] ],
            ) {
                my ( $label, $ctor, $args ) = @$case;
                my ( $body, $warns ) = build( $make->(%$ctor), $builder, tools => $tools, @$args );
                ok( !( grep { /parallel/ } keys %$body ), "$builder: $label not on the body" );
                ok( ( grep { /dropping parallel_tool_use/ } @$warns ), "$builder: dropping a set $label carps" )
                    or diag @$warns;
            }
            my ( $body, $warns ) = build( $make->(), $builder, tools => $tools );
            ok( !@$warns, "$builder: nothing set, silent" ) or diag @$warns;
        }
    };
}

subtest 'openai keeps sending it, silently' => sub {
    my $e = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
    my $tools = $e->format_tools([$tool]);
    for my $builder (qw( chat_request chat_stream_request )) {
        my ( $body, $warns ) = build( $e, $builder, tools => $tools, controls => { parallel_tool_use => 0 } );
        ok( exists $body->{parallel_tool_calls} && !$body->{parallel_tool_calls}, "$builder: sent" );
        ok( !@$warns, "$builder: no carp" ) or diag @$warns;
    }
};

done_testing;
