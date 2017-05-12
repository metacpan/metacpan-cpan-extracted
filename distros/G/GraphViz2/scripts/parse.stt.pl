#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing a Set::FA::Element's state transition table.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Parse::STT;

use Log::Handler;

use File::Slurp; # For read_file().

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
	 graph  => {rankdir => 'LR'},
	 logger => $logger,
	 node   => {color => 'green', shape => 'oval'},
	);
my($g)  = GraphViz2::Parse::STT -> new(graph => $graph);
my $stt = read_file(File::Spec -> catfile('t', 'sample.stt.1.dat') );

$g -> create(stt => $stt);

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.stt.$format");

$graph -> run(format => $format, output_file => $output_file);
