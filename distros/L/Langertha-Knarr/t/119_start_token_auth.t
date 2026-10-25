use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use YAML::PP;

# k82: knarr start / check / models with a token_auth config file. Knarr::run
# is replaced, so nothing listens and nothing connects. start builds the
# Token authorizer over the PostgreSQL store (loading DBD::Pg, not
# connecting: each worker connects on its first lookup), logs "Auth:
# token_auth (...)" without dsn, user, password or relation, and stops with a
# clear text at start when DBD::Pg is missing. check reports the same, models
# says the models come from the tokens.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG KNARR_WORKERS KNARR_LOG_FILE KNARR_LOG_DIR LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY )} }
BEGIN { *CORE::GLOBAL::exit = sub { die "EXIT $_[0]\n" } }

BEGIN {
  eval { require Capture::Tiny; 1 } or plan skip_all => 'Capture::Tiny required';
}
use Capture::Tiny qw( capture );
use Langertha::Knarr;
use Langertha::Knarr::CLI::Cmd::Start;
use Langertha::Knarr::CLI::Cmd::Check;
use Langertha::Knarr::CLI::Cmd::Models;

my $tmp = Path::Tiny->tempdir;
my $n = 0;
my $DSN = 'dbi:Pg:host=secret-db.internal;dbname=secret_platform';
my $USER = 'secret_db_user';
my $REL = 'secret_relation_view';
my $CHAN = 'secret_listen_channel';
my $PW = 'sup3r-s3cr3t-db-password';
my @SECRETS = ( $DSN, 'secret-db.internal', $USER, $REL, $CHAN, $PW );

sub file_with {
  my (%extra) = @_;
  my $file = $tmp->child( 'knarr' . ++$n . '.yaml' );
  $file->spew_utf8( YAML::PP->new->dump_string( {
    token_auth => {
      backend => 'postgresql', dsn => $DSN, user => $USER, password_env => 'TEST_KNARR_DB_PW',
      relation => $REL, listen => $CHAN,
    },
    routes => {
      local  => { upstream => 'http://127.0.0.1:1/v1', key_env => 'SKEID_KEY' },
      openai => { provider => 'openai', key_env => 'OPENAI_API_KEY' },
    },
    %extra,
  } ) );
  return $file->stringify;
}

{
  package MockMain;
  sub new { bless { config => $_[1], verbose => 0 }, $_[0] }
  sub config  { $_[0]->{config} }
  sub verbose { $_[0]->{verbose} }
}

my $ran;
{
  no warnings 'redefine';
  *Langertha::Knarr::run = sub { $ran = $_[0]; return };
}

sub run_cmd {
  my ( $class, $file, %opt ) = @_;
  undef $ran;
  my $cmd = $class->new(%opt);
  my ( $out, $err, $died ) = capture {
    my $ok = eval { $cmd->execute( [], [ MockMain->new($file) ] ); 1 };
    $ok ? '' : $@;
  };
  return ( $out, $err, $died );
}

sub without_pg(&) {
  my ($code) = @_;
  local %INC = %INC;
  delete @INC{qw( DBI.pm DBD/Pg.pm )};
  local @INC = ( sub { return unless $_[1] =~ m{\A(?:DBI|DBD/Pg)\.pm\z}; die "hidden for the test\n" }, @INC );
  return $code->();
}

sub no_secret_in {
  my ( $text, $what ) = @_;
  my @found = grep { index( $text, $_ ) >= 0 } @SECRETS;
  ok( !@found, "$what carries no dsn, user, relation, channel or password" ) or diag "found: @found";
}

my $HAVE_PG = eval { require DBD::Pg; 1 };

# --- start
SKIP: {
  skip 'DBD::Pg not installed', 14 unless $HAVE_PG;
  local $ENV{TEST_KNARR_DB_PW} = $PW;
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Start', file_with(), port => [0] );
  is( $died, '', 'start with token_auth runs' );
  ok( $ran, '... a Knarr' );
  like( $err, qr/^\[knarr\] Auth: token_auth \(postgresql, routes: local, openai\)$/m, 'the banner: Auth: token_auth (backend, routes)' );
  no_secret_in( $err, 'the banner' );
  unlike( $err, qr/Proxy auth|Engines: none \(passthrough only mode\)/, '... no proxy-key / passthrough-only lines' );
  isa_ok( $ran->authorizer, ['Langertha::Knarr::Authorizer::Token'], 'Knarr gets the Token authorizer' );
  isa_ok( $ran->authorizer->store, ['Langertha::Knarr::TokenStore::Pg'], '... over the PostgreSQL store' );
  isa_ok( $ran->handler, ['Langertha::Knarr::Handler::TokenRoutes'], '... TokenRoutes as handler' );
  is( $ran->raw_passthrough, undef, '... no raw passthrough' );
  is( $ran->auth_token, undef, '... no proxy key' );

  # workers > 1: nothing connects in the process that forks
  ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Start', file_with(), port => [0], workers => 3 );
  is( $ran->workers, 3, 'with -w 3 and no admin key: three workers' );
  my $pg = $ran->authorizer->store;
  ok( !$pg->available, '... the parent holds no database connection' );
  is( $pg->_dbh, undef, '... no handle' );
  is( $pg->_pid, 0, '... none owned by this process, so each worker opens its own' );
}

# --- start: a missing DBD::Pg stops at start
{
  local $ENV{TEST_KNARR_DB_PW} = $PW;
  my ( $out, $err, $died ) = without_pg {
    run_cmd( 'Langertha::Knarr::CLI::Cmd::Start', file_with(), port => [0] );
  };
  is( $died, "EXIT 1\n", 'DBD::Pg missing: start stops with exit 1' );
  ok( !$ran, '... without running a Knarr' );
  like( $err, qr/\[knarr\] ERROR: token_auth backend postgresql needs DBD::Pg/, '... saying what is missing' );
  no_secret_in( $err, '... the message' );
}

# --- start: invalid
{
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Start',
    file_with( proxy_api_key => $PW, passthrough => 1 ), port => [0] );
  is( $died, "EXIT 1\n", 'token_auth with a proxy key and passthrough: start refuses' );
  like( $err, qr/Configuration errors/, '... listing the errors' );
  like( $err, qr/token_auth cannot be combined with proxy_api_key/, '... the proxy key' );
  like( $err, qr/token_auth cannot be combined with passthrough/, '... the passthrough' );
  no_secret_in( $err, '... the errors' );
  ok( !$ran, '... no Knarr' );
}

# --- start: with an admin key the workers are forced to one, the status says token_auth
SKIP: {
  skip 'DBD::Pg not installed', 4 unless $HAVE_PG;
  local $ENV{TEST_KNARR_DB_PW} = $PW;
  local $ENV{KNARR_ADMIN_KEY} = 'admin-key-start-0123456789';
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Start',
    file_with(), port => [0], workers => 4 );
  is( $died, '', 'token_auth with an admin key starts' );
  is( $ran->workers, 1, '... one worker' );
  is( $ran->admin->status->{token_auth}, { backend => 'postgresql', connected => F() },
    '... status: token_auth on, not connected yet' );
  ref_is( $ran->authorizer, $ran->admin->stack->authorizer, '... the stack\'s authorizer' );
}

# --- check
SKIP: {
  skip 'DBD::Pg not installed', 5 unless $HAVE_PG;
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Check', file_with() );
  is( $died, '', 'check with token_auth: ok' );
  like( $out, qr/Configuration OK/, '... OK' );
  like( $out, qr/Token auth: postgresql \(routes: local, openai\)/, '... the backend and the routes' );
  like( $out, qr/Models: from the tokens/, '... models come from the tokens' );
  no_secret_in( $out . $err, '... the output' );
}
{
  my ( $out, $err, $died ) = without_pg { run_cmd( 'Langertha::Knarr::CLI::Cmd::Check', file_with() ) };
  is( $died, "EXIT 1\n", 'check without DBD::Pg: exit 1' );
  like( $out, qr/Configuration INVALID.*needs DBD::Pg/s, '... the same message as start' );
}
{
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Check', file_with( models => { m => { engine => 'OpenAI' } } ) );
  is( $died, "EXIT 1\n", 'check: token_auth with models is invalid' );
  like( $out, qr/token_auth cannot be combined with models/, '... says why' );
}

# --- models
{
  my ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Models', file_with(), format => 'table' );
  is( $died, '', 'models with token_auth: ok' );
  like( $out, qr/Models come from the issued tokens/, '... says the models come from the tokens' );
  like( $out, qr/local, openai/, '... shows the routes' );
  no_secret_in( $out . $err, '... the output' );
  ( $out, $err, $died ) = run_cmd( 'Langertha::Knarr::CLI::Cmd::Models', file_with(), format => 'json' );
  is( $out, "[]\n", 'models --format json: an empty list' );
}

done_testing;
