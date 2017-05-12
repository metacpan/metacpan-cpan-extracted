# -*- mode: Perl; -*-
package PgSqlTypeIntegerArrayTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::IntegerArray;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::IntegerArray->new();
}

sub test_type : Test {
    is(
        Eve::PgSqlType::IntegerArray->new()->get_type(),
        DBD::Pg::PG_INT4ARRAY);
}

sub test_wrap : Test {
    my $self = shift;

    is($self->{'type'}->wrap(expression => '?'), "CAST (? AS integer[])");
}

sub test_serialize : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => [1, 3, 7, 1337]),
        '{1,3,7,1337}');
    is(
        $self->{'type'}->serialize(
            value => [1, 3, 7, 133333337]),
        '{1,3,7,133333337}');
}

sub test_deserialize : Test(2) {
    my $self = shift;

    for my $array ([1..4], [4..9]) {
        is_deeply($self->{'type'}->deserialize(value => $array), $array);
    }
}

1;
