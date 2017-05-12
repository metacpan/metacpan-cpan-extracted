# -*-cperl-*-
# $Id: 20-convert_geotude.t,v 1.1 2007/07/12 05:17:22 asc Exp $

use strict;
use Test::More;
plan tests => 4;

use_ok("Geo::Geotude");

my $gt  = '53281.86.93.30.75.41.67';
my $lat = '3.106254';
my $lon = '101.630517';

my $geo = Geo::Geotude->new('geotude' => $gt);
isa_ok($geo, "Geo::Geotude");

my ($lt, $ln) = $geo->point();

cmp_ok($lt, 'eq', $lat, "latitude: $lat");
cmp_ok($ln, 'eq', $lon, "longitude: $lon");
