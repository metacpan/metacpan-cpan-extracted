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
  "$tmp/",
  'workdir matches'
);

ok(
  ! Git::Libgit2::FFI::git_repository_is_bare($repo),
  'init with bare=0 produces non-bare repo'
);

Git::Libgit2::FFI::git_repository_free($repo);

shutdown_lib();
done_testing;
