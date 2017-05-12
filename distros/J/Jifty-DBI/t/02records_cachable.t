#!/usr/bin/env perl -w

use strict;
use warnings;
use File::Spec;
use Test::More;
BEGIN { require "t/utils.pl" }

use constant TESTS_PER_DRIVER => 42;

our (@available_drivers);
my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d (@available_drivers) {
SKIP: {
        unless ( has_schema( 'TestApp::Address', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok( $handle->dbh, 'DBI::db' );

        {my $ret = init_schema( 'TestApp::Address', $handle );
        isa_ok( $ret, 'DBI::st',
            "Inserted the schema. got a statement handle back" );}

        {    # simple, load the same thing from cache
            my $rec = TestApp::Address->new( handle => $handle );
            isa_ok( $rec, 'Jifty::DBI::Record' );

            my ($id)
                = $rec->create( name => 'Jesse', phone => '617 124 567' );
            ok( $id, "Created record #$id" );

            ok( $rec->load($id), "Loaded the record" );
            is( $rec->id, $id, "The record has its id" );
            is( $rec->name, 'Jesse', "The record's name is Jesse" );

            my $rec_cache = TestApp::Address->new( handle => $handle );
            my ( $status, $msg ) = $rec_cache->load_by_cols( id => $id );
            ok( $status, 'loaded record' );
            is( $rec_cache->id, $id, 'the same record as we created' );
            is( $msg, 'Fetched from cache', 'we fetched record from cache' );
        }

        Jifty::DBI::Record::Cachable->flush_cache;

        {    # load by name then load by id, check that we fetch from hash
            my $rec = TestApp::Address->new( handle => $handle );
            ok( $rec->load_by_cols( name => 'Jesse' ), "Loaded the record" );
            is( $rec->name, 'Jesse', "The record's name is Jesse" );

            my $rec_cache = TestApp::Address->new( handle => $handle );
            my ( $status, $msg ) = $rec_cache->load_by_cols( id => $rec->id );
            ok( $status, 'loaded record' );
            is( $rec_cache->id, $rec->id, 'the same record as we created' );
            is( $msg, 'Fetched from cache', 'we fetched record from cache' );
        }

        Jifty::DBI::Record::Cachable->flush_cache;

        {    # load_by_cols and undef, 0 or '' values
            my $rec = TestApp::Address->new( handle => $handle );
            my ($id) = $rec->create( name => 'Emptyphone', phone => '' );
            ok( $id, "Created record #$id" );
            ($id) = $rec->create( name => 'Zerophone', phone => 0 );
            ok( $id, "Created record #$id" );
            ($id) = $rec->create( name => 'Undefphone', phone => undef );
            ok( $id, "Created record #$id" );

            Jifty::DBI::Record::Cachable->flush_cache;

            ok( $rec->load_by_cols( phone => undef ), "Loaded the record" );
            is( $rec->name, 'Undefphone', "Undefphone record" );

            is( $rec->phone, undef, "phone number is undefined" );

            ok( $rec->load_by_cols( phone => '' ), "Loaded the record" );
            is( $rec->name,  'Emptyphone', "Emptyphone record" );
            is( $rec->phone, '',           "phone number is empty string" );

            ok( $rec->load_by_cols( phone => 0 ), "Loaded the record" );
            is( $rec->name,  'Zerophone', "Zerophone record" );
            is( $rec->phone, 0,           "phone number is zero" );

     # XXX: next thing fails, looks like operator is mandatory
     # ok($rec->load_by_cols( phone => { value => 0 } ), "Loaded the record");
            ok( $rec->load_by_cols(
                    phone => { operator => '=', value => 0 }
                ),
                "Loaded the record"
            );
            is( $rec->name,  'Zerophone', "Zerophone record" );
            is( $rec->phone, 0,           "phone number is zero" );
        }

        Jifty::DBI::Record::Cachable->flush_cache;

        {    # case insensetive columns names
            my $rec = TestApp::Address->new( handle => $handle );
            ok( $rec->load_by_cols( name => 'Jesse' ), "Loaded the record" );
            is( $rec->name, 'Jesse', "loaded record" );

            my $rec_cache = TestApp::Address->new( handle => $handle );
            my ( $status, $msg )
                = $rec_cache->load_by_cols( name => 'Jesse' );
            ok( $status, 'loaded record' );
            is( $rec_cache->id, $rec->id, 'the same record as we created' );
            is( $msg, 'Fetched from cache', 'we fetched record from cache' );
        }

        Jifty::DBI::Record::Cachable->flush_cache;

        {
            my $rec = TestApp::Address->new( handle => $handle );
            my ($id) = $rec->create( name => 'Metadata', metadata => { some => "values" } );
            ok( $id, "Created record #$id" );

            # Do a search, but only load the 'id' column
            my $search = TestApp::AddressCollection->new( handle => $handle );
            $search->columns(qw/id/);
            $search->limit( column => 'name', value => 'Metadata');

            $rec = $search->first;
            is( $rec->id, $id, "The record has its id" );
            is_deeply( $rec->metadata, { some => "values" } , "Got decoded values");

            my $cache = TestApp::Address->new( handle => $handle );
            my ( $status, $msg ) = $cache->load($id);
            ok( $status, 'loaded record' );
            is( $cache->id, $id, 'the same record as we created' );
            is( $msg, 'Fetched from cache', 'we fetched record from cache' );
            is_deeply( $cache->metadata, { some => "values" } , "Got decoded values");
        }

        Jifty::DBI::Record::Cachable->flush_cache;

        cleanup_schema( 'TestApp::Address', $handle );
        disconnect_handle($handle);
    }
}    # SKIP, foreach blocks

1;

package TestApp::Address;
use base qw/Jifty::DBI::Record::Cachable/;

sub schema_mysql {
    <<EOF;
CREATE TEMPORARY table addresses (
        id integer AUTO_INCREMENT,
        name varchar(36),
        phone varchar(18),
        address varchar(50),
        employee_id int(8),
        metadata text,
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
        employee_id integer,
        metadata text
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
        employee_id int(8),
        metadata text)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE addresses_seq",
    "CREATE TABLE addresses (
        id integer CONSTRAINT addresses_key PRIMARY KEY,
        name varchar(36),
        phone varchar(18),
        employee_id integer,
        metadata text
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE addresses_seq",
    "DROP TABLE addresses", 
] }

1;

package TestApp::Address;

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column name => type is 'varchar(14)';

    column phone => type is 'varchar(18)';

    column
        address => type is 'varchar(50)',
        default is '';

    column employee_id => type is 'int(8)';

    column metadata => type is 'text',
        filters are 'Jifty::DBI::Filter::YAML';
    }
}

package TestApp::AddressCollection;
use base qw/Jifty::DBI::Collection/;
use constant table => "addresses";

1;
