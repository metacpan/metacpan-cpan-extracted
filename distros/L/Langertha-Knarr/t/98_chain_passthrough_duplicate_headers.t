use strict;
use warnings;
use Test2::V0;

# Regression: on the handler-chain path the protocol parsers kept the
# client's auth headers (forward_headers) as a hash, read with a scalar
# ->header, so a header the client sent twice reached the upstream through
# Handler::Passthrough once, as one merged value -- while the raw
# passthrough forwards each line. Now forward_headers is a list of
# [ name, value ] pairs: every line the client sent reaches the upstream as
# its own line, in order, Knarr's proxy key taken out of each line on its
# own. OpenAI, Anthropic and Ollama; sync and stream.
#
# Under PSGI the server hands Knarr a header sent twice as one value joined
# with ', ' (one HTTP_* key); that value goes on as one line, the proxy key
# taken out of it.

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
use Langertha::Knarr::Request;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $KEY = 'PROXYSECRET';

# --- The parsers on their own: pairs, repeats kept, in order -------------

{
  my $body = $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ] });
  my $http = HTTP::Request->new( POST => '/', [
    Authorization       => 'Bearer one',
    'x-api-key'         => 'k1',
    'X-Other'           => 'no',
    Authorization       => 'Bearer two',
    'anthropic-version' => '2023-06-01',
    'x-api-key'         => 'k2',
  ] );
  is( Langertha::Knarr::Protocol::OpenAI->new->parse_chat_request( $http, \$body )
      ->extra->{forward_headers},
    [ [ authorization => 'Bearer one' ], [ authorization => 'Bearer two' ] ],
    'OpenAI parser: each Authorization line as its own pair' );
  is( Langertha::Knarr::Protocol::Anthropic->new->parse_chat_request( $http, \$body )
      ->extra->{forward_headers},
    [ [ 'x-api-key' => 'k1' ], [ 'x-api-key' => 'k2' ], [ 'anthropic-version' => '2023-06-01' ],
      [ authorization => 'Bearer one' ], [ authorization => 'Bearer two' ] ],
    'Anthropic parser: each line of each auth header as its own pair' );
  is( Langertha::Knarr::Protocol::Ollama->new->parse_chat_request( $http, \$body )
      ->extra->{forward_headers},
    [ [ authorization => 'Bearer one' ], [ authorization => 'Bearer two' ] ],
    'Ollama parser: each Authorization line as its own pair' );
}

# --- The lookup helper on the Request --------------------------------------

{
  my $req = Langertha::Knarr::Request->new( protocol => 'openai',
    extra => { forward_headers => [ [ Authorization => 'a' ], [ 'x-api-key' => 'b' ], [ authorization => 'c' ] ] } );
  is( [ $req->forward_header_pairs ], [ [ Authorization => 'a' ], [ 'x-api-key' => 'b' ], [ authorization => 'c' ] ],
    'forward_header_pairs: the pairs as recorded' );
  is( [ $req->forward_header('authorization') ], [ 'a', 'c' ],
    'forward_header: every value of a name, case-insensitive, in order' );
  my $legacy = Langertha::Knarr::Request->new( protocol => 'openai',
    extra => { forward_headers => { 'X-B' => 2, 'X-A' => 1 } } );
  is( [ $legacy->forward_header_pairs ], [ [ 'X-A' => 1 ], [ 'X-B' => 2 ] ],
    'a hash built by hand still reads as pairs, by name' );
  is( [ Langertha::Knarr::Request->new( protocol => 'openai' )->forward_header_pairs ], [],
    'no forward_headers: no pairs' );
}

# --- Through Knarr and Handler::Passthrough to a fake upstream -------------

my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, { path => $req->path, headers => [ map { [ lc $_->[0], $_->[1] ] } $req->headers ] };
    my $path   = $req->path;
    my $stream = ( $req->body // '' ) =~ /"stream":true/;
    my ($ctype, @chunks);
    if ( $path eq '/v1/chat/completions' ) {
      $ctype  = $stream ? 'text/event-stream' : 'application/json';
      @chunks = $stream
        ? ( qq(data: {"choices":[{"delta":{"content":"ok"}}]}\n\n),
            qq(data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\n\n), "data: [DONE]\n\n" )
        : ( qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"ok","role":"assistant"}}]}) );
    }
    elsif ( $path eq '/v1/messages' ) {
      $ctype  = $stream ? 'text/event-stream' : 'application/json';
      @chunks = $stream
        ? ( qq(event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"ok"}}\n\n),
            qq(event: message_delta\ndata: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}\n\n),
            qq(event: message_stop\ndata: {"type":"message_stop"}\n\n) )
        : ( qq({"content":[{"type":"text","text":"ok"}],"stop_reason":"end_turn"}) );
    }
    else {
      $ctype  = $stream ? 'application/x-ndjson' : 'application/json';
      @chunks = $stream
        ? ( qq({"message":{"role":"assistant","content":"ok"},"done":false}\n),
            qq({"message":{"role":"assistant","content":""},"done":true,"done_reason":"stop"}\n) )
        : ( qq({"message":{"role":"assistant","content":"ok"},"done":true,"done_reason":"stop"}) );
    }
    if ( $stream ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => $ctype );
      $req->respond_chunk_header($head);
      $req->write_chunk($_) for @chunks;
      $req->write_chunk_eof;
      return;
    }
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => $ctype, 'Content-Length' => length $chunks[0] );
    $resp->content( $chunks[0] );
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

# No router, no raw passthrough: every request goes through the handler
# chain to Handler::Passthrough.
my $knarr = Langertha::Knarr->new(
  loop       => $loop,
  listen     => [ '127.0.0.1:0' ],
  auth_token => $KEY,
  handler    => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { openai => $up, anthropic => $up, ollama => $up }, loop => $loop ),
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

# path, client headers, then per forwarded header: the lines the upstream
# must see on the native server, and the one line it sees under PSGI.
my %protocol = (
  openai => {
    path    => '/v1/chat/completions',
    headers => [
      Authorization => "Bearer $KEY",
      'X-Custom'    => 'one',
      Authorization => 'Bearer sk-one',
      'X-Custom'    => 'two',
      Authorization => 'Bearer sk-two',
    ],
    want => {
      authorization => [ [ 'Bearer sk-one', 'Bearer sk-two' ], [ 'Bearer sk-one, Bearer sk-two' ] ],
    },
    done => "data: [DONE]",
  },
  anthropic => {
    path    => '/v1/messages',
    headers => [
      'x-api-key'         => $KEY,
      'anthropic-version' => '2023-06-01',
      'x-api-key'         => 'sk-ant-one',
      'X-Custom'          => 'one',
      'anthropic-version' => '2023-01-01',
      'x-api-key'         => 'sk-ant-two',
    ],
    want => {
      'x-api-key'         => [ [ 'sk-ant-one', 'sk-ant-two' ], [ 'sk-ant-one, sk-ant-two' ] ],
      'anthropic-version' => [ [ '2023-06-01', '2023-01-01' ], [ '2023-06-01, 2023-01-01' ] ],
    },
    done => "event: message_stop",
  },
  ollama => {
    path    => '/api/chat',
    headers => [
      'x-api-key'   => $KEY,
      Authorization => 'Bearer remote-one',
      'X-Custom'    => 'one',
      Authorization => 'Bearer remote-two',
    ],
    want => {
      authorization => [ [ 'Bearer remote-one', 'Bearer remote-two' ], [ 'Bearer remote-one, Bearer remote-two' ] ],
    },
    done => '"done":true',
  },
);

sub send_via {
  my ($transport, $name, $stream) = @_;
  my $p = $protocol{$name};
  my $body = $json->encode({ model => 'm', max_tokens => 16,
    messages => [ { role => 'user', content => 'hi' } ],
    stream   => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false() });
  my @h = ( 'Content-Type' => 'application/json', @{ $p->{headers} } );
  @seen = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port$p->{path}", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$p->{path}", \@h, $body ) );
  return ( $resp, [ @seen ] );
}

sub lines_of {
  my ($lines, $name) = @_;
  return [ map { $_->[1] } grep { $_->[0] eq $name } @$lines ];
}

for my $name ( sort keys %protocol ) {
  my $p = $protocol{$name};
  for my $stream ( 0, 1 ) {
    for my $transport ( 'native', 'psgi' ) {
      my $tag = "$name $transport " . ( $stream ? 'stream' : 'sync' );
      my ($resp, $seen) = send_via( $transport, $name, $stream );
      is( $resp->code, 200, "$tag: answered" ) or diag $resp->content;
      like( $resp->content, qr/\Q$p->{done}\E/, "$tag: the protocol's end marker" ) if $stream;
      is( scalar @$seen, 1, "$tag: reached the upstream once" ) or next;
      is( $seen->[0]{path}, $p->{path}, "$tag: at the protocol's chat path" );
      my $lines = $seen->[0]{headers};
      for my $header ( sort keys %{ $p->{want} } ) {
        my ($native, $psgi) = @{ $p->{want}{$header} };
        is( lines_of( $lines, $header ), $transport eq 'native' ? $native : $psgi,
          $transport eq 'native'
            ? "$tag: each $header line reaches the upstream as its own line, in order"
            : "$tag: the PSGI server's merged $header goes on as one line" );
      }
      is( [ grep { index( $_->[1], $KEY ) >= 0 } @$lines ], [],
        "$tag: the proxy key reaches the upstream in no header" );
      is( lines_of( $lines, 'x-custom' ), [], "$tag: headers the parser does not forward stay behind" );
    }
  }
}

done_testing;
