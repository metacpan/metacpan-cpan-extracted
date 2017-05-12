package Locale::CLDR::Transformations::Any::Latn::Hebr;
# This file auto generated from Data\common\transforms\Hebrew-Latin.xml
#	on Fri 29 Apr  6:48:42 pm GMT

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
					to => q(nfd),
				},
				{
					from => q(Any),
					to => q(lower),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:x)),
					result  => q(כס),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:v)),
					result  => q(ו),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:j)),
					result  => q(ז),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:f)),
					result  => q(ף),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:f)),
					result  => q(פ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:c)),
					result  => q(ק),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:̄)),
					result  => q(ֿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:o)),
					result  => q(ֳ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:e)),
					result  => q(ֶ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:a)),
					result  => q(ַ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:u)),
					result  => q(ֻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:i)),
					result  => q(ִ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:o([^ \p{ccc = 0} \p{ccc = 230}] *)̀)),
					result  => q(‎ֹ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:e([^ \p{ccc = 0} \p{ccc = 230}] *)̆)),
					result  => q(‎ְ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:e([^ \p{ccc = 0} \p{ccc = 230}] *)́)),
					result  => q(‎ֵ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:e([^ \p{ccc = 0} \p{ccc = 230}] *)̀)),
					result  => q(‎ֱ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:a([^ \p{ccc = 0} \p{ccc = 230}] *)́)),
					result  => q(‎ָ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:a([^ \p{ccc = 0} \p{ccc = 230}] *)̀)),
					result  => q(‎ֲ‎$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:̂)),
					result  => q(ׂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:̌)),
					result  => q(ׁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:̇)),
					result  => q(ּ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:r)),
					result  => q(ר),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:q)),
					result  => q(ק),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:p)),
					result  => q(ף),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:p)),
					result  => q(פ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʻ)),
					result  => q(ע),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:s)),
					result  => q(ס),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:n)),
					result  => q(ן),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:n)),
					result  => q(נ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:m)),
					result  => q(ם),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:m)),
					result  => q(מ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:l)),
					result  => q(ל),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:k)),
					result  => q(ך),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:k)),
					result  => q(כ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:y)),
					result  => q(י),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:t)),
					result  => q(ט),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:z)),
					result  => q(ז),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:w)),
					result  => q(ו),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:h)),
					result  => q(ה),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:d)),
					result  => q(ד),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:g)),
					result  => q(ג),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:b)),
					result  => q(ב),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ʼ)),
					result  => q(א),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ţ)),
					result  => q(ת),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ş)),
					result  => q(ש),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ẕ)),
					result  => q(ץ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:\p{M} * \p{L})),
					replace => q((?^u:ẕ)),
					result  => q(צ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ẖ)),
					result  => q(ח),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(nfc),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
