#!/usr/bin/perl

use v5.20;
use warnings;

eval { require Future::XS } or do {
   print "1..0 # SKIP No Future::XS\n";
   exit;
};

do "./t/26wrap-unwrap.pl";
die $@ if $@;
