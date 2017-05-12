#!/usr/bin/env perl -w

use strict;
use warnings;
use File::Spec;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@available_drivers);
use constant TESTS_PER_DRIVER => 59;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;

plan tests => $total;

foreach my $d (@available_drivers) {
SKIP: {
        unless ( has_schema( 'TestApp', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok( $handle->dbh, 'DBI::db', "Got handle for $d" );

        {
            my $ret = init_schema( 'TestApp', $handle );
            isa_ok( $ret, 'DBI::st',
                "Inserted the schema. got a statement handle back" );
        }

        my $emp  = TestApp::Employee->new( handle => $handle );
        my $e_id = $emp->create( name             => 'RUZ' );
        ok( $e_id, "Got an id for the new employee: $e_id" );
        $emp->load($e_id);
        is( $emp->id, $e_id );

        my $phone_collection = $emp->phones;
        isa_ok( $phone_collection, 'TestApp::PhoneCollection' );
        {
            my $phone = TestApp::Phone->new( handle => $handle );
            isa_ok( $phone, 'TestApp::Phone' );
            my $p_id = $phone->create(
                employee => $e_id,
                phone    => '+7(903)264-03-51'
            );
            is( $p_id, 1, "Loaded phone $p_id" );
            $phone->load($p_id);

            my $obj = $phone->employee;

            ok( $obj, "Employee #$e_id has phone #$p_id" );
            isa_ok( $obj, 'TestApp::Employee' );
            is( $obj->id,   $e_id );
            is( $obj->name, 'RUZ' );
        }

        my $emp2   = TestApp::Employee->new( handle => $handle );
        my $e2_id  = $emp2->create( name            => 'JESSE' );
        my $phone2 = TestApp::Phone->new( handle    => $handle );
        my $p2_id
            = $phone2->create( employee => $e2_id, phone => '+16173185823' );

        for ( 3 .. 6 ) {
            my $i = $_;
            my $phone = TestApp::Phone->new( handle => $handle );
            isa_ok( $phone, 'TestApp::Phone' );
            my $p_id = $phone->create( employee => $e_id, phone => "+1 $i" );
            is( $p_id, $i, "Loaded phone $p_id" );
            $phone->load($p_id);

            my $obj = $phone->employee;

            ok( $obj, "Employee #$e_id has phone #$p_id" );
            isa_ok( $obj, 'TestApp::Employee' );
            is( $obj->id,   $e_id );
            is( $obj->name, 'RUZ' );

        }

        $handle->log_sql_statements(1);

        {    # Old prefetch syntax
            $handle->clear_sql_statement_log;
            my $collection
                = TestApp::EmployeeCollection->new( handle => $handle );
            $collection->unlimit;
            my $phones_alias = $collection->join(
                alias1  => 'main',
                column1 => 'id',
                table2  => 'phones',
                column2 => 'employee'
            );
            $collection->prefetch( $phones_alias => 'phones' );
            $collection->order_by( column => 'id' );
            is( $collection->count, 2 );
            is( scalar( $handle->sql_statement_log ),
                1, "count is one statement" );

            $handle->clear_sql_statement_log;
            my $user = $collection->next;
            is( $user->name, 'RUZ' );
            is( $user->id, 1, "got our user" );
            my $phones = $user->phones;
            is( $phones->first->id, 1 );
            is( $phones->count, 5 );

            my $jesse = $collection->next;
            is( $jesse->name, 'JESSE' );
            my $jphone = $jesse->phones;
            is( $jphone->count, 1 );

            is( scalar( $handle->sql_statement_log ),
                1, "all that. just one sql statement" );
        }

        {    # New syntax, one-to-many
            $handle->clear_sql_statement_log;
            my $collection
                = TestApp::EmployeeCollection->new( handle => $handle );
            $collection->unlimit;
            $collection->prefetch( name => 'phones' );
            is( $collection->count, 2 );
            is( scalar( $handle->sql_statement_log ),
                1, "count is one statement" );

            $handle->clear_sql_statement_log;
            my $user = $collection->next;
            is( $user->id, 1, "got our user" );
            my $phones = $user->phones;
            is( $phones->first->id, 1 );
            is( $phones->count, 5 );

            my $jesse = $collection->next;
            is( $jesse->name, 'JESSE' );
            my $jphone = $jesse->phones;
            is( $jphone->count, 1 );

            is( scalar( $handle->sql_statement_log ),
                1, "all that. just one sql statement" );
        }

        {    # New syntax, one-to-one
            $handle->clear_sql_statement_log;
            my $collection
                = TestApp::PhoneCollection->new( handle => $handle );
            $collection->unlimit;
            $collection->prefetch( name => 'employee' );
            is( $collection->count, 6 );
            is( scalar( $handle->sql_statement_log ),
                1, "count is one statement" );

            $handle->clear_sql_statement_log;
            my $phone = $collection->next;
            is( $phone->id, 1, "Got a first phone" );
            is( $phone->phone, '+7(903)264-03-51', "Got ruz's phone number" );
            my $employee = $phone->employee;
            is( $employee->id, 1 );
            is( $employee->name, "RUZ", "Employee matches" );

            is( scalar( $handle->sql_statement_log ),
                1, "all that. just one sql statement" );
        }

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle($handle);
    }


}    # SKIP, foreach blocks

1;

package TestApp;

sub schema_sqlite {
    [   q{
CREATE table employees (
        id integer primary key,
        name varchar(36)
)
}, q{
CREATE table phones (
        id integer primary key,
        employee integer NOT NULL,
        phone varchar(18)
) }
    ];
}

sub schema_mysql {
    [   q{
CREATE TEMPORARY table employees (
        id integer AUTO_INCREMENT primary key,
        name varchar(36)
)
}, q{
CREATE TEMPORARY table phones (
        id integer AUTO_INCREMENT primary key,
        employee integer NOT NULL,
        phone varchar(18)
)
}
    ];
}

sub schema_pg {
    [   q{
CREATE TEMPORARY table employees (
        id serial PRIMARY KEY,
        name varchar
)
}, q{
CREATE TEMPORARY table phones (
        id serial PRIMARY KEY,
        employee integer references employees(id),
        phone varchar
)
}
    ];
}

package TestApp::PhoneCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab  = $self->new_item->table();
    return $tab;
}

package TestApp::Employee;
use base qw/Jifty::DBI::Record/;

sub _value {
    my $self = shift;
    my $x    = ( $self->__value(@_) );
    return $x;
}

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
        column name   => type is 'varchar';
        column phones => references TestApp::PhoneCollection by 'employee';
    }
}

package TestApp::Phone;
use base qw/Jifty::DBI::Record/;

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
        column employee => references TestApp::Employee;
        column phone    => type is 'varchar';
    }
}

package TestApp::EmployeeCollection;

use base qw/Jifty::DBI::Collection/;

1;
