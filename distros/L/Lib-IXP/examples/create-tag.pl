#!/usr/bin/perl
#
# $Id: create-tag.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

use Lib::IXP qw(:subs);

my $n = xcreate($ENV{WMII_ADDRESS}, '/lbar/mytag', "mytag") or die(ixp_errbuf()."\n");
print "Count: $n\n";
