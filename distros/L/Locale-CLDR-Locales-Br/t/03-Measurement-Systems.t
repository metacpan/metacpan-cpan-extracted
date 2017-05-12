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

is ($locale->measurement_system_name('uk'), 'RU', 'Measurement system UK');
is ($locale->measurement_system_name('us'), 'SU', 'Measurement system US');
is ($locale->measurement_system_name('metric'), 'metrek', 'Measurement system Metric');