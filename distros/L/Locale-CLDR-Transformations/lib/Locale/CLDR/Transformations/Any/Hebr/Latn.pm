package Locale::CLDR::Transformations::Any::Hebr::Latn;
# This file auto generated from Data\common\transforms\Hebrew-Latin.xml
#	on Sun  5 Aug  5:49:15 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
		qr/(?^umi:\G(?:(?![ֽ])(?:[\p{Hebrew}\p{^ccc=0}]|[ְ-ֹֻ-ּׁ-ׂℵ-ℸֿ̄])))/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(nfkd),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(ח),
					result  => q(ẖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(צ),
					result  => q(ẕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ץ),
					result  => q(ẕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ש),
					result  => q(ş),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ת),
					result  => q(ţ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(א),
					result  => q(ʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ב),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ג),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ד),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ה),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ו),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ז),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ט),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(י),
					result  => q(y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(כ),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ך),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ל),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(מ),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ם),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(נ),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ן),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ס),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ע),
					result  => q(ʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(פ),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ף),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ק),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ר),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(װ),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ױ),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ײ),
					result  => q(),
					revisit => 2,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ּ),
					result  => q(̇),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ׁ),
					result  => q(̌),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ׂ),
					result  => q(̂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ֲ‎),
					result  => q(à),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ָ‎),
					result  => q(á),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ֱ‎),
					result  => q(è),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ֵ‎),
					result  => q(é),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ְ‎),
					result  => q(ĕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‎ֹ‎),
					result  => q(ò),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ִ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ֻ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ַ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ֶ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ֳ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ֿ),
					result  => q(̄),
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
