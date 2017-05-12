#! /usr/bin/perl

# Specify borders of your bars and their color as you please.

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

$image -> BoxSplit (
	box 				=> 'free', 	# 'free' is the default box
	orientation			=> 'horizontal', 
	number 				=> 3,
	background_colors 	=> ['grey80', 'grey70', 'grey50'],
);


my @border = (1,2,5);
my @color = ('black', 'blue', 'green');

foreach my $box (0 .. 2){
	
	# padding on the right side of the chart
	$image -> Box(
		resize 		=> "free_$box",
		position	=> 'right',
		width		=> 10,
		name 		=> "free_${box}_padding_right",
		background 	=> $image -> {background}
	);

	# title
	$image -> Annotate(
		resize	 	=> "free_$box",
		text 		=> "Border $border[$box], Color $color[$box]",
		textsize 	=> 20,
		padding_bottom => 10,
	);

	$image -> Chart (
		box 		=> "free_$box",

		dataset_1 	=> [16,4,8,3,6,4,3],
		
		style 		=> 'bar',
		
		border_thickness => $border[$box],
		scale_ticks_thickness => $border[$box],
		values_ticks_thickness=> $border[$box],
		border_color=> $color[$box],
		
		values_annotations => ['a','b','c', 'd', 'e', 'f', 'g'],
	);
}

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

