#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
# The scalar $ebi does not look like Unicode to Perl
no utf8;
my $ebi = '["海老"]';
my $p = parse_json ($ebi);
print utf8::is_utf8 ($p->[0]);
# Prints nothing.

