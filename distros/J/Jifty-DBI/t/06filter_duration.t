#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 42;

eval "use Time::Duration ()";
if ($@) {
    plan skip_all => "Time::Duration not installed";
}

eval "use Time::Duration::Parse ()";
if ($@) {
    plan skip_all => "Time::Duration::Parse not installed";
}

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

my @bad_input        = ('foo');
my @duration_input   = ('3h5m', '3:05', '3:04:60', '3h 0:05', '1h 2:04:60');
my $duration_output  = '3h5m';
my $duration_seconds = 11100;

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

    for my $input ( @bad_input ) {
        my $rec = TestApp::User->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        my ($id) = $rec->create( my_data => $input );
        ok($id, 'created record');
        ok($rec->load($id), 'loaded record');
        is($rec->id, $id, 'record id matches');
        
        is($rec->my_data, undef, 'my_data output is undef');
    }

    for my $input ( @duration_input ) {
        my $rec = TestApp::User->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        my ($id) = $rec->create( my_data => $input );
        ok($id, 'created record');
        ok($rec->load($id), 'loaded record');
        is($rec->id, $id, 'record id matches');
        
        is($rec->my_data, $duration_output, 'my_data output is consistent');
        
        my $sth = $handle->simple_query("SELECT my_data FROM users WHERE id = $id");
        my ($seconds) = $sth->fetchrow_array;

        is( $seconds, $duration_seconds, 'my_data seconds match' );

        # undef/NULL
        $rec->set_my_data;
        is($rec->my_data, undef, 'set undef value');
    }

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
    my_data integer
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
    id integer auto_increment primary key,
    my_data integer
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
    id serial primary key,
    my_data integer
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column my_data =>
        type is 'integer',
        filters are qw/ Jifty::DBI::Filter::Duration /;
    }
}

