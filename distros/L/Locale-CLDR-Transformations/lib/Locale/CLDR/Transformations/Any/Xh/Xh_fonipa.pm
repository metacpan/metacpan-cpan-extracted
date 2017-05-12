package Locale::CLDR::Transformations::Any::Xh::Xh_fonipa;
# This file auto generated from Data\common\transforms\xh-xh_FONIPA.xml
#	on Fri 29 Apr  6:48:50 pm GMT

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
					replace => q((?^u:nyh)),
					result  => q(ɲʰ),
					revisit => 0,
				},
				{
					before  => q((?^u:n)),
					after   => q(),
					replace => q((?^u:tsh)),
					result  => q(t͡ʃʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tsh)),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tyh)),
					result  => q(cʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:bh)),
					result  => q(bʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ch)),
					result  => q(ǀʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:dl)),
					result  => q(ɮ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:dy)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gc)),
					result  => q(ɡ͡ǀ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gq)),
					result  => q(ɡ͡ǃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gr)),
					result  => q(ɣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:gx)),
					result  => q(ɡ͡ǁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:hl)),
					result  => q(ɬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kh)),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kr)),
					result  => q(k͡x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^l])),
					replace => q((?^u:mh)),
					result  => q(mʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:nh)),
					result  => q(nʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ny)),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ph)),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:qh)),
					result  => q(ǃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:sh)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:th)),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:tl)),
					result  => q(t͡ɬʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ts)),
					result  => q(t͡sʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ty)),
					result  => q(cʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:xh)),
					result  => q(ǁʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:aa)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ee)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ii)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kc)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:kq)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:mm)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:oo)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:rh)),
					result  => q(),
					revisit => 1,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:uu)),
					result  => q(),
					revisit => 1,
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
					result  => q(ɓ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:c)),
					result  => q(ǀ),
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
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:k)),
					result  => q(kʼ),
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
					after   => q((?^u:g)),
					replace => q((?^u:n)),
					result  => q(ŋ),
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
					result  => q(pʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:q)),
					result  => q(ǃ),
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
					after   => q(),
					replace => q((?^u:s)),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:t)),
					result  => q(tʼ),
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
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:x)),
					result  => q(ǁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:y)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:z)),
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
