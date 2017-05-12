package Locale::CLDR::Transformations::Any::Rm_sursilv::Rm_fonipa_sursilv;
# This file auto generated from Data\common\transforms\rm_SURSILV-rm_FONIPA_SURSILV.xml
#	on Fri 29 Apr  6:48:49 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
					replace => q((?^u:ai)),
					result  => q(aɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:au)),
					result  => q(aʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:a)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:b)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[ei])),
					replace => q((?^u:c)),
					result  => q(t͡s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:c)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:d)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ei)),
					result  => q(ɛɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:eu)),
					result  => q(ɛʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:e)),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:é)),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:è)),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:f)),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ge)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gh)),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gi)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aeou])),
					replace => q((?^u:gl)),
					result  => q(ɡl),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gl)),
					result  => q(ʎ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gn)),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:g)),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:h)),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:iau)),
					result  => q(ɪa̯ʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ia)),
					result  => q(ɪa̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ie)),
					result  => q(ɪɛ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:iu)),
					result  => q(ɪʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:i)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:j)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:k)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:l)),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:m)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:n)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:o)),
					result  => q(ɔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:p)),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:q)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:r)),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aeiou])),
					replace => q((?^u:sch)),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:sch)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[cptnm])),
					replace => q((?^u:s)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[gbdv])),
					replace => q((?^u:s)),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:s)),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tg)),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tsch)),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:t)),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:uau)),
					result  => q(ʊa̯ʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ua)),
					result  => q(ʊa̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:uei)),
					result  => q(ʊɛ̯ɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ue)),
					result  => q(ʊɛ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:uo)),
					result  => q(ʊɔ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:u)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:v)),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:w)),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:x)),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:y)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:z)),
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
					replace => q((?^u:mm+)),
					result  => q(mː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:nn+)),
					result  => q(nː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɲɲ+)),
					result  => q(ɲː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:pp+)),
					result  => q(pː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:bb+)),
					result  => q(bː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tt+)),
					result  => q(tː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:dd+)),
					result  => q(dː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:cc+)),
					result  => q(cː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɟɟ+)),
					result  => q(ɟː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kk+)),
					result  => q(kː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɡɡ+)),
					result  => q(ɡː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ff+)),
					result  => q(fː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:vv+)),
					result  => q(vː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ss+)),
					result  => q(sː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:zz+)),
					result  => q(zː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʃʃ+)),
					result  => q(ʃː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʒʒ+)),
					result  => q(ʒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:rr+)),
					result  => q(rː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ll+)),
					result  => q(lː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:jj+)),
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
