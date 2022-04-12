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

my $locale = Locale::CLDR->new('ca');

is($locale->unit(1, 'acre', 'narrow'), '1ac.', 'Catalan narrow 1 acre');
is($locale->unit(2, 'acre', 'narrow'), '2ac.', 'Catalan narrow 2 acres');
is($locale->unit(1, 'acre', 'short'), '1 ac', 'Catalan short 1 acre');
is($locale->unit(2, 'acre', 'short'), '2 ac', 'Catalan short 2 acres');
is($locale->unit(1, 'acre'), '1 acre', 'Catalan long 1 acre');
is($locale->unit(2, 'acre'), '2 acres', 'Catalan long 2 acres');
is($locale->duration_unit('hm', 1, 2), '1:02', 'Catalan duration hour, minuet');
is($locale->duration_unit('hms', 1, 2, 3 ), '1:02:03', 'Catalan duration hour, minuet, second');
is($locale->duration_unit('ms', 1, 2 ), '1:02', 'Catalan duration minuet, second');
is($locale->is_yes('Yes'), 1, 'Catalan is yes');
is($locale->is_yes('sí'), 1, 'Catalan is yes');
is($locale->is_yes('es'), 0, 'Catalan is not yes');
is($locale->is_no('nO'), 1, 'Catalan is no');
is($locale->is_no('n'), 1, 'Catalan is no');
is($locale->is_no('N&'), 0, 'Catalan is not no');