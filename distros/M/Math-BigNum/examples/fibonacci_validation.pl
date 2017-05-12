#!/usr/bin/perl

# Fibonacci tests

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum qw(:constant);

my $S = sqrt(1.25) + 0.5;
my $T = sqrt(1.25) - 0.5;
my $W = $S + $T;            #=> sqrt(5);

my @fib_pos_funcs = (

    #\&fib_pos1,            # requires complex numbers
    \&fib_pos2,

    #\&fib_pos3,            # requires complex numbers
    #\&fib_pos4,            # requires complex numbers
    \&fib_pos5
);

# Returns the nth Fibonacci number
sub fib {
    my ($n) = @_;
    (($S**$n - (-$T)**$n) / $W)->round(0);
}

# Returns true if a given number if the nth-Fibonacci number
sub is_fib {
    my ($i, $fib) = @_;
    ((($fib * $W) + (-$T)**$i)->log($S)->round(-$i / 4)) == $i;
}

# Returns true if a given number is probably a Fibonacci number
sub is_prob_fib {
    my ($n) = @_;
    fib($fib_pos_funcs[rand @fib_pos_funcs]->($n)) == $n;
}

#
## log(n*sqrt(5) + (((1-sqrt(5))/2) ^ ((log(n)+(log(5))/2) / (log(1+sqrt(5))-log(2))))) / (log(1+sqrt(5))-log(2))
#
sub fib_pos1 {
    my ($n) = @_;
    ($W * $n + $T->neg->pow(log(5 * $n**2) / ($W + 1)))->log($S)->round(0);
}

#
## (log((2/(sqrt(5)-1))^(log((1+sqrt(5))/(5 * n^2)))+sqrt(5)*n))/(log(1/2 (1+sqrt(5))))
#
sub fib_pos2 {
    my ($n) = @_;
    ($W * $n + (2 / ($W - 1))->pow(log((1 + $W) / (5 * $n**2))))->log((1 + $W) / 2)->round(0);
}

#
## (log(n*sqrt(5) + (((1-sqrt(5))/2) ^ (log(n * sqrt(5)) / log((1+sqrt(5))/2))))) / log((1+sqrt(5))/2)
#
sub fib_pos3 {
    my ($n) = @_;
    (($n * $W) + (-$T)**((($n * $W))->log($S)))->log($S)->round(0);
}

#
## log((W*n + ((-T)**((log(n) + log(5)/2) / S)))) / log(S)
#
sub fib_pos4 {
    my ($n) = @_;
    (
     log(($S + $T) * $n + ((0.5 * (1 - ($S + $T)))**((log($n) + (log(5) / 2)) / (log(1 + ($S + $T)) - log(2))))) /
       (log(1 + ($S + $T)) - log(2)))->round(0);
}

#
## log(n*sqrt(5)) / log(PHI)
#
sub fib_pos5 {
    my ($n) = @_;
    ($n * sqrt(5))->log($S)->round(0);
}

foreach my $group (
                   [12,  144,                   1],
                   [12,  143,                   0],
                   [12,  145,                   0],
                   [13,  233,                   1],
                   [49,  1337,                  0],
                   [32,  2178309,               1],
                   [100, 354224848179261915074, 0],
                   [100, 354224848179261915076, 0],
                   [100, 354224848179261915075, 1],
  ) {
    my ($pos, $num, $bool) = @{$group};

    is_fib($pos, $num) == $bool or say "Validation error (1)!";
    is_prob_fib($num) == $bool or say "Validation error (2)!";

    $fib_pos_funcs[rand @fib_pos_funcs]->($num) == $fib_pos_funcs[rand @fib_pos_funcs]->($num)
      or say "Error in rand pos 1";

    if ($bool) {
        $fib_pos_funcs[rand @fib_pos_funcs]->($num) == $pos
          or say "Error in rand pos 2";
    }

    printf("%21s is on position %3s in the fibonacci sequence: %s\n", $num, $pos, $bool);
}
