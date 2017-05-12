package Locale::CLDR::Transformations::Any::Mlym::Gujr;
# This file auto generated from Data\common\transforms\Malayalam-Gujarati.xml
#	on Fri 29 Apr  6:48:44 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
		qr/(?^umi:\G(?^u:[ം-ഃഅ-ഌഎ-ഐഒ-നപ-ഹാ-ൃെ-ൈൊ-്ൗൠ-ൡ൦-൯]))/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFD),
				},
				{
					from => q(Malayalam),
					to => q(InterIndic),
				},
				{
					from => q(InterIndic),
					to => q(Gujarati),
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
