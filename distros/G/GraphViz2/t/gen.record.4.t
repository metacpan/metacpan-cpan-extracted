#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Set record-style node labels and shapes in various ways.

use strict;
use warnings;

use File::Spec;

use GraphViz2;

my($id)    = '4';
my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => "Record demo $id - Set record shapes in various ways"},
	node   => {color => 'magenta', shape => 'oval'},
);

$graph -> add_node(name => 'One',   label => []);
$graph -> add_node(name => 'Two',   label => ['Left', 'Right']);
$graph -> add_node(name => 'Three', color => 'black', label => ['Good', 'Bad'], shape => 'record');
$graph -> add_node(name => 'Four',  label =>
[
	{
		text => '{Big',
	},
	{
		text => 'Small}',
	},
]);
$graph -> add_node(name => 'Five', label =>
[
	{
		text => '{Yin',
	},
	{
		text => 'Yang}',
	},
], shape => 'record');

if (@ARGV) {
  my($format)      = shift || 'svg';
  my($output_file) = shift || File::Spec -> catfile('html', "record.$id.$format");
  $graph -> run(format => $format, output_file => $output_file);
} else {
  # run as a test
  require Test::More;
  require Test::Snapshot;
  $graph->run(format => 'dot');
  Test::Snapshot::is_deeply_snapshot($graph->dot_input, 'dot file');
  Test::More::done_testing();
}
