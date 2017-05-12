#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing a Perl data structure.

use strict;
use warnings;

use File::Spec;

use GraphViz2;
use GraphViz2::Data::Grapher;

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

my($sub) = sub{};
my($s)   =
{
	A =>
	{
		a =>
		{
		},
		bbbbbb => $sub,
		c123   => $sub,
		d      => \$sub,
	},
	C =>
	{
		b =>
		{
			a =>
			{
				a =>
				{
				},
				b => sub{},
				c => 42,
			},
		},
	},
	els => [qw(element_1 element_2 element_3)],
};

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {rankdir => 'TB'},
	 logger => $logger,
	 node   => {color => 'blue', shape => 'oval'},
	);

my($g)           = GraphViz2::Data::Grapher -> new(graph => $graph, logger => $logger);
my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "parse.data.$format");

$g -> create(name => 's', thing => $s);
$graph -> run(format => $format, output_file => $output_file);

# If you did not provide a GraphViz2 object, do this
# to get access to the auto-created GraphViz2 object.

#$g -> create(name => 's', thing => $s);
#$g -> graph -> run(format => $format, output_file => $output_file);

# Or even

#$g -> create(name => 's', thing => $s)
#-> graph
#-> run(format => $format, output_file => $output_file);
