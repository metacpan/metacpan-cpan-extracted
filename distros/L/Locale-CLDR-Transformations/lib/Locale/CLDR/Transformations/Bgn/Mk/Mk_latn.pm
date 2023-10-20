package Locale::CLDR::Transformations::Bgn::Mk::Mk_latn;
# This file auto generated from Data\common\transforms\Macedonian-Latin-BGN.xml
#	on Fri 13 Oct  9:03:47 am GMT

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
		qr/(?^umi:\G[АБВГДЃЕЖЗЅИЈКЛЉМНЊОПРСТЌУФХЦЧЏШабвгдѓежзѕијклљмнњопрстќуфхцчџш’])/,
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
					replace => q(А),
					result  => q(A),
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
					replace => q(Б),
					result  => q(B),
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
					replace => q(В),
					result  => q(V),
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
					replace => q(Г),
					result  => q(G),
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
					replace => q(Д),
					result  => q(D),
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
					after   => q([ЕеИи]),
					replace => q(Ѓ),
					result  => q(G),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([ЕеИи]),
					replace => q(ѓ),
					result  => q(g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ѓ),
					result  => q(Đ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ѓ),
					result  => q(đ),
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
					replace => q(е),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ж),
					result  => q(Ž),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ж),
					result  => q(ž),
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
					replace => q(з),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[бвгдѓжзѕјклљмнњпрстќфхцчџш’]|[аеиоу])),
					replace => q(Ѕ),
					result  => q(Dz),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ѕ),
					result  => q(DZ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ѕ),
					result  => q(dz),
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
					replace => q(и),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ј),
					result  => q(J),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ј),
					result  => q(j),
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
					replace => q(к),
					result  => q(k),
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
					replace => q(л),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[бвгдѓжзѕјклљмнњпрстќфхцчџш’]|[аеиоу])),
					replace => q(Љ),
					result  => q(Lj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Љ),
					result  => q(LJ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(љ),
					result  => q(lj),
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
					replace => q(м),
					result  => q(m),
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
					replace => q(н),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[бвгдѓжзѕјклљмнњпрстќфхцчџш’]|[аеиоу])),
					replace => q(Њ),
					result  => q(Nj),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Њ),
					result  => q(NJ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(њ),
					result  => q(nj),
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
					replace => q(о),
					result  => q(o),
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
					replace => q(п),
					result  => q(p),
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
					replace => q(р),
					result  => q(r),
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
					replace => q(с),
					result  => q(s),
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
					replace => q(т),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([ЕеИи]),
					replace => q(Ќ),
					result  => q(K),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([ЕеИи]),
					replace => q(ќ),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ќ),
					result  => q(Ć),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ќ),
					result  => q(ć),
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
					replace => q(у),
					result  => q(u),
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
					replace => q(ф),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Х),
					result  => q(H),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(х),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ц),
					result  => q(C),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ц),
					result  => q(c),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ч),
					result  => q(Č),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ч),
					result  => q(č),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q((?:[бвгдѓжзѕјклљмнњпрстќфхцчџш’]|[аеиоу])),
					replace => q(Џ),
					result  => q(Dž),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Џ),
					result  => q(DŽ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(џ),
					result  => q(dž),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ш),
					result  => q(Š),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ш),
					result  => q(š),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
