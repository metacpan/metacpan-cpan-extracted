#!/usr/bin/perl -w

use strict;
use Image::EXIF;
use Data::Dumper;

my $exif = new Image::EXIF($ARGV[0] || "i424f2d1c0.jpg");

my $all_info = $exif->get_all_info();

print $exif->error ?
	$exif->errstr : Dumper($all_info);
