# -*- perl -*-
# t/04normal.t - Test Geo::SpaceManager normal
use Test::More tests => 2100;
use Geo::SpaceManager;
use blib;
use strict;
use warnings;

my $delta = 10;
my $size = 100;
my $sm = Geo::SpaceManager->new([0, 0, $size, $size,]);

for( my $x1 = 0; $x1 < $size; $x1 += $delta ) { 
  for( my $y1 = 0; $y1 < $size; $y1 += $delta ) { 
    my $x2 = $x1 + $delta;
    my $y2 = $y1 + $delta;
    my @r = (
    	[ $x1, $y1, $x2, $y2 ],
    	[ $x2, $y1, $x1, $y2 ],
    	[ $x1, $y2, $x2, $y1 ],
    	[ $x2, $y2, $x1, $y1 ],
    );
    for my $r ( @r ) {
      my $s = $sm->nearest($r);
      ok($s);
      for my $i ( 0 .. 3 ) {
        ok( $r->[$i] == $s->[$i] );
      }
    }
    ok( $sm->add($r[0]) );
  }
}

