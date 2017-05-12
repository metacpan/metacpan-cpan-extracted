#!perl

use Test::More tests => 6;

BEGIN { require "t/test_init.pl" }

use JDBC qw(:ResultSet);

JDBC->load_driver($::JDBC_DRIVER_CLASS);
pass "driver class loaded";

ok $java::sql::ResultSet::TYPE_FORWARD_ONLY;
ok $java::sql::ResultSet::CONCUR_READ_ONLY;

isnt $java::sql::ResultSet::TYPE_FORWARD_ONLY,
     $java::sql::ResultSet::CONCUR_READ_ONLY;

is TYPE_FORWARD_ONLY, $java::sql::ResultSet::TYPE_FORWARD_ONLY;
is CONCUR_READ_ONLY,  $java::sql::ResultSet::CONCUR_READ_ONLY;
