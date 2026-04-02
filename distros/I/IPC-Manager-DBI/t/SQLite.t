use Test2::V1 -ipP;
use Test2::IPC;

use Test2::Require::Module 'DBI';
use Test2::Require::Module 'DBD::SQLite';

use Test2::Tools::QuickDB;
skipall_unless_can_db(driver => 'SQLite');

{
    no warnings 'once';
    $main::PROTOCOL = 'SQLite';
}

subtest general => sub {
    do './t/generic_test.pl' or die $@;
};

subtest service => sub {
    do './t/service_test.pl' or die $@;
};

done_testing;
