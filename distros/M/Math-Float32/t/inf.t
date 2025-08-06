use strict;
use warnings;
use Math::Float32 qw(:all);

use Test::More;

my $pinf = Math::Float32->new(2) ** flt_EMAX;
cmp_ok((is_flt_inf($pinf)), '==', 1, "\$pinf is +Inf");
cmp_ok(flt_signbit($pinf), '==', 0, "+Inf does not set signbit");

my $ninf = -$pinf;
cmp_ok((is_flt_inf($ninf)), '==', -1, "\$ninf is -Inf");
cmp_ok(flt_signbit($ninf), '==', 1, "-Inf sets signbit");

cmp_ok( (is_flt_inf(Math::Float32->new(2) ** 127)),    '==', 0, " (2 ** 127) is finite");
cmp_ok( (is_flt_inf(-(Math::Float32->new(2) ** 127))), '==', 0, "-(2 ** 127) is finite");

my $bf_max = Math::Float32->new(0);
for(104 .. 127) { $bf_max += 2 ** $_ }
#print $bf_max;
cmp_ok($bf_max, '==', $Math::Float32::flt_NORM_MAX, "max Math::Float32 value is 3.402823466e+38");

cmp_ok( (is_flt_inf($bf_max + (2 ** 103))), '==', 1, "specified value is +Inf");
cmp_ok( (is_flt_inf($bf_max + (2 ** 102))), '==', 0, "specified value is finite");


done_testing();
