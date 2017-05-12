#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates a graph with a 'plaintext' shape.

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

$graph -> add_node(name => 'Murrumbeena', shape => 'plaintext');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "plaintext.$format");

$graph -> run(format => $format, output_file => $output_file);
