#!/usr/bin/perl
#
# $Id: ls.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

my $file = shift or die("Provide file\n");

use Lib::IXP qw(:subs :consts);

my $h = xls($ENV{WMII_ADDRESS}, $file) or die(ixp_errbuf()."\n");

for (@$h) {
   if ($_->{mode} & P9_DMDIR && $_->{name} ne '/') {
      print $_->{name}."/\n";
   }
   else {
      print $_->{name}."\n";
   }
}
