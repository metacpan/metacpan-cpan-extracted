#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_date);
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $date = decode_utf8('2020 březen 03.');
my $cleaned_date = clean_date($date);

# Print out.
print encode_utf8("Date: $date\n");
print "Cleaned date: $cleaned_date\n";

# Output:
# Date: 2020 březen 03.
# Cleaned date: 2020-03-03