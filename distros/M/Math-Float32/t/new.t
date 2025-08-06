use strict;
use warnings;
use Math::Float32 qw(:all);

use Test::More;

my @inputs = ('1.5', '-1.75', 2.625, 42);

for my $in(@inputs) {
  cmp_ok(flt_to_NV(Math::Float32->new($in)), '==', $in, "flt_to_NV: $in ok");
  cmp_ok(flt_to_NV(Math::Float32->new(-$in)), '==', -$in, "flt_to_NV: -$in ok");
}

cmp_ok(ref(Math::Float32->new()), 'eq', 'Math::Float32', "Math::Float32->new() returns a Math::Float32 object");
cmp_ok(ref(Math::Float32::new()), 'eq', 'Math::Float32', "Math::Float32::new() returns a Math::Float32 object");


cmp_ok(is_flt_nan(Math::Float32->new()), '==', 1, "Math::Float32->new() returns NaN");
cmp_ok(is_flt_nan(Math::Float32::new()), '==', 1, "Math::Float32::new() returns NaN");

my $obj = Math::Float32->new('1.414');
cmp_ok(Math::Float32->new($obj), '==', $obj, "new(obj) == obj");
cmp_ok(Math::Float32->new($obj), '==', '1.414', "new(obj) == value of obj");

done_testing();
