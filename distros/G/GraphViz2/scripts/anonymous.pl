#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates empty strings for node names and labels.

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
	 node   => {shape => 'oval'},
	);

$graph -> add_node(name => '', label => ''); # Same as add_node().
$graph -> add_node(name => 'Anonymous label 1', label => '');
$graph -> add_node(name => 'Anonymous label 2', label => '');
$graph -> add_edge(from => '', to => ''); # This uses the name '', and hence the first node.

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "anonymous.$format");

$graph -> run(format => $format, output_file => $output_file);
