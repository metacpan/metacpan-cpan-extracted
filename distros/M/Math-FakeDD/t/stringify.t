use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

#cmp_ok($Math::FakeDD::VERSION, '==', 1.03, "Version number is correct"); # Not needed here - checked in new.t

my $obj = Math::FakeDD->new();

dd_assign($obj, '1.3');

cmp_ok("$obj", 'eq', "[1.3 -4.4408920985006264e-17]", "'1.3' assigns and stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for '1.3'");

dd_assign($obj, '1.125');
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for '1.125'");

if(4 > Math::MPFR::MPFR_VERSION_MAJOR ) {
  warn "Skipping tests that rely on mpfr library being at version 4 or later\n";
  done_testing();
  exit 0;
}

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 5e-324]",   "1: subnormal lsd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes after 1st addition of 5e-324");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 1e-323]",   "2: subnormal lsd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes after 2nd addition of 5e-324");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 1.5e-323]", "3: subnormal lsd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes after 3rd addition of 5e-324");

dd_assign($obj, '0');
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 0");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[5e-324 0.0]",   "1: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 5e-324");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1e-323 0.0]",   "2: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 5e-324 * 2");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.5e-323 0.0]", "3: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 5e-324 * 3");

dd_assign($obj, 2 ** -1023);
cmp_ok("$obj", 'eq', "[1.1125369292536007e-308 0.0]", "4: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 2 ** -1023");

$obj /= 2;
cmp_ok("$obj", 'eq', "[5.562684646268003e-309 0.0]", "4: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 2 ** -1024");

$obj /= 2;
cmp_ok("$obj", 'eq', "[2.781342323134e-309 0.0]", "4: subnormal msd stringifies correctly");
cmp_ok(dd_repro_test(dd_repro($obj), $obj), '==', 15, "dd_repro_test passes for 2 ** -1025");

$obj += 2 ** 100;
cmp_ok("$obj", 'eq', "[1.2676506002282294e+30 2.781342323134e-309]", "5: subnormal lsd still stringifies correctly");

$obj -= 2 ** 101;
cmp_ok("$obj", 'eq', "[-1.2676506002282294e+30 2.781342323134e-309]", "sign change handled ok");

# The next test didn't always pass on perls whose nvsize != 8.
# Instead 'long double' and '__float128' builds would fail the
# following mpfr library assertion when dd_stringify() was called:
# round_prec.c:60: MPFR assertion failed: ((prec) >= 1 && (prec) <= ((mpfr_prec_t) ((((mpfr_uprec_t) -1) >> 1) - 256)))
$obj = Math::FakeDD->new(-1.625) + 1.625;
cmp_ok(dd_stringify($obj), 'eq', '[0.0 0.0]', "Math::FakeDD->new(-1.625) + 1.625 stringifies correctly");

done_testing();
