package Locale::CLDR::Transformations::Any::Und_fonipa::Fa;
# This file auto generated from Data/common/transforms/und_FONIPA-fa.xml
#	on Mon 11 Apr  5:22:57 pm GMT

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
					replace => q([ʰʱʼ̰̃̋́̄̀̏̌̂˥˦˧˨˩ꜜꜛ↗↘̯͜͡]),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʲ),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ᵐ),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ⁿ),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ᵑ),
					result  => q(ŋ),
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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q([y \N{U+268} \N{U+289} ɯ u ʏ \N{U+26A.308} \N{U+28A.308} \N{U+26F.33D} \N{U+28A} ø ɤ o \N{U+F8.31E} \N{U+264.31E} \N{U+6F.31E} ɔ w \N{U+77.325} ʍ ʷ](?:[j]|[iɪe\N{U+65.31E}])(?:[e\N{U+65.31E}]|[ɘɵə\N{U+275.31E}])),
					result  => q(uia),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(yʉ),
					result  => q(iu),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NULL),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q([ɘ ɵ ə \N{U+275.31E}]ː?),
					result  => q(ای),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɘ ɵ ə \N{U+275.31E}]ː),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?!(?:[\p{L}\p{M}\p{N}]|[\.]))(?s:.))),
					replace => q((?:[ɘɵə\N{U+275.31E}]|[e\N{U+65.31E}])),
					result  => q(ه),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɘ ɵ ə \N{U+275.31E}]),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q([i ɪ e \N{U+65.31E}]ː?),
					result  => q(ای),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([i ɪ e \N{U+65.31E}]ː?j?),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q([y \N{U+268} \N{U+289} ɯ u ʏ \N{U+26A.308} \N{U+28A.308} \N{U+26F.33D} \N{U+28A} ø ɤ o \N{U+F8.31E} \N{U+264.31E} \N{U+6F.31E} ɔ w \N{U+77.325} ʍ ʷ]ː?),
					result  => q(او),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([y \N{U+268} \N{U+289} ɯ u ʏ \N{U+26A.308} \N{U+28A.308} \N{U+26F.33D} \N{U+28A} ø ɤ o \N{U+F8.31E} \N{U+264.31E} \N{U+6F.31E} ɔ w \N{U+77.325} ʍ ʷ]ː?),
					result  => q(و),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q([ɛ œ ɜ æ ɶ]ː?),
					result  => q(ا),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɛ œ ɜ æ ɶ]ː?),
					result  => q(ا),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q([ʌ a ɑ ɒ ɐ ɞ \N{U+E4} \N{U+252.308}]ː?),
					result  => q(آ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ʌ a ɑ ɒ ɐ ɞ \N{U+E4} \N{U+252.308}]ː?),
					result  => q(ا),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ː),
					result  => q(ّ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+74.361.283}ʧ]),
					result  => q(چ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɡgɠk][ʘ ɋ ǀ ʇ ǃ ʗ ǂ ʄ ǁ ʖ]),
					result  => q(کچ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([nɲ]?[ʘ ɋ ǀ ʇ ǃ ʗ ǂ ʄ ǁ ʖ]),
					result  => q(نچ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+6D.325}mɱ]),
					result  => q(م),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+6E.33C.30A}\N{U+6E.33C}\N{U+6E.325}n\N{U+273.30A}ɳ\N{U+272.30A}\N{U+272.325}ɲ]),
					result  => q(ن),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+14B.30A}ŋ\N{U+274.325}ɴ]k),
					result  => q(نک),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+14B.30A}ŋ\N{U+274.325}ɴ][ɡg]?),
					result  => q(نگ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([p\N{U+70.32A}]),
					result  => q(پ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([b\N{U+62.32A}ɓ]),
					result  => q(ب),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+64.33C}dɗᶑ]),
					result  => q(د),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+74.33C}t]),
					result  => q(ت),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ʈ]),
					result  => q(ط),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɖ]),
					result  => q(ض),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c),
					result  => q(چ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɟ),
					result  => q(دج),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(ک),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɡgɠ]),
					result  => q(گ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([qɢʡʛ]),
					result  => q(ق),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʔ),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(س),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(ز),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ʃʂɕʄ]),
					result  => q(ش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ʒʐʑ]),
					result  => q(ژ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɸf]),
					result  => q(ف),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([βv]),
					result  => q(و),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+3B8.33C}θ\N{U+3B8.331}]),
					result  => q(ث),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+F0.33C}ð\N{U+F0.320}]),
					result  => q(ذ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ç),
					result  => q(ش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʝ[i ɪ e \N{U+65.31E}]?ː?),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([xχ]),
					result  => q(خ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ɣʁ]),
					result  => q(غ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ħ),
					result  => q(ح),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʕ),
					result  => q(ع),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([hɦ\N{U+294.31E}]),
					result  => q(ه),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʋ),
					result  => q(و),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʙ),
					result  => q(بر),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r̝),
					result  => q(رژ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+279.325}\N{U+279}\N{U+27B.30A}\N{U+27B}\N{U+27E.325}ɾ\N{U+27D.30A}ɽ\N{U+72.33C}\N{U+72.325}r]),
					result  => q(ر),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+280.325}ʀ]),
					result  => q(غ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʜ),
					result  => q(ح),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʢ),
					result  => q(ع),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j[i ɪ e \N{U+65.31E}]?ː?),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɬ),
					result  => q(شل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɮ),
					result  => q(ژل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?!(?:[iɪe\N{U+65.31E}]|[jʝ]))(?s:.))),
					replace => q([\N{U+28E.325}ʎ]),
					result  => q(لی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([\N{U+6C.33C}\N{U+6C.325}l\N{U+26D.30A}ɭ\N{U+28E.325}ʎ]),
					result  => q(ل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ʟ\N{U+29F.320}]),
					result  => q(غ),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NULL),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(\.),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ووو+),
					result  => q(وو),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
