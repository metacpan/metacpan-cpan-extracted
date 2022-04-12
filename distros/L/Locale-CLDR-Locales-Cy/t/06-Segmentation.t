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

my $locale = Locale::CLDR->new('cy_GB');

my $text = "adf543., Tiếng Viết\n\r45dfr.A new sentence";

if ($^V lt v5.18.0) {
	dies_ok {$locale->split_grapheme_clusters($text)} "Can't call split_grapheme_clusters() with a Perl version less than 5.18";
	dies_ok {$locale->split_words($text)} "Can't call split_words() with a Perl version less than 5.18";
	dies_ok {$locale->split_sentences($text)} "Can't call split_sentences() with a Perl version less than 5.18";
	dies_ok {$locale->split_lines($text)} "Can't call split_lines() with a Perl version less than 5.18";
}
else {
	my @grapheme_clusters = $locale->split_grapheme_clusters($text);
	is_deeply(\@grapheme_clusters, [
		'a', 'd', 'f', '5', '4', '3', '.', ',', ' ', 'T', 'i', 'ế', 'n', 'g',
		' ', 'V', 'i', 'ế', 't', "\n", "\r", '4', '5', 'd', 'f', 'r', '.', 
		'A', ' ', 'n', 'e', 'w', ' ', 's', 'e', 'n', 't', 'e', 'n', 'c', 'e'
	], 'Split grapheme clusters');
	
	my @words = $locale->split_words($text);
	is_deeply(\@words, [
		'adf543', '.', ', ', 'Tiếng ', 'Viết', "\n", "\r", '45dfr.', 'A ', 'new ',
		'sentence'
	], 'Split words');

	my @sentences = $locale->split_sentences($text);
	is_deeply(\@sentences, [
		"adf543., Tiếng Viết",
		"\n",
		"\r",
		"45dfr.A new sentence",
	], 'Split sentences');

	my @lines=$locale->split_lines($text);
	is_deeply(\@lines, [
		"adf543., ",
		"Tiếng ",
		"Viết\n",
		"\r",
		"45dfr.A ",
		"new ",
		"sentence",
	], 'Split lines');
}