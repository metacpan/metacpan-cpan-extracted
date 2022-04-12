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

my $locale = Locale::CLDR->new('ca');

if ($^V lt v5.18.0) {
	dies_ok {$locale->is_exemplar_character("A")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('@')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {$locale->is_exemplar_character('auxiliary', "\N{U+00EA}")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('auxiliary','@')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {$locale->is_exemplar_character('punctuation', "!")} "Can't call is_exemplar_character() with a Perl version less than 5.18";
	dies_ok {!$locale->is_exemplar_character('punctuation', 'a')} "Can't call is_exemplar_character() with a Perl version less than 5.18";
}
else {
	ok($locale->is_exemplar_character("A"), 'Is Exemplar Character');
	ok(!$locale->is_exemplar_character('@'), 'Is not Exemplar Character');
	ok($locale->is_exemplar_character('auxiliary', "\N{U+00EA}"), 'Is Auxiliary Exemplar Character');
	ok(!$locale->is_exemplar_character('auxiliary','@'), 'Is not Auxiliary Exemplar Character');
	ok($locale->is_exemplar_character('punctuation', "!"), 'Is Punctuation Exemplar Character');
	ok(!$locale->is_exemplar_character('punctuation', 'a'), 'Is not Punctuation Exemplar Character');
}
is("@{$locale->index_characters()}", 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', 'Index Characters');
