use Test;
BEGIN { plan tests => 5 };
use Geo::Coordinates::VandH::XS ':all';
ok(1); # If we made it this far, we're ok.

my $epsilon = 0.01;

my ($v, $h, $lat, $lon ) = (5587, 1601, 39.07824516, -77.00127254);

my ($vg, $hg ) = toVH( $lat,$lon );
ok( abs($vg -$v) < $epsilon );
ok( abs($hg -$h) < $epsilon );
#printf "Got: %.2f\t%.2f\n", $vg, $hg;
#printf "Exp: %.2f\t%.2f\n", $v, $h;

my ($latg, $long) = toLatLon($v,$h);
ok( abs($latg -$lat) < $epsilon );
ok( abs($long +$lon) < $epsilon );
#printf "Got: %.5f\t%.5f\n", $latg, $long;
#printf "Exp: %.5f\t%.5f\n", $lat, $lon;
