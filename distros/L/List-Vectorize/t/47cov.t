use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

is(cov(seq(1, 8), seq(8, 1)), -6);
