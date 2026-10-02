use strict;
use warnings;
use Test2::V0;

# Regression: unlike the OpenAI and Anthropic parsers, Protocol::Ollama set
# no forward_headers, so a Handler::Passthrough in the handler chain sent an
# Ollama request to its upstream without the client's Authorization -- an
# authenticated remote Ollama (behind a reverse proxy) answered 401. The raw
# passthrough was not affected (it forwards every header). Now the Ollama
# parser captures Authorization like the others, and Knarr's proxy key is
# taken out of it the same way (never forwarded).

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
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Protocol::Ollama;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

# The parser on its own.
{
  package OllamaFwdReq;
  sub new { my ($class, %h) = @_; bless { %h }, $class }
  sub path { '/api/chat' }
  sub header { $_[0]{ lc $_[1] } }
}
{
  my $body = $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ] });
  my $req = Langertha::Knarr::Protocol::Ollama->new->parse_chat_request(
    OllamaFwdReq->new( authorization => 'Bearer remote-own', 'x-other' => 'no' ), \$body );
  is( $req->extra->{forward_headers}, [ [ authorization => 'Bearer remote-own' ] ],
    'parse_chat_request captures Authorization as forward_headers' );
  is( $req->extra->{path}, '/api/chat', 'the path is still recorded' );
  my $none = Langertha::Knarr::Protocol::Ollama->new->parse_chat_request( undef, \$body );
  is( $none->extra->{forward_headers}, [], 'no request object: no forward_headers' );
}

my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, { path => $req->path, headers => [ map { [ lc $_->[0], $_->[1] ] } $req->headers ] };
    my $generate = $req->path eq '/api/generate';
    my $body = $json->encode({ model => 'm', done => JSON::MaybeXS::true(), done_reason => 'stop',
      $generate ? ( response => 'ok' ) : ( message => { role => 'assistant', content => 'ok' } ) }) . "\n";
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => ( $req->body =~ /"stream":true/ ? 'application/x-ndjson' : 'application/json' ),
      'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my $KEY = 'knarr-proxy-secret';

my %setup;
for my $auth ( 'keyed', 'open' ) {
  my $knarr = Langertha::Knarr->new(
    loop    => $loop,
    listen  => [ '127.0.0.1:0' ],
    handler => Langertha::Knarr::Handler::Passthrough->new( upstreams => { ollama => $up }, loop => $loop ),
    ( $auth eq 'keyed' ? ( auth_token => $KEY ) : () ),
  );
  $knarr->start;
  $setup{$auth} = {
    port => $knarr->_server->read_handle->sockport,
    psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

sub send_via {
  my ($transport, $auth, $path, $stream, @headers) = @_;
  my $body = $json->encode({ model => 'm', stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
    $path eq '/api/generate' ? ( prompt => 'hi' ) : ( messages => [ { role => 'user', content => 'hi' } ] ) });
  my @h = ( 'Content-Type' => 'application/json', @headers );
  my $s = $setup{$auth};
  @seen = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$s->{port}$path", \@h, $body ) )->get
    : $s->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $body ) );
  return ( $resp, [ @seen ] );
}

sub seen_header {
  my ($lines, $name) = @_;
  my @v = map { $_->[1] } grep { $_->[0] eq $name } @$lines;
  return @v ? join( ', ', @v ) : undef;
}

# label, auth, client headers, Authorization the upstream must see
my @cases = (
  [ 'open proxy, own Bearer', 'open', [ Authorization => 'Bearer remote-own' ], 'Bearer remote-own' ],
  [ 'proxy key in x-api-key, own Bearer', 'keyed',
    [ 'x-api-key' => $KEY, Authorization => 'Bearer remote-own' ], 'Bearer remote-own' ],
  [ 'only the proxy key, as Bearer', 'keyed', [ Authorization => "Bearer $KEY" ], undef ],
  [ 'proxy key and own key, Authorization twice', 'keyed',
    [ Authorization => "Bearer $KEY", Authorization => 'Bearer remote-own' ], 'Bearer remote-own' ],
);

for my $transport ( 'native', 'psgi' ) {
  for my $path ( '/api/chat', '/api/generate' ) {
    for my $stream ( 0, 1 ) {
      for my $case (@cases) {
        my ($label, $auth, $client, $want) = @$case;
        my $tag = "$transport $path" . ( $stream ? ' stream' : '' ) . ": $label";
        my ($resp, $seen) = send_via( $transport, $auth, $path, $stream, @$client );
        is( $resp->code, 200, "$tag: answered" );
        is( scalar @$seen, 1, "$tag: reached the Ollama upstream once" ) or next;
        is( $seen->[0]{path}, $path, "$tag: at the client's path" );
        is( seen_header( $seen->[0]{headers}, 'authorization' ), $want,
          "$tag: " . ( defined $want ? 'Authorization forwarded' : 'no Authorization forwarded' ) );
        is( [ grep { index( $_->[1], $KEY ) >= 0 } @{ $seen->[0]{headers} } ], [],
          "$tag: the proxy key reaches the upstream in no header" );
      }
    }
  }
}

done_testing;
