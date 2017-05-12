#!/usr/bin/perl -T
#
# Test contruction of a point
#

use strict;
use warnings;

use lib qw(. lib tests ../MathPolygon/lib ../../MathPolygon/lib);

use Test::More tests => 8;

my $gp = 'Geo::Proj';

use_ok($gp);
my $p = $gp->new(nick => 'wgs84', proj4 => '+proj=latlong +datum=WGS84');

ok(defined $p);
isa_ok($p, $gp);

is($p->nick, 'wgs84');

my $p4 = $p->proj4;
ok(defined $p4, 'got proj4');
isa_ok($p4, 'Geo::Proj4');
ok($p4->isLatlong);
is($p4->normalized, '+proj=latlong +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0');
