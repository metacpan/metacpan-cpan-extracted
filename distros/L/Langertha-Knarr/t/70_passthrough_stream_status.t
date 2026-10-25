use strict;
use warnings;
use Test2::V0;

# Regression guard (k74): Handler::Passthrough's streaming path never looked
# at the upstream's status, so a 401/429/5xx came out as an empty, successful
# stream. It must fail like handle_chat_f does.

use IO::Async::Loop;
use HTTP::Response;
use Net::Async::HTTP::Server;
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Passthrough;

my $loop = IO::Async::Loop->new;
my $status = 401;
my $upstream = Net::Async::HTTP::Server->new( on_request => sub {
  my ( $self, $req ) = @_;
  my $body = '{"error":{"message":"nope ' . $status . '"}}';
  my $res = HTTP::Response->new( $status, 'Upstream Says No' );
  $res->header( Content_Type => 'application/json', Content_Length => length $body );
  $res->content($body);
  $req->respond($res);
} );
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $port = $upstream->read_handle->sockport;

for my $protocol (qw( openai anthropic ollama )) {
  for my $code ( 401, 429, 500 ) {
    subtest "$protocol stream against $code" => sub {
      $status = $code;
      my $handler = Langertha::Knarr::Handler::Passthrough->new(
        upstreams => { $protocol => "http://127.0.0.1:$port" },
        loop      => $loop,
      );
      my $request = Langertha::Knarr::Request->new(
        protocol => $protocol,
        model    => 'm',
        stream   => 1,
        messages => [ { role => 'user', content => 'hi' } ],
      );
      my $stream = $handler->handle_stream_f( undef, $request )->get;
      my $f = $stream->next_chunk_f; $loop->await($f);
      my $ok = !$f->is_failed;
      my $err = $f->is_failed ? $f->failure : "";
      ok( !$ok, 'next_chunk_f fails instead of ending the stream' );
      like( $err, qr/Passthrough upstream failed: $code /, 'status line in the error' );
      like( $err, qr/nope $code/, 'upstream error text in the error' );
    };
  }
}

done_testing;
