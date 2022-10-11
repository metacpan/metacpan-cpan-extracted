# t/05_point.t - test file for Geo::Gpx::Point
use strict;
use warnings;

use Test::More tests => 10;
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

my $gc = $pt->to_geocalc();
isa_ok ($gc, 'Geo::Calc');

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
# Parking lot and other methods I could develop

print "so debugger doesn't exit\n";

