#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Transformation setup
# https://proj.org/development/reference/functions.html#transformation-setup

plan tests => 8 + 1 + 3 + 1;

use Geo::LibProj::FFI qw( :all );


my ($p, $p1, $p2);


# proj_create
# proj_create_argv
# proj_create_crs_to_crs_from_pj
# proj_destroy

lives_and { ok $p1 = proj_create(0, "WGS 84 / UTM zone 32N") } 'create 1';
lives_and { ok $p2 = proj_create_argv(0, 4, [qw(+proj=utm +zone=32 +datum=WGS84 +type=crs)]) } 'create 2';
lives_and { ok $p = proj_create_crs_to_crs_from_pj(0, $p1, $p2, undef, undef) } 'create_crs_to_crs_from_pj 0';
lives_ok { proj_destroy($p) } 'create_crs_to_crs_from_pj destroy 0';
lives_and { ok $p = proj_create_crs_to_crs_from_pj(0, $p1, $p2, undef, ["ALLOW_BALLPARK=YES"]) } 'create_crs_to_crs_from_pj 1';
lives_ok { proj_destroy($p) } 'create_crs_to_crs_from_pj destroy 1';
lives_ok { proj_destroy($p1) } 'create destroy 1';
lives_ok { proj_destroy($p2) } 'create destroy 2';


# proj_create_crs_to_crs

lives_and { ok $p = proj_create_crs_to_crs(0, "EPSG:25832", "EPSG:25833", 0) } 'create_crs_to_crs';


# proj_normalize_for_visualization

lives_and { ok $p2 = proj_normalize_for_visualization(0, $p) } 'normalize_for_visualization';
lives_ok { proj_destroy($p) } 'create_crs_to_crs destroy';
lives_ok { proj_destroy($p2) } 'normalize_for_visualization destroy';


done_testing;
