#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Digest::MD5 qw( md5_hex );
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 10;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d (@available_drivers) {
SKIP: {
    unless (has_schema('TestApp::User', $d)) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }

    unless (should_test($d)) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};

    my $handle = get_handle($d);
    connect_handle($handle);
    isa_ok($handle->dbh, 'DBI::db');

    {
        my $ret = init_schema('TestApp::User', $handle);
        isa_ok($ret, 'DBI::st', 'init schema');
    }

   my $rec = TestApp::User->new( handle => $handle );
   isa_ok($rec, 'Jifty::DBI::Record');

   my ($id) = $rec->create( password => 'very-very-secret' );
   ok($id, 'created record');
   ok($rec->load($id), 'loaded record');
   is($rec->id, $id, 'record id matches');
   is(ref $rec->password, 'ARRAY', 'password is an ARRAY');
   is(scalar @{ $rec->password }, 2, 'password array has 2 elements');
   my ($hash, $salt) = @{ $rec->password };
   is($hash, md5_hex('very-very-secret', $salt), 'password matches encoding');

   # undef/NULL
   $rec->set_password;
   is($rec->password, undef, 'set undef value');

   cleanup_schema('TestApp', $handle);
   disconnect_handle($handle);
}
}

package TestApp::User;
use base qw/ Jifty::DBI::Record /;

1;

sub schema_sqlite {

<<EOF;
CREATE table users (
    id integer primary key,
    password text
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
    id integer auto_increment primary key,
    password text
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
    id serial primary key,
    password text
)
EOF

}

BEGIN {
    use Jifty::DBI::Schema;

    use Jifty::DBI::Record schema {
    column password =>
        type is 'text',
        filters are qw/ Jifty::DBI::Filter::SaltHash /;
    }
}

