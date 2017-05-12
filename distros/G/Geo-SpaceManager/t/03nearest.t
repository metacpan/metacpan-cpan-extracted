# -*- perl -*-
# t/03nearest.t - Test Geo::SpaceManager nearest
use Test::More tests => 600;
use Geo::SpaceManager;
use blib;
use strict;
use warnings;

my $delta = 10;
my $size = 100;
my $sm = Geo::SpaceManager->new([0, 0, 100, 100,]);
my $count = 0;

for( my $x1 = 0; $x1 < $size; $x1 += $delta ) { 
  for( my $y1 = 0; $y1 < $size; $y1 += $delta ) { 
    my $x2 = $x1 + $delta;
    my $y2 = $y1 + $delta;
    my $r = [ $x1, $y1, $x2, $y2 ];
    my $s = $sm->nearest($r);
    ok($s);
    for my $i ( 0 .. 3 ) {
      ok( $r->[$i] == $s->[$i] );
    }
    ok( $sm->add($r) );
  }
}

