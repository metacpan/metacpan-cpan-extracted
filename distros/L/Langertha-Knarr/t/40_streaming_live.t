use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;
use Future::AsyncAwait;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub { 'hello world' },
  stream_code => sub {
    my @parts = ('hel', 'lo ', 'wor', 'ld');
    return sub { @parts ? shift @parts : undef };
  },
);

my $loop = IO::Async::Loop->new;

my $sb = Langertha::Knarr->new(
  handler => $handler,
  loop    => $loop,
  host    => '127.0.0.1',
  port    => 0,  # any free port
);
$sb->start;

# Discover the actual port we bound to
my $sock = $sb->_server->read_handle;
my $port = $sock->sockport;
ok( $port, "bound to port $port" );

my $http = Net::Async::HTTP->new;
$loop->add($http);

# --- 1) non-streaming OpenAI roundtrip ---
{
  my $body = $json->encode({
    model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
  });
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'non-stream 200' );
  my $data = $json->decode( $resp->decoded_content );
  is( $data->{object}, 'chat.completion', 'non-stream object' );
  is( $data->{choices}[0]{message}{content}, 'hello world', 'non-stream content' );
}

# --- 2) streaming OpenAI ---
{
  my $body = $json->encode({
    model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
    stream => JSON::MaybeXS::true(),
  });
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($body);

  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE content type' );
  my $body_text = $resp->decoded_content;
  my @data_lines = grep { /^data:/ } split /\n/, $body_text;
  ok( scalar(@data_lines) >= 4, 'multiple SSE data lines emitted' );
  like( $body_text, qr/hel/, 'first chunk present' );
  like( $body_text, qr/ld/,  'last chunk present' );
}

# --- 3) streaming Ollama (NDJSON) ---
{
  my $body = $json->encode({
    model => 'm',
    messages => [ { role => 'user', content => 'hi' } ],
    stream => JSON::MaybeXS::true(),
  });
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/api/chat" );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($body);
  my $resp = $http->do_request( request => $req )->get;
  is( $resp->code, 200, 'ollama stream 200' );
  is( $resp->header('Content-Type'), 'application/x-ndjson', 'NDJSON content type' );
  my @lines = grep { length } split /\n/, $resp->decoded_content;
  ok( scalar(@lines) >= 4, 'multiple ndjson lines' );
  my $first = $json->decode($lines[0]);
  is( $first->{message}{content}, 'hel', 'first ollama chunk' );
  my $last = $json->decode($lines[-1]);
  ok( $last->{done}, 'last ollama chunk has done:true' );
}

done_testing;
