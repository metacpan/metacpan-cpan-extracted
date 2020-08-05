#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::Revhash qw( revhash revunhash );

plan tests => 10;

eval { revhash() } or ok($@ =~ /not defined/, "data not defined");
eval { revhash(0, 1) } or ok($@ =~ /out of range/, "data out of range");
eval { revhash(-1, 1) } or ok($@ =~ /out of range/, "data out of range");
eval { revhash(1, -1) } or ok($@ =~ /invalid length/i, "invalid length");
eval { revhash(1, 0) } or ok($@ =~ /invalid length/i, "invalid length");
eval { revhash(1) } or ok($@ =~ /invalid length/i, "invalid length");
eval { revhash(1, 1, 0) } or ok($@ =~ /A.*invalid/, "A value");
eval { revhash(1, 10) } or ok($@ =~ /A.*undefined/, "A value");
eval { revhash(1, 1, 1, 0) } or ok($@ =~ /B.*invalid/, "B value");
eval { revhash(1, 10, 20) } or ok($@ =~ /invalid.*B value/i, "B value");
