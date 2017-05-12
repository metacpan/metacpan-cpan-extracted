#!/usr/bin/perl

#
## http://rosettacode.org/wiki/Arithmetic-geometric_mean/Calculate_Pi#Perl
#

use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum;

my $digits = shift || 100;    # Get number of digits from command line
print agm_pi($digits), "\n";

sub agm_pi {
    my $digits = shift;

    my $acc = $digits + 8;
    local $Math::BigNum::PREC = 4 * $digits;

    my $HALF = Math::BigNum->new('0.5');
    my ($an, $bn, $tn, $pn) = (Math::BigNum->one, $HALF->sqrt, $HALF->mul($HALF), Math::BigNum->one);
    while ($pn < $acc) {
        my $prev_an = $an->copy;
        $an->badd($bn)->bmul($HALF);
        $bn->bmul($prev_an)->bsqrt;
        $prev_an->bsub($an);
        $tn->bsub($pn * $prev_an * $prev_an);
        $pn->badd($pn);
    }
    $an->badd($bn);
    $an->bmul($an)->bdiv(4 * $tn);
    return $an->as_float($digits);
}
