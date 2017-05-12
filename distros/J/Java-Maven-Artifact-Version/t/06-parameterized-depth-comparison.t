#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_compare/;

plan tests => 12;

BEGIN {
  # test 1 flat versions comparison
  is(version_compare('1.1.1', '1.1', 2), 0);
  
  # test 2 suited depth comparison
  is(version_compare('1.1.1', '1.1', 3), 1);

  # test 3 too long depth comparison
  is(version_compare('1.1.1', '1.1', 4), 1);

  # test 4 flat versions comparison with stringitem, short depth
  is(version_compare('1.1.1', '1-rc', 1), 0);
  
  # test 5 flat versions comparison with stringitem, long depth
  is(version_compare('1.1.1', '1-rc', 2), 1);
  
  # test 6 deep versions comparison, short depth
  is(version_compare('1-1.1', '1-1', 2), 0);
  
  # test 7 deep versions comparison, long depth
  is(version_compare('1-1.1', '1-1.2', 3), -1);
  
  # test 8 deep versions comparison, too long depth
  is(version_compare('1-1.1', '1-1.2', 8), -1);

  # test 9 deep versions comparison, listitem with stringitem
  is(version_compare('1-1.1', '1-sp', 3), 1);
  
  # test 10 deep versions comparison, listitem with nullitem 
  is(version_compare('1-1.1', '1-ga', 3), 1);
  
  # test 11 very deep versions comparison
  is(version_compare('1-1.0-1-ga-0-1.2', '1-1.0-1-ga-0-1.3', 4), 0);
  #                   ^ ^   ^      ^      ^ ^   ^      ^

  # test 12 parameterized negative max_depth 
  is(version_compare('1-1.0', '1-1.1', -1), 0);

}

diag( "Testing Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION parameterized depth comparison features" );
