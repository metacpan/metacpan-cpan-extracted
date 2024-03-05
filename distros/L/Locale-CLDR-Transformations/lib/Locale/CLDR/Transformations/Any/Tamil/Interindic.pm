package Locale::CLDR::Transformations::Any::Tamil::Interindic;
# This file auto generated from Data\common\transforms\Tamil-InterIndic.xml
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
					replace => q(ொ),
					result  => q(\uE04A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ோ),
					result  => q(\uE04B),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ௌ),
					result  => q(\uE04C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஔ),
					result  => q(\uE014),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஂ),
					result  => q(\uE002),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஃ),
					result  => q(\uE003),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(அ),
					result  => q(\uE005),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஆ),
					result  => q(\uE006),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(இ),
					result  => q(\uE007),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஈ),
					result  => q(\uE008),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(உ),
					result  => q(\uE009),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஊ),
					result  => q(\uE00A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(எ),
					result  => q(\uE00E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஏ),
					result  => q(\uE00F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஐ),
					result  => q(\uE010),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஒ),
					result  => q(\uE012),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஓ),
					result  => q(\uE013),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஔ),
					result  => q(\uE014),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(க),
					result  => q(\uE015),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ங),
					result  => q(\uE019),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ச),
					result  => q(\uE01A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஜ),
					result  => q(\uE01C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஞ),
					result  => q(\uE01E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ட),
					result  => q(\uE01F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ண),
					result  => q(\uE023),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(த),
					result  => q(\uE024),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ந),
					result  => q(\uE028),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ன),
					result  => q(\uE029),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ப),
					result  => q(\uE02A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ம),
					result  => q(\uE02E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ய),
					result  => q(\uE02F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ர),
					result  => q(\uE030),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ற),
					result  => q(\uE031),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ல),
					result  => q(\uE032),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ள),
					result  => q(\uE033),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ழ),
					result  => q(\uE034),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(வ),
					result  => q(\uE035),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஶ),
					result  => q(\uE036),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஷ),
					result  => q(\uE037),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஸ),
					result  => q(\uE038),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஹ),
					result  => q(\uE039),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ா),
					result  => q(\uE03E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ி),
					result  => q(\uE03F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ீ),
					result  => q(\uE040),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ு),
					result  => q(\uE041),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ூ),
					result  => q(\uE042),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ெ),
					result  => q(\uE046),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ே),
					result  => q(\uE047),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ை),
					result  => q(\uE048),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(்),
					result  => q(\uE04D),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ௗ),
					result  => q(\uE057),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௧),
					result  => q(\uE067),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௨),
					result  => q(\uE068),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௩),
					result  => q(\uE069),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௪),
					result  => q(\uE06A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௫),
					result  => q(\uE06B),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௬),
					result  => q(\uE06C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௭),
					result  => q(\uE06D),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௮),
					result  => q(\uE06E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௯),
					result  => q(\uE06F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௰),
					result  => q(\uE067\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௱),
					result  => q(\uE067\uE066\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௲),
					result  => q(\uE067\uE066\uE066\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(௦),
					result  => q(\uE066),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
