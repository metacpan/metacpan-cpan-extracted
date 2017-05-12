#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;
use Jifty::DBI::Handle;

BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 7;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
    unless( should_test( $d ) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    my $handle = get_handle($d);
    connect_handle($handle);
    isa_ok( $handle->dbh, 'DBI::db' );

    my $sth;
    drop_table_if_exists( 'test', $handle );
    drop_table_if_exists( 'test1', $handle );

    $sth = $handle->simple_query("CREATE TABLE test (a int)");
    ok $sth, 'created a table';

    ok $handle->simple_query("insert into test values(1)"), "inserted a record";
    is $handle->simple_query("select * from test")->fetchrow_hashref->{'a'},
        1, 'correct value';

    $handle->rename_table( table => 'test', to => 'test1' );

    is $handle->simple_query("select * from test1")->fetchrow_hashref->{'a'},
        1, 'correct value';

    my @warnings;
    ok !eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $handle->simple_query("select * from test")
    }, "no test table anymore";
    ok(@warnings, "got some warnings");

}} # SKIP, foreach blocks

1;
