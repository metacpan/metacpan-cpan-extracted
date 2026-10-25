use strict;
use warnings;
use Test2::V0;

# k82: how token_auth is wired. The Stack builds the Token authorizer over a
# token store and the TokenRoutes handler (no raw passthrough), loading the
# store's driver but never connecting; with_config keeps the same authorizer
# and store; Knarr takes the authorizer from the stack. The admin route
# cannot open a hole: token_auth / routes are not pushable, a push of models,
# default, passthrough, auto_discover or proxy_api_key onto a token_auth start
# fails (400, nothing changed), a push of other settings keeps the token
# check; the status says on / backend / connected and nothing of the DSN,
# user, password, relation or a token. Offline: a Memory store is injected.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_URL LANGFUSE_BASE_URL )} }

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
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
use Langertha::Knarr::TokenStore::Memory;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $ADMIN = 'admin-key-wiring-0123456789';
my $TOKEN = 'tok-wiring-0123456789';
my $DSN   = 'dbi:Pg:host=secret-db.internal;dbname=secret_platform';
my $USER  = 'secret_db_user';
my $REL   = 'secret_relation_view';
my $CHAN  = 'secret_listen_channel';
my @SECRETS = ( $ADMIN, $TOKEN, $DSN, 'secret-db.internal', $USER, $REL, $CHAN, 'SECRET_PW_ENV' );

sub token_auth {
  return {
    backend => 'postgresql', dsn => $DSN, user => $USER, password_env => 'SECRET_PW_ENV',
    relation => $REL, listen => $CHAN, @_,
  };
}

sub start_data {
  return (
    token_auth => token_auth(),
    routes     => { local => { upstream => 'http://127.0.0.1:1/v1', key_env => 'WIRING_KEY' } },
    @_,
  );
}

sub config_of { Langertha::Knarr::Config->new( data => { start_data(@_) } ) }

# --- the stack without token_auth is as before
{
  my $stack = Langertha::Knarr::Stack->new(
    config => Langertha::Knarr::Config->new( data => { models => { m => { engine => 'OpenAI', api_key => 'k' } } } ),
    loop   => $loop,
  )->build;
  is( $stack->authorizer, undef, 'no token_auth: no authorizer' );
  is( $stack->token_store, undef, '... no token store' );
  isa_ok( $stack->handler, ['Langertha::Knarr::Handler::Router'], '... the router handler' );
  ok( !$stack->handler->isa('Langertha::Knarr::Handler::TokenRoutes'), '... not TokenRoutes' );
}

# --- the stack with token_auth, store injected
my $store = Langertha::Knarr::TokenStore::Memory->new;
$store->add( token => $TOKEN, model => 'm-one', provider => 'local', expires => time + 900 );
{
  my $stack = Langertha::Knarr::Stack->new( config => config_of(), loop => $loop, token_store => $store )->build;
  isa_ok( $stack->authorizer, ['Langertha::Knarr::Authorizer::Token'], 'token_auth: the Token authorizer' );
  ref_is( $stack->authorizer->store, $store, '... over the given store' );
  ok( $stack->authorizer->match_model, '... match_model defaults to true' );
  isa_ok( $stack->handler, ['Langertha::Knarr::Handler::TokenRoutes'], '... TokenRoutes as handler' );
  is( $stack->handler->routes, config_of()->routes, '... over the routes' );
  is( $stack->raw_passthrough, undef, '... no raw passthrough' );
  is( $stack->auth_token, undef, '... no proxy key' );
  ok( $stack->handler->router, '... the stack\'s router builds its engines' );
  ref_is( $stack->handler->router, $stack->router, '... the same router (timeouts, Langfuse keys)' );

  my $c = config_of( token_auth => token_auth( match_model => JSON::MaybeXS->false ) );
  ok( !Langertha::Knarr::Stack->new( config => $c, token_store => $store )->authorizer->match_model,
    'match_model false reaches the authorizer' );

  # with_config
  my $same = $stack->with_config( config_of( upstream_timeout => 7 ) );
  ref_is( $same->authorizer, $stack->authorizer, 'with_config, same token_auth: the same authorizer' );
  ref_is( $same->token_store, $store, '... and the same store' );
  isa_ok( $same->handler, ['Langertha::Knarr::Handler::TokenRoutes'], '... a TokenRoutes handler again' );
  ok( $same->handler != $stack->handler, '... a new handler' );
  is( $same->config->upstream_timeout, 7, '... for the new config' );
  my $other = $stack->with_config( config_of( token_auth => token_auth( relation => 'another' ) ) );
  ok( $other->authorizer != $stack->authorizer, 'with_config, another token_auth section: a new authorizer' );
  my $none = $stack->with_config(
    Langertha::Knarr::Config->new( data => { models => { m => { engine => 'OpenAI', api_key => 'k' } } } ) );
  is( $none->authorizer, undef, 'with_config without token_auth: none' );
}

# --- the default store: the driver is loaded, nothing connects
SKIP: {
  skip 'DBD::Pg not installed', 6 unless eval { require DBD::Pg; 1 };
  my $stack = Langertha::Knarr::Stack->new( config => config_of(), loop => $loop )->build;
  my $pg = $stack->token_store;
  isa_ok( $pg, ['Langertha::Knarr::TokenStore::Pg'], 'by default the PostgreSQL store' );
  is( $pg->dsn, $DSN, '... over the config\'s DSN' );
  is( $pg->password_env, 'SECRET_PW_ENV', '... and password_env' );
  ok( !$pg->available, 'building the stack did not connect' );
  is( $pg->_dbh, undef, '... no handle' );
  is( $pg->_pid, 0, '... not owned by this (the parent) process' );
}

# --- a missing DBD::Pg stops the build with a clear text
{
  local %INC = %INC;
  delete @INC{qw( DBI.pm DBD/Pg.pm )};
  local @INC = ( sub { return unless $_[1] =~ m{\A(?:DBI|DBD/Pg)\.pm\z}; die "hidden for the test\n" }, @INC );
  my $stack = Langertha::Knarr::Stack->new( config => config_of(), loop => $loop );
  my $ok = eval { $stack->build; 1 };
  ok( !$ok, 'DBD::Pg missing: build fails' );
  like( $@, qr/token_auth backend postgresql needs DBD::Pg/, '... saying what is missing' );
  for my $secret ( $DSN, $USER, $REL ) {
    unlike( $@, qr/\Q$secret\E/, '... without a configuration value' );
  }
}

# --- Knarr and the admin route
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
sub decode { my $d = eval { $json->decode( $_[0]->decoded_content ) }; $d }
sub no_secret_in {
  my ( $text, $what ) = @_;
  my @found = grep { index( $text, $_ ) >= 0 } @SECRETS;
  ok( !@found, "$what carries no secret" ) or diag "found: @found";
}

my $stack = Langertha::Knarr::Stack->new( config => config_of(), loop => $loop, token_store => $store );
my $admin = Langertha::Knarr::Admin->new( key => $ADMIN, stack => $stack );
my $knarr = Langertha::Knarr->new(
  loop    => $loop,
  handler => $stack->handler,
  router  => $stack->router,
  admin   => $admin,
  authorizer => $stack->authorizer,
);
my $authorizer = $knarr->authorizer;
ref_is( $authorizer, $stack->authorizer, 'Knarr takes the stack\'s authorizer' );
my $app = Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app;

is( send_req( $app, GET => '/v1/models' )->code, 401, 'no token: 401' );
{
  my $res = send_req( $app, GET => '/v1/models', bearer => $TOKEN );
  is( $res->code, 200, 'the token: 200' );
  is( [ map { $_->{id} } @{ decode($res)->{data} } ], ['m-one'], '... the model lists show the token\'s model' );
}
is( send_req( $app, GET => '/v1/models', bearer => $ADMIN )->code, 401, 'the admin key on a proxy route: 401' );

# status
{
  my $res = send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN );
  is( $res->code, 200, 'status: 200' );
  my $s = decode($res);
  is( $s->{token_auth}, { backend => 'postgresql', connected => JSON::MaybeXS->true },
    'status: token_auth on, backend, connected (the injected store is available)' );
  is( $s->{models}, [], '... no models' );
  no_secret_in( $res->decoded_content, 'the status' );
  $store->disconnect;
  is( decode( send_req( $app, GET => '/knarr/admin/status', bearer => $ADMIN ) )->{token_auth}{connected},
    JSON::MaybeXS->false, 'status: connected false while the store is down' );
  $store->reconnect;
}

# a push of the process settings and of token_auth / routes is refused
{
  for my $doc (
    { token_auth => token_auth( relation => 'other' ) },
    { routes => { x => { upstream => 'http://a/v1', key_env => 'K' } } },
    { token_auth => undef },
  ) {
    my $res = send_req( $app, PUT => '/knarr/admin/config', bearer => $ADMIN, body => $doc );
    is( $res->code, 400, 'a push naming ' . join( '/', keys %$doc ) . ': 400' );
    like( decode($res)->{error}{message}, qr/take effect only at start/, '... only at start' );
    no_secret_in( $res->decoded_content, '... the answer' );
  }
  is( $admin->generation, 0, 'nothing changed' );
}

# a push of routing settings onto a token_auth start fails validation
{
  for my $doc (
    { models => { m => { engine => 'OpenAI', api_key => 'sk-pushed-0001' } } },
    { default => { engine => 'OpenAI', api_key => 'sk-pushed-0002' } },
    { passthrough => { openai => 'https://api.openai.com' } },
    { auto_discover => 1 },
    { proxy_api_key => 'proxy-pushed-0123456789' },
  ) {
    my $what = join '/', keys %$doc;
    my $res = send_req( $app, PUT => '/knarr/admin/config', bearer => $ADMIN, body => $doc );
    is( $res->code, 400, "a push of $what onto token_auth: 400" );
    like( decode($res)->{error}{message}, qr/token_auth cannot be combined with/, '... the conflict' );
    unlike( $res->decoded_content, qr/sk-pushed|proxy-pushed/, '... without the pushed key' );
    ref_is( $knarr->authorizer, $authorizer, '... the authorizer is untouched' );
    is( send_req( $app, GET => '/v1/models' )->code, 401, '... a request without token is still 401' );
  }
  is( $admin->generation, 0, 'nothing changed' );
  is( send_req( $app, PATCH => '/knarr/admin/keys', bearer => $ADMIN, body => { m => 'sk-patched-0003' } )->code, 400,
    'a key patch finds no model to patch: 400' );
}

# a push of other settings keeps the very same token check
{
  my $handler_before = $knarr->handler;
  my $res = send_req( $app, PUT => '/knarr/admin/config', bearer => $ADMIN, body => { upstream_timeout => 11 } );
  is( $res->code, 200, 'a push of upstream_timeout: 200' );
  is( decode($res)->{generation}, 1, '... generation 1' );
  ok( $knarr->handler != $handler_before, '... a new handler is installed' );
  isa_ok( $knarr->handler, ['Langertha::Knarr::Handler::TokenRoutes'], '... still TokenRoutes' );
  ref_is( $knarr->authorizer, $authorizer, '... the same authorizer' );
  ref_is( $admin->stack->token_store, $store, '... and the same store' );
  is( send_req( $app, GET => '/v1/models' )->code, 401, '... no token: 401' );
  is( send_req( $app, GET => '/v1/models', bearer => $TOKEN )->code, 200, '... the token: 200' );
  no_secret_in( $res->decoded_content, '... the answer' );

  # a revocation after the push still takes effect
  $store->revoke( token => $TOKEN );
  $store->notify;
  is( send_req( $app, GET => '/v1/models', bearer => $TOKEN )->code, 401, 'revoked after the push: 401' );

  $res = send_req( $app, DELETE => '/knarr/admin/config', bearer => $ADMIN );
  is( $res->code, 200, 'DELETE of the push layer: 200' );
  ref_is( $knarr->authorizer, $authorizer, '... the same authorizer' );
  is( send_req( $app, GET => '/v1/models' )->code, 401, '... no token: 401' );
}

done_testing;
