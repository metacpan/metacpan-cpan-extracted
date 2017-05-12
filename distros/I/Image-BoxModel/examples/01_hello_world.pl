#! /usr/bin/perl;

use lib ("../lib/");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;
  
# Define an object
my $image = new Image::BoxModel (
	width 		=> 800, 
	height 		=> 400, 
	lib			=> "GD", 	# [IM|GD]
	fontconfig 	=> 0,		# use the nice & easy to use fontconfig-library if it is available. 
							# Normally I don't in the examples, 
							# because there would be many errors if it was not available on the users system.
	verbose => "0",			# If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV					# used to automate via run_all_examples.pl
							# If you pass arguments directly from the command line be aware that there is no error-checking!
);
				
# Define a box named "title" on the upper border
print $image -> Box(
	position 	=> 'top', 
	height		=> 140, 
	name		=> 'title', 
	background 	=> 'red'
);	

# Put some rotated text on the "title"-box and demonstrate some options.
print $image -> Text(
	box 		=> 'title', 
	text		=> "Hello World!\nAligned right, positioned in the center (default)\nslightly rotated.", 
	position	=> 'SouthWest',
	textsize	=> 16,
	rotate 		=> 10, 
	fill 		=> 'yellow',
	background	=> 'green', 
	align		=> 'Right'
);

print $image -> Box(
	position 	=> 'left', 
	width		=> 200, 
	name		=> 'text_1', 
	background 	=> 'blue'
);	

print $image -> Text(
	box 		=> 'text_1', 
	text 		=> "More text.\nIt is positioned\nat the \n'North-West'-side\nof it's box.\nThe alignment\ndafaults to\ncenter\n:-)", 
	textsize	=> 12, 
	background	=> 'yellow', 
	position 	=> 'NorthWest'
);

print $image -> Text(
	box 		=> 'text_1', 
	text 		=> "..and some\nleft-aligned text\nin an 'South-East'\n-aligned box", 
	textsize 	=> 12, 
	position	=> 'SouthEast', 
	align		=>'lEFT',	# see? even though you are advised to use Left, the program is clever enough to get along with someting like that.
							# This enables the porgrammer to be somewhat sloppy.. ;-)
	background	=> 'yellow'
);
	
print $image -> Text(
	text 		=> "Some text on the shrinked 'standard-free-box'\nTo understand what this text means, give the documentation a read.",
	textsize => 12, 
	rotate=> "-30"
);

# Save image to file
(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");