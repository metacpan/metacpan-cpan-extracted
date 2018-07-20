use strict;
use Test::More;
use lib 't/lib';
use Test::HTTP::Exception::Ranges;

use HTTP::Exception qw(REDIRECTION);

Test::HTTP::Exception::Ranges::test_range_ok(qw~3XX~);

done_testing;