# Annotation: Demonstrates a trivial 3-node graph, with colors.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {rankdir => 'TB'},
	node   => {shape => 'oval'},
);

$graph->default_node(shape     => 'circle', style => 'filled');
$graph->default_edge(arrowsize => 4);

$graph->add_node(name => 'Carnegie', shape => 'circle');
$graph->add_node(name => 'Carnegie', color => 'red');

$graph->default_node(style => 'rounded');

$graph->add_node(name => 'Murrumbeena', shape => 'doublecircle', color => 'green');
$graph->add_node(name => 'Oakleigh',    shape => 'oval',         color => 'blue');
$graph->add_edge(from => 'Murrumbeena', to => 'Carnegie', arrowsize => 2);

$graph->default_edge(arrowsize => 4);

$graph->add_edge(from => 'Murrumbeena', to => 'Oakleigh', color => 'brown');

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "trivial.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
