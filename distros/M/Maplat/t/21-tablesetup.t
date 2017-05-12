#!perl

## Test bytea handling

use 5.006;
use strict;
use warnings;
use Test::More;
use DBI     ':sql_types';
use DBD::Pg ':pg_types';
use lib 't','.';
if ( not $ENV{TEST_PG} ) {
    my $msg = 'DBI/DBD::PG test.  Set $ENV{TEST_PG} to a true value to run.';
    plan( skip_all => $msg );
}

require 'dbdpg_test_setup.pl';
select(($|=1,select(STDERR),$|=1)[1]);

my $dbh = connect_database();

if (! defined $dbh) {
	plan skip_all => 'Connection to database failed, cannot continue testing';
}
plan tests => 39;
require("t/lib/create_tables.pm");

isnt ($dbh, undef, 'Connect to database for table setup');

my @stmts = CreateTables::getStmts();
warn "Please wait, creating maplat tables for testing\n";

foreach my $stmt (@stmts) {
    if($dbh->do($stmt)) {
        pass($stmt);
    } else {
        fail($stmt);
    }
} 
$dbh->commit;
$dbh->disconnect();
