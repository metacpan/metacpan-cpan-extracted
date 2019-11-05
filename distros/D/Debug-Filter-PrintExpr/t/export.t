#!perl -T
use strict;
use warnings;
use utf8;

use Debug::Filter::PrintExpr {nofilter => 1}, qw(isstring isnumeric);
use Test2::V0;
use Scalar::Util qw(dualvar);

my $alphastr = "lkdfj";
ok(isstring($alphastr), 'alphastr is a string');
ok(!isnumeric($alphastr), 'alphastr is not a number');

my $intstr = "1234";
ok(isstring($intstr), 'intstr is a string');
ok(!isnumeric($intstr), 'intstr is not a number');

my $fpstr = "3.1415926";
ok(isstring($fpstr), 'fpstr is a string');
ok(!isnumeric($fpstr), 'fpstr is not a number');

my $int = 1234;
ok(!isstring($int), 'int is not a string');
ok(isnumeric($int), 'int is a number');

my $fp = 3.1415926;
ok(!isstring($fp), 'fp is not a string');
ok(isnumeric($fp), 'fp is a number');

my $dual = dualvar(3.1415926, "Pi");
ok(isstring($dual), 'dual is a string');
ok(isnumeric($dual), 'dual is a number');

my $ref = {};
ok(!isstring($ref), 'ref is not a string');
ok(!isnumeric($ref), 'ref is not a number');

done_testing;
