package Locale::CLDR::Transformations::Any::Ug::Latin;
# This file auto generated from Data\common\transforms\ug-Latin.xml
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
					replace => q([:Separator:]*),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(٫),
					result  => q(\'̱),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(،),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؛),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(؟),
					result  => q(\'),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(›),
					result  => q(‘),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(‹),
					result  => q(’),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ئ),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ـ),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(سھ),
					result  => q(s'h),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(نغ),
					result  => q(n'gh),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(نگ),
					result  => q(n'g),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ڭھ),
					result  => q(ng'h),
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
					result  => q(e),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ب),
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
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(چ),
					result  => q(ch),
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
					result  => q(j),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ش),
					result  => q(sh),
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
					replace => q(غ),
					result  => q(gh),
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
					replace => q(ڭ),
					result  => q(ng),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(گ),
					result  => q(g),
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
					result  => q(ö),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ۈ),
					result  => q(ü),
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
					result  => q(é),
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
					result  => q(y),
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
