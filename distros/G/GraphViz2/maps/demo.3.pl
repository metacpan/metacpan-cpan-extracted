#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates a graph with a 'plaintext' shape.

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
		 maxlevel		=> 'debug',
		 message_layout	=> '%m',
		 minlevel		=> 'error',
	 }
	);

my($id)		= 3;
my($graph)	= GraphViz2 -> new
				(
					edge   => {color => 'grey'},
					global =>
					{
						directed	=> 1,
						name		=> 'mainmap',
					},
					graph	=> {rankdir => 'TB'},
					im_meta	=>
					{
						URL => 'http://savage.net.au/maps/demo.3.1.html',	# Note: URL must be in caps.
					},
					logger	=> $logger,
					node	=> {shape => 'oval'},
				);

$graph -> add_node(name => 'source',	URL => 'http://savage.net.au/maps/demo.3.2.html');
$graph -> add_node(name => 'destination');
$graph -> add_edge(from => 'source',	to => 'destination',	URL => '/maps/demo.3.3.html');


my($format)			= shift || 'png';
my($output_file)	= shift || "demo.$id.$format";
my($im_format)		= shift || 'imap';
my($im_output_file)	= shift || "demo.$id.map";

$graph -> run(format => $format, output_file => $output_file, im_format => $im_format, im_output_file => $im_output_file);
