#!/usr/local/bin/perl
# Test Geo::Ellipsoid load
use Test::More tests => 21;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;
use blib;
use strict;
use warnings;

BEGIN { use_ok( 'Geo::Ellipsoid' ); }
my $e = Geo::Ellipsoid->new();
isa_ok( $e, 'Geo::Ellipsoid');
my $e1 = Geo::Ellipsoid->new( units => 'degrees' );
isa_ok( $e1, 'Geo::Ellipsoid');
my $e2 = Geo::Ellipsoid->new( distance_units => 'foot' );
isa_ok( $e2, 'Geo::Ellipsoid');
my $e3 = Geo::Ellipsoid->new( bearing => 1 );
isa_ok( $e3, 'Geo::Ellipsoid');
my $e4 = Geo::Ellipsoid->new( longitude => 1 );
isa_ok( $e4, 'Geo::Ellipsoid');

can_ok( 'Geo::Ellipsoid', 'new' );
can_ok( 'Geo::Ellipsoid', 'set_units' );
can_ok( 'Geo::Ellipsoid', 'set_distance_unit' );
can_ok( 'Geo::Ellipsoid', 'set_ellipsoid' );
can_ok( 'Geo::Ellipsoid', 'set_custom_ellipsoid' );
can_ok( 'Geo::Ellipsoid', 'set_longitude_symmetric' );
can_ok( 'Geo::Ellipsoid', 'set_bearing_symmetric' );
can_ok( 'Geo::Ellipsoid', 'set_defaults' );
can_ok( 'Geo::Ellipsoid', 'scales' );
can_ok( 'Geo::Ellipsoid', 'range' );
can_ok( 'Geo::Ellipsoid', 'bearing' );
can_ok( 'Geo::Ellipsoid', 'at' );
can_ok( 'Geo::Ellipsoid', 'to' );
can_ok( 'Geo::Ellipsoid', 'displacement' );
can_ok( 'Geo::Ellipsoid', 'location' );
