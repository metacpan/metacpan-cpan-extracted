=head1

Locale::CLDR::Locales::En - Package for language English

=cut

package Locale::CLDR::Locales::En;
# This file auto generated from Data\common\main\en.xml
#	on Fri 13 Apr  7:07:32 am GMT

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

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-numbering-verbose','spellout-cardinal','spellout-cardinal-verbose','spellout-ordinal','spellout-ordinal-verbose','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
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
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{st}two{nd}few{rd}other{th})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{st}two{nd}few{rd}other{th})$),
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
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← million[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← billion[ →→]),
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
					divisor => q(1000),
					rule => q(←← thousand[→%%commas→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← million[→%%commas→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← billion[→%%commas→]),
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
					rule => q(=#,##0=.),
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
					rule => q(=#,##0=.),
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
 				'ab' => 'Abkhazian',
 				'ace' => 'Achinese',
 				'ach' => 'Acoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'ae' => 'Avestan',
 				'aeb' => 'Tunisian Arabic',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Akkadian',
 				'akz' => 'Alabama',
 				'ale' => 'Aleut',
 				'aln' => 'Gheg Albanian',
 				'alt' => 'Southern Altai',
 				'am' => 'Amharic',
 				'an' => 'Aragonese',
 				'ang' => 'Old English',
 				'anp' => 'Angika',
 				'ar' => 'Arabic',
 				'ar_001' => 'Modern Standard Arabic',
 				'arc' => 'Aramaic',
 				'arn' => 'Mapuche',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho',
 				'arq' => 'Algerian Arabic',
 				'ars' => 'Najdi Arabic',
 				'arw' => 'Arawak',
 				'ary' => 'Moroccan Arabic',
 				'arz' => 'Egyptian Arabic',
 				'as' => 'Assamese',
 				'asa' => 'Asu',
 				'ase' => 'American Sign Language',
 				'ast' => 'Asturian',
 				'av' => 'Avaric',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Azerbaijani',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluchi',
 				'ban' => 'Balinese',
 				'bar' => 'Bavarian',
 				'bas' => 'Basaa',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Belarusian',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgarian',
 				'bgn' => 'Western Balochi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Bini',
 				'bjn' => 'Banjar',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'bm' => 'Bambara',
 				'bn' => 'Bangla',
 				'bo' => 'Tibetan',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bakhtiari',
 				'br' => 'Breton',
 				'bra' => 'Braj',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnian',
 				'bss' => 'Akoose',
 				'bua' => 'Buriat',
 				'bug' => 'Buginese',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Catalan',
 				'cad' => 'Caddo',
 				'car' => 'Carib',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ccp' => 'Chakma',
 				'ce' => 'Chechen',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Chuukese',
 				'chm' => 'Mari',
 				'chn' => 'Chinook Jargon',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Central Kurdish',
 				'co' => 'Corsican',
 				'cop' => 'Coptic',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crh' => 'Crimean Turkish',
 				'crs' => 'Seselwa Creole French',
 				'cs' => 'Czech',
 				'csb' => 'Kashubian',
 				'cu' => 'Church Slavic',
 				'cv' => 'Chuvash',
 				'cy' => 'Welsh',
 				'da' => 'Danish',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'German',
 				'de_AT' => 'Austrian German',
 				'de_CH' => 'Swiss High German',
 				'del' => 'Delaware',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Lower Sorbian',
 				'dtp' => 'Central Dusun',
 				'dua' => 'Duala',
 				'dum' => 'Middle Dutch',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egl' => 'Emilian',
 				'egy' => 'Ancient Egyptian',
 				'eka' => 'Ekajuk',
 				'el' => 'Greek',
 				'elx' => 'Elamite',
 				'en' => 'English',
 				'en_AU' => 'Australian English',
 				'en_CA' => 'Canadian English',
 				'en_GB' => 'British English',
 				'en_GB@alt=short' => 'UK English',
 				'en_US' => 'American English',
 				'en_US@alt=short' => 'US English',
 				'enm' => 'Middle English',
 				'eo' => 'Esperanto',
 				'es' => 'Spanish',
 				'es_419' => 'Latin American Spanish',
 				'es_ES' => 'European Spanish',
 				'es_MX' => 'Mexican Spanish',
 				'esu' => 'Central Yupik',
 				'et' => 'Estonian',
 				'eu' => 'Basque',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremaduran',
 				'fa' => 'Persian',
 				'fa_AF' => 'Dari',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fulah',
 				'fi' => 'Finnish',
 				'fil' => 'Filipino',
 				'fit' => 'Tornedalen Finnish',
 				'fj' => 'Fijian',
 				'fo' => 'Faroese',
 				'fon' => 'Fon',
 				'fr' => 'French',
 				'fr_CA' => 'Canadian French',
 				'fr_CH' => 'Swiss French',
 				'frc' => 'Cajun French',
 				'frm' => 'Middle French',
 				'fro' => 'Old French',
 				'frp' => 'Arpitan',
 				'frr' => 'Northern Frisian',
 				'frs' => 'Eastern Frisian',
 				'fur' => 'Friulian',
 				'fy' => 'Western Frisian',
 				'ga' => 'Irish',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gan' => 'Gan Chinese',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gbz' => 'Zoroastrian Dari',
 				'gd' => 'Scottish Gaelic',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertese',
 				'gl' => 'Galician',
 				'glk' => 'Gilaki',
 				'gmh' => 'Middle High German',
 				'gn' => 'Guarani',
 				'goh' => 'Old High German',
 				'gom' => 'Goan Konkani',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gothic',
 				'grb' => 'Grebo',
 				'grc' => 'Ancient Greek',
 				'gsw' => 'Swiss German',
 				'gu' => 'Gujarati',
 				'guc' => 'Wayuu',
 				'gur' => 'Frafra',
 				'guz' => 'Gusii',
 				'gv' => 'Manx',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'hak' => 'Hakka Chinese',
 				'haw' => 'Hawaiian',
 				'he' => 'Hebrew',
 				'hi' => 'Hindi',
 				'hif' => 'Fiji Hindi',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Hittite',
 				'hmn' => 'Hmong',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Croatian',
 				'hsb' => 'Upper Sorbian',
 				'hsn' => 'Xiang Chinese',
 				'ht' => 'Haitian Creole',
 				'hu' => 'Hungarian',
 				'hup' => 'Hupa',
 				'hy' => 'Armenian',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesian',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'Inupiaq',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Icelandic',
 				'it' => 'Italian',
 				'iu' => 'Inuktitut',
 				'izh' => 'Ingrian',
 				'ja' => 'Japanese',
 				'jam' => 'Jamaican Creole English',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Judeo-Persian',
 				'jrb' => 'Judeo-Arabic',
 				'jut' => 'Jutish',
 				'jv' => 'Javanese',
 				'ka' => 'Georgian',
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardian',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'kho' => 'Khotanese',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Kikuyu',
 				'kiu' => 'Kirmanjki',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kazakh',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korean',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraean',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Karelian',
 				'kru' => 'Kurukh',
 				'ks' => 'Kashmiri',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Colognian',
 				'ku' => 'Kurdish',
 				'kum' => 'Kumyk',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Cornish',
 				'ky' => 'Kyrgyz',
 				'ky@alt=variant' => 'Kirghiz',
 				'la' => 'Latin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Luxembourgish',
 				'lez' => 'Lezghian',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Ganda',
 				'li' => 'Limburgish',
 				'lij' => 'Ligurian',
 				'liv' => 'Livonian',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombard',
 				'ln' => 'Lingala',
 				'lo' => 'Lao',
 				'lol' => 'Mongo',
 				'lou' => 'Louisiana Creole',
 				'loz' => 'Lozi',
 				'lrc' => 'Northern Luri',
 				'lt' => 'Lithuanian',
 				'ltg' => 'Latgalian',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Latvian',
 				'lzh' => 'Literary Chinese',
 				'lzz' => 'Laz',
 				'mad' => 'Madurese',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'man' => 'Mandingo',
 				'mas' => 'Masai',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasy',
 				'mga' => 'Middle Irish',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Metaʼ',
 				'mh' => 'Marshallese',
 				'mi' => 'Maori',
 				'mic' => 'Mi\'kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Macedonian',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolian',
 				'mnc' => 'Manchu',
 				'mni' => 'Manipuri',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'mrj' => 'Western Mari',
 				'ms' => 'Malay',
 				'mt' => 'Maltese',
 				'mua' => 'Mundang',
 				'mul' => 'Multiple languages',
 				'mus' => 'Creek',
 				'mwl' => 'Mirandese',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Burmese',
 				'my@alt=variant' => 'Myanmar Language',
 				'mye' => 'Myene',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nauru',
 				'nan' => 'Min Nan Chinese',
 				'nap' => 'Neapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Norwegian Bokmål',
 				'nd' => 'North Ndebele',
 				'nds' => 'Low German',
 				'nds_NL' => 'Low Saxon',
 				'ne' => 'Nepali',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Niuean',
 				'njo' => 'Ao Naga',
 				'nl' => 'Dutch',
 				'nl_BE' => 'Flemish',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwegian Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegian',
 				'nog' => 'Nogai',
 				'non' => 'Old Norse',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'South Ndebele',
 				'nso' => 'Northern Sotho',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Classical Newari',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Occitan',
 				'oj' => 'Ojibwa',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetic',
 				'osa' => 'Osage',
 				'ota' => 'Ottoman Turkish',
 				'pa' => 'Punjabi',
 				'pag' => 'Pangasinan',
 				'pal' => 'Pahlavi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamento',
 				'pau' => 'Palauan',
 				'pcd' => 'Picard',
 				'pcm' => 'Nigerian Pidgin',
 				'pdc' => 'Pennsylvania German',
 				'pdt' => 'Plautdietsch',
 				'peo' => 'Old Persian',
 				'pfl' => 'Palatine German',
 				'phn' => 'Phoenician',
 				'pi' => 'Pali',
 				'pl' => 'Polish',
 				'pms' => 'Piedmontese',
 				'pnt' => 'Pontic',
 				'pon' => 'Pohnpeian',
 				'prg' => 'Prussian',
 				'pro' => 'Old Provençal',
 				'ps' => 'Pashto',
 				'ps@alt=variant' => 'Pushto',
 				'pt' => 'Portuguese',
 				'pt_BR' => 'Brazilian Portuguese',
 				'pt_PT' => 'European Portuguese',
 				'qu' => 'Quechua',
 				'quc' => 'Kʼicheʼ',
 				'qug' => 'Chimborazo Highland Quichua',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rgn' => 'Romagnol',
 				'rif' => 'Riffian',
 				'rm' => 'Romansh',
 				'rn' => 'Rundi',
 				'ro' => 'Romanian',
 				'ro_MD' => 'Moldavian',
 				'rof' => 'Rombo',
 				'rom' => 'Romany',
 				'root' => 'Root',
 				'rtm' => 'Rotuman',
 				'ru' => 'Russian',
 				'rue' => 'Rusyn',
 				'rug' => 'Roviana',
 				'rup' => 'Aromanian',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'sam' => 'Samaritan Aramaic',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardinian',
 				'scn' => 'Sicilian',
 				'sco' => 'Scots',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sassarese Sardinian',
 				'sdh' => 'Southern Kurdish',
 				'se' => 'Northern Sami',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkup',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Old Irish',
 				'sgs' => 'Samogitian',
 				'sh' => 'Serbo-Croatian',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'shu' => 'Chadian Arabic',
 				'si' => 'Sinhala',
 				'sid' => 'Sidamo',
 				'sk' => 'Slovak',
 				'sl' => 'Slovenian',
 				'sli' => 'Lower Silesian',
 				'sly' => 'Selayar',
 				'sm' => 'Samoan',
 				'sma' => 'Southern Sami',
 				'smj' => 'Lule Sami',
 				'smn' => 'Inari Sami',
 				'sms' => 'Skolt Sami',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somali',
 				'sog' => 'Sogdien',
 				'sq' => 'Albanian',
 				'sr' => 'Serbian',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serer',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Southern Sotho',
 				'stq' => 'Saterland Frisian',
 				'su' => 'Sundanese',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Sumerian',
 				'sv' => 'Swedish',
 				'sw' => 'Swahili',
 				'sw_CD' => 'Congo Swahili',
 				'swb' => 'Comorian',
 				'syc' => 'Classical Syriac',
 				'syr' => 'Syriac',
 				'szl' => 'Silesian',
 				'ta' => 'Tamil',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno',
 				'tet' => 'Tetum',
 				'tg' => 'Tajik',
 				'th' => 'Thai',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turkmen',
 				'tkl' => 'Tokelau',
 				'tkr' => 'Tsakhur',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tly' => 'Talysh',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tongan',
 				'tog' => 'Nyasa Tonga',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turkish',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonian',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatar',
 				'ttt' => 'Muslim Tat',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitian',
 				'tyv' => 'Tuvinian',
 				'tzm' => 'Central Atlas Tamazight',
 				'udm' => 'Udmurt',
 				'ug' => 'Uyghur',
 				'ug@alt=variant' => 'Uighur',
 				'uga' => 'Ugaritic',
 				'uk' => 'Ukrainian',
 				'umb' => 'Umbundu',
 				'und' => 'Unknown language',
 				'ur' => 'Urdu',
 				'uz' => 'Uzbek',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Venetian',
 				'vep' => 'Veps',
 				'vi' => 'Vietnamese',
 				'vls' => 'West Flemish',
 				'vmf' => 'Main-Franconian',
 				'vo' => 'Volapük',
 				'vot' => 'Votic',
 				'vro' => 'Võro',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Walser',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu Chinese',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xmf' => 'Mingrelian',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Yapese',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Yiddish',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Cantonese',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotec',
 				'zbl' => 'Blissymbols',
 				'zea' => 'Zeelandic',
 				'zen' => 'Zenaga',
 				'zgh' => 'Standard Moroccan Tamazight',
 				'zh' => 'Chinese',
 				'zh@alt=long' => 'Mandarin Chinese',
 				'zh_Hans' => 'Simplified Chinese',
 				'zh_Hant' => 'Traditional Chinese',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni',
 				'zxx' => 'No linguistic content',
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
 			'Aghb' => 'Caucasian Albanian',
 			'Ahom' => 'Ahom',
 			'Arab' => 'Arabic',
 			'Arab@alt=variant' => 'Perso-Arabic',
 			'Armi' => 'Imperial Aramaic',
 			'Armn' => 'Armenian',
 			'Avst' => 'Avestan',
 			'Bali' => 'Balinese',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Bangla',
 			'Bhks' => 'Bhaiksuki',
 			'Blis' => 'Blissymbols',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buginese',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Unified Canadian Aboriginal Syllabics',
 			'Cans@alt=short' => 'UCAS',
 			'Cari' => 'Carian',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Coptic',
 			'Cprt' => 'Cypriot',
 			'Cyrl' => 'Cyrillic',
 			'Cyrs' => 'Old Church Slavonic Cyrillic',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Duployan shorthand',
 			'Egyd' => 'Egyptian demotic',
 			'Egyh' => 'Egyptian hieratic',
 			'Egyp' => 'Egyptian hieroglyphs',
 			'Elba' => 'Elbasan',
 			'Ethi' => 'Ethiopic',
 			'Geok' => 'Georgian Khutsuri',
 			'Geor' => 'Georgian',
 			'Glag' => 'Glagolitic',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gothic',
 			'Gran' => 'Grantha',
 			'Grek' => 'Greek',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han with Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Simplified',
 			'Hans@alt=stand-alone' => 'Simplified Han',
 			'Hant' => 'Traditional',
 			'Hant@alt=stand-alone' => 'Traditional Han',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Hebrew',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anatolian Hieroglyphs',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Japanese syllabaries',
 			'Hung' => 'Old Hungarian',
 			'Inds' => 'Indus',
 			'Ital' => 'Old Italic',
 			'Jamo' => 'Jamo',
 			'Java' => 'Javanese',
 			'Jpan' => 'Japanese',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Kannada',
 			'Kore' => 'Korean',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Lao',
 			'Latf' => 'Fraktur Latin',
 			'Latg' => 'Gaelic Latin',
 			'Latn' => 'Latin',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycian',
 			'Lydi' => 'Lydian',
 			'Mahj' => 'Mahajani',
 			'Mand' => 'Mandaean',
 			'Mani' => 'Manichaean',
 			'Marc' => 'Marchen',
 			'Maya' => 'Mayan hieroglyphs',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroitic Cursive',
 			'Mero' => 'Meroitic',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Mongolian',
 			'Moon' => 'Moon',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Myanmar',
 			'Narb' => 'Old North Arabian',
 			'Nbat' => 'Nabataean',
 			'Newa' => 'Newa',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’Ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Odia',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Old Permic',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Inscriptional Pahlavi',
 			'Phlp' => 'Psalter Pahlavi',
 			'Phlv' => 'Book Pahlavi',
 			'Phnx' => 'Phoenician',
 			'Plrd' => 'Pollard Phonetic',
 			'Prti' => 'Inscriptional Parthian',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runic',
 			'Samr' => 'Samaritan',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Old South Arabian',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'Shavian',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Sinhala',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sundanese',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syriac',
 			'Syre' => 'Estrangelo Syriac',
 			'Syrj' => 'Western Syriac',
 			'Syrn' => 'Eastern Syriac',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'New Tai Lue',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibetan',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Ugaritic',
 			'Vaii' => 'Vai',
 			'Visp' => 'Visible Speech',
 			'Wara' => 'Varang Kshiti',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Old Persian',
 			'Xsux' => 'Sumero-Akkadian Cuneiform',
 			'Xsux@alt=short' => 'S-A Cuneiform',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Zanabazar Square',
 			'Zinh' => 'Inherited',
 			'Zmth' => 'Mathematical Notation',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Symbols',
 			'Zxxx' => 'Unwritten',
 			'Zyyy' => 'Common',
 			'Zzzz' => 'Unknown Script',

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
			'001' => 'World',
 			'002' => 'Africa',
 			'003' => 'North America',
 			'005' => 'South America',
 			'009' => 'Oceania',
 			'011' => 'Western Africa',
 			'013' => 'Central America',
 			'014' => 'Eastern Africa',
 			'015' => 'Northern Africa',
 			'017' => 'Middle Africa',
 			'018' => 'Southern Africa',
 			'019' => 'Americas',
 			'021' => 'Northern America',
 			'029' => 'Caribbean',
 			'030' => 'Eastern Asia',
 			'034' => 'Southern Asia',
 			'035' => 'Southeast Asia',
 			'039' => 'Southern Europe',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Micronesian Region',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Central Asia',
 			'145' => 'Western Asia',
 			'150' => 'Europe',
 			'151' => 'Eastern Europe',
 			'154' => 'Northern Europe',
 			'155' => 'Western Europe',
 			'202' => 'Sub-Saharan Africa',
 			'419' => 'Latin America',
 			'AC' => 'Ascension Island',
 			'AD' => 'Andorra',
 			'AE' => 'United Arab Emirates',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua & Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctica',
 			'AR' => 'Argentina',
 			'AS' => 'American Samoa',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Åland Islands',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia & Herzegovina',
 			'BA@alt=short' => 'Bosnia',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgium',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribbean Netherlands',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet Island',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Cocos (Keeling) Islands',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (DRC)',
 			'CF' => 'Central African Republic',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'Congo (Republic)',
 			'CH' => 'Switzerland',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Ivory Coast',
 			'CK' => 'Cook Islands',
 			'CL' => 'Chile',
 			'CM' => 'Cameroon',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Clipperton Island',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmas Island',
 			'CY' => 'Cyprus',
 			'CZ' => 'Czechia',
 			'CZ@alt=variant' => 'Czech Republic',
 			'DE' => 'Germany',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Denmark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominican Republic',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta & Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egypt',
 			'EH' => 'Western Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spain',
 			'ET' => 'Ethiopia',
 			'EU' => 'European Union',
 			'EZ' => 'Eurozone',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falkland Islands',
 			'FK@alt=variant' => 'Falkland Islands (Islas Malvinas)',
 			'FM' => 'Micronesia',
 			'FO' => 'Faroe Islands',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'United Kingdom',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'French Guiana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Greenland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorial Guinea',
 			'GR' => 'Greece',
 			'GS' => 'South Georgia & South Sandwich Islands',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong SAR China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard & McDonald Islands',
 			'HN' => 'Honduras',
 			'HR' => 'Croatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungary',
 			'IC' => 'Canary Islands',
 			'ID' => 'Indonesia',
 			'IE' => 'Ireland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'India',
 			'IO' => 'British Indian Ocean Territory',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Iceland',
 			'IT' => 'Italy',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Cambodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoros',
 			'KN' => 'St. Kitts & Nevis',
 			'KP' => 'North Korea',
 			'KR' => 'South Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Cayman Islands',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Lebanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lithuania',
 			'LU' => 'Luxembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Morocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Marshall Islands',
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MM@alt=short' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau SAR China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Northern Mariana Islands',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'New Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Island',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Netherlands',
 			'NO' => 'Norway',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'French Polynesia',
 			'PG' => 'Papua New Guinea',
 			'PH' => 'Philippines',
 			'PK' => 'Pakistan',
 			'PL' => 'Poland',
 			'PM' => 'St. Pierre & Miquelon',
 			'PN' => 'Pitcairn Islands',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinian Territories',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Outlying Oceania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Solomon Islands',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Sweden',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard & Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'South Sudan',
 			'ST' => 'São Tomé & Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks & Caicos Islands',
 			'TD' => 'Chad',
 			'TF' => 'French Southern Territories',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'East Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkey',
 			'TT' => 'Trinidad & Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraine',
 			'UG' => 'Uganda',
 			'UM' => 'U.S. Outlying Islands',
 			'UN' => 'United Nations',
 			'UN@alt=short' => 'UN',
 			'US' => 'United States',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatican City',
 			'VC' => 'St. Vincent & Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'British Virgin Islands',
 			'VI' => 'U.S. Virgin Islands',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis & Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'South Africa',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Unknown Region',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Traditional German orthography',
 			'1994' => 'Standardized Resian orthography',
 			'1996' => 'German orthography of 1996',
 			'1606NICT' => 'Late Middle French to 1606',
 			'1694ACAD' => 'Early Modern French',
 			'1959ACAD' => 'Academic',
 			'ABL1943' => 'Orthographic formulation of 1943',
 			'ALALC97' => 'ALA-LC Romanization, 1997 edition',
 			'ALUKU' => 'Aluku dialect',
 			'AO1990' => 'Portuguese Language Orthographic Agreement of 1990',
 			'AREVELA' => 'Eastern Armenian',
 			'AREVMDA' => 'Western Armenian',
 			'BAKU1926' => 'Unified Turkic Latin Alphabet',
 			'BALANKA' => 'Balanka dialect of Anii',
 			'BARLA' => 'Barlavento dialect group of Kabuverdianu',
 			'BISKE' => 'San Giorgio/Bila dialect',
 			'BOHORIC' => 'Bohorič alphabet',
 			'BOONT' => 'Boontling',
 			'COLB1945' => 'Portuguese-Brazilian Orthographic Convention of 1945',
 			'DAJNKO' => 'Dajnko alphabet',
 			'EKAVSK' => 'Serbian with Ekavian pronunciation',
 			'EMODENG' => 'Early Modern English',
 			'FONIPA' => 'IPA Phonetics',
 			'FONUPA' => 'UPA Phonetics',
 			'HEPBURN' => 'Hepburn romanization',
 			'IJEKAVSK' => 'Serbian with Ijekavian pronunciation',
 			'KKCOR' => 'Common Orthography',
 			'KSCOR' => 'Standard Orthography',
 			'LIPAW' => 'The Lipovaz dialect of Resian',
 			'METELKO' => 'Metelko alphabet',
 			'MONOTON' => 'Monotonic',
 			'NDYUKA' => 'Ndyuka dialect',
 			'NEDIS' => 'Natisone dialect',
 			'NJIVA' => 'Gniva/Njiva dialect',
 			'NULIK' => 'Modern Volapük',
 			'OSOJS' => 'Oseacco/Osojane dialect',
 			'OXENDICT' => 'Oxford English Dictionary spelling',
 			'PAMAKA' => 'Pamaka dialect',
 			'PINYIN' => 'Pinyin Romanization',
 			'POLYTON' => 'Polytonic',
 			'POSIX' => 'Computer',
 			'REVISED' => 'Revised Orthography',
 			'RIGIK' => 'Classic Volapük',
 			'ROZAJ' => 'Resian',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Scottish Standard English',
 			'SCOUSE' => 'Scouse',
 			'SOLBA' => 'Stolvizza/Solbica dialect',
 			'SOTAV' => 'Sotavento dialect group of Kabuverdianu',
 			'TARASK' => 'Taraskievica orthography',
 			'UCCOR' => 'Unified Orthography',
 			'UCRCOR' => 'Unified Revised Orthography',
 			'UNIFON' => 'Unifon phonetic alphabet',
 			'VALENCIA' => 'Valencian',
 			'WADEGILE' => 'Wade-Giles Romanization',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Calendar',
 			'cf' => 'Currency Format',
 			'colalternate' => 'Ignore Symbols Sorting',
 			'colbackwards' => 'Reversed Accent Sorting',
 			'colcasefirst' => 'Uppercase/Lowercase Ordering',
 			'colcaselevel' => 'Case Sensitive Sorting',
 			'collation' => 'Sort Order',
 			'colnormalization' => 'Normalized Sorting',
 			'colnumeric' => 'Numeric Sorting',
 			'colreorder' => 'Script/Block Reordering',
 			'colstrength' => 'Sorting Strength',
 			'currency' => 'Currency',
 			'd0' => 'Transform Destination',
 			'em' => 'Emoji Presentation Style',
 			'fw' => 'First day of week',
 			'h0' => 'Mixed-in Language',
 			'hc' => 'Hour Cycle (12 vs 24)',
 			'i0' => 'Input Method',
 			'k0' => 'Keyboard',
 			'kv' => 'Highest Ignored',
 			'lb' => 'Line Break Style',
 			'lw' => 'Line Breaks In Words Setting',
 			'm0' => 'Transform Rules',
 			'ms' => 'Measurement System',
 			'numbers' => 'Numbers',
 			'rg' => 'Region For Supplemental Data',
 			's0' => 'Transform Source',
 			'sd' => 'Region Subdivision',
 			'ss' => 'Sentence Break Suppressions Type',
 			't0' => 'Machine Translated',
 			'timezone' => 'Time Zone',
 			'va' => 'Locale Variant',
 			'x' => 'Private-Use',
 			'x0' => 'Private-Use Transform',

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
 				'buddhist' => q{Buddhist Calendar},
 				'chinese' => q{Chinese Calendar},
 				'coptic' => q{Coptic Calendar},
 				'dangi' => q{Dangi Calendar},
 				'ethiopic' => q{Ethiopic Calendar},
 				'ethiopic-amete-alem' => q{Ethiopic Amete Alem Calendar},
 				'gregorian' => q{Gregorian Calendar},
 				'hebrew' => q{Hebrew Calendar},
 				'indian' => q{Indian National Calendar},
 				'islamic' => q{Islamic Calendar},
 				'islamic-civil' => q{Islamic Calendar (tabular, civil epoch)},
 				'islamic-rgsa' => q{Islamic Calendar (Saudi Arabia, sighting)},
 				'islamic-tbla' => q{Islamic Calendar (tabular, astronomical epoch)},
 				'islamic-umalqura' => q{Islamic Calendar (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 Calendar},
 				'japanese' => q{Japanese Calendar},
 				'persian' => q{Persian Calendar},
 				'roc' => q{Minguo Calendar},
 			},
 			'cf' => {
 				'account' => q{Accounting Currency Format},
 				'standard' => q{Standard Currency Format},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Sort Symbols},
 				'shifted' => q{Sort Ignoring Symbols},
 			},
 			'colbackwards' => {
 				'no' => q{Sort Accents Normally},
 				'yes' => q{Sort Accents Reversed},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sort Lowercase First},
 				'no' => q{Sort Normal Case Order},
 				'upper' => q{Sort Uppercase First},
 			},
 			'colcaselevel' => {
 				'no' => q{Sort Case Insensitive},
 				'yes' => q{Sort Case Sensitive},
 			},
 			'collation' => {
 				'big5han' => q{Traditional Chinese Sort Order - Big5},
 				'compat' => q{Previous Sort Order, for compatibility},
 				'dictionary' => q{Dictionary Sort Order},
 				'ducet' => q{Default Unicode Sort Order},
 				'emoji' => q{Emoji Sort Order},
 				'eor' => q{European Ordering Rules},
 				'gb2312han' => q{Simplified Chinese Sort Order - GB2312},
 				'phonebook' => q{Phonebook Sort Order},
 				'phonetic' => q{Phonetic Sort Order},
 				'pinyin' => q{Pinyin Sort Order},
 				'reformed' => q{Reformed Sort Order},
 				'search' => q{General-Purpose Search},
 				'searchjl' => q{Search By Hangul Initial Consonant},
 				'standard' => q{Standard Sort Order},
 				'stroke' => q{Stroke Sort Order},
 				'traditional' => q{Traditional Sort Order},
 				'unihan' => q{Radical-Stroke Sort Order},
 				'zhuyin' => q{Zhuyin Sort Order},
 			},
 			'colnormalization' => {
 				'no' => q{Sort Without Normalization},
 				'yes' => q{Sort Unicode Normalized},
 			},
 			'colnumeric' => {
 				'no' => q{Sort Digits Individually},
 				'yes' => q{Sort Digits Numerically},
 			},
 			'colstrength' => {
 				'identical' => q{Sort All},
 				'primary' => q{Sort Base Letters Only},
 				'quaternary' => q{Sort Accents/Case/Width/Kana},
 				'secondary' => q{Sort Accents},
 				'tertiary' => q{Sort Accents/Case/Width},
 			},
 			'd0' => {
 				'accents' => q{To Accented Characters From ASCII Sequence},
 				'ascii' => q{To ASCII},
 				'casefold' => q{To Casefolded},
 				'charname' => q{To Unicode Character Names},
 				'fcc' => q{To Unicode FCC},
 				'fcd' => q{To Unicode FCD},
 				'fwidth' => q{To Fullwidth},
 				'hex' => q{To Hexadecimal Codes},
 				'hwidth' => q{To Halfwidth},
 				'lower' => q{To Lowercase},
 				'nfc' => q{To Unicode NFC},
 				'nfd' => q{To Unicode NFD},
 				'nfkc' => q{To Unicode NFKC},
 				'nfkd' => q{To Unicode NFKD},
 				'npinyin' => q{To Pinyin With Numeric Tones},
 				'null' => q{No Change},
 				'publish' => q{To Publishing Characters From ASCII},
 				'remove' => q{To Empty String},
 				'title' => q{To Titlecase},
 				'upper' => q{To Uppercase},
 			},
 			'em' => {
 				'default' => q{Use Default Presentation For Emoji Characters},
 				'emoji' => q{Prefer Emoji Presentation For Emoji Characters},
 				'text' => q{Prefer Text Presentation For Emoji Characters},
 			},
 			'fw' => {
 				'fri' => q{First Day of Week Is Friday},
 				'mon' => q{First Day of Week Is Monday},
 				'sat' => q{First Day of Week Is Saturday},
 				'sun' => q{First Day of Week Is Sunday},
 				'thu' => q{First Day of Week Is Thursday},
 				'tue' => q{First Day of Week Is Tuesday},
 				'wed' => q{First Day of Week Is Wednesday},
 			},
 			'h0' => {
 				'hybrid' => q{Hybrid Language},
 			},
 			'hc' => {
 				'h11' => q{12 Hour System (0–11)},
 				'h12' => q{12 Hour System (1–12)},
 				'h23' => q{24 Hour System (0–23)},
 				'h24' => q{24 Hour System (1–24)},
 			},
 			'i0' => {
 				'handwrit' => q{Handwriting Input Method},
 				'pinyin' => q{Pinyin Input Method},
 				'und' => q{Unspecified Input Method},
 				'wubi' => q{Wubi Input Method},
 			},
 			'k0' => {
 				'101key' => q{101-Key Keyboard},
 				'102key' => q{102-Key Keyboard},
 				'600dpi' => q{600 dpi Keyboard},
 				'768dpi' => q{768 dpi Keyboard},
 				'android' => q{Android Keyboard},
 				'azerty' => q{AZERTY-Based Keyboard},
 				'chromeos' => q{ChromeOS Keyboard},
 				'colemak' => q{Colemak Keyboard},
 				'dvorak' => q{Dvorak Keyboard},
 				'dvorakl' => q{Dvorak Left-Handed Keyboard},
 				'dvorakr' => q{Dvorak Right-Handed Keyboard},
 				'el220' => q{Greek 220 Keyboard},
 				'el319' => q{Greek 319 Keyboard},
 				'extended' => q{Keyboard With Many Extra Characters},
 				'googlevk' => q{Google Virtual Keyboard},
 				'isiri' => q{Persian ISIRI Keyboard},
 				'legacy' => q{Legacy Keyboard},
 				'lt1205' => q{Lithuanian LST 1205 Keyboard},
 				'lt1582' => q{Lithuanian LST 1582 Keyboard},
 				'nutaaq' => q{Inuktitut Nutaaq Keyboard},
 				'osx' => q{macOS Keyboard},
 				'patta' => q{Thai Pattachote Keyboard},
 				'qwerty' => q{QWERTY-Based Keyboard},
 				'qwertz' => q{QWERTZ-Based Keyboard},
 				'ta99' => q{Tamil 99 Keyboard},
 				'und' => q{Unspecified Keyboard},
 				'var' => q{Keyboard Variant},
 				'viqr' => q{Vietnamese VIQR Keyboard},
 				'windows' => q{Windows Keyboard},
 			},
 			'kr' => {
 				'currency' => q{Currency},
 				'digit' => q{Digits},
 				'punct' => q{Punctuation},
 				'space' => q{Whitespace},
 				'symbol' => q{Symbol},
 			},
 			'kv' => {
 				'currency' => q{Ignore Symbols affects spaces, punctuation, all symbols},
 				'punct' => q{Ignore Symbols affects spaces and punctuation only},
 				'space' => q{Ignore Symbols affects spaces only},
 				'symbol' => q{Ignore Symbols affects spaces, punctuation, non-currency symbols},
 			},
 			'lb' => {
 				'loose' => q{Loose Line Break Style},
 				'normal' => q{Normal Line Break Style},
 				'strict' => q{Strict Line Break Style},
 			},
 			'lw' => {
 				'breakall' => q{Allow Line Breaks In All Words},
 				'keepall' => q{Prevent Line Breaks In All Words},
 				'normal' => q{Normal Line Breaks For Words},
 			},
 			'm0' => {
 				'alaloc' => q{US ALA-LOC Transliteration},
 				'bgn' => q{US BGN Transliteration},
 				'buckwalt' => q{Buckwalter Arabic Transliteration},
 				'din' => q{German DIN Transliteration},
 				'gost' => q{CIS GOST Transliteration},
 				'iso' => q{ISO Transliteration},
 				'mcst' => q{Korean MCST Transliteration},
 				'mns' => q{Mongolian National Standard Transliteration},
 				'prprname' => q{Personal Name Transliteration Variant},
 				'satts' => q{Standard Arabic Technical Transliteration},
 				'ungegn' => q{UN GEGN Transliteration},
 			},
 			'ms' => {
 				'metric' => q{Metric System},
 				'uksystem' => q{Imperial Measurement System},
 				'ussystem' => q{US Measurement System},
 			},
 			'numbers' => {
 				'adlm' => q{Adlam Digits},
 				'ahom' => q{Ahom Digits},
 				'arab' => q{Arabic-Indic Digits},
 				'arabext' => q{X Arabic-Indic Digits},
 				'armn' => q{Armenian Numerals},
 				'armnlow' => q{Armenian Lowercase Numerals},
 				'bali' => q{Balinese Digits},
 				'beng' => q{Bangla Digits},
 				'bhks' => q{Bhaiksuki Digits},
 				'brah' => q{Brahmi Digits},
 				'cakm' => q{Chakma Digits},
 				'cham' => q{Cham Digits},
 				'cyrl' => q{Cyrillic Numerals},
 				'deva' => q{Devanagari Digits},
 				'ethi' => q{Ethiopic Numerals},
 				'finance' => q{Financial Numerals},
 				'fullwide' => q{Full-Width Digits},
 				'geor' => q{Georgian Numerals},
 				'gonm' => q{Masaram Gondi digits},
 				'grek' => q{Greek Numerals},
 				'greklow' => q{Greek Lowercase Numerals},
 				'gujr' => q{Gujarati Digits},
 				'guru' => q{Gurmukhi Digits},
 				'hanidays' => q{Chinese Calendar Day-of-Month Numerals},
 				'hanidec' => q{Chinese Decimal Numerals},
 				'hans' => q{Simplified Chinese Numerals},
 				'hansfin' => q{Simplified Chinese Financial Numerals},
 				'hant' => q{Traditional Chinese Numerals},
 				'hantfin' => q{Traditional Chinese Financial Numerals},
 				'hebr' => q{Hebrew Numerals},
 				'hmng' => q{Pahawh Hmong Digits},
 				'java' => q{Javanese Digits},
 				'jpan' => q{Japanese Numerals},
 				'jpanfin' => q{Japanese Financial Numerals},
 				'kali' => q{Kayah Li Digits},
 				'khmr' => q{Khmer Digits},
 				'knda' => q{Kannada Digits},
 				'lana' => q{Tai Tham Hora Digits},
 				'lanatham' => q{Tai Tham Tham Digits},
 				'laoo' => q{Lao Digits},
 				'latn' => q{Western Digits},
 				'lepc' => q{Lepcha Digits},
 				'limb' => q{Limbu Digits},
 				'mathbold' => q{Mathematical Bold Digits},
 				'mathdbl' => q{Mathematical Double-Struck Digits},
 				'mathmono' => q{Mathematical Monospace Digits},
 				'mathsanb' => q{Mathematical Sans-Serif Bold Digits},
 				'mathsans' => q{Mathematical Sans-Serif Digits},
 				'mlym' => q{Malayalam Digits},
 				'modi' => q{Modi Digits},
 				'mong' => q{Mongolian Digits},
 				'mroo' => q{Mro Digits},
 				'mtei' => q{Meetei Mayek Digits},
 				'mymr' => q{Myanmar Digits},
 				'mymrshan' => q{Myanmar Shan Digits},
 				'mymrtlng' => q{Myanmar Tai Laing Digits},
 				'native' => q{Native Digits},
 				'newa' => q{Newa Digits},
 				'nkoo' => q{N’Ko Digits},
 				'olck' => q{Ol Chiki Digits},
 				'orya' => q{Odia Digits},
 				'osma' => q{Osmanya Digits},
 				'roman' => q{Roman Numerals},
 				'romanlow' => q{Roman Lowercase Numerals},
 				'saur' => q{Saurashtra Digits},
 				'shrd' => q{Sharada Digits},
 				'sind' => q{Khudawadi Digits},
 				'sinh' => q{Sinhala Lith Digits},
 				'sora' => q{Sora Sompeng Digits},
 				'sund' => q{Sundanese Digits},
 				'takr' => q{Takri Digits},
 				'talu' => q{New Tai Lue Digits},
 				'taml' => q{Traditional Tamil Numerals},
 				'tamldec' => q{Tamil Digits},
 				'telu' => q{Telugu Digits},
 				'thai' => q{Thai Digits},
 				'tibt' => q{Tibetan Digits},
 				'tirh' => q{Tirhuta Digits},
 				'traditional' => q{Traditional Numerals},
 				'vaii' => q{Vai Digits},
 				'wara' => q{Warang Citi Digits},
 			},
 			's0' => {
 				'accents' => q{From Accented Characters To ASCII Sequence},
 				'ascii' => q{From ASCII},
 				'hex' => q{From Hexadecimal Codes},
 				'npinyin' => q{From Pinyin With Numeric Tones},
 				'publish' => q{From Publishing Punctuation To ASCII},
 				'zawgyi' => q{From Zawgyi Myanmar Encoding},
 			},
 			'ss' => {
 				'none' => q{Sentence Breaks Without Abbreviation Handling},
 				'standard' => q{Suppress Sentence Breaks After Standard Abbreviations},
 			},
 			't0' => {
 				'und' => q{Unspecified Machine Translation},
 			},
 			'va' => {
 				'posix' => q{POSIX Compliant Locale},
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
			'metric' => q{Metric},
 			'UK' => q{UK},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Language: {0}',
 			'script' => 'Script: {0}',
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
			auxiliary => qr{[á à ă â å ä ã ā æ ç é è ĕ ê ë ē í ì ĭ î ï ī ñ ó ò ŏ ô ö ø ō œ ú ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c d e f g h i j k l m n o p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
	default		=> qq{“},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					'arc-minute' => {
						'name' => q(arcminutes),
						'one' => q({0} arcminute),
						'other' => q({0} arcminutes),
					},
					'arc-second' => {
						'name' => q(arcseconds),
						'one' => q({0} arcsecond),
						'other' => q({0} arcseconds),
					},
					'astronomical-unit' => {
						'name' => q(astronomical units),
						'one' => q({0} astronomical unit),
						'other' => q({0} astronomical units),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					'carat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					'celsius' => {
						'name' => q(degrees Celsius),
						'one' => q({0} degree Celsius),
						'other' => q({0} degrees Celsius),
					},
					'centiliter' => {
						'name' => q(centiliters),
						'one' => q({0} centiliter),
						'other' => q({0} centiliters),
					},
					'centimeter' => {
						'name' => q(centimeters),
						'one' => q({0} centimeter),
						'other' => q({0} centimeters),
						'per' => q({0} per centimeter),
					},
					'century' => {
						'name' => q(centuries),
						'one' => q({0} century),
						'other' => q({0} centuries),
					},
					'coordinate' => {
						'east' => q({0} east),
						'north' => q({0} north),
						'south' => q({0} south),
						'west' => q({0} west),
					},
					'cubic-centimeter' => {
						'name' => q(cubic centimeters),
						'one' => q({0} cubic centimeter),
						'other' => q({0} cubic centimeters),
						'per' => q({0} per cubic centimeter),
					},
					'cubic-foot' => {
						'name' => q(cubic feet),
						'one' => q({0} cubic foot),
						'other' => q({0} cubic feet),
					},
					'cubic-inch' => {
						'name' => q(cubic inches),
						'one' => q({0} cubic inch),
						'other' => q({0} cubic inches),
					},
					'cubic-kilometer' => {
						'name' => q(cubic kilometers),
						'one' => q({0} cubic kilometer),
						'other' => q({0} cubic kilometers),
					},
					'cubic-meter' => {
						'name' => q(cubic meters),
						'one' => q({0} cubic meter),
						'other' => q({0} cubic meters),
						'per' => q({0} per cubic meter),
					},
					'cubic-mile' => {
						'name' => q(cubic miles),
						'one' => q({0} cubic mile),
						'other' => q({0} cubic miles),
					},
					'cubic-yard' => {
						'name' => q(cubic yards),
						'one' => q({0} cubic yard),
						'other' => q({0} cubic yards),
					},
					'cup' => {
						'name' => q(cups),
						'one' => q({0} cup),
						'other' => q({0} cups),
					},
					'cup-metric' => {
						'name' => q(metric cups),
						'one' => q({0} metric cup),
						'other' => q({0} metric cups),
					},
					'day' => {
						'name' => q(days),
						'one' => q({0} day),
						'other' => q({0} days),
						'per' => q({0} per day),
					},
					'deciliter' => {
						'name' => q(deciliters),
						'one' => q({0} deciliter),
						'other' => q({0} deciliters),
					},
					'decimeter' => {
						'name' => q(decimeters),
						'one' => q({0} decimeter),
						'other' => q({0} decimeters),
					},
					'degree' => {
						'name' => q(degrees),
						'one' => q({0} degree),
						'other' => q({0} degrees),
					},
					'fahrenheit' => {
						'name' => q(degrees Fahrenheit),
						'one' => q({0} degree Fahrenheit),
						'other' => q({0} degrees Fahrenheit),
					},
					'fathom' => {
						'name' => q(fathoms),
						'one' => q({0} fathom),
						'other' => q({0} fathoms),
					},
					'fluid-ounce' => {
						'name' => q(fluid ounces),
						'one' => q({0} fluid ounce),
						'other' => q({0} fluid ounces),
					},
					'foodcalorie' => {
						'name' => q(Calories),
						'one' => q({0} Calorie),
						'other' => q({0} Calories),
					},
					'foot' => {
						'name' => q(feet),
						'one' => q({0} foot),
						'other' => q({0} feet),
						'per' => q({0} per foot),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} g-force),
						'other' => q({0} g-force),
					},
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} per gallon),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gallons),
						'one' => q({0} Imp. gallon),
						'other' => q({0} Imp. gallons),
						'per' => q({0} per Imp. gallon),
					},
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					'gigabyte' => {
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					'gram' => {
						'name' => q(grams),
						'one' => q({0} gram),
						'other' => q({0} grams),
						'per' => q({0} per gram),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					'hectoliter' => {
						'name' => q(hectoliters),
						'one' => q({0} hectoliter),
						'other' => q({0} hectoliters),
					},
					'hectopascal' => {
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(horsepower),
						'one' => q({0} horsepower),
						'other' => q({0} horsepower),
					},
					'hour' => {
						'name' => q(hours),
						'one' => q({0} hour),
						'other' => q({0} hours),
						'per' => q({0} per hour),
					},
					'inch' => {
						'name' => q(inches),
						'one' => q({0} inch),
						'other' => q({0} inches),
						'per' => q({0} per inch),
					},
					'inch-hg' => {
						'name' => q(inches of mercury),
						'one' => q({0} inch of mercury),
						'other' => q({0} inches of mercury),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(karats),
						'one' => q({0} karat),
						'other' => q({0} karats),
					},
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					'kilocalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					'kilogram' => {
						'name' => q(kilograms),
						'one' => q({0} kilogram),
						'other' => q({0} kilograms),
						'per' => q({0} per kilogram),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					'kilometer' => {
						'name' => q(kilometers),
						'one' => q({0} kilometer),
						'other' => q({0} kilometers),
						'per' => q({0} per kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometers per hour),
						'one' => q({0} kilometer per hour),
						'other' => q({0} kilometers per hour),
					},
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(kilowatt-hours),
						'one' => q({0} kilowatt hour),
						'other' => q({0} kilowatt-hours),
					},
					'knot' => {
						'name' => q(knots),
						'one' => q({0} knot),
						'other' => q({0} knots),
					},
					'light-year' => {
						'name' => q(light years),
						'one' => q({0} light year),
						'other' => q({0} light years),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} liter),
						'other' => q({0} liters),
						'per' => q({0} per liter),
					},
					'liter-per-100kilometers' => {
						'name' => q(liters per 100 kilometers),
						'one' => q({0} liter per 100 kilometers),
						'other' => q({0} liters per 100 kilometers),
					},
					'liter-per-kilometer' => {
						'name' => q(liters per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liters per kilometer),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					'megabyte' => {
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megaliters),
						'one' => q({0} megaliter),
						'other' => q({0} megaliters),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					'meter' => {
						'name' => q(meters),
						'one' => q({0} meter),
						'other' => q({0} meters),
						'per' => q({0} per meter),
					},
					'meter-per-second' => {
						'name' => q(meters per second),
						'one' => q({0} meter per second),
						'other' => q({0} meters per second),
					},
					'meter-per-second-squared' => {
						'name' => q(meters per second squared),
						'one' => q({0} meter per second squared),
						'other' => q({0} meters per second squared),
					},
					'metric-ton' => {
						'name' => q(metric tons),
						'one' => q({0} metric ton),
						'other' => q({0} metric tons),
					},
					'microgram' => {
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					'micrometer' => {
						'name' => q(micrometers),
						'one' => q({0} micrometer),
						'other' => q({0} micrometers),
					},
					'microsecond' => {
						'name' => q(microseconds),
						'one' => q({0} microsecond),
						'other' => q({0} microseconds),
					},
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					'mile-per-gallon' => {
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles per Imp. gallon),
						'one' => q({0} mile per Imp. gallon),
						'other' => q({0} miles per Imp. gallon),
					},
					'mile-per-hour' => {
						'name' => q(miles per hour),
						'one' => q({0} mile per hour),
						'other' => q({0} miles per hour),
					},
					'mile-scandinavian' => {
						'name' => q(mile-scandinavian),
						'one' => q({0} mile-scandinavian),
						'other' => q({0} miles-scandinavian),
					},
					'milliampere' => {
						'name' => q(milliamperes),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperes),
					},
					'millibar' => {
						'name' => q(millibars),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					'milligram' => {
						'name' => q(milligrams),
						'one' => q({0} milligram),
						'other' => q({0} milligrams),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrams per deciliter),
						'one' => q({0} milligram per deciliter),
						'other' => q({0} milligrams per deciliter),
					},
					'milliliter' => {
						'name' => q(milliliters),
						'one' => q({0} milliliter),
						'other' => q({0} milliliters),
					},
					'millimeter' => {
						'name' => q(millimeters),
						'one' => q({0} millimeter),
						'other' => q({0} millimeters),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimeters of mercury),
						'one' => q({0} millimeter of mercury),
						'other' => q({0} millimeters of mercury),
					},
					'millimole-per-liter' => {
						'name' => q(millimoles per liter),
						'one' => q({0} millimole per liter),
						'other' => q({0} millimoles per liter),
					},
					'millisecond' => {
						'name' => q(milliseconds),
						'one' => q({0} millisecond),
						'other' => q({0} milliseconds),
					},
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					'minute' => {
						'name' => q(minutes),
						'one' => q({0} minute),
						'other' => q({0} minutes),
						'per' => q({0} per minute),
					},
					'month' => {
						'name' => q(months),
						'one' => q({0} month),
						'other' => q({0} months),
						'per' => q({0} per month),
					},
					'nanometer' => {
						'name' => q(nanometers),
						'one' => q({0} nanometer),
						'other' => q({0} nanometers),
					},
					'nanosecond' => {
						'name' => q(nanoseconds),
						'one' => q({0} nanosecond),
						'other' => q({0} nanoseconds),
					},
					'nautical-mile' => {
						'name' => q(nautical miles),
						'one' => q({0} nautical mile),
						'other' => q({0} nautical miles),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(ounces),
						'one' => q({0} ounce),
						'other' => q({0} ounces),
						'per' => q({0} per ounce),
					},
					'ounce-troy' => {
						'name' => q(troy ounces),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounces),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(parts per million),
						'one' => q({0} part per million),
						'other' => q({0} parts per million),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(picometers),
						'one' => q({0} picometer),
						'other' => q({0} picometers),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					'pint-metric' => {
						'name' => q(metric pints),
						'one' => q({0} metric pint),
						'other' => q({0} metric pints),
					},
					'point' => {
						'name' => q(points),
						'one' => q({0} point),
						'other' => q({0} points),
					},
					'pound' => {
						'name' => q(pounds),
						'one' => q({0} pound),
						'other' => q({0} pounds),
						'per' => q({0} per pound),
					},
					'pound-per-square-inch' => {
						'name' => q(pounds per square inch),
						'one' => q({0} pound per square inch),
						'other' => q({0} pounds per square inch),
					},
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					'radian' => {
						'name' => q(radians),
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					'revolution' => {
						'name' => q(revolution),
						'one' => q({0} revolution),
						'other' => q({0} revolutions),
					},
					'second' => {
						'name' => q(seconds),
						'one' => q({0} second),
						'other' => q({0} seconds),
						'per' => q({0} per second),
					},
					'square-centimeter' => {
						'name' => q(square centimeters),
						'one' => q({0} square centimeter),
						'other' => q({0} square centimeters),
						'per' => q({0} per square centimeter),
					},
					'square-foot' => {
						'name' => q(square feet),
						'one' => q({0} square foot),
						'other' => q({0} square feet),
					},
					'square-inch' => {
						'name' => q(square inches),
						'one' => q({0} square inch),
						'other' => q({0} square inches),
						'per' => q({0} per square inch),
					},
					'square-kilometer' => {
						'name' => q(square kilometers),
						'one' => q({0} square kilometer),
						'other' => q({0} square kilometers),
						'per' => q({0} per square kilometer),
					},
					'square-meter' => {
						'name' => q(square meters),
						'one' => q({0} square meter),
						'other' => q({0} square meters),
						'per' => q({0} per square meter),
					},
					'square-mile' => {
						'name' => q(square miles),
						'one' => q({0} square mile),
						'other' => q({0} square miles),
						'per' => q({0} per square mile),
					},
					'square-yard' => {
						'name' => q(square yards),
						'one' => q({0} square yard),
						'other' => q({0} square yards),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					'tablespoon' => {
						'name' => q(tablespoons),
						'one' => q({0} tablespoon),
						'other' => q({0} tablespoons),
					},
					'teaspoon' => {
						'name' => q(teaspoons),
						'one' => q({0} teaspoon),
						'other' => q({0} teaspoons),
					},
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					'terabyte' => {
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					'ton' => {
						'name' => q(tons),
						'one' => q({0} ton),
						'other' => q({0} tons),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					'week' => {
						'name' => q(weeks),
						'one' => q({0} week),
						'other' => q({0} weeks),
						'per' => q({0} per week),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(years),
						'one' => q({0} year),
						'other' => q({0} years),
						'per' => q({0} per year),
					},
				},
				'narrow' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0}au),
						'other' => q({0}au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					'bushel' => {
						'name' => q(bushel),
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					'carat' => {
						'name' => q(carat),
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0}c),
						'other' => q({0}c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					'day' => {
						'name' => q(day),
						'one' => q({0}d),
						'other' => q({0}d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					'degree' => {
						'name' => q(deg),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fathom' => {
						'name' => q(fathom),
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0}G),
						'other' => q({0}Gs),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					'gram' => {
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hectare' => {
						'name' => q(hectare),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					'hour' => {
						'name' => q(hour),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'inch-hg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					'kilobyte' => {
						'name' => q(kByte),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}kph),
						'other' => q({0}kph),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					'light-year' => {
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					'liter' => {
						'name' => q(liter),
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					'megabyte' => {
						'name' => q(MByte),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0}µg),
						'other' => q({0}µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0}µm),
						'other' => q({0}µm),
					},
					'microsecond' => {
						'name' => q(μsec),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					'mile-per-hour' => {
						'name' => q(mi/hr),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(msec),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'month' => {
						'name' => q(month),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					'pint-metric' => {
						'name' => q(pt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					'point' => {
						'name' => q(pts),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					'second' => {
						'name' => q(sec),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					'terabyte' => {
						'name' => q(TByte),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(wk),
						'one' => q({0}w),
						'other' => q({0}w),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(yr),
						'one' => q({0}y),
						'other' => q({0}y),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amps),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0} arcsec),
						'other' => q({0} arcsecs),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(carats),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(deg. C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					'cubic-foot' => {
						'name' => q(feet³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(inches³),
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
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yards³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cups),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(days),
						'one' => q({0} day),
						'other' => q({0} days),
						'per' => q({0}/d),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(degrees),
						'one' => q({0} deg),
						'other' => q({0} deg),
					},
					'fahrenheit' => {
						'name' => q(deg. F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fathoms),
						'one' => q({0} ftm),
						'other' => q({0} ftm),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(feet),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(g-force),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'one' => q({0} gal Imp.),
						'other' => q({0} gal Imp.),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q({0} GB),
						'other' => q({0} GB),
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
						'name' => q(grams),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
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
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(hours),
						'one' => q({0} hr),
						'other' => q({0} hr),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(inches),
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
						'name' => q(joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(karats),
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
						'name' => q(kByte),
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
						'name' => q(kilojoule),
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
						'name' => q(km/hour),
						'one' => q({0} kph),
						'other' => q({0} kph),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-hour),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(light yrs),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(liters),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(liters/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MByte),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(meters/sec),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(meters/sec²),
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
						'name' => q(µmeters),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsecs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles/gal Imp.),
						'one' => q({0} mpg Imp.),
						'other' => q({0} mpg Imp.),
					},
					'mile-per-hour' => {
						'name' => q(miles/hour),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(milliamps),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
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
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(millimol/liter),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(millisecs),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(mins),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(months),
						'one' => q({0} mth),
						'other' => q({0} mths),
						'per' => q({0}/m),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosecs),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz troy),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsecs),
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
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(points),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(pounds),
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
						'name' => q(qts),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radians),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(secs),
						'one' => q({0} sec),
						'other' => q({0} sec),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(sq feet),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					'square-inch' => {
						'name' => q(inches²),
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
						'name' => q(meters²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(sq miles),
						'one' => q({0} sq mi),
						'other' => q({0} sq mi),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yards²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TByte),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tons),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(weeks),
						'one' => q({0} wk),
						'other' => q({0} wks),
						'per' => q({0}/w),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(years),
						'one' => q({0} yr),
						'other' => q({0} yrs),
						'per' => q({0}/y),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
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
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 thousand',
					'other' => '0 thousand',
				},
				'10000' => {
					'one' => '00 thousand',
					'other' => '00 thousand',
				},
				'100000' => {
					'one' => '000 thousand',
					'other' => '000 thousand',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 million',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 million',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 million',
				},
				'1000000000' => {
					'one' => '0 billion',
					'other' => '0 billion',
				},
				'10000000000' => {
					'one' => '00 billion',
					'other' => '00 billion',
				},
				'100000000000' => {
					'one' => '000 billion',
					'other' => '000 billion',
				},
				'1000000000000' => {
					'one' => '0 trillion',
					'other' => '0 trillion',
				},
				'10000000000000' => {
					'one' => '00 trillion',
					'other' => '00 trillion',
				},
				'100000000000000' => {
					'one' => '000 trillion',
					'other' => '000 trillion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0K',
					'other' => '0K',
				},
				'10000' => {
					'one' => '00K',
					'other' => '00K',
				},
				'100000' => {
					'one' => '000K',
					'other' => '000K',
				},
				'1000000' => {
					'one' => '0M',
					'other' => '0M',
				},
				'10000000' => {
					'one' => '00M',
					'other' => '00M',
				},
				'100000000' => {
					'one' => '000M',
					'other' => '000M',
				},
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
				},
				'1000000000000' => {
					'one' => '0T',
					'other' => '0T',
				},
				'10000000000000' => {
					'one' => '00T',
					'other' => '00T',
				},
				'100000000000000' => {
					'one' => '000T',
					'other' => '000T',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '#,##0%',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(Andorran Peseta),
				'one' => q(Andorran peseta),
				'other' => q(Andorran pesetas),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(United Arab Emirates Dirham),
				'one' => q(UAE dirham),
				'other' => q(UAE dirhams),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghan Afghani \(1927–2002\)),
				'one' => q(Afghan afghani \(1927–2002\)),
				'other' => q(Afghan afghanis \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghan Afghani),
				'one' => q(Afghan Afghani),
				'other' => q(Afghan Afghanis),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albanian Lek \(1946–1965\)),
				'one' => q(Albanian lek \(1946–1965\)),
				'other' => q(Albanian lekë \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanian Lek),
				'one' => q(Albanian lek),
				'other' => q(Albanian lekë),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armenian Dram),
				'one' => q(Armenian dram),
				'other' => q(Armenian drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Netherlands Antillean Guilder),
				'one' => q(Netherlands Antillean guilder),
				'other' => q(Netherlands Antillean guilders),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolan Kwanza),
				'one' => q(Angolan kwanza),
				'other' => q(Angolan kwanzas),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolan Kwanza \(1977–1991\)),
				'one' => q(Angolan kwanza \(1977–1991\)),
				'other' => q(Angolan kwanzas \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolan New Kwanza \(1990–2000\)),
				'one' => q(Angolan new kwanza \(1990–2000\)),
				'other' => q(Angolan new kwanzas \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolan Readjusted Kwanza \(1995–1999\)),
				'one' => q(Angolan readjusted kwanza \(1995–1999\)),
				'other' => q(Angolan readjusted kwanzas \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentine Austral),
				'one' => q(Argentine austral),
				'other' => q(Argentine australs),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Argentine Peso Ley \(1970–1983\)),
				'one' => q(Argentine peso ley \(1970–1983\)),
				'other' => q(Argentine pesos ley \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Argentine Peso \(1881–1970\)),
				'one' => q(Argentine peso \(1881–1970\)),
				'other' => q(Argentine pesos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentine Peso \(1983–1985\)),
				'one' => q(Argentine peso \(1983–1985\)),
				'other' => q(Argentine pesos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentine Peso),
				'one' => q(Argentine peso),
				'other' => q(Argentine pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Austrian Schilling),
				'one' => q(Austrian schilling),
				'other' => q(Austrian schillings),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Australian Dollar),
				'one' => q(Australian dollar),
				'other' => q(Australian dollars),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruban Florin),
				'one' => q(Aruban florin),
				'other' => q(Aruban florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azerbaijani Manat \(1993–2006\)),
				'one' => q(Azerbaijani manat \(1993–2006\)),
				'other' => q(Azerbaijani manats \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Azerbaijani Manat),
				'one' => q(Azerbaijani manat),
				'other' => q(Azerbaijani manats),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Dinar \(1992–1994\)),
				'one' => q(Bosnia-Herzegovina dinar \(1992–1994\)),
				'other' => q(Bosnia-Herzegovina dinars \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina Convertible Mark),
				'one' => q(Bosnia-Herzegovina convertible mark),
				'other' => q(Bosnia-Herzegovina convertible marks),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Bosnia-Herzegovina New Dinar \(1994–1997\)),
				'one' => q(Bosnia-Herzegovina new dinar \(1994–1997\)),
				'other' => q(Bosnia-Herzegovina new dinars \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbadian Dollar),
				'one' => q(Barbadian dollar),
				'other' => q(Barbadian dollars),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Bangladeshi Taka),
				'one' => q(Bangladeshi taka),
				'other' => q(Bangladeshi takas),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belgian Franc \(convertible\)),
				'one' => q(Belgian franc \(convertible\)),
				'other' => q(Belgian francs \(convertible\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belgian Franc),
				'one' => q(Belgian franc),
				'other' => q(Belgian francs),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belgian Franc \(financial\)),
				'one' => q(Belgian franc \(financial\)),
				'other' => q(Belgian francs \(financial\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgarian Hard Lev),
				'one' => q(Bulgarian hard lev),
				'other' => q(Bulgarian hard leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Bulgarian Socialist Lev),
				'one' => q(Bulgarian socialist lev),
				'other' => q(Bulgarian socialist leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgarian Lev),
				'one' => q(Bulgarian lev),
				'other' => q(Bulgarian leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Bulgarian Lev \(1879–1952\)),
				'one' => q(Bulgarian lev \(1879–1952\)),
				'other' => q(Bulgarian leva \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahraini Dinar),
				'one' => q(Bahraini dinar),
				'other' => q(Bahraini dinars),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundian Franc),
				'one' => q(Burundian franc),
				'other' => q(Burundian francs),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermudan Dollar),
				'one' => q(Bermudan dollar),
				'other' => q(Bermudan dollars),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei Dollar),
				'one' => q(Brunei dollar),
				'other' => q(Brunei dollars),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivian Boliviano),
				'one' => q(Bolivian boliviano),
				'other' => q(Bolivian bolivianos),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Bolivian Boliviano \(1863–1963\)),
				'one' => q(Bolivian boliviano \(1863–1963\)),
				'other' => q(Bolivian bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivian Peso),
				'one' => q(Bolivian peso),
				'other' => q(Bolivian pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivian Mvdol),
				'one' => q(Bolivian mvdol),
				'other' => q(Bolivian mvdols),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brazilian New Cruzeiro \(1967–1986\)),
				'one' => q(Brazilian new cruzeiro \(1967–1986\)),
				'other' => q(Brazilian new cruzeiros \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brazilian Cruzado \(1986–1989\)),
				'one' => q(Brazilian cruzado \(1986–1989\)),
				'other' => q(Brazilian cruzados \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brazilian Cruzeiro \(1990–1993\)),
				'one' => q(Brazilian cruzeiro \(1990–1993\)),
				'other' => q(Brazilian cruzeiros \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Brazilian Real),
				'one' => q(Brazilian real),
				'other' => q(Brazilian reals),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brazilian New Cruzado \(1989–1990\)),
				'one' => q(Brazilian new cruzado \(1989–1990\)),
				'other' => q(Brazilian new cruzados \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazilian Cruzeiro \(1993–1994\)),
				'one' => q(Brazilian cruzeiro \(1993–1994\)),
				'other' => q(Brazilian cruzeiros \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brazilian Cruzeiro \(1942–1967\)),
				'one' => q(Brazilian cruzeiro \(1942–1967\)),
				'other' => q(Brazilian cruzeiros \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahamian Dollar),
				'one' => q(Bahamian dollar),
				'other' => q(Bahamian dollars),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Bhutanese Ngultrum),
				'one' => q(Bhutanese ngultrum),
				'other' => q(Bhutanese ngultrums),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmese Kyat),
				'one' => q(Burmese kyat),
				'other' => q(Burmese kyats),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanan Pula),
				'one' => q(Botswanan pula),
				'other' => q(Botswanan pulas),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarusian Ruble \(1994–1999\)),
				'one' => q(Belarusian ruble \(1994–1999\)),
				'other' => q(Belarusian rubles \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Belarusian Ruble),
				'one' => q(Belarusian ruble),
				'other' => q(Belarusian rubles),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Belarusian Ruble \(2000–2016\)),
				'one' => q(Belarusian ruble \(2000–2016\)),
				'other' => q(Belarusian rubles \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize Dollar),
				'one' => q(Belize dollar),
				'other' => q(Belize dollars),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Canadian Dollar),
				'one' => q(Canadian dollar),
				'other' => q(Canadian dollars),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Congolese Franc),
				'one' => q(Congolese franc),
				'other' => q(Congolese francs),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Euro),
				'one' => q(WIR euro),
				'other' => q(WIR euros),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Swiss Franc),
				'one' => q(Swiss franc),
				'other' => q(Swiss francs),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Franc),
				'one' => q(WIR franc),
				'other' => q(WIR francs),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Chilean Escudo),
				'one' => q(Chilean escudo),
				'other' => q(Chilean escudos),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chilean Unit of Account \(UF\)),
				'one' => q(Chilean unit of account \(UF\)),
				'other' => q(Chilean units of account \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chilean Peso),
				'one' => q(Chilean peso),
				'other' => q(Chilean pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Chinese Yuan \(offshore\)),
				'one' => q(Chinese yuan \(offshore\)),
				'other' => q(Chinese yuan \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Chinese People’s Bank Dollar),
				'one' => q(Chinese People’s Bank dollar),
				'other' => q(Chinese People’s Bank dollars),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Chinese Yuan),
				'one' => q(Chinese yuan),
				'other' => q(Chinese yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Colombian Peso),
				'one' => q(Colombian peso),
				'other' => q(Colombian pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Colombian Real Value Unit),
				'one' => q(Colombian real value unit),
				'other' => q(Colombian real value units),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa Rican Colón),
				'one' => q(Costa Rican colón),
				'other' => q(Costa Rican colóns),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbian Dinar \(2002–2006\)),
				'one' => q(Serbian dinar \(2002–2006\)),
				'other' => q(Serbian dinars \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Czechoslovak Hard Koruna),
				'one' => q(Czechoslovak hard koruna),
				'other' => q(Czechoslovak hard korunas),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Cuban Convertible Peso),
				'one' => q(Cuban convertible peso),
				'other' => q(Cuban convertible pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Cuban Peso),
				'one' => q(Cuban peso),
				'other' => q(Cuban pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Cape Verdean Escudo),
				'one' => q(Cape Verdean escudo),
				'other' => q(Cape Verdean escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Cypriot Pound),
				'one' => q(Cypriot pound),
				'other' => q(Cypriot pounds),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Czech Koruna),
				'one' => q(Czech koruna),
				'other' => q(Czech korunas),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(East German Mark),
				'one' => q(East German mark),
				'other' => q(East German marks),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(German Mark),
				'one' => q(German mark),
				'other' => q(German marks),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Djiboutian Franc),
				'one' => q(Djiboutian franc),
				'other' => q(Djiboutian francs),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Danish Krone),
				'one' => q(Danish krone),
				'other' => q(Danish kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominican Peso),
				'one' => q(Dominican peso),
				'other' => q(Dominican pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algerian Dinar),
				'one' => q(Algerian dinar),
				'other' => q(Algerian dinars),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadorian Sucre),
				'one' => q(Ecuadorian sucre),
				'other' => q(Ecuadorian sucres),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ecuadorian Unit of Constant Value),
				'one' => q(Ecuadorian unit of constant value),
				'other' => q(Ecuadorian units of constant value),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estonian Kroon),
				'one' => q(Estonian kroon),
				'other' => q(Estonian kroons),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptian Pound),
				'one' => q(Egyptian pound),
				'other' => q(Egyptian pounds),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritrean Nakfa),
				'one' => q(Eritrean nakfa),
				'other' => q(Eritrean nakfas),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spanish Peseta \(A account\)),
				'one' => q(Spanish peseta \(A account\)),
				'other' => q(Spanish pesetas \(A account\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spanish Peseta \(convertible account\)),
				'one' => q(Spanish peseta \(convertible account\)),
				'other' => q(Spanish pesetas \(convertible account\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spanish Peseta),
				'one' => q(Spanish peseta),
				'other' => q(Spanish pesetas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopian Birr),
				'one' => q(Ethiopian birr),
				'other' => q(Ethiopian birrs),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnish Markka),
				'one' => q(Finnish markka),
				'other' => q(Finnish markkas),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fijian Dollar),
				'one' => q(Fijian dollar),
				'other' => q(Fijian dollars),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland Islands Pound),
				'one' => q(Falkland Islands pound),
				'other' => q(Falkland Islands pounds),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(French Franc),
				'one' => q(French franc),
				'other' => q(French francs),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(British Pound),
				'one' => q(British pound),
				'other' => q(British pounds),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgian Kupon Larit),
				'one' => q(Georgian kupon larit),
				'other' => q(Georgian kupon larits),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgian Lari),
				'one' => q(Georgian lari),
				'other' => q(Georgian laris),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanaian Cedi \(1979–2007\)),
				'one' => q(Ghanaian cedi \(1979–2007\)),
				'other' => q(Ghanaian cedis \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaian Cedi),
				'one' => q(Ghanaian cedi),
				'other' => q(Ghanaian cedis),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar Pound),
				'one' => q(Gibraltar pound),
				'other' => q(Gibraltar pounds),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambian Dalasi),
				'one' => q(Gambian dalasi),
				'other' => q(Gambian dalasis),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinean Franc),
				'one' => q(Guinean franc),
				'other' => q(Guinean francs),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinean Syli),
				'one' => q(Guinean syli),
				'other' => q(Guinean sylis),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Equatorial Guinean Ekwele),
				'one' => q(Equatorial Guinean ekwele),
				'other' => q(Equatorial Guinean ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Greek Drachma),
				'one' => q(Greek drachma),
				'other' => q(Greek drachmas),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemalan Quetzal),
				'one' => q(Guatemalan quetzal),
				'other' => q(Guatemalan quetzals),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portuguese Guinea Escudo),
				'one' => q(Portuguese Guinea escudo),
				'other' => q(Portuguese Guinea escudos),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau Peso),
				'one' => q(Guinea-Bissau peso),
				'other' => q(Guinea-Bissau pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyanaese Dollar),
				'one' => q(Guyanaese dollar),
				'other' => q(Guyanaese dollars),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hong Kong Dollar),
				'one' => q(Hong Kong dollar),
				'other' => q(Hong Kong dollars),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduran Lempira),
				'one' => q(Honduran lempira),
				'other' => q(Honduran lempiras),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Croatian Dinar),
				'one' => q(Croatian dinar),
				'other' => q(Croatian dinars),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Croatian Kuna),
				'one' => q(Croatian kuna),
				'other' => q(Croatian kunas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitian Gourde),
				'one' => q(Haitian gourde),
				'other' => q(Haitian gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Hungarian Forint),
				'one' => q(Hungarian forint),
				'other' => q(Hungarian forints),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Indonesian Rupiah),
				'one' => q(Indonesian rupiah),
				'other' => q(Indonesian rupiahs),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irish Pound),
				'one' => q(Irish pound),
				'other' => q(Irish pounds),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israeli Pound),
				'one' => q(Israeli pound),
				'other' => q(Israeli pounds),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Israeli Shekel \(1980–1985\)),
				'one' => q(Israeli shekel \(1980–1985\)),
				'other' => q(Israeli shekels \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Israeli New Shekel),
				'one' => q(Israeli new shekel),
				'other' => q(Israeli new shekels),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Indian Rupee),
				'one' => q(Indian rupee),
				'other' => q(Indian rupees),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Iraqi Dinar),
				'one' => q(Iraqi dinar),
				'other' => q(Iraqi dinars),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Iranian Rial),
				'one' => q(Iranian rial),
				'other' => q(Iranian rials),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Icelandic Króna \(1918–1981\)),
				'one' => q(Icelandic króna \(1918–1981\)),
				'other' => q(Icelandic krónur \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Icelandic Króna),
				'one' => q(Icelandic króna),
				'other' => q(Icelandic krónur),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italian Lira),
				'one' => q(Italian lira),
				'other' => q(Italian liras),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaican Dollar),
				'one' => q(Jamaican dollar),
				'other' => q(Jamaican dollars),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordanian Dinar),
				'one' => q(Jordanian dinar),
				'other' => q(Jordanian dinars),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanese Yen),
				'one' => q(Japanese yen),
				'other' => q(Japanese yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenyan Shilling),
				'one' => q(Kenyan shilling),
				'other' => q(Kenyan shillings),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kyrgystani Som),
				'one' => q(Kyrgystani som),
				'other' => q(Kyrgystani soms),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Cambodian Riel),
				'one' => q(Cambodian riel),
				'other' => q(Cambodian riels),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Comorian Franc),
				'one' => q(Comorian franc),
				'other' => q(Comorian francs),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(North Korean Won),
				'one' => q(North Korean won),
				'other' => q(North Korean won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(South Korean Hwan \(1953–1962\)),
				'one' => q(South Korean hwan \(1953–1962\)),
				'other' => q(South Korean hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(South Korean Won \(1945–1953\)),
				'one' => q(South Korean won \(1945–1953\)),
				'other' => q(South Korean won \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(South Korean Won),
				'one' => q(South Korean won),
				'other' => q(South Korean won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwaiti Dinar),
				'one' => q(Kuwaiti dinar),
				'other' => q(Kuwaiti dinars),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Cayman Islands Dollar),
				'one' => q(Cayman Islands dollar),
				'other' => q(Cayman Islands dollars),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kazakhstani Tenge),
				'one' => q(Kazakhstani tenge),
				'other' => q(Kazakhstani tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Laotian Kip),
				'one' => q(Laotian kip),
				'other' => q(Laotian kips),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Lebanese Pound),
				'one' => q(Lebanese pound),
				'other' => q(Lebanese pounds),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Sri Lankan Rupee),
				'one' => q(Sri Lankan rupee),
				'other' => q(Sri Lankan rupees),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberian Dollar),
				'one' => q(Liberian dollar),
				'other' => q(Liberian dollars),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesotho Loti),
				'one' => q(Lesotho loti),
				'other' => q(Lesotho lotis),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Lithuanian Litas),
				'one' => q(Lithuanian litas),
				'other' => q(Lithuanian litai),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Lithuanian Talonas),
				'one' => q(Lithuanian talonas),
				'other' => q(Lithuanian talonases),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxembourgian Convertible Franc),
				'one' => q(Luxembourgian convertible franc),
				'other' => q(Luxembourgian convertible francs),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxembourgian Franc),
				'one' => q(Luxembourgian franc),
				'other' => q(Luxembourgian francs),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxembourg Financial Franc),
				'one' => q(Luxembourg financial franc),
				'other' => q(Luxembourg financial francs),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Latvian Lats),
				'one' => q(Latvian lats),
				'other' => q(Latvian lati),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvian Ruble),
				'one' => q(Latvian ruble),
				'other' => q(Latvian rubles),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libyan Dinar),
				'one' => q(Libyan dinar),
				'other' => q(Libyan dinars),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Moroccan Dirham),
				'one' => q(Moroccan dirham),
				'other' => q(Moroccan dirhams),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Moroccan Franc),
				'one' => q(Moroccan franc),
				'other' => q(Moroccan francs),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monegasque Franc),
				'one' => q(Monegasque franc),
				'other' => q(Monegasque francs),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Moldovan Cupon),
				'one' => q(Moldovan cupon),
				'other' => q(Moldovan cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldovan Leu),
				'one' => q(Moldovan leu),
				'other' => q(Moldovan lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Malagasy Ariary),
				'one' => q(Malagasy ariary),
				'other' => q(Malagasy ariaries),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Malagasy Franc),
				'one' => q(Malagasy franc),
				'other' => q(Malagasy francs),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Macedonian Denar),
				'one' => q(Macedonian denar),
				'other' => q(Macedonian denari),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Macedonian Denar \(1992–1993\)),
				'one' => q(Macedonian denar \(1992–1993\)),
				'other' => q(Macedonian denari \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malian Franc),
				'one' => q(Malian franc),
				'other' => q(Malian francs),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Myanmar Kyat),
				'one' => q(Myanmar kyat),
				'other' => q(Myanmar kyats),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Mongolian Tugrik),
				'one' => q(Mongolian tugrik),
				'other' => q(Mongolian tugriks),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Macanese Pataca),
				'one' => q(Macanese pataca),
				'other' => q(Macanese patacas),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritanian Ouguiya),
				'one' => q(Mauritanian ouguiya),
				'other' => q(Mauritanian ouguiyas),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltese Lira),
				'one' => q(Maltese lira),
				'other' => q(Maltese lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltese Pound),
				'one' => q(Maltese pound),
				'other' => q(Maltese pounds),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritian Rupee),
				'one' => q(Mauritian rupee),
				'other' => q(Mauritian rupees),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Maldivian Rupee \(1947–1981\)),
				'one' => q(Maldivian rupee \(1947–1981\)),
				'other' => q(Maldivian rupees \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Maldivian Rufiyaa),
				'one' => q(Maldivian rufiyaa),
				'other' => q(Maldivian rufiyaas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawian Kwacha),
				'one' => q(Malawian kwacha),
				'other' => q(Malawian kwachas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Mexican Peso),
				'one' => q(Mexican peso),
				'other' => q(Mexican pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexican Silver Peso \(1861–1992\)),
				'one' => q(Mexican silver peso \(1861–1992\)),
				'other' => q(Mexican silver pesos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexican Investment Unit),
				'one' => q(Mexican investment unit),
				'other' => q(Mexican investment units),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Malaysian Ringgit),
				'one' => q(Malaysian ringgit),
				'other' => q(Malaysian ringgits),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambican Escudo),
				'one' => q(Mozambican escudo),
				'other' => q(Mozambican escudos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambican Metical \(1980–2006\)),
				'one' => q(Mozambican metical \(1980–2006\)),
				'other' => q(Mozambican meticals \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mozambican Metical),
				'one' => q(Mozambican metical),
				'other' => q(Mozambican meticals),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibian Dollar),
				'one' => q(Namibian dollar),
				'other' => q(Namibian dollars),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerian Naira),
				'one' => q(Nigerian naira),
				'other' => q(Nigerian nairas),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguan Córdoba \(1988–1991\)),
				'one' => q(Nicaraguan córdoba \(1988–1991\)),
				'other' => q(Nicaraguan córdobas \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguan Córdoba),
				'one' => q(Nicaraguan córdoba),
				'other' => q(Nicaraguan córdobas),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Dutch Guilder),
				'one' => q(Dutch guilder),
				'other' => q(Dutch guilders),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegian Krone),
				'one' => q(Norwegian krone),
				'other' => q(Norwegian kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Nepalese Rupee),
				'one' => q(Nepalese rupee),
				'other' => q(Nepalese rupees),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(New Zealand Dollar),
				'one' => q(New Zealand dollar),
				'other' => q(New Zealand dollars),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omani Rial),
				'one' => q(Omani rial),
				'other' => q(Omani rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamanian Balboa),
				'one' => q(Panamanian balboa),
				'other' => q(Panamanian balboas),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruvian Inti),
				'one' => q(Peruvian inti),
				'other' => q(Peruvian intis),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruvian Sol),
				'one' => q(Peruvian sol),
				'other' => q(Peruvian soles),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruvian Sol \(1863–1965\)),
				'one' => q(Peruvian sol \(1863–1965\)),
				'other' => q(Peruvian soles \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua New Guinean Kina),
				'one' => q(Papua New Guinean kina),
				'other' => q(Papua New Guinean kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Philippine Piso),
				'one' => q(Philippine piso),
				'other' => q(Philippine pisos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Pakistani Rupee),
				'one' => q(Pakistani rupee),
				'other' => q(Pakistani rupees),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polish Zloty),
				'one' => q(Polish zloty),
				'other' => q(Polish zlotys),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polish Zloty \(1950–1995\)),
				'one' => q(Polish zloty \(PLZ\)),
				'other' => q(Polish zlotys \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portuguese Escudo),
				'one' => q(Portuguese escudo),
				'other' => q(Portuguese escudos),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayan Guarani),
				'one' => q(Paraguayan guarani),
				'other' => q(Paraguayan guaranis),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Qatari Rial),
				'one' => q(Qatari rial),
				'other' => q(Qatari rials),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodesian Dollar),
				'one' => q(Rhodesian dollar),
				'other' => q(Rhodesian dollars),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Romanian Leu \(1952–2006\)),
				'one' => q(Romanian leu \(1952–2006\)),
				'other' => q(Romanian Lei \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Romanian Leu),
				'one' => q(Romanian leu),
				'other' => q(Romanian lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbian Dinar),
				'one' => q(Serbian dinar),
				'other' => q(Serbian dinars),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russian Ruble),
				'one' => q(Russian ruble),
				'other' => q(Russian rubles),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russian Ruble \(1991–1998\)),
				'one' => q(Russian ruble \(1991–1998\)),
				'other' => q(Russian rubles \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Rwandan Franc),
				'one' => q(Rwandan franc),
				'other' => q(Rwandan francs),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi Riyal),
				'one' => q(Saudi riyal),
				'other' => q(Saudi riyals),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Solomon Islands Dollar),
				'one' => q(Solomon Islands dollar),
				'other' => q(Solomon Islands dollars),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellois Rupee),
				'one' => q(Seychellois rupee),
				'other' => q(Seychellois rupees),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudanese Dinar \(1992–2007\)),
				'one' => q(Sudanese dinar \(1992–2007\)),
				'other' => q(Sudanese dinars \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanese Pound),
				'one' => q(Sudanese pound),
				'other' => q(Sudanese pounds),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanese Pound \(1957–1998\)),
				'one' => q(Sudanese pound \(1957–1998\)),
				'other' => q(Sudanese pounds \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Swedish Krona),
				'one' => q(Swedish krona),
				'other' => q(Swedish kronor),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Singapore Dollar),
				'one' => q(Singapore dollar),
				'other' => q(Singapore dollars),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena Pound),
				'one' => q(St. Helena pound),
				'other' => q(St. Helena pounds),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Slovenian Tolar),
				'one' => q(Slovenian tolar),
				'other' => q(Slovenian tolars),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovak Koruna),
				'one' => q(Slovak koruna),
				'other' => q(Slovak korunas),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra Leonean Leone),
				'one' => q(Sierra Leonean leone),
				'other' => q(Sierra Leonean leones),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somali Shilling),
				'one' => q(Somali shilling),
				'other' => q(Somali shillings),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinamese Dollar),
				'one' => q(Surinamese dollar),
				'other' => q(Surinamese dollars),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamese Guilder),
				'one' => q(Surinamese guilder),
				'other' => q(Surinamese guilders),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(South Sudanese Pound),
				'one' => q(South Sudanese pound),
				'other' => q(South Sudanese pounds),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra),
				'one' => q(São Tomé & Príncipe dobra),
				'other' => q(São Tomé & Príncipe dobras),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra \(2018\)),
				'one' => q(São Tomé & Príncipe dobra \(2018\)),
				'other' => q(São Tomé & Príncipe dobras \(2018\)),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Soviet Rouble),
				'one' => q(Soviet rouble),
				'other' => q(Soviet roubles),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Salvadoran Colón),
				'one' => q(Salvadoran colón),
				'other' => q(Salvadoran colones),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrian Pound),
				'one' => q(Syrian pound),
				'other' => q(Syrian pounds),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swazi Lilangeni),
				'one' => q(Swazi lilangeni),
				'other' => q(Swazi emalangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Thai Baht),
				'one' => q(Thai baht),
				'other' => q(Thai baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tajikistani Ruble),
				'one' => q(Tajikistani ruble),
				'other' => q(Tajikistani rubles),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tajikistani Somoni),
				'one' => q(Tajikistani somoni),
				'other' => q(Tajikistani somonis),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistani Manat \(1993–2009\)),
				'one' => q(Turkmenistani manat \(1993–2009\)),
				'other' => q(Turkmenistani manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistani Manat),
				'one' => q(Turkmenistani manat),
				'other' => q(Turkmenistani manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tunisian Dinar),
				'one' => q(Tunisian dinar),
				'other' => q(Tunisian dinars),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongan Paʻanga),
				'one' => q(Tongan paʻanga),
				'other' => q(Tongan paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timorese Escudo),
				'one' => q(Timorese escudo),
				'other' => q(Timorese escudos),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkish Lira \(1922–2005\)),
				'one' => q(Turkish lira \(1922–2005\)),
				'other' => q(Turkish Lira \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Turkish Lira),
				'one' => q(Turkish lira),
				'other' => q(Turkish Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad & Tobago Dollar),
				'one' => q(Trinidad & Tobago dollar),
				'other' => q(Trinidad & Tobago dollars),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(New Taiwan Dollar),
				'one' => q(New Taiwan dollar),
				'other' => q(New Taiwan dollars),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tanzanian Shilling),
				'one' => q(Tanzanian shilling),
				'other' => q(Tanzanian shillings),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukrainian Hryvnia),
				'one' => q(Ukrainian hryvnia),
				'other' => q(Ukrainian hryvnias),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainian Karbovanets),
				'one' => q(Ukrainian karbovanets),
				'other' => q(Ukrainian karbovantsiv),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandan Shilling \(1966–1987\)),
				'one' => q(Ugandan shilling \(1966–1987\)),
				'other' => q(Ugandan shillings \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Ugandan Shilling),
				'one' => q(Ugandan shilling),
				'other' => q(Ugandan shillings),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US Dollar),
				'one' => q(US dollar),
				'other' => q(US dollars),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US Dollar \(Next day\)),
				'one' => q(US dollar \(next day\)),
				'other' => q(US dollars \(next day\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US Dollar \(Same day\)),
				'one' => q(US dollar \(same day\)),
				'other' => q(US dollars \(same day\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguayan Peso \(Indexed Units\)),
				'one' => q(Uruguayan peso \(indexed units\)),
				'other' => q(Uruguayan pesos \(indexed units\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayan Peso \(1975–1993\)),
				'one' => q(Uruguayan peso \(1975–1993\)),
				'other' => q(Uruguayan pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayan Peso),
				'one' => q(Uruguayan peso),
				'other' => q(Uruguayan pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Uzbekistani Som),
				'one' => q(Uzbekistani som),
				'other' => q(Uzbekistani som),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelan Bolívar \(1871–2008\)),
				'one' => q(Venezuelan bolívar \(1871–2008\)),
				'other' => q(Venezuelan bolívars \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezuelan Bolívar),
				'one' => q(Venezuelan bolívar),
				'other' => q(Venezuelan bolívars),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Vietnamese Dong),
				'one' => q(Vietnamese dong),
				'other' => q(Vietnamese dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vietnamese Dong \(1978–1985\)),
				'one' => q(Vietnamese dong \(1978–1985\)),
				'other' => q(Vietnamese dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu Vatu),
				'one' => q(Vanuatu vatu),
				'other' => q(Vanuatu vatus),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoan Tala),
				'one' => q(Samoan tala),
				'other' => q(Samoan tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Central African CFA Franc),
				'one' => q(Central African CFA franc),
				'other' => q(Central African CFA francs),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Silver),
				'one' => q(troy ounce of silver),
				'other' => q(troy ounces of silver),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Gold),
				'one' => q(troy ounce of gold),
				'other' => q(troy ounces of gold),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(European Composite Unit),
				'one' => q(European composite unit),
				'other' => q(European composite units),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(European Monetary Unit),
				'one' => q(European monetary unit),
				'other' => q(European monetary units),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(European Unit of Account \(XBC\)),
				'one' => q(European unit of account \(XBC\)),
				'other' => q(European units of account \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(European Unit of Account \(XBD\)),
				'one' => q(European unit of account \(XBD\)),
				'other' => q(European units of account \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(East Caribbean Dollar),
				'one' => q(East Caribbean dollar),
				'other' => q(East Caribbean dollars),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Special Drawing Rights),
				'one' => q(special drawing rights),
				'other' => q(special drawing rights),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(European Currency Unit),
				'one' => q(European currency unit),
				'other' => q(European currency units),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(French Gold Franc),
				'one' => q(French gold franc),
				'other' => q(French gold francs),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(French UIC-Franc),
				'one' => q(French UIC-franc),
				'other' => q(French UIC-francs),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(West African CFA Franc),
				'one' => q(West African CFA franc),
				'other' => q(West African CFA francs),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
				'one' => q(troy ounce of palladium),
				'other' => q(troy ounces of palladium),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP Franc),
				'one' => q(CFP franc),
				'other' => q(CFP francs),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinum),
				'one' => q(troy ounce of platinum),
				'other' => q(troy ounces of platinum),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET Funds),
				'one' => q(RINET Funds unit),
				'other' => q(RINET Funds units),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
				'one' => q(Sucre),
				'other' => q(Sucres),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Testing Currency Code),
				'one' => q(Testing Currency unit),
				'other' => q(Testing Currency units),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB Unit of Account),
				'one' => q(ADB unit of account),
				'other' => q(ADB units of account),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Unknown Currency),
				'one' => q(\(unknown unit of currency\)),
				'other' => q(\(unknown currency\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Yemeni Dinar),
				'one' => q(Yemeni dinar),
				'other' => q(Yemeni dinars),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Yemeni Rial),
				'one' => q(Yemeni rial),
				'other' => q(Yemeni rials),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Yugoslavian Hard Dinar \(1966–1990\)),
				'one' => q(Yugoslavian hard dinar \(1966–1990\)),
				'other' => q(Yugoslavian hard dinars \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Yugoslavian New Dinar \(1994–2002\)),
				'one' => q(Yugoslavian new dinar \(1994–2002\)),
				'other' => q(Yugoslavian new dinars \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Yugoslavian Convertible Dinar \(1990–1992\)),
				'one' => q(Yugoslavian convertible dinar \(1990–1992\)),
				'other' => q(Yugoslavian convertible dinars \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Yugoslavian Reformed Dinar \(1992–1993\)),
				'one' => q(Yugoslavian reformed dinar \(1992–1993\)),
				'other' => q(Yugoslavian reformed dinars \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(South African Rand \(financial\)),
				'one' => q(South African rand \(financial\)),
				'other' => q(South African rands \(financial\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(South African Rand),
				'one' => q(South African rand),
				'other' => q(South African rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambian Kwacha \(1968–2012\)),
				'one' => q(Zambian kwacha \(1968–2012\)),
				'other' => q(Zambian kwachas \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Zambian Kwacha),
				'one' => q(Zambian kwacha),
				'other' => q(Zambian kwachas),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zairean New Zaire \(1993–1998\)),
				'one' => q(Zairean new zaire \(1993–1998\)),
				'other' => q(Zairean new zaires \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairean Zaire \(1971–1993\)),
				'one' => q(Zairean zaire \(1971–1993\)),
				'other' => q(Zairean zaires \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwean Dollar \(1980–2008\)),
				'one' => q(Zimbabwean dollar \(1980–2008\)),
				'other' => q(Zimbabwean dollars \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabwean Dollar \(2009\)),
				'one' => q(Zimbabwean dollar \(2009\)),
				'other' => q(Zimbabwean dollars \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwean Dollar \(2008\)),
				'one' => q(Zimbabwean dollar \(2008\)),
				'other' => q(Zimbabwean dollars \(2008\)),
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
					abbreviated => {
						nonleap => [
							'Mo1',
							'Mo2',
							'Mo3',
							'Mo4',
							'Mo5',
							'Mo6',
							'Mo7',
							'Mo8',
							'Mo9',
							'Mo10',
							'Mo11',
							'Mo12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'First Month',
							'Second Month',
							'Third Month',
							'Fourth Month',
							'Fifth Month',
							'Sixth Month',
							'Seventh Month',
							'Eighth Month',
							'Ninth Month',
							'Tenth Month',
							'Eleventh Month',
							'Twelfth Month'
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
							'Jan',
							'Feb',
							'Mar',
							'Apr',
							'May',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Oct',
							'Nov',
							'Dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'January',
							'February',
							'March',
							'April',
							'May',
							'June',
							'July',
							'August',
							'September',
							'October',
							'November',
							'December'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
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
						mon => 'Mon',
						tue => 'Tue',
						wed => 'Wed',
						thu => 'Thu',
						fri => 'Fri',
						sat => 'Sat',
						sun => 'Sun'
					},
					short => {
						mon => 'Mo',
						tue => 'Tu',
						wed => 'We',
						thu => 'Th',
						fri => 'Fr',
						sat => 'Sa',
						sun => 'Su'
					},
					wide => {
						mon => 'Monday',
						tue => 'Tuesday',
						wed => 'Wednesday',
						thu => 'Thursday',
						fri => 'Friday',
						sat => 'Saturday',
						sun => 'Sunday'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
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
					wide => {0 => '1st quarter',
						1 => '2nd quarter',
						2 => '3rd quarter',
						3 => '4th quarter'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
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
					'midnight' => q{midnight},
					'pm' => q{pm},
					'night1' => q{at night},
					'noon' => q{noon},
					'afternoon1' => q{in the afternoon},
					'morning1' => q{in the morning},
					'am' => q{am},
					'evening1' => q{in the evening},
				},
				'wide' => {
					'night1' => q{at night},
					'noon' => q{noon},
					'morning1' => q{in the morning},
					'afternoon1' => q{in the afternoon},
					'midnight' => q{midnight},
					'pm' => q{pm},
					'evening1' => q{in the evening},
					'am' => q{am},
				},
				'narrow' => {
					'am' => q{a},
					'evening1' => q{in the evening},
					'pm' => q{p},
					'midnight' => q{mi},
					'afternoon1' => q{in the afternoon},
					'morning1' => q{in the morning},
					'night1' => q{at night},
					'noon' => q{n},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'evening1' => q{evening},
					'pm' => q{PM},
					'midnight' => q{midnight},
					'night1' => q{night},
					'noon' => q{noon},
					'morning1' => q{morning},
					'afternoon1' => q{afternoon},
				},
				'wide' => {
					'noon' => q{noon},
					'night1' => q{night},
					'afternoon1' => q{afternoon},
					'morning1' => q{morning},
					'pm' => q{PM},
					'midnight' => q{midnight},
					'am' => q{AM},
					'evening1' => q{evening},
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
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'BC',
				'1' => 'AD'
			},
			narrow => {
				'0' => 'B',
				'1' => 'A'
			},
			wide => {
				'0' => 'Before Christ',
				'1' => 'Anno Domini'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Before R.O.C.',
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
			'full' => q{EEEE, MMMM d, r(U)},
			'long' => q{MMMM d, r(U)},
			'medium' => q{MMM d, r},
			'short' => q{M/d/r},
		},
		'generic' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
		},
		'hebrew' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d MMM y},
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
			'full' => q{{1} 'at' {0}},
			'long' => q{{1} 'at' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'generic' => {
			'full' => q{{1} 'at' {0}},
			'long' => q{{1} 'at' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'at' {0}},
			'long' => q{{1} 'at' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{r(U)},
			GyMMM => q{MMM r(U)},
			GyMMMEd => q{E, MMM d, r(U)},
			GyMMMd => q{MMM d, r},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			UM => q{M/U},
			UMMM => q{MMM U},
			UMMMd => q{MMM d, U},
			UMd => q{M/d/U},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{r(U)},
			yMd => q{M/d/r},
			yyyy => q{r(U)},
			yyyyM => q{M/r},
			yyyyMEd => q{E, M/d/r},
			yyyyMMM => q{MMM r(U)},
			yyyyMMMEd => q{E, MMM d, r(U)},
			yyyyMMMM => q{MMMM r(U)},
			yyyyMMMd => q{MMM d, r},
			yyyyMd => q{M/d/r},
			yyyyQQQ => q{QQQ r(U)},
			yyyyQQQQ => q{QQQQ r(U)},
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
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
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
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMW => q{'week' W 'of' MMMM},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'week' w 'of' Y},
		},
		'hebrew' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E, d MMM},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d MMM},
			y => q{y},
			yM => q{MMM y},
			yMEd => q{E, d MMM y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d MMM y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
	} },
);

has 'datetime_formats_append_item' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{0} {1}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{0} {1}',
		},
		'gregorian' => {
			'Day' => '{0} ({2}: {1})',
			'Day-Of-Week' => '{0} {1}',
			'Era' => '{0} {1}',
			'Hour' => '{0} ({2}: {1})',
			'Minute' => '{0} ({2}: {1})',
			'Month' => '{0} ({2}: {1})',
			'Quarter' => '{0} ({2}: {1})',
			'Second' => '{0} ({2}: {1})',
			'Timezone' => '{0} {1}',
			'Week' => '{0} ({2}: {1})',
			'Year' => '{0} {1}',
		},
	} },
);

has 'datetime_formats_interval' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{U – U},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM U},
				y => q{MMM U – MMM U},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, U},
				d => q{E, MMM d – E, MMM d, U},
				y => q{E, MMM d, U – E, MMM d, U},
			},
			yMMMM => {
				M => q{MMMM – MMMM U},
				y => q{MMMM U – MMMM U},
			},
			yMMMd => {
				M => q{MMM d – MMM d, U},
				d => q{MMM d – d, U},
				y => q{MMM d, U – MMM d, U},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
		'generic' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				M => q{MMM d – MMM d},
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
		'hebrew' => {
			M => {
				M => q{MMM – MMM},
			},
			MEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
						0 => q(Rat),
						1 => q(Ox),
						2 => q(Tiger),
						3 => q(Rabbit),
						4 => q(Dragon),
						5 => q(Snake),
						6 => q(Horse),
						7 => q(Goat),
						8 => q(Monkey),
						9 => q(Rooster),
						10 => q(Dog),
						11 => q(Pig),
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
		regionFormat => q({0} Time),
		regionFormat => q({0} Daylight Time),
		regionFormat => q({0} Standard Time),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre Summer Time#,
				'generic' => q#Acre Time#,
				'standard' => q#Acre Standard Time#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan Time#,
			},
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Central Africa Time#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#East Africa Time#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#South Africa Standard Time#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#West Africa Summer Time#,
				'generic' => q#West Africa Time#,
				'standard' => q#West Africa Standard Time#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska Daylight Time#,
				'generic' => q#Alaska Time#,
				'standard' => q#Alaska Standard Time#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty Summer Time#,
				'generic' => q#Almaty Time#,
				'standard' => q#Almaty Standard Time#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazon Summer Time#,
				'generic' => q#Amazon Time#,
				'standard' => q#Amazon Standard Time#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Central Daylight Time#,
				'generic' => q#Central Time#,
				'standard' => q#Central Standard Time#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Eastern Daylight Time#,
				'generic' => q#Eastern Time#,
				'standard' => q#Eastern Standard Time#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Mountain Daylight Time#,
				'generic' => q#Mountain Time#,
				'standard' => q#Mountain Standard Time#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pacific Daylight Time#,
				'generic' => q#Pacific Time#,
				'standard' => q#Pacific Standard Time#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr Summer Time#,
				'generic' => q#Anadyr Time#,
				'standard' => q#Anadyr Standard Time#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apia Daylight Time#,
				'generic' => q#Apia Time#,
				'standard' => q#Apia Standard Time#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau Summer Time#,
				'generic' => q#Aqtau Time#,
				'standard' => q#Aqtau Standard Time#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtobe Summer Time#,
				'generic' => q#Aqtobe Time#,
				'standard' => q#Aqtobe Standard Time#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabian Daylight Time#,
				'generic' => q#Arabian Time#,
				'standard' => q#Arabian Standard Time#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentina Summer Time#,
				'generic' => q#Argentina Time#,
				'standard' => q#Argentina Standard Time#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Western Argentina Summer Time#,
				'generic' => q#Western Argentina Time#,
				'standard' => q#Western Argentina Standard Time#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenia Summer Time#,
				'generic' => q#Armenia Time#,
				'standard' => q#Armenia Standard Time#,
			},
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh City#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantic Daylight Time#,
				'generic' => q#Atlantic Time#,
				'standard' => q#Atlantic Standard Time#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Australian Central Daylight Time#,
				'generic' => q#Central Australia Time#,
				'standard' => q#Australian Central Standard Time#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australian Central Western Daylight Time#,
				'generic' => q#Australian Central Western Time#,
				'standard' => q#Australian Central Western Standard Time#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australian Eastern Daylight Time#,
				'generic' => q#Eastern Australia Time#,
				'standard' => q#Australian Eastern Standard Time#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australian Western Daylight Time#,
				'generic' => q#Western Australia Time#,
				'standard' => q#Australian Western Standard Time#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaijan Summer Time#,
				'generic' => q#Azerbaijan Time#,
				'standard' => q#Azerbaijan Standard Time#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azores Summer Time#,
				'generic' => q#Azores Time#,
				'standard' => q#Azores Standard Time#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesh Summer Time#,
				'generic' => q#Bangladesh Time#,
				'standard' => q#Bangladesh Standard Time#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan Time#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia Time#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasilia Summer Time#,
				'generic' => q#Brasilia Time#,
				'standard' => q#Brasilia Standard Time#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalam Time#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cape Verde Summer Time#,
				'generic' => q#Cape Verde Time#,
				'standard' => q#Cape Verde Standard Time#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey Time#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro Standard Time#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham Daylight Time#,
				'generic' => q#Chatham Time#,
				'standard' => q#Chatham Standard Time#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chile Summer Time#,
				'generic' => q#Chile Time#,
				'standard' => q#Chile Standard Time#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#China Daylight Time#,
				'generic' => q#China Time#,
				'standard' => q#China Standard Time#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan Summer Time#,
				'generic' => q#Choibalsan Time#,
				'standard' => q#Choibalsan Standard Time#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas Island Time#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos Islands Time#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Colombia Summer Time#,
				'generic' => q#Colombia Time#,
				'standard' => q#Colombia Standard Time#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook Islands Half Summer Time#,
				'generic' => q#Cook Islands Time#,
				'standard' => q#Cook Islands Standard Time#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Cuba Daylight Time#,
				'generic' => q#Cuba Time#,
				'standard' => q#Cuba Standard Time#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis Time#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Time#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#East Timor Time#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Easter Island Summer Time#,
				'generic' => q#Easter Island Time#,
				'standard' => q#Easter Island Standard Time#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuador Time#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Coordinated Universal Time#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Unknown City#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irish Standard Time#,
			},
		},
		'Europe/London' => {
			long => {
				'daylight' => q#British Summer Time#,
			},
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Central European Summer Time#,
				'generic' => q#Central European Time#,
				'standard' => q#Central European Standard Time#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Eastern European Summer Time#,
				'generic' => q#Eastern European Time#,
				'standard' => q#Eastern European Standard Time#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Further-eastern European Time#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Western European Summer Time#,
				'generic' => q#Western European Time#,
				'standard' => q#Western European Standard Time#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falkland Islands Summer Time#,
				'generic' => q#Falkland Islands Time#,
				'standard' => q#Falkland Islands Standard Time#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiji Summer Time#,
				'generic' => q#Fiji Time#,
				'standard' => q#Fiji Standard Time#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#French Guiana Time#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#French Southern & Antarctic Time#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos Time#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier Time#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgia Summer Time#,
				'generic' => q#Georgia Time#,
				'standard' => q#Georgia Standard Time#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert Islands Time#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#East Greenland Summer Time#,
				'generic' => q#East Greenland Time#,
				'standard' => q#East Greenland Standard Time#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#West Greenland Summer Time#,
				'generic' => q#West Greenland Time#,
				'standard' => q#West Greenland Standard Time#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam Standard Time#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gulf Standard Time#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana Time#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutian Daylight Time#,
				'generic' => q#Hawaii-Aleutian Time#,
				'standard' => q#Hawaii-Aleutian Standard Time#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kong Summer Time#,
				'generic' => q#Hong Kong Time#,
				'standard' => q#Hong Kong Standard Time#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Summer Time#,
				'generic' => q#Hovd Time#,
				'standard' => q#Hovd Standard Time#,
			},
		},
		'India' => {
			long => {
				'standard' => q#India Standard Time#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indian Ocean Time#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochina Time#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Central Indonesia Time#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Eastern Indonesia Time#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Western Indonesia Time#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Daylight Time#,
				'generic' => q#Iran Time#,
				'standard' => q#Iran Standard Time#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk Summer Time#,
				'generic' => q#Irkutsk Time#,
				'standard' => q#Irkutsk Standard Time#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israel Daylight Time#,
				'generic' => q#Israel Time#,
				'standard' => q#Israel Standard Time#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Daylight Time#,
				'generic' => q#Japan Time#,
				'standard' => q#Japan Standard Time#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamchatski Summer Time#,
				'generic' => q#Petropavlovsk-Kamchatski Time#,
				'standard' => q#Petropavlovsk-Kamchatski Standard Time#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#East Kazakhstan Time#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#West Kazakhstan Time#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korean Daylight Time#,
				'generic' => q#Korean Time#,
				'standard' => q#Korean Standard Time#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae Time#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyarsk Summer Time#,
				'generic' => q#Krasnoyarsk Time#,
				'standard' => q#Krasnoyarsk Standard Time#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kyrgyzstan Time#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka Time#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line Islands Time#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howe Daylight Time#,
				'generic' => q#Lord Howe Time#,
				'standard' => q#Lord Howe Standard Time#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macau Summer Time#,
				'generic' => q#Macau Time#,
				'standard' => q#Macau Standard Time#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie Island Time#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan Summer Time#,
				'generic' => q#Magadan Time#,
				'standard' => q#Magadan Standard Time#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysia Time#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldives Time#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas Time#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Islands Time#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius Summer Time#,
				'generic' => q#Mauritius Time#,
				'standard' => q#Mauritius Standard Time#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson Time#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Northwest Mexico Daylight Time#,
				'generic' => q#Northwest Mexico Time#,
				'standard' => q#Northwest Mexico Standard Time#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexican Pacific Daylight Time#,
				'generic' => q#Mexican Pacific Time#,
				'standard' => q#Mexican Pacific Standard Time#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar Summer Time#,
				'generic' => q#Ulaanbaatar Time#,
				'standard' => q#Ulaanbaatar Standard Time#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moscow Summer Time#,
				'generic' => q#Moscow Time#,
				'standard' => q#Moscow Standard Time#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar Time#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Time#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepal Time#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#New Caledonia Summer Time#,
				'generic' => q#New Caledonia Time#,
				'standard' => q#New Caledonia Standard Time#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#New Zealand Daylight Time#,
				'generic' => q#New Zealand Time#,
				'standard' => q#New Zealand Standard Time#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Newfoundland Daylight Time#,
				'generic' => q#Newfoundland Time#,
				'standard' => q#Newfoundland Standard Time#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue Time#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolk Island Time#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronha Summer Time#,
				'generic' => q#Fernando de Noronha Time#,
				'standard' => q#Fernando de Noronha Standard Time#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#North Mariana Islands Time#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirsk Summer Time#,
				'generic' => q#Novosibirsk Time#,
				'standard' => q#Novosibirsk Standard Time#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk Summer Time#,
				'generic' => q#Omsk Time#,
				'standard' => q#Omsk Standard Time#,
			},
		},
		'Pacific/Honolulu' => {
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistan Summer Time#,
				'generic' => q#Pakistan Time#,
				'standard' => q#Pakistan Standard Time#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau Time#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua New Guinea Time#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguay Summer Time#,
				'generic' => q#Paraguay Time#,
				'standard' => q#Paraguay Standard Time#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Summer Time#,
				'generic' => q#Peru Time#,
				'standard' => q#Peru Standard Time#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippine Summer Time#,
				'generic' => q#Philippine Time#,
				'standard' => q#Philippine Standard Time#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix Islands Time#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St. Pierre & Miquelon Daylight Time#,
				'generic' => q#St. Pierre & Miquelon Time#,
				'standard' => q#St. Pierre & Miquelon Standard Time#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Time#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Time#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pyongyang Time#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylorda Summer Time#,
				'generic' => q#Qyzylorda Time#,
				'standard' => q#Qyzylorda Standard Time#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunion Time#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera Time#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin Summer Time#,
				'generic' => q#Sakhalin Time#,
				'standard' => q#Sakhalin Standard Time#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara Summer Time#,
				'generic' => q#Samara Time#,
				'standard' => q#Samara Standard Time#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa Daylight Time#,
				'generic' => q#Samoa Time#,
				'standard' => q#Samoa Standard Time#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelles Time#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapore Standard Time#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Solomon Islands Time#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#South Georgia Time#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname Time#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa Time#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti Time#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Daylight Time#,
				'generic' => q#Taipei Time#,
				'standard' => q#Taipei Standard Time#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajikistan Time#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau Time#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonga Summer Time#,
				'generic' => q#Tonga Time#,
				'standard' => q#Tonga Standard Time#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Time#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan Summer Time#,
				'generic' => q#Turkmenistan Time#,
				'standard' => q#Turkmenistan Standard Time#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu Time#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguay Summer Time#,
				'generic' => q#Uruguay Time#,
				'standard' => q#Uruguay Standard Time#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistan Summer Time#,
				'generic' => q#Uzbekistan Time#,
				'standard' => q#Uzbekistan Standard Time#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu Summer Time#,
				'generic' => q#Vanuatu Time#,
				'standard' => q#Vanuatu Standard Time#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela Time#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Summer Time#,
				'generic' => q#Vladivostok Time#,
				'standard' => q#Vladivostok Standard Time#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgograd Summer Time#,
				'generic' => q#Volgograd Time#,
				'standard' => q#Volgograd Standard Time#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostok Time#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake Island Time#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis & Futuna Time#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutsk Summer Time#,
				'generic' => q#Yakutsk Time#,
				'standard' => q#Yakutsk Standard Time#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yekaterinburg Summer Time#,
				'generic' => q#Yekaterinburg Time#,
				'standard' => q#Yekaterinburg Standard Time#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
