#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Test::More tests => 10;

my $cupola5 = pentagonal cupola;
is scalar( $cupola5->vertices ), 15, 'vertices';
is scalar( $cupola5->edges ),    25, 'edges';
is scalar( $cupola5->faces ),    12, 'faces';

my $rotunda5 = pentagonal rotunda;
is scalar( $rotunda5->vertices ), 20, 'vertices';
is scalar( $rotunda5->edges ),    35, 'edges';
is scalar( $rotunda5->faces ),    17, 'faces';

my $orthobicupola5 = pentagonal orthobicupola;
is scalar( $orthobicupola5->vertices ), 20, 'vertices';
is scalar( $orthobicupola5->edges ),    40, 'edges';
is scalar( $orthobicupola5->faces ),    22, 'faces';

is join( ',', sort map { scalar @$_ } $orthobicupola5->faces ),
   '3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5';
