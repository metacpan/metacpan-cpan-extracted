# Annotation: Demonstrates graphing a byacc-style grammar.

use strict;
use warnings;
use File::Spec;
use GraphViz2;
use GraphViz2::Parse::Yacc;

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1, combine_node_and_port => 0},
	graph  => {concentrate => 1, rankdir => 'TB'},
	node   => {color => 'blue', shape => 'oval'},
);
my $g = GraphViz2::Parse::Yacc->new(graph => $graph);

$g->create(file_name => File::Spec->catfile('t', 'calc3.output'));

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "parse.yacc.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
