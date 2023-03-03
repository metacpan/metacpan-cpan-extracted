#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More;

eval 'use Graph::Nauty qw(orbits)';
plan skip_all => 'no Graph::Nauty' if $@;

my @cases = (
    [  1,  1,  1,  1, '', trigonal pyramid ],
    [ '',  1, '', '', '', square pyramid ],
    [  1, '', '', '', '', truncated icosahedron ],
    [  1,  1, '', '',  1, rectified octahedron ],
);

plan tests => 5 * scalar @cases;

for my $case (@cases) {
    my( $is_isogonal, $is_isotoxal, $is_isohedral, $is_regular, $is_quasiregular, $figure ) = @$case;
    is $figure->is_isogonal,     $is_isogonal;
    is $figure->is_isotoxal,     $is_isotoxal;
    is $figure->is_isohedral,    $is_isohedral;
    is $figure->is_regular,      $is_regular;
    is $figure->is_quasiregular, $is_quasiregular;
}
