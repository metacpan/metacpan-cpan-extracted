#! /usr/bin/perl

use lib ("../lib");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel::Chart;

my $image = new Image::BoxModel::Chart (
	width 		=> 800, 
	height 		=> 400, 
	lib			=> "GD", 			# [IM|GD]
	verbose 	=>0,
	background 	=> 'white',

	@ARGV			# used to automate via run_all_examples.pl
					# If you pass arguments directly from the command line be aware that there is no error-checking!
);	

# print the main title
$image -> Annotate (
	text			=> 'some friends using this module', 
	padding_top		=>10, 
	textsize 		=> 20, 
	padding_bottom	=> 20, 		
);

# print scale annotation 
$image -> Annotate (
	text			=> "happiness\nis everything", 
	box_position 	=> "left", 
	rotate			=> -90, 
	textsize 		=> 15, 
	padding_right 	=> 10, 
	text_position 	=> 'Center', 
);

# print subtitle 
$image -> Annotate (
	text 			=> 'version of Image::BoxModel::Chart', 
	textsize 		=> 15, 
	box_position 	=> "bottom", 
	font 			=> './FreeSans.ttf'
);

# draw the legend
$image -> Legend(
	font 			=> './FreeSans.ttf',
	textsize 		=> 15,
	name => 'legend',
	values_annotations => ['Marc','Joss','Joe','Kim','Frederic','X','y',"other\nfriends"],
	border 			=> 1,
	padding_top 	=> 0,
	position 		=> 'right',	#left | right only at the moment. bug.
);

# define some arrays
my @a = [7,7,7];
my @val_ann = ['0.01', '0.04', '0.09', '0.10', '0.11', "(future)\nstable\nrelease"];

# ..and finally the chart
print $image -> Chart (
	dataset_00 		=> @a,				# you can pass named arrays
	dataset_01 		=> [-1,0,5,3,11.5,12], 
	dataset_02 		=> [5,5,5,5,4,7], 	# or you can define them directly here.
	dataset_999		=> [-3,-2,-1,8,9,10], 
	dataset_foo		=> [11,11,11,11],	# missing numbers are zerofilled (base-filled, precisely)
	dataset_50 		=> [1,1,1,1,1,1],
	dataset_51	 	=> [2,2,2,2,2,2],
	dataset_52 		=> [3,3,3,3,3,3],
	
	style 			=> 'bar',
	
	scale_annotation_rotate 	=> 0,
	scale_annotation_size 		=> 15,
	
	values_annotations 			=> @val_ann,
	values_annotation_rotate 	=> -70,
	values_annotation_size 		=> 15,

);


(my $name = $0) =~ s/\.pl$//;
# Save image to file
$image -> Save(file=> $name."_$image->{lib}.png");
