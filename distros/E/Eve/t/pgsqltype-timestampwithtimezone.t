# -*- mode: Perl; -*-
package PgSqlTypeTimestampWithTimeZoneTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DateTime;

use Eve::PgSqlType::TimestampWithTimeZone;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::TimestampWithTimeZone->new();
}

sub test_type : Test {
    is(
        Eve::PgSqlType::TimestampWithTimeZone->new()->get_type(),
        DBD::Pg::PG_TIMESTAMPTZ);
}

sub test_wrap : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->wrap(expression => '?'),
        "CAST (? AS timestamp with time zone)");
    is(
        $self->{'type'}->wrap(expression => 'to_timestamp(?)'),
        "CAST (to_timestamp(?) AS timestamp with time zone)");
}

sub test_serialize : Test(3) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => DateTime->new(
                year => 2011, month => 3, day => 21, hour => 20, minute => 20,
                second => 41, nanosecond => 123456789, time_zone => "+0300")),
        '2011-03-21 20:20:41.123456789+0300');
    is(
        $self->{'type'}->serialize(
            value => DateTime->new(
                year => 2011, month => 3, day => 21, hour => 20, minute => 50,
                second => 39, nanosecond => 987654321, time_zone => "+0300")),
        '2011-03-21 20:50:39.987654321+0300');
    is($self->{'type'}->serialize(value => undef), 'NULL');
}

sub test_deserialize : Test(3) {
    my $self = shift;

    is_deeply(
        $self->{'type'}->deserialize(
            value => '2011-03-21 20:20:41.123456789+0300'),
        DateTime->new(
            year => 2011, month => 3, day => 21, hour => 20, minute => 20,
            second => 41, nanosecond => 123456789, time_zone => "+0300"));
    is_deeply(
        $self->{'type'}->deserialize(
            value => '2011-03-21 20:50:39.987654321+0300'),
        DateTime->new(
            year => 2011, month => 3, day => 21, hour => 20, minute => 50,
            second => 39, nanosecond => 987654321, time_zone => "+0300"));
    is_deeply($self->{'type'}->deserialize(value => undef), undef);
}

1;
