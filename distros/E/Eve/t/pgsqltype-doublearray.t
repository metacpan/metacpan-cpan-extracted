# -*- mode: Perl; -*-
package PgSqlTypeDoubleArrayTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::DoubleArray;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::DoubleArray->new();
}

sub test_type : Test {
    my $self = shift;

    is($self->{'type'}->get_type(), DBD::Pg::PG_FLOAT8ARRAY);
}

sub test_wrap : Test {
    my $self = shift;

    is(
        $self->{'type'}->wrap(expression => '?'),
        "CAST (? AS double precision[])");
}

sub test_serialize : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => [1.3, 3.3, 3.7, 1.337]),
        '{1.3,3.3,3.7,1.337}');
    is(
        $self->{'type'}->serialize(
            value => [1.3, 3.3, 3.7, 1.33333337]),
        '{1.3,3.3,3.7,1.33333337}');
}

1;

1;
