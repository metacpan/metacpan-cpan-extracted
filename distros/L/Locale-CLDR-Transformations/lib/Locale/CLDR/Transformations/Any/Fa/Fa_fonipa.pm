package Locale::CLDR::Transformations::Any::Fa::Fa_fonipa;
# This file auto generated from Data\common\transforms\fa-fa_FONIPA.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
					replace => q([‌‍]),
					result  => q(),
					revisit => 0,
				},
			],
		},
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
					replace => q(ي),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ى),
					result  => q(ی),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ك),
					result  => q(ک),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ە),
					result  => q(ه),
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
					replace => q(یّ),
					result  => q(jj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(وّ),
					result  => q(vv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([َُِ])ّ),
					result  => q(ّ),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(َیْ),
					result  => q(æj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ِی),
					result  => q(ej),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یوْ),
					result  => q(iːv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(ه[^ \p{L} \p{M} \p{N}]),
					replace => q(یو),
					result  => q(iːv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(هٔ[^ \p{L} \p{M} \p{N}]),
					replace => q(یو),
					result  => q(iːv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یو),
					result  => q(juː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(َوْ),
					result  => q(av),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ء),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(أَ),
					result  => q(ʔæ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(أ),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ؤ),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یْٔ),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یِٔ),
					result  => q(ʔe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یٔ),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(َه),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q([^ːeoæ]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(هٔ),
					result  => q(eje),
					revisit => 0,
				},
				{
					before  => q([e]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(هٔ),
					result  => q(je),
					revisit => 0,
				},
				{
					before  => q([^ːeoæ]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(ه),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q([e]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(ه),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(اَ),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(اً[^ \p{L} \p{M} \p{N}]),
					result  => q(æn),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(َ),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یه),
					result  => q(je),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یٰ),
					result  => q(ɒː),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(وی),
					result  => q(uːj),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					after   => q(),
					replace => q(ْیو),
					result  => q(juː),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(ْی),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(ی),
					result  => q(iːj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(ی),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(یْ),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ی),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(ای),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(آ),
					result  => q(ɒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(آ),
					result  => q(ɒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(اِ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(اُو),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(اُ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(او),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(او),
					result  => q(ɒːv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ا),
					result  => q(ɒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ِ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(هِّ),
					result  => q(hhe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(هِ),
					result  => q(he),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(خوا),
					result  => q(χɒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(خوی),
					result  => q(χiː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(و),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(ه[^ \p{L} \p{M} \p{N}]),
					replace => q(و),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(هٔ[^ \p{L} \p{M} \p{N}]),
					replace => q(و),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					after   => q(),
					replace => q(و),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]ّ),
					after   => q(),
					replace => q(و),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(ُ),
					after   => q([m n p b t d k ɡ ʔ f v s z ʃ ʒ ʁ ɢ h χ \N{U+74.361.283} \N{U+64.361.292} l ɾ]),
					replace => q(و),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(و),
					result  => q(va),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([َ ِ ُ ٓ ا و ی]),
					replace => q(ُو),
					result  => q(ov),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ُؤ),
					result  => q(oʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ُو),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ُ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(پ),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ب),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([تط]),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(د),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ک),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(گ),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ع),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(چ),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ج),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ف),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([سصث]),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([زذضظ]),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ش),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ژ),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(خ),
					result  => q(χ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(غ),
					result  => q(ʁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ق),
					result  => q(ɢ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ح),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(م),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ن),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ه),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ل),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ر),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ْ),
					result  => q(),
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
					before  => q(((?:[mnpbtdkɡʔfvszʃʒʁɢhχ\N{U+74.361.283}\N{U+64.361.292}lɾ]|[َُِٓاوی]))),
					after   => q(),
					replace => q(ّ),
					result  => q($1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ًّٰٔ]),
					result  => q(),
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
