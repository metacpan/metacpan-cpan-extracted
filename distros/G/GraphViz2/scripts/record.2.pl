#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Nested records using an arrayref of hashrefs as labels.

use strict;
use warnings;

use File::Spec;

use GraphViz2;

use Log::Handler;

# -----------------------------------------------

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

my($id)    = '2';
my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => "Record demo $id - Nested records using an arrayref of hashrefs as labels"},
	logger => $logger,
	node   => {shape => 'record'},
);

$graph -> add_node(name => 'struct1', label => '<f0> left|<f1> mid dle|<f2> right');
$graph -> add_node(name => 'struct2', label => '<f0> one|<f1> two');
$graph -> add_node(name => 'struct3', label =>
[
	{
		text => "hello\\nworld",
	},
	{
		text => '{b',
	},
	{
		text => '{c',
	},
	{
		port => '<here>',
		text => 'd',
	},
	{
		text => 'e}',
	},
	{
		text => 'f}',
	},
	{
		text => 'g',
	},
	{
		text => 'h',
	},
]);

$graph -> add_edge(from => 'struct1:f1', to => 'struct2:f0',   color => 'blue');
$graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "record.$id.$format");

$graph -> run(format => $format, output_file => $output_file);
