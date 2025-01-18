=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Zh::Latn - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh::Latn;
# This file auto generated from Data\common\main\zh_Latn.xml
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

extends('Locale::CLDR::Locales::Zh');
has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[v]},
			main => qr{[aáàǎā b cĉ d eéèêếề{ê̌}{ê̄}ěē f g h iíìǐī j k l mḿ{m̀}{m̄} nńǹň ŋ oóòǒō p q r sŝ t uúùǔüǘǜǚǖū w x y zẑ]},
			numbers => qr{[0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ , ! ? . · ' "]},
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
