use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

ok(rnorm(10));
ok(rnorm(10, 0, 1));
