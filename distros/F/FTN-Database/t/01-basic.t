#!/usr/bin/perl -T
#
# Test basic operations of FTN::Database

use Test::More tests => 6;
use FTN::Database;

use strict;
use warnings;

my ($db_handle, $fields);

BEGIN {

    my %db_options = (
        Type => 'SQLite',
        Name => ':memory:',
    );

    $db_handle = FTN::Database::open_ftn_database(\%db_options);
    ok( defined $db_handle, 'Open DB' );

    $fields = "nodeaka      VARCHAR(23) DEFAULT '' NOT NULL, ";
    $fields .= "sysop      VARCHAR(48) DEFAULT '' NOT NULL, ";
    $fields .= "system      VARCHAR(48) DEFAULT '' NOT NULL, ";
    $fields .= "location      VARCHAR(48) DEFAULT '' NOT NULL ";
    ok( FTN::Database::create_ftn_table($db_handle, 'Nodes', $fields), 'Create Table' );

    $fields = "nodeaka, sysop";
    ok( FTN::Database::create_ftn_index($db_handle, 'Nodes', 'nodeidx', $fields), 'Create Index' );

    ok( FTN::Database::drop_ftn_index($db_handle, 'nodeidx'), 'Drop Index' );

    ok( FTN::Database::drop_ftn_table($db_handle, 'Nodes'), 'Drop Table' );

    ok( FTN::Database::close_ftn_database($db_handle), 'Close DB' );
}

done_testing();

diag( "Basic FTN Database testing using FTN::Database $FTN::Database::VERSION." );

