#! /usr/bin/env perl
#---------------------------------------------------------------------
# delete-objects.pl
# Created by Christopher J. Madsen
#
# This example script is in the public domain.
#
# Delete files/folders/tracks/albums from device
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use Media::LibMTP::API qw(Get_First_Device);

my $device;

while (1) {
  $device = Get_First_Device() and last;
  say STDERR "Trying again in 5 seconds...";
  sleep 5;
}

say STDERR "Connected to " . $device->Get_Friendlyname;

for my $id (@ARGV) {
  $device->Delete_Object($id) and die "$id failed: " . $device->errstr;
} # end for each $id in @ARGV

undef $device;
