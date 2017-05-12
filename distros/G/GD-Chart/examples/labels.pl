#!/usr/bin/perl

use strict;
use GD::Chart;

### Example - xlabel axis labelling problem

my(@data) = (4,5,5,6,3,7,5,4,4,4,3,4,5,7,8,9,9,6,1,7,9,3,1,5,7,8,9,
	     3,5,8,2,6,6,8,2,3,10,6,8,8,3,6,4,6,2,6,5,7,8,3,4,6,7,8,
	     5,7,8,3,5,7,8,9,2,5,3,5,9,4,7,2);

my(@labels) = ("Mon", "", "", "", "", "", "", "", "", "", "Tue", "", "", "",
		"", "", "", "", "", "", "Wen", "", "", "", "", "", "",
		"", "", "", "Thu", "", "", "", "", "", "", "", "", "", "Fri",
		"", "", "", "", "", "", "", "", "", "Sat", "", "", "", ""
		,"", "", "", "", "", "Sun", "", "", "", "", "", "", "", "",
		"");

my(@cols) = (hex 'ff00ff', hex 'ff0000', hex '552233', hex '654322', hex '2341634');

my $chart = new GD::Chart(400, 200);

my %opts = (
	data	=> \@data,
	labels	=> \@labels,
	colours	=> \@cols,
	chart_type => $GD::Chart::GDC_3DBAR,
	image_type => $GD::Chart::GDC_PNG,
	bgcolour   => hex 'ffffff',
#	xlabel_skip => 20,	removed for the moment
	title => "Test"

);

$chart->options(\%opts);

$chart->filename("labels.png");

$chart->draw(\@labels);

exit;
