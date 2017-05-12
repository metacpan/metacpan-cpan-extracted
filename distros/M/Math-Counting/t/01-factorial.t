#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok 'Math::Counting', qw(:student :big);

# This is not the most rigorous test.
# 42 is the magic constant of the smallest magic cube composed with
# the numbers 1 to 27.  And 27 is the first odd perfect cube, apart
# from the number 1.

my $format = '%.8e'; # scientific notation.
my $x;
my $n   = 42;
my $k   = 27;
my $f3  = 171;
my $f4  = '1.24101807e+309';
my $f5  = '1241018070217667823424840524103103992616605577501693185388951803611996075221691752992751978120487585576464959501670387052809889858690710767331242032218484364310473577889968548278290754541561964852153468318044293239598173696899657235903947616152278558180061176365108428800000000000000000000000000000000000000000';
my $f1  = qr/^1\.40500612e\+0?51$/;
my $f2  = qr/^1\.08888695e\+0?28$/;
my $nan = 'NaN';
my $inf = qr/inf/i;

# Factorial
$x = factorial();
is $x, undef, "undef!";
$x = factorial(-1);
is $x, undef, "-1!";
$x = factorial(0);
cmp_ok $x, '==', 1, "0!";
$x = factorial(1);
cmp_ok $x, '==', 1, "1!";
$x = factorial(2);
cmp_ok $x, '==', 2, "2!";
$x = sprintf $format, factorial($k);
like $x, $f2, "$k!";
$x = sprintf $format, factorial($n);
like $x, $f1, "$n!";
$x = factorial($f3);
# Pass on machines that are "differently-abled" with infinity.
if ( $x =~ $inf ) {
    like $x, $inf, "$f3! == $x ($^O)";
    diag("OS_ERROR: $^E") if $^E;
}
else {
    # Reformat the result in scientific notation.
    my $y = sprintf $format, $x;
    ok $x eq $f5 || $y eq $f4, "$f3! == $x";
}

# Big Factorial
$x = bfact(-1);
is $x, $nan, "-1!";
$x = bfact(0);
cmp_ok $x, '==', 1, "0!";
$x = bfact(1);
cmp_ok $x, '==', 1, "1!";
$x = bfact(2);
cmp_ok $x, '==', 2, "2!";
$x = sprintf $format, bfact($k);
like $x, $f2, "$k!";
$x = sprintf $format, bfact($n);
like $x, $f1, "$n!";
$x = bfact($f3);
# Pass on machines that are "differently-abled" with infinity.
if ( $x =~ $inf ) {
    like $x, $inf, "$f3! == $x ($^O)";
    diag("OS_ERROR: $^E") if $^E;
}
else {
    # Sometimes sprintf itself can't handle giant numbers!
    my $y = sprintf $format, $x;
    ok $x eq $f5 || $y eq $f4, "$f3! == $x";
}

done_testing();
