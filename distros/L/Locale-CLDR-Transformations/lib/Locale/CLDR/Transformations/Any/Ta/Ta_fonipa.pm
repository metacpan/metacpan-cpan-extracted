package Locale::CLDR::Transformations::Any::Ta::Ta_fonipa;
# This file auto generated from Data\common\transforms\ta-ta_FONIPA.xml
#	on Sun  3 Feb  1:37:17 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(‌),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‍),
					result  => q(),
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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q([^[ா-ூெ-ைொ-ௌ]்]),
					replace => q(([கஙசஜஞடணதந-பம-ஹ])),
					result  => q($1a),
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
					replace => q(ஃப),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஃ),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(அ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஆ),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(இ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஈ),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(உ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஊ),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(எ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஏ),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஐ),
					result  => q(aɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஒ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஓ),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஔ),
					result  => q(aʊ̯),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(க),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(க),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ங),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(ச),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ச்ச),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q([ʈr]),
					after   => q(),
					replace => q(ச),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ச),
					result  => q(s\u02BC),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஜ),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஞ),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(ட),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ட),
					result  => q(ʈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ண),
					result  => q(ɳ),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(த),
					result  => q(d̪),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(த),
					result  => q(t̪),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ந),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ன),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(ப),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ப),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ம),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ய),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ர),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ற்ற),
					result  => q(tʳ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(்),
					replace => q(ற),
					result  => q(tʳ),
					revisit => 0,
				},
				{
					before  => q([ŋɲɳnm]),
					after   => q(),
					replace => q(ற),
					result  => q(tʳ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ற),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ல),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ள),
					result  => q(ɭ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ழ),
					result  => q(ɻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(வ),
					result  => q(ʋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஶ),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஷ),
					result  => q(ʂ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(ர),
					replace => q(ஸ்),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஸ),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ஹ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ா),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ி),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ீ),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ு),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ூ),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ெ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ே),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ை),
					result  => q(aɪ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ொ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ோ),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ௌ),
					result  => q(aʊ̯),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(்),
					result  => q(),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
