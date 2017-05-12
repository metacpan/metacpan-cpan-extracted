#!/usr/bin/perl

#
## http://rosettacode.org/wiki/Arithmetic-geometric_mean/Calculate_Pi#Perl
#

use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum;

my $digits = shift || 100;    # Get number of digits from command line

sub agm_pi {
    my $digits = shift;

    my $acc = $digits + 8;
    local $Math::AnyNum::PREC = 4 * $digits;

    my $HALF = Math::AnyNum->new_f(0.5);
    my $ONE  = Math::AnyNum->new_ui(1);
    my ($an, $bn, $tn, $pn) = ($ONE, sqrt($HALF), $HALF * $HALF, $ONE);
    while ($pn < $acc) {
        my $prev_an = $an;
        $an += $bn;
        $an /= 2;
        $bn *= $prev_an;
        $bn = sqrt($bn);
        $prev_an -= $an;
        $tn -= $pn * $prev_an * $prev_an;
        $pn += $pn;
    }
    $an += $bn;
    $an *= $an;
    $an /= (4 * $tn);
    return "$an";
}

print agm_pi($digits), "\n";
