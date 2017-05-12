#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::Similar;
use GD;
my $gd = GD::Image->newFromPng ("t/images/chess/chess-100.png");
my $is = Image::Similar::load_image_gd ($gd);
