#!/usr/bin/env perl
#
# Test contruction of a point
#

use strict;
use warnings;

use lib qw(. lib tests ../MathPolygon/lib ../../MathPolygon/lib);

use Test::More tests => 43;

use Geo::Point;
use Geo::Proj;

my $gp = 'Geo::Point';

Geo::Proj->new(nick => 'wgs84', proj4 => '+proj=latlong +datum=WGS84');

#
# latlong
#

my $p = $gp->latlong(2,3, 'wgs84');
ok(defined $p,                          "created a point");
isa_ok($p, $gp);
isa_ok($p, 'Geo::Shape');

cmp_ok($p->lat, '==', 2);
cmp_ok($p->latitude, '==', 2);
cmp_ok($p->long, '==', 3);
cmp_ok($p->longitude, '==', 3);
is($p->proj, 'wgs84');
is($p->string, 'point[wgs84](2.0000 3.0000)');

is($p->x, 3);
is($p->y, 2);

#
# longlat
#

$p = $gp->longlat(4,5, 'wgs84');
ok(defined $p,                          "created a longlat point");
isa_ok($p, $gp);
isa_ok($p, 'Geo::Shape');

cmp_ok($p->lat, '==', 5);
cmp_ok($p->long, '==', 4);
is($p->proj, 'wgs84');
is($p->string, 'point[wgs84](5.0000 4.0000)');

is($p->x, 4);
is($p->y, 5);

#
# xy
#

my $utm = Geo::Proj->new(nick => 'utm-31',
  proj4 => "+proj=utm +zone=31 +datum=WGS84");
ok(defined $utm, 'created utm');

$p = $gp->xy(4,5,'utm-31');
ok(defined $p,                          "created a xy point");
isa_ok($p, $gp);
isa_ok($p, 'Geo::Shape');

cmp_ok($p->x, '==', 4);
cmp_ok($p->y, '==', 5);
is($p->proj, 'utm-31');
is($p->string, 'point[utm-31](4.0000 5.0000)');

is($p->x, 4);
is($p->y, 5);

#
# yx
#

$p = $gp->yx(4,5,'utm-31');
ok(defined $p,                          "created a xy point");
isa_ok($p, $gp);
isa_ok($p, 'Geo::Shape');

cmp_ok($p->x, '==', 5);
cmp_ok($p->y, '==', 4);
is($p->proj, 'utm-31');
is($p->string, 'point[utm-31](5.0000 4.0000)');

is($p->x, 5);
is($p->y, 4);

is_deeply([$p->bbox], [ 5,4, 5,4 ]);

#
# distance
#

my $p1 = $gp->latlong(0, 1);
my $p2 = $gp->latlong(1, 1);
cmp_ok(abs($p1->distance($p2, 'nautical mile') - 60), '<', 0.1);

isnt($p1->distance($p2, 'degrees'), 0);
isnt($p1->distance($p2, 'radians'), 0);

