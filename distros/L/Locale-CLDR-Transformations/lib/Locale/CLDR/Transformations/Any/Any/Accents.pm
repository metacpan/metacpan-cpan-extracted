package Locale::CLDR::Transformations::Any::Any::Accents;
# This file auto generated from Data\common\transforms\Any-Accents.xml
#	on Fri 29 Apr  6:48:39 pm GMT

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
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\`)),
					result  => q(̀),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\')),
					result  => q(́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\^)),
					result  => q(̂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\~)),
					result  => q(̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\-)),
					result  => q(̄),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\")),
					result  => q(̈),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\*)),
					result  => q(̊),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\,)),
					result  => q(̧),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\')),
					result  => q(̸),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\.)),
					result  => q(̣),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←AE)),
					result  => q(Æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←ae)),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←D)),
					result  => q(Ð),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←d)),
					result  => q(ð),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←O\')),
					result  => q(Ø),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←o\')),
					result  => q(ø),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←TH)),
					result  => q(Þ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←th)),
					result  => q(þ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←OE)),
					result  => q(Œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←oe)),
					result  => q(œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←ss)),
					result  => q(ß),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←NG)),
					result  => q(Ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←ng)),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←T)),
					result  => q(Θ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←t)),
					result  => q(θ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←SH)),
					result  => q(Ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←sh)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←ZH)),
					result  => q(Ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←zh)),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←U)),
					result  => q(Ʊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←u)),
					result  => q(ʊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←A)),
					result  => q(Ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←a)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←O)),
					result  => q(Ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←o)),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←E)),
					result  => q(Ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←e)),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←\')),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←i)),
					result  => q(ɪ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\←v)),
					result  => q(ʌ),
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
