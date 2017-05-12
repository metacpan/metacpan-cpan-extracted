# -*- mode: Perl; -*-
package PgSqlTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use Eve::DbiStub;

use Eve::PgSql;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'pgsql'} = Eve::PgSql->new(
        database => undef,
        host => undef,
        port => undef,
        user => undef,
        password => undef,
        schema => undef);
}

sub test_get_connection : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_connection();
        },
        class_name => 'Eve::PgSqlConnection');
}

sub test_get_function : Test(2) {
    my $self = shift;

    Eve::Test::is_prototype(
        code => sub {
            return $self->{'pgsql'}->get_function(
                connection => $self->{'pgsql'}->get_connection(),
                name => 'some_function');
        },
        class_name => 'Eve::PgSqlFunction');
}

sub test_get_bigint : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_bigint();
        },
        class_name => 'Eve::PgSqlType::Bigint');
}

sub test_get_boolean : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_boolean();
        },
        class_name => 'Eve::PgSqlType::Boolean');
}

sub test_get_double : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_double();
        },
        class_name => 'Eve::PgSqlType::Double');
}

sub test_get_double_array : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_double_array();
        },
        class_name => 'Eve::PgSqlType::DoubleArray');
}

sub test_get_geometry : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_geometry();
        },
        class_name => 'Eve::PgSqlType::Geometry');
}

sub test_get_integer : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_integer();
        },
        class_name => 'Eve::PgSqlType::Integer');
}

sub test_get_integer_array : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_integer_array();
        },
        class_name => 'Eve::PgSqlType::IntegerArray');
}

sub test_get_smallint : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_smallint();
        },
        class_name => 'Eve::PgSqlType::Smallint');
}

sub test_get_text : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_text();
        },
        class_name => 'Eve::PgSqlType::Text');
}

sub test_interval : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_interval();
        },
        class_name => 'Eve::PgSqlType::Interval');
}

sub test_get_timestamp_with_time_zone : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_timestamp_with_time_zone();
        },
        class_name => 'Eve::PgSqlType::TimestampWithTimeZone');
}

sub test_get_timestamp_without_time_zone : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_timestamp_without_time_zone();
        },
        class_name => 'Eve::PgSqlType::Timestamp');
}

sub test_get_array : Test(2) {
    my $self = shift;

    Eve::Test::is_lazy(
        code => sub {
            return $self->{'pgsql'}->get_array();
        },
        class_name => 'Eve::PgSqlType::Array');
}

1;
