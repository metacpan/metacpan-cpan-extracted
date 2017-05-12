#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use File::Basename;

use_ok('Geo::PostalCode::NoDB');

use constant DIR => 'basictest';

use constant EARTH_RADIUS_MI => 3956;
use constant MI_TO_FURLONGS => 8;
use constant MI_TO_KM => 1.613;

use constant EPSILON => .009;

my $csvfile =
  File::Spec->catfile( dirname(__FILE__), '..', 'data',
    'zipcodes-csv-10-Aug-2004', 'zipcode.csv' );

sub is_close
{
  @_=(abs($_[0]-$_[1]) <= EPSILON, $_[2]||());
  goto &ok;
}

my $gp_mi = Geo::PostalCode::NoDB->new(units => 'mi', csvfile => $csvfile);
isa_ok($gp_mi,'Geo::PostalCode::NoDB');

my $gp_km = Geo::PostalCode::NoDB->new(units => 'km', csvfile => $csvfile);
isa_ok($gp_km,'Geo::PostalCode::NoDB');

my $gp_furlongs = Geo::PostalCode::NoDB->new(earth_radius => 3956 * 8, csvfile => $csvfile);
isa_ok($gp_furlongs,'Geo::PostalCode::NoDB');

my $d1_mi = $gp_mi->calculate_distance(postal_codes => ['08540','08544' ]);
is_close($d1_mi, 0.6, 'calculated distance');

my $d1_km = $gp_km->calculate_distance(postal_codes => ['08540','08544' ]);
is_close($d1_km, $d1_mi * MI_TO_KM);

my $d1_furlongs = $gp_furlongs->calculate_distance(postal_codes => ['08540','08544' ]);
is_close($d1_furlongs, $d1_mi * MI_TO_FURLONGS);

my @pc_mi = sort @{$gp_mi->nearby_postal_codes(lat => 40.726001, lon => -74.047304, distance => 25)};
my @pc_km = sort @{$gp_km->nearby_postal_codes(lat => 40.726001, lon => -74.047304, distance => 25*MI_TO_KM)};
my @pc_furlongs = sort @{$gp_furlongs->nearby_postal_codes(lat => 40.726001, lon => -74.047304, distance => 25*MI_TO_FURLONGS)};

is_deeply(\@pc_mi,\@pc_km);
is_deeply(\@pc_mi,\@pc_furlongs);
