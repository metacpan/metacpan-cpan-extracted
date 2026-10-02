use strict;
use warnings;
use Test2::V0;

# Regression: a buffered raw passthrough answer in a Content-Encoding that
# Net::Async::HTTP had not decoded (br, zstd, anything it has no decoder
# for) went through HTTP::Message->decoded_content, which answers undef for
# an encoding it cannot decode -- and the client got a 200 with an empty
# body. The bytes Net::Async::HTTP hands over now go back as they are, and
# Content-Encoding goes along exactly while those bytes still carry it: on a
# buffered answer (native and PSGI) as on a native stream.

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
  package EncRouter;   # every model is a passthrough model
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# Opaque bytes: no valid br, no valid anything -- whatever tried to decode
# them would fail, which is the point.
my $opaque = "\x0b\x80\x00\xffopaque\x00bytes\xfe";
my $plain  = qq({"choices":[{"message":{"content":"ok","role":"assistant"}}]});

my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    # Lines split on '|' go out as repeated Content-Encoding lines.
    my $label = $req->header('X-Test-Encoding');
    my @enc = map { ( 'Content-Encoding' => $_ ) } split /\|/, $label;
    my $body = $opaque;
    if ( $label eq 'gzip' ) { gzip( \$plain => \$body ) or die $GzipError }
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'text/event-stream', @enc );
      $req->respond_chunk_header($head);
      $req->write_chunk( substr( $body, 0, 5 ) );
      $req->write_chunk( substr( $body, 5 ) );
      $req->write_chunk_eof;
      return;
    }
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body, @enc );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $knarr = Langertha::Knarr->new(
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
  handler         => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
  router          => EncRouter->new,
  raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { openai => $up }, loop => $loop ),
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

# The test client decodes nothing but gzip/deflate itself, so ->content is
# what Knarr sent.
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub send_via {
  my ($transport, $stream, $label) = @_;
  my $body = $json->encode({ model => 'gpt-x', messages => [ { role => 'user', content => 'hi' } ],
    $stream ? ( stream => JSON::MaybeXS::true() ) : () });
  my @h = ( 'Content-Type' => 'application/json', 'X-Test-Encoding' => $label );
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => 'http://localhost/v1/chat/completions', \@h, $body ) );
}

# 'gzip|br': two header lines, gzip then br -- not decodable as a whole, so
# neither line may be dropped.
for my $label ( 'br', 'x-knarr-test', 'gzip, br', 'gzip|br' ) {
  for my $stream ( 0, 1 ) {
    for my $transport ( 'native', 'psgi' ) {
      my $tag = "$transport/" . ( $stream ? 'stream' : 'sync' ) . ", $label";
      my $resp = send_via( $transport, $stream, $label );
      is( $resp->code, 200, "$tag: answered" );
      is( $resp->content, $opaque, "$tag: the upstream's bytes unchanged, not an empty body" );
      is( [ $resp->header('Content-Encoding') ], [ split /\|/, $label ],
        "$tag: Content-Encoding goes along with the bytes it describes" );
      is( [ $resp->header('Content-Length') ], [ length $opaque ],
        "$tag: Content-Length counts those bytes" ) if $transport eq 'native' && !$stream;
    }
  }
}

# An encoding Net::Async::HTTP decodes still goes back decoded, without
# its label (k56).
for my $stream ( 0, 1 ) {
  for my $transport ( 'native', 'psgi' ) {
    my $tag = "$transport/" . ( $stream ? 'stream' : 'sync' ) . ', gzip';
    my $resp = send_via( $transport, $stream, 'gzip' );
    is( $resp->code, 200, "$tag: answered" );
    is( $resp->content, $plain, "$tag: decoded bytes" );
    is( [ $resp->header('Content-Encoding') ], [], "$tag: no Content-Encoding on decoded bytes" );
  }
}

done_testing;
