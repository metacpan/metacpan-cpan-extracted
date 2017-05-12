# -*- perl -*-

=head1 Test Examples

base.t - Good examples concerning how to use this module

=cut

use Test::More tests => 316;

BEGIN { use_ok( 'Geo::Horizon' ); }

use constant NEAR_DEFAULT => 7;

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||NEAR_DEFAULT;
  if (abs($x-$y)/abs($y) < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}


my $gh = Geo::Horizon->new();
isa_ok($gh, "Geo::Horizon");
isa_ok($gh->ellipsoid, "Geo::Ellipsoids");
is($gh->ellipsoid->shortname, "WGS84", "ellipsoid->shortname=WGS84");

foreach(0 .. 90) {
  is($gh->distance(0,$_), 0, "distance(0=>$_)=0");
  is($gh->distance_great_circle(0,$_), 0, "distance_great_circle(0=>$_)=0");
}

my $r=1000;
$gh = Geo::Horizon->new({a=>$r});
isa_ok($gh, "Geo::Horizon");
isa_ok($gh->ellipsoid, "Geo::Ellipsoids");
is($gh->ellipsoid->a, $r, "ellipsoid->a=$r");
is($gh->ellipsoid->b, $r, "ellipsoid->b=$r");

foreach(1 .. 100) {
  my $h=$_;
  my $r=$gh->ellipsoid->a;
  my $b=$r;
  my $c=$r + $h;
  my $a=sqrt($c ** 2 - $b **2);
  is(near($gh->distance($h), $a, 12), 1, "distance($h)=$a");
}

#Tests from http://newton.ex.ac.uk/research/qsystems/people/sque/physics/horizon/

$r=6378.14 * 1000;
$gh = Geo::Horizon->new({a=>$r});
isa_ok($gh, "Geo::Horizon");
isa_ok($gh->ellipsoid, "Geo::Ellipsoids");
is($gh->ellipsoid->a, $r, "ellipsoid->a=$r");
is($gh->ellipsoid->b, $r, "ellipsoid->b=$r");

my @data=( #[m, km,km]
          [1, 3.57159, 3.57159],
          [1.7, 4.65679, 4.65679],
          [2, 5.05100, 5.05100],
          [5, 7.98633, 7.98632],
          [10, 11.2944, 11.2944],
          [20, 15.9727, 15.9726],
          [50, 25.2550, 25.2549],
          [100, 35.7161, 35.7157],
          [1000, 112.948, 112.936],
          [10000, 357.299, 356.926],
          [100000000, 106187, 9636.11],
         );

foreach (@data) {
  my ($h, $ds, $dc)=@$_;
  $ds*=1000;
  $dc*=1000;
  is(near($gh->distance($h), $ds, 5), 1, "distance($h)=$ds");
  is(near($gh->distance_great_circle($h), $dc, 5) , 1, "distance($h)=$dc");
}
