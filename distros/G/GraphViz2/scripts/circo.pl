#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates calling circo instead of dot.

use strict;
use warnings;

use File::Spec;

use GraphViz2;

use IPC::Run3; # For run().

use Log::Handler;

# ------------

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

# Generate the dot input.

my($graph) = GraphViz2 -> new
(
	edge   => {color => 'grey'},
	global => {directed => 1},
	graph  => {rankdir => 'TB'},
	logger => $logger,
	node   => {shape => 'oval'},
);

# Redundant.
#$graph -> add_node(name => 'Here');
#$graph -> add_node(name => 'There');
#$graph -> add_node(name => 'Everywhere');

$graph -> add_edge(from => 'Here', to => 'There');
$graph -> add_edge(from => 'There', to => 'Everywhere');
$graph -> add_edge(from => 'Everywhere', to => 'Here');

# Generate the dot output.

$graph -> run;

# Generate the circo output.

my($stdout, $stderr);

run3
	[
		'circo',
		'-Gpage=8.25,10.75',
		'-Grotate=90',
		'-Gmargin=0.125',
		'-Gsize=8.25,10.75'
	],
	\$graph -> dot_input,
	\$stdout,
	\$stderr;

die $stderr if ($stderr);

my($circo_output) = $stdout;

#print '-' x 50, "\n";
#print $circo_output;
#print '-' x 50, "\n";

# Generate the dot output.

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "circo.$format");

run3
	[
		'dot',
		"-T$format",
	],
	\$circo_output,
	\$stdout,
	\$stderr;

die $stderr if ($stderr);

my($dot_output) = $stdout;

#print '-' x 50, "\n";
#print $dot_output;
#print '-' x 50, "\n";

open(OUT, '>', $output_file);
print OUT $dot_output;
close OUT;

print "Wrote $output_file. \n";
