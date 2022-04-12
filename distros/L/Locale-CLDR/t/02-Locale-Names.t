#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 21;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('en');
is ($locale->locale_name('fr'), 'French', 'Name without region');
is ($locale->locale_name('fr_CA'), 'Canadian French', 'Name with known region') ;
is ($locale->locale_name('fr_BE'), 'French (Belgium)', 'Name with unknown region') ;
is ($locale->locale_name('fr_BE'), 'French (Belgium)', 'Cached method') ;
is ($locale->language_name, 'English', 'Language name');
is ($locale->language_name('wibble'), 'Unknown language', 'Unknown Language name');
is ($locale->script_name('Cher'), 'Cherokee', 'Script name');
is ($locale->script_name('wibl'), 'Unknown Script', 'Invalid Script name');
is ($locale->region_name('GB'), 'United Kingdom', 'Region name');
is ($locale->region_name('wibble'), 'Unknown Region', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'Western Armenian', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'Klingon', 'Language alias');
is ($locale->region_name('BQ'), 'Caribbean Netherlands', 'Region alias');
is ($locale->region_name('830'), 'Unknown Region', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'Calendar', 'Key name');
is ($locale->key_name('calendar'), 'Calendar', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'Gregorian Calendar', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'Gregorian Calendar', 'Type name');