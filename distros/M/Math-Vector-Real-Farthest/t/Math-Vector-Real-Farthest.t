#!/usr/bin/perl

use strict;
use warnings;

#BEGIN { $Math::Vector::Real::dont_use_XS = 1 };

use Math::Vector::Real;
use Math::Vector::Real::Farthest;

use Test::More tests => 300;

for my $test (0..99) {
    my $dim = 1 + int rand 10;
    my $size = 1 + int(2 ** rand 10);
    my $id = "(dim: $dim, size: $size)";
    # diag $id;
    my @v = map { V(map rand, 1..$dim) } 1..$size;
    my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@v);
    my ($d2bf, $v0bf, $v1bf) = Math::Vector::Real::Farthest->find_brute_force(@v);
    is ($d2, $d2bf, "d2 $id") or diag "v0: $v0, v1: $v1, v0bf: $v0bf, v1bf: $v1bf";
    is (Math::Vector::Real::dist2($v0, $v1), $d2, "vs are at the correct distance $id");
    is (Math::Vector::Real::dist2($v0bf, $v1bf), $d2bf, "bf vs are at the correct distance $id");
}

