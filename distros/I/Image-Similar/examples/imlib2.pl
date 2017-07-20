#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::Similar 'load_image';
use Image::Imlib2;
my $imlib2 = Image::Imlib2->load ("t/images/chess/chess-100.png");
my $is = load_image ($imlib2);
