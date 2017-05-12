#! /usr/bin/perl

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
	@ARGV					# used to automate via run_all_examples.pl
							# If you pass arguments directly from the command line be aware that there is no error-checking!
);	

print $image -> Chart (
	dataset_1 			=> [6,4,8],
	dataset_2 			=> [1,2,3],
	
	style 				=> 'point',
	thickness 			=> '25',
	
	values_annotations 	=> ['a','b','c'],
	
);

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

