#!/usr/bin/perl
#
# $Id: read-bar.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

use Lib::IXP qw(:subs);

my $read = xread($ENV{WMII_ADDRESS}, '/rbar/status', -1) or die(ixp_errbuf()."\n");
print "$read\n";
