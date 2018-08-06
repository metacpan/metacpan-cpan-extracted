=head1

Locale::CLDR::Locales::Pt::Any::Pt - Package for language Portuguese

=cut

package Locale::CLDR::Locales::Pt::Any::Pt;
# This file auto generated from Data\common\main\pt_PT.xml
#	on Sun  5 Aug  6:18:35 pm GMT

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

extends('Locale::CLDR::Locales::Pt::Any');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
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
					rule => q(um bilião[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← biliões[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(um trilião[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← triliões[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(um quatrilião[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← quatriliões[ e →→]),
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
					rule => q(dezasseis),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dezassete),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(dezoito),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dezanove),
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
					rule => q(um bilião[ e →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← biliões[ e →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(um trilião[ e →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← triliões[ e →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(um quatrilião[ e →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← quatriliões[ e →→]),
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

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'af' => 'africanês',
 				'ang' => 'inglês antigo',
 				'ar_001' => 'árabe moderno padrão',
 				'arn' => 'mapuche',
 				'ars' => 'árabe do Négede',
 				'av' => 'avaric',
 				'bax' => 'bamun',
 				'bbj' => 'ghomala',
 				'bua' => 'buriat',
 				'chk' => 'chuquês',
 				'chn' => 'jargão chinook',
 				'chy' => 'cheyenne',
 				'ckb' => 'sorani curdo',
 				'co' => 'córsico',
 				'crs' => 'francês crioulo seselwa',
 				'cs' => 'checo',
 				'cv' => 'chuvash',
 				'de_AT' => 'alemão austríaco',
 				'de_CH' => 'alto alemão suíço',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'egípcio clássico',
 				'en_AU' => 'inglês australiano',
 				'en_CA' => 'inglês canadiano',
 				'en_GB' => 'inglês britânico',
 				'en_GB@alt=short' => 'inglês (RU)',
 				'en_US' => 'inglês americano',
 				'es_419' => 'espanhol latino-americano',
 				'es_ES' => 'espanhol europeu',
 				'es_MX' => 'espanhol mexicano',
 				'et' => 'estónio',
 				'fon' => 'fon',
 				'fr_CA' => 'francês canadiano',
 				'fr_CH' => 'francês suíço',
 				'fro' => 'francês antigo',
 				'frs' => 'frísio oriental',
 				'fy' => 'frísico ocidental',
 				'gez' => 'geʼez',
 				'goh' => 'alemão alto antigo',
 				'grc' => 'grego clássico',
 				'gsw' => 'alemão suíço',
 				'ha' => 'haúça',
 				'hi' => 'hindi',
 				'hy' => 'arménio',
 				'kbd' => 'cabardiano',
 				'kea' => 'crioulo cabo-verdiano',
 				'krc' => 'carachaio-bálcaro',
 				'lez' => 'lezghiano',
 				'lg' => 'ganda',
 				'lou' => 'crioulo de Louisiana',
 				'lrc' => 'luri do norte',
 				'luo' => 'luo',
 				'mak' => 'makassarês',
 				'mk' => 'macedónio',
 				'moh' => 'mohawk',
 				'mr' => 'marata',
 				'mul' => 'vários idiomas',
 				'nb' => 'norueguês bokmål',
 				'nds' => 'baixo-alemão',
 				'nds_NL' => 'baixo-saxão',
 				'ne' => 'nepali',
 				'nn' => 'norueguês nynorsk',
 				'non' => 'nórdico antigo',
 				'oc' => 'occitano',
 				'or' => 'oriya',
 				'os' => 'ossético',
 				'pag' => 'língua pangasinesa',
 				'pam' => 'pampango',
 				'peo' => 'persa antigo',
 				'pl' => 'polaco',
 				'pon' => 'língua pohnpeica',
 				'pro' => 'provençal antigo',
 				'ps' => 'pastó',
 				'pt_BR' => 'português do Brasil',
 				'pt_PT' => 'português europeu',
 				'raj' => 'rajastanês',
 				'root' => 'root',
 				'se' => 'sami do norte',
 				'sga' => 'irlandês antigo',
 				'shu' => 'árabe do Chade',
 				'smn' => 'inari sami',
 				'sn' => 'shona',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'tg' => 'tajique',
 				'tk' => 'turcomano',
 				'to' => 'tonga',
 				'tt' => 'tatar',
 				'tzm' => 'tamazight do Atlas Central',
 				'uz' => 'usbeque',
 				'vai' => 'vai',
 				'wo' => 'uólofe',
 				'xh' => 'xosa',
 				'xog' => 'soga',
 				'yo' => 'ioruba',
 				'zgh' => 'tamazight marroquino padrão',
 				'zun' => 'zuni',
 				'zza' => 'zaza',

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
			'Armi' => 'aramaico imperial',
 			'Armn' => 'arménio',
 			'Cakm' => 'chakma',
 			'Egyd' => 'egípcio demótico',
 			'Egyh' => 'egípcio hierático',
 			'Hanb' => 'han com bopomofo',
 			'Inds' => 'indus',
 			'Kthi' => 'kaithi',
 			'Mand' => 'mandeu',
 			'Orya' => 'odia',
 			'Phli' => 'pahlavi escrito',
 			'Prti' => 'parthian escrito',
 			'Sgnw' => 'escrita gestual',
 			'Sylo' => 'siloti nagri',
 			'Tale' => 'tai le',
 			'Telu' => 'telugu',
 			'Zsye' => 'emoji',
 			'Zsym' => 'símbolos',
 			'Zxxx' => 'não escrito',

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
			'009' => 'Oceânia',
 			'015' => 'Norte de África',
 			'018' => 'África Austral',
 			'029' => 'Caraíbas',
 			'034' => 'Ásia do Sul',
 			'039' => 'Europa do Sul',
 			'154' => 'Europa do Norte',
 			'202' => 'África subsariana',
 			'AI' => 'Anguila',
 			'AM' => 'Arménia',
 			'AX' => 'Alanda',
 			'BD' => 'Bangladeche',
 			'BH' => 'Barém',
 			'BJ' => 'Benim',
 			'BS' => 'Baamas',
 			'CC' => 'Ilhas dos Cocos (Keeling)',
 			'CD' => 'Congo-Kinshasa',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'República do Congo',
 			'CI' => 'Côte d’Ivoire (Costa do Marfim)',
 			'CI@alt=variant' => 'Costa do Marfim',
 			'CW' => 'Curaçau',
 			'CX' => 'Ilha do Natal',
 			'CZ' => 'Chéquia',
 			'CZ@alt=variant' => 'República Checa',
 			'DJ' => 'Jibuti',
 			'DM' => 'Domínica',
 			'EE' => 'Estónia',
 			'EH' => 'Sara Ocidental',
 			'EZ' => 'Zona Euro',
 			'FK' => 'Ilhas Falkland',
 			'FK@alt=variant' => 'Ilhas Malvinas',
 			'FO' => 'Ilhas Faroé',
 			'GB@alt=short' => 'GB',
 			'GG' => 'Guernesey',
 			'GL' => 'Gronelândia',
 			'GU' => 'Guame',
 			'IR' => 'Irão',
 			'KE' => 'Quénia',
 			'KI' => 'Quiribáti',
 			'KN' => 'São Cristóvão e Neves',
 			'KW' => 'Koweit',
 			'KY' => 'Ilhas Caimão',
 			'LI' => 'Listenstaine',
 			'LK' => 'Sri Lanca',
 			'LV' => 'Letónia',
 			'MC' => 'Mónaco',
 			'MG' => 'Madagáscar',
 			'MK' => 'Macedónia',
 			'MK@alt=variant' => 'Macedónia (ARJM)',
 			'MS' => 'Monserrate',
 			'MU' => 'Maurícia',
 			'MW' => 'Maláui',
 			'NC' => 'Nova Caledónia',
 			'NL' => 'Países Baixos',
 			'NU' => 'Niuê',
 			'PL' => 'Polónia',
 			'PS' => 'Territórios palestinianos',
 			'QO' => 'Oceânia Insular',
 			'RO' => 'Roménia',
 			'SI' => 'Eslovénia',
 			'SM' => 'São Marinho',
 			'SV' => 'Salvador',
 			'SX' => 'São Martinho (Sint Maarten)',
 			'TC' => 'Ilhas Turcas e Caicos',
 			'TJ' => 'Tajiquistão',
 			'TK' => 'Toquelau',
 			'TM' => 'Turquemenistão',
 			'TT' => 'Trindade e Tobago',
 			'UM' => 'Ilhas Menores Afastadas dos EUA',
 			'UZ' => 'Usbequistão',
 			'VI' => 'Ilhas Virgens dos EUA',
 			'VN' => 'Vietname',
 			'YE' => 'Iémen',
 			'YT' => 'Maiote',
 			'ZW' => 'Zimbabué',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1959ACAD' => 'académica',
 			'AREVELA' => 'arménio oriental',
 			'AREVMDA' => 'arménio ocidental',
 			'MONOTON' => 'monotónico',
 			'POLYTON' => 'politónico',
 			'REVISED' => 'ortografia modificada',
 			'UCRCOR' => 'ortografia modificada unificada',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'cf' => 'Formato monetário',
 			'colbackwards' => 'Ordenação de acentos invertida',
 			'colcaselevel' => 'Ordenação sensível a maiúsculas e minúsculas',
 			'colnormalization' => 'Ordenação normalizada',
 			'colnumeric' => 'Ordenação numérica',
 			'colstrength' => 'Força da ordenação',
 			'hc' => 'Ciclo horário (12 vs. 24)',
 			'ms' => 'Sistema de medida',
 			'x' => 'Utilização privada',

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
 				'buddhist' => q{Calendário budista},
 				'chinese' => q{Calendário chinês},
 				'coptic' => q{Calendário copta},
 				'dangi' => q{Calendário dangi},
 				'ethiopic' => q{Calendário etíope},
 				'ethiopic-amete-alem' => q{Calendário Etíope Amete Alem},
 				'gregorian' => q{Calendário gregoriano},
 				'hebrew' => q{Calendário hebraico},
 				'indian' => q{Calendário nacional indiano},
 				'islamic' => q{Calendário islâmico},
 				'islamic-civil' => q{Calendário islâmico (civil)},
 				'islamic-umalqura' => q{Calendário islâmico (Umm al-Qura)},
 				'japanese' => q{Calendário japonês},
 				'persian' => q{Calendário persa},
 			},
 			'cf' => {
 				'account' => q{Formato monetário contabilístico},
 				'standard' => q{Formato monetário padrão},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordenar símbolos},
 				'shifted' => q{Ordenar símbolos ignorados},
 			},
 			'colbackwards' => {
 				'no' => q{Ordenar acentos normalmente},
 				'yes' => q{Ordenar acentos inversamente},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ordenar por minúsculas},
 				'no' => q{Ordenar disposição de tipo de letra normal},
 				'upper' => q{Ordenar por maiúsculas},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordenar insensível a maiúsculas/minúsculas},
 				'yes' => q{Ordenar sensível a maiúsculas/minúsculas},
 			},
 			'collation' => {
 				'dictionary' => q{Ordenação do dicionário},
 				'ducet' => q{Ordenação unicode predefinida},
 				'eor' => q{Regras de ordenação europeias},
 				'phonebook' => q{Ordem da lista telefónica},
 				'phonetic' => q{Sequência de ordenação fonética},
 				'reformed' => q{Reforma da ordenação},
 				'standard' => q{Ordenação padrão},
 				'stroke' => q{Ordem por traços},
 				'traditional' => q{Ordem tradicional},
 				'unihan' => q{Ordem por radical e traços},
 			},
 			'colnormalization' => {
 				'no' => q{Ordenar sem normalização},
 				'yes' => q{Ordenar Unicode normalizado},
 			},
 			'colnumeric' => {
 				'no' => q{Ordenar dígitos individualmente},
 				'yes' => q{Ordenar dígitos numericamente},
 			},
 			'colstrength' => {
 				'identical' => q{Ordenar tudo},
 				'primary' => q{Ordenar apenas letras básicas},
 				'quaternary' => q{Ordenar acentos/tipo de letra/largura/kana},
 				'secondary' => q{Ordenar acentos},
 				'tertiary' => q{Ordenar acentos/tipo de letra/largura},
 			},
 			'd0' => {
 				'fwidth' => q{Largura completa},
 				'hwidth' => q{Meia largura},
 			},
 			'lb' => {
 				'loose' => q{Estilo flexível de quebra de linha},
 				'normal' => q{Estilo padrão de quebra de linha},
 				'strict' => q{Estilo estrito de quebra de linha},
 			},
 			'm0' => {
 				'bgn' => q{Transliteração BGN},
 				'ungegn' => q{Transliteração UNGEGN},
 			},
 			'ms' => {
 				'uksystem' => q{Sistema de medida imperial},
 				'ussystem' => q{Sistema de medida americano},
 			},
 			'numbers' => {
 				'arabext' => q{Algarismos indo-arábicos expandidos},
 				'armn' => q{Numeração arménia},
 				'armnlow' => q{Numeração arménia minúscula},
 				'beng' => q{Algarismos bengalis},
 				'deva' => q{Algarismos devanágaris},
 				'ethi' => q{Numeração etíope},
 				'finance' => q{Algarismos financeiros},
 				'fullwide' => q{Algarismos de largura completa},
 				'geor' => q{Numeração georgiana},
 				'grek' => q{Numeração grega},
 				'greklow' => q{Numeração grega minúscula},
 				'gujr' => q{Algarismos de guzerate},
 				'guru' => q{Algarismos de gurmukhi},
 				'hanidec' => q{Numeração decimal chinesa},
 				'hans' => q{Numeração em chinês simplificado},
 				'hansfin' => q{Numeração financeira em chinês simplificado},
 				'hant' => q{Numeração em chinês tradicional},
 				'hantfin' => q{Numeração financeira em chinês tradicional},
 				'hebr' => q{Numeração hebraica},
 				'jpan' => q{Numeração japonesa},
 				'jpanfin' => q{Numeração financeira japonesa},
 				'khmr' => q{Algarismos de cmer},
 				'knda' => q{Algarismos de canarim},
 				'mlym' => q{Algarismos de malaiala},
 				'mymr' => q{Algarismos birmaneses},
 				'orya' => q{Algarismos de odia},
 				'roman' => q{Numeração romana},
 				'romanlow' => q{Numeração romana minúscula},
 				'taml' => q{Numeração tâmil},
 				'tamldec' => q{Algarismos de tâmil},
 				'telu' => q{Algarismos de telugu},
 				'traditional' => q{Algarismos tradicionais},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'script' => 'Escrita: {0}',

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
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' " “ ” « » ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'medial' => '{0}…{1}',
		};
	},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					'century' => {
						'one' => q({0} século),
						'other' => q({0} séculos),
					},
					'coordinate' => {
						'east' => q({0} este),
						'north' => q({0} norte),
						'south' => q({0} sul),
						'west' => q({0} Oeste),
					},
					'cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					'cup' => {
						'name' => q(chávenas),
						'one' => q({0} chávena),
						'other' => q({0} chávenas),
					},
					'cup-metric' => {
						'name' => q(chávenas métricas),
						'one' => q({0} chávena métrica),
						'other' => q({0} chávenas métricas),
					},
					'foodcalorie' => {
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					'g-force' => {
						'name' => q(força G),
						'one' => q({0} força G),
						'other' => q({0} força G),
					},
					'generic' => {
						'other' => q({0}°),
					},
					'hour' => {
						'per' => q({0}/h),
					},
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					'kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
					},
					'kilometer-per-hour' => {
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					'liter-per-100kilometers' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					'liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					'meter-per-second-squared' => {
						'name' => q(metros por segundo quadrado),
						'one' => q({0} metro por segundo quadrado),
						'other' => q({0} metros por segundo quadrado),
					},
					'micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetro),
						'other' => q({0} micrómetros),
					},
					'mile-scandinavian' => {
						'name' => q(milha escandinava),
					},
					'millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimole por litro),
						'other' => q({0} milimoles por litro),
					},
					'nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetro),
						'other' => q({0} nanómetros),
					},
					'picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					'second' => {
						'per' => q({0}/s),
					},
					'square-kilometer' => {
						'name' => q(quilómetros quadrados),
						'one' => q({0} quilómetro quadrado),
						'other' => q({0} quilómetros quadrados),
						'per' => q({0} por quilómetro quadrado),
					},
				},
				'narrow' => {
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'day' => {
						'per' => q({0}/d),
					},
					'foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'liter-per-100kilometers' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'second' => {
						'name' => q(s),
						'per' => q({0}/s),
					},
				},
				'short' => {
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'arc-minute' => {
						'name' => q(minutos de arco),
					},
					'arc-second' => {
						'name' => q(segundos de arco),
					},
					'carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(graus Celsius),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					'cubic-foot' => {
						'name' => q(ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
					},
					'cup' => {
						'name' => q(chávenas),
						'one' => q({0} cháv.),
						'other' => q({0} cháv.),
					},
					'cup-metric' => {
						'name' => q(chám),
						'one' => q({0} chám),
						'other' => q({0} chám),
					},
					'fahrenheit' => {
						'name' => q(graus Fahrenheit),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'g-force' => {
						'name' => q(força G),
					},
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					'inch' => {
						'name' => q(polegadas),
					},
					'inch-hg' => {
						'name' => q(in Hg),
					},
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					'meter-per-second' => {
						'name' => q(m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
					},
					'mile' => {
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					'mile-per-gallon' => {
						'name' => q(milhas/galão),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milhas/gal imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'other' => q({0} smi),
					},
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(milimole/litro),
					},
					'minute' => {
						'name' => q(minutos),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'parsec' => {
						'name' => q(pc),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-centimeter' => {
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(pés quadrados),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-meter' => {
						'name' => q(m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
					},
					'tablespoon' => {
						'name' => q(cs),
						'one' => q({0} cs),
						'other' => q({0} cs),
					},
					'ton' => {
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
				},
			} }
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
			'group' => q( ),
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
				'1000000' => {
					'one' => '0 milhão',
					'other' => '0 milhões',
				},
				'10000000' => {
					'one' => '00 milhões',
					'other' => '00 milhões',
				},
				'100000000' => {
					'one' => '000 milhões',
					'other' => '000 milhões',
				},
				'1000000000' => {
					'one' => '0 mil milhões',
					'other' => '0 mil milhões',
				},
				'10000000000' => {
					'one' => '00 mil milhões',
					'other' => '00 mil milhões',
				},
				'100000000000' => {
					'one' => '000 mil milhões',
					'other' => '000 mil milhões',
				},
				'1000000000000' => {
					'one' => '0 bilião',
					'other' => '0 biliões',
				},
				'10000000000000' => {
					'one' => '00 biliões',
					'other' => '00 biliões',
				},
				'100000000000000' => {
					'one' => '000 biliões',
					'other' => '000 biliões',
				},
			},
			'short' => {
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
					'one' => '0 mM',
					'other' => '0 mM',
				},
				'10000000000' => {
					'one' => '00 mM',
					'other' => '00 mM',
				},
				'100000000000' => {
					'one' => '000 mM',
					'other' => '000 mM',
				},
				'1000000000000' => {
					'one' => '0 Bi',
					'other' => '0 Bi',
				},
				'10000000000000' => {
					'one' => '00 Bi',
					'other' => '00 Bi',
				},
				'100000000000000' => {
					'one' => '000 Bi',
					'other' => '000 Bi',
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
						'negative' => '(#,##0.00 ¤)',
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
		'AED' => {
			display_name => {
				'currency' => q(Dirham dos Emirados Árabes Unidos),
				'one' => q(Dirham dos Emirados Árabes Unidos),
				'other' => q(Dirhams dos Emirados Árabes Unidos),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afeghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afegani do Afeganistão),
				'one' => q(Afegani do Afeganistão),
				'other' => q(Afeganis do Afeganistão),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanês),
				'one' => q(lek albanês),
				'other' => q(leks albaneses),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram arménio),
				'one' => q(Dram arménio),
				'other' => q(Drams arménios),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentino),
				'one' => q(peso argentino),
				'other' => q(pesos argentinos),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florim de Aruba),
				'one' => q(florim de Aruba),
				'other' => q(florins de Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat do Azerbaijão),
				'one' => q(Manat do Azerbaijão),
				'other' => q(Manats do Azerbaijão),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dinar da Bósnia-Herzegóvina),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marco bósnio-herzegóvino conversível),
				'one' => q(marco bósnio-herzegóvino conversível),
				'other' => q(marcos bósnio-herzegóvinos conversíveis),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dólar barbadense),
				'one' => q(dólar barbadense),
				'other' => q(dólares barbadenses),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka de Bangladesh),
				'one' => q(Taka de Bangladesh),
				'other' => q(Takas de Bangladesh),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Franco belga \(convertível\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev búlgaro),
				'one' => q(lev búlgaro),
				'other' => q(levs búlgaros),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar baremita),
				'one' => q(Dinar baremita),
				'other' => q(Dinares baremitas),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dólar bermudense),
				'one' => q(dólar bermudense),
				'other' => q(dólares bermudense),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dólar bruneíno),
				'one' => q(Dólar bruneíno),
				'other' => q(Dólares bruneínos),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano),
				'one' => q(boliviano),
				'other' => q(bolivianos),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(real brasileiro),
				'one' => q(real brasileiro),
				'other' => q(reais brasileiros),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dólar das Bahamas),
				'one' => q(dólar das Bahamas),
				'other' => q(dólares das Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum do Butão),
				'one' => q(Ngultrum do Butão),
				'other' => q(Ngultruns do Butão),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula de Botswana),
				'one' => q(Pula de Botswana),
				'other' => q(Pulas de Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Rublo novo bielorusso \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rublo bielorrusso),
				'one' => q(rublo bielorrusso),
				'other' => q(rublos bielorrussos),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dólar belizense),
				'one' => q(dólar belizense),
				'other' => q(dólares belizense),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dólar canadiano),
				'one' => q(dólar canadiano),
				'other' => q(dólares canadianos),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franco suíço),
				'one' => q(franco suíço),
				'other' => q(francos suíços),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso chileno),
				'one' => q(peso chileno),
				'other' => q(pesos chilenos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan offshore),
				'one' => q(yuan offshore),
				'other' => q(yuans offshore),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan),
				'one' => q(yuan),
				'other' => q(yuans),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombianos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colon costa-riquenho),
				'one' => q(colon costa-riquenho),
				'other' => q(colons costa-riquenho),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cubano conversível),
				'one' => q(peso cubano conversível),
				'other' => q(pesos cubanos conversíveis),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo cabo-verdiano),
				'one' => q(escudo cabo-verdiano),
				'other' => q(escudos cabo-verdianos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Libra de Chipre),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(coroa checa),
				'one' => q(coroa checa),
				'other' => q(coroas checas),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franco jibutiano),
				'one' => q(Franco jibutiano),
				'other' => q(Francos jibutianos),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(coroa dinamarquesa),
				'one' => q(coroa dinamarquesa),
				'other' => q(coroas dinamarquesas),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar argelino),
				'one' => q(dinar argelino),
				'other' => q(dinares argelinos),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Unidad de Valor Constante \(UVC\) do Equador),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(libra egípcia),
				'one' => q(libra egípcia),
				'other' => q(libras egípcias),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dólar de Fiji),
				'one' => q(Dólar de Fiji),
				'other' => q(Dólares de Fiji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(libra das Ilhas Falkland),
				'one' => q(libra das Ilhas Falkland),
				'other' => q(libras das Ilhas Falkland),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(libra esterlina britânica),
				'one' => q(libra esterlina britânica),
				'other' => q(libras esterlinas britânicas),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi do Gana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi de Gana),
				'one' => q(Cedi de Gana),
				'other' => q(Cedis de Gana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(libra de Gibraltar),
				'one' => q(libra de Gibraltar),
				'other' => q(libras de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi da Gâmbia),
				'one' => q(Dalasi da Gâmbia),
				'other' => q(Dalasis da Gâmbia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franco guineense),
				'one' => q(Franco guineense),
				'other' => q(Francos guineenses),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal da Guatemala),
				'one' => q(quetzal da Guatemala),
				'other' => q(quetzales da Guatemala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dólar da Guiana),
				'one' => q(dólar da Guiana),
				'other' => q(dólares da Guiana),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira das Honduras),
				'one' => q(lempira das Honduras),
				'other' => q(lempiras das Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunas croatas),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint húngaro),
				'one' => q(forint húngaro),
				'other' => q(forints húngaros),
			},
		},
		'ILS' => {
			display_name => {
				'one' => q(Sheqel novo israelita),
				'other' => q(Sheqels novos israelitas),
			},
		},
		'IRR' => {
			display_name => {
				'one' => q(Rial iraniano),
				'other' => q(Riais iranianos),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(coroa islandesa),
				'one' => q(coroa islandesa),
				'other' => q(coroas islandesas),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som do Quirguistão),
				'one' => q(Som do Quirguistão),
				'other' => q(Sons do Quirguistão),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dólar das Ilhas Caimão),
				'one' => q(Dólar das Ilhas Caimão),
				'other' => q(Dólares das Ilhas Caimão),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge do Cazaquistão),
				'one' => q(Tenge do Cazaquistão),
				'other' => q(Tenges do Cazaquistão),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip de Laos),
				'one' => q(Kip de Laos),
				'other' => q(Kips de Laos),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupia do Sri Lanka),
				'one' => q(Rupia do Sri Lanka),
				'other' => q(Rupias do Sri Lanka),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas da Lituânia),
				'one' => q(Litas da Lituânia),
				'other' => q(Litas da Lituânia),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats da Letónia),
				'one' => q(Lats da Letónia),
				'other' => q(Lats da Letónia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar líbio),
				'one' => q(dinar líbio),
				'other' => q(dinares líbios),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marroquino),
				'one' => q(dirham marroquino),
				'other' => q(dirhams marroquinos),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(leus moldavos),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariari de Madagáscar),
				'one' => q(Ariari de Madagáscar),
				'other' => q(Ariaris de Madagáscar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinar macedónio),
				'one' => q(dinar macedónio),
				'other' => q(dinares macedónios),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Franco do Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat de Mianmar),
				'one' => q(Kyat de Mianmar),
				'other' => q(Kyats de Mianmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik da Mongólia),
				'one' => q(Tugrik da Mongólia),
				'other' => q(Tugriks da Mongólia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca de Macau),
				'one' => q(Pataca de Macau),
				'other' => q(Patacas de Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya da Mauritânia \(1973–2017\)),
				'one' => q(Ouguiya da Mauritânia \(1973–2017\)),
				'other' => q(Ouguiyas da Mauritânia \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya da Mauritânia),
				'one' => q(Ouguiya da Mauritânia),
				'other' => q(Ouguiyas da Mauritânia),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rupia das Ilhas Maldivas),
				'one' => q(Rupia das Ilhas Maldivas),
				'other' => q(Rupias das Ilhas Maldivas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha do Malawi),
				'one' => q(Kwacha do Malawi),
				'other' => q(Kwachas do Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso mexicano),
				'one' => q(peso mexicano),
				'other' => q(pesos mexicanos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso Plata mexicano \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Unidad de Inversion \(UDI\) mexicana),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical de Moçambique),
				'one' => q(Metical de Moçambique),
				'other' => q(Meticales de Moçambique),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dólar da Namíbia),
				'one' => q(Dólar da Namíbia),
				'other' => q(Dólares da Namíbia),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba nicaraguano \(1988–1991\)),
				'one' => q(Córdoba nicaraguano \(1988–1991\)),
				'other' => q(Córdobas nicaraguano \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaraguano),
				'one' => q(córdoba nicaraguano),
				'other' => q(córdobas nicaraguanos),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(coroa norueguesa),
				'one' => q(coroa norueguesa),
				'other' => q(coroas norueguesas),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial de Omã),
				'one' => q(Rial de Omã),
				'other' => q(Riais de Omã),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa do Panamá),
				'one' => q(balboa do Panamá),
				'other' => q(balboas do Panamá),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruano),
				'one' => q(sol peruano),
				'other' => q(sóis peruanos),
			},
		},
		'PES' => {
			display_name => {
				'one' => q(Sol peruano \(1863–1965\)),
				'other' => q(Soles peruanos \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina da Papua-Nova Guiné),
				'one' => q(Kina da Papua-Nova Guiné),
				'other' => q(Kinas da Papua-Nova Guiné),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloti polaco),
				'one' => q(zloti polaco),
				'other' => q(zlotis polacos),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloti polaco \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => '​',
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani paraguaio),
				'one' => q(guarani paraguaio),
				'other' => q(guaranis paraguaios),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial do Catar),
				'one' => q(Rial do Catar),
				'other' => q(Riais do Catar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu romeno),
				'one' => q(leu romeno),
				'other' => q(leus romenos),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar sérvio),
				'one' => q(dinar sérvio),
				'other' => q(dinares sérvios),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublo russo),
				'one' => q(rublo russo),
				'other' => q(rublos russos),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rial saudita),
				'one' => q(Rial saudita),
				'other' => q(Riais sauditas),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(libra sudanesa),
				'one' => q(libra sudanesa),
				'other' => q(libras sudanesas),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(coroa sueca),
				'one' => q(coroa sueca),
				'other' => q(coroas suecas),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dólar de Singapura),
				'one' => q(Dólar de Singapura),
				'other' => q(Dólares de Singapura),
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
				'currency' => q(dólar do Suriname),
				'one' => q(dólar do Suriname),
				'other' => q(dólares do Suriname),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São Tomé & Príncipe Dobra \(2018\)),
				'one' => q(São Tomé & Príncipe dobra \(2018\)),
				'other' => q(São Tomé & Príncipe dobras \(2018\)),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni da Suazilândia),
				'one' => q(Lilangeni da Suazilândia),
				'other' => q(Lilangenis da Suazilândia),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht da Tailândia),
				'one' => q(Baht da Tailândia),
				'other' => q(Bahts da Tailândia),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni do Tajaquistão),
				'one' => q(Somoni do Tajaquistão),
				'other' => q(Somonis do Tajaquistão),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat do Turquemenistão),
				'one' => q(Manat do Turquemenistão),
				'other' => q(Manats do Turquemenistão),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisino),
				'one' => q(dinar tunisino),
				'other' => q(dinares tunisinos),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga de Tonga),
				'one' => q(Paʻanga de Tonga),
				'other' => q(Paʻangas de Tonga),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dólar de Trindade e Tobago),
				'one' => q(Dólar de Trindade e Tobago),
				'other' => q(Dólares de Trindade e Tobago),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ucraniano),
				'one' => q(hryvnia ucraniano),
				'other' => q(hryvnias ucranianos),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dólar dos Estados Unidos),
				'one' => q(dólar dos Estados Unidos),
				'other' => q(dólares dos Estados Unidos),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguaio),
				'one' => q(peso uruguaio),
				'other' => q(pesos uruguaios),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som do Uzbequistão),
				'one' => q(Som do Uzbequistão),
				'other' => q(Sons do Uzbequistão),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolívar),
				'one' => q(bolívar),
				'other' => q(bolívares),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu de Vanuatu),
				'one' => q(Vatu de Vanuatu),
				'other' => q(Vatus de Vanuatu),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franco CFA \(BEAC\)),
				'one' => q(Franco CFA \(BEAC\)),
				'other' => q(Francos CFA \(BEAC\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dólar das Caraíbas Orientais),
				'one' => q(Dólar das Caraíbas Orientais),
				'other' => q(Dólares das Caraíbas Orientais),
			},
		},
		'XDR' => {
			display_name => {
				'one' => q(direito especial de saque),
				'other' => q(direitos especiais de saque),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Unidade da Moeda Europeia),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA \(BCEAO\)),
				'one' => q(franco CFA \(BCEAO\)),
				'other' => q(francos CFA \(BCEAO\)),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moeda desconhecida),
			},
		},
		'YER' => {
			display_name => {
				'one' => q(Rial iemenita),
				'other' => q(Riais iemenitas),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Dinar forte jugoslavo),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Super Dinar jugoslavo),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinar conversível jugoslavo),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha zambiano \(1968–2012\)),
				'one' => q(Kwacha zambiano \(1968–2012\)),
				'other' => q(Kwachas zambianos \(1968–2012\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dólar do Zimbabwe),
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
							'M1',
							'M2',
							'M3',
							'M4',
							'M5',
							'M6',
							'M7',
							'M8',
							'M9',
							'M10',
							'M11',
							'M12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'M1',
							'M2',
							'M3',
							'M4',
							'M5',
							'M6',
							'M7',
							'M8',
							'M9',
							'M10',
							'M11',
							'M12'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'',
							'Nisan',
							'',
							'Sivan'
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
						mon => 'segunda',
						tue => 'terça',
						wed => 'quarta',
						thu => 'quinta',
						fri => 'sexta',
						sat => 'sábado',
						sun => 'domingo'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'segunda',
						tue => 'terça',
						wed => 'quarta',
						thu => 'quinta',
						fri => 'sexta',
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
					wide => {0 => '1.º trimestre',
						1 => '2.º trimestre',
						2 => '3.º trimestre',
						3 => '4.º trimestre'
					},
				},
				'stand-alone' => {
					wide => {0 => '1.º trimestre',
						1 => '2.º trimestre',
						2 => '3.º trimestre',
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
				'narrow' => {
					'evening1' => q{noite},
					'morning1' => q{manhã},
					'afternoon1' => q{tarde},
					'am' => q{a.m.},
					'noon' => q{meio-dia},
					'midnight' => q{meia-noite},
					'pm' => q{p.m.},
					'night1' => q{madrugada},
				},
				'wide' => {
					'afternoon1' => q{da tarde},
					'evening1' => q{da noite},
					'morning1' => q{da manhã},
					'pm' => q{da tarde},
					'am' => q{da manhã},
					'noon' => q{meio-dia},
				},
				'abbreviated' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
					'noon' => q{meio-dia},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{manhã},
					'pm' => q{tarde},
				},
				'narrow' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
				},
				'abbreviated' => {
					'pm' => q{p.m.},
					'am' => q{a.m.},
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
				'0' => 'BE'
			},
			wide => {
				'0' => 'BE'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
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

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'short' => q{d/M/y G},
		},
		'chinese' => {
			'medium' => q{d 'de' MMM 'de' U},
		},
		'generic' => {
			'short' => q{d/M/y G},
		},
		'gregorian' => {
			'medium' => q{dd/MM/y},
			'short' => q{dd/MM/yy},
		},
		'hebrew' => {
			'short' => q{d/M/y G},
		},
		'islamic' => {
			'short' => q{d/M/y G},
		},
		'japanese' => {
			'short' => q{d/M/y G},
		},
		'roc' => {
			'short' => q{d/M/y G},
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
		},
		'generic' => {
			'full' => q{{1} 'às' {0}},
			'long' => q{{1} 'às' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'às' {0}},
			'long' => q{{1} 'às' {0}},
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
		'generic' => {
			yyyyMMM => q{MM/y G},
			yyyyMMMEEEEd => q{EEEE, d/MM/y},
			yyyyMMMEd => q{E, d/MM/y G},
			yyyyMMMd => q{d/MM/y G},
			yyyyQQQ => q{QQQQ 'de' y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
		},
		'gregorian' => {
			MMMEd => q{E, d/MM},
			MMMMEd => q{ccc, d 'de' MMMM},
			MMMMW => q{W.'ª' 'semana' 'de' MMM},
			MMMd => q{d/MM},
			Md => q{dd/MM},
			yMMM => q{MM/y},
			yMMMEEEEd => q{EEEE, d/MM/y},
			yMMMEd => q{E, d/MM/y},
			yMMMMEd => q{ccc, d 'de' MMMM 'de' y},
			yMMMd => q{d/MM/y},
			yQQQ => q{QQQQ 'de' y},
			yw => q{w.'ª' 'semana' 'de' Y},
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
			M => {
				M => q{MM–MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				d => q{ccc, dd/MM – ccc, dd/MM},
			},
			MMMMEd => {
				M => q{ccc, d 'de' MMMM – ccc, d 'de' MMMM},
				d => q{ccc, d 'de' MMMM – ccc, d 'de' MMMM},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				h => q{h:mm – h:mm a},
			},
			y => {
				y => q{y–y G},
			},
			yMMMEd => {
				d => q{E, dd/MM – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM 'de' y G},
			},
			yMMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y G},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y G},
				y => q{E, d 'de' MMMM 'de' y – E, d 'de' MMMM 'de' y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{ccc, dd/MM – ccc, dd/MM},
				d => q{ccc, dd/MM – ccc, dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{ccc, dd/MM – ccc, dd/MM},
				d => q{ccc, dd/MM – ccc, dd/MM},
			},
			MMMMEd => {
				M => q{ccc, d 'de' MMMM – ccc, d 'de' MMMM},
				d => q{ccc, d 'de' MMMM – ccc, d 'de' MMMM},
			},
			MMMd => {
				d => q{d–d 'de' MMM},
			},
			d => {
				d => q{d–d},
			},
			h => {
				h => q{h–h a},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yMEd => {
				M => q{ccc, dd/MM/y – ccc, dd/MM/y},
				d => q{ccc, dd/MM/y – ccc, dd/MM/y},
				y => q{ccc, dd/MM/y – ccc, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM 'de' y},
			},
			yMMMEd => {
				d => q{E, dd/MM – E, dd/MM/y},
			},
			yMMMMEd => {
				M => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM 'de' y},
				y => q{E, d 'de' MMMM 'de' y – E, d 'de' MMMM 'de' y},
			},
			yMMMd => {
				d => q{d–d 'de' MMM 'de' y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Hora de {0}),
		regionFormat => q(Hora padrão de {0}),
		regionFormat => q(Hora padrão de {0}),
		'Acre' => {
			long => {
				'daylight' => q#Hora de verão do Acre#,
				'generic' => q#Hora do Acre#,
				'standard' => q#Hora padrão do Acre#,
			},
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Hora do Afeganistão#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis-Abeba#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamaco#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dacar#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuti#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Campala#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaca#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ndjamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamei#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunes#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Hora da África Central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Hora da África Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Hora da África do Sul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Hora de verão da África Ocidental#,
				'generic' => q#Hora da África Ocidental#,
				'standard' => q#Hora padrão da África Ocidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Hora de verão do Alasca#,
				'generic' => q#Hora do Alasca#,
				'standard' => q#Hora padrão do Alasca#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Hora de verão de Almaty#,
				'generic' => q#Hora de Almaty#,
				'standard' => q#Hora padrão de Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Hora de verão do Amazonas#,
				'generic' => q#Hora do Amazonas#,
				'standard' => q#Hora padrão do Amazonas#,
			},
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caimão#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçau#,
		},
		'America/Dominica' => {
			exemplarCity => q#Domínica#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideu#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monserrate#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova Iorque#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Porto de Espanha#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Hora de verão Central#,
				'generic' => q#Hora Central#,
				'standard' => q#Hora padrão Central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora de verão Oriental#,
				'generic' => q#Hora Oriental#,
				'standard' => q#Hora padrão Oriental#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora de verão da Montanha#,
				'generic' => q#Hora de Montanha#,
				'standard' => q#Hora padrão da Montanha#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora de verão do Pacífico#,
				'generic' => q#Hora do Pacífico#,
				'standard' => q#Hora padrão do Pacífico#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Hora de verão de Anadyr#,
				'generic' => q#Hora de Anadyr#,
				'standard' => q#Hora padrão de Anadyr#,
			},
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Hora de verão de Apia#,
				'generic' => q#Hora de Apia#,
				'standard' => q#Hora padrão de Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Hora de verão de Aqtau#,
				'generic' => q#Hora de Aqtau#,
				'standard' => q#Hora padrão de Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Hora de verão de Aqtobe#,
				'generic' => q#Hora de Aqtobe#,
				'standard' => q#Hora padrão de Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Hora de verão da Arábia#,
				'generic' => q#Hora da Arábia#,
				'standard' => q#Hora padrão da Arábia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Hora de verão da Argentina#,
				'generic' => q#Hora da Argentina#,
				'standard' => q#Hora padrão da Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Hora de verão da Argentina Ocidental#,
				'generic' => q#Hora da Argentina Ocidental#,
				'standard' => q#Hora padrão da Argentina Ocidental#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Hora de verão da Arménia#,
				'generic' => q#Hora da Arménia#,
				'standard' => q#Hora padrão da Arménia#,
			},
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdade#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barém#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Banguecoque#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutá#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daca#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Cabul#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweit#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macassar#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Cidade de Ho Chi Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapura#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipé#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teerão#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Hora de verão do Atlântico#,
				'generic' => q#Hora do Atlântico#,
				'standard' => q#Hora padrão do Atlântico#,
			},
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroé#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Ilha de Lord Howe#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Hora de verão da Austrália Central#,
				'generic' => q#Hora da Austrália Central#,
				'standard' => q#Hora padrão da Austrália Central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Hora de verão da Austrália Central Ocidental#,
				'generic' => q#Hora da Austrália Central Ocidental#,
				'standard' => q#Hora padrão da Austrália Central Ocidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Hora de verão da Austrália Oriental#,
				'generic' => q#Hora da Austrália Oriental#,
				'standard' => q#Hora padrão da Austrália Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Hora de verão da Austrália Ocidental#,
				'generic' => q#Hora da Austrália Ocidental#,
				'standard' => q#Hora padrão da Austrália Ocidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Hora de verão do Azerbaijão#,
				'generic' => q#Hora do Azerbaijão#,
				'standard' => q#Hora padrão do Azerbaijão#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Hora de verão dos Açores#,
				'generic' => q#Hora dos Açores#,
				'standard' => q#Hora padrão dos Açores#,
			},
			short => {
				'daylight' => q#AZOST#,
				'generic' => q#AZOT#,
				'standard' => q#AZOT#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Hora de verão do Bangladesh#,
				'generic' => q#Hora do Bangladesh#,
				'standard' => q#Hora padrão do Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Hora do Butão#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Hora da Bolívia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Hora de verão de Brasília#,
				'generic' => q#Hora de Brasília#,
				'standard' => q#Hora padrão de Brasília#,
			},
			short => {
				'daylight' => q#∅∅∅#,
				'generic' => q#∅∅∅#,
				'standard' => q#∅∅∅#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Hora do Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Hora de verão de Cabo Verde#,
				'generic' => q#Hora de Cabo Verde#,
				'standard' => q#Hora padrão de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Hora padrão de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Hora de verão de Chatham#,
				'generic' => q#Hora de Chatham#,
				'standard' => q#Hora padrão de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Hora de verão do Chile#,
				'generic' => q#Hora do Chile#,
				'standard' => q#Hora padrão do Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hora de verão da China#,
				'generic' => q#Hora da China#,
				'standard' => q#Hora padrão da China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Hora de verão de Choibalsan#,
				'generic' => q#Hora de Choibalsan#,
				'standard' => q#Hora padrão de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Hora da Ilha do Natal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Hora das Ilhas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Hora de verão da Colômbia#,
				'generic' => q#Hora da Colômbia#,
				'standard' => q#Hora padrão da Colômbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hora de verão das Ilhas Cook#,
				'generic' => q#Hora das Ilhas Cook#,
				'standard' => q#Hora padrão das Ilhas Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Hora de verão de Cuba#,
				'generic' => q#Hora de Cuba#,
				'standard' => q#Hora padrão de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Hora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Hora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Hora de Timor Leste#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Hora de verão da Ilha da Páscoa#,
				'generic' => q#Hora da Ilha da Páscoa#,
				'standard' => q#Hora padrão da Ilha da Páscoa#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Hora do Equador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Hora Coordenada Universal#,
			},
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amesterdão#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhaga#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Hora de verão da Irlanda#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsínquia#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Caliningrado#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Hora de verão Britânica#,
			},
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mónaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscovo#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#São Marinho#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Hora de verão da Europa Central#,
				'generic' => q#Hora da Europa Central#,
				'standard' => q#Hora padrão da Europa Central#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Hora de verão da Europa Oriental#,
				'generic' => q#Hora da Europa Oriental#,
				'standard' => q#Hora padrão da Europa Oriental#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Hora do Extremo Leste da Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Hora de verão da Europa Ocidental#,
				'generic' => q#Hora da Europa Ocidental#,
				'standard' => q#Hora padrão da Europa Ocidental#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Hora de verão das Ilhas Falkland#,
				'generic' => q#Hora das Ilhas Falkland#,
				'standard' => q#Hora padrão das Ilhas Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Hora de verão de Fiji#,
				'generic' => q#Hora de Fiji#,
				'standard' => q#Hora padrão de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Hora da Guiana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Hora das Terras Austrais e Antárcticas Francesas#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Hora de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Hora das Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Hora de verão da Geórgia#,
				'generic' => q#Hora da Geórgia#,
				'standard' => q#Hora padrão da Geórgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Hora das Ilhas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Hora de verão da Gronelândia Oriental#,
				'generic' => q#Hora da Gronelândia Oriental#,
				'standard' => q#Hora padrão da Gronelândia Oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Hora de verão da Gronelândia Ocidental#,
				'generic' => q#Hora da Gronelândia Ocidental#,
				'standard' => q#Hora padrão da Gronelândia Ocidental#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Hora padrão de Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Hora padrão do Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Hora da Guiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hora de verão do Havai e Aleutas#,
				'generic' => q#Hora do Havai e Aleutas#,
				'standard' => q#Hora padrão do Havai e Aleutas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hora de verão de Hong Kong#,
				'generic' => q#Hora de Hong Kong#,
				'standard' => q#Hora padrão de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hora de verão de Hovd#,
				'generic' => q#Hora de Hovd#,
				'standard' => q#Hora padrão de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hora padrão da Índia#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Ilha do Natal#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Ilhas Cocos#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurícia#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hora do Oceano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hora da Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Hora da Indonésia Central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Hora da Indonésia Oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Hora da Indonésia Ocidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Hora de verão do Irão#,
				'generic' => q#Hora do Irão#,
				'standard' => q#Hora padrão do Irão#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Hora de verão de Irkutsk#,
				'generic' => q#Hora de Irkutsk#,
				'standard' => q#Hora padrão de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Hora de verão de Israel#,
				'generic' => q#Hora de Israel#,
				'standard' => q#Hora padrão de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Hora de verão do Japão#,
				'generic' => q#Hora do Japão#,
				'standard' => q#Hora padrão do Japão#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Hora de verão de Petropavlovsk-Kamchatski#,
				'generic' => q#Hora de Petropavlovsk-Kamchatski#,
				'standard' => q#Hora padrão de Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Hora do Cazaquistão Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Hora do Cazaquistão Ocidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Hora de verão da Coreia#,
				'generic' => q#Hora da Coreia#,
				'standard' => q#Hora padrão da Coreia#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Hora de verão de Krasnoyarsk#,
				'generic' => q#Hora de Krasnoyarsk#,
				'standard' => q#Hora padrão de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Hora do Quirguistão#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Hora do Sri Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Hora das Ilhas Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Hora de verão de Lord Howe#,
				'generic' => q#Hora de Lord Howe#,
				'standard' => q#Hora padrão de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Hora de verão de Macau#,
				'generic' => q#Hora de Macau#,
				'standard' => q#Hora padrão de Macau#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Hora da Ilha Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Hora de verão de Magadan#,
				'generic' => q#Hora de Magadan#,
				'standard' => q#Hora padrão de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Hora da Malásia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Hora das Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Hora das Ilhas Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Hora das Ilhas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Hora de verão da Maurícia#,
				'generic' => q#Hora da Maurícia#,
				'standard' => q#Hora padrão da Maurícia#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Hora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Hora de verão do Noroeste do México#,
				'generic' => q#Hora do Noroeste do México#,
				'standard' => q#Hora padrão do Noroeste do México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Hora de verão do Pacífico Mexicano#,
				'generic' => q#Hora do Pacífico Mexicano#,
				'standard' => q#Hora padrão do Pacífico Mexicano#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Hora de verão de Ulan Bator#,
				'generic' => q#Hora de Ulan Bator#,
				'standard' => q#Hora padrão de Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Hora de verão de Moscovo#,
				'generic' => q#Hora de Moscovo#,
				'standard' => q#Hora padrão de Moscovo#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Hora de Mianmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Hora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Hora do Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Hora de verão da Nova Caledónia#,
				'generic' => q#Hora da Nova Caledónia#,
				'standard' => q#Hora padrão da Nova Caledónia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Hora de verão da Nova Zelândia#,
				'generic' => q#Hora da Nova Zelândia#,
				'standard' => q#Hora padrão da Nova Zelândia#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Hora de verão da Terra Nova#,
				'generic' => q#Hora da Terra Nova#,
				'standard' => q#Hora padrão da Terra Nova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Hora de Niuê#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Hora da Ilha Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Hora de verão de Fernando de Noronha#,
				'generic' => q#Hora de Fernando de Noronha#,
				'standard' => q#Hora padrão de Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Hora das Ilhas Mariana do Norte#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Hora de verão de Novosibirsk#,
				'generic' => q#Hora de Novosibirsk#,
				'standard' => q#Hora padrão de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Hora de verão de Omsk#,
				'generic' => q#Hora de Omsk#,
				'standard' => q#Hora padrão de Omsk#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ilha da Páscoa#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Ilhas Pitcairn#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Hora de verão do Paquistão#,
				'generic' => q#Hora do Paquistão#,
				'standard' => q#Hora padrão do Paquistão#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Hora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Hora de Papua Nova Guiné#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Hora de verão do Paraguai#,
				'generic' => q#Hora do Paraguai#,
				'standard' => q#Hora padrão do Paraguai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Hora de verão do Peru#,
				'generic' => q#Hora do Peru#,
				'standard' => q#Hora padrão do Peru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Hora de verão das Filipinas#,
				'generic' => q#Hora das Filipinas#,
				'standard' => q#Hora padrão das Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Hora das Ilhas Fénix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Hora de verão de São Pedro e Miquelão#,
				'generic' => q#Hora de São Pedro e Miquelão#,
				'standard' => q#Hora padrão de São Pedro e Miquelão#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Hora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Hora de Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Hora de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Hora de verão de Qyzylorda#,
				'generic' => q#Hora de Qyzylorda#,
				'standard' => q#Hora padrão de Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Hora de Reunião#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Hora de verão de Sacalina#,
				'generic' => q#Hora de Sacalina#,
				'standard' => q#Hora padrão de Sacalina#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Hora de verão de Samara#,
				'generic' => q#Hora de Samara#,
				'standard' => q#Hora padrão de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Hora de verão de Samoa#,
				'generic' => q#Hora de Samoa#,
				'standard' => q#Hora padrão de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Hora das Seicheles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Hora padrão de Singapura#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Hora das Ilhas Salomão#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hora da Geórgia do Sul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Hora do Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Hora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Hora do Taiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Hora de verão de Taipé#,
				'generic' => q#Hora de Taipé#,
				'standard' => q#Hora padrão de Taipé#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Hora do Tajiquistão#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Hora de verão de Tonga#,
				'generic' => q#Hora de Tonga#,
				'standard' => q#Hora padrão de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Hora de verão do Turquemenistão#,
				'generic' => q#Hora do Turquemenistão#,
				'standard' => q#Hora padrão do Turquemenistão#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Hora de verão do Uruguai#,
				'generic' => q#Hora do Uruguai#,
				'standard' => q#Hora padrão do Uruguai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Hora de verão do Uzbequistão#,
				'generic' => q#Hora do Uzbequistão#,
				'standard' => q#Hora padrão do Uzbequistão#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Hora de verão do Vanuatu#,
				'generic' => q#Hora do Vanuatu#,
				'standard' => q#Hora padrão do Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Hora da Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Hora de verão de Vladivostok#,
				'generic' => q#Hora de Vladivostok#,
				'standard' => q#Hora padrão de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Hora de verão de Volgogrado#,
				'generic' => q#Hora de Volgogrado#,
				'standard' => q#Hora padrão de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Hora da Ilha Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Hora de Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Hora de verão de Yakutsk#,
				'generic' => q#Hora de Yakutsk#,
				'standard' => q#Hora padrão de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Hora de verão de Ecaterimburgo#,
				'generic' => q#Hora de Ecaterimburgo#,
				'standard' => q#Hora padrão de Ecaterimburgo#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
