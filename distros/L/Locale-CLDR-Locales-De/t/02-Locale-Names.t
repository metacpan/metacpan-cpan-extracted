#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 20;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('de_DE');
is ($locale->locale_name('fr'), 'Französisch', 'Name without region');
#is ($locale->locale_name('fr_CA'), 'Kanadisches Französisch', 'Name with known region') ;
is ($locale->locale_name('fr_BE'), 'Französisch (Belgien)', 'Name with unknown region') ;
is ($locale->locale_name('fr_BE'), 'Französisch (Belgien)', 'Cached method') ;
is ($locale->language_name, 'Deutsch', 'Language name');
is ($locale->language_name('wibble'), 'Unbekannte Sprache', 'Unknown Language name');
is ($locale->script_name('Cher'), 'Cherokee', 'Script name');
is ($locale->script_name('wibl'), 'Unbekannte Schrift', 'Invalid Script name');
is ($locale->region_name('GB'), 'Vereinigtes Königreich', 'Region name');
is ($locale->region_name('wibble'), 'Unbekannte Region', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'Westarmenisch', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'Klingonisch', 'Language alias');
is ($locale->region_name('BQ'), 'Bonaire, Sint Eustatius und Saba', 'Region alias');
is ($locale->region_name('830'), 'Unbekannte Region', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'Kalender', 'Key name');
is ($locale->key_name('calendar'), 'Kalender', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'Gregorianischer Kalender', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'Gregorianischer Kalender', 'Type name');