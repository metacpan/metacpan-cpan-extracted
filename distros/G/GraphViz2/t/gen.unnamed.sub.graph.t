# Annotation: Demonstrates named and unnamed subgraphs.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => 'Named and unnamed subgraphs', rankdir => 'TB'},
);

$graph->push_subgraph(
	graph => {label => 'Subgraph One'},
	node  => {color => 'magenta', shape => 'diamond'},
);
$graph->add_node(name => 'Chadstone', shape => 'hexagon');
$graph->add_node(name => 'Waverley', color => 'orange');
$graph->add_edge(from => 'Chadstone', to => 'Waverley');
$graph->pop_subgraph;

$graph->push_subgraph;
$graph->add_node(name => 'Glen Waverley', color => 'blue3', shape => 'pentagon');
$graph->add_node(name => 'Mount Waverley', color => 'darkslategrey', shape => 'rectangle');
$graph->add_edge(from => 'Glen Waverley', to => 'Mount Waverley');
$graph->pop_subgraph;

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "unnamed.sub.graph.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
