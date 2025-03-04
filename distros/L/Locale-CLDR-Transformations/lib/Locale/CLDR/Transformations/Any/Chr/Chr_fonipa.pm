package Locale::CLDR::Transformations::Any::Chr::Chr_fonipa;
# This file auto generated from Data\common\transforms\chr-chr_FONIPA.xml
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
		qr/(?^umi:\G[\p{sc=Cher}\p{P}\p{M}])/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(upper),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q([:P:]+),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭰ),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭱ),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭲ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭳ),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭴ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭵ),
					result  => q(ə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭶ),
					result  => q(ɡa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭷ),
					result  => q(ka),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭸ),
					result  => q(ɡe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭹ),
					result  => q(ɡi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭺ),
					result  => q(ɡo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭻ),
					result  => q(ɡu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭼ),
					result  => q(ɡə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭽ),
					result  => q(ha),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭾ),
					result  => q(he),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꭿ),
					result  => q(hi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮀ),
					result  => q(ho),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮁ),
					result  => q(hu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮂ),
					result  => q(hə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮃ),
					result  => q(la),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮄ),
					result  => q(le),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮅ),
					result  => q(li),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮆ),
					result  => q(lo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮇ),
					result  => q(lu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮈ),
					result  => q(lə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮉ),
					result  => q(ma),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮊ),
					result  => q(me),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮋ),
					result  => q(mi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮌ),
					result  => q(mo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮍ),
					result  => q(mu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏽ),
					result  => q(mə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮎ),
					result  => q(na),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮏ),
					result  => q(hna),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮐ),
					result  => q(nah),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮑ),
					result  => q(ne),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮒ),
					result  => q(ni),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮓ),
					result  => q(no),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮔ),
					result  => q(nu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮕ),
					result  => q(nə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮖ),
					result  => q(kʷa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮗ),
					result  => q(kʷe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮘ),
					result  => q(kʷi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮙ),
					result  => q(kʷo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮚ),
					result  => q(kʷu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮛ),
					result  => q(kʷə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮝ),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮜ),
					result  => q(sa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮞ),
					result  => q(se),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮟ),
					result  => q(si),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮠ),
					result  => q(so),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮡ),
					result  => q(su),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮢ),
					result  => q(sə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮣ),
					result  => q(da),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮤ),
					result  => q(ta),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮥ),
					result  => q(de),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮦ),
					result  => q(te),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮧ),
					result  => q(di),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮨ),
					result  => q(ti),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮩ),
					result  => q(do),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮪ),
					result  => q(du),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮫ),
					result  => q(də̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮬ),
					result  => q(d͡la),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮭ),
					result  => q(t͡ɬa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮮ),
					result  => q(t͡ɬe),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮯ),
					result  => q(t͡ɬi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮰ),
					result  => q(t͡ɬo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮱ),
					result  => q(t͡ɬu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮲ),
					result  => q(t͡ɬə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮳ),
					result  => q(t͡sa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮴ),
					result  => q(t͡se),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮵ),
					result  => q(t͡si),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮶ),
					result  => q(t͡so),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮷ),
					result  => q(t͡su),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮸ),
					result  => q(t͡sə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮹ),
					result  => q(wa),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮺ),
					result  => q(we),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮻ),
					result  => q(wi),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮼ),
					result  => q(wo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮽ),
					result  => q(wu),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮾ),
					result  => q(wə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ꮿ),
					result  => q(ja),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏸ),
					result  => q(je),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏹ),
					result  => q(ji),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏺ),
					result  => q(jo),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏻ),
					result  => q(ju),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ᏼ),
					result  => q(jə̃),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̋),
					result  => q(˥),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(́),
					result  => q(˦),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̄),
					result  => q(˧),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̀),
					result  => q(˧˩),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q([̌̆]),
					result  => q(˨˦),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(̂),
					result  => q(˥˧),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(\p{M}),
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
					to => q(null),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(aa+),
					result  => q(aː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ee+),
					result  => q(eː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ii+),
					result  => q(iː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(oo+),
					result  => q(oː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(uu+),
					result  => q(uː),
					revisit => 0,
				},
				{
					before  => q(ə̃),
					after   => q(+),
					replace => q(ə̃),
					result  => q(ə̃),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
