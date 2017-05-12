#!/usr/bin/perl -w

use Hardware::iButton::Connection;

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$c->reset();

@bs = $c->scan("0C"); # gets DS1996 devices

print scalar(@bs)," device(s) found\n";
$b = $bs[0]; die "no DS1994 found" unless $b;

$start = 0;
$len = 8;
$start = $ARGV[0] if defined($ARGV[0]);
$len = $ARGV[1] if defined($ARGV[1]);

#$Hardware::iButton::Connection::debug = 1;

$ram = $b->read_memory($start, $len);
print unpack("H*", $ram),"\n";
