#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
print repair_json (q![1 2 3 4 {"six":7 "eight":9}]!), "\n";

