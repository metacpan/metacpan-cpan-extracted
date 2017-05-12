#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
my $perl = parse_json ('{"a":1, "b":2}');
print ref $perl, "\n";

