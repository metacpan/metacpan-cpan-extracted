#! /usr/bin/perl

# As I have not found a clever way to guess the thickness of points and lines, I let you specify it by your self.
# Find out, what you like most.
# See how we put some pixels apart to ensure that your lines fit onto the chart! :-)

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

my @thickness = (3,5,15);
my @style  = ('point', 'line');

foreach my $row (0 .. 2){
	
	# padding on the right side of the chart
	$image -> Box(
		resize 		=> "free_$row",
		position	=> 'right',
		width		=> 10,
		name 		=> "free_${row}_padding_right",
		background 	=> $image -> {background}
	);

	# title
	$image -> Annotate(
		resize	 	=> "free_$row",
		text 		=> "Thickness $thickness[$row]",
		textsize 	=> 20,
		padding_bottom => 10,
	);
	
	$image -> BoxSplit (
		box			=> "free_$row",
		orientation	=> 'vertical',
		number		=> 2,
	);
	
	for my $col (0 .. 1){
		$image -> Box(
			resize		=> "free_${row}_$col",
			position	=> 'bottom',
			height		=> 10,
			name		=> "free_${row}_${col}_padding_bottom",
		);

		$image -> Chart (
			box 		=> "free_${row}_$col",
			dataset_1 	=> [5,4,0,3,6,4,3],
			scale_skip 	=> 1,
			style 		=> $style[$col],
			thickness	=> $thickness[$row],
			values_annotations => ['a','b','c', 'd', 'e', 'f', 'g'],
		);
	}
}

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

