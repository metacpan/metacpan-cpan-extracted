package Locale::CLDR::Transformations::Any::Az::Lower;
# This file auto generated from Data\common\transforms\az-Lower.xml
#	on Sun  5 Aug  5:49:19 pm GMT

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
					replace => q(İ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(I([^\p{ccc=Not_Reordered}\p{ccc=Above}]*)̇),
					result  => q(i$1),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(I),
					result  => q(ı),
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
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
