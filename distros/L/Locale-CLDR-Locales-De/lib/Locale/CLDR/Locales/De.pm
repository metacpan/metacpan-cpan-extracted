=encoding utf8

=head1 NAME

Locale::CLDR::Locales::De - Package for language German

=cut

package Locale::CLDR::Locales::De;
# This file auto generated from Data\common\main\de.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-neuter','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-n','spellout-cardinal-r','spellout-cardinal-s','spellout-cardinal-m','spellout-ordinal','spellout-ordinal-n','spellout-ordinal-r','spellout-ordinal-s','spellout-ordinal-m' ]},
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
		'spellout-cardinal-m' => {
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
					rule => q(einem),
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
					rule => q(←←­hundert[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(2000),
					divisor => q(1000),
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
		'spellout-ordinal-m' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal=m),
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
 				'ann' => 'Obolo',
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
 				'ast' => 'Asturisch',
 				'atj' => 'Atikamekw',
 				'av' => 'Awarisch',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschanisch',
 				'ba' => 'Baschkirisch',
 				'bal' => 'Belutschisch',
 				'ban' => 'Balinesisch',
 				'bar' => 'Bairisch',
 				'bas' => 'Bassa',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Belarussisch',
 				'bej' => 'Bedauye',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgarisch',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Westliches Belutschi',
 				'bho' => 'Bhodschpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjaresisch',
 				'bkm' => 'Kom',
 				'bla' => 'Blackfoot',
 				'blo' => 'Anii',
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
 				'ccp' => 'Chakma',
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
 				'ckb@alt=menu' => 'Kurdisch (Sorani)',
 				'clc' => 'Chilcotin',
 				'co' => 'Korsisch',
 				'cop' => 'Koptisch',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crg' => 'Michif',
 				'crh' => 'Krimtatarisch',
 				'crj' => 'Südost-Cree',
 				'crk' => 'Plains-Cree',
 				'crl' => 'Northern East Cree',
 				'crm' => 'Moose Cree',
 				'crr' => 'Carolina-Algonkin',
 				'crs' => 'Seychellenkreol',
 				'cs' => 'Tschechisch',
 				'csb' => 'Kaschubisch',
 				'csw' => 'Swampy Cree',
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
 				'enm' => 'Mittelenglisch',
 				'eo' => 'Esperanto',
 				'es' => 'Spanisch',
 				'esu' => 'Zentral-Alaska-Yupik',
 				'et' => 'Estnisch',
 				'eu' => 'Baskisch',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremadurisch',
 				'fa' => 'Persisch',
 				'fa_AF' => 'Dari',
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
 				'gd' => 'Gälisch (Schottland)',
 				'gez' => 'Geez',
 				'gil' => 'Kiribatisch',
 				'gl' => 'Galicisch',
 				'glk' => 'Gilaki',
 				'gmh' => 'Mittelhochdeutsch',
 				'gn' => 'Guaraní',
 				'goh' => 'Althochdeutsch',
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
 				'hax' => 'Süd-Haida',
 				'he' => 'Hebräisch',
 				'hi' => 'Hindi',
 				'hi_Latn' => 'Hindi (lateinisch)',
 				'hi_Latn@alt=variant' => 'Hinglish',
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
 				'hur' => 'Halkomelem',
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
 				'ikt' => 'Westkanadisches Inuktitut',
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
 				'kwk' => 'Kwakʼwala',
 				'kxv' => 'Kuvi',
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
 				'lil' => 'Lillooet',
 				'liv' => 'Livisch',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardisch',
 				'ln' => 'Lingala',
 				'lo' => 'Laotisch',
 				'lol' => 'Mongo',
 				'lou' => 'Kreol (Louisiana)',
 				'loz' => 'Lozi',
 				'lrc' => 'Nördliches Luri',
 				'lsm' => 'Saamia',
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
 				'mg' => 'Malagasy',
 				'mga' => 'Mittelirisch',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marschallesisch',
 				'mi' => 'Māori',
 				'mic' => 'Micmac',
 				'min' => 'Minangkabau',
 				'mk' => 'Mazedonisch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolisch',
 				'mnc' => 'Mandschurisch',
 				'mni' => 'Meithei',
 				'moe' => 'Innu-Aimun',
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
 				'nb' => 'Norwegisch (Bokmål)',
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
 				'nn' => 'Norwegisch (Nynorsk)',
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
 				'ojb' => 'Nordwest-Ojibwe',
 				'ojc' => 'Zentral-Ojibwe',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'West-Ojibwe',
 				'oka' => 'Okanagan',
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
 				'pis' => 'Pijin',
 				'pl' => 'Polnisch',
 				'pms' => 'Piemontesisch',
 				'pnt' => 'Pontisch',
 				'pon' => 'Ponapeanisch',
 				'pqm' => 'Maliseet-Passamaquoddy',
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
 				'rhg' => 'Rohingyalisch',
 				'rif' => 'Tarifit',
 				'rm' => 'Rätoromanisch',
 				'rn' => 'Rundi',
 				'ro' => 'Rumänisch',
 				'ro_MD' => 'Moldauisch',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
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
 				'slh' => 'Süd-Lushootseed',
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
 				'str' => 'Straits Salish',
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
 				'tce' => 'Südliches Tutchone',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Temne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Tadschikisch',
 				'tgx' => 'Tagish',
 				'th' => 'Thailändisch',
 				'tht' => 'Tahltan',
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
 				'tok' => 'Toki Pona',
 				'tpi' => 'Neumelanesisch',
 				'tr' => 'Türkisch',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonisch',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatarisch',
 				'ttm' => 'Nördliches Tutchone',
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
 				'vmw' => 'Makua',
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
 				'xnr' => 'Kangri',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapesisch',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddisch',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonesisch',
 				'yue@alt=menu' => 'Chinesisch (Kantonesisch)',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotekisch',
 				'zbl' => 'Bliss-Symbole',
 				'zea' => 'Seeländisch',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamazight',
 				'zh' => 'Chinesisch',
 				'zh@alt=menu' => 'Chinesisch (Mandarin)',
 				'zh_Hans' => 'Chinesisch (vereinfacht)',
 				'zh_Hans@alt=long' => 'Mandarin (Vereinfacht)',
 				'zh_Hant' => 'Chinesisch (traditionell)',
 				'zh_Hant@alt=long' => 'Mandarin (traditionell)',
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
			'Adlm' => 'Adlam',
 			'Afak' => 'Afaka',
 			'Aghb' => 'Kaukasisch-Albanisch',
 			'Arab' => 'Arabisch',
 			'Arab@alt=variant' => 'Persisch',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Aramäisch',
 			'Armn' => 'Armenisch',
 			'Avst' => 'Avestisch',
 			'Bali' => 'Balinesisch',
 			'Bamu' => 'Bamun',
 			'Bass' => 'Bassa',
 			'Batk' => 'Battakisch',
 			'Beng' => 'Bengalisch',
 			'Bhks' => 'Bhaiksuki',
 			'Blis' => 'Bliss-Symbole',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buginesisch',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Kanadische Aborigine-Silbenschrift',
 			'Cari' => 'Karisch',
 			'Cher' => 'Cherokee',
 			'Chrs' => 'Choresmisch',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptisch',
 			'Cpmn' => 'Minoisch',
 			'Cprt' => 'Zypriotisch',
 			'Cyrl' => 'Kyrillisch',
 			'Cyrs' => 'Altkirchenslawisch',
 			'Deva' => 'Devanagari',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployanisch',
 			'Egyd' => 'Ägyptisch - Demotisch',
 			'Egyh' => 'Ägyptisch - Hieratisch',
 			'Egyp' => 'Ägyptische Hieroglyphen',
 			'Elba' => 'Elbasanisch',
 			'Elym' => 'Elymäisch',
 			'Ethi' => 'Äthiopisch',
 			'Geok' => 'Khutsuri',
 			'Geor' => 'Georgisch',
 			'Glag' => 'Glagolitisch',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram-Gondi',
 			'Goth' => 'Gotisch',
 			'Gran' => 'Grantha',
 			'Grek' => 'Griechisch',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han mit Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Chinesisch',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Vereinfacht',
 			'Hans@alt=stand-alone' => 'Vereinfachtes Chinesisch',
 			'Hant' => 'Traditionell',
 			'Hant@alt=stand-alone' => 'Traditionelles Chinesisch',
 			'Hatr' => 'Hatranisch',
 			'Hebr' => 'Hebräisch',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Hieroglyphen-Luwisch',
 			'Hmng' => 'Pahawh Hmong',
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
 			'Hrkt' => 'Japanische Silbenschrift',
 			'Hung' => 'Altungarisch',
 			'Inds' => 'Indus-Schrift',
 			'Ital' => 'Altitalisch',
 			'Java' => 'Javanesisch',
 			'Jpan' => 'Japanisch',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Kits' => 'Chitan',
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
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandäisch',
 			'Mani' => 'Manichäisch',
 			'Marc' => 'Marchen',
 			'Maya' => 'Maya-Hieroglyphen',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitisch kursiv',
 			'Mero' => 'Meroitisch',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolisch',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei-Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Birmanisch',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Altnordarabisch',
 			'Nbat' => 'Nabatäisch',
 			'Nkgb' => 'Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Frauenschrift',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orchon-Runen',
 			'Orya' => 'Oriya',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanisch',
 			'Ougr' => 'Altuigurisch',
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
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi Rohingya',
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
 			'Sogd' => 'Sogdisch',
 			'Sogo' => 'Alt-Sogdisch',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Sojombo',
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
 			'Tibt' => 'Tibetisch',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritisch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Sichtbare Sprache',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Wole' => 'Woleaianisch',
 			'Xpeo' => 'Altpersisch',
 			'Xsux' => 'Sumerisch-akkadische Keilschrift',
 			'Yezi' => 'Jesidisch',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Dsanabadsar-Quadratschrift',
 			'Zinh' => 'Geerbter Schriftwert',
 			'Zmth' => 'Mathematische Notation',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Symbole',
 			'Zxxx' => 'Schriftlos',
 			'Zyyy' => 'Unbestimmt',
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
 			'BQ' => 'Karibische Niederlande',
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
 			'GB@alt=short' => 'UK',
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
 			'IO@alt=chagos' => 'Chagos-Archipel',
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
 			'MK' => 'Nordmazedonien',
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
 			'NZ@alt=variant' => 'Aotearoa (Neuseeland)',
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
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swasiland',
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
 			'XA' => 'Pseudo-Akzente',
 			'XB' => 'Pseudo-Bidi',
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
 			'UNIFON' => 'Unifon (phonetisch)',
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
 			'numbers' => 'Ziffern',
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
 				'ethiopic-amete-alem' => q{Äthiopischer Amätä-Aläm-Kalender},
 				'gregorian' => q{Gregorianischer Kalender},
 				'hebrew' => q{Hebräischer Kalender},
 				'indian' => q{Indischer Nationalkalender},
 				'islamic' => q{Hidschri-Kalender},
 				'islamic-civil' => q{Bürgerlicher Hidschri-Kalender (tabellarisch)},
 				'islamic-rgsa' => q{Islamischer Kalender (Saudi-Arabien, Beobachtung)},
 				'islamic-tbla' => q{Islamischer Kalender (tabellarisch, astronomische Epoche)},
 				'islamic-umalqura' => q{Hidschri-Kalender (Umm al-Qura)},
 				'iso8601' => q{ISO-8601-Kalender},
 				'japanese' => q{Japanischer Kalender},
 				'persian' => q{Persischer Kalender},
 				'roc' => q{Minguo-Kalender},
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
 				'big5han' => q{Traditionelle chinesische Sortierung (Big5)},
 				'compat' => q{Vorherige Sortierung, Kompatibilität},
 				'dictionary' => q{Lexikografische Sortierung},
 				'ducet' => q{Unicode-Sortierung},
 				'emoji' => q{Emoji-Sortierung},
 				'eor' => q{Europäische Sortierregeln},
 				'gb2312han' => q{Vereinfachte chinesische Sortierung (GB2312)},
 				'phonebook' => q{Telefonbuch-Sortierung},
 				'phonetic' => q{Phonetische Sortierung},
 				'pinyin' => q{Pinyin-Sortierung},
 				'search' => q{Allgemeine Suche},
 				'searchjl' => q{Suche nach Anfangsbuchstaben des koreanischen Alphabets},
 				'standard' => q{Standard-Sortierung},
 				'stroke' => q{Strichfolge},
 				'traditional' => q{Traditionelle Sortierung},
 				'unihan' => q{Radikal-und-Strich-Sortierung},
 				'zhuyin' => q{Zhuyin-Sortierung},
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
 				'fwidth' => q{Vollbreit},
 				'hwidth' => q{Halbbreit},
 				'npinyin' => q{Numerisch},
 			},
 			'hc' => {
 				'h11' => q{12-Stunden-Format (0–11)},
 				'h12' => q{12-Stunden-Format (1-12)},
 				'h23' => q{24-Stunden-Format (0-23)},
 				'h24' => q{24-Stunden-Format (1-24)},
 			},
 			'lb' => {
 				'loose' => q{Lockerer Zeilenumbruch},
 				'normal' => q{Normaler Zeilenumbruch},
 				'strict' => q{Fester Zeilenumbruch},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Metrisches System},
 				'uksystem' => q{Britisches Maßsystem},
 				'ussystem' => q{US-Maßsystem},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom-Ziffern},
 				'arab' => q{Arabisch-indische Ziffern},
 				'arabext' => q{Erweiterte arabisch-indische Ziffern},
 				'armn' => q{Armenische Ziffern},
 				'armnlow' => q{Armenische Ziffern in Kleinschrift},
 				'bali' => q{Balinesische Ziffern},
 				'beng' => q{Bengalische Ziffern},
 				'brah' => q{Brahmi-Ziffern},
 				'cakm' => q{Chakma-Ziffern},
 				'cham' => q{Cham-Ziffern},
 				'cyrl' => q{Kyrillische Zahlzeichen},
 				'deva' => q{Devanagari-Ziffern},
 				'ethi' => q{Äthiopische Ziffern},
 				'finance' => q{Finanzzahlen},
 				'fullwide' => q{Vollbreite Ziffern},
 				'geor' => q{Georgische Ziffern},
 				'gong' => q{Gunjala-Gondi-Ziffern},
 				'gonm' => q{Masaram-Gondi-Ziffern},
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
 				'hmng' => q{Pahawh-Hmong-Ziffern},
 				'hmnp' => q{Nyiakeng-Puachue-Hmong-Ziffern},
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
 				'mathbold' => q{Mathematische Fettschrift-Ziffern},
 				'mathdbl' => q{Mathematische Doppelstrich-Ziffern},
 				'mathmono' => q{Mathematische Konstantschrift-Ziffern},
 				'mathsanb' => q{Mathematische Grotesk-Fettschrift-Ziffern},
 				'mathsans' => q{Mathematische Grotesk-Ziffern},
 				'mlym' => q{Malayalam-Ziffern},
 				'modi' => q{Modi-Ziffern},
 				'mong' => q{Mongolische Ziffern},
 				'mroo' => q{Mro-Ziffern},
 				'mtei' => q{Meitei-Mayek-Ziffern},
 				'mymr' => q{Myanmar-Ziffern},
 				'mymrshan' => q{Myanmarische Shan-Ziffern},
 				'mymrtlng' => q{Myanmarische Tai-Laing-Ziffern},
 				'native' => q{Native Ziffern},
 				'nkoo' => q{N’Ko-Ziffern},
 				'olck' => q{Ol-Chiki-Ziffern},
 				'orya' => q{Oriya-Ziffern},
 				'osma' => q{Osmaniya-Ziffern},
 				'rohg' => q{Hanifi-Rohingya-Ziffern},
 				'roman' => q{Römische Ziffern},
 				'romanlow' => q{Römische Ziffern in Kleinschrift},
 				'saur' => q{Saurashtra-Ziffern},
 				'shrd' => q{Sharada-Ziffern},
 				'sind' => q{Khudawadi-Ziffern},
 				'sinh' => q{Sinhala-Lith-Ziffern},
 				'sora' => q{Sora-Sompeng-Ziffern},
 				'sund' => q{Sundanesische Ziffern},
 				'takr' => q{Takri-Ziffern},
 				'talu' => q{Neue Tai-Lü-Ziffern},
 				'taml' => q{Tamilische Ziffern},
 				'tamldec' => q{Tamil-Ziffern},
 				'telu' => q{Telugu-Ziffern},
 				'thai' => q{Thai-Ziffern},
 				'tibt' => q{Tibetische Ziffern},
 				'tirh' => q{Tirhuta-Ziffern},
 				'traditional' => q{Traditionelle Zahlen},
 				'vaii' => q{Vai-Ziffern},
 				'wara' => q{Warang-Citi-Ziffern},
 				'wcho' => q{Wancho-Ziffern},
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
			auxiliary => qr{[áàăâåãā æ ç éèĕêëē ğ íìĭîïİī ı ñ óòŏôøō œ ş úùŭûū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aä b c d e f g h i j k l m n oö p q r s ß t uü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(Himmelsrichtung),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(Himmelsrichtung),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(Dezi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(Dezi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(Piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(Piko{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(Femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(Femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(Atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(Atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(Zenti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(Zenti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(Zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(Zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(Yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(Yokto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(Ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(Ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(Milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(Milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(Quekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(Quekto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(Mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(Mikro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(Nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(Nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(Deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(Deka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(Tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(Tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(Peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(Peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(Exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(Exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(Hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(Hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Yotta{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(Ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(Ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(Kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(Kilo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(Quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(Quetta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(Mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(Mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(Giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(Giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(Meter pro Quadratsekunde),
						'one' => q({0} Meter pro Quadratsekunde),
						'other' => q({0} Meter pro Quadratsekunde),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(Meter pro Quadratsekunde),
						'one' => q({0} Meter pro Quadratsekunde),
						'other' => q({0} Meter pro Quadratsekunde),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminuten),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'one' => q({0} Winkelminute),
						'other' => q({0} Winkelminuten),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunden),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunden),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(neuter),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(neuter),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'name' => q(Radiant),
						'one' => q({0} Radiant),
						'other' => q({0} Radiant),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'name' => q(Radiant),
						'one' => q({0} Radiant),
						'other' => q({0} Radiant),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(Umdrehung),
						'one' => q({0} Umdrehung),
						'other' => q({0} Umdrehungen),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(Umdrehung),
						'one' => q({0} Umdrehung),
						'other' => q({0} Umdrehungen),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(masculine),
						'name' => q(Acres),
						'one' => q({0} Acre),
						'other' => q({0} Acres),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(masculine),
						'name' => q(Acres),
						'one' => q({0} Acre),
						'other' => q({0} Acres),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0} Dunam),
						'other' => q({0} Dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0} Dunam),
						'other' => q({0} Dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(Quadratzentimeter),
						'one' => q({0} Quadratzentimeter),
						'other' => q({0} Quadratzentimeter),
						'per' => q({0} pro Quadratzentimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(Quadratzentimeter),
						'one' => q({0} Quadratzentimeter),
						'other' => q({0} Quadratzentimeter),
						'per' => q({0} pro Quadratzentimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'name' => q(Quadratfuß),
						'one' => q({0} Quadratfuß),
						'other' => q({0} Quadratfuß),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'name' => q(Quadratfuß),
						'one' => q({0} Quadratfuß),
						'other' => q({0} Quadratfuß),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(Quadratzoll),
						'one' => q({0} Quadratzoll),
						'other' => q({0} Quadratzoll),
						'per' => q({0} pro Quadratzoll),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(Quadratzoll),
						'one' => q({0} Quadratzoll),
						'other' => q({0} Quadratzoll),
						'per' => q({0} pro Quadratzoll),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
						'per' => q({0} pro Quadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
						'per' => q({0} pro Quadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
						'per' => q({0} pro Quadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
						'per' => q({0} pro Quadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(feminine),
						'name' => q(Quadratmeilen),
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeilen),
						'per' => q({0} pro Quadratmeile),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(feminine),
						'name' => q(Quadratmeilen),
						'one' => q({0} Quadratmeile),
						'other' => q({0} Quadratmeilen),
						'per' => q({0} pro Quadratmeile),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(Quadratyards),
						'one' => q({0} Quadratyard),
						'other' => q({0} Quadratyards),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(Quadratyards),
						'one' => q({0} Quadratyard),
						'other' => q({0} Quadratyards),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(neuter),
						'name' => q(Elemente),
						'one' => q({0} Element),
						'other' => q({0} Elemente),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(neuter),
						'name' => q(Elemente),
						'one' => q({0} Element),
						'other' => q({0} Elemente),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(neuter),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(neuter),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(Milligramm pro Deziliter),
						'one' => q({0} Milligramm pro Deziliter),
						'other' => q({0} Milligramm pro Deziliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(Milligramm pro Deziliter),
						'one' => q({0} Milligramm pro Deziliter),
						'other' => q({0} Milligramm pro Deziliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(Millimol pro Liter),
						'one' => q({0} Millimol pro Liter),
						'other' => q({0} Millimol pro Liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(neuter),
						'name' => q(Millimol pro Liter),
						'one' => q({0} Millimol pro Liter),
						'other' => q({0} Millimol pro Liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(neuter),
						'name' => q(Mole),
						'one' => q({0} Mol),
						'other' => q({0} Mol),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(neuter),
						'name' => q(Mole),
						'one' => q({0} Mol),
						'other' => q({0} Mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'name' => q(Prozent),
						'one' => q({0} Prozent),
						'other' => q({0} Prozent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'name' => q(Prozent),
						'one' => q({0} Prozent),
						'other' => q({0} Prozent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(neuter),
						'name' => q(Promille),
						'one' => q({0} Promille),
						'other' => q({0} Promille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(neuter),
						'name' => q(Promille),
						'one' => q({0} Promille),
						'other' => q({0} Promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(neuter),
						'name' => q(Millionstel),
						'one' => q({0} Millionstel),
						'other' => q({0} Millionstel),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(neuter),
						'name' => q(Millionstel),
						'one' => q({0} Millionstel),
						'other' => q({0} Millionstel),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(neuter),
						'name' => q(Pro-Zehntausend),
						'one' => q({0} pro Zehntausend),
						'other' => q({0} pro Zehntausend),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(neuter),
						'name' => q(Pro-Zehntausend),
						'one' => q({0} pro Zehntausend),
						'other' => q({0} pro Zehntausend),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(neuter),
						'name' => q(Milliardstel),
						'one' => q({0} Milliardstel),
						'other' => q({0} Milliardstel),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(neuter),
						'name' => q(Milliardstel),
						'one' => q({0} Milliardstel),
						'other' => q({0} Milliardstel),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(Liter pro 100 Kilometer),
						'one' => q({0} Liter pro 100 Kilometer),
						'other' => q({0} Liter pro 100 Kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(Liter pro 100 Kilometer),
						'one' => q({0} Liter pro 100 Kilometer),
						'other' => q({0} Liter pro 100 Kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(Liter pro Kilometer),
						'one' => q({0} Liter pro Kilometer),
						'other' => q({0} Liter pro Kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(Liter pro Kilometer),
						'one' => q({0} Liter pro Kilometer),
						'other' => q({0} Liter pro Kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Gallone),
						'one' => q({0} Meile pro Gallone),
						'other' => q({0} Meilen pro Gallone),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Gallone),
						'one' => q({0} Meile pro Gallone),
						'other' => q({0} Meilen pro Gallone),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Imp. Gallone),
						'one' => q({0} Meile pro Imp. Gallone),
						'other' => q({0} Meilen pro Imp. Gallone),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Imp. Gallone),
						'one' => q({0} Meile pro Imp. Gallone),
						'other' => q({0} Meilen pro Imp. Gallone),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ost),
						'north' => q({0} Nord),
						'south' => q({0} Süd),
						'west' => q({0} West),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ost),
						'north' => q({0} Nord),
						'south' => q({0} Süd),
						'west' => q({0} West),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(neuter),
						'name' => q(Bits),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(neuter),
						'name' => q(Bits),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(neuter),
						'name' => q(Bytes),
						'one' => q({0} Byte),
						'other' => q({0} Byte),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(neuter),
						'name' => q(Bytes),
						'one' => q({0} Byte),
						'other' => q({0} Byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(neuter),
						'name' => q(Gigabits),
						'one' => q({0} Gigabit),
						'other' => q({0} Gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(neuter),
						'name' => q(Gigabits),
						'one' => q({0} Gigabit),
						'other' => q({0} Gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(neuter),
						'name' => q(Gigabytes),
						'one' => q({0} Gigabyte),
						'other' => q({0} Gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(neuter),
						'name' => q(Gigabytes),
						'one' => q({0} Gigabyte),
						'other' => q({0} Gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(neuter),
						'name' => q(Kilobits),
						'one' => q({0} Kilobit),
						'other' => q({0} Kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(neuter),
						'name' => q(Kilobits),
						'one' => q({0} Kilobit),
						'other' => q({0} Kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(neuter),
						'name' => q(Kilobytes),
						'one' => q({0} Kilobyte),
						'other' => q({0} Kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(neuter),
						'name' => q(Kilobytes),
						'one' => q({0} Kilobyte),
						'other' => q({0} Kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(neuter),
						'name' => q(Megabits),
						'one' => q({0} Megabit),
						'other' => q({0} Megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(neuter),
						'name' => q(Megabits),
						'one' => q({0} Megabit),
						'other' => q({0} Megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(neuter),
						'name' => q(Megabytes),
						'one' => q({0} Megabyte),
						'other' => q({0} Megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(neuter),
						'name' => q(Megabytes),
						'one' => q({0} Megabyte),
						'other' => q({0} Megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(neuter),
						'name' => q(Petabytes),
						'one' => q({0} Petabyte),
						'other' => q({0} Petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(neuter),
						'name' => q(Petabytes),
						'one' => q({0} Petabyte),
						'other' => q({0} Petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(neuter),
						'name' => q(Terabits),
						'one' => q({0} Terabit),
						'other' => q({0} Terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(neuter),
						'name' => q(Terabits),
						'one' => q({0} Terabit),
						'other' => q({0} Terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(neuter),
						'name' => q(Terabytes),
						'one' => q({0} Terabyte),
						'other' => q({0} Terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(neuter),
						'name' => q(Terabytes),
						'one' => q({0} Terabyte),
						'other' => q({0} Terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'name' => q(Jahrhunderte),
						'one' => q({0} Jahrhundert),
						'other' => q({0} Jahrhunderte),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'name' => q(Jahrhunderte),
						'one' => q({0} Jahrhundert),
						'other' => q({0} Jahrhunderte),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'name' => q(Tage),
						'one' => q({0} Tag),
						'other' => q({0} Tage),
						'per' => q({0} pro Tag),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'name' => q(Tage),
						'one' => q({0} Tag),
						'other' => q({0} Tage),
						'per' => q({0} pro Tag),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(masculine),
						'one' => q({0} Tag),
						'other' => q({0} Tage),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(masculine),
						'one' => q({0} Tag),
						'other' => q({0} Tage),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'name' => q(Jahrzehnte),
						'one' => q({0} Jahrzehnt),
						'other' => q({0} Jahrzehnte),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'name' => q(Jahrzehnte),
						'one' => q({0} Jahrzehnt),
						'other' => q({0} Jahrzehnte),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'name' => q(Stunden),
						'one' => q({0} Stunde),
						'other' => q({0} Stunden),
						'per' => q({0} pro Stunde),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'name' => q(Stunden),
						'one' => q({0} Stunde),
						'other' => q({0} Stunden),
						'per' => q({0} pro Stunde),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'name' => q(Mikrosekunden),
						'one' => q({0} Mikrosekunde),
						'other' => q({0} Mikrosekunden),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'name' => q(Mikrosekunden),
						'one' => q({0} Mikrosekunde),
						'other' => q({0} Mikrosekunden),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'name' => q(Millisekunden),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunden),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'name' => q(Millisekunden),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunden),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'name' => q(Minuten),
						'one' => q({0} Minute),
						'other' => q({0} Minuten),
						'per' => q({0} pro Minute),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'name' => q(Minuten),
						'one' => q({0} Minute),
						'other' => q({0} Minuten),
						'per' => q({0} pro Minute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'name' => q(Monate),
						'one' => q({0} Monat),
						'other' => q({0} Monate),
						'per' => q({0} pro Monat),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'name' => q(Monate),
						'one' => q({0} Monat),
						'other' => q({0} Monate),
						'per' => q({0} pro Monat),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'name' => q(Nanosekunden),
						'one' => q({0} Nanosekunde),
						'other' => q({0} Nanosekunden),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'name' => q(Nanosekunden),
						'one' => q({0} Nanosekunde),
						'other' => q({0} Nanosekunden),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(feminine),
						'name' => q(Übernachtungen),
						'one' => q({0} Übernachtung),
						'other' => q({0} Übernachtungen),
						'per' => q({0} pro Übernachtung),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(feminine),
						'name' => q(Übernachtungen),
						'one' => q({0} Übernachtung),
						'other' => q({0} Übernachtungen),
						'per' => q({0} pro Übernachtung),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'name' => q(Quartale),
						'one' => q({0} Quartal),
						'other' => q({0} Quartale),
						'per' => q({0}/Quartal),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'name' => q(Quartale),
						'one' => q({0} Quartal),
						'other' => q({0} Quartale),
						'per' => q({0}/Quartal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'name' => q(Sekunden),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunden),
						'per' => q({0} pro Sekunde),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'name' => q(Sekunden),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunden),
						'per' => q({0} pro Sekunde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'name' => q(Wochen),
						'one' => q({0} Woche),
						'other' => q({0} Wochen),
						'per' => q({0} pro Woche),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'name' => q(Wochen),
						'one' => q({0} Woche),
						'other' => q({0} Wochen),
						'per' => q({0} pro Woche),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'name' => q(Jahre),
						'one' => q({0} Jahr),
						'other' => q({0} Jahre),
						'per' => q({0} pro Jahr),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'name' => q(Jahre),
						'one' => q({0} Jahr),
						'other' => q({0} Jahre),
						'per' => q({0} pro Jahr),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(neuter),
						'one' => q({0} Ampere),
						'other' => q({0} Ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(neuter),
						'one' => q({0} Ampere),
						'other' => q({0} Ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(neuter),
						'name' => q(Milliampere),
						'one' => q({0} Milliampere),
						'other' => q({0} Milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(neuter),
						'name' => q(Milliampere),
						'one' => q({0} Milliampere),
						'other' => q({0} Milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(neuter),
						'one' => q({0} Ohm),
						'other' => q({0} Ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(neuter),
						'one' => q({0} Ohm),
						'other' => q({0} Ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(neuter),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(neuter),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal units),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(Kalorien),
						'one' => q({0} Kalorie),
						'other' => q({0} Kalorien),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(Kalorien),
						'one' => q({0} Kalorie),
						'other' => q({0} Kalorien),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(Elektronenvolt),
						'one' => q({0} Elektronenvolt),
						'other' => q({0} Elektronenvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(Elektronenvolt),
						'one' => q({0} Elektronenvolt),
						'other' => q({0} Elektronenvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(feminine),
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(feminine),
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(neuter),
						'one' => q({0} Joule),
						'other' => q({0} Joule),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(neuter),
						'one' => q({0} Joule),
						'other' => q({0} Joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(neuter),
						'one' => q({0} Kilojoule),
						'other' => q({0} Kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(neuter),
						'one' => q({0} Kilojoule),
						'other' => q({0} Kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(Kilowattstunden),
						'one' => q({0} Kilowattstunde),
						'other' => q({0} Kilowattstunden),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'name' => q(Kilowattstunden),
						'one' => q({0} Kilowattstunde),
						'other' => q({0} Kilowattstunden),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US thermal units),
						'one' => q({0} US thermal unit),
						'other' => q({0} US thermal units),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US thermal units),
						'one' => q({0} US thermal unit),
						'other' => q({0} US thermal units),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'name' => q(Kilowattstunde pro 100 Kilometer),
						'one' => q({0} Kilowattstunde pro 100 Kilometer),
						'other' => q({0} Kilowattstunden pro 100 Kilometer),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
						'name' => q(Kilowattstunde pro 100 Kilometer),
						'one' => q({0} Kilowattstunde pro 100 Kilometer),
						'other' => q({0} Kilowattstunden pro 100 Kilometer),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(neuter),
						'name' => q(Newton),
						'one' => q({0} Newton),
						'other' => q({0} Newton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(neuter),
						'name' => q(Newton),
						'one' => q({0} Newton),
						'other' => q({0} Newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(Pound-force),
						'one' => q({0} Pound-force),
						'other' => q({0} Pound-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(Pound-force),
						'one' => q({0} Pound-force),
						'other' => q({0} Pound-force),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(neuter),
						'name' => q(Gigahertz),
						'one' => q({0} Gigahertz),
						'other' => q({0} Gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(neuter),
						'name' => q(Gigahertz),
						'one' => q({0} Gigahertz),
						'other' => q({0} Gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(neuter),
						'name' => q(Hertz),
						'one' => q({0} Hertz),
						'other' => q({0} Hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(neuter),
						'name' => q(Hertz),
						'one' => q({0} Hertz),
						'other' => q({0} Hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(neuter),
						'name' => q(Kilohertz),
						'one' => q({0} Kilohertz),
						'other' => q({0} Kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(neuter),
						'name' => q(Kilohertz),
						'one' => q({0} Kilohertz),
						'other' => q({0} Kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(neuter),
						'name' => q(Megahertz),
						'one' => q({0} Megahertz),
						'other' => q({0} Megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(neuter),
						'name' => q(Megahertz),
						'one' => q({0} Megahertz),
						'other' => q({0} Megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} Dot),
						'other' => q({0} Dots),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} Dot),
						'other' => q({0} Dots),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(Dots pro Zentimeter),
						'one' => q({0} Dot pro Zentimeter),
						'other' => q({0} Dots pro Zentimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(Dots pro Zentimeter),
						'one' => q({0} Dot pro Zentimeter),
						'other' => q({0} Dots pro Zentimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(Dots pro Inch),
						'one' => q({0} Dot pro Inch),
						'other' => q({0} Dots pro Inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(Dots pro Inch),
						'one' => q({0} Dot pro Inch),
						'other' => q({0} Dots pro Inch),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(neuter),
						'name' => q(Megapixel),
						'one' => q({0} Megapixel),
						'other' => q({0} Megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(neuter),
						'name' => q(Megapixel),
						'one' => q({0} Megapixel),
						'other' => q({0} Megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(neuter),
						'name' => q(Pixel),
						'one' => q({0} Pixel),
						'other' => q({0} Pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(neuter),
						'name' => q(Pixel),
						'one' => q({0} Pixel),
						'other' => q({0} Pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(neuter),
						'name' => q(Pixel pro Zentimeter),
						'one' => q({0} Pixel pro Zentimeter),
						'other' => q({0} Pixel pro Zentimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(neuter),
						'name' => q(Pixel pro Zentimeter),
						'one' => q({0} Pixel pro Zentimeter),
						'other' => q({0} Pixel pro Zentimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(Pixel pro Inch),
						'one' => q({0} Pixel pro Inch),
						'other' => q({0} Pixel pro Inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(Pixel pro Inch),
						'one' => q({0} Pixel pro Inch),
						'other' => q({0} Pixel pro Inch),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(Astronomische Einheiten),
						'one' => q({0} Astronomische Einheit),
						'other' => q({0} Astronomische Einheiten),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(Astronomische Einheiten),
						'one' => q({0} Astronomische Einheit),
						'other' => q({0} Astronomische Einheiten),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
						'per' => q({0} pro Zentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
						'per' => q({0} pro Zentimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(Dezimeter),
						'one' => q({0} Dezimeter),
						'other' => q({0} Dezimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(Dezimeter),
						'one' => q({0} Dezimeter),
						'other' => q({0} Dezimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Erdradius),
						'one' => q({0} Erdradius),
						'other' => q({0} Erdradien),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Erdradius),
						'one' => q({0} Erdradius),
						'other' => q({0} Erdradien),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(Nautischer Faden),
						'one' => q({0} Faden),
						'other' => q({0} Faden),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(Nautischer Faden),
						'one' => q({0} Faden),
						'other' => q({0} Faden),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'one' => q({0} Fuß),
						'other' => q({0} Fuß),
						'per' => q({0} pro Fuß),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'one' => q({0} Fuß),
						'other' => q({0} Fuß),
						'per' => q({0} pro Fuß),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(Furlongs),
						'one' => q({0} Furlong),
						'other' => q({0} Furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(Furlongs),
						'one' => q({0} Furlong),
						'other' => q({0} Furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(masculine),
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
						'per' => q({0} pro Zoll),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(masculine),
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
						'per' => q({0} pro Zoll),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
						'per' => q({0} pro Kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
						'per' => q({0} pro Kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(Lichtjahre),
						'one' => q({0} Lichtjahr),
						'other' => q({0} Lichtjahre),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Lichtjahre),
						'one' => q({0} Lichtjahr),
						'other' => q({0} Lichtjahre),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
						'per' => q({0} pro Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
						'per' => q({0} pro Meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(Mikrometer),
						'one' => q({0} Mikrometer),
						'other' => q({0} Mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(Mikrometer),
						'one' => q({0} Mikrometer),
						'other' => q({0} Mikrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(feminine),
						'one' => q({0} Meile),
						'other' => q({0} Meilen),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(feminine),
						'one' => q({0} Meile),
						'other' => q({0} Meilen),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(skandinavische Meilen),
						'one' => q({0} skandinavische Meile),
						'other' => q({0} skandinavische Meilen),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(skandinavische Meilen),
						'one' => q({0} skandinavische Meile),
						'other' => q({0} skandinavische Meilen),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(Nanometer),
						'one' => q({0} Nanometer),
						'other' => q({0} Nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(Nanometer),
						'one' => q({0} Nanometer),
						'other' => q({0} Nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(Seemeilen),
						'one' => q({0} Seemeile),
						'other' => q({0} Seemeilen),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(Seemeilen),
						'one' => q({0} Seemeile),
						'other' => q({0} Seemeilen),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(neuter),
						'name' => q(Parsec),
						'one' => q({0} Parsec),
						'other' => q({0} Parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(neuter),
						'name' => q(Parsec),
						'one' => q({0} Parsec),
						'other' => q({0} Parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(masculine),
						'name' => q(DTP-Punkte),
						'one' => q({0} DTP-Punkt),
						'other' => q({0} DTP-Punkte),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(masculine),
						'name' => q(DTP-Punkte),
						'one' => q({0} DTP-Punkt),
						'other' => q({0} DTP-Punkte),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'name' => q(Sonnenradien),
						'one' => q({0} Sonnenradius),
						'other' => q({0} Sonnenradien),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'name' => q(Sonnenradien),
						'one' => q({0} Sonnenradius),
						'other' => q({0} Sonnenradien),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(neuter),
						'one' => q({0} Yard),
						'other' => q({0} Yards),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(neuter),
						'one' => q({0} Yard),
						'other' => q({0} Yards),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'name' => q(Candela),
						'one' => q({0} Candela),
						'other' => q({0} Candela),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'name' => q(Candela),
						'one' => q({0} Candela),
						'other' => q({0} Candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(neuter),
						'name' => q(Lumen),
						'one' => q({0} Lumen),
						'other' => q({0} Lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(neuter),
						'name' => q(Lumen),
						'one' => q({0} Lumen),
						'other' => q({0} Lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(neuter),
						'one' => q({0} Lux),
						'other' => q({0} Lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(neuter),
						'one' => q({0} Lux),
						'other' => q({0} Lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(Sonnenleuchtkräfte),
						'one' => q({0} Sonnenleuchtkraft),
						'other' => q({0} Sonnenleuchtkräfte),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(Sonnenleuchtkräfte),
						'one' => q({0} Sonnenleuchtkraft),
						'other' => q({0} Sonnenleuchtkräfte),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(neuter),
						'name' => q(Karat),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(neuter),
						'name' => q(Karat),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(neuter),
						'name' => q(Dalton),
						'one' => q({0} Dalton),
						'other' => q({0} Dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(neuter),
						'name' => q(Dalton),
						'one' => q({0} Dalton),
						'other' => q({0} Dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(feminine),
						'name' => q(Erdmassen),
						'one' => q({0} Erdmasse),
						'other' => q({0} Erdmassen),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(feminine),
						'name' => q(Erdmassen),
						'one' => q({0} Erdmasse),
						'other' => q({0} Erdmassen),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(neuter),
						'one' => q({0} Gran),
						'other' => q({0} Gran),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(neuter),
						'one' => q({0} Gran),
						'other' => q({0} Gran),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
						'per' => q({0} pro Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
						'per' => q({0} pro Gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
						'per' => q({0} pro Kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
						'per' => q({0} pro Kilogramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(neuter),
						'name' => q(Mikrogramm),
						'one' => q({0} Mikrogramm),
						'other' => q({0} Mikrogramm),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(neuter),
						'name' => q(Mikrogramm),
						'one' => q({0} Mikrogramm),
						'other' => q({0} Mikrogramm),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(neuter),
						'name' => q(Milligramm),
						'one' => q({0} Milligramm),
						'other' => q({0} Milligramm),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(neuter),
						'name' => q(Milligramm),
						'one' => q({0} Milligramm),
						'other' => q({0} Milligramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'per' => q({0} pro Unze),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'per' => q({0} pro Unze),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(Feinunzen),
						'one' => q({0} Feinunze),
						'other' => q({0} Feinunzen),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(Feinunzen),
						'one' => q({0} Feinunze),
						'other' => q({0} Feinunzen),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(neuter),
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'per' => q({0} pro Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(neuter),
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'per' => q({0} pro Pfund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(feminine),
						'name' => q(Sonnenmassen),
						'one' => q({0} Sonnenmasse),
						'other' => q({0} Sonnenmassen),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(feminine),
						'name' => q(Sonnenmassen),
						'one' => q({0} Sonnenmasse),
						'other' => q({0} Sonnenmassen),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} Stone),
						'other' => q({0} Stones),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} Stone),
						'other' => q({0} Stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(Short Tons),
						'one' => q({0} Short Ton),
						'other' => q({0} Short Tons),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(Short Tons),
						'one' => q({0} Short Ton),
						'other' => q({0} Short Tons),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(Tonnen),
						'one' => q({0} Tonne),
						'other' => q({0} Tonnen),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(Tonnen),
						'one' => q({0} Tonne),
						'other' => q({0} Tonnen),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(neuter),
						'name' => q(Gigawatt),
						'one' => q({0} Gigawatt),
						'other' => q({0} Gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(neuter),
						'name' => q(Gigawatt),
						'one' => q({0} Gigawatt),
						'other' => q({0} Gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärken),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(Pferdestärke),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärken),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(neuter),
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(neuter),
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(neuter),
						'name' => q(Megawatt),
						'one' => q({0} Megawatt),
						'other' => q({0} Megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(neuter),
						'name' => q(Megawatt),
						'one' => q({0} Megawatt),
						'other' => q({0} Megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(neuter),
						'name' => q(Milliwatt),
						'one' => q({0} Milliwatt),
						'other' => q({0} Milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(neuter),
						'name' => q(Milliwatt),
						'one' => q({0} Milliwatt),
						'other' => q({0} Milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(neuter),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(neuter),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(Quadrat{0}),
						'one' => q(Quadrat{0}),
						'other' => q(Quadrat{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(Quadrat{0}),
						'one' => q(Quadrat{0}),
						'other' => q(Quadrat{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(Kubik{0}),
						'one' => q(Kubik{0}),
						'other' => q(Kubik{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(Kubik{0}),
						'one' => q(Kubik{0}),
						'other' => q(Kubik{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(Atmosphären),
						'one' => q({0} Atmosphäre),
						'other' => q({0} Atmosphären),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(Atmosphären),
						'one' => q({0} Atmosphäre),
						'other' => q({0} Atmosphären),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(neuter),
						'name' => q(Bar),
						'one' => q({0} Bar),
						'other' => q({0} Bar),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(neuter),
						'name' => q(Bar),
						'one' => q({0} Bar),
						'other' => q({0} Bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(neuter),
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(neuter),
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Zoll Quecksilbersäule),
						'one' => q({0} Zoll Quecksilbersäule),
						'other' => q({0} Zoll Quecksilbersäule),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Zoll Quecksilbersäule),
						'one' => q({0} Zoll Quecksilbersäule),
						'other' => q({0} Zoll Quecksilbersäule),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(neuter),
						'name' => q(Kilopascal),
						'one' => q({0} Kilopascal),
						'other' => q({0} Kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(neuter),
						'name' => q(Kilopascal),
						'one' => q({0} Kilopascal),
						'other' => q({0} Kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(neuter),
						'name' => q(Megapascal),
						'one' => q({0} Megapascal),
						'other' => q({0} Megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(neuter),
						'name' => q(Megapascal),
						'one' => q({0} Megapascal),
						'other' => q({0} Megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(neuter),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(neuter),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(Millimeter Quecksilbersäule),
						'one' => q({0} Millimeter Quecksilbersäule),
						'other' => q({0} Millimeter Quecksilbersäule),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(Millimeter Quecksilbersäule),
						'one' => q({0} Millimeter Quecksilbersäule),
						'other' => q({0} Millimeter Quecksilbersäule),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(neuter),
						'name' => q(Pascal),
						'one' => q({0} Pascal),
						'other' => q({0} Pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(neuter),
						'name' => q(Pascal),
						'one' => q({0} Pascal),
						'other' => q({0} Pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(Pfund pro Quadratzoll),
						'one' => q({0} Pfund pro Quadratzoll),
						'other' => q({0} Pfund pro Quadratzoll),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(Pfund pro Quadratzoll),
						'one' => q({0} Pfund pro Quadratzoll),
						'other' => q({0} Pfund pro Quadratzoll),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'1' => q(neuter),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'1' => q(neuter),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(Kilometer pro Stunde),
						'one' => q({0} Kilometer pro Stunde),
						'other' => q({0} Kilometer pro Stunde),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(Kilometer pro Stunde),
						'one' => q({0} Kilometer pro Stunde),
						'other' => q({0} Kilometer pro Stunde),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(Knoten),
						'one' => q({0} Knoten),
						'other' => q({0} Knoten),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(Knoten),
						'one' => q({0} Knoten),
						'other' => q({0} Knoten),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Stunde),
						'one' => q({0} Meile pro Stunde),
						'other' => q({0} Meilen pro Stunde),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(Meilen pro Stunde),
						'one' => q({0} Meile pro Stunde),
						'other' => q({0} Meilen pro Stunde),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(neuter),
						'name' => q(Grad Celsius),
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(neuter),
						'name' => q(Grad Celsius),
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(neuter),
						'name' => q(Grad Fahrenheit),
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(neuter),
						'name' => q(Grad Fahrenheit),
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(neuter),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(neuter),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(neuter),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(neuter),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(Newtonmeter),
						'one' => q({0} Newtonmeter),
						'other' => q({0} Newtonmeter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(Newtonmeter),
						'one' => q({0} Newtonmeter),
						'other' => q({0} Newtonmeter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(Foot-pound),
						'one' => q({0} Foot-pound),
						'other' => q({0} Foot-pound),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(Foot-pound),
						'one' => q({0} Foot-pound),
						'other' => q({0} Foot-pound),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} Acre-Foot),
						'other' => q({0} Acre-Feet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} Acre-Foot),
						'other' => q({0} Acre-Feet),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(Barrel),
						'one' => q({0} Barrel),
						'other' => q({0} Barrel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(Barrel),
						'one' => q({0} Barrel),
						'other' => q({0} Barrel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} Bushel),
						'other' => q({0} Bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} Bushel),
						'other' => q({0} Bushel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(Zentiliter),
						'one' => q({0} Zentiliter),
						'other' => q({0} Zentiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(Zentiliter),
						'one' => q({0} Zentiliter),
						'other' => q({0} Zentiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(Kubikzentimeter),
						'one' => q({0} Kubikzentimeter),
						'other' => q({0} Kubikzentimeter),
						'per' => q({0} pro Kubikzentimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(Kubikzentimeter),
						'one' => q({0} Kubikzentimeter),
						'other' => q({0} Kubikzentimeter),
						'per' => q({0} pro Kubikzentimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(masculine),
						'name' => q(Kubikfuß),
						'one' => q({0} Kubikfuß),
						'other' => q({0} Kubikfuß),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(Kubikfuß),
						'one' => q({0} Kubikfuß),
						'other' => q({0} Kubikfuß),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(Kubikzoll),
						'one' => q({0} Kubikzoll),
						'other' => q({0} Kubikzoll),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(Kubikzoll),
						'one' => q({0} Kubikzoll),
						'other' => q({0} Kubikzoll),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(Kubikmeter),
						'one' => q({0} Kubikmeter),
						'other' => q({0} Kubikmeter),
						'per' => q({0} pro Kubikmeter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(Kubikmeter),
						'one' => q({0} Kubikmeter),
						'other' => q({0} Kubikmeter),
						'per' => q({0} pro Kubikmeter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(feminine),
						'name' => q(Kubikmeilen),
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeilen),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(feminine),
						'name' => q(Kubikmeilen),
						'one' => q({0} Kubikmeile),
						'other' => q({0} Kubikmeilen),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(Kubikyards),
						'one' => q({0} Kubikyard),
						'other' => q({0} Kubikyards),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(Kubikyards),
						'one' => q({0} Kubikyard),
						'other' => q({0} Kubikyards),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(feminine),
						'name' => q(Tassen),
						'one' => q({0} Tasse),
						'other' => q({0} Tassen),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(feminine),
						'name' => q(Tassen),
						'one' => q({0} Tasse),
						'other' => q({0} Tassen),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(metrische Tassen),
						'one' => q({0} metrische Tasse),
						'other' => q({0} metrische Tassen),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(metrische Tassen),
						'one' => q({0} metrische Tasse),
						'other' => q({0} metrische Tassen),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(Deziliter),
						'one' => q({0} Deziliter),
						'other' => q({0} Deziliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(Deziliter),
						'one' => q({0} Deziliter),
						'other' => q({0} Deziliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(Dessertlöffel),
						'one' => q({0} Dessertlöffel),
						'other' => q({0} Dessertlöffel),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(Dessertlöffel),
						'one' => q({0} Dessertlöffel),
						'other' => q({0} Dessertlöffel),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(Imp. Dessertlöffel),
						'one' => q({0} Imp. Dessertlöffel),
						'other' => q({0} Imp. Dessertlöffel),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(Imp. Dessertlöffel),
						'one' => q({0} Imp. Dessertlöffel),
						'other' => q({0} Imp. Dessertlöffel),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(neuter),
						'name' => q(Dram),
						'one' => q({0} Dram),
						'other' => q({0} Dram),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(neuter),
						'name' => q(Dram),
						'one' => q({0} Dram),
						'other' => q({0} Dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(masculine),
						'name' => q(Tropfen),
						'one' => q({0} Tropfen),
						'other' => q({0} Tropfen),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(masculine),
						'name' => q(Tropfen),
						'one' => q({0} Tropfen),
						'other' => q({0} Tropfen),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(Flüssigunzen),
						'one' => q({0} Flüssigunze),
						'other' => q({0} Flüssigunzen),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(Flüssigunzen),
						'one' => q({0} Flüssigunze),
						'other' => q({0} Flüssigunzen),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(Imp. Flüssigunzen),
						'one' => q({0} Imp. Flüssigunze),
						'other' => q({0} Imp. Flüssigunzen),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(Imp. Flüssigunzen),
						'one' => q({0} Imp. Flüssigunze),
						'other' => q({0} Imp. Flüssigunzen),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(feminine),
						'name' => q(Gallone),
						'one' => q({0} Gallone),
						'other' => q({0} Gallonen),
						'per' => q({0} pro Gallone),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(feminine),
						'name' => q(Gallone),
						'one' => q({0} Gallone),
						'other' => q({0} Gallonen),
						'per' => q({0} pro Gallone),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(Imp. Gallonen),
						'one' => q({0} Imp. Gallone),
						'other' => q({0} Imp. Gallonen),
						'per' => q({0} pro Imp. Gallone),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(Imp. Gallonen),
						'one' => q({0} Imp. Gallone),
						'other' => q({0} Imp. Gallonen),
						'per' => q({0} pro Imp. Gallone),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(Hektoliter),
						'one' => q({0} Hektoliter),
						'other' => q({0} Hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(Hektoliter),
						'one' => q({0} Hektoliter),
						'other' => q({0} Hektoliter),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(masculine),
						'one' => q({0} Jigger),
						'other' => q({0} Jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(masculine),
						'one' => q({0} Jigger),
						'other' => q({0} Jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
						'per' => q({0} pro Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
						'per' => q({0} pro Liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(Megaliter),
						'one' => q({0} Megaliter),
						'other' => q({0} Megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(Megaliter),
						'one' => q({0} Megaliter),
						'other' => q({0} Megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(Milliliter),
						'one' => q({0} Milliliter),
						'other' => q({0} Milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(Milliliter),
						'one' => q({0} Milliliter),
						'other' => q({0} Milliliter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(feminine),
						'one' => q({0} Prise),
						'other' => q({0} Prisen),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(feminine),
						'one' => q({0} Prise),
						'other' => q({0} Prisen),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(neuter),
						'name' => q(Pints),
						'one' => q({0} Pint),
						'other' => q({0} Pints),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(neuter),
						'name' => q(Pints),
						'one' => q({0} Pint),
						'other' => q({0} Pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(neuter),
						'name' => q(metrische Pints),
						'one' => q({0} metrisches Pint),
						'other' => q({0} metrische Pints),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(neuter),
						'name' => q(metrische Pints),
						'one' => q({0} metrisches Pint),
						'other' => q({0} metrische Pints),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(neuter),
						'name' => q(Quarts),
						'one' => q({0} Quart),
						'other' => q({0} Quart),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(neuter),
						'name' => q(Quarts),
						'one' => q({0} Quart),
						'other' => q({0} Quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(neuter),
						'name' => q(Imp. Quart),
						'one' => q({0} Imp. Quart),
						'other' => q({0} Imp. Quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(neuter),
						'name' => q(Imp. Quart),
						'one' => q({0} Imp. Quart),
						'other' => q({0} Imp. Quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(masculine),
						'name' => q(Esslöffel),
						'one' => q({0} Esslöffel),
						'other' => q({0} Esslöffel),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(masculine),
						'name' => q(Esslöffel),
						'one' => q({0} Esslöffel),
						'other' => q({0} Esslöffel),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(masculine),
						'name' => q(Teelöffel),
						'one' => q({0} Teelöffel),
						'other' => q({0} Teelöffel),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(masculine),
						'name' => q(Teelöffel),
						'one' => q({0} Teelöffel),
						'other' => q({0} Teelöffel),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(NOSW),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(NOSW),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(U),
						'one' => q({0} U),
						'other' => q({0} U),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(U),
						'one' => q({0} U),
						'other' => q({0} U),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(Dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(Dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(Elem.),
						'one' => q({0} Elem.),
						'other' => q({0} Elem.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(Elem.),
						'one' => q({0} Elem.),
						'other' => q({0} Elem.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0} mpg UK),
						'other' => q({0} mpg UK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0} mpg UK),
						'other' => q({0} mpg UK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(T),
						'one' => q({0} T),
						'other' => q({0} T),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(T),
						'one' => q({0} T),
						'other' => q({0} T),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(Nächte),
						'one' => q({0}Nacht),
						'other' => q({0}Nächte),
						'per' => q({0}/Nacht),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(Nächte),
						'one' => q({0}Nacht),
						'other' => q({0}Nächte),
						'per' => q({0}/Nacht),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Q),
						'one' => q({0} Q),
						'other' => q({0} Q),
						'per' => q({0}/Q),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Q),
						'one' => q({0} Q),
						'other' => q({0} Q),
						'per' => q({0}/Q),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'one' => q({0} kWh/100km),
						'other' => q({0} kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(d),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(d),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}AE),
						'other' => q({0}AE),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}Lj),
						'other' => q({0}Lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}Lj),
						'other' => q({0}Lj),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(Karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(Karat),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(Unzen),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(Unzen),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Pfund),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(Tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(Tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0} Imp.DL),
						'other' => q({0} Imp.DL),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0} Imp.DL),
						'other' => q({0} Imp.DL),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0} fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(Tr.),
						'one' => q({0} Tr.),
						'other' => q({0} Tr.),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(Tr.),
						'one' => q({0} Tr.),
						'other' => q({0} Tr.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Im.fl.oz),
						'one' => q({0} Im.fl.oz),
						'other' => q({0} Im.fl.oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Im.fl.oz),
						'one' => q({0} Im.fl.oz),
						'other' => q({0} Im.fl.oz),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp.gal),
						'one' => q({0} Imp.gal),
						'other' => q({0} Imp.gal),
						'per' => q({0}/Imp.gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp.gal),
						'one' => q({0} Imp.gal),
						'other' => q({0} Imp.gal),
						'per' => q({0}/Imp.gal),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(Pr.),
						'one' => q({0} Pr),
						'other' => q({0} Pr),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(Pr.),
						'one' => q({0} Pr),
						'other' => q({0} Pr),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp.qt),
						'one' => q({0} Imp.qt),
						'other' => q({0} Imp.qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp.qt),
						'one' => q({0} Imp.qt),
						'other' => q({0} Imp.qt),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(Richtung),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(Richtung),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-Kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-Kraft),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Winkelminuten),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Winkelminuten),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Winkelsekunden),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Winkelsekunden),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Grad),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Grad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(Umdr.),
						'one' => q({0} Umdr.),
						'other' => q({0} Umdr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(Umdr.),
						'one' => q({0} Umdr.),
						'other' => q({0} Umdr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(Dunams),
						'one' => q({0} Dunam),
						'other' => q({0} Dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(Dunams),
						'one' => q({0} Dunam),
						'other' => q({0} Dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(Hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(Hektar),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(Element),
						'one' => q({0} Element),
						'other' => q({0} Elemente),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(Element),
						'one' => q({0} Element),
						'other' => q({0} Elemente),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(Karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(Karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(Millimol/Liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(Millimol/Liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(Milliardstel),
						'one' => q({0} Milliardstel),
						'other' => q({0} Milliardstel),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(Milliardstel),
						'one' => q({0} Milliardstel),
						'other' => q({0} Milliardstel),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(Meilen/ Imp. Gal.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(Meilen/ Imp. Gal.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} O),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(Bit),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(Bit),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(Byte),
						'one' => q({0} Byte),
						'other' => q({0} Byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(Byte),
						'one' => q({0} Byte),
						'other' => q({0} Byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gigabit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gigabit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Gigabyte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Gigabyte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kbyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kbyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mbyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mbyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(Jh.),
						'one' => q({0} Jh.),
						'other' => q({0} Jh.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(Jh.),
						'one' => q({0} Jh.),
						'other' => q({0} Jh.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Tg.),
						'one' => q({0} Tg.),
						'other' => q({0} Tg.),
						'per' => q({0}/T),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Tg.),
						'one' => q({0} Tg.),
						'other' => q({0} Tg.),
						'per' => q({0}/T),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Jz.),
						'one' => q({0} Jz.),
						'other' => q({0} Jz.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Jz.),
						'one' => q({0} Jz.),
						'other' => q({0} Jz.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Std.),
						'one' => q({0} Std.),
						'other' => q({0} Std.),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Std.),
						'one' => q({0} Std.),
						'other' => q({0} Std.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} Min.),
						'other' => q({0} Min.),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} Min.),
						'other' => q({0} Min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mon.),
						'one' => q({0} Mon.),
						'other' => q({0} Mon.),
						'per' => q({0}/M),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mon.),
						'one' => q({0} Mon.),
						'other' => q({0} Mon.),
						'per' => q({0}/M),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(Nächte),
						'one' => q({0} Nacht),
						'other' => q({0} Nächte),
						'per' => q({0}/Nacht),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(Nächte),
						'one' => q({0} Nacht),
						'other' => q({0} Nächte),
						'per' => q({0}/Nacht),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(Quart.),
						'one' => q({0} Quart.),
						'other' => q({0} Quart.),
						'per' => q({0}/Quart.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(Quart.),
						'one' => q({0} Quart.),
						'other' => q({0} Quart.),
						'per' => q({0}/Quart.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sek.),
						'one' => q({0} Sek.),
						'other' => q({0} Sek.),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sek.),
						'one' => q({0} Sek.),
						'other' => q({0} Sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wo.),
						'one' => q({0} Wo.),
						'other' => q({0} Wo.),
						'per' => q({0}/W),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wo.),
						'one' => q({0} Wo.),
						'other' => q({0} Wo.),
						'per' => q({0}/W),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'per' => q({0}/J),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
						'per' => q({0}/J),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(Ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(Ampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(Volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(Volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(Joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(Joule),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(Kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(Kilojoule),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(Dots),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(Dots),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AE),
						'one' => q({0} AE),
						'other' => q({0} AE),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(Faden),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(Faden),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Fuß),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Fuß),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(Furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(Furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(Lj),
						'one' => q({0} Lj),
						'other' => q({0} Lj),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Lj),
						'one' => q({0} Lj),
						'other' => q({0} Lj),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(Meilen),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(Meilen),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(Yards),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(Yards),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(Lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(Lux),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(Gran),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(Gran),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gramm),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz.tr.),
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz.tr.),
						'one' => q({0} oz.tr.),
						'other' => q({0} oz.tr.),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(Stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(Stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn. sh.),
						'one' => q({0} tn. sh.),
						'other' => q({0} tn. sh.),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn. sh.),
						'one' => q({0} tn. sh.),
						'other' => q({0} tn. sh.),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Watt),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(Millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(Millibar),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(Acre-Feet),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(Acre-Feet),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(Bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(Bushel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(Cups),
						'one' => q({0} Cup),
						'other' => q({0} Cups),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(Cups),
						'one' => q({0} Cup),
						'other' => q({0} Cups),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(Ta),
						'one' => q({0} Ta),
						'other' => q({0} Ta),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(Ta),
						'one' => q({0} Ta),
						'other' => q({0} Ta),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(DL),
						'one' => q({0} DL),
						'other' => q({0} DL),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(DL),
						'one' => q({0} DL),
						'other' => q({0} DL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. DL),
						'one' => q({0} Imp. DL),
						'other' => q({0} Imp. DL),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. DL),
						'one' => q({0} Imp. DL),
						'other' => q({0} Imp. DL),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(Flüssigdram),
						'one' => q({0} Fl.-Dram),
						'other' => q({0} Fl.-Dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(Flüssigdram),
						'one' => q({0} Fl.-Dram),
						'other' => q({0} Fl.-Dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(Trpf.),
						'one' => q({0} Trpf.),
						'other' => q({0} Trpf.),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(Trpf.),
						'one' => q({0} Trpf.),
						'other' => q({0} Trpf.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp.fl.oz.),
						'one' => q({0} Imp.fl.oz.),
						'other' => q({0} Imp.fl.oz.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp.fl.oz.),
						'one' => q({0} Imp.fl.oz.),
						'other' => q({0} Imp.fl.oz.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'one' => q({0} Imp. gal),
						'other' => q({0} Imp. gal),
						'per' => q({0} pro Imp. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0} Imp. gal),
						'other' => q({0} Imp. gal),
						'per' => q({0} pro Imp. gal),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(Jigger),
						'one' => q({0} Jigger),
						'other' => q({0} Jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(Jigger),
						'one' => q({0} Jigger),
						'other' => q({0} Jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(Prise),
						'one' => q({0} Pr.),
						'other' => q({0} Pr.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(Prise),
						'one' => q({0} Pr.),
						'other' => q({0} Pr.),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp.qt.),
						'one' => q({0} Imp.qt.),
						'other' => q({0} Imp.qt.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp.qt.),
						'one' => q({0} Imp.qt.),
						'other' => q({0} Imp.qt.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(EL),
						'one' => q({0} EL),
						'other' => q({0} EL),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(EL),
						'one' => q({0} EL),
						'other' => q({0} EL),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(TL),
						'one' => q({0} TL),
						'other' => q({0} TL),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(TL),
						'one' => q({0} TL),
						'other' => q({0} TL),
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
				end => q({0} und {1}),
				2 => q({0} und {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'superscriptingExponent' => q(·),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
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
			display_name => {
				'currency' => q(Andorranische Pesete),
				'one' => q(Andorranische Pesete),
				'other' => q(Andorranische Peseten),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(VAE-Dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghanische Afghani \(1927–2002\)),
			},
		},
		'AFN' => {
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
			display_name => {
				'currency' => q(Albanischer Lek),
				'one' => q(Albanischer Lek),
				'other' => q(Albanische Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenischer Dram),
				'one' => q(Armenischer Dram),
				'other' => q(Armenische Dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Niederländische-Antillen-Gulden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolanischer Kwanza),
				'one' => q(Angolanischer Kwanza),
				'other' => q(Angolanische Kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolanischer Kwanza \(1977–1990\)),
				'one' => q(Angolanischer Kwanza \(1977–1990\)),
				'other' => q(Angolanische Kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolanischer Neuer Kwanza \(1990–2000\)),
				'one' => q(Angolanischer Neuer Kwanza \(1990–2000\)),
				'other' => q(Angolanische Neue Kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolanischer Kwanza Reajustado \(1995–1999\)),
				'one' => q(Angolanischer Kwanza Reajustado \(1995–1999\)),
				'other' => q(Angolanische Kwanza Reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentinischer Austral),
				'one' => q(Argentinischer Austral),
				'other' => q(Argentinische Austral),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentinischer Peso Ley \(1970–1983\)),
				'one' => q(Argentinischer Peso Ley \(1970–1983\)),
				'other' => q(Argentinische Pesos Ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentinischer Peso \(1881–1970\)),
				'one' => q(Argentinischer Peso \(1881–1970\)),
				'other' => q(Argentinische Pesos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinischer Peso \(1983–1985\)),
				'one' => q(Argentinischer Peso \(1983–1985\)),
				'other' => q(Argentinische Peso \(1983–1985\)),
			},
		},
		'ARS' => {
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
			display_name => {
				'currency' => q(Aruba-Florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Aserbaidschan-Manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbaidschan-Manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnien und Herzegowina Dinar \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Konvertible Mark Bosnien und Herzegowina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosnien und Herzegowina Neuer Dinar \(1994–1997\)),
				'one' => q(Bosnien und Herzegowina Neuer Dinar \(1994–1997\)),
				'other' => q(Bosnien und Herzegowina Neue Dinar \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados-Dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladesch-Taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgischer Franc \(konvertibel\)),
				'one' => q(Belgischer Franc \(konvertibel\)),
				'other' => q(Belgische Franc \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgischer Franc),
				'one' => q(Belgischer Franc),
				'other' => q(Belgische Franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgischer Finanz-Franc),
				'one' => q(Belgischer Finanz-Franc),
				'other' => q(Belgische Finanz-Franc),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgarische Lew \(1962–1999\)),
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
			display_name => {
				'currency' => q(Bahrain-Dinar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi-Franc),
				'one' => q(Burundi-Franc),
				'other' => q(Burundi-Francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-Dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei-Dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivianischer Boliviano),
				'one' => q(Bolivianischer Boliviano),
				'other' => q(Bolivianische Bolivianos),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolivianischer Boliviano \(1863–1963\)),
				'one' => q(Bolivianischer Boliviano \(1863–1963\)),
				'other' => q(Bolivianische Bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivianischer Peso),
				'one' => q(Bolivianischer Peso),
				'other' => q(Bolivianische Peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviansiche Mvdol),
				'one' => q(Boliviansiche Mvdol),
				'other' => q(Bolivianische Mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro Novo \(1967–1986\)),
				'one' => q(Brasilianischer Cruzeiro Novo \(1967–1986\)),
				'other' => q(Brasilianische Cruzeiro Novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzado \(1986–1989\)),
				'one' => q(Brasilianischer Cruzado \(1986–1989\)),
				'other' => q(Brasilianische Cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1990–1993\)),
				'one' => q(Brasilianischer Cruzeiro \(1990–1993\)),
				'other' => q(Brasilianische Cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brasilianischer Real),
				'one' => q(Brasilianischer Real),
				'other' => q(Brasilianische Real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzado Novo \(1989–1990\)),
				'one' => q(Brasilianischer Cruzado Novo \(1989–1990\)),
				'other' => q(Brasilianische Cruzado Novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1993–1994\)),
				'one' => q(Brasilianischer Cruzeiro \(1993–1994\)),
				'other' => q(Brasilianische Cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brasilianischer Cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamas-Dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutan-Ngultrum),
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
			display_name => {
				'currency' => q(Botswanischer Pula),
				'one' => q(Botswanischer Pula),
				'other' => q(Botswanische Pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarus-Rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Weißrussischer Rubel),
				'one' => q(Weißrussischer Rubel),
				'other' => q(Weißrussische Rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Weißrussischer Rubel \(2000–2016\)),
				'one' => q(Weißrussischer Rubel \(2000–2016\)),
				'other' => q(Weißrussische Rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize-Dollar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Kanadischer Dollar),
				'one' => q(Kanadischer Dollar),
				'other' => q(Kanadische Dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo-Franc),
				'one' => q(Kongo-Franc),
				'other' => q(Kongo-Francs),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR-Euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Schweizer Franken),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Franken),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Chilenischer Escudo),
				'one' => q(Chilenischer Escudo),
				'other' => q(Chilenische Escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chilenische Unidades de Fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chilenischer Peso),
				'one' => q(Chilenischer Peso),
				'other' => q(Chilenische Pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Renminbi-Yuan \(Offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dollar der Chinesischen Volksbank),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Renminbi Yuan),
				'one' => q(Chinesischer Yuan),
				'other' => q(Renminbi Yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbianischer Peso),
				'one' => q(Kolumbianischer Peso),
				'other' => q(Kolumbianische Pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Kolumbianische Unidades de valor real),
				'one' => q(Kolumbianische Unidad de valor real),
				'other' => q(Kolumbianische Unidades de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa-Rica-Colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbischer Dinar \(2002–2006\)),
				'one' => q(Serbischer Dinar \(2002–2006\)),
				'other' => q(Serbische Dinar \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tschechoslowakische Krone),
				'one' => q(Tschechoslowakische Kronen),
				'other' => q(Tschechoslowakische Kronen),
			},
		},
		'CUC' => {
			symbol => 'Cub$',
			display_name => {
				'currency' => q(Kubanischer Peso \(konvertibel\)),
				'one' => q(Kubanischer Peso \(konvertibel\)),
				'other' => q(Kubanische Pesos \(konvertibel\)),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubanischer Peso),
				'one' => q(Kubanischer Peso),
				'other' => q(Kubanische Pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cabo-Verde-Escudo),
				'one' => q(Cabo-Verde-Escudo),
				'other' => q(Cabo-Verde-Escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Zypern-Pfund),
				'one' => q(Zypern Pfund),
				'other' => q(Zypern Pfund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tschechische Krone),
				'one' => q(Tschechische Krone),
				'other' => q(Tschechische Kronen),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Mark der DDR),
			},
		},
		'DEM' => {
			symbol => 'DM',
			display_name => {
				'currency' => q(Deutsche Mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Dschibuti-Franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Dänische Krone),
				'one' => q(Dänische Krone),
				'other' => q(Dänische Kronen),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikanischer Peso),
				'one' => q(Dominikanischer Peso),
				'other' => q(Dominikanische Pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerischer Dinar),
				'one' => q(Algerischer Dinar),
				'other' => q(Algerische Dinar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadorianischer Sucre),
				'one' => q(Ecuadorianischer Sucre),
				'other' => q(Ecuadorianische Sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Verrechnungseinheit für Ecuador),
				'one' => q(Verrechnungseinheiten für Ecuador),
				'other' => q(Verrechnungseinheiten für Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estnische Krone),
				'one' => q(Estnische Krone),
				'other' => q(Estnische Kronen),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ägyptisches Pfund),
				'one' => q(Ägyptisches Pfund),
				'other' => q(Ägyptische Pfund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritreischer Nakfa),
				'one' => q(Eritreischer Nakfa),
				'other' => q(Eritreische Nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spanische Peseta \(A–Konten\)),
				'one' => q(Spanische Peseta \(A–Konten\)),
				'other' => q(Spanische Peseten \(A–Konten\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spanische Peseta \(konvertibel\)),
				'one' => q(Spanische Peseta \(konvertibel\)),
				'other' => q(Spanische Peseten \(konvertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spanische Peseta),
				'one' => q(Spanische Peseta),
				'other' => q(Spanische Peseten),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Äthiopischer Birr),
				'one' => q(Äthiopischer Birr),
				'other' => q(Äthiopische Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnische Mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi-Dollar),
			},
		},
		'FKP' => {
			symbol => 'Fl£',
			display_name => {
				'currency' => q(Falkland-Pfund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Französischer Franc),
				'one' => q(Französischer Franc),
				'other' => q(Französische Franc),
			},
		},
		'GBP' => {
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
			display_name => {
				'currency' => q(Georgischer Lari),
				'one' => q(Georgischer Lari),
				'other' => q(Georgische Lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanaischer Cedi \(1979–2007\)),
				'one' => q(Ghanaischer Cedi \(1979–2007\)),
				'other' => q(Ghanaische Cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => '₵',
			display_name => {
				'currency' => q(Ghanaischer Cedi),
				'one' => q(Ghanaischer Cedi),
				'other' => q(Ghanaische Cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar-Pfund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia-Dalasi),
			},
		},
		'GNF' => {
			symbol => 'F.G.',
			display_name => {
				'currency' => q(Guinea-Franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guineischer Syli),
				'one' => q(Guineischer Syli),
				'other' => q(Guineische Syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Äquatorialguinea-Ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Griechische Drachme),
				'one' => q(Griechische Drachme),
				'other' => q(Griechische Drachmen),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemaltekischer Quetzal),
				'one' => q(Guatemaltekischer Quetzal),
				'other' => q(Guatemaltekische Quetzales),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugiesisch Guinea Escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau Peso),
				'one' => q(Guinea-Bissau Peso),
				'other' => q(Guinea-Bissau Pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana-Dollar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-Dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduras-Lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroatischer Dinar),
				'one' => q(Kroatischer Dinar),
				'other' => q(Kroatische Dinar),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatischer Kuna),
				'one' => q(Kroatischer Kuna),
				'other' => q(Kroatische Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitianische Gourde),
				'one' => q(Haitianische Gourde),
				'other' => q(Haitianische Gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungarischer Forint),
				'one' => q(Ungarischer Forint),
				'other' => q(Ungarische Forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesische Rupiah),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irisches Pfund),
				'one' => q(Irisches Pfund),
				'other' => q(Irische Pfund),
			},
		},
		'ILP' => {
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
			display_name => {
				'currency' => q(Israelischer Neuer Schekel),
				'one' => q(Israelischer Neuer Schekel),
				'other' => q(Israelische Neue Schekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indische Rupie),
				'one' => q(Indische Rupie),
				'other' => q(Indische Rupien),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irakischer Dinar),
				'one' => q(Irakischer Dinar),
				'other' => q(Irakische Dinar),
			},
		},
		'IRR' => {
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
			display_name => {
				'currency' => q(Isländische Krone),
				'one' => q(Isländische Krone),
				'other' => q(Isländische Kronen),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italienische Lira),
				'one' => q(Italienische Lira),
				'other' => q(Italienische Lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika-Dollar),
			},
		},
		'JOD' => {
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
			display_name => {
				'currency' => q(Kenia-Schilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisischer Som),
				'one' => q(Kirgisischer Som),
				'other' => q(Kirgisische Som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Kambodschanischer Riel),
				'one' => q(Kambodschanischer Riel),
				'other' => q(Kambodschanische Riel),
			},
		},
		'KMF' => {
			symbol => 'FC',
			display_name => {
				'currency' => q(Komoren-Franc),
				'one' => q(Komoren-Franc),
				'other' => q(Komoren-Francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Nordkoreanischer Won),
				'one' => q(Nordkoreanischer Won),
				'other' => q(Nordkoreanische Won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Südkoreanischer Hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Südkoreanischer Won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Südkoreanischer Won),
				'one' => q(Südkoreanischer Won),
				'other' => q(Südkoreanische Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwait-Dinar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaiman-Dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasachischer Tenge),
				'one' => q(Kasachischer Tenge),
				'other' => q(Kasachische Tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotischer Kip),
				'one' => q(Laotischer Kip),
				'other' => q(Laotische Kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanesisches Pfund),
				'one' => q(Libanesisches Pfund),
				'other' => q(Libanesische Pfund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri-Lanka-Rupie),
				'one' => q(Sri-Lanka-Rupie),
				'other' => q(Sri-Lanka-Rupien),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberianischer Dollar),
				'one' => q(Liberianischer Dollar),
				'other' => q(Liberianische Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litauischer Litas),
				'one' => q(Litauischer Litas),
				'other' => q(Litauische Litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litauischer Talonas),
				'one' => q(Litauische Talonas),
				'other' => q(Litauische Talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxemburgischer Franc \(konvertibel\)),
				'one' => q(Luxemburgische Franc \(konvertibel\)),
				'other' => q(Luxemburgische Franc \(konvertibel\)),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburgischer Franc),
				'one' => q(Luxemburgische Franc),
				'other' => q(Luxemburgische Franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxemburgischer Finanz-Franc),
				'one' => q(Luxemburgische Finanz-Franc),
				'other' => q(Luxemburgische Finanz-Franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettischer Lats),
				'one' => q(Lettischer Lats),
				'other' => q(Lettische Lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lettischer Rubel),
				'one' => q(Lettische Rubel),
				'other' => q(Lettische Rubel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyscher Dinar),
				'one' => q(Libyscher Dinar),
				'other' => q(Libysche Dinar),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkanischer Dirham),
				'one' => q(Marokkanischer Dirham),
				'other' => q(Marokkanische Dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkanischer Franc),
				'one' => q(Marokkanische Franc),
				'other' => q(Marokkanische Franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegassischer Franc),
				'one' => q(Monegassischer Franc),
				'other' => q(Monegassische Franc),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldau-Cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldau-Leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskar-Ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskar-Franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Mazedonischer Denar),
				'one' => q(Mazedonischer Denar),
				'other' => q(Mazedonische Denari),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Mazedonischer Denar \(1992–1993\)),
				'one' => q(Mazedonischer Denar \(1992–1993\)),
				'other' => q(Mazedonische Denar \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malischer Franc),
				'one' => q(Malische Franc),
				'other' => q(Malische Franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmarischer Kyat),
				'one' => q(Myanmarischer Kyat),
				'other' => q(Myanmarische Kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolischer Tögrög),
				'one' => q(Mongolischer Tögrög),
				'other' => q(Mongolische Tögrög),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macao-Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauretanischer Ouguiya \(1973–2017\)),
				'one' => q(Mauretanischer Ouguiya \(1973–2017\)),
				'other' => q(Mauretanische Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauretanischer Ouguiya),
				'one' => q(Mauretanischer Ouguiya),
				'other' => q(Mauretanische Ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltesische Lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltesisches Pfund),
				'one' => q(Maltesische Pfund),
				'other' => q(Maltesische Pfund),
			},
		},
		'MUR' => {
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
			display_name => {
				'currency' => q(Malediven-Rufiyaa),
				'one' => q(Malediven-Rufiyaa),
				'other' => q(Malediven-Rupien),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi-Kwacha),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexikanischer Peso),
				'one' => q(Mexikanischer Peso),
				'other' => q(Mexikanische Pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexikanischer Silber-Peso \(1861–1992\)),
				'one' => q(Mexikanische Silber-Peso \(1861–1992\)),
				'other' => q(Mexikanische Silber-Pesos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexicanischer Unidad de Inversion \(UDI\)),
				'one' => q(Mexicanischer Unidad de Inversion \(UDI\)),
				'other' => q(Mexikanische Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
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
			display_name => {
				'currency' => q(Mosambikanischer Metical \(1980–2006\)),
				'one' => q(Mosambikanischer Metical \(1980–2006\)),
				'other' => q(Mosambikanische Meticais \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambikanischer Metical),
				'one' => q(Mosambikanischer Metical),
				'other' => q(Mosambikanische Meticais),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia-Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerianischer Naira),
				'one' => q(Nigerianischer Naira),
				'other' => q(Nigerianische Naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguanischer Córdoba \(1988–1991\)),
				'one' => q(Nicaraguanischer Córdoba \(1988–1991\)),
				'other' => q(Nicaraguanische Córdoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaragua-Córdoba),
				'one' => q(Nicaragua-Córdoba),
				'other' => q(Nicaragua-Córdobas),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Niederländischer Gulden),
				'one' => q(Niederländischer Gulden),
				'other' => q(Niederländische Gulden),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegische Krone),
				'one' => q(Norwegische Krone),
				'other' => q(Norwegische Kronen),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalesische Rupie),
				'one' => q(Nepalesische Rupie),
				'other' => q(Nepalesische Rupien),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Neuseeland-Dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omanischer Rial),
				'one' => q(Omanischer Rial),
				'other' => q(Omanische Rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamaischer Balboa),
				'one' => q(Panamaischer Balboa),
				'other' => q(Panamaische Balboas),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruanischer Inti),
				'one' => q(Peruanische Inti),
				'other' => q(Peruanische Inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruanischer Sol),
				'one' => q(Peruanischer Sol),
				'other' => q(Peruanische Sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruanischer Sol \(1863–1965\)),
				'one' => q(Peruanischer Sol \(1863–1965\)),
				'other' => q(Peruanische Sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua-neuguineischer Kina),
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
			display_name => {
				'currency' => q(Pakistanische Rupie),
				'one' => q(Pakistanische Rupie),
				'other' => q(Pakistanische Rupien),
			},
		},
		'PLN' => {
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
			display_name => {
				'currency' => q(Portugiesischer Escudo),
				'one' => q(Portugiesische Escudo),
				'other' => q(Portugiesische Escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayischer Guaraní),
				'one' => q(Paraguayischer Guaraní),
				'other' => q(Paraguayische Guaraníes),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar-Riyal),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesischer Dollar),
				'one' => q(Rhodesische Dollar),
				'other' => q(Rhodesische Dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumänischer Leu \(1952–2006\)),
				'one' => q(Rumänischer Leu \(1952–2006\)),
				'other' => q(Rumänische Leu \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(Rumänischer Leu),
				'one' => q(Rumänischer Leu),
				'other' => q(Rumänische Leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbischer Dinar),
				'one' => q(Serbischer Dinar),
				'other' => q(Serbische Dinaren),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russischer Rubel),
				'one' => q(Russischer Rubel),
				'other' => q(Russische Rubel),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Russischer Rubel \(1991–1998\)),
				'one' => q(Russischer Rubel \(1991–1998\)),
				'other' => q(Russische Rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'F.Rw',
			display_name => {
				'currency' => q(Ruanda-Franc),
				'one' => q(Ruanda-Franc),
				'other' => q(Ruanda-Francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi-Rial),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomonen-Dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellen-Rupie),
				'one' => q(Seychellen-Rupie),
				'other' => q(Seychellen-Rupien),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudanesischer Dinar \(1992–2007\)),
				'one' => q(Sudanesischer Dinar \(1992–2007\)),
				'other' => q(Sudanesische Dinar \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanesisches Pfund),
				'one' => q(Sudanesisches Pfund),
				'other' => q(Sudanesische Pfund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanesisches Pfund \(1957–1998\)),
				'one' => q(Sudanesisches Pfund \(1957–1998\)),
				'other' => q(Sudanesische Pfund \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Schwedische Krone),
				'one' => q(Schwedische Krone),
				'other' => q(Schwedische Kronen),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapur-Dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St.-Helena-Pfund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slowenischer Tolar),
				'one' => q(Slowenischer Tolar),
				'other' => q(Slowenische Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowakische Krone),
				'one' => q(Slowakische Kronen),
				'other' => q(Slowakische Kronen),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Sierra-leonischer Leone),
				'one' => q(Sierra-leonischer Leone),
				'other' => q(Sierra-leonische Leones),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra-leonischer Leone \(1964–2022\)),
				'one' => q(Sierra-leonischer Leone \(1964–2022\)),
				'other' => q(Sierra-leonische Leones \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalia-Schilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Suriname-Dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Suriname Gulden),
				'one' => q(Suriname-Gulden),
				'other' => q(Suriname-Gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Südsudanesisches Pfund),
				'one' => q(Südsudanesisches Pfund),
				'other' => q(Südsudanesische Pfund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São-toméischer Dobra \(1977–2017\)),
				'one' => q(São-toméischer Dobra \(1977–2017\)),
				'other' => q(São-toméische Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São-toméischer Dobra),
				'one' => q(São-toméischer Dobra),
				'other' => q(São-toméische Dobras),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sowjetischer Rubel),
				'one' => q(Sowjetische Rubel),
				'other' => q(Sowjetische Rubel),
			},
		},
		'SVC' => {
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
			display_name => {
				'currency' => q(Tadschikistan Rubel),
				'one' => q(Tadschikistan-Rubel),
				'other' => q(Tadschikistan-Rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadschikistan-Somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistan-Manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistan-Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunesischer Dinar),
				'one' => q(Tunesischer Dinar),
				'other' => q(Tunesische Dinar),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaischer Paʻanga),
				'one' => q(Tongaischer Paʻanga),
				'other' => q(Tongaische Paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor-Escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Türkische Lira \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Türkische Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad-und-Tobago-Dollar),
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
			display_name => {
				'currency' => q(Tansania-Schilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainische Hrywnja),
				'one' => q(Ukrainische Hrywnja),
				'other' => q(Ukrainische Hrywen),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainischer Karbovanetz),
				'one' => q(Ukrainische Karbovanetz),
				'other' => q(Ukrainische Karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uganda-Schilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda-Schilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US Dollar \(Nächster Tag\)),
				'one' => q(US-Dollar \(Nächster Tag\)),
				'other' => q(US-Dollar \(Nächster Tag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US Dollar \(Gleicher Tag\)),
				'one' => q(US-Dollar \(Gleicher Tag\)),
				'other' => q(US-Dollar \(Gleicher Tag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayischer Peso \(Indexierte Rechnungseinheiten\)),
				'one' => q(Uruguayischer Peso \(Indexierte Rechnungseinheiten\)),
				'other' => q(Uruguayische Pesos \(Indexierte Rechnungseinheiten\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayischer Peso \(1975–1993\)),
				'one' => q(Uruguayischer Peso \(1975–1993\)),
				'other' => q(Uruguayische Pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayischer Peso),
				'one' => q(Uruguayischer Peso),
				'other' => q(Uruguayische Pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbekistan-Sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezolanischer Bolívar \(1871–2008\)),
				'one' => q(Venezolanischer Bolívar \(1871–2008\)),
				'other' => q(Venezolanische Bolívares \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezolanischer Bolívar \(2008–2018\)),
				'one' => q(Venezolanischer Bolívar \(2008–2018\)),
				'other' => q(Venezolanische Bolívares \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Venezolanischer Bolívar),
				'one' => q(Venezolanischer Bolívar),
				'other' => q(Venezolanische Bolívares),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamesischer Dong),
				'one' => q(Vietnamesischer Dong),
				'other' => q(Vietnamesische Dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnamesischer Dong\(1978–1985\)),
				'one' => q(Vietnamesischer Dong\(1978–1985\)),
				'other' => q(Vietnamesische Dong\(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu-Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoanischer Tala),
				'one' => q(Samoanischer Tala),
				'other' => q(Samoanische Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-Franc \(BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Unze Silber),
				'one' => q(Unze Silber),
				'other' => q(Unzen Silber),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Unze Gold),
				'one' => q(Unze Gold),
				'other' => q(Unzen Gold),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europäische Rechnungseinheit),
				'one' => q(Europäische Rechnungseinheiten),
				'other' => q(Europäische Rechnungseinheiten),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europäische Währungseinheit \(XBB\)),
				'one' => q(Europäische Währungseinheiten \(XBB\)),
				'other' => q(Europäische Währungseinheiten \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europäische Rechnungseinheit \(XBC\)),
				'one' => q(Europäische Rechnungseinheiten \(XBC\)),
				'other' => q(Europäische Rechnungseinheiten \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europäische Rechnungseinheit \(XBD\)),
				'one' => q(Europäische Rechnungseinheiten \(XBD\)),
				'other' => q(Europäische Rechnungseinheiten \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Ostkaribischer Dollar),
				'one' => q(Ostkaribischer Dollar),
				'other' => q(Ostkaribische Dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Sonderziehungsrechte),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Europäische Währungseinheit \(XEU\)),
				'one' => q(Europäische Währungseinheiten \(XEU\)),
				'other' => q(Europäische Währungseinheiten \(XEU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Französischer Gold-Franc),
				'one' => q(Französische Gold-Franc),
				'other' => q(Französische Gold-Franc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Französischer UIC-Franc),
				'one' => q(Französische UIC-Franc),
				'other' => q(Französische UIC-Franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-Franc \(BCEAO\)),
				'one' => q(CFA-Franc \(BCEAO\)),
				'other' => q(CFA-Francs \(BCEAO\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Unze Palladium),
				'one' => q(Unze Palladium),
				'other' => q(Unzen Palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-Franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Unze Platin),
				'one' => q(Unze Platin),
				'other' => q(Unzen Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET Funds),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(SUCRE),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Testwährung),
			},
		},
		'XUA' => {
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
			display_name => {
				'currency' => q(Jemen-Dinar),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemen-Rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslawischer Dinar \(1966–1990\)),
				'one' => q(Jugoslawischer Dinar \(1966–1990\)),
				'other' => q(Jugoslawische Dinar \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslawischer Neuer Dinar \(1994–2002\)),
				'one' => q(Jugoslawischer Neuer Dinar \(1994–2002\)),
				'other' => q(Jugoslawische Neue Dinar \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslawischer Dinar \(konvertibel\)),
				'one' => q(Jugoslawische Dinar \(konvertibel\)),
				'other' => q(Jugoslawische Dinar \(konvertibel\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Jugoslawischer reformierter Dinar \(1992–1993\)),
				'one' => q(Jugoslawischer reformierter Dinar \(1992–1993\)),
				'other' => q(Jugoslawische reformierte Dinar \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Südafrikanischer Rand \(Finanz\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Südafrikanischer Rand),
				'one' => q(Südafrikanischer Rand),
				'other' => q(Südafrikanische Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'K',
			display_name => {
				'currency' => q(Kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire-Neuer Zaïre \(1993–1998\)),
				'one' => q(Zaire-Neuer Zaïre \(1993–1998\)),
				'other' => q(Zaire-Neue Zaïre \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire-Zaïre \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					wide => {
						nonleap => [
							'Erster',
							'Zweiter',
							'Dritter',
							'Vierter',
							'Fünfter',
							'Sechster',
							'Siebter',
							'Achter',
							'Neunter',
							'Zehnter',
							'Elfter',
							'Zwölfter'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'Erster',
							'Zweiter',
							'Dritter',
							'Vierter',
							'Fünfter',
							'Sechster',
							'Siebter',
							'Achter',
							'Neunter',
							'Zehnter',
							'Elfter',
							'Zwölfter'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
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
				},
			},
			'hebrew' => {
				'format' => {
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
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
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
					'afternoon2' => q{nachm.},
					'evening1' => q{abends},
					'midnight' => q{Mitternacht},
					'morning1' => q{morgens},
					'morning2' => q{vorm.},
					'night1' => q{nachts},
				},
				'wide' => {
					'afternoon1' => q{mittags},
					'afternoon2' => q{nachmittags},
					'evening1' => q{abends},
					'midnight' => q{Mitternacht},
					'morning1' => q{morgens},
					'morning2' => q{vormittags},
					'night1' => q{nachts},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Nachm.},
					'evening1' => q{Abend},
					'morning1' => q{Morgen},
					'morning2' => q{Vorm.},
					'night1' => q{Nacht},
				},
				'wide' => {
					'afternoon1' => q{Mittag},
					'afternoon2' => q{Nachmittag},
					'evening1' => q{Abend},
					'morning1' => q{Morgen},
					'morning2' => q{Vormittag},
					'night1' => q{Nacht},
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
			wide => {
				'0' => 'B.E.'
			},
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
			abbreviated => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'v. VR China'
			},
			wide => {
				'0' => 'vor Volksrepublik China'
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
			'full' => q{{1}, {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
			GyMMMMEd => q{E, d. MMMM U},
			GyMMMMd => q{d. MMMM U},
			GyMMMd => q{d. MMM U},
			H => q{HH 'Uhr'},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{U},
			yyyy => q{U},
			yyyyM => q{M.y},
			yyyyMEd => q{E, d.M.y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E, d. MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMMEd => q{E, d. MMMM U},
			yyyyMMMMd => q{d. MMMM U},
			yyyyMMMd => q{d. MMM U},
			yyyyMd => q{d.M.y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'generic' => {
			Bh => q{h 'Uhr' B},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{HH 'Uhr'},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h 'Uhr' B},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
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
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{dd.MM.y G},
			H => q{HH 'Uhr'},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMEd => q{E, d. MMMM},
			MMMMW => q{'Woche' W 'im' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMd => q{d.MM.},
			MMdd => q{dd.MM.},
			Md => q{d.M.},
			h => q{h 'Uhr' a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
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
			Hv => {
				H => q{HH–HH 'Uhr' v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h 'Uhr' B – h 'Uhr' B},
				h => q{h–h 'Uhr' B},
			},
			Bhm => {
				B => q{h:mm 'Uhr' B – h:mm 'Uhr' B},
				h => q{h:mm – h:mm 'Uhr' B},
				m => q{h:mm – h:mm 'Uhr' B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E, dd.MM.y G – E, dd.MM.y G},
				M => q{E, dd.MM. – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y G – dd.MM.y G},
				M => q{dd.MM. – dd.MM.y G},
				d => q{dd.–dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
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
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			h => {
				a => q{h 'Uhr' a – h 'Uhr' a},
				h => q{h – h 'Uhr' a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, dd.MM. – E, dd.MM.y},
				d => q{E, dd. – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM. – dd.MM.y},
				d => q{dd.–dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(Mäusezeit),
						1 => q(Büffelzeit),
						2 => q(Tigerzeit),
						3 => q(Katzenzeit),
						4 => q(Drachenzeit),
						5 => q(Schlangenzeit),
						6 => q(Pferdezeit),
						7 => q(Ziegenzeit),
						8 => q(Affenzeit),
						9 => q(Hühnerzeit),
						10 => q(Hundezeit),
						11 => q(Schweinezeit),
					},
					'narrow' => {
						0 => q(🐭),
						1 => q(🐮),
						2 => q(🐯),
						3 => q(🐱),
						4 => q(🐲),
						5 => q(🐍),
						6 => q(🐴),
						7 => q(🐏),
						8 => q(🐵),
						9 => q(🐔),
						10 => q(🐶),
						11 => q(🐷),
					},
					'wide' => {
						1 => q(Büffelstunden),
						2 => q(Tigerstunden),
						3 => q(Katzenstunden),
						4 => q(Drachenstunden),
						5 => q(Schlangenstunden),
						6 => q(Pferdestunden),
						7 => q(Ziegenstunden),
						8 => q(Affenstunden),
						9 => q(Hühnerstunden),
						10 => q(Hundestunden),
						11 => q(Schweinestunden),
					},
				},
			},
			'days' => {
				'format' => {
					'abbreviated' => {
						0 => q(Holzratte),
						1 => q(Holzbüffel),
						2 => q(Feuertiger),
						3 => q(Feuerhase),
						4 => q(Erddrache),
						5 => q(Erdschlange),
						6 => q(Metallpferd),
						7 => q(Metallziege),
						8 => q(Wasseraffe),
						9 => q(Wasserhuhn),
						10 => q(Holzhund),
						11 => q(Holzschwein),
						12 => q(Feuerratte),
						13 => q(Feuerbüffel),
						14 => q(Erdtiger),
						15 => q(Erdhase),
						16 => q(Metalldrache),
						17 => q(Metallschlange),
						18 => q(Wasserpferd),
						19 => q(Wasserziege),
						20 => q(Holzaffe),
						21 => q(Holzhuhn),
						22 => q(Feuerhund),
						23 => q(Feuerschwein),
						24 => q(Erdratte),
						25 => q(Erdbüffel),
						26 => q(Metalltiger),
						27 => q(Metallhase),
						28 => q(Wasserdrache),
						29 => q(Wasserschlange),
						30 => q(Holzpferd),
						31 => q(Holzziege),
						32 => q(Feueraffe),
						33 => q(Feuerhuhn),
						34 => q(Erdhund),
						35 => q(Erdschwein),
						36 => q(Metallratte),
						37 => q(Metallbüffel),
						38 => q(Wassertiger),
						39 => q(Wasserhase),
						40 => q(Holzdrache),
						41 => q(Holzschlange),
						42 => q(Feuerpferd),
						43 => q(Feuerziege),
						44 => q(Erdaffe),
						45 => q(Erdhuhn),
						46 => q(Metallhund),
						47 => q(Metallschwein),
						48 => q(Wasserratte),
						49 => q(Wasserbüffel),
						50 => q(Holztiger),
						51 => q(Holzhase),
						52 => q(Feuerdrache),
						53 => q(Feuerschlange),
						54 => q(Erdpferd),
						55 => q(Erdziege),
						56 => q(Metallaffe),
						57 => q(Metallhuhn),
						58 => q(Wasserhund),
						59 => q(Wasserschwein),
					},
					'narrow' => {
						0 => q(🌲🐭),
						1 => q(🌲🐮),
						2 => q(🔥🐯),
						3 => q(🔥🐱),
						4 => q(🌱🐲),
						5 => q(🌱🐍),
						6 => q(⚡🐴),
						7 => q(⚡🐏),
						8 => q(💧🐵),
						9 => q(💧🐔),
						10 => q(🌲🐶),
						11 => q(🌲🐷),
						12 => q(🔥🐭),
						13 => q(🔥🐮),
						14 => q(🌱🐯),
						15 => q(🌱🐱),
						16 => q(⚡🐲),
						17 => q(⚡🐍),
						18 => q(💧🐴),
						19 => q(💧🐏),
						20 => q(🌲🐵),
						21 => q(🌲🐔),
						22 => q(🔥🐶),
						23 => q(🔥🐷),
						24 => q(🌱🐭),
						25 => q(🌱🐮),
						26 => q(⚡🐯),
						27 => q(⚡🐱),
						28 => q(💧🐲),
						29 => q(💧🐍),
						30 => q(🌲🐴),
						31 => q(🌲🐏),
						32 => q(🔥🐵),
						33 => q(🔥🐔),
						34 => q(🌱🐶),
						35 => q(🌱🐷),
						36 => q(⚡🐭),
						37 => q(⚡🐮),
						38 => q(💧🐯),
						39 => q(💧🐱),
						40 => q(🌲🐲),
						41 => q(🌲🐍),
						42 => q(🔥🐴),
						43 => q(🔥🐏),
						44 => q(🌱🐵),
						45 => q(🌱🐔),
						46 => q(⚡🐶),
						47 => q(⚡🐷),
						48 => q(💧🐭),
						49 => q(💧🐮),
						50 => q(🌲🐯),
						51 => q(🌲🐱),
						52 => q(🔥🐲),
						53 => q(🔥🐍),
						54 => q(🌱🐴),
						55 => q(🌱🐏),
						56 => q(⚡🐵),
						57 => q(⚡🐔),
						58 => q(💧🐶),
						59 => q(💧🐷),
					},
					'wide' => {
						0 => q(Yang-Holzratte),
						1 => q(Yin-Holzbüffel),
						2 => q(Yang-Feuertiger),
						3 => q(Yin-Feuerhase),
						4 => q(Yang-Erddrache),
						5 => q(Yin-Erdschlange),
						6 => q(Yang-Metallpferd),
						7 => q(Yin-Metallziege),
						8 => q(Yang-Wasseraffe),
						9 => q(Yin-Wasserhuhn),
						10 => q(Yang-Holzhund),
						11 => q(Yin-Holzschwein),
						12 => q(Yang-Feuerratte),
						13 => q(Yin-Feuerbüffel),
						14 => q(Yang-Erdtiger),
						15 => q(Yin-Erdhase),
						16 => q(Yang-Metalldrache),
						17 => q(Yin-Metallschlange),
						18 => q(Yang-Wasserpferd),
						19 => q(Yin-Wasserziege),
						20 => q(Yang-Holzaffe),
						21 => q(Yin-Holzhuhn),
						22 => q(Yang-Feuerhund),
						23 => q(Yin-Feuerschwein),
						24 => q(Yang-Erdratte),
						25 => q(Yin-Erdbüffel),
						26 => q(Yang-Metalltiger),
						27 => q(Yin-Metallhase),
						28 => q(Yang-Wasserdrache),
						29 => q(Yin-Wasserschlange),
						30 => q(Yang-Holzpferd),
						31 => q(Yin-Holzziege),
						32 => q(Yang-Feueraffe),
						33 => q(Yin-Feuerhuhn),
						34 => q(Yang-Erdhund),
						35 => q(Yin-Erdschwein),
						36 => q(Yang-Metallratte),
						37 => q(Yin-Metallbüffel),
						38 => q(Yang-Wassertiger),
						39 => q(Yin-Wasserhase),
						40 => q(Yang-Holzdrache),
						41 => q(Yin-Holzschlange),
						42 => q(Yang-Feuerpferd),
						43 => q(Yin-Feuerziege),
						44 => q(Yang-Erdaffe),
						45 => q(Yin-Erdhuhn),
						46 => q(Yang-Metallhund),
						47 => q(Yin-Metallschwein),
						48 => q(Yang-Wasserratte),
						49 => q(Yin-Wasserbüffel),
						50 => q(Yang-Holztiger),
						51 => q(Yin-Holzhase),
						52 => q(Yang-Feuerdrache),
						53 => q(Yin-Feuerschlange),
						54 => q(Yang-Erdpferd),
						55 => q(Yin-Erdziege),
						56 => q(Yang-Metallaffe),
						57 => q(Yin-Metallhuhn),
						58 => q(Yang-Wasserhund),
						59 => q(Yin-Wasserschwein),
					},
				},
			},
			'months' => {
				'format' => {
					'wide' => {
						0 => q(Yang-Holzratte),
						1 => q(Yin-Holzbüffel),
						2 => q(Yang-Feuertiger),
						3 => q(Yin-Feuerhase),
						4 => q(Yang-Erddrache),
						5 => q(Yin-Erdschlange),
						6 => q(Yang-Metallpferd),
						7 => q(Yin-Metallziege),
						8 => q(Yang-Wasseraffe),
						9 => q(Yin-Wasserhuhn),
						10 => q(Yang-Holzhund),
						11 => q(Yin-Holzschwein),
						12 => q(Yang-Feuerratte),
						13 => q(Yin-Feuerbüffel),
						14 => q(Yang-Erdtiger),
						15 => q(Yin-Erdhase),
						16 => q(Yang-Metalldrache),
						17 => q(Yin-Metallschlange),
						18 => q(Yang-Wasserpferd),
						19 => q(Yin-Wasserziege),
						20 => q(Yang-Holzaffe),
						21 => q(Yin-Holzhuhn),
						22 => q(Yang-Feuerhund),
						23 => q(Yin-Feuerschwein),
						24 => q(Yang-Erdratte),
						25 => q(Yin-Erdbüffel),
						26 => q(Yang-Metalltiger),
						27 => q(Yin-Metallhase),
						28 => q(Yang-Wasserdrache),
						29 => q(Yin-Wasserschlange),
						30 => q(Yang-Holzpferd),
						31 => q(Yin-Holzziege),
						32 => q(Yang-Feueraffe),
						33 => q(Yin-Feuerhuhn),
						34 => q(Yang-Erdhund),
						35 => q(Yin-Erdschwein),
						36 => q(Yang-Metallratte),
						37 => q(Yin-Metallbüffel),
						38 => q(Yang-Wassertiger),
						39 => q(Yin-Wasserhase),
						40 => q(Yang-Holzdrache),
						41 => q(Yin-Holzschlange),
						42 => q(Yang-Feuerpferd),
						43 => q(Yin-Feuerziege),
						44 => q(Yang-Erdaffe),
						45 => q(Yin-Erdhuhn),
						46 => q(Yang-Metallhund),
						47 => q(Yin-Metallschwein),
						48 => q(Yang-Wasserratte),
						49 => q(Yin-Wasserbüffel),
						50 => q(Yang-Holztiger),
						51 => q(Yin-Holzhase),
						52 => q(Yang-Feuerdrache),
						53 => q(Yin-Feuerschlange),
						54 => q(Yang-Erdpferd),
						55 => q(Yin-Erdziege),
						56 => q(Yang-Metallaffe),
						57 => q(Yin-Metallhuhn),
						58 => q(Yang-Wasserhund),
						59 => q(Yin-Wasserschwein),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'narrow' => {
						0 => q(🐯♒),
						1 => q(🐯♓),
						2 => q(🐰♓),
						3 => q(🐰♈),
						4 => q(🐲♈),
						5 => q(🐲♉),
						6 => q(🐍♉),
						7 => q(🐍♊),
						8 => q(🐴♊),
						9 => q(🐴♋),
						10 => q(🐏♋),
						11 => q(🐏♌),
						12 => q(🐵♌),
						13 => q(🐵♍),
						14 => q(🐔♍),
						15 => q(🐔♎),
						16 => q(🐶♎),
						17 => q(🐶♏),
						18 => q(🐷♏),
						19 => q(🐷♐),
						20 => q(🐭♐),
						21 => q(🐭♑),
						22 => q(🐮♑),
						23 => q(🐮♒),
					},
					'wide' => {
						0 => q(Neufrühling),
						1 => q(Wässer),
						2 => q(Schlüpfen),
						3 => q(Vollfrühling),
						4 => q(Flügge),
						5 => q(Sprosskorn),
						6 => q(Neusommer),
						7 => q(Halmkorn),
						8 => q(Ährenkorn),
						9 => q(Vollsommer),
						10 => q(Vorhitze),
						11 => q(Haupthitze),
						12 => q(Neuherbst),
						13 => q(Endhitze),
						14 => q(Morgentau),
						15 => q(Vollherbst),
						16 => q(Morgenreif),
						17 => q(Morgenfrost),
						18 => q(Neuwinter),
						19 => q(Vorschnee),
						20 => q(Hauptschnee),
						21 => q(Vollwinter),
						22 => q(Vorkälte),
						23 => q(Hauptkälte),
					},
				},
			},
			'years' => {
				'format' => {
					'wide' => {
						0 => q(Yang-Holzratte),
						1 => q(Yin-Holzbüffel),
						2 => q(Yang-Feuertiger),
						3 => q(Yin-Feuerhase),
						4 => q(Yang-Erddrache),
						5 => q(Yin-Erdschlange),
						6 => q(Yang-Metallpferd),
						7 => q(Yin-Metallziege),
						8 => q(Yang-Wasseraffe),
						9 => q(Yin-Wasserhuhn),
						10 => q(Yang-Holzhund),
						11 => q(Yin-Holzschwein),
						12 => q(Yang-Feuerratte),
						13 => q(Yin-Feuerbüffel),
						14 => q(Yang-Erdtiger),
						15 => q(Yin-Erdhase),
						16 => q(Yang-Metalldrache),
						17 => q(Yin-Metallschlange),
						18 => q(Yang-Wasserpferd),
						19 => q(Yin-Wasserziege),
						20 => q(Yang-Holzaffe),
						21 => q(Yin-Holzhuhn),
						22 => q(Yang-Feuerhund),
						23 => q(Yin-Feuerschwein),
						24 => q(Yang-Erdratte),
						25 => q(Yin-Erdbüffel),
						26 => q(Yang-Metalltiger),
						27 => q(Yin-Metallhase),
						28 => q(Yang-Wasserdrache),
						29 => q(Yin-Wasserschlange),
						30 => q(Yang-Holzpferd),
						31 => q(Yin-Holzziege),
						32 => q(Yang-Feueraffe),
						33 => q(Yin-Feuerhuhn),
						34 => q(Yang-Erdhund),
						35 => q(Yin-Erdschwein),
						36 => q(Yang-Metallratte),
						37 => q(Yin-Metallbüffel),
						38 => q(Yang-Wassertiger),
						39 => q(Yin-Wasserhase),
						40 => q(Yang-Holzdrache),
						41 => q(Yin-Holzschlange),
						42 => q(Yang-Feuerpferd),
						43 => q(Yin-Feuerziege),
						44 => q(Yang-Erdaffe),
						45 => q(Yin-Erdhuhn),
						46 => q(Yang-Metallhund),
						47 => q(Yin-Metallschwein),
						48 => q(Yang-Wasserratte),
						49 => q(Yin-Wasserbüffel),
						50 => q(Yang-Holztiger),
						51 => q(Yin-Holzhase),
						52 => q(Yang-Feuerdrache),
						53 => q(Yin-Feuerschlange),
						54 => q(Yang-Erdpferd),
						55 => q(Yin-Erdziege),
						56 => q(Yang-Metallaffe),
						57 => q(Yin-Metallhuhn),
						58 => q(Yang-Wasserhund),
						59 => q(Yin-Wasserschwein),
					},
				},
			},
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
					'narrow' => {
						0 => q(🐭),
						1 => q(🐮),
						2 => q(🐯),
						3 => q(🐰),
						4 => q(🐲),
						5 => q(🐍),
						6 => q(🐴),
						7 => q(🐏),
						8 => q(🐵),
						9 => q(🐔),
						10 => q(🐶),
						11 => q(🐷),
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
		regionFormat => q({0} (Ortszeit)),
		regionFormat => q({0} (Sommerzeit)),
		regionFormat => q({0} (Normalzeit)),
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
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dschibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadischu#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
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
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaninseln#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-Stadt#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Nordamerikanische Zentral-Sommerzeit#,
				'generic' => q#Nordamerikanische Zentralzeit#,
				'standard' => q#Nordamerikanische Zentral-Normalzeit#,
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
				'daylight' => q#Rocky-Mountains-Sommerzeit#,
				'generic' => q#Rocky-Mountains-Zeit#,
				'standard' => q#Rocky-Mountains-Normalzeit#,
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
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
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
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chowd#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtschatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatschi#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
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
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Qostanai#,
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
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
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
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
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
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaren#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöer#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reyk­ja­vík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Südgeorgien#,
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
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irische Sommerzeit#,
			},
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
		'Europe/London' => {
			long => {
				'daylight' => q#Britische Sommerzeit#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratow#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanowsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
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
				'standard' => q#Französische-Süd-und-Antarktisgebiete-Zeit#,
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
				'standard' => q#Indische Normalzeit#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Weihnachtsinsel#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoren#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediven#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indischer-Ozean-Zeit#,
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
				'daylight' => q#Irkutsker Sommerzeit#,
				'generic' => q#Irkutsker Zeit#,
				'standard' => q#Irkutsker Normalzeit#,
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
		'Kazakhstan' => {
			long => {
				'standard' => q#Kasachische Zeit#,
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
				'daylight' => q#Krasnojarsker Sommerzeit#,
				'generic' => q#Krasnojarsker Zeit#,
				'standard' => q#Krasnojarsker Normalzeit#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisische Zeit#,
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
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexikanische Pazifik-Sommerzeit#,
				'generic' => q#Mexikanische Pazifikzeit#,
				'standard' => q#Mexikanische Pazifik-Normalzeit#,
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
				'daylight' => q#Norfolkinsel-Sommerzeit#,
				'generic' => q#Norfolkinsel-Zeit#,
				'standard' => q#Norfolkinsel-Normalzeit#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando-de-Noronha-Sommerzeit#,
				'generic' => q#Fernando-de-Noronha-Zeit#,
				'standard' => q#Fernando-de-Noronha-Normalzeit#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Nördliche-Marianen-Zeit#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirsker Sommerzeit#,
				'generic' => q#Nowosibirsker Zeit#,
				'standard' => q#Nowosibirsker Normalzeit#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsker Sommerzeit#,
				'generic' => q#Omsker Zeit#,
				'standard' => q#Omsker Normalzeit#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Osterinsel#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
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
				'daylight' => q#Paraguayische Sommerzeit#,
				'generic' => q#Paraguayische Zeit#,
				'standard' => q#Paraguayische Normalzeit#,
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
				'standard' => q#Singapurische Normalzeit#,
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
				'standard' => q#Tadschikische Zeit#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-Zeit#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongaische Sommerzeit#,
				'generic' => q#Tongaische Zeit#,
				'standard' => q#Tongaische Normalzeit#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-Zeit#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenische Sommerzeit#,
				'generic' => q#Turkmenistan-Zeit#,
				'standard' => q#Turkmenische Normalzeit#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu-Zeit#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayische Sommerzeit#,
				'generic' => q#Uruguayische Zeit#,
				'standard' => q#Uruguayische Normalzeit#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekische Sommerzeit#,
				'generic' => q#Usbekische Zeit#,
				'standard' => q#Usbekische Normalzeit#,
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
				'daylight' => q#Wladiwostoker Sommerzeit#,
				'generic' => q#Wladiwostoker Zeit#,
				'standard' => q#Wladiwostoker Normalzeit#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograder Sommerzeit#,
				'generic' => q#Wolgograder Zeit#,
				'standard' => q#Wolgograder Normalzeit#,
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
				'daylight' => q#Jakutsker Sommerzeit#,
				'generic' => q#Jakutsker Zeit#,
				'standard' => q#Jakutsker Normalzeit#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburger Sommerzeit#,
				'generic' => q#Jekaterinburger Zeit#,
				'standard' => q#Jekaterinburger Normalzeit#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon-Zeit#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
