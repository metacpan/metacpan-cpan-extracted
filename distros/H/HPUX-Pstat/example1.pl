#!/usr/bin/perl -w
#
# dump the result of all HPUX::Pstat functions
#
# $Id: example1.pl,v 1.1 2003/03/31 17:42:16 deschwen Exp $

use Data::Dumper;
use ExtUtils::testlib;
use HPUX::Pstat;

my $x  = HPUX::Pstat::getstatic();
print "getstatic() ", Dumper($x);

$x  = HPUX::Pstat::getdynamic();
print "getdynamic() ", Dumper($x);

$x  = HPUX::Pstat::getvminfo();
print "getvminfo() ", Dumper($x);

$x  = HPUX::Pstat::getswap(4);
print "getswap(4) ", Dumper($x);

$x  = HPUX::Pstat::getproc(10);
print "getproc(10) ", Dumper($x);

$x  = HPUX::Pstat::getprocessor(4);
print "getprocessor(4) ", Dumper($x);

