#! /usr/bin/perl

# Pay attention with stapled_points! It may happen, that you staple mor points that fit on the chart. 
# Please check the result and see if you like it. 
# Better solutions are welcome.

use lib ("../lib");	# if you don't install the module but just untar & run example

use strict;
use warnings;


use Image::BoxModel::Chart;

my $image = new Image::BoxModel::Chart (
	width => 800, 
	height => 400, 
	lib=> "GD", 			# [IM|GD]
	verbose =>0,
	background => 'white',
	@ARGV			# used to automate via run_all_examples.pl
					# If you pass arguments directly from the command line be aware that there is no error-checking!
);	

print $image -> Chart (
	dataset_1 	=> [16,4,8,3,6,4,3],
	dataset_2 	=> [1,2,3,3,0,4,3],
	dataset_3 	=> [0,1,2,3,2,1,0],
	
	style 		=> 'stapled_points',
	thickness 	=> 15,
	
	values_annotations => ['a','b','c', 'd', 'e', 'f', 'g'],
);

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

