#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates subgraph name effects (cluster version).

use strict;
use warnings;

use File::Spec;

use GraphViz2;

my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {rankdir => 'TB'},
	node   => {shape => 'oval'},
);

$graph -> add_node(name => 'Carnegie',    shape => 'circle');
$graph -> add_node(name => 'Chadstone',   shape => 'circle', color => 'red');
$graph -> add_node(name => 'Malvern',     shape => 'box', color => 'green');
$graph -> add_node(name => 'Murrumbeena', shape => 'doublecircle', color => 'orange');
$graph -> add_node(name => 'Oakleigh',    color => 'blue');

$graph -> add_edge(from => 'Chadstone', to => 'Oakleigh', arrowhead => 'odot');
$graph -> add_edge(from => 'Malvern',   to => 'Carnegie', arrowsize => 2);
$graph -> add_edge(from => 'Malvern',   to => 'Oakleigh', color => 'brown');

$graph -> push_subgraph
(
	subgraph => {rank => 'same'},
);

$graph -> add_node(name => 'Malvern');
$graph -> add_node(name => 'Prahran');

$graph -> pop_subgraph;

$graph -> push_subgraph
(
	name     => 'cluster Subgraph 2',
	subgraph => {rank => 'same'},
);

$graph -> add_node(name => 'Oakleigh');
$graph -> add_node(name => 'Murrumbeena');

$graph -> pop_subgraph;

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "rank.sub.graph.4.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  $graph->run(format => 'dot');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
