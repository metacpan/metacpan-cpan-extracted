package Locale::CLDR::Transformations::Any::Latn::Syrc;
# This file auto generated from Data\common\transforms\Syriac-Latin.xml
#	on Sun  5 Aug  5:49:18 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
					replace => q(o),
					result  => q(ܿ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(u),
					result  => q(ܼ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(i),
					result  => q(݂),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ē),
					result  => q(ܹ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(e),
					result  => q(ܸ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(a),
					result  => q(ܲ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(t),
					result  => q(ܬ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(r),
					result  => q(ܪ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(q),
					result  => q(ܩ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ṣ),
					result  => q(ܨ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(p),
					result  => q(ܦ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(s),
					result  => q(ܣ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(n),
					result  => q(ܢ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(m),
					result  => q(ܡ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(l),
					result  => q(ܠ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(k),
					result  => q(ܟ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(y),
					result  => q(ܝ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ṭ),
					result  => q(ܛ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ḥ),
					result  => q(ܚ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(z),
					result  => q(ܙ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(w),
					result  => q(ܘ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(h),
					result  => q(ܗ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(d),
					result  => q(ܕ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(g),
					result  => q(ܓ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(b),
					result  => q(ܒ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʾ),
					result  => q(ܐ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(dr),
					result  => q(ܖ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(sh),
					result  => q(ܫ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
