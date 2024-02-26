=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Iu::Latn - Package for language Inuktitut

=cut

package Locale::CLDR::Locales::Iu::Latn;
# This file auto generated from Data\common\main\iu_Latn.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
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
			auxiliary => qr{[b c d e f h o w x y z]},
			index => ['A', 'G', 'I', 'J', 'K', 'LŁ', 'M', 'N', '{NG}', '{NNG}', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'],
			main => qr{[a g i j k lł m n {ng} {nng} p q r s t u v]},
		};
	},
EOT
: sub {
		return { index => ['A', 'G', 'I', 'J', 'K', 'LŁ', 'M', 'N', '{NG}', '{NNG}', 'P', 'Q', 'R', 'S', 'T', 'U', 'V'], };
},
);


no Moo;

1;

# vim: tabstop=4
