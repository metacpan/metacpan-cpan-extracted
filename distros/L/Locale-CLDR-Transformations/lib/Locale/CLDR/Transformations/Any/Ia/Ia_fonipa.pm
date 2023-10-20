package Locale::CLDR::Transformations::Any::Ia::Ia_fonipa;
# This file auto generated from Data\common\transforms\ia-ia_FONIPA.xml
#	on Fri 13 Oct  9:03:50 am GMT

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
					replace => q(ai),
					result  => q(ai̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(au),
					result  => q(au̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ei),
					result  => q(ei̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(eu),
					result  => q(eu̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oi),
					result  => q(oi̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([$]),
					replace => q(age),
					result  => q(ad͡ʒe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aeiouy]),
					replace => q(agi),
					result  => q(ad͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(agi),
					result  => q(ad͡ʒi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aeiouy]),
					replace => q(egi),
					result  => q(ed͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(egi),
					result  => q(ed͡ʒi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gg),
					result  => q(ɡ),
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
					after   => q([gkqx]),
					replace => q(n),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nn),
					result  => q(n),
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
					replace => q(a),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(bb),
					result  => q(b),
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
					replace => q(cc),
					result  => q(k),
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
					replace => q(ch),
					result  => q(k),
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
					replace => q(dd),
					result  => q(d),
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
					replace => q(ff),
					result  => q(f),
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
					replace => q(h),
					result  => q(),
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
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kk),
					result  => q(k),
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
					result  => q(l),
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
					replace => q(mm),
					result  => q(m),
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
					replace => q(o),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ph),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pp),
					result  => q(p),
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
					replace => q(que),
					result  => q(ke),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(qu),
					result  => q(kw),
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
					result  => q(ɾ),
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
					replace => q(sh),
					result  => q(ʃ),
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
					before  => q([^s]),
					after   => q([aeiouy]),
					replace => q(ti),
					result  => q(t͡sj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tt),
					result  => q(t),
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
