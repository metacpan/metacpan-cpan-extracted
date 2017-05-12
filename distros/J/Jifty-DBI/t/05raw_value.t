#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

eval "use URI";
plan skip_all => "URI required for testing the URI filter" if $@;

use constant TESTS_PER_DRIVER => 14;

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

        require URI;
        my $uri = URI->new( 'http://bestpractical.com/foo' );
        my ($id) = $rec->create(uri => $uri);
        ok($id, "Successfuly created a user");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");

        isa_ok( $rec->uri, 'URI' );
        is($rec->uri->as_string, $uri, "Corrent uri");
        is($rec->__raw_value( 'uri' ), $uri->as_string, 'Correct raw uri' );

        # undef/NULL
        $rec->set_uri;
        is($rec->uri, undef, "Set undef value" );
        is($rec->__raw_value( 'uri' ), undef, 'Correct raw uri' );

        my $new_uri = 'http://jifty.org/bar';
        $rec->set_uri( $new_uri );
        isa_ok( $rec->uri, 'URI' );
        is($rec->uri->as_string, $new_uri, "The record has its id");
        is($rec->__raw_value( 'uri' ), $new_uri, 'Correct raw value' );

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
        uri varchar(64)
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        uri varchar(64)
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        uri varchar(64)
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column uri =>
      type is 'text',
      filters are qw/Jifty::DBI::Filter::URI/,
      default is undef;
    }
}

1;

