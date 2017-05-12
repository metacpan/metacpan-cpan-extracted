#!/usr/bin/perl -w

# test conversion with groups

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

$ge->add_group( 'Cities' );
is (scalar $ge->groups(), 1, 'one group');

my $graph = Graph::Convert->as_graph( $ge );

is (scalar $graph->vertices(), 2, '2 nodes');
is (scalar $graph->edges(), 1, '1 edges');
is ($graph->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');

my $graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->nodes(), 2, '2 nodes');
is (scalar $graph_easy->edges(), 1, '1 edges');
is ($graph_easy->is_simple_graph(), 1, 'simple graph (2 nodes, 1 edge)');
is (scalar $ge->groups(), 1, 'one group');

#############################################################################
# test multi-edges graphs with groups

$ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Berlin', 'by train' );
$ge->add_edge( 'Bonn', 'Berlin', 'by car' );

is (scalar $ge->nodes(), 2, '2 nodes');
is (scalar $ge->edges(), 2, '2 edges');
is ($ge->is_simple_graph(), 0, 'no simple graph (2 nodes, 2 edge)');

$ge->add_group( 'Cities' );
is (scalar $ge->groups(), 1, 'one group');

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
is (scalar $ge->groups(), 1, 'one group');

#############################################################################
# groups with attributes and nodes in them

$ge = Graph::Easy->new();

is (ref($ge), 'Graph::Easy');
$ge->add_edge( 'Bonn', 'Berlin', 'by train' );
$ge->add_edge( 'Bonn', 'Berlin', 'by car' );

is (scalar $ge->nodes(), 2, '2 nodes');
is (scalar $ge->edges(), 2, '2 edges');
is ($ge->is_simple_graph(), 0, 'no simple graph (2 nodes, 2 edge)');

my $grp = $ge->add_group( 'Cities' );
is (scalar $ge->groups(), 1, 'one group');

$grp->set_attribute('fill', 'green');

$graph = Graph::Convert->as_graph( $ge );
$graph_easy = Graph::Convert->as_graph_easy( $graph );

my $group = $graph_easy->group('Cities');

is ($group->attribute('fill'), 'green', 'group and attribute got preserved');

#############################################################################
# add a node

my $u = $ge->add_node( 'Ulm' );
$grp->add_node($u);

$graph = Graph::Convert->as_graph( $ge );
$graph_easy = Graph::Convert->as_graph_easy( $graph );

$group = $graph_easy->group('Cities');

is ($group->attribute('fill'), 'green', 'group and attribute got preserved');
is (scalar $group->nodes(), 1, 'group has one node');

my $ulm = $graph_easy->node('Ulm');
is (ref($ulm), 'Graph::Easy::Node', 'Node survived');
my $nodes_group = $ulm->group();

is ( ref($nodes_group), 'Graph::Easy::Group', 'Group was set on the node');

#############################################################################
# nested groups

my $grp_2 = $ge->add_group( 'German Cities' );
$grp_2->set_attribute('fill', 'red');

$grp_2->add_group($grp);

is (scalar $ge->groups(), 2, 'two groups');
is (ref($grp->group()), 'Graph::Easy::Group', 'sub group');

$graph = Graph::Convert->as_graph( $ge );
$graph_easy = Graph::Convert->as_graph_easy( $graph );

is (scalar $graph_easy->groups(), 2, 'two groups');

$ulm = $graph_easy->node('Ulm');
is (ref($ulm), 'Graph::Easy::Node', 'Node survived');
$nodes_group = $ulm->group();
is ( ref($nodes_group), 'Graph::Easy::Group', 'Group was set on the node');

my $sub_group = $nodes_group->group();
is ( ref($sub_group), 'Graph::Easy::Group', 'Group was set on the group');

isnt ($sub_group, $nodes_group, 'groups are different');
is ($nodes_group->attribute('fill'), 'green', "first group's attribute got preserved");
is ($sub_group->attribute('fill'), 'red', "sub group's attribute got preserved");

