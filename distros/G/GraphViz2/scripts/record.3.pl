#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Deeply nested records using strings as labels.

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

my($id)    = '3';
my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {label => "Record demo $id - Deeply nested records using strings as labels"},
	logger => $logger,
	node   => {shape => 'record'},
);

$graph -> add_node(name => 'Alphabet',
label => '<port_a> a:port_a |{<port_b> b:port_b | c |{<port_d> d:port_d | e | f |{ g |<port_h> h:port_h | i | j |{ k | l | m |<port_n> n:port_n | o | p}| q | r |<port_s> s:port_s | t }| u | v |<port_w> w:port_w }| x |<port_y> y:port_y }| z');

$graph -> add_edge(from => 'Alphabet:port_a', to => 'Alphabet:port_n', color => 'maroon');
$graph -> add_edge(from => 'Alphabet:port_b', to => 'Alphabet:port_s', color => 'blue');
$graph -> add_edge(from => 'Alphabet:port_d', to => 'Alphabet:port_w', color => 'red');
$graph -> add_edge(from => 'Alphabet:port_y', to => 'Alphabet:port_h', color => 'green');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "record.$id.$format");

$graph -> run(format => $format, output_file => $output_file);
