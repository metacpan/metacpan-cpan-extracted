#!/usr/bin/perl -I.

use strict;
use warnings;

if ($^O eq 'MSWin32') {
    print "1..0 # Skip Event is not compatible with emulated fork on Windows\n";
    exit 0;
}

eval { require Event; };
if ($@) {
    print "1..0 # Skip Event not installed\n";
    exit 0;
}
require './t/multifork.tt';
