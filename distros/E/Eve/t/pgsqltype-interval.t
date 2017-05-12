# -*- mode: Perl; -*-
package Eve::PgSqlTypeIntervalTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DateTime;

use Eve::PgSqlType::Interval;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'type'} = Eve::PgSqlType::Interval->new();
}

sub test_type : Test {
    is(
        Eve::PgSqlType::Interval->new()->get_type(),
        DBD::Pg::PG_INTERVAL);
}

sub test_wrap : Test(1) {
    my $self = shift;

    is(
        $self->{'type'}->wrap(expression => '?'),
        "CAST (? AS interval)");
}

sub test_serialize : Test(2) {
    my $self = shift;

    is(
        $self->{'type'}->serialize(
            value => DateTime::Duration->new(
                days => 3, hours => 4, minutes => 5, seconds => 5)),
        '@ 3 days 245 minutes 5 seconds');
    is(
        $self->{'type'}->serialize(
            value => DateTime::Duration->new(
                days => -1, hours => -10, minutes => -50, seconds => -1)),
        '@ -1 days -650 minutes -1 seconds');
}

sub test_deserialize : Test(6) {
    my $self = shift;

    my $duration = $self->{'type'}->deserialize(value => '@ 3 days 06:05:05');
    is($duration->days, 3);
    is($duration->hours, 6);
    is($duration->minutes, 5);
    is($duration->seconds, 5);
    ok($duration->is_positive);

    is_deeply($self->{'type'}->deserialize(value => undef), undef);
}

1;
