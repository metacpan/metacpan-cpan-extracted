=head1

Locale::CLDR::Locales::Pt - Package for language Portuguese

=cut

package Locale::CLDR::Locales::Pt;
# This file auto generated from Data\common\main\pt.xml
#	on Sun  5 Aug  6:18:11 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
		use bignum;
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
					rule => q(mil[ e →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[ e →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(um milhão[ e →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milhões[ e →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(um bilhão[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← bilhões[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(um trilhão[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← trilhões[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(um quatrilhão[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← quatrilhões[ e →→]),
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
					rule => q(mil[ e →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←← mil[ e →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(um milhão[ e →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← milhões[ e →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(um bilhão[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← bilhões[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(um trilhão[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilhões[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(um quatrilhão[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← quatrilhões[ e →→]),
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
					rule => q(←%spellout-cardinal-feminine← ­milésima[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(uma milionésima[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← milionésima[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(uma bilionésima[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← bilionésima[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(uma trilionésima[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← trilionésima[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(uma quadrilionésima[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
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
					rule => q(←%spellout-cardinal-masculine← ­milésimo[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(um milionésimo[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milionésimo[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(um bilionésimo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← bilionésimo[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(um trilionésimo[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← trilionésima[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(um quadrilionésimo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
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
 				'alt' => 'altai do sul',
 				'am' => 'amárico',
 				'an' => 'aragonês',
 				'ang' => 'inglês arcaico',
 				'anp' => 'angika',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe moderno',
 				'arc' => 'aramaico',
 				'arn' => 'mapudungun',
 				'arp' => 'arapaho',
 				'ars' => 'árabe - Négede',
 				'arw' => 'arauaqui',
 				'as' => 'assamês',
 				'asa' => 'asu',
 				'ast' => 'asturiano',
 				'av' => 'avárico',
 				'awa' => 'awadhi',
 				'ay' => 'aimará',
 				'az' => 'azerbaijano',
 				'az@alt=short' => 'azeri',
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
 				'chr' => 'cherokee',
 				'chy' => 'cheiene',
 				'ckb' => 'curdo central',
 				'co' => 'corso',
 				'cop' => 'copta',
 				'cr' => 'cree',
 				'crh' => 'turco da Crimeia',
 				'crs' => 'crioulo francês seichelense',
 				'cs' => 'tcheco',
 				'csb' => 'kashubian',
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
 				'ee' => 'eve',
 				'efi' => 'efique',
 				'egy' => 'egípcio arcaico',
 				'eka' => 'ekajuk',
 				'el' => 'grego',
 				'elx' => 'elamite',
 				'en' => 'inglês',
 				'en_US@alt=short' => 'inglês (EUA)',
 				'enm' => 'inglês médio',
 				'eo' => 'esperanto',
 				'es' => 'espanhol',
 				'et' => 'estoniano',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'fa' => 'persa',
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
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koro',
 				'kg' => 'congolês',
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
 				'lkt' => 'lacota',
 				'ln' => 'lingala',
 				'lo' => 'laosiano',
 				'lol' => 'mongo',
 				'lou' => 'crioulo da Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri setentrional',
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
 				'pl' => 'polonês',
 				'pon' => 'pohnpeiano',
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
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'romeno',
 				'ro_MD' => 'moldávio',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'raiz',
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
 				'sm' => 'samoano',
 				'sma' => 'sami do sul',
 				'smj' => 'sami de Lule',
 				'smn' => 'sami de Inari',
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
 				'te' => 'télugo',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tétum',
 				'tg' => 'tadjique',
 				'th' => 'tailandês',
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
 				'ty' => 'taitiano',
 				'tyv' => 'tuviniano',
 				'tzm' => 'tamazirte do Atlas Central',
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
 				'yue' => 'cantonês',
 				'za' => 'zhuang',
 				'zap' => 'zapoteco',
 				'zbl' => 'símbolos blis',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazirte marroqino padrão',
 				'zh' => 'chinês',
 				'zh_Hans' => 'chinês simplificado',
 				'zh_Hant' => 'chinês tradicional',
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
			'Arab' => 'árabe',
 			'Arab@alt=variant' => 'perso-árabe',
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
 			'Orya' => 'oriya',
 			'Osma' => 'osmania',
 			'Perm' => 'pérmico antigo',
 			'Phag' => 'phags-pa',
 			'Phli' => 'phli',
 			'Phlp' => 'phlp',
 			'Phlv' => 'pahlavi antigo',
 			'Phnx' => 'fenício',
 			'Plrd' => 'fonético pollard',
 			'Prti' => 'prti',
 			'Rjng' => 'rejang',
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
 			'Zsye' => 'Emoji',
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
 			'419' => 'América Latina',
 			'AC' => 'Ilha de Ascensão',
 			'AD' => 'Andorra',
 			'AE' => 'Emirados Árabes Unidos',
 			'AF' => 'Afeganistão',
 			'AG' => 'Antígua e Barbuda',
 			'AI' => 'Anguilla',
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
 			'BH' => 'Bahrein',
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
 			'CG' => 'Congo - Brazzaville',
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
 			'EA' => 'Ceuta e Melilha',
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
 			'FK@alt=variant' => 'Ilhas Falkland (Ilhas Malvinas)',
 			'FM' => 'Micronésia',
 			'FO' => 'Ilhas Faroe',
 			'FR' => 'França',
 			'GA' => 'Gabão',
 			'GB' => 'Reino Unido',
 			'GB@alt=short' => 'Reino Unido',
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
 			'MK' => 'Macedônia',
 			'MK@alt=variant' => 'Macedônia (ARIM)',
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
 			'NL' => 'Holanda',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelândia',
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
 			'SZ' => 'Suazilândia',
 			'TA' => 'Tristão da Cunha',
 			'TC' => 'Ilhas Turks e Caicos',
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
 			'colbackwards' => 'Classificação reversa de acentos',
 			'colcasefirst' => 'Ordem de maiúsculas/minúsculas',
 			'colcaselevel' => 'Ordem com diferenciação de maiúsculas e minúsculas',
 			'collation' => 'Ordenação',
 			'colnormalization' => 'Classificação normalizada',
 			'colnumeric' => 'Classificação numérica',
 			'colstrength' => 'Intensidade da classificação',
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
 				'coptic' => q{Calendário Coptic},
 				'dangi' => q{Calendário Dangi},
 				'ethiopic' => q{Calendário Etíope},
 				'ethiopic-amete-alem' => q{Calendário Amete Alem da Etiópia},
 				'gregorian' => q{Calendário Gregoriano},
 				'hebrew' => q{Calendário Hebraico},
 				'indian' => q{Calendário Nacional Indiano},
 				'islamic' => q{Calendário Islâmico},
 				'islamic-civil' => q{Calendário Civil Islâmico},
 				'islamic-umalqura' => q{Calendário Islâmico (Umm al-Qura)},
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
 				'phonebook' => q{Ordem de Lista Telefônica},
 				'phonetic' => q{Ordem de classificação fonética},
 				'pinyin' => q{Ordem Pin-yin},
 				'reformed' => q{Ordem reformulada},
 				'search' => q{Pesquisa de uso geral},
 				'searchjl' => q{Pesquisar por consonante inicial hangul},
 				'standard' => q{Ordem padrão},
 				'stroke' => q{Ordem dos Traços},
 				'traditional' => q{Ordem Tradicional},
 				'unihan' => q{Ordem por Radical-Traços},
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
 				'fwidth' => q{Extensão total},
 				'hwidth' => q{Extensão total},
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
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistema métrico},
 				'uksystem' => q{Sistema de medição imperial},
 				'ussystem' => q{Sistema de medição americano},
 			},
 			'numbers' => {
 				'arab' => q{Algarismos indo-arábicos},
 				'arabext' => q{Algarismos indo-arábicos por extenso},
 				'armn' => q{Algarismos armênios},
 				'armnlow' => q{Algarismos armênios minúsculos},
 				'beng' => q{Algarismos bengali},
 				'deva' => q{Algarismos devanágari},
 				'ethi' => q{Algarismos etiopianos},
 				'finance' => q{Numerais financeiros},
 				'fullwide' => q{Algarismos em extensão total},
 				'geor' => q{Algarismos georgianos},
 				'grek' => q{Algarismos gregos},
 				'greklow' => q{Algarismos gregos minúsculos},
 				'gujr' => q{Algarismos guzerate},
 				'guru' => q{Algarismos gurmukhi},
 				'hanidec' => q{Algarismos decimais chineses},
 				'hans' => q{Algarismos chineses simplificados},
 				'hansfin' => q{Algarismos financeiros chineses simplificados},
 				'hant' => q{Algarismos chineses tradicionais},
 				'hantfin' => q{Algarismos financeiros chineses tradicionais},
 				'hebr' => q{Algarismos hebraicos},
 				'jpan' => q{Algarismos japoneses},
 				'jpanfin' => q{Algarismos financeiros japoneses},
 				'khmr' => q{Algarismos khmer},
 				'knda' => q{Algarismos canareses},
 				'laoo' => q{Algarismos laosianos},
 				'latn' => q{Algarismos ocidentais},
 				'mlym' => q{Algarismos malaialos},
 				'mong' => q{Algarismos mongóis},
 				'mymr' => q{Algarismos de Myanmar},
 				'native' => q{Dígitos nativos},
 				'orya' => q{Algarismos oriá},
 				'roman' => q{Algarismos romanos},
 				'romanlow' => q{Algarismos romanos minúsculos},
 				'taml' => q{Algarismos tâmil tradicionais},
 				'tamldec' => q{Algarismos tâmil},
 				'telu' => q{Algarismos telugos},
 				'thai' => q{Algarismos tailandeses},
 				'tibt' => q{Algarismos tibetanos},
 				'traditional' => q{Numerais tradicionais},
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
 			'UK' => q{inglês},
 			'US' => q{americano},

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
			auxiliary => qr{[ª ă å ä ā æ è ĕ ë ē ì ĭ î ï ī ñ º ŏ ö ø ō œ ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a á à â ã b c ç d e é ê f g h i í j k l m n o ó ò ô õ p q r s t u ú v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
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
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
					},
					'ampere' => {
						'name' => q(amperes),
						'one' => q({0} ampere),
						'other' => q({0} amperes),
					},
					'arc-minute' => {
						'name' => q(minutos de arco),
						'one' => q({0} minuto de arco),
						'other' => q({0} minutos de arco),
					},
					'arc-second' => {
						'name' => q(segundos de arco),
						'one' => q({0} segundo de arco),
						'other' => q({0} segundos de arco),
					},
					'astronomical-unit' => {
						'name' => q(unidades astronômicas),
						'one' => q({0} unidade astronômica),
						'other' => q({0} unidades astronômicas),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(calorias),
						'one' => q({0} caloria),
						'other' => q({0} calorias),
					},
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					'celsius' => {
						'name' => q(graus Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graus Celsius),
					},
					'centiliter' => {
						'name' => q(centilitros),
						'one' => q({0} centilitro),
						'other' => q({0} centilitros),
					},
					'centimeter' => {
						'name' => q(centímetros),
						'one' => q({0} centímetro),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetro),
					},
					'century' => {
						'name' => q(séculos),
						'one' => q({0} século),
						'other' => q({0} sécs.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetro cúbico),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} por centímetro cúbico),
					},
					'cubic-foot' => {
						'name' => q(pés cúbicos),
						'one' => q({0} pé cúbico),
						'other' => q({0} pés cúbicos),
					},
					'cubic-inch' => {
						'name' => q(polegadas cúbicas),
						'one' => q({0} polegada cúbica),
						'other' => q({0} polegadas cúbicas),
					},
					'cubic-kilometer' => {
						'name' => q(quilômetros cúbicos),
						'one' => q({0} quilômetro cúbico),
						'other' => q({0} quilômetros cúbicos),
					},
					'cubic-meter' => {
						'name' => q(metros cúbicos),
						'one' => q({0} metro cúbico),
						'other' => q({0} metros cúbicos),
						'per' => q({0} por metro cúbico),
					},
					'cubic-mile' => {
						'name' => q(milhas cúbicas),
						'one' => q({0} milha cúbica),
						'other' => q({0} milhas cúbicas),
					},
					'cubic-yard' => {
						'name' => q(jardas cúbicas),
						'one' => q({0} jarda cúbica),
						'other' => q({0} jardas cúbicas),
					},
					'cup' => {
						'name' => q(xícaras),
						'one' => q({0} xícara),
						'other' => q({0} xícaras),
					},
					'cup-metric' => {
						'name' => q(xícaras métricas),
						'one' => q({0} xícara métrica),
						'other' => q({0} xícaras métricas),
					},
					'day' => {
						'name' => q(dias),
						'one' => q({0} dia),
						'other' => q({0} dias),
						'per' => q({0} por dia),
					},
					'deciliter' => {
						'name' => q(decilitros),
						'one' => q({0} decilitro),
						'other' => q({0} decilitros),
					},
					'decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetro),
						'other' => q({0} decímetros),
					},
					'degree' => {
						'name' => q(graus),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					'fahrenheit' => {
						'name' => q(graus Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graus Fahrenheit),
					},
					'fathom' => {
						'name' => q(braças),
						'one' => q({0} braça),
						'other' => q({0} braças),
					},
					'fluid-ounce' => {
						'name' => q(onças fluidas),
						'one' => q({0} onça fluida),
						'other' => q({0} onças fluidas),
					},
					'foodcalorie' => {
						'name' => q(Calorias),
						'one' => q({0} Caloria),
						'other' => q({0} Calorias),
					},
					'foot' => {
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0} por pé),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					'g-force' => {
						'name' => q(força g),
						'one' => q({0} força g),
						'other' => q({0} força g),
					},
					'gallon' => {
						'name' => q(galões),
						'one' => q({0} galão),
						'other' => q({0} galões),
						'per' => q({0} por galão),
					},
					'gallon-imperial' => {
						'name' => q(galões imperiais),
						'one' => q({0} galão imperial),
						'other' => q({0} galões imperiais),
						'per' => q({0} por galão imperial),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'name' => q(gramas),
						'one' => q({0} grama),
						'other' => q({0} gramas),
						'per' => q({0} por grama),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					'hectoliter' => {
						'name' => q(hectolitros),
						'one' => q({0} hectolitro),
						'other' => q({0} hectolitros),
					},
					'hectopascal' => {
						'name' => q(hectopascais),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascais),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(cavalos-vapor),
						'one' => q({0} cavalo-vapor),
						'other' => q({0} cavalos-vapor),
					},
					'hour' => {
						'name' => q(horas),
						'one' => q({0} hora),
						'other' => q({0} horas),
						'per' => q({0} por hora),
					},
					'inch' => {
						'name' => q(polegadas),
						'one' => q({0} polegada),
						'other' => q({0} polegadas),
						'per' => q({0} por polegada),
					},
					'inch-hg' => {
						'name' => q(polegadas de mercúrio),
						'one' => q({0} polegada de mercúrio),
						'other' => q({0} polegadas de mercúrio),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(kilates),
						'one' => q({0} kilate),
						'other' => q({0} kilates),
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
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					'kilogram' => {
						'name' => q(quilogramas),
						'one' => q({0} quilograma),
						'other' => q({0} quilogramas),
						'per' => q({0} por quilograma),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(quilojoules),
						'one' => q({0} quilojoule),
						'other' => q({0} quilojoules),
					},
					'kilometer' => {
						'name' => q(quilômetros),
						'one' => q({0} quilômetro),
						'other' => q({0} quilômetros),
						'per' => q({0} por quilômetro),
					},
					'kilometer-per-hour' => {
						'name' => q(quilômetros por hora),
						'one' => q({0} quilômetro por hora),
						'other' => q({0} quilômetros por hora),
					},
					'kilowatt' => {
						'name' => q(quilowatts),
						'one' => q({0} quilowatt),
						'other' => q({0} quilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(quilowatts-hora),
						'one' => q({0} quilowatt-hora),
						'other' => q({0} quilowatts-hora),
					},
					'knot' => {
						'name' => q(nó),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					'light-year' => {
						'name' => q(anos-luz),
						'one' => q({0} ano-luz),
						'other' => q({0} anos-luz),
					},
					'liter' => {
						'name' => q(litros),
						'one' => q({0} litro),
						'other' => q({0} litros),
						'per' => q({0} por litro),
					},
					'liter-per-100kilometers' => {
						'name' => q(litros por 100 quilômetros),
						'one' => q({0} litro por 100 quilômetros),
						'other' => q({0} litros por 100 quilômetros),
					},
					'liter-per-kilometer' => {
						'name' => q(litros por quilômetro),
						'one' => q({0} litro por quilômetro),
						'other' => q({0} litros por quilômetro),
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
						'name' => q(megalitros),
						'one' => q({0} megalitro),
						'other' => q({0} megalitros),
					},
					'megawatt' => {
						'name' => q(megawatts),
						'one' => q({0} megawatt),
						'other' => q({0} megawatts),
					},
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metro),
						'other' => q({0} metros),
						'per' => q({0} por metro),
					},
					'meter-per-second' => {
						'name' => q(metros por segundo),
						'one' => q({0} metro por segundo),
						'other' => q({0} metros por segundo),
					},
					'meter-per-second-squared' => {
						'name' => q(metros por segundo ao quadrado),
						'one' => q({0} metro por segundo ao quadrado),
						'other' => q({0} metros por segundo ao quadrado),
					},
					'metric-ton' => {
						'name' => q(toneladas métricas),
						'one' => q({0} tonelada métrica),
						'other' => q({0} toneladas métricas),
					},
					'microgram' => {
						'name' => q(microgramas),
						'one' => q({0} micrograma),
						'other' => q({0} microgramas),
					},
					'micrometer' => {
						'name' => q(micrômetros),
						'one' => q({0} micrômetro),
						'other' => q({0} micrômetros),
					},
					'microsecond' => {
						'name' => q(microssegundos),
						'one' => q({0} microssegundo),
						'other' => q({0} microssegundos),
					},
					'mile' => {
						'name' => q(milhas),
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					'mile-per-gallon' => {
						'name' => q(milhas por galão),
						'one' => q({0} milha por galão),
						'other' => q({0} milhas por galão),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milhas por galão imperial),
						'one' => q({0} milha por galão imperial),
						'other' => q({0} milhas por galão imperial),
					},
					'mile-per-hour' => {
						'name' => q(milhas por hora),
						'one' => q({0} milha por hora),
						'other' => q({0} milhas por hora),
					},
					'mile-scandinavian' => {
						'name' => q(milhas escandinavas),
						'one' => q({0} milha escandinava),
						'other' => q({0} milhas escandinavas),
					},
					'milliampere' => {
						'name' => q(miliamperes),
						'one' => q({0} miliampere),
						'other' => q({0} miliamperes),
					},
					'millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					'milligram' => {
						'name' => q(miligramas),
						'one' => q({0} miligrama),
						'other' => q({0} miligramas),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligramas por decilitro),
						'one' => q({0} miligrama por decilitro),
						'other' => q({0} miligramas por decilitro),
					},
					'milliliter' => {
						'name' => q(mililitros),
						'one' => q({0} mililitro),
						'other' => q({0} mililitros),
					},
					'millimeter' => {
						'name' => q(milímetros),
						'one' => q({0} milímetro),
						'other' => q({0} milímetros),
					},
					'millimeter-of-mercury' => {
						'name' => q(milímetros de mercúrio),
						'one' => q({0} milímetro de mercúrio),
						'other' => q({0} milímetros de mercúrio),
					},
					'millimole-per-liter' => {
						'name' => q(milimols por litro),
						'one' => q({0} milimol por litro),
						'other' => q({0} milimols por litro),
					},
					'millisecond' => {
						'name' => q(milissegundos),
						'one' => q({0} milissegundo),
						'other' => q({0} milissegundos),
					},
					'milliwatt' => {
						'name' => q(miliwatts),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatts),
					},
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} minuto),
						'other' => q({0} minutos),
						'per' => q({0} por minuto),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} mês),
						'other' => q({0} meses),
						'per' => q({0} por mês),
					},
					'nanometer' => {
						'name' => q(nanômetros),
						'one' => q({0} nanômetro),
						'other' => q({0} nanômetros),
					},
					'nanosecond' => {
						'name' => q(nanossegundos),
						'one' => q({0} nanossegundo),
						'other' => q({0} nanossegundos),
					},
					'nautical-mile' => {
						'name' => q(milhas náuticas),
						'one' => q({0} milha náutica),
						'other' => q({0} milhas náuticas),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(onças),
						'one' => q({0} onça),
						'other' => q({0} onças),
						'per' => q({0} por onça),
					},
					'ounce-troy' => {
						'name' => q(onças troy),
						'one' => q({0} onça troy),
						'other' => q({0} onças troy),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(partes por milhão),
						'one' => q({0} parte por milhão),
						'other' => q({0} partes por milhão),
					},
					'per' => {
						'1' => q({0} por {1}),
					},
					'picometer' => {
						'name' => q(picômetros),
						'one' => q({0} picômetro),
						'other' => q({0} picômetros),
					},
					'pint' => {
						'name' => q(pints),
						'one' => q({0} pint),
						'other' => q({0} pints),
					},
					'pint-metric' => {
						'name' => q(pints métricos),
						'one' => q({0} pint métrico),
						'other' => q({0} pints métricos),
					},
					'point' => {
						'name' => q(pontos),
						'one' => q({0} ponto),
						'other' => q({0} pontos),
					},
					'pound' => {
						'name' => q(libras),
						'one' => q({0} libra),
						'other' => q({0} libras),
						'per' => q({0} por libra),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(quartos),
						'one' => q({0} quarto),
						'other' => q({0} quartos),
					},
					'radian' => {
						'name' => q(radianos),
						'one' => q({0} radiano),
						'other' => q({0} radianos),
					},
					'revolution' => {
						'name' => q(revolução),
						'one' => q({0} revolução),
						'other' => q({0} revoluções),
					},
					'second' => {
						'name' => q(segundos),
						'one' => q({0} segundo),
						'other' => q({0} segundos),
						'per' => q({0} por segundo),
					},
					'square-centimeter' => {
						'name' => q(centímetros quadrados),
						'one' => q({0} centímetro quadrado),
						'other' => q({0} centímetros quadrados),
						'per' => q({0} por centímetro quadrado),
					},
					'square-foot' => {
						'name' => q(pés quadrados),
						'one' => q({0} pé quadrado),
						'other' => q({0} pés quadrados),
					},
					'square-inch' => {
						'name' => q(polegadas quadradas),
						'one' => q({0} polegada quadrada),
						'other' => q({0} polegadas quadradas),
						'per' => q({0} por polegada quadrada),
					},
					'square-kilometer' => {
						'name' => q(quilômetros quadrados),
						'one' => q({0} quilômetro quadrado),
						'other' => q({0} quilômetros quadrados),
						'per' => q({0} por quilômetro quadrado),
					},
					'square-meter' => {
						'name' => q(metros quadrados),
						'one' => q({0} metro quadrado),
						'other' => q({0} metros quadrados),
						'per' => q({0} por metro quadrado),
					},
					'square-mile' => {
						'name' => q(milhas quadradas),
						'one' => q({0} milha quadrada),
						'other' => q({0} milhas quadradas),
						'per' => q({0} por milha quadrada),
					},
					'square-yard' => {
						'name' => q(jardas quadradas),
						'one' => q({0} jarda quadrada),
						'other' => q({0} jardas quadradas),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					'tablespoon' => {
						'name' => q(colheres de sopa),
						'one' => q({0} colher de sopa),
						'other' => q({0} colheres de sopa),
					},
					'teaspoon' => {
						'name' => q(colheres de chá),
						'one' => q({0} colher de chá),
						'other' => q({0} colheres de chá),
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
						'name' => q(toneladas),
						'one' => q({0} tonelada),
						'other' => q({0} toneladas),
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
						'name' => q(semanas),
						'one' => q({0} semana),
						'other' => q({0} semanas),
						'per' => q({0} por semana),
					},
					'yard' => {
						'name' => q(jardas),
						'one' => q({0} jarda),
						'other' => q({0} jardas),
					},
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0} por ano),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'arc-minute' => {
						'one' => q({0}'),
						'other' => q({0}'),
					},
					'arc-second' => {
						'one' => q({0}"),
						'other' => q({0}"),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'carat' => {
						'name' => q(quilate),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} sécs.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'day' => {
						'name' => q(dia),
						'one' => q({0} dia),
						'other' => q({0} dias),
						'per' => q({0}/dia),
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
						'name' => q(braça),
						'one' => q({0} bça.),
						'other' => q({0} bça.),
					},
					'foot' => {
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0}/pé),
					},
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(força g),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gram' => {
						'name' => q(grama),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					'hour' => {
						'name' => q(hora),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(pol.),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/pol.),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
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
					'knot' => {
						'name' => q(nó),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					'light-year' => {
						'name' => q(anos-luz),
						'one' => q({0} ano-luz),
						'other' => q({0} anos-luz),
					},
					'liter' => {
						'name' => q(litro),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'meter' => {
						'name' => q(metro),
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
						'one' => q({0} milha),
						'other' => q({0} milhas),
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
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
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
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(mês),
						'one' => q({0} mês),
						'other' => q({0} meses),
						'per' => q({0}/mês),
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
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'second' => {
						'name' => q(seg),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/seg),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
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
					'stone' => {
						'name' => q(stone),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(ano),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acres),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(acre-pés),
						'one' => q({0} acre-pé),
						'other' => q({0} acre-pés),
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
						'name' => q(arcsegs),
						'one' => q({0} arcseg),
						'other' => q({0} arcsegs),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
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
						'name' => q(quilates),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					'celsius' => {
						'name' => q(graus C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(séc.),
						'one' => q({0} séc.),
						'other' => q({0} sécs.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(pés³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(polegadas³),
						'one' => q({0} pol³),
						'other' => q({0} pol³),
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
						'name' => q(jardas³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(xícaras),
						'one' => q({0} xíc.),
						'other' => q({0} xíc.),
					},
					'cup-metric' => {
						'name' => q(xícm),
						'one' => q({0} xícm),
						'other' => q({0} xícm),
					},
					'day' => {
						'name' => q(dias),
						'one' => q({0} dia),
						'other' => q({0} dias),
						'per' => q({0}/dia),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(graus),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(graus F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'name' => q(braças),
						'one' => q({0} bça.),
						'other' => q({0} bça.),
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
						'name' => q(pés),
						'one' => q({0} pé),
						'other' => q({0} pés),
						'per' => q({0}/pé),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(força g),
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
						'name' => q(gal. imp.),
						'one' => q({0} gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
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
						'name' => q(gramas),
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
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
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
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					'hour' => {
						'name' => q(horas),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
						'per' => q({0}/pol.),
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
						'name' => q(kilates),
						'one' => q({0} k),
						'other' => q({0} k),
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
						'name' => q(quilojoule),
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
						'name' => q(kW-hora),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(nó),
						'one' => q({0} nó),
						'other' => q({0} nós),
					},
					'light-year' => {
						'name' => q(anos-luz),
						'one' => q({0} ano-luz),
						'other' => q({0} anos-luz),
					},
					'liter' => {
						'name' => q(litros),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litros/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
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
						'name' => q(metros),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metros/seg),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(metros/seg²),
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
						'name' => q(milhas),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(milhas/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milhas/gal. imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(milhas/hora),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliamps),
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
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
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
						'name' => q(milimol/litro),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(milissegundos),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} mês),
						'other' => q({0} meses),
						'per' => q({0}/mês),
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
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
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
						'name' => q(partes/milhão),
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
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					'point' => {
						'name' => q(pontos),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(libras),
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
						'name' => q(radianos),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(seg),
						'one' => q({0} seg),
						'other' => q({0} seg),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0} por cm²),
					},
					'square-foot' => {
						'name' => q(pés²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(polegadas²),
						'one' => q({0} pol²),
						'other' => q({0} pol²),
						'per' => q({0} por pol²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(metros²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0} por m²),
					},
					'square-mile' => {
						'name' => q(milhas²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(jardas²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(CS),
						'one' => q({0} CS),
						'other' => q({0} CS),
					},
					'teaspoon' => {
						'name' => q(cc),
						'one' => q({0} cc),
						'other' => q({0} cc),
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
						'name' => q(toneladas),
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
						'name' => q(semanas),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					'yard' => {
						'name' => q(jardas),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(anos),
						'one' => q({0} ano),
						'other' => q({0} anos),
						'per' => q({0}/ano),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
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
		'ADP' => {
			display_name => {
				'currency' => q(Peseta de Andorra),
				'one' => q(Peseta de Andorra),
				'other' => q(Pesetas de Andorra),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirrã dos Emirados Árabes Unidos),
				'one' => q(Dirrã dos Emirados Árabes Unidos),
				'other' => q(Dirrãs dos Emirados Árabes Unidos),
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
			symbol => 'AFN',
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
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek albanês),
				'one' => q(Lek albanês),
				'other' => q(Leks albaneses),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram armênio),
				'one' => q(Dram armênio),
				'other' => q(Drams armênios),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Florim das Antilhas Holandesas),
				'one' => q(Florim das Antilhas Holandesas),
				'other' => q(Florins das Antilhas Holandesas),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'AWG',
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
			symbol => 'AZN',
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
			symbol => 'BAM',
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
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dólar barbadense),
				'one' => q(Dólar barbadense),
				'other' => q(Dólares barbadenses),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka bengalesa),
				'one' => q(Taka bengalesa),
				'other' => q(Takas bengalesas),
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
			symbol => 'BGN',
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
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar bareinita),
				'one' => q(Dinar bareinita),
				'other' => q(Dinares bareinitas),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Franco burundiano),
				'one' => q(Franco burundiano),
				'other' => q(Francos burundianos),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dólar bermudense),
				'one' => q(Dólar bermudense),
				'other' => q(Dólares bermudenses),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Dólar bruneano),
				'one' => q(Dólar bruneano),
				'other' => q(Dólares bruneanos),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviano),
				'one' => q(Boliviano),
				'other' => q(Bolivianos),
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
			symbol => 'R$',
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
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dólar bahamense),
				'one' => q(Dólar bahamense),
				'other' => q(Dólares bahamenses),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
			symbol => 'BWP',
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
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rublo bielorrusso),
				'one' => q(Rublo bielorrusso),
				'other' => q(Rublos bielorrussos),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rublo bielorrusso \(2000–2016\)),
				'one' => q(Rublo bielorrusso \(2000–2016\)),
				'other' => q(Rublos bielorrussos \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dólar belizenho),
				'one' => q(Dólar belizenho),
				'other' => q(Dólares belizenhos),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dólar canadense),
				'one' => q(Dólar canadense),
				'other' => q(Dólares canadenses),
			},
		},
		'CDF' => {
			symbol => 'CDF',
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
			symbol => 'CHF',
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
			symbol => 'CLP',
			display_name => {
				'currency' => q(Peso chileno),
				'one' => q(Peso chileno),
				'other' => q(Pesos chilenos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan \(offshore\)),
				'one' => q(Yuan \(offshore\)),
				'other' => q(Yuans \(offshore\)),
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
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan chinês),
				'one' => q(Yuan chinês),
				'other' => q(Yuans chineses),
			},
		},
		'COP' => {
			symbol => 'COP',
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
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(Peso cubano conversível),
				'one' => q(Peso cubano conversível),
				'other' => q(Pesos cubanos conversíveis),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Peso cubano),
				'one' => q(Peso cubano),
				'other' => q(Pesos cubanos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(Franco djiboutiano),
				'one' => q(Franco djiboutiano),
				'other' => q(Francos djiboutianos),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Coroa dinamarquesa),
				'one' => q(Coroa dinamarquesa),
				'other' => q(Coroas dinamarquesas),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Peso dominicano),
				'one' => q(Peso dominicano),
				'other' => q(Pesos dominicanos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(Libra egípcia),
				'one' => q(Libra egípcia),
				'other' => q(Libras egípcias),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr etíope),
				'one' => q(Birr etíope),
				'other' => q(Birrs etíopes),
			},
		},
		'EUR' => {
			symbol => '€',
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
			symbol => 'FJD',
			display_name => {
				'currency' => q(Dólar fijiano),
				'one' => q(Dólar fijiano),
				'other' => q(Dólares fijianos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
			symbol => '£',
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
			symbol => 'GEL',
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(Cedi ganês),
				'one' => q(Cedi ganês),
				'other' => q(Cedis ganeses),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Libra de Gibraltar),
				'one' => q(Libra de Gibraltar),
				'other' => q(Libras de Gibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Dalasi gambiano),
				'one' => q(Dalasi gambiano),
				'other' => q(Dalasis gambianos),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
			display_name => {
				'currency' => q(Dólar guianense),
				'one' => q(Dólar guianense),
				'other' => q(Dólares guianenses),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dólar de Hong Kong),
				'one' => q(Dólar de Hong Kong),
				'other' => q(Dólares de Hong Kong),
			},
		},
		'HNL' => {
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna croata),
				'one' => q(Kuna croata),
				'other' => q(Kunas croatas),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde haitiano),
				'one' => q(Gourde haitiano),
				'other' => q(Gourdes haitianos),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Florim húngaro),
				'one' => q(Florim húngaro),
				'other' => q(Florins húngaros),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
			display_name => {
				'currency' => q(Sheqel novo israelita),
				'one' => q(Sheqel novo israelita),
				'other' => q(Sheqels novos israelita),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia indiana),
				'one' => q(Rupia indiana),
				'other' => q(Rupias indianas),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar iraquiano),
				'one' => q(Dinar iraquiano),
				'other' => q(Dinares iraquianos),
			},
		},
		'IRR' => {
			symbol => 'IRR',
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
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dólar jamaicano),
				'one' => q(Dólar jamaicano),
				'other' => q(Dólares jamaicanos),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar jordaniano),
				'one' => q(Dinar jordaniano),
				'other' => q(Dinares jordanianos),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Iene japonês),
				'one' => q(Iene japonês),
				'other' => q(Ienes japoneses),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Xelim queniano),
				'one' => q(Xelim queniano),
				'other' => q(Xelins quenianos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som quirguiz),
				'one' => q(Som quirguiz),
				'other' => q(Sons quirguizes),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Riel cambojano),
				'one' => q(Riel cambojano),
				'other' => q(Rieles cambojanos),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Franco comoriano),
				'one' => q(Franco comoriano),
				'other' => q(Francos comorianos),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => '₩',
			display_name => {
				'currency' => q(Won sul-coreano),
				'one' => q(Won sul-coreano),
				'other' => q(Wons sul-coreanos),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar kuwaitiano),
				'one' => q(Dinar kuwaitiano),
				'other' => q(Dinares kuwaitianos),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Dólar das Ilhas Cayman),
				'one' => q(Dólar das Ilhas Cayman),
				'other' => q(Dólares das Ilhas Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge cazaque),
				'one' => q(Tenge cazaque),
				'other' => q(Tenges cazaques),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Kip laosiano),
				'one' => q(Kip laosiano),
				'other' => q(Kips laosianos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Libra libanesa),
				'one' => q(Libra libanesa),
				'other' => q(Libras libanesas),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia ceilandesa),
				'one' => q(Rupia ceilandesa),
				'other' => q(Rupias ceilandesas),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Dólar liberiano),
				'one' => q(Dólar liberiano),
				'other' => q(Dólares liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti do Lesoto),
				'one' => q(Loti do Lesoto),
				'other' => q(Lotis do Lesoto),
			},
		},
		'LTL' => {
			symbol => 'LTL',
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
			symbol => 'LVL',
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
			symbol => 'LYD',
			display_name => {
				'currency' => q(Dinar líbio),
				'one' => q(Dinar líbio),
				'other' => q(Dinares líbios),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
				'one' => q(Cupon moldávio),
				'other' => q(Cupon moldávio),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu moldávio),
				'one' => q(Leu moldávio),
				'other' => q(Leus moldávios),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
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
			symbol => 'MMK',
			display_name => {
				'currency' => q(Kyat mianmarense),
				'one' => q(Kyat mianmarense),
				'other' => q(Kyats mianmarenses),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik mongol),
				'one' => q(Tugrik mongol),
				'other' => q(Tugriks mongóis),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca macaense),
				'one' => q(Pataca macaense),
				'other' => q(Patacas macaenses),
			},
		},
		'MRO' => {
			symbol => 'MRO',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia mauriciana),
				'one' => q(Rupia mauriciana),
				'other' => q(Rupias mauricianas),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rupia maldiva),
				'one' => q(Rupia maldiva),
				'other' => q(Rupias maldivas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha malauiana),
				'one' => q(Kwacha malauiana),
				'other' => q(Kwachas malauianas),
			},
		},
		'MXN' => {
			symbol => 'MX$',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical moçambicano),
				'one' => q(Metical moçambicano),
				'other' => q(Meticais moçambicanos),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dólar namibiano),
				'one' => q(Dólar namibiano),
				'other' => q(Dólares namibianos),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
			symbol => 'NIO',
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(Coroa norueguesa),
				'one' => q(Coroa norueguesa),
				'other' => q(Coroas norueguesas),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia nepalesa),
				'one' => q(Rupia nepalesa),
				'other' => q(Rupias nepalesas),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Dólar neozelandês),
				'one' => q(Dólar neozelandês),
				'other' => q(Dólares neozelandeses),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial omanense),
				'one' => q(Rial omanense),
				'other' => q(Riales omanenses),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol peruano),
				'one' => q(Sol peruano),
				'other' => q(Sóis peruanos),
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
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia paquistanesa),
				'one' => q(Rupia paquistanesa),
				'other' => q(Rupias paquistanesas),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloti polonês),
				'one' => q(Zloti polonês),
				'other' => q(Zlotis poloneses),
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(Guarani paraguaio),
				'one' => q(Guarani paraguaio),
				'other' => q(Guaranis paraguaios),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu romeno),
				'one' => q(Leu romeno),
				'other' => q(Leus romenos),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Dinar sérvio),
				'one' => q(Dinar sérvio),
				'other' => q(Dinares sérvios),
			},
		},
		'RUB' => {
			symbol => 'RUB',
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
			symbol => 'RWF',
			display_name => {
				'currency' => q(Franco ruandês),
				'one' => q(Franco ruandês),
				'other' => q(Francos ruandeses),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal saudita),
				'one' => q(Riyal saudita),
				'other' => q(Riyales sauditas),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Dólar das Ilhas Salomão),
				'one' => q(Dólar das Ilhas Salomão),
				'other' => q(Dólares das Ilhas Salomão),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
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
			symbol => 'SEK',
			display_name => {
				'currency' => q(Coroa sueca),
				'one' => q(Coroa sueca),
				'other' => q(Coroas suecas),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Dólar singapuriano),
				'one' => q(Dólar singapuriano),
				'other' => q(Dólares singapurianos),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Leone de Serra Leoa),
				'one' => q(Leone de Serra Leoa),
				'other' => q(Leones de Serra Leoa),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Xelim somaliano),
				'one' => q(Xelim somaliano),
				'other' => q(Xelins somalianos),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(Libra sul-sudanesa),
				'one' => q(Libra sul-sudanesa),
				'other' => q(Libras sul-sudanesas),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
				'one' => q(Dobra de São Tomé e Príncipe \(1977–2017\)),
				'other' => q(Dobras de São Tomé e Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(Libra síria),
				'one' => q(Libra síria),
				'other' => q(Libras sírias),
			},
		},
		'SZL' => {
			symbol => 'SZL',
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
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat turcomeno),
				'one' => q(Manat turcomeno),
				'other' => q(Manats turcomenos),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Dinar tunisiano),
				'one' => q(Dinar tunisiano),
				'other' => q(Dinares tunisianos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(Lira turca),
				'one' => q(Lira turca),
				'other' => q(Liras turcas),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(Xelim tanzaniano),
				'one' => q(Xelim tanzaniano),
				'other' => q(Xelins tanzanianos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
			display_name => {
				'currency' => q(Xelim ugandense),
				'one' => q(Xelim ugandense),
				'other' => q(Xelins ugandenses),
			},
		},
		'USD' => {
			symbol => 'US$',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(Peso uruguaio),
				'one' => q(Peso uruguaio),
				'other' => q(Pesos uruguaios),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
			display_name => {
				'currency' => q(Bolívar venezuelano),
				'one' => q(Bolívar venezuelano),
				'other' => q(Bolívares venezuelanos),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Dong vietnamita),
				'one' => q(Dong vietnamita),
				'other' => q(Dongs vietnamitas),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong vietnamita \(1978–1985\)),
				'one' => q(Dong vietnamita \(1978–1985\)),
				'other' => q(Dong vietnamita \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vatu vanuatuense),
				'one' => q(Vatu vanuatuense),
				'other' => q(Vatus vanuatuenses),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Tala samoano),
				'one' => q(Tala samoano),
				'other' => q(Talas samoanos),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
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
			symbol => 'EC$',
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
			symbol => 'CFA',
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
			symbol => 'CFPF',
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
				'one' => q(Fundos RINET),
				'other' => q(Fundos RINET),
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
				'one' => q(\(moeda desconhecida\)),
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
			symbol => 'YER',
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
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand sul-africano),
				'one' => q(Rand sul-africano),
				'other' => q(Rands sul-africanos),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Cuacha zambiano \(1968–2012\)),
				'one' => q(Kwacha da Zâmbia \(1968–2012\)),
				'other' => q(Kwachas da Zâmbia \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
							'Nasie'
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
							'Tout',
							'Baba',
							'Hator',
							'Kiahk',
							'Toba',
							'Amshir',
							'Baramhat',
							'Baramouda',
							'Bashans',
							'Paona',
							'Epep',
							'Mesra',
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
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
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
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
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
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
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
							'jan',
							'fev',
							'mar',
							'abr',
							'mai',
							'jun',
							'jul',
							'ago',
							'set',
							'out',
							'nov',
							'dez'
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
					abbreviated => {
						nonleap => [
							'jan',
							'fev',
							'mar',
							'abr',
							'mai',
							'jun',
							'jul',
							'ago',
							'set',
							'out',
							'nov',
							'dez'
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
			},
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
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
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
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
							'',
							'',
							'',
							'',
							'',
							'',
							'7'
						],
					},
					wide => {
						nonleap => [
							'Tishri',
							'Heshvan',
							'Kislev',
							'Tevet',
							'Shevat',
							'Adar I',
							'Adar',
							'Nisan',
							'Iyar',
							'Sivan',
							'Tamuz',
							'Av',
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
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
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
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
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
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
							'Farvardin',
							'Ordibehesht',
							'Khordad',
							'Tir',
							'Mordad',
							'Shahrivar',
							'Mehr',
							'Aban',
							'Azar',
							'Dey',
							'Bahman',
							'Esfand'
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
						mon => 'seg',
						tue => 'ter',
						wed => 'qua',
						thu => 'qui',
						fri => 'sex',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'Q',
						thu => 'Q',
						fri => 'S',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'seg',
						tue => 'ter',
						wed => 'qua',
						thu => 'qui',
						fri => 'sex',
						sat => 'sáb',
						sun => 'dom'
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
					abbreviated => {
						mon => 'seg',
						tue => 'ter',
						wed => 'qua',
						thu => 'qui',
						fri => 'sex',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'S',
						tue => 'T',
						wed => 'Q',
						thu => 'Q',
						fri => 'S',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'seg',
						tue => 'ter',
						wed => 'qua',
						thu => 'qui',
						fri => 'sex',
						sat => 'sáb',
						sun => 'dom'
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
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
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
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
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
					'night1' => q{da madrugada},
					'pm' => q{PM},
					'midnight' => q{meia-noite},
					'noon' => q{meio-dia},
					'am' => q{AM},
					'morning1' => q{da manhã},
					'evening1' => q{da noite},
					'afternoon1' => q{da tarde},
				},
				'wide' => {
					'noon' => q{meio-dia},
					'evening1' => q{da noite},
					'morning1' => q{da manhã},
					'afternoon1' => q{da tarde},
					'am' => q{AM},
					'night1' => q{da madrugada},
					'midnight' => q{meia-noite},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'evening1' => q{da noite},
					'morning1' => q{da manhã},
					'afternoon1' => q{da tarde},
					'noon' => q{meio-dia},
					'pm' => q{PM},
					'midnight' => q{meia-noite},
					'night1' => q{da madrugada},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'pm' => q{PM},
					'midnight' => q{meia-noite},
					'night1' => q{madrugada},
					'am' => q{AM},
					'evening1' => q{noite},
					'morning1' => q{manhã},
					'afternoon1' => q{tarde},
					'noon' => q{meio-dia},
				},
				'wide' => {
					'midnight' => q{meia-noite},
					'pm' => q{PM},
					'night1' => q{madrugada},
					'afternoon1' => q{tarde},
					'evening1' => q{noite},
					'morning1' => q{manhã},
					'am' => q{AM},
					'noon' => q{meio-dia},
				},
				'abbreviated' => {
					'midnight' => q{meia-noite},
					'pm' => q{PM},
					'night1' => q{madrugada},
					'evening1' => q{noite},
					'afternoon1' => q{tarde},
					'morning1' => q{manhã},
					'am' => q{AM},
					'noon' => q{meio-dia},
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
				'0' => 'EB'
			},
			wide => {
				'0' => 'EB'
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
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
			wide => {
				'0' => 'antes de Cristo',
				'1' => 'depois de Cristo'
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
				'0' => 'Antes da R.C.',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'Antes da R.C.',
				'1' => 'Minguo'
			},
			wide => {
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
			'short' => q{dd/MM/yy},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{dd/MM/y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
			'medium' => q{d 'de' MMM 'de' y},
			'short' => q{dd/MM/y},
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
			'medium' => q{dd/MM/y G},
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
		'generic' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
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
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
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
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM 'de' y G},
			GyMMMEd => q{E, d 'de' MMM 'de' y G},
			GyMMMd => q{d 'de' MMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d 'de' MMM},
			MMMMEd => q{E, d 'de' MMMM},
			MMMMW => q{W'ª' 'semana' 'de' MMMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d 'de' MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
				H => q{HH'h' - HH'h'},
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
				H => q{HH – HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d–d 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' - h'h' a},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y G},
				y => q{MMM 'de' y – MMM 'de' y G},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y G},
				d => q{E, d – E, d 'de' MMM 'de' y G},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'de' y G},
				y => q{MMMM 'de' y – MMMM 'de' y G},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y G},
				d => q{d–d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH'h' - HH'h'},
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
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM},
				d => q{E, d – E, d 'de' MMM},
			},
			MMMd => {
				M => q{d 'de' MMM – d 'de' MMM},
				d => q{d – d 'de' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM 'de' y},
				y => q{MMM 'de' y – MMM 'de' y},
			},
			yMMMEd => {
				M => q{E, d 'de' MMM – E, d 'de' MMM 'de' y},
				d => q{E, d – E, d 'de' MMM 'de' y},
				y => q{E, d 'de' MMM 'de' y – E, d 'de' MMM 'de' y},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'de' y},
				y => q{MMMM 'de' y – MMMM 'de' y},
			},
			yMMMd => {
				M => q{d 'de' MMM – d 'de' MMM 'de' y},
				d => q{d – d 'de' MMM 'de' y},
				y => q{d 'de' MMM 'de' y – d 'de' MMM 'de' y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
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
		regionFormat => q(Horário {0}),
		regionFormat => q(Horário de Verão: {0}),
		regionFormat => q(Horário Padrão: {0}),
		fallbackFormat => q({1} ({0})),
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
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
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
			exemplarCity => q#Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conacri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
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
			exemplarCity => q#Joanesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Cartum#,
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
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
			exemplarCity => q#Antígua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
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
			exemplarCity => q#Tucumã#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Assunção#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
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
			exemplarCity => q#Caiena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
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
			exemplarCity => q#Grand Turk#,
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
			exemplarCity => q#Guaiaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guiana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
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
			exemplarCity => q#Los Angeles#,
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
			exemplarCity => q#Manágua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
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
			exemplarCity => q#Mazatlan#,
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
			exemplarCity => q#Cidade do México#,
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
			exemplarCity => q#Montevidéu#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
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
			exemplarCity => q#Porto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rico#,
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
			exemplarCity => q#Santarém#,
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
			exemplarCity => q#Showa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
			exemplarCity => q#Adem#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amã#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asgabate#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdá#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
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
			exemplarCity => q#Beirute#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
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
			exemplarCity => q#Dacca#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duchambe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrom#,
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
			exemplarCity => q#Jacarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalém#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Carachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Catmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lampur#,
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
			exemplarCity => q#Macáçar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicósia#,
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
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riade#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
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
			exemplarCity => q#Cingapura#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teerã#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tóquio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ecaterimburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
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
			exemplarCity => q#Ilhas Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reiquiavique#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geórgia do Sul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
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
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Horário Padrão da Irlanda#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
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
			exemplarCity => q#Kirov#,
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
			exemplarCity => q#Mônaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscou#,
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
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sófia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsóvia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
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
				'standard' => q#Horário da Antártida e do Sul da França#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comores#,
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
			exemplarCity => q#Maurício#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
				'standard' => q#Horário das Ilhas Line#,
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
				'standard' => q#Horário da Ilha Norfolk#,
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
		'Pacific/Apia' => {
			exemplarCity => q#Ápia#,
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
			exemplarCity => q#Ilha de Páscoa#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
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
			exemplarCity => q#Nouméa#,
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
			exemplarCity => q#Taiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Taraua#,
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
				'standard' => q#Horário de Papua Nova Guiné#,
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
				'daylight' => q#Horário de Verão de Saint Pierre e Miquelon#,
				'generic' => q#Horário de Saint Pierre e Miquelon#,
				'standard' => q#Horário Padrão de Saint Pierre e Miquelon#,
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
				'standard' => q#Horário Padrão de Cingapura#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
