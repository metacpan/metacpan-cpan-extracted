package Locale::CLDR::Transformations::Any::Cy::Cy_fonipa;
# This file auto generated from Data\common\transforms\cy-fonipa-t-cy.xml
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
					replace => q([’[:P:]]),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(v),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(x),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(s),
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
					replace => q(ngh),
					result  => q(ŋ̊),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(χ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dd),
					result  => q(ð),
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
					replace => q(ll),
					result  => q(ɬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(mh),
					result  => q(m̥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nh),
					result  => q(n̥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ng),
					result  => q(ŋ),
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
					replace => q(rh),
					result  => q(r̥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(th),
					result  => q(θ),
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
					replace => q(f),
					result  => q(v),
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
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j),
					result  => q(d͡ʒ),
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
					replace => q(p),
					result  => q(p),
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
					after   => q(),
					replace => q(s),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(t),
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
					after   => q([aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(si),
					result  => q(ʃ),
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
					after   => q([aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(i),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(w),
					result  => q(W),
					revisit => 0,
				},
				{
					before  => q([ɡŋ]),
					after   => q([rl][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(w),
					result  => q(W),
					revisit => 0,
				},
				{
					before  => q(^),
					after   => q([rl][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(w),
					result  => q(W),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ẃ),
					result  => q(w),
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
					after   => q([$]),
					replace => q(([aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]++[aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]+*)),
					result  => q(ˈ$1),
					revisit => 0,
				},
				{
					before  => q([$]*),
					after   => q([$]),
					replace => q(([aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]+*)),
					result  => q(ˈ$1),
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
					replace => q(ˈ+),
					result  => q(ˈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(*[$]),
					replace => q(yw),
					result  => q(ɨu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(yw),
					result  => q(əu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(*[$]),
					replace => q(y),
					result  => q(ɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(ə),
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
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(ɨu),
					result  => q(ɨːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(aw),
					result  => q(ɑːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(ew),
					result  => q(eːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(oe),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(ou),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(wy),
					result  => q(uːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(ɨu),
					result  => q(ɨːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(aw),
					result  => q(ɑːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(ew),
					result  => q(eːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(oe),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(ou),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(wy),
					result  => q(uːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(ɨu),
					result  => q(ɨːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(aw),
					result  => q(ɑːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(ew),
					result  => q(eːu),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(oe),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(ou),
					result  => q(ɔːɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(wy),
					result  => q(uːɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ae),
					result  => q(ɑːɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ai),
					result  => q(ai),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(aw),
					result  => q(au),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ei),
					result  => q(əi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(eu),
					result  => q(əɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ew),
					result  => q(ɛu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ey),
					result  => q(əɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(iw),
					result  => q(ɪu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oe),
					result  => q(ɔɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oi),
					result  => q(ɔi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ou),
					result  => q(ɔɨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uw),
					result  => q(ɨu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(wy),
					result  => q(ʊɨ),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(ɨ),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(a),
					result  => q(ɑː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(e),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(i),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(o),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(u),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q(s?[$]),
					replace => q(w),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(ɨ),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(a),
					result  => q(ɑː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(e),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(i),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(o),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(u),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][$]),
					replace => q(w),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(ɨ),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(a),
					result  => q(ɑː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(e),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(i),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(o),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(u),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(ˈ),
					after   => q([bχdðɡvfθ][aeiouwyâêîôûŵŷɑɨəɛɪɔʊ]),
					replace => q(w),
					result  => q(uː),
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
					replace => q(e),
					result  => q(ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(ɪ),
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
					replace => q(u),
					result  => q(ɨ̞),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(ʊ),
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
					replace => q(W),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(â),
					result  => q(ɑː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ê),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(î),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ô),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(û),
					result  => q(ɨː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ŵ),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ŷ),
					result  => q(ɨː),
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
					after   => q(w][lɬr\N{U+72.325}]?j?w?)ˈ),
					replace => q(([),
					result  => q(ˈ$1),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
