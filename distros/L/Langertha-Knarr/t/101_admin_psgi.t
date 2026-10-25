use strict;
use warnings;
use Test2::V0;

# k75 under Plack: the admin routes, their key, the not-configured 503 and the
# limits work through Langertha::Knarr::PSGI as on the native server; the
# body is read only after the key and the Content-Length passed, and a
# prefork PSGI server (psgi.multiprocess) gets 501 instead of a push that
# would reach one process.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG )} }

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}

BEGIN {
  package LangerthaX::Engine::TestKnarrAdminPSGI;
  use Future;
  use Langertha::Response;
  our @chats;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub chat_model { $_[0]{model} }
  sub chat_f {
    my ($self) = @_;
    push @chats, { model => $self->{model}, api_key => $self->{api_key} };
    return Future->done( Langertha::Response->new( content => 'from '.$self->{model}, raw => {} ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrAdminPSGI.pm'} = __FILE__;
}

use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Admin;
use Langertha::Knarr::Config;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Stack;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $ADMIN_KEY = 'admin-key-psgi-0123456789';
my $PROXY_KEY = 'proxy-key-psgi-0001';
my $KEY_ONE   = 'sk-psgi-one-AAAAAAAAAA';
my $KEY_TWO   = 'sk-psgi-two-BBBBBBBBBB';
my @SECRETS = ( $ADMIN_KEY, $KEY_ONE, $KEY_TWO );

sub app_for {
  my (%opt) = @_;
  my $config = Langertha::Knarr::Config->new( data => $opt{data} // {} );
  my $stack = Langertha::Knarr::Stack->new( config => $config, loop => $loop );
  my $knarr = Langertha::Knarr->new(
    loop    => $loop,
    handler => $stack->handler,
    router  => $stack->router,
    ( defined $stack->auth_token ? ( auth_token => $stack->auth_token ) : () ),
    ( $opt{no_admin} ? () : ( admin => Langertha::Knarr::Admin->new(
      key => $ADMIN_KEY, stack => $stack, remote_config => $opt{remote_config} // 0 ) ) ),
  );
  my $psgi = Langertha::Knarr::PSGI->new( knarr => $knarr );
  return ( $knarr, $psgi );
}

sub send_req {
  my ( $app, $method, $path, %opt ) = @_;
  my $req = HTTP::Request->new( $method => "http://localhost$path" );
  $req->header( Authorization => "Bearer $opt{bearer}" ) if defined $opt{bearer};
  if ( defined $opt{body} ) {
    my $body = ref $opt{body} ? $json->encode( $opt{body} ) : $opt{body};
    $req->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $req->content($body);
  }
  my $res;
  test_psgi( $app, sub { $res = $_[0]->($req) } );
  return $res;
}

sub chat {
  my ( $app, $model, %opt ) = @_;
  return send_req( $app, POST => '/v1/chat/completions', %opt,
    body => { model => $model, messages => [ { role => 'user', content => 'hi' } ] } );
}

sub decode { my $d = eval { $json->decode( $_[0]->decoded_content ) }; $d }

sub no_secret_in {
  my ( $text, $what ) = @_;
  my @found = grep { index( $text, $_ ) >= 0 } @SECRETS;
  ok( !@found, "$what carries no key" ) or diag "found: @found";
}

my %start = (
  proxy_api_key => $PROXY_KEY,
  models => { alpha => { engine => 'TestKnarrAdminPSGI', model => 'alpha-up', api_key => $KEY_ONE } },
);

{
  my ( undef, $psgi ) = app_for( data => { %start }, no_admin => 1 );
  is( send_req( $psgi->to_app, GET => '/knarr/admin/status', bearer => $ADMIN_KEY )->code, 404,
    'PSGI without an admin: the route does not exist' );
}

my ( $knarr, $psgi ) = app_for( data => { %start } );
my $app = $psgi->to_app;

is( send_req( $app, GET => '/knarr/admin/status' )->code, 401, 'PSGI status without a key: 401' );
is( send_req( $app, GET => '/knarr/admin/status', bearer => $PROXY_KEY )->code, 401, '... with the proxy key: 401' );
%{ $knarr->admin->_failures } = ();
{
  my $res = send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN_KEY );
  is( $res->code, 200, '... with the admin key: 200' );
  is( scalar $res->header('Cache-Control'), 'no-store', '... not cached' );
  is( decode($res)->{models}, [ 'alpha' ], '... naming the models' );
}
is( chat( $app, 'alpha', bearer => $ADMIN_KEY )->code, 401, 'PSGI: the admin key on chat is 401' );
is( decode( chat( $app, 'alpha', bearer => $PROXY_KEY ) )->{choices}[0]{message}{content}, 'from alpha-up',
  'PSGI: the start setup serves' );

{
  my $res = send_req( $app, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => qq({"models":{"x":{"engine":"TestKnarrAdminPSGI","api_key":"$KEY_TWO"}}) );
  is( $res->code, 400, 'PSGI PUT broken JSON: 400' );
  is( decode($res)->{error}{message}, 'the request body is not valid JSON', '... without an excerpt' );
  no_secret_in( $res->decoded_content, '... the answer' );
}

{
  my $res = send_req( $app, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { beta => { engine => 'TestKnarrAdminPSGI', model => 'beta-up', api_key => $KEY_TWO } } } );
  is( $res->code, 200, 'PSGI PUT: 200' );
  is( decode($res)->{generation}, 1, '... generation 1' );
  no_secret_in( $res->decoded_content, '... the answer' );
  is( chat( $app, 'beta' )->code, 401, 'PSGI: the start layer proxy key still applies' );
  is( decode( chat( $app, 'beta', bearer => $PROXY_KEY ) )->{choices}[0]{message}{content}, 'from beta-up',
    'PSGI: the pushed setup serves, next to the start model' );

  $res = send_req( $app, PATCH => '/knarr/admin/keys', bearer => $ADMIN_KEY, body => { beta => $KEY_ONE } );
  is( $res->code, 200, 'PSGI PATCH keys: 200' );
  chat( $app, 'beta', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdminPSGI::chats[-1]{api_key}, $KEY_ONE, '... beta uses the new key' );

  $res = send_req( $app, DELETE => '/knarr/admin/config', bearer => $ADMIN_KEY );
  is( [ @{ decode($res) }{qw( generation layers )} ], [ 3, ['env'] ], 'PSGI DELETE: back to the start setup' );
  is( chat( $app, 'beta', bearer => $PROXY_KEY )->code, 404, '... beta is gone' );
}

# --- The body is read only after the key and within the limit ---
{
  package CountingInput;
  sub new { bless { reads => 0 }, shift }
  sub read { $_[0]{reads}++; return 0 }
}
{
  for my $case (
    [ 'without the key', undef, 100, 401 ],
    [ 'over max_body', $ADMIN_KEY, $knarr->admin->max_body + 1, 413 ],
  ) {
    my ( $what, $bearer, $length, $code ) = @$case;
    my $input = CountingInput->new;
    my $res = $psgi->_handle_psgi({
      REQUEST_METHOD => 'PUT',
      PATH_INFO      => '/knarr/admin/config',
      CONTENT_LENGTH => $length,
      REMOTE_ADDR    => '10.9.8.7',
      'psgi.input'   => $input,
      ( defined $bearer ? ( HTTP_AUTHORIZATION => "Bearer $bearer" ) : () ),
    });
    is( $res->[0], $code, "PSGI PUT $what: $code" );
    is( $input->{reads}, 0, '... and the body was not read' );
  }
}

# --- A prefork PSGI server gets no admin push ---
{
  my $prefork = sub { my ($env) = @_; $env->{'psgi.multiprocess'} = 1; $app->($env) };
  my $res = send_req( $prefork, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { gamma => { engine => 'TestKnarrAdminPSGI', api_key => $KEY_TWO } } } );
  is( $res->code, 501, 'psgi.multiprocess: the admin routes answer 501' );
  like( decode($res)->{error}{message}, qr/single-process server/, '... saying why' );
  is( decode( send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) )->{models}, [ 'alpha' ],
    '... and nothing changed' );
}

# --- Wrong keys lock the address out ---
{
  my $now = 2_000_000;
  no warnings 'redefine';
  local *Langertha::Knarr::Admin::_now = sub { $now };
  send_req( $app, GET => '/knarr/admin/status', bearer => 'wrong' ) for 1 .. 3;
  my $res = send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN_KEY );
  is( [ $res->code, scalar $res->header('Retry-After') ], [ 429, 1 ], 'PSGI: locked out after three wrong keys' );
  $now += 1;
  is( send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN_KEY )->code, 200, '... until the wait is over' );
}

# --- remote_config without a start setup ---
{
  my ( undef, $ram ) = app_for( data => {}, remote_config => 1 );
  my $rapp = $ram->to_app;
  my $res = chat( $rapp, 'beta' );
  is( $res->code, 503, 'PSGI remote_config, no setup: 503' );
  like( decode($res)->{error}{message}, qr/not configured/, '... not configured' );
  is( send_req( $rapp, GET => '/api/tags' )->code, 503, '... Ollama model list too' );
  is( send_req( $rapp, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { beta => { engine => 'TestKnarrAdminPSGI', model => 'beta-up', api_key => $KEY_TWO } } } )->code,
    200, 'the first push' );
  is( decode( chat( $rapp, 'beta' ) )->{choices}[0]{message}{content}, 'from beta-up', 'then it serves' );
}

done_testing;
