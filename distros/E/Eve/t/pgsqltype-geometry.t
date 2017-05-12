# -*- mode: Perl; -*-
package PgSqlTypeGeometryTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DateTime;

use Eve::PgSqlType::Geometry;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::Geometry->new();
}

sub test_type : Test {
    is(
        Eve::PgSqlType::Geometry->new()->get_type(),
        DBD::Pg::PG_ANY);
}

sub test_wrap : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->wrap(expression => '?'),
        "CAST (? AS geometry)");
    is(
        $self->{'type'}->wrap(expression => 'astext(?)'),
        "CAST (astext(?) AS geometry)");
}

sub test_serialize : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => Eve::Geometry::Point->new(
                data => [10.01, 20.02])),
        "(geomfromtext('POINT(20.02 10.01)', 4001))");
    is(
        $self->{'type'}->serialize(
            value => Eve::Geometry::Polygon->new(
                data => [[30.01, 40.02], [40.01, 50.02]])),
        "(geomfromtext('POLYGON((40.02 30.01,50.02 40.01))', 4001))");
}

sub test_deserialize : Test(3) {
    my $self = shift;

    my $string_list = ['POINT(40.02 30.01)', 'POINT(20.02 10.01)'];

    for my $string (@{$string_list}) {
        is_deeply(
            $self->{'type'}->deserialize(value => $string),
            Eve::Geometry->from_string(string => $string));
    }

    is_deeply($self->{'type'}->deserialize(value => undef), undef);
}

1;
