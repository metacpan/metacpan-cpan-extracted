#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 4;
use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('en_US');

$locale->add_plural_to_lexicon(
	files => {
		other => '[_1 files]',
		zero => 'no files',
		one => '[_1 file]',
		two => '[_1 files]',
	},
	directories => {
		other => '[_1 directories]',
		zero => 'no directories',
		one => '[_1 directory]',
		two => '[_1 directories]',
	}
);

$locale->add_to_lexicon(
	'scanned x files in y directories',
	'Scanned [plural,_1,files] in [plural,_2,directories]'
);

is($locale->localetext('scanned x files in y directories', 0, 0),
	'Scanned 0 files in 0 directories',
	'maketext with two zero elements'
);

is($locale->localetext('scanned x files in y directories', 1, 0),
	'Scanned 1 file in 0 directories',
	'maketext with 1 and 0'
);

is($locale->localetext('scanned x files in y directories', 1, 1),
	'Scanned 1 file in 1 directory',
	'maketext with 1 and 1'
);