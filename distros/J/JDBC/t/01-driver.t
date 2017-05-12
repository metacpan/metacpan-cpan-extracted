#!perl

use Test::More tests => 4;

BEGIN { require "t/test_init.pl" }

use JDBC;

print "CLASSPATH=$ENV{CLASSPATH}\n";
JDBC->load_driver($::JDBC_DRIVER_CLASS);
pass("driver class loaded");

my $timeout = JDBC->getLoginTimeout;
ok defined $timeout, "getLoginTimeout";

my $drivers_enumeration = JDBC->getDrivers;
can_ok $drivers_enumeration, 'hasMoreElements';

my @drivers;
while ($drivers_enumeration->hasMoreElements) {
    my $driver = $drivers_enumeration->nextElement;
    print "Driver: $driver\n";
    push @drivers, $driver;
}
ok @drivers >= 1, "can iterate over drivers";

