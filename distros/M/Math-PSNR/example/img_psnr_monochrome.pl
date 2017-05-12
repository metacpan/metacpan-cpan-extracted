#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.012000;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Math::PSNR;
use Imager;
use autodie;

my $img = Imager->new;
$img->read( file => "$FindBin::Bin/comp_barb.jpg" ) or die $img->errstr;

my $orig_img = Imager->new;
$orig_img->read( file => "$FindBin::Bin/orig_barb.jpg" ) or die $orig_img->errstr;

my $width  = $img->getwidth;
my $height = $img->getheight;

die 'Image size is different.'
  if ( $width != $orig_img->getwidth || $height != $orig_img->getheight );

my @pixels;
my @orig_pixels;
for ( 0 .. $height - 1 ) {
    push( @pixels, $img->getpixel( x => [ 0 .. $width - 1 ], y => $_ ) );
    push( @orig_pixels,
        $orig_img->getpixel( x => [ 0 .. $width - 1 ], y => $_ ) );
}

my @colors;
my @orig_colors;
my $pixels_len = scalar @pixels;
for ( 0 .. $pixels_len - 1 ) {
    my ($color)      = $pixels[$_]->rgba;
    my ($orig_color) = $orig_pixels[$_]->rgba;
    push( @colors,      $color );
    push( @orig_colors, $orig_color );
}

my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => \@colors,
        y   => \@orig_colors,
    }
);
print $psnr->psnr . "\n";
