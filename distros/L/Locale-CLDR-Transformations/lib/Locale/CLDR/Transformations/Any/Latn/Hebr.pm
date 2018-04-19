package Locale::CLDR::Transformations::Any::Latn::Hebr;
# This file auto generated from Data\common\transforms\Hebrew-Latin.xml
#	on Fri 13 Apr  6:59:52 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
					to => q(nfd),
				},
				{
					from => q(Any),
					to => q(lower),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(x),
					result  => q(כס),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(v),
					result  => q(ו),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j),
					result  => q(ז),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(f),
					result  => q(ף),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(f),
					result  => q(פ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c),
					result  => q(ק),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̄),
					result  => q(ֿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o),
					result  => q(ֳ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e),
					result  => q(ֶ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(ַ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(u),
					result  => q(ֻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(ִ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o([^ \p{ccc = 0} \p{ccc = 230}] *)̀),
					result  => q(‎ֹ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e([^ \p{ccc = 0} \p{ccc = 230}] *)̆),
					result  => q(‎ְ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e([^ \p{ccc = 0} \p{ccc = 230}] *)́),
					result  => q(‎ֵ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e([^ \p{ccc = 0} \p{ccc = 230}] *)̀),
					result  => q(‎ֱ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a([^ \p{ccc = 0} \p{ccc = 230}] *)́),
					result  => q(‎ָ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a([^ \p{ccc = 0} \p{ccc = 230}] *)̀),
					result  => q(‎ֲ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̂),
					result  => q(ׂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̌),
					result  => q(ׁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̇),
					result  => q(ּ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(ר),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(q),
					result  => q(ק),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(p),
					result  => q(ף),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(p),
					result  => q(פ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʻ),
					result  => q(ע),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(ס),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(n),
					result  => q(ן),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(n),
					result  => q(נ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(m),
					result  => q(ם),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(m),
					result  => q(מ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(l),
					result  => q(ל),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(ך),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(k),
					result  => q(כ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(י),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(ט),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(ז),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(ו),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(ה),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(ד),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(ג),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(ב),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʼ),
					result  => q(א),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ţ),
					result  => q(ת),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ş),
					result  => q(ש),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ẕ),
					result  => q(ץ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(\p{M} * \p{L}),
					replace => q(ẕ),
					result  => q(צ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ẖ),
					result  => q(ח),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(nfc),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
