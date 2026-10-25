use strict;
use warnings;
use Test2::V0;

# k82: Config for token_auth and routes. validate reports an incomplete
# section, unknown keys, routes that cannot work and every setting that would
# reach past the per-model token (a shared key, static models, a default
# engine, passthrough, auto_discover, remote_config). No message holds a
# value of the section. Without the keys nothing changes.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG )} }

use JSON::MaybeXS ();
use Langertha::Knarr::Config;

my $SECRET = 'S3CR3T-value-0123456789';

sub auth {
  return {
    backend  => 'postgresql',
    dsn      => 'dbi:Pg:host=db.example;dbname=platform',
    user     => 'tester_knarr',
    relation => 'tester_token_auth',
    listen   => 'tester_token',
    @_,
  };
}

sub routes {
  return {
    local  => { upstream => 'http://api:8080/v1', key_env => 'SKEID_KEY' },
    openai => { provider => 'openai', key_env => 'OPENAI_API_KEY' },
    @_,
  };
}

sub cfg { Langertha::Knarr::Config->new( data => { @_ } ) }

sub errors_of { return [ cfg(@_)->validate ] }

# --- a valid setup
{
  my $c = cfg( token_auth => auth(), routes => routes() );
  is( [ $c->validate ], [], 'token_auth with routes and nothing else is valid (no model needed)' );
  is( $c->token_auth, {
    backend     => 'postgresql',
    dsn         => 'dbi:Pg:host=db.example;dbname=platform',
    user        => 'tester_knarr',
    relation    => 'tester_token_auth',
    listen      => 'tester_token',
    hash        => 'sha256',
    columns     => { hash => 'token_hash', model => 'model', provider => 'provider', expires => 'expires_at' },
    match_model => 1,
  }, 'defaults: hash sha256, the columns, match_model true' );
  is( [ sort keys %{ $c->routes } ], [qw( local openai )], 'routes' );
}

# --- everything given
{
  my $c = cfg(
    token_auth => auth(
      password_env => 'TESTER_DB_PASSWORD', hash => 'sha256', match_model => JSON::MaybeXS->false,
      columns => { hash => 'h', model => 'm', provider => 'p', expires => 'e' },
    ),
    routes => routes( eu => { provider => 'Anthropic', key_env => 'A_KEY', url => 'https://eu.example/' } ),
  );
  is( [ $c->validate ], [], 'a full section with a regional provider url is valid' );
  is( $c->token_auth->{match_model}, 0, 'match_model false' );
  is( $c->token_auth->{columns}, { hash => 'h', model => 'm', provider => 'p', expires => 'e' }, 'columns' );
}

# --- partial columns keep the other defaults
{
  my $c = cfg( token_auth => auth( columns => { expires => 'valid_until' } ), routes => routes() );
  is( [ $c->validate ], [], 'one column renamed is valid' );
  is( $c->token_auth->{columns}{expires}, 'valid_until', '... renamed' );
  is( $c->token_auth->{columns}{hash}, 'token_hash', '... the others default' );
}

# --- the section
{
  my $e = errors_of( token_auth => auth( backend => 'mysql' ), routes => routes() );
  like( $e, bag { item match qr/backend must be 'postgresql'/; etc }, 'backend other than postgresql' );
  for my $key (qw( dsn relation listen )) {
    my %a = %{ auth() };
    delete $a{$key};
    $e = errors_of( token_auth => \%a, routes => routes() );
    like( $e, bag { item match qr/\Q$key\E is required/; etc }, "missing $key" );
  }
  $e = errors_of( token_auth => auth( hash => 'md5' ), routes => routes() );
  like( $e, bag { item match qr/hash must be 'sha256'/; etc }, 'hash other than sha256' );
  $e = errors_of( token_auth => auth( columns => { token => 'x' } ), routes => routes() );
  like( $e, bag { item match qr/unknown columns key 'token'/; etc }, 'unknown columns key' );
  $e = errors_of( token_auth => auth( columns => 'x' ), routes => routes() );
  like( $e, bag { item match qr/columns must be a mapping/; etc }, 'columns not a mapping' );
  $e = errors_of( token_auth => auth( match_modell => 1 ), routes => routes() );
  like( $e, bag { item match qr/unknown key 'match_modell'/; etc }, 'a typo in a key is an error, not silently ignored' );
  $e = errors_of( token_auth => auth( password_env => $SECRET ), routes => routes() );
  like( $e, bag { item match qr/password_env must be the name of an environment variable/; etc },
    'password_env given as the password itself' );
  is( [ grep { /\Q$SECRET\E/ } @$e ], [], '... and the error does not repeat it' );
  $e = errors_of( token_auth => 'yes', routes => routes() );
  like( $e, bag { item match qr/token_auth must be a mapping/; etc }, 'token_auth not a mapping' );
}

# --- the pairing of token_auth and routes
{
  my $e = errors_of( token_auth => auth() );
  like( $e, bag { item 'token_auth needs routes'; etc }, 'token_auth without routes' );
  $e = errors_of( token_auth => auth(), routes => {} );
  like( $e, bag { item match qr/routes must be a mapping.*at least one/; etc }, 'empty routes' );
  $e = errors_of( routes => routes(), models => { m => { engine => 'OpenAI' } } );
  like( $e, bag { item 'routes needs token_auth'; etc }, 'routes without token_auth' );
}

# --- the routes
{
  my %bad = (
    'both upstream and provider' => [ { upstream => 'http://a/v1', provider => 'openai', key_env => 'K' }, qr/exactly one of upstream and provider/ ],
    'neither'                    => [ { key_env => 'K' }, qr/exactly one of upstream and provider/ ],
    'no key_env'                 => [ { provider => 'openai' }, qr/key_env must be the name of an environment variable/ ],
    'key given for key_env'      => [ { provider => 'openai', key_env => 'sk-live-ABC123def456' }, qr/key_env must be the name/ ],
    'upstream not http'          => [ { upstream => 'ftp://a/v1', key_env => 'K' }, qr/upstream must be an http:\/\/ or https:\/\/ URL/ ],
    'unknown provider'           => [ { provider => 'nosuchengine', key_env => 'K' }, qr/unknown provider/ ],
    'url with upstream'          => [ { upstream => 'http://a/v1', url => 'http://b', key_env => 'K' }, qr/url goes with provider/ ],
    'url not http'               => [ { provider => 'openai', url => 'gopher://b', key_env => 'K' }, qr/url must be an http/ ],
    'unknown key'                => [ { provider => 'openai', key_env => 'K', api_key => $SECRET }, qr/unknown key 'api_key'/ ],
    'not a mapping'              => [ 'openai', qr/must be a mapping/ ],
  );
  for my $name ( sort keys %bad ) {
    my ( $route, $re ) = @{ $bad{$name} };
    my $e = errors_of( token_auth => auth(), routes => { r => $route } );
    like( $e, bag { item match $re; etc }, "route: $name" );
    is( [ grep { /sk-live|\Q$SECRET\E/ } @$e ], [], '... without echoing a value' );
  }
  my $e = errors_of( token_auth => auth(), routes => { r => { provider => 'OPENAI', key_env => 'K' } } );
  is( $e, [], 'a provider matches the engine catalog without regard to case' );
}

# --- conflicts
{
  my %base = ( token_auth => auth(), routes => routes() );
  my %conflict = (
    proxy_api_key  => [ { proxy_api_key => $SECRET }, qr/proxy_api_key \(or KNARR_API_KEY\)/ ],
    models         => [ { models => { m => { engine => 'OpenAI' } } }, qr/models/ ],
    default        => [ { default => { engine => 'OpenAI' } }, qr/default engine/ ],
    passthrough    => [ { passthrough => 1 }, qr/passthrough/ ],
    passthrough_h  => [ { passthrough => { openai => 'https://api.openai.com' } }, qr/passthrough/ ],
    auto_discover  => [ { auto_discover => 1 }, qr/auto_discover/ ],
    remote_config  => [ { remote_config => 1, admin_key => 'admin-key-0123456789' }, qr/remote_config/ ],
  );
  for my $name ( sort keys %conflict ) {
    my ( $extra, $re ) = @{ $conflict{$name} };
    my $e = errors_of( %base, %$extra );
    like( $e, bag { item match qr/token_auth cannot be combined with.*$re|token_auth cannot be combined with $re/; etc },
      "token_auth with $name is an error" );
    is( [ grep { /\Q$SECRET\E/ } @$e ], [], '... without the key' );
  }
  {
    local $ENV{KNARR_API_KEY} = $SECRET;
    my $e = errors_of(%base);
    like( $e, bag { item match qr/KNARR_API_KEY/; etc }, 'KNARR_API_KEY in the environment counts as a proxy key' );
    is( [ grep { /\Q$SECRET\E/ } @$e ], [], '... without the key' );
  }
  # not conflicts
  is( errors_of( %base, passthrough => 0, auto_discover => 0, proxy_api_key => '' ), [],
    'falsy passthrough / auto_discover and an empty proxy key do not conflict' );
  is( errors_of( %base, admin_key => 'admin-key-0123456789' ), [], 'an admin key goes with token_auth' );
}

# --- without the new keys nothing changes
{
  my $c = cfg( models => { m => { engine => 'OpenAI' } } );
  is( [ $c->validate ], [], 'a plain config is valid' );
  is( $c->token_auth, undef, 'no token_auth' );
  is( $c->routes, {}, 'no routes' );
  is( [ cfg()->validate ], [ 'No models configured and no default engine set' ],
    'no models still an error without token_auth' );
  is( [ Langertha::Knarr::Config->runtime_keys ], bag {
    item 'models'; item 'langfuse'; item 'passthrough'; etc;
  }, 'runtime_keys' );
  is( [ grep { /token_auth|routes/ } Langertha::Knarr::Config->runtime_keys ], [],
    'token_auth and routes are not runtime keys' );
}

done_testing;
