#!/usr/bin/perl -w

use blib;
use Hardware::iButton::Connection;
use Hardware::iButton::Device;

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$c->reset();

@bs = $c->scan("0C"); # gets DS1996 devices

$b = $bs[0]; die "no DS1996 found" unless $b;

$start = 0;
$len = 8;
$start = $ARGV[0] if defined($ARGV[0]);
$len = $ARGV[1] if defined($ARGV[1]);

$data = pack("C$len", (0 .. $len-1));
print "length: ",length($data),"\n";
print "model: ",$b->model(),"\n";
print "data: ",unpack("H*",$data),"\n";

$Hardware::iButton::Connection::debug = 1;

$nwritten = $b->write_memory($start, $data);
$Hardware::iButton::Connection::debug = 0;
print "nwritten: $nwritten\n";

$ram = $b->read_memory($start, $len);
print unpack("H*", $ram),"\n";
