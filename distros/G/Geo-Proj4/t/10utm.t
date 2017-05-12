#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 43;
use lib qw[blib/lib blib/arch];

use_ok('Geo::Proj4');
my $version = Geo::Proj4->libVersion;
ok(defined $version, "library version $version");

ok(1,'Start testing Lat/Long to/from UTM');

my $proj = Geo::Proj4->new(proj => "utm", zone => 10, datum => 'WGS84');
unless(defined $proj)
{  my $err  = Geo::Proj4->error;
   warn +($err+0).": ".$err;
   exit 1;
}
ok(defined $proj,  "object creation");

isa_ok($proj, "Geo::Proj4");

is($proj->normalized,
   "+proj=utm +zone=10 +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"
  );

ok(not $proj->isLatlong);
ok(not $proj->isGeodesic);
ok(not $proj->isGeocentric);

# convert from lat/long to UTM

my @rv =
 ( { name     => "imaginary"
   , lat      => 38.40249
   , long     => -122.82888
   , northing => 4250487 
   , easting  => 514941
   }

 , { name     => "O'Reilly"
   , lat      => 38.40342
   , long     => -122.81856
   , northing => 4250592
   , easting  => 515842
   }

 , { name     => "Unicorn Precinct"
   , lat      => 37.73960, 
   , long     => -122.41980, 
   , northing => 4177082,
   , easting  => 551119,
   }
 );

foreach my $c (@rv) {
    my ($x, $y) = $proj->forward($c->{lat}, $c->{long});
    cmp_ok(int $x,    '==', $c->{easting},  "$c->{name} forward to UTM x");
    cmp_ok(int $y,    '==', $c->{northing}, "$c->{name} forward to UTM y");

    my ($lat, $long) = $proj->inverse($x, $y);
    cmp_ok(int $lat,  '==', int $c->{lat},  "$c->{name} inverse lat");
    cmp_ok(int $long, '==', int $c->{long}, "$c->{name} inverse long");
}


my ($long, $lat) = (-122.82888, 38.40249);
my ($x, $y) = $proj->forward($lat, $long);
cmp_ok(int $x, '==', 514941,  "forward to UTM x");
cmp_ok(int $y, '==', 4250487, "forward to UTM y");

my ($lat2, $long2) =  $proj->inverse($x, $y);
cmp_ok(int $lat,  '==', int $lat2,  "inverse lat");
cmp_ok(int $long, '==', int $long2, "inverse long");

#
# repeated forward-inverse
#

($long, $lat) = (-122.82888, 38.40249);
for (1..10) {
    ($x, $y) = $proj->forward($lat, $long);
    ($lat, $long) =  $proj->inverse($x, $y);
}

cmp_ok(int $x,    '==',     514941, "Run 10 convs to UTM x");
cmp_ok(int $y,    '==',    4250487, "Run 10 convs to UTM y");
cmp_ok(int $lat,  '==',  int $lat2, "Run 10 inverse convs lat");
cmp_ok(int $long, '==', int $long2, "Run 10 inverse convs long");

#
# The same, but now using transform
#

my $from = Geo::Proj4->new(proj=>'latlong', ellps=>'WGS84',datum=>'WGS84');
unless(defined $from)
{  my $err  = Geo::Proj4->error;
   warn +($err+0).": ".$err;
   exit 1;
}
ok(defined $from,  "object 'from' created explicitly");
ok($from->isLatlong);

foreach my $c (@rv) {
    my($point) = $from->transform($proj, [$c->{long}, $c->{lat}]);
    unless(defined $point)
    {   my $err  = Geo::Proj4->error;
        warn +($err+0).": ".$err;
        next;
    }

    cmp_ok(int $point->[0],'==', $c->{easting},  "$c->{name} forward to UTM x");
    cmp_ok(int $point->[1],'==', $c->{northing}, "$c->{name} forward to UTM y");

    my($back) = $proj->transform($from, $point);
    unless(defined $back)
    {   my $err  = Geo::Proj4->error;
        warn +($err+0).": ".$err;
        next;
    }
    cmp_ok(int $back->[0], '==', int $c->{long}, "$c->{name} inverse long");
    cmp_ok(int $back->[1], '==', int $c->{lat},  "$c->{name} inverse lat");
}

