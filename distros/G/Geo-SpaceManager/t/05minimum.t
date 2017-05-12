# -*- perl -*-
# t/05minimum.t - Test Geo::SpaceManager minimum
use Test::More tests => 19;
use Geo::SpaceManager;
use blib;
use strict;
use warnings;

my $initial = 1;
my $delta = 3;
my $size = 2;
my $space = 10;
my $sm = Geo::SpaceManager->new([0, 0, $space, $space]);
$sm->set_minimum_size([$size,$size]);
for( my $x1 = $initial; $x1 < ($space-$size); $x1 += $delta ) { 
  for( my $y1 = $initial; $y1 < ($space-$size); $y1 += $delta ) { 
    my $x2 = $x1 + $size;
    my $y2 = $y1 + $size;
    my $r = [ $x1, $y1, $x2, $y2 ];
    my $s = $sm->nearest($r);
    ok($s);
    ok( $sm->add($s) );
  }
}

my $r = [0,0,1,1];
my $s = $sm->nearest($r);
ok( ! defined $s );

