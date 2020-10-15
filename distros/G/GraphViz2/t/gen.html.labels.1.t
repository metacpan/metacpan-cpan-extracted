# Annotation: Demonstrates a HTML label without a table.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $id    = 1;
my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {
	  label => "HTML label demo # $id - Using \\< ... \\>",
          rankdir => 'TB',
        },
	node   => {shape => 'oval'},
);
$graph -> default_node(shape     => 'circle', style => 'filled');
$graph -> default_edge(arrowsize => 4);

$graph -> add_node(name => 'Carnegie', shape => 'circle');
$graph -> add_node(name => 'Carnegie', color => 'red');

$graph -> default_node(style => 'rounded');

$graph -> add_node(
  name => 'Murrumbeena',
  shape => 'doublecircle',
  color => 'green',
  label =>
    '<Murrumbeena<br/><font color="#0000ff">Victoria</font><br/>Australia>',
);
$graph -> add_node(
  name => 'Oakleigh',
  shape => 'record',
  color => 'blue',
  label => ['West Oakleigh', 'East Oakleigh'],
);

$graph -> add_edge(
  from => 'Murrumbeena',
  to => 'Carnegie',
  arrowsize => 2,
  label => '<Bike<br/>Train<br/>Stroll>',
);

$graph -> default_edge(arrowsize => 1);

$graph -> add_edge(
  from => 'Murrumbeena',
  to => 'Oakleigh:port1',
  color => 'brown',
  label => '<Meander<br/>Promenade<br/>Saunter>',
);
$graph -> add_edge(
  from => 'Murrumbeena',
  to => 'Oakleigh:port2',
  color => 'green',
  label => '<Drive<br/>Run<br/>Sprint>',
);

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "html.labels.$id.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
