#!/usr/bin/perl

# Algorithm from:
#   http://oeis.org/wiki/User:Peter_Luschny/ComputationAndAsymptoticsOfBernoulliNumbers#Seidel

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum;

sub bernoulli_seidel {
    my ($n) = @_;

    state $one  = Math::AnyNum->one;
    state $zero = Math::AnyNum->zero;

    $n == 0 and return $one;
    $n == 1 and return $one / 2;
    $n % 2  and return $zero;

    my @D = ($zero, $one, ($zero) x ($n / 2 - 1));

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            ($D[$_] += $D[$_ - 1]) for (1 .. $h - 1);
        }
        else {
            $w = $h++;
            ($D[$w] += $D[$w + 1]) while --$w;
        }
    }

    my $den = ($one << ($n + 1)) - 2;
    my $num = $D[$h - 1];

    $num = -$num if $n % 4 == 0;
    $num / $den;
}

my $from = shift(@ARGV) // 1;
my $to   = shift(@ARGV) // 50;

foreach my $n ($from .. $to) {
    say "B(", 2 * $n, ") = ", bernoulli_seidel(2 * $n);
}
