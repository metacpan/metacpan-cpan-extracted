#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_compare/;

plan tests => 9;

BEGIN {

  #test 1 : integeritem with integeritem - inferiority
  is(version_compare(1, 2), -1);

  #test 2 : integeritem with integeritem - superiority
  is(version_compare(2, 1), 1);
  
  #test 3 : integeritem with integeritem - equality
  is(version_compare(2, 2), 0);

  #test 4 : integeritem with stringitem - superiority
  is(version_compare('1.1', '1-m1'), 1);

  #test 5 : integeritem with listitem - superiority
  is(version_compare('1.1', '1-1'), 1);

  #test 6 : integeritem with nullitem - case of superiority
  is(version_compare('1.1.1', '1.ga.1'), 1);
  
  #test 7 : integeritem with nullitem - case of equality
  is(version_compare('1.0.1', '1..1'), 0); #_replace_alias do the job
  
  #test 8 : 0 integeritem lower than 'sp' qualifier
  is(version_compare('0', 'sp'), -1); 
  
  #test 9 : 0 integeritem greater than 'SNAPSHOT' qualifier
  is(version_compare('1-1.0.sp', '1-1-SNAPSHOT'), 1); 
}

diag( "Testing integer items comparison Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
