#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates using XML::Bare to parse HTML.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Data::Grapher;

use Log::Handler;

use File::Slurp; # For read_file().

use XML::Bare;

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

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	 node   => {color => 'blue', shape => 'oval'},
	);
my $xml   = read_file(File::Spec -> catfile('t', 'sample.html'), {chomp => 1});
my($g)    = GraphViz2::Data::Grapher -> new(graph => $graph);
my($bare) = XML::Bare -> new(text => $xml) -> simple;
my(@key)  = sort keys %$bare;

$g -> create(name => $key[0], thing => $$bare{$key[0]});

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.html.$format");

$graph -> run(format => $format, output_file => $output_file);
