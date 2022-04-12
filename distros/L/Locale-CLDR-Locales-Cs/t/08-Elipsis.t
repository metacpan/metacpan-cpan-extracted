#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 8;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('cs');

is ($locale->truncated_beginning('abc'), '… abc','Truncated beginning');
is ($locale->truncated_between('abc','def'), 'abc… def','Truncated between');
is ($locale->truncated_end('abc'), 'abc…','Truncated end');
is ($locale->truncated_word_beginning('abc'), '… abc','Truncated word beginning');
is ($locale->truncated_word_between('abc','def'), 'abc… def','Truncated word between');
is ($locale->truncated_word_end('abc'), 'abc…','Truncated word end');
is ($locale->more_information(), '?','More Information');