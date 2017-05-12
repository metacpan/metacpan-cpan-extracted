package Locale::CLDR::Transformations::Any::Und_fonipa::Ar;
# This file auto generated from Data\common\transforms\und_FONIPA-ar.xml
#	on Fri 29 Apr  6:48:50 pm GMT

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
					replace => q((?^u:[ʰʱʼ̰̃̋́̄̀̏̌̂˥˦˧˨˩ꜜꜛ↗↘̯͜͡])),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʲ)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ᵐ)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ⁿ)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ᵑ)),
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
					replace => q((?^u:[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ](?[[j] + [i ɪ e \{ e̞ \}]])(?[[e\{e̞\}] + [ɘ ɵ ə \{ ɵ̞ \}]]))),
					result  => q(uia),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:yʉ)),
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
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[i ɪ e \{ e̞ \}]ː)),
					result  => q(إِي),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[i ɪ e \{ e̞ \}])),
					result  => q(إِ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[i ɪ e \{ e̞ \}]ʔ)),
					result  => q(ئ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[i ɪ e \{ e̞ \}]ːʔ)),
					result  => q(يء),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:(?[([i ɪ e \{ e̞ \}] + [y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ] + [ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ] + [ɘ ɵ ə \{ ɵ̞ \}])]))),
					replace => q((?^u:[i ɪ e \{ e̞ \}]ːʔ)),
					result  => q(ئ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[i ɪ e \{ e̞ \}]ː?)),
					result  => q(ي),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ]ː)),
					result  => q(أو),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ])),
					result  => q(أ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ]ʔ)),
					result  => q(ؤ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ]ːʔ)),
					result  => q(وء),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[y \{ ɨ \} \{ ʉ \} ɯ u ʏ \{ ɪ̈ \} \{ ʊ̈ \} \{ ɯ̽ \} \{ ʊ \} ø ɤ o \{ ø̞ \} \{ ɤ̞ \} \{ o̞ \} ɞ ɔ w \{ w̥ \} ʍ ʷ]ː?)),
					result  => q(و),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ː)),
					result  => q(آ),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ])),
					result  => q(أ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ʔ)),
					result  => q(أ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ːʔ)),
					result  => q(اء),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ː?ʔ[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ː?)),
					result  => q(اءا),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɛ œ ɜ ʌ æ ɐ a ɶ \{ ä \} \{ ɒ̈ \} ɑ ɒ]ː?)),
					result  => q(ا),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[ɘ ɵ ə \{ ɵ̞ \}]ː)),
					result  => q(إِي),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ʔ?[ɘ ɵ ə \{ ɵ̞ \}])),
					result  => q(أ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɘ ɵ ə \{ ɵ̞ \}]ː)),
					result  => q(ي),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɘ ɵ ə \{ ɵ̞ \}])),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʔ)),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ː)),
					result  => q(ّ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{t͡ʃ\}ʧ])),
					result  => q(تْش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɡgɠk][ʘ ɋ ǀ ʇ ǃ ʗ ǂ ʄ ǁ ʖ])),
					result  => q(كْش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ʘ ɋ ǀ ʇ ǃ ʗ ǂ ʄ ǁ ʖ])),
					result  => q(تْش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{m̥\}mɱ])),
					result  => q(م),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{n̼̊\}\{n̼\}\{n̥\}n\{ɳ̊\}ɳ\{ɲ̊\}\{ɲ̥\}ɲ])),
					result  => q(ن),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{ŋ̊\}ŋ\{ɴ̥\}ɴ]k)),
					result  => q(نك),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{ŋ̊\}ŋ\{ɴ̥\}ɴ][ɡgɠ]?)),
					result  => q(نْغ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[pb\{p̪\}\{b̪\}ɓ])),
					result  => q(ب),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{d̼\}dɗᶑ])),
					result  => q(د),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{t̼\}t])),
					result  => q(ت),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ʈ])),
					result  => q(ط),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɖ])),
					result  => q(ض),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:c)),
					result  => q(تْش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɟ)),
					result  => q(دج),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:k)),
					result  => q(ك),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɡgɠ])),
					result  => q(غ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[qɢʡʛ])),
					result  => q(ق),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:s)),
					result  => q(س),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:z)),
					result  => q(ز),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ʃʂɕʄ])),
					result  => q(ش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ʒʐʑ])),
					result  => q(ج),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɸfv])),
					result  => q(ف),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:β)),
					result  => q(ب),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{θ̼\}θ\{θ̱\}])),
					result  => q(ث),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{ð̼\}ð\{ð̠\}])),
					result  => q(ذ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ç)),
					result  => q(ش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʝ[i ɪ e \{ e̞ \}]?ː?)),
					result  => q(ي),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[xχ])),
					result  => q(خ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ɣʁ])),
					result  => q(غ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ħ)),
					result  => q(ح),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʕ)),
					result  => q(ع),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[hɦ\{ʔ̞\}])),
					result  => q(ه),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʋ)),
					result  => q(و),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʙ)),
					result  => q(بر),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:r̝)),
					result  => q(رش),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{ɹ̥\}\{ɹ\}\{ɻ̊\}\{ɻ\}\{ɾ̥\}ɾ\{ɽ̊\}ɽ\{r̼\}\{r̥\}r])),
					result  => q(ر),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{ʀ̥\}ʀ])),
					result  => q(غ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʜ)),
					result  => q(ح),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʢ)),
					result  => q(ع),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:j[i ɪ e \{ e̞ \}]?ː?)),
					result  => q(ي),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɬ)),
					result  => q(شْل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɮ)),
					result  => q(جْل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:(?[![i ɪ e \{ e̞ \}] + [jʝ]]))),
					replace => q((?^u:[\{ʎ̥\}ʎ])),
					result  => q(لي),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[\{l̼\}\{l̥\}l\{ɭ̊\}ɭ\{ʎ̥\}ʎ])),
					result  => q(ل),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[ʟ\{ʟ̠\}])),
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
					replace => q((?^u:\.)),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ووو+)),
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
