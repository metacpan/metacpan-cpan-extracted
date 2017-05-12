#!/usr/bin/perl

use Test::More tests => 261;

use strict;
use warnings;

BEGIN { $Math::Vector::Real::dont_use_XS = 1 }
use Math::Vector::Real;

BEGIN {
    for (qw(box
            sum
            dist2_to_box
            max_dist2_to_box
            max_dist2_between_boxes)) {
        eval "package Math::Vector::Real; *pp_$_ = \\&$_";
        is ($@, '', "installing pp doesn't fail for $_");
    }
}

use Math::Vector::Real::XS;
use Math::Vector::Real::Test qw(eq_vector eq_vector_norm);

for my $dim (1, 2, 3, 10) {
    for my $n (1, 2, 4, 8, 16, 32, 64, 128) {

        my $o = V(map rand(), 1..$dim);
        my @v = map V(map rand(), 1..$dim), 1..$n;
        eq_vector(Math::Vector::Real->sum(@v),
                  Math::Vector::Real->pp_sum(@v),
                  "sum dim: $dim, n: $n");

        eq_vector($o->sum(@v),
                  $o->pp_sum(@v),
                  "v->sum dim: $dim, n: $n");

        for my $c (0..1) {
            eq_vector((Math::Vector::Real->box(@v))[$c],
                      (Math::Vector::Real->pp_box(@v))[$c],
                      "box dim: $dim, n: $n, c: $c");

            eq_vector(($o->box(@v))[$c],
                      ($o->pp_box(@v))[$c],
                      "v->box dim: $dim, n: $n, c: $c");
        }

        eq_vector([$o->dist2_to_box(@v)],
                  [$o->pp_dist2_to_box(@v)],
                  "v->dist2_to_box dim: $dim, n: $n");

        eq_vector([$o->max_dist2_to_box(@v)],
                  [$o->pp_max_dist2_to_box(@v)],
                  "v->max_dist2_to_box dim: $dim, n: $n");
    }
}

