=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Pt - Package for language Portuguese

=cut

package Locale::CLDR::Locales::Pt;
# This file auto generated from Data\common\main\pt.xml
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

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
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
					rule => q(=#,##0=ª),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ª),
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
					rule => q(=#,##0=º),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=º),
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
		'optional-e' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' e ),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' ),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' ),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vírgula →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(uma),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(duas),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vinte[ e →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trinta[ e →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarenta[ e →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquenta[ e →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessenta[ e →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setenta[ e →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(oitenta[ e →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noventa[ e →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cem),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(cento e →→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(duzentas[ e →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trezentas[ e →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(quatrocentas[ e →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quinhentas[ e →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(seiscentas[ e →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(setecentas[ e →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(oitocentas[ e →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(novecentas[ e →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[→%%spellout-cardinal-feminine-with-e→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{milhão}other{milhões})$[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{bilhão}other{bilhões})$[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{trilhão}other{trilhões})$[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{quatrilhão}other{quatrilhões})$[→%%spellout-cardinal-feminine-with-e→]),
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
		'spellout-cardinal-feminine-with-e' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' e =%spellout-cardinal-feminine=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%optional-e→=%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%optional-e→=%spellout-cardinal-feminine=),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vírgula →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(um),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dois),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(três),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quatro),
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
					rule => q(sete),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(oito),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nove),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dez),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(doze),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(treze),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(catorze),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quinze),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(dezesseis),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dezessete),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(dezoito),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dezenove),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vinte[ e →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trinta[ e →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarenta[ e →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquenta[ e →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessenta[ e →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setenta[ e →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(oitenta[ e →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noventa[ e →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cem),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(cento e →→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(duzentos[ e →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(trezentos[ e →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(quatrocentos[ e →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(quinhentos[ e →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(seiscentos[ e →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(setecentos[ e →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(oitocentos[ e →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(novecentos[ e →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil[→%%spellout-cardinal-masculine-with-e→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← $(cardinal,one{milhão}other{milhões})$[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← $(cardinal,one{bilhão}other{bilhões})$[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← $(cardinal,one{trilhão}other{trilhões})$[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← $(cardinal,one{quatrilhão}other{quatrilhões})$[→%%spellout-cardinal-masculine-with-e→]),
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
		'spellout-cardinal-masculine-with-e' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' e =%spellout-cardinal-masculine=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%optional-e→=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%optional-e→=%spellout-cardinal-masculine=),
				},
			},
		},
		'spellout-numbering' => {
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primeira),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segunda),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terceira),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarta),
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
					rule => q(sétima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(oitava),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nona),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(décima[ →→]),
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
					rule => q(quadragésima[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(quinquagésima[ →→]),
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
					rule => q(quadringentésima[ →→]),
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
					rule => q(octingentésima[ →→]),
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
					rule => q(←%spellout-cardinal-feminine← milésima[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milionésima[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← bilionésima[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← trilionésima[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← quadrilionésima[ →→]),
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
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primeiro),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segundo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terceiro),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarto),
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
					rule => q(sétimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(oitavo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nono),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(décimo[ →→]),
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
					rule => q(quadragésimo[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(quinquagésimo[ →→]),
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
					rule => q(quadringentésimo[ →→]),
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
					rule => q(octingentésimo[ →→]),
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
					rule => q(←%spellout-cardinal-masculine← milionésimo[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← bilionésimo[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← trilionésimo[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← quadrilionésimo[ →→]),
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

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afar',
 				'ab' => 'abcázio',
 				'ace' => 'achém',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adigue',
 				'ae' => 'avéstico',
 				'af' => 'africâner',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'acadiano',
 				'ale' => 'aleúte',
 				'alt' => 'altai meridional',
 				'am' => 'amárico',
 				'an' => 'aragonês',
 				'ang' => 'inglês arcaico',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe moderno',
 				'arc' => 'aramaico',
 				'arn' => 'mapudungun',
 				'arp' => 'arapaho',
 				'ars' => 'árabe négede',
 				'arw' => 'arauaqui',
 				'as' => 'assamês',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'atj' => 'atikamekw',
 				'av' => 'avárico',
 				'awa' => 'awadhi',
 				'ay' => 'aimará',
 				'az' => 'azerbaijano',
 				'az_Arab' => 'azeri sul',
 				'ba' => 'bashkir',
 				'bal' => 'balúchi',
 				'ban' => 'balinês',
 				'bas' => 'basa',
 				'bax' => 'bamum',
 				'bbj' => 'ghomala’',
 				'be' => 'bielorrusso',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'búlgaro',
 				'bgc' => 'hariani',
 				'bgn' => 'balúchi ocidental',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislamá',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetano',
 				'br' => 'bretão',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bósnio',
 				'bss' => 'akoose',
 				'bua' => 'buriato',
 				'bug' => 'buginês',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalão',
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
 				'chg' => 'chagatai',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'chn' => 'jargão Chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cheroqui',
 				'chy' => 'cheiene',
 				'ckb' => 'curdo central',
 				'ckb@alt=menu' => 'curdo, central',
 				'ckb@alt=variant' => 'curdo sorâni',
 				'clc' => 'chilcotin',
 				'co' => 'corso',
 				'cop' => 'copta',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'tártara da Crimeia',
 				'crj' => 'cree do sudeste',
 				'crk' => 'cree das planícies',
 				'crl' => 'cree do nordeste',
 				'crm' => 'moose cree',
 				'crr' => 'algonquiano Carolina',
 				'crs' => 'crioulo francês seichelense',
 				'cs' => 'tcheco',
 				'csb' => 'kashubian',
 				'csw' => 'cree swampy',
 				'cu' => 'eslavo eclesiástico',
 				'cv' => 'tchuvache',
 				'cy' => 'galês',
 				'da' => 'dinamarquês',
 				'dak' => 'dacota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'alemão',
 				'de_CH' => 'alto alemão (Suíça)',
 				'del' => 'delaware',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'baixo sorábio',
 				'dua' => 'duala',
 				'dum' => 'holandês médio',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'diúla',
 				'dz' => 'dzonga',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efique',
 				'egy' => 'egípcio arcaico',
 				'eka' => 'ekajuk',
 				'el' => 'grego',
 				'elx' => 'elamite',
 				'en' => 'inglês',
 				'enm' => 'inglês médio',
 				'eo' => 'esperanto',
 				'es' => 'espanhol',
 				'et' => 'estoniano',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
 				'fa_AF' => 'dari',
 				'fan' => 'fangue',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'finlandês',
 				'fil' => 'filipino',
 				'fj' => 'fijiano',
 				'fo' => 'feroês',
 				'fon' => 'fom',
 				'fr' => 'francês',
 				'frc' => 'francês cajun',
 				'frm' => 'francês médio',
 				'fro' => 'francês arcaico',
 				'frr' => 'frísio setentrional',
 				'frs' => 'frisão oriental',
 				'fur' => 'friulano',
 				'fy' => 'frísio ocidental',
 				'ga' => 'irlandês',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gan' => 'gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaia',
 				'gd' => 'gaélico escocês',
 				'gez' => 'geez',
 				'gil' => 'gilbertês',
 				'gl' => 'galego',
 				'gmh' => 'alto alemão médio',
 				'gn' => 'guarani',
 				'goh' => 'alemão arcaico alto',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gótico',
 				'grb' => 'grebo',
 				'grc' => 'grego arcaico',
 				'gsw' => 'alemão (Suíça)',
 				'gu' => 'guzerate',
 				'guz' => 'gusii',
 				'gv' => 'manx',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hauçá',
 				'hai' => 'haida',
 				'hak' => 'hacá',
 				'haw' => 'havaiano',
 				'hax' => 'haida do sul',
 				'he' => 'hebraico',
 				'hi' => 'híndi',
 				'hil' => 'hiligaynon',
 				'hit' => 'hitita',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croata',
 				'hsb' => 'alto sorábio',
 				'hsn' => 'xiang',
 				'ht' => 'haitiano',
 				'hu' => 'húngaro',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armênio',
 				'hz' => 'herero',
 				'ia' => 'interlíngua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonésio',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiaque',
 				'ikt' => 'inuktitut canadense ocidental',
 				'ilo' => 'ilocano',
 				'inh' => 'inguche',
 				'io' => 'ido',
 				'is' => 'islandês',
 				'it' => 'italiano',
 				'iu' => 'inuktitut',
 				'ja' => 'japonês',
 				'jbo' => 'lojban',
 				'jgo' => 'nguemba',
 				'jmc' => 'machame',
 				'jpr' => 'judaico-persa',
 				'jrb' => 'judaico-arábico',
 				'jv' => 'javanês',
 				'ka' => 'georgiano',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardiano',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'maconde',
 				'kea' => 'crioulo cabo-verdiano',
 				'kfo' => 'koro',
 				'kg' => 'congolês',
 				'kgp' => 'caingangue',
 				'kha' => 'khasi',
 				'kho' => 'khotanês',
 				'khq' => 'koyra chiini',
 				'ki' => 'quicuio',
 				'kj' => 'cuanhama',
 				'kk' => 'cazaque',
 				'kkj' => 'kako',
 				'kl' => 'groenlandês',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'quimbundo',
 				'kn' => 'canarim',
 				'ko' => 'coreano',
 				'koi' => 'komi-permyak',
 				'kok' => 'concani',
 				'kos' => 'kosraean',
 				'kpe' => 'kpelle',
 				'kr' => 'canúri',
 				'krc' => 'karachay-balkar',
 				'krl' => 'carélio',
 				'kru' => 'kurukh',
 				'ks' => 'caxemira',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'curdo',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'córnico',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'quirguiz',
 				'la' => 'latim',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburguês',
 				'lez' => 'lezgui',
 				'lg' => 'luganda',
 				'li' => 'limburguês',
 				'lil' => 'lillooet',
 				'lkt' => 'lacota',
 				'lmo' => 'lombardo',
 				'ln' => 'lingala',
 				'lo' => 'laosiano',
 				'lol' => 'mongo',
 				'lou' => 'crioulo da Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri setentrional',
 				'lsm' => 'saamia',
 				'lt' => 'lituano',
 				'lu' => 'luba-catanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'letão',
 				'mad' => 'madurês',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandinga',
 				'mas' => 'massai',
 				'mde' => 'maba',
 				'mdf' => 'mocsa',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malgaxe',
 				'mga' => 'irlandês médio',
 				'mgh' => 'macua',
 				'mgo' => 'meta’',
 				'mh' => 'marshalês',
 				'mi' => 'maori',
 				'mic' => 'miquemaque',
 				'min' => 'minangkabau',
 				'mk' => 'macedônio',
 				'ml' => 'malaiala',
 				'mn' => 'mongol',
 				'mnc' => 'manchu',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'moicano',
 				'mos' => 'mossi',
 				'mr' => 'marati',
 				'ms' => 'malaio',
 				'mt' => 'maltês',
 				'mua' => 'mundang',
 				'mul' => 'múltiplos idiomas',
 				'mus' => 'creek',
 				'mwl' => 'mirandês',
 				'mwr' => 'marwari',
 				'my' => 'birmanês',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazandarani',
 				'na' => 'nauruano',
 				'nan' => 'min nan',
 				'nap' => 'napolitano',
 				'naq' => 'nama',
 				'nb' => 'bokmål norueguês',
 				'nd' => 'ndebele do norte',
 				'nds' => 'baixo alemão',
 				'nds_NL' => 'baixo saxão',
 				'ne' => 'nepalês',
 				'new' => 'newari',
 				'ng' => 'dongo',
 				'nia' => 'nias',
 				'niu' => 'niueano',
 				'nl' => 'holandês',
 				'nl_BE' => 'flamengo',
 				'nmg' => 'kwasio',
 				'nn' => 'nynorsk norueguês',
 				'nnh' => 'ngiemboon',
 				'no' => 'norueguês',
 				'nog' => 'nogai',
 				'non' => 'nórdico arcaico',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele do sul',
 				'nso' => 'soto setentrional',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari clássico',
 				'ny' => 'nianja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitânico',
 				'oj' => 'ojibwa',
 				'ojb' => 'ojibwa do noroeste',
 				'ojc' => 'ojibwa central',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwa ocidental',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'oriá',
 				'os' => 'osseto',
 				'osa' => 'osage',
 				'ota' => 'turco otomano',
 				'pa' => 'panjabi',
 				'pag' => 'pangasinã',
 				'pal' => 'pálavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauano',
 				'pcm' => 'pidgin nigeriano',
 				'peo' => 'persa arcaico',
 				'phn' => 'fenício',
 				'pi' => 'páli',
 				'pis' => 'pijin',
 				'pl' => 'polonês',
 				'pon' => 'pohnpeiano',
 				'pqm' => 'malecite–passamaquoddy',
 				'prg' => 'prussiano',
 				'pro' => 'provençal arcaico',
 				'ps' => 'pashto',
 				'ps@alt=variant' => 'pushto',
 				'pt' => 'português',
 				'qu' => 'quíchua',
 				'quc' => 'quiché',
 				'raj' => 'rajastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongano',
 				'rhg' => 'ruainga',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romeno',
 				'ro_MD' => 'moldávio',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'ru' => 'russo',
 				'rup' => 'aromeno',
 				'rw' => 'quiniaruanda',
 				'rwk' => 'rwa',
 				'sa' => 'sânscrito',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'sam' => 'aramaico samaritano',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siciliano',
 				'sco' => 'scots',
 				'sd' => 'sindi',
 				'sdh' => 'curdo meridional',
 				'se' => 'sami setentrional',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'irlandês arcaico',
 				'sh' => 'servo-croata',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'árabe chadiano',
 				'si' => 'cingalês',
 				'sid' => 'sidamo',
 				'sk' => 'eslovaco',
 				'sl' => 'esloveno',
 				'slh' => 'lushootseed do sul',
 				'sm' => 'samoano',
 				'sma' => 'sami meridional',
 				'smj' => 'sami de Lule',
 				'smn' => 'lapão de Inari',
 				'sms' => 'sami de Skolt',
 				'sn' => 'xona',
 				'snk' => 'soninquê',
 				'so' => 'somali',
 				'sog' => 'sogdiano',
 				'sq' => 'albanês',
 				'sr' => 'sérvio',
 				'srn' => 'surinamês',
 				'srr' => 'serere',
 				'ss' => 'suázi',
 				'ssy' => 'saho',
 				'st' => 'soto do sul',
 				'str' => 'salish do estreito norte',
 				'su' => 'sundanês',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumério',
 				'sv' => 'sueco',
 				'sw' => 'suaíli',
 				'sw_CD' => 'suaíli do Congo',
 				'swb' => 'comoriano',
 				'syc' => 'siríaco clássico',
 				'syr' => 'siríaco',
 				'ta' => 'tâmil',
 				'tce' => 'tutchone do sul',
 				'te' => 'télugo',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tétum',
 				'tg' => 'tadjique',
 				'tgx' => 'tagish',
 				'th' => 'tailandês',
 				'tht' => 'tahltan',
 				'ti' => 'tigrínia',
 				'tig' => 'tigré',
 				'tiv' => 'tiv',
 				'tk' => 'turcomeno',
 				'tkl' => 'toquelauano',
 				'tl' => 'tagalo',
 				'tlh' => 'klingon',
 				'tli' => 'tlinguite',
 				'tmh' => 'tamaxeque',
 				'tn' => 'tswana',
 				'to' => 'tonganês',
 				'tog' => 'tonganês de Nyasa',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshiano',
 				'tt' => 'tártaro',
 				'ttm' => 'tutchone setentrional',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluano',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'taitiano',
 				'tyv' => 'tuviniano',
 				'tzm' => 'tamazight do Atlas Central',
 				'udm' => 'udmurte',
 				'ug' => 'uigur',
 				'uga' => 'ugarítico',
 				'uk' => 'ucraniano',
 				'umb' => 'umbundu',
 				'und' => 'idioma desconhecido',
 				'ur' => 'urdu',
 				'uz' => 'uzbeque',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vietnamita',
 				'vo' => 'volapuque',
 				'vot' => 'vótico',
 				'vun' => 'vunjo',
 				'wa' => 'valão',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'uolofe',
 				'wuu' => 'wu',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xog' => 'lusoga',
 				'yao' => 'yao',
 				'yap' => 'yapese',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'iídiche',
 				'yo' => 'iorubá',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantonês',
 				'yue@alt=menu' => 'cantonês (tradicional)',
 				'za' => 'zhuang',
 				'zap' => 'zapoteco',
 				'zbl' => 'símbolos blis',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazirte marroqino padrão',
 				'zh' => 'chinês',
 				'zh@alt=menu' => 'chinês, mandarim',
 				'zh_Hans' => 'chinês simplificado',
 				'zh_Hans@alt=long' => 'chinês mandarim (simplificado)',
 				'zh_Hant' => 'chinês tradicional',
 				'zh_Hant@alt=long' => 'chinês mandarim (tradicional)',
 				'zu' => 'zulu',
 				'zun' => 'zunhi',
 				'zxx' => 'sem conteúdo linguístico',
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
			'Adlm' => 'adlam',
 			'Arab' => 'árabe',
 			'Arab@alt=variant' => 'perso-árabe',
 			'Aran' => 'nastaliq',
 			'Armi' => 'armi',
 			'Armn' => 'armênio',
 			'Avst' => 'avéstico',
 			'Bali' => 'balinês',
 			'Bamu' => 'bamum',
 			'Batk' => 'bataque',
 			'Beng' => 'bengali',
 			'Blis' => 'símbolos bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'buginês',
 			'Buhd' => 'buhid',
 			'Cakm' => 'cakm',
 			'Cans' => 'escrita silábica unificada dos aborígenes canadenses',
 			'Cari' => 'cariano',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'cóptico',
 			'Cprt' => 'cipriota',
 			'Cyrl' => 'cirílico',
 			'Cyrs' => 'cirílico eslavo eclesiástico',
 			'Deva' => 'devanágari',
 			'Dsrt' => 'deseret',
 			'Egyd' => 'demótico egípcio',
 			'Egyh' => 'hierático egípcio',
 			'Egyp' => 'hieróglifos egípcios',
 			'Ethi' => 'etiópico',
 			'Geok' => 'khutsuri georgiano',
 			'Geor' => 'georgiano',
 			'Glag' => 'glagolítico',
 			'Goth' => 'gótico',
 			'Grek' => 'grego',
 			'Gujr' => 'guzerate',
 			'Guru' => 'gurmuqui',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'simplificado',
 			'Hans@alt=stand-alone' => 'han simplificado',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hebr' => 'hebraico',
 			'Hira' => 'hiragana',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'silabários japoneses',
 			'Hung' => 'húngaro antigo',
 			'Inds' => 'indo',
 			'Ital' => 'itálico antigo',
 			'Jamo' => 'jamo',
 			'Java' => 'javanês',
 			'Jpan' => 'japonês',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'coreano',
 			'Kthi' => 'kthi',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'latim fraktur',
 			'Latg' => 'latim gaélico',
 			'Latn' => 'latim',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'linear A',
 			'Linb' => 'linear B',
 			'Lisu' => 'lisu',
 			'Lyci' => 'lício',
 			'Lydi' => 'lídio',
 			'Mand' => 'mandaico',
 			'Mani' => 'maniqueano',
 			'Maya' => 'hieróglifos maias',
 			'Merc' => 'meroítico cursivo',
 			'Mero' => 'meroítico',
 			'Mlym' => 'malaiala',
 			'Mong' => 'mongol',
 			'Moon' => 'moon',
 			'Mtei' => 'meitei mayek',
 			'Mymr' => 'birmanês',
 			'Nkoo' => 'n’ko',
 			'Ogam' => 'ogâmico',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriá',
 			'Osma' => 'osmania',
 			'Perm' => 'pérmico antigo',
 			'Phag' => 'phags-pa',
 			'Phli' => 'phli',
 			'Phlp' => 'phlp',
 			'Phlv' => 'pahlavi antigo',
 			'Phnx' => 'fenício',
 			'Plrd' => 'fonético pollard',
 			'Prti' => 'prti',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'rúnico',
 			'Samr' => 'samaritano',
 			'Sara' => 'sarati',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'signwriting',
 			'Shaw' => 'shaviano',
 			'Sinh' => 'cingalês',
 			'Sund' => 'sundanês',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siríaco',
 			'Syre' => 'siríaco estrangelo',
 			'Syrj' => 'siríaco ocidental',
 			'Syrn' => 'siríaco oriental',
 			'Tagb' => 'tagbanwa',
 			'Tale' => 'tai Le',
 			'Talu' => 'novo tai lue',
 			'Taml' => 'tâmil',
 			'Tavt' => 'tavt',
 			'Telu' => 'télugo',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalo',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandês',
 			'Tibt' => 'tibetano',
 			'Ugar' => 'ugarítico',
 			'Vaii' => 'vai',
 			'Visp' => 'visible speech',
 			'Xpeo' => 'persa antigo',
 			'Xsux' => 'sumério-acadiano cuneiforme',
 			'Yiii' => 'yi',
 			'Zinh' => 'herdado',
 			'Zmth' => 'notação matemática',
 			'Zsye' => 'emoji',
 			'Zsym' => 'zsym',
 			'Zxxx' => 'ágrafo',
 			'Zyyy' => 'comum',
 			'Zzzz' => 'escrita desconhecida',

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
 			'003' => 'América do Norte',
 			'005' => 'América do Sul',
 			'009' => 'Oceania',
 			'011' => 'África Ocidental',
 			'013' => 'América Central',
 			'014' => 'África Oriental',
 			'015' => 'África do Norte',
 			'017' => 'África Central',
 			'018' => 'África Meridional',
 			'019' => 'Américas',
 			'021' => 'América Setentrional',
 			'029' => 'Caribe',
 			'030' => 'Ásia Oriental',
 			'034' => 'Ásia Meridional',
 			'035' => 'Sudeste Asiático',
 			'039' => 'Europa Meridional',
 			'053' => 'Australásia',
 			'054' => 'Melanésia',
 			'057' => 'Região da Micronésia',
 			'061' => 'Polinésia',
 			'142' => 'Ásia',
 			'143' => 'Ásia Central',
 			'145' => 'Ásia Ocidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa Setentrional',
 			'155' => 'Europa Ocidental',
 			'202' => 'África Subsaariana',
 			'419' => 'América Latina',
 			'AC' => 'Ilha de Ascensão',
 			'AD' => 'Andorra',
 			'AE' => 'Emirados Árabes Unidos',
 			'AF' => 'Afeganistão',
 			'AG' => 'Antígua e Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albânia',
 			'AM' => 'Armênia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Áustria',
 			'AU' => 'Austrália',
 			'AW' => 'Aruba',
 			'AX' => 'Ilhas Aland',
 			'AZ' => 'Azerbaijão',
 			'BA' => 'Bósnia e Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélgica',
 			'BF' => 'Burquina Faso',
 			'BG' => 'Bulgária',
 			'BH' => 'Barein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'São Bartolomeu',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Países Baixos Caribenhos',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Butão',
 			'BV' => 'Ilha Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Bielorrússia',
 			'BZ' => 'Belize',
 			'CA' => 'Canadá',
 			'CC' => 'Ilhas Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'República Democrática do Congo',
 			'CF' => 'República Centro-Africana',
 			'CG' => 'República do Congo',
 			'CG@alt=variant' => 'Congo',
 			'CH' => 'Suíça',
 			'CI' => 'Costa do Marfim',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Ilhas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camarões',
 			'CN' => 'China',
 			'CO' => 'Colômbia',
 			'CP' => 'Ilha de Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Ilha Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Tchéquia',
 			'CZ@alt=variant' => 'República Tcheca',
 			'DE' => 'Alemanha',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Argélia',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Equador',
 			'EE' => 'Estônia',
 			'EG' => 'Egito',
 			'EH' => 'Saara Ocidental',
 			'ER' => 'Eritreia',
 			'ES' => 'Espanha',
 			'ET' => 'Etiópia',
 			'EU' => 'União Europeia',
 			'EZ' => 'zona do euro',
 			'FI' => 'Finlândia',
 			'FJ' => 'Fiji',
 			'FK' => 'Ilhas Malvinas',
 			'FK@alt=variant' => 'Ilhas Malvinas (Ilhas Falkland)',
 			'FM' => 'Micronésia',
 			'FO' => 'Ilhas Faroé',
 			'FR' => 'França',
 			'GA' => 'Gabão',
 			'GB' => 'Reino Unido',
 			'GD' => 'Granada',
 			'GE' => 'Geórgia',
 			'GF' => 'Guiana Francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlândia',
 			'GM' => 'Gâmbia',
 			'GN' => 'Guiné',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guiné Equatorial',
 			'GR' => 'Grécia',
 			'GS' => 'Ilhas Geórgia do Sul e Sandwich do Sul',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guiné-Bissau',
 			'GY' => 'Guiana',
 			'HK' => 'Hong Kong, RAE da China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ilhas Heard e McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croácia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungria',
 			'IC' => 'Ilhas Canárias',
 			'ID' => 'Indonésia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Ilha de Man',
 			'IN' => 'Índia',
 			'IO' => 'Território Britânico do Oceano Índico',
 			'IO@alt=chagos' => 'Arquipélago de Chagos',
 			'IQ' => 'Iraque',
 			'IR' => 'Irã',
 			'IS' => 'Islândia',
 			'IT' => 'Itália',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordânia',
 			'JP' => 'Japão',
 			'KE' => 'Quênia',
 			'KG' => 'Quirguistão',
 			'KH' => 'Camboja',
 			'KI' => 'Quiribati',
 			'KM' => 'Comores',
 			'KN' => 'São Cristóvão e Névis',
 			'KP' => 'Coreia do Norte',
 			'KR' => 'Coreia do Sul',
 			'KW' => 'Kuwait',
 			'KY' => 'Ilhas Cayman',
 			'KZ' => 'Cazaquistão',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
 			'LC' => 'Santa Lúcia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libéria',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituânia',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letônia',
 			'LY' => 'Líbia',
 			'MA' => 'Marrocos',
 			'MC' => 'Mônaco',
 			'MD' => 'Moldávia',
 			'ME' => 'Montenegro',
 			'MF' => 'São Martinho',
 			'MG' => 'Madagascar',
 			'MH' => 'Ilhas Marshall',
 			'MK' => 'Macedônia do Norte',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birmânia)',
 			'MN' => 'Mongólia',
 			'MO' => 'Macau, RAE da China',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Ilhas Marianas do Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritânia',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurício',
 			'MV' => 'Maldivas',
 			'MW' => 'Malaui',
 			'MX' => 'México',
 			'MY' => 'Malásia',
 			'MZ' => 'Moçambique',
 			'NA' => 'Namíbia',
 			'NC' => 'Nova Caledônia',
 			'NE' => 'Níger',
 			'NF' => 'Ilha Norfolk',
 			'NG' => 'Nigéria',
 			'NI' => 'Nicarágua',
 			'NL' => 'Países Baixos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelândia',
 			'NZ@alt=variant' => 'Aotearoa da Nova Zelândia',
 			'OM' => 'Omã',
 			'PA' => 'Panamá',
 			'PE' => 'Peru',
 			'PF' => 'Polinésia Francesa',
 			'PG' => 'Papua-Nova Guiné',
 			'PH' => 'Filipinas',
 			'PK' => 'Paquistão',
 			'PL' => 'Polônia',
 			'PM' => 'São Pedro e Miquelão',
 			'PN' => 'Ilhas Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Territórios palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Catar',
 			'QO' => 'Oceania Remota',
 			'RE' => 'Reunião',
 			'RO' => 'Romênia',
 			'RS' => 'Sérvia',
 			'RU' => 'Rússia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arábia Saudita',
 			'SB' => 'Ilhas Salomão',
 			'SC' => 'Seicheles',
 			'SD' => 'Sudão',
 			'SE' => 'Suécia',
 			'SG' => 'Singapura',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovênia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Eslováquia',
 			'SL' => 'Serra Leoa',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somália',
 			'SR' => 'Suriname',
 			'SS' => 'Sudão do Sul',
 			'ST' => 'São Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Síria',
 			'SZ' => 'Essuatíni',
 			'SZ@alt=variant' => 'Suazilândia',
 			'TA' => 'Tristão da Cunha',
 			'TC' => 'Ilhas Turcas e Caicos',
 			'TD' => 'Chade',
 			'TF' => 'Territórios Franceses do Sul',
 			'TG' => 'Togo',
 			'TH' => 'Tailândia',
 			'TJ' => 'Tadjiquistão',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'República Democrática de Timor-Leste',
 			'TM' => 'Turcomenistão',
 			'TN' => 'Tunísia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzânia',
 			'UA' => 'Ucrânia',
 			'UG' => 'Uganda',
 			'UM' => 'Ilhas Menores Distantes dos EUA',
 			'UN' => 'Nações Unidas',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Estados Unidos',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbequistão',
 			'VA' => 'Cidade do Vaticano',
 			'VC' => 'São Vicente e Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Ilhas Virgens Britânicas',
 			'VI' => 'Ilhas Virgens Americanas',
 			'VN' => 'Vietnã',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudossotaques',
 			'XB' => 'Pseudobidirecional',
 			'XK' => 'Kosovo',
 			'YE' => 'Iêmen',
 			'YT' => 'Mayotte',
 			'ZA' => 'África do Sul',
 			'ZM' => 'Zâmbia',
 			'ZW' => 'Zimbábue',
 			'ZZ' => 'Região desconhecida',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia alemã tradicional',
 			'1994' => 'ortografia resiana padronizada',
 			'1996' => 'ortografia alemã de 1996',
 			'1606NICT' => 'francês antigo de 1606',
 			'1694ACAD' => 'francês da idade moderna',
 			'1959ACAD' => 'acadêmico',
 			'ABL1943' => 'Formulário Ortográfico de 1943',
 			'AO1990' => 'Acordo Ortográfico da Língua Portuguesa de 1990',
 			'AREVELA' => 'armênio oriental',
 			'AREVMDA' => 'armênio ocidental',
 			'BAKU1926' => 'alfabeto latino turco unificado',
 			'BISCAYAN' => 'biscainho',
 			'BISKE' => 'dialeto san giorgio/bila',
 			'BOONT' => 'boontling',
 			'COLB1945' => 'Convenção Ortográfica Luso-Brasileira de 1945',
 			'FONIPA' => 'fonética do Alfabeto Fonético Internacional',
 			'FONUPA' => 'fonética do Alfabeto Fonético Urálico',
 			'HEPBURN' => 'romanização hepburn',
 			'HOGNORSK' => 'alto noruego',
 			'KKCOR' => 'ortografia comum',
 			'LIPAW' => 'dialeto lipovaz de Resian',
 			'MONOTON' => 'monotônico',
 			'NDYUKA' => 'dialeto ndyuka',
 			'NEDIS' => 'dialeto natisone',
 			'NJIVA' => 'dialeto gniva/njiva',
 			'OSOJS' => 'dialeto oseacco/osojane',
 			'PAMAKA' => 'dialeto pamaka',
 			'PINYIN' => 'romanização Pinyin',
 			'POLYTON' => 'politônico',
 			'POSIX' => 'computador',
 			'REVISED' => 'ortografia revisada',
 			'ROZAJ' => 'resiano',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'inglês padrão escocês',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'dialeto stolvizza/solbica',
 			'TARASK' => 'ortografia taraskievica',
 			'UCCOR' => 'ortografia unificada',
 			'UCRCOR' => 'ortografia revisada e unificada',
 			'VALENCIA' => 'valenciano',
 			'WADEGILE' => 'romanização Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Calendário',
 			'cf' => 'Formato de moeda',
 			'colalternate' => 'Ignorar classificação de símbolos',
 			'colbackwards' => 'Classificação de acentos invertida',
 			'colcasefirst' => 'Ordem de maiúsculas/minúsculas',
 			'colcaselevel' => 'Classificação com distinção entre maiúsculas e minúsculas',
 			'collation' => 'Ordenação',
 			'colnormalization' => 'Classificação normalizada',
 			'colnumeric' => 'Classificação numérica',
 			'colstrength' => 'Prioridade da classificação',
 			'currency' => 'Moeda',
 			'hc' => 'Ciclo de horário (12 vs. 24)',
 			'lb' => 'Estilo de quebra de linha',
 			'ms' => 'Sistema de medição',
 			'numbers' => 'Números',
 			'timezone' => 'Fuso horário',
 			'va' => 'Variante de localidade',
 			'x' => 'Uso privado',

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
 				'buddhist' => q{Calendário Budista},
 				'chinese' => q{Calendário Chinês},
 				'coptic' => q{Calendário Copta},
 				'dangi' => q{Calendário Dangi},
 				'ethiopic' => q{Calendário Etíope},
 				'ethiopic-amete-alem' => q{Calendário Amete Alem da Etiópia},
 				'gregorian' => q{Calendário Gregoriano},
 				'hebrew' => q{Calendário Hebraico},
 				'indian' => q{Calendário Nacional Indiano},
 				'islamic' => q{Calendário Hegírico},
 				'islamic-civil' => q{Calendário Hegírico (tabular, época civil)},
 				'islamic-umalqura' => q{Calendário Hegírico (Umm al‑Qura)},
 				'iso8601' => q{Calendário ISO-8601},
 				'japanese' => q{Calendário Japonês},
 				'persian' => q{Calendário Persa},
 				'roc' => q{Calendário da República da China},
 			},
 			'cf' => {
 				'account' => q{Formato de moeda para contabilidade},
 				'standard' => q{Formato de moeda padrão},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Classificar símbolos},
 				'shifted' => q{Classificar ignorando símbolos},
 			},
 			'colbackwards' => {
 				'no' => q{Classificar acentos normalmente},
 				'yes' => q{Classificação reversa de acentos},
 			},
 			'colcasefirst' => {
 				'lower' => q{Classificar por minúsculas},
 				'no' => q{Classificação normal de maiúsculas e minúsculas},
 				'upper' => q{Classificar por maiúsculas},
 			},
 			'colcaselevel' => {
 				'no' => q{Classificação sem diferenciação de maiúsculas e minúsculas},
 				'yes' => q{Classificação com diferenciação de maiúsculas e minúsculas},
 			},
 			'collation' => {
 				'big5han' => q{Ordem do Chinês Tradicional - Big5},
 				'compat' => q{Ordem anterior, para compatibilidade},
 				'dictionary' => q{Ordem do dicionário},
 				'ducet' => q{Ordem padrão do Unicode},
 				'eor' => q{Regras europeias de ordenação},
 				'gb2312han' => q{Ordem do Chinês Simplificado - GB2312},
 				'phonebook' => q{Ordem de lista telefônica},
 				'phonetic' => q{Ordem de classificação fonética},
 				'pinyin' => q{Ordem Pin-yin},
 				'reformed' => q{Ordem reformulada},
 				'search' => q{Pesquisa de uso geral},
 				'searchjl' => q{Pesquisar por consonante inicial hangul},
 				'standard' => q{Ordem padrão},
 				'stroke' => q{Ordem dos traços},
 				'traditional' => q{Ordem tradicional},
 				'unihan' => q{Ordem por Radical-Traços},
 				'zhuyin' => q{Ordem Zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Classificar sem normalização},
 				'yes' => q{Classificar Unicode normalizado},
 			},
 			'colnumeric' => {
 				'no' => q{Classificar dígitos individualmente},
 				'yes' => q{Classificar dígitos numericamente},
 			},
 			'colstrength' => {
 				'identical' => q{Classificar tudo},
 				'primary' => q{Classificar somente letras básicas},
 				'quaternary' => q{Classificar acentos/maiúsculas e minúsculas/largura/kana},
 				'secondary' => q{Classificar acentos},
 				'tertiary' => q{Classificar acentos/maiúsculas e minúsculas/largura},
 			},
 			'd0' => {
 				'fwidth' => q{Largura inteira},
 				'hwidth' => q{Meia largura},
 				'npinyin' => q{Numérico},
 			},
 			'hc' => {
 				'h11' => q{Sistema de 12 horas (0–11)},
 				'h12' => q{Sistema de 12 horas (1–12)},
 				'h23' => q{Sistema de 24 horas (0–23)},
 				'h24' => q{Sistema de 24 horas (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Quebra de linha com estilo solto},
 				'normal' => q{Quebra de linha com estilo normal},
 				'strict' => q{Quebra de linha com estilo estrito},
 			},
 			'm0' => {
 				'bgn' => q{Transliteração BGN EUA},
 				'ungegn' => q{Transliteração UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistema métrico},
 				'uksystem' => q{Sistema de medição imperial},
 				'ussystem' => q{Sistema de medição americano},
 			},
 			'numbers' => {
 				'arab' => q{Algarismos indo-arábicos},
 				'arabext' => q{Algarismos indo-arábicos estendidos},
 				'armn' => q{Algarismos armênios},
 				'armnlow' => q{Algarismos armênios minúsculos},
 				'beng' => q{Algarismos bengali},
 				'cakm' => q{Algarismos chakma},
 				'deva' => q{Algarismos devanágari},
 				'ethi' => q{Algarismos etiopianos},
 				'finance' => q{Numerais financeiros},
 				'fullwide' => q{Algarismos em extensão total},
 				'geor' => q{Algarismos georgianos},
 				'grek' => q{Algarismos gregos},
 				'greklow' => q{Algarismos gregos minúsculos},
 				'gujr' => q{Algarismos guzerate},
 				'guru' => q{Algarismos gurmuqui},
 				'hanidec' => q{Algarismos decimais chineses},
 				'hans' => q{Algarismos chineses simplificados},
 				'hansfin' => q{Algarismos financeiros chineses simplificados},
 				'hant' => q{Algarismos chineses tradicionais},
 				'hantfin' => q{Algarismos financeiros chineses tradicionais},
 				'hebr' => q{Algarismos hebraicos},
 				'java' => q{Algarismos javaneses},
 				'jpan' => q{Algarismos japoneses},
 				'jpanfin' => q{Algarismos financeiros japoneses},
 				'khmr' => q{Algarismos khmer},
 				'knda' => q{Algarismos canareses},
 				'laoo' => q{Algarismos laosianos},
 				'latn' => q{Algarismos ocidentais},
 				'mlym' => q{Algarismos malaialos},
 				'mong' => q{Algarismos mongóis},
 				'mtei' => q{Algarismos meetei mayek},
 				'mymr' => q{Algarismos mianmarenses},
 				'native' => q{Algarismos nativos},
 				'olck' => q{Algarismos ol chiki},
 				'orya' => q{Algarismos oriá},
 				'roman' => q{Algarismos romanos},
 				'romanlow' => q{Algarismos romanos minúsculos},
 				'taml' => q{Algarismos tâmil tradicionais},
 				'tamldec' => q{Algarismos tâmil},
 				'telu' => q{Algarismos telugos},
 				'thai' => q{Algarismos tailandeses},
 				'tibt' => q{Algarismos tibetanos},
 				'traditional' => q{Numerais tradicionais},
 				'vaii' => q{Algarismos vai},
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
 			'UK' => q{Reino Unido},
 			'US' => q{Estados Unidos},

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
 			'script' => 'Alfabeto: {0}',
 			'region' => 'Região: {0}',

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
			auxiliary => qr{[ªăåäā æ èĕëē ìĭîïī ñ ºŏöøō œ ùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aáàâã b cç d eéê f g h ií j k l m n oóòôõ p q r s t uú v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
		};
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direção cardeal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direção cardeal),
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
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(decí{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(decí{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(picô{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(picô{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femtô{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femtô{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(attô{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(attô{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centí{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centí{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zeptô{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zeptô{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ioctô{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ioctô{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milí{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milí{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micrô{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micrô{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanô{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanô{0}),
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
						'1' => q(zeta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(quilô{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(quilô{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
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
						'one' => q({0} força g),
						'other' => q({0} força g),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'one' => q({0} força g),
						'other' => q({0} força g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo ao quadrado),
						'one' => q({0} metro por segundo ao quadrado),
						'other' => q({0} metros por segundo ao quadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metros por segundo ao quadrado),
						'one' => q({0} metro por segundo ao quadrado),
						'other' => q({0} metros por segundo ao quadrado),
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
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'one' => q({0} radiano),
						'other' => q({0} radianos),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'one' => q({0} radiano),
						'other' => q({0} radianos),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(revoluções),
						'one' => q({0} revolução),
						'other' => q({0} revoluções),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(revoluções),
						'one' => q({0} revolução),
						'other' => q({0} revoluções),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(masculine),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(masculine),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros quadrados),
						'one' => q({0} centímetro quadrado),
						'other' => q({0} centímetros quadrados),
						'per' => q({0} por centímetro quadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetros quadrados),
						'one' => q({0} centímetro quadrado),
						'other' => q({0} centímetros quadrados),
						'per' => q({0} por centímetro quadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'name' => q(pés quadrados),
						'one' => q({0} pé quadrado),
						'other' => q({0} pés quadrados),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'name' => q(pés quadrados),
						'one' => q({0} pé quadrado),
						'other' => q({0} pés quadrados),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(polegadas quadradas),
						'one' => q({0} polegada quadrada),
						'other' => q({0} polegadas quadradas),
						'per' => q({0} por polegada quadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(polegadas quadradas),
						'one' => q({0} polegada quadrada),
						'other' => q({0} polegadas quadradas),
						'per' => q({0} por polegada quadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros quadrados),
						'one' => q({0} quilômetro quadrado),
						'other' => q({0} quilômetros quadrados),
						'per' => q({0} por quilômetro quadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros quadrados),
						'one' => q({0} quilômetro quadrado),
						'other' => q({0} quilômetros quadrados),
						'per' => q({0} por quilômetro quadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(metros quadrados),
						'one' => q({0} metro quadrado),
						'other' => q({0} metros quadrados),
						'per' => q({0} por metro quadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(metros quadrados),
						'one' => q({0} metro quadrado),
						'other' => q({0} metros quadrados),
						'per' => q({0} por metro quadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(feminine),
						'name' => q(milhas quadradas),
						'one' => q({0} milha quadrada),
						'other' => q({0} milhas quadradas),
						'per' => q({0} por milha quadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(feminine),
						'name' => q(milhas quadradas),
						'one' => q({0} milha quadrada),
						'other' => q({0} milhas quadradas),
						'per' => q({0} por milha quadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jardas quadradas),
						'one' => q({0} jarda quadrada),
						'other' => q({0} jardas quadradas),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jardas quadradas),
						'one' => q({0} jarda quadrada),
						'other' => q({0} jardas quadradas),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'name' => q(itens),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'name' => q(itens),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'one' => q({0} kilate),
						'other' => q({0} kilates),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'one' => q({0} kilate),
						'other' => q({0} kilates),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramas por decilitro),
						'one' => q({0} miligrama por decilitro),
						'other' => q({0} miligramas por decilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramas por decilitro),
						'one' => q({0} miligrama por decilitro),
						'other' => q({0} miligramas por decilitro),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(milimols por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimols por litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(milimols por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimols por litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
						'name' => q(mols),
						'one' => q({0} mol),
						'other' => q({0} mols),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
						'name' => q(mols),
						'one' => q({0} mol),
						'other' => q({0} mols),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'one' => q({0} por cento),
						'other' => q({0} por cento),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'one' => q({0} por cento),
						'other' => q({0} por cento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'one' => q({0} por mil),
						'other' => q({0} por mil),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'one' => q({0} por mil),
						'other' => q({0} por mil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'name' => q(partes por milhão),
						'one' => q({0} parte por milhão),
						'other' => q({0} partes por milhão),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'name' => q(partes por milhão),
						'one' => q({0} parte por milhão),
						'other' => q({0} partes por milhão),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'one' => q({0} ponto base),
						'other' => q({0} pontos base),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'one' => q({0} ponto base),
						'other' => q({0} pontos base),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por 100 quilômetros),
						'one' => q({0} litro por 100 quilômetros),
						'other' => q({0} litros por 100 quilômetros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por 100 quilômetros),
						'one' => q({0} litro por 100 quilômetros),
						'other' => q({0} litros por 100 quilômetros),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por quilômetro),
						'one' => q({0} litro por quilômetro),
						'other' => q({0} litros por quilômetro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litros por quilômetro),
						'one' => q({0} litro por quilômetro),
						'other' => q({0} litros por quilômetro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(milhas por galão),
						'one' => q({0} milha por galão),
						'other' => q({0} milhas por galão),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(milhas por galão),
						'one' => q({0} milha por galão),
						'other' => q({0} milhas por galão),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(milhas por galão imperial),
						'one' => q({0} milha por galão imperial),
						'other' => q({0} milhas por galão imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(milhas por galão imperial),
						'one' => q({0} milha por galão imperial),
						'other' => q({0} milhas por galão imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} leste),
						'north' => q({0} norte),
						'south' => q({0} sul),
						'west' => q({0} oeste),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} leste),
						'north' => q({0} norte),
						'south' => q({0} sul),
						'west' => q({0} oeste),
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
						'1' => q(masculine),
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'name' => q(petabytes),
						'one' => q({0} petabyte),
						'other' => q({0} petabytes),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'name' => q(terabits),
						'one' => q({0} terabit),
						'other' => q({0} terabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
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
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'per' => q({0} por dia),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'per' => q({0} por dia),
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
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(masculine),
						'name' => q(microssegundos),
						'one' => q({0} microssegundo),
						'other' => q({0} microssegundos),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(masculine),
						'name' => q(microssegundos),
						'one' => q({0} microssegundo),
						'other' => q({0} microssegundos),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(masculine),
						'one' => q({0} milissegundo),
						'other' => q({0} milissegundos),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(masculine),
						'one' => q({0} milissegundo),
						'other' => q({0} milissegundos),
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
						'per' => q({0} por mês),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'per' => q({0} por mês),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanossegundos),
						'one' => q({0} nanossegundo),
						'other' => q({0} nanossegundos),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanossegundos),
						'one' => q({0} nanossegundo),
						'other' => q({0} nanossegundos),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(trimestre),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0}/trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(trimestre),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0}/trimestre),
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
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'per' => q({0} por ano),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'per' => q({0} por ano),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unidades térmicas britânicas),
						'one' => q({0} unidade térmica britânica),
						'other' => q({0} unidades térmicas britânicas),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unidades térmicas britânicas),
						'one' => q({0} unidade térmica britânica),
						'other' => q({0} unidades térmicas britânicas),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elétrons-volt),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétrons-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elétrons-volt),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétrons-volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(feminine),
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(feminine),
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(quilowatts-hora),
						'one' => q({0} quilowatt-hora),
						'other' => q({0} quilowatts-hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(quilowatts-hora),
						'one' => q({0} quilowatt-hora),
						'other' => q({0} quilowatts-hora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(unidades térmicas norte-americanas),
						'one' => q({0} unidade térmica norte-americana),
						'other' => q({0} unidades térmicas norte-americanas),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(unidades térmicas norte-americanas),
						'one' => q({0} unidade térmica norte-americana),
						'other' => q({0} unidades térmicas norte-americanas),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilowatts-hora por 100 quilômetros),
						'one' => q({0} quilowatt-hora por 100 quilômetros),
						'other' => q({0} quilowatts-hora por 100 quilômetros),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilowatts-hora por 100 quilômetros),
						'one' => q({0} quilowatt-hora por 100 quilômetros),
						'other' => q({0} quilowatts-hora por 100 quilômetros),
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
						'name' => q(libras de força),
						'one' => q({0} libra de força),
						'other' => q({0} libras de força),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libras de força),
						'one' => q({0} libra de força),
						'other' => q({0} libras de força),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pontos),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pontos),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pontos por centímetro),
						'one' => q({0} ponto por centímetro),
						'other' => q({0} pontos por centímetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pontos por centímetro),
						'one' => q({0} ponto por centímetro),
						'other' => q({0} pontos por centímetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pontos por polegada),
						'one' => q({0} ponto por polegada),
						'other' => q({0} pontos por polegada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pontos por polegada),
						'one' => q({0} ponto por polegada),
						'other' => q({0} pontos por polegada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(em tipográfico),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(em tipográfico),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapixel),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixels por centímetro),
						'one' => q({0} pixel por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixels por centímetro),
						'one' => q({0} pixel por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels por polegada),
						'one' => q({0} pixel por polegada),
						'other' => q({0} pixels por polegada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels por polegada),
						'one' => q({0} pixel por polegada),
						'other' => q({0} pixels por polegada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronômicas),
						'one' => q({0} unidade astronômica),
						'other' => q({0} unidades astronômicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronômicas),
						'one' => q({0} unidade astronômica),
						'other' => q({0} unidades astronômicas),
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
						'1' => q(masculine),
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raio terrestre),
						'one' => q({0} raio terrestre),
						'other' => q({0} raios terrestres),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raio terrestre),
						'one' => q({0} raio terrestre),
						'other' => q({0} raios terrestres),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} braça),
						'other' => q({0} braças),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} braça),
						'other' => q({0} braças),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(feminine),
						'name' => q(polegadas),
						'one' => q({0} polegada),
						'other' => q({0} polegadas),
						'per' => q({0} por polegada),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(feminine),
						'name' => q(polegadas),
						'one' => q({0} polegada),
						'other' => q({0} polegadas),
						'per' => q({0} por polegada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros),
						'one' => q({0} quilômetro),
						'other' => q({0} quilômetros),
						'per' => q({0} por quilômetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros),
						'one' => q({0} quilômetro),
						'other' => q({0} quilômetros),
						'per' => q({0} por quilômetro),
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
						'1' => q(masculine),
						'name' => q(micrômetros),
						'one' => q({0} micrômetro),
						'other' => q({0} micrômetros),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(micrômetros),
						'one' => q({0} micrômetro),
						'other' => q({0} micrômetros),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(feminine),
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(feminine),
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(milhas escandinavas),
						'one' => q({0} milha escandinava),
						'other' => q({0} milhas escandinavas),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(milhas escandinavas),
						'one' => q({0} milha escandinava),
						'other' => q({0} milhas escandinavas),
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
						'1' => q(masculine),
						'name' => q(nanômetros),
						'one' => q({0} nanômetro),
						'other' => q({0} nanômetros),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanômetros),
						'one' => q({0} nanômetro),
						'other' => q({0} nanômetros),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milhas náuticas),
						'one' => q({0} milha náutica),
						'other' => q({0} milhas náuticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milhas náuticas),
						'one' => q({0} milha náutica),
						'other' => q({0} milhas náuticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(masculine),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(masculine),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(picômetros),
						'one' => q({0} picômetro),
						'other' => q({0} picômetros),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(picômetros),
						'one' => q({0} picômetro),
						'other' => q({0} picômetros),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pontos tipográficos),
						'one' => q({0} ponto tipográfico),
						'other' => q({0} pontos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pontos tipográficos),
						'one' => q({0} ponto tipográfico),
						'other' => q({0} pontos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'one' => q({0} raio solar),
						'other' => q({0} raios solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'one' => q({0} raio solar),
						'other' => q({0} raios solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(feminine),
						'one' => q({0} jarda),
						'other' => q({0} jardas),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(feminine),
						'one' => q({0} jarda),
						'other' => q({0} jardas),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candelas),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'name' => q(lúmen),
						'one' => q({0} lúmen),
						'other' => q({0} lúmens),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'name' => q(lúmen),
						'one' => q({0} lúmen),
						'other' => q({0} lúmens),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(feminine),
						'one' => q({0} luminosidade solar),
						'other' => q({0} luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(feminine),
						'one' => q({0} luminosidade solar),
						'other' => q({0} luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(masculine),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(masculine),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(feminine),
						'one' => q({0} massa terrestre),
						'other' => q({0} massas terrestres),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(feminine),
						'one' => q({0} massa terrestre),
						'other' => q({0} massas terrestres),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'one' => q({0} grama),
						'other' => q({0} gramas),
						'per' => q({0} por grama),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'one' => q({0} grama),
						'other' => q({0} gramas),
						'per' => q({0} por grama),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(quilogramas),
						'one' => q({0} quilograma),
						'other' => q({0} quilogramas),
						'per' => q({0} por quilograma),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(quilogramas),
						'one' => q({0} quilograma),
						'other' => q({0} quilogramas),
						'per' => q({0} por quilograma),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'name' => q(microgramas),
						'one' => q({0} micrograma),
						'other' => q({0} microgramas),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'name' => q(microgramas),
						'one' => q({0} micrograma),
						'other' => q({0} microgramas),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(miligramas),
						'one' => q({0} miligrama),
						'other' => q({0} miligramas),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(miligramas),
						'one' => q({0} miligrama),
						'other' => q({0} miligramas),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
						'name' => q(onças),
						'one' => q({0} onça),
						'other' => q({0} onças),
						'per' => q({0} por onça),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
						'name' => q(onças),
						'one' => q({0} onça),
						'other' => q({0} onças),
						'per' => q({0} por onça),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onças troy),
						'one' => q({0} onça troy),
						'other' => q({0} onças troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onças troy),
						'one' => q({0} onça troy),
						'other' => q({0} onças troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(feminine),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(feminine),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(feminine),
						'one' => q({0} massa solar),
						'other' => q({0} massas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(feminine),
						'one' => q({0} massa solar),
						'other' => q({0} massas solares),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} tonelada americana),
						'other' => q({0} toneladas americanas),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} tonelada americana),
						'other' => q({0} toneladas americanas),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
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
						'1' => q(masculine),
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cavalos-vapor),
						'one' => q({0} cavalo-vapor),
						'other' => q({0} cavalos-vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavalos-vapor),
						'one' => q({0} cavalo-vapor),
						'other' => q({0} cavalos-vapor),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} quadrado),
						'other' => q({0} quadrados),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} quadrado),
						'other' => q({0} quadrados),
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
						'name' => q(atmosferas),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferas),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosferas),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferas),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'name' => q(bars),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'name' => q(bars),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(polegadas de mercúrio),
						'one' => q({0} polegada de mercúrio),
						'other' => q({0} polegadas de mercúrio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(polegadas de mercúrio),
						'one' => q({0} polegada de mercúrio),
						'other' => q({0} polegadas de mercúrio),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(quilopascais),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascais),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(quilopascais),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascais),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascais),
						'one' => q({0} megapascal),
						'other' => q({0} megapascais),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascais),
						'one' => q({0} megapascal),
						'other' => q({0} megapascais),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milímetros de mercúrio),
						'one' => q({0} milímetro de mercúrio),
						'other' => q({0} milímetros de mercúrio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milímetros de mercúrio),
						'one' => q({0} milímetro de mercúrio),
						'other' => q({0} milímetros de mercúrio),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'name' => q(pascais),
						'one' => q({0} pascal),
						'other' => q({0} pascais),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'name' => q(pascais),
						'one' => q({0} pascal),
						'other' => q({0} pascais),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libras por polegada quadrada),
						'one' => q({0} libra por polegada quadrada),
						'other' => q({0} libras por polegada quadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libras por polegada quadrada),
						'one' => q({0} libra por polegada quadrada),
						'other' => q({0} libras por polegada quadrada),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} Beaufort),
						'other' => q({0} Beaufort),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} Beaufort),
						'other' => q({0} Beaufort),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(quilômetros por hora),
						'one' => q({0} quilômetro por hora),
						'other' => q({0} quilômetros por hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(quilômetros por hora),
						'one' => q({0} quilômetro por hora),
						'other' => q({0} quilômetros por hora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nós),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nós),
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
						'name' => q(milhas por hora),
						'one' => q({0} milha por hora),
						'other' => q({0} milhas por hora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(milhas por hora),
						'one' => q({0} milha por hora),
						'other' => q({0} milhas por hora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(graus Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graus Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(graus Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graus Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(masculine),
						'name' => q(graus Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graus Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(masculine),
						'name' => q(graus Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graus Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}–{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}–{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(newton-metros),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metros),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(newton-metros),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metros),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pés-libra),
						'one' => q({0} pé-libra),
						'other' => q({0} pés-libra),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pés-libra),
						'one' => q({0} pé-libra),
						'other' => q({0} pés-libra),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barris),
						'one' => q({0} barril),
						'other' => q({0} barris),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barris),
						'one' => q({0} barril),
						'other' => q({0} barris),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
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
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(polegadas cúbicas),
						'one' => q({0} polegada cúbica),
						'other' => q({0} polegadas cúbicas),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(polegadas cúbicas),
						'one' => q({0} polegada cúbica),
						'other' => q({0} polegadas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros cúbicos),
						'one' => q({0} quilômetro cúbico),
						'other' => q({0} quilômetros cúbicos),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilômetros cúbicos),
						'one' => q({0} quilômetro cúbico),
						'other' => q({0} quilômetros cúbicos),
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
						'name' => q(milhas cúbicas),
						'one' => q({0} milha cúbica),
						'other' => q({0} milhas cúbicas),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(feminine),
						'name' => q(milhas cúbicas),
						'one' => q({0} milha cúbica),
						'other' => q({0} milhas cúbicas),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jardas cúbicas),
						'one' => q({0} jarda cúbica),
						'other' => q({0} jardas cúbicas),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jardas cúbicas),
						'one' => q({0} jarda cúbica),
						'other' => q({0} jardas cúbicas),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(feminine),
						'one' => q({0} xícara),
						'other' => q({0} xícaras),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(feminine),
						'one' => q({0} xícara),
						'other' => q({0} xícaras),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(xícaras métricas),
						'one' => q({0} xícara métrica),
						'other' => q({0} xícaras métricas),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(xícaras métricas),
						'one' => q({0} xícara métrica),
						'other' => q({0} xícaras métricas),
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
						'name' => q(colher de sobremesa),
						'one' => q({0} colher de sobremesa),
						'other' => q({0} colheres de sobremesa),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(colher de sobremesa),
						'one' => q({0} colher de sobremesa),
						'other' => q({0} colheres de sobremesa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(colheres de sobremesa imperiais),
						'one' => q({0} colher de sobremesa imperial),
						'other' => q({0} colheres de sobremesa imperiais),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(colheres de sobremesa imperiais),
						'one' => q({0} colher de sobremesa imperial),
						'other' => q({0} colheres de sobremesa imperiais),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(masculine),
						'name' => q(dracma),
						'one' => q({0} dracma líquido),
						'other' => q({0} dracmas líquidos),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(masculine),
						'name' => q(dracma),
						'one' => q({0} dracma líquido),
						'other' => q({0} dracmas líquidos),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onças fluidas),
						'one' => q({0} onça fluida),
						'other' => q({0} onças fluidas),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onças fluidas),
						'one' => q({0} onça fluida),
						'other' => q({0} onças fluidas),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onças fluidas imperiais),
						'one' => q({0} onça fluida imperial),
						'other' => q({0} onças fluidas imperiais),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onças fluidas imperiais),
						'one' => q({0} onça fluida imperial),
						'other' => q({0} onças fluidas imperiais),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(masculine),
						'name' => q(galões),
						'one' => q({0} galão),
						'other' => q({0} galões),
						'per' => q({0} por galão),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(masculine),
						'name' => q(galões),
						'one' => q({0} galão),
						'other' => q({0} galões),
						'per' => q({0} por galão),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galões imperiais),
						'one' => q({0} galão imperial),
						'other' => q({0} galões imperiais),
						'per' => q({0} por galão imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galões imperiais),
						'one' => q({0} galão imperial),
						'other' => q({0} galões imperiais),
						'per' => q({0} por galão imperial),
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
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
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
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(masculine),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(masculine),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(masculine),
						'name' => q(pints métricos),
						'one' => q({0} pint métrico),
						'other' => q({0} pints métricos),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(masculine),
						'name' => q(pints métricos),
						'one' => q({0} pint métrico),
						'other' => q({0} pints métricos),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(masculine),
						'name' => q(quartos),
						'one' => q({0} quarto),
						'other' => q({0} quartos),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(masculine),
						'name' => q(quartos),
						'one' => q({0} quarto),
						'other' => q({0} quartos),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarto imperial),
						'one' => q({0} quarto imperial),
						'other' => q({0} quartos imperiais),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarto imperial),
						'one' => q({0} quarto imperial),
						'other' => q({0} quartos imperiais),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(feminine),
						'name' => q(colheres de sopa),
						'one' => q({0} colher de sopa),
						'other' => q({0} colheres de sopa),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(feminine),
						'name' => q(colheres de sopa),
						'one' => q({0} colher de sopa),
						'other' => q({0} colheres de sopa),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(feminine),
						'name' => q(colheres de chá),
						'one' => q({0} colher de chá),
						'other' => q({0} colheres de chá),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(feminine),
						'name' => q(colheres de chá),
						'one' => q({0} colher de chá),
						'other' => q({0} colheres de chá),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseg),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseg),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectare),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectare),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pol²),
						'per' => q({0}/pol²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pol²),
						'per' => q({0}/pol²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kilate),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kilate),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bits),
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
					'digital-petabyte' => {
						'name' => q(PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dia),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dia),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hora),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mês),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mês),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ano),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ano),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amp),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amp),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule),
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
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pts),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pts),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(braça),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(braça),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
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
					'length-parsec' => {
						'name' => q(parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
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
					'light-solar-luminosity' => {
						'name' => q(L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quilate),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quilate),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grama),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grama),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pol³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pol³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xícara),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xícara),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(direção),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(direção),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(força g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(força g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros/seg²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros/seg²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsegs),
						'one' => q({0} arcseg),
						'other' => q({0} arcsegs),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsegs),
						'one' => q({0} arcseg),
						'other' => q({0} arcsegs),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graus),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graus),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianos),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianos),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acres),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acres),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunans),
						'one' => q({0} dunam),
						'other' => q({0} dunans),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunans),
						'one' => q({0} dunam),
						'other' => q({0} dunans),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectares),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectares),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pés²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pés²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(polegadas²),
						'one' => q({0} pol²),
						'other' => q({0} pol²),
						'per' => q({0} por pol²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(polegadas²),
						'one' => q({0} pol²),
						'other' => q({0} pol²),
						'per' => q({0} por pol²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metros²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metros²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milhas²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milhas²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jardas²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jardas²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0} item),
						'other' => q({0} itens),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} item),
						'other' => q({0} itens),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kilates),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kilates),
						'one' => q({0} k),
						'other' => q({0} k),
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
						'name' => q(milimol/litro),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/litro),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(por cento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(por cento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(por mil),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(por mil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes/milhão),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes/milhão),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(ponto base),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(ponto base),
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
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milhas/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milhas/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milhas/gal. imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milhas/gal. imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bits),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bits),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} bytes),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} bytes),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
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
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
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
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} sécs.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} sécs.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dias),
						'one' => q({0} dia),
						'other' => q({0} dias),
						'per' => q({0}/dia),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dias),
						'one' => q({0} dia),
						'other' => q({0} dias),
						'per' => q({0}/dia),
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
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(horas),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milissegundos),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milissegundos),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(meses),
						'one' => q({0} mês),
						'other' => q({0} meses),
						'per' => q({0}/mês),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(meses),
						'one' => q({0} mês),
						'other' => q({0} meses),
						'per' => q({0}/mês),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semanas),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semanas),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amps),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amps),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamps),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamps),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
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
					'energy-electronvolt' => {
						'name' => q(elétron-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elétron-volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joules),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joules),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(quilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(quilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-hora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm EUA),
						'one' => q({0} thm EUA),
						'other' => q({0} thm EUA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm EUA),
						'one' => q({0} thm EUA),
						'other' => q({0} thm EUA),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libra-força),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra-força),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pts),
						'one' => q({0} ponto),
						'other' => q({0} pts),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pts),
						'one' => q({0} ponto),
						'other' => q({0} pts),
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
					'graphics-megapixel' => {
						'name' => q(megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(braças),
						'one' => q({0} bça.),
						'other' => q({0} bça.),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(braças),
						'one' => q({0} bça.),
						'other' => q({0} bça.),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pés),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pés),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
						'per' => q({0}/pol.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
						'per' => q({0}/pol.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anos-luz),
						'one' => q({0} ano-luz),
						'other' => q({0} anos-luz),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anos-luz),
						'one' => q({0} ano-luz),
						'other' => q({0} anos-luz),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milhas),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milhas),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pts tipográficos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pts tipográficos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raios solares),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raios solares),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jardas),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jardas),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(luminosidades solares),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(luminosidades solares),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quilates),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(massas terrestres),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massas terrestres),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grão),
						'one' => q({0} grão),
						'other' => q({0} grãos),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grão),
						'one' => q({0} grão),
						'other' => q({0} grãos),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramas),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramas),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libras),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libras),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(massas solares),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(massas solares),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(toneladas americanas),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(toneladas americanas),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watts),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watts),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bars),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bars),
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
					'speed-beaufort' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nó),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nó),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metros/seg),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metros/seg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milhas/hora),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milhas/hora),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(graus C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graus C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graus F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graus F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barril),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
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
					'volume-cubic-foot' => {
						'name' => q(pés³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pés³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(polegadas³),
						'one' => q({0} pol³),
						'other' => q({0} pol³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(polegadas³),
						'one' => q({0} pol³),
						'other' => q({0} pol³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jardas³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jardas³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xícaras),
						'one' => q({0} xíc.),
						'other' => q({0} xíc.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xícaras),
						'one' => q({0} xíc.),
						'other' => q({0} xíc.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xícm),
						'one' => q({0} xícm),
						'other' => q({0} xícm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xícm),
						'one' => q({0} xícm),
						'other' => q({0} xícm),
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
						'name' => q(csb),
						'one' => q({0} csb),
						'other' => q({0} csb),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(csb),
						'one' => q({0} csb),
						'other' => q({0} csb),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(csb imp),
						'one' => q({0} csb imp),
						'other' => q({0} csb imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(csb imp),
						'one' => q({0} csb imp),
						'other' => q({0} csb imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma líquido),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma líquido),
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
						'name' => q(gal. imp.),
						'one' => q({0} gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal. imp.),
						'one' => q({0} gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
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
						'name' => q(dosador),
						'one' => q({0} dosador),
						'other' => q({0} dosadores),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(dosador),
						'one' => q({0} dosador),
						'other' => q({0} dosadores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litros),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litros),
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
						'name' => q(pitada),
						'one' => q({0} pitada),
						'other' => q({0} pitadas),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pitada),
						'one' => q({0} pitada),
						'other' => q({0} pitadas),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pints),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pints),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(impqt),
						'one' => q({0} impqt),
						'other' => q({0} impqt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(impqt),
						'one' => q({0} impqt),
						'other' => q({0} impqt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(c. sopa),
						'one' => q({0} c. sopa),
						'other' => q({0} c. sopa),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(c. sopa),
						'one' => q({0} c. sopa),
						'other' => q({0} c. sopa),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(c. chá),
						'one' => q({0} c. chá),
						'other' => q({0} c. chá),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(c. chá),
						'one' => q({0} c. chá),
						'other' => q({0} c. chá),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sim|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:não|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
					'one' => '0 milhão',
					'other' => '0 milhões',
				},
				'10000000' => {
					'one' => '00 milhão',
					'other' => '00 milhões',
				},
				'100000000' => {
					'one' => '000 milhão',
					'other' => '000 milhões',
				},
				'1000000000' => {
					'one' => '0 bilhão',
					'other' => '0 bilhões',
				},
				'10000000000' => {
					'one' => '00 bilhão',
					'other' => '00 bilhões',
				},
				'100000000000' => {
					'one' => '000 bilhão',
					'other' => '000 bilhões',
				},
				'1000000000000' => {
					'one' => '0 trilhão',
					'other' => '0 trilhões',
				},
				'10000000000000' => {
					'one' => '00 trilhão',
					'other' => '00 trilhões',
				},
				'100000000000000' => {
					'one' => '000 trilhão',
					'other' => '000 trilhões',
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
					'one' => '0 mi',
					'other' => '0 mi',
				},
				'10000000' => {
					'one' => '00 mi',
					'other' => '00 mi',
				},
				'100000000' => {
					'one' => '000 mi',
					'other' => '000 mi',
				},
				'1000000000' => {
					'one' => '0 bi',
					'other' => '0 bi',
				},
				'10000000000' => {
					'one' => '00 bi',
					'other' => '00 bi',
				},
				'100000000000' => {
					'one' => '000 bi',
					'other' => '000 bi',
				},
				'1000000000000' => {
					'one' => '0 tri',
					'other' => '0 tri',
				},
				'10000000000000' => {
					'one' => '00 tri',
					'other' => '00 tri',
				},
				'100000000000000' => {
					'one' => '000 tri',
					'other' => '000 tri',
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
				'currency' => q(Peseta de Andorra),
				'one' => q(Peseta de Andorra),
				'other' => q(Pesetas de Andorra),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirham dos Emirados Árabes Unidos),
				'one' => q(Dirham dos EAU),
				'other' => q(Dirhams dos EAU),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afegane \(1927–2002\)),
				'one' => q(Afegane do Afeganistão \(AFA\)),
				'other' => q(Afeganes do Afeganistão \(AFA\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afegane afegão),
				'one' => q(Afegane afegão),
				'other' => q(Afeganes afegãos),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Lek Albanês \(1946–1965\)),
				'one' => q(Lek Albanês \(1946–1965\)),
				'other' => q(Leks Albaneses \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek albanês),
				'one' => q(Lek albanês),
				'other' => q(Leks albaneses),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram armênio),
				'one' => q(Dram armênio),
				'other' => q(Drams armênios),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Florim das Antilhas Holandesas),
				'one' => q(Florim das Antilhas Holandesas),
				'other' => q(Florins das Antilhas Holandesas),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza angolano),
				'one' => q(Kwanza angolano),
				'other' => q(Kwanzas angolanos),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Cuanza angolano \(1977–1990\)),
				'one' => q(Kwanza angolano \(AOK\)),
				'other' => q(Kwanzas angolanos \(AOK\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Novo cuanza angolano \(1990–2000\)),
				'one' => q(Novo kwanza angolano \(AON\)),
				'other' => q(Novos kwanzas angolanos \(AON\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Cuanza angolano reajustado \(1995–1999\)),
				'one' => q(Kwanza angolano reajustado \(AOR\)),
				'other' => q(Kwanzas angolanos reajustados \(AOR\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral argentino),
				'one' => q(Austral argentino),
				'other' => q(Austrais argentinos),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Peso lei argentino \(1970–1983\)),
				'one' => q(Peso lei argentino \(1970–1983\)),
				'other' => q(Pesos lei argentinos \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Peso argentino \(1881–1970\)),
				'one' => q(Peso argentino \(1881–1970\)),
				'other' => q(Pesos argentinos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso argentino \(1983–1985\)),
				'one' => q(Peso argentino \(1983–1985\)),
				'other' => q(Pesos argentinos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso argentino),
				'one' => q(Peso argentino),
				'other' => q(Pesos argentinos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Xelim austríaco),
				'one' => q(Schilling australiano),
				'other' => q(Schillings australianos),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Dólar australiano),
				'one' => q(Dólar australiano),
				'other' => q(Dólares australianos),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florim arubano),
				'one' => q(Florim arubano),
				'other' => q(Florins arubanos),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manat azerbaijano \(1993–2006\)),
				'one' => q(Manat do Azeibaijão \(1993–2006\)),
				'other' => q(Manats do Azeibaijão \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat azeri),
				'one' => q(Manat azeri),
				'other' => q(Manats azeris),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dinar da Bósnia-Herzegovina \(1992–1994\)),
				'one' => q(Dinar da Bósnia Herzegovina),
				'other' => q(Dinares da Bósnia Herzegovina),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marco conversível da Bósnia e Herzegovina),
				'one' => q(Marco conversível da Bósnia e Herzegovina),
				'other' => q(Marcos conversíveis da Bósnia e Herzegovina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Novo dinar da Bósnia-Herzegovina \(1994–1997\)),
				'one' => q(Novo dinar da Bósnia-Herzegovina),
				'other' => q(Novos dinares da Bósnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dólar barbadense),
				'one' => q(Dólar barbadense),
				'other' => q(Dólares barbadenses),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka bengali),
				'one' => q(Taka bengali),
				'other' => q(Takas bengalis),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Franco belga \(conversível\)),
				'one' => q(Franco belga \(conversível\)),
				'other' => q(Francos belgas \(conversíveis\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franco belga),
				'one' => q(Franco belga),
				'other' => q(Francos belgas),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Franco belga \(financeiro\)),
				'one' => q(Franco belga \(financeiro\)),
				'other' => q(Francos belgas \(financeiros\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lev forte búlgaro),
				'one' => q(Lev forte búlgaro),
				'other' => q(Levs fortes búlgaros),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Lev socialista búlgaro),
				'one' => q(Lev socialista búlgaro),
				'other' => q(Levs socialistas búlgaros),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev búlgaro),
				'one' => q(Lev búlgaro),
				'other' => q(Levs búlgaros),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev búlgaro \(1879–1952\)),
				'one' => q(Lev búlgaro \(1879–1952\)),
				'other' => q(Levs búlgaros \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar bareinita),
				'one' => q(Dinar bareinita),
				'other' => q(Dinares bareinitas),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franco burundiano),
				'one' => q(Franco burundiano),
				'other' => q(Francos burundianos),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dólar bermudense),
				'one' => q(Dólar bermudense),
				'other' => q(Dólares bermudenses),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dólar bruneano),
				'one' => q(Dólar bruneano),
				'other' => q(Dólares bruneanos),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano da Bolívia),
				'one' => q(Boliviano da Bolívia),
				'other' => q(Bolivianos da Bolívia),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviano \(1863–1963\)),
				'one' => q(Boliviano \(1863–1963\)),
				'other' => q(Bolivianos \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso boliviano),
				'one' => q(Peso boliviano),
				'other' => q(Pesos bolivianos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol boliviano),
				'one' => q(Mvdol boliviano),
				'other' => q(Mvdols bolivianos),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro novo brasileiro \(1967–1986\)),
				'one' => q(Cruzeiro novo brasileiro \(BRB\)),
				'other' => q(Cruzeiros novos brasileiros \(BRB\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado brasileiro \(1986–1989\)),
				'one' => q(Cruzado brasileiro),
				'other' => q(Cruzados brasileiros),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro brasileiro \(1990–1993\)),
				'one' => q(Cruzeiro brasileiro \(BRE\)),
				'other' => q(Cruzeiros brasileiros \(BRE\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real brasileiro),
				'one' => q(Real brasileiro),
				'other' => q(Reais brasileiros),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado novo brasileiro \(1989–1990\)),
				'one' => q(Cruzado novo brasileiro),
				'other' => q(Cruzados novos brasileiros),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro brasileiro \(1993–1994\)),
				'one' => q(Cruzeiro brasileiro),
				'other' => q(Cruzeiros brasileiros),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Cruzeiro brasileiro \(1942–1967\)),
				'one' => q(Cruzeiro brasileiro antigo),
				'other' => q(Cruzeiros brasileiros antigos),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dólar bahamense),
				'one' => q(Dólar bahamense),
				'other' => q(Dólares bahamenses),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum butanês),
				'one' => q(Ngultrum butanês),
				'other' => q(Ngultruns butaneses),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat birmanês),
				'one' => q(Kyat burmês),
				'other' => q(Kyats burmeses),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula botsuanesa),
				'one' => q(Pula botsuanesa),
				'other' => q(Pulas botsuanesas),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Rublo novo bielo-russo \(1994–1999\)),
				'one' => q(Novo rublo bielorusso \(BYB\)),
				'other' => q(Novos rublos bielorussos \(BYB\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rublo bielorrusso),
				'one' => q(Rublo bielorrusso),
				'other' => q(Rublos bielorrussos),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rublo bielorrusso \(2000–2016\)),
				'one' => q(Rublo bielorrusso \(2000–2016\)),
				'other' => q(Rublos bielorrussos \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dólar belizenho),
				'one' => q(Dólar belizenho),
				'other' => q(Dólares belizenhos),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dólar canadense),
				'one' => q(Dólar canadense),
				'other' => q(Dólares canadenses),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franco congolês),
				'one' => q(Franco congolês),
				'other' => q(Francos congoleses),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Euro WIR),
				'one' => q(Euro WIR),
				'other' => q(Euros WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franco suíço),
				'one' => q(Franco suíço),
				'other' => q(Francos suíços),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Franco WIR),
				'one' => q(Franco WIR),
				'other' => q(Francos WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Escudo chileno),
				'one' => q(Escudo chileno),
				'other' => q(Escudos chilenos),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Unidades de Fomento chilenas),
				'one' => q(Unidade de fomento chilena),
				'other' => q(Unidades de fomento chilenas),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso chileno),
				'one' => q(Peso chileno),
				'other' => q(Pesos chilenos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan chinês \(offshore\)),
				'one' => q(Yuan chinês \(offshore\)),
				'other' => q(Yuans chineses \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dólar do Banco Popular da China),
				'one' => q(Dólar do Banco Popular da China),
				'other' => q(Dólares do Banco Popular da China),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan chinês),
				'one' => q(Yuan chinês),
				'other' => q(Yuans chineses),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso colombiano),
				'one' => q(Peso colombiano),
				'other' => q(Pesos colombianos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Unidade de Valor Real),
				'one' => q(Unidade de valor real),
				'other' => q(Unidades de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón costarriquenho),
				'one' => q(Colón costarriquenho),
				'other' => q(Colóns costarriquenhos),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Dinar sérvio \(2002–2006\)),
				'one' => q(Dinar antigo da Sérvia),
				'other' => q(Dinares antigos da Sérvia),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Coroa Forte checoslovaca),
				'one' => q(Coroa forte tchecoslovaca),
				'other' => q(Coroas fortes tchecoslovacas),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso cubano conversível),
				'one' => q(Peso cubano conversível),
				'other' => q(Pesos cubanos conversíveis),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso cubano),
				'one' => q(Peso cubano),
				'other' => q(Pesos cubanos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo cabo-verdiano),
				'one' => q(Escudo cabo-verdiano),
				'other' => q(Escudos cabo-verdianos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Libra cipriota),
				'one' => q(Libra cipriota),
				'other' => q(Libras cipriotas),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Coroa tcheca),
				'one' => q(Coroa tcheca),
				'other' => q(Coroas tchecas),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Ostmark da Alemanha Oriental),
				'one' => q(Marco da Alemanha Oriental),
				'other' => q(Marcos da Alemanha Oriental),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marco alemão),
				'one' => q(Marco alemão),
				'other' => q(Marcos alemães),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franco djiboutiano),
				'one' => q(Franco djiboutiano),
				'other' => q(Francos djiboutianos),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Coroa dinamarquesa),
				'one' => q(Coroa dinamarquesa),
				'other' => q(Coroas dinamarquesas),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso dominicano),
				'one' => q(Peso dominicano),
				'other' => q(Pesos dominicanos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar argelino),
				'one' => q(Dinar argelino),
				'other' => q(Dinares argelinos),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre equatoriano),
				'one' => q(Sucre equatoriano),
				'other' => q(Sucres equatorianos),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Unidade de Valor Constante \(UVC\) do Equador),
				'one' => q(Unidade de valor constante equatoriana \(UVC\)),
				'other' => q(Unidades de valor constante equatorianas \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Coroa estoniana),
				'one' => q(Coroa estoniana),
				'other' => q(Coroas estonianas),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Libra egípcia),
				'one' => q(Libra egípcia),
				'other' => q(Libras egípcias),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa da Eritreia),
				'one' => q(Nakfa da Eritreia),
				'other' => q(Nakfas da Eritreia),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Peseta espanhola \(conta A\)),
				'one' => q(Peseta espanhola \(conta A\)),
				'other' => q(Pesetas espanholas \(conta A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Peseta espanhola \(conta conversível\)),
				'one' => q(Peseta espanhola \(conta conversível\)),
				'other' => q(Pesetas espanholas \(conta conversível\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Peseta espanhola),
				'one' => q(Peseta espanhola),
				'other' => q(Pesetas espanholas),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr etíope),
				'one' => q(Birr etíope),
				'other' => q(Birrs etíopes),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'one' => q(Euro),
				'other' => q(Euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Marca finlandesa),
				'one' => q(Marco finlandês),
				'other' => q(Marcos finlandeses),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dólar fijiano),
				'one' => q(Dólar fijiano),
				'other' => q(Dólares fijianos),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Libra malvinense),
				'one' => q(Libra malvinense),
				'other' => q(Libras malvinenses),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franco francês),
				'one' => q(Franco francês),
				'other' => q(Francos franceses),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra esterlina),
				'one' => q(Libra esterlina),
				'other' => q(Libras esterlinas),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Cupom Lari georgiano),
				'one' => q(Kupon larit da Geórgia),
				'other' => q(Kupon larits da Geórgia),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari georgiano),
				'one' => q(Lari georgiano),
				'other' => q(Laris georgianos),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi de Gana \(1979–2007\)),
				'one' => q(Cedi de Gana \(1979–2007\)),
				'other' => q(Cedis de Gana \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi ganês),
				'one' => q(Cedi ganês),
				'other' => q(Cedis ganeses),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Libra de Gibraltar),
				'one' => q(Libra de Gibraltar),
				'other' => q(Libras de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi gambiano),
				'one' => q(Dalasi gambiano),
				'other' => q(Dalasis gambianos),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franco guineano),
				'one' => q(Franco guineano),
				'other' => q(Francos guineanos),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli da Guiné),
				'one' => q(Syli guineano),
				'other' => q(Sylis guineanos),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele da Guiné Equatorial),
				'one' => q(Ekwele da Guiné Equatorial),
				'other' => q(Ekweles da Guiné Equatorial),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Dracma grego),
				'one' => q(Dracma grego),
				'other' => q(Dracmas gregos),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal guatemalteco),
				'one' => q(Quetzal guatemalteco),
				'other' => q(Quetzais guatemaltecos),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Escudo da Guiné Portuguesa),
				'one' => q(Escudo da Guiné Portuguesa),
				'other' => q(Escudos da Guinéa Portuguesa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso da Guiné-Bissau),
				'one' => q(Peso de Guiné-Bissau),
				'other' => q(Pesos de Guiné-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dólar guianense),
				'one' => q(Dólar guianense),
				'other' => q(Dólares guianenses),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dólar de Hong Kong),
				'one' => q(Dólar de Hong Kong),
				'other' => q(Dólares de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira hondurenha),
				'one' => q(Lempira hondurenha),
				'other' => q(Lempiras hondurenhas),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Dinar croata),
				'one' => q(Dinar croata),
				'other' => q(Dinares croatas),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna croata),
				'one' => q(Kuna croata),
				'other' => q(Kunas croatas),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde haitiano),
				'one' => q(Gourde haitiano),
				'other' => q(Gourdes haitianos),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Florim húngaro),
				'one' => q(Florim húngaro),
				'other' => q(Florins húngaros),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia indonésia),
				'one' => q(Rupia indonésia),
				'other' => q(Rupias indonésias),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Libra irlandesa),
				'one' => q(Libra irlandesa),
				'other' => q(Libras irlandesas),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Libra israelita),
				'one' => q(Libra israelita),
				'other' => q(Libras israelitas),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Sheqel antigo israelita),
				'one' => q(Sheqel antigo israelita),
				'other' => q(Sheqels antigos israelitas),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Novo shekel israelense),
				'one' => q(Novo shekel israelense),
				'other' => q(Novos shekels israelenses),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia indiana),
				'one' => q(Rupia indiana),
				'other' => q(Rupias indianas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar iraquiano),
				'one' => q(Dinar iraquiano),
				'other' => q(Dinares iraquianos),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial iraniano),
				'one' => q(Rial iraniano),
				'other' => q(Riales iranianos),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Coroa antiga islandesa),
				'one' => q(Coroa antiga islandesa),
				'other' => q(Coroas antigas islandesas),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Coroa islandesa),
				'one' => q(Coroa islandesa),
				'other' => q(Coroas islandesas),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira italiana),
				'one' => q(Lira italiana),
				'other' => q(Liras italianas),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dólar jamaicano),
				'one' => q(Dólar jamaicano),
				'other' => q(Dólares jamaicanos),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar jordaniano),
				'one' => q(Dinar jordaniano),
				'other' => q(Dinares jordanianos),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Iene japonês),
				'one' => q(Iene japonês),
				'other' => q(Ienes japoneses),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Xelim queniano),
				'one' => q(Xelim queniano),
				'other' => q(Xelins quenianos),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som quirguiz),
				'one' => q(Som quirguiz),
				'other' => q(Sons quirguizes),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel cambojano),
				'one' => q(Riel cambojano),
				'other' => q(Rieles cambojanos),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franco comoriano),
				'one' => q(Franco comoriano),
				'other' => q(Francos comorianos),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won norte-coreano),
				'one' => q(Won norte-coreano),
				'other' => q(Wons norte-coreanos),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Hwan da Coreia do Sul \(1953–1962\)),
				'one' => q(Hwan da Coreia do Sul),
				'other' => q(Hwans da Coreia do Sul),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Won da Coreia do Sul \(1945–1953\)),
				'one' => q(Won antigo da Coreia do Sul),
				'other' => q(Wons antigos da Coreia do Sul),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won sul-coreano),
				'one' => q(Won sul-coreano),
				'other' => q(Wons sul-coreanos),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar kuwaitiano),
				'one' => q(Dinar kuwaitiano),
				'other' => q(Dinares kuwaitianos),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dólar das Ilhas Cayman),
				'one' => q(Dólar das Ilhas Cayman),
				'other' => q(Dólares das Ilhas Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge cazaque),
				'one' => q(Tenge cazaque),
				'other' => q(Tenges cazaques),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip laosiano),
				'one' => q(Kip laosiano),
				'other' => q(Kips laosianos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libra libanesa),
				'one' => q(Libra libanesa),
				'other' => q(Libras libanesas),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupia cingalesa),
				'one' => q(Rupia cingalesa),
				'other' => q(Rupias cingalesas),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dólar liberiano),
				'one' => q(Dólar liberiano),
				'other' => q(Dólares liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti lesotiano),
				'one' => q(Loti lesotiano),
				'other' => q(Lotis lesotianos),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas lituano),
				'one' => q(Litas lituano),
				'other' => q(Litai lituanos),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Talonas lituano),
				'one' => q(Talonas lituanas),
				'other' => q(Talonases lituanas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Franco conversível de Luxemburgo),
				'one' => q(Franco conversível de Luxemburgo),
				'other' => q(Francos conversíveis de Luxemburgo),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Franco luxemburguês),
				'one' => q(Franco de Luxemburgo),
				'other' => q(Francos de Luxemburgo),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Franco financeiro de Luxemburgo),
				'one' => q(Franco financeiro de Luxemburgo),
				'other' => q(Francos financeiros de Luxemburgo),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats letão),
				'one' => q(Lats letão),
				'other' => q(Lati letões),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rublo letão),
				'one' => q(Rublo da Letônia),
				'other' => q(Rublos da Letônia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar líbio),
				'one' => q(Dinar líbio),
				'other' => q(Dinares líbios),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham marroquino),
				'one' => q(Dirham marroquino),
				'other' => q(Dirhams marroquinos),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Franco marroquino),
				'one' => q(Franco marroquino),
				'other' => q(Francos marroquinos),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Franco monegasco),
				'one' => q(Franco monegasco),
				'other' => q(Francos monegascos),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Cupon moldávio),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu moldávio),
				'one' => q(Leu moldávio),
				'other' => q(Leus moldávios),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary malgaxe),
				'one' => q(Ariary malgaxe),
				'other' => q(Ariarys malgaxes),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Franco de Madagascar),
				'one' => q(Franco de Madagascar),
				'other' => q(Francos de Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinar macedônio),
				'one' => q(Dinar macedônio),
				'other' => q(Dinares macedônios),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Dinar macedônio \(1992–1993\)),
				'one' => q(Dinar macedônio \(1992–1993\)),
				'other' => q(Dinares macedônios \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Franco de Mali),
				'one' => q(Franco de Mali),
				'other' => q(Francos de Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Quiate mianmarense),
				'one' => q(Quiate mianmarense),
				'other' => q(Quiates mianmarenses),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik mongol),
				'one' => q(Tugrik mongol),
				'other' => q(Tugriks mongóis),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca macaense),
				'one' => q(Pataca macaense),
				'other' => q(Patacas macaenses),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya mauritana \(1973–2017\)),
				'one' => q(Ouguiya mauritana \(1973–2017\)),
				'other' => q(Ouguiyas mauritanas \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya mauritana),
				'one' => q(Ouguiya mauritana),
				'other' => q(Ouguiyas mauritanas),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lira maltesa),
				'one' => q(Lira Maltesa),
				'other' => q(Liras maltesas),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Libra maltesa),
				'one' => q(Libra maltesa),
				'other' => q(Libras maltesas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia mauriciana),
				'one' => q(Rupia mauriciana),
				'other' => q(Rupias mauricianas),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rupia maldivana),
				'one' => q(Rupia maldivana),
				'other' => q(Rupias maldivanas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha malauiana),
				'one' => q(Kwacha malauiana),
				'other' => q(Kwachas malauianas),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso mexicano),
				'one' => q(Peso mexicano),
				'other' => q(Pesos mexicanos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso Prata mexicano \(1861–1992\)),
				'one' => q(Peso de prata mexicano \(1861–1992\)),
				'other' => q(Pesos de prata mexicanos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Unidade Mexicana de Investimento \(UDI\)),
				'one' => q(Unidade de investimento mexicana \(UDI\)),
				'other' => q(Unidades de investimento mexicanas \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit malaio),
				'one' => q(Ringgit malaio),
				'other' => q(Ringgits malaios),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo de Moçambique),
				'one' => q(Escudo de Moçambique),
				'other' => q(Escudos de Moçambique),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical de Moçambique \(1980–2006\)),
				'one' => q(Metical antigo de Moçambique),
				'other' => q(Meticales antigos de Moçambique),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical moçambicano),
				'one' => q(Metical moçambicano),
				'other' => q(Meticais moçambicanos),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dólar namibiano),
				'one' => q(Dólar namibiano),
				'other' => q(Dólares namibianos),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira nigeriana),
				'one' => q(Naira nigeriana),
				'other' => q(Nairas nigerianas),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba nicaraguense \(1988–1991\)),
				'one' => q(Córdoba nicaraguense \(1988–1991\)),
				'other' => q(Córdobas nicaraguense \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba nicaraguense),
				'one' => q(Córdoba nicaraguense),
				'other' => q(Córdobas nicaraguenses),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Florim holandês),
				'one' => q(Florim holandês),
				'other' => q(Florins holandeses),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Coroa norueguesa),
				'one' => q(Coroa norueguesa),
				'other' => q(Coroas norueguesas),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia nepalesa),
				'one' => q(Rupia nepalesa),
				'other' => q(Rupias nepalesas),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dólar neozelandês),
				'one' => q(Dólar neozelandês),
				'other' => q(Dólares neozelandeses),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial omanense),
				'one' => q(Rial omanense),
				'other' => q(Riales omanenses),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa panamenho),
				'one' => q(Balboa panamenho),
				'other' => q(Balboas panamenhos),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Inti peruano),
				'one' => q(Inti peruano),
				'other' => q(Intis peruanos),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Novo sol peruano),
				'one' => q(Novo sol peruano),
				'other' => q(Novos sóis peruanos),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol peruano \(1863–1965\)),
				'one' => q(Sol peruano \(1863–1965\)),
				'other' => q(Sóis peruanos \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina papuásia),
				'one' => q(Kina papuásia),
				'other' => q(Kinas papuásias),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso filipino),
				'one' => q(Peso filipino),
				'other' => q(Pesos filipinos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia paquistanesa),
				'one' => q(Rupia paquistanesa),
				'other' => q(Rupias paquistanesas),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty polonês),
				'one' => q(Zloty polonês),
				'other' => q(Zlotys poloneses),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloti polonês \(1950–1995\)),
				'one' => q(Zloti polonês \(1950–1995\)),
				'other' => q(Zlotis poloneses \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'Esc.',
			display_name => {
				'currency' => q(Escudo português),
				'one' => q(Escudo português),
				'other' => q(Escudos portugueses),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani paraguaio),
				'one' => q(Guarani paraguaio),
				'other' => q(Guaranis paraguaios),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial catariano),
				'one' => q(Rial catariano),
				'other' => q(Riales catarianos),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Dólar rodesiano),
				'one' => q(Dólar da Rodésia),
				'other' => q(Dólares da Rodésia),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Leu romeno \(1952–2006\)),
				'one' => q(Leu antigo da Romênia),
				'other' => q(Leus antigos da Romênia),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(Leu romeno),
				'one' => q(Leu romeno),
				'other' => q(Leus romenos),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar sérvio),
				'one' => q(Dinar sérvio),
				'other' => q(Dinares sérvios),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rublo russo),
				'one' => q(Rublo russo),
				'other' => q(Rublos russos),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rublo russo \(1991–1998\)),
				'one' => q(Rublo russo \(1991–1998\)),
				'other' => q(Rublos russos \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franco ruandês),
				'one' => q(Franco ruandês),
				'other' => q(Francos ruandeses),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal saudita),
				'one' => q(Riyal saudita),
				'other' => q(Riyales sauditas),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dólar das Ilhas Salomão),
				'one' => q(Dólar das Ilhas Salomão),
				'other' => q(Dólares das Ilhas Salomão),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia seichelense),
				'one' => q(Rupia seichelense),
				'other' => q(Rupias seichelenses),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Dinar sudanês \(1992–2007\)),
				'one' => q(Dinar antigo do Sudão),
				'other' => q(Dinares antigos do Sudão),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Libra sudanesa),
				'one' => q(Libra sudanesa),
				'other' => q(Libras sudanesas),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Libra sudanesa \(1957–1998\)),
				'one' => q(Libra antiga sudanesa),
				'other' => q(Libras antigas sudanesas),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Coroa sueca),
				'one' => q(Coroa sueca),
				'other' => q(Coroas suecas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dólar singapuriano),
				'one' => q(Dólar singapuriano),
				'other' => q(Dólares singapurianos),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Libra de Santa Helena),
				'one' => q(Libra de Santa Helena),
				'other' => q(Libras de Santa Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar Bons esloveno),
				'one' => q(Tolar da Eslovênia),
				'other' => q(Tolares da Eslovênia),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Coroa eslovaca),
				'one' => q(Coroa eslovaca),
				'other' => q(Coroas eslovacas),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone de Serra Leoa),
				'one' => q(Leone de Serra Leoa),
				'other' => q(Leones de Serra Leoa),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone de Serra Leoa \(1964—2022\)),
				'one' => q(Leone de Serra Leoa \(1964—2022\)),
				'other' => q(Leones de Serra Leoa \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Xelim somali),
				'one' => q(Xelim somali),
				'other' => q(Xelins somalis),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dólar surinamês),
				'one' => q(Dólar surinamês),
				'other' => q(Dólares surinameses),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Florim do Suriname),
				'one' => q(Florim do Suriname),
				'other' => q(Florins do Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Libra sul-sudanesa),
				'one' => q(Libra sul-sudanesa),
				'other' => q(Libras sul-sudanesas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
				'one' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
				'other' => q(Dobras de São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe),
				'one' => q(Dobra de São Tomé e Príncipe),
				'other' => q(Dobras de São Tomé e Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Rublo soviético),
				'one' => q(Rublo soviético),
				'other' => q(Rublos soviéticos),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colom salvadorenho),
				'one' => q(Colon de El Salvador),
				'other' => q(Colons de El Salvador),
			},
		},
		'SYP' => {
			symbol => 'S£',
			display_name => {
				'currency' => q(Libra síria),
				'one' => q(Libra síria),
				'other' => q(Libras sírias),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni suazi),
				'one' => q(Lilangeni suazi),
				'other' => q(Lilangenis suazis),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht tailandês),
				'one' => q(Baht tailandês),
				'other' => q(Bahts tailandeses),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Rublo do Tadjiquistão),
				'one' => q(Rublo do Tajaquistão),
				'other' => q(Rublos do Tajaquistão),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni tadjique),
				'one' => q(Somoni tadjique),
				'other' => q(Somonis tadjiques),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manat do Turcomenistão \(1993–2009\)),
				'one' => q(Manat do Turcomenistão \(1993–2009\)),
				'other' => q(Manats do Turcomenistão \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat turcomeno),
				'one' => q(Manat turcomeno),
				'other' => q(Manats turcomenos),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar tunisiano),
				'one' => q(Dinar tunisiano),
				'other' => q(Dinares tunisianos),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga tonganesa),
				'one' => q(Paʻanga tonganesa),
				'other' => q(Paʻangas tonganesas),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo timorense),
				'one' => q(Escudo do Timor),
				'other' => q(Escudos do Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lira turca \(1922–2005\)),
				'one' => q(Lira turca antiga),
				'other' => q(Liras turcas antigas),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira turca),
				'one' => q(Lira turca),
				'other' => q(Liras turcas),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dólar de Trinidad e Tobago),
				'one' => q(Dólar de Trinidad e Tobago),
				'other' => q(Dólares de Trinidad e Tobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Novo dólar taiwanês),
				'one' => q(Novo dólar taiwanês),
				'other' => q(Novos dólares taiwaneses),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Xelim tanzaniano),
				'one' => q(Xelim tanzaniano),
				'other' => q(Xelins tanzanianos),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia ucraniano),
				'one' => q(Hryvnia ucraniano),
				'other' => q(Hryvnias ucranianos),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Karbovanetz ucraniano),
				'one' => q(Karbovanetz da Ucrânia),
				'other' => q(Karbovanetzs da Ucrânia),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Xelim ugandense \(1966–1987\)),
				'one' => q(Shilling de Uganda \(1966–1987\)),
				'other' => q(Shillings de Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Xelim ugandense),
				'one' => q(Xelim ugandense),
				'other' => q(Xelins ugandenses),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dólar americano),
				'one' => q(Dólar americano),
				'other' => q(Dólares americanos),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dólar norte-americano \(Dia seguinte\)),
				'one' => q(Dólar americano \(dia seguinte\)),
				'other' => q(Dólares americanos \(dia seguinte\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dólar norte-americano \(Mesmo dia\)),
				'one' => q(Dólar americano \(mesmo dia\)),
				'other' => q(Dólares americanos \(mesmo dia\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Peso uruguaio en unidades indexadas),
				'one' => q(Peso uruguaio em unidades indexadas),
				'other' => q(Pesos uruguaios em unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso uruguaio \(1975–1993\)),
				'one' => q(Peso uruguaio \(1975–1993\)),
				'other' => q(Pesos uruguaios \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso uruguaio),
				'one' => q(Peso uruguaio),
				'other' => q(Pesos uruguaios),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som uzbeque),
				'one' => q(Som uzbeque),
				'other' => q(Sons uzbeques),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar venezuelano \(1871–2008\)),
				'one' => q(Bolívar venezuelano \(1871–2008\)),
				'other' => q(Bolívares venezuelanos \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar venezuelano \(2008–2018\)),
				'one' => q(Bolívar venezuelano \(2008–2018\)),
				'other' => q(Bolívares venezuelanos \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar venezuelano),
				'one' => q(Bolívar venezuelano),
				'other' => q(Bolívares venezuelanos),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong vietnamita),
				'one' => q(Dong vietnamita),
				'other' => q(Dongs vietnamitas),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong vietnamita \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu de Vanuatu),
				'one' => q(Vatu de Vanuatu),
				'other' => q(Vatus de Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala samoano),
				'one' => q(Tala samoano),
				'other' => q(Talas samoanos),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franco CFA de BEAC),
				'one' => q(Franco CFA de BEAC),
				'other' => q(Francos CFA de BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Prata),
				'one' => q(Prata),
				'other' => q(Pratas),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Ouro),
				'one' => q(Ouro),
				'other' => q(Ouros),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Unidade Composta Europeia),
				'one' => q(Unidade de composição europeia),
				'other' => q(Unidades de composição europeias),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Unidade Monetária Europeia),
				'one' => q(Unidade monetária europeia),
				'other' => q(Unidades monetárias europeias),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Unidade de Conta Europeia \(XBC\)),
				'one' => q(Unidade europeia de conta \(XBC\)),
				'other' => q(Unidades europeias de conta \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Unidade de Conta Europeia \(XBD\)),
				'one' => q(Unidade europeia de conta \(XBD\)),
				'other' => q(Unidades europeias de conta \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dólar do Caribe Oriental),
				'one' => q(Dólar do Caribe Oriental),
				'other' => q(Dólares do Caribe Oriental),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Direitos Especiais de Giro),
				'one' => q(Direitos de desenho especiais),
				'other' => q(Direitos de desenho especiais),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Unidade de Moeda Europeia),
				'one' => q(Unidade de moeda europeia),
				'other' => q(Unidades de moedas europeias),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franco-ouro francês),
				'one' => q(Franco de ouro francês),
				'other' => q(Francos de ouro franceses),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franco UIC francês),
				'one' => q(Franco UIC francês),
				'other' => q(Francos UIC franceses),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franco CFA de BCEAO),
				'one' => q(Franco CFA de BCEAO),
				'other' => q(Francos CFA de BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paládio),
				'one' => q(Paládio),
				'other' => q(Paládios),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franco CFP),
				'one' => q(Franco CFP),
				'other' => q(Francos CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platina),
				'one' => q(Platina),
				'other' => q(Platinas),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(Fundos RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Código de Moeda de Teste),
				'one' => q(Código de moeda de teste),
				'other' => q(Códigos de moeda de teste),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moeda desconhecida),
				'one' => q(\(unidade monetária desconhecida\)),
				'other' => q(\(moedas desconhecidas\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Dinar iemenita),
				'one' => q(Dinar do Iêmen),
				'other' => q(Dinares do Iêmen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial iemenita),
				'one' => q(Rial iemenita),
				'other' => q(Riales iemenitas),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Dinar forte iugoslavo \(1966–1990\)),
				'one' => q(Dinar forte iugoslavo),
				'other' => q(Dinares fortes iugoslavos),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Dinar noviy iugoslavo \(1994–2002\)),
				'one' => q(Dinar noviy da Iugoslávia),
				'other' => q(Dinares noviy da Iugoslávia),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinar conversível iugoslavo \(1990–1992\)),
				'one' => q(Dinar conversível da Iugoslávia),
				'other' => q(Dinares conversíveis da Iugoslávia),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Dinar reformado iugoslavo \(1992–1993\)),
				'one' => q(Dinar iugoslavo reformado),
				'other' => q(Dinares iugoslavos reformados),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand sul-africano \(financeiro\)),
				'one' => q(Rand da África do Sul \(financeiro\)),
				'other' => q(Rands da África do Sul \(financeiro\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand sul-africano),
				'one' => q(Rand sul-africano),
				'other' => q(Rands sul-africanos),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Cuacha zambiano \(1968–2012\)),
				'one' => q(Kwacha da Zâmbia \(1968–2012\)),
				'other' => q(Kwachas da Zâmbia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha zambiano),
				'one' => q(Kwacha zambiano),
				'other' => q(Kwachas zambianos),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire Novo zairense \(1993–1998\)),
				'one' => q(Novo zaire do Zaire),
				'other' => q(Novos zaires do Zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire zairense \(1971–1993\)),
				'one' => q(Zaire do Zaire),
				'other' => q(Zaires do Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dólar do Zimbábue \(1980–2008\)),
				'one' => q(Dólar do Zimbábue),
				'other' => q(Dólares do Zimbábue),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Dólar do Zimbábue \(2009\)),
				'one' => q(Dólar do Zimbábue \(2009\)),
				'other' => q(Dólares do Zimbábue \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Dólar do Zimbábue \(2008\)),
				'one' => q(Dólar do Zimbábue \(2008\)),
				'other' => q(Dólares do Zimbábue \(2008\)),
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
							'Mês 1',
							'Mês 2',
							'Mês 3',
							'Mês 4',
							'Mês 5',
							'Mês 6',
							'Mês 7',
							'Mês 8',
							'Mês 9',
							'Mês 10',
							'Mês 11',
							'Mês 12'
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
							'jan.',
							'fev.',
							'mar.',
							'abr.',
							'mai.',
							'jun.',
							'jul.',
							'ago.',
							'set.',
							'out.',
							'nov.',
							'dez.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janeiro',
							'fevereiro',
							'março',
							'abril',
							'maio',
							'junho',
							'julho',
							'agosto',
							'setembro',
							'outubro',
							'novembro',
							'dezembro'
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
						mon => 'seg.',
						tue => 'ter.',
						wed => 'qua.',
						thu => 'qui.',
						fri => 'sex.',
						sat => 'sáb.',
						sun => 'dom.'
					},
					wide => {
						mon => 'segunda-feira',
						tue => 'terça-feira',
						wed => 'quarta-feira',
						thu => 'quinta-feira',
						fri => 'sexta-feira',
						sat => 'sábado',
						sun => 'domingo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'Q',
						thu => 'Q',
						fri => 'S',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
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
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					'afternoon1' => q{da tarde},
					'evening1' => q{da noite},
					'midnight' => q{meia-noite},
					'morning1' => q{da manhã},
					'night1' => q{da madrugada},
					'noon' => q{meio-dia},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{tarde},
					'evening1' => q{noite},
					'morning1' => q{manhã},
					'night1' => q{madrugada},
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
			narrow => {
				'0' => 'EB'
			},
			wide => {
				'0' => 'EB'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
			wide => {
				'0' => 'antes de Cristo',
				'1' => 'depois de Cristo'
			},
		},
		'japanese' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Antes da R.C.',
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
			'full' => q{EEEE, d 'de' MMMM 'de' U},
			'long' => q{d 'de' MMMM 'de' U},
			'medium' => q{dd/MM U},
			'short' => q{dd/MM/r},
		},
		'generic' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d 'de' MMM 'de' y},
			'short' => q{dd/MM/y},
		},
		'japanese' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{dd/MM/y G},
			'short' => q{dd/MM/yy GGGGG},
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		},
		'generic' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{r(U)},
			GyMMM => q{MMM 'de' U},
			GyMMMEd => q{E, d 'de' MMM 'de' U},
			GyMMMd => q{d 'de' MMM 'de' U},
			GyMd => q{dd/MM/r},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yyyyM => q{MM/r},
			yyyyMEd => q{E, dd/MM/r},
			yyyyMMM => q{MMM 'de' U},
			yyyyMMMEd => q{E, d 'de' MMM 'de' U},
			yyyyMMMM => q{MMMM 'de' U},
			yyyyMMMMEd => q{E, d 'de' MMMM 'de' U},
			yyyyMMMMd => q{d 'de' MMMM 'de' U},
			yyyyMMMd => q{d 'de' MMM 'de' U},
			yyyyMd => q{dd/MM/r},
			yyyyQQQ => q{U QQQ},
			yyyyQQQQ => q{U QQQQ},
		},
		'generic' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM 'de' y G},
			yyyyMMMEd => q{E, d 'de' MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMMEd => q{E, d 'de' MMMM 'de' y G},
			yyyyMMMMd => q{d 'de' MMMM 'de' y G},
			yyyyMMMd => q{d 'de' MMM 'de' y G},
			yyyyMd => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMW => q{W'ª' 'semana' 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			MMdd => q{dd/MM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM 'de' y},
			yMMMEd => q{E, d 'de' MMM 'de' y},
			yMMMM => q{MMMM 'de' y},
			yMMMMEd => q{E, d 'de' MMMM 'de' y},
			yMMMMd => q{d 'de' MMMM 'de' y},
			yMMMd => q{d 'de' MMM 'de' y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ 'de' y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{w'ª' 'semana' 'de' Y},
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
			Bhm => {
				h => q{h:mm – h:mm B},
			},
			H => {
				H => q{HH'h' - HH'h'},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d–d 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' - h'h' a},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
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
			yMMM => {
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E, dd/MM/y GGGGG – E, dd/MM/y GGGGG},
				M => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				d => q{E, dd/MM/y – E, dd/MM/y GGGGG},
				y => q{E, dd/MM/y – E, dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d 'de' MMM 'de' y G – E, d 'de' MMM 'de' y G},
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			GyMMMd => {
				G => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
				M => q{dd 'de' MMM – dd 'de' MMM 'de' y G},
				d => q{d – d 'de' MMM, y G},
				y => q{d 'de' MMM 'de' y G – d 'de' MMM 'de' y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH'h' - HH'h'},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d 'de' MMM – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM 'de' y},
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'de' y},
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d – d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Horário {0}),
		regionFormat => q(Horário de Verão: {0}),
		regionFormat => q(Horário Padrão: {0}),
		'Acre' => {
			long => {
				'daylight' => q#Horário de Verão do Acre#,
				'generic' => q#Horário do Acre#,
				'standard' => q#Horário Padrão do Acre#,
			},
			short => {
				'daylight' => q#ACST#,
				'generic' => q#ACT#,
				'standard' => q#ACT#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Horário do Afeganistão#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argel#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conacri#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Joanesburgo#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Cartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadíscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monróvia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairóbi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Horário da África Central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Horário da África Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Horário da África do Sul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Horário de Verão da África Ocidental#,
				'generic' => q#Horário da África Ocidental#,
				'standard' => q#Horário Padrão da África Ocidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Horário de Verão do Alasca#,
				'generic' => q#Horário do Alasca#,
				'standard' => q#Horário Padrão do Alasca#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Horário de Verão do Almaty#,
				'generic' => q#Horário do Almaty#,
				'standard' => q#Horário Padrão do Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Horário de Verão do Amazonas#,
				'generic' => q#Horário do Amazonas#,
				'standard' => q#Horário Padrão do Amazonas#,
			},
			short => {
				'daylight' => q#AMST#,
				'generic' => q#AMT#,
				'standard' => q#AMT#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antígua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumã#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Assunção#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caiena#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guaiaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianápolis#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Managua' => {
			exemplarCity => q#Manágua#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cidade do México#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevidéu#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova York#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota do Norte#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota do Norte#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salen, Dakota do Norte#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Porto Príncipe#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rico#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#São Bartolomeu#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#São Cristóvão#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lúcia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#São Vicente#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Horário de Verão Central#,
				'generic' => q#Horário Central#,
				'standard' => q#Horário Padrão Central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Horário de Verão do Leste#,
				'generic' => q#Horário do Leste#,
				'standard' => q#Horário Padrão do Leste#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Horário de Verão das Montanhas#,
				'generic' => q#Horário das Montanhas#,
				'standard' => q#Horário Padrão das Montanhas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Horário de Verão do Pacífico#,
				'generic' => q#Horário do Pacífico#,
				'standard' => q#Horário Padrão do Pacífico#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Horário de Verão do Anadyr#,
				'generic' => q#Horário de Anadyr#,
				'standard' => q#Horário Padrão do Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Horário de Verão de Apia#,
				'generic' => q#Horário de Apia#,
				'standard' => q#Horário Padrão de Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Horário de Verão do Aqtau#,
				'generic' => q#Horário do Aqtau#,
				'standard' => q#Horário Padrão do Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Horário de Verão do Aqtobe#,
				'generic' => q#Horário do Aqtobe#,
				'standard' => q#Horário Padrão do Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Horário de Verão da Arábia#,
				'generic' => q#Horário da Arábia#,
				'standard' => q#Horário Padrão da Arábia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Horário de Verão da Argentina#,
				'generic' => q#Horário da Argentina#,
				'standard' => q#Horário Padrão da Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Horário de Verão da Argentina Ocidental#,
				'generic' => q#Horário da Argentina Ocidental#,
				'standard' => q#Horário Padrão da Argentina Ocidental#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Horário de Verão da Armênia#,
				'generic' => q#Horário da Armênia#,
				'standard' => q#Horário Padrão da Armênia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Áden#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amã#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asgabate#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdá#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirute#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutá#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duchambe#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalém#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Cabul#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicósia#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangum#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riade#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Cidade de Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sacalina#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Xangai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teerã#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tóquio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ecaterimburgo#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Horário de Verão do Atlântico#,
				'generic' => q#Horário do Atlântico#,
				'standard' => q#Horário Padrão do Atlântico#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Açores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canárias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ilhas Faroé#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geórgia do Sul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Horário de Verão da Austrália Central#,
				'generic' => q#Horário da Austrália Central#,
				'standard' => q#Horário Padrão da Austrália Central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Horário de Verão da Austrália Centro-Ocidental#,
				'generic' => q#Horário da Austrália Centro-Ocidental#,
				'standard' => q#Horário Padrão da Austrália Centro-Ocidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Horário de Verão da Austrália Oriental#,
				'generic' => q#Horário da Austrália Oriental#,
				'standard' => q#Horário Padrão da Austrália Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Horário de Verão da Austrália Ocidental#,
				'generic' => q#Horário da Austrália Ocidental#,
				'standard' => q#Horário Padrão da Austrália Ocidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Horário de Verão do Arzeibaijão#,
				'generic' => q#Horário do Arzeibaijão#,
				'standard' => q#Horário Padrão do Arzeibaijão#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Horário de Verão dos Açores#,
				'generic' => q#Horário dos Açores#,
				'standard' => q#Horário Padrão dos Açores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Horário de Verão de Bangladesh#,
				'generic' => q#Horário de Bangladesh#,
				'standard' => q#Horário Padrão de Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Horário do Butão#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Horário da Bolívia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Horário de Verão de Brasília#,
				'generic' => q#Horário de Brasília#,
				'standard' => q#Horário Padrão de Brasília#,
			},
			short => {
				'daylight' => q#BRST#,
				'generic' => q#BRT#,
				'standard' => q#BRT#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Horário de Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Horário de Verão de Cabo Verde#,
				'generic' => q#Horário de Cabo Verde#,
				'standard' => q#Horário Padrão de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Horário de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Horário de Verão de Chatham#,
				'generic' => q#Horário de Chatham#,
				'standard' => q#Horário Padrão de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Horário de Verão do Chile#,
				'generic' => q#Horário do Chile#,
				'standard' => q#Horário Padrão do Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Horário de Verão da China#,
				'generic' => q#Horário da China#,
				'standard' => q#Horário Padrão da China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Horário de Verão de Choibalsan#,
				'generic' => q#Horário de Choibalsan#,
				'standard' => q#Horário Padrão de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Horário da Ilha Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Horário das Ilhas Coco#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Horário de Verão da Colômbia#,
				'generic' => q#Horário da Colômbia#,
				'standard' => q#Horário Padrão da Colômbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Meio Horário de Verão das Ilhas Cook#,
				'generic' => q#Horário das Ilhas Cook#,
				'standard' => q#Horário Padrão das Ilhas Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Horário de Verão de Cuba#,
				'generic' => q#Horário de Cuba#,
				'standard' => q#Horário Padrão de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Horário de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Horário de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Horário do Timor-Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Horário de Verão da Ilha de Páscoa#,
				'generic' => q#Horário da Ilha de Páscoa#,
				'standard' => q#Horário Padrão da Ilha de Páscoa#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Horário do Equador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Horário Universal Coordenado#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Cidade desconhecida#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdã#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astracã#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlim#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucareste#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeste#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Horário Padrão Irlandês#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinque#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ilha de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istambul#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
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
				'daylight' => q#Horário de Verão Britânico#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madri#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mônaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscou#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sófia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsóvia#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporizhia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurique#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Horário de Verão da Europa Central#,
				'generic' => q#Horário da Europa Central#,
				'standard' => q#Horário Padrão da Europa Central#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Horário de Verão da Europa Oriental#,
				'generic' => q#Horário da Europa Oriental#,
				'standard' => q#Horário Padrão da Europa Oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Horário do Extremo Leste Europeu#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Horário de Verão da Europa Ocidental#,
				'generic' => q#Horário da Europa Ocidental#,
				'standard' => q#Horário Padrão da Europa Ocidental#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Horário de Verão das Ilhas Malvinas#,
				'generic' => q#Horário das Ilhas Malvinas#,
				'standard' => q#Horário Padrão das Ilhas Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Horário de Verão de Fiji#,
				'generic' => q#Horário de Fiji#,
				'standard' => q#Horário Padrão de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Horário da Guiana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Horário dos Territórios Franceses do Sul e Antártida#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Horário do Meridiano de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Horário de Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Horário de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Horário de Verão da Geórgia#,
				'generic' => q#Horário da Geórgia#,
				'standard' => q#Horário Padrão da Geórgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Horário das Ilhas Gilberto#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Horário de Verão da Groelândia Oriental#,
				'generic' => q#Horário da Groelândia Oriental#,
				'standard' => q#Horário Padrão da Groelândia Oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Horário de Verão da Groenlândia Ocidental#,
				'generic' => q#Horário da Groenlândia Ocidental#,
				'standard' => q#Horário Padrão da Groenlândia Ocidental#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Horário Padrão de Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Horário do Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Horário da Guiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Horário de Verão do Havaí e Ilhas Aleutas#,
				'generic' => q#Horário do Havaí e Ilhas Aleutas#,
				'standard' => q#Horário Padrão do Havaí e Ilhas Aleutas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Horário de Verão de Hong Kong#,
				'generic' => q#Horário de Hong Kong#,
				'standard' => q#Horário Padrão de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Horário de Verão de Hovd#,
				'generic' => q#Horário de Hovd#,
				'standard' => q#Horário Padrão de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Horário Padrão da Índia#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comores#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurício#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunião#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Horário do Oceano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Horário da Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Horário da Indonésia Central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Horário da Indonésia Oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Horário da Indonésia Ocidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Horário de Verão do Irã#,
				'generic' => q#Horário do Irã#,
				'standard' => q#Horário Padrão do Irã#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Horário de Verão de Irkutsk#,
				'generic' => q#Horário de Irkutsk#,
				'standard' => q#Horário Padrão de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Horário de Verão de Israel#,
				'generic' => q#Horário de Israel#,
				'standard' => q#Horário Padrão de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Horário de Verão do Japão#,
				'generic' => q#Horário do Japão#,
				'standard' => q#Horário Padrão do Japão#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Horário de Verão de Petropavlovsk-Kamchatski#,
				'generic' => q#Horário de Petropavlovsk-Kamchatski#,
				'standard' => q#Horário Padrão de Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Horário do Casaquistão Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Horário do Casaquistão Ocidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Horário de Verão da Coreia#,
				'generic' => q#Horário da Coreia#,
				'standard' => q#Horário Padrão da Coreia#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Horário de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Horário de Verão de Krasnoyarsk#,
				'generic' => q#Horário de Krasnoyarsk#,
				'standard' => q#Horário Padrão de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Horário do Quirguistão#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Horário de Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Horário das Ilhas da Linha#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Horário de Verão de Lord Howe#,
				'generic' => q#Horário de Lord Howe#,
				'standard' => q#Horário Padrão de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Horário de Verão de Macau#,
				'generic' => q#Horário de Macau#,
				'standard' => q#Horário Padrão de Macau#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Horário da Ilha Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Horário de Verão de Magadan#,
				'generic' => q#Horário de Magadan#,
				'standard' => q#Horário Padrão de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Horário da Malásia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Horário das Ilhas Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Horário das Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Horário das Ilhas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Horário de Verão de Maurício#,
				'generic' => q#Horário de Maurício#,
				'standard' => q#Horário Padrão de Maurício#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Horário de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Horário de Verão do Noroeste do México#,
				'generic' => q#Horário do Noroeste do México#,
				'standard' => q#Horário Padrão do Noroeste do México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Horário de Verão do Pacífico Mexicano#,
				'generic' => q#Horário do Pacífico Mexicano#,
				'standard' => q#Horário Padrão do Pacífico Mexicano#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Horário de Verão de Ulan Bator#,
				'generic' => q#Horário de Ulan Bator#,
				'standard' => q#Horário Padrão de Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Horário de Verão de Moscou#,
				'generic' => q#Horário de Moscou#,
				'standard' => q#Horário Padrão de Moscou#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Horário de Mianmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Horário de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Horário do Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Horário de Verão da Nova Caledônia#,
				'generic' => q#Horário da Nova Caledônia#,
				'standard' => q#Horário Padrão da Nova Caledônia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Horário de Verão da Nova Zelândia#,
				'generic' => q#Horário da Nova Zelândia#,
				'standard' => q#Horário Padrão da Nova Zelândia#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Horário de Verão da Terra Nova#,
				'generic' => q#Horário da Terra Nova#,
				'standard' => q#Horário Padrão da Terra Nova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Horário de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Horário de Verão da Ilha Norfolk#,
				'generic' => q#Horário da Ilha Norfolk#,
				'standard' => q#Horário Padrão da Ilha Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Horário de Verão de Fernando de Noronha#,
				'generic' => q#Horário de Fernando de Noronha#,
				'standard' => q#Horário Padrão de Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Horário das Ilhas Mariana do Norte#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Horário de Verão de Novosibirsk#,
				'generic' => q#Horário de Novosibirsk#,
				'standard' => q#Horário Padrão de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Horário de Verão de Omsk#,
				'generic' => q#Horário de Omsk#,
				'standard' => q#Horário Padrão de Omsk#,
			},
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatnam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ilha de Páscoa#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Taraua#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Horário de Verão do Paquistão#,
				'generic' => q#Horário do Paquistão#,
				'standard' => q#Horário Padrão do Paquistão#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Horário de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Horário de Papua-Nova Guiné#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Horário de Verão do Paraguai#,
				'generic' => q#Horário do Paraguai#,
				'standard' => q#Horário Padrão do Paraguai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Horário de Verão do Peru#,
				'generic' => q#Horário do Peru#,
				'standard' => q#Horário Padrão do Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Horário de Verão das Filipinas#,
				'generic' => q#Horário das Filipinas#,
				'standard' => q#Horário Padrão das Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Horário das Ilhas Fênix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Horário Verão de São Pedro e Miquelão#,
				'generic' => q#Horário de São Pedro e Miquelão#,
				'standard' => q#Horário Padrão de São Pedro e Miquelão#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Horário de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Horário de Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Horário de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Horário de Verão de Qyzylorda#,
				'generic' => q#Horário de Qyzylorda#,
				'standard' => q#Horário Padrão de Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Horário de Reunião#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Horário de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Horário de Verão de Sacalina#,
				'generic' => q#Horário de Sacalina#,
				'standard' => q#Horário Padrão de Sacalina#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Horário de Verão de Samara#,
				'generic' => q#Horário de Samara#,
				'standard' => q#Horário Padrão de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Horário de Verão de Samoa#,
				'generic' => q#Horário de Samoa#,
				'standard' => q#Horário Padrão de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Horário de Seicheles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Horário Padrão de Singapura#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Horário das Ilhas Salomão#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Horário da Geórgia do Sul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Horário do Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Horário de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Horário do Taiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Horário de Verão de Taipei#,
				'generic' => q#Horário de Taipei#,
				'standard' => q#Horário Padrão de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Horário do Tajiquistão#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Horário de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Horário de Verão de Tonga#,
				'generic' => q#Horário de Tonga#,
				'standard' => q#Horário Padrão de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Horário de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Horário de Verão do Turcomenistão#,
				'generic' => q#Horário do Turcomenistão#,
				'standard' => q#Horário Padrão do Turcomenistão#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Horário de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Horário de Verão do Uruguai#,
				'generic' => q#Horário do Uruguai#,
				'standard' => q#Horário Padrão do Uruguai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Horário de Verão do Uzbequistão#,
				'generic' => q#Horário do Uzbequistão#,
				'standard' => q#Horário Padrão do Uzbequistão#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Horário de Verão de Vanuatu#,
				'generic' => q#Horário de Vanuatu#,
				'standard' => q#Horário Padrão de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Horário da Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Horário de Verão de Vladivostok#,
				'generic' => q#Horário de Vladivostok#,
				'standard' => q#Horário Padrão de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Horário de Verão de Volgogrado#,
				'generic' => q#Horário de Volgogrado#,
				'standard' => q#Horário Padrão de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Horário de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Horário das Ilhas Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Horário de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Horário de Verão de Yakutsk#,
				'generic' => q#Horário de Yakutsk#,
				'standard' => q#Horário Padrão de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Horário de Verão de Ecaterimburgo#,
				'generic' => q#Horário de Ecaterimburgo#,
				'standard' => q#Horário Padrão de Ecaterimburgo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Horário do Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
