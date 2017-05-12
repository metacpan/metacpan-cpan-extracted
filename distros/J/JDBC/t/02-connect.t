#!perl

use Test::More tests => 3;

BEGIN { require "t/test_init.pl" }

use JDBC;

JDBC->load_driver($::JDBC_DRIVER_CLASS);
pass "driver class loaded";

my $con = JDBC->getConnection($::JDBC_DRIVER_URL, "test", "test");
ok ref $con, "got ref";
can_ok $con, 'createStatement';

