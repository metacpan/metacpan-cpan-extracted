#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use Math::BigNum qw(:constant);

my $ln_ev = -7 / (10**17);
my $ev = exp($ln_ev);

is(sprintf('%0.5f', $ev),       '1.00000', '($ev) is approx. 1');
is(sprintf('%0.5f', 1 - $ev),   '0.00000', '(1-$ev) is approx. 0');
is(sprintf('%0.5f', 1 - "$ev"), '0.00000', '(1-"$ev") is approx. 0');

cmp_ok($ev, '!=', 0, '$ev should not equal 0');
