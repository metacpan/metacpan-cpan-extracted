#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 6;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('de');
is($locale->list(), '', 'Empty list');
is($locale->list(1), '1', 'One element list');
is($locale->list(qw(1 2)), '1, 2', 'Two element list');
is($locale->list(qw(1 2 3)), '1, 2 und 3', 'Three element list');
is($locale->list(qw(1 2 3 4)), '1, 2, 3 und 4', 'Four element list');