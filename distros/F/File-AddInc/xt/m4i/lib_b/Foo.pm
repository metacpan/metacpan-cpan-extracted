#!/usr/bin/env perl
package Foo;
use MyExporter2 -file_inc, -strict;
use Bar;

unless (caller) {
  print "OK\n";
}

1;
