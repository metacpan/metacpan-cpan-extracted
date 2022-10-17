# t/02_track.t - testing file for Track.pm
use strict;
use warnings;

use Test::More tests => 53;
use Geo::TCX;

#
# Section A - Track.pm

# note that one of the trackpoints in the track_string below, purposely does not contain any <Position>...</Position> data
my $track_string = '<Track><Trackpoint><Time>2014-08-11T10:25:23Z</Time><Position><LatitudeDegrees>45.305054</LatitudeDegrees><LongitudeDegrees>-72.637287</LongitudeDegrees></Position><AltitudeMeters>210.963</AltitudeMeters><DistanceMeters>5.704</DistanceMeters><HeartRateBpm><Value>75</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:26Z</Time><Position><LatitudeDegrees>45.304996</LatitudeDegrees><LongitudeDegrees>-72.637243</LongitudeDegrees></Position><AltitudeMeters>211.082</AltitudeMeters><DistanceMeters>13.030</DistanceMeters><HeartRateBpm><Value>80</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:28Z</Time><Position><LatitudeDegrees>45.304957</LatitudeDegrees><LongitudeDegrees>-72.637210</LongitudeDegrees></Position><AltitudeMeters>211.080</AltitudeMeters><DistanceMeters>18.044</DistanceMeters><HeartRateBpm><Value>85</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:29Z</Time><Position><LatitudeDegrees>45.304934</LatitudeDegrees><LongitudeDegrees>-72.637199</LongitudeDegrees></Position><AltitudeMeters>211.008</AltitudeMeters><DistanceMeters>20.741</DistanceMeters><HeartRateBpm><Value>91</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:33Z</Time><Position><LatitudeDegrees>45.304907</LatitudeDegrees><LongitudeDegrees>-72.637078</LongitudeDegrees></Position><AltitudeMeters>211.027</AltitudeMeters><DistanceMeters>32.002</DistanceMeters><HeartRateBpm><Value>93</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:36Z</Time><Position><LatitudeDegrees>45.304851</LatitudeDegrees><LongitudeDegrees>-72.637002</LongitudeDegrees></Position><AltitudeMeters>211.504</AltitudeMeters><DistanceMeters>40.867</DistanceMeters><HeartRateBpm><Value>94</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:40Z</Time><AltitudeMeters>211.420</AltitudeMeters><DistanceMeters>53.348</DistanceMeters><HeartRateBpm><Value>99</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:41Z</Time><Position><LatitudeDegrees>45.304735</LatitudeDegrees><LongitudeDegrees>-72.637054</LongitudeDegrees></Position><AltitudeMeters>211.203</AltitudeMeters><DistanceMeters>56.596</DistanceMeters><HeartRateBpm><Value>99</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:46Z</Time><Position><LatitudeDegrees>45.304631</LatitudeDegrees><LongitudeDegrees>-72.637257</LongitudeDegrees></Position><AltitudeMeters>210.141</AltitudeMeters><DistanceMeters>76.773</DistanceMeters><HeartRateBpm><Value>94</Value></HeartRateBpm></Trackpoint><Trackpoint><Time>2014-08-11T10:25:51Z</Time><Position><LatitudeDegrees>45.304450</LatitudeDegrees><LongitudeDegrees>-72.637330</LongitudeDegrees></Position><AltitudeMeters>209.562</AltitudeMeters><DistanceMeters>97.855</DistanceMeters><HeartRateBpm><Value>84</Value></HeartRateBpm></Trackpoint></Track>';

my $t = Geo::TCX::Track->new($track_string);
isa_ok ($t, 'Geo::TCX::Track');

#
# trackpoint() method, using only latitudes

my $o = Geo::TCX->new ('t/2014-08-11-10-25-15.tcx');

my @answers_begin = ( 45.305113, 45.297959, 45.295806, 45.293131);
my @answers_end = ( 45.298015, 45.295845, 45.293122, 45.291618);
for (my $i = 0; $i < 4; $i++) {
    my $lap_i = $i+1;
    my $l = $o->lap($lap_i);
    my ($pt_begin, $pt_end) = ( $l->trackpoint(1), $l->trackpoint(-1) );
    is($pt_begin->LatitudeDegrees, $answers_begin[$i],      "    test begin waypoint of lap $lap_i");
    is($pt_end->LatitudeDegrees,   $answers_end[$i],        "    test end waypoint of lap $lap_i");
}

#
# trackpoint() method, using only longitudes

@answers_begin = ( -72.637326, -72.655698, -72.650486, -72.650505);
@answers_end = ( -72.655766, -72.650482, -72.650406, '-72.650220');
for (my $i = 0; $i < 4; $i++) {
    my $lap_i = $i+1;
    my $l = $o->lap($lap_i);
    my ($pt_begin, $pt_end) = ( $l->trackpoint(1), $l->trackpoint(-1) );
    is($pt_begin->LongitudeDegrees, $answers_begin[$i],     "    test begin waypoint of lap $lap_i");
    is($pt_end->LongitudeDegrees,   $answers_end[$i],       "    test end waypoint of lap $lap_i");
}

#
# trackpoint() again

my $l2 = $o->lap(2);
my $l3 = $o->lap(3);
my $t_end = $l2->trackpoint(-1);
my $t_beg = $l3->trackpoint(1);
is($t_end->DistanceMeters,   3000.923,          "    test DistanceMeters of last trackpoint of lap 2");
is($t_beg->DistanceMeters,   3005.432,          "    test DistanceMeters of first trackpoint of lap 3");

#
# trackpoints()

my ($point2, $point3, $point4) = $t->trackpoints( 2 .. 4 );
my $scalar3 = $t->trackpoints( 2 .. 4 );
my $npoints = $t->trackpoints();
is ($scalar3, 3,                                "   tests that trackpoints() returns scalar if in scalar context");
is ($npoints, 10,                               "   tests that trackpoints() returns number of trackpoints if called without arguments");
is ($point2->isa('Geo::TCX::Trackpoint'), 1, "   tests that trackpoints() retur array of points references");
is ($point3->isa('Geo::TCX::Trackpoint'), 1, "   tests that trackpoints() retur array of points references");
is ($point4->isa('Geo::TCX::Trackpoint'), 1, "   tests that trackpoints() retur array of points references");
is($point2->HeartRateBpm, 80,                   "   test that we can access that point with attibutes");
is($point4->HeartRateBpm, 91,                   "   test that we can access that point with attibutes");

#
# split()

my ($t1, $t2) = $t->split(8);
is($t1->trackpoints, 8,             "   split(): test that we get right number of trackpoints");
is($t2->trackpoints, 2,             "   split(): test that we get right number of trackpoints");
# we should actually check something more precise, like the time of the 1st and last trackpoints of each
is($t->trackpoints, 10,                             "   split(): test that the track used for the split is left intact");

#
# split_at_point_closest_to()

my $coord_str = '45.30542 -72.63563';   # intersection Montcalm & Stanstead
my $pt = Geo::Gpx::Point->flex_coordinates( \$coord_str );
($t1, $t2) = $t->split_at_point_closest_to( $coord_str );
is($t1->trackpoints, 6,             "   split(): test that we get right number of trackpoints");
is($t2->trackpoints, 4,             "   split(): test that we get right number of trackpoints");
# we should actually check something more precise, like the time of the 1st and last trackpoints of each

#
# merge()

# modify $t2 to make it look like it came from a completely different activity
$t2->time_add( years => 1, months => 2, days => 9, hours => 3, minutes => 22, seconds => 10 );

# delete the last point of t1 and the first point of t2
my ($t3, $t4) = $t1->split(5);
# my ($t3, $t4) = $t1->split(-1);
# oh split with -1 doesn't split at last point: fix that
my ($t5, $t6) = $t2->split(1);

my $t7 = $t3->merge($t6);
is($t7->trackpoints, 8,                             "   merge(): test that we get right number of trackpoints");
is($t7->trackpoint(-1)->DistanceMeters,   92.478,   "   merge(): DistanceMeters of merged track");
is($t7->trackpoint(6)->Time, '2014-08-11T10:25:36Z',"   merge(): check Time of first trackpoint of 2nd tracked merged");
is($t3->trackpoints, 5,                             "   merge(): test that the tracks used for the merge are left intact");
is($t6->trackpoints, 3,                             "   merge(): test that the tracks used for the merge are left intact");

#
# clone(), xml_string()

my $c = $t->clone;
# is_deeply( $c, $t,                " clone(): test that the data structures");
# is_deeply does not work because of operator overloading
is($c->xml_string, $track_string, "   xml_string(): reproduces the original string, indirect way to test clone()");

#
# time_add() -- add 1 day and 5 seconds to all points, check return values (should be nothing)

my $ret_val = $c->time_add( days => 1, seconds => 5 );
is($c->trackpoint(4)->Time, '2014-08-12T10:25:34Z', "   time_add(): picked one point, has Time been incremented properly?");
is($ret_val, 1,                                     "   time_add(): return value");

#
# point_closest_to()

my @coords = ( 45.40820, -75.75663 );
my $point_ramp_to_bridge = Geo::Gpx::Point->flex_coordinates(@coords);
isa_ok ($point_ramp_to_bridge, 'Geo::Gpx::Point');

my $o2 = Geo::TCX->new ('t/2022-08-21-00-34-06.tcx');

my $l = $o2->lap(2);
my ($closest_pt, $meters, $pt_no) = $l->point_closest_to($point_ramp_to_bridge);
isa_ok ($closest_pt, 'Geo::TCX::Trackpoint');
is ($pt_no,  14,                 "   point_closest_to(): test which point is the closest one");
is ($meters, 76.000892,          "   point_closest_to(): test meters from the point");

#
# reverse()

my ($t_shorter, $t_rest) = $t->split(5);
my $rev = $t_shorter->reverse;
my $t_shorter_clone = $t_shorter->clone;

is ($rev->trackpoint(2)->distance_elapsed,  11.261,   "   reverse(): expected elapsed distance between 2nd and 1st point");
is ($rev->trackpoint(3)->distance_elapsed,  2.697,    "   reverse(): expected elapsed distance between 3rd and 2nd point");
is ($rev->trackpoint(2)->time_elapsed,  4,            "   reverse(): expected elapsed distance between 2nd and 1st point");
is ($rev->trackpoint(3)->time_elapsed,  1,            "   reverse(): expected elapsed distance between 3rd and 2nd point");
is ($rev->trackpoint(4)->time_elapsed,  2,            "   reverse(): expected elapsed distance between 3rd and 2nd point");
# is_deeply( $t_shorter, $t_shorter_clone,             "   reverse(): test that original track is left intact");
# - is_deeply does not work because of operator overloading
# - testing by comparing a few points instead:
is ($t_shorter_clone->trackpoint(5)->distance_elapsed,  11.261,   "   reverse(): test that original track is left intact");
is ($t_shorter_clone->trackpoint(4)->distance_elapsed,  2.697,    "   reverse(): test that original track is left intact");
is ($t_shorter_clone->trackpoint(5)->time_elapsed,  4,            "   reverse(): test that original track is left intact");
is ($t_shorter_clone->trackpoint(4)->time_elapsed,  1,            "   reverse(): test that original track is left intact");
is ($t_shorter_clone->trackpoint(3)->time_elapsed,  2,            "   reverse(): test that original track is left intact");

print "so debugger doesn't exit\n";

