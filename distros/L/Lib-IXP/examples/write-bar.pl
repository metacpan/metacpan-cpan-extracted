#!/usr/bin/perl
#
# $Id: write-bar.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

use Lib::IXP qw(:subs);

my $n = xwrite($ENV{WMII_ADDRESS}, '/rbar/status', "test") or die(ixp_errbuf()."\n");
print "Count: $n\n";
