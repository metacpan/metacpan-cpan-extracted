package Locale::CLDR::Transformations::Any::Ug::Ug_fonipa;
# This file auto generated from Data\common\transforms\ug-ug_FONIPA.xml
#	on Fri 13 Oct  9:03:52 am GMT

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
					before  => q(),
					after   => q(),
					replace => q(ئ),
					result  => q(ʔ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ا),
					result  => q(a),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ە),
					result  => q(‎ɛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ب‎),
					result  => q(b),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(پ),
					result  => q(p),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ت),
					result  => q(t),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ج),
					result  => q(d͡ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(چ),
					result  => q(t͡ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(خ),
					result  => q(x),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(د),
					result  => q(d),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ر),
					result  => q(r),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ز),
					result  => q(z),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ژ),
					result  => q(ʒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(س),
					result  => q(s),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ش),
					result  => q(ʃ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(غ),
					result  => q(ʁ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ف),
					result  => q(f),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ق),
					result  => q(q),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ك),
					result  => q(k),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(گ),
					result  => q(ɡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ڭ),
					result  => q(ŋ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ل),
					result  => q(l),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(م),
					result  => q(m),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ن),
					result  => q(n),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ھ),
					result  => q(h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(و),
					result  => q(o),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۇ),
					result  => q(u),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۆ),
					result  => q(ø),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۈ),
					result  => q(y),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۋ),
					result  => q(w),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ې),
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ى),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ي),
					result  => q(j),
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
					replace => q(bb),
					result  => q(bː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pp),
					result  => q(pː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^͡]),
					replace => q(tt),
					result  => q(tː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d͡ʒd͡ʒ),
					result  => q(d͡ʒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t͡ʃt͡ʃ),
					result  => q(t͡ʃː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(xx),
					result  => q(xː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^͡]),
					replace => q(dd),
					result  => q(dː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(rr),
					result  => q(rː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(zz),
					result  => q(zː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʒʒ),
					result  => q(ʒː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ss),
					result  => q(sː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʃʃ),
					result  => q(ʃː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʁʁ),
					result  => q(ʁː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ff),
					result  => q(fː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(qq),
					result  => q(qː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kk),
					result  => q(kː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ɡɡ),
					result  => q(ɡː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ŋŋ),
					result  => q(ŋː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ll),
					result  => q(lː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(mm),
					result  => q(mː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(nn),
					result  => q(nː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(hh),
					result  => q(hː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ww),
					result  => q(wː),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(jj),
					result  => q(jː),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
