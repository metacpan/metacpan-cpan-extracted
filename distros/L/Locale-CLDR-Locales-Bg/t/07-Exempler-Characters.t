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

my $locale = Locale::CLDR->new('bg');

if ($^V lt v5.18.0) {
	dies_ok {$locale->is_exemplar_character("а")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('@')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {$locale->is_exemplar_character('auxiliary', "ѐ")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('auxiliary','@')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {$locale->is_exemplar_character('punctuation', "!")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('punctuation', 'a')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
}
else {
	ok($locale->is_exemplar_character("а"), 'Is Exemplar Character');
	ok(!$locale->is_exemplar_character('@'), 'Is not Exemplar Character');
	ok($locale->is_exemplar_character('auxiliary', "ѐ"), 'Is Auxiliary Exemplar Character');
	ok(!$locale->is_exemplar_character('auxiliary','@'), 'Is not Auxiliary Exemplar Character');
	ok($locale->is_exemplar_character('punctuation', "!"), 'Is Punctuation Exemplar Character');
	ok(!$locale->is_exemplar_character('punctuation', 'a'), 'Is not Punctuation Exemplar Character');
}
is("@{$locale->index_characters()}", 'А Б В Г Д Е Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ю Я', 'Index Characters');
