#! /usr/bin/perl

use lib ("../lib");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;

my $image = new Image::BoxModel (
	width 	=> 800, 
	height 	=> 400, 
	lib		=> 'GD', 			# [IM|GD]
	verbose => 0,
	@ARGV						# used to automate via run_all_examples.pl
								# If you pass arguments directly from the command line be aware that there is no error-checking!
);	

$image -> Annotate (
	text			=> 'Hello @ Text-demo', 
	padding_top		=> 10, 
	padding_bottom	=> 20, 
	background 		=> "white", 
);

my $lowest = -4;
my $highest = 10;

$image -> Annotate (
	text 			=> "happiness (range from $lowest to $highest)", 
	textsize 		=> 14, 
	box_position 	=> 'left', 
	rotate			=> -90, padding_right => "10", 
	text_position 	=> 'Center', 
);

(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");