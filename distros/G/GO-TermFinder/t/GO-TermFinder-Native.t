#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use Test;
BEGIN { plan tests => 15 };

# File       : GO-TermFinder-Native.t
# Author     : Ihab A.B. Awad
# Date Begun : October 13th 2004

# $Id: GO-TermFinder-Native.t,v 1.2 2007/03/18 01:37:14 sherlock Exp $

# This file tests the native math functions in module GO::TermFinder::Native.

use GO::TermFinder::Native;

$| = 1;

my $d = GO::TermFinder::Native::Distributions->new(8192);

# check that the logfactorial is okay

# first calculate factorials from 0 through 10

my @factorials = (1, 1); # initialize for 0 and 1

for (my $i = 2; $i <= 10; $i++){

    $factorials[$i] = $factorials[$i-1] * $i;

}

# now check them against the log values from the Distributions object

for (my $i = 0; $i <= 10; $i++){

    ok(log($factorials[$i]), $d->logFactorial($i));

}

# now check that the __logNCr method is working correctly

# test that we get the correct value as if 6 had been chosen out of 10,
# given that:
#
#           n!
# nCr =  ---------
#        r! (n-r)!

{ # lexically scope, to prevent collision between this $n and the $n
  # used below

    my $n = 10;
    my $r = 6;

    my $nChooseR = $factorials[$n] / ($factorials[$r] * $factorials[$n-$r]);

    # now check against the log value that the TermFinder will return

    ok($d->logNCr($n, $r), log($nChooseR));

}

# now let's test that the hypergeometric function works correctly
#
# we'll do a simple test for the probability of picking 3 out of 5,
# given that in the population there is 4 out of 10
#
# The calculation is the probability of picking x positives from a
# sample of n, given that there are M positives in a population of N.
#
# The value is calculated as:
#
#       (M choose x) (N-M choose n-x)
# P =   -----------------------------
#               N choose n
#

my $M = 4;
my $N = 10;

my $n = 5;
my $x = 3;

my $a = $factorials[$M] / ($factorials[$x] * $factorials[$M-$x]);
my $b = $factorials[$N - $M] / ($factorials[$n - $x] * $factorials[($N - $M) - ($n - $x)]);
my $c = $factorials[$N] / ($factorials[$n] * $factorials[$N-$n]);

my $probability = ($a * $b) / $c;

ok($probability, $d->hypergeometric($x, $n, $M, $N));

# now we want to check the pvalue using the hypergeometric
#
# the pvalue is the probability of getting x or more from a sample of
# n, given M positives in a population of N
#
# We'll use the same example as above, and calculate the pvalue for 3
# of 5, given 4 of 10 in the population

my $pvalue = 0;

for (my $i = $x; $i <= $n; $i++){

    my $a = $factorials[$M] / ($factorials[$i] * $factorials[$M-$i]);
    my $b = $factorials[$N - $M] / ($factorials[$n - $i] * $factorials[($N - $M) - ($n - $i)]);
    my $c = $factorials[$N] / ($factorials[$n] * $factorials[$N-$n]);

    my $probability = ($a * $b) / $c;

    $pvalue += $probability;

}

# because the GO::TermFinder::Native::Distributions module uses log
# space internally to calculate factorials and nChooseR, it is not as
# precise as this test-suite.  Thus we need to reduce the precision a
# little.
#
# Should get GO::TermFinder to use BigInt sometime....

$pvalue = sprintf("%.8f", $pvalue);

my $test = sprintf("%.8f", $d->pValueByHypergeometric($x, $n, $M, $N));

ok($pvalue, $test);

$pvalue = 0;

for (my $i = 0; $i < $x; $i++){

    my $a = $factorials[$M] / ($factorials[$i] * $factorials[$M-$i]);
    my $b = $factorials[$N - $M] / ($factorials[$n - $i] * $factorials[($N - $M) - ($n - $i)]);
    my $c = $factorials[$N] / ($factorials[$n] * $factorials[$N-$n]);

    my $probability = ($a * $b) / $c;

    $pvalue += $probability;

}

$pvalue = 1 - $pvalue;

$pvalue = sprintf("%.8f", $pvalue);

ok($pvalue, $test);

