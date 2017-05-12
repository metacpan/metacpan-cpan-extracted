#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates HTML labels with newlines and double-quotes.

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

my($id)    = 3;
my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => "HTML label demo # $id - Fixing newlines", rankdir => 'TB'},
	logger => $logger,
	node   => {shape => 'oval'},
);

$graph -> add_node(name => 'One', label => '
<One<br/><font color="#0000ff">Blue</font><br/>>
');

$graph -> add_node(name => 'Two', label => '<
Two<br/><font color="#00ff00">Green</font><br/>
>');

$graph -> add_node(name => 'Three', color => 'red', label => '
<<table border="1"><tr><td align="left">Three</td></tr><tr align="right"><td>Red</td></tr></table>>
');

$graph -> add_node(name => 'Four', color => 'magenta', label => '<
<table border="1"><tr><td align="left">Four<br />magenta</td></tr></table>
>');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "html.labels.$id.$format");

$graph -> run(format => $format, output_file => $output_file);
