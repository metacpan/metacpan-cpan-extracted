package Eve::DbiStub;

use strict;
use warnings;

use DateTime::Format::Pg;
use DBD::Pg ();

use Test::MockObject;
use Test::MockObject::Extends;

=head1 NAME

B<Eve::DbiStub> - a stub for replacing the database in unit tests.

=head1 SYNOPSIS

    my $data_hash = Eve::DbiStub->get_compiled_data();

    my $function_return_data = $data_hash->{'test_function_1'}->{'data'};

=head1 METHODS

=head2 B<get_compiled_data()>

Returns compiled data that is to be returned from stored procedures
after being processed by a database adapter.

=cut

sub get_compiled_data {
    my ($data_hash, $result) = (get_data(), undef);

    my $callback_hash = {
        'created' => sub {
            return DateTime::Format::Pg->parse_timestamp_with_time_zone($_[0]);
        },
        'modified' => sub {
            return DateTime::Format::Pg->parse_timestamp_with_time_zone($_[0]);
        }};

    my $compiled_data = {};

    for my $function (keys %{$data_hash}) {
        my $compiled_result_list = [];

        for my $result_list (@{$data_hash->{$function}->{'data'}}) {
            my $data = [];

            if (ref($result_list)) {
                for my $entry (@{$result_list}) {
                    my $processed_entry = {};

                    for my $field_key (keys %{$entry}) {

                       if (defined $callback_hash->{$field_key}
                            and defined $entry->{$field_key}) {

                            $processed_entry->{$field_key} =
                                $callback_hash->{$field_key}->(
                                    $entry->{$field_key});
                        } else {

                            $processed_entry->{$field_key} =
                                $entry->{$field_key};
                        }
                    }

                    push (@{$data}, $processed_entry);
                }
            }

            push (@{$compiled_result_list}, $data);
        }

        $compiled_data->{$function} =
            {%{$data_hash->{$function}}, 'data' => $compiled_result_list};
    }

    return $compiled_data;
}

=head2 B<get_data()>

Returns raw data that is to be returned from stored procedures prior
to being processed by the database adapter.

=cut

sub get_data {

    my $data_template_hash = {
        'entry_undef' => {
            'id' => undef,
            'created' => undef,
            'modified' => undef,
            'status' => undef},
        'entry_inactive' => {
            'id' => 12345,
            'created' => '2012-04-02 00:00:00',
            'modified' => '2012-04-02 00:00:00',
            'status' => 0},
        'entry_1' => {
            'id' => 123456789,
            'created' => '2011-07-01 00:00:00',
            'modified' => '2011-07-01 00:00:00',
            'status' => 1},
        'entry_2' => {
            'id' => 987654321,
            'created' => '2011-04-22 00:00:00',
            'modified' => '2011-04-22 00:00:00',
            'status' => 1},
        'entry_3' => {
            'id' => 12345,
            'created' => '2012-04-02 00:00:00',
            'modified' => '2012-04-02 00:00:00',
            'status' => 1},
        'profile_undef' => {
            'provider_name' => undef,
            'identifier' => undef,
            'display_name' => undef,
            'email' => undef},
        'profile_1' => {
            'provider_name' => 'facebook',
            'identifier' => '100000123812',
            'display_name' => 'John Q. Doe',
            'email' => 'john.q.doe@example.net'},
        'profile_2' => {
            'provider_name' => 'twitter',
            'identifier' => '1000001211812',
            'display_name' => 'John M. Doe',
            'email' => 'john.m.doe@example.net'},
        'profile_3' => {
            'provider_name' => 'facebook',
            'identifier' => '100000123812',
            'display_name' => 'John Q. Deere',
            'email' => 'john.q.deere@example.net'},
        'profile_4' => {
            'provider_name' => 'twitter',
            'identifier' => '100000123813',
            'display_name' => 'John M. Smith',
            'email' => 'john.m.smith@example.com'}};

    my $data_hash_list = {
        'test_function_1' => {
            'sql_pattern' => 'pgsql_function_test\.test_function_1',
            'data' => [[
                {'id' => 1, 'memo' => 'text 1'},
                {'id' => 2, 'memo' => 'text 2'}]]},
        'test_function_2' => {
            'sql_pattern' => 'pgsql_function_test\.test_function_2',
            'data' => [[{'memo' => 'text'}]]},
        'account_add' => {
            'sql_pattern' => 'account_add',
            'input_type_list' => [],
            'data' => [
                [$data_template_hash->{'entry_1'}],
                [$data_template_hash->{'entry_2'}]]},
        'account_get' => {
            'sql_pattern' => 'account_get',
            'input_type_list' => [DBD::Pg::PG_INT8],
            'data' => [
                [{%{$data_template_hash->{'entry_1'}}, 'id' => 987654321}],
                [{%{$data_template_hash->{'entry_2'}}, 'id' => 123456789}]]},
        'account_get_by_userid' => {
            'sql_pattern' => 'account_get_by_userid',
            'input_type_list' => [DBD::Pg::PG_TEXT],
            'data' => [
                [{%{$data_template_hash->{'entry_1'}}, 'id' => 987654321}],
                [{%{$data_template_hash->{'entry_2'}}, 'id' => 123456789}]]},
        'external_profile_add' => {
            'sql_pattern' => 'external_profile_add',
            'input_type_list' => [DBD::Pg::PG_INT8, (DBD::Pg::PG_TEXT) x 4],
            'data' => [
                [{%{$data_template_hash->{'entry_1'}},
                 'account_id' => 123123123,
                 %{$data_template_hash->{'profile_1'}}}],
                [{%{$data_template_hash->{'entry_2'}},
                 'account_id' => 123123,
                 %{$data_template_hash->{'profile_2'}}}]]},
        'external_profile_get_by_credentials' => {
            'sql_pattern' => 'external_profile_get_by_credentials',
            'input_type_list' => [DBD::Pg::PG_TEXT, DBD::Pg::PG_TEXT],
            'data' => [
                [{%{$data_template_hash->{'entry_1'}},
                  'id' => 987654321,
                  'account_id' => 123123123,
                  %{$data_template_hash->{'profile_1'}}}],
                [{%{$data_template_hash->{'entry_3'}},
                  'account_id' => 123123,
                  %{$data_template_hash->{'profile_2'}},
                  'identifier' => '100000123813'}],
                [{%{$data_template_hash->{'entry_undef'}},
                  'account_id' => undef,
                  %{$data_template_hash->{'profile_undef'}}}]]},
        'external_profile_update' => {
            'sql_pattern' => 'external_profile_update',
            'input_type_list' => [DBD::Pg::PG_INT8, (DBD::Pg::PG_TEXT) x 4],
            'data' => [
                [{%{$data_template_hash->{'entry_1'}},
                  'modified' => '2011-03-24 00:00:00',
                  'account_id' => 123123123,
                  %{$data_template_hash->{'profile_3'}}}],
                [{%{$data_template_hash->{'entry_3'}},
                  'modified' => '2012-04-15 00:00:00',
                  'account_id' => 123123,
                  %{$data_template_hash->{'profile_4'}}}]]}};

    return $data_hash_list;
}

=head2 B<mock_sth()>

Returns a mock statement handle.

=cut

sub mock_sth {
    my $sql = shift;

    my $sth_mock = Test::MockObject->new();

    $sth_mock->{'input_type_list'} = [];
    $sth_mock->{'data_hash_list'} = get_data();

    $sth_mock->mock(
        'bind_param',
        sub {
            my ($self, $index, undef, $attr_hash) = @_;

            push(@{$self->{'input_type_list'}}, $attr_hash->{'pg_type'});
            return;
        });

    $sth_mock->mock(
        'execute',
        sub {
            my $self = shift;

            $self->set_always('value_list', [@_]);

            $self->{'return_list'} = [];

            my $match_found;

            for my $key (keys %{$self->{'data_hash_list'}}) {
                my $data_hash = $self->{'data_hash_list'}->{$key};
                my $function_name = defined $data_hash->{'real_function_name'} ?
                    $data_hash->{'real_function_name'} : $key;

                my $pattern = qr/$data_hash->{'sql_pattern'}/;

                if ($sql =~ $pattern) {
                    my $result;
                    if (
                        exists $data_hash->{'constant'}
                        and $data_hash->{'constant'}) {
                        $result = $data_hash->{'data'}->[0];
                    } else {
                        $result = shift(@{$data_hash->{'data'}});
                    }

                    if (exists $data_hash->{'cyclical'}
                        and $data_hash->{'cyclical'}) {

                        my $result_copy;

                        if (ref($result)) {
                            $result_copy = [];

                            for my $item (@{$result}) {
                                push (@{$result_copy}, {%{$item}});
                            }
                        }

                        push (@{$data_hash->{'data'}}, $result_copy);
                    }

                    if (not ref ($result) and defined $result) {
                        die($result);
                    } elsif (not defined $result) {
                        die('No more results for this function.');
                    }

                    if (defined $data_hash->{'input_type_list'} and
                        not $data_hash->{'input_type_list'} ~~
                            $self->{'input_type_list'}) {
                        next;
                        $match_found = 0;
                    } else {
                        $match_found = 1;
                        $self->{'return_list'} = $result;
                        last;
                    }
                }
            }

            if (defined $match_found and not $match_found) {
                $sql =~ m/([\w_]+)\s*\(/;

                die('DBD::Pg::st execute failed: ERROR:  function ' .
                    $sql . '(' .
                    join(', ', @{$self->{'input_type_list'}}) . ') ' .
                    'does not exist');
            }

            return;
        });

    $sth_mock->mock(
        'fetchall_arrayref',
        sub {
            my $self = shift;

            return $self->{'return_list'};
        });

    return $sth_mock;
}

=head2 B<mock_dbh()>

Returns a mock database connection handle.

=cut

sub mock_dbh {
    my @arg_list = @_;

    my $dbh_mock = Test::MockObject::Extends->new('DBI');

    $dbh_mock->mock('connect', sub { return shift; });

    $dbh_mock->mock(
        'prepare',
        sub {
            shift;

            return mock_sth(@_);
        });

    return $dbh_mock->connect(@arg_list);
}

=head2 B<main()>

Main procedure that is being run when the module is being
required. Fakes the DBI package by replacing it with a
B<Test::MockObject> object.

=cut

sub main {
    Test::MockObject::Extends->new('DBI')->fake_module(
        'DBI', 'connect' => sub { return mock_dbh(@_); });
}

main();

=head1 SEE ALSO

=over 4

=item L<DBI>

=item L<DBD::Pg>

=item L<Eve::Test>

=item L<Test::Class>

=item L<Test::MockObject>

=item L<Test::MockObject::Extends>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

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
