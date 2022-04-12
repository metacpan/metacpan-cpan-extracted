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

my $locale = Locale::CLDR->new('cs');

is($locale->unit(1, 'acre', 'narrow'), '1 ac', 'Czech narrow 1 acre');
is($locale->unit(2, 'acre', 'narrow'), '2 ac', 'Czech narrow 2 acres');
is($locale->unit(1, 'acre', 'short'), '1 ac', 'Czech short 1 acre');
is($locale->unit(2, 'acre', 'short'), '2 ac', 'Czech short 2 acres');
is($locale->unit(1, 'acre'), '1 akr', 'Czech long 1 acre');
is($locale->unit(2, 'acre'), '2 akry', 'Czech long 2 acres');
is($locale->duration_unit('hm', 1, 2), '1:02', 'Czech duration hour, minuet');
is($locale->duration_unit('hms', 1, 2, 3 ), '1:02:03', 'Czech duration hour, minuet, second');
is($locale->duration_unit('ms', 1, 2 ), '1:02', 'Czech duration minuet, second');
is($locale->is_yes('Yes'), 1, 'Czech is yes');
is($locale->is_yes('ano'), 1, 'Czech is yes');
is($locale->is_yes('es'), 0, 'Czech is not yes');
is($locale->is_no('n'), 1, 'Czech is no');
is($locale->is_no('ne'), 1, 'Czech is no');
is($locale->is_no('N&'), 0, 'Czech is not no');