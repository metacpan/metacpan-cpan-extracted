#!/usr/bin/perl

# Find the position of a Fibonacci number in the Fibonacci sequence.

# See also:
#   https://en.wikipedia.org/wiki/Fibonacci_number#Recognizing_Fibonacci_numbers

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload fibonacci is_square isqrt phi round);

sub fibonacci_inverse ($n) {

    my $m = 5 * $n * $n;

    if (is_square($m - 4)) {
        $m = isqrt($m - 4);
    }
    elsif (is_square($m + 4)) {
        $m = isqrt($m + 4);
    }
    else {
        return -1;    # not a Fibonacci number
    }

    round(log(($n * sqrt(5) + $m) / 2) / log(phi));
}

foreach my $n(3..20) {

    my $fib   = fibonacci($n);
    my $index = fibonacci_inverse($fib);

    die "error: $index != $n" if ($index != $n);
    say "F($index) = $fib";
}

die "error" if fibonacci_inverse(fibonacci(1000)) != 1000;
die "error" if fibonacci_inverse(fibonacci(1001)) != 1001;
die "error" if fibonacci_inverse(fibonacci(1002)) != 1002;
die "error" if fibonacci_inverse(fibonacci(1003)) != 1003;
