#!perl -T
use warnings;
use strict;

use Test::More;
eval "use Math::Trig";
plan skip_all => 'Math::Trig not found' if $@;

use Games::EternalLands::Binary::Unitvec16 ':all';

sub dot {
  return $_[0]->[0] * $_[1]->[0]
    + $_[0]->[1] * $_[1]->[1]
    + $_[0]->[2] * $_[1]->[2];
}

sub norm {
  my $d = dot($_[0], $_[0]);
  return if abs($d) < 0.0001;
  my $i = 1.0 / sqrt($d);
  $_[0]->[$_] *= $i for 0 .. 2;
  return $_[0];
}

my $E = 0.05; # radians
my $R = 4;
my $nt = 0;

sub check {
  my ($v, $n) = @_;
  return unless norm($v);
  my $u = unpack_unitvec16(pack_unitvec16($v));
  my $d = dot($v, $u);
  my $a = (abs($d) > 0.99999 ? 0 : acos($d));
  cmp_ok($a, '<', $E, $n);
  $nt++;
}

for (my $x = -$R; $x <= $R; ++$x) {
  for (my $y = -$R; $y <= $R; ++$y) {
    for (my $z = -$R; $z <= $R; ++$z) {
      my $v = [$x, $y, $z];
      check($v, 'angular deflection for converted vectors in range');
    }
  }
}

for (1 .. 100) {
  my $v = [rand 100, rand 100, rand 100];
  check($v, 'angular deflection for 100 random vectors');
}
  
done_testing($nt);
