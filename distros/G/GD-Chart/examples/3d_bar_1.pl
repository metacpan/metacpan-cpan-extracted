#!/usr/bin/perl

use strict;
use GD::Chart;

## Data on Oceans
## - Need to add legend afterwards

my(@data) = (
[180, 106, 75],
[724, 355, 292]
);
my(@labels) = ("Pacific Ocean", "Atlantic Ocean", "Indian Ocean");
my(@colours) = (hex 'bbccdd', hex 'aaffcc', hex 'ddaabb');

my(%opts) = (
	data	=> \@data,
	labels	=> \@labels,
	colours	=> \@colours,
	chart_type	=> $GD::Chart::GDC_3DBAR,
	image_type	=> $GD::Chart::GDC_PNG,
	title		=> "Area and Volume Of Oceans",
	bgcolour	=> hex 'ffffff',
	ytitle		=> "millions km^2/km^3",
	ytitle2		=> "millions km^3",
);

my $chart = new GD::Chart(350, 350);

my $note = new GD::Chart::note("Also Artic Ocean", hex '00bbff', 1, $GD::Chart::GDC_TINY);

$chart->note($note);
$chart->options(\%opts);

$chart->filename("3d_bar_1.png");

$chart->draw();

exit;
