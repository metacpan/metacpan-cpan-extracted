#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More;

my @cases = ( pentagonal trapezohedron );

plan tests => 3 * scalar @cases;

for (@cases) {
    is scalar( $_->vertices ), 12;
    is scalar( $_->edges ),    20;
    is scalar( $_->faces ),    10;
}
