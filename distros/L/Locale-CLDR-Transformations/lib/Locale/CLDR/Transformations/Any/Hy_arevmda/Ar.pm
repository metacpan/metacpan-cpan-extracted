package Locale::CLDR::Transformations::Any::Hy_arevmda::Ar;
# This file auto generated from Data\common\transforms\hy_AREVMDA-ar.xml
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
					from => q(hy_AREVMDA),
					to => q(hy_AREVMDA_FONIPA),
				},
				{
					from => q(Any_FONIPA),
					to => q(ar),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
