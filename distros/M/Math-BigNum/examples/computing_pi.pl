#!/usr/bin/perl

# Code from:
#   http://www.perlmonks.org/?node_id=992580

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum;

my $digits = int($ARGV[0] // 0) || 60;

{
    say "Newton iteration, using Taylor series of sine and cosine.";
    local $Math::BigNum::PREC = 4 * $digits;
    my $b = Math::BigNum->new(0);
    my $x = $b + 0.5;
    my %x;
    while (!$x{$x}++) {
        my $m = 1;
        my $s = 0;
        my $c = 1;
        my $k = 0;
        while (0 != $m) {
            $s += $m = $m * $x / ++$k;
            $c += $m = -$m * $x / ++$k;
            $m->bround(-$digits);
        }
        $x += (0.5 - $s) / $c;
        $x->bround(-$digits);
    }
    say "pi = ", (6 * $x)->as_float($digits), ";";
}

{
    say "Using Taylor series of arctangent.";
    local $Math::BigNum::PREC = 4 * $digits;
    my $b = Math::BigNum->new(0);
    my $x = 2 - sqrt($b + 3);
    my $f = -$x * $x;
    my $m = $x * ($b + 12);
    my $a = $m;
    my $k = 1;
    while (0 != $m) {
        $m *= $f;
        $k += 2;
        $a += $m / $k;
        $m->bround(-$digits);
    }
    $a->bround(-$digits);
    say "pi = ", $a->as_float($digits), ";";
}
