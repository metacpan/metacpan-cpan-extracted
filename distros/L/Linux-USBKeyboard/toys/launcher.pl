#!/usr/bin/perl

use warnings;
use strict;

use YAML;
use Linux::USBKeyboard;

my @args = @ARGV;

(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';

my $config_file = shift(@args) or die "no config";
die "no config" unless(-e $config_file);
my ($config) = YAML::LoadFile($config_file);

my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));
$product or die "bah";

my $kb = Linux::USBKeyboard->open_keys($vendor, $product);

while(my $key = <$kb>) {
  chomp($key);
  if(my $cmd = $config->{$key}) {
    warn "$cmd\n";
    my $pid = fork;
    unless($pid) {
      close(STDIN); close(STDOUT); close(STDERR);
      exec(split(/ /, $cmd));
    }
    waitpid($pid, 0);
  }
}
wait;

# vim:ts=2:sw=2:et:sta
