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

my $locale = Locale::CLDR->new('cy_GB');
is ($locale->locale_name('fr'), 'Ffrangeg', 'Name without region');
is ($locale->locale_name('fr_CA'), 'Ffrangeg Canada', 'Name with known region');
is ($locale->locale_name('fr_BE'), 'Ffrangeg (Gwlad Belg)', 'Name with unknown region');
is ($locale->locale_name('fr_BE'), 'Ffrangeg (Gwlad Belg)', 'Cached method');
is ($locale->language_name, 'Cymraeg', 'Language name');
is ($locale->language_name('wibble'), 'Iaith anhysbys', 'Unknown Language name');
is ($locale->script_name('Guru'), 'Gwrmwci', 'Script name');
is ($locale->script_name('wibl'), 'Sgript anhysbys', 'Invalid Script name');
is ($locale->region_name('GB'), 'Y Deyrnas Unedig', 'Region name');
is ($locale->region_name('wibble'), 'Rhanbarth Anhysbys', 'Invalid Region name');
is ($locale->variant_name('AREVMDA'), 'Armeneg Gorllewinol', 'Variant name');
throws_ok { $locale->variant_name('WIBBLE') } qr{ \A Invalid \s variant }xms, 'Invalid Variant name';
is ($locale->language_name('i_klingon'), 'Klingon', 'Language alias');
is ($locale->region_name('BQ'), 'Antilles yr Iseldiroedd', 'Region alias');
is ($locale->region_name('830'), 'Rhanbarth Anhysbys', 'Region alias');
is ($locale->variant_name('BOKMAL'), '', 'Variant alias');
is ($locale->key_name('ca'), 'Calendr', 'Key name');
is ($locale->key_name('calendar'), 'Calendr', 'Key name');
is ($locale->type_name('ca', 'gregorian'), 'Calendr Gregori', 'Type name');
is ($locale->type_name('calendar', 'gregorian'), 'Calendr Gregori', 'Type name');