#!perl -T
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Java::Maven::Artifact::Version qw/version_parse/;

plan tests => 20;

BEGIN {
  #test 1 : 1.0 normalized to (1)
  is(version_parse('1.0'), '(1)'); 

  #test 2 : 1.0.1 normalized to (1,0,1)
  is(version_parse('1.0.1'), '(1,0,1)');

  #test 3 : 1.0-1 normalized to (1,(1))
  is(version_parse('1.0-1'), '(1,(1))');

  #test 4 : 1.0-1-alpha-1 normalized to (1,(1,alpha,1))
  is(version_parse('1.0-1-alpha-1'), '(1,(1,alpha,1))');

  #test 5 : 222-ga.0.1-final.1-1-rc.final normalized to (222,,0,1,,1,(1,rc))
  is(version_parse('222-ga.0.1-final.1-1-rc.final'), '(222,,0,1,,1,(1,rc))');

  #test 6 : 1.0-final-1.0.1-1-4-SNAPSHOT normalized to (1,,1,0,1,(1,(4,snapshot)))
  is(version_parse('1.0-final-1.0.1-1-4-SNAPSHOT'), '(1,,1,0,1,(1,(4,snapshot)))');

  #test 7 : 1.1-1.1-1.1-1.1 normalized to (1,1,(1,1,(1,1,(1,1))))
  is(version_parse('1.1-1.1-1.1-1.1'), '(1,1,(1,1,(1,1,(1,1))))');

  #test 8 : 1....1 normalized to (1,0,0,0,1)
  is(version_parse('1....1'), '(1,0,0,0,1)');
  
  #test 9 : special alias 'a\d' normalization test
  is(version_parse('a1'), '(alpha,1)');
  
  #test 10 : special alias 'a\d' normalization test
  is(version_parse('1-a1'), '(1,alpha,1)');
  
  #test 11 : special alias 'b\d' normalization test
  is(version_parse('b1'), '(beta,1)');
  
  #test 12 : special alias 'b\d' normalization test
  is(version_parse('1-b1'), '(1,beta,1)');

  #test 13 : special alias 'm\d' normalization test
  is(version_parse('m1'), '(milestone,1)');
  
  #test 14 : special alias 'm\d' normalization test
  is(version_parse('1-m1'), '(1,milestone,1)');

  #test 15 : null alias start followed by non nullitem
  is(version_parse('final-0.1'), '(,0,1)');

  #test 16 : only nullitems
  is(version_parse('final.0.0'), '()');
  
  #test 17 : zero appending does not build listitem on dash
  is(version_parse('-1-.1'), '(0,1,0,1)');

  #test 18 : stringitem with digit split stringitem to items
  is(version_parse('m1char'), '(milestone,1,char)');
  
  #test 19 : stringitem with digit split stringitem to items
  is(version_parse('12xxx'), '(12,xxx)');

  #test 20 : stringitem with digit split stringitem to items
  is(version_parse('xxx12'), '(xxx,12)');
}

diag( "Testing normalization Java::Maven::Artifact::Version $Java::Maven::Artifact::Version::VERSION feature" );
