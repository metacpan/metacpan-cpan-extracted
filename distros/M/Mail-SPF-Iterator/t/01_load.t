#!/usr/bin/perl

use strict;
use warnings;

print "1..1\n";
eval 'use Mail::SPF::Iterator';
print STDOUT ( $@ ? "not ":"" )."ok # loading Mail::SPF::Iterator\n";
