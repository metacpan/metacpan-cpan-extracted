#!/usr/bin/perl -I.

use strict;
use warnings;

eval { require Event; };
if ($@) {
    print "1..0 # Skip Event not installed\n";
    exit 0;
}
require './t/getline.tt';
