#!/usr/bin/env perl
# ABSTRACT: tool_choice reaches the body only where supports('tool_choice_*') says the wire has it (k239)

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Langertha::Engine::Ollama;
use Langertha::Engine::OllamaOpenAI;
use Langertha::Engine::LMStudio;
use Langertha::Engine::OpenAI;
use Langertha::ToolChoice;
use Test::MockAsyncHTTP;

# karr k239 (ADR 0002, ADR 0010): Ollama native (/api/chat) and Ollama's /v1
# endpoint have no tool_choice field. Their Go servers bind JSON without
# DisallowUnknownFields, so a tool_choice is accepted, IGNORED and answered
# 200 -- the caller believes a tool was forced when the model was free to
# skip it. LM Studio's native /api/v1/chat takes neither tools nor
# tool_choice ("Custom tools: NO" in its endpoint table). One Role::Chat rule
# now decides a caller's tool_choice against supports('tool_choice_*'):
# auto (the wire default) and undef drop silently, 'none' withholds the tools
# with a carp, a forced choice drops with a carp. On Ollama native a forced
# named tool through chat_f takes the ADR 0005 rewrite instead: format=<schema>
# plus a synthetic ToolCall, grammar-constrained.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $msgs = [ { role => 'user', content => 'weather?' } ];
my $tools = [ { type => 'function', function => {
    name => 'get_weather', description => 'Weather for a city',
    parameters => { type => 'object', properties => { city => { type => 'string' } },
                    required => ['city'] } } } ];

sub body_of { $json->decode( $_[0]->content ) }

# Body and warnings of one builder call.
sub build {
    my ( $engine, $builder, @args ) = @_;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $body = body_of( $engine->$builder( $msgs, @args ) );
    return ( $body, \@warns );
}

my %engines = (
    ollama        => sub { Langertha::Engine::Ollama->new( url => 'http://127.0.0.1:11434', model => 'qwen3:8b', @_ ) },
    ollama_openai => sub { Langertha::Engine::OllamaOpenAI->new( url => 'http://127.0.0.1:11434/v1', model => 'qwen3:8b', @_ ) },
);

subtest 'Ollama native claims no tool_choice, keeps tools_native' => sub {
    my $e = $engines{ollama}->();
    ok( $e->supports('tools_native'), 'tools_native stays (the tools array works)' );
    ok( !$e->supports($_), "no $_ (no tool_choice field on /api/chat)" )
        for qw( tool_choice_auto tool_choice_any tool_choice_none tool_choice_named );
};

for my $name ( sort keys %engines ) {
    subtest "$name: no tool_choice on the body" => sub {
        my $e = $engines{$name}->();
        for my $builder (qw( chat_request chat_stream_request )) {
            for my $auto ( 'auto', Langertha::ToolChoice->auto, undef ) {
                my $label = defined $auto ? ( ref $auto ? 'auto object' : 'auto' ) : 'undef';
                my ( $body, $warns ) = build( $e, $builder, tools => $tools, tool_choice => $auto );
                ok( !exists $body->{tool_choice}, "$builder: $label not sent" );
                ok( $body->{tools} && @{ $body->{tools} }, "$builder: $label keeps the tools" );
                ok( !@$warns, "$builder: dropping $label is silent (the wire default)" ) or diag @$warns;
            }
            for my $forced ( 'required', 'any', { type => 'tool', name => 'get_weather' },
                             Langertha::ToolChoice->specific('get_weather') ) {
                my $label = ref $forced ? ( ref $forced eq 'HASH' ? 'named hash' : 'named object' ) : $forced;
                my ( $body, $warns ) = build( $e, $builder, tools => $tools, tool_choice => $forced );
                ok( !exists $body->{tool_choice}, "$builder: $label not sent" );
                ok( $body->{tools} && @{ $body->{tools} }, "$builder: $label keeps the tools" );
                ok( ( grep { /dropping tool_choice/ } @$warns ), "$builder: dropping $label carps" )
                    or diag @$warns;
            }
            my ( $body, $warns ) = build( $e, $builder, tools => $tools, tool_choice => 'none' );
            ok( !exists $body->{tool_choice} && !exists $body->{tools},
                "$builder: none withholds the tools instead" );
            ok( ( grep { /tool_choice 'none'.*withh[oe]ld/ } @$warns ), "$builder: carps the withhold" )
                or diag @$warns;
            # k246: with no tools there is nothing to withhold, so no carp
            # (the hermes path already stays quiet here); the field still drops.
            for my $no_tools ( [], [ tools => [] ], [ tools => undef ] ) {
                my $label = @$no_tools ? ( defined $no_tools->[1] ? 'empty tools' : 'tools undef' ) : 'no tools';
                ( $body, $warns ) = build( $e, $builder, @$no_tools, tool_choice => 'none' );
                ok( !exists $body->{tool_choice}, "$builder: none with $label not sent" );
                ok( !@$warns, "$builder: none with $label is silent" ) or diag @$warns;
            }
        }
    };
}

subtest 'Ollama native chat_f: a forced named tool takes the ADR 0005 rewrite' => sub {
    my $mock = Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( {
        model => 'qwen3:8b', done => JSON->true,
        message => { role => 'assistant', content => '{"city":"Berlin"}' } } ) ] );
    my $e = $engines{ollama}->( _async_http => $mock );
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $response = $e->chat_f( messages => ['weather?'], tools => $tools,
        tool_choice => { type => 'tool', name => 'get_weather' } )->get;
    my $body = body_of( ( $mock->requests )[0] );
    ok( !exists $body->{tool_choice} && !exists $body->{tools}, 'neither tools nor tool_choice on the wire' );
    is( ref $body->{format}, 'HASH', 'the tool schema rides format' );
    my $tc = $response->tool_call('get_weather');
    ok( $tc && $tc->synthetic, 'a synthetic ToolCall lands on Response.tool_calls' );
    is_deeply( $response->tool_call_args('get_weather'), { city => 'Berlin' }, 'with the arguments' );
    ok( !@warns, 'the rewrite needs no carp' ) or diag @warns;
};

subtest 'LMStudio native: tools croak, tool_choice never reaches the body' => sub {
    my $e = Langertha::Engine::LMStudio->new( model => 'qwen2.5-7b-instruct' );
    for my $builder (qw( chat_request chat_stream_request )) {
        eval { $e->$builder( $msgs, tools => $tools ) };
        like( $@, qr/LMStudioOpenAI.*LMStudioAnthropic|LMStudioAnthropic.*LMStudioOpenAI/,
            "$builder: tools croak, pointing to the tool-capable faces" );
        eval { $e->$builder( $msgs, tools => 'get_weather' ) };
        like( $@, qr/takes no tools/, "$builder: a defined non-list tools value croaks" );
        my ( $body, $warns ) = build( $e, $builder, tools => [] );
        ok( !exists $body->{tools}, "$builder: an empty tools list is not sent" );
        # k246: tools => undef is "no tools" (a caller passing an optional
        # list through), not a tool request -- no croak, nothing sent.
        ( $body, $warns ) = eval { build( $e, $builder, tools => undef ) };
        is( $@, '', "$builder: tools => undef does not croak" );
        ok( $body && !exists $body->{tools} && !@$warns, "$builder: tools => undef is not sent, silently" );
        ( $body, $warns ) = build( $e, $builder, tool_choice => 'none' );
        ok( !exists $body->{tool_choice} && !@$warns, "$builder: none without tools dropped silently" )
            or diag @$warns;
        ( $body, $warns ) = build( $e, $builder, tool_choice => 'auto' );
        ok( !exists $body->{tool_choice} && !@$warns, "$builder: auto dropped silently" ) or diag @$warns;
        ( $body, $warns ) = build( $e, $builder, tool_choice => { type => 'tool', name => 'x' } );
        ok( !exists $body->{tool_choice}, "$builder: forced choice not sent" );
        ok( ( grep { /dropping tool_choice/ } @$warns ), "$builder: and carps" ) or diag @$warns;
    }
};

subtest 'a wire with tool_choice is unchanged' => sub {
    my $e = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6' );
    for my $builder (qw( chat_request chat_stream_request )) {
        my ( $body, $warns ) = build( $e, $builder, tools => $tools, tool_choice => 'none' );
        is( $body->{tool_choice}, 'none', "$builder: none sent" );
        ok( $body->{tools}, "$builder: tools kept" );
        ( $body, $warns ) = build( $e, $builder, tools => $tools,
            tool_choice => { type => 'tool', name => 'get_weather' } );
        is_deeply( $body->{tool_choice}, { type => 'function', function => { name => 'get_weather' } },
            "$builder: named sent in the OpenAI shape" );
        ( $body, $warns ) = build( $e, $builder, tools => $tools,
            tool_choice => { type => 'allowed_tools', mode => 'auto', tools => [] } );
        is( $body->{tool_choice}{type}, 'allowed_tools', "$builder: an unreadable native value passes through" );
        ok( !@$warns, "$builder: silently" ) or diag @$warns;
    }
};

done_testing;
