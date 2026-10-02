use strict;
use warnings;
use Test2::V0;

# Regression (k48): on the routed path an Ollama POST /api/generate was
# answered in the /api/chat shape (message.content instead of response),
# sync and streaming, and Handler::Passthrough in the handler chain sent the
# generate body to the upstream's /api/chat and read message.content from
# the answer. /api/generate answers in Ollama's generate shape now, and the
# chain passthrough reaches the upstream's /api/generate. /api/chat stays as
# it was. Native server and PSGI alike.

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

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub knarr_with {
  my ($handler) = @_;
  my $knarr = Langertha::Knarr->new(
    handler => $handler,
    loop    => $loop,
    listen  => [ '127.0.0.1:0' ],
  );
  $knarr->start;
  return (
    $knarr,
    $knarr->_server->read_handle->sockport,
    Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  );
}

sub request {
  my ($transport, $port, $psgi, $path, $body) = @_;
  my @h = ( 'Content-Type' => 'application/json' );
  my $content = $json->encode($body);
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port$path", \@h, $content ) )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
}

sub lines { map { $json->decode($_) } grep { length } split /\n/, $_[0] }

my %gen_sync  = ( model => 'llama', prompt => 'hi', stream => JSON::MaybeXS::false() );
my %gen_strm  = ( model => 'llama', prompt => 'hi' );
my %chat_sync = ( model => 'llama', messages => [ { role => 'user', content => 'hi' } ],
  stream => JSON::MaybeXS::false() );
my %chat_strm = ( model => 'llama', messages => [ { role => 'user', content => 'hi' } ] );

# --- Routed path: an engine-like handler answers ------------------------

{
  my ($knarr, $port, $psgi) = knarr_with( Langertha::Knarr::Handler::Code->new(
    code => sub {
      return {
        content       => 'hello world',
        finish_reason => 'stop',
        usage         => { prompt_tokens => 11, completion_tokens => 18, total_tokens => 29 },
      };
    },
    stream_code => sub {
      my @parts = ( 'hel', 'lo ', 'wor', 'ld' );
      return sub { @parts ? shift @parts : undef };
    },
  ) );

  for my $transport ( 'native', 'psgi' ) {
    my $resp = request( $transport, $port, $psgi, '/api/generate', \%gen_sync );
    is( $resp->code, 200, "$transport generate sync: 200" );
    my $d = $json->decode( $resp->content );
    is( $d, hash {
      field model       => 'llama';
      field created_at  => match qr/^\d{4}-\d\d-\d\dT/;
      field response    => 'hello world';
      field done        => T();
      field done_reason => 'stop';
      field prompt_eval_count => 11;
      field eval_count        => 18;
      field message     => DNE();
      etc;
    }, "$transport generate sync: Ollama generate shape with the usage counters" );

    $resp = request( $transport, $port, $psgi, '/api/generate', \%gen_strm );
    is( $resp->code, 200, "$transport generate stream: 200" );
    like( $resp->header('Content-Type'), qr{application/x-ndjson}, "$transport generate stream: NDJSON" );
    my @l = lines( $resp->content );
    is( scalar @l, 5, "$transport generate stream: four chunks and the done line" );
    is( [ map { $_->{response} } @l[0..3] ], [ 'hel', 'lo ', 'wor', 'ld' ],
      "$transport generate stream: text rides on response" );
    ok( !( grep { exists $_->{message} } @l ), "$transport generate stream: no message field" );
    ok( !( grep { $_->{done} } @l[0..3] ), "$transport generate stream: chunks are done:false" );
    is( $l[-1], hash {
      field model       => 'llama';
      field response    => '';
      field done        => T();
      field done_reason => 'stop';
      field message     => DNE();
      etc;
    }, "$transport generate stream: final {done: true} line in the generate shape" );

    # /api/chat keeps its shape.
    $resp = request( $transport, $port, $psgi, '/api/chat', \%chat_sync );
    $d = $json->decode( $resp->content );
    is( $d->{message}{content}, 'hello world', "$transport chat sync: still message.content" );
    ok( !exists $d->{response}, "$transport chat sync: no response field" );
    @l = lines( request( $transport, $port, $psgi, '/api/chat', \%chat_strm )->content );
    is( [ map { $_->{message}{content} } @l ], [ 'hel', 'lo ', 'wor', 'ld', '' ],
      "$transport chat stream: still message.content" );
  }
  $knarr->stop if $knarr->can('stop');
}

# --- Handler::Passthrough in the chain ----------------------------------

my %answer = (
  '/api/generate' => qq({"done":true,"done_reason":"stop","model":"llama","response":"gen"}),
  '/api/chat'     => qq({"done":true,"done_reason":"stop","message":{"content":"chat","role":"assistant"},"model":"llama"}),
);
my %stream = (
  '/api/generate' => [ qq({"done":false,"response":"g"}\n), qq({"done":false,"response":"en"}\n),
    qq({"done":true,"done_reason":"length","response":""}\n) ],
  '/api/chat'     => [ qq({"done":false,"message":{"content":"ch"}}\n), qq({"done":false,"message":{"content":"at"}}\n),
    qq({"done":true,"done_reason":"length"}\n) ],
);

my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, $req->path;
    my $path = exists $answer{ $req->path } ? $req->path : '/api/chat';
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
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

{
  my ($knarr, $port, $psgi) = knarr_with( Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { ollama => $up }, loop => $loop ) );

  for my $transport ( 'native', 'psgi' ) {
    @seen = ();
    my $d = $json->decode( request( $transport, $port, $psgi, '/api/generate', \%gen_sync )->content );
    is( \@seen, [ '/api/generate' ], "$transport chain generate sync: upstream /api/generate" );
    is( $d->{response}, 'gen', "$transport chain generate sync: upstream response read, answered as response" );
    ok( !exists $d->{message}, "$transport chain generate sync: no message field" );

    @seen = ();
    my @l = lines( request( $transport, $port, $psgi, '/api/generate', \%gen_strm )->content );
    is( \@seen, [ '/api/generate' ], "$transport chain generate stream: upstream /api/generate" );
    is( [ map { $_->{response} } @l ], [ 'g', 'en', '' ], "$transport chain generate stream: response chunks" );
    is( $l[-1]{done_reason}, 'length', "$transport chain generate stream: upstream done_reason carried" );

    @seen = ();
    $d = $json->decode( request( $transport, $port, $psgi, '/api/chat', \%chat_sync )->content );
    is( \@seen, [ '/api/chat' ], "$transport chain chat sync: upstream /api/chat" );
    is( $d->{message}{content}, 'chat', "$transport chain chat sync: message.content" );

    @seen = ();
    @l = lines( request( $transport, $port, $psgi, '/api/chat', \%chat_strm )->content );
    is( \@seen, [ '/api/chat' ], "$transport chain chat stream: upstream /api/chat" );
    is( [ map { $_->{message}{content} } @l ], [ 'ch', 'at', '' ], "$transport chain chat stream: message chunks" );
  }
}

done_testing;
