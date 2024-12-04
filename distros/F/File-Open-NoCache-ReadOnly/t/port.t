use Test::Most;

use warnings;
use strict;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Portability::Files';

Test::Portability::Files->import();

# Turn off test_one_dot because even though use_file_find is off, T:P:F still
# tests files not distributed e.g. .travis.yml
options(use_file_find => 0, test_one_dot => 0);
run_tests();
