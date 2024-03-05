package Locale::CLDR::Transformations::Any::Hy_arevmda::Hy_arevmda_fonipa;
# This file auto generated from Data\common\transforms\hy_AREVMDA-hy_AREVMDA_FONIPA.xml
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
					replace => q(\'),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(մ),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ն),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(պ),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(տ),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(կ),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(բ),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(դ),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(գ),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(փ),
					result  => q(pʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(թիւն),
					result  => q(tʰjun),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(թ),
					result  => q(tʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ք),
					result  => q(kʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ծ),
					result  => q(d͡z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ճ),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ձ),
					result  => q(t͡sʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ջ),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ց),
					result  => q(t͡sʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(չ),
					result  => q(t͡ʃʰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ֆ),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ս),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(շ),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(խ),
					result  => q(χ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(հ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(վ),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ւ),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(զ),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ժ),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ղ),
					result  => q(ʁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(լ),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(յ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(յ),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ռ),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ր),
					result  => q(ɾ),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(իւ),
					result  => q(ju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(իու),
					result  => q(iju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(իւ),
					result  => q(ʏ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(իայ),
					result  => q(ja),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(իա),
					result  => q(ijɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ի),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(եայ),
					result  => q(jɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(եա),
					result  => q(jɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(եօ),
					result  => q(jo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ով),
					result  => q(ov),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(ոյ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([աեէըիոևօւ]),
					replace => q(ոյ),
					result  => q(oj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ոյ),
					result  => q(uj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([աեէըիոևօւ]),
					replace => q(ու),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ու),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(ո),
					result  => q(vo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ո),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q([աեէըիոևօւ]),
					after   => q(),
					replace => q(ե),
					result  => q(jɛ),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(ե),
					result  => q(jɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ե),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q([^ \p{L} \p{M} \p{N}]),
					after   => q(),
					replace => q(և),
					result  => q(jɛv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(և),
					result  => q(ɛv),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(էայ),
					result  => q(ɛjɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(էա),
					result  => q(ɛjɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(էի),
					result  => q(ɛji),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(էու),
					result  => q(ɛju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(էօ),
					result  => q(œ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(էյ),
					result  => q(ej),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(է),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ը),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(օ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^ \p{L} \p{M} \p{N}]),
					replace => q(այ),
					result  => q(ɑ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ա),
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
					replace => q(jj),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nɡ),
					result  => q(ŋɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nk),
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
