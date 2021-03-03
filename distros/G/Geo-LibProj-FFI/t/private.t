#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# non-API functions
# (not exported through :all)

plan tests => 6 + 1;

use Geo::LibProj::FFI qw( :all );


my ($p, $a);


# _trans

lives_and { ok $p = proj_create_crs_to_crs(0, "EPSG:4326", "EPSG:25833", 0) } 'create_crs_to_crs';
$a = [ 79, 12, 0, 0 ];
dies_ok { _trans( $p, PJ_FWD(), $a ) } 'trans not exported';
lives_and { ok $a = Geo::LibProj::FFI::_trans( $p, PJ_FWD(), $a ) } 'trans';
lives_and { like $a->[0], qr/^43612.\./ } 'easting';
lives_and { like $a->[1], qr/^877161.\./ } 'northing';
lives_ok { proj_destroy($p) } 'destroy';


done_testing;
