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

my $locale = Locale::CLDR->new('ru_RU');
is ($locale->locale_name('fr'), 'французский', 'Name without region');
is ($locale->locale_name('fr_CA'), 'канадский французский', 'Name with known region');
is ($locale->locale_name('fr_BE'), 'французский (Бельгия)', 'Name with unknown region');
is ($locale->locale_name('fr_BE'), 'французский (Бельгия)', 'Cached method');
is ($locale->language_name, 'русский', 'Language name');
is ($locale->language_name('wibble'), 'неизвестный язык', 'Unknown Language name');
is ($locale->script_name('Cher'), 'чероки', 'Script name');
is ($locale->script_name('wibl'), 'неизвестная письменность', 'Invalid Script name');
is ($locale->region_name('GB'), 'Великобритания', 'Region name');
is ($locale->region_name('wibble'), 'неизвестный регион', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'Западно-армянский', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'клингонский', 'Language alias');
is ($locale->region_name('BQ'), 'Бонэйр, Синт-Эстатиус и Саба', 'Region alias');
is ($locale->region_name('830'), 'неизвестный регион', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'календарь', 'Key name');
is ($locale->key_name('calendar'), 'календарь', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'григорианский календарь', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'григорианский календарь', 'Type name');