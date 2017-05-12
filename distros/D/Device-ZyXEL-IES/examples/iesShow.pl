#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: iesShow.pl
#
#        USAGE: ./iesShow.pl  
#
#  DESCRIPTION: Demonstrates the Device::XyXEL::IES module
#
#      OPTIONS: dslamname readcommunity
# REQUIREMENTS: Device::ZyXEL::IES
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jesper Dalberg (jdalberg at gmail.com), 
# ORGANIZATION: Fullrate 
#      VERSION: 1.0
#      CREATED: 09/18/12 09:18:10
#     REVISION: 0.1
#===============================================================================

use strict;
use warnings;
use utf8;
use Data::Dumper;
use Device::ZyXEL::IES;

my ($dslam, $readcommunity) = @ARGV;

die "USAGE: $0 dslam readcommunity\n" unless defined( $readcommunity );

my $device = Device::ZyXEL::IES->new( get_community => $readcommunity,  hostname => $dslam );

my $dr = $device->fetchDetails();

printf "System: %s\n", $device->sysdescr;
printf "Uptime: %s\n", $device->uptime;

# Do a slotInventory
my $result = $device->slotInventory;

my $slotlist = $device->slots;

foreach my $sid ( sort keys %{$slotlist} ) {
  my $slot = $slotlist->{$sid};

  $slot->fetchDetails;

  printf "  Slot: %d, Cardtype: %s, Firmware: %s\n", $slot->id, $slot->cardtype, $slot->firmware;

  my $pir = $slot->portInventory;

  die "$pir\n" unless $pir eq 'OK';

  my $ports = $slot->ports;
  foreach my $pid ( sort keys %{$ports} ) {
    my $port = $ports->{$pid};
    printf "%02d: %s, %s, %s\n", $port->id, $port->profile, $port->adminstatus == 1 ? 'UP' : 'DOWN', $port->operstatus == 1 ? 'UP' : 'DOWN';
  }
}

