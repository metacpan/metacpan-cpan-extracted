#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 5;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('fr_FR');
is($locale->measurement, 'metric', 'FR uses metric measurement');
is($locale->paper, 'A4', 'FR uses A4 paper');
$locale = Locale::CLDR->new('fr_CH');
is($locale->measurement, 'metric', 'CH uses metric measurement');
is($locale->paper, 'A4', 'CH uses A4 paper');