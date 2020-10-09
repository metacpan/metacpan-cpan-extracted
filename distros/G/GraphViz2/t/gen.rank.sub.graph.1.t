#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates subgraphs used to rank nodes horizontally (succinct version of code).

use strict;
use warnings;

use File::Spec;

use GraphViz2;

my($graph) = GraphViz2 -> new
(
	edge     => {color => 'grey'},
	global   => {directed => 1},
	graph    => {rankdir => 'TB'},
	node     => {shape => 'oval'},
	subgraph => {rank => 'same'},
);

$graph -> add_node(name => 'Carnegie',    shape => 'circle');
$graph -> add_node(name => 'Chadstone',   shape => 'circle', color => 'red');
$graph -> add_node(name => 'Malvern',     shape => 'box', color => 'green');
$graph -> add_node(name => 'Murrumbeena', shape => 'doublecircle', color => 'orange');
$graph -> add_node(name => 'Oakleigh',    color => 'blue');

$graph -> add_edge(from => 'Chadstone', to => 'Oakleigh', arrowhead => 'odot');
$graph -> add_edge(from => 'Malvern',   to => 'Carnegie', arrowsize => 2);
$graph -> add_edge(from => 'Malvern',   to => 'Oakleigh', color => 'brown');

# a and b are arbitrary values. All that's happening is that all nodes
# in @{$rank{a} } will be in the same horizontal line, and likewise for b.

my(%rank) = (a => [], b => []);

push @{$rank{a} }, 'Malvern';
push @{$rank{a} }, 'Prahran';

push @{$rank{b} }, 'Oakleigh';
push @{$rank{b} }, 'Murrumbeena';

for my $key (sort keys %rank)
{
	$graph -> push_subgraph;
	$graph -> add_node(name => $_) for @{$rank{$key} };
	$graph -> pop_subgraph;
}

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "rank.sub.graph.1.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  $graph->run(format => 'dot');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
