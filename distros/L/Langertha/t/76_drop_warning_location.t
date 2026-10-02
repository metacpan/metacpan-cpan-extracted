#!/usr/bin/env perl
# ABSTRACT: Capability drop warnings name the caller's line and do not repeat for engine attributes
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';
use Test::MockAsyncHTTP;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;

# karr k247 (ADR 0025 drop+carp). A request builder that leaves a value off the
# wire warns, but the warning fired in a private helper several Langertha frames
# below the caller, and Carp skips only one frame: it named a line in
# Role/OpenAICompatible.pm or Engine/Ollama.pm, which tells the user nothing
# about which of their calls set the value. And a value that comes from an
# engine attribute is the same on every request, so it warned on every request,
# every chat_with_tools_f iteration included. Now the warning names the user's
# own call site, and an engine-attribute drop warns once per engine instance,
# while a value passed with the request still warns every time.

my $file = __FILE__;

my %reply = (
  openai => { model => 'gpt-5.6-terra',
    choices => [ { index => 0, finish_reason => 'stop',
                   message => { role => 'assistant', content => 'ok' } } ] },
  ollama => { model => 'm', done => JSON::MaybeXS::true(),
              message => { role => 'assistant', content => 'ok' } },
  gemini => { candidates => [ { finishReason => 'STOP',
                content => { role => 'model', parts => [ { text => 'ok' } ] } } ] },
);

sub mock { Test::MockAsyncHTTP->new( responses => [ Test::MockAsyncHTTP->mock_json_response( $reply{ $_[0] } ) ] ) }

sub openai { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-5.6-terra', _async_http => mock('openai'), @_ ) }
sub ollama { Langertha::Engine::Ollama->new( url => 'http://h:1', model => 'm', _async_http => mock('ollama'), @_ ) }
sub gemini { Langertha::Engine::Gemini->new( api_key => 'k', _async_http => mock('gemini'), @_ ) }

my $tool = {
  name        => 'get_weather',
  description => 'Weather for a city',
  inputSchema => { type => 'object', properties => { city => { type => 'string' } } },
};
my $msgs = [ { role => 'user', content => 'weather?' } ];

# Runs $code with warnings captured; returns the ones matching $re.
sub warnings_of {
  my ( $re, $code ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $code->();
  return grep { /$re/ } @warns;
}

# The warning must say "at <this test file> line <the call's line>".
sub at_call_site {
  my ( $warns, $line, $label ) = @_;
  is( scalar @$warns, 1, "$label: one warning" ) or diag @$warns;
  like( $warns->[0] // '', qr/ at \Q$file\E line $line\.$/m, "$label: names the caller's line" )
    or diag @$warns;
}

subtest 'the warning names the caller, not Langertha internals' => sub {
  my $line;
  my @w = warnings_of( qr/dropping temperature/, sub {
    $line = __LINE__; openai( temperature => 0.5 )->chat_f( messages => $msgs )->get;
  } );
  at_call_site( \@w, $line, 'OpenAI reasoning model, temperature, chat_f' );

  @w = warnings_of( qr/dropping temperature/, sub {
    $line = __LINE__; openai( temperature => 0.5 )->simple_chat_f('hi')->get;
  } );
  at_call_site( \@w, $line, 'OpenAI reasoning model, temperature, simple_chat_f' );

  my $engine = openai();
  @w = warnings_of( qr/dropping temperature/, sub {
    $line = __LINE__; $engine->chat_request( $engine->chat_messages('p'), controls => { temperature => 0.5 } );
  } );
  at_call_site( \@w, $line, 'OpenAI reasoning model, temperature, chat_request' );

  @w = warnings_of( qr/dropping tool_choice/, sub {
    $line = __LINE__; ollama()->chat_f( messages => $msgs, tools => [$tool], tool_choice => 'required' )->get;
  } );
  at_call_site( \@w, $line, 'Ollama native, forced tool_choice, chat_f' );

  @w = warnings_of( qr/dropping parallel_tool_use/, sub {
    $line = __LINE__; gemini( parallel_tool_use => 0 )->chat_f( messages => $msgs, tools => [$tool] )->get;
  } );
  at_call_site( \@w, $line, 'Gemini, parallel_tool_use engine attribute, chat_f' );
};

subtest 'an engine attribute warns once per engine, a request value every time' => sub {
  my $engine = openai( temperature => 0.5 );
  my @w = warnings_of( qr/dropping temperature/, sub {
    $engine->chat_f( messages => $msgs )->get for 1 .. 3;
  } );
  is( scalar @w, 1, 'temperature attribute: one warning over three requests' ) or diag @w;

  @w = warnings_of( qr/dropping temperature/, sub {
    openai( temperature => 0.5 )->chat_f( messages => $msgs )->get;
  } );
  is( scalar @w, 1, 'a new engine instance warns again' ) or diag @w;

  $engine = openai();
  @w = warnings_of( qr/dropping temperature/, sub {
    $engine->chat_f( messages => $msgs, temperature => 0.5 )->get for 1 .. 3;
  } );
  is( scalar @w, 3, 'temperature per request: one warning per request' ) or diag @w;

  $engine = gemini( parallel_tool_use => 0 );
  @w = warnings_of( qr/dropping parallel_tool_use/, sub {
    $engine->chat_f( messages => $msgs, tools => [$tool] )->get for 1 .. 3;
  } );
  is( scalar @w, 1, 'parallel_tool_use attribute: one warning over three requests' ) or diag @w;

  $engine = gemini();
  @w = warnings_of( qr/dropping parallel_tool_use/, sub {
    $engine->chat_f( messages => $msgs, tools => [$tool], parallel_tool_use => 0 )->get for 1 .. 3;
  } );
  is( scalar @w, 3, 'parallel_tool_use per request: one warning per request' ) or diag @w;

  $engine = ollama();
  @w = warnings_of( qr/dropping tool_choice/, sub {
    $engine->chat_f( messages => $msgs, tools => [$tool], tool_choice => 'required' )->get for 1 .. 3;
  } );
  is( scalar @w, 3, 'tool_choice (always per request): one warning per request' ) or diag @w;
};

subtest 'croak keeps its location' => sub {
  # Only the drop warnings are relocated; Carp::Internal is restored after
  # each one, so a later carp/croak from Langertha is unchanged.
  my $engine = openai( temperature => 0.5 );
  warnings_of( qr/./, sub { $engine->chat_f( messages => $msgs )->get } );
  ok( !grep( { /\ALangertha/ } keys %Carp::Internal ), 'no Langertha package left in %Carp::Internal' );
};

done_testing;
