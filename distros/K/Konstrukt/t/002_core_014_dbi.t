# check core module: dbi

#TODO: create tests! will need a dbi backend to test.
#      maybe use sqlite, db_file or DBD::Mock

use strict;
use warnings;

use Test::More tests => 1;

#=== Dependencies
use Konstrukt::Settings;
$Konstrukt::Handler->{filename} = "test";
use Konstrukt::Debug;
$Konstrukt::Debug->init();

#DBI
#use Konstrukt::DBI;

SKIP: {
    skip "TODO: DBI testing to be implemented...", 1;
	is(1, 1, "some_test");
}
