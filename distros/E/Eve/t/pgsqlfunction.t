# -*- mode: Perl; -*-
package PgSqlFunctionTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::Exception;
use Test::More;

use Eve::DbiStub;
use Eve::RegistryStub;

use Eve::PgSqlFunction;
use Eve::Registry;

sub setup : Test(setup) {
    my $self = shift;

    my $registry = Eve::Registry->new();
    $self->{'pgsql'} = $registry->get_pgsql();
}

sub teardown : Test(teardown) {
    my $self = shift;

    $self->{'pgsql'}->get_connection()->dbh->clear();
}

sub test_init_clean : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function');

    is($self->{'pgsql'}->get_connection()->dbh->call_pos(-1), 'prepare');
    is_deeply(
        [$self->{'pgsql'}->get_connection()->dbh->call_args(-1)],
        [$self->{'pgsql'}->get_connection()->dbh,
         'SELECT * FROM pgsql_function_test.test_function()']);
}

sub test_init_input_and_bind : Test(6) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        input_list => [
            {'id' => $self->{'pgsql'}->get_bigint()},
            {'memo' => $self->{'pgsql'}->get_text()}]);

    is($self->{'pgsql'}->get_connection()->dbh->call_pos(-1), 'prepare');
    is_deeply(
        [$self->{'pgsql'}->get_connection()->dbh->call_args(-1)],
        [$self->{'pgsql'}->get_connection()->dbh,
         'SELECT * FROM pgsql_function_test.test_function(?, ?)']);
    is($function->sth->call_pos(1), 'bind_param');
    is_deeply(
        [$function->sth->call_args(1)],
        [$function->sth, 1, undef,
         {'pg_type' => $self->{'pgsql'}->get_bigint()->get_type()}]);
    is($function->sth->call_pos(2), 'bind_param');
    is_deeply(
        [$function->sth->call_args(2)],
        [$function->sth, 2, undef,
         {'pg_type' => $self->{'pgsql'}->get_text()->get_type()}]);
}

sub test_execute_no_parameters : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        is_set_returning => 1);

    $function->execute();

    is($function->sth->call_pos(1), 'execute');
    is_deeply([$function->sth->call_args(1)], [$function->sth]);
}

sub test_execute_parameters : Test(4) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        input_list => [
            {'memo' => $self->{'pgsql'}->get_text()},
            {'id' => $self->{'pgsql'}->get_bigint()}],
        is_set_returning => 1);

    $function->execute(
        value_hash => {'memo' => 'some text', 'id' => 1});

    is($function->sth->call_pos(3), 'execute');
    is_deeply(
        [$function->sth->call_args(3)],
        [$function->sth, 'some text', 1]);

    $function->execute(
        value_hash => {'memo' => 'another text', 'id' => 2});

    is($function->sth->call_pos(5), 'execute');
    is_deeply(
        [$function->sth->call_args(5)],
        [$function->sth, 'another text', 2]);
}

sub test_execute_not_enough_substitutions : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        input_list => [
            {'memo' => $self->{'pgsql'}->get_text()},
            {'id' => $self->{'pgsql'}->get_bigint()}]);

    throws_ok(
        sub { $function->execute(value_hash => {'memo' => 'some text'}); },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Required input parameter: id/);
}

sub test_execute_redundant_substitutions : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        input_list => [
            {'memo' => $self->{'pgsql'}->get_text()}]);

    throws_ok(
        sub {
            $function->execute(
                value_hash => {
                    'memo' => 'some text',
                    'oops' => 1, 'wtf' => 1});
        },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Redundant input parameter\(s\): oops, wtf/);
}

sub test_execute_wrap_and_serialize : Test(3) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function',
        input_list => [
            {'dummy' => Eve::PgSqlFunctionTest::DummyType->new()}],
        is_set_returning => 1);

    is_deeply(
        [$self->{'pgsql'}->get_connection()->dbh->call_args(-1)],
        [$self->{'pgsql'}->get_connection()->dbh,
         "SELECT * FROM pgsql_function_test.test_function('wrapped ' || ?)"]);

    $function->execute(value_hash => {'dummy' => 'text'});

    is($function->sth->call_pos(2), 'execute');
    is_deeply(
        [$function->sth->call_args(2)],
        [$function->sth, 'serialized text']);
}

sub test_execute_return : Test(3) {
    my $self = shift;

    my $data_hash = Eve::DbiStub::get_compiled_data();

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function_1',
        input_list => [],
        output_list => [
            {'id' => $self->{'pgsql'}->get_bigint()},
            {'memo' => $self->{'pgsql'}->get_text()}],
        is_set_returning => 1);

    my $result = $function->execute(value_hash => {});
    is($function->sth->call_pos(-1), 'fetchall_arrayref');
    is_deeply([$function->sth->call_args(-1)], [$function->sth, {}]);

    is_deeply(
        $result,
        $data_hash->{'test_function_1'}->{'data'}->[0]);
}

sub test_execute_deserialize : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function_2',
        input_list => [
            {'memo' => Eve::PgSqlFunctionTest::DummyType->new()}],
        output_list => [
            {'memo' => Eve::PgSqlFunctionTest::DummyType->new()}]);

    is_deeply(
        $function->execute(value_hash => {'memo' => 'text'}),
        {'memo' => 'deserialized text'});
    is_deeply([$function->sth->call_args(-2)],
              [$function->sth, 'serialized text']);
}

sub test_execute_not_enough_column : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function_2',
        input_list => [
            {'memo' => Eve::PgSqlFunctionTest::DummyType->new()}],
        output_list => [
            {'memo' => Eve::PgSqlFunctionTest::DummyType->new()},
            {'id' => $self->{'pgsql'}->get_bigint()}]);

    throws_ok(
        sub { $function->execute(value_hash => {'memo' => 'text'}); },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Column has not been returned: id/);
}

sub test_execute_redundant_column : Test(2) {
    my $self = shift;

    my $function = Eve::PgSqlFunction->new(
        connection => $self->{'pgsql'}->get_connection(),
        name => 'pgsql_function_test.test_function_2',
        input_list => [
            {'memo' => Eve::PgSqlFunctionTest::DummyType->new()}]);

    throws_ok(
        sub { $function->execute(value_hash => {'memo' => 'text'}); },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Redundant column\(s\) returned: memo/);
}

sub test_wrong_parameter_definition : Test(2) {
    my $self = shift;

    throws_ok(
        sub {
            Eve::PgSqlFunction->new(
                connection => $self->{'pgsql'}->get_connection(),
                name => 'pgsql_function_test.test_function_2',
                input_list => [
                    {'memo' => Eve::PgSqlFunctionTest::DummyType->new(),
                     'and' => 'something else'}])
        },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Wrong parameter definition/);
}

sub test_not_is_set_returning_wrong_rows_number : Test(4) {
    my $self = shift;

    throws_ok(
        sub {
            Eve::PgSqlFunction->new(
                connection => $self->{'pgsql'}->get_connection(),
                name => 'pgsql_function_test.test_function',
                is_set_returning => 0)->execute();
        },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Expected 1 row from database but returned 0/);

    throws_ok(
        sub {
            Eve::PgSqlFunction->new(
                connection => $self->{'pgsql'}->get_connection(),
                name => 'pgsql_function_test.test_function_1',
                input_list => [],
                output_list => [
                    {'id' => $self->{'pgsql'}->get_bigint()},
                    {'memo' => $self->{'pgsql'}->get_text()}],
                is_set_returning => 0)->execute();
        },
        'Eve::Error::Value');
    like(
        Eve::Error::Value->caught()->message,
        qr/Expected 1 row from database but returned 2/);
}

1;

package Eve::PgSqlFunctionTest::DummyType;

use parent qw(Eve::PgSqlType);

use DBD::Pg ();

sub get_type {
    return DBD::Pg::PG_TEXT;
}

sub wrap {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $expression);

    return "'wrapped ' || $expression";
}

sub serialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return 'serialized '.$value;
}

sub deserialize {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $value);

    return 'deserialized '.$value;
}

1;
