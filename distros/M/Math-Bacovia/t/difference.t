#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 21;

use Math::Bacovia qw(Fraction Log Exp Product Difference i);

is(1 - Difference(3, 4), Difference(5, 3));
is(-(1 - Difference(3, 4)), Difference(3, 5));

is(Difference(3, 4)->inv, Fraction(1, Difference(3, 4)));
is(Fraction(3, 4)->neg, Difference(0, Fraction(3, 4)));
is(Difference(1, 2) / Difference(3, 4), Fraction(Difference(1, 2), Difference(3, 4)));

is(Fraction(3, 4) - 5, Fraction(-17, 4));
is(5 - Fraction(3, 4), Difference(5, Fraction(3, 4)));

is(Fraction(Fraction(3, 2), Fraction(4, 12)) - 5, Fraction(Fraction(-4, 24), Fraction(4, 12)));
is(5 - Fraction(Fraction(3, 2), Fraction(4, 12)), Difference(5, Fraction(Fraction(3, 2), Fraction(4, 12))));

is(5 - Fraction(Log(3), Exp(4)), Difference(5, Fraction(Log(3), Exp(4))));
is(Fraction(Log(3), Exp(4)) - 5, Fraction(Difference(Log(3), Product(Exp(4), 5)), Exp(4)));

is(Exp(12) - Fraction(3, 4), Difference(Exp(12), Fraction(3, 4)));
is(Fraction(3, 4) - Exp(12), Difference(Fraction(3, 4), Exp(12)));

#
## Fraction [OP] Difference
#

{    # Addition
    my $res = Fraction(1, 1);
    foreach my $i (1 .. 5) {
        $res += Difference($i, 1);
    }
    is($res, Fraction(Difference(16, 5), 1));
}

{    # Subtraction
    my $res = Fraction(1, 1);
    foreach my $i (1 .. 5) {
        $res -= Difference($i, 1);
    }
    is($res, Fraction(Difference(6, 15), 1));
}

{    # Multiplication
    my $res = Fraction(1, 1);
    foreach my $i (1 .. 5) {
        $res *= Difference($i, i);
    }
    is($res, Fraction(Difference(-90, 190 * i), 1));
}

{    # Division
    my $res = Fraction(1, 1);
    foreach my $i (1 .. 5) {
        $res /= Difference($i, i);
    }
    is($res, Fraction(1, Difference(-90, 190 * i)));
}

#
## Difference [OP] Fraction
#

{    # Addition
    my $res = Difference(13, 5);
    foreach my $i (1 .. 5) {
        $res += Fraction(3, $i);
    }
    is($res, Difference(Fraction(2382, 120), 5));
}

{    # Subtraction
    my $res = Difference(13, 5);
    foreach my $i (1 .. 5) {
        $res -= Fraction(3, $i);
    }
    is($res, Difference(13, Fraction(1422, 120)));
}

{    # Multiplication
    my $res = Difference(13, 5);
    foreach my $i (1 .. 5) {
        $res *= Fraction(3, $i);
    }
    is($res, Difference(Fraction(3159, 120), Fraction(1215, 120)));
}

{    # Division
    my $res = Difference(13, 5);
    foreach my $i (1 .. 5) {
        $res /= Fraction(3, $i);
    }
    is($res, Fraction(Difference(1560, 600), Fraction(243, 1)));
}
