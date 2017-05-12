#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates named and unnamed subgraphs.

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
	graph  => {label => 'Named and unnamed subgraphs', rankdir => 'TB'},
	logger => $logger,
	node   => {shape => 'oval'},
);

$graph -> push_subgraph
(
	graph => {label => 'Subgraph One'},
	node  => {color => 'magenta', shape => 'diamond'},
);

$graph -> add_node(name => 'Chadstone', shape => 'hexagon');
$graph -> add_node(name => 'Waverley', color => 'orange');

$graph -> add_edge(from => 'Chadstone', to => 'Waverley');

$graph -> pop_subgraph;

$graph -> push_subgraph
(
	graph => {label => ''},
	node  => {color => 'blue3'},
);

$graph -> add_node(name => 'Glen Waverley', shape => 'pentagon');
$graph -> add_node(name => 'Mount Waverley', color => 'darkslategrey', shape => 'rectangle');

$graph -> add_edge(from => 'Glen Waverley', to => 'Mount Waverley');

$graph -> pop_subgraph;
my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "unnamed.sub.graph.$format");

$graph -> run(format => $format, output_file => $output_file);
