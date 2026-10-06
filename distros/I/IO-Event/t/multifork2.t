#!/usr/bin/perl

use strict;
use warnings;

if ($^O eq 'MSWin32') {
    # all tests pass, but perl frequently crashes while tearing down the
    # emulated fork children
    print "1..0 # Skip crashes during emulated fork teardown on Windows\n";
    exit 0;
}

use IO::Event 'emulate_Event';
require './t/multifork.tt';
