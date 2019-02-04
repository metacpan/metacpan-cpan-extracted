use strict;
use warnings;

use Test::More;

eval 'use Test::Portability::Files';
plan skip_all => 'Test::Portability::Files required for testing portability'
    if $@;
options(test_dos_length => 0, test_one_dot => 0);
run_tests();
