use Test::Most;

use warnings;
use strict;

eval 'use Test::Portability::Files';

plan(skip_all => 'Test::Portability::Files required for testing filenames portability') if $@;

# Turn off test_one_dot because even thoug use_file_find is off, T:P:F still
# tests files not distributed e.g. .travis.yml
options(use_file_find => 0, test_one_dot => 0);
run_tests();
