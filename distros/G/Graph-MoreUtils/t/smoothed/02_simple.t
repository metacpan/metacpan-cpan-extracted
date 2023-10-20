#!/usr/bin/perl

use strict;
use warnings;

use Graph::MoreUtils qw( smooth );
use Graph::Undirected;
use Test::More tests => 8;

my( $g, @edges );

# Path of three vertices, one edge has an attribute

$g = Graph::Undirected->new;
$g->add_path( 'A'..'Z' );

smooth( $g );

is( $g->vertices, 2 );
is( $g->edges, 1 );
is( join( ',', @{$g->get_edge_attribute( 'A', 'Z', 'intermediate' )} ),
    join( ',', 'B'..'Y' ) );

$g = Graph::Undirected->new;
$g->add_path( 'Z', 'B'..'Y', 'A' );

smooth( $g );

is( $g->vertices, 2 );
is( $g->edges, 1 );
is( join( ',', @{$g->get_edge_attribute( 'A', 'Z', 'intermediate' )} ),
    join( ',', reverse 'B'..'Y' ) );

$g = Graph::Undirected->new;
$g->add_edges( [ 'A', 'B' ], [ 'B', 'C' ], [ 'C', 'A' ] );

smooth( $g );

is( $g->vertices, 3 );
is( $g->edges, 3 );
