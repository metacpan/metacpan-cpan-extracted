# -*- mode: Perl; -*-
package PgSqlTypeTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::PgSqlType;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType->new();
}

sub test_type : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'type'}->get_type(); },
        'Eve::Error::NotImplemented');
}

sub test_wrap : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'type'}->wrap(expression => 'some'); },
        'Eve::Error::NotImplemented');
}

sub test_serialize : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'type'}->serialize(value => 'some'); },
        'Eve::Error::NotImplemented');
}

sub test_deserialize : Test {
    my $self = shift;

    throws_ok(
        sub { $self->{'type'}->deserialize(value => 'some'); },
        'Eve::Error::NotImplemented');
}

1;
