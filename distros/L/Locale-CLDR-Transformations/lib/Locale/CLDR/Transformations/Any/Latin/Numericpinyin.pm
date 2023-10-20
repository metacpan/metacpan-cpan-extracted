package Locale::CLDR::Transformations::Any::Latin::Numericpinyin;
# This file auto generated from Data\common\transforms\Latin-NumericPinyin.xml
#	on Fri 13 Oct  9:03:47 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
					before  => q(e),
					after   => q(),
					replace => q(([̄́̌̀̆])r),
					result  => q(r&Pinyin-NumericPinyin($1)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([̄́̌̀̆])([ionu\N{U+6F.6E}\N{U+6E.67}])),
					result  => q($2&Pinyin-NumericPinyin($1)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([̄́̌̀̆])),
					result  => q(&Pinyin-NumericPinyin($1)),
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
