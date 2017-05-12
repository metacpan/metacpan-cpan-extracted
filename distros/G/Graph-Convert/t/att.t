#!/usr/bin/perl -w

# Test that attributes survive the conversion

use Test::More;
use strict;

BEGIN
   {
   plan tests => 16;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Convert") or die($@);
   };

#############################################################################
# both Graph and Graph::Easy are automatically loaded:

my $g = Graph->new( multiedged => 1 );

is (ref($g), 'Graph');

my $edge = $g->add_edge_get_id( 'Bonn', 'Berlin' );

$g->set_edge_attribute_by_id( 'Bonn', 'Berlin', $edge, 'label', 'by train');
$g->set_vertex_attribute( 'Bonn', 'color', 'red');

my $ge = Graph::Convert->as_graph_easy( $g );

is (scalar $ge->nodes(), 2, '2 nodes');
is (scalar $ge->edges(), 1, '1 edge');
is ($ge->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');

#############################################################################
# edge attributes

my @edges = $ge->edges();

my $e = $edges[0];
is (ref($e), 'Graph::Easy::Edge', '1 edge');

is ($e->attribute('label'), 'by train', 'attribute label survived');

#############################################################################
# node attributes

my $bonn = $ge->node('Bonn');
is (ref($bonn), 'Graph::Easy::Node', 'got Bonn');
is ($bonn->attribute('color'), 'red', 'color attribute survived');

#############################################################################
# now back to graph:

my $graph = Graph::Convert->as_graph( $ge );

is ($graph->get_edge_attribute('Bonn','Berlin','label'), 'by train', 
  'edge label survived again');

is ($graph->get_vertex_attribute('Bonn','color'), 'red', 
  'node color survived again');

#############################################################################
# class attributes as well as attributes on the graph itself

$ge = Graph::Easy->new();

$ge->add_edge('A','B');

$ge->set_attribute('color', 'red');
$ge->set_attribute('node', 'color', 'green');

$g = Graph::Convert->as_graph( $ge );

is ($g->get_graph_attribute('graph_color'),'red', 'graph color was carried over');
is ($g->get_graph_attribute('node_color'), 'green', 'node class color was carried over');

my $ge_2 = Graph::Convert->as_graph_easy( $g );

is ($ge_2->get_attribute('graph','color'), 'red', 'graph class color was carried back');
is ($ge_2->get_attribute('node','color'),  'green', 'node class color was carried back');
is ($ge_2->get_attribute('color'), 'red',  'graph color was carried back');

