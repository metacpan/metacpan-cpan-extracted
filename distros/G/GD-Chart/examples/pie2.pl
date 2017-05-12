#!/usr/bin/perl

use strict;
use GD::Chart;

### The problem with small fractions of pie chart being placed together. 

my(@data) = (99.85, 0.135, 0.01, 0.00005, 0.0000002);
my(@labels) = ("Sun", "Planets", "Comets", "Satellites", "Minor Planets");
my(@colours) = (hex 'ffff00', hex '00ffff', hex '00ff00', 
	        hex 'ff00ff', hex '0000ff');

my $c = new GD::Chart(450, 450);

my %opts = 
(
	pie_type => $GD::Chart::GDC_2DPIE,
	image_type => $GD::Chart::GDC_PNG,
	data	   => \@data,
	labels	   => \@labels,
	colours    => \@colours,
	bgcolour   => hex 'ffffff',
	edge_colour=> hex 'ff0000',
	plot_colour=> hex 'ff0000',
	percent_labels=> $GD::Chart::GDCPIE_PCT_RIGHT,
	title	   => "Mass Distribution in the Solar System"
	
);

$c->options(\%opts);

$c->filename("pie2.png");

$c->draw();

exit;
