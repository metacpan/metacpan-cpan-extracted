package Locale::CLDR::Transformations::Any::Az::Title;
# This file auto generated from Data\common\transforms\az-Title.xml
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
					before  => q(\p{cased}\p{case-ignorable}*),
					after   => q(),
					replace => q(İ),
					result  => q(i),
					revisit => 0,
				},
				{
					before  => q(\p{cased}\p{case-ignorable}*),
					after   => q(),
					replace => q(I),
					result  => q(ı),
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
					replace => q(i),
					result  => q(İ),
					revisit => 0,
				},
				{
					before  => q(),
					after   => q(),
					replace => q(([:Lowercase:])),
					result  => q(&Any-Upper($1)),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
