use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('List::Vectorize') }

my $s = ["a", "b", "c", "d", "e"];

is(is_element("a", $s), 1);
is(is_element("g", $s), 0);

my $s2 = [1, 2, 3];
is(is_element(1, $s2), 1);
is(is_element(1.0, $s2), 1);
is(is_element(1.0000000000001, $s2), 1);
is(is_element(1.5, $s2), 0);
