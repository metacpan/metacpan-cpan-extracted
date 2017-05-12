#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 15;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }
        diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};
        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db');

        unless( has_schema( 'TestApp::User', $handle ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER - 1;
        }

        {my $ret = init_schema( 'TestApp::User', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        my $rec = TestApp::User->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        # name would be truncated
        my($id) = $rec->create( login => "obra", name => "Jesse Vincent" );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        is($rec->login, 'obra', "Login is not truncated" );
        is($rec->name, 'Jesse Vinc', "But name is truncated" );
        
        # UTF-8 string with flag set
        use Encode ();
        ($id) = $rec->create( login => "\x{442}\x{435}\x{441}\x{442}", name => "test" );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        is(Encode::decode_utf8($rec->login), "\x{442}\x{435}", "Login is truncated to two UTF-8 chars" );
        is($rec->name, 'test', "Name is not truncated" );

# this test fails on Pg because it doesn't like data that
# has bytes in unsupported encoding, we should use 'bytea'
# type for this test, but we don't have coverage for this
#       # scalar with cp1251 octets
#       $str = "\x{442}\x{435}\x{441}\x{442}\x{442}\x{435}\x{441}\x{442}";
#       $str = Encode::encode('cp1251', $str);
#       ($id) = $rec->create( login => $str, name => "test" );
#       ok($id, "Successfuly created ticket");
#       ok($rec->load($id), "Loaded the record");
#       is($rec->id, $id, "The record has its id");
#       is($rec->login, "\xf2\xe5\xf1\xf2\xf2", "Login is truncated to five octets" );
#       is($rec->name, 'test', "Name is not truncated" );

        # check that filter also work for set_* operations
        $rec->set_login( 'ruz' );
        $rec->set_name( 'Ruslan Zakirov' );
        is($rec->login, "ruz", "Login is not truncated" );
        is($rec->name, 'Ruslan Zak', "Name is truncated" );

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
        login char(5),
        name varchar(10),
        disabled int(4) default 0
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        login char(5),
        name varchar(10),
        disabled int(4) default 0
)
EOF

}

sub schema_mysql_4_1 {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        login binary(5),
        name varbinary(10),
        disabled int(4) default 0
)
EOF

}

# XXX: Pg adds trailing spaces to CHAR columns
# when other don't, must be fixed for consistency
sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        login varchar(5),
        name varchar(10),
        disabled integer default 0
)
EOF

}

1;

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    # special small lengths to test truncation
    column login =>
      type is 'varchar(5)',
      default is '';

    column name =>
      type is 'varchar(10)',
      max_length is 10,
      default is '';

    column disabled =>
      type is 'int(4)',
      max_length is 4,
      default is 0;
    }
}

1;
