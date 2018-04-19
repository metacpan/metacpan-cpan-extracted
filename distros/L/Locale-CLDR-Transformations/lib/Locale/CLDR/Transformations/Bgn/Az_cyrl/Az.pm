package Locale::CLDR::Transformations::Bgn::Az_cyrl::Az;
# This file auto generated from Data\common\transforms\Azerbaijani-Latin-BGN.xml
#	on Fri 13 Apr  6:59:51 am GMT

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
		qr/(?^umi:\G[АБВГҒДЕӘЖЗИЫЈКҜЛМНОӨПРСТУҮФХҺЧҸШЙЭЮЯабвгғдеәжзиыјкҝлмноөпрстуүфхһчҹш’йэюя])/,
		{
			type => 'transform',
			data => [
				{
					from => q(Any),
					to => q(NFD),
				},
			]
		},
	] },
);

no Moo;

1;

# vim: tabstop=4
