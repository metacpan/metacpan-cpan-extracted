#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::Similar 'load_image';
use Imager;
use FindBin '$Bin';
my $x = Imager->new ();
# Get image data from file
$x->read (file => "$Bin/x.png");
# Load image into Image::Similar
my $xi = load_image ($x);
my $y = Imager->new ();
# Get image data from file
$y->read (file => "$Bin/y.jpg");
# Load image into Image::Similar
my $yi = load_image ($y);
print "The difference is ", $xi->diff ($yi), ".\n";
