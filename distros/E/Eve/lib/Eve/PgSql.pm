package Eve::PgSql;

use parent qw(Eve::Class);

use strict;
use warnings;

use Eve::PgSqlConnection;
use Eve::PgSqlFunction;
use Eve::PgSqlType::Array;
use Eve::PgSqlType::Bigint;
use Eve::PgSqlType::Boolean;
use Eve::PgSqlType::Double;
use Eve::PgSqlType::DoubleArray;
use Eve::PgSqlType::Geometry;
use Eve::PgSqlType::Integer;
use Eve::PgSqlType::IntegerArray;
use Eve::PgSqlType::Interval;
use Eve::PgSqlType::Smallint;
use Eve::PgSqlType::Text;
use Eve::PgSqlType::Timestamp;
use Eve::PgSqlType::TimestampWithTimeZone;

=head1 NAME

B<Eve::PgSql> - the PostgreSQL factory.

=head1 SYNOPSIS

    use Eve::PgSql;

    # Construct a factory instance
    my $pgsql = Eve::PgSql->new(
        database => $database,
        host => $host,
        port => $port,
        user => $user,
        password => $password,
        schema => $schema);

    # Create a function instance
    my $foo = $pgsql->get_function(
        name => 'foo',
        input_list => [
            {'bar' => $pgsql->get_bigint()},
            {'foo' => $pgsql->get_smallint()}],
        output_list => [
            {'baz' => $pgsql->get_text()},
            {'bam' => $pgsql->get_timestamp_with_timezome()}]);

=head1 DESCRIPTION

B<Eve::PgSql> is a factory providing services to interact with
PostgreSQL databases and common dependencies between these services.

=head3 Constructor arguments

=over 4

=item C<database>

=item C<host>

=item C<port>

=item C<user>

=item C<password>

=item C<schema>

=back

By default all arguments are C<undef> so the database adapter will
attempt to use standard PostgreSQL environment variables.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($database, $host, $port, $user, $password, $schema) = (\undef) x 6);

    $self->{'database'} = $database;
    $self->{'host'} = $host;
    $self->{'port'} = $port;
    $self->{'user'} = $user;
    $self->{'password'} = $password;
    $self->{'schema'} = $schema;

    return;
}

=head2 B<get_connection()>

A PostgreSQL connection lazy loader service.

=cut

sub get_connection {
    my $self = shift;

    if (not exists $self->{'_connection'}) {
        $self->{'_connection'} = Eve::PgSqlConnection->new(
            database => $self->database,
            host => $self->host,
            port => $self->port,
            user => $self->user,
            password => $self->password,
            schema => $self->schema);
    }

    return $self->_connection;
}

=head2 B<get_function()>

A PostgreSQL stored function prototype service.

=head3 Arguments

=over 4

=item C<name>

a stored function name

=item C<input_list>

an optional list of input parameters, each of which is specified as a
structure like

    {'parameter_name' => $parameter_type}

where the C<$parameter_type> is a B<Eve::PgSqlType> derivative.

=item C<output_list>

an optional list of output parameters specified, just like the
C<input_list> argument.

=back

=cut

sub get_function {
    my $self = shift;

    return Eve::PgSqlFunction->new(connection => $self->get_connection, @_);
}

=head2 B<get_bigint()>

A PostgreSQL bigint type lazy loader service.

=cut

sub get_bigint {
    my $self = shift;

    if (not exists $self->{'_bigint'}) {
        $self->{'_bigint'} = Eve::PgSqlType::Bigint->new();
    }

    return $self->_bigint;
}

=head2 B<get_boolean()>

A PostgreSQL boolean type lazy loader service.

=cut

sub get_boolean {
    my $self = shift;

    if (not exists $self->{'_boolean'}) {
        $self->{'_boolean'} = Eve::PgSqlType::Boolean->new();
    }

    return $self->_boolean;
}

=head2 B<get_double()>

A PostgreSQL double precision floating point type lazy loader service.

=cut

sub get_double {
    my $self = shift;

    if (not exists $self->{'_double'}) {
        $self->{'_double'} = Eve::PgSqlType::Double->new();
    }

    return $self->_double;
}

=head2 B<get_double_array()>

A PostgreSQL double precision array type lazy loader service.

=cut

sub get_double_array {
    my $self = shift;

    if (not exists $self->{'_double_array'}) {
        $self->{'_double_array'} = Eve::PgSqlType::DoubleArray->new();
    }

    return $self->_double_array;
}

=head2 B<get_geometry()>

A PostGIS geometry type lazy loader service.

=cut

sub get_geometry {
    my $self = shift;

    if (not exists $self->{'_geometry'}) {
        $self->{'_geometry'} = Eve::PgSqlType::Geometry->new();
    }

    return $self->_geometry;
}

=head2 B<get_integer()>

A PostgreSQL integer type lazy loader service.

=cut

sub get_integer {
    my $self = shift;

    if (not exists $self->{'_integer'}) {
        $self->{'_integer'} = Eve::PgSqlType::Integer->new();
    }

    return $self->_integer;
}

=head2 B<get_integer_array()>

A PostgreSQL integer array type lazy loader service.

=cut

sub get_integer_array {
    my $self = shift;

    if (not exists $self->{'_integer_array'}) {
        $self->{'_integer_array'} = Eve::PgSqlType::IntegerArray->new();
    }

    return $self->_integer_array;
}

=head2 B<get_interval()>

A PostgreSQL interval type lazy loader service.

=cut

sub get_interval {
    my $self = shift;

    if (not exists $self->{'_interval'}) {
        $self->{'_interval'} = Eve::PgSqlType::Interval->new();
    }

    return $self->_interval;
}

=head2 B<get_smallint()>

A PostgreSQL smallint type lazy loader service.

=cut

sub get_smallint {
    my $self = shift;

    if (not exists $self->{'_smallint'}) {
        $self->{'_smallint'} = Eve::PgSqlType::Smallint->new();
    }

    return $self->_smallint;
}

=head2 B<get_text()>

A PostgreSQL text type lazy loader service.

=cut

sub get_text {
    my $self = shift;

    if (not exists $self->{'_text'}) {
        $self->{'_text'} = Eve::PgSqlType::Text->new();
    }

    return $self->_text;
}

=head2 B<get_timestamp_with_time_zone()>

A PostgreSQL timestamp with time zone type lazy loader service.

=cut

sub get_timestamp_with_time_zone {
    my $self = shift;

    if (not exists $self->{'_timestamp_with_time_zone'}) {
        $self->{'_timestamp_with_time_zone'} =
            Eve::PgSqlType::TimestampWithTimeZone->new();
    }

    return $self->_timestamp_with_time_zone;
}

=head2 B<get_timestamp_without_time_zone()>

A PostgreSQL timestamp without time zone type lazy loader service.

=cut

sub get_timestamp_without_time_zone {
    my $self = shift;

    if (not exists $self->{'_timestamp_without_time_zone'}) {
        $self->{'_timestamp_without_time_zone'} =
            Eve::PgSqlType::Timestamp->new();
    }

    return $self->_timestamp_without_time_zone;
}

=head2 B<get_array()>

A PostgreSQL array type lazy loader service.

=cut

sub get_array {
    my $self = shift;

    if (not exists $self->{'_array'}) {
        $self->{'_array'} =
            Eve::PgSqlType::Array->new();
    }

    return $self->_array;
}

=head1 SEE ALSO

=over 4

=item L<Eve::PgSqlConnection>

=item L<Eve::PgSqlFunction>

=item L<Eve::PgSqlType>

=item L<Eve::PgSqlType::Array>

=item L<Eve::PgSqlType::Bigint>

=item L<Eve::PgSqlType::Integer>

=item L<Eve::PgSqlType::Interval>

=item L<Eve::PgSqlType::Smallint>

=item L<Eve::PgSqlType::Text>

=item L<Eve::PgSqlType::TimestampWithTimeZone>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
