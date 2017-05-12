#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
my $r = repair_json ('{"stuff":["good');
print "$r\n";
