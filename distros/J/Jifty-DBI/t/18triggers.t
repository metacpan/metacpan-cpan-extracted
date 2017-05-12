#!/usr/bin/env perl -w

use strict;
use warnings;
use File::Spec;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 66;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
    unless (has_schema('TestApp::Address', $d)) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless (should_test($d)) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    my $handle = get_handle($d);
    connect_handle($handle);
    isa_ok($handle->dbh, 'DBI::db');

    {my $ret = init_schema('TestApp::Address', $handle);
    isa_ok($ret, 'DBI::st', "Inserted the schema. got a statement handle back");}

    my $rec = TestApp::Address->new( handle => $handle );
    isa_ok($rec, 'Jifty::DBI::Record');

    my $rid = $rec->create(
        name  => 'Sterling',
        phone => '123 456 7890',
    );
    ok($rid, 'created a record');
    $rec->load($rid);
    ok($rec->id, 'loaded a record');

    $rec->set_name('zostay');
    $rec->set_phone('098 765 4321');

    my $ret = $rec->delete;
    ok($ret, 'deleted a record');
    disconnect_handle($handle);
};
}

package TestApp::TestMixin;
use base qw/ Jifty::DBI::Record::Plugin /;

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema { };

use Test::More;

sub register_triggers {
    my $self = shift;

    $self->add_trigger(before_create => sub {
        my $self = shift;
        my $columns = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $columns, 'HASH', 'arg is a hash');
        is(scalar(keys %$columns), 2, 'arg has 2 keys');
        is($columns->{name}, 'Sterling', 'name is Sterling');
        is($columns->{phone}, '123 456 7890', 'phone is 123 456 7890');
    });
    $self->add_trigger(after_create => sub {
        my $self = shift;
        my $ret = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $ret, 'SCALAR', 'arg is a scalar ref');
        ok($$ret, 'create was sucessful');
    });
    $self->add_trigger(before_set => sub {
        my $self = shift;
        my $arg = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $arg, 'HASH', 'arg is a hash');
        is(scalar(keys %$arg), 3, 'hash has 2 keys');
        ok($arg->{column}, "column arg is set");
        ok($arg->{value}, "value arg set");
        is($arg->{is_sql_function}, undef, 'is_sql_function is undef');
    });
    $self->add_trigger(after_set => sub {
        my $self = shift;
        my $arg = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $arg, 'HASH', 'arg is a hash');
        is(scalar(keys %$arg), 3, 'hash has 3 keys');
        ok($arg->{column}, "column arg is set");
        ok($arg->{value}, "value arg is set");
        ok($arg->{old_value}, "old_value arg is set");
    });
    $self->add_trigger(before_delete => sub {
        my $self = shift;
        isa_ok($self, 'TestApp::Address');
    });
    $self->add_trigger(after_delete => sub {
        my $self = shift;
        my $ret = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $ret, 'SCALAR', 'arg is a scalar ref');
        ok($$ret, 'delete was successful');
    });
}

sub register_triggers_for_column {
    my $self   = shift;
    my $column = shift;

    my $old_value = $column eq 'name' ? 'Sterling' : '123 456 7890';
    my $value     = $column eq 'name' ? 'zostay'   : '098 765 4321';

    $self->add_trigger('before_set_'.$column => sub {
        my $self = shift;
        my $arg = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $arg, 'HASH', 'arg is a hash');
        is(scalar(keys %$arg), 3, 'hash has 2 keys');
        is($arg->{column}, $column, "column arg is $column");
        is($arg->{value}, $value, "value arg is $value");
        is($arg->{is_sql_function}, undef, 'is_sql_function is undef');
    });
    $self->add_trigger('after_set_'.$column => sub {
        my $self = shift;
        my $arg = shift;
        isa_ok($self, 'TestApp::Address');
        is(ref $arg, 'HASH', 'arg is a hash');
        is(scalar(keys %$arg), 3, 'hash has 3 keys');
        is($arg->{column}, $column, "column arg is $column");
        is($arg->{value}, $value, "value arg is $value");
        is($arg->{old_value}, $old_value, "old_value arg is $old_value");
    });
}

1;

package TestApp::Address;
use base qw/ Jifty::DBI::Record /;

sub schema_mysql {
<<EOF;
CREATE TEMPORARY table addresses (
        id integer AUTO_INCREMENT,
        name varchar(36),
        phone varchar(18),
        address varchar(50),
        employee_id int(8),
        PRIMARY KEY (id))
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY table addresses (
        id serial PRIMARY KEY,
        name varchar,
        phone varchar,
        address varchar,
        employee_id integer
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE table addresses (
        id  integer primary key,
        name varchar(36),
        phone varchar(18),
        address varchar(50),
        employee_id int(8))
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE addresses_seq",
    "CREATE TABLE addresses (
        id integer CONSTRAINT address_key PRIMARY KEY,
        name varchar(36),
        phone varchar(18),
        employee_id integer
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE addresses_seq",
    "DROP TABLE addresses",
] }

1;

BEGIN {
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column name =>
  till 999,
  type is 'varchar(14)';

column phone =>
  type is 'varchar(18)';

column address =>
  type is 'varchar(50)',
  default is '';

column employee_id =>
  type is 'int(8)';
};
TestApp::TestMixin->import();
}
1;

