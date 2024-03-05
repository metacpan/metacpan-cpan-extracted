package Locale::CLDR::Transformations::Any::Tlh::Tlh_fonipa;
# This file auto generated from Data\common\transforms\tlh-tlh_FONIPA.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(tlh),
					result  => q(t͡ɬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(aw),
					result  => q(aʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ew),
					result  => q(ɛʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Iw),
					result  => q(ɪʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ay),
					result  => q(aɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ey),
					result  => q(eɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Iy),
					result  => q(ɪː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oy),
					result  => q(oɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uy),
					result  => q(uɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gh),
					result  => q(ɣ),
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
					replace => q(p),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(q),
					result  => q(qʰ),
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
					replace => q(\'),
					result  => q(ʔ),
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
					replace => q(D),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Q),
					result  => q(q͡χ),
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
					replace => q(S),
					result  => q(ʂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(H),
					result  => q(x),
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
					replace => q(m),
					result  => q(m),
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
					replace => q(r),
					result  => q(r),
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
					replace => q(l),
					result  => q(l),
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
					replace => q(a),
					result  => q(ɑ),
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
					replace => q(I),
					result  => q(ɪ),
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
					replace => q(u),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\-),
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
