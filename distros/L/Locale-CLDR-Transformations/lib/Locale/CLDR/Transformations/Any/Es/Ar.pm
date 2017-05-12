package Locale::CLDR::Transformations::Any::Es::Ar;
# This file auto generated from Data\common\transforms\es-ar.xml
#	on Fri 29 Apr  6:48:47 pm GMT

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
		qr/(?^um:\G.)/,
		{
			type => 'transform',
			data => [
				{
					from => q(es),
					to => q(es_FONIPA),
				},
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q((?^u:[^ \p{L} \p{M} \p{N}][^Vowel])),
					after   => q((?^u:(?[![i e o u a]])*[i e o u a])),
					replace => q((?^u:e)),
					result  => q(ə),
					revisit => 0,
				},
			],
		},
		{
			type => 'transform',
			data => [
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
