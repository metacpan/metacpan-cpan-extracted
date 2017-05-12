# -*- mode: Perl; -*-
package GeometryTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::Geometry;

sub test_from_string : Test(5) {
    my $self = shift;

    my $geo = Eve::Geometry->from_string(string => 'POINT(33.123 57.109)');

    isa_ok($geo, 'Eve::Geometry::Point');
    is($geo->latitude, 57.109);
    is($geo->longitude, 33.123);

    $geo = Eve::Geometry->from_string(
        string => 'POLYGON((33.123 57.109,33.123 57.109,33.123 57.109))');

    isa_ok($geo, 'Eve::Geometry::Polygon');
    is($geo->length, 3);
}

1;
