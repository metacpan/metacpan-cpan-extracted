#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::Similar 'load_image';
use GD;
my $gd = GD::Image->newFromPng ("t/images/chess/chess-100.png");
my $is = load_image ($gd);
