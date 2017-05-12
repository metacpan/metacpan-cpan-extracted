#!/usr/bin/perl -w

# Some basic tests:

use Test::More;
use strict;

BEGIN
   {
   plan tests => 47;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Convert") or die($@);
   };

can_ok ("Graph::Convert", qw/
  as_graph
  as_multiedged_graph
  as_undirected_graph
  as_graph_easy
  /);

#############################################################################
# both Graph and Graph::Easy are automatically loaded:

my $ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Berlin', 'by train' );

is (scalar $ge->nodes(), 2, '2 nodes');
is (scalar $ge->edges(), 1, '1 edges');
is ($ge->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');

my $graph = Graph::Convert->as_graph( $ge );

is (scalar $graph->vertices(), 2, '2 nodes');
is (scalar $graph->edges(), 1, '1 edges');
is ($graph->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');

my $graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->nodes(), 2, '2 nodes');
is (scalar $graph_easy->edges(), 1, '1 edges');
is ($graph_easy->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');

#############################################################################
# test multi-edges graphs

$ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Berlin', 'by train' );
$ge->add_edge( 'Bonn', 'Berlin', 'by car' );

is (scalar $ge->nodes(), 2, '2 nodes');
is (scalar $ge->edges(), 2, '2 edges');
is ($ge->is_simple_graph(), 0, 'no simple graph (2 nodes, 2 edge)');

$graph = Graph::Convert->as_graph( $ge );

is (scalar $graph->vertices(), 2, '2 nodes');
is (scalar $graph->edges(), 2, '2 edges');
is (scalar $graph->unique_edges(), 1, '1 unique edge');
is ($graph->is_simple_graph(), 0, 'no simple graph (2 nodes, 2 edge)');
isnt ($graph->is_multiedged(), 0, 'is multiedged');

$graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->nodes(), 2, '2 nodes');
is (scalar $graph_easy->edges(), 2, '2 edges');
is ($graph_easy->is_simple_graph(), 0, 'no simple graph (2 nodes, 2 edges)');

#############################################################################
# test self-loops

$ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Bonn', 'loop' );

is (scalar $ge->nodes(), 1, '1 node');
is (scalar $ge->edges(), 1, '1 edge');
is ($ge->is_simple_graph(), 1, 'simple graph (self-loop but no multi-edge)');

$graph = Graph::Convert->as_graph( $ge );

is (scalar $graph->vertices(), 1, '1 node');
is (scalar $graph->edges(), 1, '1 edge');
is ($graph->is_simple_graph(), 1, 'is simple graph');
is ($graph->is_multiedged(), 0, 'is not multiedged');

$graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->nodes(), 1, '1 node');
is (scalar $graph_easy->edges(), 1, '1 edge');
is ($graph_easy->is_simple_graph(), 1, 'simple graph (selfloop)');

#############################################################################
# test self-loops and multi-edges

$ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Bonn', 'loop' );
$ge->add_edge( 'Bonn', 'Bonn', 'loop 2' );

is (scalar $ge->nodes(), 1, '1 node');
is (scalar $ge->edges(), 2, '2 edges');
is ($ge->is_simple_graph(), 0, 'no simple graph (multi-edges)');

$graph = Graph::Convert->as_graph( $ge );

is (scalar $graph->vertices(), 1, '1 node');
is (scalar $graph->edges(), 2, '2 edges');
is (scalar $graph->unique_edges(), 1, '1 unique edge');
is ($graph->is_simple_graph(), 0, 'no simple graph');
isnt ($graph->is_multiedged(), 0, 'is multiedged');

$graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->nodes(), 1, '1 node');
is (scalar $graph_easy->edges(), 2, '2 edges');
is ($graph_easy->is_simple_graph(), 0, 'no simple graph');

