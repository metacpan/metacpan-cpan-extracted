package Test::Raider::Git;
# ABSTRACT: Temporary git repositories for the worktree tests

use strict;
use warnings;
use Exporter 'import';
use File::Which qw( which );
use IPC::Run ();
use Path::Tiny;

our @EXPORT_OK = qw( have_git git_repo git_in );

# Tests that need git:
#
#   use Test::Raider::Git qw( have_git git_repo git_in );
#   plan skip_all => 'needs git' unless have_git();
#   my $repo = git_repo( 'a.txt' => "a\n", 'lib/B.pm' => "1;\n" );   # committed on main
#   my $out  = git_in( $repo, qw( status --porcelain ) );
#
# git_repo makes a fresh repository in a temporary directory (removed when
# the returned Path::Tiny goes away), with a local user, the files written
# and committed on branch main. No global or system git configuration is
# read: the environment points both at nothing, so a developer's
# commit.gpgsign or hooks never reach the tests.

$ENV{GIT_CONFIG_NOSYSTEM} = 1;
$ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
delete @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR )};

sub have_git { which('git') ? 1 : 0 }

sub git_in {
  my ( $dir, @args ) = @_;
  my ( $out, $err ) = ( '', '' );
  IPC::Run::run( [ 'git', '-C', "$dir", @args ], \undef, \$out, \$err )
    or die 'git '.join( ' ', @args ).' in '.$dir.' failed: '.$err;
  return $out;
}

my @held;

sub git_repo {
  my ( %files ) = @_;
  my $tmp = Path::Tiny->tempdir;
  push @held, $tmp;
  my $dir = $tmp->realpath;
  git_in( $dir, qw( init -q -b main ) );
  git_in( $dir, qw( config user.name Tester ) );
  git_in( $dir, qw( config user.email tester@example.com ) );
  git_in( $dir, qw( config commit.gpgsign false ) );
  %files = ( 'README' => "readme\n" ) unless %files;
  $dir->child($_)->touchpath->spew_utf8( $files{$_} ) for keys %files;
  git_in( $dir, qw( add -A ) );
  git_in( $dir, qw( commit -q -m initial ) );
  return $dir;
}

1;
