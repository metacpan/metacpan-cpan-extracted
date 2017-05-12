#!/usr/bin/perl

use strict;
use GD::Chart;

my(@data) = (81000, 700, 100, 0.005, 50000, 20, 25000, 1, 80, 0.005,
	     1, 1.5, 1.5, 7, 80);
my(@labels) = ("Aluminium", "Chromium", "Copper", "Gold", "Iron", "Lead",
	 	"Magnesium", "Mercury", "Nickel", "Platinum", "Silver",
		"Tin", "Tungsten", "Uranium", "Zinc");

my $chart = new GD::Chart(400, 350);

my(%opts) = (
	data	=> \@data,
	labels	=> \@labels,
	chart_type => $GD::Chart::GDC_BAR,
	image_type => $GD::Chart::GDC_PNG,
	bgcolour  => hex 'ffffff',
	title => "Metals (in Earth Crust)",
	ytitle => "Parts per Million"
);
	
$chart->options(\%opts);

$chart->filename("bar1.png");

$chart->draw();

exit;
