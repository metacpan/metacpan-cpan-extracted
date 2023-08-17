#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_edition_number);
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $edition_number = decode_utf8('Druhé vydání');
my $cleaned_edition_number = clean_edition_number($edition_number);

# Print out.
print encode_utf8("Edition number: $edition_number\n");
print "Cleaned edition number: $cleaned_edition_number\n";

# Output:
# Edition number: Druhé vydání
# Cleaned edition number: 2