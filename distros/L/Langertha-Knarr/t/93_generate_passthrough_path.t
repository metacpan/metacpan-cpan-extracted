use strict;
use warnings;
use Test2::V0;

# Regression (k46): the raw passthrough knew one upstream path per protocol,
# so an Ollama POST /api/generate went to the upstream's /api/chat with a
# generate body (prompt, no messages). It reaches the upstream's
# /api/generate now; /api/chat stays /api/chat, and the bytes go through
# unchanged both ways. Native server and PSGI alike.

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

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

{
  package GenRouter;
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my %answer = (
  '/api/generate' => qq({"done":true,"model":"llama","response":"gen \xc3\xa4"}),
  '/api/chat'     => qq({"done":true,"message":{"content":"chat","role":"assistant"},"model":"llama"}),
);
my %stream = (
  '/api/generate' => [ qq({"done":false,"response":"a"}\n), qq({"done":true,"done_reason":"stop","response":""}\n) ],
  '/api/chat'     => [ qq({"done":false,"message":{"content":"a"}}\n), qq({"done":true,"done_reason":"stop"}\n) ],
);

my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, { path => $req->path, body => $req->body };
    my $path = exists $answer{ $req->path } ? $req->path : '/api/chat';
    if ( ( $req->body // '' ) !~ /"stream":false/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'application/x-ndjson' );
      $req->respond_chunk_header($head);
      $req->write_chunk($_) for @{ $stream{$path} };
      $req->write_chunk_eof;
      return;
    }
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $answer{$path} );
    $resp->content( $answer{$path} );
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $knarr = Langertha::Knarr->new(
  handler         => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
  router          => GenRouter->new,
  raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { ollama => $up }, loop => $loop ),
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my @cases = (
  [ 'generate sync',   '/api/generate', { model => 'llama', prompt => 'hi', stream => JSON::MaybeXS::false() } ],
  [ 'generate stream', '/api/generate', { model => 'llama', prompt => 'hi' } ],
  [ 'chat sync',       '/api/chat', { model => 'llama', messages => [ { role => 'user', content => 'hi' } ],
    stream => JSON::MaybeXS::false() } ],
);

for my $case (@cases) {
  my ($label, $path, $body) = @$case;
  my $content = $json->encode($body);
  my $expected = $content =~ /"stream":false/ ? $answer{$path} : join '', @{ $stream{$path} };
  for my $transport ( 'native', 'psgi' ) {
    @seen = ();
    my @h = ( 'Content-Type' => 'application/json' );
    my $resp = $transport eq 'native'
      ? $http->do_request( request =>
          HTTP::Request->new( POST => "http://127.0.0.1:$port$path", \@h, $content ) )->get
      : $psgi->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
    is( $resp->code, 200, "$transport $label: 200" );
    is( scalar @seen, 1, "$transport $label: upstream hit once" ) or next;
    is( $seen[0]{path}, $path, "$transport $label: upstream path is the client's $path" );
    is( $seen[0]{body}, $content, "$transport $label: body forwarded 1:1" );
    is( $resp->content, $expected, "$transport $label: answer returned 1:1" );
  }
}

done_testing;
