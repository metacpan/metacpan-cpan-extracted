#!/usr/bin/perl

# Code from:
#   http://www.perlmonks.org/?node_id=992580

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum;

my $digits = int($ARGV[0] // 0) || 60;

{
    say "Newton iteration, using Taylor series of sine and cosine.";
    local $Math::AnyNum::PREC = log(10)/log(2) * $digits;
    my $b = Math::AnyNum->new(0);
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
            $m = $m->round(-$digits);
        }
        $x += (0.5 - $s) / $c;
        $x = $x->round(-$digits);
    }
    say "pi = " . (6 * $x);
}

{
    say "Using Taylor series of arctangent.";
    local $Math::AnyNum::PREC = log(10)/log(2) * $digits;
    my $b = Math::AnyNum->new(0);
    my $x = 2 - sqrt($b + 3);
    my $f = -$x * $x;
    my $m = $x * ($b + 12);
    my $a = $m;
    my $k = 1;
    while (0 != $m) {
        $m *= $f;
        $k += 2;
        $a += $m / $k;
        $m = $m->round(-$digits);
    }
    $a = $a->round(-$digits);
    say "pi = $a";
}
