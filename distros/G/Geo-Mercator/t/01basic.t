#
#	GD::Mercator test script
#
use Test::More tests => 11;
use strict;
use warnings;

use_ok('Geo::Mercator');

my ($x, $y) = mercate(0,0);
#
#	we have to be forgiving of minor precision issues
#	(except for longitude, which is a simple linear calculation)
#
ok(($x == 0) && ($y < 0.0001) && ($y > -0.0001), 'mercate origin');
my ($lat, $long) = demercate($x, $y);
ok($lat == 0 && $long == 0, 'demercate origin');

($x, $y) = mercate(45, 30);
ok(($x < 3339584.72381) && ($x > 3339584.72379) && 
	($y < 5591295.91849) && ($y > 5591295.91848), 'mercate (45,30)');
($lat, $long) = demercate($x, $y);
ok(($lat < 45.0001) && ($lat > 44.9999) &&
	($long > 29.9999) && ($long < 30.0001), 'demercate back to 45, 30');

($x, $y) = mercate(-45, 30);
ok(($x < 3339584.7238) && ($x > 3339584.72379) && 
	($y > -5591295.91849) && ($y < -5591295.91848), 'mercate (-45,30)');
($lat, $long) = demercate($x, $y);
ok(($lat > -45.0001) && ($lat < -44.9999) &&
	($long > 29.9999) && ($long < 30.0001), 'demercate back to -45, 30');

($x, $y) = mercate(-45, -30);
ok(($x > -3339584.7238) && ($x < -3339584.72379) && 
	($y > -5591295.91849) && ($y < -5591295.91848), 'mercate (-45,-30)');
($lat, $long) = demercate($x, $y);
ok(($lat > -45.0001) && ($lat < -44.9999) &&
	($long < -29.9999) && ($long > -30.0001), 'demercate back to -45, -30');

($x, $y) = mercate(45, -30);
ok(($x > -3339584.7238) && ($x < -3339584.72379) && 
	($y > 5591295.91848) && ($y < 5591295.91849), 'mercate (45,-30)');
($lat, $long) = demercate($x, $y);
ok(($lat < 45.0001) && ($lat > 44.9999) &&
	($long < -29.9999) && ($long > -30.0001), 'demercate back to 45, -30');
