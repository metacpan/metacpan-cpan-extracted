#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 72;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp::Address', $d ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db');

        {my $ret = init_schema( 'TestApp::Address', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        my $rec = TestApp::Address->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');


# _accessible testings
        is( $rec->_accessible('id' => 'read'), 1, 'id is accessible for read' );
        is( $rec->_accessible('id' => 'write'), 0, 'id is not accessible for write' );
        is( $rec->_accessible('id'), undef, "any column is not accessible in undefined mode" );
        is( $rec->_accessible('unexpected_column' => 'read'), undef, "column doesn't exist and can't be accessible for read" );
        is_deeply( [sort($rec->readable_attributes)], [sort qw(address employee_id id name phone)], 'readable attributes' );
        is_deeply( [sort($rec->writable_attributes)], [sort qw(address employee_id name phone)], 'writable attributes' );

        is $rec->column('employee_id')->sort_order, -1, "got manual sort order";

        can_ok($rec,'create');

        # Test create and load as class methods
    
        my $record2 = TestApp::Address->create( _handle => $handle, name => 'Enoch', phone => '123 456 7890');
        isa_ok($record2, 'TestApp::Address');
        ok($record2->id, "Created a record with a class method");
        is_deeply({ $record2->as_hash }, {
            id          => $record2->id,
            employee_id => undef,
            name        => 'Enoch',
            address     => '',
            phone       => '123 456 7890',
        }, 'as_hash works');

        my $clone2 = TestApp::Address->load_by_cols( _handle => $handle, name => 'Enoch');
        isa_ok($clone2, 'TestApp::Address');
        is($clone2->phone, '123 456 7890');

        { 
            local *TestApp::Address::_handle = sub { return $handle};
        my $clone_by_id = TestApp::Address->load($record2->id);
        isa_ok($clone_by_id, 'TestApp::Address');
        is($clone_by_id->phone, '123 456 7890');
        }

        my ($id) = $rec->create( name => 'Jesse', phone => '617 124 567');
        ok($id,"Created record ". $id);
        ok($rec->load($id), "Loaded the record");

        is($rec->id, $id, "The record has its id");
        is ($rec->name, 'Jesse', "The record's name is Jesse");

        my ($val, $msg) = $rec->set_name('Obra');
        ok($val, $msg) ;
        is($rec->name, 'Obra', "We did actually change the name");
# Validate immutability of the column id
        ($val, $msg) = $rec->set_id( $rec->id + 1 );
        ok(!$val, $msg);
        is($msg, 'Immutable column', 'id is immutable column');
        is($rec->id, $id, "The record still has its id");

# Check some non existent column
        ok( !eval{ $rec->some_unexpected_column }, "The record has no 'some_unexpected_column'");
        {
                # test produce DBI warning
                local $SIG{__WARN__} = sub {return};
                is( $rec->_value( 'some_unexpected_column' ), undef, "The record has no 'some_unexpected_column'");
        }
        ok (!eval { $rec->set_some_unexpected_column( 'foo' )}, "Can't call nonexistent columns");
        ($val, $msg) = $rec->_set(column =>'some_unexpected_column', value =>'foo');
        ok(!$val, defined $msg ? $msg : "");


# Validate truncation on update

        ($val,$msg) = $rec->set_name('1234567890123456789012345678901234567890');
        ok($val, $msg);
        is($rec->name, '12345678901234', "Truncated on update");


# make sure we do _not_ truncate things which should not be truncated
        ($val,$msg) = $rec->set_employee_id('1234567890');
        ok($val, $msg) ;
        is($rec->employee_id, '1234567890', "Did not truncate id on create");

        #delete prev record
        $rec->delete;

# make sure we do truncation on create
        my $newrec = TestApp::Address->new( handle => $handle );
        my $newid = $newrec->create( name => '1234567890123456789012345678901234567890',
                                     employee_id => '1234567890' );

        $newrec->load($newid);

        ok ($newid, "Created a new record");
        is($newrec->name, '12345678901234', "Truncated on create");
        is($newrec->employee_id, '1234567890', "Did not truncate id on create");

# no prefetch feature and _load_from_sql sub checks
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->_load_from_sql('SELECT id FROM addresses WHERE id = ?', $newid);
        is($val, 1, 'found object');
        is($newrec->name, '12345678901234', "autoloaded not prefetched column");
        is($newrec->employee_id, '1234567890', "autoloaded not prefetched column");

# _load_from_sql and missing PK
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->_load_from_sql('SELECT name FROM addresses WHERE name = ?', '12345678901234');
        is($val, 0, "didn't find object");
        is($msg, "Missing a primary key?", "reason is missing PK");

# _load_from_sql and not existent row
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->_load_from_sql('SELECT id FROM addresses WHERE id = ?', 0);
        is($val, 0, "didn't find object");
        is($msg, "Couldn't find row", "reason is wrong id");
# _load_from_sql and wrong SQL
        $newrec = TestApp::Address->new( handle => $handle );
        {
                local $SIG{__WARN__} = sub{return};
                ($val, $msg) = $newrec->_load_from_sql('SELECT ...');
        }
        is($val, 0, "didn't find object");
        is($msg, "Couldn't execute query", "reason is bad SQL");

# test load_* methods
        $newrec = TestApp::Address->new( handle => $handle );
        $newrec->load();
        is( $newrec->id, undef, "can't load record with undef id");

        $newrec = TestApp::Address->new( handle => $handle );
        $newrec->load_by_cols( name => '12345678901234' );
        is( $newrec->id, $newid, "load record by 'name' column value");

# load_by_col with operator
        $newrec = TestApp::Address->new( handle => $handle );
        $newrec->load_by_cols( name => { value => '%45678%',
                                      operator => 'LIKE' } );
        is( $newrec->id, $newid, "load record by 'name' with LIKE");

# load_by_primary_keys
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->load_by_primary_keys( id => $newid );
        ok( $val, "load record by PK");
        is( $newrec->id, $newid, "loaded correct record");
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->load_by_primary_keys( {id => $newid} );
        ok( $val, "load record by PK");
        is( $newrec->id, $newid, "loaded correct record" );
        $newrec = TestApp::Address->new( handle => $handle );
        ($val, $msg) = $newrec->load_by_primary_keys( phone => 'some' );
        ok( !$val, "couldn't load, missing PK column");
        is( $msg, "Missing PK column: 'id'", "right error message" );

# Defaults kick in
        $rec = TestApp::Address->new( handle => $handle );
        $id = $rec->create( name => 'Chmrr' );
        ok( $id, "new record");
        $rec = TestApp::Address->new( handle => $handle );
        $rec->load_by_cols( name => 'Chmrr' );
        is( $rec->id, $id, "loaded record by empty value" );
        is( $rec->address, '', "Got default on create" );

# load_by_cols and empty or NULL values
        $rec = TestApp::Address->new( handle => $handle );
        $id = $rec->create( name => 'Obra', phone => undef );
        ok( $id, "new record");
        $rec = TestApp::Address->new( handle => $handle );
        $rec->load_by_cols( name => 'Obra', phone => undef, employee_id => '' );
        is( $rec->id, $id, "loaded record by empty value" );

# __set error paths
        $rec = TestApp::Address->new( handle => $handle );
        $rec->load( $id );
        $val = $rec->set_name( 'Obra' );
        isa_ok( $val, 'Class::ReturnValue', "couldn't set same value, error returned");
        is( ($val->as_array)[1], "That is already the current value", "correct error message" );
        is( $rec->name, 'Obra', "old value is still there");
        $val = $rec->set_name( 'invalid' );
        isa_ok( $val, 'Class::ReturnValue', "couldn't set invalid value, error returned");
        is( ($val->as_array)[1], 'Illegal value for name', "correct error message" );
        is( $rec->name, 'Obra', "old value is still there");
# XXX TODO FIXME: this test cover current implementation that is broken //RUZ
# fixed, now we can set undef values(NULLs)
        $val = $rec->set_name( );
        isa_ok( $val, 'Class::ReturnValue', "set empty/undef/NULL value");
        is( ($val->as_array)[1], "The new value has been set.", "correct error message" );
        is( $rec->name, undef, "new value is undef, NULL in DB");

# deletes
        $newrec = TestApp::Address->new( handle => $handle );
        $newrec->load( $newid );
        is( $newrec->delete, 1, 'successfuly delete record');
        $newrec = TestApp::Address->new( handle => $handle );
        $newrec->load( $newid );
        is( $newrec->id, undef, "record doesn't exist any more");

        cleanup_schema( 'TestApp::Address', $handle );
        disconnect_handle( $handle );
}} # SKIP, foreach blocks

1;


package TestApp::Address;
use base qw/Jifty::DBI::Record/;

sub validate_name
{
        my ($self, $value) = @_;
        return 0 if $value && $value =~ /invalid/i;
        return 1;
}

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
  type is 'int(8)',
  order is -1;
}
}
1;

