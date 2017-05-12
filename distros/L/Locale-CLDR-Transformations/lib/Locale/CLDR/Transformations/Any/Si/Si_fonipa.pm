package Locale::CLDR::Transformations::Any::Si::Si_fonipa;
# This file auto generated from Data\common\transforms\si-si_FONIPA.xml
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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q((?^u:[ක-ෆ]්(‍)?)),
					after   => q(),
					replace => q((?^u:ය්‍ය)),
					result  => q(ය),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‌)),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:‍)),
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
					after   => q((?^u:[^්-ෟෲෳ])),
					replace => q((?^u:([ක-ෆ]))),
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
					replace => q((?^u:[Ff]ප)),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:[Zz]ස)),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ං)),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:o)),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඃ([ක-ෆ]))),
					result  => q(),
					revisit => 10,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඃ)),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:අ)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ආ)),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඇ)),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඈ)),
					result  => q(æː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඉ)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඊ)),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:උ)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඌ)),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඍ)),
					result  => q(ri),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඎ)),
					result  => q(ruː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඏ)),
					result  => q(ilu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඐ)),
					result  => q(iluː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:එ)),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඒ)),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඓ)),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඔ)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඕ)),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඖ)),
					result  => q(aw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ක)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඛ)),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ග)),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඝ)),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඞ)),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඟ)),
					result  => q(ᵑɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ච)),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඡ)),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ජ)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඣ)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඤ)),
					result  => q(ɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඥ)),
					result  => q(kɲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඦ)),
					result  => q(ɟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ට)),
					result  => q(ʈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඨ)),
					result  => q(ʈ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඩ)),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඪ)),
					result  => q(ɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ණ)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඬ)),
					result  => q(ⁿɖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ත)),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ථ)),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ද)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ධ)),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:න)),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඳ)),
					result  => q(ⁿd),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ප)),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඵ)),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:බ)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:භ)),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ම)),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ඹ)),
					result  => q(ᵐb),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ය)),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ර)),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ල)),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ව)),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ශ)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෂ)),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ස)),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:හ)),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ළ)),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෆ)),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:්)),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ා)),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ැ)),
					result  => q(æ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෑ)),
					result  => q(æː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ි)),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ී)),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ු)),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ූ)),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෘ)),
					result  => q(ru),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෙ)),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ේ)),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෛ)),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ො)),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෝ)),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෞ)),
					result  => q(aw),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෟ)),
					result  => q(lu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෲ)),
					result  => q(ruː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:ෳ)),
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
					before  => q((?^u:\p{^L}sv)),
					after   => q(),
					replace => q((?^u:ə)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}k)),
					after   => q((?^u:r)),
					replace => q((?^u:ə)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					after   => q((?^u:\p{^L})),
					replace => q((?^u:ə)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f][k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					after   => q(),
					replace => q((?^u:ə)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					after   => q(),
					replace => q((?^u:ə)),
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
					before  => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f]r)),
					after   => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					replace => q((?^u:ə)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f]r)),
					after   => q((?^u:h)),
					replace => q((?^u:a)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f]r)),
					after   => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					replace => q((?^u:a)),
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
					before  => q((?^u:[aeæoə]h)),
					after   => q(),
					replace => q((?^u:ə)),
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
					after   => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f][k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f])),
					replace => q((?^u:ə)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[rbɖʈ]\p{^L})),
					replace => q((?^u:ə)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:[k ɡ ŋ \{ ᵑɡ \} c ɟ ɲ ʈ ɖ \{ ⁿɖ \} t d n \{ ⁿd \} p b m \{ ᵐb \} j r l w ʃ s z h f]\p{^L})),
					replace => q((?^u:ə)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?^u:ji\p{^L})),
					replace => q((?^u:ə)),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q((?^u:k)),
					after   => q((?^u:[rl]u)),
					replace => q((?^u:ə)),
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
					before  => q((?^u:\p{^L}k)),
					after   => q((?^u:l[aeo]ːj)),
					replace => q((?^u:a)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}k)),
					after   => q((?^u:le[mh][ui])),
					replace => q((?^u:a)),
					result  => q(ə),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}k)),
					after   => q((?^u:h[ui])),
					replace => q((?^u:alə)),
					result  => q(əle),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{^L}k)),
					after   => q((?^u:lə)),
					replace => q((?^u:a)),
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
					replace => q((?^u:www+)),
					result  => q(ww),
					revisit => 0,
				},
				{
					before  => q((?^u:[i\{iː\}e\{eː\}æ\{æː\}o\{oː\}a\{aː\}])),
					after   => q(),
					replace => q((?^u:wu)),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:əji)),
					result  => q(aj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q((?^u:iji)),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q((?^u:[u\{uː\}e\{eː\}æ\{æː\}o\{oː\}a\{aː\}])),
					after   => q(),
					replace => q((?^u:ji)),
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
