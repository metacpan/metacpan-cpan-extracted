#!/usr/bin/perl -T
#
# Test parsing of strings containing DMS
#

use strict;
use warnings;

use lib qw(. .. tests ../MathPolygon/lib ../../MathPolygon/lib);

use Test::More tests => 16;

use Geo::Point;

my $pkg = 'Geo::Point';

#
# DEGMS
#

is($pkg->deg2dms(0, 'e', 'w'), '0e',                      'zero east');
is($pkg->deg2dms(1, 'e', 'w'), '1e',                      'one east');
is($pkg->deg2dms(-1, 'e', 'w'), '1w',                     'one west');

is($pkg->deg2dms( 3.14159265, 'E', 'W'), qq#3d08'29.733"E#, 'pi east');
is($pkg->deg2dms(-3.14159265, 'E', 'W'), qq#3d08'29.733"W#, 'pi west');

#
# DMSEG
#

# avoid failures on rounding errors
sub about($$)
{   my ($calc, $expect) = @_;
    my $ok = abs($calc - $expect) < 0.00001;
    warn "$calc => $expect\n" unless $ok;
    $ok;
}

ok(about($pkg->dms2deg( qq#3d 8'29.733"W# ), -3.1415925),      'un-pi west');
ok(about($pkg->dms2deg( qq#W3d8'29.733"# ), -3.1415925),       'un-pi west 2');
ok(about($pkg->dms2deg( qq#3d 8'29.733"E# ), 3.1415925),       'un-pi east');
ok(about($pkg->dms2deg( qq#E3d 8'29.733"# ), 3.1415925),       'un-pi east 2');

ok(about($pkg->dms2deg( qq#3d8'29.733"E# ), 3.1415925));
ok(about($pkg->dms2deg( "3.1415925" ), 3.1415925));
ok(about($pkg->dms2deg( qq#3d8'29"E# ), 3.141388889));
ok(about($pkg->dms2deg( qq#3d8'29E# ), 3.141388889));
ok(about($pkg->dms2deg( qq#3d8E# ), 3.13333333));

#
# DMS
#

my $p = Geo::Point->latlong(3.12, 4.20);
is($p->dms, qq#3d07'12"N, 4d12'E#, 'dms');
is($p->dm,  qq#3d07'N, 4d12'E#,    'dm' );
