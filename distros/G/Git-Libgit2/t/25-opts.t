use Test2::V0;
use Git::Libgit2 qw(
  init_lib shutdown_lib check_rc
  GIT_OPT_SET_SEARCH_PATH
  GIT_CONFIG_LEVEL_PROGRAMDATA
  GIT_CONFIG_LEVEL_SYSTEM
  GIT_CONFIG_LEVEL_XDG
  GIT_CONFIG_LEVEL_GLOBAL
);
use Git::Libgit2::FFI ();

# Pin libgit2 away from the user's gitconfig — exact bug Git::Raw shipped.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

# git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH, $level, "") blanks the search path
# for that config level. "" is NOT NULL — NULL resets to the compiled default,
# "" sets it empty (per include/git2/common.h docs). For test isolation this
# keeps libgit2 from reaching into /etc/gitconfig etc. Returns 0 on success.
for my $level ( GIT_CONFIG_LEVEL_PROGRAMDATA, GIT_CONFIG_LEVEL_SYSTEM,
                GIT_CONFIG_LEVEL_XDG, GIT_CONFIG_LEVEL_GLOBAL ) {
  my $rc = Git::Libgit2::FFI::git_libgit2_opts(
    GIT_OPT_SET_SEARCH_PATH, $level, ""
  );
  is( $rc, 0, "git_libgit2_opts(SET_SEARCH_PATH, level=$level, \"\") returns 0" );
}

shutdown_lib();
done_testing;