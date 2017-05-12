#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# 1:  Check that we're installed.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use GraphViz::Zone;
$loaded = 1;
print "ok 1\n";
$obj = new GraphViz::Zone('zonefile' => $ARGV[0]);
