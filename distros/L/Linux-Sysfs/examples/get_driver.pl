#!/usr/bin/perl

use strict;
use warnings;
use Linux::Sysfs;

if (scalar @ARGV != 2) {
    print_usage();
    exit 1;
}

my $path = Linux::Sysfs->get_mnt_path();
unless ($path) {
    print "Sysfs not mounted?\n";
    exit 1;
}

$path .= "/$Linux::Sysfs::BUS_NAME";
$path .= "/$ARGV[0]";
$path .= "/$Linux::Sysfs::DRIVERS_NAME";
$path .= "/$ARGV[1]";

my $driver = Linux::Sysfs::Driver->open_path($path);
unless ($driver) {
    print "Driver $ARGV[0] not found\n";
    exit 1;
}

my @devlist = $driver->get_devices;
if (scalar @devlist) {
    print "$ARGV[1] is used by:\n";
    for my $dev (@devlist) {
        printf "\t\t%s\n", $dev->bus_id;
    }
}
else {
    print "$ARGV[1] is presently not used by any device\n";
}

printf "driver %s is on bus %s\n",
       $driver->name, $driver->bus;

my $module = $driver->get_module;
if ($module) {
    printf "%s is using the module %s\n",
           $driver->name, $module->name;
}

$driver->close;

sub print_usage {
    print "Usage: $0 [bus] [driver]\n";
}
