#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 24;

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

        $handle->input_filters( 'Jifty::DBI::Filter::utf8' );
        is( ($handle->input_filters)[0], 'Jifty::DBI::Filter::utf8', 'Filter was added' );

        my $rec = TestApp::User->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        # "test" in Russian
        my $str = "\x{442}\x{435}\x{441}\x{442}";

        my($id) = $rec->create( signature => $str );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        ok( Encode::is_utf8($rec->signature), "Value is UTF-8" );
        is( $rec->signature, $str, "Value is the same" );

        # correct data with no UTF-8 flag
        my $nstr = Encode::encode_utf8( $str );
        ($id) = $rec->create( signature => $nstr );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        ok( Encode::is_utf8($rec->signature), "Value is UTF-8" );
        is( $rec->signature, $str, "Value is the same" );

        # cut string in the middle of the unicode char
        # and drop flag, leave only first char and
        # a half of the second so in result we will
        # get only one char
        $nstr = do{ use bytes; substr( $str, 0, 3 ) };
        ($id) = $rec->create( signature => $nstr );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        ok( Encode::is_utf8($rec->signature), "Value is UTF-8" );
        is( $rec->signature, "\x{442}", "Value is correct" );

        # UTF-8 string with flag unset and enabeld trancation
        # truncation should cut third char, but utf8 filter should
        # replace it with \x{fffd} code point
        $rec->set_name( Encode::encode_utf8($str) );
        is($rec->name, "\x{442}\x{435}",
           "Name was truncated to two UTF-8 chars"
          );

        # create with undef value, no utf8 or truncate magic
        ($id) = $rec->create( signature => undef );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        is($rec->signature, undef, "successfuly stored and fetched undef");

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle( $handle );
}
}

package TestApp::User;
use base qw/Jifty::DBI::Record/;

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        name varchar(5),
        signature varchar(100)
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        name varchar(5),
        signature varchar(100)
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        name varchar(5),
        signature varchar(100)
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
    column name      => type is 'varchar(5)';
    column signature => type is 'varchar(100)';
    }
}

1;
