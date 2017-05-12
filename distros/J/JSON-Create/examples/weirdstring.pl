#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create 'create_json';
# An example string containing various things.
my $weirdstring = {weird => "\t\r\n\x00 " . '"' . '\\' . '/' };
print create_json ($weirdstring);

