package TestRepo;
use strict;
use warnings;
use Path::Tiny;
use Git::Native;

# Pin libgit2 away from the user's gitconfig. The exact bug Git::Raw shipped.
$ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
$ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

sub new_repo {
  my $tmp  = Path::Tiny->tempdir;
  # Pin the default branch to 'main' so tests don't depend on libgit2's
  # compiled-in default: Debian patches it to 'main', upstream/Homebrew
  # still defaults to 'master'.
  my $repo = Git::Native->init( "$tmp", initial_branch => 'main' );
  return ( $repo, $tmp );
}

1;
