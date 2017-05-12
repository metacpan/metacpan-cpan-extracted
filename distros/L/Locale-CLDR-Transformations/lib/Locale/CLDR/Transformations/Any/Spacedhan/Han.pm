package Locale::CLDR::Transformations::Any::Spacedhan::Han;
# This file auto generated from Data\common\transforms\Han-Spacedhan.xml
#	on Fri 29 Apr  6:48:42 pm GMT

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
			],
		},
		{
			type => 'conversion',
			data => [
				{
					before  => q((?^u:\p{Letter}\p{Mark}*)),
					after   => q((?^u:\p{Ideographic})),
					replace => q((?^u:\')),
					result  => q(),
					revisit => 0,
				},
				{
					before  => q((?^u:\p{Ideographic})),
					after   => q((?^u:\p{Letter})),
					replace => q((?^u:\')),
					result  => q(),
					revisit => 0,
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
