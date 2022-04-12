=encoding utf8

=head1

Locale::CLDR::Locales::De::Any::Ch - Package for language German

=cut

package Locale::CLDR::Locales::De::Any::Ch;
# This file auto generated from Data/common/main/de_CH.xml
#	on Mon 11 Apr  5:26:25 pm GMT

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

extends('Locale::CLDR::Locales::De::Any');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-n','spellout-cardinal-r','spellout-cardinal-s','spellout-ordinal','spellout-ordinal-n','spellout-ordinal-r','spellout-ordinal-s' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eine),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ein),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-n' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(einen),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
			},
		},
		'spellout-cardinal-r' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(einer),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-cardinal-s' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eines),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eins),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zwei),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drei),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(vier),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fünf),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechs),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sieben),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(acht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(neun),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(zehn),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elf),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(zwölf),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→zehn),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sechzehn),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(siebzehn),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(→→zehn),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]zwanzig),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]dreissig),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]vierzig),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]fünfzig),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]sechzig),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]siebzig),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]achtzig),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-cardinal-masculine→­und­]neunzig),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert[­→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(erste),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zweite),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(dritte),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(vierte),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fünfte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechste),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siebte),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(achte),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(=%spellout-numbering=te),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-numbering=ste),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­hundert→%%ste→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­tausend→%%ste→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(eine Million→%%ste2→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← Millionen→%%ste2→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(eine Milliarde→%%ste2→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← Milliarden→%%ste2→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(eine Billion→%%ste→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← Billionen→%%ste2→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(eine Billiarde→%%ste2→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← Billiarden→%%ste2→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-n' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal=n),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
		'spellout-ordinal-r' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal=r),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
		'spellout-ordinal-s' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal=s),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
			},
		},
		'ste' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ste),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal=),
				},
			},
		},
		'ste2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ste),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
	} },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'ace' => 'Aceh-Sprache',
 				'ach' => 'Acholi-Sprache',
 				'ars' => 'Nadschd-Arabisch',
 				'bas' => 'Basaa-Sprache',
 				'be' => 'Weissrussisch',
 				'bik' => 'Bikol-Sprache',
 				'bin' => 'Bini-Sprache',
 				'chb' => 'Chibcha-Sprache',
 				'din' => 'Dinka-Sprache',
 				'fan' => 'Pangwe-Sprache',
 				'gba' => 'Gbaya-Sprache',
 				'kmb' => 'Kimbundu-Sprache',
 				'mus' => 'Muskogee-Sprache',
 				'prg' => 'Altpreussisch',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'BN' => 'Brunei',
 			'BW' => 'Botswana',
 			'BY' => 'Weissrussland',
 			'CV' => 'Kapverden',
 			'GB' => 'Grossbritannien',
 			'QO' => 'Äusseres Ozeanien',
 			'SB' => 'Salomon-Inseln',
 			'TL' => 'Osttimor',
 			'ZW' => 'Zimbabwe',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'colcasefirst' => 'Sortierung nach Gross- bzw. Kleinbuchstaben',
 			'colcaselevel' => 'Sortierung nach Gross- oder Kleinschreibung',
 			'ms' => 'Mass-System',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'colcasefirst' => {
 				'upper' => q{Grossbuchstaben zuerst aufführen},
 			},
 			'colcaselevel' => {
 				'no' => q{Ohne Gross-/Kleinschreibung sortieren},
 				'yes' => q{Nach Gross-/Kleinschreibung sortieren},
 			},
 			'ms' => {
 				'uksystem' => q{britisches Mass-System},
 				'ussystem' => q{US Mass-System},
 			},

		}
	},
);

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			main => qr{[a ä b c d e f g h i j k l m n o ö p q r s t u ü v w x y z]},
			numbers => qr{[\- . ’ % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'cubic-foot' => {
						'name' => q(Kubikfuss),
						'one' => q({0} Kubikfuss),
						'other' => q({0} Kubikfuss),
					},
					'foot' => {
						'name' => q(Fuss),
						'one' => q({0} Fuss),
						'other' => q({0} Fuss),
						'per' => q({0} pro Fuss),
					},
					'gallon-imperial' => {
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
					},
					'square-foot' => {
						'name' => q(Quadratfuss),
						'one' => q({0} Quadratfuss),
						'other' => q({0} Quadratfuss),
					},
				},
				'short' => {
					'foot' => {
						'name' => q(Fuss),
					},
					'gallon-imperial' => {
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
						'per' => q({0}/gal Imp.),
					},
				},
			} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'group' => q(’),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
				},
			},
		},
} },
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'negative' => '¤-#,##0.00',
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
} },
);

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'BYN' => {
			display_name => {
				'currency' => q(Weissrussischer Rubel),
				'one' => q(Weissrussischer Rubel),
				'other' => q(Weissrussische Rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Weissrussischer Rubel \(2000–2016\)),
				'one' => q(Weissrussischer Rubel \(2000–2016\)),
				'other' => q(Weissrussische Rubel \(2000–2016\)),
			},
		},
		'EUR' => {
			symbol => 'EUR',
		},
		'STN' => {
			display_name => {
				'currency' => q(São-toméischer Dobra \(2018\)),
				'one' => q(São-toméischer Dobra \(2018\)),
				'other' => q(São-toméischer Dobra \(2018\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezolanischer Bolívar),
				'one' => q(Venezolanischer Bolívar),
				'other' => q(Venezolanische Bolívares),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(VES),
				'one' => q(VES),
				'other' => q(VES),
			},
		},
	} },
);


has 'calendar_days' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					short => {
						mon => 'Mo',
						tue => 'Di',
						wed => 'Mi',
						thu => 'Do',
						fri => 'Fr',
						sat => 'Sa',
						sun => 'So'
					},
				},
			},
	} },
);

has 'day_period_data' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { sub {
		# Time in hhmm format
		my ($self, $type, $time, $day_period_type) = @_;
		$day_period_type //= 'default';
		SWITCH:
		for ($type) {
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
		}
	} },
);

around day_period_data => sub {
	my ($orig, $self) = @_;
	return $self->$orig;
};

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei-Zeit#,
			},
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomoninseln-Zeit#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
