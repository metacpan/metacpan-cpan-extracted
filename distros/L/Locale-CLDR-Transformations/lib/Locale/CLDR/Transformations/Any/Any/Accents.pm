package Locale::CLDR::Transformations::Any::Any::Accents;
# This file auto generated from Data/common/transforms/Any-Accents.xml
#	on Mon 11 Apr  5:22:55 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
					replace => q(\←\`),
					result  => q(̀),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\'),
					result  => q(́),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\^),
					result  => q(̂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\~),
					result  => q(̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\-),
					result  => q(̄),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\"),
					result  => q(̈),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\*),
					result  => q(̊),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\,),
					result  => q(̧),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\'),
					result  => q(̸),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\.),
					result  => q(̣),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←AE),
					result  => q(Æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←ae),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←D),
					result  => q(Ð),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←d),
					result  => q(ð),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←O\'),
					result  => q(Ø),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←o\'),
					result  => q(ø),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←TH),
					result  => q(Þ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←th),
					result  => q(þ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←OE),
					result  => q(Œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←oe),
					result  => q(œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←ss),
					result  => q(ß),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←NG),
					result  => q(Ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←ng),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←T),
					result  => q(Θ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←t),
					result  => q(θ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←SH),
					result  => q(Ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←sh),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←ZH),
					result  => q(Ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←zh),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←U),
					result  => q(Ʊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←u),
					result  => q(ʊ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←A),
					result  => q(Ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←a),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←O),
					result  => q(Ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←o),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←E),
					result  => q(Ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←e),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←\'),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←i),
					result  => q(ɪ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\←v),
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
