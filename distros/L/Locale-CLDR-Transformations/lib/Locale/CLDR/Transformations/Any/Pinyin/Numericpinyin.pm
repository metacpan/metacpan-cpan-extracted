package Locale::CLDR::Transformations::Any::Pinyin::Numericpinyin;
# This file auto generated from Data\common\transforms\Pinyin-NumericPinyin.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(̄),
					result  => q(1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(́),
					result  => q(2),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̌),
					result  => q(3),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̀),
					result  => q(4),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
