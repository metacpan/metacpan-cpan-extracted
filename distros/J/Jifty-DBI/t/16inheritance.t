#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 17;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

use DateTime ();

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp::CrazyUser', $d ) ) {
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
        {my $ret = init_schema( 'TestApp::CrazyUser', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}
        my $rec = TestApp::CrazyUser->new( handle => $handle );
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
Jifty::DBI::Schema->register_types(
    Date =>
        sub { type is 'date', input_filters are qw/Jifty::DBI::Filter::Date/ },
    Time =>
        sub { type is 'time', input_filters are qw/Jifty::DBI::Filter::Time/ },
    DateTime => sub {
        type is 'datetime',
        input_filters are qw/Jifty::DBI::Filter::DateTime/
    }
);
}

use Jifty::DBI::Record schema {
    column created     => is DateTime;
    column event_on    => is Date;
    column event_stops => is Time;
};

package TestApp::CrazyUser;
BEGIN {
our @ISA =qw(TestApp::User);
}
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column craziness => type is 'text';
#    column event_on  => is mandatory;
};

sub schema_sqlite {

<<EOF;
CREATE table crazy_users (
        id integer primary key,
        craziness varchar(16),
        created datetime,
        event_on date,
        event_stops time
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table crazy_users (
        id integer auto_increment primary key,
        created datetime,
        event_on date,
        event_stops time
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table crazy_users (
        id serial primary key,
        craziness varchar(16),
        created timestamp,
        event_on date,
        event_stops time
)
EOF

}


1;

