package Locale::CLDR::Transformations::Any::Latn::Geor;
# This file auto generated from Data\common\transforms\Georgian-Latin.xml
#	on Sun  3 Feb  1:37:07 pm GMT

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
					replace => q(q),
					result  => q(ჴ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(ჰ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(j),
					result  => q(ჯ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(ქ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(p),
					result  => q(ფ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(u),
					result  => q(უ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(ს),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(რ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(o),
					result  => q(ო),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(n),
					result  => q(ნ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(m),
					result  => q(მ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(l),
					result  => q(ლ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(ი),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(თ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(ზ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(v),
					result  => q(ვ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e),
					result  => q(ე),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(დ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(გ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(ბ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(ა),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ŭi),
					result  => q(ჳ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kh),
					result  => q(ხ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dz),
					result  => q(ძ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ts),
					result  => q(ც),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ch),
					result  => q(ჩ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(chʼ),
					result  => q(ჭ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(sh),
					result  => q(შ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(qʼ),
					result  => q(ყ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(gh),
					result  => q(ღ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tʼ),
					result  => q(ტ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(zh),
					result  => q(ჟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(pʼ),
					result  => q(პ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(kʼ),
					result  => q(კ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(tsʼ),
					result  => q(წ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
