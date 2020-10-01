#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing a Perl class hierarchy.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Parse::ISA;

use Log::Handler;

# ------------------------------------------------

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
	 graph  => {rankdir => 'BT'},
	 logger => $logger,
	 node   => {color => 'blue', shape => 'Mrecord'},
	);
my($parser) = GraphViz2::Parse::ISA -> new(graph => $graph);

unshift @INC, 't/lib';

$parser -> add(class => 'Adult::Child::Grandchild', ignore => []);
$parser -> add(class => 'HybridVariety', ignore => []);
$parser -> generate_graph;

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.isa.$format");

$graph -> run(format => $format, output_file => $output_file);
