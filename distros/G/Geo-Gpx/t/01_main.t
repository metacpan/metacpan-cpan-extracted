# t/01_main.t - main testing file (for Gpx.pm)
use strict;
use warnings;

use Test::More tests => 38;
use Geo::Gpx;
use File::Temp qw/ tempfile tempdir /;
use Cwd qw(cwd abs_path);

my $cwd     = abs_path( cwd() );
my $tmp_dir = tempdir( CLEANUP => 1 );

my $href_chez_andy = { lat => 54.786989, lon => -2.344214, ele => 512, time => 1164488503, magvar => 0, geoidheight => 0, name => 'My house & home', cmt => 'Where I live', desc => '<<Chez moi>>', src => 'Testing', link => { href => 'http://hexten.net/', text => 'Hexten', type => 'Blah' }, sym => 'Flag, Green', type => 'unknown', fix => 'dgps', sat => 3, hdop => 10, vdop => 10, pdop => 10, ageofdgpsdata => 45, dgpsid => 247 };

my $href_chez_pat  = { lat => 45.93789, lon => -75.85077, lon => -2.344214, ele => 550, time => 1167813923, magvar => 0, geoidheight => 0, name => 'Atop Radar Road', cmt => 'This key is cmt', desc => '<<This key is desc>>', src => 'Testing', sym => 'pin', type => 'unknown', fix => 'dgps', sat => 3, hdop => 10, vdop => 10, pdop => 10, ageofdgpsdata => 54, dgpsid => 247 };

my $href_chez_kaz = { lat => 45.94636, lon => -76.01154, 'sym' => 'Parking Area' };

my $o  = Geo::Gpx->new();
isa_ok ($o,  'Geo::Gpx');

$o->waypoints_add( $href_chez_andy, $href_chez_pat );
$o->waypoints_add( $href_chez_kaz );

#
# Section A - Constructor

# new(): from filename (file with only waypoints)
my $fname_wpt1 = 't/larose_wpt.gpx';
my $o_wpt_only1 = Geo::Gpx->new( input => "$fname_wpt1" );
isa_ok ($o_wpt_only1,  'Geo::Gpx');

# new(): from filename (file with only trackpoints)
my $fname_trk1 = 't/larose_trk1.gpx';
my $o_trk_only1 = Geo::Gpx->new( input => "$fname_trk1" );
isa_ok ($o_trk_only1,  'Geo::Gpx');
my $fname_trk2 = 't/larose_trk2.gpx';
my $o_trk_only2 = Geo::Gpx->new( input => "$fname_trk2" );
isa_ok ($o_trk_only2,  'Geo::Gpx');

# new(): from filehandle
open( my $fh , '<', $fname_wpt1 ) or  die "can't open file $fname_wpt1 $!";
my $o_from_fh = Geo::Gpx->new( input => $fh );
isa_ok ($o_from_fh,  'Geo::Gpx');

# NextSteps: create a new empty gpx file, add the waypoints, add a track, then add another track (do we have a method to add another track like waypoints_add()

#
# Section B - Object Methods

# *_count() accessors:
is($o_trk_only1->waypoints_count, 0,   "    waypoints_count(): test the number of waypoints found");
is($o->routes_count, 0,                "    routes_count(): test the number of routes found");
is($o->tracks_count, 0,                "    tracks_count(): test the number of tracks found");

# waypoints_add(): will likely rename waypoints_add()
my %point = ( lat => 54.786989, lon => -2.344214, ele => 512, time => 1164488503, name => 'My house', desc => 'There\'s no place like home' );
my $pt = Geo::Gpx::Point->new( %point );
$pt->sym('Triangle, Blue');
$o->waypoints_add( $pt );
is($o->waypoints_count, 4,             "    waypoints_add(): test the number of waypoints found");

# waypoints():
my $gotten1 = $o->waypoints( name => 'My house' );
my $gotten2 = $o->waypoints( 4 );
is_deeply ($gotten1, $gotten2,         "    waypoints(): compare waypoints obtained with name => \$name and integer index");
my $waypoints_ret_val;
$waypoints_ret_val = $o->waypoints( name => 'There are none with that name' );
is($waypoints_ret_val, undef,          "    waypoints(): no exception raised if name is not found, return undef");
$waypoints_ret_val = $o->waypoints( 5 );
is($waypoints_ret_val, undef,          "    waypoints(): no exception raised if index is not found, return undef");

# tracks_add():
my $track1 = $o_trk_only1->tracks( 1 );
my $track2 = $o_trk_only2->tracks( 1 );
$o_wpt_only1->tracks_add( $track1, name => 'My first track' );
$o_wpt_only1->tracks_add( $track2 );
my $get_track = $o_wpt_only1->tracks( name => '2020-10-25T20:36:07Z' );
is($o_wpt_only1->tracks_count, 2,      "    tracks_add(): test the number of tracks found");

# tracks_add(): test also with aref's
my $aref1 = [
    { lat => 45.405441, lon => -75.137497,  ele => -0.301, time => '2020-10-25T21:34:31Z' },
    { lat => 45.405291, lon => -75.137528,  ele => -0.098, time => '2020-10-25T21:34:35Z' },
    { lat => 45.405147, lon => -75.137508,  ele => -0.233, time => '2020-10-25T21:34:38Z' },
    { lat => 45.405050, lon => -75.137655,  ele => -0.512, time => '2020-10-25T21:34:41Z' },
    { lat => 45.404993, lon => -75.137781,  ele => -0.108, time => '2020-10-25T21:34:43Z' },
];
my $aref2 = [
    { lat => 45.404952, lon => -75.137896,  ele =>  0.057, time => '2020-10-25T21:34:45Z' },
    { lat => 45.405009, lon => -75.138072,  ele => -0.518, time => '2020-10-25T21:34:48Z' },
    { lat => 45.405023, lon => -75.138386,  ele => -0.613, time => '2020-10-25T21:34:53Z' },
    { lat => 45.405017, lon => -75.138450,  ele => -0.442, time => '2020-10-25T21:34:54Z' },
    { lat => 45.405042, lon => -75.138751,  ele => -0.704, time => '2020-10-25T21:34:59Z' },
];
my $aref3 = [
    { lat => 45.405051, lon => -75.138798,  ele => -0.656, time => '2020-10-25T21:35:00Z' },
    { lat => 45.405025, lon => -75.139096,  ele => -0.164, time => '2020-10-25T21:35:05Z' },
    { lat => 45.405061, lon => -75.139310,  ele => -0.205, time => '2020-10-25T21:35:10Z' },
    { lat => 45.405020, lon => -75.139528,  ele => -0.242, time => '2020-10-25T21:35:15Z' },
    { lat => 45.404974, lon => -75.139638,  ele => -0.047, time => '2020-10-25T21:35:19Z' },
];
my $o_ta = Geo::Gpx->new();
$o_ta->tracks_add( $aref1, name => 'A track with one segment' );
is($o_ta->tracks_count, 1,             "    tracks_add(): test the number of tracks found");
$o_ta->tracks_add( $aref2, $aref3, name => 'Two segments near the end of the trail' );
is($o_ta->tracks_count, 2,             "    tracks_add(): test the number of tracks found");

# routes_add():
$o_ta->routes_add( $aref2, name => 'My first route' );
is($o_ta->routes_count, 1,             "    routes_add(): test the number of routes found");
$o_wpt_only1->routes_add( $aref2 );
is($o_wpt_only1->routes_count, 1,      "    routes_add(): test the number of routes found");

# waypoints_search():
my @search;
@search = $o_wpt_only1->waypoints_search( name => qr/(?i:p[0-4])/);
@search = $o_wpt_only1->waypoints_search( desc => qr/(?i:limoges)/);

# waypoints_merge():
my $n_merged = $o->waypoints_merge( $o_wpt_only1, qr/LP[4-9]/ );
is($n_merged, 2,                       "    waypoints_merge(): number of waypoints merged");
is($o->waypoints_count, 6,             "    waypoints_merge(): number of waypoints found");

# waypoint_rename():
is( $o_wpt_only1->waypoint_rename('LP1', 'LP1_renamed'), 'LP1_renamed', "    waypoint_rename(): check if rename is successful");
is( $o_wpt_only1->waypoint_rename('LP1', 'Another name'), undef,        "    waypoint_rename(): check return value if unsuccessful");

# waypoint_delete():
is( $o_wpt_only1->waypoint_delete('LP1'), undef,    "    waypoint_delete(): check return value if waypoint name is not found");
$o_wpt_only1->waypoint_rename('LP1_renamed', 'LP1');
is( $o_wpt_only1->waypoint_delete('LP1'), 1,        "    waypoint_delete(): check if waypoint deletion is successful");
is( $o_wpt_only1->waypoints_count, 2,               "    waypoint_delete(): had 3 points, should now have 2");

# test the various *_closest_to() methods:

#   . point_closest_to();
my $pt1 = Geo::Gpx::Point->new( lat => 45.405120, lon => -75.139360 );
my ($closest_pt1, $dist1) = $o_wpt_only1->point_closest_to( $pt1 );
isa_ok ($closest_pt1,  'Geo::Gpx::Point');
is($dist1, 2.010698,                    "    point_closest_to(): check the distance to the closest point");

#   . waypoint_closest_to();
my $pt2 = Geo::Gpx::Point->new( lat => 45.405441, lon => -75.137497 );
my ($closest_pt2, $dist2) = $o_wpt_only1->waypoint_closest_to( $pt2 );
isa_ok ($closest_pt2,  'Geo::Gpx::Point');
is($dist2, 241.593745,                  "    waypoint_closest_to(): check the distance to the closest waypoint");

#   . trackpoint_closest_to();
my $pt3 = Geo::Gpx::Point->new( lat => 45.405120, lon => -75.139360 );
my ($closest_pt3, $dist3) = $o_wpt_only1->trackpoint_closest_to( $pt3 );
isa_ok ($closest_pt3,  'Geo::Gpx::Point');
is($dist3, 2.010698,                    "    trackpoint_closest_to(): check the distance to the closest trackpoint");

#   . routepoint_closest_to();
my $pt4 = Geo::Gpx::Point->new( lat => 45.405120, lon => -75.139360 );
my ($closest_pt4, $dist4) = $o_wpt_only1->routepoint_closest_to( $pt4 );
isa_ok ($closest_pt4,  'Geo::Gpx::Point');
is($dist4, 48.328519,                   "    routepoint_closest_to(): check the distance to the closest routepoint");

# track_rename():
is( $o_ta->track_rename('A track with one segment', 'Single segment track'), 'Single segment track', "    track_rename(): check if rename is successful");
# is( $o_ta->track_rename( -0, 'Really just one'), 'Really just one', "    track_rename(): check if rename is successful");
# ... counting from the end is undocumented and will change in the future i.e. -1 will refer to last not -0
# is( $o_ta->track_rename('A track with one segment', 'LP1_renamed'),  undef,        "    track_rename(): check return value if unsuccessful");
# ... this one croaks instead of returing undef, I think waypoint_rename() should behave the same way and croak

# track_delete():
$o_ta->track_delete( 'Single segment track' );
is($o_ta->tracks_count, 1,             "    tracks_delete(): test the number of tracks remaining");

# save(): a few saves
$o->set_wd( $tmp_dir );
$o->save( filename => 'test_save.gpx', force => 1);
$o->set_wd( '-' );
$o_wpt_only1->set_wd( $tmp_dir );
$o_wpt_only1->save( filename => 'test_save_wpt_and_track.gpx', force => 1);
$o_wpt_only1->set_wd( '-' );

# save() - new instance based on saved file
my $saved_then_read  = Geo::Gpx->new( input => $tmp_dir . '/test_save.gpx' );
isa_ok ($saved_then_read,  'Geo::Gpx');

# delete_all's
$o->waypoints_delete_all;
is( $o->waypoints_count, 0,            "    waypoints_delete_all(): count should now be 0");
$o_ta->tracks_delete_all;
is( $o_ta->tracks_count, 0,            "    waypoints_delete_all(): count should now be 0");
$o_ta->routes_delete_all;
is( $o_ta->routes_count, 0,            "    waypoints_delete_all(): count should now be 0");

print "so debugger doesn't exit\n";

