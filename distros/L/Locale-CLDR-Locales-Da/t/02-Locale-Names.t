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

my $locale = Locale::CLDR->new('da_DK');
is ($locale->locale_name('fr'), 'fransk', 'Name without region');
is ($locale->locale_name('fr_CA'), 'canadisk fransk', 'Name with known region') ;
is ($locale->locale_name('fr_BE'), 'fransk (Belgien)', 'Name with unknown region') ;
is ($locale->locale_name('fr_BE'), 'fransk (Belgien)', 'Cached method') ;
is ($locale->language_name, 'dansk', 'Language name');
is ($locale->language_name('wibble'), 'ukendt sprog', 'Unknown Language name');
is ($locale->script_name('Cher'), 'cherokee', 'Script name');
is ($locale->script_name('wibl'), 'ukendt skriftsprog', 'Invalid Script name');
is ($locale->region_name('GB'), 'Storbritannien', 'Region name');
is ($locale->region_name('wibble'), 'Ukendt område', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'vestarmensk', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'klingon', 'Language alias');
is ($locale->region_name('BQ'), 'De tidligere Nederlandske Antiller', 'Region alias');
is ($locale->region_name('830'), 'Ukendt område', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'kalender', 'Key name');
is ($locale->key_name('calendar'), 'kalender', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'gregoriansk kalender', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'gregoriansk kalender', 'Type name');