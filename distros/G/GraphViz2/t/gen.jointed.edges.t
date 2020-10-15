# Annotation: Demonstrates Y-shaped edges between 3 nodes.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my %junction = (color => 'grey', shape => 'point', width => 0);
# Note: arrowhead is case-sensitive (i.e. arrowHead does not work).
my %headless_arrow = (arrowhead => 'none');

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {rankdir => 'TB'},
	node   => {shape => 'oval', style => 'filled'},
);

# Node set 1:
$graph->add_node(name => 'Carnegie',    color => 'aquamarine');
$graph->add_node(name => 'Murrumbeena', color => 'bisque');
$graph->add_node(name => 'Oakleigh',    color => 'blueviolet');
$graph->add_node(name => 'one', %junction); # 1st of 2 junction nodes
$graph->add_edge(from => 'Murrumbeena', to => 'one', %headless_arrow);
$graph->add_edge(from => 'Carnegie',    to => 'one', %headless_arrow);
$graph->add_edge(from => 'one',         to => 'Oakleigh');

# Node set 2:
$graph->add_node(name => 'Ashburton', color => 'lawngreen');
$graph->add_node(name => 'Chadstone', color => 'coral');
$graph->add_node(name => 'Waverley',  color => 'crimson');
$graph->add_node(name => 'two', %junction); # 2nd of 2 junction nodes
$graph->add_edge(from => 'Ashburton', to => 'two', %headless_arrow);
$graph->add_edge(from => 'Chadstone', to => 'two', %headless_arrow);
$graph->add_edge(from => 'two',       to => 'Waverley');

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec->catfile('html', "jointed.edges.$format");
  $graph->run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
