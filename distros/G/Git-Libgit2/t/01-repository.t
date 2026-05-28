use Test2::V0;
use Path::Tiny;
use File::Temp ();
use Git::Libgit2 qw( init_lib shutdown_lib check_rc );
use Git::Libgit2::FFI ();

# Pin libgit2 away from the user's gitconfig — exact bug Git::Raw shipped.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );
ok( $repo, 'git_repository_init returned a handle' );

is(
  Git::Libgit2::FFI::git_repository_workdir($repo),
  # libgit2 returns the canonical (symlink-resolved) path, so resolve our
  # side too — on macOS /var is a symlink to /private/var. No-op on Linux.
  $tmp->realpath . '/',
  'workdir matches'
);

ok(
  ! Git::Libgit2::FFI::git_repository_is_bare($repo),
  'init with bare=0 produces non-bare repo'
);

# git_repository_set_head: point HEAD at an as-yet-unborn branch, then
# confirm the HEAD file was rewritten (no head() binding to read it back).
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );
like(
  path( Git::Libgit2::FFI::git_repository_path($repo) )->child('HEAD')->slurp_utf8,
  qr{ref:\s*refs/heads/main},
  'set_head pointed HEAD at refs/heads/main'
);

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
