#!/usr/bin/env perl -w

use strict;
use warnings;

use File::Spec;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 47;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
    unless( has_schema( 'TestApp', $d ) ) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless( should_test( $d ) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    my $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    my $ret = init_schema( 'TestApp', $handle );
    isa_ok($ret, 'DBI::st', "Inserted the schema. got a statement handle back");

    my $count_users = init_data( 'TestApp::User', $handle );
    ok( $count_users,  "init users data" );
    my $count_groups = init_data( 'TestApp::Group', $handle );
    ok( $count_groups,  "init groups data" );
    my $count_us2gs = init_data( 'TestApp::UserToGroup', $handle );
    ok( $count_us2gs,  "init users&groups relations data" );

    my $clean_obj = TestApp::UserCollection->new( handle => $handle );
    my $users_obj = $clean_obj->clone;
    is_deeply( $users_obj, $clean_obj, 'after Clone looks the same');

diag "inner JOIN with ->join method" if $ENV{'TEST_VERBOSE'};
{
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->join(
        column1 => 'id',
        table2 => 'user_to_groups',
        column2 => 'user_id'
    );
    ok( $alias, "Join returns alias" );
    TODO: {
        local $TODO = "is joined doesn't mean is limited, count returns 0";
        is( $users_obj->count, 3, "three users are members of the groups" );
    }
    # fake limit to check if join actually joins
    $users_obj->limit( column => 'id', operator => 'IS NOT', value => 'NULL' );
    is( $users_obj->count, 3, "three users are members of the groups" );
}

diag "LEFT JOIN with ->join method" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->join(
        type   => 'LEFT',
        column1 => 'id',
        table2 => 'user_to_groups',
        column2 => 'user_id'
    );
    ok( $alias, "Join returns alias" );
    $users_obj->limit( alias => $alias, column => 'id', operator => 'IS', value => 'NULL' );
    ok( $users_obj->build_select_query =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->count, 1, "user is not member of any group" );
    is( $users_obj->first->id, 3, "correct user id" );
}

diag "LEFT JOIN with IS NOT NULL on the right side" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->join(
        type   => 'LEFT',
        column1 => 'id',
        table2 => 'user_to_groups',
        column2 => 'user_id'
    );
    ok( $alias, "Join returns alias" );
    $users_obj->limit( alias => $alias, column => 'id', operator => 'IS NOT', value => 'NULL' );
    if ( $d eq 'mysql' && $handle->database_version =~ /^[34]/ ) {
        ok( $users_obj->build_select_query !~ /LEFT JOIN/, 'LJ is optimized away');
    } else {
        ok( 1, 'mysql >= 5.0 dont need this optimization' );
    }
    is( $users_obj->count, 3, "users whos is memebers of at least one group" );
}

diag "LEFT JOIN with ->join method and using alias" if $ENV{'TEST_VERBOSE'};
{
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->new_alias( 'user_to_groups' );
    ok( $alias, "new alias" );
    is($users_obj->join(
            type   => 'LEFT',
            column1 => 'id',
            alias2 => $alias,
            column2 => 'user_id' ),
        $alias, "joined table"
    );
    $users_obj->limit( alias => $alias, column => 'id', operator => 'IS', value => 'NULL' );
    ok( $users_obj->build_select_query =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->count, 1, "user is not member of any group" );
}

diag "main <- alias <- join" if $ENV{'TEST_VERBOSE'};
{
    # The join depends on the alias, we should build joins with correct order.
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->new_alias( 'user_to_groups' );
    ok( $alias, "new alias" );
    ok( $users_obj->_is_joined, "object with aliases is joined");
    $users_obj->limit( column => 'id', value => "$alias.user_id", quote_value => 0);
    ok( my $groups_alias = $users_obj->join(
            alias1 => $alias,
            column1 => 'group_id',
            table2 => 'groups',
            column2 => 'id',
        ),
        "joined table"
    );
    $users_obj->limit( alias => $groups_alias, column => 'name', value => 'Developers' );
    #diag $users_obj->build_select_query;
    is( $users_obj->count, 3, "three members" );
}

diag "main <- alias <- join into main" if $ENV{'TEST_VERBOSE'};
{
    # DBs' parsers don't like: FROM X, Y JOIN C ON C.f = X.f
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");

    ok( my $groups_alias = $users_obj->new_alias( 'groups' ), "new alias" );
    ok( my $g2u_alias = $users_obj->join(
            alias1 => 'main',
            column1 => 'id',
            table2 => 'user_to_groups',
            column2 => 'user_id',
        ),
        "joined table"
    );
    $users_obj->limit( alias => $g2u_alias, column => 'group_id', value => "$groups_alias.id", quote_value => 0);
    $users_obj->limit( alias => $groups_alias, column => 'name', value => 'Developers' );
    #diag $users_obj->build_select_query;
    is( $users_obj->count, 3, "three members" );
}

diag "cascaded LEFT JOIN optimization" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->join(
        type   => 'LEFT',
        column1 => 'id',
        table2 => 'user_to_groups',
        column2 => 'user_id'
    );
    ok( $alias, "Join returns alias" );
    $alias = $users_obj->join(
        type   => 'LEFT',
        alias1 => $alias,
        column1 => 'group_id',
        table2 => 'groups',
        column2 => 'id'
    );
    $users_obj->limit( alias => $alias, column => 'id', operator => 'IS NOT', value => 'NULL' );
    if ( $d eq 'mysql' && $handle->database_version =~ /^[34]/ ) {
        ok( $users_obj->build_select_query !~ /LEFT JOIN/, 'both LJs are optimized away');
    } else {
        ok( 1, 'mysql >= 5.0 dont need this optimization' );
    }
    is( $users_obj->count, 3, "users whos is memebers of at least one group" );
}

diag "LEFT JOIN optimization and OR clause" if $ENV{'TEST_VERBOSE'}; 
{
    $users_obj->clean_slate;
    is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
    ok( !$users_obj->_is_joined, "new object isn't joined");
    my $alias = $users_obj->join(
        type   => 'LEFT',
        column1 => 'id',
        table2 => 'user_to_groups',
        column2 => 'user_id'
    );
    $users_obj->open_paren('my_clause');
    $users_obj->limit(
        subclause => 'my_clause',
        alias => $alias,
        column => 'id',
        operator => 'IS NOT',
        value => 'NULL'
    );
    $users_obj->limit(
        subclause => 'my_clause',
        entry_aggregator => 'OR',
        column => 'id',
        value => 3
    );
    $users_obj->close_paren('my_clause');
    ok( $users_obj->build_select_query =~ /LEFT JOIN/, 'LJ is not optimized away');
    is( $users_obj->count, 4, "all users" );
}

    cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks

1;


package TestApp;
sub schema_sqlite {
[
q{
CREATE table users (
    id integer primary key,
    login varchar(36)
) },
q{
CREATE table user_to_groups (
    id integer primary key,
    user_id  integer,
    group_id integer
) },
q{
CREATE table groups (
    id integer primary key,
    name varchar(36)
) },
]
}

sub schema_mysql {
[
q{
CREATE TEMPORARY table users (
    id integer primary key AUTO_INCREMENT,
    login varchar(36)
) },
q{
CREATE TEMPORARY table user_to_groups (
    id integer primary key AUTO_INCREMENT,
    user_id  integer,
    group_id integer
) },
q{
CREATE TEMPORARY table groups (
    id integer primary key AUTO_INCREMENT,
    name varchar(36)
) },
]
}

sub schema_pg {
[
q{
CREATE TEMPORARY table users (
    id serial primary key,
    login varchar(36)
) },
q{
CREATE TEMPORARY table user_to_groups (
    id serial primary key,
    user_id integer,
    group_id integer
) },
q{
CREATE TEMPORARY table groups (
    id serial primary key,
    name varchar(36)
) },
]
}

sub schema_oracle { [
    "CREATE SEQUENCE users_seq",
    "CREATE table users (
        id integer CONSTRAINT users_Key PRIMARY KEY,
        login varchar(36)
    )",
    "CREATE SEQUENCE user_to_groups_seq",
    "CREATE table user_to_groups (
        id integer CONSTRAINT user_to_groups_Key PRIMARY KEY,
        user_id integer,
        group_id integer
    )",
    "CREATE SEQUENCE groups_seq",
    "CREATE table groups (
        id integer CONSTRAINT groups_Key PRIMARY KEY,
        name varchar(36)
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE users_seq",
    "DROP table users", 
    "DROP SEQUENCE groups_seq",
    "DROP table groups", 
    "DROP SEQUENCE user_to_groups_seq",
    "DROP table user_to_groups", 
] }

package TestApp::User;

use base qw/Jifty::DBI::Record/;

BEGIN {
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column login   => type is 'varchar(36)';
};
}

sub _init {
    my $self = shift;
    $self->table('users');
    $self->SUPER::_init( @_ );
}

sub init_data {
    return (
    [ 'login' ],

    [ 'ivan' ],
    [ 'john' ],
    [ 'bob' ],
    [ 'aurelia' ],
    );
}

package TestApp::UserCollection;

use base qw/Jifty::DBI::Collection/;

sub _init {
    my $self = shift;
    $self->table('users');
    return $self->SUPER::_init( @_ );
}

1;

package TestApp::Group;

use base qw/Jifty::DBI::Record/;

BEGIN {
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column name => type is 'varchar(36)';
};
}

sub _init {
    my $self = shift;
    $self->table('groups');
    return $self->SUPER::_init( @_ );
}

sub init_data {
    return (
    [ 'name' ],

    [ 'Developers' ],
    [ 'Sales' ],
    [ 'Support' ],
    );
}

package TestApp::GroupCollection;

use base qw/Jifty::DBI::Collection/;

sub _init {
    my $self = shift;
    $self->table('groups');
    return $self->SUPER::_init( @_ );
}

1;

package TestApp::UserToGroup;

use base qw/Jifty::DBI::Record/;

BEGIN {
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column user_id => type is 'int(11)';
    column group_id => type is 'int(11)';
};
}

sub init_data {
    return (
    [ 'group_id',    'user_id' ],
# dev group
    [ 1,        1 ],
    [ 1,        2 ],
    [ 1,        4 ],
# sales
#    [ 2,        0 ],
# support
    [ 3,        1 ],
    );
}

package TestApp::UserToGroupCollection;
use base qw/Jifty::DBI::Collection/;

1;
