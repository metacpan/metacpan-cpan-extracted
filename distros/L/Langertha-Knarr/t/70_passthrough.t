use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# --- Backend: a Knarr that answers OpenAI/Anthropic/Ollama with a known string,
#     plus token-by-token streaming so the passthrough's stream-extractor can
#     unwrap the protocol-native chunks.
my $backend_handler = Langertha::Knarr::Handler::Code->new(
  code => sub {
    my ($s, $r) = @_;
    my $u = $r->messages->[-1] // {};
    return "BACKEND: " . ( $u->{content} // '' );
  },
  stream_code => sub {
    my @parts = ('BACK', 'END:', ' hi');
    return sub { @parts ? shift @parts : undef };
  },
);
my $backend = Langertha::Knarr->new(
  handler => $backend_handler,
  loop    => $loop,
  port    => 0,
);
$backend->start;
my $bport = $backend->_server->read_handle->sockport;
ok( $bport, "backend on $bport" );

# --- Knarr in front of the backend with a Passthrough handler.
my $passthrough = Langertha::Knarr::Handler::Passthrough->new(
  upstreams => {
    openai    => "http://127.0.0.1:$bport",
    anthropic => "http://127.0.0.1:$bport",
    ollama    => "http://127.0.0.1:$bport",
  },
  loop => $loop,
);
my $front = Langertha::Knarr->new(
  handler => $passthrough,
  loop    => $loop,
  port    => 0,
);
$front->start;
my $fport = $front->_server->read_handle->sockport;
ok( $fport, "front on $fport" );

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_json {
  my ($url, $body) = @_;
  my $req = HTTP::Request->new( POST => $url );
  $req->header( 'Content-Type' => 'application/json' );
  $req->content( $json->encode($body) );
  return $http->do_request( request => $req )->get;
}

# --- 1) OpenAI sync passthrough ---
{
  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/chat/completions",
    { model => 'm', messages => [ { role => 'user', content => 'hi' } ] },
  );
  is( $resp->code, 200, 'openai passthrough sync 200' );
  my $d = $json->decode($resp->decoded_content);
  is( $d->{choices}[0]{message}{content}, 'BACKEND: hi', 'openai content via passthrough' );
}

# --- 2) Ollama sync passthrough ---
{
  my $resp = post_json(
    "http://127.0.0.1:$fport/api/chat",
    { model => 'm', messages => [ { role => 'user', content => 'yo' } ], stream => JSON::MaybeXS::false() },
  );
  is( $resp->code, 200, 'ollama passthrough sync 200' );
  my $d = $json->decode($resp->decoded_content);
  is( $d->{message}{content}, 'BACKEND: yo', 'ollama content via passthrough' );
}

# --- 3) Anthropic sync passthrough ---
{
  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/messages",
    { model => 'm', messages => [ { role => 'user', content => 'sup' } ] },
  );
  is( $resp->code, 200, 'anthropic passthrough sync 200' );
  my $d = $json->decode($resp->decoded_content);
  is( $d->{content}[0]{text}, 'BACKEND: sup', 'anthropic content via passthrough' );
}

# --- 4) OpenAI streaming passthrough ---
{
  my $resp = post_json(
    "http://127.0.0.1:$fport/v1/chat/completions",
    { model => 'm', messages => [ { role => 'user', content => 'hi' } ], stream => JSON::MaybeXS::true() },
  );
  is( $resp->code, 200, 'openai passthrough stream 200' );
  is( $resp->header('Content-Type'), 'text/event-stream', 'SSE content type' );
  my $body = $resp->decoded_content;
  my @data = grep { /^data:/ && !/\[DONE\]/ } split /\n/, $body;
  ok( scalar(@data) >= 3, 'multiple SSE chunks forwarded' );
  like( $body, qr/BACK/, 'first chunk text present' );
  like( $body, qr/END:/, 'second chunk text present' );
}

# --- 5) Ollama streaming passthrough ---
{
  my $resp = post_json(
    "http://127.0.0.1:$fport/api/chat",
    { model => 'm', messages => [ { role => 'user', content => 'hi' } ], stream => JSON::MaybeXS::true() },
  );
  is( $resp->code, 200, 'ollama passthrough stream 200' );
  is( $resp->header('Content-Type'), 'application/x-ndjson', 'NDJSON content type' );
  my @lines = grep { length } split /\n/, $resp->decoded_content;
  ok( scalar(@lines) >= 4, 'multiple NDJSON lines forwarded' );
  my $last = $json->decode($lines[-1]);
  ok( $last->{done}, 'final ndjson chunk has done:true' );
}

# --- 6) list_models on passthrough ---
{
  is( $passthrough->list_models->[0]{id}, 'passthrough', 'default model id' );
}

done_testing;
