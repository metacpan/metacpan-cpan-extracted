#! /usr/bin/perl;

use lib ("../lib");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;

# Define an object
my  $image = new Image::BoxModel (
	width 	=> 500, 
	height 	=> 300, 
	lib		=> "GD", 			# [IM|GD]
	verbose => "0",				# If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV						# used to automate via run_all_examples.pl
								# If you pass arguments directly from the command line be aware that there is no error-checking!
);

# Define a floating box. Attention, there is no error-checking at the moment, so be careful!
print $image -> FloatBox(top =>100, bottom=>200, right=> 300, left=> 200, name=>"floatbox", background =>'red');

# Put some rotated text on the box
print $image -> Text(box=> "floatbox", text => "Hello\nFloatbox", textsize => 12);

# Save image to file
(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");

