#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More;

my @cases = ( rhombic_dodecahedron );

plan tests => 3 * scalar @cases;

for (@cases) {
    is scalar( $_->vertices ), 14, 'vertices';
    is scalar( $_->edges ),    24, 'edges';
    is scalar( $_->faces ),    12, 'faces';
}
