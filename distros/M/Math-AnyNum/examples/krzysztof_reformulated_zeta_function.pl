#!/usr/bin/perl

# Formula due to Krzysztof Maslanka

use 5.018;
use strict;
use warnings;

use experimental qw(signatures);

use lib qw(../lib);
use Math::AnyNum qw(:overload);    # can be commented out
use Math::AnyNum qw(gamma binomial zeta factorial);

sub Ak($k) {
    my $sum = 0;
    foreach my $j (0 .. $k) {
        $sum += (-1)**$j * binomial($k, $j) * (2 * $j + 1) * zeta(2 * $j + 2);
    }
    $sum;
}

sub krzysztof_zeta ($s, $r = 100) {
    my $sum = 0;
    foreach my $k (0 .. $r) {
        $sum += (gamma($k + 1 - $s / 2) / gamma(1 - $s / 2)) * (Ak($k) / factorial($k));
    }
    $sum / ($s - 1);
}

say krzysztof_zeta(3);    #=> 1.2020569022705898699637409727804911671219286162
say krzysztof_zeta(5);    #=> 1.0369277551507417486201175962997774385468699839
