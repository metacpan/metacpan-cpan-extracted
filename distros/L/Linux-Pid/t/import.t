#!perl -w

BEGIN { unshift @INC, './lib'; }

use strict;
use warnings;
use Linux::Pid qw(getpid getppid);

print "1..2\n";
print "not " if $$ != getpid();
print "ok 1\n";
print "not " if CORE::getppid() != getppid();
print "ok 2\n";
