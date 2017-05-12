#!perl -w

BEGIN { unshift @INC, './lib'; }

use strict;
use warnings;
use Linux::Pid;

print "1..2\n";
print "not " if $$ != Linux::Pid::getpid();
print "ok 1\n";
print "not " if getppid() != Linux::Pid::getppid();
print "ok 2\n";
