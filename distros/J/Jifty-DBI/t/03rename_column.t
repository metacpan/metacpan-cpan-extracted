#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;
use Jifty::DBI::Handle;

BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 11;

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

    drop_table_if_exists( 'test', $handle );

    my $sth = $handle->simple_query(
        "CREATE TABLE test (a int, x integer not null default 1)"
    );
    ok $sth, 'created a table';

    ok $handle->simple_query("insert into test values(2,2)"), "inserted a record";
    $sth = $handle->simple_query("select * from test");
    is $sth->fetchrow_hashref->{'x'}, 2, 'correct value';

    $handle->rename_column( table => 'test', column => 'x', to => 'y' );
    $sth = $handle->simple_query("select * from test");
    is $sth->fetchrow_hashref->{'y'}, 2, 'correct value';
    $sth->finish;
    undef $sth;

    my @warnings;
    ok !eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $handle->simple_query("insert into test(x) values(1)");
    }, "no x anymore";
    ok((splice @warnings), "we got warnings");

    ok !eval {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $handle->simple_query("insert into test(y) values(NULL)");
    }, "NOT NULL is still there";
    ok((splice @warnings), "we got warnings");

    $handle->simple_query("delete from test");
    ok $handle->simple_query("insert into test(a) values(1)"), "DEFAULT is still there";
    is $handle->simple_query("select * from test")->fetchrow_hashref->{'y'},
        1, 'correct value';
    undef $handle;
}} # SKIP, foreach blocks

1;
