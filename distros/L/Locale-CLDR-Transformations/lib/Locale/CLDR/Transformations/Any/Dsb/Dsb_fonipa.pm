package Locale::CLDR::Transformations::Any::Dsb::Dsb_fonipa;
# This file auto generated from Data\common\transforms\dsb-dsb_FONIPA.xml
#	on Sun  7 Oct 10:18:22 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
					to => q(NFC),
				},
				{
					from => q(Any),
					to => q(Lower),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b́),
					result  => q(bʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(bj),
					result  => q(bʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(č),
					result  => q(t\u0361ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ć),
					result  => q(t\u0361ɕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c),
					result  => q(t\u0361s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dź),
					result  => q(d\u0361ʑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ě),
					result  => q(iɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(f),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ł),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(l),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ḿ),
					result  => q(mʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(mj),
					result  => q(mʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(m),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ń),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(n),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ó),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ṕ),
					result  => q(pʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pj),
					result  => q(pʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(p),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ř),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ŕ),
					result  => q(rʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(š),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ś),
					result  => q(ɕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(u),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ẃ),
					result  => q(wʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(wj),
					result  => q(wʲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(ɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ž),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ź),
					result  => q(ʑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(z),
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
					after   => q([k]),
					replace => q(b),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([k]),
					replace => q(d),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʃt͡ɕ),
					result  => q(ɕt͡ɕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(b),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(d͡z),
					result  => q(t\u0361s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(d),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(ɡ),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(v),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(w),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(ʑ),
					result  => q(ɕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(z),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(ʒ),
					result  => q(ʃ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
