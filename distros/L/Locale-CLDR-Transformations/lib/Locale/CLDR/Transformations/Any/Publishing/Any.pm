package Locale::CLDR::Transformations::Any::Publishing::Any;
# This file auto generated from Data\common\transforms\Any-Publishing.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
					replace => q(⅞),
					result  => q(7\/8),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅝),
					result  => q(5\/8),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅜),
					result  => q(3\/8),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅛),
					result  => q(1\/8),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅚),
					result  => q(5\/6),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅙),
					result  => q(1\/6),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅘),
					result  => q(4\/5),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅗),
					result  => q(3\/5),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅖),
					result  => q(2\/5),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅕),
					result  => q(1\/5),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(¾),
					result  => q(3\/4),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(¼),
					result  => q(1\/4),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅔),
					result  => q(2\/3),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(⅓),
					result  => q(1\/3),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(½),
					result  => q(1\/2),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(℅),
					result  => q(c\/o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(™),
					result  => q(\(TM\)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(®),
					result  => q(\(R\)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(©),
					result  => q(\(C\)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(…),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(—),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(≅),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(∓),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(±),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(≥),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(≤),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(≠),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(’),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‘),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(”),
					result  => q(\"),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(“),
					result  => q(\"),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
