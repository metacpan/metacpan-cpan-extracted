package Locale::CLDR::Transformations::Any::Ha::Ha_ne;
# This file auto generated from Data\common\transforms\ha-ha_NE.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
		qr/(?^umi:\G[yYƴƳʼ])/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFC),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(),
					after   => q(),
					replace => q(ʼy),
					result  => q(ƴ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(ʼY),
					result  => q(Ƴ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
