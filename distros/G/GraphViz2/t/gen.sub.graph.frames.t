# Annotation: Demonstrates clusters with and without frames.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new(
	edge   => {color => 'grey', penwidth => 3},
	global => {directed => 1},
	graph  => {label => 'Demo of 3 subgraphs (2 being clusters), and 1 frame', rankdir => 'TB'},
	node   => {shape => 'oval'},
);

$graph->add_node(name => 'One', color => 'red',   shape => 'circle');
$graph->add_node(name => 'Two', color => 'green', shape => 'doublecircle');
$graph->add_edge(from => 'One', to => 'Two', color => 'maroon');

$graph->push_subgraph(
	graph    => {label => 'Child the First'},
	name     => 'cluster First subgraph',
	node     => {color => 'magenta', shape => 'diamond'},
	subgraph => {pencolor => 'white'}, # Required because name =~ /^cluster/.
);
$graph->add_node(name => 'Three'); # Default color and shape.
$graph->add_node(name => 'Four',  color => 'orange', shape => 'rectangle');
$graph->add_edge(from => 'Three', to => 'Four');
$graph->pop_subgraph;

$graph->push_subgraph(
	graph    => {label => 'Child the Second'},
	name     => 'cluster Second subgraph',
	node     => {color => 'magenta', shape => 'diamond'},
	subgraph => {pencolor => 'purple'}, # Required because name =~ /^cluster/.
);
$graph->add_node(name => 'Five', color => 'blue'); # Default shape.
$graph->add_node(name => 'Six',  color => 'orange', shape => 'rectangle');
$graph->add_edge(from => 'Five', to => 'Six');
$graph->pop_subgraph;

$graph->push_subgraph(
	name     => 'Third subgraph',
	graph    => {label => 'Child the Third'},
	node     => {color => 'magenta', shape => 'diamond'},
);
$graph->add_node(name => 'Seven', color => 'blue',   shape => 'doubleoctagon');
$graph->add_node(name => 'Eight', color => 'orange', shape => 'rectangle');
$graph->add_edge(from => 'Seven', to => 'Eight');
$graph->pop_subgraph;

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "sub.graph.frames.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
