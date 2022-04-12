#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 19;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('cs');
is ($locale->locale_name('fr'), 'francouzština', 'Name without region');
is ($locale->locale_name('de_CH'), 'němčina standardní (Švýcarsko)', 'Name with known region') ;
is ($locale->locale_name('fr_BE'), 'francouzština (Belgie)', 'Name with unknown region') ;
is ($locale->locale_name('fr_BE'), 'francouzština (Belgie)', 'Cached method') ;
is ($locale->language_name, 'čeština', 'Language name');
is ($locale->language_name('wibble'), 'neznámý jazyk', 'Unknown Language name');
is ($locale->script_name('Cher'), 'čerokí', 'Script name');
is ($locale->script_name('wibl'), 'neznámé písmo', 'Invalid Script name');
is ($locale->region_name('GB'), 'Spojené království', 'Region name');
is ($locale->region_name('wibble'), 'neznámá oblast', 'Invalid Region name');
is ($locale->variant_name('SCOTLAND'), 'angličtina (Skotsko)', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'klingonština', 'Language alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'Kalendář', 'Key name');
is ($locale->key_name('calendar'), 'Kalendář', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'Gregoriánský kalendář', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'Gregoriánský kalendář', 'Type name');