#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename; # For fileparse().
use File::Spec;
use File::Temp;

use Image::Magick::Tiler;

use Test::More;

# ------------------------

# The EXLOCK option is for BSD-based systems.

my($temp_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);

my($result) = Image::Magick::Tiler -> new
(
	input_file	=> File::Spec -> catdir('t', 'sample.png'),
	geometry	=> '2x2+6+0',
	output_dir	=> $temp_dir,
	output_type	=> 'png',
	verbose		=> 1,
	write		=> 0,
);

isnt($result, undef, 'new() returned something');
isa_ok($result, 'Image::Magick::Tiler', 'new() returned an object of type Image::Magick::Tiler');

my($ara) = $result -> tile();

isnt($ara, undef, 'tile() returned something');
is($#$ara, 3, 'tile() returned an array ref of 4 elements');
isa_ok($$ara[0]{image}, 'Image::Magick', 'tile() returned an Image::Magick image');

my($name, $path, $suffix) = fileparse($$ara[0]{file_name});

is($name, '1-1.png', 'tile() returned a file name');

done_testing;
