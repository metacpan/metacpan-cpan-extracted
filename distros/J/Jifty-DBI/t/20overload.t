#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 109;

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

        {my $ret = init_schema( 'TestApp', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        my $count_all = init_data( 'TestApp::User', $handle );
        ok( $count_all,  "init users data" );

        my $users_obj = TestApp::UserCollection->new( handle => $handle );
        isa_ok( $users_obj, 'Jifty::DBI::Collection' );
        is( $users_obj->_handle, $handle, "same handle as we used in constructor");

# check that new object returns 0 records in any case
        is( $users_obj->_record_count, 0, '_record_count returns 0 on not limited obj' );
        is( $users_obj->count, 0, 'count returns 0 on not limited obj' );
        is( $users_obj->is_last, undef, 'is_last returns undef on not limited obj after count' );
        is( $users_obj->first, undef, 'first returns undef on not limited obj' );
        is( $users_obj->is_last, undef, 'is_last returns undef on not limited obj after first' );
        is( $users_obj->last, undef, 'last returns undef on not limited obj' );
        is( $users_obj->is_last, undef, 'is_last returns undef on not limited obj after last' );
        $users_obj->goto_first_item;
        is( $users_obj->peek, undef, 'peek returns undef on not limited obj' );
        is( <$users_obj>, undef, 'next returns undef on not limited obj' );
        is( $users_obj->is_last, undef, 'is_last returns undef on not limited obj after next' );
        # XXX TODO FIXME: may be this methods should be implemented
        # $users_obj->goto_last_item;
        # is( $users_obj->prev, undef, 'prev returns undef on not limited obj' );
        my $items_ref = \@$users_obj;
        isa_ok( $items_ref, 'ARRAY', 'items_array_ref always returns array reference' );
        is_deeply( $items_ref, [], 'items_array_ref returns [] on not limited obj' );

# unlimit new object and check
        $users_obj->unlimit;
        is( $users_obj->count, $count_all, 'count returns same number of records as was inserted' );
        isa_ok( $users_obj->first, 'Jifty::DBI::Record', 'first returns record object' );
        isa_ok( $users_obj->last, 'Jifty::DBI::Record', 'last returns record object' );
        $users_obj->goto_first_item;
        isa_ok( $users_obj->peek, 'Jifty::DBI::Record', 'peek returns record object' );
        isa_ok( <$users_obj>, 'Jifty::DBI::Record', 'next returns record object' );
        $items_ref = \@$users_obj;
        isa_ok( $items_ref, 'ARRAY', 'items_array_ref always returns array reference' );
        is( scalar @{$items_ref}, $count_all, 'items_array_ref returns same number of records as was inserted' );
        $users_obj->redo_search;
        $items_ref = \@$users_obj;
        isa_ok( $items_ref, 'ARRAY', 'items_array_ref always returns array reference' );
        is( scalar @{$items_ref}, $count_all, 'items_array_ref returns same number of records as was inserted' );

# try to use $users_obj for all tests, after each call to clean_slate it should look like new obj.
# and test $obj->new syntax
        my $clean_obj = $users_obj->new( handle => $handle );
        isa_ok( $clean_obj, 'Jifty::DBI::Collection' );

# basic limits
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'login', value => 'obra' );
        is( $users_obj->count, 1, 'found one user with login obra' );
        TODO: {
                local $TODO = 'require discussion';
                is( $users_obj->is_last, undef, 'is_last returns undef before we fetch any record' );
        }
        my $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $users_obj->is_last, 1, '1 record in the collection then first rec is last');
        is( $first_rec->login, 'obra', 'login is correct' );
        my $last_rec = $users_obj->last;
        is( $last_rec, $first_rec, 'last returns same object as first' );
        is( $users_obj->is_last, 1, 'is_last always returns 1 after last call');
        $users_obj->goto_first_item;
        my $peek_rec = $users_obj->peek;
        my $next_rec = <$users_obj>;
        is( $next_rec, $peek_rec, 'peek returns same object as next' );
        is( $next_rec, $first_rec, 'next returns same object as first' );
        is( $users_obj->is_last, 1, 'is_last returns 1 after fetch first record with next method');
        is( $users_obj->peek, undef, 'only one record in the collection' );
        is( <$users_obj>, undef, 'only one record in the collection' );
        TODO: {
                local $TODO = 'require discussion';
                is( $users_obj->is_last, undef, 'next returns undef, is_last returns undef too');
        }
        $items_ref = \@$users_obj;
        isa_ok( $items_ref, 'ARRAY', 'items_array_ref always returns array reference' );
        is( scalar @{$items_ref}, 1, 'items_array_ref has only 1 record' );

# similar basic limit, but with different operators and less first/next/last tests
        # LIKE
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', operator => 'MATCHES', value => 'Glass' );
        is( $users_obj->count, 1, "found one user with 'Glass' in the name" );
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'glasser', 'login is correct' );

        # LIKE with wildcard
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', operator => 'MATCHES', value => 'G_ass' );
        is( $users_obj->count, 1, "found one user with 'Glass' in the name" );
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'glasser', 'login is correct' );

        # LIKE with escaped wildcard
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        # XXX: don't use backslashes; Pg (only Pg?) requires special
        # treatment like "LIKE E'%g\\_ass%'" for that case, 
        # which is not supported yet (but this should be fixed)
        $users_obj->limit( column => 'name', operator => 'MATCHES', value => 'G@_ass', escape => '@' );
        is( $users_obj->count, 0, "should not find users with 'Glass' in the name" );

        # LIKE with wildcard
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', operator => 'MATCHES', value => 'Glass%' );
        is( $users_obj->count, 1, "found one user with 'Glass' in the name" );
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'glasser', 'login is correct' );

        # MATCHES with escaped wildcard
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        # XXX: don't use backslashes; reason above
        $users_obj->limit( column => 'name', operator => 'MATCHES', value => 'Glass@%', escape => '@' );
        is( $users_obj->count, 0, "should not find users with 'Glass' in the name" );

        # STARTSWITH
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', operator => 'STARTSWITH', value => 'Ruslan' );
        is( $users_obj->count, 1, "found one user who name starts with 'Ruslan'" );
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'cubic', 'login is correct' );

        # ENDSWITH
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', operator => 'ENDSWITH', value => 'Tang' );
        is( $users_obj->count, 1, "found one user who name ends with 'Tang'" );
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'audreyt', 'login is correct' );

        # IN
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'login', operator => 'IN', 
                           value => ['cubic', 'obra', 'glasser', 'audreyt'] );
        is( $users_obj->count, 4, "found 4 user ids" );
        my %logins = (cubic => 1, obra => 1, glasser => 1, audreyt => 1);
        while ( my $user = <$users_obj> ) {
          is ( defined $logins{$user->login}, 1, 'Found login' );
          delete $logins{$user->login};
        }
        is ( scalar( keys( %logins ) ), 0, 'All logins found' );

        # IS NULL
        # XXX TODO FIXME: column => undef should be handled as NULL
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'phone', operator => 'IS', value => 'NULL' );
        is( $users_obj->count, 2, "found 2 users who has unknown phone number" );
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'address', operator => 'IS', value => 'NULL' );
        is( $users_obj->count, 0, "found 0 users who has unknown address" );
        
        # IS NOT NULL
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'phone', operator => 'IS NOT', value => 'NULL', quotevalue => 0 );
        is( $users_obj->count, $count_all - 2, "found users who have phone number filled" );
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'address', operator => 'IS NOT', value => 'NULL', quotevalue => 0 );
        is( $users_obj->count, $count_all, "found users who have address filled" );
       
        # CASE SENSITIVITY, default is limits are not case sensitive
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => 'Jesse Vincent' );
        is( $users_obj->count, 1, "case insensitive, matching case, should find one row");
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => 'jesse vincent' );
        is( $users_obj->count, 1, "case insensitive, non-matched case, should find one row");
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => ['Jesse Vincent', 'Audrey Tang'], operator => 'IN');
        is( $users_obj->count, 2, "case insensitive, matching case, should find two rows");
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => ['jesse vincent', 'audrey tang'], operator => 'IN');
        is( $users_obj->count, 2, "case insensitive, non-matched case, should find two rows");

        # CASE SENSITIVITY, testing with case_sensitive => 1
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => 'Jesse Vincent', case_sensitive => 1 );
        is( $users_obj->count, 1, "case sensitive search, should find one row");
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => 'jesse vincent', case_sensitive => 1 );
        TODO: {
            local $TODO = "MySQL still needs case sensitive fixes" if ( $d eq 'mysql' || $d eq 'mysqlPP' );
            is( $users_obj->count, 0, "case sensitive search, should find zero rows");
        }
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => ['Jesse Vincent', 'Audrey Tang'], operator => 'IN',
                           case_sensitive => 1 );
        is( $users_obj->count, 2, "case sensitive search, should find two rows");
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'name', value => ['jesse vincent', 'audrey tang'], operator => 'IN', 
                           case_sensitive => 1 );
        TODO: {
            local $TODO = "MySQL still needs case sensitive fixes" if ( $d eq 'mysql' || $d eq 'mysqlPP' );
            is( $users_obj->count, 0, "case sensitive search, should find zero rows");
        }

        # ORDER BY / GROUP BY
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->unlimit;
        $users_obj->group_by(column => 'login');
        $users_obj->order_by(column => 'login', order => 'desc');
        $users_obj->column(column => 'login');
        is( $users_obj->count, $count_all, "group by / order by finds right amount");
        $first_rec = $users_obj->first;
        isa_ok( $first_rec, 'Jifty::DBI::Record', 'First returns record object' );
        is( $first_rec->login, 'obra', 'login is correct' );

        $users_obj->clean_slate;
        TODO: {
            local $TODO = 'we leave order_by after clean slate, fixing this results in many RT failures';
            is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
            $users_obj = TestApp::UserCollection->new( handle => $handle );
        }
 
# Let's play a little with 'entry_aggregator'
        # EA defaults to OR for the same field
        $users_obj->limit( column => 'phone', operator => 'IS', value => 'NULL', quote_value => 0 );
        $users_obj->limit( column => 'phone', operator => 'LIKE', value => '%X%' );
        is( $users_obj->count, 4, "found users who has no phone or it has X char" );

        # set AND for the same field
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'Login', operator => 'NOT LIKE', value => '%c%' );
        $users_obj->limit(
            entry_aggregator => 'AND', column => 'Login', operator => 'LIKE', value => '%u%'
        );
        is( $users_obj->count, 1, "found users who has no phone or it has X char" );

        # default is AND for different fields
        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object');
        $users_obj->limit( column => 'phone', operator => 'IS', value => 'NULL', quote_value => 0 );
        $users_obj->limit( column => 'login', operator => 'LIKE', value => '%r%' );
        is( $users_obj->count, 2, "found users who has no phone number or login has 'r' char" );

        $users_obj->clean_slate;
        is_deeply( $users_obj, $clean_obj, 'after clean_slate looks like new object'); 

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle( $handle );
}} # SKIP, foreach blocks

1;

package TestApp;

sub schema_mysql {
<<EOF;
CREATE TEMPORARY table users (
        id integer AUTO_INCREMENT,
        login varchar(18) NOT NULL,
        name varchar(36),
        phone varchar(18),
        address varchar(18),
        PRIMARY KEY (id))
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY table users (
        id serial PRIMARY KEY,
        login varchar(18) NOT NULL,
        name varchar(36),
        phone varchar(18),
        address varchar(18)
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        login varchar(18) NOT NULL,
        name varchar(36),
        phone varchar(18),
        address varchar(18))
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE users (
        id integer CONSTRAINT users_key PRIMARY KEY,
        Login varchar(18) NOT NULL,
        name varchar(36),
        phone varchar(18)
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE users_seq",
    "DROP TABLE users", 
] }


1;

package TestApp::User;

use base qw/Jifty::DBI::Record/;

sub _init {
    my $self = shift;
    $self->table('users');
    $self->SUPER::_init(@_);
}

sub init_data {
    return (
        [ 'login',      'name',                 'phone',            'address' ],
        [ 'cubic',      'Ruslan U. Zakirov',    '+7-903-264-XX-XX', undef ],
        [ 'obra',       'Jesse Vincent',        undef,              undef ],
        [ 'glasser',    'David Glasser',        undef,              'somewhere' ],
        [ 'audreyt',    'Audrey Tang',          '+X-XXX-XXX-XX-XX', 'someplace' ],
    );
}

1;

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
    column login   => type is 'varchar(18)';
    column name    => type is 'varchar(36)';
    column phone   => type is 'varchar(18)', default is undef;
    column address => type is 'varchar(18)', default is '';
    }
}

1;

package TestApp::UserCollection;

# use TestApp::User;
use base qw/Jifty::DBI::Collection/;

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->table('users');
}

1;

