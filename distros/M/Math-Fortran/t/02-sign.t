#!perl -T
use 5.008003;
use strict;
use warnings;
use Test::More tests => 6;

use Math::Fortran qw(sign);

my $sn = sign(-12);
ok($sn == -1, "sign(-12) returned $sn");

$sn = sign(12);
ok($sn == 1, "sign(12) returned $sn");

$sn = sign(0);
ok($sn == 1, "sign(0) returned $sn");

$sn = sign(-12, 5);
ok($sn == 12, "sign(-12, 5) returned $sn");

$sn = sign(12, -5);
ok($sn == -12, "sign(12, -5) returned $sn");

$sn = sign(-12, 0);
ok($sn == 12, "sign(-12, 0) returned $sn");

