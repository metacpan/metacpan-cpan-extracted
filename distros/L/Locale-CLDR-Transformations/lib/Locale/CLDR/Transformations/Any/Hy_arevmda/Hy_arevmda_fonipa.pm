package Locale::CLDR::Transformations::Any::Hy_arevmda::Hy_arevmda_fonipa;
# This file auto generated from Data\common\transforms\hy_AREVMDA-hy_AREVMDA_FONIPA.xml
#	on Fri 29 Apr  6:48:48 pm GMT

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
					replace => q((?^u:\')),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:մ)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ն)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:պ)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:տ)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:կ)),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:բ)),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:դ)),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:գ)),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:փ)),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:թիւն)),
					result  => q(tʰjun),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:թ)),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ք)),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ծ)),
					result  => q(d͡z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ճ)),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ձ)),
					result  => q(t͡sʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ջ)),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ց)),
					result  => q(t͡sʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:չ)),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ֆ)),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ս)),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:շ)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:խ)),
					result  => q(χ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:հ)),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:վ)),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ւ)),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:զ)),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ժ)),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ղ)),
					result  => q(ʁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:լ)),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:յ)),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:յ)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ռ)),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ր)),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:իւ)),
					result  => q(ju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:իու)),
					result  => q(iju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:իւ)),
					result  => q(ʏ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:իայ)),
					result  => q(ja),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:իա)),
					result  => q(ijɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ի)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:եայ)),
					result  => q(jɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:եա)),
					result  => q(jɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:եօ)),
					result  => q(jo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ով)),
					result  => q(ov),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:ոյ)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[աեէըիոևօւ])),
					replace => q((?^u:ոյ)),
					result  => q(oj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ոյ)),
					result  => q(uj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[աեէըիոևօւ])),
					replace => q((?^u:ու)),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ու)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ո)),
					result  => q(vo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ո)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q((?^u:[աեէըիոևօւ])),
					after   => q(),
					replace => q((?^u:ե)),
					result  => q(jɛ),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:ե)),
					result  => q(jɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ե)),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}])),
					after   => q(),
					replace => q((?^u:և)),
					result  => q(jɛv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:և)),
					result  => q(ɛv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:էայ)),
					result  => q(ɛjɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:էա)),
					result  => q(ɛjɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:էի)),
					result  => q(ɛji),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:էու)),
					result  => q(ɛju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:էօ)),
					result  => q(œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:էյ)),
					result  => q(ej),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:է)),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ը)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:օ)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[^ \p{L} \p{M} \p{N}])),
					replace => q((?^u:այ)),
					result  => q(ɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ա)),
					result  => q(ɑ),
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
					replace => q((?^u:jj)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:nɡ)),
					result  => q(ŋɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:nk)),
					result  => q(ŋk),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
