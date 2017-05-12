#!/usr/bin/perl

use strict;
use warnings;

use Geo::Proj4;

my $proj = Geo::Proj4->new( proj => "utm", zone => 10 );
my ($x, $y) = $proj->forward(38.40342, -122.81856);
print "conversion to UTM: y is  $y\n";
print "conversion to UTM: x is  $x\n";

my ($lat, $long) = $proj->inverse($x, $y);
print "inverse conversion: lat is $lat \n" ;
print "inverse conversion: long is $long \n" ;

