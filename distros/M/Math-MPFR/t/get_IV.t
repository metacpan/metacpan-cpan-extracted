use strict;
use warnings;

use Math::MPFR qw(:mpfr);

use Test::More;

my $iv = ~0;
my $f = Rmpfr_init2(64);

Rmpfr_set_IV($f, $iv, MPFR_RNDN);
cmp_ok($f, '==', ~0, "~0 assigned correctly in Rmpfr_set_IV()");
cmp_ok($f, '>', 0, "\$f > 0");
cmp_ok(Rmpfr_get_IV($f, MPFR_RNDN), '==', ~0, "Rmpfr_get_IV successfully retrieves ~0");

$iv = -1;
Rmpfr_set_IV($f, $iv, MPFR_RNDN);
cmp_ok($f, '==', -1, "-1 assigned correctly in Rmpfr_set_IV()");
cmp_ok($f, '<', 0, "\$f is now less than zero");
cmp_ok(Rmpfr_get_IV($f, MPFR_RNDN), '==', -1, "Rmpfr_get_IV successfully retrieves -1");


done_testing();
