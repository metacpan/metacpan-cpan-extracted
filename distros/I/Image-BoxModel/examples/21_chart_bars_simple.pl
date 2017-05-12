#! /usr/bin/perl

use strict;
use warnings;

use lib ("../lib");	#if you don't install the module but just untar & run example

# this is the shortest way to draw a chart.

use Image::BoxModel::Chart;

#create a new object.
my $image = new Image::BoxModel::Chart (
	@ARGV			#used to automate via run_all_examples.pl
);	

#draw a simple chart:
print $image -> Chart (
	dataset_1 => [6,4,12],
	dataset_2 => [-3,2,3],
);

(my $name = $0) =~ s/\.pl$//;
# Save to file:
$image -> Save(file=> $name."_$image->{lib}.png");
