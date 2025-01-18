package Locale::CLDR::Transformations::Any::Gz_ethi::Sarb;
# This file auto generated from Data\common\transforms\gz-Ethi-t-und-sarb.xml
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
		qr/(?^umi:\G\p{Ethiopic})/,
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
					replace => q([ሀ-ሆ]),
					result  => q(𐩠),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ለ-ሏ]),
					result  => q(𐩡),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ሐ-ሗ]),
					result  => q(𐩢),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([መ-ሟ]),
					result  => q(𐩣),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ሠ-ሧ]),
					result  => q(𐩦),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ረ-ሯ]),
					result  => q(𐩧),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ሰ-ሷ]),
					result  => q(𐩪),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ቀ-ቍ]),
					result  => q(𐩤),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([በ-ቧ]),
					result  => q(𐩨),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ተ-ቷ]),
					result  => q(𐩩),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ኀ-ኍ]),
					result  => q(𐩭),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ነ-ኗ]),
					result  => q(𐩬),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([አ-ኧ]),
					result  => q(𐩱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ከ-ኵ]),
					result  => q(𐩫),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ወ-ዎ]),
					result  => q(𐩥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ዐ-ዖ]),
					result  => q(𐩲),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ዘ-ዟ]),
					result  => q(𐩸),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([የ-ዮ]),
					result  => q(𐩺),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ደ-ዷ]),
					result  => q(𐩵),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ገ-ጕ]),
					result  => q(𐩴),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ጠ-ጧ]),
					result  => q(𐩷),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ጸ-ጿ]),
					result  => q(𐩮),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ፀ-ፆ]),
					result  => q(𐩳),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ፈ-ፏ]),
					result  => q(𐩰),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፲፻),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፩),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፪),
					result  => q(),
					revisit => 4,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፫),
					result  => q(),
					revisit => 5,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፬),
					result  => q(),
					revisit => 6,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፭),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፮),
					result  => q(),
					revisit => 4,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፯),
					result  => q(),
					revisit => 5,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፰),
					result  => q(),
					revisit => 6,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፱),
					result  => q(),
					revisit => 7,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፲),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፳),
					result  => q(),
					revisit => 4,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፴),
					result  => q(),
					revisit => 5,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፵),
					result  => q(),
					revisit => 6,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፶),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፷),
					result  => q(),
					revisit => 4,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፸),
					result  => q(),
					revisit => 5,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፹),
					result  => q(),
					revisit => 6,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፺),
					result  => q(),
					revisit => 7,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፻),
					result  => q(),
					revisit => 3,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(፼),
					result  => q(),
					revisit => 4,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(Null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(𐩿𐩿),
					result  => q(),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
