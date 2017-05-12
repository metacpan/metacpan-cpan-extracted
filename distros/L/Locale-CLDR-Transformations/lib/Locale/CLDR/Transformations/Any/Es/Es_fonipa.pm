package Locale::CLDR::Transformations::Any::Es::Es_fonipa;
# This file auto generated from Data\common\transforms\es-es_FONIPA.xml
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
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:ct)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:cz)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:gn)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:mn)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:ps)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:pt)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:x)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q((?^u:[-\ $])),
					after   => q(),
					replace => q((?^u:i)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q((?^u:[bβdðfgɣʝklʎmnŋɲθprɾstʧx])),
					after   => q((?^u:[aáeéoóuú])),
					replace => q((?^u:i)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q((?^u:[aeo])),
					after   => q((?^u:[^aáeéoóuú])),
					replace => q((?^u:i)),
					result  => q(i̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aáeéoóuú])),
					replace => q((?^u:i)),
					result  => q(ʝ),
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
					before  => q((?^u:[aeo])),
					after   => q((?^u:[^aáeéiíoóuú])),
					replace => q((?^u:y)),
					result  => q(i̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aáeéiíoóuú])),
					replace => q((?^u:y)),
					result  => q(ʝ),
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
					before  => q((?^u:[aeo])),
					after   => q((?^u:[^aáeéiíoó])),
					replace => q((?^u:u)),
					result  => q(u̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aáeéiíoó])),
					replace => q((?^u:u)),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[eéií])),
					replace => q((?^u:ü)),
					result  => q(w),
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
					replace => q((?^u:ü)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[aá])),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[eé])),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:í)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[oó])),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ú)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:b)),
					result  => q(β),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:cch)),
					result  => q(ʧ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ch)),
					result  => q(ʧ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^eéií])),
					replace => q((?^u:cc)),
					result  => q(k),
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
					result  => q(ð),
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
					after   => q((?^u:[eéiíy])),
					replace => q((?^u:gu)),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[eéiíy])),
					replace => q((?^u:g)),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:g)),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[aáeéoóuú])),
					replace => q((?^u:hi)),
					result  => q(ʝ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:h)),
					result  => q(\'),
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
					replace => q((?^u:ll)),
					result  => q(ʎ),
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
					replace => q((?^u:ñ)),
					result  => q(ɲ),
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
					before  => q((?^u:[-\ lns$])),
					after   => q(),
					replace => q((?^u:r)),
					result  => q(r),
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
					replace => q((?^u:ss)),
					result  => q(s),
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
					replace => q((?^u:tx)),
					result  => q(ʧ),
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
					replace => q((?^u:v)),
					result  => q(β),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:w)),
					result  => q(\'w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:h?[aáeéiíoóuú$])),
					replace => q((?^u:x)),
					result  => q(ks),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^aáeéiíoóuú$])),
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
					replace => q((?^u:z)),
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
					replace => q((?^u:[-\ ])),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q((?^u:[mnɲŋ$])),
					after   => q(),
					replace => q((?^u:β)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q((?^u:[mnɲŋlʎ$])),
					after   => q(),
					replace => q((?^u:ð)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q((?^u:[mnɲŋ$])),
					after   => q(),
					replace => q((?^u:ɣ)),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[gɣk])),
					replace => q((?^u:n)),
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
