#!/usr/bin/perl -w

use strict;
$| = 1;

print "Attempting to make all tests...\n";

my($in, $out, $err);

foreach my $file (sort <*.data.in>) {
  print "  Running $file...";
  system "perl ./build_test ./$file @ARGV";
  print "done\n";
}

print "All tests rebuilt.\n";
