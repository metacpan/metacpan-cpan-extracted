#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 10 Novermber 2018
# https://github.com/trizen

# A generalized formula with O(sqrt(n)) complexity for computing the partial-sum of `k^m * sigma_j(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} k^m * sigma_j(k)
#
# for any fixed integers m >= 0 and j >= 0.

# Formula:
#   Sum_{k=1..n} k^m * sigma_j(k) =   Sum_{k=1..floor(sqrt(n))} F(m, k) * (F(m+j, floor(n/k)) - F(m+j, floor(n/(k+1))))
#                                   + Sum_{k=1..floor(n/(floor(sqrt(n))+1))} k^(m+j) * F(m, floor(n/k))
#
# where F(n,x) is Faulhaber's formula for `Sum_{k=1..x} k^n`, defined in terms of Bernoulli polynomials as:
#
#   F(n, x) = (Bernoulli(n+1, x+1) - Bernoulli(n+1)) / (n+1)
#
# where Bernoulli(n,x) are the Bernoulli polynomials and Bernoulli(n) is the n-th Bernoulli number.

# See also:
#   https://en.wikipedia.org/wiki/Divisor_function
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#   https://en.wikipedia.org/wiki/Bernoulli_polynomials
#   https://trizenx.blogspot.com/2018/11/partial-sums-of-arithmetical-functions.html

use 5.020;
use strict;
use warnings;

use lib qw(../lib);
use experimental qw(signatures);
use Math::AnyNum qw(isqrt ipow bernoulli faulhaber_sum);

sub faulhaber_partial_sum_of_sigma($n, $m, $j) {      # using Faulhaber's formula

    my $total = 0;

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += faulhaber_sum($k, $m) * (
                  faulhaber_sum(int($n/$k),     $m+$j)
                - faulhaber_sum(int($n/($k+1)), $m+$j)
            );
    }

    for my $k (1 .. $u) {
        $total += ipow($k, $m+$j) * faulhaber_sum(int($n/$k), $m);
    }

    return $total;
}

sub bernoulli_partial_sum_of_sigma($n, $m, $j) {      # using Bernoulli polynomials

    my $total = 0;

    my $s = isqrt($n);
    my $u = int($n / ($s + 1));

    for my $k (1 .. $s) {
        $total += (
                      bernoulli($m+1, $k+1)
                    - bernoulli($m+1)
                  )/($m+1)
                * (
                      bernoulli($m+$j+1, 1+int($n/$k))
                    - bernoulli($m+$j+1, 1+int($n/($k+1)))
                  )/($m+$j+1);
    }

    for my $k (1 .. $u) {
        $total += ipow($k, $m+$j) * (bernoulli($m+1, 1+int($n/$k)) - bernoulli($m+1)) / ($m+1);
    }

    return $total;
}

sub dirichlet_partial_sum_of_sigma ($n, $m, $j) {    # using Dirichlet's hyperbola method

    my $total = 0;
    my $s = isqrt($n);

    for my $k (1 .. $s) {
        $total += ipow($k, $m)    * faulhaber_sum(int($n/$k), $m+$j);
        $total += ipow($k, $m+$j) * faulhaber_sum(int($n/$k), $m);
    }

    $total -= faulhaber_sum($s, $m) * faulhaber_sum($s, $j+$m);

    return $total;
}

for my $m (0..10) {

    my $j = int rand 10;
    my $n = int rand 1000;

    my $t1 = faulhaber_partial_sum_of_sigma($n, $m, $j);
    my $t2 = bernoulli_partial_sum_of_sigma($n, $m, $j);
    my $t3 = dirichlet_partial_sum_of_sigma($n, $m, $j);

    die "error: $t1 != $t2" if ($t1 != $t2);
    die "error: $t1 != $t3" if ($t1 != $t3);

    say "Sum_{k=1..$n} k^$m * sigma_$j(k) = $t2";
}

die "error" if faulhaber_partial_sum_of_sigma(10**8, 0, 2) != "400685641565621401132515";  # Sum_{k=1..10^8} sigma_2(k)

__END__
Sum_{k=1..955} k^0 * sigma_7(k) = 87199595877187457268469
Sum_{k=1..765} k^1 * sigma_5(k) = 22385163976024509818
Sum_{k=1..805} k^2 * sigma_6(k) = 15993292528868648475167542
Sum_{k=1..477} k^3 * sigma_2(k) = 2374273670858643
Sum_{k=1..522} k^4 * sigma_8(k) = 16674413261032779166355164886215351
Sum_{k=1..983} k^5 * sigma_0(k) = 1180528862233337314
Sum_{k=1..293} k^6 * sigma_1(k) = 11217015502565855041
Sum_{k=1..906} k^7 * sigma_7(k) = 15353361004402823613827018815424339863159897
Sum_{k=1..467} k^8 * sigma_2(k) = 25400023350505369496677066803
Sum_{k=1..801} k^9 * sigma_4(k) = 3343390385697199861864437708422750691782
Sum_{k=1..142} k^10 * sigma_8(k) = 4409116061384423423777822848241899183830
