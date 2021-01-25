#!perl

use strict;
use warnings;

use Test::More tests => 64;

use Geo::Ellipsoid;

my $e = Geo::Ellipsoid->new();

for my $method ('set_angle_unit', 'set_units') {

    for my $unit ('degrees', 'DEG', 'Deg', 'deg') {
        my $e1 = Geo::Ellipsoid->new();
        $e->$method($unit);
        $e1->$method($unit);
        is( $e->{angle_unit}, 'degrees' );
        is( $e1->{angle_unit}, 'degrees' );
        is($e -> get_angle_unit(), 'degrees');
        is($e1 -> get_angle_unit(), 'degrees');
    }

    for my $unit ('radians', 'RAD', 'Rad', 'rad') {
        my $e1 = Geo::Ellipsoid->new();
        $e->$method($unit);
        $e1->$method($unit);
        is( $e->{angle_unit}, 'radians' );
        is( $e1->{angle_unit}, 'radians' );
        is($e -> get_angle_unit(), 'radians');
        is($e1 -> get_angle_unit(), 'radians');
    }

}
