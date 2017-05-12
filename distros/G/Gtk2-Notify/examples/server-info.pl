#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Notify -init, 'ServerInfo';

my ($name, $vendor, $version, $spec_version)
    = Gtk2::Notify->get_server_info;

print <<"EOI";
Name:         $name
Vendor:       $vendor
Version:      $version
Spec Version: $spec_version
Capabilities:
EOI

my @caps = Gtk2::Notify->get_server_caps;

if (!scalar @caps) {
    print "Failed to receive server caps.\n";
    exit 1;
}

for my $cap (@caps) {
    print "    $cap\n";
}
