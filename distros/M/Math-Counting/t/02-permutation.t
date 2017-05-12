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
my $f1  = qr/^1\.40500612e\+0?51$/;
my $f2  = qr/^1\.08888695e\+0?28$/;
my $p1  = qr/^1\.07443118e\+0?39$/;
my $p2  = qr/^4\.43426488e\+0?38$/;
my $p3  = qr/^1\.31002051e\+0?60$/;
my $p4  = qr/^6\.72559700e\+0?43$/;
my $p5  = qr/^1\.50130938e\+0?68$/;
my $p6  = qr/^2\.00000000e\+0?00$/;
my $p7  = qr/^9\.00000000e\+0?00$/;
my $p8  = qr/^1\.76214841e\+0?08$/;
my $p9  = qr/^9\.75810738e\+0?31$/;
my $nan = 'NaN';
my $inf = qr/inf/i;

# Permutation without repetition
$x = permutation(-1, 0);
is $x, undef, "-1 P 0";
$x = permutation(0, -1);
is $x, undef, "0 P -1";
$x = permutation(0 - $k, 0 - $n);
is $x, undef, "-$k P -$n";
$x = permutation(0, 0);
cmp_ok $x, '==', 1, "0 P 0";
$x = permutation(0, 1);
cmp_ok $x, '==', 0, "0 P 1";
$x = permutation(1, 0);
cmp_ok $x, '==', 1, "1 P 0";
$x = permutation(1, 1);
cmp_ok $x, '==', 1, "1 P 1";
$x = sprintf $format, permutation($k, $k);
like $x, $f2, "$k P $k";
$x = permutation($k, $n);
cmp_ok $x, '==', 0, "$k P $n";
$x = sprintf $format, permutation($n, $k);
like $x, $p1, "$n P $k";
$x = sprintf $format, permutation($n, $n);
like $x, $f1, "$n P $n";

# Big Permutation without repetition
$x = bperm(0 - $k, 0 - $n);
is $x, $nan, "-$k bperm -$n";
$x = bperm(-1, 0);
is $x, $nan, "-1 bperm 0";
$x = bperm(0, -1);
cmp_ok $x, '==', 1, "0 bperm -1";
$x = bperm(0, 0);
cmp_ok $x, '==', 1, "0 bperm 0";
$x = bperm(0, 1);
is $x, $nan, "0 bperm 1";
$x = bperm(1, 0);
cmp_ok $x, '==', 1, "1 bperm 0";
$x = bperm(1, 1);
cmp_ok $x, '==', 1, "1 bperm 1";
$x = sprintf $format, bperm($k, $k);
like $x, $f2, "$k bperm $k";
$x = bperm($k, $n);
is $x, $nan, "$k bperm $n";
$x = sprintf $format, bperm($n, $k);
like $x, $p1, "$n bperm $k";
$x = sprintf $format, bperm($n, $n);
like $x, $f1, "$n bperm $n";

# Big Permutation with repetition
$x = bperm(0 - $k, 0 - $n, 1);
is $x, $nan, "-$k bperm -$n";
$x = bperm(-1, 0, 1);
cmp_ok $x, '==', 1, "-1 bperm 0";
$x = bperm(0, -1, 1);
like $x, $inf, "0 bperm -1";
$x = bperm(0, 0, 1);
cmp_ok $x, '==', 1, "0 bperm 0";
$x = bperm(0, 1, 1);
cmp_ok $x, '==', 0, "0 bperm 1";
$x = bperm(1, 0, 1);
cmp_ok $x, '==', 1, "1 bperm 0";
$x = bperm(1, 1, 1);
cmp_ok $x, '==', 1, "1 bperm 1";
$x = sprintf $format, bperm($k, $k, 1);
like $x, $p2, "$k bperm $k";
$x = sprintf $format, bperm($k, $n, 1);
like $x, $p3, "$k bperm $n";
$x = sprintf $format, bperm($n, $k, 1);
like $x, $p4, "$n bperm $k";
$x = sprintf $format, bperm($n, $n, 1);
like $x, $p5, "$n bperm $n";

# Derangements
# 0, 1, 2, 9, 44, 265, 1854...
$x = bderange(0);
cmp_ok $x, '==', 1, "derange 0";
$x = bderange(1);
cmp_ok $x, '==', 0, "derange 1";
$x = bderange(2);
cmp_ok $x, '==', 1, "derange 2";
$x = sprintf $format, bderange(3);
like $x, $p6, "derange 3";
$x = sprintf $format, bderange(4);
like $x, $p7, "derange 4";
$x = sprintf $format, bderange(12);
like $x, $p8, "derange 12";
$x = sprintf $format, bderange(30);
like $x, $p9, "derange 30";

done_testing();
