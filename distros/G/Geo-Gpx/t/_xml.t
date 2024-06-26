# t/_xml.t - test _xml(), _tag(), _enc(), all methods called by xml()
use strict;
use warnings;

use Test::More tests => 7;
use Geo::Gpx;
use File::Temp qw/ tempfile tempdir /;
use Cwd qw(cwd abs_path);

my $cwd     = abs_path( cwd() );
my $tmp_dir = tempdir( CLEANUP => 1 );

my $o  = Geo::Gpx->new( input => 't/larose_wpt.gpx');
isa_ok ($o,  'Geo::Gpx');

# a waypoint we can use for tests, but let's add some unicode to it
my $pt = $o->waypoints( name => 'LP1' );
$pt->desc( 'Larose P1 - Limoges - Stationnement & début des trails' );

# just a temporary call to xml() -- so we can put breakpoint in *.pm and see what the argument are where for calls we want to test
# $o->xml();

#
# _tag() -- as called by _xml()

#      . with a non-empty href
my $uc   = '<>&"';        # same as the default ($unsafe_chars_default), could test with other values for $uc
my $tag  = 'wpt';
my $attr = { 'lat' => $pt->lat, 'lon' => $pt->lon };
my @cont = ( "\n", "<ele>" . $pt->ele . "</ele>\n", "<name>" . $pt->name . "</name>\n", "<cmt>" . $pt->cmt . "</cmt>\n", "<desc>" . $pt->desc . "</desc>\n", "<sym>" . $pt->sym . "</sym>\n", "<extensions>" . $pt->extensions . "</extensions>\n" );
my $expect_tag = '<wpt lat="' . $pt->{lat} . '" lon="' . $pt->{lon} . "\">" . join( '', @cont ) . "</wpt>\n";
my $return_tag = Geo::Gpx::_tag( $uc, $tag, $attr, @cont );
is($return_tag, $expect_tag,            "    _tag(): as called by _xml() with a non-empty href");

#      . with an empty href
$tag  = 'desc';
@cont = 'Larose P1 - Limoges';
$expect_tag = "<desc>Larose P1 - Limoges</desc>\n";
$return_tag = Geo::Gpx::_tag( $uc, $tag, {}, @cont );
is($return_tag, $expect_tag,            "    _tag(): as called by _xml() with an empty href");

#
# _tag() -- as called by itself

#      . with an empty href
$tag = 'name';
my $value = 'α β\' è γ';
$expect_tag = "<name>α β' è γ</name>\n";
$return_tag = Geo::Gpx::_tag( $uc, $tag, {}, Geo::Gpx::_enc( $value, $uc ) );
is($return_tag, $expect_tag,            "    _tag(): as called by itself with an empty href");

#
# _xml() -- as called by xml()

#      . with a href (e.g. a Geo::Gpx::Point)
my $name = 'wpt';
# we expect same output as a call to _tag() above:
@cont = ( "\n", "<ele>" . $pt->ele . "</ele>\n", "<name>" . $pt->name . "</name>\n", "<cmt>" . $pt->cmt . "</cmt>\n", "<desc>" . $pt->desc . "</desc>\n", "<sym>" . $pt->sym . "</sym>\n", "<extensions>" . $pt->extensions . "</extensions>\n" );
my $expect__xml = '<wpt lat="' . $pt->{lat} . '" lon="' . $pt->{lon} . "\">" . join( '', @cont ) . "</wpt>\n";
$expect__xml =~ s/\&/&#x26;/;
my $return__xml = $o->_xml( $uc, $name, $pt );
is($return__xml, $expect__xml,            "    _xml(): as called by xml() with a href as \$value");

#      . with an aref
$name = 'wpt';
$value = [ $o->waypoints_search( desc => qr/Limoges/ ) ];
my $name_map = { 'waypoints' => 'wpt' };
my @cont0 = ( "\n", "<ele>" . $value->[0]->ele . "</ele>\n", "<name>" . $value->[0]->name . "</name>\n", "<cmt>" . $value->[0]->cmt . "</cmt>\n", "<desc>" . $value->[0]->desc . "</desc>\n", "<sym>" . $value->[0]->sym . "</sym>\n", "<extensions>" . $value->[0]->extensions . "</extensions>\n" );
my @cont1 = ( "\n", "<ele>" . $value->[1]->ele . "</ele>\n", "<name>" . $value->[1]->name . "</name>\n", "<cmt>" . $value->[1]->cmt . "</cmt>\n", "<desc>" . $value->[1]->desc . "</desc>\n", "<sym>" . $value->[1]->sym . "</sym>\n", "<extensions>" . $value->[1]->extensions . "</extensions>\n" );
$expect__xml = '<wpt lat="' . $value->[0]->{lat} . '" lon="' . $value->[0]->{lon} . "\">" . join( '', @cont0 ) . "</wpt>\n" . '<wpt lat="' . $value->[1]->{lat} . '" lon="' . $value->[1]->{lon} . "\">" . join( '', @cont1 ) . "</wpt>\n";
$expect__xml =~ s/\&/&#x26;/;
$return__xml = $o->_xml( $uc, $name, $value, $name_map );
is($return__xml, $expect__xml,            "    _xml(): as called by xml() with an aref as \$value");

#      . with a scalar
$name  = 'desc';
$value = 'Larose P1 - Limoges';
$expect__xml= "<desc>Larose P1 - Limoges</desc>\n";
$return__xml = $o->_xml( $uc, $name, $value );
is($return__xml, $expect__xml,            "    _xml(): as called by _xml() with a scalar as \$value");

print "so debugger doesn't exit\n";
