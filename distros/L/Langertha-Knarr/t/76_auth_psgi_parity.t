use strict;
use warnings;
use Test2::V0;

# Security regression (k25): under Plack, Langertha::Knarr::PSGI skipped
# Knarr::_check_auth entirely, so a Knarr with auth_token (proxy_api_key)
# set served chat, /v1/models and /.well-known/langertha.json to anyone.
# The auth decision must be identical on the native server and PSGI for
# every route: same header sources (Authorization Bearer, x-api-key), same
# anonymous exemption (A2A agent card), same 401 status/content type/body.
# One table drives both transports so they cannot drift apart again, and
# a streaming request must be rejected before the handler's stream starts.

BEGIN {
  eval { require Plack::Test; require HTTP::Request::Common; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;

my $json   = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $secret = 'sk-parity-secret';

my %handler_calls;
my $handler = Langertha::Knarr::Handler::Code->new(
  code        => sub { $handler_calls{chat}++;   'parity-ok' },
  stream_code => sub { $handler_calls{stream}++; my @p = ('x'); sub { @p ? shift @p : undef } },
);

my $msgs = [ { role => 'user', content => 'hi' } ];
my %chat_body = (
  '/v1/chat/completions' => { model => 'm', messages => $msgs },
  '/v1/messages'         => { model => 'm', max_tokens => 10, messages => $msgs },
  '/api/chat'            => { model => 'm', messages => $msgs, stream => JSON::MaybeXS::false() },
  '/api/generate'        => { model => 'm', prompt => 'hi', stream => JSON::MaybeXS::false() },
  '/'                    => { jsonrpc => '2.0', id => 1, method => 'tasks/send',
    params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } } },
  '/runs'                => { agent_name => 'm', mode => 'sync',
    input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ] },
  '/awp'                 => { threadId => 'th1', runId => 'r1', messages => $msgs },
  '/api/show'            => { model => 'knarr-code' },   # not a chat route (k29)
);
my %stream_body = (
  '/v1/chat/completions' => { model => 'm', messages => $msgs, stream => JSON::MaybeXS::true() },
  '/v1/messages'         => { model => 'm', max_tokens => 10, messages => $msgs, stream => JSON::MaybeXS::true() },
  '/api/chat'            => { model => 'm', messages => $msgs },
  '/'                    => { jsonrpc => '2.0', id => 1, method => 'tasks/sendSubscribe',
    params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } } },
  '/runs'                => { agent_name => 'm', mode => 'stream',
    input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ] },
);

my %credentials = (
  none          => [],
  wrong_bearer  => [ Authorization => 'Bearer wrong' ],
  wrong_api_key => [ 'x-api-key'   => 'wrong' ],
  bare_secret   => [ Authorization => $secret ],   # no "Bearer" scheme
  bearer        => [ Authorization => "Bearer $secret" ],
  bearer_lc     => [ Authorization => "bearer $secret" ],
  api_key       => [ 'x-api-key'   => $secret ],
);
my %credential_ok = map { $_ => 1 } qw( bearer bearer_lc api_key );
my %anonymous_action = ( a2a_card => 1 );

my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %setup;
for my $auth ( 'configured', 'open' ) {
  my $knarr = Langertha::Knarr->new(
    handler => $handler,
    loop    => $loop,
    listen  => [ '127.0.0.1:0' ],
    ( $auth eq 'configured' ? ( auth_token => $secret ) : () ),
  );
  $knarr->start;
  $setup{$auth} = {
    knarr => $knarr,
    port  => $knarr->_server->read_handle->sockport,
    psgi  => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

sub run_both {
  my ($auth, $method, $path, $body, $headers) = @_;
  my $s = $setup{$auth};
  my @h = ( @$headers, ( defined $body ? ( 'Content-Type' => 'application/json' ) : () ) );
  my $content = defined $body ? $json->encode($body) : undef;

  my $nreq = HTTP::Request->new( $method => "http://127.0.0.1:$s->{port}$path", \@h, $content );
  my $native = $http->do_request( request => $nreq )->get;

  my $preq = HTTP::Request->new( $method => "http://localhost$path", \@h, $content );
  my $psgi = $s->{psgi}->request($preq);
  return ( $native, $psgi );
}

my @routes = @{ $setup{configured}{knarr}->_routes };
ok( scalar(@routes) >= 12, 'route table enumerated' );
my %actions_seen;

for my $route (@routes) {
  my ($method, $path, $action) = @{$route}{qw( method path action )};
  $actions_seen{$action}++;
  my @variants = ( [ 'plain', $method eq 'POST' ? $chat_body{$path} : undef ] );
  push @variants, [ 'stream', $stream_body{$path} ] if $action eq 'chat' && $stream_body{$path};

  for my $variant (@variants) {
    my ($kind, $body) = @$variant;
    if ( $method eq 'POST' && !$body ) {
      fail("no request body in the table for POST $path");
      next;
    }
    for my $auth ( 'configured', 'open' ) {
      for my $cred ( sort keys %credentials ) {
        my $cell = "$method $path ($kind) auth=$auth cred=$cred";
        %handler_calls = ();
        my ($native, $psgi) = run_both( $auth, $method, $path, $body, $credentials{$cred} );

        my $must_reject = $auth eq 'configured'
          && !$credential_ok{$cred} && !$anonymous_action{$action};

        is( $psgi->code, $native->code, "$cell: PSGI status matches native" );
        if ($must_reject) {
          is( $native->code, 401, "$cell: native rejects" );
          is( $psgi->code,   401, "$cell: PSGI rejects" );
          is( $psgi->header('Content-Type'), $native->header('Content-Type'),
            "$cell: same 401 content type" );
          is( $psgi->decoded_content, $native->decoded_content, "$cell: same 401 body" );
          is( eval { $json->decode( $psgi->decoded_content ) }, { error => { message => 'unauthorized' } },
            "$cell: 401 body shape" );
          is( \%handler_calls, {}, "$cell: handler never reached (no stream started)" );
        }
        else {
          isnt( $native->code, 401, "$cell: native lets it through" );
          isnt( $psgi->code,   401, "$cell: PSGI lets it through" );
        }
      }
    }
  }
}

# The table must actually cover every kind of route Knarr serves.
for my $action (qw( chat models acp_agents a2a_card manifest version show )) {
  ok( $actions_seen{$action}, "matrix covers action $action" );
}

done_testing;
