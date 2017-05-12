#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates the transitive 6-net, also known as Heawood's graph.
#
# Reverse-engineered from graphs/directed/Heawood.gv from the Graphviz distro for V 2.26.3.

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
	 global => {name => 'Heawood'},
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	);

$graph -> default_edge(color => 'black');
$graph -> default_node
(
 fontname => ($^O eq 'darwin') ? "ArialMT" : "Arial",
 label    => "\\N",
 shape    => "circle",
 width    => "0.50000",
 height   => "0.500000",
 color    => "black",
);

for my $i (0 .. 12)
{
	$graph -> add_edge(from => $i, to => ($i + 1) );
}

$graph -> add_edge(from => 13, to =>  0);
$graph -> add_edge(from =>  0, to =>  5, len => 2.5);
$graph -> add_edge(from =>  2, to =>  7, len => 2.5);
$graph -> add_edge(from =>  4, to =>  9, len => 2.5);
$graph -> add_edge(from =>  6, to => 11, len => 2.5);
$graph -> add_edge(from =>  8, to => 13, len => 2.5);
$graph -> add_edge(from => 10, to =>  1, len => 2.5);
$graph -> add_edge(from => 12, to =>  3, len => 2.5);

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "Heawood.$format");

$graph -> run(format => $format, output_file => $output_file);
