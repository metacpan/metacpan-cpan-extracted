#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates a cluster - with a bug. See the TODO in the POD.

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
	 graph  => {clusterrank => 'local', compound => 1, rankdir => 'TB'},
	 logger => $logger,
	 node   => {shape => 'oval'},
	);

$graph -> push_subgraph(name => 'cluster_Europe', graph => {bgcolor => 'grey', label => 'Europe'});

$graph -> add_node(name => 'London', color => 'blue');
$graph -> add_node(name => 'Paris', color => 'green', label => 'City of\nlurve');

$graph -> add_edge(from => 'London', to => 'Paris');
$graph -> add_edge(from => 'Paris', to => 'London');

$graph -> pop_subgraph;

$graph -> add_node(name => 'New York', color => 'yellow');
$graph -> add_edge(from => 'London', to => 'New York', label => 'Far');

$graph -> push_subgraph(name => 'cluster_Australia', graph => {bgcolor => 'grey', label => 'Australia'});

$graph -> add_node(name => 'Victoria', color => 'blue');
$graph -> add_node(name => 'New South Wales', color => 'green');
$graph -> add_node(name => 'Tasmania', color => 'red');

$graph -> add_edge(from => 'Victoria', to => 'New South Wales');
$graph -> add_edge(from => 'Victoria', to => 'Tasmania');

$graph -> pop_subgraph;

$graph -> add_edge(from => 'cluster_Australia', to => 'cluster_Europe');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "cluster.$format");

$graph -> run(format => $format, output_file => $output_file);
