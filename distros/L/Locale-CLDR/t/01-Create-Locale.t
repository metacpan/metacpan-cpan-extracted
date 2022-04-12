#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 18;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new();
is($locale->id, 'und', 'Empty Locale');

$locale = Locale::CLDR->new(language_id => 'en');
is($locale->id, 'en', 'Set Language explicitly');

$locale = Locale::CLDR->new('en');
is($locale->id, 'en', 'Set Language implicitly');

$locale = Locale::CLDR->new(language_id => 'en', region_id => 'gb');
is($locale->id, 'en_GB', 'Set Language and Region explicitly');

$locale = Locale::CLDR->new('en-gb');
is($locale->id, 'en_GB', 'Set Language and Region implicitly');

$locale = Locale::CLDR->new(language_id => 'en', script_id => 'latn');
is($locale->id, 'en_Latn', 'Set Language and Script explicitly');

$locale = Locale::CLDR->new('en-latn');
is($locale->id, 'en_Latn', 'Set Language and Script implicitly');

$locale = Locale::CLDR->new(language_id => 'en', region_id => 'gb', script_id => 'latn');
is($locale->id, 'en_Latn_GB', 'Set Language, Region and Script explicitly');

$locale = Locale::CLDR->new('en-latn-gb');
is($locale->id, 'en_Latn_GB', 'Set Language, Region and Script implicitly');

$locale = Locale::CLDR->new(language_id => 'en', variant_id => '1994');
is($locale->id, 'en_1994', 'Set Language and Variant from string explicitly');

$locale = Locale::CLDR->new('en_1994');
is($locale->id, 'en_1994', 'Set Language and variant implicitly');

$locale = Locale::CLDR->new('en_latn_gb_1994');
is($locale->id, 'en_Latn_GB_1994', 'Set Language, Region, Script and variant implicitly');

$locale = Locale::CLDR->new('latn_gb');
is($locale->id, 'und_Latn_GB', 'Set likely Language, Region, and Script implicitly');

throws_ok { $locale = Locale::CLDR->new('wibble') } qr/Invalid language/, "Caught invalid language";
throws_ok { $locale = Locale::CLDR->new('en_wi') } qr/Invalid region/, "Caught invalid region";
throws_ok { $locale = Locale::CLDR->new('en_wibb') } qr/Invalid script/, "Caught invalid script";
throws_ok { $locale = Locale::CLDR->new('en_wibble') } qr/Invalid variant/, "Caught invalid variant";