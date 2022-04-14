package Locale::CLDR::Transformations::Any::Es_419::Chr;
# This file auto generated from Data/common/transforms/es_419-chr.xml
#	on Mon 11 Apr  5:22:57 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.1');

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
					from => q(es),
					to => q(es_FONIPA),
				},
				{
					from => q(es_FONIPA),
					to => q(es_419_FONIPA),
				},
				{
					from => q(Any_FONIPA),
					to => q(chr),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
