#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing a byacc-style grammar.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Parse::Yacc;

use Log::Handler;

# ------------------------------------------------

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

my($graph)  = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {concentrate => 1, rankdir => 'TB'},
	 logger => $logger,
	 node   => {color => 'blue', shape => 'oval'},
	);
my($g) = GraphViz2::Parse::Yacc -> new(graph => $graph);

$g -> create(file_name => File::Spec -> catfile('t', 'calc3.output') );

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.yacc.$format");

$graph -> run(format => $format, output_file => $output_file);
