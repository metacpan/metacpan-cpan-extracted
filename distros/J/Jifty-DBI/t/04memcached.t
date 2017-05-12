#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN { require 't/utils.pl' }

use constant TESTS_PER_DRIVER => 1;

our (@available_drivers);
my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
# plan tests => $total;

BEGIN {
    eval { require Cache::Memcached; Cache::Memcached->import; };
    plan skip_all => 'Cache::Memcached not available' if $@;
}

my $memd = Cache::Memcached->new({TestApp::Address->memcached_config});

plan skip_all => 'Memcached apparently not running' unless $memd->set('test_testval', 0, 1);

plan 'no_plan';

for my $d (@available_drivers) {
  SKIP: {
        unless ( has_schema( 'TestApp::Address', $d ) ) {
            skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless ( should_test($d) ) {
            skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle($d);
        connect_handle($handle);
        isa_ok($handle->dbh, 'DBI::db');

        {my $ret = init_schema( 'TestApp::Address', $handle );
        isa_ok( $ret, 'DBI::st',
                "Inserted the schema. got a statement handle back" );}


        # Create a record, load from cache
        my $rec = TestApp::Address->new( handle => $handle );

        my ($id) = $rec->create( name => 'Jesse', phone => '617 124 567' );
        ok( $id, "Created record #$id" );

        ok( $rec->load($id), "Loaded the record" );
        is( $rec->id, $id, "The record has its id" );
        is( $rec->name, 'Jesse', "The record's name is Jesse" );

        my $rec_cache = TestApp::Address->new( handle => $handle );
        my ( $status, $msg ) = $rec_cache->load_by_cols( id => $id );
        ok( $status, 'loaded record' );
        is( $rec_cache->id, $id, 'the same record as we created' );
        is( $msg, 'Fetched from cache', 'we fetched record from cache' );
        is( $rec_cache->phone, '617 124 567', "Loaded the phone number correctly");

        # Check mutation
        $rec->set_phone('555 543 6789');
        is($rec->phone, '555 543 6789');

        $rec = TestApp::Address->new( handle => $handle );
        $rec->load($id);
        is($rec->phone, '555 543 6789', "Loaded changed data from cache OK");
        disconnect_handle($handle);
}}

package TestApp::Address;
use base qw/Jifty::DBI::Record::Memcached/;

# Make this unique per run and database, since otherwise we'll get
# stale caches when we run for the 2nd and future drivers

sub cache_key_prefix {
    my $self = shift;
    my $driver = ref($self->_handle);
    $driver = lc $1 if $driver =~ /::(\w+)$/;
    return "jifty-test-$$-$driver";
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

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {

    column name => type is 'varchar(14)';

    column phone => type is 'varchar(18)';

    column
        address => type is 'varchar(50)',
        default is '';

    column employee_id => type is 'int(8)';
    }
}
1;
