#!/usr/bin/perl

# Display 10 registers from local modbus server to console.
# For test it, you need a modbus/TCP server like mbserverd. It's available here:
# https://github.com/sourceperl/mbserverd

use strict;
use warnings;
use MBclient;

# create modbus object
my $m = MBclient->new();

# on local modbus server
$m->host("127.0.0.1");
$m->unit_id(1);
# for print frame and debug string : uncomment this line
#$m->{debug} = 1;

# open TCP socket
if (! $m->open()) {
  print "unable to open TCP socket.\n";
  exit(1);
}

# read register 0 to 9 and print it on stdout
my $words = $m->read_holding_registers(0, 10);
foreach my $word (@$words) {
  print $word."\n";
}
