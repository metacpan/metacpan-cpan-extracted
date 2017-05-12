#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok 'Math::Counting', qw(:student :big);

# This is not the most rigorous test.
# 42 is the magic constant of the smallest magic cube composed with
# the numbers 1 to 27.  And 27 is the first odd perfect cube, apart
# from the number 1.

my $format = '%.8e';
my $x;
my $n   = 42;
my $k   = 27;
my $c1  = qr/^9\.73469713e\+0?14$/;
my $c2  = qr/^4\.37683992e\+0?18$/;
my $c3  = qr/^6\.80841765e\+0?18$/;
my $c4  = qr/^8\.39455243e\+0?23$/;
my $c5  = qr/^9\.86724276e\+0?10$/;
my $nan = 'NaN';

# Combination without repetition
$x = combination(0 - $n, 0 - $k);
is $x, undef, "-$n C -$k";
$x = combination(-1, 0);
is $x, undef, "-1 C 0";
$x = combination(0, -1);
is $x, undef, "0 C -1";
$x = combination(0, 0);
cmp_ok $x, '==', 1, "0 C 0";
$x = combination(0, 1);
cmp_ok $x, '==', 0, "0 C 1";
$x = combination(1, 0);
cmp_ok $x, '==', 1, "1 C 0";
$x = combination(1, 1);
cmp_ok $x, '==', 1, "1 C 1";
$x = combination($k, $k);
cmp_ok $x, '==', 1, "$k C $k";
$x = combination($k, $n);
cmp_ok $x, '==', 0, "$k C $n";
$x = sprintf $format, combination($n, $k);
like $x, $c5, "$n C $k";
$x = combination($n, $n);
cmp_ok $x, '==', 1, "$n C $n";

# Big Combination without repetition
$x = bcomb(0 - $n, 0 - $k);
is $x, $nan, "-$n bcomb -$k";
$x = bcomb(-1, 0);
is $x, $nan, "-1 bcomb 0";
$x = bcomb(0, -1);
is $x, $nan, "0 bcomb -1";
$x = bcomb(0, 0);
cmp_ok $x, '==', 1, "0 bcomb 0";
$x = bcomb(0, 1);
is $x, $nan, "0 bcomb 1";
$x = bcomb(1, 0);
cmp_ok $x, '==', 1, "1 bcomb 0";
$x = bcomb(1, 1);
cmp_ok $x, '==', 1, "1 bcomb 1";
$x = bcomb($k, $k);
cmp_ok $x, '==', 1, "$k bcomb $k";
$x = bcomb($k, $n);
is $x, $nan, "$k bcomb $n";
$x = sprintf $format, bcomb($n, $k);
like $x, $c5, "$n bcomb $k";
$x = bcomb($n, $n);
cmp_ok $x, '==', 1, "$n bcomb $n";

# Big Combination with repetition
$x = bcomb(0 - $n, 0 - $k, 1);
is $x, $nan, "-$n bcomb -$k";
$x = bcomb(-1, 0, 1);
is $x, $nan, "-1 bcomb 0";
$x = bcomb(0, -1, 1);
is $x, $nan, "0 bcomb -1";
$x = bcomb(0, 0, 1);
is $x, $nan, "0 bcomb 0";
$x = bcomb(0, 1, 1);
is $x, $nan, "0 bcomb 1";
$x = bcomb(1, 0, 1);
cmp_ok $x, '==', 1, "1 bcomb 0";
$x = bcomb(1, 1, 1);
cmp_ok $x, '==', 1, "1 bcomb 1";
$x = sprintf $format, bcomb($k, $k, 1);
like $x, $c1, "$k bcomb $k";
$x = sprintf $format, bcomb($k, $n, 1);
like $x, $c2, "$k bcomb $n";
$x = sprintf $format, bcomb($n, $k, 1);
like $x, $c3, "$n bcomb $k";
$x = sprintf $format, bcomb($n, $n, 1);
like $x, $c4, "$n bcomb $n";

done_testing();
