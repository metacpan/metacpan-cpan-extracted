#!/usr/bin/perl

# Approximate nth-roots using Newton's method.

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(:overload approx_cmp);

sub nth_root {
    my ($n, $x) = @_;

    my $r = 0.0;
    my $m = 1.0;

    until (approx_cmp($m, $r) == 0) {
        $r = $m;
        $m = (($n - 1) * $r + $x / $r**($n - 1)) / $n;
    }

    return $r;
}

say nth_root(2,  2);
say nth_root(3,  125);
say nth_root(7,  42**7);
say nth_root(42, 987**42);
