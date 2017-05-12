#!/usr/bin/perl -T
#
# Test basic operations of FTN::Database

use Test::More tests => 6;
use FTN::Database;
use FTN::Database::Nodelist;

use strict;
use warnings;

my ($db_handle, $fields);

BEGIN {

    my %db_options = (
        Type => 'SQLite',
        Name => ':memory:',
    );

    $db_handle = FTN::Database::open_ftn_database(\%db_options);
    ok( defined $db_handle, 'Open Nodelist DB' );

    $fields = FTN::Database::Nodelist::define_nodelist_table();
    ok( FTN::Database::create_ftn_table($db_handle, 'Nodelist', $fields), 'Create Nodelist Table' );

    $fields = FTN::Database::Nodelist::ftnnode_index_fields();
    ok( FTN::Database::create_ftn_index($db_handle, 'Nodelist', 'ftnnode', $fields), 'Create Nodelist Index' );

    ok( FTN::Database::drop_ftn_index($db_handle, 'ftnnode'), 'Drop Nodelist Index' );

    ok( FTN::Database::drop_ftn_table($db_handle, 'Nodelist'), 'Drop Nodelist Table' );

    ok( FTN::Database::close_ftn_database($db_handle), 'Close Nodelist DB' );
}

done_testing();

diag( "Basic FTN Nodelist Database testing using FTN::Database::Nodelist $FTN::Database::Nodelist::VERSION." );

