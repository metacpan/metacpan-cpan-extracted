#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair 'repair_json';
my $badstring = '"' . chr (9) . chr (0) . "\n" . '"';
print repair_json ($badstring), "\n";
