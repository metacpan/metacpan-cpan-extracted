# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-decNumber.t'

#########################
use Math::decNumber ':all';
use t::tool;
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 1278  };

test_file("t/decNumberTest/compare.decTest");




