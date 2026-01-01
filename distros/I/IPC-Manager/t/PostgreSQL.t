use strict;
use warnings;

use Test2::Require::Module 'DBI';
use Test2::Require::Module 'DBD::Pg';
use Test2::Require::Module 'DBIx::QuickDB';

use Test2::Tools::QuickDB;
skipall_unless_can_db(driver => 'PostgreSQL');

{
    no warnings 'once';
    $main::PROTOCOL = 'PostgreSQL';
}

do './t/generic_test.pl' or die $@;
