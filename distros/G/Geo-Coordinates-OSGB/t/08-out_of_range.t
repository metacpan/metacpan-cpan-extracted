# Toby Thurston -- 27 Jan 2016 

# out of range conditions and comparison with helmert

use strict;
use Geo::Coordinates::OSGB   qw/grid_to_ll grid_to_ll_helmert ll_to_grid ll_to_grid_helmert/;

use Test::More tests => 9; 

#print grid_to_ll(538874.197, 177344.080);
is(ll_to_grid(51.4775, 0, {shape => 'OSGB36'}), '538874.197 177344.080', "RO Greenwich");
is(ll_to_grid(51.4780161357,  -0.0015938564), '538874.197 177344.080', "RO Greenwich");
is(ll_to_grid_helmert(51.4780161357,  -0.0015938564), '538876 177344', "RO Greenwich");
is(sprintf("%.6g %.4g", grid_to_ll_helmert(538876, 177344)), '51.478 -0.001594', "RO Greenwich");

is(ll_to_grid(49,-2),  ll_to_grid_helmert(49,-2), "True origin of OSGB36");
is(ll_to_grid(55,-10), ll_to_grid_helmert(55,-10), "Outside OSTN02");
is(ll_to_grid(66,40),  ll_to_grid_helmert(66,40), "In the White Sea, NW Russia");

is(sprintf("%.7g %.6g", grid_to_ll_helmert(400096,-100086)), '49 -2', "True origin of OSGB36 in WGS84 coordinates");
is(sprintf("%.7g %.6g", grid_to_ll_helmert(133985, 604172)), '55.25972 -6.18834', "Outside OSTN02");
