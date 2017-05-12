#!/usr/bin/perl
#
# $Id: remove-tag.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

use Lib::IXP qw(:subs);

my $n = xremove($ENV{WMII_ADDRESS}, '/lbar/mytag') or die(ixp_errbuf()."\n");
print "Count: $n\n";
