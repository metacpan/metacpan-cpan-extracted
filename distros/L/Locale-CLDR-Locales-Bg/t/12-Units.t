#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 16;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('bg');

is($locale->unit(1, 'acre', 'narrow'), '1 акър', 'Bulgarian narrow 1 acre');
is($locale->unit(2, 'acre', 'narrow'), '2 акра', 'Bulgarian narrow 2 acres');
is($locale->unit(1, 'acre', 'short'), '1 акър', 'Bulgarian short 1 acre');
is($locale->unit(2, 'acre', 'short'), '2 акра', 'Bulgarian short 2 acres');
is($locale->unit(1, 'acre'), '1 акър', 'Bulgarian long 1 acre');
is($locale->unit(2, 'acre'), '2 акра', 'Bulgarian long 2 acres');
is($locale->duration_unit('hm', 1, 2), '1:02', 'Bulgarian duration hour, minuet');
is($locale->duration_unit('hms', 1, 2, 3 ), '1:02:03', 'Bulgarian duration hour, minuet, second');
is($locale->duration_unit('ms', 1, 2 ), '1:02', 'Bulgarian duration minuet, second');
is($locale->is_yes('Yes'), 1, 'Bulgarian is yes');
is($locale->is_yes('да'), 1, 'Bulgarian is yes');
is($locale->is_yes('es'), 0, 'Bulgarian is not yes');
is($locale->is_no('nO'), 1, 'Bulgarian is no');
is($locale->is_no('н'), 1, 'Bulgarian is no');
is($locale->is_no('N&'), 0, 'Bulgarian is not no');