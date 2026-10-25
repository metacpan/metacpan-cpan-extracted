use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use YAML::PP;

# k75: knarr start --remote-config (and KNARR_REMOTE_CONFIG) starts without a config
# file and without models, with the admin routes on; an admin key forces one
# worker; the banner never shows a key. Knarr::run is replaced, so nothing
# listens, and exit is turned into a die to see the refusals.

BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG KNARR_WORKERS KNARR_LOG_FILE KNARR_LOG_DIR )} }
BEGIN { *CORE::GLOBAL::exit = sub { die "EXIT $_[0]\n" } }

BEGIN {
  eval { require Capture::Tiny; 1 } or plan skip_all => 'Capture::Tiny required';
}
use Capture::Tiny qw( capture );
use Langertha::Knarr;
use Langertha::Knarr::CLI::Cmd::Start;

my $ADMIN = 'admin-key-start-0123456789';
my $tmp = Path::Tiny->tempdir;

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

sub start {
  my ( $file, %opt ) = @_;
  undef $ran;
  my $cmd = Langertha::Knarr::CLI::Cmd::Start->new( port => [ 0 ], %opt );
  my ( $out, $err, $died ) = capture {
    my $ok = eval { $cmd->execute( [], [ MockMain->new($file) ] ); 1 };
    $ok ? '' : $@;
  };
  return ( $err, $died );
}

my $missing = $tmp->child('none.yaml')->stringify;

# --- --remote-config without a file ---
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  my ( $err, $died ) = start( $missing, remote_config => 1 );
  is( $died, '', 'knarr start --remote-config starts without a config file' );
  ok( $ran, '... and runs a Knarr' );
  ok( $ran->admin, '... with the admin routes' );
  ok( !$ran->admin->configured, '... and no setup' );
  ok( $ran->admin->remote_config, '... remote_config' );
  like( $err, qr/Config: remote config, no config file/, 'the banner says remote config' );
  like( $err, qr/Admin routes: enabled/, '... and that the admin routes are on' );
  unlike( $err, qr/\Q$ADMIN\E/, '... never the key' );
}

# --- KNARR_REMOTE_CONFIG wins over --from-env (the Docker default) ---
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  local $ENV{KNARR_REMOTE_CONFIG}  = 1;
  local $ENV{OPENAI_API_KEY}  = 'sk-from-env-not-used-0001';
  my ( $err, $died ) = start( $missing, from_env => 1 );
  is( $died, '', 'KNARR_REMOTE_CONFIG with --from-env starts' );
  like( $err, qr/--from-env ignored/, '... saying --from-env is ignored' );
  is( $ran->router->config->models, {}, '... with no models from the environment' );
  unlike( $err, qr/sk-from-env-not-used/, '... and no key in the banner' );
}

# --- No admin key, remote_config on ---
{
  my ( $err, $died ) = start( $missing, remote_config => 1 );
  is( $died, "EXIT 1\n", 'remote_config without an admin key: refused' );
  like( $err, qr/remote_config needs an admin_key/, '... saying why' );
  ok( !$ran, '... before anything runs' );
}

# --- An admin key forces one worker ---
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  my $file = $tmp->child('w.yaml');
  $file->spew_utf8( YAML::PP->new->dump_string({ models => { m => { engine => 'OpenAI', api_key => 'sk-file-key-000001' } } }) );
  my ( $err, $died ) = start( "$file", workers => 3 );
  is( $died, '', 'a config file with an admin key and -w 3 starts' );
  is( $ran->workers, 1, '... with one worker' );
  like( $err, qr/workers forced to 1 \(was 3\)/, '... saying so' );
  ok( $ran->admin->configured, '... configured from the file' );
  is( $ran->admin->status->{layers}, ['file'], '... layer file' );
  unlike( $err, qr/\Q$ADMIN\E|sk-file-key/, 'no key in the banner' );
}

# --- remote_config with a config file that holds models: always in effect ---
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  my $file = $tmp->child('r.yaml');
  $file->spew_utf8( YAML::PP->new->dump_string({ remote_config => 1, proxy_api_key => 'proxy-from-file-0001',
    models => { m => { engine => 'OpenAI', api_key => 'sk-file-key-000002' } } }) );
  my ( $err, $died ) = start("$file");
  is( $died, '', 'remote_config with models in the file: starts' );
  ok( $ran->admin->configured, '... configured from the file at once' );
  is( $ran->admin->status->{layers}, ['file'], '... the file is the only layer' );
  is( $ran->admin->status->{models}, ['m'], '... with its model' );
  ok( $ran->admin->remote_config, '... remote_config on' );
  unlike( $err, qr/sk-file-key|proxy-from-file/, '... without a key in the banner' );
  unlike( $err, qr/requests answer 503/, '... and no 503 notice' );
  like( $err, qr/Remote config: on/, '... saying a push layers over the file' );
}

# --- remote_config, a file without models: 503 until the push ---
{
  local $ENV{KNARR_ADMIN_KEY} = $ADMIN;
  my $file = $tmp->child('rn.yaml');
  $file->spew_utf8( YAML::PP->new->dump_string({ remote_config => 1, listen => ['127.0.0.1:1'] }) );
  my ( $err, $died ) = start("$file");
  is( $died, '', 'remote_config, file without models: starts' );
  ok( !$ran->admin->configured, '... not configured' );
  is( $ran->admin->status->{layers}, ['file'], '... the file is a layer, holding no setup' );
}

# --- --from-env: the admin key is still checked ---
{
  local $ENV{KNARR_ADMIN_KEY} = 'too-short';
  my ( $err, $died ) = start( $missing, from_env => 1 );
  is( $died, "EXIT 1\n", '--from-env with a short admin key: refused' );
  like( $err, qr/admin_key must be at least 16 characters/, '... saying why' );
  unlike( $err, qr/too-short/, '... without the key' );
}

# --- Without an admin key: no admin routes, workers as asked ---
{
  my $file = $tmp->child('p.yaml');
  $file->spew_utf8( YAML::PP->new->dump_string({ models => { m => { engine => 'OpenAI', api_key => 'sk-file-key-000003' } } }) );
  my ( $err, $died ) = start( "$file", workers => 2 );
  is( $died, '', 'no admin key: starts' );
  ok( !$ran->admin, '... without admin routes' );
  is( $ran->workers, 2, '... with the workers asked for' );
  like( $err, qr/Admin routes: off/, '... and says so' );
}

done_testing;
