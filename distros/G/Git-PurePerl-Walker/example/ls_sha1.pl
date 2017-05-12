#!/usr/bin/env perl

use strict;
use warnings;

# FILENAME: ls_sha1.pl
# CREATED: 29/05/12 16:42:08 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: List all sha1's in parent order in current git repo

use Path::Class qw( dir );
use Term::ANSIColor qw( :constants );

my $cwd = dir(q{.});

sub is_git_dir {
  my ($dir) = @_;
  return unless -e $dir->subdir('objects');
  return unless -e $dir->subdir('refs');
  return unless -e $dir->file('HEAD');
  return 1;
}

sub find_git_dir {
  my $start = shift;
  if ( is_git_dir($start) ) {
    return $start;
  }
  if ( -e $start->subdir('.git') && is_git_dir( $start->subdir(q{.git}) ) ) {
    return $start->subdir('.git');
  }
  if ( $start->parent->stringify ne $start->stringify ) {
    return find_git_dir( $start->parent );
  }
  die "No Git Directory found";
}

require Git::PurePerl;
require Git::PurePerl::Walker;
require Git::PurePerl::Walker::Method::FirstParent;

sub trim {
  my $comment = shift;
  $comment =~ s/\s+/ /g;
  if ( length($comment) > 80 ) {
    return substr( $comment, 0, 80 ) . '...';
  }
  return $comment;
}

sub abbr_sha {
  my $sha = shift;
  return substr $sha, 0, 8;
}
my $repo = Git::PurePerl->new( gitdir => find_git_dir($cwd), );

my $walker = Git::PurePerl::Walker->new(
  repo      => $repo,
  method    => 'FirstParent::FromHEAD',
  on_commit => sub {
    my $commit   = shift;
    my $is_merge = ' ';
    $is_merge = BRIGHT_RED . '*' . RESET if @{ $commit->parent_sha1s } > 1;
    printf "%s%s %s", $is_merge, GREEN . abbr_sha( $commit->sha1 ) . RESET, trim( $commit->comment );
    print BRIGHT_BLUE . " -> " . join q{, }, map { abbr_sha($_) } @{ $commit->parent_sha1s };
    print RESET . "\n";
  },
);

$walker->step_all;
