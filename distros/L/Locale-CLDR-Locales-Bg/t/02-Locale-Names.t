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

my $locale = Locale::CLDR->new('bg');
is ($locale->locale_name('fr'), 'френски', 'Name without region');
is ($locale->locale_name('nl_BE'), 'фламандски', 'Name with known region');
is ($locale->locale_name('fr_BE'), 'френски (Белгия)', 'Name with unknown region');
is ($locale->locale_name('fr_BE'), 'френски (Белгия)', 'Cached method');
is ($locale->language_name, 'български', 'Language name');
is ($locale->language_name('wibble'), 'неопределен', 'Unknown Language name');
is ($locale->script_name('Cher'), 'Чероки', 'Script name');
is ($locale->script_name('wibl'), 'непозната писменост', 'Invalid Script name');
is ($locale->region_name('GB'), 'Обединеното кралство', 'Region name');
is ($locale->region_name('wibble'), 'непознат регион', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'Западно арменски', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'клингонски', 'Language alias');
is ($locale->region_name('BQ'), 'Карибска Нидерландия', 'Region alias');
is ($locale->region_name('830'), 'непознат регион', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'календар', 'Key name');
is ($locale->key_name('calendar'), 'календар', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'григориански календар', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'григориански календар', 'Type name');