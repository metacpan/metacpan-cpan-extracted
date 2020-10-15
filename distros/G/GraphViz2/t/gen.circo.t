# Annotation: Demonstrates calling circo instead of dot.

use strict;
use warnings;
use File::Spec;
use GraphViz2;

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {
          rankdir => 'TB',
          page => '8.25,10.75',
          rotate => '90',
          margin => '0.125',
          size => '8.25,10.75'
        },
	node   => {shape => 'oval'},
);
$graph -> add_edge(from => 'Here', to => 'There');
$graph -> add_edge(from => 'There', to => 'Everywhere');
$graph -> add_edge(from => 'Everywhere', to => 'Here');

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "circo.$format");
  $graph->run(driver => 'circo', format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
