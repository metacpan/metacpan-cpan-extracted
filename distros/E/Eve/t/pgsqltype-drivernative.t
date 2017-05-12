# -*- mode: Perl; -*-
package PgSqlTypeDriverNativeTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use Eve::PgSqlType::DriverNative;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::DriverNative->new();
}

sub test_wrap : Test(2) {
    my $self = shift;

    is($self->{'type'}->wrap(expression => 1), 1);
    is($self->{'type'}->wrap(expression => 'some'), 'some');
}

sub test_serialize : Test(2) {
    my $self = shift;

    is($self->{'type'}->serialize(value => 2), 2);
    is($self->{'type'}->serialize(value => 'another'), 'another');
}

sub test_deserialize : Test(2) {
    my $self = shift;

    is($self->{'type'}->deserialize(value => 3), 3);
    is($self->{'type'}->deserialize(value => 'yet another'), 'yet another');
}

1;
