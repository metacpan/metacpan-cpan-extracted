#!/usr/bin/perl

use strict;
use GD::Chart;


my(@data) = (16, 14, 13, 1,  18, 1, 38 );
my(@labels) = ("Mountains", "Rock Slopes", "Flood Plains", "Dry Lakes", 
	       "Other", "Gullied Areas", "Sand Dunes");
my(@colours) = (hex 'ffeeee', hex 'eeffee', hex 'eeeeff', hex '00ff00',
		hex '00ffbb', hex 'bbeeff', hex '0000bb');

my $chart = new GD::Chart(250, 250);

my(%opts) = (
	data	=> \@data,
	labels	=> \@labels,
	colours	=> \@colours,
	pie_type => $GD::Chart::GDC_3DPIE,
	image_type	=> $GD::Chart::GDC_PNG,

	# Now setup some extra options 

	edge_colour  => hex '000000',
	label_dist  => 12,
	bgcolour	=> hex 'ffffff',

	# Now some pie specific options

	percent_labels	=> $GD::Chart::TRUE,
	percent_fmt 	=> $GD::Chart::GDCPIE_PCT_ABOVE,
	label_line	=> $GD::Chart::TRUE,


	title	    => "Landscape of Desert\n Area of Australia"
);

$chart->options(\%opts);

$chart->filename("3d_pie_1.png");

$chart->draw();

exit;
