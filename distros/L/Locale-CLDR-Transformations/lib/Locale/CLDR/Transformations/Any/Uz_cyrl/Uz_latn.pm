package Locale::CLDR::Transformations::Any::Uz_cyrl::Uz_latn;
# This file auto generated from Data\common\transforms\uz_Cyrl-uz_Latn.xml
#	on Fri 17 Jan 12:03:31 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.46.0');

use v5.12.0;
use mro 'c3';
use utf8;
use feature 'unicode_strings';
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
					to => q(NFD),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(ў),
					result  => q(oʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ў),
					result  => q(Oʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ғ),
					result  => q(gʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ғ),
					result  => q(Gʻ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ш),
					result  => q(sh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Ш),
					result  => q(Sh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ш),
					result  => q(SH),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ч),
					result  => q(ch),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Ч),
					result  => q(Ch),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ч),
					result  => q(CH),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ъ),
					result  => q(ʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ъ),
					result  => q(ʼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ё),
					result  => q(yo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Ё),
					result  => q(Yo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ё),
					result  => q(YO),
					revisit => 0,
				},
				{
					before  => q(\p{^L}),
					after   => q(),
					replace => q(е),
					result  => q(ye),
					revisit => 0,
				},
				{
					before  => q(\p{^L}),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Е),
					result  => q(Ye),
					revisit => 0,
				},
				{
					before  => q(\p{^L}),
					after   => q(),
					replace => q(Е),
					result  => q(YE),
					revisit => 0,
				},
				{
					before  => q([AEIOUaeiouĬĭʼËë \N{U+6F.2BB} \N{U+4F.2BB}]),
					after   => q(),
					replace => q(е),
					result  => q(ye),
					revisit => 0,
				},
				{
					before  => q([AEIOUaeiouĬĭʼËë \N{U+6F.2BB} \N{U+4F.2BB}]),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Е),
					result  => q(Ye),
					revisit => 0,
				},
				{
					before  => q([AEIOUaeiouĬĭʼËë \N{U+6F.2BB} \N{U+4F.2BB}]),
					after   => q(),
					replace => q(Е),
					result  => q(YE),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ье),
					result  => q(ye),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(ьЕ),
					result  => q(Ye),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ьЕ),
					result  => q(YE),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ье),
					result  => q(ye),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(ЬЕ),
					result  => q(Ye),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ЬЕ),
					result  => q(YE),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(е),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Е),
					result  => q(E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ю),
					result  => q(yu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Ю),
					result  => q(Yu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ю),
					result  => q(YU),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(я),
					result  => q(ya),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Я),
					result  => q(Ya),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Я),
					result  => q(YA),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ц),
					result  => q(ts),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:(?=[\p{Ll}])(?:(?=[\p{L}])[\p{sc = Latn}\p{sc = Cyrl}]))),
					replace => q(Ц),
					result  => q(Ts),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ц),
					result  => q(TS),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(а),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(А),
					result  => q(A),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(б),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Б),
					result  => q(B),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(д),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Д),
					result  => q(D),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(э),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Э),
					result  => q(E),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ф),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ф),
					result  => q(F),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(г),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Г),
					result  => q(G),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ҳ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ҳ),
					result  => q(H),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(й),
					result  => q(y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Й),
					result  => q(Y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(и),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(И),
					result  => q(I),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ж),
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ж),
					result  => q(J),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(к),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(К),
					result  => q(K),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(л),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Л),
					result  => q(L),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(м),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(М),
					result  => q(M),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(н),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Н),
					result  => q(N),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(о),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(О),
					result  => q(O),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(п),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(П),
					result  => q(P),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(қ),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Қ),
					result  => q(Q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(р),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Р),
					result  => q(R),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(с),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(С),
					result  => q(S),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(т),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Т),
					result  => q(T),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(у),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(У),
					result  => q(U),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(в),
					result  => q(v),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(В),
					result  => q(V),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(х),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Х),
					result  => q(X),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(з),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(З),
					result  => q(Z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ь),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ь),
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
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
