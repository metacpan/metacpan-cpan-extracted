#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

if ( not env_exists('TRAVIS') ) {
  diag('Is not running under travis!');
  exit 1;
}
if ( not env_exists('STERILIZE_ENV') ) {
  diag("\e[31mSTERILIZE_ENV is not set, skipping, because this is probably Travis's Default ( and unwanted ) target");
  exit 0;
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) and env_is( 'TRAVIS_PERL_VERSION', '5.8' ) ) {
  diag("\e[31mscript skipped on 5.8 on master\e[32m, because \@Git, a dependency of \@Author::KENTNL, is unavailble on 5.8\e[0m");
  exit 0;
}
if ( env_is( 'TRAVIS_BRANCH', 'master' ) ) {
  my $xtest = safe_exec_nonfatal( 'dzil', 'xtest' );
  my $test  = safe_exec_nonfatal( 'dzil', 'test' );
  if ( $test != 0 ) {
    exit $test;
  }
  if ( $xtest != 0 ) {
    exit $xtest;
  }
  exit 0;
}
else {
  my @paths = './t';

  if ( env_true('AUTHOR_TESTING') or env_true('RELEASE_TESTING') ) {
    push @paths, './xt';
  }
  safe_exec( 'prove', '--blib', '--shuffle', '--color', '--recurse', '--timer', '--jobs', 30, @paths );
}
