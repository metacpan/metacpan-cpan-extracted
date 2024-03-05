package Locale::CLDR::Transformations::Any::Any::Publishing;
# This file auto generated from Data\common\transforms\Any-Publishing.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
					replace => q(\`\`),
					result  => q(“),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\`),
					result  => q(‘),
					revisit => 0,
				},
				{
					before  => q([\p{Z} \p{Ps} \p{Pi} $]),
					after   => q(),
					replace => q(\"),
					result  => q(“),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\"),
					result  => q(”),
					revisit => 0,
				},
				{
					before  => q([\p{Z} \p{Ps} \p{Pi} $]),
					after   => q(),
					replace => q(\'),
					result  => q(‘),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(’),
					revisit => 0,
				},
				{
					before  => q(\'),
					after   => q(),
					replace => q(\'),
					result  => q(),
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
					replace => q(\'),
					result  => q(≠),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(≤),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(≥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(±),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(∓),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(≅),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(—),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\'),
					result  => q(…),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(C\)),
					result  => q(©),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(c\)),
					result  => q(©),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(R\)),
					result  => q(®),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(r\)),
					result  => q(®),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(TM\)),
					result  => q(™),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\(tm\)),
					result  => q(™),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c\/o),
					result  => q(℅),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/2),
					result  => q(½),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/3),
					result  => q(⅓),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(2\/3),
					result  => q(⅔),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/4),
					result  => q(¼),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(3\/4),
					result  => q(¾),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/5),
					result  => q(⅕),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(2\/5),
					result  => q(⅖),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(3\/5),
					result  => q(⅗),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(4\/5),
					result  => q(⅘),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/6),
					result  => q(⅙),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(5\/6),
					result  => q(⅚),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(1\/8),
					result  => q(⅛),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(3\/8),
					result  => q(⅜),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(5\/8),
					result  => q(⅝),
					revisit => 0,
				},
				{
					before  => q([^0-9]),
					after   => q([^0-9]),
					replace => q(7\/8),
					result  => q(⅞),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
