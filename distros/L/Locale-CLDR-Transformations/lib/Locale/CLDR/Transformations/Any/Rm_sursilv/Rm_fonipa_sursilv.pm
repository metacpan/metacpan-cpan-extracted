package Locale::CLDR::Transformations::Any::Rm_sursilv::Rm_fonipa_sursilv;
# This file auto generated from Data\common\transforms\rm_SURSILV-rm_FONIPA_SURSILV.xml
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
					replace => q(ai),
					result  => q(aɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(au),
					result  => q(aʊ̯),
					revisit => 0,
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
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([ei]),
					replace => q(c),
					result  => q(t͡s),
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
					replace => q(ei),
					result  => q(ɛɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(eu),
					result  => q(ɛʊ̯),
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
					replace => q(é),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(è),
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
					replace => q(ge),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gh),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gi),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aeou]),
					replace => q(gl),
					result  => q(ɡl),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gl),
					result  => q(ʎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gn),
					result  => q(ɲ),
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
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(iau),
					result  => q(ɪa̯ʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ia),
					result  => q(ɪa̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ie),
					result  => q(ɪɛ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(iu),
					result  => q(ɪʊ̯),
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
					replace => q(o),
					result  => q(ɔ),
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
					replace => q(q),
					result  => q(k),
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
					after   => q([aeiou]),
					replace => q(sch),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(sch),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([cptnm]),
					replace => q(s),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([gbdv]),
					replace => q(s),
					result  => q(ʒ),
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
					replace => q(tg),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tsch),
					result  => q(t͡ʃ),
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
					replace => q(uau),
					result  => q(ʊa̯ʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ua),
					result  => q(ʊa̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uei),
					result  => q(ʊɛ̯ɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ue),
					result  => q(ʊɛ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uo),
					result  => q(ʊɔ̯),
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
					result  => q(v),
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
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(t͡s),
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
					replace => q(mm+),
					result  => q(mː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nn+),
					result  => q(nː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɲɲ+),
					result  => q(ɲː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pp+),
					result  => q(pː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(bb+),
					result  => q(bː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tt+),
					result  => q(tː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dd+),
					result  => q(dː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(cc+),
					result  => q(cː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɟɟ+),
					result  => q(ɟː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kk+),
					result  => q(kː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɡɡ+),
					result  => q(ɡː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ff+),
					result  => q(fː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(vv+),
					result  => q(vː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ss+),
					result  => q(sː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(zz+),
					result  => q(zː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʃʃ+),
					result  => q(ʃː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʒʒ+),
					result  => q(ʒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(rr+),
					result  => q(rː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ll+),
					result  => q(lː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(jj+),
					result  => q(jː),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
