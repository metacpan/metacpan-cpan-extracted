#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Distances
# https://proj.org/development/reference/functions.html#distances

plan tests => 4 + 7 + 3;

use Geo::LibProj::FFI qw( :all );


my ($c, $p, $a, $b, $d);

lives_and { ok $c = proj_context_create() } 'context_create';
lives_and { ok $p = proj_create($c, "EPSG:4979") } 'create';
lives_and { ok $a = proj_coord(  .21, 1.3, 0, 0 ) } 'coord a';
lives_and { ok $b = proj_coord( -1.3, .68, 5, 0 ) } 'coord b';


# proj_lp_dist

lives_ok { proj_lp_dist($p, $a, $b) } 'lp_dist';


# proj_lpz_dist

lives_ok { proj_lpz_dist($p, $a, $b) } 'lpz_dist';


# proj_xy_dist

lives_ok { $d = -1; $d = proj_xy_dist($a, $b) } 'xy_dist';
like $d, qr/^1\.6/, 'xy_dist ballpark';


# proj_xyz_dist

lives_ok { $d = -1; $d = proj_xyz_dist($a, $b) } 'xyz_dist';
like $d, qr/^5\.2/, 'xyz_dist ballpark';


# proj_geod

lives_ok { proj_geod($p, $a, $b) } 'geod';


lives_ok { proj_destroy($p) } 'destroy';
lives_ok { proj_context_destroy($c) } 'context_destroy';

done_testing;
