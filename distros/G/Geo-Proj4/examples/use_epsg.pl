#!/usr/bin/perl -w
# Example contributed by Michael R. Davis, see after __END__

use strict;
use warnings;
use Geo::Proj4 ();

my $epsg = 26985;
my $proj = Geo::Proj4->new(init => "epsg:$epsg")
  or die "cannot use EPSG 26985: ",Geo::Proj4->error, "\n";

my ($x, $y) = (401717.80, 130013.88);
my ($lat, $lon) = $proj->inverse($x, $y);
print "  x: $x\n  y: $y\nlat: $lat\nlon: $lon\n";

__END__

Proj4 EPSG Example
  Convert SPCS83 Maryland zone (meters) to Latitude and Longitude

Projection Input:
  Code - CRS: 26985
  CRS Name: NAD83 / Maryland
  CRS Type: projected
  Coord Sys code: 4499
  CS Type: Cartesian
  Dimension: 2
  Remarks: Used in projected and engineering coordinate reference systems.
  CRS Name: NAD83
  Datum Name: North American Datum 1983
  Datum Origin: Origin at geocentre.
  Ellipsoid Name: GRS 1980
  Ellipsoid Unit: metre
  Coord Operation Name: SPCS83 Maryland zone (meters)
  Coord Op Method Name: Lambert Conic Conformal (2SP)

Output
  Unprojected Latitude and Longitude, probably with GRS80 ellipsoids.

Copyright
  Copyright 2007 Michael R. Davis

License
  MIT, BSD, Perl, or GPL
