#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_compare/;

plan tests => 8;

BEGIN {

  # test 1 : listitem with integeritem comparison : listitem is lower
  is(version_compare('1-1.1', '1.1'), -1);

  # test 2 : listitem with integeritem comparison : listitem is lower
  is(version_compare('1-1', '1.alpha'), 1);

  # test 3 : listitem with nullitem comparison : listitem is equal if listitem is empty
  is(version_compare('1-0.final-ga', '1'), 0);
  
  # test 4 : listitem with nullitem comparison : listitem is equal if listitem first elem is 0 integeritem
  is(version_compare('1-0.alpha', '1'), 0);
  
  # test 5 : listitem with nullitem comparison : listitem is greater if listitem first elem is not 0 integeritem
  is(version_compare('1-1', '1'), 1);
  
  # test 6 : listitem with nullitem comparison : listitem is lower if listitem first elem is lower than nullitem
  is(version_compare('alpha', '0'), -1); #0 is normalized then listitem will be empty and will begin nullitem

  # test 7 : listitem with listitem : comparison is done for each elem until inequality
  is(version_compare('1-1-rc-2', '1-1-rc-1'), 1);

  # test 8 : listitem with listitem : very deep comparison 
  is(version_compare('1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-alpha', 
      '1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-beta'), -1);

}

diag( "Testing simple Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION listitems comparison features" );
