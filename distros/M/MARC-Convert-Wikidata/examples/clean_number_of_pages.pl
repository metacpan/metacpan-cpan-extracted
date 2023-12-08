#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Convert::Wikidata::Utils qw(clean_number_of_pages);

my $number_of_pages = '575 s. ;';
my $cleaned_number_of_pages = clean_number_of_pages($number_of_pages);

# Print out.
print "Number of pages: $number_of_pages\n";
print "Cleaned number of pages: $cleaned_number_of_pages\n";

# Output:
# Number of pages: 575 s. ;
# Cleaned number of pages: 575