#!/usr/bin/perl
#
# This takes information from the Debian developer database and draws
# an image of their locations.
#
# 2000-07-12 Leon Brocard acme@astray.com

use strict;
use LWP::Simple;
use Image::WorldMap;
use XML::Simple;

$| = 1;

my $filein = '../earth-small.png';
my $fileout = 'debian_developers.png';

my $map = Image::WorldMap->new($filein);

mirror("http://www.debian.org/devel/developers.coords", "developers.coords") unless -f "developers.coords";

open(IN, 'developers.coords');

while (defined(my $line = <IN>)) {
  next unless my ($latitude, $longitude) = $line =~ /([-+.0-9]+?)\s+([-+.0-9]+?)\s+/;
#  print "$longitude, $latitude\n";
  $map->add($longitude, $latitude);
}

$map->draw($fileout);

