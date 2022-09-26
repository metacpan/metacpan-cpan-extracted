
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok($Math::FakeDD::VERSION, '==', 0.05, "Version number is correct");

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

done_testing();
