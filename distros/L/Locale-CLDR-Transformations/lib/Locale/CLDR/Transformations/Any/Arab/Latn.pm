package Locale::CLDR::Transformations::Any::Arab::Latn;
# This file auto generated from Data\common\transforms\Arabic-Latin.xml
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
		qr/(?^umi:\G(?:[\p{Arabic}\p{Block=Arabic}]|[‎ⁿ،؛؟ـً-ٕ٠-٬۰-۹﷼ښ]|[ٰؑ]))/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFKD),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(\p{Nd}),
					after   => q(\p{Nd}),
					replace => q(٫),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(\p{Nd}),
					after   => q(\p{Nd}),
					replace => q(٬),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٫),
					result  => q(\'̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٬),
					result  => q(\'̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(،),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؛),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؟),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٪),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۰),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۱),
					result  => q(1̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۲),
					result  => q(2̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۳),
					result  => q(3̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۴),
					result  => q(4̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۵),
					result  => q(5̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۶),
					result  => q(6̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۷),
					result  => q(7̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۸),
					result  => q(8̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(۹),
					result  => q(9̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٠),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(١),
					result  => q(1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٢),
					result  => q(2),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٣),
					result  => q(3),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٤),
					result  => q(4),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٥),
					result  => q(5),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٦),
					result  => q(6),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٧),
					result  => q(7),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٨),
					result  => q(8),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٩),
					result  => q(9),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؉),
					result  => q(‰),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؊),
					result  => q(‱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎۔‎),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(َا),
					result  => q(ā),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ُو),
					result  => q(ū),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ِي),
					result  => q(ī),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ث),
					result  => q(tẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ذ),
					result  => q(dẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ش),
					result  => q(sẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ص),
					result  => q(ṣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ض),
					result  => q(ḍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ط),
					result  => q(ṭ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ظ),
					result  => q(ẓ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(غ),
					result  => q(gẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ة),
					result  => q(ẗ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ژ),
					result  => q(zẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ڭ),
					result  => q(ṉg),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۋ),
					result  => q(v̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ی),
					result  => q(y̰),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ښ),
					result  => q(sˌ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ء),
					result  => q(ʾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ا),
					result  => q(ạ),
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
					replace => q(ت),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ج),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ح),
					result  => q(ḥ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(خ),
					result  => q(kẖ),
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
					replace => q(ر),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ز),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(س),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ع),
					result  => q(ʿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ـ),
					result  => q(),
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
					replace => q(ق),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ک),
					result  => q(ḵ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ك),
					result  => q(k),
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
					replace => q(و),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ى),
					result  => q(y̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ي),
					result  => q(y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ً),
					result  => q(aⁿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ٌ),
					result  => q(uⁿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ٍ),
					result  => q(iⁿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(َ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ُ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ِ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ّ),
					result  => q(̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ْ),
					result  => q(̊),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ٓ),
					result  => q(̂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ٔ),
					result  => q(̉),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ٕ),
					result  => q(̹),
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
					replace => q(چ),
					result  => q(cẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ڤ),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(گ),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ٺ‎),
					result  => q(ṭh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ٿ‎),
					result  => q(th),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ٽ‎),
					result  => q(ṭ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڙ‎),
					result  => q(ṛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڦ‎),
					result  => q(ph),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڻ‎),
					result  => q(ṇ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڱ‎),
					result  => q(ṅ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڃ‎),
					result  => q(ñ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڪ‎),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڄ‎),
					result  => q(j̈),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ۃ‎),
					result  => q(ẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڳ‎),
					result  => q(g̤),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڍ‎),
					result  => q(ḍh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڌ‎),
					result  => q(dh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڏ‎),
					result  => q(d̤),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڊ‎),
					result  => q(ḍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڇ‎),
					result  => q(ch),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڀ‎),
					result  => q(bh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ٻ‎),
					result  => q(ḇ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎۽‎),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎۾‎),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ھ‎),
					result  => q(ʱ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ں‎),
					result  => q(◌̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ے‎),
					result  => q(ai),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڈ‎),
					result  => q(ḍ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڑ‎),
					result  => q(ṛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ٹ‎),
					result  => q(ṭ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ټ‎),
					result  => q(ṯ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ځ‎),
					result  => q(dz),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎څ‎),
					result  => q(ts),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ډ‎),
					result  => q(ḏ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ړ‎),
					result  => q(ṟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ږ‎),
					result  => q(z͟h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ګ‎),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ڼ‎),
					result  => q(ṉ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ۍ‎),
					result  => q(ạy),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ې‎),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ہ‎),
					result  => q(ḥ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ە‎),
					result  => q(ĥ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([ٰؑ]),
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
