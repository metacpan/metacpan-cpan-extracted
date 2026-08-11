use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc );
use Git::Libgit2::FFI ();

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );

# --- git_repository_config ---
my $config;
check_rc Git::Libgit2::FFI::git_repository_config( \$config, $repo );
ok( $config, 'git_repository_config returned a config handle' );

# --- git_config_set_string ---
check_rc Git::Libgit2::FFI::git_config_set_string( $config, 'user.name', 'Test User' );
check_rc Git::Libgit2::FFI::git_config_set_string( $config, 'user.email', 'test@example.invalid' );

# --- git_config_get_string ---
# The out-param borrows storage owned by the config object, so libgit2
# refuses the call on a live (writable) handle and says so:
# "get_string called on a live config object" (GIT_ERROR_CONFIG).
my $rc_live = Git::Libgit2::FFI::git_config_get_string( \my $live_name, $config, 'user.name' );
isnt( $rc_live, 0, 'git_config_get_string is refused on a live config handle' );
like(
  Git::Libgit2::Error->last($rc_live)->message,
  qr/live config object/,
  'refusal comes from libgit2 as the live-config error'
);

# Reads therefore go through a snapshot, same as the get_bool block below.
my $name_snap;
check_rc Git::Libgit2::FFI::git_config_snapshot( \$name_snap, $config );
my $rc_get = Git::Libgit2::FFI::git_config_get_string( \my $name, $name_snap, 'user.name' );
is( $rc_get, 0, 'git_config_get_string succeeded on a snapshot (rc=' . $rc_get . ')' );
is( $name, 'Test User', 'git_config_get_string read back the value set above' );
Git::Libgit2::FFI::git_config_free($name_snap);

# --- git_config_get_bool (read off a snapshot, the safe read path) ---
check_rc Git::Libgit2::FFI::git_config_set_string( $config, 'core.flag', 'true' );
my $snap;
check_rc Git::Libgit2::FFI::git_config_snapshot( \$snap, $config );
my $rc_bool = Git::Libgit2::FFI::git_config_get_bool( \my $bool, $snap, 'core.flag' );
is( $rc_bool, 0, 'git_config_get_bool succeeded (rc=' . $rc_bool . ')' );
ok( $bool, "git_config_get_bool parsed 'true' as truthy" );
Git::Libgit2::FFI::git_config_free($snap);

# --- git_config_free ---
Git::Libgit2::FFI::git_config_free($config);

# --- git_config_open_default ---
my $default_config;
check_rc Git::Libgit2::FFI::git_config_open_default( \$default_config );
ok( $default_config, 'git_config_open_default returned a config handle' );
Git::Libgit2::FFI::git_config_free($default_config);

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;