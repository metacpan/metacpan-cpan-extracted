#!/bin/perl

use strict;

# Autodetect Linux or Solaris
die $@ if eval sprintf('use %s::loadavg qw(loadavg)',ucfirst $^O) || $@;

print "Current 1, 5 and 15 minute load averages are:\n";
print join("\n",loadavg()),"\n";
