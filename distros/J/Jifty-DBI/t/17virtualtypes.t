#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 9;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

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

        my ($id) = $rec->create( location_x => 10, location_y => 20 );
        ok($id, "Successfuly created ticket");
        ok($rec->load($id), "Loaded the record");
        is($rec->id, $id, "The record has its id");
        is($rec->location_x, 10);
        is($rec->location_y, 20);
        is_deeply($rec->location, { x => 10, y => 20});
        disconnect_handle($handle);
    }
}

package TestApp::User;
use base qw/Jifty::DBI::Record/;

1;

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        location_x double,
        location_y double
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        location_x double,
        location_y double
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        location_x double precision,
        location_y double precision
)
EOF

}


sub geolocation {
    my ($column, $from) = @_;
    my $name = $column->name;
    $column->virtual(1);
    for (qw(x y)) {
        Jifty::DBI::Schema::_init_column_for(
            Jifty::DBI::Column->new({ type => 'double',
                                      name => $name."_$_",
                                      writable => $column->writable,
                                      readable => $column->readable }),
            $from);
    }
    no strict 'refs';
    *{$from.'::'.$name} = sub { return { map { my $method = "${name}_$_"; $_ => $_[0]->$method } qw(x y) } };
    *{$from.'::'.'set_'.$name} = sub { die "not yet" };
}

BEGIN {

use Jifty::DBI::Schema;
Jifty::DBI::Schema->register_types(
    GeoLocation =>
        sub { _init_handler is \&geolocation },
);
}


use Jifty::DBI::Record schema {
    column location    => is GeoLocation;
};


1;

