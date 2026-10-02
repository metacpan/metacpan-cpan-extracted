use strict;
use warnings;
use Test2::V0;

# Regression: the proxy key was dropped only from a header whose whole value
# was the key. A client that sends Authorization twice (or x-api-key twice)
# gets them merged into one value joined with ', ' -- by the PSGI server
# (one HTTP_AUTHORIZATION) and by the protocol parsers (scalar ->header) --
# and 'Bearer <proxy key>, Bearer sk-own' went to the upstream, on the PSGI
# raw passthrough and on Handler::Passthrough in the handler chain (native
# and PSGI). Now every comma-separated element that carries the key is
# removed from Authorization and x-api-key, whatever path the request takes;
# the client's own key next to it still reaches the upstream.

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
  package MergedKeyRouter;   # every model is a passthrough model
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my %canned = (
  '/v1/chat/completions' => qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"ok","role":"assistant"}}]}),
  '/v1/messages'         => qq({"content":[{"text":"ok","type":"text"}],"stop_reason":"end_turn"}),
);

# Every header line the upstream got, duplicates kept.
my @seen;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @seen, [ map { [ lc $_->[0], $_->[1] ] } $req->headers ];
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

my $KEY = 'PROXYSECRET';

sub passthrough { Langertha::Knarr::Handler::Passthrough->new(
  upstreams => { openai => $up, anthropic => $up }, loop => $loop ) }

my %setup;
for my $path_kind ( 'raw', 'chain' ) {
  my $knarr = Langertha::Knarr->new(
    loop       => $loop,
    listen     => [ '127.0.0.1:0' ],
    auth_token => $KEY,
    $path_kind eq 'raw'
      ? ( handler => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
          router  => MergedKeyRouter->new, raw_passthrough => passthrough() )
      : ( handler => passthrough() ),
  );
  $knarr->start;
  $setup{$path_kind} = {
    port => $knarr->_server->read_handle->sockport,
    psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

my $msgs = [ { role => 'user', content => 'hi' } ];
my %body = (
  '/v1/chat/completions' => $json->encode({ model => 'gpt-x', messages => $msgs }),
  '/v1/messages'         => $json->encode({ model => 'claude-x', max_tokens => 5, messages => $msgs }),
);

sub send_via {
  my ($transport, $s, $path, @headers) = @_;
  my @h = ( 'Content-Type' => 'application/json', 'anthropic-version' => '2023-06-01', @headers );
  @seen = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$s->{port}$path", \@h, $body{$path} ) )->get
    : $s->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $body{$path} ) );
  return ( $resp, [ @seen ] );
}

# One header's value as the upstream saw it: its lines joined like HTTP does.
sub seen_header {
  my ($lines, $name) = @_;
  my @v = map { $_->[1] } grep { $_->[0] eq $name } @$lines;
  return @v ? join( ', ', @v ) : undef;
}

# label, path, client headers, the auth headers the upstream must see
# (undef: must not see it at all)
my @cases = (
  [ 'OpenAI, Authorization twice (proxy key, own key), key also in x-api-key', '/v1/chat/completions',
    [ 'x-api-key' => $KEY, Authorization => "Bearer $KEY", Authorization => 'Bearer sk-own' ],
    { authorization => 'Bearer sk-own', 'x-api-key' => undef } ],
  [ 'OpenAI, own key first, proxy key second in Authorization', '/v1/chat/completions',
    [ Authorization => 'Bearer sk-own', Authorization => "Bearer $KEY" ],
    { authorization => 'Bearer sk-own', 'x-api-key' => undef } ],
  [ 'OpenAI, one Authorization value already merged', '/v1/chat/completions',
    [ Authorization => "Bearer $KEY, Bearer sk-own" ],
    { authorization => 'Bearer sk-own', 'x-api-key' => undef } ],
  [ 'OpenAI, only the proxy key, twice', '/v1/chat/completions',
    [ Authorization => "Bearer $KEY", Authorization => "bearer $KEY" ],
    { authorization => undef, 'x-api-key' => undef } ],
  [ 'Anthropic, x-api-key twice (proxy key, own key)', '/v1/messages',
    [ 'x-api-key' => $KEY, 'x-api-key' => 'sk-ant-own' ],
    { 'x-api-key' => 'sk-ant-own', authorization => undef } ],
  [ 'Anthropic, one x-api-key value already merged, own key first', '/v1/messages',
    [ 'x-api-key' => "sk-ant-own, $KEY" ],
    { 'x-api-key' => 'sk-ant-own', authorization => undef } ],
  [ 'Anthropic, proxy key as Bearer twice, own key in x-api-key', '/v1/messages',
    [ Authorization => "Bearer $KEY", Authorization => "Bearer $KEY", 'x-api-key' => 'sk-ant-own' ],
    { 'x-api-key' => 'sk-ant-own', authorization => undef } ],
);

for my $path_kind ( 'raw', 'chain' ) {
  for my $transport ( 'native', 'psgi' ) {
    for my $case (@cases) {
      my ($label, $path, $client, $want) = @$case;
      my $tag = "$path_kind/$transport: $label";
      my ($resp, $seen) = send_via( $transport, $setup{$path_kind}, $path, @$client );
      is( $resp->code, 200, "$tag: accepted" );
      is( scalar @$seen, 1, "$tag: reached the upstream once" ) or next;
      my $lines = $seen->[0];
      is( seen_header( $lines, $_ ), $want->{$_},
        "$tag: $_ " . ( defined $want->{$_} ? "is the client's own key" : 'not forwarded' ) )
        for sort keys %$want;
      is( [ grep { index( $_->[1], $KEY ) >= 0 } @$lines ], [],
        "$tag: the proxy key reaches the upstream in no header" );
      is( seen_header( $lines, 'anthropic-version' ), '2023-06-01', "$tag: other headers kept" )
        if $path eq '/v1/messages';
    }

    # The proxy key is still required: a merged value without it is refused.
    my ($resp, $seen) = send_via( $transport, $setup{$path_kind}, '/v1/chat/completions',
      Authorization => 'Bearer sk-own', Authorization => 'Bearer sk-other' );
    is( $resp->code, 401, "$path_kind/$transport: without the proxy key: 401" );
    is( scalar @$seen, 0, "$path_kind/$transport: without the proxy key: nothing forwarded" );
  }
}

done_testing;
