package Locale::CLDR::Transformations::Any::Tamil::Interindic;
# This file auto generated from Data\common\transforms\Tamil-InterIndic.xml
#	on Fri 29 Apr  6:48:46 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
					replace => q((?^u:ொ)),
					result  => q(\uE04A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ோ)),
					result  => q(\uE04B),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ௌ)),
					result  => q(\uE04C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஔ)),
					result  => q(\uE014),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஂ)),
					result  => q(\uE002),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஃ)),
					result  => q(\uE003),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:அ)),
					result  => q(\uE005),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஆ)),
					result  => q(\uE006),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:இ)),
					result  => q(\uE007),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஈ)),
					result  => q(\uE008),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:உ)),
					result  => q(\uE009),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஊ)),
					result  => q(\uE00A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:எ)),
					result  => q(\uE00E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஏ)),
					result  => q(\uE00F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஐ)),
					result  => q(\uE010),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஒ)),
					result  => q(\uE012),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஓ)),
					result  => q(\uE013),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஔ)),
					result  => q(\uE014),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:க)),
					result  => q(\uE015),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ங)),
					result  => q(\uE019),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ச)),
					result  => q(\uE01A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஜ)),
					result  => q(\uE01C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஞ)),
					result  => q(\uE01E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ட)),
					result  => q(\uE01F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ண)),
					result  => q(\uE023),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:த)),
					result  => q(\uE024),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ந)),
					result  => q(\uE028),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ன)),
					result  => q(\uE029),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ப)),
					result  => q(\uE02A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ம)),
					result  => q(\uE02E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ய)),
					result  => q(\uE02F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ர)),
					result  => q(\uE030),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ற)),
					result  => q(\uE031),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ல)),
					result  => q(\uE032),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ள)),
					result  => q(\uE033),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ழ)),
					result  => q(\uE034),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:வ)),
					result  => q(\uE035),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஶ)),
					result  => q(\uE036),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஷ)),
					result  => q(\uE037),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஸ)),
					result  => q(\uE038),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ஹ)),
					result  => q(\uE039),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ா)),
					result  => q(\uE03E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ி)),
					result  => q(\uE03F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ீ)),
					result  => q(\uE040),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ு)),
					result  => q(\uE041),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ூ)),
					result  => q(\uE042),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ெ)),
					result  => q(\uE046),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ே)),
					result  => q(\uE047),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ை)),
					result  => q(\uE048),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:்)),
					result  => q(\uE04D),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ௗ)),
					result  => q(\uE057),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௧)),
					result  => q(\uE067),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௨)),
					result  => q(\uE068),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௩)),
					result  => q(\uE069),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௪)),
					result  => q(\uE06A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௫)),
					result  => q(\uE06B),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௬)),
					result  => q(\uE06C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௭)),
					result  => q(\uE06D),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௮)),
					result  => q(\uE06E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௯)),
					result  => q(\uE06F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௰)),
					result  => q(\uE067\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௱)),
					result  => q(\uE067\uE066\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௲)),
					result  => q(\uE067\uE066\uE066\uE066),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:௦)),
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
