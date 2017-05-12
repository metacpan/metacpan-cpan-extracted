package Eve::PgSqlFunction;

use parent qw(Eve::Class);

use strict;
use warnings;

use DBI;

use Eve::Exception;

=head1 NAME

B<Eve::PgSqlFunction> - a PostgreSQL stored function class.

=head1 SYNOPSIS

    my $foo = Eve::PgSqlFunction->new(
        connection => $pgsql_connection,
        name => 'foo',
        input_list => [
            {'bar' => $pgsql_bigint}],
        output_list => [
            {'bar' => $pgsql_bigint},
            {'baz' => $pgsql_text}]);

    my $result_list = $foo->execute(value_hash => {'bar' => 123});

=head1 DESCRIPTION

B<Eve::PgSqlFunction> is an adapter class for PostgreSQL stored
function. It adapts B<DBI> B<DBD::Pg> statement handle and
encapsulates statement preparation and execution mechanisms.

=head3 Attributes

=over 4

=item C<sth>

a service attribute containing a statement handle (not for regular
use).

=back

=head3 Constructor arguments

=over 4

=item C<connection>

a PostgreSQL connection (B<Eve::PgSqlConnection>) object

=item C<name>

a stored function name

=item C<input_list>

an optional list of input parameters, each of which is specified as a
structure like

    {'parameter_name' => $parameter_type}

where the C<$parameter_type> is a B<Eve::PgSqlType> derivative.

=item C<output_list>

an optional list of output parameters specified, just like the
C<input_list> argument

=item C<is_set_returning>

A boolean value depending of what do we expect from the function - a
set or one row.

=back

=head3 Throws

=over 4

=item C<Eve::Error::Value>

when input or output parameter definitions does not match the required
definition format.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($connection, $name),
        my ($input_list, $output_list, $is_set_returning) = ([], [], 0));

    $self->{'_input_list'} = $self->_transform_parameter_list(
        raw_list => $input_list);
    $self->{'_output_list'} = $self->_transform_parameter_list(
        raw_list => $output_list);
    $self->{'_is_set_returning'} = $is_set_returning;

    $self->{'sth'} = $connection->dbh->prepare(
        'SELECT * FROM '.$name.'('.
        join(
            ', ',
            map(
                $_->{'type'}->wrap(expression => '?'),
                @{$self->_input_list})).
        ')');

    my $i = 1;
    for my $param (@{$self->{'_input_list'}}) {
        $self->sth->bind_param(
            $i++, undef, { 'pg_type' => $param->{'type'}->get_type() });
    }

    return;
}

=head2 B<_transform_parameter_list()>

=cut

sub _transform_parameter_list {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $raw_list);

    my $result_list = [];
    for my $hash (@{$raw_list}) {
        if (scalar keys %{$hash} > 1) {
            Eve::Error::Value->throw(
                message => 'Wrong parameter definition');
        }
        for my $key (keys %{$hash}) {
            push(
                @{$result_list},
                {'name' => $key, 'type' => $hash->{$key}});
        }
    }

    return $result_list;
}

=head2 B<execute()>

Executes the stored function.

=head3 Arguments

=over 4

=item C<value_hash>

an optional hash of the input parameters substitutions where keys are
parameter names and values are values to substitute.

=back

=head3 Returns

A list of hashes corresponding to the rows returning from the stored
function if C<is_set_returning> is true or a hash of a single row
otherwise.

=head3 Throws

=over 4

=item C<Eve::Error::Value>

in case when input values does not meet the signature of the stored
function, when resulting columns set does not meet required output
parameters or when 0 or more than 1 row returned in case of not set
returning function.

=back

=cut

sub execute {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value_hash = {});

    my $value_list = [];
    for my $input (@{$self->_input_list}) {
        if (not exists $value_hash->{$input->{'name'}}) {
            Eve::Error::Value->throw(
                message => 'Required input parameter: '.$input->{'name'});
        }

        push(
            @{$value_list},
            $input->{'type'}->serialize(
                value => $value_hash->{$input->{'name'}}));
        delete($value_hash->{$input->{'name'}});
    }

    my $key_list = [keys %{$value_hash}];
    if (@{$key_list}) {
        Eve::Error::Value->throw(
            message =>
                'Redundant input parameter(s): '.
                join(', ', sort(@{$key_list})));
    }

    $self->sth->execute(@{$value_list});

    my $row_hash_list = $self->sth->fetchall_arrayref({});
    for my $row_hash (@{$row_hash_list}) {
        my $key_hash = {%{$row_hash}};
        for my $output (@{$self->_output_list}) {
            if (not exists $row_hash->{$output->{'name'}}) {
                Eve::Error::Value->throw(
                    message =>
                        'Column has not been returned: '.
                        $output->{'name'});
            }

            $row_hash->{$output->{'name'}} = $output->{'type'}->deserialize(
                value => $row_hash->{$output->{'name'}});
            delete($key_hash->{$output->{'name'}});
        }

        $key_list = [keys %{$key_hash}];
        if (@{$key_list}) {
            Eve::Error::Value->throw(
                message =>
                'Redundant column(s) returned: '.
                join(', ', sort(@{$key_list})));
        }
    }

    my $result;
    my $row_count = @{$row_hash_list};
    if ($self->_is_set_returning) {
        $result = $row_hash_list;
    } else {
        if (not $row_count == 1) {
            Eve::Error::Value->throw(
                message =>
                'Expected 1 row from database but returned '.
                $row_count);
        }
        $result = $row_hash_list->[0];
    }

    return $result;
}

=head1 SEE ALSO

=over 4

=item L<DBI>

=item L<DBD::Pg>

=item L<Eve::Exception>

=item L<Eve::PgSqlConnection>

=item L<Eve::PgSqlType>

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

=back

=cut

1;
