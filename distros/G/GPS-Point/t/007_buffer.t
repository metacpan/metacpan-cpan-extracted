# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 16;
use Test::Number::Delta;

BEGIN { use_ok( 'GPS::Point' ); }

SKIP: {
  eval { require Geo::Forward };
  skip "Geo::Forward not installed", 15 if $@;

  ok(1, "Running tests that require Geo::Forward");

  my $pt=GPS::Point->new(lat=>38.907671, lon=>-76.864482, alt=>59.6811); #Fedex Field
  my $buffer=$pt->buffer(91.44/2, 60); #100 yards = 91.44 meters
  isa_ok($buffer, "ARRAY");
  is(scalar(@$buffer), 61, "points not sections in buffer"); 
  isa_ok($buffer->[0], "GPS::Point");
  isa_ok($buffer->[1], "GPS::Point");
  isa_ok($buffer->[2], "GPS::Point");
  isa_ok($buffer->[3], "GPS::Point");
  isa_ok($buffer->[4], "GPS::Point");
  isa_ok($buffer->[5], "GPS::Point");
  is($buffer->[0]->alt, 59.6811, 'altitude');
  is($buffer->[1]->alt, 59.6811, 'altitude');
  is($buffer->[2]->alt, 59.6811, 'altitude');
  is($buffer->[3]->alt, 59.6811, 'altitude');
  is($buffer->[4]->alt, 59.6811, 'altitude');
  is($buffer->[5]->alt, 59.6811, 'altitude');

  eval { require Geo::Google::StaticMaps::V2 };
  unless ($@) {
    my $map=Geo::Google::StaticMaps::V2->new(type=>"satellite", scale=>2);
    $map->path(locations => [map {[$_->lat => $_->lon]} @$buffer]);
    #foreach my $pt (@$buffer) {
      #$map->marker(location => [$pt->lat=>$pt->lon]);
    #}
    diag $map->url;
  }
}
