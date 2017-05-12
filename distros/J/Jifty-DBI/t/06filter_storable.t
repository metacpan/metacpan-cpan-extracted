#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 9;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

my $complex_data = {
    foo => 'bar',
    baz => [ 1,  2, 3 ],
};

foreach my $d (@available_drivers) {
SKIP: {
    unless (has_schema('TestApp::User', $d)) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }

    unless (should_test($d)) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};

    my $handle = get_handle($d);
    connect_handle($handle);
    isa_ok($handle->dbh, 'DBI::db');

    {
        my $ret = init_schema('TestApp::User', $handle);
        isa_ok($ret, 'DBI::st', 'init schema');
    }

   my $rec = TestApp::User->new( handle => $handle );
   isa_ok($rec, 'Jifty::DBI::Record');

   my ($id) = $rec->create( my_data => $complex_data );
   ok($id, 'created record');
   ok($rec->load($id), 'loaded record');
   is($rec->id, $id, 'record id matches');
   is(ref $rec->my_data, 'HASH', 'my_data is a HASH');
   is_deeply($rec->my_data, $complex_data, 'my_data matches initial data');

   # undef/NULL
   $rec->set_my_data;
   is($rec->my_data, undef, 'set undef value');

   cleanup_schema('TestApp', $handle);
   disconnect_handle($handle);
}
}

package TestApp::User;
use base qw/ Jifty::DBI::Record /;

1;

sub schema_sqlite {

<<EOF;
CREATE table users (
    id integer primary key,
    my_data blob
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
    id integer auto_increment primary key,
    my_data blob
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
    id serial primary key,
    my_data bytea
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column my_data =>
        type is 'blob',
        filters are qw/ Jifty::DBI::Filter::Storable /;
    }
}

