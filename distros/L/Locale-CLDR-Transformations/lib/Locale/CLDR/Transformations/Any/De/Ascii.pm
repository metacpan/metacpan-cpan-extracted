package Locale::CLDR::Transformations::Any::De::Ascii;
# This file auto generated from Data\common\transforms\de-ASCII.xml
#	on Sat  4 Nov  5:50:50 pm GMT

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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q([ä\N{U+61.308}]),
					result  => q(ae),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ö\N{U+6F.308}]),
					result  => q(oe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ü\N{U+75.308}]),
					result  => q(ue),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{Lowercase}),
					replace => q([Ä \{ A ̈ \}]),
					result  => q(Ae),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{Lowercase}),
					replace => q([Ö \{ O ̈ \}]),
					result  => q(Oe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{Lowercase}),
					replace => q([Ü \{ U ̈ \}]),
					result  => q(Ue),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([Ä \{ A ̈ \}]),
					result  => q(AE),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([Ö \{ O ̈ \}]),
					result  => q(OE),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([Ü \{ U ̈ \}]),
					result  => q(UE),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(ASCII),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
