#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Path::FindDev qw( find_dev );
my $root = find_dev('./');

chdir "$root";

sub diag {
  print STDERR @_;
  print STDERR "\n";
}

sub safe_exec {
  my ( $command, @params ) = @_;
  diag("running $command @params");
  my $exit = system( $command, @params );
  if ( $exit != 0 ) {
    my $low  = $exit & 0b11111111;
    my $high = $exit >> 8;
    warn "$command failed: $? $! and exit = $high , flags = $low";
    if ( $high != 0 ) {
      exit $high;
    }
    else {
      exit 1;
    }
  }
  return 1;
}

sub git_subtree {
  safe_exec( 'git', 'subtree', @_ );
}

my $travis = 'https://github.com/kentfredric/travis-scripts.git';
my $prefix = 'maint-travis-ci';

if ( not -d -e $root->child($prefix) ) {
  git_subtree( 'add', '--prefix=' . $prefix, $travis, 'master' );
}
else {
  git_subtree( 'pull', '-m', 'Synchronise git subtree maint-travis-ci', '--prefix=' . $prefix, $travis, 'master' );
}

