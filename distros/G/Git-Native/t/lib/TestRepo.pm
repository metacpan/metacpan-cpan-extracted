package TestRepo;
use strict;
use warnings;
use Path::Tiny;
# --- config isolation -------------------------------------------------------
#
# Keep the developer's real git config out of the suite - the exact bug
# Git::Raw shipped. Three mechanisms, because each one reaches somewhere the
# others do not:
#
# 1. GIT_CONFIG_GLOBAL / GIT_CONFIG_SYSTEM cover the git CLI a fixture may
#    shell out to. libgit2 does not know either variable (nor
#    GIT_CONFIG_NOSYSTEM) - measured, no effect.
#
# 2. Git::Native->set_config_search_path covers libgit2 itself, and is the
#    only supported way to reach its *system* level: /etc/gitconfig is
#    compiled in, no environment variable moves it. It is process-global and
#    takes effect for every repository opened after the call, which is why it
#    runs here at load time, before any test has a repository.
#
# 3. The HOME / XDG_CONFIG_HOME redirect. No longer what isolates the config
#    - point 2 does that, verifiably with HOME left alone (karr-13). It stays
#    for the *non*-config things libgit2 and Git::Native read out of a home
#    directory: ~/.ssh/known_hosts, which Git::Native::Remote checks hostkeys
#    against, and the default ssh key paths in Git::Native::Credential.
#    Without it those tests would read the operator's real ~/.ssh.
#
# The two halves agree on purpose: the global / xdg search paths point into
# the same throwaway HOME the redirect creates, so "drop a .gitconfig into
# $TestRepo::HOME" keeps meaning what it did before.
#
# Load order: this module still has to come before Git::Native. Not for the
# HOME redirect any more, but because the search path only applies to
# repositories opened *after* it is set - an already-open repository keeps the
# config it resolved at open time (measured). Loading TestRepo first is the
# cheap way to guarantee nothing got there first.
#
# Scope of the isolation, on purpose:
#   system + programdata  isolated - /etc/gitconfig no longer applies.
#   global + XDG          isolated - nothing of ~/.gitconfig reaches a test.
#   repository            untouched - tests set user.name / user.email on the
#                         repo they just created and must keep seeing those.
#
# t/69-config-isolation.t is the regression test for all of this.
our $REAL_HOME;
our $HOME;
our $SYSTEM_CONFIG_DIR;
BEGIN {
  die "TestRepo must be loaded before Git::Native - libgit2's config search "
    . "path only applies to repositories opened after it is redirected, and "
    . "this module is what redirects it\n"
    if $INC{'Git/Libgit2.pm'};
  $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
  $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';
  # Live network tests need the operator's real ~/.ssh (keys, known_hosts),
  # which the redirect would hide; they restore HOME from here.
  $REAL_HOME = $ENV{HOME};
  # One throwaway HOME per test process. File::Temp hands out a unique
  # directory, so parallel test files never share one, and the tempdir guard
  # removes it on exit exactly like the test repos below.
  $HOME                 = Path::Tiny->tempdir('git-native-home-XXXXXXXX');
  $ENV{HOME}            = "$HOME";
  $ENV{XDG_CONFIG_HOME} = $HOME->child('.config')->stringify;
  # Stand-in for /etc: empty, but it exists so a test can plant a probe
  # gitconfig in it and watch the system level pick it up.
  $SYSTEM_CONFIG_DIR = $HOME->child('etc');
  $SYSTEM_CONFIG_DIR->mkpath;
}
use Git::Native;
Git::Native->set_config_search_path(
  system      => "$SYSTEM_CONFIG_DIR",
  programdata => "$SYSTEM_CONFIG_DIR",
  global      => "$HOME",
  xdg         => $ENV{XDG_CONFIG_HOME},
);
sub new_repo {
  my $tmp  = Path::Tiny->tempdir;
  # Pin the default branch to 'main' so tests don't depend on libgit2's
  # compiled-in default: Debian patches it to 'main', upstream/Homebrew
  # still defaults to 'master'.
  my $repo = Git::Native->init( "$tmp", initial_branch => 'main' );
  return ( $repo, $tmp );
}
1;
