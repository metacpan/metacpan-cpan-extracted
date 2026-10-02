use strict;
use warnings;
use Test2::V0;

# Regression: the raw passthrough is 1:1, but a header the client sent twice
# reached the upstream once, with its last value -- the upstream request was
# built with HTTP::Headers->header, which replaces. And in the other
# direction the upstream's answer came back with its status, content type
# and body only: every other response header (a Set-Cookie sent twice,
# retry-after, request ids) was dropped, on a buffered answer and on a
# stream. Now every client header line reaches the upstream in its order,
# Knarr's proxy key still taken out of each line on its own, and the
# upstream's response headers come back with their repeats, minus the
# connection-level ones Knarr sets itself and a Content-Encoding the bytes
# no longer carry.
#
# Under PSGI the server hands Knarr a header sent twice as one value joined
# with ', ' (one HTTP_* key); that one value is forwarded unchanged. The
# response side keeps repeats there too.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;
use IO::Compress::Gzip qw( gzip $GzipError );

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

{
  package DupRouter;   # every model is a passthrough model
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $sync_body = qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"ok","role":"assistant"}}]});
my @stream_chunks = (
  qq(data: {"choices":[{"delta":{"content":"a"}}]}\n\n),
  "data: [DONE]\n\n",
);

# The response headers the upstream sends on every answer, repeats included.
my @upstream_response_headers = (
  'Set-Cookie'   => 'a=1; Path=/',
  'X-Request-Id' => 'req-1',
  'Set-Cookie'   => 'b=2; Path=/',
  'X-Dup'        => 'first',
  'X-Dup'        => 'second',
  'Retry-After'  => '7',
);

# Every header line the upstream got, in order, duplicates kept.
my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, [ map { [ lc $_->[0], $_->[1] ] } $req->headers ];
    my $label = $req->header('X-Test-Encoding');
    my $gz = ( $label // '' ) eq 'gzip';
    my @enc = $label ? ( 'Content-Encoding' => $label ) : ();
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'text/event-stream', @enc, @upstream_response_headers );
      $req->respond_chunk_header($head);
      if ( $gz ) {
        my $plain = join '', @stream_chunks;
        gzip( \$plain => \my $packed ) or die $GzipError;
        $req->write_chunk($packed);
      }
      else {
        $req->write_chunk($_) for @stream_chunks;
      }
      $req->write_chunk_eof;
      return;
    }
    my $body = $sync_body;
    if ( $gz ) { gzip( \$sync_body => \$body ) or die $GzipError }
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body,
      @enc, @upstream_response_headers );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my $KEY = 'PROXYSECRET';

my $knarr = Langertha::Knarr->new(
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
  auth_token      => $KEY,
  handler         => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
  router          => DupRouter->new,
  raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { openai => $up }, loop => $loop ),
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my @client_headers = (
  'Content-Type'  => 'application/json',
  'X-Custom'      => 'one',
  'Authorization' => "Bearer $KEY",
  'X-Custom'      => 'two',
  'Authorization' => 'Bearer sk-own',
  'X-Custom'      => 'three',
);

sub send_via {
  my ($transport, $stream, @extra) = @_;
  my $body = $json->encode({ model => 'gpt-x', messages => [ { role => 'user', content => 'hi' } ],
    $stream ? ( stream => JSON::MaybeXS::true() ) : () });
  my @h = ( @client_headers, @extra );
  @seen = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => 'http://localhost/v1/chat/completions', \@h, $body ) );
  return ( $resp, [ @seen ] );
}

sub lines_of {
  my ($lines, $name) = @_;
  return [ map { $_->[1] } grep { $_->[0] eq $name } @$lines ];
}

for my $stream ( 0, 1 ) {
  my $kind = $stream ? 'stream' : 'sync';
  for my $transport ( 'native', 'psgi' ) {
    my $tag = "$transport/$kind";
    my ($resp, $seen) = send_via( $transport, $stream );
    is( $resp->code, 200, "$tag: answered" );
    is( scalar @$seen, 1, "$tag: reached the upstream once" ) or next;
    my $lines = $seen->[0];

    # Request direction.
    is( lines_of( $lines, 'x-custom' ),
      $transport eq 'native' ? [ 'one', 'two', 'three' ] : [ 'one, two, three' ],
      $transport eq 'native'
        ? "$tag: a header sent three times reaches the upstream three times, in order"
        : "$tag: the PSGI server's merged value reaches the upstream unchanged" );
    is( lines_of( $lines, 'authorization' ), [ 'Bearer sk-own' ],
      "$tag: the proxy key is taken out, the client's own key kept" );
    is( [ grep { index( $_->[1], $KEY ) >= 0 } @$lines ], [],
      "$tag: the proxy key reaches the upstream in no header" );

    # Response direction.
    is( [ $resp->header('Set-Cookie') ], [ 'a=1; Path=/', 'b=2; Path=/' ],
      "$tag: both Set-Cookie headers come back, in order" );
    is( [ $resp->header('X-Dup') ], [ 'first', 'second' ], "$tag: a repeated header comes back repeated" );
    is( scalar $resp->header('X-Request-Id'), 'req-1', "$tag: upstream request id comes back" );
    is( scalar $resp->header('Retry-After'), '7', "$tag: retry-after comes back" );
    is( [ $resp->header('Content-Type') ], [ $stream ? 'text/event-stream' : 'application/json' ],
      "$tag: the upstream's content type, once" );

    if ( $stream ) {
      is( $resp->decoded_content( charset => 'none' ), join( '', @stream_chunks ),
        "$tag: the stream's bytes unchanged, ending with data: [DONE]" );
    }
    else {
      is( $resp->decoded_content( charset => 'none' ), $sync_body, "$tag: the body unchanged" );
    }
    if ( $transport eq 'native' ) {
      is( [ $resp->header('Content-Length') ], $stream ? [] : [ length $sync_body ],
        "$tag: one Content-Length, set by Knarr" );
      is( scalar $resp->header('Cache-Control'), 'no-cache', "$tag: no-cache on a stream" ) if $stream;
    }
  }
}

# A gzip answer reaches Knarr decoded (Net::Async::HTTP decodes what it
# knows, a stream too), so it goes back decoded and without its
# Content-Encoding -- a client told 'gzip' about plain bytes cannot read
# them. A stream in an encoding nobody decoded is piped with its label.
for my $stream ( 0, 1 ) {
  my $kind = $stream ? 'stream' : 'sync';
  for my $transport ( 'native', 'psgi' ) {
    my $tag = "$transport/$kind, gzip";
    my ($resp) = send_via( $transport, $stream, 'X-Test-Encoding' => 'gzip' );
    is( $resp->code, 200, "$tag: answered" );
    is( [ $resp->header('Content-Encoding') ], [], "$tag: no Content-Encoding on the decoded body" );
    is( $resp->content, $stream ? join( '', @stream_chunks ) : $sync_body,
      "$tag: the client gets the decoded bytes" );
  }
}
{
  my $tag = 'native/stream, undecoded encoding';
  my ($resp) = send_via( 'native', 1, 'X-Test-Encoding' => 'x-knarr-test' );
  is( $resp->code, 200, "$tag: answered" );
  is( [ $resp->header('Content-Encoding') ], [ 'x-knarr-test' ],
    "$tag: Content-Encoding goes along with the bytes it still describes" );
  is( $resp->content, join( '', @stream_chunks ), "$tag: the bytes unchanged" );
}

done_testing;
