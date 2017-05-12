#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 18;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

use DateTime ();

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp::User', $d ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }
        diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};

        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db');

        {my $ret = init_schema( 'TestApp::User', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        my $rec = TestApp::User->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        my $now = time;
        my $today = DateTime->from_epoch( epoch => $now )->truncate( to => 'day' )->epoch;
        my $min_of_day = DateTime->from_epoch( epoch => $now )->truncate( to => 'minute' );
        my $dt = DateTime->from_epoch( epoch => $now );
        my ($id) = $rec->create( created => $dt, event_on => $dt, event_stops => $min_of_day );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        isa_ok($rec->created, 'DateTime' );
        is( $rec->created->epoch, $now, "Correct value");
        isa_ok($rec->event_on, 'DateTime' );
        is( $rec->event_on->epoch, $today, "Correct value");
        isa_ok($rec->event_stops, 'DateTime' );
        is( $rec->event_stops->minute, $min_of_day->minute, "Correct value");
        is( $rec->event_stops->hour, $min_of_day->hour, "Correct value");

        # undef/NULL
        $rec->set_created;
        is($rec->created, undef, "Set undef value" );

        # Create using default undef
        my $rec2 = TestApp::User->new( handle => $handle );
        isa_ok($rec2, 'Jifty::DBI::Record');
        is($rec2->created, undef, 'Default of undef');

        # from string
        require POSIX;
        $rec->set_created( POSIX::strftime( "%Y-%m-%d %H:%M:%S", gmtime($now) ) );
        isa_ok($rec->created, 'DateTime' );
        is( $rec->created->epoch, $now, "Correct value");

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle( $handle );
}
}

package TestApp::User;
use base qw/Jifty::DBI::Record/;

1;

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        created datetime,
        event_on date,
        event_stops time
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        created datetime,
        event_on date,
        event_stops time
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        created timestamp,
        event_on date,
        event_stops time
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;


    use Jifty::DBI::Record schema {
    column created =>
      type is 'datetime',
      filters are qw/Jifty::DBI::Filter::DateTime/,
      default is undef;

    column event_on =>
      type is 'date',
      filters are qw/Jifty::DBI::Filter::Date/;

    column event_stops =>
      type is 'time',
      filters are qw/Jifty::DBI::Filter::Time/;
    }
}

1;

