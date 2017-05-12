#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2 + 1001 * 2;

BEGIN { use_ok( 'Geo::Forward' ); }
my $gf = Geo::Forward->new;
isa_ok($gf, "Geo::Forward");

my @data=$gf->forward(34,-77,45,100);

my $lat=39;
my $lon=-77;
foreach (-200 .. 800) {
  #Zero distance test at all angles
  my @data=$gf->forward($lat => $lon, $_ => 0);
  ok(near($data[0], $lat, 10e-7), "lat");
  ok(near($data[1], $lon, 10e-7), "lon");
}

sub near {
  my $x=shift;
  my $y=shift;
  my $p=shift || 10e-7;
  if (($x-$y)/$y < $p) {
    return 1;
  } else {
    return 0;
  }
}
