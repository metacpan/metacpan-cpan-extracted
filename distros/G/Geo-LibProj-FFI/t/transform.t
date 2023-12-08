#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Coordinate transformation
# https://proj.org/development/reference/functions.html#coordinate-transformation

plan tests => 2 + 4 + 2 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($c, $p, $a);

lives_and { ok $c = proj_context_create() } 'context_create';
lives_and { ok $p = proj_create_crs_to_crs($c, "EPSG:4326", "EPSG:25833", 0) } 'create_crs_to_crs';


# proj_trans

lives_and { ok $a = proj_coord( 79, 12, 0, 0 ) } 'coord';
lives_and { ok $a = proj_trans( $p, PJ_FWD(), $a ) } 'trans';
lives_and { like $a->enu_e(), qr/^43612.\./ } 'easting';
lives_and { like $a->enu_n(), qr/^877161.\./ } 'northing';


# proj_trans_generic

# proj_trans_array



lives_ok { proj_destroy($p) } 'destroy';
lives_ok { proj_context_destroy($c) } 'context_destroy';

done_testing;
