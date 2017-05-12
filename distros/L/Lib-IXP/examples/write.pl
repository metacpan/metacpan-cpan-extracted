#!/usr/bin/perl
#
# $Id: write.pl 11 2008-12-15 20:57:33Z gomor $
#
use strict; use warnings;

my $file = shift or die("Specify file\n");
my $data = shift or die("Specify data\n");

use Lib::IXP qw(:subs);

my $n = xwrite($ENV{WMII_ADDRESS}, $file, $data) or die(ixp_errbuf()."\n");
print "Count: $n\n";
