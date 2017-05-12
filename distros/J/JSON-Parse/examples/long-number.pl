#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
my $long_number = '[12345678901234567890123456789012345678901234567890]';
my $out = parse_json ($long_number);
print "$out->[0]\n";
