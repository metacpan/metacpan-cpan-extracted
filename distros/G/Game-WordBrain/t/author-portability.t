#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use Test::More;

eval 'use Test::Portability::Files';
plan skip_all => 'Test::Portability::Files required for testing portability'
    if $@;

run_tests();
