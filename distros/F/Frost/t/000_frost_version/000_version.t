#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Test::More tests => 1;
#use Test::More 'no_plan';

use Frost();

diag 'VERSIONS:';
diag 'Perl       ' . $];
diag 'Moose      ' . $Moose::VERSION;
diag 'Frost      ' . $Frost::VERSION;
#	diag 'DB_File    ' . $DB_File::VERSION;
#	diag "           Built   with Berkeley DB $DB_File::db_ver";
#	diag "           Running with Berkeley DB $DB_File::db_version";
diag 'BerkeleyDB ' . $BerkeleyDB::VERSION;
diag "           Running with Berkeley DB $BerkeleyDB::db_version";
diag 'Test::More ' . $Test::More::VERSION;

ok 1;
