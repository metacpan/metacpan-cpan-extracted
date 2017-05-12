#!/usr/bin/perl
# This code demonstrates the problem I am having with labels inside
# of a stacked bar chart

use strict;
use GD::Graph::hbars;
require "save.pl";

my @data = (
["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
[ 1, 2, 5, 6, 3, 1.5, 1, 3, 4],
[ 1, 1.5, 3, 2, 3, 1.5, 3, 4, 4 ]
);

my @dim = (600,400);
my @names = qw/sample1B sample1B-h/;

for my $graph (GD::Graph::bars->new(@dim),GD::Graph::hbars->new(@dim)) {
    my $name = shift @names;
    print STDERR "Processing $name\n";

	$graph->set_legend('Pass', 'Fail');
	$graph->set(
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'Cumulated bar graph with labels',
	y_max_value => 10,
	y_tick_number => 10,
	y_label_skip => 2,
	bar_spacing => 8,
	cumulate => 'true',
	
	dclrs => [ qw( green lred ) ],
	show_values => 1,
	values_space => 4,
	)
	or warn $graph->error;
	my $format = $graph->export_format;
	$graph->plot(\@data)->$format();
	
	save_chart($graph,$name);
}


1;
