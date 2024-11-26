#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_issn);

my $issn = '0585-5675 ;';
my $cleaned_issn = clean_issn($issn);

# Print out.
print "ISSN: $issn\n";
print "Cleaned ISSN: $cleaned_issn\n";

# Output:
# ISSN: 0585-5675 ;
# Cleaned ISSN: 0585-5675