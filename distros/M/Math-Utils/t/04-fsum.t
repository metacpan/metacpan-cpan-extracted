#!perl
use 5.010001;
use strict;
use warnings;
use Test::More tests => 3;

use Math::Utils qw(:utility :compare);

my $fltcmp = generate_fltcmp(1e-5);
my $sum;

$sum = fsum(0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
#diag($sum);
ok(&$fltcmp($sum, 1) == 0, "fsum() of 10 0.1s");

$sum = fsum(10000, 3.14159, 2.71828);
#diag($sum);
ok(&$fltcmp($sum, 10005.85987) == 0, "fsum() of 10000, 3.14159, 2.71828");

$sum = fsum(10000, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1);
#diag($sum);
ok(&$fltcmp($sum, 10001) == 0, "fsum() of 1000 plus 10 0.1s");

