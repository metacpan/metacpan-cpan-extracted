use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $obj = dd_sqrt(2);

cmp_ok("$obj", 'eq', "[1.4142135623730951 -9.667293313452913e-17]", "sqrt 2 calculated correctly");

#warn $obj, "\n";

done_testing();
