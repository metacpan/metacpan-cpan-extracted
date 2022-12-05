# t/01_main.t - main testing file (for Gpx.pm)
use strict;
use warnings;

use Test::More tests => 20;
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

# waypoints_search():
my @search;
@search = $o_wpt_only1->waypoints_search( name => qr/(?i:p[0-4])/);
@search = $o_wpt_only1->waypoints_search( desc => qr/(?i:limoges)/);

# waypoints_merge():
my $n_merged = $o->waypoints_merge( $o_wpt_only1, qr/LP[4-9]/ );
is($n_merged, 2,                       "    waypoints_merge(): number of waypoints merged");
is($o->waypoints_count, 6,             "    waypoints_merge(): number of waypoints found");

# waypoint_closest_to();
my $pt2 = Geo::Gpx::Point->new( lat => 45.405441, lon => -75.137497 );
my ($closest, $dist) = $o_wpt_only1->waypoint_closest_to( $pt2 );
isa_ok ($closest,  'Geo::Gpx::Point');
is($dist, 241.593745,                  "    waypoints_closest_to(): check the distance to the closest waypoint");

# waypoint_delete():
$o_wpt_only1->waypoint_delete('LP1');
$o_wpt_only1->waypoints_count;      # was 3 should now be 2

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

print "so debugger doesn't exit\n";

