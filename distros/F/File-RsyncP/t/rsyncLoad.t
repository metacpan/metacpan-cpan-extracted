#!/bin/perl

#
# No decent tests for File::RsyncP until the server-side code is
# written and it can talk to itself.  I guess we could have some
# tests that run if can find a real rsync somewhere...
#

BEGIN {print "1..1\n";}
END {print "not ok 1\n" unless $loaded;}
use File::RsyncP;
$loaded = 1;
print "ok 1\n";

