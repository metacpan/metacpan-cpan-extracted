#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More;

my @cases = ( rectified tetragonal prism,
              rectified octahedron );

plan tests => 3 * scalar @cases;

for (@cases) {
    is scalar( $_->vertices ), 12, 'vertices';
    is scalar( $_->edges ),    24, 'edges';
    is scalar( $_->faces ),    14, 'faces';
}
