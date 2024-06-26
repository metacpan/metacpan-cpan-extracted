# t/encodings.t - test encodings
use strict;
use warnings;

use Test::More tests => 12;
use Encode;
use Geo::Gpx;
use File::Temp qw/ tempfile tempdir /;
use Cwd qw(cwd abs_path);

my $cwd     = abs_path( cwd() );
my $tmp_dir = tempdir( CLEANUP => 1 );

my $wpt1 = { lat => 45.93789, lon => -75.85077, ele => 550, time => 1167813923, name => 'é è à ï', desc => 'Un waypoint nommé é è à ï', sym => 'pin', };
my $wpt2 = { lat => 45.93678, lon => -75.85093, ele => 548, time => 1167814115, name => 'α β\' è γ', desc => 'Un waypoint nommé alpha, beta prime, e accent grave & gamma', sym => 'Flag, Blue', };
my $wpt3 = { lat => 45.94636, lon => -76.01154, time => 1167810723,  sym => 'Parking Area' };

#
# Test waypoints with unicode

my $o  = Geo::Gpx->new();
isa_ok ($o,  'Geo::Gpx');
$o->set_wd( $tmp_dir );

$o->waypoints_add( $wpt1, $wpt2, $wpt3 );
is($o->waypoints_count, 3,          "    waypoints_add(): waypoints with unicode added");

# save and reload

$o->save( filename => 'test_unicode.gpx', force => 1);
my $o_copy  = Geo::Gpx->new( input => $tmp_dir . '/test_unicode.gpx' );
isa_ok ($o_copy,  'Geo::Gpx');

$o->save( filename => 'test_unicode_explicit_unsafe_chars.gpx', unsafe_chars => "<>&\"'", force => 1);
my $o_copy2  = Geo::Gpx->new( input => $tmp_dir . '/test_unicode_explicit_unsafe_chars.gpx' );
isa_ok ($o_copy2,  'Geo::Gpx');

# TODO: should be compare the 2 objects, like a deep compare? Look into it.

# 
# test .gpx file with mix of unicode and ascii/latin1 codes entities

# here we test a file that has a mix of entities based on unicode and ascii/latin1 codes can be read properly into an object

my $mixed1  = Geo::Gpx->new( input => 't/mix_of_latin1_utf8_chars.xml' );
$mixed1->waypoints_add( $wpt1 );
# ... we added a waypoint so we have a combination of points read from a file and at least one added from a script

my $str1_expect = 'CC & URj';
my $str2_expect = 'βelvé (name hard-coded, added a beta too)';
my $str3_expect = 'βé (hard-coded)';
my $str4_expect = 'RRtop';
my $str5_expect = 'α, é, & γ (hard-coded except the ampersand)';
my $str1 = $mixed1->waypoints(1)->name;
my $str2 = $mixed1->waypoints(2)->name;
my $str3 = $mixed1->waypoints(3)->name;
my $str4 = $mixed1->waypoints(4)->name;
my $str5 = $mixed1->waypoints(5)->name;
is($str1, $str1_expect,             "    Encode::encode() call in _trim(): ensure string is unicode");
is($str2, $str2_expect,             "    Encode::encode() call in _trim(): ensure string is unicode");
is($str3, $str3_expect,             "    Encode::encode() call in _trim(): ensure string is unicode");
is($str4, $str4_expect,             "    Encode::encode() call in _trim(): ensure string is unicode");
is($str5, $str5_expect,             "    Encode::encode() call in _trim(): ensure string is unicode");

my $desc4 = $mixed1->waypoints( name => 'RRtop' )->desc;
my $expect_not = 'Belvédère en haut de la montagne (2-bytes codes based on binary values)';
isnt($desc4, $expect_not,             "    new(): read xml with accented characters wrongly encoded with the binary values of a char instead of unicode code");

# waypoints_search() with unicode characters in their name
my @search;
@search = $o->waypoints_search( name => qr/(?i:[è])/);
is( @search, 2,                     "    waypoints_search(): search waypoints based on unicode character");

# waypoints_search() with unicode characters in their name -- example with greek letter
my $mixed2 = $mixed1->clone();
$mixed2->waypoints_add( $wpt2 );
@search = $mixed2->waypoints_search( name => qr/β/);
is( @search, 3,                     "    waypoints_search(): search waypoints based on unicode character");

# $DB::single=1;

print "so debugger doesn't exit\n";

