package Locale::CLDR::Locales::Mhn;
# This file auto generated from Data\common\main\mhn.xml
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

extends('Locale::CLDR::Locales::Root');
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			main => qr{[aáà b c d eéèë f g h iíì j k l m n oóò p q r s t uúù v w x y z]},
			numbers => qr{[\- ‑ , + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[, ; ! ? . ' "]},
		};
	},
EOT
: sub {
		return {};
},
);


no Moo;

1;

# vim: tabstop=4
