# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 11;
use Geo::Dymaxion;

my @sample = (
    [40, -75, 5967, 4035, "Philadelphia, PA"],
    [38.3993, -122.8259, 5934, 6092, "Sebastopol, CA"],
    [0, 50, 2655, 2518, "London, UK"],
    [28.67, 77.21, 3180, 4557, "Dilli, India"],
    [-37.81, 144.96, 1707, 8510, "Melbourne, Australia"]
);

my $map = Geo::Dymaxion->new(10_000, 10_000);
isa_ok( $map, Geo::Dymaxion );
for my $city (@sample) {
    my ($lat, $long, $x, $y, $name) = @$city;
    my ($x2, $y2) = $map->plot( $lat, $long );
    is( $x, int $x2, "plotting $name" );
    is( $y, int $y2, "plotting $name" );
}
