use strict;
use warnings;
use Test2::V0;

# Regression (k44): with a proxy key set (auth_token / proxy_api_key /
# KNARR_API_KEY), the passthrough forwarded every client header to the
# upstream -- the one carrying Knarr's own key included, so the proxy
# secret reached api.openai.com / api.anthropic.com. The header Knarr
# accepted the key from is Knarr's and is dropped; the client's own provider
# key travels in the other header and still reaches the upstream, as does
# every other header. Checked for the raw passthrough and for
# Handler::Passthrough in the handler chain, on the native server and under
# PSGI.

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
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;

{
  package KeyRouter;   # every model is a passthrough model
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my %canned = (
  '/v1/chat/completions' => qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"ok","role":"assistant"}}]}),
  '/v1/messages'         => qq({"content":[{"text":"ok","type":"text"}],"stop_reason":"end_turn"}),
);

my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my %h = map { lc( $_->[0] ) => $_->[1] } $req->headers;
    push @seen, { path => $req->path, headers => \%h };
    my $body = $canned{ $req->path } // '{}';
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my $PROXY_KEY = 'knarr-proxy-secret';

sub passthrough { Langertha::Knarr::Handler::Passthrough->new(
  upstreams => { openai => $up, anthropic => $up }, loop => $loop ) }

# raw: the raw passthrough seam; chain: Handler::Passthrough behind the
# handler chain (no raw passthrough).
my %setup;
for my $path_kind ( 'raw', 'chain' ) {
  for my $auth ( 'keyed', 'open' ) {
    my $knarr = Langertha::Knarr->new(
      loop   => $loop,
      listen => [ '127.0.0.1:0' ],
      ( $auth eq 'keyed' ? ( auth_token => $PROXY_KEY ) : () ),
      $path_kind eq 'raw'
        ? ( handler => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
            router  => KeyRouter->new, raw_passthrough => passthrough() )
        : ( handler => passthrough() ),
    );
    $knarr->start;
    $setup{"$path_kind/$auth"} = {
      port => $knarr->_server->read_handle->sockport,
      psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
    };
  }
}

my $msgs = [ { role => 'user', content => 'hi' } ];
my %body = (
  '/v1/chat/completions' => $json->encode({ model => 'gpt-x', messages => $msgs }),
  '/v1/messages'         => $json->encode({ model => 'claude-x', max_tokens => 5, messages => $msgs }),
);

sub send_via {
  my ($transport, $s, $path, @headers) = @_;
  my @h = ( 'Content-Type' => 'application/json', 'anthropic-version' => '2023-06-01',
    'X-Custom' => 'kept', @headers );
  @seen = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$s->{port}$path", \@h, $body{$path} ) )->get
    : $s->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $body{$path} ) );
  return ( $resp, [ @seen ] );
}

# label, path, client headers, upstream must see, upstream must not see
my @cases = (
  [ 'OpenAI, proxy key in x-api-key, own key as Bearer', '/v1/chat/completions',
    [ 'x-api-key' => $PROXY_KEY, Authorization => 'Bearer sk-openai-own' ],
    { authorization => 'Bearer sk-openai-own' }, [ 'x-api-key' ] ],
  [ 'Anthropic, proxy key as Bearer, own key in x-api-key', '/v1/messages',
    [ Authorization => "Bearer $PROXY_KEY", 'x-api-key' => 'sk-ant-own' ],
    { 'x-api-key' => 'sk-ant-own' }, [ 'authorization' ] ],
  [ 'Anthropic, proxy key in x-api-key, own OAuth token as Bearer', '/v1/messages',
    [ 'x-api-key' => $PROXY_KEY, Authorization => 'Bearer oauth-own' ],
    { authorization => 'Bearer oauth-own' }, [ 'x-api-key' ] ],
  [ 'OpenAI, lower-case bearer scheme', '/v1/chat/completions',
    [ Authorization => "bearer $PROXY_KEY" ],
    {}, [ 'authorization' ] ],
);

for my $path_kind ( 'raw', 'chain' ) {
  for my $transport ( 'native', 'psgi' ) {
    my $s = $setup{"$path_kind/keyed"};
    for my $case (@cases) {
      my ($label, $path, $client, $want, $gone) = @$case;
      my $tag = "$path_kind/$transport: $label";
      my ($resp, $seen) = send_via( $transport, $s, $path, @$client );
      is( $resp->code, 200, "$tag: accepted" );
      is( scalar @$seen, 1, "$tag: reached the upstream once" ) or next;
      my $h = $seen->[0]{headers};
      is( $h->{$_}, $want->{$_}, "$tag: $_ forwarded" ) for sort keys %$want;
      ok( !exists $h->{$_}, "$tag: $_ (proxy key) not forwarded" ) for @$gone;
      ok( !grep( { index( $_, $PROXY_KEY ) >= 0 } values %$h ),
        "$tag: the proxy key reaches the upstream in no header" );
      is( $h->{'anthropic-version'}, '2023-06-01', "$tag: anthropic-version still forwarded" )
        if $path eq '/v1/messages';
      is( $h->{'x-custom'}, 'kept', "$tag: other headers untouched" ) if $path_kind eq 'raw';
    }

    # Without a proxy key nothing is Knarr's: both headers go through.
    my ($resp, $seen) = send_via( $transport, $setup{"$path_kind/open"}, '/v1/messages',
      Authorization => 'Bearer tok-a', 'x-api-key' => 'tok-b' );
    is( $resp->code, 200, "$path_kind/$transport open: accepted" );
    is( $seen->[0]{headers}{authorization}, 'Bearer tok-a', "$path_kind/$transport open: Authorization forwarded" );
    is( $seen->[0]{headers}{'x-api-key'}, 'tok-b', "$path_kind/$transport open: x-api-key forwarded" );
  }
}

done_testing;
