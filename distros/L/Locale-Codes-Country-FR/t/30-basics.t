#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Locale::Codes::Country::FR;

# Create an object
my $loc = Locale::Codes::Country::FR->new;
ok(defined $loc, 'Object creation successful');

# Test country name translations
is($loc->country2fr('Australia'), 'Australie', 'Australia -> Australie');
is($loc->country2fr('United States'), 'États-Unis', 'United States -> États-Unis');
is($loc->country2fr('England'), 'Angleterre', 'England -> Angleterre');
is($loc->country2fr('Canada'), 'Canada', 'Canada -> Canada');

# Test gender determination
is($loc->en_country2gender('Australia'), 'F', 'Australia is feminine');
is($loc->en_country2gender('United States'), 'M', 'United States is masculine');
is($loc->en_country2gender('France'), 'F', 'France is feminine');
is($loc->en_country2gender('Canada'), 'M', 'Canada is masculine');

# Edge case: Country not in the list
is($loc->country2fr('Unknown Country'), undef, 'Unknown country returns undef');

# Test gender for a missing country
is($loc->en_country2gender('Unknown Country'), undef, 'Gender for unknown country is undef');

done_testing();
