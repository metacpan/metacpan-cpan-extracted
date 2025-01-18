package Locale::CLDR::Transformations::Any::El::Title;
# This file auto generated from Data\common\transforms\el-Title.xml
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
					before  => q(\p{Cased}\p{Case_Ignorable}*),
					after   => q(\p{Case_Ignorable}*\p{Cased}),
					replace => q(Σ),
					result  => q(σ),
					revisit => 0,
				},
				{
					before  => q(\p{Cased}\p{Case_Ignorable}*),
					after   => q(),
					replace => q(Σ),
					result  => q(ς),
					revisit => 0,
				},
				{
					before  => q(\p{Cased}\p{Case_Ignorable}*),
					after   => q(),
					replace => q((.)),
					result  => q(&Any-Lower($1)),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([:Lowercase:])),
					result  => q(&Any-Title($1)),
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
