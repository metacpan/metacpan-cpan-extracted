#!/usr/bin/env perl
use strict;
use warnings;

use Encode qw(decode_utf8 is_utf8);

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 20;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

my $normal_data = "Hi there";
my $perl_data   = "Hi there—";
my $utf8_data   = decode_utf8($perl_data);

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

    # data ref, is_utf8 expected, base64 expected, handle
    store_data( \$normal_data,  0, "SGkgdGhlcmU=\n",      $handle );
    store_data( \$perl_data,    0, "SGkgdGhlcmXigJQ=\n",  $handle );
    store_data( \$utf8_data,    1, "SGkgdGhlcmXigJQ=\n",  $handle );

    cleanup_schema('TestApp', $handle);
    disconnect_handle($handle);
}
}

sub store_data {
    my $data = shift;
    my $isutf8 = shift;
    my $expected = shift;
    my $handle = shift;

    my $utf8 = is_utf8($$data) ? 1 : 0;

    ok $utf8 == $isutf8, "is_utf8 = $utf8 as expected";
    
    my $rec = TestApp::User->new( handle => $handle );
    isa_ok($rec, 'Jifty::DBI::Record');

    my $id;
   
    eval { $id = $rec->create( content => $$data ); };
    ok($id, 'created record');
    ok($rec->load($id), 'loaded record');
    is($rec->id, $id, 'record id matches');
    is($rec->__raw_value('content'), $expected, "got expected base64");
}

package TestApp::User;
use base qw/ Jifty::DBI::Record /;

1;

sub schema_sqlite {

<<EOF;
CREATE table users (
    id integer primary key,
    content text
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
    id integer auto_increment primary key,
    content text
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
    id serial primary key,
    content text
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column content =>
        type is 'text',
        filters are qw/ Jifty::DBI::Filter::base64 /;
    }
}

