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

# Split the whole image into 9 boxes.

$image -> BoxSplit (
	box 				=> 'free', 	# 'free' is the default box
	orientation			=> 'vertical', 
	number 				=> 9,
	background_colors 	=> ['yellow', 'orange', 'red', 'violet', 'blue'], # you don't need to specify as many colors as you make baby-boxes
 );
 
# Split the bottom-most baby-box into 4 boxes.

$image -> BoxSplit (
	box					=> 'free_8', # Baby-boxes get the name of their parent, then an underscore, then the number
									 # pay attention! Baby-number range from 0 to max-1
	orientation			=> 'horizontal',
	number				=> '4',
	background_colors	=> ['grey30', undef, 'grey80','black'] # to leave out boxes in the middle, undef the value. '' would die.
);


# And of course, you can put things on baby-boxes, too:

$image -> Annotate (
	text	=> 'Hello',
	name	=> 'free_3',
);

$image -> DrawCircle (
	left 	=> $image -> {free_8_1}{left},
	top 	=> $image -> {free_8_1}{top}, 	
	right	=> $image -> {free_8_1}{right},
	bottom 	=> $image -> {free_8_1}{bottom},
	
	color 	=> 'orange',
);
$image -> Annotate (
	text		=> ':-)',
	textsize	=> '20',
	name		=> 'free_8_1',
);
	

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

