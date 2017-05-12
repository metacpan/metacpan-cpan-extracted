#!/usr/bin/perl

use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Device::Arduino::LCD;


my $lcd = Device::Arduino::LCD->new;

# clear the displays.
$lcd->reset;

# a label.
$lcd->first_line("load average");

# if we get a signal, reset the LCD before exiting.
$SIG{INT} = sub { $lcd->reset; exit };
$SIG{$_} = $SIG{INT} for qw[ HUP ABRT QUIT TRAP STOP ];

# forever
while (1) {

  # snarf the loadavg
  chomp(my $uptime = `uptime`);
  my @values = reverse split /\s+/, $uptime;
  my ($fifteen, $five, $one) = @values[0..2];

  # print it on the second line.
  $lcd->second_line("$one $five $fifteen");

  # and wobble the gauge around a bit.
  $lcd->gauge_pct(1 => ($one * 50)); # dual CPU machine...

  # to really jack the load avg, don't bother sleeping.
  sleep 1;
}
