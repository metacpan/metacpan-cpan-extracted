# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok( 'GPS::Point' ); }

my $pt1 = GPS::Point->new(lat=>39,
                          lon=>-77);
isa_ok ($pt1, 'GPS::Point');

my $pt2=GPS::Point->new(%$pt1);

is($pt1->lat, 39, "pt1 lat");
is($pt2->lat, 39, "pt2 lat");

is($pt1->lat(38), 38, "pt1 lat");

is($pt1->lat, 38, "pt1 lat");
is($pt2->lat, 39, "pt2 lat");
