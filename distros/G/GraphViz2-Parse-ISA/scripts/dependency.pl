#!/usr/bin/env perl
#
# Note: t/test.t searches for the next line.
# Annotation: Demonstrates graphing an Algorithm::Dependency object.

use strict;
use warnings;

use Algorithm::Dependency;
use Algorithm::Dependency::Source::HoA;

use File::Spec;

use GraphViz2;

my($graph) = GraphViz2 -> new
	(
	 edge   => {color => 'grey'},
	 global => {directed => 1},
	 graph  => {label => 'Adult', rankdir => 'BT'},
	 node   => {shape => 'oval'},
	);
my($data) =
{
	'Adult' => [],
	'Adult::Child1' => [qw/Adult/],
	'Adult::Child2' => [qw/Adult/],
	'Adult::Child::Grandchild' => [qw/Adult::Child1 Adult::Child2/],
};

$graph -> dependency(data => Algorithm::Dependency -> new(source => Algorithm::Dependency::Source::HoA -> new($data) ) );

my($format)      = shift || 'svg';
my($output_file) = shift || File::Spec -> catfile('html', "dependency.$format");

$graph -> run(format => $format, output_file => $output_file);
