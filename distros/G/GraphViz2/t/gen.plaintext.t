# Annotation: Demonstrates a graph with a 'plaintext' shape.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new;

$graph->add_node(name => 'Murrumbeena', shape => 'plaintext');

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "plaintext.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
