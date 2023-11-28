package Locale::CLDR::Transformations::Any::Zu::Am;
# This file auto generated from Data\common\transforms\zu-am.xml
#	on Sat  4 Nov  5:50:52 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

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
					from => q(zu),
					to => q(zu_FONIPA),
				},
				{
					from => q(am_FONIPA),
					to => q(am),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
