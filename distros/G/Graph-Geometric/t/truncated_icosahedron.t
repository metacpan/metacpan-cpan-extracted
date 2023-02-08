#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More;

my @cases = ( truncated icosahedron );

plan tests => 4 * scalar @cases;

for (@cases) {
    is scalar( $_->vertices ), 60;
    is scalar( $_->edges ), 90;
    is scalar( $_->faces ), 32;

    is join( ',', sort map { scalar @$_ } $_->faces ), '5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6';
}
