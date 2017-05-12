#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing a Perl regular expression.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Parse::Regexp;

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
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	 node   => {color => 'blue', shape => 'oval'},
	);
my($g) = GraphViz2::Parse::Regexp -> new(graph => $graph);

$g -> create(regexp => '(([abcd0-9])|(foo))');

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.regexp.$format");

$graph -> run(format => $format, output_file => $output_file);
