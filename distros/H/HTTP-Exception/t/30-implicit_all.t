use strict;
use Test::More;
use lib 't/lib';
use Test::HTTP::Exception::Ranges;

use HTTP::Exception;
Test::HTTP::Exception::Ranges::test_range_ok(100, 200, 300, 400, 500);

done_testing;