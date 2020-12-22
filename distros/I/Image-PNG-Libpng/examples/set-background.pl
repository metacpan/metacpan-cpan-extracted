#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
my $file = "$Bin/luv.png";
my %color = (red => 0xC0, green => 0xFF, blue => 0xFF);
my $png = create_reader ($file);
$png->set_background (\%color, PNG_BACKGROUND_GAMMA_SCREEN, 0);
$png->read_png ();
my $wpng = copy_png ($png);
$wpng->write_png_file ("$Bin/set-background.png");
