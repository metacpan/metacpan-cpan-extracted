package Locale::CLDR::Transformations::Any::Sk::Am;
# This file auto generated from Data\common\transforms\sk-am.xml
#	on Sun  7 Oct 10:18:25 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

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
					from => q(sk),
					to => q(sk_FONIPA),
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
