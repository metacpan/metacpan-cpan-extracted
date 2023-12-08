=encoding utf8

=head1 NAME

Locale::CLDR::Locales::De - Package for language German

=cut

package Locale::CLDR::Locales::De;
# This file auto generated from Data\common\main\de.xml
#	on Tue  5 Dec  1:06:12 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.4');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Root');
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
		use bigfloat;
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
					rule => q([→%spellout-cardinal-masculine→­und­]dreißig),
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

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}, {1}', grep {$_} (
		$region,
		$script,
		$variant,
	);

	$display_pattern =~s/\{1\}/$subtags/g;
	return $display_pattern;
}

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'aa' => 'Afar',
 				'ab' => 'Abchasisch',
 				'ace' => 'Aceh',
 				'ach' => 'Acholi',
 				'ada' => 'Adangme',
 				'ady' => 'Adygeisch',
 				'ae' => 'Avestisch',
 				'aeb' => 'Tunesisches Arabisch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadisch',
 				'akz' => 'Alabama',
 				'ale' => 'Aleutisch',
 				'aln' => 'Gegisch',
 				'alt' => 'Süd-Altaisch',
 				'am' => 'Amharisch',
 				'an' => 'Aragonesisch',
 				'ang' => 'Altenglisch',
 				'anp' => 'Angika',
 				'ar' => 'Arabisch',
 				'ar_001' => 'Modernes Hocharabisch',
 				'arc' => 'Aramäisch',
 				'arn' => 'Mapudungun',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho',
 				'arq' => 'Algerisches Arabisch',
 				'ars' => 'Arabisch (Nadschd)',
 				'arw' => 'Arawak',
 				'ary' => 'Marokkanisches Arabisch',
 				'arz' => 'Ägyptisches Arabisch',
 				'as' => 'Assamesisch',
 				'asa' => 'Asu',
 				'ase' => 'Amerikanische Gebärdensprache',
 				'ast' => 'Asturianisch',
 				'av' => 'Awarisch',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschanisch',
 				'az@alt=short' => 'Aserbaidschanisch',
 				'ba' => 'Baschkirisch',
 				'bal' => 'Belutschisch',
 				'ban' => 'Balinesisch',
 				'bar' => 'Bairisch',
 				'bas' => 'Basaa',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Weißrussisch',
 				'bej' => 'Bedauye',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgarisch',
 				'bgn' => 'Westliches Belutschi',
 				'bho' => 'Bhodschpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjaresisch',
 				'bkm' => 'Kom',
 				'bla' => 'Blackfoot',
 				'bm' => 'Bambara',
 				'bn' => 'Bengalisch',
 				'bo' => 'Tibetisch',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bachtiarisch',
 				'br' => 'Bretonisch',
 				'bra' => 'Braj-Bhakha',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnisch',
 				'bss' => 'Akoose',
 				'bua' => 'Burjatisch',
 				'bug' => 'Buginesisch',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Katalanisch',
 				'cad' => 'Caddo',
 				'car' => 'Karibisch',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ce' => 'Tschetschenisch',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Rukiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Tschagataisch',
 				'chk' => 'Chuukesisch',
 				'chm' => 'Mari',
 				'chn' => 'Chinook',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Zentralkurdisch',
 				'co' => 'Korsisch',
 				'cop' => 'Koptisch',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crh' => 'Krimtatarisch',
 				'crs' => 'Seychellenkreol',
 				'cs' => 'Tschechisch',
 				'csb' => 'Kaschubisch',
 				'cu' => 'Kirchenslawisch',
 				'cv' => 'Tschuwaschisch',
 				'cy' => 'Walisisch',
 				'da' => 'Dänisch',
 				'dak' => 'Dakota',
 				'dar' => 'Darginisch',
 				'dav' => 'Taita',
 				'de' => 'Deutsch',
 				'de_AT' => 'Österreichisches Deutsch',
 				'de_CH' => 'Schweizer Hochdeutsch',
 				'del' => 'Delaware',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Niedersorbisch',
 				'dtp' => 'Zentral-Dusun',
 				'dua' => 'Duala',
 				'dum' => 'Mittelniederländisch',
 				'dv' => 'Dhivehi',
 				'dyo' => 'Diola',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egl' => 'Emilianisch',
 				'egy' => 'Ägyptisch',
 				'eka' => 'Ekajuk',
 				'el' => 'Griechisch',
 				'elx' => 'Elamisch',
 				'en' => 'Englisch',
 				'en_GB@alt=short' => 'Englisch (GB)',
 				'en_US@alt=short' => 'Englisch (USA)',
 				'enm' => 'Mittelenglisch',
 				'eo' => 'Esperanto',
 				'es' => 'Spanisch',
 				'esu' => 'Zentral-Alaska-Yupik',
 				'et' => 'Estnisch',
 				'eu' => 'Baskisch',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremadurisch',
 				'fa' => 'Persisch',
 				'fan' => 'Pangwe',
 				'fat' => 'Fanti',
 				'ff' => 'Ful',
 				'fi' => 'Finnisch',
 				'fil' => 'Filipino',
 				'fit' => 'Meänkieli',
 				'fj' => 'Fidschi',
 				'fo' => 'Färöisch',
 				'fon' => 'Fon',
 				'fr' => 'Französisch',
 				'frc' => 'Cajun',
 				'frm' => 'Mittelfranzösisch',
 				'fro' => 'Altfranzösisch',
 				'frp' => 'Frankoprovenzalisch',
 				'frr' => 'Nordfriesisch',
 				'frs' => 'Ostfriesisch',
 				'fur' => 'Friaulisch',
 				'fy' => 'Westfriesisch',
 				'ga' => 'Irisch',
 				'gaa' => 'Ga',
 				'gag' => 'Gagausisch',
 				'gan' => 'Gan',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gbz' => 'Gabri',
 				'gd' => 'Schottisches Gälisch',
 				'gez' => 'Geez',
 				'gil' => 'Kiribatisch',
 				'gl' => 'Galicisch',
 				'glk' => 'Gilaki',
 				'gmh' => 'Mittelhochdeutsch',
 				'gn' => 'Guaraní',
 				'goh' => 'Althochdeutsch',
 				'gom' => 'Goa-Konkani',
 				'gon' => 'Gondi',
 				'gor' => 'Mongondou',
 				'got' => 'Gotisch',
 				'grb' => 'Grebo',
 				'grc' => 'Altgriechisch',
 				'gsw' => 'Schweizerdeutsch',
 				'gu' => 'Gujarati',
 				'guc' => 'Wayúu',
 				'gur' => 'Farefare',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Kutchin',
 				'ha' => 'Haussa',
 				'hai' => 'Haida',
 				'hak' => 'Hakka',
 				'haw' => 'Hawaiisch',
 				'he' => 'Hebräisch',
 				'hi' => 'Hindi',
 				'hif' => 'Fidschi-Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hethitisch',
 				'hmn' => 'Miao',
 				'ho' => 'Hiri-Motu',
 				'hr' => 'Kroatisch',
 				'hsb' => 'Obersorbisch',
 				'hsn' => 'Xiang',
 				'ht' => 'Haiti-Kreolisch',
 				'hu' => 'Ungarisch',
 				'hup' => 'Hupa',
 				'hy' => 'Armenisch',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesisch',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Yi',
 				'ik' => 'Inupiak',
 				'ilo' => 'Ilokano',
 				'inh' => 'Inguschisch',
 				'io' => 'Ido',
 				'is' => 'Isländisch',
 				'it' => 'Italienisch',
 				'iu' => 'Inuktitut',
 				'izh' => 'Ischorisch',
 				'ja' => 'Japanisch',
 				'jam' => 'Jamaikanisch-Kreolisch',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Jüdisch-Persisch',
 				'jrb' => 'Jüdisch-Arabisch',
 				'jut' => 'Jütisch',
 				'jv' => 'Javanisch',
 				'ka' => 'Georgisch',
 				'kaa' => 'Karakalpakisch',
 				'kab' => 'Kabylisch',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardinisch',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongolesisch',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'kho' => 'Sakisch',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Kikuyu',
 				'kiu' => 'Kirmanjki',
 				'kj' => 'Kwanyama',
 				'kk' => 'Kasachisch',
 				'kkj' => 'Kako',
 				'kl' => 'Grönländisch',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Koreanisch',
 				'koi' => 'Komi-Permjakisch',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeanisch',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karatschaiisch-Balkarisch',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Karelisch',
 				'kru' => 'Oraon',
 				'ks' => 'Kaschmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kölsch',
 				'ku' => 'Kurdisch',
 				'kum' => 'Kumükisch',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Kornisch',
 				'ky' => 'Kirgisisch',
 				'la' => 'Latein',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luxemburgisch',
 				'lez' => 'Lesgisch',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Ganda',
 				'li' => 'Limburgisch',
 				'lij' => 'Ligurisch',
 				'liv' => 'Livisch',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardisch',
 				'ln' => 'Lingala',
 				'lo' => 'Laotisch',
 				'lol' => 'Mongo',
 				'lou' => 'Kreol (Louisiana)',
 				'loz' => 'Lozi',
 				'lrc' => 'Nördliches Luri',
 				'lt' => 'Litauisch',
 				'ltg' => 'Lettgallisch',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Lushai',
 				'luy' => 'Luhya',
 				'lv' => 'Lettisch',
 				'lzh' => 'Klassisches Chinesisch',
 				'lzz' => 'Lasisch',
 				'mad' => 'Maduresisch',
 				'maf' => 'Mafa',
 				'mag' => 'Khotta',
 				'mai' => 'Maithili',
 				'mak' => 'Makassarisch',
 				'man' => 'Malinke',
 				'mas' => 'Massai',
 				'mde' => 'Maba',
 				'mdf' => 'Mokschanisch',
 				'mdr' => 'Mandaresisch',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Madagassisch',
 				'mga' => 'Mittelirisch',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marschallesisch',
 				'mi' => 'Maori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Mazedonisch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolisch',
 				'mnc' => 'Mandschurisch',
 				'mni' => 'Meithei',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'mrj' => 'Bergmari',
 				'ms' => 'Malaiisch',
 				'mt' => 'Maltesisch',
 				'mua' => 'Mundang',
 				'mul' => 'Mehrsprachig',
 				'mus' => 'Muskogee',
 				'mwl' => 'Mirandesisch',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Birmanisch',
 				'mye' => 'Myene',
 				'myv' => 'Ersja-Mordwinisch',
 				'mzn' => 'Masanderanisch',
 				'na' => 'Nauruisch',
 				'nan' => 'Min Nan',
 				'nap' => 'Neapolitanisch',
 				'naq' => 'Nama',
 				'nb' => 'Norwegisch Bokmål',
 				'nd' => 'Nord-Ndebele',
 				'nds' => 'Niederdeutsch',
 				'nds_NL' => 'Niedersächsisch',
 				'ne' => 'Nepalesisch',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niue',
 				'njo' => 'Ao-Naga',
 				'nl' => 'Niederländisch',
 				'nl_BE' => 'Flämisch',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwegisch Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegisch',
 				'nog' => 'Nogai',
 				'non' => 'Altnordisch',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'Süd-Ndebele',
 				'nso' => 'Nord-Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Alt-Newari',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Okzitanisch',
 				'oj' => 'Ojibwa',
 				'om' => 'Oromo',
 				'or' => 'Oriya',
 				'os' => 'Ossetisch',
 				'osa' => 'Osage',
 				'ota' => 'Osmanisch',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pal' => 'Mittelpersisch',
 				'pam' => 'Pampanggan',
 				'pap' => 'Papiamento',
 				'pau' => 'Palau',
 				'pcd' => 'Picardisch',
 				'pcm' => 'Nigerianisches Pidgin',
 				'pdc' => 'Pennsylvaniadeutsch',
 				'pdt' => 'Plautdietsch',
 				'peo' => 'Altpersisch',
 				'pfl' => 'Pfälzisch',
 				'phn' => 'Phönizisch',
 				'pi' => 'Pali',
 				'pl' => 'Polnisch',
 				'pms' => 'Piemontesisch',
 				'pnt' => 'Pontisch',
 				'pon' => 'Ponapeanisch',
 				'prg' => 'Altpreußisch',
 				'pro' => 'Altprovenzalisch',
 				'ps' => 'Paschtu',
 				'pt' => 'Portugiesisch',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'qug' => 'Chimborazo Hochland-Quechua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotonganisch',
 				'rgn' => 'Romagnol',
 				'rif' => 'Tarifit',
 				'rm' => 'Rätoromanisch',
 				'rn' => 'Rundi',
 				'ro' => 'Rumänisch',
 				'ro_MD' => 'Moldauisch',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'root' => 'Root',
 				'rtm' => 'Rotumanisch',
 				'ru' => 'Russisch',
 				'rue' => 'Russinisch',
 				'rug' => 'Roviana',
 				'rup' => 'Aromunisch',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Jakutisch',
 				'sam' => 'Samaritanisch',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardisch',
 				'scn' => 'Sizilianisch',
 				'sco' => 'Schottisch',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sassarisch',
 				'sdh' => 'Südkurdisch',
 				'se' => 'Nordsamisch',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkupisch',
 				'ses' => 'Koyra Senni',
 				'sg' => 'Sango',
 				'sga' => 'Altirisch',
 				'sgs' => 'Samogitisch',
 				'sh' => 'Serbo-Kroatisch',
 				'shi' => 'Taschelhit',
 				'shn' => 'Schan',
 				'shu' => 'Tschadisch-Arabisch',
 				'si' => 'Singhalesisch',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowakisch',
 				'sl' => 'Slowenisch',
 				'sli' => 'Schlesisch (Niederschlesisch)',
 				'sly' => 'Selayar',
 				'sm' => 'Samoanisch',
 				'sma' => 'Südsamisch',
 				'smj' => 'Lule-Samisch',
 				'smn' => 'Inari-Samisch',
 				'sms' => 'Skolt-Samisch',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sog' => 'Sogdisch',
 				'sq' => 'Albanisch',
 				'sr' => 'Serbisch',
 				'srn' => 'Srananisch',
 				'srr' => 'Serer',
 				'ss' => 'Swazi',
 				'ssy' => 'Saho',
 				'st' => 'Süd-Sotho',
 				'stq' => 'Saterfriesisch',
 				'su' => 'Sundanesisch',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Sumerisch',
 				'sv' => 'Schwedisch',
 				'sw' => 'Suaheli',
 				'sw_CD' => 'Kongo-Swahili',
 				'swb' => 'Komorisch',
 				'syc' => 'Altsyrisch',
 				'syr' => 'Syrisch',
 				'szl' => 'Schlesisch (Wasserpolnisch)',
 				'ta' => 'Tamil',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Temne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Tadschikisch',
 				'th' => 'Thailändisch',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmenisch',
 				'tkl' => 'Tokelauanisch',
 				'tkr' => 'Tsachurisch',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingonisch',
 				'tli' => 'Tlingit',
 				'tly' => 'Talisch',
 				'tmh' => 'Tamaseq',
 				'tn' => 'Tswana',
 				'to' => 'Tongaisch',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Neumelanesisch',
 				'tr' => 'Türkisch',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonisch',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatarisch',
 				'ttt' => 'Tatisch',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvaluisch',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitisch',
 				'tyv' => 'Tuwinisch',
 				'tzm' => 'Zentralatlas-Tamazight',
 				'udm' => 'Udmurtisch',
 				'ug' => 'Uigurisch',
 				'uga' => 'Ugaritisch',
 				'uk' => 'Ukrainisch',
 				'umb' => 'Umbundu',
 				'und' => 'Unbekannte Sprache',
 				'ur' => 'Urdu',
 				'uz' => 'Usbekisch',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Venetisch',
 				'vep' => 'Wepsisch',
 				'vi' => 'Vietnamesisch',
 				'vls' => 'Westflämisch',
 				'vmf' => 'Mainfränkisch',
 				'vo' => 'Volapük',
 				'vot' => 'Wotisch',
 				'vro' => 'Võro',
 				'vun' => 'Vunjo',
 				'wa' => 'Wallonisch',
 				'wae' => 'Walliserdeutsch',
 				'wal' => 'Walamo',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu',
 				'xal' => 'Kalmückisch',
 				'xh' => 'Xhosa',
 				'xmf' => 'Mingrelisch',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapesisch',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddisch',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonesisch',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotekisch',
 				'zbl' => 'Bliss-Symbole',
 				'zea' => 'Seeländisch',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamazight',
 				'zh' => 'Chinesisch',
 				'zh_Hans' => 'Chinesisch (vereinfacht)',
 				'zh_Hant' => 'Chinesisch (traditionell)',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'Keine Sprachinhalte',
 				'zza' => 'Zaza',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_script' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		sub {
			my %scripts = (
			'Afak' => 'Afaka',
 			'Aghb' => 'Kaukasisch-Albanisch',
 			'Arab' => 'Arabisch',
 			'Arab@alt=variant' => 'Persisch',
 			'Armi' => 'Armi',
 			'Armn' => 'Armenisch',
 			'Avst' => 'Avestisch',
 			'Bali' => 'Balinesisch',
 			'Bamu' => 'Bamun',
 			'Bass' => 'Bassa',
 			'Batk' => 'Battakisch',
 			'Beng' => 'Bengalisch',
 			'Blis' => 'Bliss-Symbole',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buginesisch',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'UCAS',
 			'Cari' => 'Karisch',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptisch',
 			'Cprt' => 'Zypriotisch',
 			'Cyrl' => 'Kyrillisch',
 			'Cyrs' => 'Altkirchenslawisch',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployanisch',
 			'Egyd' => 'Ägyptisch - Demotisch',
 			'Egyh' => 'Ägyptisch - Hieratisch',
 			'Egyp' => 'Ägyptische Hieroglyphen',
 			'Elba' => 'Elbasanisch',
 			'Ethi' => 'Äthiopisch',
 			'Geok' => 'Khutsuri',
 			'Geor' => 'Georgisch',
 			'Glag' => 'Glagolitisch',
 			'Goth' => 'Gotisch',
 			'Gran' => 'Grantha',
 			'Grek' => 'Griechisch',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Hanb',
 			'Hang' => 'Hangul',
 			'Hani' => 'Chinesisch',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Vereinfacht',
 			'Hans@alt=stand-alone' => 'Vereinfachtes Chinesisch',
 			'Hant' => 'Traditionell',
 			'Hant@alt=stand-alone' => 'Traditionelles Chinesisch',
 			'Hebr' => 'Hebräisch',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Hieroglyphen-Luwisch',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Japanische Silbenschrift',
 			'Hung' => 'Altungarisch',
 			'Inds' => 'Indus-Schrift',
 			'Ital' => 'Altitalisch',
 			'Jamo' => 'Jamo',
 			'Java' => 'Javanesisch',
 			'Jpan' => 'Japanisch',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreanisch',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laotisch',
 			'Latf' => 'Lateinisch - Fraktur-Variante',
 			'Latg' => 'Lateinisch - Gälische Variante',
 			'Latn' => 'Lateinisch',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lykisch',
 			'Lydi' => 'Lydisch',
 			'Mahj' => 'Mahajani',
 			'Mand' => 'Mandäisch',
 			'Mani' => 'Manichäisch',
 			'Maya' => 'Maya-Hieroglyphen',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitisch kursiv',
 			'Mero' => 'Meroitisch',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Mongolisch',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Birmanisch',
 			'Narb' => 'Altnordarabisch',
 			'Nbat' => 'Nabatäisch',
 			'Nkgb' => 'Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Frauenschrift',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orchon-Runen',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmanisch',
 			'Palm' => 'Palmyrenisch',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Altpermisch',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Buch-Pahlavi',
 			'Phlp' => 'Psalter-Pahlavi',
 			'Phlv' => 'Pahlavi',
 			'Phnx' => 'Phönizisch',
 			'Plrd' => 'Pollard Phonetisch',
 			'Prti' => 'Parthisch',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runenschrift',
 			'Samr' => 'Samaritanisch',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Altsüdarabisch',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Gebärdensprache',
 			'Shaw' => 'Shaw-Alphabet',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Singhalesisch',
 			'Sora' => 'Sora Sompeng',
 			'Sund' => 'Sundanesisch',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syrisch',
 			'Syre' => 'Syrisch - Estrangelo-Variante',
 			'Syrj' => 'Westsyrisch',
 			'Syrn' => 'Ostsyrisch',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue',
 			'Taml' => 'Tamilisch',
 			'Tang' => 'Xixia',
 			'Tavt' => 'Tai-Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibetisch',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritisch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Sichtbare Sprache',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleaianisch',
 			'Xpeo' => 'Altpersisch',
 			'Xsux' => 'Sumerisch-akkadische Keilschrift',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Geerbter Schriftwert',
 			'Zmth' => 'Mathematische Notation',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Symbole',
 			'Zxxx' => 'Schriftlos',
 			'Zyyy' => 'Verbreitet',
 			'Zzzz' => 'Unbekannte Schrift',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'001' => 'Welt',
 			'002' => 'Afrika',
 			'003' => 'Nordamerika',
 			'005' => 'Südamerika',
 			'009' => 'Ozeanien',
 			'011' => 'Westafrika',
 			'013' => 'Mittelamerika',
 			'014' => 'Ostafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Zentralafrika',
 			'018' => 'Südliches Afrika',
 			'019' => 'Amerika',
 			'021' => 'Nördliches Amerika',
 			'029' => 'Karibik',
 			'030' => 'Ostasien',
 			'034' => 'Südasien',
 			'035' => 'Südostasien',
 			'039' => 'Südeuropa',
 			'053' => 'Australasien',
 			'054' => 'Melanesien',
 			'057' => 'Mikronesisches Inselgebiet',
 			'061' => 'Polynesien',
 			'142' => 'Asien',
 			'143' => 'Zentralasien',
 			'145' => 'Westasien',
 			'150' => 'Europa',
 			'151' => 'Osteuropa',
 			'154' => 'Nordeuropa',
 			'155' => 'Westeuropa',
 			'202' => 'Subsahara-Afrika',
 			'419' => 'Lateinamerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Vereinigte Arabische Emirate',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua und Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanien',
 			'AM' => 'Armenien',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinien',
 			'AS' => 'Amerikanisch-Samoa',
 			'AT' => 'Österreich',
 			'AU' => 'Australien',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandinseln',
 			'AZ' => 'Aserbaidschan',
 			'BA' => 'Bosnien und Herzegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belgien',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarien',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei Darussalam',
 			'BO' => 'Bolivien',
 			'BQ' => 'Bonaire, Sint Eustatius und Saba',
 			'BR' => 'Brasilien',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetinsel',
 			'BW' => 'Botsuana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosinseln',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (Demokratische Republik)',
 			'CF' => 'Zentralafrikanische Republik',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republik)',
 			'CH' => 'Schweiz',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Elfenbeinküste',
 			'CK' => 'Cookinseln',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbien',
 			'CP' => 'Clipperton-Insel',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Weihnachtsinsel',
 			'CY' => 'Zypern',
 			'CZ' => 'Tschechien',
 			'CZ@alt=variant' => 'Tschechische Republik',
 			'DE' => 'Deutschland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dschibuti',
 			'DK' => 'Dänemark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikanische Republik',
 			'DZ' => 'Algerien',
 			'EA' => 'Ceuta und Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Ägypten',
 			'EH' => 'Westsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanien',
 			'ET' => 'Äthiopien',
 			'EU' => 'Europäische Union',
 			'EZ' => 'Eurozone',
 			'FI' => 'Finnland',
 			'FJ' => 'Fidschi',
 			'FK' => 'Falklandinseln',
 			'FK@alt=variant' => 'Falklandinseln (Malwinen)',
 			'FM' => 'Mikronesien',
 			'FO' => 'Färöer',
 			'FR' => 'Frankreich',
 			'GA' => 'Gabun',
 			'GB' => 'Vereinigtes Königreich',
 			'GB@alt=short' => 'GB',
 			'GD' => 'Grenada',
 			'GE' => 'Georgien',
 			'GF' => 'Französisch-Guayana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Äquatorialguinea',
 			'GR' => 'Griechenland',
 			'GS' => 'Südgeorgien und die Südlichen Sandwichinseln',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Sonderverwaltungsregion Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard und McDonaldinseln',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanarische Inseln',
 			'ID' => 'Indonesien',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'Indien',
 			'IO' => 'Britisches Territorium im Indischen Ozean',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordanien',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoren',
 			'KN' => 'St. Kitts und Nevis',
 			'KP' => 'Nordkorea',
 			'KR' => 'Südkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Kaimaninseln',
 			'KZ' => 'Kasachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxemburg',
 			'LV' => 'Lettland',
 			'LY' => 'Libyen',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Republik Moldau',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallinseln',
 			'MK' => 'Mazedonien',
 			'MK@alt=variant' => 'Mazedonien (EJR)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolei',
 			'MO' => 'Sonderverwaltungsregion Macau',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Nördliche Marianen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediven',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Neukaledonien',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkinsel',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Niederlande',
 			'NO' => 'Norwegen',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neuseeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Französisch-Polynesien',
 			'PG' => 'Papua-Neuguinea',
 			'PH' => 'Philippinen',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'St. Pierre und Miquelon',
 			'PN' => 'Pitcairninseln',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palästinensische Autonomiegebiete',
 			'PS@alt=short' => 'Palästina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Äußeres Ozeanien',
 			'RE' => 'Réunion',
 			'RO' => 'Rumänien',
 			'RS' => 'Serbien',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabien',
 			'SB' => 'Salomonen',
 			'SC' => 'Seychellen',
 			'SD' => 'Sudan',
 			'SE' => 'Schweden',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Slowenien',
 			'SJ' => 'Spitzbergen und Jan Mayen',
 			'SK' => 'Slowakei',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Südsudan',
 			'ST' => 'São Tomé und Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syrien',
 			'SZ' => 'Swasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- und Caicosinseln',
 			'TD' => 'Tschad',
 			'TF' => 'Französische Süd- und Antarktisgebiete',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadschikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Osttimor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesien',
 			'TO' => 'Tonga',
 			'TR' => 'Türkei',
 			'TT' => 'Trinidad und Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikanische Überseeinseln',
 			'UN' => 'Vereinte Nationen',
 			'UN@alt=short' => 'UN',
 			'US' => 'Vereinigte Staaten',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstadt',
 			'VC' => 'St. Vincent und die Grenadinen',
 			'VE' => 'Venezuela',
 			'VG' => 'Britische Jungferninseln',
 			'VI' => 'Amerikanische Jungferninseln',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis und Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Südafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Unbekannte Region',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Alte deutsche Rechtschreibung',
 			'1994' => 'Standardisierte Resianische Rechtschreibung',
 			'1996' => 'Neue deutsche Rechtschreibung',
 			'1606NICT' => 'Spätes Mittelfranzösisch',
 			'1694ACAD' => 'Klassisches Französisch',
 			'1959ACAD' => 'Akademisch',
 			'AREVELA' => 'Ostarmenisch',
 			'AREVMDA' => 'Westarmenisch',
 			'BAKU1926' => 'Einheitliches Türkisches Alphabet',
 			'BISKE' => 'Bela-Dialekt',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'IPA Phonetisch',
 			'FONUPA' => 'Phonetisch (UPA)',
 			'KKCOR' => 'Allgemeine Rechtschreibung',
 			'LIPAW' => 'Lipovaz-Dialekt',
 			'MONOTON' => 'Monotonisch',
 			'NEDIS' => 'Natisone-Dialekt',
 			'NJIVA' => 'Njiva-Dialekt',
 			'OSOJS' => 'Osojane-Dialekt',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Polytonisch',
 			'POSIX' => 'Posix',
 			'REVISED' => 'Revidierte Rechtschreibung',
 			'ROZAJ' => 'Resianisch',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schottisches Standardenglisch',
 			'SCOUSE' => 'Scouse-Dialekt',
 			'SOLBA' => 'Solbica-Dialekt',
 			'TARASK' => 'Taraskievica-Orthographie',
 			'UCCOR' => 'Vereinheitlichte Rechtschreibung',
 			'UCRCOR' => 'Vereinheitlichte überarbeitete Rechtschreibung',
 			'VALENCIA' => 'Valencianisch',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Kalender',
 			'cf' => 'Währungsformat',
 			'colalternate' => 'Sortierung ohne Symbole',
 			'colbackwards' => 'Umgekehrte Sortierung von Akzenten',
 			'colcasefirst' => 'Sortierung nach Groß- bzw. Kleinbuchstaben',
 			'colcaselevel' => 'Sortierung nach Groß- oder Kleinschreibung',
 			'collation' => 'Sortierung',
 			'colnormalization' => 'Normierte Sortierung',
 			'colnumeric' => 'Sortierung nach Zahlen',
 			'colstrength' => 'Sortierstärke',
 			'currency' => 'Währung',
 			'hc' => 'Stundenformat (12h/24h)',
 			'lb' => 'Zeilenumbruchstil',
 			'ms' => 'Maßsystem',
 			'numbers' => 'Zahlen',
 			'timezone' => 'Zeitzone',
 			'va' => 'Lokale Variante',
 			'x' => 'Privatnutzung',

		}
	},
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => {
 				'buddhist' => q{Buddhistischer Kalender},
 				'chinese' => q{Chinesischer Kalender},
 				'coptic' => q{Koptischer Kalender},
 				'dangi' => q{Dangi-Kalender},
 				'ethiopic' => q{Äthiopischer Kalender},
 				'ethiopic-amete-alem' => q{Äthiopischer Kalender "Amete Alem"},
 				'gregorian' => q{Gregorianischer Kalender},
 				'hebrew' => q{Hebräischer Kalender},
 				'indian' => q{Indischer Nationalkalender},
 				'islamic' => q{Islamischer Kalender},
 				'islamic-civil' => q{Bürgerlicher islamischer Kalender},
 				'islamic-rgsa' => q{Islamischer Kalender (Saudi-Arabien, Beobachtung)},
 				'islamic-tbla' => q{Islamischer Kalender (tabellarisch, astronomische Epoche)},
 				'islamic-umalqura' => q{Islamischer Kalender (Umm al-Qura},
 				'iso8601' => q{ISO-8601-Kalender},
 				'japanese' => q{Japanischer Kalender},
 				'persian' => q{Persischer Kalender},
 				'roc' => q{Kalender der Republik China},
 			},
 			'cf' => {
 				'account' => q{Währungsformat (Buchhaltung)},
 				'standard' => q{Währungsformat (Standard)},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Symbole sortieren},
 				'shifted' => q{Symbole sortieren ignorieren},
 			},
 			'colbackwards' => {
 				'no' => q{Akzente normal sortieren},
 				'yes' => q{Akzente umgekehrt sortieren},
 			},
 			'colcasefirst' => {
 				'lower' => q{Kleinbuchstaben zuerst aufführen},
 				'no' => q{Normal sortieren},
 				'upper' => q{Großbuchstaben zuerst aufführen},
 			},
 			'colcaselevel' => {
 				'no' => q{Ohne Groß-/Kleinschreibung sortieren},
 				'yes' => q{Nach Groß-/Kleinschreibung sortieren},
 			},
 			'collation' => {
 				'big5han' => q{Traditionelles Chinesisch - Big5},
 				'compat' => q{vorherige Sortierung, Kompatibilität},
 				'dictionary' => q{Lexikographische Sortierreihenfolge},
 				'ducet' => q{Unicode-Sortierung},
 				'eor' => q{Europäische Sortierregeln},
 				'gb2312han' => q{Vereinfachtes Chinesisch - GB2312},
 				'phonebook' => q{Telefonbuch-Sortierung},
 				'phonetic' => q{Sortierung nach Phonetik},
 				'pinyin' => q{Pinyin-Sortierregeln},
 				'reformed' => q{Reformierte Sortierreihenfolge},
 				'search' => q{allgemeine Suche},
 				'searchjl' => q{Suche nach Anfangsbuchstaben des koreanischen Alphabets},
 				'standard' => q{Standard-Sortierung},
 				'stroke' => q{Strichfolge},
 				'traditional' => q{Traditionelle Sortierregeln},
 				'unihan' => q{Radikal-Strich-Sortierregeln},
 				'zhuyin' => q{Zhuyin-Sortierregeln},
 			},
 			'colnormalization' => {
 				'no' => q{Ohne Normierung sortieren},
 				'yes' => q{Nach Unicode sortieren},
 			},
 			'colnumeric' => {
 				'no' => q{Ziffern einzeln sortieren},
 				'yes' => q{Ziffern numerisch sortieren},
 			},
 			'colstrength' => {
 				'identical' => q{Alle sortieren},
 				'primary' => q{Nur Basisbuchstaben sortieren},
 				'quaternary' => q{Akzente/Fall/Breite/Kana sortieren},
 				'secondary' => q{Akzente sortieren},
 				'tertiary' => q{Akzente/Fall/Breite sortieren},
 			},
 			'd0' => {
 				'fwidth' => q{Breit},
 				'hwidth' => q{Halbe Breite},
 				'npinyin' => q{Numerisch},
 			},
 			'hc' => {
 				'h11' => q{12-Stunden-Format (0-11)},
 				'h12' => q{12-Stunden-Format (1-12)},
 				'h23' => q{24-Stunden-Format (0-23)},
 				'h24' => q{24-Stunden-Format (1-24)},
 			},
 			'lb' => {
 				'loose' => q{lockerer Zeilenumbruch},
 				'normal' => q{normaler Zeilenumbruch},
 				'strict' => q{fester Zeilenumbruch},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{metrisches System},
 				'uksystem' => q{britisches Maßsystem},
 				'ussystem' => q{US-Maßsystem},
 			},
 			'numbers' => {
 				'arab' => q{Arabisch-indische Ziffern},
 				'arabext' => q{Erweiterte arabisch-indische Ziffern},
 				'armn' => q{Armenische Ziffern},
 				'armnlow' => q{Armenische Ziffern in Kleinschrift},
 				'bali' => q{Balinesische Ziffern},
 				'beng' => q{Bengalische Ziffern},
 				'brah' => q{Brahmi-Ziffern},
 				'cakm' => q{Chakma-Ziffern},
 				'cham' => q{Cham-Ziffern},
 				'deva' => q{Devanagari-Ziffern},
 				'ethi' => q{Äthiopische Ziffern},
 				'finance' => q{Finanzzahlen},
 				'fullwide' => q{Vollbreite Ziffern},
 				'geor' => q{Georgische Ziffern},
 				'grek' => q{Griechische Ziffern},
 				'greklow' => q{Griechische Ziffern in Kleinschrift},
 				'gujr' => q{Gujarati-Ziffern},
 				'guru' => q{Gurmukhi-Ziffern},
 				'hanidec' => q{Chinesische Dezimalzahlen},
 				'hans' => q{Vereinfacht-chinesische Ziffern},
 				'hansfin' => q{Vereinfacht-chinesische Finanzziffern},
 				'hant' => q{Traditionell-chinesische Ziffern},
 				'hantfin' => q{Traditionell-chinesische Finanzziffern},
 				'hebr' => q{Hebräische Ziffern},
 				'java' => q{Javanesische Ziffern},
 				'jpan' => q{Japanische Ziffern},
 				'jpanfin' => q{Japanische Finanzziffern},
 				'kali' => q{Kayah-Li-Ziffern},
 				'khmr' => q{Khmer-Ziffern},
 				'knda' => q{Kannada-Ziffern},
 				'lana' => q{Lanna-Ziffern (säkular)},
 				'lanatham' => q{Lanna-Ziffern (sakral)},
 				'laoo' => q{Laotische Ziffern},
 				'latn' => q{Westliche Ziffern},
 				'lepc' => q{Lepcha-Ziffern},
 				'limb' => q{Limbu-Ziffern},
 				'mlym' => q{Malayalam-Ziffern},
 				'mong' => q{Mongolische Ziffern},
 				'mtei' => q{Meitei-Mayek-Ziffern},
 				'mymr' => q{Myanmar-Ziffern},
 				'mymrshan' => q{Myanmarische Shan-Ziffern},
 				'native' => q{Native Ziffern},
 				'nkoo' => q{N’Ko-Ziffern},
 				'olck' => q{Ol-Chiki-Ziffern},
 				'orya' => q{Oriya-Ziffern},
 				'roman' => q{Römische Ziffern},
 				'romanlow' => q{Römische Ziffern in Kleinschrift},
 				'saur' => q{Saurashtra-Ziffern},
 				'shrd' => q{Sharada-Ziffern},
 				'sora' => q{Sora-Sompeng-Ziffern},
 				'sund' => q{Sundanesische Ziffern},
 				'takr' => q{Takri-Ziffern},
 				'talu' => q{Neue Tai-Lü-Ziffern},
 				'taml' => q{Tamilische Ziffern},
 				'tamldec' => q{Tamil-Ziffern},
 				'telu' => q{Telugu-Ziffern},
 				'thai' => q{Thai-Ziffern},
 				'tibt' => q{Tibetische Ziffern},
 				'traditional' => q{Traditionelle Zahlen},
 				'vaii' => q{Vai-Ziffern},
 			},

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{Internationales (SI)},
 			'UK' => q{Englisches},
 			'US' => q{Angloamerikanisches},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Sprache: {0}',
 			'script' => 'Schrift: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[á à ă â å ã ā æ ç é è ĕ ê ë ē ğ í ì ĭ î ï İ ī ı ñ ó ò ŏ ô ø ō œ ş ú ù ŭ û ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ä b c d e f g h i j k l m n o ö p q r s ß t u ü v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
		};
	},
);

has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{?},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h:mm',
				hms => 'h:mm:ss',
				ms => 'm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'' => {
						'name' => q(Himmelsrichtung),
					},
					'acre' => {
						'name' => q(Acres),
						'one' => q({0} Acre),
						'other' => q({0} Acres),
					},
					'acre-foot' => {
						'name' => q(Acre-Feet),
						'one' => q({0} Acre-Foot),
						'other' => q({0} Acre-Feet),
					},
					'ampere' => {
						'name' => q(Ampere),
						'one' => q({0} Ampere),
						'other' => q({0} Ampere),
					},
					'arc-minute' => {
						'name' => q(Winkelminuten),
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminuten),
					},
					'arc-second' => {
						'name' => q(Winkelsekunden),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunden),
					},
					'astronomical-unit' => {
						'name' => q(Astronomische Einheiten),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'atmosphere' => {
						'name' => q(Atmosphären),
						'one' => q({0} Atmosphäre),
						'other' => q({0} Atmosphären),
					},
					'bit' => {
						'name' => q(Bits),
						'one' => q({0} Bit),
						'other' => q({0} Bits),
					},
					'bushel' => {
						'name' => q(Bushel),
						'one' => q({0} Bushel),
						'other' => q({0} Bushel),
					},
					'byte' => {
						'name' => q(Bytes),
						'one' => q({0} Byte),
						'other' => q({0} Bytes),
					},
					'calorie' => {
						'name' => q(Kalorien),
						'one' => q({0} Kalorie),
						'other' => q({0} Kalorien),
					},
					'carat' => {
						'name' => q(Karat),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					'celsius' => {
						'name' => q(Grad Celsius),
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					'centiliter' => {
						'name' => q(Zentiliter),
						'one' => q({0} Zentiliter),
						'other' => q({0} Zentiliter),
					},
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
						'per' => q({0} pro Zentimeter),
					},
					'century' => {
						'name' => q(Jahrhunderte),
						'one' => q({0} Jahrhundert),
						'other' => q({0} Jahrhunderte),
					},
					'coordinate' => {
						'east' => q({0} Ost),
						'north' => q({0} Nord),
						'south' => q({0} Süd),
						'west' => q({0} West),
					},
					'cubic-centimeter' => {
						'name' => q(Kubikzentimeter),
						'one' => q({0} Kubikzentimeter),
						'other' => q({0} Kubikzentimeter),
						'per' => q({0} pro Kubikzentimeter),
					},
					'cubic-foot' => {
						'name' => q(Kubikfuß),
						'one' => q({0} Kubikfuß),
						'other' => q({0} Kubikfuß),
					},
					'cubic-inch' => {
						'name' => q(Kubikzoll),
						'one' => q({0} Kubikzoll),
						'other' => q({0} Kubikzoll),
					},
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					'cubic-meter' => {
						'name' => q(Kubikmeter),
						'one' => q({0} Kubikmeter),
						'other' => q({0} Kubikmeter),
						'per' => q({0} pro Kubikmeter),
					},
					'cubic-mile' => {
						'name' => q(Kubikmeilen),
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeilen),
					},
					'cubic-yard' => {
						'name' => q(Kubikyards),
						'one' => q({0} Kubikyard),
						'other' => q({0} Kubikyards),
					},
					'cup' => {
						'name' => q(Cups),
						'one' => q({0} Cup),
						'other' => q({0} Cups),
					},
					'cup-metric' => {
						'name' => q(Tasse),
						'one' => q({0} Tasse),
						'other' => q({0} Tassen),
					},
					'day' => {
						'name' => q(Tage),
						'one' => q({0} Tag),
						'other' => q({0} Tage),
						'per' => q({0} pro Tag),
					},
					'deciliter' => {
						'name' => q(Deziliter),
						'one' => q({0} Deziliter),
						'other' => q({0} Deziliter),
					},
					'decimeter' => {
						'name' => q(Dezimeter),
						'one' => q({0} Dezimeter),
						'other' => q({0} Dezimeter),
					},
					'degree' => {
						'name' => q(Grad),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					'fahrenheit' => {
						'name' => q(Grad Fahrenheit),
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					'fathom' => {
						'name' => q(Nautischer Faden),
						'one' => q({0} Faden),
						'other' => q({0} Faden),
					},
					'fluid-ounce' => {
						'name' => q(Flüssigunzen),
						'one' => q({0} Flüssigunze),
						'other' => q({0} Flüssigunzen),
					},
					'foodcalorie' => {
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorien),
						'other' => q({0} Kilokalorien),
					},
					'foot' => {
						'name' => q(Fuß),
						'one' => q({0} Fuß),
						'other' => q({0} Fuß),
						'per' => q({0} pro Fuß),
					},
					'furlong' => {
						'name' => q(Furlong),
						'one' => q({0} Furlong),
						'other' => q({0} Furlong),
					},
					'g-force' => {
						'name' => q(g-Kraft),
						'one' => q({0}-fache Erdbeschleunigung),
						'other' => q({0}-fache Erdbeschleunigung),
					},
					'gallon' => {
						'name' => q(Gallonen),
						'one' => q({0} Gallone),
						'other' => q({0} Gallonen),
						'per' => q({0} pro Gallone),
					},
					'gallon-imperial' => {
						'name' => q(Imp. Gallone),
						'one' => q({0} Imp. Gallone),
						'other' => q({0} Imp. Gallonen),
						'per' => q({0} pro Imp. Gallone),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gigabits),
						'one' => q({0} Gigabit),
						'other' => q({0} Gigabits),
					},
					'gigabyte' => {
						'name' => q(Gigabytes),
						'one' => q({0} Gigabyte),
						'other' => q({0} Gigabytes),
					},
					'gigahertz' => {
						'name' => q(Gigahertz),
						'one' => q({0} Gigahertz),
						'other' => q({0} Gigahertz),
					},
					'gigawatt' => {
						'name' => q(Gigawatt),
						'one' => q({0} Gigawatt),
						'other' => q({0} Gigawatt),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
						'per' => q({0} pro Gramm),
					},
					'hectare' => {
						'name' => q(Hektar),
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					'hectoliter' => {
						'name' => q(Hektoliter),
						'one' => q({0} Hektoliter),
						'other' => q({0} Hektoliter),
					},
					'hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					'hertz' => {
						'name' => q(Hertz),
						'one' => q({0} Hertz),
						'other' => q({0} Hertz),
					},
					'horsepower' => {
						'name' => q(Pferdestärken),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärken),
					},
					'hour' => {
						'name' => q(Stunden),
						'one' => q({0} Stunde),
						'other' => q({0} Stunden),
						'per' => q({0} pro Stunde),
					},
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
						'per' => q({0} pro Zoll),
					},
					'inch-hg' => {
						'name' => q(Zoll Quecksilbersäule),
						'one' => q({0} Zoll Quecksilbersäule),
						'other' => q({0} Zoll Quecksilbersäule),
					},
					'joule' => {
						'name' => q(Joule),
						'one' => q({0} Joule),
						'other' => q({0} Joule),
					},
					'karat' => {
						'name' => q(Karat),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					'kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					'kilobit' => {
						'name' => q(Kilobits),
						'one' => q({0} Kilobit),
						'other' => q({0} Kilobits),
					},
					'kilobyte' => {
						'name' => q(Kilobytes),
						'one' => q({0} Kilobyte),
						'other' => q({0} Kilobytes),
					},
					'kilocalorie' => {
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
						'per' => q({0} pro Kilogramm),
					},
					'kilohertz' => {
						'name' => q(Kilohertz),
						'one' => q({0} Kilohertz),
						'other' => q({0} Kilohertz),
					},
					'kilojoule' => {
						'name' => q(Kilojoule),
						'one' => q({0} Kilojoule),
						'other' => q({0} Kilojoule),
					},
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
						'per' => q({0} pro Kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Stunde),
						'one' => q({0} Kilometer pro Stunde),
						'other' => q({0} Kilometer pro Stunde),
					},
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(Kilowattstunden),
						'one' => q({0} Kilowattstunde),
						'other' => q({0} Kilowattstunden),
					},
					'knot' => {
						'name' => q(Knoten),
						'one' => q({0} Knoten),
						'other' => q({0} Knoten),
					},
					'light-year' => {
						'name' => q(Lichtjahre),
						'one' => q({0} Lichtjahr),
						'other' => q({0} Lichtjahre),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
						'per' => q({0} pro Liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(Liter auf 100 Kilometer),
						'one' => q({0} Liter auf 100 Kilometer),
						'other' => q({0} Liter auf 100 Kilometer),
					},
					'liter-per-kilometer' => {
						'name' => q(Liter pro Kilometer),
						'one' => q({0} Liter pro Kilometer),
						'other' => q({0} Liter pro Kilometer),
					},
					'lux' => {
						'name' => q(Lux),
						'one' => q({0} Lux),
						'other' => q({0} Lux),
					},
					'megabit' => {
						'name' => q(Megabits),
						'one' => q({0} Megabit),
						'other' => q({0} Megabits),
					},
					'megabyte' => {
						'name' => q(Megabytes),
						'one' => q({0} Megabyte),
						'other' => q({0} Megabytes),
					},
					'megahertz' => {
						'name' => q(Megahertz),
						'one' => q({0} Megahertz),
						'other' => q({0} Megahertz),
					},
					'megaliter' => {
						'name' => q(Megaliter),
						'one' => q({0} Megaliter),
						'other' => q({0} Megaliter),
					},
					'megawatt' => {
						'name' => q(Megawatt),
						'one' => q({0} Megawatt),
						'other' => q({0} Megawatt),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
						'per' => q({0} pro Meter),
					},
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					'meter-per-second-squared' => {
						'name' => q(Meter pro Quadratsekunde),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(Tonnen),
						'one' => q({0} Tonne),
						'other' => q({0} Tonnen),
					},
					'microgram' => {
						'name' => q(Mikrogramm),
						'one' => q({0} Mikrogramm),
						'other' => q({0} Mikrogramm),
					},
					'micrometer' => {
						'name' => q(Mikrometer),
						'one' => q({0} Mikrometer),
						'other' => q({0} Mikrometer),
					},
					'microsecond' => {
						'name' => q(Mikrosekunden),
						'one' => q({0} Mikrosekunde),
						'other' => q({0} Mikrosekunden),
					},
					'mile' => {
						'name' => q(Meilen),
						'one' => q({0} Meile),
						'other' => q({0} Meilen),
					},
					'mile-per-gallon' => {
						'name' => q(Meilen pro Gallone),
						'one' => q({0} Meile pro Gallone),
						'other' => q({0} Meilen pro Gallone),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(Meilen pro Imp. Gallone),
						'one' => q({0} Meile pro Imp. Gallone),
						'other' => q({0} Meilen pro Imp. Gallone),
					},
					'mile-per-hour' => {
						'name' => q(Meilen pro Stunde),
						'one' => q({0} Meile pro Stunde),
						'other' => q({0} Meilen pro Stunde),
					},
					'mile-scandinavian' => {
						'name' => q(skandinavische Meilen),
						'one' => q({0} skandinavische Meile),
						'other' => q({0} skandinavische Meilen),
					},
					'milliampere' => {
						'name' => q(Milliampere),
						'one' => q({0} Milliampere),
						'other' => q({0} Milliampere),
					},
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					'milligram' => {
						'name' => q(Milligramm),
						'one' => q({0} Milligramm),
						'other' => q({0} Milligramm),
					},
					'milligram-per-deciliter' => {
						'name' => q(Milligramm pro Deziliter),
						'one' => q({0} Milligramm pro Deziliter),
						'other' => q({0} Milligramm pro Deziliter),
					},
					'milliliter' => {
						'name' => q(Milliliter),
						'one' => q({0} Milliliter),
						'other' => q({0} Milliliter),
					},
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(Millimeter Quecksilbersäule),
						'one' => q({0} Millimeter Quecksilbersäule),
						'other' => q({0} Millimeter Quecksilbersäule),
					},
					'millimole-per-liter' => {
						'name' => q(Millimol pro Liter),
						'one' => q({0} Millimol pro Liter),
						'other' => q({0} Millimol pro Liter),
					},
					'millisecond' => {
						'name' => q(Millisekunden),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunden),
					},
					'milliwatt' => {
						'name' => q(Milliwatt),
						'one' => q({0} Milliwatt),
						'other' => q({0} Milliwatt),
					},
					'minute' => {
						'name' => q(Minuten),
						'one' => q({0} Minute),
						'other' => q({0} Minuten),
						'per' => q({0} pro Minute),
					},
					'month' => {
						'name' => q(Monate),
						'one' => q({0} Monat),
						'other' => q({0} Monate),
						'per' => q({0} pro Monat),
					},
					'nanometer' => {
						'name' => q(Nanometer),
						'one' => q({0} Nanometer),
						'other' => q({0} Nanometer),
					},
					'nanosecond' => {
						'name' => q(Nanosekunden),
						'one' => q({0} Nanosekunde),
						'other' => q({0} Nanosekunden),
					},
					'nautical-mile' => {
						'name' => q(Seemeilen),
						'one' => q({0} Seemeile),
						'other' => q({0} Seemeilen),
					},
					'ohm' => {
						'name' => q(Ohm),
						'one' => q({0} Ohm),
						'other' => q({0} Ohm),
					},
					'ounce' => {
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'per' => q({0} pro Unze),
					},
					'ounce-troy' => {
						'name' => q(Feinunzen),
						'one' => q({0} Feinunze),
						'other' => q({0} Feinunzen),
					},
					'parsec' => {
						'name' => q(Parsec),
						'one' => q({0} Parsec),
						'other' => q({0} Parsec),
					},
					'part-per-million' => {
						'name' => q(Parts per million),
						'one' => q({0} Parts per million),
						'other' => q({0} Parts per million),
					},
					'per' => {
						'1' => q({0} pro {1}),
					},
					'percent' => {
						'name' => q(Prozent),
						'one' => q({0} Prozent),
						'other' => q({0} Prozent),
					},
					'permille' => {
						'name' => q(Promille),
						'one' => q({0} Promille),
						'other' => q({0} Promille),
					},
					'petabyte' => {
						'name' => q(Petabytes),
						'one' => q({0} Petabyte),
						'other' => q({0} Petabytes),
					},
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					'pint' => {
						'name' => q(Pints),
						'one' => q({0} Pint),
						'other' => q({0} Pints),
					},
					'pint-metric' => {
						'name' => q(metrische Pints),
						'one' => q({0} metrisches Pint),
						'other' => q({0} metrische Pints),
					},
					'point' => {
						'name' => q(Punkte),
						'one' => q({0} Punkt),
						'other' => q({0} Punkte),
					},
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'per' => q({0} pro Pfund),
					},
					'pound-per-square-inch' => {
						'name' => q(Pfund pro Quadratzoll),
						'one' => q({0} Pfund pro Quadratzoll),
						'other' => q({0} Pfund pro Quadratzoll),
					},
					'quart' => {
						'name' => q(Quart),
						'one' => q({0} Quart),
						'other' => q({0} Quart),
					},
					'radian' => {
						'name' => q(Radianten),
						'one' => q({0} Radiant),
						'other' => q({0} Radianten),
					},
					'revolution' => {
						'name' => q(Umdrehung),
						'one' => q({0} Umdrehung),
						'other' => q({0} Umdrehungen),
					},
					'second' => {
						'name' => q(Sekunden),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunden),
						'per' => q({0} pro Sekunde),
					},
					'square-centimeter' => {
						'name' => q(Quadratzentimeter),
						'one' => q({0} Quadratzentimeter),
						'other' => q({0} Quadratzentimeter),
						'per' => q({0} pro Quadratzentimeter),
					},
					'square-foot' => {
						'name' => q(Quadratfuß),
						'one' => q({0} Quadratfuß),
						'other' => q({0} Quadratfuß),
					},
					'square-inch' => {
						'name' => q(Quadratzoll),
						'one' => q({0} Quadratzoll),
						'other' => q({0} Quadratzoll),
						'per' => q({0} pro Quadratzoll),
					},
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
						'per' => q({0} pro Quadratkilometer),
					},
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
						'per' => q({0} pro Quadratmeter),
					},
					'square-mile' => {
						'name' => q(Quadratmeilen),
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeilen),
						'per' => q({0} pro Quadratmeile),
					},
					'square-yard' => {
						'name' => q(Quadratyards),
						'one' => q({0} Quadratyard),
						'other' => q({0} Quadratyards),
					},
					'stone' => {
						'name' => q(Stones),
						'one' => q({0} Stone),
						'other' => q({0} Stones),
					},
					'tablespoon' => {
						'name' => q(Esslöffel),
						'one' => q({0} Esslöffel),
						'other' => q({0} Esslöffel),
					},
					'teaspoon' => {
						'name' => q(Teelöffel),
						'one' => q({0} Teelöffel),
						'other' => q({0} Teelöffel),
					},
					'terabit' => {
						'name' => q(Terabits),
						'one' => q({0} Terabit),
						'other' => q({0} Terabits),
					},
					'terabyte' => {
						'name' => q(Terabytes),
						'one' => q({0} Terabyte),
						'other' => q({0} Terabytes),
					},
					'ton' => {
						'name' => q(Short Tons),
						'one' => q({0} Short Ton),
						'other' => q({0} Short Tons),
					},
					'volt' => {
						'name' => q(Volt),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					'week' => {
						'name' => q(Wochen),
						'one' => q({0} Woche),
						'other' => q({0} Wochen),
						'per' => q({0} pro Woche),
					},
					'yard' => {
						'name' => q(Yards),
						'one' => q({0} Yard),
						'other' => q({0} Yards),
					},
					'year' => {
						'name' => q(Jahre),
						'one' => q({0} Jahr),
						'other' => q({0} Jahre),
						'per' => q({0} pro Jahr),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(NOSW),
					},
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'bit' => {
						'one' => q({0} Bit),
						'other' => q({0} Bits),
					},
					'bushel' => {
						'name' => q(Bushel),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'one' => q({0} Byte),
						'other' => q({0} Bytes),
					},
					'calorie' => {
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(Karat),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centiliter' => {
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(Jh.),
						'one' => q({0} Jh.),
						'other' => q({0} Jh.),
					},
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'one' => q({0} Cup),
						'other' => q({0} Cups),
					},
					'day' => {
						'name' => q(T),
						'one' => q({0} T),
						'other' => q({0} T),
						'per' => q({0}/T),
					},
					'deciliter' => {
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(Faden),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(Furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(g-Kraft),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'name' => q(Std.),
						'one' => q({0} Std.),
						'other' => q({0} Std.),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'milliliter' => {
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(Min.),
						'one' => q({0} Min.),
						'other' => q({0} Min.),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
						'per' => q({0}/M),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					'ohm' => {
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(Unzen),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz.tr.),
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'second' => {
						'name' => q(Sek.),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'one' => q({0} in²),
						'other' => q({0} in²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'square-yard' => {
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(Stones),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'one' => q({0} EL),
						'other' => q({0} EL),
					},
					'teaspoon' => {
						'one' => q({0} TL),
						'other' => q({0} TL),
					},
					'terabit' => {
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(Tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
						'per' => q({0}/W),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'per' => q({0}/J),
					},
				},
				'short' => {
					'' => {
						'name' => q(Richtung),
					},
					'acre' => {
						'name' => q(Acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(Acre-Feet),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(Ampere),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(Winkelminuten),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(Winkelsekunden),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(Bit),
						'one' => q({0} Bit),
						'other' => q({0} Bits),
					},
					'bushel' => {
						'name' => q(Bushel),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(Byte),
						'one' => q({0} Byte),
						'other' => q({0} Bytes),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(Karat),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(Jh.),
						'one' => q({0} Jh.),
						'other' => q({0} Jh.),
					},
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(Cups),
						'one' => q({0} Cup),
						'other' => q({0} Cups),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(Tg.),
						'one' => q({0} Tg.),
						'other' => q({0} Tg.),
						'per' => q({0}/T),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(Grad),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(Faden),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(Fuß),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(Furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(g-Kraft),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} Imp. gal),
						'other' => q({0} Imp. gal),
						'per' => q({0} pro Imp. gal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gigabit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(Gigabyte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(Hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(Pferdestärken),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'name' => q(Std.),
						'one' => q({0} Std.),
						'other' => q({0} Std.),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
						'per' => q({0}/Zoll),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(Joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(Karat),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kbyte),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(Kilojoule),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(Lichtjahre),
						'one' => q({0} Lj),
						'other' => q({0} Lj),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(Lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(Mbyte),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(Meilen),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(Meilen/ Imp. Gal.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(Millimol/Liter),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(Min.),
						'one' => q({0} Min.),
						'other' => q({0} Min.),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(Mon.),
						'one' => q({0} Mon.),
						'other' => q({0} Mon.),
						'per' => q({0}/M),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					'ohm' => {
						'name' => q(Ohm),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(Unzen),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz.tr.),
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					'parsec' => {
						'name' => q(Parsec),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(parts/million),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(Pints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(metr. Pints),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(Quart),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(Umdr.),
						'one' => q({0} Umdr.),
						'other' => q({0} Umdr.),
					},
					'second' => {
						'name' => q(Sek.),
						'one' => q({0} Sek.),
						'other' => q({0} Sek.),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(Stones),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(EL),
						'one' => q({0} EL),
						'other' => q({0} EL),
					},
					'teaspoon' => {
						'name' => q(TL),
						'one' => q({0} TL),
						'other' => q({0} TL),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(Tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(Volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(Wo.),
						'one' => q({0} Wo.),
						'other' => q({0} Wo.),
						'per' => q({0}/W),
					},
					'yard' => {
						'name' => q(Yards),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'per' => q({0}/J),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nein|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} und {1}),
				2 => q({0}, {1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'latn',
);

has 'minimum_grouping_digits' => (
	is			=>'ro',
	isa			=> Int,
	init_arg	=> undef,
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(·),
			'timeSeparator' => q(:),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'default' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 Mio'.'',
					'other' => '0 Mio'.'',
				},
				'10000000' => {
					'one' => '00 Mio'.'',
					'other' => '00 Mio'.'',
				},
				'100000000' => {
					'one' => '000 Mio'.'',
					'other' => '000 Mio'.'',
				},
				'1000000000' => {
					'one' => '0 Mrd'.'',
					'other' => '0 Mrd'.'',
				},
				'10000000000' => {
					'one' => '00 Mrd'.'',
					'other' => '00 Mrd'.'',
				},
				'100000000000' => {
					'one' => '000 Mrd'.'',
					'other' => '000 Mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 Bio'.'',
					'other' => '0 Bio'.'',
				},
				'10000000000000' => {
					'one' => '00 Bio'.'',
					'other' => '00 Bio'.'',
				},
				'100000000000000' => {
					'one' => '000 Bio'.'',
					'other' => '000 Bio'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 Tausend',
					'other' => '0 Tausend',
				},
				'10000' => {
					'one' => '00 Tausend',
					'other' => '00 Tausend',
				},
				'100000' => {
					'one' => '000 Tausend',
					'other' => '000 Tausend',
				},
				'1000000' => {
					'one' => '0 Million',
					'other' => '0 Millionen',
				},
				'10000000' => {
					'one' => '00 Millionen',
					'other' => '00 Millionen',
				},
				'100000000' => {
					'one' => '000 Millionen',
					'other' => '000 Millionen',
				},
				'1000000000' => {
					'one' => '0 Milliarde',
					'other' => '0 Milliarden',
				},
				'10000000000' => {
					'one' => '00 Milliarden',
					'other' => '00 Milliarden',
				},
				'100000000000' => {
					'one' => '000 Milliarden',
					'other' => '000 Milliarden',
				},
				'1000000000000' => {
					'one' => '0 Billion',
					'other' => '0 Billionen',
				},
				'10000000000000' => {
					'one' => '00 Billionen',
					'other' => '00 Billionen',
				},
				'100000000000000' => {
					'one' => '000 Billionen',
					'other' => '000 Billionen',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 Mio'.'',
					'other' => '0 Mio'.'',
				},
				'10000000' => {
					'one' => '00 Mio'.'',
					'other' => '00 Mio'.'',
				},
				'100000000' => {
					'one' => '000 Mio'.'',
					'other' => '000 Mio'.'',
				},
				'1000000000' => {
					'one' => '0 Mrd'.'',
					'other' => '0 Mrd'.'',
				},
				'10000000000' => {
					'one' => '00 Mrd'.'',
					'other' => '00 Mrd'.'',
				},
				'100000000000' => {
					'one' => '000 Mrd'.'',
					'other' => '000 Mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 Bio'.'',
					'other' => '0 Bio'.'',
				},
				'10000000000000' => {
					'one' => '00 Bio'.'',
					'other' => '00 Bio'.'',
				},
				'100000000000000' => {
					'one' => '000 Bio'.'',
					'other' => '000 Bio'.'',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0 %',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'default' => '#E0',
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
					'accounting' => {
						'positive' => '#,##0.00 ¤',
					},
					'standard' => {
						'positive' => '#,##0.00 ¤',
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
		'ADP' => {
			symbol => 'ADP',
			display_name => {
				'currency' => q(Andorranische Pesete),
				'one' => q(Andorranische Pesete),
				'other' => q(Andorranische Peseten),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(VAE-Dirham),
				'one' => q(VAE-Dirham),
				'other' => q(VAE-Dirham),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afghanische Afghani \(1927–2002\)),
				'one' => q(Afghanische Afghani \(1927–2002\)),
				'other' => q(Afghanische Afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghanischer Afghani),
				'one' => q(Afghanischer Afghani),
				'other' => q(Afghanische Afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albanischer Lek \(1946–1965\)),
				'one' => q(Albanischer Lek \(1946–1965\)),
				'other' => q(Albanische Lek \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albanischer Lek),
				'one' => q(Albanischer Lek),
				'other' => q(Albanische Lek),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armenischer Dram),
				'one' => q(Armenischer Dram),
				'other' => q(Armenische Dram),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Niederländische-Antillen-Gulden),
				'one' => q(Niederländische-Antillen-Gulden),
				'other' => q(Niederländische-Antillen-Gulden),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angolanischer Kwanza),
				'one' => q(Angolanischer Kwanza),
				'other' => q(Angolanische Kwanza),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(Angolanischer Kwanza \(1977–1990\)),
				'one' => q(Angolanischer Kwanza \(1977–1990\)),
				'other' => q(Angolanische Kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(Angolanischer Neuer Kwanza \(1990–2000\)),
				'one' => q(Angolanischer Neuer Kwanza \(1990–2000\)),
				'other' => q(Angolanische Neue Kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(Angolanischer Kwanza Reajustado \(1995–1999\)),
				'one' => q(Angolanischer Kwanza Reajustado \(1995–1999\)),
				'other' => q(Angolanische Kwanza Reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(Argentinischer Austral),
				'one' => q(Argentinischer Austral),
				'other' => q(Argentinische Austral),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(Argentinischer Peso Ley \(1970–1983\)),
				'one' => q(Argentinischer Peso Ley \(1970–1983\)),
				'other' => q(Argentinische Pesos Ley \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(Argentinischer Peso \(1881–1970\)),
				'one' => q(Argentinischer Peso \(1881–1970\)),
				'other' => q(Argentinische Pesos \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(Argentinischer Peso \(1983–1985\)),
				'one' => q(Argentinischer Peso \(1983–1985\)),
				'other' => q(Argentinische Peso \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentinischer Peso),
				'one' => q(Argentinischer Peso),
				'other' => q(Argentinische Pesos),
			},
		},
		'ATS' => {
			symbol => 'öS',
			display_name => {
				'currency' => q(Österreichischer Schilling),
				'one' => q(Österreichischer Schilling),
				'other' => q(Österreichische Schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australischer Dollar),
				'one' => q(Australischer Dollar),
				'other' => q(Australische Dollar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruba-Florin),
				'one' => q(Aruba-Florin),
				'other' => q(Aruba-Florin),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(Aserbaidschan-Manat \(1993–2006\)),
				'one' => q(Aserbaidschan-Manat \(1993–2006\)),
				'other' => q(Aserbaidschan-Manat \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Aserbaidschan-Manat),
				'one' => q(Aserbaidschan-Manat),
				'other' => q(Aserbaidschan-Manat),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(Bosnien und Herzegowina Dinar \(1992–1994\)),
				'one' => q(Bosnien und Herzegowina Dinar \(1992–1994\)),
				'other' => q(Bosnien und Herzegowina Dinar \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosnien und Herzegowina Konvertierbare Mark),
				'one' => q(Bosnien und Herzegowina Konvertierbare Mark),
				'other' => q(Bosnien und Herzegowina Konvertierbare Mark),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(Bosnien und Herzegowina Neuer Dinar \(1994–1997\)),
				'one' => q(Bosnien und Herzegowina Neuer Dinar \(1994–1997\)),
				'other' => q(Bosnien und Herzegowina Neue Dinar \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados-Dollar),
				'one' => q(Barbados-Dollar),
				'other' => q(Barbados-Dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladesch-Taka),
				'one' => q(Bangladesch-Taka),
				'other' => q(Bangladesch-Taka),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(Belgischer Franc \(konvertibel\)),
				'one' => q(Belgischer Franc \(konvertibel\)),
				'other' => q(Belgische Franc \(konvertibel\)),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(Belgischer Franc),
				'one' => q(Belgischer Franc),
				'other' => q(Belgische Franc),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(Belgischer Finanz-Franc),
				'one' => q(Belgischer Finanz-Franc),
				'other' => q(Belgische Finanz-Franc),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgarische Lew \(1962–1999\)),
				'one' => q(Bulgarische Lew \(1962–1999\)),
				'other' => q(Bulgarische Lew \(1962–1999\)),
			},
		},
		'BGM' => {
			symbol => 'BGK',
			display_name => {
				'currency' => q(Bulgarischer Lew \(1952–1962\)),
				'one' => q(Bulgarischer Lew \(1952–1962\)),
				'other' => q(Bulgarische Lew \(1952–1962\)),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bulgarischer Lew),
				'one' => q(Bulgarischer Lew),
				'other' => q(Bulgarische Lew),
			},
		},
		'BGO' => {
			symbol => 'BGJ',
			display_name => {
				'currency' => q(Bulgarischer Lew \(1879–1952\)),
				'one' => q(Bulgarischer Lew \(1879–1952\)),
				'other' => q(Bulgarische Lew \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bahrain-Dinar),
				'one' => q(Bahrain-Dinar),
				'other' => q(Bahrain-Dinar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi-Franc),
				'one' => q(Burundi-Franc),
				'other' => q(Burundi-Francs),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda-Dollar),
				'one' => q(Bermuda-Dollar),
				'other' => q(Bermuda-Dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunei-Dollar),
				'one' => q(Brunei-Dollar),
				'other' => q(Brunei-Dollar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolivianischer Boliviano),
				'one' => q(Bolivianischer Boliviano),
				'other' => q(Bolivianische Bolivianos),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(Bolivianischer Boliviano \(1863–1963\)),
				'one' => q(Bolivianischer Boliviano \(1863–1963\)),
				'other' => q(Bolivianische Bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(Bolivianischer Peso),
				'one' => q(Bolivianischer Peso),
				'other' => q(Bolivianische Peso),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(Boliviansiche Mvdol),
				'one' => q(Boliviansiche Mvdol),
				'other' => q(Bolivianische Mvdol),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro Novo \(1967–1986\)),
				'one' => q(Brasilianischer Cruzeiro Novo \(1967–1986\)),
				'other' => q(Brasilianische Cruzeiro Novo \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(Brasilianischer Cruzado \(1986–1989\)),
				'one' => q(Brasilianischer Cruzado \(1986–1989\)),
				'other' => q(Brasilianische Cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1990–1993\)),
				'one' => q(Brasilianischer Cruzeiro \(1990–1993\)),
				'other' => q(Brasilianische Cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brasilianischer Real),
				'one' => q(Brasilianischer Real),
				'other' => q(Brasilianische Real),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(Brasilianischer Cruzado Novo \(1989–1990\)),
				'one' => q(Brasilianischer Cruzado Novo \(1989–1990\)),
				'other' => q(Brasilianische Cruzado Novo \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1993–1994\)),
				'one' => q(Brasilianischer Cruzeiro \(1993–1994\)),
				'other' => q(Brasilianische Cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1942–1967\)),
				'one' => q(Brasilianischer Cruzeiro \(1942–1967\)),
				'other' => q(Brasilianischer Cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahamas-Dollar),
				'one' => q(Bahamas-Dollar),
				'other' => q(Bahamas-Dollar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Bhutan-Ngultrum),
				'one' => q(Bhutan-Ngultrum),
				'other' => q(Bhutan-Ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Birmanischer Kyat),
				'one' => q(Birmanischer Kyat),
				'other' => q(Birmanische Kyat),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswanischer Pula),
				'one' => q(Botswanischer Pula),
				'other' => q(Botswanische Pula),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(Belarus-Rubel \(1994–1999\)),
				'one' => q(Belarus-Rubel \(1994–1999\)),
				'other' => q(Belarus-Rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Weißrussischer Rubel),
				'one' => q(Weißrussischer Rubel),
				'other' => q(Weißrussische Rubel),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Weißrussischer Rubel \(2000–2016\)),
				'one' => q(Weißrussischer Rubel \(2000–2016\)),
				'other' => q(Weißrussische Rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Belize-Dollar),
				'one' => q(Belize-Dollar),
				'other' => q(Belize-Dollar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanadischer Dollar),
				'one' => q(Kanadischer Dollar),
				'other' => q(Kanadische Dollar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kongo-Franc),
				'one' => q(Kongo-Franc),
				'other' => q(Kongo-Francs),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(WIR-Euro),
				'one' => q(WIR-Euro),
				'other' => q(WIR-Euro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Schweizer Franken),
				'one' => q(Schweizer Franken),
				'other' => q(Schweizer Franken),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(WIR Franken),
				'one' => q(WIR Franken),
				'other' => q(WIR Franken),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(Chilenischer Escudo),
				'one' => q(Chilenischer Escudo),
				'other' => q(Chilenische Escudo),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(Chilenische Unidades de Fomento),
				'one' => q(Chilenische Unidades de Fomento),
				'other' => q(Chilenische Unidades de Fomento),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chilenischer Peso),
				'one' => q(Chilenischer Peso),
				'other' => q(Chilenische Pesos),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Renminbi Yuan \(Off–Shore\)),
				'one' => q(Renminbi Yuan \(Off–Shore\)),
				'other' => q(Renminbi Yuan \(Off–Shore\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
			display_name => {
				'currency' => q(Dollar der Chinesischen Volksbank),
				'one' => q(Dollar der Chinesischen Volksbank),
				'other' => q(Dollar der Chinesischen Volksbank),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Renminbi Yuan),
				'one' => q(Chinesischer Yuan),
				'other' => q(Renminbi Yuan),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbianischer Peso),
				'one' => q(Kolumbianischer Peso),
				'other' => q(Kolumbianische Pesos),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(Kolumbianische Unidades de valor real),
				'one' => q(Kolumbianische Unidad de valor real),
				'other' => q(Kolumbianische Unidades de valor real),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Costa-Rica-Colón),
				'one' => q(Costa-Rica-Colón),
				'other' => q(Costa-Rica-Colón),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(Serbischer Dinar \(2002–2006\)),
				'one' => q(Serbischer Dinar \(2002–2006\)),
				'other' => q(Serbische Dinar \(2002–2006\)),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(Tschechoslowakische Krone),
				'one' => q(Tschechoslowakische Kronen),
				'other' => q(Tschechoslowakische Kronen),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kubanischer Peso \(konvertibel\)),
				'one' => q(Kubanischer Peso \(konvertibel\)),
				'other' => q(Kubanische Pesos \(konvertibel\)),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kubanischer Peso),
				'one' => q(Kubanischer Peso),
				'other' => q(Kubanische Pesos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Cabo-Verde-Escudo),
				'one' => q(Cabo-Verde-Escudo),
				'other' => q(Cabo-Verde-Escudos),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(Zypern-Pfund),
				'one' => q(Zypern Pfund),
				'other' => q(Zypern Pfund),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Tschechische Krone),
				'one' => q(Tschechische Krone),
				'other' => q(Tschechische Kronen),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(Mark der DDR),
				'one' => q(Mark der DDR),
				'other' => q(Mark der DDR),
			},
		},
		'DEM' => {
			symbol => 'DM',
			display_name => {
				'currency' => q(Deutsche Mark),
				'one' => q(Deutsche Mark),
				'other' => q(Deutsche Mark),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Dschibuti-Franc),
				'one' => q(Dschibuti-Franc),
				'other' => q(Dschibuti-Franc),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Dänische Krone),
				'one' => q(Dänische Krone),
				'other' => q(Dänische Kronen),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominikanischer Peso),
				'one' => q(Dominikanischer Peso),
				'other' => q(Dominikanische Pesos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Algerischer Dinar),
				'one' => q(Algerischer Dinar),
				'other' => q(Algerische Dinar),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(Ecuadorianischer Sucre),
				'one' => q(Ecuadorianischer Sucre),
				'other' => q(Ecuadorianische Sucre),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(Verrechnungseinheit für Ecuador),
				'one' => q(Verrechnungseinheiten für Ecuador),
				'other' => q(Verrechnungseinheiten für Ecuador),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(Estnische Krone),
				'one' => q(Estnische Krone),
				'other' => q(Estnische Kronen),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Ägyptisches Pfund),
				'one' => q(Ägyptisches Pfund),
				'other' => q(Ägyptische Pfund),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritreischer Nakfa),
				'one' => q(Eritreischer Nakfa),
				'other' => q(Eritreische Nakfa),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(Spanische Peseta \(A–Konten\)),
				'one' => q(Spanische Peseta \(A–Konten\)),
				'other' => q(Spanische Peseten \(A–Konten\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(Spanische Peseta \(konvertibel\)),
				'one' => q(Spanische Peseta \(konvertibel\)),
				'other' => q(Spanische Peseten \(konvertibel\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Spanische Peseta),
				'one' => q(Spanische Peseta),
				'other' => q(Spanische Peseten),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Äthiopischer Birr),
				'one' => q(Äthiopischer Birr),
				'other' => q(Äthiopische Birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'one' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(Finnische Mark),
				'one' => q(Finnische Mark),
				'other' => q(Finnische Mark),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fidschi-Dollar),
				'one' => q(Fidschi-Dollar),
				'other' => q(Fidschi-Dollar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Falkland-Pfund),
				'one' => q(Falkland-Pfund),
				'other' => q(Falkland-Pfund),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(Französischer Franc),
				'one' => q(Französischer Franc),
				'other' => q(Französische Franc),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Britisches Pfund),
				'one' => q(Britisches Pfund),
				'other' => q(Britische Pfund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgischer Kupon Larit),
				'one' => q(Georgischer Kupon Larit),
				'other' => q(Georgische Kupon Larit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Georgischer Lari),
				'one' => q(Georgischer Lari),
				'other' => q(Georgische Lari),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Ghanaischer Cedi \(1979–2007\)),
				'one' => q(Ghanaischer Cedi \(1979–2007\)),
				'other' => q(Ghanaische Cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ghanaischer Cedi),
				'one' => q(Ghanaischer Cedi),
				'other' => q(Ghanaische Cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltar-Pfund),
				'one' => q(Gibraltar-Pfund),
				'other' => q(Gibraltar-Pfund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gambia-Dalasi),
				'one' => q(Gambia-Dalasi),
				'other' => q(Gambia-Dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Guinea-Franc),
				'one' => q(Guinea-Franc),
				'other' => q(Guinea-Franc),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(Guineischer Syli),
				'one' => q(Guineischer Syli),
				'other' => q(Guineische Syli),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(Äquatorialguinea-Ekwele),
				'one' => q(Äquatorialguinea-Ekwele),
				'other' => q(Äquatorialguinea-Ekwele),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(Griechische Drachme),
				'one' => q(Griechische Drachme),
				'other' => q(Griechische Drachmen),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guatemaltekischer Quetzal),
				'one' => q(Guatemaltekischer Quetzal),
				'other' => q(Guatemaltekische Quetzales),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugiesisch Guinea Escudo),
				'one' => q(Portugiesisch Guinea Escudo),
				'other' => q(Portugiesisch Guinea Escudo),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Guinea-Bissau Peso),
				'one' => q(Guinea-Bissau Peso),
				'other' => q(Guinea-Bissau Pesos),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Guyana-Dollar),
				'one' => q(Guyana-Dollar),
				'other' => q(Guyana-Dollar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hongkong-Dollar),
				'one' => q(Hongkong-Dollar),
				'other' => q(Hongkong-Dollar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Honduras-Lempira),
				'one' => q(Honduras-Lempira),
				'other' => q(Honduras-Lempira),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(Kroatischer Dinar),
				'one' => q(Kroatischer Dinar),
				'other' => q(Kroatische Dinar),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroatischer Kuna),
				'one' => q(Kroatischer Kuna),
				'other' => q(Kroatische Kuna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haitianische Gourde),
				'one' => q(Haitianische Gourde),
				'other' => q(Haitianische Gourdes),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Ungarischer Forint),
				'one' => q(Ungarischer Forint),
				'other' => q(Ungarische Forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesische Rupiah),
				'one' => q(Indonesische Rupiah),
				'other' => q(Indonesische Rupiah),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(Irisches Pfund),
				'one' => q(Irisches Pfund),
				'other' => q(Irische Pfund),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(Israelisches Pfund),
				'one' => q(Israelisches Pfund),
				'other' => q(Israelische Pfund),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Israelischer Schekel \(1980–1985\)),
				'one' => q(Israelischer Schekel \(1980–1985\)),
				'other' => q(Israelische Schekel \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Israelischer Neuer Schekel),
				'one' => q(Israelischer Neuer Schekel),
				'other' => q(Israelische Neue Schekel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indische Rupie),
				'one' => q(Indische Rupie),
				'other' => q(Indische Rupien),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Irakischer Dinar),
				'one' => q(Irakischer Dinar),
				'other' => q(Irakische Dinar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Iranischer Rial),
				'one' => q(Iranischer Rial),
				'other' => q(Iranische Rial),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Isländische Krone \(1918–1981\)),
				'one' => q(Isländische Krone \(1918–1981\)),
				'other' => q(Isländische Kronen \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Isländische Krone),
				'one' => q(Isländische Krone),
				'other' => q(Isländische Kronen),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(Italienische Lira),
				'one' => q(Italienische Lira),
				'other' => q(Italienische Lire),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaika-Dollar),
				'one' => q(Jamaika-Dollar),
				'other' => q(Jamaika-Dollar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jordanischer Dinar),
				'one' => q(Jordanischer Dinar),
				'other' => q(Jordanische Dinar),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanischer Yen),
				'one' => q(Japanischer Yen),
				'other' => q(Japanische Yen),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Kenia-Schilling),
				'one' => q(Kenia-Schilling),
				'other' => q(Kenia-Schilling),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgisischer Som),
				'one' => q(Kirgisischer Som),
				'other' => q(Kirgisische Som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodschanischer Riel),
				'one' => q(Kambodschanischer Riel),
				'other' => q(Kambodschanische Riel),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komoren-Franc),
				'one' => q(Komoren-Franc),
				'other' => q(Komoren-Francs),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Nordkoreanischer Won),
				'one' => q(Nordkoreanischer Won),
				'other' => q(Nordkoreanische Won),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(Südkoreanischer Hwan \(1953–1962\)),
				'one' => q(Südkoreanischer Hwan \(1953–1962\)),
				'other' => q(Südkoreanischer Hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(Südkoreanischer Won \(1945–1953\)),
				'one' => q(Südkoreanischer Won \(1945–1953\)),
				'other' => q(Südkoreanischer Won \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Südkoreanischer Won),
				'one' => q(Südkoreanischer Won),
				'other' => q(Südkoreanische Won),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuwait-Dinar),
				'one' => q(Kuwait-Dinar),
				'other' => q(Kuwait-Dinar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kaiman-Dollar),
				'one' => q(Kaiman-Dollar),
				'other' => q(Kaiman-Dollar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kasachischer Tenge),
				'one' => q(Kasachischer Tenge),
				'other' => q(Kasachische Tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laotischer Kip),
				'one' => q(Laotischer Kip),
				'other' => q(Laotische Kip),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libanesisches Pfund),
				'one' => q(Libanesisches Pfund),
				'other' => q(Libanesische Pfund),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri-Lanka-Rupie),
				'one' => q(Sri-Lanka-Rupie),
				'other' => q(Sri-Lanka-Rupien),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberianischer Dollar),
				'one' => q(Liberianischer Dollar),
				'other' => q(Liberianische Dollar),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(Loti),
				'one' => q(Loti),
				'other' => q(Loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litauischer Litas),
				'one' => q(Litauischer Litas),
				'other' => q(Litauische Litas),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(Litauischer Talonas),
				'one' => q(Litauische Talonas),
				'other' => q(Litauische Talonas),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(Luxemburgischer Franc \(konvertibel\)),
				'one' => q(Luxemburgische Franc \(konvertibel\)),
				'other' => q(Luxemburgische Franc \(konvertibel\)),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(Luxemburgischer Franc),
				'one' => q(Luxemburgische Franc),
				'other' => q(Luxemburgische Franc),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(Luxemburgischer Finanz-Franc),
				'one' => q(Luxemburgische Finanz-Franc),
				'other' => q(Luxemburgische Finanz-Franc),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lettischer Lats),
				'one' => q(Lettischer Lats),
				'other' => q(Lettische Lats),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(Lettischer Rubel),
				'one' => q(Lettische Rubel),
				'other' => q(Lettische Rubel),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Libyscher Dinar),
				'one' => q(Libyscher Dinar),
				'other' => q(Libysche Dinar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Marokkanischer Dirham),
				'one' => q(Marokkanischer Dirham),
				'other' => q(Marokkanische Dirham),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(Marokkanischer Franc),
				'one' => q(Marokkanische Franc),
				'other' => q(Marokkanische Franc),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(Monegassischer Franc),
				'one' => q(Monegassischer Franc),
				'other' => q(Monegassische Franc),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(Moldau-Cupon),
				'one' => q(Moldau-Cupon),
				'other' => q(Moldau-Cupon),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldau-Leu),
				'one' => q(Moldau-Leu),
				'other' => q(Moldau-Leu),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Madagaskar-Ariary),
				'one' => q(Madagaskar-Ariary),
				'other' => q(Madagaskar-Ariary),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(Madagaskar-Franc),
				'one' => q(Madagaskar-Franc),
				'other' => q(Madagaskar-Franc),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Mazedonischer Denar),
				'one' => q(Mazedonischer Denar),
				'other' => q(Mazedonische Denari),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(Mazedonischer Denar \(1992–1993\)),
				'one' => q(Mazedonischer Denar \(1992–1993\)),
				'other' => q(Mazedonische Denar \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(Malischer Franc),
				'one' => q(Malische Franc),
				'other' => q(Malische Franc),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmarischer Kyat),
				'one' => q(Myanmarischer Kyat),
				'other' => q(Myanmarische Kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongolischer Tögrög),
				'one' => q(Mongolischer Tögrög),
				'other' => q(Mongolische Tögrög),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Macao-Pataca),
				'one' => q(Macao-Pataca),
				'other' => q(Macao-Pataca),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mauretanischer Ouguiya \(1973–2017\)),
				'one' => q(Mauretanischer Ouguiya \(1973–2017\)),
				'other' => q(Mauretanische Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Mauretanischer Ouguiya),
				'one' => q(Mauretanischer Ouguiya),
				'other' => q(Mauretanische Ouguiya),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(Maltesische Lira),
				'one' => q(Maltesische Lira),
				'other' => q(Maltesische Lira),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(Maltesisches Pfund),
				'one' => q(Maltesische Pfund),
				'other' => q(Maltesische Pfund),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mauritius-Rupie),
				'one' => q(Mauritius-Rupie),
				'other' => q(Mauritius-Rupien),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Malediven-Rupie \(alt\)),
				'one' => q(Malediven-Rupie \(alt\)),
				'other' => q(Malediven-Rupien \(alt\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Malediven-Rufiyaa),
				'one' => q(Malediven-Rufiyaa),
				'other' => q(Malediven-Rupien),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malawi-Kwacha),
				'one' => q(Malawi-Kwacha),
				'other' => q(Malawi-Kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mexikanischer Peso),
				'one' => q(Mexikanischer Peso),
				'other' => q(Mexikanische Pesos),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Mexikanischer Silber-Peso \(1861–1992\)),
				'one' => q(Mexikanische Silber-Peso \(1861–1992\)),
				'other' => q(Mexikanische Silber-Pesos \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Mexicanischer Unidad de Inversion \(UDI\)),
				'one' => q(Mexicanischer Unidad de Inversion \(UDI\)),
				'other' => q(Mexikanische Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malaysischer Ringgit),
				'one' => q(Malaysischer Ringgit),
				'other' => q(Malaysische Ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mosambikanischer Escudo),
				'one' => q(Mozambikanische Escudo),
				'other' => q(Mozambikanische Escudo),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(Mosambikanischer Metical \(1980–2006\)),
				'one' => q(Mosambikanischer Metical \(1980–2006\)),
				'other' => q(Mosambikanische Meticais \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mosambikanischer Metical),
				'one' => q(Mosambikanischer Metical),
				'other' => q(Mosambikanische Meticais),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibia-Dollar),
				'one' => q(Namibia-Dollar),
				'other' => q(Namibia-Dollar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigerianischer Naira),
				'one' => q(Nigerianischer Naira),
				'other' => q(Nigerianische Naira),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(Nicaraguanischer Córdoba \(1988–1991\)),
				'one' => q(Nicaraguanischer Córdoba \(1988–1991\)),
				'other' => q(Nicaraguanische Córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nicaragua-Córdoba),
				'one' => q(Nicaragua-Córdoba),
				'other' => q(Nicaragua-Córdobas),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(Niederländischer Gulden),
				'one' => q(Niederländischer Gulden),
				'other' => q(Niederländische Gulden),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norwegische Krone),
				'one' => q(Norwegische Krone),
				'other' => q(Norwegische Kronen),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalesische Rupie),
				'one' => q(Nepalesische Rupie),
				'other' => q(Nepalesische Rupien),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Neuseeland-Dollar),
				'one' => q(Neuseeland-Dollar),
				'other' => q(Neuseeland-Dollar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omanischer Rial),
				'one' => q(Omanischer Rial),
				'other' => q(Omanische Rials),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panamaischer Balboa),
				'one' => q(Panamaischer Balboa),
				'other' => q(Panamaische Balboas),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(Peruanischer Inti),
				'one' => q(Peruanische Inti),
				'other' => q(Peruanische Inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peruanischer Sol),
				'one' => q(Peruanischer Sol),
				'other' => q(Peruanische Sol),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(Peruanischer Sol \(1863–1965\)),
				'one' => q(Peruanischer Sol \(1863–1965\)),
				'other' => q(Peruanische Sol \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papua-Neuguineischer Kina),
				'one' => q(Papua-Neuguineischer Kina),
				'other' => q(Papua-Neuguineische Kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Philippinischer Peso),
				'one' => q(Philippinischer Peso),
				'other' => q(Philippinische Pesos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistanische Rupie),
				'one' => q(Pakistanische Rupie),
				'other' => q(Pakistanische Rupien),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Polnischer Złoty),
				'one' => q(Polnischer Złoty),
				'other' => q(Polnische Złoty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polnischer Zloty \(1950–1995\)),
				'one' => q(Polnischer Zloty \(1950–1995\)),
				'other' => q(Polnische Zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(Portugiesischer Escudo),
				'one' => q(Portugiesische Escudo),
				'other' => q(Portugiesische Escudo),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguayischer Guaraní),
				'one' => q(Paraguayischer Guaraní),
				'other' => q(Paraguayische Guaraníes),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katar-Riyal),
				'one' => q(Katar-Riyal),
				'other' => q(Katar-Riyal),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(Rhodesischer Dollar),
				'one' => q(Rhodesische Dollar),
				'other' => q(Rhodesische Dollar),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(Rumänischer Leu \(1952–2006\)),
				'one' => q(Rumänischer Leu \(1952–2006\)),
				'other' => q(Rumänische Leu \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumänischer Leu),
				'one' => q(Rumänischer Leu),
				'other' => q(Rumänische Leu),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbischer Dinar),
				'one' => q(Serbischer Dinar),
				'other' => q(Serbische Dinaren),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Russischer Rubel),
				'one' => q(Russischer Rubel),
				'other' => q(Russische Rubel),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(Russischer Rubel \(1991–1998\)),
				'one' => q(Russischer Rubel \(1991–1998\)),
				'other' => q(Russische Rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruanda-Franc),
				'one' => q(Ruanda-Franc),
				'other' => q(Ruanda-Francs),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saudi-Rial),
				'one' => q(Saudi-Rial),
				'other' => q(Saudi-Rial),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Salomonen-Dollar),
				'one' => q(Salomonen-Dollar),
				'other' => q(Salomonen-Dollar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seychellen-Rupie),
				'one' => q(Seychellen-Rupie),
				'other' => q(Seychellen-Rupien),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(Sudanesischer Dinar \(1992–2007\)),
				'one' => q(Sudanesischer Dinar \(1992–2007\)),
				'other' => q(Sudanesische Dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudanesisches Pfund),
				'one' => q(Sudanesisches Pfund),
				'other' => q(Sudanesische Pfund),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(Sudanesisches Pfund \(1957–1998\)),
				'one' => q(Sudanesisches Pfund \(1957–1998\)),
				'other' => q(Sudanesische Pfund \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Schwedische Krone),
				'one' => q(Schwedische Krone),
				'other' => q(Schwedische Kronen),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapur-Dollar),
				'one' => q(Singapur-Dollar),
				'other' => q(Singapur-Dollar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(St. Helena-Pfund),
				'one' => q(St. Helena-Pfund),
				'other' => q(St. Helena-Pfund),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(Slowenischer Tolar),
				'one' => q(Slowenischer Tolar),
				'other' => q(Slowenische Tolar),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(Slowakische Krone),
				'one' => q(Slowakische Kronen),
				'other' => q(Slowakische Kronen),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra-leonischer Leone),
				'one' => q(Sierra-leonischer Leone),
				'other' => q(Sierra-leonische Leones),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somalia-Schilling),
				'one' => q(Somalia-Schilling),
				'other' => q(Somalia-Schilling),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Suriname-Dollar),
				'one' => q(Suriname-Dollar),
				'other' => q(Suriname-Dollar),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(Suriname Gulden),
				'one' => q(Suriname-Gulden),
				'other' => q(Suriname-Gulden),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Südsudanesisches Pfund),
				'one' => q(Südsudanesisches Pfund),
				'other' => q(Südsudanesische Pfund),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(São-toméischer Dobra \(1977–2017\)),
				'one' => q(São-toméischer Dobra \(1977–2017\)),
				'other' => q(São-toméische Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(São-toméischer Dobra),
				'one' => q(São-toméischer Dobra),
				'other' => q(São-toméische Dobras),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(Sowjetischer Rubel),
				'one' => q(Sowjetische Rubel),
				'other' => q(Sowjetische Rubel),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(El Salvador Colon),
				'one' => q(El Salvador-Colon),
				'other' => q(El Salvador-Colon),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Syrisches Pfund),
				'one' => q(Syrisches Pfund),
				'other' => q(Syrische Pfund),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Swasiländischer Lilangeni),
				'one' => q(Swasiländischer Lilangeni),
				'other' => q(Swasiländische Emalangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thailändischer Baht),
				'one' => q(Thailändischer Baht),
				'other' => q(Thailändische Baht),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(Tadschikistan Rubel),
				'one' => q(Tadschikistan-Rubel),
				'other' => q(Tadschikistan-Rubel),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tadschikistan-Somoni),
				'one' => q(Tadschikistan-Somoni),
				'other' => q(Tadschikistan-Somoni),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(Turkmenistan-Manat \(1993–2009\)),
				'one' => q(Turkmenistan-Manat \(1993–2009\)),
				'other' => q(Turkmenistan-Manat \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Turkmenistan-Manat),
				'one' => q(Turkmenistan-Manat),
				'other' => q(Turkmenistan-Manat),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunesischer Dinar),
				'one' => q(Tunesischer Dinar),
				'other' => q(Tunesische Dinar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tongaischer Paʻanga),
				'one' => q(Tongaischer Paʻanga),
				'other' => q(Tongaische Paʻanga),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Timor-Escudo),
				'one' => q(Timor-Escudo),
				'other' => q(Timor-Escudo),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(Türkische Lira \(1922–2005\)),
				'one' => q(Türkische Lira \(1922–2005\)),
				'other' => q(Türkische Lira \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Türkische Lira),
				'one' => q(Türkische Lira),
				'other' => q(Türkische Lira),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad und Tobago-Dollar),
				'one' => q(Trinidad und Tobago-Dollar),
				'other' => q(Trinidad und Tobago-Dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Neuer Taiwan-Dollar),
				'one' => q(Neuer Taiwan-Dollar),
				'other' => q(Neue Taiwan-Dollar),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tansania-Schilling),
				'one' => q(Tansania-Schilling),
				'other' => q(Tansania-Schilling),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrainische Hrywnja),
				'one' => q(Ukrainische Hrywnja),
				'other' => q(Ukrainische Hrywen),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(Ukrainischer Karbovanetz),
				'one' => q(Ukrainische Karbovanetz),
				'other' => q(Ukrainische Karbovanetz),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Uganda-Schilling \(1966–1987\)),
				'one' => q(Uganda-Schilling \(1966–1987\)),
				'other' => q(Uganda-Schilling \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Uganda-Schilling),
				'one' => q(Uganda-Schilling),
				'other' => q(Uganda-Schilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
				'one' => q(US-Dollar),
				'other' => q(US-Dollar),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(US Dollar \(Nächster Tag\)),
				'one' => q(US-Dollar \(Nächster Tag\)),
				'other' => q(US-Dollar \(Nächster Tag\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(US Dollar \(Gleicher Tag\)),
				'one' => q(US-Dollar \(Gleicher Tag\)),
				'other' => q(US-Dollar \(Gleicher Tag\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(Uruguayischer Peso \(Indexierte Rechnungseinheiten\)),
				'one' => q(Uruguayischer Peso \(Indexierte Rechnungseinheiten\)),
				'other' => q(Uruguayische Pesos \(Indexierte Rechnungseinheiten\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(Uruguayischer Peso \(1975–1993\)),
				'one' => q(Uruguayischer Peso \(1975–1993\)),
				'other' => q(Uruguayische Pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguayischer Peso),
				'one' => q(Uruguayischer Peso),
				'other' => q(Uruguayische Pesos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Usbekistan-Sum),
				'one' => q(Usbekistan-Sum),
				'other' => q(Usbekistan-Sum),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Venezolanischer Bolívar \(1871–2008\)),
				'one' => q(Venezolanischer Bolívar \(1871–2008\)),
				'other' => q(Venezolanische Bolívares \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezolanischer Bolívar \(2008–2018\)),
				'one' => q(Venezolanischer Bolívar \(2008–2018\)),
				'other' => q(Venezolanische Bolívares \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Venezolanischer Bolívar),
				'one' => q(Venezolanischer Bolívar),
				'other' => q(Venezolanische Bolívares),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vietnamesischer Dong),
				'one' => q(Vietnamesischer Dong),
				'other' => q(Vietnamesische Dong),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(Vietnamesischer Dong\(1978–1985\)),
				'one' => q(Vietnamesischer Dong\(1978–1985\)),
				'other' => q(Vietnamesische Dong\(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatu-Vatu),
				'one' => q(Vanuatu-Vatu),
				'other' => q(Vanuatu-Vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoanischer Tala),
				'one' => q(Samoanischer Tala),
				'other' => q(Samoanische Tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA-Franc \(BEAC\)),
				'one' => q(CFA-Franc \(BEAC\)),
				'other' => q(CFA-Franc \(BEAC\)),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(Unze Silber),
				'one' => q(Unze Silber),
				'other' => q(Unzen Silber),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(Unze Gold),
				'one' => q(Unze Gold),
				'other' => q(Unzen Gold),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Europäische Rechnungseinheit),
				'one' => q(Europäische Rechnungseinheiten),
				'other' => q(Europäische Rechnungseinheiten),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Europäische Währungseinheit \(XBB\)),
				'one' => q(Europäische Währungseinheiten \(XBB\)),
				'other' => q(Europäische Währungseinheiten \(XBB\)),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(Europäische Rechnungseinheit \(XBC\)),
				'one' => q(Europäische Rechnungseinheiten \(XBC\)),
				'other' => q(Europäische Rechnungseinheiten \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(Europäische Rechnungseinheit \(XBD\)),
				'one' => q(Europäische Rechnungseinheiten \(XBD\)),
				'other' => q(Europäische Rechnungseinheiten \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Ostkaribischer Dollar),
				'one' => q(Ostkaribischer Dollar),
				'other' => q(Ostkaribische Dollar),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(Sonderziehungsrechte),
				'one' => q(Sonderziehungsrechte),
				'other' => q(Sonderziehungsrechte),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(Europäische Währungseinheit \(XEU\)),
				'one' => q(Europäische Währungseinheiten \(XEU\)),
				'other' => q(Europäische Währungseinheiten \(XEU\)),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(Französischer Gold-Franc),
				'one' => q(Französische Gold-Franc),
				'other' => q(Französische Gold-Franc),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(Französischer UIC-Franc),
				'one' => q(Französische UIC-Franc),
				'other' => q(Französische UIC-Franc),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA-Franc \(BCEAO\)),
				'one' => q(CFA-Franc \(BCEAO\)),
				'other' => q(CFA-Francs \(BCEAO\)),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(Unze Palladium),
				'one' => q(Unze Palladium),
				'other' => q(Unzen Palladium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-Franc),
				'one' => q(CFP-Franc),
				'other' => q(CFP-Franc),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(Unze Platin),
				'one' => q(Unze Platin),
				'other' => q(Unzen Platin),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(RINET Funds),
				'one' => q(RINET Funds),
				'other' => q(RINET Funds),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(SUCRE),
				'one' => q(SUCRE),
				'other' => q(SUCRE),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(Testwährung),
				'one' => q(Testwährung),
				'other' => q(Testwährung),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(Rechnungseinheit der AfEB),
				'one' => q(Rechnungseinheit der AfEB),
				'other' => q(Rechnungseinheiten der AfEB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Unbekannte Währung),
				'one' => q(\(unbekannte Währung\)),
				'other' => q(\(unbekannte Währung\)),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(Jemen-Dinar),
				'one' => q(Jemen-Dinar),
				'other' => q(Jemen-Dinar),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemen-Rial),
				'one' => q(Jemen-Rial),
				'other' => q(Jemen-Rial),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(Jugoslawischer Dinar \(1966–1990\)),
				'one' => q(Jugoslawischer Dinar \(1966–1990\)),
				'other' => q(Jugoslawische Dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(Jugoslawischer Neuer Dinar \(1994–2002\)),
				'one' => q(Jugoslawischer Neuer Dinar \(1994–2002\)),
				'other' => q(Jugoslawische Neue Dinar \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(Jugoslawischer Dinar \(konvertibel\)),
				'one' => q(Jugoslawische Dinar \(konvertibel\)),
				'other' => q(Jugoslawische Dinar \(konvertibel\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(Jugoslawischer reformierter Dinar \(1992–1993\)),
				'one' => q(Jugoslawischer reformierter Dinar \(1992–1993\)),
				'other' => q(Jugoslawische reformierte Dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(Südafrikanischer Rand \(Finanz\)),
				'one' => q(Südafrikanischer Rand \(Finanz\)),
				'other' => q(Südafrikanischer Rand \(Finanz\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Südafrikanischer Rand),
				'one' => q(Südafrikanischer Rand),
				'other' => q(Südafrikanische Rand),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Kwacha \(1968–2012\)),
				'one' => q(Kwacha \(1968–2012\)),
				'other' => q(Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha),
				'one' => q(Kwacha),
				'other' => q(Kwacha),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(Zaire-Neuer Zaïre \(1993–1998\)),
				'one' => q(Zaire-Neuer Zaïre \(1993–1998\)),
				'other' => q(Zaire-Neue Zaïre \(1993–1998\)),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(Zaire-Zaïre \(1971–1993\)),
				'one' => q(Zaire-Zaïre \(1971–1993\)),
				'other' => q(Zaire-Zaïre \(1971–1993\)),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(Simbabwe-Dollar \(1980–2008\)),
				'one' => q(Simbabwe-Dollar \(1980–2008\)),
				'other' => q(Simbabwe-Dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2009\)),
				'one' => q(Simbabwe-Dollar \(2009\)),
				'other' => q(Simbabwe-Dollar \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2008\)),
				'one' => q(Simbabwe-Dollar \(2008\)),
				'other' => q(Simbabwe-Dollar \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Thout',
							'Paopi',
							'Hathor',
							'Koiak',
							'Tobi',
							'Meschir',
							'Paremhat',
							'Paremoude',
							'Paschons',
							'Paoni',
							'Epip',
							'Mesori',
							'Nasie'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Thout',
							'Paopi',
							'Hathor',
							'Koiak',
							'Tobi',
							'Meschir',
							'Paremhat',
							'Paremoude',
							'Paschons',
							'Paoni',
							'Epip',
							'Mesori',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Thout',
							'Paopi',
							'Hathor',
							'Koiak',
							'Tobi',
							'Meschir',
							'Paremhat',
							'Paremoude',
							'Paschons',
							'Paoni',
							'Epip',
							'Mesori',
							'Nasie'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Thout',
							'Paopi',
							'Hathor',
							'Koiak',
							'Tobi',
							'Meschir',
							'Paremhat',
							'Paremoude',
							'Paschons',
							'Paoni',
							'Epip',
							'Mesori',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Mäskäräm',
							'Ṭəqəmt',
							'Ḫədar',
							'Taḫśaś',
							'Ṭərr',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Gənbot',
							'Säne',
							'Ḥamle',
							'Nähase',
							'Ṗagumen'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mäskäräm',
							'Ṭəqəmt',
							'Ḫədar',
							'Taḫśaś',
							'Ṭərr',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Gənbot',
							'Säne',
							'Ḥamle',
							'Nähase',
							'Ṗagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Mäskäräm',
							'Ṭəqəmt',
							'Ḫədar',
							'Taḫśaś',
							'Ṭərr',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Gənbot',
							'Säne',
							'Ḥamle',
							'Nähase',
							'Ṗagumen'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Mäskäräm',
							'Ṭəqəmt',
							'Ḫədar',
							'Taḫśaś',
							'Ṭərr',
							'Yäkatit',
							'Mägabit',
							'Miyazya',
							'Gənbot',
							'Säne',
							'Ḥamle',
							'Nähase',
							'Ṗagumen'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Jan.',
							'Feb.',
							'März',
							'Apr.',
							'Mai',
							'Juni',
							'Juli',
							'Aug.',
							'Sept.',
							'Okt.',
							'Nov.',
							'Dez.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januar',
							'Februar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mär',
							'Apr',
							'Mai',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Okt',
							'Nov',
							'Dez'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januar',
							'Februar',
							'März',
							'April',
							'Mai',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tischri',
							'Cheschwan',
							'Kislew',
							'Tevet',
							'Schevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Ijjar',
							'Siwan',
							'Tammus',
							'Aw',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
					wide => {
						nonleap => [
							'Tischri',
							'Cheschwan',
							'Kislew',
							'Tevet',
							'Schevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Ijjar',
							'Siwan',
							'Tammus',
							'Aw',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tischri',
							'Cheschwan',
							'Kislew',
							'Tevet',
							'Schevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Ijjar',
							'Siwan',
							'Tammus',
							'Aw',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
					wide => {
						nonleap => [
							'Tischri',
							'Cheschwan',
							'Kislew',
							'Tevet',
							'Schevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Ijjar',
							'Siwan',
							'Tammus',
							'Aw',
							'Elul'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'Adar II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaishtha',
							'Ashadha',
							'Sravana',
							'Bhadrapada',
							'Ashvina',
							'Kartika',
							'Margasirsha',
							'Pausha',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaishtha',
							'Ashadha',
							'Sravana',
							'Bhadrapada',
							'Ashvina',
							'Kartika',
							'Margasirsha',
							'Pausha',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaishtha',
							'Ashadha',
							'Sravana',
							'Bhadrapada',
							'Ashvina',
							'Kartika',
							'Margasirsha',
							'Pausha',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaishtha',
							'Ashadha',
							'Sravana',
							'Bhadrapada',
							'Ashvina',
							'Kartika',
							'Margasirsha',
							'Pausha',
							'Magha',
							'Phalguna'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Dschumada I',
							'Dschumada II',
							'Radschab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhu l-qaʿda',
							'Dhu l-Hiddscha'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Dschumada I',
							'Dschumada II',
							'Radschab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhu l-qaʿda',
							'Dhu l-Hiddscha'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Farwardin',
							'Ordibehescht',
							'Chordād',
							'Tir',
							'Mordād',
							'Schahriwar',
							'Mehr',
							'Ābān',
							'Āsar',
							'Déi',
							'Bahman',
							'Essfand'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Farwardin',
							'Ordibehescht',
							'Chordād',
							'Tir',
							'Mordād',
							'Schahriwar',
							'Mehr',
							'Ābān',
							'Āsar',
							'Déi',
							'Bahman',
							'Essfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Farwardin',
							'Ordibehescht',
							'Chordād',
							'Tir',
							'Mordād',
							'Schahriwar',
							'Mehr',
							'Ābān',
							'Āsar',
							'Déi',
							'Bahman',
							'Essfand'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Farwardin',
							'Ordibehescht',
							'Chordād',
							'Tir',
							'Mordād',
							'Schahriwar',
							'Mehr',
							'Ābān',
							'Āsar',
							'Déi',
							'Bahman',
							'Essfand'
						],
						leap => [
							
						],
					},
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
					abbreviated => {
						mon => 'Mo.',
						tue => 'Di.',
						wed => 'Mi.',
						thu => 'Do.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'M',
						thu => 'D',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Mo.',
						tue => 'Di.',
						wed => 'Mi.',
						thu => 'Do.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Montag',
						tue => 'Dienstag',
						wed => 'Mittwoch',
						thu => 'Donnerstag',
						fri => 'Freitag',
						sat => 'Samstag',
						sun => 'Sonntag'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mo',
						tue => 'Di',
						wed => 'Mi',
						thu => 'Do',
						fri => 'Fr',
						sat => 'Sa',
						sun => 'So'
					},
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'M',
						thu => 'D',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Mo.',
						tue => 'Di.',
						wed => 'Mi.',
						thu => 'Do.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Montag',
						tue => 'Dienstag',
						wed => 'Mittwoch',
						thu => 'Donnerstag',
						fri => 'Freitag',
						sat => 'Samstag',
						sun => 'Sonntag'
					},
				},
			},
	} },
);

has 'calendar_quarters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. Quartal',
						1 => '2. Quartal',
						2 => '3. Quartal',
						3 => '4. Quartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. Quartal',
						1 => '2. Quartal',
						2 => '3. Quartal',
						3 => '4. Quartal'
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
			if ($_ eq 'buddhist') {
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
			if ($_ eq 'chinese') {
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
			if ($_ eq 'coptic') {
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
			if ($_ eq 'ethiopic') {
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
			if ($_ eq 'generic') {
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
			if ($_ eq 'hebrew') {
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
			if ($_ eq 'indian') {
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
			if ($_ eq 'islamic') {
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
			if ($_ eq 'japanese') {
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
			if ($_ eq 'persian') {
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
			if ($_ eq 'roc') {
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'afternoon1' => q{mittags},
					'afternoon2' => q{nachmittags},
					'am' => q{AM},
					'evening1' => q{abends},
					'midnight' => q{Mitternacht},
					'morning1' => q{morgens},
					'morning2' => q{vormittags},
					'night1' => q{nachts},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{mittags},
					'afternoon2' => q{nachmittags},
					'am' => q{a},
					'evening1' => q{abends},
					'midnight' => q{Mitternacht},
					'morning1' => q{morgens},
					'morning2' => q{vormittags},
					'night1' => q{nachts},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{mittags},
					'afternoon2' => q{nachmittags},
					'am' => q{AM},
					'evening1' => q{abends},
					'midnight' => q{Mitternacht},
					'morning1' => q{morgens},
					'morning2' => q{vormittags},
					'night1' => q{nachts},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Nachmittag},
					'am' => q{AM},
					'evening1' => q{Abend},
					'midnight' => q{Mitternacht},
					'morning1' => q{Morgen},
					'morning2' => q{Vormittag},
					'night1' => q{Nacht},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Nachmittag},
					'am' => q{a},
					'evening1' => q{Abend},
					'midnight' => q{Mitternacht},
					'morning1' => q{Morgen},
					'morning2' => q{Vormittag},
					'night1' => q{Nacht},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Nachmittag},
					'am' => q{AM},
					'evening1' => q{Abend},
					'midnight' => q{Mitternacht},
					'morning1' => q{Morgen},
					'morning2' => q{Vormittag},
					'night1' => q{Nacht},
					'pm' => q{PM},
				},
			},
		},
	} },
);

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			abbreviated => {
				'0' => 'BE'
			},
			narrow => {
				'0' => 'BE'
			},
			wide => {
				'0' => 'B.E.'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			narrow => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
			wide => {
				'0' => 'ERA0',
				'1' => 'ERA1'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
			narrow => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
			wide => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'AM'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'AH'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'AP'
			},
			narrow => {
				'0' => 'AP'
			},
			wide => {
				'0' => 'AP'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Before R.O.C.',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'v. VR China',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'vor Volksrepublik China',
				'1' => 'Minguo'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
			'full' => q{EEEE, d. MMMM U},
			'long' => q{d. MMMM U},
			'medium' => q{dd.MM U},
			'short' => q{dd.MM.yy},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{dd.MM.y},
			'short' => q{dd.MM.yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} 'um' {0}},
			'long' => q{{1} 'um' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'um' {0}},
			'long' => q{{1} 'um' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			Ed => q{E, d.},
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E, d. MMM U},
			GyMMMd => q{d. MMM U},
			H => q{HH 'Uhr'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{U},
			yyyy => q{U},
			yyyyM => q{M.y},
			yyyyMEd => q{E, d.M.y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E, d. MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMd => q{d. MMM U},
			yyyyMd => q{d.M.y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH 'Uhr'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH 'Uhr'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{'Woche' W 'im' MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			d => q{d},
			h => q{h 'Uhr' a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMMdd => q{dd.MM.y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'Woche' w 'des' 'Jahres' Y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'Timezone' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			H => {
				H => q{HH–HH 'Uhr'},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH 'Uhr' v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH 'Uhr'},
			},
			Hm => {
				H => q{HH:mm–HH:mm 'Uhr'},
				m => q{HH:mm–HH:mm 'Uhr'},
			},
			Hmv => {
				H => q{HH:mm–HH:mm 'Uhr' v},
				m => q{HH:mm–HH:mm 'Uhr' v},
			},
			Hv => {
				H => q{HH–HH 'Uhr' v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h 'Uhr' a – h 'Uhr' a},
				h => q{h – h 'Uhr' a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{E, dd.MM. – E, dd.MM.y},
				d => q{E, dd. – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM. – dd.MM.y},
				d => q{dd.–dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Ratte),
						1 => q(Büffel),
						2 => q(Tiger),
						3 => q(Hase),
						4 => q(Drache),
						5 => q(Schlange),
						6 => q(Pferd),
						7 => q(Ziege),
						8 => q(Affe),
						9 => q(Hahn),
						10 => q(Hund),
						11 => q(Schwein),
					},
				},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} Zeit),
		regionFormat => q({0} Sommerzeit),
		regionFormat => q({0} Normalzeit),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre-Sommerzeit#,
				'generic' => q#Acre-Zeit#,
				'standard' => q#Acre-Normalzeit#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan-Zeit#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dschibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadischu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Zentralafrikanische Zeit#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ostafrikanische Zeit#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Südafrikanische Zeit#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Westafrikanische Sommerzeit#,
				'generic' => q#Westafrikanische Zeit#,
				'standard' => q#Westafrikanische Normalzeit#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-Sommerzeit#,
				'generic' => q#Alaska-Zeit#,
				'standard' => q#Alaska-Normalzeit#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty-Sommerzeit#,
				'generic' => q#Almaty-Zeit#,
				'standard' => q#Almaty-Normalzeit#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas-Sommerzeit#,
				'generic' => q#Amazonas-Zeit#,
				'standard' => q#Amazonas-Normalzeit#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaninseln#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-Stadt#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Nordamerikanische Inland-Sommerzeit#,
				'generic' => q#Nordamerikanische Inlandzeit#,
				'standard' => q#Nordamerikanische Inland-Normalzeit#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Nordamerikanische Ostküsten-Sommerzeit#,
				'generic' => q#Nordamerikanische Ostküstenzeit#,
				'standard' => q#Nordamerikanische Ostküsten-Normalzeit#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Rocky-Mountain-Sommerzeit#,
				'generic' => q#Rocky-Mountain-Zeit#,
				'standard' => q#Rocky Mountain-Normalzeit#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Nordamerikanische Westküsten-Sommerzeit#,
				'generic' => q#Nordamerikanische Westküstenzeit#,
				'standard' => q#Nordamerikanische Westküsten-Normalzeit#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr Sommerzeit#,
				'generic' => q#Anadyr Zeit#,
				'standard' => q#Anadyr Normalzeit#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia-Sommerzeit#,
				'generic' => q#Apia-Zeit#,
				'standard' => q#Apia-Normalzeit#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau-Sommerzeit#,
				'generic' => q#Aqtau-Zeit#,
				'standard' => q#Aqtau-Normalzeit#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtöbe-Sommerzeit#,
				'generic' => q#Aqtöbe-Zeit#,
				'standard' => q#Aqtöbe-Normalzeit#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabische Sommerzeit#,
				'generic' => q#Arabische Zeit#,
				'standard' => q#Arabische Normalzeit#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinische Sommerzeit#,
				'generic' => q#Argentinische Zeit#,
				'standard' => q#Argentinische Normalzeit#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Westargentinische Sommerzeit#,
				'generic' => q#Westargentinische Zeit#,
				'standard' => q#Westargentinische Normalzeit#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenische Sommerzeit#,
				'generic' => q#Armenische Zeit#,
				'standard' => q#Armenische Normalzeit#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei Darussalam#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tschita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tschoibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chowd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtschatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatschi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qysylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Chi-Minh-Stadt#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seoul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipeh#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Eriwan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik-Sommerzeit#,
				'generic' => q#Atlantik-Zeit#,
				'standard' => q#Atlantik-Normalzeit#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaren#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöer#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reyk­ja­vík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Südgeorgien#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Zentralaustralische Sommerzeit#,
				'generic' => q#Zentralaustralische Zeit#,
				'standard' => q#Zentralaustralische Normalzeit#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Zentral-/Westaustralische Sommerzeit#,
				'generic' => q#Zentral-/Westaustralische Zeit#,
				'standard' => q#Zentral-/Westaustralische Normalzeit#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ostaustralische Sommerzeit#,
				'generic' => q#Ostaustralische Zeit#,
				'standard' => q#Ostaustralische Normalzeit#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Westaustralische Sommerzeit#,
				'generic' => q#Westaustralische Zeit#,
				'standard' => q#Westaustralische Normalzeit#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbaidschanische Sommerzeit#,
				'generic' => q#Aserbaidschanische Zeit#,
				'standard' => q#Aserbeidschanische Normalzeit#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoren-Sommerzeit#,
				'generic' => q#Azoren-Zeit#,
				'standard' => q#Azoren-Normalzeit#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesch-Sommerzeit#,
				'generic' => q#Bangladesch-Zeit#,
				'standard' => q#Bangladesch-Normalzeit#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan-Zeit#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivianische Zeit#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília-Sommerzeit#,
				'generic' => q#Brasília-Zeit#,
				'standard' => q#Brasília-Normalzeit#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei-Darussalam-Zeit#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cabo-Verde-Sommerzeit#,
				'generic' => q#Cabo-Verde-Zeit#,
				'standard' => q#Cabo-Verde-Normalzeit#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey-Zeit#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-Zeit#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham-Sommerzeit#,
				'generic' => q#Chatham-Zeit#,
				'standard' => q#Chatham-Normalzeit#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilenische Sommerzeit#,
				'generic' => q#Chilenische Zeit#,
				'standard' => q#Chilenische Normalzeit#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinesische Sommerzeit#,
				'generic' => q#Chinesische Zeit#,
				'standard' => q#Chinesische Normalzeit#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Tschoibalsan-Sommerzeit#,
				'generic' => q#Tschoibalsan-Zeit#,
				'standard' => q#Tschoibalsan-Normalzeit#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Weihnachtsinsel-Zeit#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokosinseln-Zeit#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbianische Sommerzeit#,
				'generic' => q#Kolumbianische Zeit#,
				'standard' => q#Kolumbianische Normalzeit#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookinseln-Sommerzeit#,
				'generic' => q#Cookinseln-Zeit#,
				'standard' => q#Cookinseln-Normalzeit#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubanische Sommerzeit#,
				'generic' => q#Kubanische Zeit#,
				'standard' => q#Kubanische Normalzeit#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-Zeit#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville-Zeit#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Osttimor-Zeit#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Osterinsel-Sommerzeit#,
				'generic' => q#Osterinsel-Zeit#,
				'standard' => q#Osterinsel-Normalzeit#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadorianische Zeit#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Koordinierte Weltzeit#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unbekannt#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kischinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Irische Sommerzeit#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isle of Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirow#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q#Britische Sommerzeit#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratow#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanowsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mitteleuropäische Sommerzeit#,
				'generic' => q#Mitteleuropäische Zeit#,
				'standard' => q#Mitteleuropäische Normalzeit#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Osteuropäische Sommerzeit#,
				'generic' => q#Osteuropäische Zeit#,
				'standard' => q#Osteuropäische Normalzeit#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningrader Zeit#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Westeuropäische Sommerzeit#,
				'generic' => q#Westeuropäische Zeit#,
				'standard' => q#Westeuropäische Normalzeit#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandinseln-Sommerzeit#,
				'generic' => q#Falklandinseln-Zeit#,
				'standard' => q#Falklandinseln-Normalzeit#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidschi-Sommerzeit#,
				'generic' => q#Fidschi-Zeit#,
				'standard' => q#Fidschi-Normalzeit#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Französisch-Guayana-Zeit#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Französische Süd- und Antarktisgebiete-Zeit#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Mittlere Greenwich-Zeit#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos-Zeit#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier-Zeit#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgische Sommerzeit#,
				'generic' => q#Georgische Zeit#,
				'standard' => q#Georgische Normalzeit#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert-Inseln-Zeit#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ostgrönland-Sommerzeit#,
				'generic' => q#Ostgrönland-Zeit#,
				'standard' => q#Ostgrönland-Normalzeit#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Westgrönland-Sommerzeit#,
				'generic' => q#Westgrönland-Zeit#,
				'standard' => q#Westgrönland-Normalzeit#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam-Zeit#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golf-Zeit#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana-Zeit#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleuten-Sommerzeit#,
				'generic' => q#Hawaii-Aleuten-Zeit#,
				'standard' => q#Hawaii-Aleuten-Normalzeit#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkong-Sommerzeit#,
				'generic' => q#Hongkong-Zeit#,
				'standard' => q#Hongkong-Normalzeit#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chowd-Sommerzeit#,
				'generic' => q#Chowd-Zeit#,
				'standard' => q#Chowd-Normalzeit#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indische Zeit#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Weihnachtsinsel#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoren#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediven#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indischer Ozean-Zeit#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochina-Zeit#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Zentralindonesische Zeit#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ostindonesische Zeit#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Westindonesische Zeit#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iranische Sommerzeit#,
				'generic' => q#Iranische Zeit#,
				'standard' => q#Iranische Normalzeit#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk-Sommerzeit#,
				'generic' => q#Irkutsk-Zeit#,
				'standard' => q#Irkutsk-Normalzeit#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelische Sommerzeit#,
				'generic' => q#Israelische Zeit#,
				'standard' => q#Israelische Normalzeit#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japanische Sommerzeit#,
				'generic' => q#Japanische Zeit#,
				'standard' => q#Japanische Normalzeit#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Kamtschatka-Sommerzeit#,
				'generic' => q#Kamtschatka-Zeit#,
				'standard' => q#Kamtschatka-Normalzeit#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ostkasachische Zeit#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Westkasachische Zeit#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreanische Sommerzeit#,
				'generic' => q#Koreanische Zeit#,
				'standard' => q#Koreanische Normalzeit#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae-Zeit#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-Sommerzeit#,
				'generic' => q#Krasnojarsk-Zeit#,
				'standard' => q#Krasnojarsk-Normalzeit#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisistan-Zeit#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Sri-Lanka-Zeit#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linieninseln-Zeit#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord-Howe-Sommerzeit#,
				'generic' => q#Lord-Howe-Zeit#,
				'standard' => q#Lord-Howe-Normalzeit#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macau-Sommerzeit#,
				'generic' => q#Macau-Zeit#,
				'standard' => q#Macau-Normalzeit#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarieinsel-Zeit#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-Sommerzeit#,
				'generic' => q#Magadan-Zeit#,
				'standard' => q#Magadan-Normalzeit#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysische Zeit#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediven-Zeit#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas-Zeit#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshallinseln-Zeit#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius-Sommerzeit#,
				'generic' => q#Mauritius-Zeit#,
				'standard' => q#Mauritius-Normalzeit#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-Zeit#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Mexiko Nordwestliche Zone-Sommerzeit#,
				'generic' => q#Mexiko Nordwestliche Zone-Zeit#,
				'standard' => q#Mexiko Nordwestliche Zone-Normalzeit#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexiko Pazifikzone-Sommerzeit#,
				'generic' => q#Mexiko Pazifikzone-Zeit#,
				'standard' => q#Mexiko Pazifikzone-Normalzeit#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar-Sommerzeit#,
				'generic' => q#Ulaanbaatar-Zeit#,
				'standard' => q#Ulaanbaatar-Normalzeit#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskauer Sommerzeit#,
				'generic' => q#Moskauer Zeit#,
				'standard' => q#Moskauer Normalzeit#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar-Zeit#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru-Zeit#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalesische Zeit#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Neukaledonische Sommerzeit#,
				'generic' => q#Neukaledonische Zeit#,
				'standard' => q#Neukaledonische Normalzeit#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Neuseeland-Sommerzeit#,
				'generic' => q#Neuseeland-Zeit#,
				'standard' => q#Neuseeland-Normalzeit#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Neufundland-Sommerzeit#,
				'generic' => q#Neufundland-Zeit#,
				'standard' => q#Neufundland-Normalzeit#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue-Zeit#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolkinsel-Zeit#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha-Sommerzeit#,
				'generic' => q#Fernando de Noronha-Zeit#,
				'standard' => q#Fernando de Noronha-Normalzeit#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Nördliche-Marianen-Zeit#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirsk-Sommerzeit#,
				'generic' => q#Nowosibirsk-Zeit#,
				'standard' => q#Nowosibirsk-Normalzeit#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-Sommerzeit#,
				'generic' => q#Omsk-Zeit#,
				'standard' => q#Omsk-Normalzeit#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Osterinsel#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistanische Sommerzeit#,
				'generic' => q#Pakistanische Zeit#,
				'standard' => q#Pakistanische Normalzeit#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau-Zeit#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Neuguinea-Zeit#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayanische Sommerzeit#,
				'generic' => q#Paraguayanische Zeit#,
				'standard' => q#Paraguayanische Normalzeit#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruanische Sommerzeit#,
				'generic' => q#Peruanische Zeit#,
				'standard' => q#Peruanische Normalzeit#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippinische Sommerzeit#,
				'generic' => q#Philippinische Zeit#,
				'standard' => q#Philippinische Normalzeit#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixinseln-Zeit#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St.-Pierre-und-Miquelon-Sommerzeit#,
				'generic' => q#St.-Pierre-und-Miquelon-Zeit#,
				'standard' => q#St.-Pierre-und-Miquelon-Normalzeit#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairninseln-Zeit#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape-Zeit#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjöngjang-Zeit#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qysylorda-Sommerzeit#,
				'generic' => q#Quysylorda-Zeit#,
				'standard' => q#Quysylorda-Normalzeit#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion-Zeit#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-Zeit#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalin-Sommerzeit#,
				'generic' => q#Sachalin-Zeit#,
				'standard' => q#Sachalin-Normalzeit#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-Sommerzeit#,
				'generic' => q#Samara-Zeit#,
				'standard' => q#Samara-Normalzeit#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa-Sommerzeit#,
				'generic' => q#Samoa-Zeit#,
				'standard' => q#Samoa-Normalzeit#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellen-Zeit#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur-Zeit#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomonen-Zeit#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Südgeorgische Zeit#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname-Zeit#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-Zeit#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti-Zeit#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipeh-Sommerzeit#,
				'generic' => q#Taipeh-Zeit#,
				'standard' => q#Taipeh-Normalzeit#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadschikistan-Zeit#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-Zeit#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonganische Sommerzeit#,
				'generic' => q#Tonganische Zeit#,
				'standard' => q#Tonganische Normalzeit#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-Zeit#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan-Sommerzeit#,
				'generic' => q#Turkmenistan-Zeit#,
				'standard' => q#Turkmenistan-Normalzeit#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu-Zeit#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayanische Sommerzeit#,
				'generic' => q#Uruguayanische Zeit#,
				'standard' => q#Uruguyanische Normalzeit#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistan-Sommerzeit#,
				'generic' => q#Usbekistan-Zeit#,
				'standard' => q#Usbekistan-Normalzeit#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu-Sommerzeit#,
				'generic' => q#Vanuatu-Zeit#,
				'standard' => q#Vanuatu-Normalzeit#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela-Zeit#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostok-Sommerzeit#,
				'generic' => q#Wladiwostok-Zeit#,
				'standard' => q#Wladiwostok-Normalzeit#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd-Sommerzeit#,
				'generic' => q#Wolgograd-Zeit#,
				'standard' => q#Wolgograd-Normalzeit#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok-Zeit#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake-Insel-Zeit#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis-und-Futuna-Zeit#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk-Sommerzeit#,
				'generic' => q#Jakutsk-Zeit#,
				'standard' => q#Jakutsk-Normalzeit#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburg-Sommerzeit#,
				'generic' => q#Jekaterinburg-Zeit#,
				'standard' => q#Jekaterinburg-Normalzeit#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
