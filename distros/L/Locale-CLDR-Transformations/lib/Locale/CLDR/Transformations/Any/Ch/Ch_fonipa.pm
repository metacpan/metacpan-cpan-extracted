package Locale::CLDR::Transformations::Any::Ch::Ch_fonipa;
# This file auto generated from Data\common\transforms\ch-ch_FONIPA.xml
#	on Fri 29 Apr  6:48:47 pm GMT

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
					replace => q((?^u:\')),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:’)),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:a)),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:å)),
					result  => q(ɑ),
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
					after   => q(),
					replace => q((?^u:ch)),
					result  => q(t͡s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[eéií])),
					replace => q((?^u:c)),
					result  => q(θ),
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
					replace => q((?^u:e)),
					result  => q(e),
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
					replace => q((?^u:gu)),
					result  => q(ɡʷ),
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
					result  => q(h),
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
					result  => q(x),
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
					replace => q((?^u:ng)),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ñ)),
					result  => q(ɲ),
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
					result  => q(o),
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
					after   => q((?^u:[eéiíy])),
					replace => q((?^u:qu)),
					result  => q(k),
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
					replace => q((?^u:rr)),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:r)),
					result  => q(ɾ),
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
					replace => q((?^u:t)),
					result  => q(t),
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
					result  => q(β),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:w)),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:h?[aáåeéiíoóuú$])),
					replace => q((?^u:x)),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^aáåeéiíoóuú$])),
					replace => q((?^u:x)),
					result  => q(s),
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
					result  => q(d͡z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:\-)),
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
					replace => q((?^u:bb)),
					result  => q(bː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:dd)),
					result  => q(dː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ff)),
					result  => q(fː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ɡɡ)),
					result  => q(ɡː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:hh)),
					result  => q(hː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kk)),
					result  => q(kː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ll)),
					result  => q(lː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:mm)),
					result  => q(mː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:nn)),
					result  => q(nː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:pp)),
					result  => q(pː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:rr)),
					result  => q(rː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ss)),
					result  => q(sː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tt)),
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
