# Annotation: Demonstrates graphing a Perl regular expression.

use strict;
use warnings;
use File::Spec;
use GraphViz2;
use GraphViz2::Parse::Regexp;

my $graph = GraphViz2->new(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {rankdir => 'TB'},
	node   => {color => 'blue', shape => 'oval'},
);
my $g = GraphViz2::Parse::Regexp->new(graph => $graph);

my $re = '^(([abcd0-9])|(foo)n?)x*y{1,2}';
$g->create(regexp => $re);

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "parse.regexp.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  local our $TODO = 'seems to vary by Perl version';
  my $gd = GraphViz2::Parse::Regexp::to_graph($re);
  my $gvre = GraphViz2::Parse::Regexp->new(as_graph => $gd);
  Test::Snapshot::is_deeply_snapshot($gvre->graph->dot_input, 'dot file');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
