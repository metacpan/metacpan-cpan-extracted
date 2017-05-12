#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Memory::Process;

# Object.
my $m = Memory::Process->new;

# Example process.
$m->record("Before my big method");
my $var = ('foo' x 100);
sleep 1;
$m->record("After my big method");
sleep 1;
$m->record("End");

# Print report.
print $m->report."\n";

# Output like:
#   time    vsz (  diff)    rss (  diff) shared (  diff)   code (  diff)   data (  diff)
#      1  19120 (     0)   2464 (     0)   1824 (     0)      8 (     0)   1056 (     0) After my big method
#      2  19120 (     0)   2464 (     0)   1824 (     0)      8 (     0)   1056 (     0) End