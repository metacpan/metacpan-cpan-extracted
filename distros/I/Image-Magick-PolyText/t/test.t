#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Image::Magick;
use Image::Magick::PolyText::FreeType;

# ------------------------------------

my($image)	= Image::Magick -> new(size => '800 x 400');
my($result)	= $image -> Read('xc:white');
$result		= $image -> Set(font => 't/n019003l.pfb');
my($x_1)	= [100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700];
my($y_1)	= [100, 147, 184, 199, 190, 159, 114, 65, 25, 3, 5, 30, 73];
my($x_2)	= [100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700];
my($y_2)	= [250, 297, 334, 349, 340, 309, 264, 215, 175, 153, 155, 180, 223]; # $y_1[*] + 150.
my($writer)	= Image::Magick::PolyText -> new
(
	image	=> $image,
	text	=> 'Draw text along a polyline',
	x		=> $x_1,
	y		=> $y_1,
);

ok(defined $writer);
ok($writer -> isa('Image::Magick::PolyText') );
ok($writer -> image -> isa('Image::Magick') );
ok($writer -> fill eq 'Red');
ok($writer -> pointsize == 16);

$writer -> draw(stroke => 'red');
$writer -> highlight_data_points(stroke => 'black');
$writer -> annotate;

note "Image depth: @{[$image -> get('depth')]} bits per pixel";

done_testing();
