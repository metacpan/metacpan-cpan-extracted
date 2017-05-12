#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

use Path::FindDev qw( find_dev );
my $root = find_dev('./');

chdir "$root";

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

