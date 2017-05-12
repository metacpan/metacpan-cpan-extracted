# -*-cperl-*-
# $Id: 10-convert_point.t,v 1.2 2007/07/12 13:59:37 asc Exp $

use strict;
use Test::More;
plan tests => 6;

use_ok("Geo::Geotude");

my $lat = '3.106254';
my $lon = '101.630517';
my $major = '53281';
my $minor = '86.93.30.75.41.67';
my $combined = join(".", ($major, $minor));

my $geo = Geo::Geotude->new('latitude' => $lat, 'longitude' => $lon);
isa_ok($geo, "Geo::Geotude");

my $gt = $geo->geotude();
cmp_ok($gt, 'eq', $combined, "geotude: $combined");

my @gt = $geo->geotude();
cmp_ok(scalar(@gt), '==', 2, "wantarray ok");

cmp_ok($gt[0], 'eq', $major, "major : $major");
cmp_ok($gt[1], 'eq', $minor, "minor : $minor");
