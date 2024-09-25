#!/usr/bin/perl

use strict;
use warnings;

use Graph::Grammar;
use Graph::Undirected;
use Test::More;

my @rules = (
    [ 'delete red nodes',
      sub { 1 }, EDGE { $_[0]->get_edge_attribute( $_[1], $_[2], 'color' ) eq 'red' }, sub { 1 },
      sub { $_[0]->delete_edge( $_[1], $_[2] ) } ],
);

plan tests => 1;

my $g = Graph::Undirected->new;
$g->add_cycle( 1..6 );
for ($g->edges) {
    $g->set_edge_attribute( @$_, 'color', 'black' );
}

$g->set_edge_attribute( 1, 2, 'color', 'red' );
$g->set_edge_attribute( 3, 4, 'color', 'red' );
$g->set_edge_attribute( 5, 6, 'color', 'red' );

parse_graph( $g, @rules );
is scalar $g->edges, 3;
