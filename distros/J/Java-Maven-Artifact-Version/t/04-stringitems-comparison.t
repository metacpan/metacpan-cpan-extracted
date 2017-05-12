#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_compare/;

plan tests => 3;

BEGIN {
  #test 1 : integer item is greater
  is(version_compare('1-xxxxx', '1.1'), -1);

  #test 2 : listitem is greater
  is(version_compare('1-xxxxx', '1-0.1'), -1);

  #test 3 : nullitem is equal when qualifier is '' or alias
  is(version_compare('1-ga', '1'), 0); #normalization do the job
  
  #stringitem with stringitem comparisons have already been tested in t/02-qualifiers-comparison.t
}

diag( "Testing string items comparison Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
