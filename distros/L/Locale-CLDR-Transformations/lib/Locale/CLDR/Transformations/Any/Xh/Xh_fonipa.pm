package Locale::CLDR::Transformations::Any::Xh::Xh_fonipa;
# This file auto generated from Data/common/transforms/xh-xh_FONIPA.xml
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
					replace => q(nyh),
					result  => q(ɲʰ),
					revisit => 0,
				},
				{
					before  => q(n),
					after   => q(),
					replace => q(tsh),
					result  => q(t͡ʃʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tsh),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tyh),
					result  => q(cʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(bh),
					result  => q(bʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(ǀʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dl),
					result  => q(ɮ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dy),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gc),
					result  => q(ɡ͡ǀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gq),
					result  => q(ɡ͡ǃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gr),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gx),
					result  => q(ɡ͡ǁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(hl),
					result  => q(ɬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kh),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kr),
					result  => q(k͡x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^l]),
					replace => q(mh),
					result  => q(mʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nh),
					result  => q(nʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ny),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ph),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(qh),
					result  => q(ǃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(sh),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(th),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tl),
					result  => q(t͡ɬʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ts),
					result  => q(t͡sʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ty),
					result  => q(cʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(xh),
					result  => q(ǁʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(aa),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ee),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ii),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kc),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kq),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(mm),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oo),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(rh),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uu),
					result  => q(),
					revisit => 1,
				},
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
					replace => q(b),
					result  => q(ɓ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(c),
					result  => q(ǀ),
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
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(kʼ),
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
					after   => q(g),
					replace => q(n),
					result  => q(ŋ),
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
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(p),
					result  => q(pʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(q),
					result  => q(ǃ),
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
					replace => q(s),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(tʼ),
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
					result  => q(v),
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
					replace => q(x),
					result  => q(ǁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(z),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
