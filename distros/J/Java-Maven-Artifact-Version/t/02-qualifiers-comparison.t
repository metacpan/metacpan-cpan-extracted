#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_compare/;

plan tests => 12;

BEGIN {
  #test 1 : alpha < beta
  is(version_compare('alpha', 'beta'), -1);
  
  #test 2 : beta < milestone
  is(version_compare('beta', 'milestone'), -1);
  
  #test 3 : milestone < rc
  is(version_compare('milestone', 'rc'), -1);
  
  #test 4 : rc < ''
  is(version_compare('rc', 'ga'), -1);
  
  #test 5 : '' < sp
  is(version_compare('', 'sp'), -1);
  
  #test 6 : sp < xxx
  is(version_compare('sp', 'xxx'), -1);

  #test 7 : sp > '' (inversion of test just to check it can return something else of -1)
  is(version_compare('sp', 'ga'), 1);

  #test 8 : xx < xxx
  is(version_compare('xx', 'xxx'), -1);

  #test 9 : a < b
  is(version_compare('a', 'b'), -1);
  
  #test 10 : a < aa
  is(version_compare('a', 'aa'), -1);
  
  #test 11 : a == a (equality test not done until this one)
  is(version_compare('a', 'a'), 0);
  
  #test 12 : milestone == milestone (equality test not done until this one on known qualifiers)
  is(version_compare('milestone', 'milestone'), 0);
}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION qualifiers comparison feature" );
