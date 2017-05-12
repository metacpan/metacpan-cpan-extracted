#!/usr/bin/perl

# Copyright 2008 Eric L. Wilhelm, all rights reserved

# Read keys from the keyboard and use --remote-send to relay them to a
# gvim server.

use warnings;
use strict;

use Linux::USBKeyboard;

my @args = @ARGV;
(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';
my $servername = shift(@args) or die "no servername";

my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));
$product or die "bah";

my $kb = Linux::USBKeyboard->open_keys($vendor, $product);

# ctrl => <C-$key>
# enter => <Enter>
# tab   => <Tab>
my %named = (
  escape => 'Esc',
  backspace => 'BS',
  delete    => 'Del',
  map({$_ => ucfirst($_)} qw(
    up down left right
    home end
    insert
    enter tab space
  )),
  pgup => 'PageUp',
  pgdn => 'PageDown',
);
my %bmap = map({$_ => uc(substr($_, 0, 1))} qw(ctrl alt shift));
while(my $read = <$kb>) {
  chomp($read);
  my ($k, @b) = split(/ /, $read);
  my %bits = map({$_ => $_} @b);
  my @bucky = map({$bits{$_} ? $bmap{$_} : ()} qw(ctrl alt shift));

  if(length($k) > 1) { # named keys
    if($k =~ m/^F\d+/) {}
    elsif(my $name = $named{$k}) {
      $k = $name;
    }
    else {
      warn "no named key for $k\n";
      next;
    }

    # and apply the bucky bits
    $k = '<' . join('-', @bucky, $k) . '>';
  }
  elsif(@bucky) {
    $k = '<' . join('-', @bucky, $k) . '>';
  }

  #warn "send $k\n";
  system('gvim', '--servername', $servername, '--remote-send', $k);
}

# vim:ts=2:sw=2:et:sta
