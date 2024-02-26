package Locale::CLDR::Transformations::Any::Es::Es_fonipa;
# This file auto generated from Data\common\transforms\es-es_FONIPA.xml
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
					before  => q([-\ $]),
					after   => q(),
					replace => q(ct),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(cz),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(gn),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(mn),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(ps),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(pt),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(x),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q([-\ $]),
					after   => q(),
					replace => q(i),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q([bβdðfgɣʝklʎmnŋɲθprɾstʧx]),
					after   => q([aáeéoóuú]),
					replace => q(i),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q([aeo]),
					after   => q([^aáeéoóuú]),
					replace => q(i),
					result  => q(i̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aáeéoóuú]),
					replace => q(i),
					result  => q(ʝ),
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
					before  => q([aeo]),
					after   => q([^aáeéiíoóuú]),
					replace => q(y),
					result  => q(i̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aáeéiíoóuú]),
					replace => q(y),
					result  => q(ʝ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q([aeo]),
					after   => q([^aáeéiíoó]),
					replace => q(u),
					result  => q(u̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aáeéiíoó]),
					replace => q(u),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([eéií]),
					replace => q(ü),
					result  => q(w),
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
					replace => q(ü),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([aá]),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([eé]),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(í),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([oó]),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ú),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(β),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(cch),
					result  => q(ʧ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(ʧ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^eéií]),
					replace => q(cc),
					result  => q(k),
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
					result  => q(ð),
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
					after   => q([eéiíy]),
					replace => q(gu),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([eéiíy]),
					replace => q(g),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aáeéoóuú]),
					replace => q(hi),
					result  => q(ʝ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(\'),
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
					replace => q(ll),
					result  => q(ʎ),
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
					replace => q(n),
					result  => q(n),
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
					before  => q([-\ lns$]),
					after   => q(),
					replace => q(r),
					result  => q(r),
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
					replace => q(ss),
					result  => q(s),
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
					replace => q(tx),
					result  => q(ʧ),
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
					replace => q(v),
					result  => q(β),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(\'w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(h?[aáeéiíoóuú$]),
					replace => q(x),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^aáeéiíoóuú$]),
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
					replace => q(z),
					result  => q(θ),
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
					replace => q([-\ ]),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q([mnɲŋ$]),
					after   => q(),
					replace => q(β),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q([mnɲŋlʎ$]),
					after   => q(),
					replace => q(ð),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q([mnɲŋ$]),
					after   => q(),
					replace => q(ɣ),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([gɣk]),
					replace => q(n),
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
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
