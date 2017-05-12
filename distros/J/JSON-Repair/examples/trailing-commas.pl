#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
print repair_json (q/{"answer":["bob dylan",42,],}/), "\n";


