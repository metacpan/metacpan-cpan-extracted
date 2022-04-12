#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 4;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('br_FR');

my $test = Locale::CLDR->new('en_latn_US');
is ($locale->code_pattern('language', $test), 'saozneg', 'Code pattern Language');
is ($locale->code_pattern('script', $test), 'latin', 'Code pattern script');
is ($locale->code_pattern('region', $test), 'Stadoù-Unanet', 'Code pattern region');