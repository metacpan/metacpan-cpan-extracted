#!/usr/bin/perl -w
use strict;

use GD::Chart::Radial;

my $chart = GD::Chart::Radial->new(500,500,1);

my $max = 31;

$chart->set(
	    legend            => [qw/april may/],
	    title             => 'Some simple graph',
	    y_max_value       => $max,
	    y_tick_number     => 5,
	   );

my @data = ([qw/A B C D E F G/],[12,21,23,30,23,22,5],[10,20,21,24,28,15,9]);

$chart->plot(\@data);

open(IMG, '>test.jpg') or die $!;
binmode IMG;
print IMG $chart->jpg;
close IMG
