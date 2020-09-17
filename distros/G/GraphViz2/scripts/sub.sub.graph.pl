#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates a subsubgraph.

use strict;
use warnings;

use File::Spec;

use GraphViz2;

use Log::Handler;

# ---------------

my($logger) = Log::Handler -> new;

$logger -> add
	(
	 screen =>
	 {
		 maxlevel       => 'debug',
		 message_layout => '%m',
		 minlevel       => 'error',
	 }
	);

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {label => 'sub.sub.graph.pl', rankdir => 'TB'},
	 logger => $logger,
	 node   => {shape => 'oval'},
	);

$graph -> add_node(name => 'Carnegie', shape => 'circle');
$graph -> add_node(name => 'Murrumbeena', shape => 'doublecircle', color => 'green');
$graph -> add_node(name => 'Oakleigh',    color => 'blue');
$graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
$graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

$graph -> push_subgraph
(
 name  => 'subgraph_1',
 graph => {label => 'Child'},
 node  => {color => 'magenta', shape => 'diamond'},
);

$graph -> add_node(name => 'Chadstone', shape => 'hexagon');
$graph -> add_node(name => 'Waverley', color => 'orange');
$graph -> add_edge(from => 'Chadstone', to => 'Waverley');

$graph -> push_subgraph
(
 name  => 'cluster_2',
 graph => {label => 'Grandchild'},
 node  => {color => 'blue3', shape => 'triangle'},
);

$graph -> add_node(name => 'Glen Waverley', shape => 'pentagon');
$graph -> add_node(name => 'Mount Waverley', color => 'darkslategrey');
$graph -> add_edge(from => 'Glen Waverley', to => 'Mount Waverley');

$graph -> pop_subgraph;
$graph -> pop_subgraph;

$graph -> default_node(color => 'cyan');
$graph -> add_node(name => 'Malvern');
$graph -> add_node(name => 'Prahran', shape => 'trapezium');
$graph -> add_edge(from => 'Malvern', to => 'Prahran');
$graph -> add_edge(from => 'Malvern', to => 'Murrumbeena');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "sub.sub.graph.$format");

$graph -> run(format => $format, output_file => $output_file);
