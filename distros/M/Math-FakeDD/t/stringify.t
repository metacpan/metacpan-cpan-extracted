use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok($Math::FakeDD::VERSION, '==', 0.08, "Version number is correct");

my $obj = Math::FakeDD->new();

dd_assign($obj, '1.3');

cmp_ok("$obj", 'eq', "[1.3 -4.4408920985006264e-17]", "'1.3' assigns and stringifies correctly");

dd_assign($obj, '1.125');

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 5e-324]",   "1: subnormal lsd stringifies correctly");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 1e-323]",   "2: subnormal lsd stringifies correctly");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.125 1.5e-323]", "3: subnormal lsd stringifies correctly");

dd_assign($obj, '0');

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[5e-324 0.0]",   "1: subnormal msd stringifies correctly");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1e-323 0.0]",   "2: subnormal msd stringifies correctly");

$obj += 2 ** -1074;
cmp_ok("$obj", 'eq', "[1.5e-323 0.0]", "3: subnormal msd stringifies correctly");

dd_assign($obj, 2 ** -1023);
cmp_ok("$obj", 'eq', "[1.1125369292536007e-308 0.0]", "4: subnormal msd stringifies correctly");

$obj /= 2;
cmp_ok("$obj", 'eq', "[5.562684646268003e-309 0.0]", "4: subnormal msd stringifies correctly");

$obj /= 2;
cmp_ok("$obj", 'eq', "[2.781342323134e-309 0.0]", "4: subnormal msd stringifies correctly");

# The next test didn't always pass on perls whose nvsize != 8.
# Instead 'long double' and '__float128' builds would fail the
# following mpfr library assertion when dd_stringify() was called:
# round_prec.c:60: MPFR assertion failed: ((prec) >= 1 && (prec) <= ((mpfr_prec_t) ((((mpfr_uprec_t) -1) >> 1) - 256)))
$obj = Math::FakeDD->new(-1.625) + 1.625;
cmp_ok(dd_stringify($obj), 'eq', '[0.0 0.0]', "Math::FakeDD->new(-1.625) + 1.625 stringifies correctly");

done_testing();
