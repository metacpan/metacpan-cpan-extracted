package Locale::CLDR::Transformations::Any::Nl::Title;
# This file auto generated from Data\common\transforms\nl-Title.xml
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
					to => q(Title),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q(\p{^WB=ALetter}\p{WB=Extend}*[\p{WB=MidLetter}\p{WB=MidNumLet}]?),
					after   => q(),
					replace => q(Ij),
					result  => q(IJ),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
