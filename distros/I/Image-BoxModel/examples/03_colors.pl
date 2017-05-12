#! /usr/bin/perl;

use lib ("../lib");	# if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;
  
# Define an object
my  $image = new Image::BoxModel (
	width 	=> 800, 
	height 	=> 400, 
	lib		=> "IM", 			# [IM|GD]
	verbose => "0",				# If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV						# used to automate via run_all_examples.pl
								# If you pass arguments directly from the command line be aware that there is no error-checking!
);
				
print $image -> Box(position =>'top', height=>60, name=>'title', background =>'#cccccc');		#html-style colors
print $image -> Text(box =>'title', text=>'some nice colors', textsize => '20');

my $color;

foreach (
		'LightYellow', 
		'yellow', 
		'orange', 
		'red', 
		'DarkRed', 
		'BlueViolet', 
		'DarkBlue', 
		'blue', 
		'SlateBlue', 
		'DarkGreen', 
		'green', 
		'LightGreen', 
		'silver', 
		'gold', 
		'black', 
		'white'
	){
		
	if ($_ eq 'black'){
		$color = 'white' ;
	}
	else{
		$color = 'black';
	}
	$image -> Annotate (position =>'bottom', text=> $_,background =>$_, font => './FreeSans.ttf', color => $color);
}

#Save image to file
(my $name = $0) =~ s/\.pl$//;
$image -> Save(file=> $name."_$image->{lib}.png");