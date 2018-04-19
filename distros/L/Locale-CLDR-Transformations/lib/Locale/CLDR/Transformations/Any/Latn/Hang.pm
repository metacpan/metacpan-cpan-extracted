package Locale::CLDR::Transformations::Any::Latn::Hang;
# This file auto generated from Data\common\transforms\Latin-Hangul.xml
#	on Fri 13 Apr  6:59:54 am GMT

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
		qr/(?^umi:\G[-A-Za-zÀ-ÅÇ-ÏÑ-ÖÙ-Ýà-åç-ïñ-öù-ýÿ-ďĒ-ĥĨ-İĴ-ķĹ-ľŃ-ňŌ-őŔ-ťŨ-žƠ-ơƯ-ưǍ-ǜǞ-ǡǦ-ǭǰǴ-ǵǸ-ǻȀ-țȞ-ȟȦ-ȳḀ-ẙẠ-ỹK-Å])/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFD),
				},
				{
					from => q(Any),
					to => q(Lower),
				},
				{
					from => q(Latin),
					to => q(ConjoiningJamo),
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
