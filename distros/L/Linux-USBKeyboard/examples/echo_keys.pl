#!/usr/bin/perl

# echo keypresses with open_keys()

use warnings;
use strict;

use lib 'lib';

use Linux::USBKeyboard;

# e.g. 0x0e6a, 0x0001
my @args = @ARGV;
(@args) or die 'run `lsusb` to determine your vendor_id, product_id';
########################################################################

my %sel;

if($args[0] !~ m/^-/) {
  my ($vendor, $product) = map({hex($_)}
    $#args ? @args : split(/:/, $args[0]));
  warn "getting $vendor, $product\n";
  $product = 1 unless(defined($product));
  %sel = (product => $product, vendor => $vendor);
}
else {
  (@args % 2) and die "odd number of arguments";
  while(@args) {
    my $key = shift(@args);
    $key =~ s/^--?// or die "'$key' is not an option?";
    $sel{$key} = shift(@args);
  }
}

my $k = eval {Linux::USBKeyboard->open_keys(%sel)};
if($@) { die "$@ - you might have the wrong permissions or address"; }

$SIG{INT} = sub { warn "bye\n"; exit};
while(my $line = <$k>) {
  print $line;
}

# vim:ts=2:sw=2:et:sta

