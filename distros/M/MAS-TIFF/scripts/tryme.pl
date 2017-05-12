#!/usr/bin/perl
#
# http://www.fileformat.info/format/tiff/corion.htm
#

use strict;
use warnings;

use MAS::TIFF::File;

my $path = 't/original.tif';
#my $path = 't/noisy.tif';
#my $path = 't/diffuse.tif';
#my $path = 't/multi.tif';

my $tif = MAS::TIFF::File->new($path);
$tif->dump;

#for my $ifd ($tif->ifds) {
#  my $pixel_reader = $ifd->pixel_reader;
#  
#  for my $y (0..70) {
#    for my $x (0..70) {
#      print &$pixel_reader($x, $y) ? '.' : '*';
#    }
#    print "\n";
#  }
#
#  for my $y (0..$ifd->image_length - 1) {
#    my $temp = &$pixel_reader(0, $y);
#  }
#}

$tif->close;

exit 0;
