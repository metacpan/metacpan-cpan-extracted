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
									# If you pass arguments directly from the command line be aware that there is no error-checking!
);

# There always is a "default-fallback". FreeSans.ttf is stored in the module's backend-directory and used if
# - you don't specify a font
# - your font is not found

# Simplest invocation: Just define text and let it choose the default font.
# (textsize is set because 12-pixel-fonts are a poorly readable.)
$image -> Annotate (
	text 	 => 'Hello. This is some text in different fonts.',	# mandatory
	textsize => 20,
);

$image -> Annotate (
	text 	 => 'Hello. This is some text in different fonts.',	# mandatory
	textsize => 20,
	font	 => 'FreeMono.ttf'								
);

$image -> Annotate (
	text 	 => 'Hello. This is some text in different fonts.',	# mandatory
	textsize => 20,
	font	 => 'FreeSerif.ttf'								
);


# If you define a non-existent font, it silently falls back to the default font.
$image -> Annotate (
	text 	 => 'Hello. This is some text in different fonts.',	# mandatory
	textsize => 20,
	font	 => 'gaga.nofont'
);



(my $name = $0) =~ s/\.pl$//;
# Save image to file
$image -> Save(file=> $name."_$image->{lib}.png");