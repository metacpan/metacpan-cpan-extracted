#!/usr/bin/perl
# Convert wgs84 to clark80 as example of a lat-long to lat-long conversion.

use strict;
use warnings;

use Test::More tests => 21;
use lib qw[blib/lib blib/arch];

use_ok('Geo::Proj4');

my $version = Geo::Proj4->libVersion;
ok(defined $version, "library version $version");

ok(1,'Start testing Lat/Long to/from UTM');

my $from = Geo::Proj4->new(proj => 'latlong', ellps => 'WGS84');
defined $from or die Geo::Proj4->error;

isa_ok($from, "Geo::Proj4");
is($from->normalized, '+proj=latlong +ellps=WGS84');
ok($from->isLatlong);
ok($from->isGeodesic);
ok(not $from->isGeocentric);

my $proj = Geo::Proj4->new("+proj=latlong +ellps=clrk80");
isa_ok($proj, "Geo::Proj4");
defined $proj or die Geo::Proj4->error;

is($proj->normalized, '+proj=latlong +ellps=clrk80');
ok($proj->isLatlong);
ok($proj->isGeodesic);
ok(not $proj->isGeocentric);

#$from->dump;
#$proj->dump;

# convert from wgs84 to clark80

my @rv =
 ( { name     => "imaginary"
   , wgs_lat  => 38.40249
   , wgs_long => -122.82888
   , cl_lat   =>  38.40249
   , cl_long  => -122.82888
   }

 );

sub about($$$)
{  my ($float1, $float2, $text) = @_;
   my $dist = abs($float1/$float2 -1);

   if($dist < 0.0001) { ok(1, $text) }
   else
   {   my $percent = sprintf "%.6f", $dist;
       ok(0, "$text fail: $float1/$float2 $percent%");
   }
}

foreach my $c (@rv) {
    my $point = [ $c->{wgs_long}, $c->{wgs_lat} ];
    my $pr    = $from->transform($proj, $point);
    my ($cl_long, $cl_lat) = @$pr;
    about($cl_lat,  $c->{cl_lat},   "$c->{name} forward clark80 lat");
    about($cl_long, $c->{cl_long},  "$c->{name} forward clark80 long");

    my $w_pr  = $proj->transform($from, [$cl_long, $cl_lat] );
    my ($w_long, $w_lat) = @$w_pr;
    about($w_lat,   $c->{wgs_lat},  "$c->{name} inverse lat");
    about($w_long,  $c->{wgs_long}, "$c->{name} inverse long");
}

#
# repeated forward-inverse
#

my $one = $rv[0];
my ($w_lat, $w_long) = @{$one}{ qw/wgs_lat wgs_long/ };
my ($cl_lat, $cl_long);

for (1..10)
{
    ($cl_long, $cl_lat) = $proj->forward($w_lat, $w_long);
    ($w_lat, $w_long) =  $proj->inverse($cl_long, $cl_lat);
}

about($w_lat,   $one->{wgs_lat},  "Run 10 wgs_lat");
about($w_long,  $one->{wgs_long}, "Run 10 wgs_long");
about($cl_lat,  $one->{cl_lat},   "Run 10 cl_lat");
about($cl_long, $one->{cl_long},  "Run 10 cl_long");
