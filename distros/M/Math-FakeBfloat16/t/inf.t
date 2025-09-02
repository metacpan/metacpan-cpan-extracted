use strict;
use warnings;
use Math::FakeBfloat16 qw(:all);

use Test::More;

my $pinf = Math::FakeBfloat16->new(2) ** 128;
cmp_ok((is_bf16_inf($pinf)), '==', 1, "\$pinf is +Inf");

my $ninf = -$pinf;
cmp_ok((is_bf16_inf($ninf)), '==', -1, "\$ninf is -Inf");

cmp_ok( (is_bf16_inf(Math::FakeBfloat16->new(2) ** 127)),    '==', 0, " (2 ** 127) is finite");
cmp_ok( (is_bf16_inf(-(Math::FakeBfloat16->new(2) ** 127))), '==', 0, "-(2 ** 127) is finite");

my $bf_max = Math::FakeBfloat16->new(0);
for(120 .. 127) { $bf_max += 2 ** $_ }
#print $bf_max;
cmp_ok($bf_max, '==', 3.39e38, "max Math::FakeBfloat16 value is 3.39e38");

cmp_ok( (is_bf16_inf($bf_max + (2 ** 119))), '==', 1, "specified value is +Inf");
cmp_ok( (is_bf16_inf($bf_max + (2 ** 118))), '==', 0, "specified value is finite");

my $mpfr = Math::MPFR->new();
Math::MPFR::Rmpfr_set_inf($mpfr, 1);
cmp_ok(Math::FakeBfloat16->new($mpfr),  '==', $pinf, "MPFR('Inf')  assigns correctly");
cmp_ok(Math::FakeBfloat16->new(-$mpfr), '==', $ninf, "MPFR('-Inf') assigns correctly");


done_testing();
