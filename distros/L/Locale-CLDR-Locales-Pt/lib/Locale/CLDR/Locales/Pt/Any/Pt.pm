=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Pt::Any::Pt - Package for language Portuguese

=cut

package Locale::CLDR::Locales::Pt::Any::Pt;
# This file auto generated from Data\common\main\pt_PT.xml
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
        use bigfloat;
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
					rule => q(←%spellout-cardinal-masculine← mil milhões[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{bilião}other{biliões})$[→%%spellout-cardinal-feminine-with-e→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← mil biliões[→%%spellout-cardinal-feminine-with-e→]),
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
					rule => q(←← mil milhões[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← $(cardinal,one{bilião}other{biliões})$[→%%spellout-cardinal-masculine-with-e→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← mil biliões[→%%spellout-cardinal-masculine-with-e→]),
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
					rule => q(←%spellout-cardinal-feminine← mil milionésima[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← bilionésima[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← mil bilionésima[ →→]),
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
					rule => q(←%spellout-cardinal-masculine← mil milionésimo[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilionésimo[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← mil bilionésimo[ →→]),
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
 				'alt' => 'altai do sul',
 				'ang' => 'inglês antigo',
 				'ar_001' => 'árabe moderno padrão',
 				'arn' => 'mapuche',
 				'ars' => 'árabe do Négede',
 				'av' => 'avaric',
 				'az@alt=short' => 'azeri',
 				'bax' => 'bamun',
 				'bbj' => 'ghomala',
 				'bn' => 'bengalês',
 				'bua' => 'buriat',
 				'ccp' => 'changma',
 				'chk' => 'chuquês',
 				'chn' => 'jargão chinook',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb@alt=menu' => 'curdo sorani',
 				'ckb@alt=variant' => 'sorani (curdo)',
 				'co' => 'córsico',
 				'crs' => 'francês crioulo seselwa',
 				'cs' => 'checo',
 				'cv' => 'chuvash',
 				'de_AT' => 'alemão austríaco',
 				'de_CH' => 'alto alemão suíço',
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
 				'fa_AF' => 'dari',
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
 				'kl' => 'gronelandês',
 				'krc' => 'carachaio-bálcaro',
 				'lez' => 'lezghiano',
 				'lg' => 'ganda',
 				'lou' => 'crioulo de Louisiana',
 				'lrc' => 'luri do norte',
 				'mak' => 'makassarês',
 				'mfe' => 'crioulo mauriciano',
 				'mk' => 'macedónio',
 				'moh' => 'mohawk',
 				'mr' => 'marata',
 				'mul' => 'vários idiomas',
 				'nb' => 'norueguês bokmål',
 				'nds' => 'baixo-alemão',
 				'nds_NL' => 'baixo-saxão',
 				'nl' => 'neerlandês',
 				'nl_BE' => 'flamengo',
 				'nn' => 'norueguês nynorsk',
 				'non' => 'nórdico antigo',
 				'oc' => 'occitano',
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
 				'rhg' => 'rohingya',
 				'ro_MD' => 'moldávio',
 				'se' => 'sami do norte',
 				'sga' => 'irlandês antigo',
 				'shu' => 'árabe do Chade',
 				'sma' => 'sami do sul',
 				'smn' => 'inari sami',
 				'sn' => 'shona',
 				'st' => 'sesoto',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'tg' => 'tajique',
 				'tk' => 'turcomano',
 				'to' => 'tonga',
 				'tt' => 'tatar',
 				'tzm' => 'tamazigue do Atlas Central',
 				'uz' => 'usbeque',
 				'wo' => 'uólofe',
 				'xh' => 'xosa',
 				'xog' => 'soga',
 				'yo' => 'ioruba',
 				'zgh' => 'tamazight marroquino padrão',
 				'zh@alt=menu' => 'chinês mandarim',
 				'zh_Hans' => 'chinês simplificado',
 				'zh_Hans@alt=long' => 'chinês mandarim simplificado',
 				'zh_Hant' => 'chinês tradicional',
 				'zh_Hant@alt=long' => 'chinês mandarim tradicional',
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
			'Aran' => 'nasta’liq',
 			'Armi' => 'aramaico imperial',
 			'Armn' => 'arménio',
 			'Beng' => 'bengalês',
 			'Cakm' => 'chakma',
 			'Egyd' => 'egípcio demótico',
 			'Egyh' => 'egípcio hierático',
 			'Ethi' => 'etíope',
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
 			'EA' => 'Ceuta e Melilha',
 			'EE' => 'Estónia',
 			'EH' => 'Sara Ocidental',
 			'EZ' => 'Zona Euro',
 			'FK' => 'Ilhas Falkland',
 			'FK@alt=variant' => 'Ilhas Falkland (Malvinas)',
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
 			'MK' => 'Macedónia do Norte',
 			'MS' => 'Monserrate',
 			'MU' => 'Maurícia',
 			'MW' => 'Maláui',
 			'NC' => 'Nova Caledónia',
 			'NU' => 'Niuê',
 			'PL' => 'Polónia',
 			'PS' => 'Territórios palestinianos',
 			'QO' => 'Oceânia Insular',
 			'RO' => 'Roménia',
 			'SI' => 'Eslovénia',
 			'SM' => 'São Marinho',
 			'SV' => 'Salvador',
 			'SX' => 'São Martinho (Sint Maarten)',
 			'TF' => 'Territórios Austrais Franceses',
 			'TJ' => 'Tajiquistão',
 			'TK' => 'Toquelau',
 			'TM' => 'Turquemenistão',
 			'TT' => 'Trindade e Tobago',
 			'UM' => 'Ilhas Menores Afastadas dos EUA',
 			'UZ' => 'Usbequistão',
 			'VI' => 'Ilhas Virgens dos EUA',
 			'VN' => 'Vietname',
 			'XA' => 'Pseudoacentos',
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
 			'colalternate' => 'Ignorar ordenação de símbolos',
 			'colbackwards' => 'Ordenação de acentos invertida',
 			'colcasefirst' => 'Ordenação de maiúsculas/minúsculas',
 			'colcaselevel' => 'Ordenação sensível a maiúsculas e minúsculas',
 			'colnormalization' => 'Ordenação normalizada',
 			'colnumeric' => 'Ordenação numérica',
 			'colstrength' => 'Força da ordenação',
 			'hc' => 'Ciclo horário (12 vs. 24)',
 			'ms' => 'Sistema de medida',
 			'va' => 'Variante de região',

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
 				'khmr' => q{Algarismos de khmer},
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
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' " “ ” « » ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
			'final' => '{0}…',
			'initial' => '…{0}',
			'medial' => '{0}…{1}',
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
						'1' => q(picó{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(picó{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(fentó{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(fentó{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ató{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ató{0}),
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
						'1' => q(zeptó{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zeptó{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(ioctó{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(ioctó{0}),
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
					'10p-6' => {
						'1' => q(micró{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micró{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanó{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanó{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(decâ{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(decâ{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(terâ{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(terâ{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(petâ{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(petâ{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exâ{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exâ{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hectó{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hectó{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetâ{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetâ{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(iotâ{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(iotâ{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(quiló{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(quiló{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(megâ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(megâ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(gigâ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(gigâ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(força G),
						'one' => q({0} força G),
						'other' => q({0} força G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(força G),
						'one' => q({0} força G),
						'other' => q({0} força G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros por segundo quadrado),
						'one' => q({0} metro por segundo quadrado),
						'other' => q({0} metros por segundo quadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros por segundo quadrado),
						'one' => q({0} metro por segundo quadrado),
						'other' => q({0} metros por segundo quadrado),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(quilómetros quadrados),
						'one' => q({0} quilómetro quadrado),
						'other' => q({0} quilómetros quadrados),
						'per' => q({0} por quilómetro quadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(quilómetros quadrados),
						'one' => q({0} quilómetro quadrado),
						'other' => q({0} quilómetros quadrados),
						'per' => q({0} por quilómetro quadrado),
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
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimole por litro),
						'other' => q({0} milimoles por litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimoles por litro),
						'one' => q({0} milimole por litro),
						'other' => q({0} milimoles por litro),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros por 100 quilómetros),
						'one' => q({0} litro por 100 quilómetros),
						'other' => q({0} litros por 100 quilómetros),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litros por quilómetro),
						'one' => q({0} litro por quilómetro),
						'other' => q({0} litros por quilómetro),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'west' => q({0} Oeste),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} este),
						'west' => q({0} Oeste),
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
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eletrões-volts),
						'one' => q({0} eletrão-volt),
						'other' => q({0} eletrões-volts),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eletrões-volts),
						'one' => q({0} eletrão-volt),
						'other' => q({0} eletrões-volts),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(quilocalorias),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalorias),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(quilowatt-hora por 100 quilómetros),
						'one' => q({0} quilowatt-hora por 100 quilómetros),
						'other' => q({0} quilowatts-hora por 100 quilómetros),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(quilowatt-hora por 100 quilómetros),
						'one' => q({0} quilowatt-hora por 100 quilómetros),
						'other' => q({0} quilowatts-hora por 100 quilómetros),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pontos),
						'one' => q({0} ponto),
						'other' => q({0} pontos),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pontos),
						'one' => q({0} ponto),
						'other' => q({0} pontos),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapíxeis),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeis),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapíxeis),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxeis),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(píxeis),
						'one' => q({0} píxel),
						'other' => q({0} píxeis),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(píxeis),
						'one' => q({0} píxel),
						'other' => q({0} píxeis),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(píxeis por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeis por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(píxeis por centímetro),
						'one' => q({0} píxel por centímetro),
						'other' => q({0} píxeis por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(píxeis por polegada),
						'one' => q({0} píxel por polegada),
						'other' => q({0} píxeis por polegada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(píxeis por polegada),
						'one' => q({0} píxel por polegada),
						'other' => q({0} píxeis por polegada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'one' => q({0} unidade astronómica),
						'other' => q({0} unidades astronómicas),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetro),
						'other' => q({0} quilómetros),
						'per' => q({0} por quilómetro),
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
					'length-mile-scandinavian' => {
						'name' => q(milha escandinava),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milha escandinava),
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
					'length-picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetro),
						'other' => q({0} picómetros),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pontos tipográficos),
						'one' => q({0} ponto tipográfico),
						'other' => q({0} pontos tipográficos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pontos tipográficos),
						'one' => q({0} ponto tipográfico),
						'other' => q({0} pontos tipográficos),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0} lúmen),
						'other' => q({0} lúmenes),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0} lúmen),
						'other' => q({0} lúmenes),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} massa da Terra),
						'other' => q({0} massas da Terra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} massa da Terra),
						'other' => q({0} massas da Terra),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} quadrados),
						'one' => q({0} quadrado),
						'other' => q({0} quadrados),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} quadrados),
						'one' => q({0} quadrado),
						'other' => q({0} quadrados),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} cúbicos),
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} cúbicos),
						'one' => q({0} cúbico),
						'other' => q({0} cúbicos),
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
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(quilómetros por hora),
						'one' => q({0} quilómetro por hora),
						'other' => q({0} quilómetros por hora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nó),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nó),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetro cúbico),
						'other' => q({0} quilómetros cúbicos),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(chávenas),
						'one' => q({0} chávena),
						'other' => q({0} chávenas),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(chávenas),
						'one' => q({0} chávena),
						'other' => q({0} chávenas),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(chávenas métricas),
						'one' => q({0} chávena métrica),
						'other' => q({0} chávenas métricas),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(chávenas métricas),
						'one' => q({0} chávena métrica),
						'other' => q({0} chávenas métricas),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(colher de sobremesa imperial),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(colher de sobremesa imperial),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'one' => q({0} dracma),
						'other' => q({0} dracmas),
					},
					# Core Unit Identifier
					'dram' => {
						'one' => q({0} dracma),
						'other' => q({0} dracmas),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(doseador),
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(doseador),
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(força G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(força G),
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
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
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
					'consumption-liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg imp.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100 km),
						'one' => q({0}kWh/100 km),
						'other' => q({0}kWh/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(ponto),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(ponto),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milha),
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha),
						'one' => q({0} milha),
						'other' => q({0} milhas),
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
					'length-nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
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
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
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
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
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
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(chávena),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(chávena),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(csb imp.),
						'one' => q({0} csb imp.),
						'other' => q({0} csb imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(csb imp.),
						'one' => q({0} csb imp.),
						'other' => q({0} csb imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fl),
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
					'volume-jigger' => {
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} l),
						'other' => q({0} l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(força G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(força G),
						'one' => q({0} G),
						'other' => q({0} G),
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
						'name' => q(minutos de arco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(minutos de arco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(segundos de arco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(segundos de arco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
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
						'name' => q(pés quadrados),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pés quadrados),
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
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
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
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
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
						'name' => q(quilates),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole/litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole/litro),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milhas/galão),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milhas/galão),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milhas/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milhas/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
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
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutos),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
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
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} V),
						'other' => q({0} V),
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
					'energy-electronvolt' => {
						'name' => q(eletrão-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eletrão-volt),
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
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
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
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
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
						'name' => q(pontos),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pontos),
						'one' => q({0} p),
						'other' => q({0} p),
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
					'graphics-megapixel' => {
						'name' => q(megapíxeis),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapíxeis),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(píxeis),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(píxeis),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
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
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(polegadas),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(polegadas),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metros),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metros),
						'one' => q({0} m),
						'other' => q({0} m),
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
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milha),
						'other' => q({0} milhas),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
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
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
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
						'name' => q(pontos tipográficos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pontos tipográficos),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(massas da Terra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(massas da Terra),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
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
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} ton),
						'other' => q({0} ton),
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
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
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
					'pressure-millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mb),
						'other' => q({0} mb),
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
						'name' => q(graus Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(graus Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(graus Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graus Fahrenheit),
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
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
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
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
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
						'name' => q(chávenas),
						'one' => q({0} cháv.),
						'other' => q({0} cháv.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(chávenas),
						'one' => q({0} cháv.),
						'other' => q({0} cháv.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(chám),
						'one' => q({0} chám),
						'other' => q({0} chám),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(chám),
						'one' => q({0} chám),
						'other' => q({0} chám),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(csb imp.),
						'one' => q({0} csb imp.),
						'other' => q({0} csb imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(csb imp.),
						'one' => q({0} csb imp.),
						'other' => q({0} csb imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma fluido),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma fluido),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(onças fluidas imp.),
						'one' => q({0} onça fluida imp.),
						'other' => q({0} onças fluidas imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(onças fluidas imp.),
						'one' => q({0} onça fluida imp.),
						'other' => q({0} onças fluidas imp.),
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
					'volume-jigger' => {
						'name' => q(doseador),
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(doseador),
						'one' => q({0} doseador),
						'other' => q({0} doseadores),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(quarto imp.),
						'one' => q({0} quarto imp.),
						'other' => q({0} quartos imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quarto imp.),
						'one' => q({0} quarto imp.),
						'other' => q({0} quartos imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cs),
						'one' => q({0} cs),
						'other' => q({0} cs),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cs),
						'one' => q({0} cs),
						'other' => q({0} cs),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cc),
						'one' => q({0} cc),
						'other' => q({0} cc),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cc),
						'one' => q({0} cc),
						'other' => q({0} cc),
					},
				},
			} }
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
				'currency' => q(dirham dos Emirados Árabes Unidos),
				'one' => q(dirham dos Emirados Árabes Unidos),
				'other' => q(sdirham dos Emirados Árabes Unidos),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afeghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afegâni afegão),
				'one' => q(afegâni afegão),
				'other' => q(afegânis afegãos),
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
				'currency' => q(dram arménio),
				'one' => q(dram arménio),
				'other' => q(drams arménios),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florim das Antilhas Holandesas),
				'one' => q(florim das Antilhas Holandesas),
				'other' => q(florins das Antilhas Holandesas),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolano),
				'one' => q(kwanza angolano),
				'other' => q(kwanzas angolanos),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentino),
				'one' => q(peso argentino),
				'other' => q(pesos argentinos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dólar australiano),
				'one' => q(dólar australiano),
				'other' => q(dólares australianos),
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
				'currency' => q(manat azeri),
				'one' => q(manat azeri),
				'other' => q(manats azeris),
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
				'currency' => q(taka bengali),
				'one' => q(taka bengali),
				'other' => q(takas bengalis),
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
				'currency' => q(dinar baremita),
				'one' => q(dinar baremita),
				'other' => q(dinares baremitas),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franco burundiano),
				'one' => q(franco burundiano),
				'other' => q(francos burundianos),
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
				'currency' => q(dólar bruneano),
				'one' => q(dólar bruneano),
				'other' => q(dólares bruneanos),
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
				'currency' => q(ngultrum butanês),
				'one' => q(ngultrum butanês),
				'other' => q(ngultrumes butaneses),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula de Botswana),
				'one' => q(pula de Botswana),
				'other' => q(pulas de Botswana),
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
		'CDF' => {
			display_name => {
				'currency' => q(franco congolês),
				'one' => q(franco congolês),
				'other' => q(francos congoleses),
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
				'currency' => q(franco jibutiano),
				'one' => q(franco jibutiano),
				'other' => q(francos jibutianos),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(coroa dinamarquesa),
				'one' => q(coroa dinamarquesa),
				'other' => q(coroas dinamarquesas),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicanos),
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
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreia),
				'one' => q(nakfa eritreia),
				'other' => q(nakfas eritreias),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etíope),
				'one' => q(birr etíope),
				'other' => q(birres etíopes),
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
				'currency' => q(dólar fijiano),
				'one' => q(dólar fijiano),
				'other' => q(dólares fijianos),
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
		'GEL' => {
			display_name => {
				'currency' => q(lari georgiano),
				'one' => q(lari georgiano),
				'other' => q(laris georgianos),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi do Gana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ganês),
				'one' => q(cedi ganês),
				'other' => q(cedis ganeses),
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
				'currency' => q(dalasi gambiano),
				'one' => q(dalasi gambiano),
				'other' => q(dalasis gambianos),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franco guineense),
				'one' => q(franco guineense),
				'other' => q(francos guineenses),
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
		'HKD' => {
			display_name => {
				'currency' => q(dólar de Hong Kong),
				'one' => q(dólar de Hong Kong),
				'other' => q(dólares de Hong Kong),
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
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitiano),
				'one' => q(gourde haitiano),
				'other' => q(gourdes haitianos),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint húngaro),
				'one' => q(forint húngaro),
				'other' => q(forints húngaros),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonésia),
				'one' => q(rupia indonésia),
				'other' => q(rupias indonésias),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(sheqel novo israelita),
				'one' => q(sheqel novo israelita),
				'other' => q(sheqels novos israelitas),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia indiana),
				'one' => q(rupia indiana),
				'other' => q(rupias indianas),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar iraquiano),
				'one' => q(dinar iraquiano),
				'other' => q(dinares iraquianos),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iraniano),
				'one' => q(rial iraniano),
				'other' => q(riais iranianos),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(coroa islandesa),
				'one' => q(coroa islandesa),
				'other' => q(coroas islandesas),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dólar jamaicano),
				'one' => q(dólar jamaicano),
				'other' => q(dólares jamaicanos),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordaniano),
				'one' => q(dinar jordaniano),
				'other' => q(dinares jordanianos),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(iene japonês),
				'one' => q(iene japonês),
				'other' => q(ienes japoneses),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(xelim queniano),
				'one' => q(xelim queniano),
				'other' => q(xelins quenianos),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som quirguiz),
				'one' => q(som quirguiz),
				'other' => q(somes quirguizes),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambojano),
				'one' => q(riel cambojano),
				'other' => q(rieles cambojanos),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franco comoriano),
				'one' => q(franco comoriano),
				'other' => q(francos comorianos),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won norte-coreano),
				'one' => q(won norte-coreano),
				'other' => q(wons norte-coreanos),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won sul-coreano),
				'one' => q(won sul-coreano),
				'other' => q(wons sul-coreano),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuwaitiano),
				'one' => q(dinar kuwaitiano),
				'other' => q(dinares kuwaitianos),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dólar das Ilhas Caimão),
				'one' => q(dólar das Ilhas Caimão),
				'other' => q(dólares das Ilhas Caimão),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge cazaque),
				'one' => q(tenge cazaque),
				'other' => q(tenges cazaques),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laosiano),
				'one' => q(kip laosiano),
				'other' => q(kips laosianos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libra libanesa),
				'one' => q(libra libanesa),
				'other' => q(libras libanesas),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia do Sri Lanka),
				'one' => q(rupia do Sri Lanka),
				'other' => q(rupias do Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dólar liberiano),
				'one' => q(dólar liberiano),
				'other' => q(dólares liberianos),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesotiano),
				'one' => q(loti lesotiano),
				'other' => q(lotis lesotianos),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas da Lituânia),
				'one' => q(Litas da Lituânia),
				'other' => q(Litas da Lituânia),
			},
		},
		'LVL' => {
			symbol => 'LVL',
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
				'currency' => q(ariari malgaxe),
				'one' => q(ariari malgaxe),
				'other' => q(ariaris malgaxes),
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
				'currency' => q(kyat de Mianmar),
				'one' => q(kyat de Mianmar),
				'other' => q(kyats de Mianmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongóis),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca macaense),
				'one' => q(pataca macaense),
				'other' => q(patacas macaenses),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya mauritana \(1973–2017\)),
				'one' => q(ouguiya mauritana \(1973–2017\)),
				'other' => q(ouguiyas mauritanas \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritana),
				'one' => q(ouguiya mauritana),
				'other' => q(ouguiyas mauritanas),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupias mauricianas),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rupia maldivana),
				'one' => q(rupia maldivana),
				'other' => q(rupias maldivanas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malauiano),
				'one' => q(kwacha malauiano),
				'other' => q(kwachas malauianos),
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
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malaio),
				'one' => q(ringgit malaio),
				'other' => q(ringgits malaios),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical moçambicano),
				'one' => q(metical moçambicano),
				'other' => q(meticais moçambicanos),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dólar namibiano),
				'one' => q(dólar namibiano),
				'other' => q(dólares namibianos),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(nairas nigerianas),
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
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupias nepalesas),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dólar neozelandês),
				'one' => q(dólar neozelandês),
				'other' => q(dólares neozelandeses),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanense),
				'one' => q(rial omanense),
				'other' => q(riais omanenses),
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
				'currency' => q(kina papuásia),
				'one' => q(kina papuásia),
				'other' => q(kinas papuásias),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(peso filipino),
				'one' => q(peso filipino),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia paquistanesa),
				'one' => q(rupia paquistanesa),
				'other' => q(rupias paquistanesas),
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
			display_name => {
				'currency' => q(escudo português),
				'one' => q(escudo português),
				'other' => q(escudos portugueses),
			},
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
				'currency' => q(rial catarense),
				'one' => q(rial catarense),
				'other' => q(riais catarenses),
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
		'RWF' => {
			display_name => {
				'currency' => q(franco ruandês),
				'one' => q(franco ruandês),
				'other' => q(francos ruandeses),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudita),
				'one' => q(rial saudita),
				'other' => q(riais sauditas),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dólar das Ilhas Salomão),
				'one' => q(dólar das Ilhas Salomão),
				'other' => q(dólares das Ilhas Salomão),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia seichelense),
				'one' => q(rupia seichelense),
				'other' => q(rupias seichelenses),
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
				'currency' => q(dólar singapuriano),
				'one' => q(dólar singapuriano),
				'other' => q(dólares singapurianos),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(libra santa-helenense),
				'one' => q(libra santa-helenense),
				'other' => q(libras santa-helenenses),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone de Serra Leoa),
				'one' => q(leone de Serra Leoa),
				'other' => q(leones de Serra Leoa),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(xelim somali),
				'one' => q(xelim somali),
				'other' => q(xelins somalis),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dólar do Suriname),
				'one' => q(dólar do Suriname),
				'other' => q(dólares do Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(libra sul-sudanesa),
				'one' => q(libra sul-sudanesa),
				'other' => q(libras sul-sudanesas),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de São Tomé e Príncipe),
				'one' => q(dobra de São Tomé e Príncipe),
				'other' => q(dobras de São Tomé e Príncipe),
			},
		},
		'SYP' => {
			symbol => '£',
			display_name => {
				'currency' => q(libra síria),
				'one' => q(libra síria),
				'other' => q(libras sírias),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni suázi),
				'one' => q(lilangeni suázi),
				'other' => q(lilangenis suázis),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht tailandês),
				'one' => q(baht tailandês),
				'other' => q(bahts tailandeses),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tajique),
				'one' => q(somoni tajique),
				'other' => q(somonis tajiques),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turcomeno),
				'one' => q(manat turcomeno),
				'other' => q(manats turcomenos),
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
				'currency' => q(paʻanga tonganesa),
				'one' => q(paʻanga tonganesa),
				'other' => q(paʻangas tonganesas),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(liras turcas),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dólar de Trindade e Tobago),
				'one' => q(dólar de Trindade e Tobago),
				'other' => q(dólares de Trindade e Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(novo dólar taiwanês),
				'one' => q(novo dólar taiwanês),
				'other' => q(novos dólares taiwaneses),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(xelim tanzaniano),
				'one' => q(xelim tanzaniano),
				'other' => q(xelins tanzanianos),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ucraniano),
				'one' => q(hryvnia ucraniano),
				'other' => q(hryvnias ucranianos),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(xelim ugandense),
				'one' => q(xelim ugandense),
				'other' => q(xelins ugandenses),
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
				'currency' => q(som uzbeque),
				'one' => q(som uzbeque),
				'other' => q(somes uzbeques),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolívar \(2008–2018\)),
				'one' => q(bolívar \(2008–2018\)),
				'other' => q(bolívares \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar),
				'one' => q(bolívar),
				'other' => q(bolívares),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dongs vietnamitas),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu de Vanuatu),
				'one' => q(vatu de Vanuatu),
				'other' => q(vatus de Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoano),
				'one' => q(tala samoano),
				'other' => q(talas samoanos),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA \(BEAC\)),
				'one' => q(franco CFA \(BEAC\)),
				'other' => q(francos CFA \(BEAC\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dólar das Caraíbas Orientais),
				'one' => q(dólar das Caraíbas Orientais),
				'other' => q(dólares das Caraíbas Orientais),
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
		'XPF' => {
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(franco CFP),
				'other' => q(francos CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moeda desconhecida),
				'one' => q(\(moeda desconhecida\)),
				'other' => q(\(moedas desconhecidas\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial iemenita),
				'one' => q(rial iemenita),
				'other' => q(riais iemenitas),
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
		'ZAR' => {
			display_name => {
				'currency' => q(rand sul-africano),
				'one' => q(rand sul-africano),
				'other' => q(rands sul-africanos),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha zambiano \(1968–2012\)),
				'one' => q(Kwacha zambiano \(1968–2012\)),
				'other' => q(Kwachas zambianos \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambiano),
				'one' => q(kwacha zambiano),
				'other' => q(kwachas zambianos),
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
						mon => 'seg.',
						tue => 'ter.',
						wed => 'qua.',
						thu => 'qui.',
						fri => 'sex.',
						sat => 'sáb.',
						sun => 'dom.'
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
			if ($_ eq 'hebrew') {
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
			if ($_ eq 'islamic') {
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
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{tarde},
					'am' => q{a.m.},
					'evening1' => q{noite},
					'midnight' => q{meia-noite},
					'morning1' => q{manhã},
					'night1' => q{madrugada},
					'noon' => q{meio-dia},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{da manhã},
					'pm' => q{da tarde},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'am' => q{a.m.},
					'pm' => q{p.m.},
				},
				'wide' => {
					'am' => q{manhã},
					'pm' => q{tarde},
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
			'full' => q{EEEE, d 'de' MMMM 'de' U},
			'long' => q{d 'de' MMMM 'de' U},
			'medium' => q{d 'de' MMM 'de' U},
			'short' => q{dd/MM/yy},
		},
		'generic' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y G},
			'long' => q{d 'de' MMMM 'de' y G},
			'medium' => q{d 'de' MMM 'de' y G},
			'short' => q{d/M/y G},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'de' MMMM 'de' y},
			'long' => q{d 'de' MMMM 'de' y},
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
			MMMMW => q{W.'ª' 'semana' 'de' MMMM},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/MM/y GGGGG – E, d/MM/y GGGGG},
				M => q{E, d/MM/y – E, d/MM/y GGGGG},
				d => q{E, d/MM/y – E, d/MM/y GGGGG},
				y => q{E, d/MM/y – E, d/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d 'de' MMMM, y G – E, d 'de' MMMM, y G},
				M => q{E, d 'de' MMMM – E, d 'de' MMMM, y G},
				d => q{E, d 'de' MMMM – E, d 'de' MMMM, y G},
				y => q{E, d 'de' MMMM, y – E, d 'de' MMMM, y G},
			},
			GyMMMd => {
				G => q{d 'de' MMMM, y G – d 'de' MMMM, y G},
				M => q{d 'de' MMMM – d 'de' MMMM, y G},
				d => q{d – d 'de' MMMM, y G},
				y => q{d 'de' MMMM, y – d 'de' MMMM, y G},
			},
			GyMd => {
				G => q{d/MM/y GGGGG – d/MM/y GGGGG},
				M => q{d/MM/y – d/MM/y GGGGG},
				d => q{d/MM/y – d/MM/y GGGGG},
				y => q{d/MM/y – d/MM/y GGGGG},
			},
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
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
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
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
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
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
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
				'daylight' => q#Hora de verão central norte-americana#,
				'generic' => q#Hora central norte-americana#,
				'standard' => q#Hora padrão central norte-americana#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora de verão oriental norte-americana#,
				'generic' => q#Hora oriental norte-americana#,
				'standard' => q#Hora padrão oriental norte-americana#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora de verão de montanha norte-americana#,
				'generic' => q#Hora de montanha norte-americana#,
				'standard' => q#Hora padrão de montanha norte-americana#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora de verão do Pacífico norte-americana#,
				'generic' => q#Hora do Pacífico norte-americana#,
				'standard' => q#Hora padrão do Pacífico norte-americana#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Hora de verão de Anadyr#,
				'generic' => q#Hora de Anadyr#,
				'standard' => q#Hora padrão de Anadyr#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
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
		'Asia/Aden' => {
			exemplarCity => q#Adem#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
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
		'Asia/Dhaka' => {
			exemplarCity => q#Daca#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Carachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Catmandu#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweit#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macassar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipé#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teerão#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timphu#,
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
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reiquiavique#,
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
				'daylight' => q#Hora de verão do Bangladeche#,
				'generic' => q#Hora do Bangladeche#,
				'standard' => q#Hora padrão do Bangladeche#,
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
		'Europe/Tallinn' => {
			exemplarCity => q#Talim#,
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
				'daylight' => q#Hora de verão da Ilha Norfolk#,
				'generic' => q#Hora da Ilha Norfolk#,
				'standard' => q#Hora padrão da Ilha Norfolk#,
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
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
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
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
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
		'Yukon' => {
			long => {
				'standard' => q#Hora do Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
