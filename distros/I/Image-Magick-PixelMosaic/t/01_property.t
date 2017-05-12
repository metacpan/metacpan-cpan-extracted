
use strict;
use warnings;

package Dummy;
sub new { bless [],$_[0] }

package main;

use Test::More tests => 13;

use Image::Magick;
use Image::Magick::PixelMosaic;

## new 1
my $pix = Image::Magick::PixelMosaic->new;
ok( $pix );
is( $pix->src, undef );

undef $pix;


## new 2
my $img = Image::Magick->new;
$pix = Image::Magick::PixelMosaic->new(src=>$img);
ok( $pix );
is( ref $pix->src, ref $img );

$pix = Image::Magick::PixelMosaic->new(src=>undef);
ok( $pix );
is( $pix->src, undef );

undef $pix;

## new (type error)
$@ = undef;
eval { Image::Magick::PixelMosaic->new(src=>Dummy->new) };
ok ( $@ );


## src
$pix = Image::Magick::PixelMosaic->new;
is( $pix->src, undef );
is( ref $pix->src($img), ref $img );
is( ref $pix->src, ref $img );
is( ref $pix->src(undef), ref $img );
is( ref $pix->src, ref $img );

## src (type error)
$@ = undef;
eval { $pix->src(Dummy->new); };
ok ( $@ );
