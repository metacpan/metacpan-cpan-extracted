# -*- mode: Perl; -*-
package PgSqlTypeArrayTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Array;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::Array->new();
}

sub test_type : Test {
    is(Eve::PgSqlType::Array->new()->get_type(), DBD::Pg::PG_ANYARRAY);
}

sub test_wrap : Test {
    my $self = shift;

    is($self->{'type'}->wrap(expression => '?'), "CAST (? AS anyarray)");
}

sub test_serialize : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => ['an', 'array', 'reference']),
        '{an,array,reference}');
    is(
        $self->{'type'}->serialize(
            value => ['an', 'another', 'array', 'reference']),
        '{an,another,array,reference}');
}

sub test_deserialize : Test(2) {
    my $self = shift;

    is_deeply(
        $self->{'type'}->deserialize(
            value => ['an', 'array', 'reference']),
        ['an', 'array', 'reference']);
    is_deeply(
        $self->{'type'}->deserialize(
            value => ['an', 'another', 'array', 'reference']),
        ['an', 'another', 'array', 'reference']);
}

1;
