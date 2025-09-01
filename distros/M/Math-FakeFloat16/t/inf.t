use strict;
use warnings;
use Math::FakeFloat16 qw(:all);

use Test::More;

# emin = -23; emax = 16; mantbits = 11;

my $pinf = Math::FakeFloat16->new(2) ** 16;
cmp_ok((is_f16_inf($pinf)), '==', 1, "\$pinf is +Inf");

my $ninf = -$pinf;
cmp_ok((is_f16_inf($ninf)), '==', -1, "\$ninf is -Inf");

cmp_ok( (is_f16_inf(Math::FakeFloat16->new(2) ** 15)),    '==', 0, " (2 ** 15) is finite");
cmp_ok( (is_f16_inf(-(Math::FakeFloat16->new(2) ** 15))), '==', 0, "-(2 ** 15) is finite");

my $bf_max = Math::FakeFloat16->new(0);
for(5 .. 15) { $bf_max += 2 ** $_ }
cmp_ok($bf_max, '==', $Math::FakeFloat16::f16_NORM_MAX, "max Math::FakeFloat16 value is 6.5504e4");

cmp_ok( (is_f16_inf($bf_max + (2 ** 4))), '==', 1, "specified value is +Inf");
cmp_ok( (is_f16_inf($bf_max + (2 ** 3))), '==', 0, "specified value is finite");

my $mpfr = Math::MPFR->new();
Math::MPFR::Rmpfr_set_inf($mpfr, 1);
cmp_ok(Math::FakeFloat16->new($mpfr),  '==', $pinf, "MPFR('Inf')  assigns correctly");
cmp_ok(Math::FakeFloat16->new(-$mpfr), '==', $ninf, "MPFR('-Inf') assigns correctly");

cmp_ok(is_f16_inf(Math::FakeFloat16->new(~0)), '==', 1, "~0 is +Inf");
cmp_ok(is_f16_inf(Math::FakeFloat16->new(-(~0 >> 2))), '==', -1, "-(~0 >> 2) is -Inf");


done_testing();
