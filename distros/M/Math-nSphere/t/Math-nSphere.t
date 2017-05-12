#!/usr/bin/perl

use strict;
use warnings;

use Math::nSphere qw(nsphere_surface nsphere_volumen);

use Test::More tests => 39;

my $PI = 3.14159;

sub is_we { # we => with some tolerable error
    my $tb = Test::More->builder;
    my ($a, $b, $name) = @_;
    if (defined $a) {
        if ($b) {
            if (abs($a - $b) / (abs($a) + abs($b)) < 0.001) {
                $tb->ok(1, $name);
            }
            else {
                $tb->is_num($a, $b, $name)
            }
        }
        else {
            $tb->is_num($a, $b, $name)
        }
    }
    else {
        $tb->ok(0, $name);
    }
}

is_we(nsphere_volumen(0), 0, "V0");
is_we(nsphere_volumen(1), 2, "V1");
is_we(nsphere_volumen(2), 3.14159, "V2");
is_we(nsphere_volumen(3), 4.18879, "V3");
is_we(nsphere_volumen(4), 4.93480, "V4");
is_we(nsphere_volumen(5), 5.26379, "V5");
is_we(nsphere_volumen(6), 5.16771, "V6");
is_we(nsphere_volumen(7), 4.72477, "V7");
is_we(nsphere_volumen(8), 4.05871, "V8");

for (reverse 1..30) {
    is_we(nsphere_surface($_ + 1), 2 * $PI * nsphere_volumen($_), "surface $_ + 1");
}
