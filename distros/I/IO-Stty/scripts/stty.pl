#!/usr/bin/perl

use strict;
use warnings;

use IO::Stty;

my @params;
foreach my $param (@ARGV) {
  push (@params,split(/\s/,$param));
}
my $stty = IO::Stty::stty(\*STDIN,@params);
if (defined $stty && $stty ne '0 but true') {
  print $stty;
}
