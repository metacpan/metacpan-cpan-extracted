#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
my $perl = parse_json ('["a", "b", "c"]');
print ref $perl, "\n";

