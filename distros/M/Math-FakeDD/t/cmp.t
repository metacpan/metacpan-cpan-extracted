use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

my $obj1 = sqrt(Math::FakeDD->new(2));
my $obj2 = sqrt(Math::FakeDD->new(3));
my $nv   = sqrt 5;

cmp_ok(dd_cmp($obj1, $obj2), '<',  0, "obj1 <  obj2");
cmp_ok(dd_cmp($obj1, $obj2), '<=', 0, "obj1 <= obj2");
cmp_ok(dd_cmp($obj2, $obj1), '>',  0, "obj2 >  obj1");
cmp_ok(dd_cmp($obj2, $obj1), '>=', 0, "obj2 >= obj1");

cmp_ok(dd_cmp($obj1, $nv), '<',  0, "obj1 <  nv");
cmp_ok(dd_cmp($obj1, $nv), '<=', 0, "obj1 <= nv");
cmp_ok(dd_cmp($nv, $obj1), '>',  0, "nv   >  obj1");
cmp_ok(dd_cmp($nv, $obj1), '>=', 0, "nv   >= obj1");

done_testing();
