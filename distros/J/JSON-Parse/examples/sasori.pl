#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Parse ':all';
# The scalar $sasori looks like Unicode to Perl
use utf8;
my $sasori = '["蠍"]';
my $p = parse_json ($sasori);
print utf8::is_utf8 ($p->[0]);
# Prints 1.

