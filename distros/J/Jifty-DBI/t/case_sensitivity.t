#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 139;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

use DateTime ();

foreach my $d (@available_drivers) {
SKIP: {
    unless ( has_schema( 'TestApp::User', $d ) ) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless ( should_test($d) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }
    diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};

    my $handle = get_handle($d);
    connect_handle($handle);
    isa_ok( $handle->dbh, 'DBI::db' );

    {
        my $ret = init_schema( 'TestApp::User', $handle );
        isa_ok( $ret, 'DBI::st',
            "Inserted the schema. got a statement handle back" );
    }

    my $rec = TestApp::User->new( handle => $handle );
    isa_ok( $rec, 'Jifty::DBI::Record' );

    my ($id) = $rec->create( name => 'Foobar', interests => 'Slacking' );
    ok( $id, "Successfuly created ticket" );

    $rec->load_by_cols( name => 'foobar' );
TODO: {
        local $TODO = "How do we force mysql to be case sensitive?"
            if ( $d eq 'mysql' || $d eq 'mysqlPP' );
        is( $rec->id, undef );
    }

    $rec->load_by_cols( name =>
            { value => 'foobar', case_sensitive => 0, operator => '=' } );
    is( $rec->id, $id );

    $rec->load_by_cols( name => 'Foobar' );
    is( $rec->id, $id );

    $rec->load_by_cols( interests => 'slacking' );
    is( $rec->id, $id );

    $rec->load_by_cols( interests => 'Slacking' );
    is( $rec->id, $id );

# IN
# IS
# IS NOT

    ### Numbers
    threeway_same($handle, id => $_, 42) for qw/= != < > <= >=/;
    threeway_same($handle, id => $_, 42) for ("LIKE", "NOT LIKE", "MATCHES", "STARTS_WITH", "ENDS_WITH");
    threeway_same($handle, id => $_ => [ 42, 17 ]) for qw/= IN/;
    threeway_same($handle, id => $_ => 'NULL') for ("IS", "IS NOT");
    threeway_same($handle, id => $_ => 'null') for ("IS", "IS NOT");

    ## Strings
    threeway_same($handle, name => $_, "bob") for qw/< > <= >=/;
    threeway_same($handle, name => $_, 17)  for ("=", "!=", "LIKE", "NOT LIKE");
    threeway_different($handle, name => $_, 17) for ("MATCHES", "STARTS_WITH", "ENDS_WITH");
    threeway_different($handle, name => $_, "bob")  for ("=", "!=", "LIKE", "NOT LIKE", "MATCHES", "STARTS_WITH", "ENDS_WITH");
    threeway_different($handle, name => $_, "null") for ("=", "!=", "LIKE", "NOT LIKE", "MATCHES", "STARTS_WITH", "ENDS_WITH");
    threeway_different($handle, name => $_ => [ "bob", "alice" ]) for qw/= IN/;
    threeway_same($handle, name => $_ => 'NULL') for ("IS", "IS NOT");
    threeway_same($handle, name => $_ => 'null') for ("IS", "IS NOT");

    ## Other
    threeway_same($handle, created => $_, 42) for qw/= != < > <= >=/;
    threeway_same($handle, created => $_, 42) for ("LIKE", "NOT LIKE", "MATCHES", "STARTS_WITH", "ENDS_WITH");
    threeway_same($handle, created => $_ => [ 42, 17 ]) for qw/= IN/;
    threeway_same($handle, created => $_ => 'NULL') for ("IS", "IS NOT");
    threeway_same($handle, created => $_ => 'null') for ("IS", "IS NOT");

    cleanup_schema( 'TestApp', $handle );
    disconnect_handle($handle);
}
}

sub threeway_same {
    my ($default, $insensitive, $sensitive) = threeway_test(@_);
    shift @_;
    is( $default, $insensitive, "Default and insensitive queries are the same (@_)");
    is( $sensitive, $insensitive, "Sensitive and insensitive queries are the same (@_)");
}

sub threeway_different {
    my ($default, $insensitive, $sensitive) = threeway_test(@_);
    my $handle = shift @_;
    is( $default, $sensitive, "Default and insensitive queries are the same (@_)");
TODO: {
        local $TODO = "How do we force mysql to be case sensitive?"
            if $handle =~ /mysql/;
        isnt( $sensitive, $insensitive, "Sensitive and insensitive queries are not the same (@_)");
    }
}

sub threeway_test {
    my ($handle, $column, $op, $value) = @_;
    my $default = TestApp::UserCollection->new( handle => $handle );
    $default->limit( column => $column, value => $value, operator => $op );

    my $insensitive = TestApp::UserCollection->new( handle => $handle );
    $insensitive->limit( column => $column, value => $value, operator => $op, case_sensitive => 0 );

    my $sensitive = TestApp::UserCollection->new( handle => $handle );
    $sensitive->limit( column => $column, value => $value, operator => $op, case_sensitive => 1 );

    return map {$_->build_select_query} ($default, $insensitive, $sensitive);
}

package TestApp::User;
use base qw/Jifty::DBI::Record/;

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        name varchar,
        interests varchar,
        created date
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        name varchar(255),
        interests varchar(255),
        created date
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        name varchar,
        interests varchar,
        created date
)
EOF

}

use Jifty::DBI::Schema;

use Jifty::DBI::Record schema {
    column name      => type is 'varchar', label is 'Name', is case_sensitive;
    column interests => type is 'varchar';
    column created   => type is 'date';
};

package TestApp::UserCollection;
use base qw/Jifty::DBI::Collection/;

1;

