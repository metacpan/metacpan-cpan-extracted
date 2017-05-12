#!/usr/bin/perl

use strict;
use warnings;
use Linux::Sysfs;

if (scalar @ARGV != 2) {
    print_usage();
    exit 1;
}

my $device = Linux::Sysfs::Device->open($ARGV[0], $ARGV[1]);
unless ($device) {
    print "Device \"$ARGV[0]\" not found on bus \"$ARGV[1]\"\n";
    exit 1;
}

printf "Device is on bus %s, using driver %s\n",
       $device->bus, $device->driver_name;

if (my $parent = $device->get_parent) {
    printf "parent is %s\n",
           $parent->name;
} else {
    print "no parent\n";
}

sub print_usage {
    print "Usage: $0 [bus] [device]\n";
}
