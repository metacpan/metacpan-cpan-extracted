#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
print repair_json ('[.123,0123,1.e9]');
