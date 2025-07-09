use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

my $op = sqrt(Math::MPFR->new(2));
my $nv = Rmpfr_get_flt($op, MPFR_RNDN);
cmp_ok($op, '!=', $nv, "values no longer match");

my $op32 = Rmpfr_init2(24); # _Float32 has 24 bits of precision.
Rmpfr_set_ui($op32, 2, MPFR_RNDN);
Rmpfr_sqrt($op32, $op32, MPFR_RNDN);

cmp_ok($nv, '==', $op32, "values match");
cmp_ok(unpack_float32($nv, MPFR_RNDN), 'eq', '3FB504F3', 'hex unpacking of sqrt(2) is as expected');

my $inex = Rmpfr_set_flt($op, $nv, MPFR_RNDN);

cmp_ok($inex, '==', 0, 'value was set exactly');
cmp_ok($op, '==', $op32, 'values still match');

done_testing();
