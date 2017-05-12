#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;# import => [qw(isa_ok skip plan)];
use Test::Warn;

BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 9;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp', $d ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db');

        {{my $ret = init_schema( 'TestApp', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}
        }


        my $emp = TestApp::Employee->new( handle => $handle );
        my $e_id = $emp->create( name => 'RUZ', employee_num => '123' );
        ok($e_id, "Got an id for the new employee");

        # Test 'is mandatory'
        warning_like {
            $e_id = $emp->create( employee_num => '456' );
        } qr/^Did not supply value for mandatory column name/;

        ok(!$e_id, "Did not get an id for second new employee, good");

        # Test 'is distinct'
        $e_id = $emp->create( name => 'Foo', employee_num => '456' );
        ok($e_id, "Was able to create a second record successfully");
        my $e_id2;

        warning_like {
            $e_id2 = $emp->create( name => 'Bar', employee_num => '123' );
        } qr/^TestApp::Employee=HASH\(\w+\) failed a 'is_distinct' check for employee_num on 123/;

        ok(!$e_id2, "is_distinct prevents us from creating another record");
        my $obj = TestApp::Employee->new( handle => $handle );
        $obj->load( $e_id );
        ok(!$obj->set_employee_num('123'), "is_distinct prevents us from modifying a record to a duplicate value");

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle( $handle );
}} # SKIP, foreach blocks

1;


package TestApp;
sub schema_sqlite {
[
q{
CREATE table employees (
        id integer primary key,
        name varchar(36) NOT NULL,
        employee_num int(8)
)
} ]
}

sub schema_mysql {
[ q{
CREATE TEMPORARY table employees (
        id integer AUTO_INCREMENT primary key,
        name varchar(36) NOT NULL,
        employee_num int(8)
)
} ]
}

sub schema_pg {
[ q{
CREATE TEMPORARY table employees (
        id serial PRIMARY KEY,
        name varchar NOT NULL,
        employee_num integer
)
} ]
}



package TestApp::Employee;

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {

    column name => type is 'varchar(18)',
        is mandatory;

    column employee_num =>
        type is 'int(8)',
        is distinct;
    }
}

1;

