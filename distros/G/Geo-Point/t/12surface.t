#!/usr/bin/perl
#
# Test contruction of a point
#

use strict;
use warnings;

use Test::More tests => 11;

use Geo::Line;
use Geo::Surface;
use Geo::Proj;

Geo::Proj->new(nick => 'wgs84', proj4 => '+proj=latlong +datum=WGS84');

#
# outer from ARRAY
#

my $s1 = Geo::Surface->new([[1,2],[3,4],[5,6],[1,2]], proj => 'wgs84');
ok(defined $s1, 'simple outer');
isa_ok($s1, 'Geo::Surface');

is($s1->toString, <<_S);
surface[wgs84]
  ([[1,2], [3,4], [5,6], [1,2]])
_S

my $o1 = $s1->outer;
isa_ok($o1, 'Math::Polygon');
my @p1 = $o1->points;
cmp_ok(scalar @p1, '==', 4);
is($o1->string, '[1,2], [3,4], [5,6], [1,2]');

my @i1 = $s1->inner;
cmp_ok(scalar @i1, '==', 0);

my $go1 = $s1->geo_outer;
isa_ok($go1, 'Geo::Line');
is($go1->toString, 'line[wgs84]([1,2], [3,4], [5,6], [1,2])');

###

my $s2 = Geo::Surface->new($go1);
is($s2->proj, 'wgs84');

is($s2->toString, <<_S);
surface[wgs84]
  ([[1,2], [3,4], [5,6], [1,2]])
_S
