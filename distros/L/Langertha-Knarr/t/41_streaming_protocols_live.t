use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub { 'hello world' },
  stream_code => sub {
    my @parts = ( 'hel', 'lo ', 'wor', 'ld' );
    return sub { @parts ? shift @parts : undef };
  },
);

my $knarr = Langertha::Knarr->new(
  handler => $handler,
  loop    => $loop,
  port    => 0,
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
ok( $port, "knarr on $port" );

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post {
  my ($path, $body) = @_;
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port$path" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode($body) );
  return $http->do_request( request => $req )->get;
}

# --- Anthropic streaming: named SSE events ---
{
  my $resp = post( '/v1/messages', {
    model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
    stream => JSON::MaybeXS::true(),
  });
  is( $resp->code, 200, 'anthropic stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE type' );
  my $body = $resp->decoded_content;
  like( $body, qr/event: message_start/,        'message_start frame' );
  like( $body, qr/event: content_block_start/,  'block_start frame' );
  like( $body, qr/event: content_block_delta/,  'block_delta frames' );
  like( $body, qr/event: content_block_stop/,   'block_stop frame' );
  like( $body, qr/event: message_stop/,         'message_stop frame' );
  like( $body, qr/"text":"hel"/,                'first chunk text in delta' );
  like( $body, qr/"text":"ld"/,                 'last chunk text in delta' );

  # Count content_block_delta events — should equal number of stream chunks (4).
  my $deltas = () = $body =~ /event: content_block_delta/g;
  is( $deltas, 4, 'four content_block_delta events' );
}

# --- A2A streaming via JSON-RPC tasks/sendSubscribe ---
{
  my $resp = post( '/', {
    jsonrpc => '2.0',
    id      => 1,
    method  => 'tasks/sendSubscribe',
    params  => {
      id => 'task-1',
      message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] },
    },
  });
  is( $resp->code, 200, 'a2a stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE type' );
  my $body = $resp->decoded_content;
  my @data = grep { /^data:/ } split /\n/, $body;
  ok( scalar(@data) >= 6, 'multiple a2a frames (open + 4 chunks + close)' );
  like( $body, qr/"state":"working"/,    'working state frame' );
  like( $body, qr/"state":"completed"/,  'completed state frame' );
  like( $body, qr/"text":"hel"/,         'first chunk text' );
  like( $body, qr/"text":"ld"/,          'last chunk text' );
  like( $body, qr/"final":true/,         'final flag set on close' );

  # Each delta should be a JSON-RPC envelope with the original id.
  my $first_delta = (grep { /artifact/ } @data)[0];
  ok( $first_delta, 'has artifact frame' );
  like( $first_delta, qr/"id":1/, 'jsonrpc id preserved' );
}

# --- ACP streaming ---
{
  my $resp = post( '/runs', {
    agent_name => 'm',
    mode       => 'stream',
    input      => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ],
  });
  is( $resp->code, 200, 'acp stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE type' );
  my $body = $resp->decoded_content;
  like( $body, qr/event: run\.created/,        'run.created' );
  like( $body, qr/event: message\.created/,    'message.created' );
  like( $body, qr/event: message\.part/,       'message.part frames' );
  like( $body, qr/event: message\.completed/,  'message.completed' );
  like( $body, qr/event: run\.completed/,      'run.completed' );
  like( $body, qr/"content":"hel"/,            'first chunk content' );
  like( $body, qr/"content":"ld"/,             'last chunk content' );

  my $parts = () = $body =~ /event: message\.part/g;
  is( $parts, 4, 'four message.part events' );
}

# --- AG-UI streaming ---
{
  my $resp = post( '/awp', {
    threadId => 'th-1',
    runId    => 'run-1',
    messages => [ { role => 'user', content => 'hi' } ],
  });
  is( $resp->code, 200, 'agui stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE type' );
  my $body = $resp->decoded_content;
  like( $body, qr/"type":"RUN_STARTED"/,           'RUN_STARTED' );
  like( $body, qr/"type":"TEXT_MESSAGE_START"/,    'TEXT_MESSAGE_START' );
  like( $body, qr/"type":"TEXT_MESSAGE_CONTENT"/,  'TEXT_MESSAGE_CONTENT frames' );
  like( $body, qr/"type":"TEXT_MESSAGE_END"/,      'TEXT_MESSAGE_END' );
  like( $body, qr/"type":"RUN_FINISHED"/,          'RUN_FINISHED' );
  like( $body, qr/"delta":"hel"/,                  'first delta' );
  like( $body, qr/"delta":"ld"/,                   'last delta' );

  my $contents = () = $body =~ /TEXT_MESSAGE_CONTENT/g;
  is( $contents, 4, 'four TEXT_MESSAGE_CONTENT events' );
}

done_testing;
