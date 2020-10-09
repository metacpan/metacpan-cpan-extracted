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

my($graph) = GraphViz2 -> new
	(
	 global => {name => 'Heawood'},
	 graph  => {rankdir => 'TB'},
	);

$graph -> default_edge(color => 'black');
$graph -> default_node
(
 fontname => "Arial",
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

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec->catfile('html', "Heawood.$format");
  $graph->run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  $graph->run(format => 'dot');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
