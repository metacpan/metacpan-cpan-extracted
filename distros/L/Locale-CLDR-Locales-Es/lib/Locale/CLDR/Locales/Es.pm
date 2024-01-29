=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Es - Package for language Spanish

=cut

package Locale::CLDR::Locales::Es;
# This file auto generated from Data\common\main\es.xml
#	on Sun  7 Jan  2:30:41 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.40.1');

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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine-adjective','spellout-ordinal-masculine-plural','spellout-ordinal-masculine','spellout-ordinal-feminine-plural','spellout-ordinal-feminine','digits-ordinal-masculine-adjective','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'digits-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%digits-ordinal-masculine=),
				},
			},
		},
		'digits-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.ª),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.ª),
				},
			},
		},
		'digits-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.º),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.º),
				},
			},
		},
		'digits-ordinal-masculine-adjective' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.=%%dord-mascabbrev=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=.=%%dord-mascabbrev=),
				},
			},
		},
		'dord-mascabbrev' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(º),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(º),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ᵉʳ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(º),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→→),
				},
			},
		},
		'lenient-parse' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(&[last primary ignorable ] ←← ' ' ←← ',' ←← '-' ←← '­'),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(&[last primary ignorable ] ←← ' ' ←← ',' ←← '-' ←← '­'),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x,x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punto →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(veintiuna),
				},
				'22' => {
					base_value => q(22),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(treinta[ y →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarenta[ y →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cincuenta[ y →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesenta[ y →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setenta[ y →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ochenta[ y →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noventa[ y →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cien),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(ciento →→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(dos­cientas[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tres­cientas[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuatro­cientas[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quinientas[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(seis­cientas[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sete­cientas[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ocho­cientas[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(nove­cientas[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millón[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millones[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billón[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billones[ →→]),
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
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x,x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punto →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(veintiún),
				},
				'22' => {
					base_value => q(22),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(treinta[ y →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarenta[ y →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cincuenta[ y →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesenta[ y →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setenta[ y →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ochenta[ y →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noventa[ y →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cien),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(ciento →→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(doscientos[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trescientos[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuatrocientos[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quinientos[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(seis­cientos[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(sete­cientos[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ocho­cientos[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(nove­cientos[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millón[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millones[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billón[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billones[ →→]),
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
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x,x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← punto →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dos),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tres),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuatro),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinco),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seis),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siete),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ocho),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nueve),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(diez),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(once),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(doce),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trece),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(catorce),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quince),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(dieciséis),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dieci→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(veinte),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(veintiuno),
				},
				'22' => {
					base_value => q(22),
					divisor => q(10),
					rule => q(veintidós),
				},
				'23' => {
					base_value => q(23),
					divisor => q(10),
					rule => q(veintitrés),
				},
				'24' => {
					base_value => q(24),
					divisor => q(10),
					rule => q(veinticuatro),
				},
				'25' => {
					base_value => q(25),
					divisor => q(10),
					rule => q(veinticinco),
				},
				'26' => {
					base_value => q(26),
					divisor => q(10),
					rule => q(veintiséis),
				},
				'27' => {
					base_value => q(27),
					divisor => q(10),
					rule => q(veinti→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(treinta[ y →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarenta[ y →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cincuenta[ y →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesenta[ y →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setenta[ y →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ochenta[ y →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noventa[ y →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cien),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(ciento →→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(doscientos[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trescientos[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuatrocientos[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quinientos[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(seiscientos[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(setecientos[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(ochocientos[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(novecientos[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mil[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millón[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millones[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billón[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billones[ →→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primera),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segunda),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tercera),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuarta),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinta),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sexta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(séptima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(octava),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(novena),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(décima),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(decim→→),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vigésima[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trigésima[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuadragésima[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(quincuagésima[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sexagésima[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septuagésima[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(octogésima[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonagésima[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(centésima[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ducentésima[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tricentésima[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuadringentésima[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quingentésima[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(sexcentésima[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(septingentésima[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(octingésima[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(noningentésima[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(milésima[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← milésima[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millonésima[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millonésima[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billonésima[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billonésima[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ª),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ª),
				},
			},
		},
		'spellout-ordinal-feminine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=s),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ª),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ª),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primero),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segundo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tercero),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuarto),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinto),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sexto),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(séptimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(octavo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(noveno),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(décimo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(decim→→),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vigésimo[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trigésimo[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuadragésimo[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(quincuagésimo[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sexagésimo[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septuagésimo[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(octogésimo[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonagésimo[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(centésimo[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ducentésimo[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tricentésimo[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuadringentésimo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quingentésimo[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(sexcentésimo[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(septingentésimo[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(octingésimo[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(noningentésimo[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(milésimo[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← milésimo[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millonésimo[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millonésimo[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billonésimo[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billonésimo[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
				},
			},
		},
		'spellout-ordinal-masculine-adjective' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(cero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primer),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segundo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tercer),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuarto),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinto),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sexto),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(séptimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(octavo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(noveno),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(décimo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undécimo),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(duodécimo),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(decim→→),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(decimo→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vigésimo[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trigésimo[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuadragésimo[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(quincuagésimo[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sexagésimo[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septuagésimo[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(octogésimo[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonagésimo[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(centésimo[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(ducentésimo[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(tricentésimo[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(cuadringentésimo[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quingentésimo[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(sexcentésimo[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(septingentésimo[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(octingésimo[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(noningentésimo[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(milésimo[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← milésimo[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un millonésimo[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← millonésimo[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billonésimo[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← billonésimo[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
				},
			},
		},
		'spellout-ordinal-masculine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menos →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=s),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=º),
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
				'aa' => 'afar',
 				'ab' => 'abjasio',
 				'ace' => 'acehnés',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adigué',
 				'ae' => 'avéstico',
 				'af' => 'afrikáans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'acadio',
 				'ale' => 'aleutiano',
 				'alt' => 'altái meridional',
 				'am' => 'amárico',
 				'an' => 'aragonés',
 				'ang' => 'inglés antiguo',
 				'anp' => 'angika',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe estándar moderno',
 				'arc' => 'arameo',
 				'arn' => 'mapuche',
 				'arp' => 'arapaho',
 				'ars' => 'árabe najdí',
 				'arw' => 'arahuaco',
 				'as' => 'asamés',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'av' => 'avar',
 				'awa' => 'avadhi',
 				'ay' => 'aimara',
 				'az' => 'azerbaiyano',
 				'az@alt=short' => 'azerí',
 				'ba' => 'baskir',
 				'bal' => 'baluchi',
 				'ban' => 'balinés',
 				'bas' => 'basaa',
 				'bax' => 'bamún',
 				'bbj' => 'ghomala',
 				'be' => 'bielorruso',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'búlgaro',
 				'bgn' => 'baluchi occidental',
 				'bho' => 'bhoyapurí',
 				'bi' => 'bislama',
 				'bik' => 'bicol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengalí',
 				'bo' => 'tibetano',
 				'br' => 'bretón',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosnio',
 				'bss' => 'akoose',
 				'bua' => 'buriato',
 				'bug' => 'buginés',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalán',
 				'cad' => 'caddo',
 				'car' => 'caribe',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'checheno',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatái',
 				'chk' => 'trukés',
 				'chm' => 'marí',
 				'chn' => 'jerga chinuk',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cheroqui',
 				'chy' => 'cheyene',
 				'ckb' => 'kurdo sorani',
 				'ckb@alt=variant' => 'kurdo central',
 				'co' => 'corso',
 				'cop' => 'copto',
 				'cr' => 'cree',
 				'crh' => 'tártaro de Crimea',
 				'crs' => 'criollo seychelense',
 				'cs' => 'checo',
 				'csb' => 'casubio',
 				'cu' => 'eslavo eclesiástico',
 				'cv' => 'chuvasio',
 				'cy' => 'galés',
 				'da' => 'danés',
 				'dak' => 'dakota',
 				'dar' => 'dargva',
 				'dav' => 'taita',
 				'de' => 'alemán',
 				'de_AT' => 'alemán austríaco',
 				'de_CH' => 'alto alemán suizo',
 				'del' => 'delaware',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'bajo sorbio',
 				'dua' => 'duala',
 				'dum' => 'neerlandés medio',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'diula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewé',
 				'efi' => 'efik',
 				'egy' => 'egipcio antiguo',
 				'eka' => 'ekajuk',
 				'el' => 'griego',
 				'elx' => 'elamita',
 				'en' => 'inglés',
 				'en_AU' => 'inglés australiano',
 				'en_CA' => 'inglés canadiense',
 				'en_GB' => 'inglés británico',
 				'en_US' => 'inglés estadounidense',
 				'enm' => 'inglés medio',
 				'eo' => 'esperanto',
 				'es' => 'español',
 				'es_419' => 'español latinoamericano',
 				'es_ES' => 'español de España',
 				'es_MX' => 'español de México',
 				'et' => 'estonio',
 				'eu' => 'euskera',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'fa_AF' => 'darí',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'finés',
 				'fil' => 'filipino',
 				'fj' => 'fiyiano',
 				'fo' => 'feroés',
 				'fon' => 'fon',
 				'fr' => 'francés',
 				'fr_CA' => 'francés canadiense',
 				'fr_CH' => 'francés suizo',
 				'frc' => 'francés cajún',
 				'frm' => 'francés medio',
 				'fro' => 'francés antiguo',
 				'frr' => 'frisón septentrional',
 				'frs' => 'frisón oriental',
 				'fur' => 'friulano',
 				'fy' => 'frisón occidental',
 				'ga' => 'irlandés',
 				'gaa' => 'ga',
 				'gag' => 'gagauzo',
 				'gan' => 'chino gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'gaélico escocés',
 				'gez' => 'geez',
 				'gil' => 'gilbertés',
 				'gl' => 'gallego',
 				'gmh' => 'alto alemán medio',
 				'gn' => 'guaraní',
 				'goh' => 'alto alemán antiguo',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gótico',
 				'grb' => 'grebo',
 				'grc' => 'griego antiguo',
 				'gsw' => 'alemán suizo',
 				'gu' => 'guyaratí',
 				'guz' => 'gusii',
 				'gv' => 'manés',
 				'gwi' => 'kutchin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'chino hakka',
 				'haw' => 'hawaiano',
 				'he' => 'hebreo',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hit' => 'hitita',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croata',
 				'hsb' => 'alto sorbio',
 				'hsn' => 'chino xiang',
 				'ht' => 'criollo haitiano',
 				'hu' => 'húngaro',
 				'hup' => 'hupa',
 				'hy' => 'armenio',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesio',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi de Sichuán',
 				'ik' => 'inupiaq',
 				'ilo' => 'ilocano',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandés',
 				'it' => 'italiano',
 				'iu' => 'inuktitut',
 				'ja' => 'japonés',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'judeo-persa',
 				'jrb' => 'judeo-árabe',
 				'jv' => 'javanés',
 				'ka' => 'georgiano',
 				'kaa' => 'karakalpako',
 				'kab' => 'cabila',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardiano',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'criollo caboverdiano',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kha' => 'khasi',
 				'kho' => 'kotanés',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazajo',
 				'kkj' => 'kako',
 				'kl' => 'groenlandés',
 				'kln' => 'kalenjin',
 				'km' => 'jemer',
 				'kmb' => 'kimbundu',
 				'kn' => 'canarés',
 				'ko' => 'coreano',
 				'koi' => 'komi permio',
 				'kok' => 'konkaní',
 				'kos' => 'kosraeano',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'carelio',
 				'kru' => 'kurukh',
 				'ks' => 'cachemir',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurdo',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'córnico',
 				'ky' => 'kirguís',
 				'la' => 'latín',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgués',
 				'lez' => 'lezgiano',
 				'lg' => 'ganda',
 				'li' => 'limburgués',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'criollo de Luisiana',
 				'loz' => 'lozi',
 				'lrc' => 'lorí septentrional',
 				'lt' => 'lituano',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseño',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letón',
 				'mad' => 'madurés',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'macasar',
 				'man' => 'mandingo',
 				'mas' => 'masái',
 				'mde' => 'maba',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'criollo mauriciano',
 				'mg' => 'malgache',
 				'mga' => 'irlandés medio',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshalés',
 				'mi' => 'maorí',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedonio',
 				'ml' => 'malayálam',
 				'mn' => 'mongol',
 				'mnc' => 'manchú',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'maratí',
 				'ms' => 'malayo',
 				'mt' => 'maltés',
 				'mua' => 'mundang',
 				'mul' => 'varios idiomas',
 				'mus' => 'creek',
 				'mwl' => 'mirandés',
 				'mwr' => 'marwari',
 				'my' => 'birmano',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazandaraní',
 				'na' => 'nauruano',
 				'nan' => 'chino min nan',
 				'nap' => 'napolitano',
 				'naq' => 'nama',
 				'nb' => 'noruego bokmal',
 				'nd' => 'ndebele septentrional',
 				'nds' => 'bajo alemán',
 				'nds_NL' => 'bajo sajón',
 				'ne' => 'nepalí',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueano',
 				'nl' => 'neerlandés',
 				'nl_BE' => 'flamenco',
 				'nmg' => 'kwasio',
 				'nn' => 'noruego nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'noruego',
 				'nog' => 'nogai',
 				'non' => 'nórdico antiguo',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari clásico',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitano',
 				'oj' => 'ojibwa',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osético',
 				'osa' => 'osage',
 				'ota' => 'turco otomano',
 				'pa' => 'punyabí',
 				'pag' => 'pangasinán',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauano',
 				'pcm' => 'pidgin de Nigeria',
 				'peo' => 'persa antiguo',
 				'phn' => 'fenicio',
 				'pi' => 'pali',
 				'pl' => 'polaco',
 				'pon' => 'pohnpeiano',
 				'prg' => 'prusiano',
 				'pro' => 'provenzal antiguo',
 				'ps' => 'pastún',
 				'ps@alt=variant' => 'pastú',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués de Brasil',
 				'pt_PT' => 'portugués de Portugal',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongano',
 				'rhg' => 'rohinyá',
 				'rm' => 'romanche',
 				'rn' => 'kirundi',
 				'ro' => 'rumano',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
 				'rom' => 'romaní',
 				'ru' => 'ruso',
 				'rup' => 'arrumano',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sánscrito',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'sam' => 'arameo samaritano',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siciliano',
 				'sco' => 'escocés',
 				'sd' => 'sindhi',
 				'sdh' => 'kurdo meridional',
 				'se' => 'sami septentrional',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'irlandés antiguo',
 				'sh' => 'serbocroata',
 				'shi' => 'tashelhit',
 				'shn' => 'shan',
 				'shu' => 'árabe chadiano',
 				'si' => 'cingalés',
 				'sid' => 'sidamo',
 				'sk' => 'eslovaco',
 				'sl' => 'esloveno',
 				'sm' => 'samoano',
 				'sma' => 'sami meridional',
 				'smj' => 'sami lule',
 				'smn' => 'sami inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninké',
 				'so' => 'somalí',
 				'sog' => 'sogdiano',
 				'sq' => 'albanés',
 				'sr' => 'serbio',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'suazi',
 				'ssy' => 'saho',
 				'st' => 'sotho meridional',
 				'su' => 'sundanés',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerio',
 				'sv' => 'sueco',
 				'sw' => 'suajili',
 				'sw_CD' => 'suajili del Congo',
 				'swb' => 'comorense',
 				'syc' => 'siríaco clásico',
 				'syr' => 'siriaco',
 				'ta' => 'tamil',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetún',
 				'tg' => 'tayiko',
 				'th' => 'tailandés',
 				'ti' => 'tigriña',
 				'tig' => 'tigré',
 				'tiv' => 'tiv',
 				'tk' => 'turcomano',
 				'tkl' => 'tokelauano',
 				'tl' => 'tagalo',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tmh' => 'tamashek',
 				'tn' => 'setsuana',
 				'to' => 'tongano',
 				'tog' => 'tonga del Nyasa',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshiano',
 				'tt' => 'tártaro',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluano',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiano',
 				'tyv' => 'tuviniano',
 				'tzm' => 'tamazight del Atlas Central',
 				'udm' => 'udmurt',
 				'ug' => 'uigur',
 				'ug@alt=variant' => 'uygur',
 				'uga' => 'ugarítico',
 				'uk' => 'ucraniano',
 				'umb' => 'umbundu',
 				'und' => 'lengua desconocida',
 				'ur' => 'urdu',
 				'uz' => 'uzbeko',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamita',
 				'vo' => 'volapük',
 				'vot' => 'vótico',
 				'vun' => 'vunjo',
 				'wa' => 'valón',
 				'wae' => 'walser',
 				'wal' => 'wolayta',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wólof',
 				'wuu' => 'chino wu',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapés',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yidis',
 				'yo' => 'yoruba',
 				'yue' => 'cantonés',
 				'yue@alt=menu' => 'chino cantonés',
 				'za' => 'zhuang',
 				'zap' => 'zapoteco',
 				'zbl' => 'símbolos Bliss',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight estándar marroquí',
 				'zh' => 'chino',
 				'zh@alt=menu' => 'chino mandarín',
 				'zh_Hans' => 'chino simplificado',
 				'zh_Hans@alt=long' => 'chino mandarín simplificado',
 				'zh_Hant' => 'chino tradicional',
 				'zh_Hant@alt=long' => 'chino mandarín tradicional',
 				'zu' => 'zulú',
 				'zun' => 'zuñi',
 				'zxx' => 'sin contenido lingüístico',
 				'zza' => 'zazaki',

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
			'Arab' => 'árabe',
 			'Arab@alt=variant' => 'perso-árabe',
 			'Aran' => 'nastaliq',
 			'Armn' => 'armenio',
 			'Avst' => 'avéstico',
 			'Bali' => 'balinés',
 			'Batk' => 'batak',
 			'Beng' => 'bengalí',
 			'Blis' => 'símbolos blis',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'buginés',
 			'Buhd' => 'buhid',
 			'Cans' => 'silabarios aborígenes canadienses unificados',
 			'Cari' => 'cario',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'copto',
 			'Cprt' => 'chipriota',
 			'Cyrl' => 'cirílico',
 			'Cyrs' => 'cirílico del antiguo eslavo eclesiástico',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Egyd' => 'egipcio demótico',
 			'Egyh' => 'egipcio hierático',
 			'Egyp' => 'jeroglíficos egipcios',
 			'Ethi' => 'etiópico',
 			'Geok' => 'georgiano eclesiástico',
 			'Geor' => 'georgiano',
 			'Glag' => 'glagolítico',
 			'Goth' => 'gótico',
 			'Grek' => 'griego',
 			'Gujr' => 'guyaratí',
 			'Guru' => 'gurmuji',
 			'Hanb' => 'han con bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'simplificado',
 			'Hans@alt=stand-alone' => 'han simplificado',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hebr' => 'hebreo',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'silabarios japoneses',
 			'Hung' => 'húngaro antiguo',
 			'Inds' => 'Indio (harappan)',
 			'Ital' => 'antigua bastardilla',
 			'Jamo' => 'jamo',
 			'Java' => 'javanés',
 			'Jpan' => 'japonés',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharosthi',
 			'Khmr' => 'jemer',
 			'Knda' => 'canarés',
 			'Kore' => 'coreano',
 			'Lana' => 'lanna',
 			'Laoo' => 'laosiano',
 			'Latf' => 'latino fraktur',
 			'Latg' => 'latino gaélico',
 			'Latn' => 'latino',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineal A',
 			'Linb' => 'lineal B',
 			'Lyci' => 'licio',
 			'Lydi' => 'lidio',
 			'Mand' => 'mandeo',
 			'Maya' => 'jeroglíficos mayas',
 			'Merc' => 'cursivo meroítico',
 			'Mero' => 'meroítico',
 			'Mlym' => 'malayálam',
 			'Mong' => 'mongol',
 			'Moon' => 'moon',
 			'Mtei' => 'manipuri',
 			'Mymr' => 'birmano',
 			'Nkoo' => 'n’ko',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol ciki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osma' => 'osmaniya',
 			'Perm' => 'permiano antiguo',
 			'Phag' => 'phags-pa',
 			'Phnx' => 'fenicio',
 			'Plrd' => 'Pollard Miao',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Roro' => 'rongo-rongo',
 			'Runr' => 'rúnico',
 			'Samr' => 'samaritano',
 			'Sara' => 'sarati',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'SignWriting',
 			'Shaw' => 'shaviano',
 			'Sinh' => 'cingalés',
 			'Sund' => 'sundanés',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siriaco',
 			'Syre' => 'siriaco estrangelo',
 			'Syrj' => 'siriaco occidental',
 			'Syrn' => 'siriaco oriental',
 			'Tagb' => 'tagbanúa',
 			'Tale' => 'tai le',
 			'Talu' => 'nuevo tai lue',
 			'Taml' => 'tamil',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalo',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandés',
 			'Tibt' => 'tibetano',
 			'Ugar' => 'ugarítico',
 			'Vaii' => 'vai',
 			'Visp' => 'lenguaje visible',
 			'Xpeo' => 'persa antiguo',
 			'Xsux' => 'cuneiforme sumerio-acadio',
 			'Yiii' => 'yi',
 			'Zinh' => 'heredado',
 			'Zmth' => 'notación matemática',
 			'Zsye' => 'emojis',
 			'Zsym' => 'símbolos',
 			'Zxxx' => 'no escrito',
 			'Zyyy' => 'común',
 			'Zzzz' => 'alfabeto desconocido',

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
			'001' => 'Mundo',
 			'002' => 'África',
 			'003' => 'América del Norte',
 			'005' => 'Sudamérica',
 			'009' => 'Oceanía',
 			'011' => 'África occidental',
 			'013' => 'Centroamérica',
 			'014' => 'África oriental',
 			'015' => 'África septentrional',
 			'017' => 'África central',
 			'018' => 'África meridional',
 			'019' => 'América',
 			'021' => 'Norteamérica',
 			'029' => 'Caribe',
 			'030' => 'Asia oriental',
 			'034' => 'Asia meridional',
 			'035' => 'Sudeste asiático',
 			'039' => 'Europa meridional',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Región de Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia central',
 			'145' => 'Asia occidental',
 			'150' => 'Europa',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'202' => 'África subsahariana',
 			'419' => 'Latinoamérica',
 			'AC' => 'Isla de la Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Árabes Unidos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Islas Aland',
 			'AZ' => 'Azerbaiyán',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladés',
 			'BE' => 'Bélgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baréin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'San Bartolomé',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribe neerlandés',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bután',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Bielorrusia',
 			'BZ' => 'Belice',
 			'CA' => 'Canadá',
 			'CC' => 'Islas Cocos',
 			'CD' => 'República Democrática del Congo',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'Congo',
 			'CG@alt=variant' => 'Congo (República)',
 			'CH' => 'Suiza',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Costa de Marfil',
 			'CK' => 'Islas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Isla Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curazao',
 			'CX' => 'Isla de Navidad',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'República Checa',
 			'DE' => 'Alemania',
 			'DG' => 'Diego García',
 			'DJ' => 'Yibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Argelia',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipto',
 			'EH' => 'Sáhara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Unión Europea',
 			'EZ' => 'zona del euro',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiyi',
 			'FK' => 'Islas Malvinas',
 			'FK@alt=variant' => 'Islas Malvinas (Islas Falkland)',
 			'FM' => 'Micronesia',
 			'FO' => 'Islas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reino Unido',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Granada',
 			'GE' => 'Georgia',
 			'GF' => 'Guayana Francesa',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Islas Georgia del Sur y Sandwich del Sur',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bisáu',
 			'GY' => 'Guyana',
 			'HK' => 'RAE de Hong Kong (China)',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Islas Heard y McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hungría',
 			'IC' => 'Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Isla de Man',
 			'IN' => 'India',
 			'IO' => 'Territorio Británico del Océano Índico',
 			'IQ' => 'Irak',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordania',
 			'JP' => 'Japón',
 			'KE' => 'Kenia',
 			'KG' => 'Kirguistán',
 			'KH' => 'Camboya',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoras',
 			'KN' => 'San Cristóbal y Nieves',
 			'KP' => 'Corea del Norte',
 			'KR' => 'Corea del Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Islas Caimán',
 			'KZ' => 'Kazajistán',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
 			'LC' => 'Santa Lucía',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marruecos',
 			'MC' => 'Mónaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'San Martín',
 			'MG' => 'Madagascar',
 			'MH' => 'Islas Marshall',
 			'MK' => 'Macedonia del Norte',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'RAE de Macao (China)',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Islas Marianas del Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malaui',
 			'MX' => 'México',
 			'MY' => 'Malasia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nueva Caledonia',
 			'NE' => 'Níger',
 			'NF' => 'Isla Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Bajos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nueva Zelanda',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Francesa',
 			'PG' => 'Papúa Nueva Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Pakistán',
 			'PL' => 'Polonia',
 			'PM' => 'San Pedro y Miquelón',
 			'PN' => 'Islas Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territorios Palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palaos',
 			'PY' => 'Paraguay',
 			'QA' => 'Catar',
 			'QO' => 'Territorios alejados de Oceanía',
 			'RE' => 'Reunión',
 			'RO' => 'Rumanía',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudí',
 			'SB' => 'Islas Salomón',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Elena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard y Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudán del Sur',
 			'ST' => 'Santo Tomé y Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Esuatini',
 			'SZ@alt=variant' => 'Suazilandia',
 			'TA' => 'Tristán de Acuña',
 			'TC' => 'Islas Turcas y Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Australes Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tayikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor Oriental',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Túnez',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidad y Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucrania',
 			'UG' => 'Uganda',
 			'UM' => 'Islas menores alejadas de EE. UU.',
 			'UN' => 'Naciones Unidas',
 			'US' => 'Estados Unidos',
 			'US@alt=short' => 'EE. UU.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Ciudad del Vaticano',
 			'VC' => 'San Vicente y las Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Islas Vírgenes Británicas',
 			'VI' => 'Islas Vírgenes de EE. UU.',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudoacentos',
 			'XB' => 'Pseudobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudáfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Región desconocida',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Ortografía alemana tradicional',
 			'1994' => 'Ortografía estandarizada del resiano',
 			'1996' => 'Ortografía alemana de 1996',
 			'1606NICT' => 'Francés medieval tardío hasta 1606',
 			'1694ACAD' => 'Francés moderno temprano',
 			'1959ACAD' => 'Académico',
 			'AREVELA' => 'Armenio oriental',
 			'AREVMDA' => 'Armenio occidental',
 			'BAKU1926' => 'Alfabeto latino túrquico unificado',
 			'BISKE' => 'Dialecto de San Giorgio/Bila',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'Alfabeto fonético internacional IPA',
 			'FONUPA' => 'Alfabeto fonético urálico UPA',
 			'KKCOR' => 'Ortografía común',
 			'LIPAW' => 'Dialecto Lipovaz del resiano',
 			'MONOTON' => 'Monotónico',
 			'NEDIS' => 'Dialecto del Natisone',
 			'NJIVA' => 'Dialecto de Gniva/Njiva',
 			'OSOJS' => 'Dialecto de Oseacco/Osoane',
 			'PINYIN' => 'Romanización pinyin',
 			'POLYTON' => 'Politónico',
 			'POSIX' => 'Ordenador',
 			'REVISED' => 'Ortografía revisada',
 			'ROZAJ' => 'Resiano',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Inglés escocés estándar',
 			'SCOUSE' => 'Scouse',
 			'SOLBA' => 'Dialecto de Stolvizza/Solbica',
 			'TARASK' => 'Ortografía taraskievica',
 			'UCCOR' => 'Ortografía unificada',
 			'UCRCOR' => 'Ortografía unificada revisada',
 			'VALENCIA' => 'Valenciano',
 			'WADEGILE' => 'Romanización Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendario',
 			'cf' => 'formato de moneda',
 			'colalternate' => 'orden ignorando símbolos',
 			'colbackwards' => 'orden de acentos con inversión',
 			'colcasefirst' => 'orden de mayúsculas/minúsculas',
 			'colcaselevel' => 'orden con distinción entre mayúsculas y minúsculas',
 			'collation' => 'orden',
 			'colnormalization' => 'orden con normalización',
 			'colnumeric' => 'orden numérico',
 			'colstrength' => 'intensidad de orden',
 			'currency' => 'moneda',
 			'hc' => 'ciclo horario (12 o 24 horas)',
 			'lb' => 'estilo de salto de línea',
 			'ms' => 'sistema de medición',
 			'numbers' => 'números',
 			'timezone' => 'zona horaria',
 			'va' => 'variante local',
 			'x' => 'uso privado',

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
 				'buddhist' => q{calendario budista},
 				'chinese' => q{calendario chino},
 				'coptic' => q{calendario cóptico},
 				'dangi' => q{calendario dangi},
 				'ethiopic' => q{calendario etíope},
 				'ethiopic-amete-alem' => q{calendario etíope Amete Alem},
 				'gregorian' => q{calendario gregoriano},
 				'hebrew' => q{calendario hebreo},
 				'indian' => q{calendario nacional hindú},
 				'islamic' => q{calendario islámico},
 				'islamic-civil' => q{calendario civil islámico},
 				'islamic-umalqura' => q{calendario islámico umalqura},
 				'iso8601' => q{calendario ISO-8601},
 				'japanese' => q{calendario japonés},
 				'persian' => q{calendario persa},
 				'roc' => q{calendario de la República de China},
 			},
 			'cf' => {
 				'account' => q{formato de moneda de contabilidad},
 				'standard' => q{formato de moneda estándar},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordenar símbolos},
 				'shifted' => q{Ordenar ignorando símbolos},
 			},
 			'colbackwards' => {
 				'no' => q{Ordenar acentos normalmente},
 				'yes' => q{Ordenar acentos con inversión},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ordenar empezando por minúsculas},
 				'no' => q{Ordenar siguiendo orden normal de mayúsculas y minúsculas},
 				'upper' => q{Ordenar empezando por mayúsculas},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordenar sin distinguir entre mayúsculas y minúsculas},
 				'yes' => q{Ordenar distinguiendo entre mayúsculas y minúsculas},
 			},
 			'collation' => {
 				'big5han' => q{orden del chino tradicional - Big5},
 				'compat' => q{orden de clasificación anterior, para compatibilidad},
 				'dictionary' => q{orden de clasificación del diccionario},
 				'ducet' => q{orden predeterminado de Unicode},
 				'eor' => q{reglas de ordenación europeas},
 				'gb2312han' => q{orden del chino simplificado - GB2312},
 				'phonebook' => q{orden de listín telefónico},
 				'phonetic' => q{Orden de clasificación fonético},
 				'pinyin' => q{orden pinyin},
 				'reformed' => q{orden de clasificación reformado},
 				'search' => q{búsqueda de uso general},
 				'searchjl' => q{Buscar por consonante inicial de hangul},
 				'standard' => q{orden estándar},
 				'stroke' => q{orden de los trazos},
 				'traditional' => q{orden tradicional},
 				'unihan' => q{orden de clasificación de trazos radicales},
 			},
 			'colnormalization' => {
 				'no' => q{Ordenar sin normalización},
 				'yes' => q{Ordenar con normalización Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Ordenar dígitos individualmente},
 				'yes' => q{Ordenar dígitos numéricamente},
 			},
 			'colstrength' => {
 				'identical' => q{Ordenar todo},
 				'primary' => q{Ordenar solo letras base},
 				'quaternary' => q{Ordenar acentos/mayúsculas y minúsculas/ancho/kana},
 				'secondary' => q{Ordenar acentos},
 				'tertiary' => q{Ordenar acentos/mayúsculas y minúsculas/ancho},
 			},
 			'd0' => {
 				'fwidth' => q{ancho completo},
 				'hwidth' => q{ancho medio},
 				'npinyin' => q{Numérico},
 			},
 			'hc' => {
 				'h11' => q{sistema de 12 horas (0–11)},
 				'h12' => q{sistema de 12 horas (1–12)},
 				'h23' => q{sistema de 24 horas (0–23)},
 				'h24' => q{sistema de 24 horas (1–24)},
 			},
 			'lb' => {
 				'loose' => q{estilo de salto de línea flexible},
 				'normal' => q{estilo de salto de línea normal},
 				'strict' => q{estilo de salto de línea estricto},
 			},
 			'm0' => {
 				'bgn' => q{transliteración USBGN},
 				'ungegn' => q{transliteración UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{sistema métrico},
 				'uksystem' => q{sistema imperial},
 				'ussystem' => q{sistema estadounidense},
 			},
 			'numbers' => {
 				'arab' => q{dígitos indoarábigos},
 				'arabext' => q{dígitos indoarábigos extendidos},
 				'armn' => q{números en armenio},
 				'armnlow' => q{números en armenio en minúscula},
 				'beng' => q{dígitos en bengalí},
 				'deva' => q{dígitos en devanagari},
 				'ethi' => q{números en etíope},
 				'finance' => q{Números financieros},
 				'fullwide' => q{dígitos de ancho completo},
 				'geor' => q{números en georgiano},
 				'grek' => q{números en griego},
 				'greklow' => q{números en griego en minúscula},
 				'gujr' => q{dígitos en guyaratí},
 				'guru' => q{dígitos en gurmuji},
 				'hanidec' => q{números decimales en chino},
 				'hans' => q{números en chino simplificado},
 				'hansfin' => q{números financieros en chino simplificado},
 				'hant' => q{números en chino tradicional},
 				'hantfin' => q{números financieros en chino tradicional},
 				'hebr' => q{números en hebreo},
 				'jpan' => q{números en japonés},
 				'jpanfin' => q{números financieros en japonés},
 				'khmr' => q{dígitos en jemer},
 				'knda' => q{dígitos en canarés},
 				'laoo' => q{dígitos en lao},
 				'latn' => q{dígitos occidentales},
 				'mlym' => q{dígitos en malayálam},
 				'mong' => q{dígitos en mongol},
 				'mymr' => q{dígitos en birmano},
 				'native' => q{Dígitos nativos},
 				'orya' => q{dígitos en oriya},
 				'roman' => q{números romanos},
 				'romanlow' => q{números romanos en minúscula},
 				'taml' => q{números en tamil tradicional},
 				'tamldec' => q{dígitos en tamil},
 				'telu' => q{dígitos en telugu},
 				'thai' => q{dígitos en tailandés},
 				'tibt' => q{dígitos en tibetano},
 				'traditional' => q{Números tradicionales},
 				'vaii' => q{Dígitos vai},
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
			'metric' => q{métrico},
 			'UK' => q{anglosajón},
 			'US' => q{estadounidense},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Idioma: {0}',
 			'script' => 'Sistema de escritura: {0}',
 			'region' => 'Región: {0}',

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
			auxiliary => qr{[ª à ă â å ä ã ā æ ç è ĕ ê ë ē ì ĭ î ï ī º ò ŏ ô ö ø ō œ ù ŭ û ū ý ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á b c d e é f g h i í j k l m n ñ o ó p q r s t u ú ü v w x y z]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ¡ ? ¿ . … ' ‘ ’ " “ ” « » ( ) \[ \] § @ * / \\ \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0}…',
			'initial' => '… {0}',
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
			'word-initial' => '… {0}',
			'word-medial' => '{0}… {1}',
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
	default		=> qq{«},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
					# Long Unit Identifier
					'' => {
						'name' => q(punto cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto cardinal),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
						'name' => q(unidades de fuerza g),
						'one' => q({0} unidad de fuerza g),
						'other' => q({0} unidades de fuerza g),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'name' => q(unidades de fuerza g),
						'one' => q({0} unidad de fuerza g),
						'other' => q({0} unidades de fuerza g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo al cuadrado),
						'one' => q({0} metro por segundo al cuadrado),
						'other' => q({0} metros por segundo al cuadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo al cuadrado),
						'one' => q({0} metro por segundo al cuadrado),
						'other' => q({0} metros por segundo al cuadrado),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(masculine),
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(masculine),
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(masculine),
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(masculine),
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(masculine),
						'name' => q(grados),
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'name' => q(grados),
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'name' => q(radianes),
						'one' => q({0} radián),
						'other' => q({0} radianes),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'name' => q(radianes),
						'one' => q({0} radián),
						'other' => q({0} radianes),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(revoluciones),
						'one' => q({0} revolución),
						'other' => q({0} revoluciones),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(revoluciones),
						'one' => q({0} revolución),
						'other' => q({0} revoluciones),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(masculine),
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(masculine),
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(feminine),
						'name' => q(hectáreas),
						'one' => q({0} hectárea),
						'other' => q({0} hectáreas),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(feminine),
						'name' => q(hectáreas),
						'one' => q({0} hectárea),
						'other' => q({0} hectáreas),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros cuadrados),
						'one' => q({0} centímetro cuadrado),
						'other' => q({0} centímetros cuadrados),
						'per' => q({0} por centímetro cuadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros cuadrados),
						'one' => q({0} centímetro cuadrado),
						'other' => q({0} centímetros cuadrados),
						'per' => q({0} por centímetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'name' => q(pies cuadrados),
						'one' => q({0} pie cuadrado),
						'other' => q({0} pies cuadrados),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'name' => q(pies cuadrados),
						'one' => q({0} pie cuadrado),
						'other' => q({0} pies cuadrados),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulgadas cuadradas),
						'one' => q({0} pulgada cuadrada),
						'other' => q({0} pulgadas cuadradas),
						'per' => q({0} por pulgada cuadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulgadas cuadradas),
						'one' => q({0} pulgada cuadrada),
						'other' => q({0} pulgadas cuadradas),
						'per' => q({0} por pulgada cuadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros cuadrados),
						'one' => q({0} kilómetro cuadrado),
						'other' => q({0} kilómetros cuadrados),
						'per' => q({0} por kilómetro cuadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros cuadrados),
						'one' => q({0} kilómetro cuadrado),
						'other' => q({0} kilómetros cuadrados),
						'per' => q({0} por kilómetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(metros cuadrados),
						'one' => q({0} metro cuadrado),
						'other' => q({0} metros cuadrados),
						'per' => q({0} por metro cuadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(metros cuadrados),
						'one' => q({0} metro cuadrado),
						'other' => q({0} metros cuadrados),
						'per' => q({0} por metro cuadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(feminine),
						'name' => q(millas cuadradas),
						'one' => q({0} milla cuadrada),
						'other' => q({0} millas cuadradas),
						'per' => q({0} por milla cuadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(feminine),
						'name' => q(millas cuadradas),
						'one' => q({0} milla cuadrada),
						'other' => q({0} millas cuadradas),
						'per' => q({0} por milla cuadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yardas cuadradas),
						'one' => q({0} yarda cuadrada),
						'other' => q({0} yardas cuadradas),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yardas cuadradas),
						'one' => q({0} yarda cuadrada),
						'other' => q({0} yardas cuadradas),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ítem),
						'one' => q({0} ítem),
						'other' => q({0} ítems),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ítem),
						'one' => q({0} ítem),
						'other' => q({0} ítems),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
						'one' => q({0} miligramo por decilitro),
						'other' => q({0} miligramos por decilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramos por decilitro),
						'one' => q({0} miligramo por decilitro),
						'other' => q({0} miligramos por decilitro),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimoles por litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimoles por litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
						'name' => q(moles),
						'one' => q({0} mol),
						'other' => q({0} moles),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
						'name' => q(moles),
						'one' => q({0} mol),
						'other' => q({0} moles),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'name' => q(por ciento),
						'one' => q({0} por ciento),
						'other' => q({0} por ciento),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'name' => q(por ciento),
						'one' => q({0} por ciento),
						'other' => q({0} por ciento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'name' => q(por mil),
						'one' => q({0} por mil),
						'other' => q({0} por mil),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'name' => q(por mil),
						'one' => q({0} por mil),
						'other' => q({0} por mil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'name' => q(partes por millón),
						'one' => q({0} parte por millón),
						'other' => q({0} partes por millón),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'name' => q(partes por millón),
						'one' => q({0} parte por millón),
						'other' => q({0} partes por millón),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'name' => q(por diez mil),
						'one' => q({0} por diez mil),
						'other' => q({0} por diez mil),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'name' => q(por diez mil),
						'one' => q({0} por diez mil),
						'other' => q({0} por diez mil),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por 100 kilómetros),
						'one' => q({0} litro por 100 kilómetros),
						'other' => q({0} litros por 100 kilómetros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por 100 kilómetros),
						'one' => q({0} litro por 100 kilómetros),
						'other' => q({0} litros por 100 kilómetros),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litros por kilómetro),
						'one' => q({0} litro por kilómetro),
						'other' => q({0} litros por kilómetro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros por kilómetro),
						'one' => q({0} litro por kilómetro),
						'other' => q({0} litros por kilómetro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(millas por galón),
						'one' => q({0} milla por galón),
						'other' => q({0} millas por galón),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(millas por galón),
						'one' => q({0} milla por galón),
						'other' => q({0} millas por galón),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(millas por galón imperial),
						'one' => q({0} milla por galón imperial),
						'other' => q({0} millas por galón imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(millas por galón imperial),
						'one' => q({0} milla por galón imperial),
						'other' => q({0} millas por galón imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabytes),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabytes),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobytes),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobytes),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'name' => q(megabits),
						'one' => q({0} megabit),
						'other' => q({0} megabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'name' => q(megabytes),
						'one' => q({0} megabyte),
						'other' => q({0} megabytes),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'name' => q(terabytes),
						'one' => q({0} terabyte),
						'other' => q({0} terabytes),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(masculine),
						'name' => q(siglos),
						'one' => q({0} siglo),
						'other' => q({0} siglos),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(siglos),
						'one' => q({0} siglo),
						'other' => q({0} siglos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0} por día),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'name' => q(días),
						'one' => q({0} día),
						'other' => q({0} días),
						'per' => q({0} por día),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(feminine),
						'name' => q(décadas),
						'one' => q({0} década),
						'other' => q({0} décadas),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'name' => q(décadas),
						'one' => q({0} década),
						'other' => q({0} décadas),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundo),
						'other' => q({0} microsegundos),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundo),
						'other' => q({0} microsegundos),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundos),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundos),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(masculine),
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(masculine),
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} por mes),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} por mes),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundos),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundos),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(masculine),
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(masculine),
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'name' => q(años),
						'one' => q({0} año),
						'other' => q({0} años),
						'per' => q({0} por año),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'name' => q(años),
						'one' => q({0} año),
						'other' => q({0} años),
						'per' => q({0} por año),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'name' => q(amperios),
						'one' => q({0} amperio),
						'other' => q({0} amperios),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} miliamperio),
						'other' => q({0} miliamperios),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'name' => q(ohmios),
						'one' => q({0} ohmio),
						'other' => q({0} ohmios),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'name' => q(voltios),
						'one' => q({0} voltio),
						'other' => q({0} voltios),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'name' => q(voltios),
						'one' => q({0} voltio),
						'other' => q({0} voltios),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unidades térmicas británicas),
						'one' => q({0} unidad térmica británica),
						'other' => q({0} unidades térmicas británicas),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unidades térmicas británicas),
						'one' => q({0} unidad térmica británica),
						'other' => q({0} unidades térmicas británicas),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(calorías),
						'one' => q({0} caloría),
						'other' => q({0} calorías),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(calorías),
						'one' => q({0} caloría),
						'other' => q({0} calorías),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electronvoltios),
						'one' => q({0} electronvoltio),
						'other' => q({0} electronvoltios),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electronvoltios),
						'one' => q({0} electronvoltio),
						'other' => q({0} electronvoltios),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalorías),
						'one' => q({0} kilocaloría),
						'other' => q({0} kilocalorías),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalorías),
						'one' => q({0} kilocaloría),
						'other' => q({0} kilocalorías),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'name' => q(julios),
						'one' => q({0} julio),
						'other' => q({0} julios),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalorías),
						'one' => q({0} kilocaloría),
						'other' => q({0} kilocalorías),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalorías),
						'one' => q({0} kilocaloría),
						'other' => q({0} kilocalorías),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulios),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojulios),
						'one' => q({0} kilojulio),
						'other' => q({0} kilojulios),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilovatios hora),
						'one' => q({0} kilovatio hora),
						'other' => q({0} kilovatios hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilovatios hora),
						'one' => q({0} kilovatio hora),
						'other' => q({0} kilovatios hora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(termias estadounidenses),
						'one' => q({0} termia estadounidense),
						'other' => q({0} termias estadounidenses),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(termias estadounidenses),
						'one' => q({0} termia estadounidense),
						'other' => q({0} termias estadounidenses),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovatios hora por 100 kilómetros),
						'one' => q({0} kilovatio hora por 100 kilómetros),
						'other' => q({0} kilovatios hora por 100 kilómetros),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilovatios hora por 100 kilómetros),
						'one' => q({0} kilovatio hora por 100 kilómetros),
						'other' => q({0} kilovatios hora por 100 kilómetros),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libras de fuerza),
						'one' => q({0} libra de fuerza),
						'other' => q({0} libras de fuerza),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libras de fuerza),
						'one' => q({0} libra de fuerza),
						'other' => q({0} libras de fuerza),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahercios),
						'one' => q({0} gigahercio),
						'other' => q({0} gigahercios),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahercios),
						'one' => q({0} gigahercio),
						'other' => q({0} gigahercios),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(hercios),
						'one' => q({0} hercio),
						'other' => q({0} hercios),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(hercios),
						'one' => q({0} hercio),
						'other' => q({0} hercios),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohercios),
						'one' => q({0} kilohercio),
						'other' => q({0} kilohercios),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohercios),
						'one' => q({0} kilohercio),
						'other' => q({0} kilohercios),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahercios),
						'one' => q({0} megahercio),
						'other' => q({0} megahercios),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahercios),
						'one' => q({0} megahercio),
						'other' => q({0} megahercios),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntos tipográficos),
						'one' => q({0} punto tipográfico),
						'other' => q({0} puntos tipográficos),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntos tipográficos),
						'one' => q({0} punto tipográfico),
						'other' => q({0} puntos tipográficos),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'one' => q({0} punto por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'one' => q({0} punto por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'one' => q({0} punto por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'one' => q({0} punto por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(espacios eme),
						'one' => q({0} espacio eme),
						'other' => q({0} espacios eme),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(espacios eme),
						'one' => q({0} espacio eme),
						'other' => q({0} espacios eme),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapíxeles),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeles),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapíxeles),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeles),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'name' => q(píxeles),
						'one' => q({0} píxel),
						'other' => q({0} píxeles),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'name' => q(píxeles),
						'one' => q({0} píxel),
						'other' => q({0} píxeles),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(píxeles por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeles por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(píxeles por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeles por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(píxeles por pulgada),
						'one' => q({0} píxel por pulgada),
						'other' => q({0} píxeles por pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(píxeles por pulgada),
						'one' => q({0} píxel por pulgada),
						'other' => q({0} píxeles por pulgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidad astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidad astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radios terrestres),
						'one' => q({0} radio terrestre),
						'other' => q({0} radios terrestres),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radios terrestres),
						'one' => q({0} radio terrestre),
						'other' => q({0} radios terrestres),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(brazas),
						'one' => q({0} braza),
						'other' => q({0} brazas),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(brazas),
						'one' => q({0} braza),
						'other' => q({0} brazas),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'name' => q(pies),
						'one' => q({0} pie),
						'other' => q({0} pies),
						'per' => q({0} por pie),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'name' => q(pies),
						'one' => q({0} pie),
						'other' => q({0} pies),
						'per' => q({0} por pie),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(feminine),
						'name' => q(pulgadas),
						'one' => q({0} pulgada),
						'other' => q({0} pulgadas),
						'per' => q({0} por pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(feminine),
						'name' => q(pulgadas),
						'one' => q({0} pulgada),
						'other' => q({0} pulgadas),
						'per' => q({0} por pulgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros),
						'one' => q({0} kilómetro),
						'other' => q({0} kilómetros),
						'per' => q({0} por kilómetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros),
						'one' => q({0} kilómetro),
						'other' => q({0} kilómetros),
						'per' => q({0} por kilómetro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(años luz),
						'one' => q({0} año luz),
						'other' => q({0} años luz),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(años luz),
						'one' => q({0} año luz),
						'other' => q({0} años luz),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(feminine),
						'name' => q(millas),
						'one' => q({0} milla),
						'other' => q({0} millas),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(feminine),
						'name' => q(millas),
						'one' => q({0} milla),
						'other' => q({0} millas),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(millas escandinavas),
						'one' => q({0} milla escandinava),
						'other' => q({0} millas escandinavas),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(millas escandinavas),
						'one' => q({0} milla escandinava),
						'other' => q({0} millas escandinavas),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas náuticas),
						'one' => q({0} milla náutica),
						'other' => q({0} millas náuticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas náuticas),
						'one' => q({0} milla náutica),
						'other' => q({0} millas náuticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(masculine),
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(masculine),
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos),
						'one' => q({0} punto),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos),
						'one' => q({0} punto),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'name' => q(radios solares),
						'one' => q({0} radio solar),
						'other' => q({0} radios solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'name' => q(radios solares),
						'one' => q({0} radio solar),
						'other' => q({0} radios solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(feminine),
						'name' => q(yardas),
						'one' => q({0} yarda),
						'other' => q({0} yardas),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(feminine),
						'name' => q(yardas),
						'one' => q({0} yarda),
						'other' => q({0} yardas),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'name' => q(candelas),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'name' => q(candelas),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'name' => q(lúmenes),
						'one' => q({0} lumen),
						'other' => q({0} lúmenes),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'name' => q(lúmenes),
						'one' => q({0} lumen),
						'other' => q({0} lúmenes),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'name' => q(luxes),
						'one' => q({0} lux),
						'other' => q({0} luxes),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'name' => q(luxes),
						'one' => q({0} lux),
						'other' => q({0} luxes),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosidades solares),
						'one' => q({0} luminosidad solar),
						'other' => q({0} luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosidades solares),
						'one' => q({0} luminosidad solar),
						'other' => q({0} luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(masculine),
						'name' => q(daltones),
						'one' => q({0} dalton),
						'other' => q({0} daltones),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(masculine),
						'name' => q(daltones),
						'one' => q({0} dalton),
						'other' => q({0} daltones),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(feminine),
						'name' => q(masas terrestres),
						'one' => q({0} masa terrestre),
						'other' => q({0} masas terrestres),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(feminine),
						'name' => q(masas terrestres),
						'one' => q({0} masa terrestre),
						'other' => q({0} masas terrestres),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(masculine),
						'name' => q(granos),
						'one' => q({0} grano),
						'other' => q({0} granos),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(masculine),
						'name' => q(granos),
						'one' => q({0} grano),
						'other' => q({0} granos),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} por gramo),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'name' => q(gramos),
						'one' => q({0} gramo),
						'other' => q({0} gramos),
						'per' => q({0} por gramo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogramos),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramos),
						'per' => q({0} por kilogramo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogramos),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramos),
						'per' => q({0} por kilogramo),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'1' => q(feminine),
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'1' => q(feminine),
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramo),
						'other' => q({0} microgramos),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramo),
						'other' => q({0} microgramos),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(miligramos),
						'one' => q({0} miligramo),
						'other' => q({0} miligramos),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(miligramos),
						'one' => q({0} miligramo),
						'other' => q({0} miligramos),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
						'name' => q(onzas),
						'one' => q({0} onza),
						'other' => q({0} onzas),
						'per' => q({0} por onza),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
						'name' => q(onzas),
						'one' => q({0} onza),
						'other' => q({0} onzas),
						'per' => q({0} por onza),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onzas troy),
						'one' => q({0} onza troy),
						'other' => q({0} onzas troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onzas troy),
						'one' => q({0} onza troy),
						'other' => q({0} onzas troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(feminine),
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(feminine),
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(feminine),
						'name' => q(masas solares),
						'one' => q({0} masa solar),
						'other' => q({0} masas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(feminine),
						'name' => q(masas solares),
						'one' => q({0} masa solar),
						'other' => q({0} masas solares),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(toneladas cortas),
						'one' => q({0} tonelada corta),
						'other' => q({0} toneladas cortas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(toneladas cortas),
						'one' => q({0} tonelada corta),
						'other' => q({0} toneladas cortas),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigavatios),
						'one' => q({0} gigavatio),
						'other' => q({0} gigavatios),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigavatios),
						'one' => q({0} gigavatio),
						'other' => q({0} gigavatios),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(caballos de vapor),
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(caballos de vapor),
						'one' => q({0} caballo de vapor),
						'other' => q({0} caballos de vapor),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilovatios),
						'one' => q({0} kilovatio),
						'other' => q({0} kilovatios),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilovatios),
						'one' => q({0} kilovatio),
						'other' => q({0} kilovatios),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'name' => q(megavatios),
						'one' => q({0} megavatio),
						'other' => q({0} megavatios),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'name' => q(megavatios),
						'one' => q({0} megavatio),
						'other' => q({0} megavatios),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(milivatios),
						'one' => q({0} milivatio),
						'other' => q({0} milivatios),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(milivatios),
						'one' => q({0} milivatio),
						'other' => q({0} milivatios),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'name' => q(vatios),
						'one' => q({0} vatio),
						'other' => q({0} vatios),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'name' => q(vatios),
						'one' => q({0} vatio),
						'other' => q({0} vatios),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} cuadrado),
						'other' => q({0} cuadrados),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} cuadrado),
						'other' => q({0} cuadrados),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmósferas),
						'one' => q({0} atmósfera),
						'other' => q({0} atmósferas),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmósferas),
						'one' => q({0} atmósfera),
						'other' => q({0} atmósferas),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'name' => q(bares),
						'one' => q({0} bar),
						'other' => q({0} bares),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'name' => q(bares),
						'one' => q({0} bar),
						'other' => q({0} bares),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascales),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascales),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascales),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascales),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pulgadas de mercurio),
						'one' => q({0} pulgada de mercurio),
						'other' => q({0} pulgadas de mercurio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pulgadas de mercurio),
						'one' => q({0} pulgada de mercurio),
						'other' => q({0} pulgadas de mercurio),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascales),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascales),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascales),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascales),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascales),
						'one' => q({0} megapascal),
						'other' => q({0} megapascales),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascales),
						'one' => q({0} megapascal),
						'other' => q({0} megapascales),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milímetros de mercurio),
						'one' => q({0} milímetro de mercurio),
						'other' => q({0} milímetros de mercurio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milímetros de mercurio),
						'one' => q({0} milímetro de mercurio),
						'other' => q({0} milímetros de mercurio),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'name' => q(pascales),
						'one' => q({0} pascal),
						'other' => q({0} pascales),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'name' => q(pascales),
						'one' => q({0} pascal),
						'other' => q({0} pascales),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'one' => q({0} libra por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'one' => q({0} libra por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilómetros por hora),
						'one' => q({0} kilómetro por hora),
						'other' => q({0} kilómetros por hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilómetros por hora),
						'one' => q({0} kilómetro por hora),
						'other' => q({0} kilómetros por hora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nudos),
						'one' => q({0} nudo),
						'other' => q({0} nudos),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nudos),
						'one' => q({0} nudo),
						'other' => q({0} nudos),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(millas por hora),
						'one' => q({0} milla por hora),
						'other' => q({0} millas por hora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(millas por hora),
						'one' => q({0} milla por hora),
						'other' => q({0} millas por hora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(grados Celsius),
						'one' => q({0} grado Celsius),
						'other' => q({0} grados Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(grados Celsius),
						'one' => q({0} grado Celsius),
						'other' => q({0} grados Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(masculine),
						'name' => q(grados Fahrenheit),
						'one' => q({0} grado Fahrenheit),
						'other' => q({0} grados Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(masculine),
						'name' => q(grados Fahrenheit),
						'one' => q({0} grado Fahrenheit),
						'other' => q({0} grados Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'name' => q(grados),
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'name' => q(grados),
						'one' => q({0} grado),
						'other' => q({0} grados),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}-{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton metros),
						'one' => q({0} newton metro),
						'other' => q({0} newton metros),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton metros),
						'one' => q({0} newton metro),
						'other' => q({0} newton metros),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libras pies),
						'one' => q({0} libra pie),
						'other' => q({0} libras pies),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libras pies),
						'one' => q({0} libra pie),
						'other' => q({0} libras pies),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acres-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acres-pies),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acres-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acres-pies),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barriles),
						'one' => q({0} barril),
						'other' => q({0} barriles),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barriles),
						'one' => q({0} barril),
						'other' => q({0} barriles),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(masculine),
						'name' => q(pies cúbicos),
						'one' => q({0} pie cúbico),
						'other' => q({0} pies cúbicos),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(pies cúbicos),
						'one' => q({0} pie cúbico),
						'other' => q({0} pies cúbicos),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'1' => q(feminine),
						'name' => q(pulgadas cúbicas),
						'one' => q({0} pulgada cúbica),
						'other' => q({0} pulgadas cúbicas),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'1' => q(feminine),
						'name' => q(pulgadas cúbicas),
						'one' => q({0} pulgada cúbica),
						'other' => q({0} pulgadas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros cúbicos),
						'one' => q({0} kilómetro cúbico),
						'other' => q({0} kilómetros cúbicos),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilómetros cúbicos),
						'one' => q({0} kilómetro cúbico),
						'other' => q({0} kilómetros cúbicos),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(feminine),
						'name' => q(millas cúbicas),
						'one' => q({0} milla cúbica),
						'other' => q({0} millas cúbicas),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(feminine),
						'name' => q(millas cúbicas),
						'one' => q({0} milla cúbica),
						'other' => q({0} millas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yardas cúbicas),
						'one' => q({0} yarda cúbica),
						'other' => q({0} yardas cúbicas),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yardas cúbicas),
						'one' => q({0} yarda cúbica),
						'other' => q({0} yardas cúbicas),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(feminine),
						'name' => q(tazas),
						'one' => q({0} taza),
						'other' => q({0} tazas),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(feminine),
						'name' => q(tazas),
						'one' => q({0} taza),
						'other' => q({0} tazas),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(tazas métricas),
						'one' => q({0} taza métrica),
						'other' => q({0} tazas métricas),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(tazas métricas),
						'one' => q({0} taza métrica),
						'other' => q({0} tazas métricas),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(cucharadas de postre),
						'one' => q({0} cucharada de postre),
						'other' => q({0} cucharadas de postre),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(cucharadas de postre),
						'one' => q({0} cucharada de postre),
						'other' => q({0} cucharadas de postre),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(cucharadas de postre imperiales),
						'one' => q({0} cucharada de postre imperial),
						'other' => q({0} cucharadas de postre imperiales),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(cucharadas de postre imperiales),
						'one' => q({0} cucharada de postre imperial),
						'other' => q({0} cucharadas de postre imperiales),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(feminine),
						'name' => q(dracmas líquidas),
						'one' => q({0} dracma líquida),
						'other' => q({0} dracmas líquidas),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(feminine),
						'name' => q(dracmas líquidas),
						'one' => q({0} dracma líquida),
						'other' => q({0} dracmas líquidas),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(feminine),
						'name' => q(gotas),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(feminine),
						'name' => q(gotas),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onzas líquidas),
						'one' => q({0} onza líquida),
						'other' => q({0} onzas líquidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onzas líquidas imperiales),
						'one' => q({0} onza líquida imperial),
						'other' => q({0} onzas líquidas imperiales),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onzas líquidas imperiales),
						'one' => q({0} onza líquida imperial),
						'other' => q({0} onzas líquidas imperiales),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(masculine),
						'name' => q(galones),
						'one' => q({0} galón),
						'other' => q({0} galones),
						'per' => q({0} por galón),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(masculine),
						'name' => q(galones),
						'one' => q({0} galón),
						'other' => q({0} galones),
						'per' => q({0} por galón),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galones imperiales),
						'one' => q({0} galón imperial),
						'other' => q({0} galones imperiales),
						'per' => q({0} por galón imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galones imperiales),
						'one' => q({0} galón imperial),
						'other' => q({0} galones imperiales),
						'per' => q({0} por galón imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(masculine),
						'name' => q(vasos medidores),
						'one' => q({0} vaso medidor),
						'other' => q({0} vasos medidores),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(masculine),
						'name' => q(vasos medidores),
						'one' => q({0} vaso medidor),
						'other' => q({0} vasos medidores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(feminine),
						'name' => q(pizcas),
						'one' => q({0} pizca),
						'other' => q({0} pizcas),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(feminine),
						'name' => q(pizcas),
						'one' => q({0} pizca),
						'other' => q({0} pizcas),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(feminine),
						'name' => q(pintas),
						'one' => q({0} pinta),
						'other' => q({0} pintas),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(feminine),
						'name' => q(pintas),
						'one' => q({0} pinta),
						'other' => q({0} pintas),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintas métricas),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintas métricas),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintas métricas),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintas métricas),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(masculine),
						'name' => q(cuartos),
						'one' => q({0} cuarto),
						'other' => q({0} cuartos),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(masculine),
						'name' => q(cuartos),
						'one' => q({0} cuarto),
						'other' => q({0} cuartos),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(masculine),
						'name' => q(cuartos imperiales),
						'one' => q({0} cuarto imperial),
						'other' => q({0} cuartos imperiales),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(masculine),
						'name' => q(cuartos imperiales),
						'one' => q({0} cuarto imperial),
						'other' => q({0} cuartos imperiales),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(feminine),
						'name' => q(cucharadas),
						'one' => q({0} cucharada),
						'other' => q({0} cucharadas),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(feminine),
						'name' => q(cucharadas),
						'one' => q({0} cucharada),
						'other' => q({0} cucharadas),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(feminine),
						'name' => q(cucharaditas),
						'one' => q({0} cucharadita),
						'other' => q({0} cucharaditas),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(feminine),
						'name' => q(cucharaditas),
						'one' => q({0} cucharadita),
						'other' => q({0} cucharaditas),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(d{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(d{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(f{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(f{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(a{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(a{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(c{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(c{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(z{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(y{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}Fg),
						'other' => q({0}Fg),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}Fg),
						'other' => q({0}Fg),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grad),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grad),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
						'one' => q({0}dunam),
						'other' => q({0}dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ítem),
						'one' => q({0}ít),
						'other' => q({0}ít),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ítem),
						'one' => q({0}ít),
						'other' => q({0}ít),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
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
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
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
					'concentr-permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
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
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp),
						'one' => q({0}m/g imp),
						'other' => q({0}m/g imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp),
						'one' => q({0}m/g imp),
						'other' => q({0}m/g imp),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}b),
						'other' => q({0}b),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}b),
						'other' => q({0}b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'one' => q({0}d),
						'other' => q({0}d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(déc),
						'one' => q({0}déc),
						'other' => q({0}déc),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(déc),
						'one' => q({0}déc),
						'other' => q({0}déc),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0}min),
						'other' => q({0}min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0}min),
						'other' => q({0}min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
						'per' => q({0}/sem),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem),
						'one' => q({0}sem),
						'other' => q({0}sem),
						'per' => q({0}/sem),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
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
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}thm EEUU),
						'other' => q({0}thm EEUU),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}thm EEUU),
						'other' => q({0}thm EEUU),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
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
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}ppp),
						'other' => q({0}ppp),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}ppp),
						'other' => q({0}ppp),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}px/in),
						'other' => q({0}px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}px/in),
						'other' => q({0}px/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}ftm),
						'other' => q({0}ftm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}ftm),
						'other' => q({0}ftm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
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
					'length-inch' => {
						'name' => q(in),
						'one' => q({0}in),
						'other' => q({0}in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0}in),
						'other' => q({0}in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(al),
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(al),
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mi esc),
						'one' => q({0}mi esc),
						'other' => q({0}mi esc),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mi esc),
						'one' => q({0}mi esc),
						'other' => q({0}mi esc),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}M),
						'other' => q({0}M),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}M),
						'other' => q({0}M),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ptos),
						'one' => q({0}pto),
						'other' => q({0}pto),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ptos),
						'one' => q({0}pto),
						'other' => q({0}pto),
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
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
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
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
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
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(st),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(st),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tc),
						'other' => q({0}tc),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tc),
						'other' => q({0}tc),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}CV),
						'other' => q({0}CV),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}CV),
						'other' => q({0}CV),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
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
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf ft),
						'other' => q({0}lbf ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf ft),
						'other' => q({0}lbf ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}tza),
						'other' => q({0}tza),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}tza),
						'other' => q({0}tza),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}tza m),
						'other' => q({0}tza m),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}tza m),
						'other' => q({0}tza m),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0}c/p),
						'other' => q({0}c/p),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}c/p),
						'other' => q({0}c/p),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp imp),
						'one' => q({0}dsp imp),
						'other' => q({0}dsp imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp imp),
						'one' => q({0}dsp imp),
						'other' => q({0}dsp imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gt),
						'one' => q({0}gt),
						'other' => q({0}gt),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gt),
						'one' => q({0}gt),
						'other' => q({0}gt),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz imp),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal imp),
						'one' => q({0}gal imp),
						'other' => q({0}gal imp),
						'per' => q({0}/gal imp),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp),
						'one' => q({0}gal imp),
						'other' => q({0}gal imp),
						'per' => q({0}/gal imp),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(med),
						'one' => q({0}med),
						'other' => q({0}med),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(med),
						'one' => q({0}med),
						'other' => q({0}med),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0}pzc),
						'other' => q({0}pzc),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0}pzc),
						'other' => q({0}pzc),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt imp),
						'one' => q({0}qt imp),
						'other' => q({0}qt imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt imp),
						'one' => q({0}qt imp),
						'other' => q({0}qt imp),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}cda),
						'other' => q({0}cda),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}cda),
						'other' => q({0}cda),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}cdta),
						'other' => q({0}cdta),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}cdta),
						'other' => q({0}cdta),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(d{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(d{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(f{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(f{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(a{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(a{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(c{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(c{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(z{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(z{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(y{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(y{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(da{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(E{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Z{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Y{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Fg),
						'one' => q({0} Fg),
						'other' => q({0} Fg),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Fg),
						'one' => q({0} Fg),
						'other' => q({0} Fg),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grad.),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grad.),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunams),
						'one' => q({0} dunam),
						'other' => q({0} dunams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ítem),
						'one' => q({0} ítem),
						'other' => q({0} ítems),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ítem),
						'one' => q({0} ítem),
						'other' => q({0} ítems),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(por ciento),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(por ciento),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(por mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(por mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(por diez mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(por diez mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
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
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(s.),
						'one' => q({0} s.),
						'other' => q({0} s.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(s.),
						'one' => q({0} s.),
						'other' => q({0} s.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(déc.),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(déc.),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(horas),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(horas),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(a),
						'one' => q({0} a),
						'other' => q({0} a),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm EE. UU.),
						'one' => q({0} thm EE. UU.),
						'other' => q({0} thm EE. UU.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm EE. UU.),
						'one' => q({0} thm EE. UU.),
						'other' => q({0} thm EE. UU.),
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
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ppp),
						'one' => q({0} ppp),
						'other' => q({0} ppp),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ppp),
						'one' => q({0} ppp),
						'other' => q({0} ppp),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(ftm),
						'one' => q({0} ftm),
						'other' => q({0} ftm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(ftm),
						'one' => q({0} ftm),
						'other' => q({0} ftm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(a. l.),
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(a. l.),
						'one' => q({0} a. l.),
						'other' => q({0} a. l.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mi esc.),
						'one' => q({0} mi esc.),
						'other' => q({0} mi esc.),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mi esc.),
						'one' => q({0} mi esc.),
						'other' => q({0} mi esc.),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ptos.),
						'one' => q({0} pto.),
						'other' => q({0} ptos.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ptos.),
						'one' => q({0} pto.),
						'other' => q({0} ptos.),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tc),
						'one' => q({0} tc),
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tc),
						'one' => q({0} tc),
						'other' => q({0} tc),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(CV),
						'one' => q({0} CV),
						'other' => q({0} CV),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(CV),
						'one' => q({0} CV),
						'other' => q({0} CV),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
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
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf ft),
						'one' => q({0} lbf ft),
						'other' => q({0} lbf ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf ft),
						'one' => q({0} lbf ft),
						'other' => q({0} lbf ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} bbl),
						'other' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} bbl),
						'other' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tza),
						'one' => q({0} tza),
						'other' => q({0} tza),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tza),
						'one' => q({0} tza),
						'other' => q({0} tza),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tza m),
						'one' => q({0} tza m),
						'other' => q({0} tza m),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tza m),
						'one' => q({0} tza m),
						'other' => q({0} tza m),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(c/p),
						'one' => q({0} c/p),
						'other' => q({0} c/p),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(c/p),
						'one' => q({0} c/p),
						'other' => q({0} c/p),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn imp.),
						'one' => q({0} dstspn imp.),
						'other' => q({0} dstspn imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotas),
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
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
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
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medidor),
						'one' => q({0} medidor),
						'other' => q({0} medidores),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medidor),
						'one' => q({0} medidor),
						'other' => q({0} medidores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pzc),
						'one' => q({0} pzc),
						'other' => q({0} pzc),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pzc),
						'one' => q({0} pzc),
						'other' => q({0} pzc),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(p),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt imp.),
						'one' => q({0} qt imp.),
						'other' => q({0} qt imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cda),
						'one' => q({0} cda),
						'other' => q({0} cda),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cda),
						'one' => q({0} cda),
						'other' => q({0} cda),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cdta),
						'one' => q({0} cdta),
						'other' => q({0} cdta),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cdta),
						'one' => q({0} cdta),
						'other' => q({0} cdta),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sí|s|yes|y)$' }
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
				2 => q({0} y {1}),
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
	default		=> 2,
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
			'superscriptingExponent' => q(×),
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
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00 mil M',
					'other' => '00 mil M',
				},
				'100000000000' => {
					'one' => '000 mil M',
					'other' => '000 mil M',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 millón',
					'other' => '0 millones',
				},
				'10000000' => {
					'one' => '00 millones',
					'other' => '00 millones',
				},
				'100000000' => {
					'one' => '000 millones',
					'other' => '000 millones',
				},
				'1000000000' => {
					'one' => '0 mil millones',
					'other' => '0 mil millones',
				},
				'10000000000' => {
					'one' => '00 mil millones',
					'other' => '00 mil millones',
				},
				'100000000000' => {
					'one' => '000 mil millones',
					'other' => '000 mil millones',
				},
				'1000000000000' => {
					'one' => '0 billón',
					'other' => '0 billones',
				},
				'10000000000000' => {
					'one' => '00 billones',
					'other' => '00 billones',
				},
				'100000000000000' => {
					'one' => '000 billones',
					'other' => '000 billones',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00 mil M',
					'other' => '00 mil M',
				},
				'100000000000' => {
					'one' => '000 mil M',
					'other' => '000 mil M',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
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
			display_name => {
				'currency' => q(peseta andorrana),
				'one' => q(peseta andorrana),
				'other' => q(pesetas andorranas),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(dírham de los Emiratos Árabes Unidos),
				'one' => q(dírham de los Emiratos Árabes Unidos),
				'other' => q(dírhams de los Emiratos Árabes Unidos),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani),
				'one' => q(afgani),
				'other' => q(afganis),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(lek),
				'one' => q(lek),
				'other' => q(leks),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram),
				'one' => q(dram),
				'other' => q(drams),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(florín antillano),
				'one' => q(florín antillano),
				'other' => q(florines antillanos),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(kuanza),
				'one' => q(kuanza),
				'other' => q(kuanzas),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angoleño \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nuevo kwanza angoleño \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza reajustado angoleño \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentino),
				'one' => q(austral argentino),
				'other' => q(australes argentinos),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentino \(1983–1985\)),
				'one' => q(peso argentino \(ARP\)),
				'other' => q(pesos argentinos \(ARP\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(peso argentino),
				'one' => q(peso argentino),
				'other' => q(pesos argentinos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(chelín austriaco),
				'one' => q(chelín austriaco),
				'other' => q(chelines austriacos),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(dólar australiano),
				'one' => q(dólar australiano),
				'other' => q(dólares australianos),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(florín arubeño),
				'one' => q(florín arubeño),
				'other' => q(florines arubeños),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azerí \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(manat azerbaiyano),
				'one' => q(manat azerbaiyano),
				'other' => q(manats azerbaiyanos),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar bosnio),
				'one' => q(dinar bosnio),
				'other' => q(dinares bosnios),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(marco convertible de Bosnia y Herzegovina),
				'one' => q(marco convertible de Bosnia y Herzegovina),
				'other' => q(marcos convertibles de Bosnia y Herzegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dólar barbadense),
				'one' => q(dólar barbadense),
				'other' => q(dólares barbadenses),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(taka),
				'one' => q(taka),
				'other' => q(takas),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franco belga \(convertible\)),
				'one' => q(franco belga \(convertible\)),
				'other' => q(francos belgas \(convertibles\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franco belga),
				'one' => q(franco belga),
				'other' => q(francos belgas),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franco belga \(financiero\)),
				'one' => q(franco belga \(financiero\)),
				'other' => q(francos belgas \(financieros\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev fuerte búlgaro),
				'one' => q(lev fuerte búlgaro),
				'other' => q(leva fuertes búlgaros),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(leva búlgara),
				'one' => q(leva búlgara),
				'other' => q(levas búlgaras),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinar bareiní),
				'one' => q(dinar bareiní),
				'other' => q(dinares bareiníes),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(franco burundés),
				'one' => q(franco burundés),
				'other' => q(francos burundeses),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dólar bermudeño),
				'one' => q(dólar bermudeño),
				'other' => q(dólares bermudeños),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dólar bruneano),
				'one' => q(dólar bruneano),
				'other' => q(dólares bruneanos),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(boliviano),
				'one' => q(boliviano),
				'other' => q(bolivianos),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso boliviano),
				'one' => q(peso boliviano),
				'other' => q(pesos bolivianos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(MVDOL boliviano),
				'one' => q(MVDOL boliviano),
				'other' => q(MVDOL bolivianos),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(nuevo cruceiro brasileño \(1967–1986\)),
				'one' => q(nuevo cruzado brasileño \(BRB\)),
				'other' => q(nuevos cruzados brasileños \(BRB\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brasileño),
				'one' => q(cruzado brasileño),
				'other' => q(cruzados brasileños),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruceiro brasileño \(1990–1993\)),
				'one' => q(cruceiro brasileño \(BRE\)),
				'other' => q(cruceiros brasileños \(BRE\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real brasileño),
				'one' => q(real brasileño),
				'other' => q(reales brasileños),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(nuevo cruzado brasileño),
				'one' => q(nuevo cruzado brasileño),
				'other' => q(nuevos cruzados brasileños),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruceiro brasileño),
				'one' => q(cruceiro brasileño),
				'other' => q(cruceiros brasileños),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(dólar bahameño),
				'one' => q(dólar bahameño),
				'other' => q(dólares bahameños),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(gultrum),
				'one' => q(gultrum),
				'other' => q(gultrums),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birmano),
				'one' => q(kyat birmano),
				'other' => q(kyat birmanos),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula),
				'one' => q(pula),
				'other' => q(pulas),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nuevo rublo bielorruso \(1994–1999\)),
				'one' => q(nuevo rublo bielorruso),
				'other' => q(nuevos rublos bielorrusos),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(rublo bielorruso),
				'one' => q(rublo bielorruso),
				'other' => q(rublos bielorrusos),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(rublo bielorruso \(2000–2016\)),
				'one' => q(rublo bielorruso \(2000–2016\)),
				'other' => q(rublos bielorrusos \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(dólar beliceño),
				'one' => q(dólar beliceño),
				'other' => q(dólares beliceños),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(dólar canadiense),
				'one' => q(dólar canadiense),
				'other' => q(dólares canadienses),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(franco congoleño),
				'one' => q(franco congoleño),
				'other' => q(francos congoleños),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro WIR),
				'one' => q(euro WIR),
				'other' => q(euros WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franco suizo),
				'one' => q(franco suizo),
				'other' => q(francos suizos),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(franco WIR),
				'one' => q(franco WIR),
				'other' => q(francos WIR),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unidad de fomento chilena),
				'one' => q(unidad de fomento chilena),
				'other' => q(unidades de fomento chilenas),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(peso chileno),
				'one' => q(peso chileno),
				'other' => q(pesos chilenos),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(yuan chino \(extracontinental\)),
				'one' => q(yuan chino \(extracontinental\)),
				'other' => q(yuanes chinos \(extracontinentales\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(yuan),
				'one' => q(yuan),
				'other' => q(yuanes),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombianos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidad de valor real colombiana),
				'one' => q(unidad de valor real),
				'other' => q(unidades de valor reales),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(colón costarricense),
				'one' => q(colón costarricense),
				'other' => q(colones costarricenses),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(antiguo dinar serbio),
				'one' => q(antiguo dinar serbio),
				'other' => q(antiguos dinares serbios),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(corona fuerte checoslovaca),
				'one' => q(corona fuerte checoslovaca),
				'other' => q(coronas fuertes checoslovacas),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso cubano convertible),
				'one' => q(peso cubano convertible),
				'other' => q(pesos cubanos convertibles),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(escudo de Cabo Verde),
				'one' => q(escudo de Cabo Verde),
				'other' => q(escudos de Cabo Verde),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(libra chipriota),
				'one' => q(libra chipriota),
				'other' => q(libras chipriotas),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(corona checa),
				'one' => q(corona checa),
				'other' => q(coronas checas),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(ostmark de Alemania del Este),
				'one' => q(marco de la República Democrática Alemana),
				'other' => q(marcos de la República Democrática Alemana),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marco alemán),
				'one' => q(marco alemán),
				'other' => q(marcos alemanes),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(franco yibutiano),
				'one' => q(franco yibutiano),
				'other' => q(francos yibutianos),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(corona danesa),
				'one' => q(corona danesa),
				'other' => q(coronas danesas),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicanos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(dinar argelino),
				'one' => q(dinar argelino),
				'other' => q(dinares argelinos),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre ecuatoriano),
				'one' => q(sucre ecuatoriano),
				'other' => q(sucres ecuatorianos),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unidad de valor constante \(UVC\) ecuatoriana),
				'one' => q(unidad de valor constante \(UVC\) ecuatoriana),
				'other' => q(unidades de valor constante \(UVC\) ecuatorianas),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(corona estonia),
				'one' => q(corona estonia),
				'other' => q(coronas estonias),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(libra egipcia),
				'one' => q(libra egipcia),
				'other' => q(libras egipcias),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(nakfa),
				'one' => q(nakfa),
				'other' => q(nakfas),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta española \(cuenta A\)),
				'one' => q(peseta española \(cuenta A\)),
				'other' => q(pesetas españolas \(cuenta A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta española \(cuenta convertible\)),
				'one' => q(peseta española \(cuenta convertible\)),
				'other' => q(pesetas españolas \(cuenta convertible\)),
			},
		},
		'ESP' => {
			symbol => '₧',
			display_name => {
				'currency' => q(peseta española),
				'one' => q(peseta española),
				'other' => q(pesetas españolas),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(bir),
				'one' => q(bir),
				'other' => q(bires),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marco finlandés),
				'one' => q(marco finlandés),
				'other' => q(marcos finlandeses),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(dólar fiyiano),
				'one' => q(dólar fiyiano),
				'other' => q(dólares fiyianos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(libra malvinense),
				'one' => q(libra malvinense),
				'other' => q(libras malvinenses),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franco francés),
				'one' => q(franco francés),
				'other' => q(francos franceses),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(libra esterlina),
				'one' => q(libra esterlina),
				'other' => q(libras esterlinas),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgiano),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(lari),
				'one' => q(lari),
				'other' => q(laris),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanés \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi),
				'one' => q(cedi),
				'other' => q(cedis),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(libra gibraltareña),
				'one' => q(libra gibraltareña),
				'other' => q(libras gibraltareñas),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi),
				'one' => q(dalasi),
				'other' => q(dalasis),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(franco guineano),
				'one' => q(franco guineano),
				'other' => q(francos guineanos),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli guineano),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekuele de Guinea Ecuatorial),
				'one' => q(ekuele de Guinea Ecuatorial),
				'other' => q(ekueles de Guinea Ecuatorial),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(dracma griego),
				'one' => q(dracma griego),
				'other' => q(dracmas griegos),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(quetzal guatemalteco),
				'one' => q(quetzal guatemalteco),
				'other' => q(quetzales guatemaltecos),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escudo de Guinea Portuguesa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso de Guinea-Bissáu),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(dólar guyanés),
				'one' => q(dólar guyanés),
				'other' => q(dólares guyaneses),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dólar hongkonés),
				'one' => q(dólar hongkonés),
				'other' => q(dólares hongkoneses),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(lempira hondureño),
				'one' => q(lempira hondureño),
				'other' => q(lempiras hondureños),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croata),
				'one' => q(dinar croata),
				'other' => q(dinares croatas),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna),
				'one' => q(kuna),
				'other' => q(kunas),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gurde haitiano),
				'one' => q(gurde haitiano),
				'other' => q(gurdes haitianos),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(forinto húngaro),
				'one' => q(forinto húngaro),
				'other' => q(forintos húngaros),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(rupia indonesia),
				'one' => q(rupia indonesia),
				'other' => q(rupias indonesias),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(libra irlandesa),
				'one' => q(libra irlandesa),
				'other' => q(libras irlandesas),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(libra israelí),
				'one' => q(libra israelí),
				'other' => q(libras israelíes),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(nuevo séquel israelí),
				'one' => q(nuevo séquel israelí),
				'other' => q(nuevos séqueles israelíes),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupia india),
				'one' => q(rupia india),
				'other' => q(rupias indias),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinar iraquí),
				'one' => q(dinar iraquí),
				'other' => q(dinares iraquíes),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(rial iraní),
				'one' => q(rial iraní),
				'other' => q(riales iraníes),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(corona islandesa),
				'one' => q(corona islandesa),
				'other' => q(coronas islandesas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiana),
				'one' => q(lira italiana),
				'other' => q(liras italianas),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(dólar jamaicano),
				'one' => q(dólar jamaicano),
				'other' => q(dólares jamaicanos),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(dinar jordano),
				'one' => q(dinar jordano),
				'other' => q(dinares jordanos),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen),
				'one' => q(yen),
				'other' => q(yenes),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(chelín keniano),
				'one' => q(chelín keniano),
				'other' => q(chelines kenianos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som),
				'one' => q(som),
				'other' => q(soms),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel),
				'one' => q(riel),
				'other' => q(rieles),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franco comorense),
				'one' => q(franco comorense),
				'other' => q(francos comorenses),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(won norcoreano),
				'one' => q(won norcoreano),
				'other' => q(wons norcoreanos),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won surcoreano),
				'one' => q(won surcoreano),
				'other' => q(wons surcoreanos),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinar kuwaití),
				'one' => q(dinar kuwaití),
				'other' => q(dinares kuwaitíes),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dólar de las Islas Caimán),
				'one' => q(dólar de las Islas Caimán),
				'other' => q(dólares de las Islas Caimán),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tengue kazajo),
				'one' => q(tengue kazajo),
				'other' => q(tengues kazajos),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip),
				'one' => q(kip),
				'other' => q(kips),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libra libanesa),
				'one' => q(libra libanesa),
				'other' => q(libras libanesas),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(rupia esrilanquesa),
				'one' => q(rupia esrilanquesa),
				'other' => q(rupias esrilanquesas),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dólar liberiano),
				'one' => q(dólar liberiano),
				'other' => q(dólares liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesotense),
				'one' => q(loti lesotense),
				'other' => q(lotis lesotenses),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litas lituano),
				'one' => q(litas lituana),
				'other' => q(litas lituanas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituano),
				'one' => q(talonas lituana),
				'other' => q(talonas lituanas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franco convertible luxemburgués),
				'one' => q(franco convertible luxemburgués),
				'other' => q(francos convertibles luxemburgueses),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franco luxemburgués),
				'one' => q(franco luxemburgués),
				'other' => q(francos luxemburgueses),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franco financiero luxemburgués),
				'one' => q(franco financiero luxemburgués),
				'other' => q(francos financieros luxemburgueses),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(lats letón),
				'one' => q(lats letón),
				'other' => q(lats letónes),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rublo letón),
				'one' => q(rublo letón),
				'other' => q(rublos letones),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinar libio),
				'one' => q(dinar libio),
				'other' => q(dinares libios),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(dírham marroquí),
				'one' => q(dírham marroquí),
				'other' => q(dírhams marroquíes),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franco marroquí),
				'one' => q(franco marroquí),
				'other' => q(francos marroquíes),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(leus moldavos),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(ariari),
				'one' => q(ariari),
				'other' => q(ariaris),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franco malgache),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(dinar macedonio),
				'one' => q(dinar macedonio),
				'other' => q(dinares macedonios),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franco malí),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kiat),
				'one' => q(kiat),
				'other' => q(kiats),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik),
				'one' => q(tugrik),
				'other' => q(tugriks),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca de Macao),
				'one' => q(pataca de Macao),
				'other' => q(patacas de Macao),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(uguiya \(1973–2017\)),
				'one' => q(uguiya \(1973–2017\)),
				'other' => q(uguiyas \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(uguiya),
				'one' => q(uguiya),
				'other' => q(uguiyas),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltesa),
				'one' => q(lira maltesa),
				'other' => q(liras maltesas),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(libra maltesa),
				'one' => q(libra maltesa),
				'other' => q(libras maltesas),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupias mauricianas),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rufiya),
				'one' => q(rufiya),
				'other' => q(rufiyas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(kuacha malauí),
				'one' => q(kuacha malauí),
				'other' => q(kuachas malauíes),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(peso mexicano),
				'one' => q(peso mexicano),
				'other' => q(pesos mexicanos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso de plata mexicano \(1861–1992\)),
				'one' => q(peso de plata mexicano \(MXP\)),
				'other' => q(pesos de plata mexicanos \(MXP\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unidad de inversión \(UDI\) mexicana),
				'one' => q(unidad de inversión \(UDI\) mexicana),
				'other' => q(unidades de inversión \(UDI\) mexicanas),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(ringit),
				'one' => q(ringit),
				'other' => q(ringits),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo mozambiqueño),
				'one' => q(escudo mozambiqueño),
				'other' => q(escudos mozambiqueños),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(antiguo metical mozambiqueño),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(metical),
				'one' => q(metical),
				'other' => q(meticales),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(dólar namibio),
				'one' => q(dólar namibio),
				'other' => q(dólares namibios),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira),
				'one' => q(naira),
				'other' => q(nairas),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(córdoba nicaragüense \(1988–1991\)),
				'one' => q(córdoba nicaragüense \(1988–1991\)),
				'other' => q(córdobas nicaragüenses \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(córdoba oro),
				'one' => q(córdoba oro),
				'other' => q(córdobas oro),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(florín neerlandés),
				'one' => q(florín neerlandés),
				'other' => q(florines neerlandeses),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(corona noruega),
				'one' => q(corona noruega),
				'other' => q(coronas noruegas),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(rupia nepalí),
				'one' => q(rupia nepalí),
				'other' => q(rupias nepalíes),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(dólar neozelandés),
				'one' => q(dólar neozelandés),
				'other' => q(dólares neozelandeses),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(rial omaní),
				'one' => q(rial omaní),
				'other' => q(riales omaníes),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(balboa panameño),
				'one' => q(balboa panameño),
				'other' => q(balboas panameños),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruano),
				'one' => q(inti peruano),
				'other' => q(intis peruanos),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(sol peruano),
				'one' => q(sol peruano),
				'other' => q(soles peruanos),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruano \(1863–1965\)),
				'one' => q(sol peruano \(1863–1965\)),
				'other' => q(soles peruanos \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina),
				'one' => q(kina),
				'other' => q(kinas),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipino),
				'one' => q(peso filipino),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(rupia pakistaní),
				'one' => q(rupia pakistaní),
				'other' => q(rupias pakistaníes),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(esloti),
				'one' => q(esloti),
				'other' => q(eslotis),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty polaco \(1950–1995\)),
				'one' => q(zloty polaco \(PLZ\)),
				'other' => q(zlotys polacos \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo portugués),
				'one' => q(escudo portugués),
				'other' => q(escudos portugueses),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(guaraní paraguayo),
				'one' => q(guaraní paraguayo),
				'other' => q(guaraníes paraguayos),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(rial catarí),
				'one' => q(rial catarí),
				'other' => q(riales cataríes),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dólar rodesiano),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(antiguo leu rumano),
				'one' => q(antiguo leu rumano),
				'other' => q(antiguos lei rumanos),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(leu rumano),
				'one' => q(leu rumano),
				'other' => q(leus rumanos),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar serbio),
				'one' => q(dinar serbio),
				'other' => q(dinares serbios),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(rublo ruso),
				'one' => q(rublo ruso),
				'other' => q(rublos rusos),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rublo ruso \(1991–1998\)),
				'one' => q(rublo ruso \(RUR\)),
				'other' => q(rublos rusos \(RUR\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(franco ruandés),
				'one' => q(franco ruandés),
				'other' => q(francos ruandeses),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(rial saudí),
				'one' => q(rial saudí),
				'other' => q(riales saudíes),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dólar salomonense),
				'one' => q(dólar salomonense),
				'other' => q(dólares salomonenses),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(rupia seychellense),
				'one' => q(rupia seychellense),
				'other' => q(rupias seychellenses),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanés),
				'one' => q(dinar sudanés),
				'other' => q(dinares sudaneses),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(libra sudanesa),
				'one' => q(libra sudanesa),
				'other' => q(libras sudanesas),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(libra sudanesa antigua),
				'one' => q(libra sudanesa antigua),
				'other' => q(libras sudanesas antiguas),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(corona sueca),
				'one' => q(corona sueca),
				'other' => q(coronas suecas),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dólar singapurense),
				'one' => q(dólar singapurense),
				'other' => q(dólares singapurenses),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(libra de Santa Elena),
				'one' => q(libra de Santa Elena),
				'other' => q(libras de Santa Elena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tólar esloveno),
				'one' => q(tólar esloveno),
				'other' => q(tólares eslovenos),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(corona eslovaca),
				'one' => q(corona eslovaca),
				'other' => q(coronas eslovacas),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leona),
				'one' => q(leona),
				'other' => q(leonas),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(chelín somalí),
				'one' => q(chelín somalí),
				'other' => q(chelines somalíes),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(dólar surinamés),
				'one' => q(dólar surinamés),
				'other' => q(dólares surinameses),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(florín surinamés),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(libra sursudanesa),
				'one' => q(libra sursudanesa),
				'other' => q(libras sursudanesas),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra \(1977–2017\)),
				'one' => q(dobra \(1977–2017\)),
				'other' => q(dobras \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra),
				'one' => q(dobra),
				'other' => q(dobras),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rublo soviético),
				'one' => q(rublo soviético),
				'other' => q(rublos soviéticos),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colón salvadoreño),
				'one' => q(colón salvadoreño),
				'other' => q(colones salvadoreños),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(libra siria),
				'one' => q(libra siria),
				'other' => q(libras sirias),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni),
				'one' => q(lilangeni),
				'other' => q(lilangenis),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(bat),
				'one' => q(bat),
				'other' => q(bats),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rublo tayiko),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(somoni tayiko),
				'one' => q(somoni tayiko),
				'other' => q(somonis tayikos),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turcomano \(1993–2009\)),
				'one' => q(manat turcomano \(1993–2009\)),
				'other' => q(manats turcomanos \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(manat turcomano),
				'one' => q(manat turcomano),
				'other' => q(manats turcomanos),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunecino),
				'one' => q(dinar tunecino),
				'other' => q(dinares tunecinos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(paanga),
				'one' => q(paanga),
				'other' => q(paangas),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo timorense),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira turca \(1922–2005\)),
				'one' => q(lira turca \(1922–2005\)),
				'other' => q(liras turcas \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(liras turcas),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dólar de Trinidad y Tobago),
				'one' => q(dólar de Trinidad y Tobago),
				'other' => q(dólares de Trinidad y Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nuevo dólar taiwanés),
				'one' => q(nuevo dólar taiwanés),
				'other' => q(nuevos dólares taiwaneses),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(chelín tanzano),
				'one' => q(chelín tanzano),
				'other' => q(chelines tanzanos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(grivna),
				'one' => q(grivna),
				'other' => q(grivnas),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanet ucraniano),
				'one' => q(karbovanet ucraniano),
				'other' => q(karbovanets ucranianos),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(chelín ugandés \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(chelín ugandés),
				'one' => q(chelín ugandés),
				'other' => q(chelines ugandeses),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(dólar estadounidense),
				'one' => q(dólar estadounidense),
				'other' => q(dólares estadounidenses),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dólar estadounidense \(día siguiente\)),
				'one' => q(dólar estadounidense \(día siguiente\)),
				'other' => q(dólares estadounidenses \(día siguiente\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dólar estadounidense \(mismo día\)),
				'one' => q(dólar estadounidense \(mismo día\)),
				'other' => q(dólares estadounidenses \(mismo día\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguayo en unidades indexadas),
				'one' => q(peso uruguayo en unidades indexadas),
				'other' => q(pesos uruguayos en unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguayo \(1975–1993\)),
				'one' => q(peso uruguayo \(UYP\)),
				'other' => q(pesos uruguayos \(UYP\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(peso uruguayo),
				'one' => q(peso uruguayo),
				'other' => q(pesos uruguayos),
			},
		},
		'UYW' => {
			symbol => 'UYW',
			display_name => {
				'currency' => q(unidad previsional uruguayo),
				'one' => q(unidad previsional uruguayo),
				'other' => q(unidades previsionales uruguayos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(sum),
				'one' => q(sum),
				'other' => q(sums),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolívar venezolano \(1871–2008\)),
				'one' => q(bolívar venezolano \(1871–2008\)),
				'other' => q(bolívares venezolanos \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(bolívar venezolano \(2008–2018\)),
				'one' => q(bolívar venezolano \(2008–2018\)),
				'other' => q(bolívares venezolanos \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(bolívar venezolano),
				'one' => q(bolívar venezolano),
				'other' => q(bolívares venezolanos),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dong),
				'one' => q(dong),
				'other' => q(dongs),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu),
				'one' => q(vatu),
				'other' => q(vatus),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala),
				'one' => q(tala),
				'other' => q(talas),
			},
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(franco CFA de África Central),
				'one' => q(franco CFA de África Central),
				'other' => q(francos CFA de África Central),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(plata),
				'one' => q(plata),
				'other' => q(plata),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(oro),
				'one' => q(oro),
				'other' => q(oro),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unidad compuesta europea),
				'one' => q(unidad compuesta europea),
				'other' => q(unidades compuestas europeas),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unidad monetaria europea),
				'one' => q(unidad monetaria europea),
				'other' => q(unidades monetarias europeas),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unidad de cuenta europea \(XBC\)),
				'one' => q(unidad de cuenta europea \(XBC\)),
				'other' => q(unidades de cuenta europeas \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unidad de cuenta europea \(XBD\)),
				'one' => q(unidad de cuenta europea \(XBD\)),
				'other' => q(unidades de cuenta europeas \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dólar del Caribe Oriental),
				'one' => q(dólar del Caribe Oriental),
				'other' => q(dólares del Caribe Oriental),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(derechos especiales de giro),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unidad de moneda europea),
				'one' => q(unidad de moneda europea),
				'other' => q(unidades de moneda europeas),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franco oro francés),
				'one' => q(franco oro francés),
				'other' => q(francos oro franceses),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franco UIC francés),
				'one' => q(franco UIC francés),
				'other' => q(francos UIC franceses),
			},
		},
		'XOF' => {
			symbol => 'XOF',
			display_name => {
				'currency' => q(franco CFA de África Occidental),
				'one' => q(franco CFA de África Occidental),
				'other' => q(francos CFA de África Occidental),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladio),
				'one' => q(paladio),
				'other' => q(paladio),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(franco CFP),
				'other' => q(francos CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platino),
				'one' => q(platino),
				'other' => q(platino),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fondos RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(código reservado para pruebas),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneda desconocida),
				'one' => q(\(moneda desconocida\)),
				'other' => q(\(moneda desconocida\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar yemení),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(rial yemení),
				'one' => q(rial yemení),
				'other' => q(riales yemeníes),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar fuerte yugoslavo),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(super dinar yugoslavo),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar convertible yugoslavo),
				'one' => q(dinar convertible yugoslavo),
				'other' => q(dinares convertibles yugoslavos),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sudafricano \(financiero\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(rand),
				'one' => q(rand),
				'other' => q(rands),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zambiano \(1968–2012\)),
				'one' => q(kwacha zambiano \(1968–2012\)),
				'other' => q(kwachas zambianos \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(kuacha zambiano),
				'one' => q(kuacha zambiano),
				'other' => q(kuachas zambianos),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nuevo zaire zaireño),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire zaireño),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dólar de Zimbabue),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dólar zimbabuense),
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
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
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
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
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
							'ene',
							'feb',
							'mar',
							'abr',
							'may',
							'jun',
							'jul',
							'ago',
							'sept',
							'oct',
							'nov',
							'dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'E',
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
							'enero',
							'febrero',
							'marzo',
							'abril',
							'mayo',
							'junio',
							'julio',
							'agosto',
							'septiembre',
							'octubre',
							'noviembre',
							'diciembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'ene',
							'feb',
							'mar',
							'abr',
							'may',
							'jun',
							'jul',
							'ago',
							'sept',
							'oct',
							'nov',
							'dic'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'E',
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
							'enero',
							'febrero',
							'marzo',
							'abril',
							'mayo',
							'junio',
							'julio',
							'agosto',
							'septiembre',
							'octubre',
							'noviembre',
							'diciembre'
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
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
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
					wide => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12',
							'13'
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
					wide => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
					abbreviated => {
						nonleap => [
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
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
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-q.',
							'dhuʻl-h.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharram',
							'safar',
							'rabiʻ I',
							'rabiʻ II',
							'jumada I',
							'jumada II',
							'rajab',
							'shaʻban',
							'ramadán',
							'shawwal',
							'dhuʻl-qiʻdah',
							'dhuʻl-hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-q.',
							'dhuʻl-h.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharram',
							'safar',
							'rabiʻ I',
							'rabiʻ II',
							'jumada I',
							'jumada II',
							'rajab',
							'shaʻban',
							'ramadán',
							'shawwal',
							'dhuʻl-qiʻdah',
							'dhuʻl-hijjah'
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
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
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
						mon => 'lun',
						tue => 'mar',
						wed => 'mié',
						thu => 'jue',
						fri => 'vie',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'LU',
						tue => 'MA',
						wed => 'MI',
						thu => 'JU',
						fri => 'VI',
						sat => 'SA',
						sun => 'DO'
					},
					wide => {
						mon => 'lunes',
						tue => 'martes',
						wed => 'miércoles',
						thu => 'jueves',
						fri => 'viernes',
						sat => 'sábado',
						sun => 'domingo'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'lun',
						tue => 'mar',
						wed => 'mié',
						thu => 'jue',
						fri => 'vie',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'LU',
						tue => 'MA',
						wed => 'MI',
						thu => 'JU',
						fri => 'VI',
						sat => 'SA',
						sun => 'DO'
					},
					wide => {
						mon => 'lunes',
						tue => 'martes',
						wed => 'miércoles',
						thu => 'jueves',
						fri => 'viernes',
						sat => 'sábado',
						sun => 'domingo'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1.er trimestre',
						1 => '2.º trimestre',
						2 => '3.er trimestre',
						3 => '4.º trimestre'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1.er trimestre',
						1 => '2.º trimestre',
						2 => '3.er trimestre',
						3 => '4.º trimestre'
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
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1200
						&& $time < 2000;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2000
						&& $time < 2400;
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
					'am' => q{a. m.},
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{del mediodía},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{del mediodía},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'evening1' => q{de la tarde},
					'morning1' => q{de la madrugada},
					'morning2' => q{de la mañana},
					'night1' => q{de la noche},
					'noon' => q{del mediodía},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a. m.},
					'evening1' => q{tarde},
					'morning1' => q{madrugada},
					'morning2' => q{mañana},
					'night1' => q{noche},
					'noon' => q{mediodía},
					'pm' => q{p. m.},
				},
				'narrow' => {
					'am' => q{a. m.},
					'evening1' => q{tarde},
					'morning1' => q{madrugada},
					'morning2' => q{mañana},
					'night1' => q{noche},
					'noon' => q{mediodía},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'evening1' => q{tarde},
					'morning1' => q{madrugada},
					'morning2' => q{mañana},
					'night1' => q{noche},
					'noon' => q{mediodía},
					'pm' => q{p. m.},
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
				'0' => 'BE'
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
				'0' => 'a. C.',
				'1' => 'd. C.'
			},
			wide => {
				'0' => 'antes de Cristo',
				'1' => 'después de Cristo'
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
				'0' => 'saka'
			},
			narrow => {
				'0' => 'saka'
			},
			wide => {
				'0' => 'saka'
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
				'0' => 'antes de RDC',
				'1' => 'minguo'
			},
			narrow => {
				'0' => 'antes de RDC',
				'1' => 'minguo'
			},
			wide => {
				'0' => 'antes de RDC',
				'1' => 'minguo'
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
			'full' => q{EEEE, d-M-r},
			'long' => q{d-M-r},
			'medium' => q{d-M-r},
			'short' => q{d-M-r},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{dd/MM/y GGGGG},
			'short' => q{dd/MM/yy GGGGG},
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
			Ed => q{E d},
			Gy => q{r},
			GyMMM => q{M-r},
			GyMMMEd => q{E, d-M-r},
			GyMMMd => q{d-M-r},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d-M},
			MMM => q{L},
			MMMEd => q{E d-M},
			MMMd => q{d-M},
			Md => q{d-M},
			d => q{d},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
			y => q{r},
			yyyy => q{r},
			yyyyM => q{M-r},
			yyyyMEd => q{E, d-M-r},
			yyyyMMM => q{M-r},
			yyyyMMMEd => q{E, d-M-r},
			yyyyMMMM => q{M-r},
			yyyyMMMd => q{d-M-r},
			yyyyMd => q{d-M-r},
			yyyyQQQ => q{QQQ r},
			yyyyQQQQ => q{QQQQ r},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMM => q{MMMM 'de' y G},
			GyMMMMEd => q{E, d 'de' MMMM 'de' y G},
			GyMMMMd => q{d 'de' MMMM 'de' y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{EEE, d MMM y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMMEd => q{EEE, d 'de' MMMM 'de' y G},
			yyyyMMMMd => q{d 'de' MMMM 'de' y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, H:mm},
			EHms => q{E, H:mm:ss},
			Ed => q{E d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMM => q{MMMM 'de' y G},
			GyMMMMEd => q{E, d 'de' MMMM 'de' y G},
			GyMMMMd => q{d 'de' MMMM 'de' y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmsvvvv => q{H:mm:ss (vvvv)},
			Hmv => q{H:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMW => q{'semana' W 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			MMd => q{d/M},
			MMdd => q{d/M},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmsvvvv => q{h:mm:ss a (vvvv)},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{EEE, d/M/y},
			yMM => q{M/y},
			yMMM => q{MMM y},
			yMMMEd => q{EEE, d MMM y},
			yMMMM => q{MMMM 'de' y},
			yMMMMEd => q{EEE, d 'de' MMMM 'de' y},
			yMMMMd => q{d 'de' MMMM 'de' y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{'semana' w 'de' Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM 'de' y G – MMM 'de' y G},
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			GyMMMEd => {
				G => q{E d 'de' MMM 'de' y G – E d 'de' MMM 'de' y G},
				M => q{E d 'de' MMM – E d 'de' MMM 'de' y G},
				d => q{E d 'de' MMM – E d 'de' MMM 'de' y G},
				y => q{E d 'de' MMM 'de' y – E d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH–HH},
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
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d–d 'de' MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
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
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM y G},
				d => q{d–d 'de' MMM 'de' y G},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H:mm–H:mm},
				m => q{H:mm–H:mm},
			},
			Hmv => {
				H => q{H:mm–H:mm v},
				m => q{H:mm–H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM},
			},
			MMMMd => {
				M => q{d 'de' MMMM – d 'de' MMMM},
				d => q{d–d 'de' MMMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d–d},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
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
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y},
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				y => q{E, d 'de' MMMM 'de' y – E, d 'de' MMMM 'de' y},
			},
			yMMMMd => {
				M => q{d 'de' MMMM – d 'de' MMMM 'de' y},
				d => q{d–d 'de' MMMM 'de' y},
				y => q{d 'de' MMMM 'de' y – d 'de' MMMM 'de' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
		regionFormat => q(hora de {0}),
		regionFormat => q(horario de verano de {0}),
		regionFormat => q(horario estándar de {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Hora de verano de Acre#,
				'generic' => q#Hora de Acre#,
				'standard' => q#Hora estándar de Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#hora de Afganistán#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abiyán#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argel#,
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
			exemplarCity => q#Bisáu#,
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
			exemplarCity => q#El Cairo#,
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
			exemplarCity => q#Dar es-Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Yibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
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
			exemplarCity => q#Johannesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Jartum#,
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
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Yamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakchot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugú#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Portonovo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Santo Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnez#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#hora de África central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#hora de África oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#hora de Sudáfrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#hora de verano de África occidental#,
				'generic' => q#hora de África occidental#,
				'standard' => q#hora estándar de África occidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#hora de verano de Alaska#,
				'generic' => q#hora de Alaska#,
				'standard' => q#hora estándar de Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#hora de verano del Amazonas#,
				'generic' => q#hora del Amazonas#,
				'standard' => q#hora estándar del Amazonas#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
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
			exemplarCity => q#Tucumán#,
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
			exemplarCity => q#Bahía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belén#,
		},
		'America/Belize' => {
			exemplarCity => q#Belice#,
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
			exemplarCity => q#Cayena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caimán#,
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
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curazao#,
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
			exemplarCity => q#Eirunepé#,
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
			exemplarCity => q#Gran Turca#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
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
			exemplarCity => q#La Habana#,
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
			exemplarCity => q#Indianápolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaica#,
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
			exemplarCity => q#Los Ángeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaos#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de México#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelón#,
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
			exemplarCity => q#Nueva York#,
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
			exemplarCity => q#Beulah, Dakota del Norte#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota del Norte#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota del Norte#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
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
			exemplarCity => q#Puerto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puerto España#,
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
			exemplarCity => q#Río Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago de Chile#,
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
			exemplarCity => q#San Bartolomé#,
		},
		'America/St_Johns' => {
			exemplarCity => q#San Juan de Terranova#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristóbal#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucía#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vicente#,
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
			exemplarCity => q#Tórtola#,
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
				'daylight' => q#hora de verano central#,
				'generic' => q#hora central#,
				'standard' => q#hora estándar central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#hora de verano oriental#,
				'generic' => q#hora oriental#,
				'standard' => q#hora estándar oriental#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#hora de verano de las Montañas Rocosas#,
				'generic' => q#hora de las Montañas Rocosas#,
				'standard' => q#hora estándar de las Montañas Rocosas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#hora de verano del Pacífico#,
				'generic' => q#hora del Pacífico#,
				'standard' => q#hora estándar del Pacífico#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#hora de verano de Anadyr#,
				'generic' => q#hora de Anadyr#,
				'standard' => q#hora estándar de Anadyr#,
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
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#horario de verano de Apia#,
				'generic' => q#hora de Apia#,
				'standard' => q#hora estándar de Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Hora de verano de Aktau#,
				'generic' => q#Hora de Aktau#,
				'standard' => q#Hora estándar de Aktau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Hora de verano de Aktobe#,
				'generic' => q#Hora de Aktobe#,
				'standard' => q#Hora estándar de Aktobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#hora de verano de Arabia#,
				'generic' => q#hora de Arabia#,
				'standard' => q#hora estándar de Arabia#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#hora de verano de Argentina#,
				'generic' => q#hora de Argentina#,
				'standard' => q#hora estándar de Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#hora de verano de Argentina occidental#,
				'generic' => q#hora de Argentina occidental#,
				'standard' => q#hora estándar de Argentina occidental#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#hora de verano de Armenia#,
				'generic' => q#hora de Armenia#,
				'standard' => q#hora estándar de Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adén#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anádyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjabad#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baréin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaúl#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunéi#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chitá#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daca#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubái#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrón#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Yakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalén#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
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
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadán#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
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
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanái#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangón (Rangún)#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ciudad Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sajalín#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghái#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipéi#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timbu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulán Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientián#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterimburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#hora de verano del Atlántico#,
				'generic' => q#hora del Atlántico#,
				'standard' => q#hora estándar del Atlántico#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Islas Feroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikiavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia del Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Elena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
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
			exemplarCity => q#Sídney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#hora de verano de Australia central#,
				'generic' => q#hora de Australia central#,
				'standard' => q#hora estándar de Australia central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#hora de verano de Australia centroccidental#,
				'generic' => q#hora de Australia centroccidental#,
				'standard' => q#hora estándar de Australia centroccidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Australia oriental#,
				'generic' => q#hora de Australia oriental#,
				'standard' => q#hora estándar de Australia oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#hora de verano de Australia occidental#,
				'generic' => q#hora de Australia occidental#,
				'standard' => q#hora estándar de Australia occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#hora de verano de Azerbaiyán#,
				'generic' => q#hora de Azerbaiyán#,
				'standard' => q#hora estándar de Azerbaiyán#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#hora de verano de las Azores#,
				'generic' => q#hora de las Azores#,
				'standard' => q#hora estándar de las Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#hora de verano de Bangladés#,
				'generic' => q#hora de Bangladés#,
				'standard' => q#hora estándar de Bangladés#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#hora de Bután#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#hora de Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#hora de verano de Brasilia#,
				'generic' => q#hora de Brasilia#,
				'standard' => q#hora estándar de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#hora de Brunéi#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#hora de verano de Cabo Verde#,
				'generic' => q#hora de Cabo Verde#,
				'standard' => q#hora estándar de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#hora estándar de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#hora de verano de Chatham#,
				'generic' => q#hora de Chatham#,
				'standard' => q#hora estándar de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#hora de verano de Chile#,
				'generic' => q#hora de Chile#,
				'standard' => q#hora estándar de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#hora de verano de China#,
				'generic' => q#hora de China#,
				'standard' => q#hora estándar de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#hora de verano de Choibalsan#,
				'generic' => q#hora de Choibalsan#,
				'standard' => q#hora estándar de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#hora de la Isla de Navidad#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#hora de las Islas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#hora de verano de Colombia#,
				'generic' => q#hora de Colombia#,
				'standard' => q#hora estándar de Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#hora de verano media de las Islas Cook#,
				'generic' => q#hora de las Islas Cook#,
				'standard' => q#hora estándar de las Islas Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#hora de verano de Cuba#,
				'generic' => q#hora de Cuba#,
				'standard' => q#hora estándar de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#hora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#hora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#hora de Timor Oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#hora de verano de la isla de Pascua#,
				'generic' => q#hora de la isla de Pascua#,
				'standard' => q#hora estándar de la isla de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#hora de Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#tiempo universal coordinado#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ciudad desconocida#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Ámsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astracán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruselas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisináu#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublín#,
			long => {
				'daylight' => q#hora de verano de Irlanda#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernesey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isla de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kírov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#hora de verano británica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
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
			exemplarCity => q#Mónaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscú#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
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
			exemplarCity => q#Sarátov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferópol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopie#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uliánovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Úzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#El Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilna#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporiyia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zúrich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#hora de verano de Europa central#,
				'generic' => q#hora de Europa central#,
				'standard' => q#hora estándar de Europa central#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Europa oriental#,
				'generic' => q#hora de Europa oriental#,
				'standard' => q#hora estándar de Europa oriental#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#hora del extremo oriental de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#hora de verano de Europa occidental#,
				'generic' => q#hora de Europa occidental#,
				'standard' => q#hora estándar de Europa occidental#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#hora de verano de las islas Malvinas#,
				'generic' => q#hora de las islas Malvinas#,
				'standard' => q#hora estándar de las islas Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#hora de verano de Fiyi#,
				'generic' => q#hora de Fiyi#,
				'standard' => q#hora estándar de Fiyi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#hora de la Guayana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#hora de Antártida y Territorios Australes Franceses#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#hora del meridiano de Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#hora de Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#hora de verano de Georgia#,
				'generic' => q#hora de Georgia#,
				'standard' => q#hora estándar de Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#hora de las islas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#hora de verano de Groenlandia oriental#,
				'generic' => q#hora de Groenlandia oriental#,
				'standard' => q#hora estándar de Groenlandia oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#hora de verano de Groenlandia occidental#,
				'generic' => q#hora de Groenlandia occidental#,
				'standard' => q#hora estándar de Groenlandia occidental#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Hora estándar de Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#hora estándar del Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#hora de Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#hora de verano de Hawái-Aleutianas#,
				'generic' => q#hora de Hawái-Aleutianas#,
				'standard' => q#hora estándar de Hawái-Aleutianas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hora de verano de Hong Kong#,
				'generic' => q#hora de Hong Kong#,
				'standard' => q#hora estándar de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#hora de verano de Hovd#,
				'generic' => q#hora de Hovd#,
				'standard' => q#hora estándar de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#hora estándar de la India#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Navidad#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comoras#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauricio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunión#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#hora del océano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#hora de Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#hora de Indonesia central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#hora de Indonesia oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#hora de Indonesia occidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#hora de verano de Irán#,
				'generic' => q#hora de Irán#,
				'standard' => q#hora estándar de Irán#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#hora de verano de Irkutsk#,
				'generic' => q#hora de Irkutsk#,
				'standard' => q#hora estándar de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#hora de verano de Israel#,
				'generic' => q#hora de Israel#,
				'standard' => q#hora estándar de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#hora de verano de Japón#,
				'generic' => q#hora de Japón#,
				'standard' => q#hora estándar de Japón#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#hora de verano de Kamchatka#,
				'generic' => q#hora de Kamchatka#,
				'standard' => q#hora estándar de Kamchatka#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#hora de Kazajistán oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#hora de Kazajistán occidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#hora de verano de Corea#,
				'generic' => q#hora de Corea#,
				'standard' => q#hora estándar de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#hora de verano de Krasnoyarsk#,
				'generic' => q#hora de Krasnoyarsk#,
				'standard' => q#hora estándar de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#hora de Kirguistán#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Hora de Sri Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#hora de las Espóradas Ecuatoriales#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#hora de verano de Lord Howe#,
				'generic' => q#hora de Lord Howe#,
				'standard' => q#hora estándar de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Hora de verano de Macao#,
				'generic' => q#Hora de Macao#,
				'standard' => q#Hora estándar de Macao#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#hora de la isla Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#hora de verano de Magadán#,
				'generic' => q#hora de Magadán#,
				'standard' => q#hora estándar de Magadán#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#hora de Malasia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#hora de Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#hora de Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#hora de las Islas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#hora de verano de Mauricio#,
				'generic' => q#hora de Mauricio#,
				'standard' => q#hora estándar de Mauricio#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#hora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#hora de verano del noroeste de México#,
				'generic' => q#hora del noroeste de México#,
				'standard' => q#hora estándar del noroeste de México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#hora de verano del Pacífico de México#,
				'generic' => q#hora del Pacífico de México#,
				'standard' => q#hora estándar del Pacífico de México#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#hora de verano de Ulán Bator#,
				'generic' => q#hora de Ulán Bator#,
				'standard' => q#hora estándar de Ulán Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#hora de verano de Moscú#,
				'generic' => q#hora de Moscú#,
				'standard' => q#hora estándar de Moscú#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#hora de Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#hora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#hora de Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#hora de verano de Nueva Caledonia#,
				'generic' => q#hora de Nueva Caledonia#,
				'standard' => q#hora estándar de Nueva Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#hora de verano de Nueva Zelanda#,
				'generic' => q#hora de Nueva Zelanda#,
				'standard' => q#hora estándar de Nueva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#hora de verano de Terranova#,
				'generic' => q#hora de Terranova#,
				'standard' => q#hora estándar de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#hora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#hora de verano de la isla Norfolk#,
				'generic' => q#hora de la isla Norfolk#,
				'standard' => q#hora estándar de la isla Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#hora de verano de Fernando de Noronha#,
				'generic' => q#hora de Fernando de Noronha#,
				'standard' => q#hora estándar de Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Hora de las Islas Marianas del Norte#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#hora de verano de Novosibirsk#,
				'generic' => q#hora de Novosibirsk#,
				'standard' => q#hora estándar de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#hora de verano de Omsk#,
				'generic' => q#hora de Omsk#,
				'standard' => q#hora estándar de Omsk#,
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
			exemplarCity => q#Isla de Pascua#,
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
			exemplarCity => q#Fiyi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
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
			exemplarCity => q#Honolulú#,
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
			exemplarCity => q#Numea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palaos#,
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
			exemplarCity => q#Saipán#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahití#,
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
				'daylight' => q#hora de verano de Pakistán#,
				'generic' => q#hora de Pakistán#,
				'standard' => q#hora estándar de Pakistán#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#hora de Palaos#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#hora de Papúa Nueva Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#hora de verano de Paraguay#,
				'generic' => q#hora de Paraguay#,
				'standard' => q#hora estándar de Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#hora de verano de Perú#,
				'generic' => q#hora de Perú#,
				'standard' => q#hora estándar de Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#hora de verano de Filipinas#,
				'generic' => q#hora de Filipinas#,
				'standard' => q#hora estándar de Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#hora de las Islas Fénix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#hora de verano de San Pedro y Miquelón#,
				'generic' => q#hora de San Pedro y Miquelón#,
				'standard' => q#hora estándar de San Pedro y Miquelón#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#hora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#hora de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#hora de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Hora de verano de Qyzylorda#,
				'generic' => q#Hora de Qyzylorda#,
				'standard' => q#Hora estándar de Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#hora de Reunión#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#hora de verano de Sajalín#,
				'generic' => q#hora de Sajalín#,
				'standard' => q#hora estándar de Sajalín#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#hora de verano de Samara#,
				'generic' => q#hora de Samara#,
				'standard' => q#hora estándar de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#hora de verano de Samoa#,
				'generic' => q#hora de Samoa#,
				'standard' => q#hora estándar de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#hora de Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#hora de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#hora de las Islas Salomón#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#hora de Georgia del Sur#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#hora de Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#hora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#hora de Tahití#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#hora de verano de Taipéi#,
				'generic' => q#hora de Taipéi#,
				'standard' => q#hora estándar de Taipéi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#hora de Tayikistán#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#hora de verano de Tonga#,
				'generic' => q#hora de Tonga#,
				'standard' => q#hora estándar de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#hora de verano de Turkmenistán#,
				'generic' => q#hora de Turkmenistán#,
				'standard' => q#hora estándar de Turkmenistán#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#hora de verano de Uruguay#,
				'generic' => q#hora de Uruguay#,
				'standard' => q#hora estándar de Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#hora de verano de Uzbekistán#,
				'generic' => q#hora de Uzbekistán#,
				'standard' => q#hora estándar de Uzbekistán#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#hora de verano de Vanuatu#,
				'generic' => q#hora de Vanuatu#,
				'standard' => q#hora estándar de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#hora de Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#hora de verano de Vladivostok#,
				'generic' => q#hora de Vladivostok#,
				'standard' => q#hora estándar de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#hora de verano de Volgogrado#,
				'generic' => q#hora de Volgogrado#,
				'standard' => q#hora estándar de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#hora de la isla Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#hora de Wallis y Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#hora de verano de Yakutsk#,
				'generic' => q#hora de Yakutsk#,
				'standard' => q#hora estándar de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#hora de verano de Ekaterimburgo#,
				'generic' => q#hora de Ekaterimburgo#,
				'standard' => q#hora estándar de Ekaterimburgo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#hora de Yukón#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
