#!/usr/bin/env perl
# ABSTRACT: The tool loops read each reply through chat_response, like chat_f

use strict;
use warnings;

use Test2::Bundle::More;

# The three MCP tool loops -- Role::Tools::chat_with_tools_f and
# Langertha::Chat's simple_chat_with_tools / simple_chat_with_tools_f -- used to
# read the raw body themselves (parse_response + response_text_content), a
# second, weaker parser beside the engine's chat_response that chat_f uses.
#
#   karr k321: the body-error guards live in chat_response (k301, k311, k317),
#   so a 200 carrying an error answered the loop with '' as the final text,
#   where chat_f croaks "response carried an error". A caller could not tell
#   a failed request from a model that said nothing.
#
#   karr k322: the final text diverged from chat_f's -- Gemini thought parts
#   leaked into the answer, and a Mistral content-chunk list came back as an
#   ARRAY ref instead of text.
#
# The invariant: on the same wire body, every loop ends the way chat_f does --
# the same croak text, or the same content.

use lib 't/lib';
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny;
use Future;
use Test::MockAsyncHTTP;

use Langertha::Chat;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Mistral;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;

{
  package LoopUserAgent;
  our @ISA = ('LWP::UserAgent');
  sub new {
    my ( $class, @responses ) = @_;
    my $self = $class->SUPER::new;
    $self->{queue} = [@responses];
    return $self;
  }
  sub request {
    my ( $self ) = @_;
    my $response = shift @{ $self->{queue} };
    die "LoopUserAgent: no canned response left\n" unless $response;
    return $response;
  }
}

{
  package LoopMCP;
  sub new { bless { calls => 0 }, shift }
  sub list_tools {
    Future->done([ { name => 'echo', description => 'Echo',
      inputSchema => { type => 'object', properties => {} } } ]);
  }
  sub call_tool {
    $_[0]{calls}++;
    Future->done({ content => [ { type => 'text', text => 'ok' } ] });
  }
}

my %engine = (
  openai    => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x', @_ ) },
  mistral   => sub { Langertha::Engine::Mistral->new( api_key => 'k', model => 'magistral-medium-latest', @_ ) },
  gemini    => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x', @_ ) },
  responses => sub { Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro', @_ ) },
  anthropic => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x', response_size => 256, @_ ) },
);

sub http_for {
  my ( $body ) = @_;
  my $raw = ref $body ? encode_json($body) : $body;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $raw );
}

sub mock_for { Test::MockAsyncHTTP->new( responses => [ http_for( $_[0] ) ] ) }

sub strip_location {
  my ( $err ) = @_;
  $err =~ s/ at \S+ line \d+\.?\n?\z//;
  return $err;
}

# Runs one wire body through chat_f and the three loops. Returns
# { name => [ 'ok' => $text | 'died' => $error ] }.
sub run_all {
  my ( $dialect, $body ) = @_;
  my $make = $engine{$dialect};
  my %out;
  my $capture = sub {
    my ( $name, $code ) = @_;
    my $result = eval { $code->() };
    $out{$name} = defined $result ? [ ok => $result ] : [ died => strip_location($@) ];
  };
  $capture->( chat_f => sub {
    $make->( _async_http => mock_for($body) )
      ->chat_f( messages => [ { role => 'user', content => 'hi' } ] )->get->content;
  });
  $capture->( chat_with_tools_f => sub {
    $make->( _async_http => mock_for($body), mcp_servers => [ LoopMCP->new ] )
      ->chat_with_tools_f('hi')->get;
  });
  $capture->( simple_chat_with_tools_f => sub {
    Langertha::Chat->new( engine => $make->( _async_http => mock_for($body) ),
      mcp_servers => [ LoopMCP->new ] )->simple_chat_with_tools_f('hi')->get;
  });
  $capture->( simple_chat_with_tools => sub {
    Langertha::Chat->new( engine => $make->( user_agent => LoopUserAgent->new( http_for($body) ) ),
      mcp_servers => [ LoopMCP->new ] )->simple_chat_with_tools('hi');
  });
  return \%out;
}

my @loops = qw( chat_with_tools_f simple_chat_with_tools_f simple_chat_with_tools );

# --- k321: an error in a 200 body croaks in every loop, as in chat_f --------

my @error_cases = (
  [ openai => 'top-level error object, no choices (k301)',
    { error => { message => 'upstream overloaded', code => 502 } },
    qr/response carried an error: upstream overloaded \(502\)/ ],
  [ openai => 'error inside the choice, finish_reason error (k311)',
    { choices => [ { index => 0, finish_reason => 'error',
      message => { role => 'assistant', content => '' },
      error => { message => 'provider died' } } ] },
    qr/response carried an error: provider died/ ],
  [ openai => 'finish_reason error without an error object (k317)',
    { choices => [ { index => 0, finish_reason => 'error',
      message => { role => 'assistant', content => '' } } ] },
    qr/response ended with finish_reason error/ ],
  [ openai => 'empty choices list (k301)',
    { choices => [] },
    qr/response contained no choices/ ],
  [ gemini => 'error object, no candidates (k301)',
    { error => { message => 'quota exhausted', code => 429 } },
    qr/response carried an error: quota exhausted \(429\)/ ],
  [ responses => 'error object, no output (k311)',
    { id => 'resp_1', object => 'response', status => 'failed', output => [],
      error => { message => 'server_error', code => 'server_error' } },
    qr/response carried an error: server_error/ ],
  [ anthropic => 'error envelope in a 200 (k338)',
    { type => 'error', error => { type => 'overloaded_error', message => 'Overloaded' } },
    qr/response carried an error: Overloaded/ ],
);

for my $case (@error_cases) {
  my ( $dialect, $label, $body, $want ) = @$case;
  subtest "k321 $dialect: $label" => sub {
    my $out = run_all( $dialect, $body );
    is( $out->{chat_f}[0], 'died', 'chat_f croaks' );
    like( $out->{chat_f}[1], $want, 'with the body error' );
    for my $loop (@loops) {
      is( $out->{$loop}[0], 'died', "$loop croaks instead of answering ''" );
      is( $out->{$loop}[1], $out->{chat_f}[1], "$loop croaks chat_f's text" );
    }
  };
}

# --- k322: the final text is chat_f's content ------------------------------

my @text_cases = (
  # Gemini thinking models return the thought summary as a part with
  # thought:true beside the answer; it is thinking, not answer text.
  [ gemini => 'thought parts stay out of the answer',
    { responseId => 'r1', modelVersion => 'gemini-x',
      candidates => [ { finishReason => 'STOP', content => { role => 'model', parts => [
        { text => '**Planning** I will just answer.', thought => JSON::MaybeXS::true() },
        { text => 'Answer: 4' },
      ] } } ] },
    'Answer: 4' ],
  # Mistral's documented Magistral reply: message.content is a chunk list
  # (thinking, text, reference) -- the same body t/47_openai_content_chunks.t
  # replays.
  [ mistral => 'a content-chunk list becomes its text',
    path('t/data/mistral_magistral_doc_response.json')->slurp_raw,
    '2 + 2 = **4**' ],
  [ anthropic => 'thinking blocks stay out of the answer',
    { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
      stop_reason => 'end_turn', content => [
        { type => 'thinking', thinking => 'Let me add.', signature => 'sig' },
        { type => 'text', text => 'Answer: 4' },
      ] },
    'Answer: 4' ],
);

for my $case (@text_cases) {
  my ( $dialect, $label, $body, $want ) = @$case;
  subtest "k322 $dialect: $label" => sub {
    my $out = run_all( $dialect, $body );
    is_deeply( $out->{chat_f}, [ ok => $want ], 'chat_f content' );
    for my $loop (@loops) {
      is( ref $out->{$loop}[1], '', "$loop answers a string, not a reference" );
      is_deeply( $out->{$loop}, [ ok => $want ], "$loop answers chat_f's content" );
    }
  };
}

# --- the sync Chat loop names its failure like the async one (k312) --------

subtest 'a non-2xx reply fails every loop as a "tool chat request"' => sub {
  my $failed = sub {
    HTTP::Response->new( 503, 'Service Unavailable',
      [ 'Content-Type' => 'application/json' ], '{"error":{"message":"down"}}' );
  };
  my $make = $engine{openai};
  my %err;
  eval { Langertha::Chat->new( engine => $make->( user_agent => LoopUserAgent->new( $failed->() ) ),
    mcp_servers => [ LoopMCP->new ] )->simple_chat_with_tools('hi') };
  $err{simple_chat_with_tools} = strip_location($@);
  eval { Langertha::Chat->new( engine => $make->( _async_http => Test::MockAsyncHTTP->new( responses => [ $failed->() ] ) ),
    mcp_servers => [ LoopMCP->new ] )->simple_chat_with_tools_f('hi')->get };
  $err{simple_chat_with_tools_f} = strip_location($@);
  eval { $make->( _async_http => Test::MockAsyncHTTP->new( responses => [ $failed->() ] ),
    mcp_servers => [ LoopMCP->new ] )->chat_with_tools_f('hi')->get };
  $err{chat_with_tools_f} = strip_location($@);
  like( $err{simple_chat_with_tools}, qr/tool chat request failed: 503 Service Unavailable - .*down/,
    'sync loop: "tool chat request failed", body included' );
  is( $err{simple_chat_with_tools}, $err{simple_chat_with_tools_f}, 'sync and async Chat loops agree' );
  is( $err{simple_chat_with_tools}, $err{chat_with_tools_f}, 'and agree with the engine loop' );
};

# --- the calls come from Response.tool_calls and still round-trip ----------

subtest 'a tool turn runs Response.tool_calls, and the echo pairs by id' => sub {
  my $tool_turn = { id => 'c1', choices => [ { index => 0, finish_reason => 'tool_calls',
    message => { role => 'assistant', content => undef, tool_calls => [
      { id => 'call_7', type => 'function', function => { name => 'echo', arguments => '{"x":1}' } },
    ] } } ] };
  my $text_turn = { id => 'c2', choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'done' } } ] };
  my $mock = Test::MockAsyncHTTP->new( responses => [ http_for($tool_turn), http_for($text_turn) ] );
  my $mcp = LoopMCP->new;
  my $result = $engine{openai}->( _async_http => $mock, mcp_servers => [$mcp] )
    ->chat_with_tools_f('hi')->get;
  is( $result, 'done', 'final text' );
  is( $mcp->{calls}, 1, 'the call ran' );
  my $turn2 = decode_json( ( $mock->requests )[1]->content );
  my ($result_msg) = grep { ( $_->{role} // '' ) eq 'tool' } @{ $turn2->{messages} };
  is( $result_msg->{tool_call_id}, 'call_7', 'the result block carries the call id' );
};

done_testing;
