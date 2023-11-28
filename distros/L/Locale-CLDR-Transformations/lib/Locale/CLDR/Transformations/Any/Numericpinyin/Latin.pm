package Locale::CLDR::Transformations::Any::Numericpinyin::Latin;
# This file auto generated from Data\common\transforms\Latin-NumericPinyin.xml
#	on Sat  4 Nov  5:50:48 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

BEGIN {
	die "Transliteration requires Perl 5.18 or above"
		unless $^V ge v5.18.0;
}

no warnings 'experimental::regex_sets';
has 'transforms' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub { [
		qr/(?^um:\G.)/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFD),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(\p{letter}),
					after   => q(),
					replace => q(([1-5])),
					result  => q(&NumericPinyin-Pinyin($1)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([aAeEiIoOuU \N{U+75.308} \N{U+55.308} vV])((?:(?![aAeEiIoOuU\N{U+75.308}\N{U+55.308}vV])[a-zA-Z])*)([1-5])),
					result  => q($1&NumericPinyin-Pinyin($3)$2),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([oO])((?:(?![aeAE])[aAeEiIoOuU\N{U+75.308}\N{U+55.308}vV])*(?:(?![aAeEiIoOuU\N{U+75.308}\N{U+55.308}vV])[a-zA-Z])*)([1-5])),
					result  => q($1&NumericPinyin-Pinyin($3)$2),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([aAeE])([aAeEiIoOuU \N{U+75.308} \N{U+55.308} vV]*(?:(?![aAeEiIoOuU\N{U+75.308}\N{U+55.308}vV])[a-zA-Z])*)([1-5])),
					result  => q($1&NumericPinyin-Pinyin($3)$2),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFC),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
