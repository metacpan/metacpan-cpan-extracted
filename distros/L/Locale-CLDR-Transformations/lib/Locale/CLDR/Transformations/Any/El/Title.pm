package Locale::CLDR::Transformations::Any::El::Title;
# This file auto generated from Data\common\transforms\el-Title.xml
#	on Fri 13 Apr  6:59:56 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.32.0');

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
					before  => q(\p{cased}\p{case-ignorable}*),
					after   => q(\p{case-ignorable}*\p{cased}),
					replace => q(Σ),
					result  => q(σ),
					revisit => 0,
				},
				{
					before  => q(\p{cased}\p{case-ignorable}*),
					after   => q(),
					replace => q(Σ),
					result  => q(ς),
					revisit => 0,
				},
				{
					before  => q(\p{cased}\p{case-ignorable}*),
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
