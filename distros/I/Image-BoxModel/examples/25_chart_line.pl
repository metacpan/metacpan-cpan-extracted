#! /usr/bin/perl

use lib ("../lib");	#if you don't install the module but just untar & run example

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
	dataset_1 => [16,4,8,3,6,4,3],
	dataset_2 => [1,2,3,3,0,4,3],
	dataset_3 => [0,4,-2,3,-10,1,0],
	
	style => 'line',
	
	thickness => 5,
	
	values_annotations => ['a','b','c', 'd', 'e', 'f', 'g'],
	
	#~ offset => 1,		# see what happens. :-) hard to explain, easy to understand visually.
);

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

