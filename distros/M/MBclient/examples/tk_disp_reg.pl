#!/usr/bin/perl

# Build a Tk window to display modbus register #0 from local modbus server.
# Update label area every 200 ms.
# For test it, you need a modbus/TCP server like mbserverd. It's available here:
# https://github.com/sourceperl/mbserverd

use strict;
use warnings;
use MBclient;
use Tk;

# modbus value to display
my $modbus_val = 0;

# create modbus object
my $m = MBclient->new();

# on local modbus server
$m->host("127.0.0.1");
$m->unit_id(1);

# open TCP socket
if (! $m->open()) {
  print "unable to open TCP socket.\n";
  exit(1);
}

# sub to update modbus_val (call by a tk timer)
sub update_modbus() {
  my $words = $m->read_holding_registers(0, 1);
  $modbus_val = $words->[0]."\n";
}

# init Tk
my $mw = tkinit();

# build modbus label area
my $modbus_label = $mw->Label(
  -textvariable => \$modbus_val,
  -relief       => 'raised',
  -width        => 10,
  -padx         => '2m',
  -pady         => '1m'
);
$modbus_label->pack(-side => 'bottom', -fill => 'both');

# destroy handler
$mw->bind('<Control-c>', sub{ $mw->destroy() });
$mw->bind('<Control-q>', sub{ $mw->destroy() });

# set update timer
my $timer = $mw->repeat(200, sub{ update_modbus(); });

# start Loop
$mw->MainLoop();
