# Toby Thurston -- 27 Jan 2016 

# out of range conditions and comparison with helmert

use strict;
use Geo::Coordinates::OSGB   qw/grid_to_ll_helmert ll_to_grid ll_to_grid_helmert/;

use Test::More tests => 11; 

is(ll_to_grid(51.477811, -0.001475), '538883.061 177321.493', "RO Greenwich");
is(ll_to_grid(49,-2, {shape => 'OSGB36'} ), '400000.000 -100000.000', "True origin of OSGB36");
is(ll_to_grid(55.2597198486328,-6.1883339881897), '133985 604172', "Outside OSTN02");
is(ll_to_grid(66,40), '2184572 2427658', "In the White Sea, NW Russia");

is(ll_to_grid_helmert(51.477811, -0.001475), '538885 177322', "RO Greenwich");
is(ll_to_grid_helmert(49,-2), '400096 -100086', "True origin of OSGB36 in WGS84 coordinates");
is(ll_to_grid_helmert(55.2597198486328,-6.1883339881897), '133985 604172', "Outside OSTN02");
is(ll_to_grid_helmert(66,40), '2184572 2427658', "In the White Sea, NW Russia");

is(sprintf("%.7g %.6g", grid_to_ll_helmert(538885, 177322)), '51.47781 -0.00147285', "RO Greenwich");
is(sprintf("%.7g %.6g", grid_to_ll_helmert(400096,-100086)), '49 -2', "True origin of OSGB36 in WGS84 coordinates");
is(sprintf("%.7g %.6g", grid_to_ll_helmert(133985, 604172)), '55.25972 -6.18834', "Outside OSTN02");
