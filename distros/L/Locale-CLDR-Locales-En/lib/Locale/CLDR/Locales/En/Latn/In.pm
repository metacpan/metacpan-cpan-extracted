=encoding utf8

=head1 NAME

Locale::CLDR::Locales::En::Latn::In - Package for language English

=cut

package Locale::CLDR::Locales::En::Latn::In;
# This file auto generated from Data\common\main\en_IN.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::En::Latn::001');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-numbering-verbose','spellout-cardinal','spellout-cardinal-verbose','spellout-ordinal','spellout-ordinal-verbose' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'2d-year' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(hundred),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(oh-=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'and' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' and =%spellout-cardinal-verbose=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal-verbose=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-cardinal-verbose=),
				},
			},
		},
		'and-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(th),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' and =%spellout-ordinal-verbose=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-verbose=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(' =%spellout-ordinal-verbose=),
				},
			},
		},
		'commas' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' and =%spellout-cardinal-verbose=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(, =%spellout-cardinal-verbose=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(, ←%spellout-cardinal-verbose← thousand[→%%commas→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(, =%spellout-cardinal-verbose=),
				},
				'max' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(, =%spellout-cardinal-verbose=),
				},
			},
		},
		'commas-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(th),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' and =%spellout-ordinal-verbose=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(, =%spellout-ordinal-verbose=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(, ←%spellout-cardinal-verbose← thousand→%%commas-o→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(, =%spellout-ordinal-verbose=),
				},
				'max' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(, =%spellout-ordinal-verbose=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← point →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(one),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(two),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(three),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(four),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(five),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(six),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seven),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(eight),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nine),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ten),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(eleven),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(twelve),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(thirteen),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fourteen),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(fifteen),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sixteen),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(seventeen),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(eighteen),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nineteen),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(twenty[-→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(thirty[-→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(forty[-→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fifty[-→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sixty[-→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(seventy[-→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(eighty[-→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ninety[-→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← hundred[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← thousand[ →→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(←← lakh[ →→]),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(←← crore[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trillion[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← quadrillion[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinite),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(not a number),
				},
				'max' => {
					divisor => q(1),
					rule => q(not a number),
				},
			},
		},
		'spellout-cardinal-verbose' => {
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
					rule => q(←← point →→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← hundred[→%%and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← thousand[→%%and→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(←← lakh[→%%commas→]),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(←← crore[→%%commas→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trillion[→%%commas→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← quadrillion[→%%commas→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinite),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(not a number),
				},
				'max' => {
					divisor => q(1),
					rule => q(not a number),
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
					rule => q(=%spellout-cardinal=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinity),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(not a number),
				},
				'max' => {
					divisor => q(1),
					rule => q(not a number),
				},
			},
		},
		'spellout-numbering-verbose' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-verbose=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinity),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(not a number),
				},
				'max' => {
					divisor => q(1),
					rule => q(not a number),
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
					rule => q(=#,##0.#=),
				},
				'1010' => {
					base_value => q(1010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'2010' => {
					base_value => q(2010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'2100' => {
					base_value => q(2100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'3010' => {
					base_value => q(3010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'3100' => {
					base_value => q(3100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'4010' => {
					base_value => q(4010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'4100' => {
					base_value => q(4100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'5010' => {
					base_value => q(5010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'5100' => {
					base_value => q(5100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'6010' => {
					base_value => q(6010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'6100' => {
					base_value => q(6100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'7010' => {
					base_value => q(7010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'7100' => {
					base_value => q(7100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'8010' => {
					base_value => q(8010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'8100' => {
					base_value => q(8100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'9010' => {
					base_value => q(9010),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
				},
				'9100' => {
					base_value => q(9100),
					divisor => q(100),
					rule => q(←← →%%2d-year→),
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
					rule => q(zeroth),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(first),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(second),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(third),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fourth),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fifth),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sixth),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seventh),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(eighth),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ninth),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tenth),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(eleventh),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(twelfth),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-numbering=th),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(twen→%%tieth→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(thir→%%tieth→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(for→%%tieth→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(fif→%%tieth→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(six→%%tieth→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(seven→%%tieth→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(eigh→%%tieth→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nine→%%tieth→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering← hundred→%%th→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← thousand→%%th→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering← million→%%th→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering← billion→%%th→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering← trillion→%%th→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering← quadrillion→%%th→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=$(ordinal,one{st}two{nd}few{rd}other{th})$),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinitieth),
				},
				'max' => {
					divisor => q(1),
					rule => q(infinitieth),
				},
			},
		},
		'spellout-ordinal-verbose' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering-verbose← hundred→%%and-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering-verbose← thousand→%%and-o→),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(1000),
					rule => q(←%spellout-numbering-verbose← thousand→%%commas-o→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering-verbose← million→%%commas-o→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering-verbose← billion→%%commas-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering-verbose← trillion→%%commas-o→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering-verbose← quadrillion→%%commas-o→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=$(ordinal,one{st}two{nd}few{rd}other{th})$),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(infinitieth),
				},
				'max' => {
					divisor => q(1),
					rule => q(infinitieth),
				},
			},
		},
		'th' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(th),
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
		'tieth' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(tieth),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ty-=%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ty-=%spellout-ordinal=),
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
				'bn' => 'Bengali',

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
			'Beng' => 'Bengali',
 			'Orya' => 'Oriya',

			);
			if ( @_ ) {
				return $scripts{$_[0]};
			}
			return \%scripts;
		}
	}
);

has 'display_name_type' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[Str]],
	init_arg	=> undef,
	default		=> sub {
		{
			'numbers' => {
 				'beng' => q{Bengali Digits},
 				'orya' => q{Oriya Digits},
 			},

		}
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0} earth radius),
						'other' => q({0} earth radius),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0} earth radius),
						'other' => q({0} earth radius),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}kph),
						'other' => q({0}kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}kph),
						'other' => q({0}kph),
					},
				},
				'short' => {
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
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
					'one' => '0T',
					'other' => '0T',
				},
				'10000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000' => {
					'one' => '0L',
					'other' => '0L',
				},
				'1000000' => {
					'one' => '00L',
					'other' => '00L',
				},
				'10000000' => {
					'one' => '0Cr',
					'other' => '0Cr',
				},
				'100000000' => {
					'one' => '00Cr',
					'other' => '00Cr',
				},
				'1000000000' => {
					'one' => '000Cr',
					'other' => '000Cr',
				},
				'10000000000' => {
					'one' => '0TCr',
					'other' => '0TCr',
				},
				'100000000000' => {
					'one' => '00TCr',
					'other' => '00TCr',
				},
				'1000000000000' => {
					'one' => '0LCr',
					'other' => '0LCr',
				},
				'10000000000000' => {
					'one' => '00LCr',
					'other' => '00LCr',
				},
				'100000000000000' => {
					'one' => '000LCr',
					'other' => '000LCr',
				},
				'standard' => {
					'default' => '#,##,##0.###',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000' => {
					'one' => '0L',
					'other' => '0L',
				},
				'1000000' => {
					'one' => '00L',
					'other' => '00L',
				},
				'10000000' => {
					'one' => '0Cr',
					'other' => '0Cr',
				},
				'100000000' => {
					'one' => '00Cr',
					'other' => '00Cr',
				},
				'1000000000' => {
					'one' => '000Cr',
					'other' => '000Cr',
				},
				'10000000000' => {
					'one' => '0TCr',
					'other' => '0TCr',
				},
				'100000000000' => {
					'one' => '00TCr',
					'other' => '00TCr',
				},
				'1000000000000' => {
					'one' => '0LCr',
					'other' => '0LCr',
				},
				'10000000000000' => {
					'one' => '00LCr',
					'other' => '00LCr',
				},
				'100000000000000' => {
					'one' => '000LCr',
					'other' => '000LCr',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##,##0%',
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
						'positive' => '¤#,##,##0.00',
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
		'USD' => {
			symbol => '$',
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezuelan Bolívar),
				'one' => q(Venezuelan bolívar),
				'other' => q(Venezuelan bolívars),
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
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
			'stand-alone' => {
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
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
		'generic' => {
		},
		'gregorian' => {
		},
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE d MMMM, y G},
			'long' => q{d MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM, y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
		},
		'islamic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM, y G},
			'medium' => q{dd-MMM-y G},
			'short' => q{d/M/y/ GGGGG},
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			GyMMM => q{MMM, y G},
			GyMMMEEEEd => q{EEEE d MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			MEd => q{E, d/M},
			MMMEEEEd => q{EEEE d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			Md => q{d/M},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM, y G},
			yyyyMMMEEEEd => q{EEEE d MMM, y G},
			yyyyMMMEd => q{E, d MMM, y G},
			yyyyMMMM => q{MMMM, y G},
			yyyyMMMMEEEEd => q{EEEE d MMMM, y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d/M/y G},
		},
		'gregorian' => {
			EBhm => q{E, h:mm B},
			EBhms => q{E, h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			GyMMMEEEEd => q{EEEE d MMM, y G},
			MMMEEEEd => q{EEEE d MMM},
			MMMMEEEEd => q{EEEE d MMMM},
			yMEd => q{E, d/M/y},
			yMMMEEEEd => q{EEEE d MMM, y},
			yMMMEd => q{E, d MMM, y},
			yMMMMEEEEd => q{EEEE d MMMM, y},
			yMd => q{d/M/y},
		},
		'islamic' => {
			Ed => q{E d},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{d MMM, y G},
			MEd => q{E, d/M},
			Md => q{d/M},
			yyyyMEd => q{E d/M/y G},
			yyyyMMM => q{MMM, y G},
			yyyyMMMEd => q{E, d MMM, y G},
			yyyyMMMM => q{MMMM, y G},
			yyyyMMMd => q{d MMM, y G},
			yyyyMd => q{d/M/y G},
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
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMMEEEEd => {
				G => q{EEEE d MMM y G – EEEE d MMM, y G},
				M => q{EEEE d MMM – EEEE d MMM, y G},
				d => q{EEEE d MMM – EEEE d MMM, y G},
				y => q{EEEE d MMM y – EEEE d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM},
				d => q{EEEE d – EEEE d MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			GyMMMEEEEd => {
				G => q{EEEE d MMM y G – EEEE d MMM y G},
				M => q{EEEE d MMM – EEEE d MMM y G},
				d => q{EEEE d MMM – EEEE d MMM y G},
				y => q{EEEE d MMM y – EEEE d MMM y G},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM},
				d => q{EEEE d – EEEE d MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			yMMMEEEEd => {
				M => q{EEEE d MMM – EEEE d MMM y},
				d => q{EEEE d – EEEE d MMM y},
				y => q{EEEE d MMM y – EEEE d MMM y},
			},
			yMMMMEEEEd => {
				M => q{EEEE d MMMM – EEEE d MMMM y},
				d => q{EEEE d – EEEE d MMMM y},
				y => q{EEEE d MMMM y – EEEE d MMMM y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Gulf' => {
			short => {
				'standard' => q#GST#,
			},
		},
		'India' => {
			short => {
				'standard' => q#IST#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
