#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 8;

use Math::Utils qw(:utility);

my @f;
my $fstr;

ok(floor(1.5) == 1, "floor(1.5)");
ok(floor(-1.5) == -2, "floor(-1.5)");
ok(ceil(1.5) == 2, "ceil(1.5)");
ok(ceil(-1.5) == -1, "ceil(-1.5)");

@f = floor(1.5, 1.87, 1);
$fstr = join(", ", @f);
ok($fstr eq "1, 1, 1", "floor(1.5, 1.87, 1) returned $fstr");

@f = floor(-1.5, -1.87, -1);
$fstr = join(", ", @f);
ok($fstr eq "-2, -2, -1", "floor(-1.5, -1.87, -1) returned $fstr");

@f = ceil(1.5, 1.87, 1);
$fstr = join(", ", @f);
ok($fstr eq "2, 2, 1", "ceil(1.5, 1.87, 1) returned $fstr");

@f = ceil(-1.5, -1.87, -1);
$fstr = join(", ", @f);
ok($fstr eq "-1, -1, -1", "ceil(-1.5, -1.87, -1) returned $fstr");

