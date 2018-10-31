#!perl
use 5.010001;
use strict;
use warnings;
use Test::More tests => 12;

use Math::Utils qw(sign copysign);

my($sn, $snjoin);

$sn = sign(-12);
ok($sn == -1, "sign(-12) returned $sn");

$sn = sign(12);
ok($sn == 1, "sign(12) returned $sn");

$sn = sign(0);
ok($sn == 0, "sign(0) returned $sn");

$snjoin = join("", sign(-12, 5));
ok($snjoin eq "-11", "sign(-12, 5) returned $snjoin");

$snjoin = join("", sign(12, -5));
ok($snjoin eq "1-1", "sign(12, -5) returned $snjoin");

$snjoin = join("", sign(-12, 0, 2, 9, 0.5, -0.5));
ok($snjoin eq "-10111-1", "sign(-12, 0, 2, 9, 0.5, -0.5) returned $snjoin");


$sn = copysign(-12);
ok($sn == -1, "copysign(-12) returned $sn");

$sn = copysign(12);
ok($sn == 1, "copysign(12) returned $sn");

$sn = copysign(0);
ok($sn == 1, "copysign(0) returned $sn");

$sn = copysign(-12, 5);
ok($sn == 12, "copysign(-12, 5) returned $sn");

$sn = copysign(12, -5);
ok($sn == -12, "copysign(12, -5) returned $sn");

$sn = copysign(-12, 0);
ok($sn == 12, "copysign(-12, 0) returned $sn");

