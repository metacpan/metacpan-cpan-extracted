package Locale::CLDR::Transformations::Any::Lt::Lower;
# This file auto generated from Data\common\transforms\lt-Lower.xml
#	on Sun  5 Aug  5:49:21 pm GMT

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
					after   => q([^\p{ccc=Not_Reordered}\p{ccc=Above}]*\p{ccc=Above}),
					replace => q(I),
					result  => q(i\u0307),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^\p{ccc=Not_Reordered}\p{ccc=Above}]*\p{ccc=Above}),
					replace => q(J),
					result  => q(j\u0307),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q([^\p{ccc=Not_Reordered}\p{ccc=Above}]*\p{ccc=Above}),
					replace => q(Į),
					result  => q(i\u0328\u0307),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ì),
					result  => q(i\u0307\u0300),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Í),
					result  => q(i\u0307\u0301),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(Ĩ),
					result  => q(i\u0307\u0303),
					revisit => 0,
				},
			],
		},
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
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
