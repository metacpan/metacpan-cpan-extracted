#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_cover);
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $cover = decode_utf8('(Vázáno) :');;
my $cleaned_cover = clean_cover($cover);

# Print out.
print encode_utf8("Cover: $cover\n");
print "Cleaned cover: $cleaned_cover\n";

# Output:
# Cover: (Vázáno) :
# Cleaned cover: hardback