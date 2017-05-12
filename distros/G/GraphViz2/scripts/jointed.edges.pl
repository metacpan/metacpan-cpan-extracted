#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates Y-shaped edges between 3 nodes.

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
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	 node   => {shape => 'oval', style => 'filled'},
	);

# Node set 1:

$graph -> add_node(name => 'Carnegie',    color => 'aquamarine');
$graph -> add_node(name => 'Murrumbeena', color => 'bisque');
$graph -> add_node(name => 'Oakleigh',    color => 'blueviolet');

# This is the 1st of 2 nodes used as the junction of 3 edges.

my(%junction) =
(
	color => 'grey',
	shape => 'point',
	width => 0,
);

$graph -> add_node(name => 'one', %junction);

# Note: arrowhead is case-sensitive (i.e. arrowHead does not work).
# Presumably all attribute names are likewise case-sensitive.

my(%headless_arrow) = (arrowhead => 'none');

$graph -> add_edge(from => 'Murrumbeena', to => 'one', %headless_arrow);
$graph -> add_edge(from => 'Carnegie',    to => 'one', %headless_arrow);
$graph -> add_edge(from => 'one',         to => 'Oakleigh');

# Node set 2:

$graph -> add_node(name => 'Ashburton', color => 'lawngreen');
$graph -> add_node(name => 'Chadstone', color => 'coral');
$graph -> add_node(name => 'Waverley',  color => 'crimson');

# This is the 2nd of 2 nodes used as the junction of 3 edges.

$graph -> add_node(name => 'two', %junction);

$graph -> add_edge(from => 'Ashburton', to => 'two', %headless_arrow);
$graph -> add_edge(from => 'Chadstone', to => 'two', %headless_arrow);
$graph -> add_edge(from => 'two',       to => 'Waverley');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "jointed.edges.$format");

$graph -> run(format => $format, output_file => $output_file);
