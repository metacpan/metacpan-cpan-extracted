#! /usr/bin/perl;

use lib ("../lib/");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;
  
#Define an object
my $image = new Image::BoxModel (
	width 		=> 800, 
	height 		=> 400, 
	lib			=> "GD", 			# [IM|GD]
	fontconfig	=> 0,		
	#~ verbose 	=> "0",				# If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV							# used to automate via run_all_examples.pl
									#If you pass arguments directly from the command line be aware that there is no error-checking!
);

# Get yourselves some boxes (you don't have to if you pass DrawRectangle / DrawCircle absolute coordinates)

$image -> BoxSplit (
	box 			=> 'free', 	# 'free' is the default box
	orientation		=> 'vertical', 
	number 			=> 4,
	background 		=> 'white',
	border_color	=> 'black', 
	border_thickness => 1		# not really necessary to set it to 1 as it defaults to that value anyway
 );
 
 for (0 .. 3){
	$image -> BoxSplit (
		box 		=> "free_$_", 	# for the naming of the baby boxes see example 04_box_split.pl
		orientation	=> 'horizontal',
		number		=> 8,
		background 		=> 'white',
		border_color	=> 'black', 
		border_thickness => 1		# not really necessary to set it to 1 as it defaults to that value anyway
	);
}

$image -> DrawRectangle(	# a filled rectangle without border
	left 	=> $image -> {free_0_0}{left}	+ 10,
	top 	=> $image -> {free_0_0}{top} 	+ 10,
	right	=> $image -> {free_0_0}{right} 	- 10,
	bottom 	=> $image -> {free_0_0}{bottom} - 10,
	
	color 	=> 'blue',
);

$image -> DrawRectangle(	# a filled rectangle with a border of a different color
	left 	=> $image -> {free_0_1}{left}	+ 10,
	top 	=> $image -> {free_0_1}{top} 	+ 10,
	right	=> $image -> {free_0_1}{right} 	- 10,
	bottom 	=> $image -> {free_0_1}{bottom} - 10,
	
	fill_color 	=> 'blue',
	border_color=> 'red',
	border_thickness => 10,
);

$image -> DrawCircle(		# a circle without border
	left 	=> $image -> {free_0_2}{left}	+ 10,
	top 	=> $image -> {free_0_2}{top} 	+ 10,
	right	=> $image -> {free_0_2}{right} 	- 10,
	bottom 	=> $image -> {free_0_2}{bottom} - 10,
	
	color 	=> 'orange',
);

$image -> DrawCircle(		# a circle without a border of a different color
	left 	=> $image -> {free_0_3}{left}	+ 10,
	top 	=> $image -> {free_0_3}{top} 	+ 10,
	right	=> $image -> {free_0_3}{right} 	- 10,
	bottom 	=> $image -> {free_0_3}{bottom} - 10,

	fill_color => 'orange', 
	border_color=>'black', 
	border_thickness => 4
);

# as you can easily see it is no problem at all to draw across box borders..

foreach (
	$image -> {free_0_4}{left},
	$image -> {free_0_4}{left} + ($image -> {free_0_4}{right} - $image -> {free_0_4}{left}) / 2, # middle of box
	$image -> {free_0_5}{left},
	$image -> {free_0_5}{left} + ($image -> {free_0_4}{right} - $image -> {free_0_4}{left}) / 2, # middle of box
	){	# some lines without border
		
	$image -> DrawLine(
		x1 		=> $_,
		y1		=> $image -> {free_0_4}{top} 	+ 10,
		x2		=> $image -> {free_0_4}{right} 	- 10,
		y2	 	=> $image -> {free_0_4}{bottom} - 10,
		
		color 	=> 'green',
		thickness => 10,
	);
}


(my $name = $0) =~ s/\.pl$//;
#Save image to file
$image -> Save(file=> $name."_$image->{lib}.png");