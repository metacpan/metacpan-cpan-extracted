#!/usr/bin/perl

use strict;
use warnings;
use Graph::MoreUtils qw( line );
use Graph::Undirected;
use Test::More tests => 5;

my $g = Graph::Undirected->new( multiedged => 1 );
$g->add_edges( [ 'A', 'B' ], [ 'A', 'B' ] );

is( $g->vertices, 2 );
is( $g->edges, 2 );

my $l = line( $g );

is( $l->vertices, 2 );
is( $l->edges, 1 );
is( (grep { $l->degree( $_ ) == 1 } $l->vertices), 2 );
