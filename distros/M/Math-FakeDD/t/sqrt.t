use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $obj = dd_sqrt(2);

cmp_ok("$obj", 'eq', "[1.4142135623730951 -9.667293313452913e-17]", "sqrt 2 calculated correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for sqrt 2");
cmp_ok(dd_sqrt(Math::FakeDD->new(2.2)), '==', dd_sqrt(2.2), "dd_sqrt() processes args correctly");

#warn $obj, "\n";

done_testing();
