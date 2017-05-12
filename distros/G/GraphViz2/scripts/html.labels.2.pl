#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates a HTML label with a table.

use strict;
use warnings;

use File::Spec;

use GraphViz2;

use Log::Handler;

# ---------------

my($logger) = Log::Handler -> new;

$logger -> add
(
	screen =>
	{
		maxlevel       => 'debug',
		message_layout => '%m',
		minlevel       => 'error',
	}
);

my($id)    = 2;
my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => "HTML label demo # $id - Using \\<\\<table\\> ... \\</table\\>\\>", rankdir => 'TB'},
	logger => $logger,
	node   => {shape => 'oval'},
);

$graph -> add_node
(
	label =>
q|
<<table bgcolor = 'white'>
<tr>
	<td bgcolor = 'palegreen'>The green node is the start node</td>
</tr>
<tr>
	<td bgcolor = 'lightblue'>Lightblue nodes are for lexeme attributes</td>
</tr>
<tr>
	<td bgcolor = 'orchid'>Orchid nodes are for lexemes</td>
</tr>
<tr>
	<td bgcolor = 'goldenrod'>Golden nodes are for actions</td>
</tr>
<tr>
	<td bgcolor = 'firebrick1'>Red nodes are for events</td>
</tr>
</table>>
|,
	name  => 'Legend',
	shape => 'plaintext',
);

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "html.labels.$id.$format");

$graph -> run(format => $format, output_file => $output_file);
