# Annotation: Demonstrates empty strings for node names and labels.

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

$graph -> add_node(name => '', label => ''); # Same as add_node().
$graph -> add_node(name => 'Anonymous label 1', label => '');
$graph -> add_node(name => 'Anonymous label 2', label => '');
$graph -> add_edge(from => '', to => ''); # This uses the name '', and hence the first node.

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "anonymous.$format");
  $graph->run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
