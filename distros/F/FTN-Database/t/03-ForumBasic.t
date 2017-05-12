#!/usr/bin/perl -T
#
# Test basic operations of FTN::Database:Forum

use Test::More tests => 10;
use FTN::Database;
use FTN::Database::Forum;

use strict;
use warnings;

my ($db_handle, $fields);

BEGIN {

    my %db_options = (
        Type => 'SQLite',
        Name => ':memory:',
    );

    $db_handle = FTN::Database::open_ftn_database(\%db_options);
    ok( defined $db_handle, 'Open Forum DB' );

    $fields = FTN::Database::Forum::define_forum_table();
    ok( FTN::Database::create_ftn_table($db_handle, 'Forum', $fields), 'Create Forum Table' );

    $fields = FTN::Database::Forum::ftnmsg_index_fields();
    ok( FTN::Database::create_ftn_index($db_handle, 'Forum', 'ftnmsg', $fields), 'Create Forum Index' );

    $fields = FTN::Database::Forum::define_areasbbs_table();
    ok( FTN::Database::create_ftn_table($db_handle, 'areasbbs', $fields), 'Create areasbbs Table' );

    $fields = FTN::Database::Forum::ftnareas_index_fields();
    ok( FTN::Database::create_ftn_index($db_handle, 'areasbbs', 'ftnareas', $fields), 'Create areasbbs Index' );

    ok( FTN::Database::drop_ftn_index($db_handle, 'ftnmsg'), 'Drop Forum Index' );

    ok( FTN::Database::drop_ftn_table($db_handle, 'Forum'), 'Drop Forum Table' );

    ok( FTN::Database::drop_ftn_index($db_handle, 'ftnareas'), 'Drop areasbbs Index' );

    ok( FTN::Database::drop_ftn_table($db_handle, 'areasbbs'), 'Drop areasbbs Table' );

    ok( FTN::Database::close_ftn_database($db_handle), 'Close Forum DB' );
}

done_testing();

diag( "Basic FTN Message/Forum Database testing using FTN::Database::Forum $FTN::Database::Forum::VERSION." );

