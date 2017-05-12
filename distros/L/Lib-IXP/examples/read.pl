#!/usr/bin/perl
#
# $Id: read.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

my $file = shift or die("Specify file to read\n");

use Lib::IXP qw(:subs);

while (1) {
   sleep(1);
   my $read = xread($ENV{WMII_ADDRESS}, $file, 1) or die(ixp_errbuf()."\n");
   print "$read\n";
}
