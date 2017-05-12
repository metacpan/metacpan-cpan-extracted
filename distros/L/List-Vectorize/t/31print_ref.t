use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

ok(print_ref [1..10]);
ok(print_ref {"a" => 1, "b" => 2});
ok(print_ref \1);
