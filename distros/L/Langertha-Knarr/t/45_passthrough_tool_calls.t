use strict;
use warnings;
use utf8;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;

# k21: a non-streaming Handler::Passthrough answer must carry the upstream's
# tool calls and its finish reason. It returned the text only, so a client
# whose model asked for a tool got a plain text answer (often empty) with a
# "normal end" -- the agent loop has nothing to execute and stops. The
# upstream JSON is now read per protocol (OpenAI choices[0].message.tool_calls,
# Anthropic tool_use content blocks, Ollama message.tool_calls) through core's
# Langertha::ToolCall->extract, the same door the streaming path (k19) uses,
# and the terminal reason is kept verbatim for the client-side protocol to
# map. Arguments carry a non-ASCII value, since they are decoded from a UTF-8
# body and re-encoded into another one and must not be encoded twice.

use Langertha::Knarr;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Passthrough;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
# function.arguments is JSON nested in an already-decoded body: characters.
# A byte decoder here only passed while the wire was encoded twice (k24).
my $args_json = JSON::MaybeXS->new( canonical => 1 );
my $loop = IO::Async::Loop->new;

my %UPSTREAM = (
  '/v1/chat/completions' => '{"id":"chatcmpl-u","object":"chat.completion","model":"m","choices":[{"index":0,"message":{"role":"assistant","content":null,"tool_calls":['
    . '{"id":"call_x","type":"function","function":{"name":"weather","arguments":"{\"city\":\"Köln\"}"}},'
    . '{"id":"call_y","type":"function","function":{"name":"time","arguments":"{}"}}'
    . ']},"finish_reason":"tool_calls"}],"usage":{"prompt_tokens":3,"completion_tokens":5,"total_tokens":8}}',
  '/v1/messages' => '{"id":"msg_u","type":"message","role":"assistant","model":"m","content":['
    . '{"type":"text","text":"Schaue nach"},'
    . '{"type":"tool_use","id":"toolu_x","name":"weather","input":{"city":"Köln"}},'
    . '{"type":"tool_use","id":"toolu_y","name":"time","input":{}}'
    . '],"stop_reason":"tool_use","stop_sequence":null,"usage":{"input_tokens":3,"output_tokens":5}}',
  '/api/chat' => '{"model":"m","created_at":"2026-09-25T00:00:00Z","message":{"role":"assistant","content":"",'
    . '"tool_calls":[{"function":{"name":"weather","arguments":{"city":"Köln"}}}]},"done":true,"done_reason":"stop"}',
);

my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $srv, $r ) = @_;
    my $body = $UPSTREAM{ $r->path } or return $r->respond( HTTP::Response->new(404) );
    my $resp = HTTP::Response->new(200);
    $resp->header( 'Content-Type' => 'application/json' );
    utf8::encode( my $bytes = $body );
    $resp->content($bytes);
    $resp->content_length( length $bytes );
    $r->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $uport = $upstream->read_handle->sockport;

my %WANT = (
  openai => {
    text   => '',
    finish => 'tool_calls',
    calls  => [ [ call_x => weather => { city => 'Köln' } ], [ call_y => time => {} ] ],
  },
  anthropic => {
    text   => 'Schaue nach',
    finish => 'tool_use',
    calls  => [ [ toolu_x => weather => { city => 'Köln' } ], [ toolu_y => time => {} ] ],
  },
  ollama => {
    text   => '',
    finish => 'stop',
    calls  => [ [ '' => weather => { city => 'Köln' } ] ],
  },
);

my $passthrough = Langertha::Knarr::Handler::Passthrough->new(
  upstreams => { map { $_ => "http://127.0.0.1:$uport" } qw( openai anthropic ollama ) },
  loop      => $loop,
);

subtest 'handle_chat_f returns the upstream tool calls and finish reason' => sub {
  my $session = Langertha::Knarr::Session->new( id => 's' );
  for my $proto (qw( openai anthropic ollama )) {
    my $r = Langertha::Knarr::Request->new(
      protocol => $proto, model => 'm',
      messages => [ { role => 'user', content => 'hi' } ],
      raw => { model => 'm', messages => [ { role => 'user', content => 'hi' } ] },
    );
    my $resp = $passthrough->handle_chat_f( $session, $r )->get;
    is $resp->content, $WANT{$proto}{text}, "$proto: text";
    is $resp->finish_reason, $WANT{$proto}{finish}, "$proto: finish_reason verbatim";
    ok( ( !grep { !$_->isa('Langertha::ToolCall') } @{ $resp->tool_calls } ), "$proto: ToolCall objects" );
    is [ map { [ $_->id, $_->name, $_->arguments ] } @{ $resp->tool_calls } ], $WANT{$proto}{calls},
      "$proto: calls";
  }
};

subtest 'a text-only upstream answer carries no calls' => sub {
  local $UPSTREAM{'/v1/chat/completions'} =
    '{"choices":[{"index":0,"message":{"role":"assistant","content":"Grüße"},"finish_reason":"stop"}]}';
  my $r = Langertha::Knarr::Request->new(
    protocol => 'openai', model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
    raw => { model => 'm', messages => [ { role => 'user', content => 'hi' } ] },
  );
  my $resp = $passthrough->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $r )->get;
  is $resp->content, 'Grüße', 'text';
  is $resp->tool_calls, [], 'no calls';
  is $resp->finish_reason, 'stop', 'finish_reason';
};

# --- End to end: a Knarr server with the Passthrough handler answers each
#     client protocol with the upstream's calls in that protocol's shape.

my $front = Langertha::Knarr->new( handler => $passthrough, loop => $loop, port => 0 );
$front->start;
my $fport = $front->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_json {
  my ($path) = @_;
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$fport$path" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode({
    model => 'm', max_tokens => 16, stream => JSON::MaybeXS::false(),
    messages => [ { role => 'user', content => 'hi' } ],
  }) );
  my $resp = $http->do_request( request => $req )->get;
  is $resp->code, 200, "$path: 200";
  return $json->decode( $resp->content );
}

subtest 'Knarr re-frames the upstream calls for the client' => sub {
  my $openai = post_json('/v1/chat/completions');
  is $openai->{choices}[0]{finish_reason}, 'tool_calls', 'openai: finish_reason';
  is [ map { [ $_->{id}, $_->{function}{name}, $args_json->decode( $_->{function}{arguments} ) ] }
      @{ $openai->{choices}[0]{message}{tool_calls} } ],
    [ [ call_x => weather => { city => 'Köln' } ], [ call_y => time => {} ] ], 'openai: calls';

  my $anthropic = post_json('/v1/messages');
  is $anthropic->{stop_reason}, 'tool_use', 'anthropic: stop_reason';
  is [ map { [ $_->{type}, $_->{text} // $_->{name}, $_->{input} ] } @{ $anthropic->{content} } ],
    [ [ text => 'Schaue nach', undef ], [ tool_use => weather => { city => 'Köln' } ], [ tool_use => time => {} ] ],
    'anthropic: text and tool_use blocks';

  my $ollama = post_json('/api/chat');
  is $ollama->{done_reason}, 'stop', 'ollama: done_reason';
  is $ollama->{message}{tool_calls}[0]{function}, { name => 'weather', arguments => { city => 'Köln' } },
    'ollama: calls';
};

done_testing;
