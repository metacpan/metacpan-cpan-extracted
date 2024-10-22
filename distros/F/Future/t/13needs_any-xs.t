#!/usr/bin/perl

use v5.14;
use warnings;

eval { require Future::XS } or do {
   print "1..0 # SKIP No Future::XS\n";
   exit;
};

do "./t/13needs_any.pl";
die $@ if $@;
