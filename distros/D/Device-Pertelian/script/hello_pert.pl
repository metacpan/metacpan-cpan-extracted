#! /usr/bin/perl

use strict;
use IO::File;
use Time::HiRes qw(usleep);

my $device = $ARGV[0];
die "usage: $0 device" unless defined $device;
my $fh = IO::File->new(">$device") or die "Can't open $device: $!";
$fh->autoflush(1);

init($fh);
clearscreen($fh);
backlight($fh, 0);

my $index = 0;
while (1) {
  writeline($fh, sprintf("Hello World line %d", $index), 1, $index % 4 + 1);
  ++$index;
  Sleep(1000);
}

sub Sleep {
  my $millesec = shift;
  usleep($millesec * 1000);
}

sub writeout {
  my($fh, $buf) = @_;
  $fh->print($buf);
  Sleep(1);
}

sub writeline {
  my($fh, $text, $col, $row) = @_;
  my @rowvals = (undef,
       0x80 + ($col - 1),
       0x80 + ($col - 1) +0x40,
       0x80 + ($col - 1) +0x14,
       0x80 + ($col - 1) + 0x54);
  my $buf = pack("cc", 0xfe, $rowvals[$row]);
  writeout($fh, $buf);

  foreach (split(//, $text)) {
    writeout($fh, $_);
  }
}

sub clearscreen {
  my($fh) = @_;

  my $buf = pack("cc", 0xfe, 1);
  writeout($fh, $buf);
  Sleep(10);
}

sub backlight {
  my($fh, $state) = @_;

  my $buf = pack("cc", 0xfe, 2 | $state? 1 : 0);
  writeout($fh, $buf);
}

sub init {
  my($fh) = @_;

  my $buf = pack("cc", 0xfe, 0x38);
  writeout($fh, $buf);

  $buf = pack("cc", 0xfe, 0x06);
  writeout($fh, $buf);

  $buf = pack("cc", 0xfe, 0x10);
  writeout($fh, $buf);

  $buf = pack("cc", 0xfe, 0x0c);
  writeout($fh, $buf);
} 
