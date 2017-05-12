use strict;
use warnings;

package t::util;

# CREATED: 28/05/12 22:03:22 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test Library Util

use Package::Stash;
use FindBin;
use Path::Tiny qw(path);
use Git::PurePerl;
use Archive::Tar;
use File::Temp qw( tempdir );
use File::pushd qw( pushd );

sub import {
  my ( $self, $config ) = @_;
  my $caller = caller();
  $caller = $config->{into} if defined $config->{into};
  my $stash = Package::Stash->new($caller);
  if ( defined $config->{'$repo'} ) {
    $stash->add_symbol( '$repo', \gen_repo() );
  }
}

my %handles;

sub gen_repo {
  return Git::PurePerl->new( directory => get_repo('01'), );
}

sub get_repo {
  my $name  = shift;
  my $dir   = $handles{$name} = tempdir( CLEANUP => 1 );
  my ($tar) = Archive::Tar->new;
  my $dh    = pushd($dir);
  $tar->read( repos_src()->{$name}->stringify, { extract => 1 } );
  $tar->extract();
  return $dir;
}

sub repos_src {
  my $root = path($FindBin::Bin);
  return { '01' => $root->child('git_repo_01.tar.gz')->absolute, };
}

1;
