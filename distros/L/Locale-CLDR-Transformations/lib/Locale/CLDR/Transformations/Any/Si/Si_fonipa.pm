package Locale::CLDR::Transformations::Any::Si::Si_fonipa;
# This file auto generated from Data\common\transforms\si-si_FONIPA.xml
#	on Fri 13 Oct  9:03:51 am GMT

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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q([ක-ෆ]්(‍)?),
					after   => q(),
					replace => q(ය්‍ය),
					result  => q(ය),
					revisit => 0,
				},
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
					to => q(Null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q([^්-ෟෲෳ]),
					replace => q(([ක-ෆ])),
					result  => q($1ə),
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
					replace => q([Ff]ප),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([Zz]ස),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ං),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඃ([ක-ෆ])),
					result  => q(),
					revisit => 10,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඃ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(අ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ආ),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඇ),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඈ),
					result  => q(æː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඉ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඊ),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(උ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඌ),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඍ),
					result  => q(ri),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඎ),
					result  => q(ruː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඏ),
					result  => q(ilu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඐ),
					result  => q(iluː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(එ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඒ),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඓ),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඔ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඕ),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඖ),
					result  => q(aw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ක),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඛ),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ග),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඝ),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඞ),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඟ),
					result  => q(ᵑɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ච),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඡ),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ජ),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඣ),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඤ),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඥ),
					result  => q(kɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඦ),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ට),
					result  => q(ʈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඨ),
					result  => q(ʈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඩ),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඪ),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ණ),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඬ),
					result  => q(ⁿɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ත),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ථ),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ද),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ධ),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(න),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඳ),
					result  => q(ⁿd),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ප),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඵ),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(බ),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(භ),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ම),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ඹ),
					result  => q(ᵐb),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ය),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ර),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ල),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ව),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ශ),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෂ),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ස),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(හ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ළ),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෆ),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(්),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ා),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ැ),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෑ),
					result  => q(æː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ි),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ී),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ු),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ූ),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෘ),
					result  => q(ru),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෙ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ේ),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෛ),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ො),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෝ),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෞ),
					result  => q(aw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෟ),
					result  => q(lu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෲ),
					result  => q(ruː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ෳ),
					result  => q(luː),
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
					before  => q(\p{^L}sv),
					after   => q(),
					replace => q(ə),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q([:^L:]k),
					after   => q(r),
					replace => q(ə),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(\p{^L}[k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					after   => q(\p{^L}),
					replace => q(ə),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(\p{^L}[k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f][k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					after   => q(),
					replace => q(ə),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(\p{^L}[k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					after   => q(),
					replace => q(ə),
					result  => q(a),
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
					before  => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]r),
					after   => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					replace => q(ə),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]r),
					after   => q(h),
					replace => q(a),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]r),
					after   => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					replace => q(a),
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
					before  => q([aeæoə]h),
					after   => q(),
					replace => q(ə),
					result  => q(a),
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
					after   => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f][k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]),
					replace => q(ə),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([rbɖʈ]\p{^L}),
					replace => q(ə),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([k ɡ ŋ \N{U+1D51.261} c ɟ ɲ ʈ ɖ \N{U+207F.256} t d n \N{U+207F.64} p b m \N{U+1D50.62} j r l w ʃ s z h f]\p{^L}),
					replace => q(ə),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(ji\p{^L}),
					replace => q(ə),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(k),
					after   => q([rl]u),
					replace => q(ə),
					result  => q(a),
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
					before  => q([:^L:]k),
					after   => q(l[aeo]ːj),
					replace => q(a),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q([:^L:]k),
					after   => q(le[mh][ui]),
					replace => q(a),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q([:^L:]k),
					after   => q(h[ui]),
					replace => q(alə),
					result  => q(əle),
					revisit => 0,
				},
				{
					before  => q([:^L:]k),
					after   => q(lə),
					replace => q(a),
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
					before  => q(),
					after   => q(),
					replace => q(www+),
					result  => q(ww),
					revisit => 0,
				},
				{
					before  => q([i\N{U+69.2D0}e\N{U+65.2D0}æ\N{U+E6.2D0}o\N{U+6F.2D0}a\N{U+61.2D0}]),
					after   => q(),
					replace => q(wu),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(əji),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(iji),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q([u\N{U+75.2D0}e\N{U+65.2D0}æ\N{U+E6.2D0}o\N{U+6F.2D0}a\N{U+61.2D0}]),
					after   => q(),
					replace => q(ji),
					result  => q(j),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
