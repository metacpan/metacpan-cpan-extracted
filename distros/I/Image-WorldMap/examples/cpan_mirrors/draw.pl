#!/usr/bin/perl
#
# This reads the CPAN MIRRORED.BY file and draws a graph
# of all the CPAN mirrors. A surprising amount are in Europe.
#
# 2000-01-16 Leon Brocard acme@astray.com

use strict;
use LWP::Simple;
use Image::WorldMap;

$| = 1;

my $filein = '../earth-small.png';
my $fileout = 'cpan_mirrors.png';

my $map = Image::WorldMap->new($filein);

mirror("http://www.cpan.org/MIRRORED.BY", "MIRRORED.BY") unless -f "MIRRORED.BY";

open(IN, 'MIRRORED.BY');

while (defined(my $line = <IN>)) {
#  next unless my ($latitude, $lat_dir, $longitude, $long_dir) = $line =~ /dst_location.+?\((.+?)(N|S) (.+?)(W|E)/;
#  dst_location     = "Florianopolis, Brazil, South America (-27.588 -48.575)"

  next unless my ($latitude, $longitude) = $line =~ /dst_location.+?\(([-.0-9]+?) ([-.0-9]+?)\)/;
#  $longitude = -$longitude if $long_dir =~ /W/i;
#  $latitude = -$latitude if $lat_dir =~ /S/i;
#  print "$longitude, $latitude\n";
  $map->add($longitude, $latitude);
}

$map->draw($fileout);

