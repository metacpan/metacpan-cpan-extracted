package Locale::CLDR::Transformations::Any::Sarb::Gz_ethi;
# This file auto generated from Data\common\transforms\gz-Ethi-t-und-sarb.xml
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
					replace => q(𐩿𐩲𐩱𐩿),
					result  => q(፼),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩣𐩿),
					result  => q(፻),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩲𐩲𐩾𐩿),
					result  => q(፺),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩲𐩾𐩿),
					result  => q(፹),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩾𐩿),
					result  => q(፸),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩾𐩿),
					result  => q(፷),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩾𐩿),
					result  => q(፶),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩲𐩲𐩿),
					result  => q(፵),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩲𐩿),
					result  => q(፴),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩲𐩿),
					result  => q(፳),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩲𐩿),
					result  => q(፲),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩽𐩽𐩭𐩿),
					result  => q(፱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩽𐩭𐩿),
					result  => q(፰),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩭𐩿),
					result  => q(፯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩭𐩿),
					result  => q(፮),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩭𐩿),
					result  => q(፭),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩽𐩽𐩿),
					result  => q(፬),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩽𐩿),
					result  => q(፫),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩽𐩿),
					result  => q(፪),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩽𐩿),
					result  => q(፩),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩱𐩿),
					result  => q(፲፻),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩰),
					result  => q(ፈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩳),
					result  => q(ፀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩮),
					result  => q(ጸ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩷),
					result  => q(ጠ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩴),
					result  => q(ገ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩵),
					result  => q(ደ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩺),
					result  => q(የ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩹),
					result  => q(ዘ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩸),
					result  => q(ዘ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩲),
					result  => q(ዐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩥),
					result  => q(ወ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩫),
					result  => q(ከ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩱),
					result  => q(አ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩬),
					result  => q(ነ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩭),
					result  => q(ኍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩩),
					result  => q(ተ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩨),
					result  => q(በ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩤),
					result  => q(ቀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩪),
					result  => q(ሰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩧),
					result  => q(ረ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩦),
					result  => q(ሠ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩣),
					result  => q(መ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩢),
					result  => q(ሐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩡),
					result  => q(ለ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(𐩠),
					result  => q(ሀ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
