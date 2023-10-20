package Locale::CLDR::Transformations::Any::Ch::Ch_fonipa;
# This file auto generated from Data\common\transforms\ch-ch_FONIPA.xml
#	on Fri 13 Oct  9:03:49 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
					to => q(Lower),
				},
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
					replace => q(\'),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(’),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(å),
					result  => q(ɑ),
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
					result  => q(t͡s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([eéií]),
					replace => q(c),
					result  => q(θ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c),
					result  => q(k),
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
					replace => q(e),
					result  => q(e),
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
					replace => q(gu),
					result  => q(ɡʷ),
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
					result  => q(x),
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
					replace => q(l),
					result  => q(l),
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
					replace => q(ng),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ñ),
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
					replace => q(o),
					result  => q(o),
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
					after   => q([eéiíy]),
					replace => q(qu),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(q),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(rr),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(ɾ),
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
					replace => q(v),
					result  => q(β),
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
					after   => q(h?[aáåeéiíoóuú$]),
					replace => q(x),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^aáåeéiíoóuú$]),
					replace => q(x),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(x),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(d͡z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\-),
					result  => q(\.),
					revisit => 0,
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
					replace => q(bb),
					result  => q(bː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dd),
					result  => q(dː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ff),
					result  => q(fː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɡɡ),
					result  => q(ɡː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(hh),
					result  => q(hː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kk),
					result  => q(kː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ll),
					result  => q(lː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(mm),
					result  => q(mː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nn),
					result  => q(nː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pp),
					result  => q(pː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(rr),
					result  => q(rː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ss),
					result  => q(sː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tt),
					result  => q(tː),
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
