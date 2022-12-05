# t/05_point.t - test file for Geo::Gpx::Point
use strict;
use warnings;

use Test::More tests => 11;
use Geo::Gpx::Point;

my %point_fields = ( lat => 45.483419, lon => 75.848268, ele => 260.91, name => 'MacKing', desc => "Mackenzie King Estate");

my $pt = Geo::Gpx::Point->new( %point_fields );
isa_ok ($pt, 'Geo::Gpx::Point');

#
# clone()
my $cl = $pt->clone;
isa_ok ($cl, 'Geo::Gpx::Point');

# the following change would make desc test below fail if clone() did not work properly
$cl->desc('clone now is amnesiac, where was this?');
is ($cl->desc, 'clone now is amnesiac, where was this?',          "   test clone() and desc field");

#
# to_geocalc()

# enable this test but skip if Geo::Calc is not available
# my $gc = $pt->to_geocalc();
# isa_ok ($gc, 'Geo::Calc');

#
# to_geocalc()

# enable this test but skip if Geo::TCX is not available
# my $tcx = $pt->to_tcx();
# isa_ok ($tcx, 'Geo::TCX::Trackpoint');

#
# test other fields
is ($pt->desc, 'Mackenzie King Estate',          "   test desc field");

#
# flex_coordinates()

my @lusk_cave = qw/ 45.5832 75.9816 /;
my $msa = \'47.0871  -70.9318';
my $pt_lc  = Geo::Gpx::Point->flex_coordinates(@lusk_cave, ele => 503 );
my $pt_msa = Geo::Gpx::Point->flex_coordinates($msa, desc => 'Mont Ste-Anne' );
isa_ok ($pt_lc,  'Geo::Gpx::Point');
isa_ok ($pt_msa, 'Geo::Gpx::Point');
is ($pt_lc->ele, '503',             "   test for ele field");
is ($pt_msa->desc, 'Mont Ste-Anne', "   test for desc field");

my $lat = q/ N45 32.298 /;
my $lon = q/ W75 52.066 /;
my @ruins = ( $lat, $lon);
my $pt_ruins = Geo::Gpx::Point->flex_coordinates(@ruins);
isa_ok ($pt_ruins, 'Geo::Gpx::Point');

#
# distance_to()

my ($some_pt, $p4, $dist);
$some_pt = Geo::Gpx::Point->new( lat => 45.405441, lon => -75.137497 );
$p4      = Geo::Gpx::Point->new( lat => 45.404692031443119, lon=> -75.140401963144541 );
$dist = $some_pt->distance_to( $p4 );
is($dist, 241.593745,                  "    distance_to(): we get the expected distance");
$dist = $some_pt->distance_to( $p4, dec => 2 );
is($dist, 241.59,                      "    distance_to(): we get the expected no of decimal points");

#
# Parking lot and other methods I could develop

print "so debugger doesn't exit\n";

