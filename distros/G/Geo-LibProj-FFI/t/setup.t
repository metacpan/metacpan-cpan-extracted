#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Transformation setup
# https://proj.org/development/reference/functions.html#transformation-setup

plan tests => 8 + 4 + 3 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($a, $p, $p1, $p2);


# proj_create
# proj_create_argv
# proj_create_crs_to_crs_from_pj
# proj_destroy

lives_and { ok $p1 = proj_create(0, "WGS 84 / UTM zone 32N") } 'create 1';
lives_and { ok $p2 = proj_create_argv(0, 4, [qw(+proj=utm +zone=32 +datum=WGS84 +type=crs)]) } 'create 2';
lives_and { ok $p = proj_create_crs_to_crs_from_pj(0, $p1, $p2, undef, undef) } 'create_crs_to_crs_from_pj 0';
lives_ok { proj_destroy($p) } 'create_crs_to_crs_from_pj destroy 0';
lives_and { ok $p = proj_create_crs_to_crs_from_pj(0, $p1, $p2, 0, ["ALLOW_BALLPARK=YES"]) } 'create_crs_to_crs_from_pj 1';
lives_ok { proj_destroy($p) } 'create_crs_to_crs_from_pj destroy 1';
lives_ok { proj_destroy($p1) } 'create destroy 1';
lives_ok { proj_destroy($p2) } 'create destroy 2';


# proj_create_crs_to_crs
# Area of interest
# https://proj.org/development/reference/functions.html#area-of-interest

lives_and { ok $a = proj_area_create() } 'area_create';
lives_ok { proj_area_set_bbox($a, -150, 64, -149, 65) } 'area_set_bbox';
lives_and { ok $p = proj_create_crs_to_crs(0, "EPSG:4267", "EPSG:4326", $a) } 'create_crs_to_crs';
lives_ok { proj_area_destroy($a) } 'area_destroy';


# proj_normalize_for_visualization

lives_and { ok $p2 = proj_normalize_for_visualization(0, $p) } 'normalize_for_visualization';
lives_ok { proj_destroy($p) } 'create_crs_to_crs destroy';
lives_ok { proj_destroy($p2) } 'normalize_for_visualization destroy';


done_testing;
