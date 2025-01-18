=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ca - Package for language Catalan

=cut

package Locale::CLDR::Locales::Ca;
# This file auto generated from Data\common\main\ca.xml
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
					rule => q(=#,##0=a),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=a),
				},
			},
		},
		'digits-ordinal-indicator-m' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(è),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(r),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(n),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(r),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(t),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(è),
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
		'digits-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator-m=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator-m=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menys →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dues),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint[-i-→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trenta[-→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quaranta[-→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquanta[-→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seixanta[-→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setanta[-→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(vuitanta[-→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noranta[-→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[-→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←-cent→%%spellout-cardinal-feminine-cents→),
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
					rule => q(un milió[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milions[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliards[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilió[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilions[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliards[ →→]),
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
		'spellout-cardinal-feminine-cents' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(s),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-feminine=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menys →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
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
					rule => q(quatre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinc),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sis),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(set),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(vuit),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nou),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deu),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dotze),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretze),
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
					rule => q(setze),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(disset),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(divuit),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dinou),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint[-i-→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trenta[-→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quaranta[-→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquanta[-→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seixanta[-→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setanta[-→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(vuitanta[-→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noranta[-→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[-→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←-cent→%%spellout-cardinal-masculine-cents→),
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
					rule => q(un milió[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milions[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliards[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilió[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilions[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliards[ →→]),
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
		'spellout-cardinal-masculine-cents' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(s),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-masculine=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menys →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← coma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(u),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint[-i-→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trenta[-→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quaranta[-→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquanta[-→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seixanta[-→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setanta[-→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(vuitanta[-→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(noranta[-→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[-→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←-cent→%%spellout-numbering-cents→),
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
					rule => q(un milió[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milions[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliards[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilió[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilions[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliards[ →→]),
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
		'spellout-numbering-cents' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(s),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-cardinal-masculine=),
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
					rule => q(menys →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zerona),
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
					rule => q(segona),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tercera),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarta),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinquena),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sisena),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(setena),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(vuitena),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(novena),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(desena),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onzena),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dotzena),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretzena),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(catorzena),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quinzena),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(setzena),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dissetena),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(divuitena),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dinovena),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vintena),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(vint-i-→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trentena),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(trenta-→→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarantena),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(quaranta-→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquantena),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(cinquanta-→→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seixantena),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(seixanta-→→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setantena),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(setanta-→→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(vuitantena),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(vuitanta-→→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(norantena),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(noranta-→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(centena),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(cent-→→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←-cent→%%spellout-ordinal-feminine-cont→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil→%%spellout-ordinal-feminine-cont→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mil→%%spellout-ordinal-feminine-cont→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un milion→%%spellout-ordinal-feminine-cont→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion→%%spellout-ordinal-feminine-conts→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliard→%%spellout-ordinal-feminine-cont→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliard→%%spellout-ordinal-feminine-conts→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilion→%%spellout-ordinal-feminine-cont→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion→%%spellout-ordinal-feminine-conts→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliard→%%spellout-ordinal-feminine-cont→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliard→%%spellout-ordinal-feminine-conts→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ena),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=ena),
				},
			},
		},
		'spellout-ordinal-feminine-cont' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ena),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-feminine-conts' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ena),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(s =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(s =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(menys →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zeroè),
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
					rule => q(segon),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tercer),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quart),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinquè),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sisè),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(setè),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(vuitè),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(novè),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(desè),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onzè),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dotzè),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretzè),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(catorzè),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quinzè),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(setzè),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dissetè),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(divuitè),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(dinovè),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vintè),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(vint-i-→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trentè),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(trenta-→→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarantè),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(quaranta-→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquantè),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(cinquanta-→→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seixantè),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(seixanta-→→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setantè),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(setanta-→→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(vuitantè),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(vuitanta-→→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(norantè),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(noranta-→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(centè),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(cent-→→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←-cent→%%spellout-ordinal-masculine-cont→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mil→%%spellout-ordinal-masculine-cont→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← mil→%%spellout-ordinal-masculine-cont→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un milion→%%spellout-ordinal-masculine-cont→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milion→%%spellout-ordinal-masculine-conts→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliard→%%spellout-ordinal-masculine-cont→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliard→%%spellout-ordinal-masculine-conts→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilion→%%spellout-ordinal-masculine-cont→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilion→%%spellout-ordinal-masculine-conts→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliard→%%spellout-ordinal-masculine-cont→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliard→%%spellout-ordinal-masculine-conts→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=è),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=è),
				},
			},
		},
		'spellout-ordinal-masculine-cont' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(è),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-masculine-conts' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(è),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(s =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(s =%spellout-ordinal-masculine=),
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
				'aa' => 'àfar',
 				'ab' => 'abkhaz',
 				'ace' => 'atjeh',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adigué',
 				'ae' => 'avèstic',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'àkan',
 				'akk' => 'accadi',
 				'akz' => 'alabama',
 				'ale' => 'aleuta',
 				'aln' => 'albanès geg',
 				'alt' => 'altaic meridional',
 				'am' => 'amhàric',
 				'an' => 'aragonès',
 				'ang' => 'anglès antic',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'àrab',
 				'ar_001' => 'àrab estàndard modern',
 				'arc' => 'arameu',
 				'arn' => 'mapudungu',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'ars' => 'àrab najdi',
 				'arw' => 'arauac',
 				'arz' => 'àrab egipci',
 				'as' => 'assamès',
 				'asa' => 'pare',
 				'ase' => 'llengua de signes americana',
 				'ast' => 'asturià',
 				'atj' => 'atacama',
 				'av' => 'àvar',
 				'awa' => 'awadhi',
 				'ay' => 'aimara',
 				'az' => 'azerbaidjanès',
 				'az@alt=short' => 'àzeri',
 				'ba' => 'baixkir',
 				'bal' => 'balutxi',
 				'ban' => 'balinès',
 				'bar' => 'bavarès',
 				'bas' => 'basa',
 				'bax' => 'bamum',
 				'bbj' => 'ghomala',
 				'be' => 'belarús',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'búlgar',
 				'bgc' => 'haryanvi',
 				'bgn' => 'balutxi occidental',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bicol',
 				'bin' => 'edo',
 				'bkm' => 'kom',
 				'bla' => 'blackfoot',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bengalí',
 				'bo' => 'tibetà',
 				'br' => 'bretó',
 				'bra' => 'braj',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosnià',
 				'bss' => 'akoose',
 				'bua' => 'buriat',
 				'bug' => 'bugui',
 				'bum' => 'bulu',
 				'byn' => 'bilin',
 				'byv' => 'medumba',
 				'ca' => 'català',
 				'cad' => 'caddo',
 				'car' => 'carib',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'txetxè',
 				'ceb' => 'cebuà',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'txibtxa',
 				'chg' => 'txagatai',
 				'chk' => 'chuuk',
 				'chm' => 'mari',
 				'chn' => 'pidgin chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'xeiene',
 				'cic' => 'chickasaw',
 				'ckb' => 'kurd central',
 				'ckb@alt=menu' => 'sorani',
 				'ckb@alt=variant' => 'kurd sorani',
 				'clc' => 'chilcotin',
 				'co' => 'cors',
 				'cop' => 'copte',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'tàtar de Crimea',
 				'crj' => 'cree sud-oriental',
 				'crk' => 'cree de la plana',
 				'crl' => 'cree nord-oriental',
 				'crm' => 'moose cree',
 				'crr' => 'algonquí de Carolina',
 				'crs' => 'francès crioll de les Seychelles',
 				'cs' => 'txec',
 				'csb' => 'caixubi',
 				'csw' => 'swampy cree',
 				'cu' => 'eslau eclesiàstic',
 				'cv' => 'txuvaix',
 				'cy' => 'gal·lès',
 				'da' => 'danès',
 				'dak' => 'dakota',
 				'dar' => 'darguà',
 				'dav' => 'taita',
 				'de' => 'alemany',
 				'de_AT' => 'alemany austríac',
 				'de_CH' => 'alemany estàndard suís',
 				'del' => 'delaware',
 				'den' => 'slavi',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'baix sòrab',
 				'dua' => 'douala',
 				'dum' => 'neerlandès mitjà',
 				'dv' => 'divehi',
 				'dyo' => 'diola',
 				'dyu' => 'jula',
 				'dz' => 'dzongka',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emilià',
 				'egy' => 'egipci antic',
 				'eka' => 'ekajuk',
 				'el' => 'grec',
 				'elx' => 'elamita',
 				'en' => 'anglès',
 				'en_AU' => 'anglès australià',
 				'en_CA' => 'anglès canadenc',
 				'en_GB' => 'anglès britànic',
 				'en_GB@alt=short' => 'anglès (GB)',
 				'en_US' => 'anglès americà',
 				'en_US@alt=short' => 'anglès (EUA)',
 				'enm' => 'anglès mitjà',
 				'eo' => 'esperanto',
 				'es' => 'espanyol',
 				'es_419' => 'espanyol llatinoamericà',
 				'es_ES' => 'espanyol europeu',
 				'es_MX' => 'espanyol de Mèxic',
 				'et' => 'estonià',
 				'eu' => 'basc',
 				'ewo' => 'ewondo',
 				'ext' => 'extremeny',
 				'fa' => 'persa',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'ful',
 				'fi' => 'finès',
 				'fil' => 'filipí',
 				'fj' => 'fijià',
 				'fo' => 'feroès',
 				'fon' => 'fon',
 				'fr' => 'francès',
 				'fr_CA' => 'francès canadenc',
 				'fr_CH' => 'francès suís',
 				'frc' => 'francès cajun',
 				'frm' => 'francès mitjà',
 				'fro' => 'francès antic',
 				'frr' => 'frisó septentrional',
 				'frs' => 'frisó oriental',
 				'fur' => 'friülà',
 				'fy' => 'frisó occidental',
 				'ga' => 'irlandès',
 				'gaa' => 'ga',
 				'gag' => 'gagaús',
 				'gan' => 'xinès gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'gaèlic escocès',
 				'gez' => 'gueez',
 				'gil' => 'gilbertès',
 				'gl' => 'gallec',
 				'glk' => 'gilaki',
 				'gmh' => 'alt alemany mitjà',
 				'gn' => 'guaraní',
 				'goh' => 'alt alemany antic',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gòtic',
 				'grb' => 'grebo',
 				'grc' => 'grec antic',
 				'gsw' => 'alemany suís',
 				'gu' => 'gujarati',
 				'guc' => 'wayú',
 				'guz' => 'gusí',
 				'gv' => 'manx',
 				'gwi' => 'gwich’in',
 				'ha' => 'haussa',
 				'hai' => 'haida',
 				'hak' => 'xinès hakka',
 				'haw' => 'hawaià',
 				'hax' => 'haida meridional',
 				'he' => 'hebreu',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'hindi de Fiji',
 				'hil' => 'híligaynon',
 				'hit' => 'hitita',
 				'hmn' => 'hmong',
 				'hnj' => 'hmong njua',
 				'ho' => 'hiri motu',
 				'hr' => 'croat',
 				'hsb' => 'alt sòrab',
 				'hsn' => 'xinès xiang',
 				'ht' => 'crioll d’Haití',
 				'hu' => 'hongarès',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armeni',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesi',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi sichuan',
 				'ik' => 'inupiak',
 				'ikt' => 'inuktitut occidental canadenc',
 				'ilo' => 'ilocano',
 				'inh' => 'ingúix',
 				'io' => 'ido',
 				'is' => 'islandès',
 				'it' => 'italià',
 				'iu' => 'inuktitut',
 				'ja' => 'japonès',
 				'jam' => 'crioll anglès de Jamaica',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'judeopersa',
 				'jrb' => 'judeoàrab',
 				'jv' => 'javanès',
 				'ka' => 'georgià',
 				'kaa' => 'karakalpak',
 				'kab' => 'cabilenc',
 				'kac' => 'katxin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardí',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'crioll capverdià',
 				'ken' => 'kenyang',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingà',
 				'kha' => 'khasi',
 				'kho' => 'khotanès',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuiu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakh',
 				'kkj' => 'kako',
 				'kl' => 'groenlandès',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'coreà',
 				'koi' => 'komi-permiac',
 				'kok' => 'concani',
 				'kos' => 'kosraeà',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karatxai-balkar',
 				'kri' => 'krio',
 				'krl' => 'carelià',
 				'kru' => 'kurukh',
 				'ks' => 'caixmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurd',
 				'kum' => 'kúmik',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'còrnic',
 				'kwk' => 'kwak’wala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirguís',
 				'la' => 'llatí',
 				'lad' => 'judeocastellà',
 				'lag' => 'langi',
 				'lah' => 'panjabi occidental',
 				'lam' => 'lamba',
 				'lb' => 'luxemburguès',
 				'lez' => 'lesguià',
 				'lg' => 'ganda',
 				'li' => 'limburguès',
 				'lij' => 'lígur',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'lld' => 'ladí',
 				'lmo' => 'llombard',
 				'ln' => 'lingala',
 				'lo' => 'laosià',
 				'lol' => 'mongo',
 				'lou' => 'crioll francès de Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri septentrional',
 				'lsm' => 'saamia',
 				'lt' => 'lituà',
 				'lu' => 'luba katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luisenyo',
 				'lun' => 'lunda',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letó',
 				'lzh' => 'xinès clàssic',
 				'lzz' => 'laz',
 				'mad' => 'madurès',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makassar',
 				'man' => 'mandinga',
 				'mas' => 'massai',
 				'mde' => 'maba',
 				'mdf' => 'mordovià moksa',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauricià',
 				'mg' => 'malgaix',
 				'mga' => 'gaèlic irlandès mitjà',
 				'mgh' => 'makhuwa-metto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallès',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedoni',
 				'ml' => 'malaiàlam',
 				'mn' => 'mongol',
 				'mnc' => 'manxú',
 				'mni' => 'manipurí',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'moore',
 				'mr' => 'marathi',
 				'mrj' => 'mari occidental',
 				'ms' => 'malai',
 				'mt' => 'maltès',
 				'mua' => 'mundang',
 				'mul' => 'llengües vàries',
 				'mus' => 'creek',
 				'mwl' => 'mirandès',
 				'mwr' => 'marwari',
 				'my' => 'birmà',
 				'mye' => 'myene',
 				'myv' => 'mordovià erza',
 				'mzn' => 'mazanderani',
 				'na' => 'nauruà',
 				'nan' => 'xinès min del sud',
 				'nap' => 'napolità',
 				'naq' => 'nama',
 				'nb' => 'noruec bokmål',
 				'nd' => 'ndebele septentrional',
 				'nds' => 'baix alemany',
 				'nds_NL' => 'baix saxó',
 				'ne' => 'nepalès',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueà',
 				'nl' => 'neerlandès',
 				'nl_BE' => 'flamenc',
 				'nmg' => 'bissio',
 				'nn' => 'noruec nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'noruec',
 				'nog' => 'nogai',
 				'non' => 'nòrdic antic',
 				'nov' => 'novial',
 				'nqo' => 'n’Ko',
 				'nr' => 'ndebele meridional',
 				'nso' => 'sotho septentrional',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nwc' => 'newari clàssic',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwesi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzema',
 				'oc' => 'occità',
 				'oj' => 'ojibwa',
 				'ojb' => 'ojibwa septentrional',
 				'ojc' => 'ojibwa central',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwa occidental',
 				'oka' => 'okanagà',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osseta',
 				'osa' => 'osage',
 				'ota' => 'turc otomà',
 				'pa' => 'panjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiament',
 				'pau' => 'palauà',
 				'pcd' => 'picard',
 				'pcm' => 'pidgin de Nigèria',
 				'pdc' => 'alemany pennsilvanià',
 				'peo' => 'persa antic',
 				'pfl' => 'alemany palatí',
 				'phn' => 'fenici',
 				'pi' => 'pali',
 				'pis' => 'pidgin',
 				'pl' => 'polonès',
 				'pms' => 'piemontès',
 				'pnt' => 'pòntic',
 				'pon' => 'ponapeà',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'prussià',
 				'pro' => 'provençal antic',
 				'ps' => 'paixtu',
 				'ps@alt=variant' => 'pushtu',
 				'pt' => 'portuguès',
 				'pt_BR' => 'portuguès del Brasil',
 				'pt_PT' => 'portuguès de Portugal',
 				'qu' => 'quítxua',
 				'quc' => 'k’iche’',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongà',
 				'rgn' => 'romanyès',
 				'rhg' => 'rohingya',
 				'rm' => 'retoromànic',
 				'rn' => 'rundi',
 				'ro' => 'romanès',
 				'ro_MD' => 'moldau',
 				'rof' => 'rombo',
 				'rom' => 'romaní',
 				'ru' => 'rus',
 				'rup' => 'aromanès',
 				'rw' => 'ruandès',
 				'rwk' => 'rwo',
 				'sa' => 'sànscrit',
 				'sad' => 'sandawe',
 				'sah' => 'iacut',
 				'sam' => 'arameu samarità',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sard',
 				'scn' => 'sicilià',
 				'sco' => 'escocès',
 				'sd' => 'sindi',
 				'sdc' => 'sasserès',
 				'sdh' => 'kurd meridional',
 				'se' => 'sami septentrional',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'songhai oriental',
 				'sg' => 'sango',
 				'sga' => 'irlandès antic',
 				'sh' => 'serbocroat',
 				'shi' => 'taixelhit',
 				'shn' => 'xan',
 				'shu' => 'àrab txadià',
 				'si' => 'singalès',
 				'sid' => 'sidamo',
 				'sk' => 'eslovac',
 				'sl' => 'eslovè',
 				'slh' => 'lushootseed meridional',
 				'sm' => 'samoà',
 				'sma' => 'sami meridional',
 				'smj' => 'sami lule',
 				'smn' => 'sami d’Inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdià',
 				'sq' => 'albanès',
 				'sr' => 'serbi',
 				'srn' => 'sranan',
 				'srr' => 'serer',
 				'ss' => 'swazi',
 				'ssy' => 'saho',
 				'st' => 'sotho meridional',
 				'str' => 'straits salish',
 				'su' => 'sondanès',
 				'suk' => 'sukuma',
 				'sus' => 'susú',
 				'sux' => 'sumeri',
 				'sv' => 'suec',
 				'sw' => 'suahili',
 				'sw_CD' => 'suahili del Congo',
 				'swb' => 'comorià',
 				'syc' => 'siríac clàssic',
 				'syr' => 'siríac',
 				'szl' => 'silesià',
 				'ta' => 'tàmil',
 				'tce' => 'tutxone meridional',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'terena',
 				'tet' => 'tètum',
 				'tg' => 'tadjik',
 				'tgx' => 'tagish',
 				'th' => 'tai',
 				'tht' => 'tahltà',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turcman',
 				'tkl' => 'tokelauès',
 				'tkr' => 'tsakhur',
 				'tl' => 'tagal',
 				'tlh' => 'klingonià',
 				'tli' => 'tlingit',
 				'tly' => 'talix',
 				'tmh' => 'amazic',
 				'tn' => 'setswana',
 				'to' => 'tongalès',
 				'tog' => 'tonga',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turc',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshià',
 				'tt' => 'tàtar',
 				'ttm' => 'tutxone septentrional',
 				'ttt' => 'tat meridional',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvaluà',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitià',
 				'tyv' => 'tuvinià',
 				'tzm' => 'amazic del Marroc central',
 				'udm' => 'udmurt',
 				'ug' => 'uigur',
 				'uga' => 'ugarític',
 				'uk' => 'ucraïnès',
 				'umb' => 'umbundu',
 				'und' => 'idioma desconegut',
 				'ur' => 'urdú',
 				'uz' => 'uzbek',
 				've' => 'venda',
 				'vec' => 'vènet',
 				'vep' => 'vepse',
 				'vi' => 'vietnamita',
 				'vls' => 'flamenc occidental',
 				'vmw' => 'makua',
 				'vo' => 'volapük',
 				'vot' => 'vòtic',
 				'vun' => 'vunjo',
 				'wa' => 'való',
 				'wae' => 'walser',
 				'wal' => 'wolaita',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wòlof',
 				'wuu' => 'xinès wu',
 				'xal' => 'calmuc',
 				'xh' => 'xosa',
 				'xmf' => 'mingrelià',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapeà',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'ídix',
 				'yo' => 'ioruba',
 				'yrl' => 'nheengatú',
 				'yue' => 'cantonès',
 				'yue@alt=menu' => 'xinès, cantonès',
 				'za' => 'zhuang',
 				'zap' => 'zapoteca',
 				'zbl' => 'símbols Bliss',
 				'zea' => 'zelandès',
 				'zen' => 'zenaga',
 				'zgh' => 'amazic estàndard marroquí',
 				'zh' => 'xinès',
 				'zh@alt=menu' => 'xinès, mandarí',
 				'zh_Hans' => 'xinès simplificat',
 				'zh_Hans@alt=long' => 'xinès mandarí (simplificat)',
 				'zh_Hant' => 'xinès tradicional',
 				'zh_Hant@alt=long' => 'xinès mandarí (tradicional)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'sense contingut lingüístic',
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
			'Adlm' => 'adlam',
 			'Afak' => 'afaka',
 			'Aghb' => 'albanès caucàsic',
 			'Ahom' => 'ahom',
 			'Arab' => 'àrab',
 			'Arab@alt=variant' => 'persoaràbic',
 			'Aran' => 'nasta’liq',
 			'Armi' => 'arameu imperial',
 			'Armn' => 'armeni',
 			'Avst' => 'avèstic',
 			'Bali' => 'balinès',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalí',
 			'Bhks' => 'bhaiksuki',
 			'Blis' => 'símbols Bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'buginès',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'sil·labari aborigen canadenc unificat',
 			'Cari' => 'carià',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'copte',
 			'Cprt' => 'xipriota',
 			'Cyrl' => 'ciríl·lic',
 			'Cyrs' => 'ciríl·lic de l’antic eslau eclesiàstic',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'taquigrafia Duployé',
 			'Egyd' => 'demòtic egipci',
 			'Egyh' => 'hieràtic egipci',
 			'Egyp' => 'jeroglífic egipci',
 			'Elba' => 'elbasan',
 			'Ethi' => 'etiòpic',
 			'Geok' => 'georgià hucuri',
 			'Geor' => 'georgià',
 			'Glag' => 'glagolític',
 			'Goth' => 'gòtic',
 			'Gran' => 'grantha',
 			'Grek' => 'grec',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han amb bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'simplificat',
 			'Hans@alt=stand-alone' => 'han simplificat',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hebr' => 'hebreu',
 			'Hira' => 'hiragana',
 			'Hluw' => 'jeroglífic anatoli',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'sil·labaris japonesos',
 			'Hung' => 'hongarès antic',
 			'Inds' => 'escriptura de la vall de l’Indus',
 			'Ital' => 'cursiva antiga',
 			'Jamo' => 'jamo',
 			'Java' => 'javanès',
 			'Jpan' => 'japonès',
 			'Jurc' => 'jürchen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharosthi',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khoja',
 			'Knda' => 'kannada',
 			'Kore' => 'coreà',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'llatí fraktur',
 			'Latg' => 'llatí gaèlic',
 			'Latn' => 'llatí',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineal A',
 			'Linb' => 'lineal B',
 			'Lisu' => 'lisu',
 			'Loma' => 'loma',
 			'Lyci' => 'lici',
 			'Lydi' => 'lidi',
 			'Mahj' => 'mahajani',
 			'Mand' => 'mandaic',
 			'Mani' => 'maniqueu',
 			'Maya' => 'jeroglífics maies',
 			'Mend' => 'mende',
 			'Merc' => 'cursiva meroítica',
 			'Mero' => 'meroític',
 			'Mlym' => 'malaiàlam',
 			'Modi' => 'modi',
 			'Mong' => 'mongol',
 			'Moon' => 'moon',
 			'Mroo' => 'mro',
 			'Mtei' => 'manipuri',
 			'Mult' => 'multani',
 			'Mymr' => 'birmà',
 			'Narb' => 'antic nord-aràbic',
 			'Nbat' => 'nabateu',
 			'Newa' => 'newar',
 			'Nkgb' => 'geba',
 			'Nkoo' => 'n’Ko',
 			'Nshu' => 'nü shu',
 			'Ogam' => 'ogham',
 			'Olck' => 'santali',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osge' => 'osage',
 			'Osma' => 'osmanya',
 			'Palm' => 'palmirè',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'antic pèrmic',
 			'Phag' => 'phagspa',
 			'Phli' => 'pahlavi inscripcional',
 			'Phlp' => 'psalter pahlavi',
 			'Phlv' => 'pahlavi',
 			'Phnx' => 'fenici',
 			'Plrd' => 'pollard miao',
 			'Prti' => 'parthià inscripcional',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongo-rongo',
 			'Runr' => 'rúnic',
 			'Samr' => 'samarità',
 			'Sara' => 'sarati',
 			'Sarb' => 'sud-aràbic antic',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'escriptura de signes',
 			'Shaw' => 'shavià',
 			'Shrd' => 'shrada',
 			'Sidd' => 'siddham',
 			'Sind' => 'devangari',
 			'Sinh' => 'singalès',
 			'Sora' => 'sora sompeng',
 			'Sund' => 'sundanès',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siríac',
 			'Syre' => 'siríac estrangelo',
 			'Syrj' => 'siríac occidental',
 			'Syrn' => 'siríac oriental',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'nou tai lue',
 			'Taml' => 'tàmil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinag',
 			'Tglg' => 'tagàlog',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandès',
 			'Tibt' => 'tibetà',
 			'Tirh' => 'tirhut',
 			'Ugar' => 'ugarític',
 			'Vaii' => 'vai',
 			'Visp' => 'llenguatge visible',
 			'Wara' => 'varang kshiti',
 			'Wole' => 'woleai',
 			'Xpeo' => 'persa antic',
 			'Xsux' => 'cuneïforme sumeri-accadi',
 			'Yiii' => 'yi',
 			'Zinh' => 'heretat',
 			'Zmth' => 'notació matemàtica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'símbols',
 			'Zxxx' => 'sense escriptura',
 			'Zyyy' => 'comú',
 			'Zzzz' => 'escriptura desconeguda',

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
			'001' => 'Món',
 			'002' => 'Àfrica',
 			'003' => 'Amèrica del Nord',
 			'005' => 'Amèrica del Sud',
 			'009' => 'Oceania',
 			'011' => 'Àfrica occidental',
 			'013' => 'Amèrica Central',
 			'014' => 'Àfrica oriental',
 			'015' => 'Àfrica septentrional',
 			'017' => 'Àfrica central',
 			'018' => 'Àfrica meridional',
 			'019' => 'Amèrica',
 			'021' => 'Amèrica septentrional',
 			'029' => 'Carib',
 			'030' => 'Àsia oriental',
 			'034' => 'Àsia meridional',
 			'035' => 'Àsia sud-oriental',
 			'039' => 'Europa meridional',
 			'053' => 'Australàsia',
 			'054' => 'Melanèsia',
 			'057' => 'Regió de la Micronèsia',
 			'061' => 'Polinèsia',
 			'142' => 'Àsia',
 			'143' => 'Àsia central',
 			'145' => 'Àsia occidental',
 			'150' => 'Europa',
 			'151' => 'Europa oriental',
 			'154' => 'Europa septentrional',
 			'155' => 'Europa occidental',
 			'202' => 'Àfrica subsahariana',
 			'419' => 'Amèrica Llatina',
 			'AC' => 'Illa de l’Ascensió',
 			'AD' => 'Andorra',
 			'AE' => 'Emirats Àrabs Units',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua i Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albània',
 			'AM' => 'Armènia',
 			'AO' => 'Angola',
 			'AQ' => 'Antàrtida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Àustria',
 			'AU' => 'Austràlia',
 			'AW' => 'Aruba',
 			'AX' => 'Illes Åland',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bòsnia i Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bèlgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgària',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermudes',
 			'BN' => 'Brunei',
 			'BO' => 'Bolívia',
 			'BQ' => 'Carib Neerlandès',
 			'BR' => 'Brasil',
 			'BS' => 'Bahames',
 			'BT' => 'Bhutan',
 			'BV' => 'Illa Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarús',
 			'BZ' => 'Belize',
 			'CA' => 'Canadà',
 			'CC' => 'Illes Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'República Democràtica del Congo',
 			'CF' => 'República Centreafricana',
 			'CG' => 'Congo - Brazzaville',
 			'CG@alt=variant' => 'República del Congo',
 			'CH' => 'Suïssa',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Costa d’Ivori',
 			'CK' => 'Illes Cook',
 			'CL' => 'Xile',
 			'CM' => 'Camerun',
 			'CN' => 'Xina',
 			'CO' => 'Colòmbia',
 			'CP' => 'Illa Clipperton',
 			'CQ' => 'Sark',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap Verd',
 			'CW' => 'Curaçao',
 			'CX' => 'Illa Christmas',
 			'CY' => 'Xipre',
 			'CZ' => 'Txèquia',
 			'CZ@alt=variant' => 'República Txeca',
 			'DE' => 'Alemanya',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Algèria',
 			'EA' => 'Ceuta i Melilla',
 			'EC' => 'Equador',
 			'EE' => 'Estònia',
 			'EG' => 'Egipte',
 			'EH' => 'Sàhara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'Espanya',
 			'ET' => 'Etiòpia',
 			'EU' => 'Unió Europea',
 			'EZ' => 'zona euro',
 			'FI' => 'Finlàndia',
 			'FJ' => 'Fiji',
 			'FK' => 'Illes Falkland',
 			'FK@alt=variant' => 'Illes Falkland (Illes Malvines)',
 			'FM' => 'Micronèsia',
 			'FO' => 'Illes Fèroe',
 			'FR' => 'França',
 			'GA' => 'Gabon',
 			'GB' => 'Regne Unit',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Grenada',
 			'GE' => 'Geòrgia',
 			'GF' => 'Guaiana Francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlàndia',
 			'GM' => 'Gàmbia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Equatorial',
 			'GR' => 'Grècia',
 			'GS' => 'Illes Geòrgia del Sud i Sandwich del Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong (RAE Xina)',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Illes Heard i McDonald',
 			'HN' => 'Hondures',
 			'HR' => 'Croàcia',
 			'HT' => 'Haití',
 			'HU' => 'Hongria',
 			'IC' => 'Illes Canàries',
 			'ID' => 'Indonèsia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Illa de Man',
 			'IN' => 'Índia',
 			'IO' => 'Territori Britànic de l’Oceà Índic',
 			'IO@alt=chagos' => 'Illes Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islàndia',
 			'IT' => 'Itàlia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordània',
 			'JP' => 'Japó',
 			'KE' => 'Kenya',
 			'KG' => 'Kirguizstan',
 			'KH' => 'Cambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'Saint Kitts i Nevis',
 			'KP' => 'Corea del Nord',
 			'KR' => 'Corea del Sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Illes Caiman',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Lao',
 			'LB' => 'Líban',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libèria',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituània',
 			'LU' => 'Luxemburg',
 			'LV' => 'Letònia',
 			'LY' => 'Líbia',
 			'MA' => 'Marroc',
 			'MC' => 'Mònaco',
 			'MD' => 'Moldàvia',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Illes Marshall',
 			'MK' => 'Macedònia del Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmània)',
 			'MN' => 'Mongòlia',
 			'MO' => 'Macau (RAE Xina)',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Illes Marianes del Nord',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritània',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurici',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mèxic',
 			'MY' => 'Malàisia',
 			'MZ' => 'Moçambic',
 			'NA' => 'Namíbia',
 			'NC' => 'Nova Caledònia',
 			'NE' => 'Níger',
 			'NF' => 'Illa Norfolk',
 			'NG' => 'Nigèria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Països Baixos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelanda',
 			'NZ@alt=variant' => 'Aotearoa (Nova Zelanda)',
 			'OM' => 'Oman',
 			'PA' => 'Panamà',
 			'PE' => 'Perú',
 			'PF' => 'Polinèsia Francesa',
 			'PG' => 'Papua Nova Guinea',
 			'PH' => 'Filipines',
 			'PK' => 'Pakistan',
 			'PL' => 'Polònia',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Illes Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Territoris palestins',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Qatar',
 			'QO' => 'Territoris allunyats d’Oceania',
 			'RE' => 'Illa de la Reunió',
 			'RO' => 'Romania',
 			'RS' => 'Sèrbia',
 			'RU' => 'Rússia',
 			'RW' => 'Ruanda',
 			'SA' => 'Aràbia Saudí',
 			'SB' => 'Illes Salomó',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Suècia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovènia',
 			'SJ' => 'Svalbard i Jan Mayen',
 			'SK' => 'Eslovàquia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somàlia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudan del Sud',
 			'ST' => 'São Tomé i Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Síria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swazilàndia',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Illes Turks i Caicos',
 			'TD' => 'Txad',
 			'TF' => 'Terres Australs Antàrtiques Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailàndia',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor Oriental',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunísia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquia',
 			'TT' => 'Trinidad i Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzània',
 			'UA' => 'Ucraïna',
 			'UG' => 'Uganda',
 			'UM' => 'Illes Menors Allunyades dels Estats Units',
 			'UN' => 'Nacions Unides',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Estats Units',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Ciutat del Vaticà',
 			'VC' => 'Saint Vincent i les Grenadines',
 			'VE' => 'Veneçuela',
 			'VG' => 'Illes Verges Britàniques',
 			'VI' => 'Illes Verges dels Estats Units',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis i Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudoaccents',
 			'XB' => 'pseudobidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Iemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sud-àfrica',
 			'ZM' => 'Zàmbia',
 			'ZW' => 'Zimbàbue',
 			'ZZ' => 'regió desconeguda',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia alemanya tradicional',
 			'1994' => 'ortografia resiana estandarditzada',
 			'1996' => 'ortografia alemanya de 1996',
 			'1606NICT' => 'francès mitjà tardà fins el 1606',
 			'1694ACAD' => 'francès modern primerenc',
 			'1959ACAD' => 'acadèmica',
 			'ALALC97' => 'romanització ALA/LC, edició de 1997',
 			'ALUKU' => 'dialecte aluku',
 			'AREVELA' => 'armeni oriental',
 			'AREVMDA' => 'armeni occidental',
 			'BAKU1926' => 'alfabet llatí turc unificat',
 			'BAUDDHA' => 'bauddha',
 			'BISCAYAN' => 'basc biscaí',
 			'BISKE' => 'dialecte de San Giorgio/Bila',
 			'BOONT' => 'Boontling',
 			'FONIPA' => 'alfabet fonètic internacional',
 			'FONUPA' => 'sistema fonètic UPA',
 			'FONXSAMP' => 'sistema X-SAMPA',
 			'HEPBURN' => 'romanització Hepburn',
 			'HOGNORSK' => 'høgnorsk',
 			'ITIHASA' => 'itihasa',
 			'JAUER' => 'jauer',
 			'JYUTPING' => 'jyupting',
 			'KKCOR' => 'ortografia comuna',
 			'LAUKIKA' => 'laukika',
 			'LIPAW' => 'dialecte Lipovaz del resià',
 			'LUNA1918' => 'luna 1918',
 			'MONOTON' => 'monotònic',
 			'NDYUKA' => 'dialecte ndyuka',
 			'NEDIS' => 'dialecte de Natisone',
 			'NJIVA' => 'dialecte de Gniva/Njiva',
 			'OSOJS' => 'dialecte d’Oseacco/Osojane',
 			'PAMAKA' => 'dialecte pamaka',
 			'PETR1708' => 'ortografia russa 1708–1917',
 			'PINYIN' => 'romanització Pinyin',
 			'POLYTON' => 'politònic',
 			'POSIX' => 'ordinador',
 			'PUTER' => 'alt engiadinès',
 			'REVISED' => 'ortografia revisada',
 			'ROZAJ' => 'resià',
 			'RUMGR' => 'interomanx',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'anglès estàndard d’Escòcia',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'dialecte de Stolvizza/Solbica',
 			'SURMIRAN' => 'surmiran',
 			'SURSILV' => 'sobreselvà',
 			'SUTSILV' => 'sotaselvà',
 			'TARASK' => 'ortografia taraskievica',
 			'UCCOR' => 'ortografia unificada',
 			'UCRCOR' => 'ortografia revisada unificada',
 			'ULSTER' => 'ulster',
 			'VAIDIKA' => 'vèdic',
 			'VALENCIA' => 'valencià',
 			'VALLADER' => 'baix engiadinès',
 			'WADEGILE' => 'romanització Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendari',
 			'cf' => 'format de moneda',
 			'colalternate' => 'ordre sense tenir en compte els símbols',
 			'colbackwards' => 'ordre per accents invertit',
 			'colcasefirst' => 'ordre per majúscules i minúscules',
 			'colcaselevel' => 'ordre per detecció de majúscules',
 			'collation' => 'ordre',
 			'colnormalization' => 'ordre normalitzat',
 			'colnumeric' => 'ordre numèric',
 			'colstrength' => 'força de l’ordre',
 			'currency' => 'moneda',
 			'hc' => 'sistema horari (12 h o 24 h)',
 			'lb' => 'estil de salt de línia',
 			'ms' => 'sistema de mesures',
 			'numbers' => 'xifres',
 			'timezone' => 'zona horària',
 			'va' => 'variant local',
 			'x' => 'ús privat',

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
 				'buddhist' => q{calendari budista},
 				'chinese' => q{calendari xinès},
 				'coptic' => q{calendari copte},
 				'dangi' => q{calendari dangi},
 				'ethiopic' => q{calendari etíop},
 				'ethiopic-amete-alem' => q{calendari etíop amete-alem},
 				'gregorian' => q{calendari gregorià},
 				'hebrew' => q{calendari hebreu},
 				'indian' => q{calendari hindú},
 				'islamic' => q{calendari islàmic},
 				'islamic-civil' => q{calendari civil islàmic},
 				'islamic-umalqura' => q{calendari islàmic (Umm al-Qura)},
 				'iso8601' => q{calendari ISO-8601},
 				'japanese' => q{calendari japonès},
 				'persian' => q{calendari persa},
 				'roc' => q{calendari de la República de Xina},
 			},
 			'cf' => {
 				'account' => q{format de moneda comptable},
 				'standard' => q{format de moneda estàndard},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordena els símbols},
 				'shifted' => q{Ordena sense tenir en compte els símbols},
 			},
 			'colbackwards' => {
 				'no' => q{Ordena els accents de manera normal},
 				'yes' => q{Ordena amb ordre invers dels accents},
 			},
 			'colcasefirst' => {
 				'lower' => q{Mostra primer les minúscules},
 				'no' => q{Ordena per tipus de lletra normal},
 				'upper' => q{Ordena amb majúscules primer},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordena sense distingir majúscules i minúscules},
 				'yes' => q{Ordena amb detecció de majúscules i minúscules},
 			},
 			'collation' => {
 				'big5han' => q{ordre del xinès tradicional - Big5},
 				'compat' => q{ordre anterior, per a compatibilitat},
 				'dictionary' => q{ordre de diccionari},
 				'ducet' => q{ordre Unicode predeterminat},
 				'eor' => q{normes europees d’ordenació},
 				'gb2312han' => q{ordre del xinès simplificat - GB2312},
 				'phonebook' => q{ordre de la guia telefònica},
 				'phonetic' => q{ordre fonètic},
 				'pinyin' => q{ordre pinyin},
 				'search' => q{cerca de propòsit general},
 				'searchjl' => q{cerca per consonant inicial del hangul},
 				'standard' => q{ordre estàndard},
 				'stroke' => q{ordre dels traços},
 				'traditional' => q{ordre tradicional},
 				'unihan' => q{ordre de traços radicals},
 				'zhuyin' => q{ordre zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Ordena sense normalització},
 				'yes' => q{Ordena per caràcters Unicode normalitzats},
 			},
 			'colnumeric' => {
 				'no' => q{Ordena els dígits individualment},
 				'yes' => q{Ordena els dígits numèricament},
 			},
 			'colstrength' => {
 				'identical' => q{Ordena-ho tot},
 				'primary' => q{Ordena només les lletres de base},
 				'quaternary' => q{Ordena per accents/majúscules/amplada/kana},
 				'secondary' => q{Ordena els accents},
 				'tertiary' => q{Ordena per accent/majúscules/amplada},
 			},
 			'd0' => {
 				'fwidth' => q{amplada completa},
 				'hwidth' => q{amplada mitjana},
 				'npinyin' => q{Numèric},
 			},
 			'hc' => {
 				'h11' => q{sistema de 12 hores (0–11)},
 				'h12' => q{sistema de 12 hores (1–12)},
 				'h23' => q{sistema de 24 hores (0–23)},
 				'h24' => q{sistema de 24 hores (1–24)},
 			},
 			'lb' => {
 				'loose' => q{salt de línia flexible},
 				'normal' => q{salt de línia normal},
 				'strict' => q{salt de línia estricte},
 			},
 			'm0' => {
 				'bgn' => q{sistema de transliteració BGN},
 				'ungegn' => q{sistema de transliteració UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{sistema mètric},
 				'uksystem' => q{sistema imperial d’unitats},
 				'ussystem' => q{sistema d’unitats dels EUA},
 			},
 			'numbers' => {
 				'arab' => q{xifres indoaràbigues},
 				'arabext' => q{xifres indoaràbigues ampliades},
 				'armn' => q{nombres armenis},
 				'armnlow' => q{nombres armenis en minúscula},
 				'bali' => q{dígits balinesos},
 				'beng' => q{dígits bengalins},
 				'cakm' => q{dígits chakma},
 				'cham' => q{dígits txams},
 				'deva' => q{dígits devanagaris},
 				'ethi' => q{nombres etiòpics},
 				'finance' => q{Numerals financers},
 				'fullwide' => q{dígits d’amplada completa},
 				'geor' => q{nombres georgians},
 				'grek' => q{nombres grecs},
 				'greklow' => q{nombres grecs en minúscula},
 				'gujr' => q{dígits gujarati},
 				'guru' => q{dígits gurmukhi},
 				'hanidec' => q{nombres decimals xinesos},
 				'hans' => q{nombres xinesos simplificats},
 				'hansfin' => q{nombres financers xinesos simplificats},
 				'hant' => q{nombres xinesos tradicionals},
 				'hantfin' => q{nombres financers xinesos tradicionals},
 				'hebr' => q{nombres hebreus},
 				'java' => q{dígits javanesos},
 				'jpan' => q{nombres japonesos},
 				'jpanfin' => q{nombres financers japonesos},
 				'kali' => q{dígits kayah},
 				'khmr' => q{dígits khmer},
 				'knda' => q{dígits kannada},
 				'lana' => q{dígits tai tham hora},
 				'lanatham' => q{dígits tai tham tham},
 				'laoo' => q{dígits lao},
 				'latn' => q{dígits aràbics},
 				'lepc' => q{dígits lepcha},
 				'limb' => q{dígits limbu},
 				'mlym' => q{dígits malaiàlam},
 				'mong' => q{dígits mongols},
 				'mtei' => q{dígits meitei mayek},
 				'mymr' => q{dígits de Myanmar},
 				'mymrshan' => q{dígits shan de Myanmar},
 				'native' => q{dígits natius},
 				'nkoo' => q{dígits n’ko},
 				'olck' => q{dígits ol chiki},
 				'orya' => q{dígits oriya},
 				'roman' => q{nombres romans},
 				'romanlow' => q{nombres romans en minúscula},
 				'saur' => q{dígits saurashtra},
 				'sund' => q{dígits sudanesos},
 				'talu' => q{dígits tai lue nous},
 				'taml' => q{nombres tamils tradicionals},
 				'tamldec' => q{dígits tamils},
 				'telu' => q{dígits telugu},
 				'thai' => q{dígits tai},
 				'tibt' => q{dígits tibetans},
 				'traditional' => q{Numerals tradicionals},
 				'vaii' => q{dígits vai},
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
			'metric' => q{mètric},
 			'UK' => q{RU},
 			'US' => q{EUA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Llengua: {0}',
 			'script' => 'Escriptura: {0}',
 			'region' => 'Regió: {0}',

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
			auxiliary => qr{[áăâåäãā æ ĕêëē ìĭîī ŀ ñ ºŏôöøō œ ùŭûū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[· aà b cç d eéè f g h iíï j k l m n oóò p q r s t uúü v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ¡ ? ¿ . … '‘’ "“” « » ( ) \[ \] § @ * / \\ \& # † ‡ ′ ″]},
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
			'word-final' => '{0}…',
			'word-medial' => '{0}… {1}',
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
					# Long Unit Identifier
					'' => {
						'name' => q(punt cardinal),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punt cardinal),
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
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(mil·li{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mil·li{0}),
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
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(quilo{0}),
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
						'name' => q(força G),
						'one' => q({0} força G),
						'other' => q({0} força G),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'name' => q(força G),
						'one' => q({0} força G),
						'other' => q({0} força G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metres per segon al quadrat),
						'one' => q({0} metre per segon al quadrat),
						'other' => q({0} metres per segon al quadrat),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metres per segon al quadrat),
						'one' => q({0} metre per segon al quadrat),
						'other' => q({0} metres per segon al quadrat),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(masculine),
						'name' => q(minuts d’arc),
						'one' => q({0} minut d’arc),
						'other' => q({0} minuts d’arc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(masculine),
						'name' => q(minuts d’arc),
						'one' => q({0} minut d’arc),
						'other' => q({0} minuts d’arc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(masculine),
						'name' => q(segons d’arc),
						'one' => q({0} segon d’arc),
						'other' => q({0} segons d’arc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(masculine),
						'name' => q(segons d’arc),
						'one' => q({0} segon d’arc),
						'other' => q({0} segons d’arc),
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
						'one' => q({0} radiant),
						'other' => q({0} radiants),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'one' => q({0} radiant),
						'other' => q({0} radiants),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(revolució),
						'one' => q({0} revolució),
						'other' => q({0} revolucions),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(revolució),
						'one' => q({0} revolució),
						'other' => q({0} revolucions),
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
						'1' => q(feminine),
						'one' => q({0} hectàrea),
						'other' => q({0} hectàrees),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(feminine),
						'one' => q({0} hectàrea),
						'other' => q({0} hectàrees),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres quadrats),
						'one' => q({0} centímetre quadrat),
						'other' => q({0} centímetres quadrats),
						'per' => q({0} per centímetre quadrat),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres quadrats),
						'one' => q({0} centímetre quadrat),
						'other' => q({0} centímetres quadrats),
						'per' => q({0} per centímetre quadrat),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(peus quadrats),
						'one' => q({0} peu quadrat),
						'other' => q({0} peus quadrats),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(peus quadrats),
						'one' => q({0} peu quadrat),
						'other' => q({0} peus quadrats),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(polzades quadrades),
						'one' => q({0} polzada quadrada),
						'other' => q({0} polzades quadrades),
						'per' => q({0} per polzada quadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(polzades quadrades),
						'one' => q({0} polzada quadrada),
						'other' => q({0} polzades quadrades),
						'per' => q({0} per polzada quadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres quadrats),
						'one' => q({0} quilòmetre quadrat),
						'other' => q({0} quilòmetres quadrats),
						'per' => q({0} per quilòmetre quadrat),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres quadrats),
						'one' => q({0} quilòmetre quadrat),
						'other' => q({0} quilòmetres quadrats),
						'per' => q({0} per quilòmetre quadrat),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(metres quadrats),
						'one' => q({0} metre quadrat),
						'other' => q({0} metres quadrats),
						'per' => q({0} per metre quadrat),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(metres quadrats),
						'one' => q({0} metre quadrat),
						'other' => q({0} metres quadrats),
						'per' => q({0} per metre quadrat),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milles quadrades),
						'one' => q({0} milla quadrada),
						'other' => q({0} milles quadrades),
						'per' => q({0} per milla quadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milles quadrades),
						'one' => q({0} milla quadrada),
						'other' => q({0} milles quadrades),
						'per' => q({0} per milla quadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iardes quadrades),
						'one' => q({0} iarda quadrada),
						'other' => q({0} iardes quadrades),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iardes quadrades),
						'one' => q({0} iarda quadrada),
						'other' => q({0} iardes quadrades),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'one' => q({0} quirat),
						'other' => q({0} quirats),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'one' => q({0} quirat),
						'other' => q({0} quirats),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(mil·ligrams per decilitre),
						'one' => q({0} mil·ligram per decilitre),
						'other' => q({0} mil·ligrams per decilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(mil·ligrams per decilitre),
						'one' => q({0} mil·ligram per decilitre),
						'other' => q({0} mil·ligrams per decilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(mil·limols per litre),
						'one' => q({0} mil·limol per litre),
						'other' => q({0} mil·limols per litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(mil·limols per litre),
						'one' => q({0} mil·limol per litre),
						'other' => q({0} mil·limols per litre),
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
						'one' => q({0} per cent),
						'other' => q({0} per cent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'one' => q({0} per cent),
						'other' => q({0} per cent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'one' => q({0} per mil),
						'other' => q({0} per mil),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'one' => q({0} per mil),
						'other' => q({0} per mil),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(masculine),
						'name' => q(parts per milió),
						'one' => q({0} part per milió),
						'other' => q({0} parts per milió),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(masculine),
						'name' => q(parts per milió),
						'one' => q({0} part per milió),
						'other' => q({0} parts per milió),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'one' => q({0} per deu mil),
						'other' => q({0} per deu mil),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'one' => q({0} per deu mil),
						'other' => q({0} per deu mil),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(masculine),
						'name' => q(part per mil milions),
						'one' => q({0} part per mil milions),
						'other' => q({0} parts per mil milions),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(masculine),
						'name' => q(part per mil milions),
						'one' => q({0} part per mil milions),
						'other' => q({0} parts per mil milions),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres per 100 quilòmetres),
						'one' => q({0} litre per 100 quilòmetres),
						'other' => q({0} litres per 100 quilòmetres),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres per 100 quilòmetres),
						'one' => q({0} litre per 100 quilòmetres),
						'other' => q({0} litres per 100 quilòmetres),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres per quilòmetre),
						'one' => q({0} litre per quilòmetre),
						'other' => q({0} litres per quilòmetre),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres per quilòmetre),
						'one' => q({0} litre per quilòmetre),
						'other' => q({0} litres per quilòmetre),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milles per galó),
						'one' => q({0} milla per galó),
						'other' => q({0} milles per galó),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milles per galó),
						'one' => q({0} milla per galó),
						'other' => q({0} milles per galó),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milles per galó imperial),
						'one' => q({0} milla per galó imperial),
						'other' => q({0} milles per galó imperial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milles per galó imperial),
						'one' => q({0} milla per galó imperial),
						'other' => q({0} milles per galó imperial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} oest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} oest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'name' => q(bits),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'name' => q(bits),
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
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'per' => q({0} per dia),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'per' => q({0} per dia),
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
						'name' => q(dècades),
						'one' => q({0} dècada),
						'other' => q({0} dècades),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'name' => q(dècades),
						'one' => q({0} dècada),
						'other' => q({0} dècades),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'one' => q({0} hora),
						'other' => q({0} hores),
						'per' => q({0} per hora),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'one' => q({0} hora),
						'other' => q({0} hores),
						'per' => q({0} per hora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(masculine),
						'name' => q(microsegons),
						'one' => q({0} microsegon),
						'other' => q({0} microsegons),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(masculine),
						'name' => q(microsegons),
						'one' => q({0} microsegon),
						'other' => q({0} microsegons),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(masculine),
						'one' => q({0} mil·lisegon),
						'other' => q({0} mil·lisegons),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(masculine),
						'one' => q({0} mil·lisegon),
						'other' => q({0} mil·lisegons),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(masculine),
						'name' => q(minuts),
						'one' => q({0} minut),
						'other' => q({0} minuts),
						'per' => q({0} per minut),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(masculine),
						'name' => q(minuts),
						'one' => q({0} minut),
						'other' => q({0} minuts),
						'per' => q({0} per minut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'one' => q({0} mes),
						'other' => q({0} mesos),
						'per' => q({0} per mes),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'one' => q({0} mes),
						'other' => q({0} mesos),
						'per' => q({0} per mes),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanosegons),
						'one' => q({0} nanosegon),
						'other' => q({0} nanosegons),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanosegons),
						'one' => q({0} nanosegon),
						'other' => q({0} nanosegons),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(feminine),
						'name' => q(nits),
						'one' => q({0} nit),
						'other' => q({0} nits),
						'per' => q({0} per nit),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(feminine),
						'name' => q(nits),
						'one' => q({0} nit),
						'other' => q({0} nits),
						'per' => q({0} per nit),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(trimestres),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0} per trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(trimestres),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0} per trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(masculine),
						'name' => q(segons),
						'one' => q({0} segon),
						'other' => q({0} segons),
						'per' => q({0} per segon),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(masculine),
						'name' => q(segons),
						'one' => q({0} segon),
						'other' => q({0} segons),
						'per' => q({0} per segon),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'name' => q(setmanes),
						'one' => q({0} setmana),
						'other' => q({0} setmanes),
						'per' => q({0} per setmana),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'name' => q(setmanes),
						'one' => q({0} setmana),
						'other' => q({0} setmanes),
						'per' => q({0} per setmana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'per' => q({0} per any),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'per' => q({0} per any),
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
						'name' => q(mil·liamperes),
						'one' => q({0} mil·liampere),
						'other' => q({0} mil·liamperes),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'name' => q(mil·liamperes),
						'one' => q({0} mil·liampere),
						'other' => q({0} mil·liamperes),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unitats tèrmiques britàniques),
						'one' => q({0} unitat tèrmica britànica),
						'other' => q({0} unitats tèrmiques britàniques),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unitats tèrmiques britàniques),
						'one' => q({0} unitat tèrmica britànica),
						'other' => q({0} unitats tèrmiques britàniques),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(calories),
						'one' => q({0} caloria),
						'other' => q({0} calories),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(calories),
						'one' => q({0} caloria),
						'other' => q({0} calories),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(electrons-volt),
						'one' => q({0} electró-volt),
						'other' => q({0} electrons-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(electrons-volt),
						'one' => q({0} electró-volt),
						'other' => q({0} electrons-volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(calories),
						'one' => q({0} caloria),
						'other' => q({0} calories),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(calories),
						'one' => q({0} caloria),
						'other' => q({0} calories),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(quilocalories),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalories),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(quilocalories),
						'one' => q({0} quilocaloria),
						'other' => q({0} quilocalories),
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
						'name' => q(quilowatts hora),
						'one' => q({0} quilowatt hora),
						'other' => q({0} quilowatts hora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(quilowatts hora),
						'one' => q({0} quilowatt hora),
						'other' => q({0} quilowatts hora),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(unitats tèrmiques americanes),
						'one' => q({0} unitat tèrmica americana),
						'other' => q({0} unitats tèrmiques americanes),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(unitats tèrmiques americanes),
						'one' => q({0} unitat tèrmica americana),
						'other' => q({0} unitats tèrmiques americanes),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilowatt hora per 100 quilòmetres),
						'one' => q({0} kilowatt hora per 100 quilòmetres),
						'other' => q({0} kilowatts hora per 100 quilòmetres),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilowatt hora per 100 quilòmetres),
						'one' => q({0} kilowatt hora per 100 quilòmetres),
						'other' => q({0} kilowatts hora per 100 quilòmetres),
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
						'name' => q(lliures de força),
						'one' => q({0} lliura de força),
						'other' => q({0} lliures de força),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lliures de força),
						'one' => q({0} lliura de força),
						'other' => q({0} lliures de força),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzs),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzs),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertzs),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertzs),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'name' => q(quilohertz),
						'one' => q({0} quilohertz),
						'other' => q({0} quilohertzs),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'name' => q(quilohertz),
						'one' => q({0} quilohertz),
						'other' => q({0} quilohertzs),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzs),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzs),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} píxel),
						'other' => q({0} píxels),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} píxel),
						'other' => q({0} píxels),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(píxels per centímetre),
						'one' => q({0} píxel per centímetre),
						'other' => q({0} píxels per centímetre),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(píxels per centímetre),
						'one' => q({0} píxel per centímetre),
						'other' => q({0} píxels per centímetre),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(píxels per polzada),
						'one' => q({0} píxel per polzada),
						'other' => q({0} píxels per polzada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(píxels per polzada),
						'one' => q({0} píxel per polzada),
						'other' => q({0} píxels per polzada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(em tipogràfic),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(em tipogràfic),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapíxel),
						'other' => q({0} megapíxels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'one' => q({0} píxel),
						'other' => q({0} píxels),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'one' => q({0} píxel),
						'other' => q({0} píxels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(píxels per centímetre),
						'one' => q({0} píxel per centímetre),
						'other' => q({0} píxels per centímetre),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(píxels per centímetre),
						'one' => q({0} píxel per centímetre),
						'other' => q({0} píxels per centímetre),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(píxels per polzada),
						'one' => q({0} píxel per polzada),
						'other' => q({0} píxels per polzada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(píxels per polzada),
						'one' => q({0} píxel per polzada),
						'other' => q({0} píxels per polzada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unitats astronòmiques),
						'one' => q({0} unitat astronòmica),
						'other' => q({0} unitats astronòmiques),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unitats astronòmiques),
						'one' => q({0} unitat astronòmica),
						'other' => q({0} unitats astronòmiques),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres),
						'one' => q({0} centímetre),
						'other' => q({0} centímetres),
						'per' => q({0} per centímetre),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres),
						'one' => q({0} centímetre),
						'other' => q({0} centímetres),
						'per' => q({0} per centímetre),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(decímetres),
						'one' => q({0} decímetre),
						'other' => q({0} decímetres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(decímetres),
						'one' => q({0} decímetre),
						'other' => q({0} decímetres),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radi terrestre),
						'one' => q({0} radi terrestre),
						'other' => q({0} radis terrestres),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radi terrestre),
						'one' => q({0} radi terrestre),
						'other' => q({0} radis terrestres),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(braces),
						'one' => q({0} braça),
						'other' => q({0} braces),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(braces),
						'one' => q({0} braça),
						'other' => q({0} braces),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} peu),
						'other' => q({0} peus),
						'per' => q({0} per peu),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} peu),
						'other' => q({0} peus),
						'per' => q({0} per peu),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(estadis),
						'one' => q({0} estadi),
						'other' => q({0} estadis),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(estadis),
						'one' => q({0} estadi),
						'other' => q({0} estadis),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} polzada),
						'other' => q({0} polzades),
						'per' => q({0} per polzada),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} polzada),
						'other' => q({0} polzades),
						'per' => q({0} per polzada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres),
						'one' => q({0} quilòmetre),
						'other' => q({0} quilòmetres),
						'per' => q({0} per quilòmetre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres),
						'one' => q({0} quilòmetre),
						'other' => q({0} quilòmetres),
						'per' => q({0} per quilòmetre),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} any llum),
						'other' => q({0} anys llum),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} any llum),
						'other' => q({0} anys llum),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(metres),
						'one' => q({0} metre),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(metres),
						'one' => q({0} metre),
						'other' => q({0} metres),
						'per' => q({0} per metre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(micròmetres),
						'one' => q({0} micròmetre),
						'other' => q({0} micròmetres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(micròmetres),
						'one' => q({0} micròmetre),
						'other' => q({0} micròmetres),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} milla),
						'other' => q({0} milles),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milla),
						'other' => q({0} milles),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(milles escandinaves),
						'one' => q({0} milla escandinava),
						'other' => q({0} milles escandinaves),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(milles escandinaves),
						'one' => q({0} milla escandinava),
						'other' => q({0} milles escandinaves),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(mil·límetres),
						'one' => q({0} mil·límetre),
						'other' => q({0} mil·límetres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(mil·límetres),
						'one' => q({0} mil·límetre),
						'other' => q({0} mil·límetres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanòmetre),
						'one' => q({0} nanòmetre),
						'other' => q({0} nanòmetres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanòmetre),
						'one' => q({0} nanòmetre),
						'other' => q({0} nanòmetres),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milles nàutiques),
						'one' => q({0} milla nàutica),
						'other' => q({0} milles nàutiques),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milles nàutiques),
						'one' => q({0} milla nàutica),
						'other' => q({0} milles nàutiques),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(picòmetres),
						'one' => q({0} picòmetre),
						'other' => q({0} picòmetres),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(picòmetres),
						'one' => q({0} picòmetre),
						'other' => q({0} picòmetres),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(masculine),
						'one' => q({0} punt tipogràfic),
						'other' => q({0} punts tipogràfics),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(masculine),
						'one' => q({0} punt tipogràfic),
						'other' => q({0} punts tipogràfics),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radis solars),
						'one' => q({0} radi solar),
						'other' => q({0} radis solars),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radis solars),
						'one' => q({0} radi solar),
						'other' => q({0} radis solars),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} iarda),
						'other' => q({0} iardes),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} iarda),
						'other' => q({0} iardes),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candeles),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candeles),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumens),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'one' => q({0} lux),
						'other' => q({0} luxs),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'one' => q({0} lux),
						'other' => q({0} luxs),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} lluminositat solar),
						'other' => q({0} lluminositats solars),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} lluminositat solar),
						'other' => q({0} lluminositats solars),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'name' => q(quirats),
						'one' => q({0} quirat),
						'other' => q({0} quirats),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'name' => q(quirats),
						'one' => q({0} quirat),
						'other' => q({0} quirats),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masses de la Terra),
						'one' => q({0} massa de la Terra),
						'other' => q({0} masses de la Terra),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masses de la Terra),
						'one' => q({0} massa de la Terra),
						'other' => q({0} masses de la Terra),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grans),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grans),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'one' => q({0} gram),
						'other' => q({0} grams),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'one' => q({0} gram),
						'other' => q({0} grams),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(quilograms),
						'one' => q({0} quilogram),
						'other' => q({0} quilograms),
						'per' => q({0} per quilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(quilograms),
						'one' => q({0} quilogram),
						'other' => q({0} quilograms),
						'per' => q({0} per quilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'name' => q(micrograms),
						'one' => q({0} microgram),
						'other' => q({0} micrograms),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(mil·ligrams),
						'one' => q({0} mil·ligram),
						'other' => q({0} mil·ligrams),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(mil·ligrams),
						'one' => q({0} mil·ligram),
						'other' => q({0} mil·ligrams),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unces),
						'one' => q({0} unça),
						'other' => q({0} unces),
						'per' => q({0} per unça),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unces),
						'one' => q({0} unça),
						'other' => q({0} unces),
						'per' => q({0} per unça),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(unces troy),
						'one' => q({0} unça troy),
						'other' => q({0} unces troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(unces troy),
						'one' => q({0} unça troy),
						'other' => q({0} unces troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lliures),
						'one' => q({0} lliura),
						'other' => q({0} lliures),
						'per' => q({0} per lliura),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lliures),
						'one' => q({0} lliura),
						'other' => q({0} lliures),
						'per' => q({0} per lliura),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masses solars),
						'one' => q({0} massa solar),
						'other' => q({0} masses solars),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masses solars),
						'one' => q({0} massa solar),
						'other' => q({0} masses solars),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(pedres),
						'one' => q({0} pedra),
						'other' => q({0} pedres),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(pedres),
						'one' => q({0} pedra),
						'other' => q({0} pedres),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tones),
						'one' => q({0} tona),
						'other' => q({0} tones),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tones),
						'one' => q({0} tona),
						'other' => q({0} tones),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(tones mètriques),
						'one' => q({0} tona mètrica),
						'other' => q({0} tones mètriques),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(tones mètriques),
						'one' => q({0} tona mètrica),
						'other' => q({0} tones mètriques),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
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
						'name' => q(cavalls de vapor),
						'one' => q({0} cavall de vapor),
						'other' => q({0} cavalls de vapor),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavalls de vapor),
						'one' => q({0} cavall de vapor),
						'other' => q({0} cavalls de vapor),
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
						'name' => q(mil·liwatts),
						'one' => q({0} mil·liwatt),
						'other' => q({0} mil·liwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'name' => q(mil·liwatts),
						'one' => q({0} mil·liwatt),
						'other' => q({0} mil·liwatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} quadrats),
						'one' => q({0} quadrat),
						'other' => q({0} quadrats),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} quadrats),
						'one' => q({0} quadrat),
						'other' => q({0} quadrats),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} cúbics),
						'one' => q({0} cúbic),
						'other' => q({0} cúbics),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} cúbics),
						'one' => q({0} cúbic),
						'other' => q({0} cúbics),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosferes),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferes),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosferes),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferes),
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
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(polzades de mercuri),
						'one' => q({0} polzada de mercuri),
						'other' => q({0} polzades de mercuri),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(polzades de mercuri),
						'one' => q({0} polzada de mercuri),
						'other' => q({0} polzades de mercuri),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(quilopascals),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascals),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(quilopascals),
						'one' => q({0} quilopascal),
						'other' => q({0} quilopascals),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascals),
						'one' => q({0} megapascal),
						'other' => q({0} megapascals),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascals),
						'one' => q({0} megapascal),
						'other' => q({0} megapascals),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'name' => q(mil·libars),
						'one' => q({0} mil·libar),
						'other' => q({0} mil·libars),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'name' => q(mil·libars),
						'one' => q({0} mil·libar),
						'other' => q({0} mil·libars),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(mil·límetres de mercuri),
						'one' => q({0} mil·límetre de mercuri),
						'other' => q({0} mil·límetres de mercuri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(mil·límetres de mercuri),
						'one' => q({0} mil·límetre de mercuri),
						'other' => q({0} mil·límetres de mercuri),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'name' => q(pascals),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'name' => q(pascals),
						'one' => q({0} pascal),
						'other' => q({0} pascals),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(lliures per polzada quadrada),
						'one' => q({0} lliura per polzada quadrada),
						'other' => q({0} lliures per polzada quadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(lliures per polzada quadrada),
						'one' => q({0} lliura per polzada quadrada),
						'other' => q({0} lliures per polzada quadrada),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(quilòmetres per hora),
						'one' => q({0} quilòmetre per hora),
						'other' => q({0} quilòmetres per hora),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(quilòmetres per hora),
						'one' => q({0} quilòmetre per hora),
						'other' => q({0} quilòmetres per hora),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nusos),
						'one' => q({0} nus),
						'other' => q({0} nusos),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nusos),
						'one' => q({0} nus),
						'other' => q({0} nusos),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'1' => q(feminine),
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
					},
					# Core Unit Identifier
					'light-speed' => {
						'1' => q(feminine),
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metres per segon),
						'one' => q({0} metre per segon),
						'other' => q({0} metres per segon),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metres per segon),
						'one' => q({0} metre per segon),
						'other' => q({0} metres per segon),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milles per hora),
						'one' => q({0} milla per hora),
						'other' => q({0} milles per hora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milles per hora),
						'one' => q({0} milla per hora),
						'other' => q({0} milles per hora),
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
						'name' => q(graus Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graus Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(graus Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graus Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'name' => q(grau),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'name' => q(grau),
						'one' => q({0} grau),
						'other' => q({0} graus),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtons-metre),
						'one' => q({0} newton-metre),
						'other' => q({0} newtons-metre),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtons-metre),
						'one' => q({0} newton-metre),
						'other' => q({0} newtons-metre),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lliures-peu),
						'one' => q({0} lliura-peu),
						'other' => q({0} lliures-peu),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lliures-peu),
						'one' => q({0} lliura-peu),
						'other' => q({0} lliures-peu),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-peu),
						'one' => q({0} acre-peu),
						'other' => q({0} acres-peus),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-peu),
						'one' => q({0} acre-peu),
						'other' => q({0} acres-peus),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barrils),
						'one' => q({0} barril),
						'other' => q({0} barrils),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barrils),
						'one' => q({0} barril),
						'other' => q({0} barrils),
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
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres cúbics),
						'one' => q({0} centímetre cúbic),
						'other' => q({0} centímetres cúbics),
						'per' => q({0} per centímetre cúbic),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centímetres cúbics),
						'one' => q({0} centímetre cúbic),
						'other' => q({0} centímetres cúbics),
						'per' => q({0} per centímetre cúbic),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(peus cúbics),
						'one' => q({0} peu cúbic),
						'other' => q({0} peus cúbics),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(peus cúbics),
						'one' => q({0} peu cúbic),
						'other' => q({0} peus cúbics),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(polzades cúbiques),
						'one' => q({0} polzada cúbica),
						'other' => q({0} polzades cúbiques),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(polzades cúbiques),
						'one' => q({0} polzada cúbica),
						'other' => q({0} polzades cúbiques),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres cúbics),
						'one' => q({0} quilòmetre cúbic),
						'other' => q({0} quilòmetres cúbics),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(quilòmetres cúbics),
						'one' => q({0} quilòmetre cúbic),
						'other' => q({0} quilòmetres cúbics),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metres cúbics),
						'one' => q({0} metre cúbic),
						'other' => q({0} metres cúbics),
						'per' => q({0} per metre cúbic),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metres cúbics),
						'one' => q({0} metre cúbic),
						'other' => q({0} metres cúbics),
						'per' => q({0} per metre cúbic),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milles cúbiques),
						'one' => q({0} milla cúbica),
						'other' => q({0} milles cúbiques),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milles cúbiques),
						'one' => q({0} milla cúbica),
						'other' => q({0} milles cúbiques),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iardes cúbiques),
						'one' => q({0} iarda cúbica),
						'other' => q({0} iardes cúbiques),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iardes cúbiques),
						'one' => q({0} iarda cúbica),
						'other' => q({0} iardes cúbiques),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tasses),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tasses),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(tasses mètriques),
						'one' => q({0} tassa mètrica),
						'other' => q({0} tasses mètriques),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(tasses mètriques),
						'one' => q({0} tassa mètrica),
						'other' => q({0} tasses mètriques),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitres),
						'one' => q({0} decilitre),
						'other' => q({0} decilitres),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitres),
						'one' => q({0} decilitre),
						'other' => q({0} decilitres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(culleradeta de postres),
						'one' => q({0} culleradeta de postres),
						'other' => q({0} culleradetes de postres),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(culleradeta de postres),
						'one' => q({0} culleradeta de postres),
						'other' => q({0} culleradetes de postres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(culleradeta de postres imperial),
						'one' => q({0} culleradeta de postres imperial),
						'other' => q({0} culleradetes de postres imperials),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(culleradeta de postres imperial),
						'one' => q({0} culleradeta de postres imperial),
						'other' => q({0} culleradetes de postres imperials),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma),
						'one' => q({0} dracma),
						'other' => q({0} dracmes),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma),
						'one' => q({0} dracma),
						'other' => q({0} dracmes),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gotes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gotes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(unces líquides),
						'one' => q({0} unça líquida),
						'other' => q({0} unces líquides),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(unces líquides),
						'one' => q({0} unça líquida),
						'other' => q({0} unces líquides),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(unces líquides imperials),
						'one' => q({0} unça líquida imperial),
						'other' => q({0} unces líquides imperials),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(unces líquides imperials),
						'one' => q({0} unça líquida imperial),
						'other' => q({0} unces líquides imperials),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galons),
						'one' => q({0} galó),
						'other' => q({0} galons),
						'per' => q({0} per galó),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galons),
						'one' => q({0} galó),
						'other' => q({0} galons),
						'per' => q({0} per galó),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galons imperials),
						'one' => q({0} galó imperial),
						'other' => q({0} galons imperials),
						'per' => q({0} per galó imperial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galons imperials),
						'one' => q({0} galó imperial),
						'other' => q({0} galons imperials),
						'per' => q({0} per galó imperial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(mesuradors de cocteleria),
						'one' => q({0} mesurador de cocteleria),
						'other' => q({0} mesuradors de cocteleria),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(mesuradors de cocteleria),
						'one' => q({0} mesurador de cocteleria),
						'other' => q({0} mesuradors de cocteleria),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} per litre),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitres),
						'one' => q({0} megalitre),
						'other' => q({0} megalitres),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitres),
						'one' => q({0} megalitre),
						'other' => q({0} megalitres),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(mil·lilitres),
						'one' => q({0} mil·lilitre),
						'other' => q({0} mil·lilitres),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(mil·lilitres),
						'one' => q({0} mil·lilitre),
						'other' => q({0} mil·lilitres),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pessics),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pessics),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pintes),
						'one' => q({0} pinta),
						'other' => q({0} pintes),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pintes),
						'one' => q({0} pinta),
						'other' => q({0} pintes),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintes mètriques),
						'one' => q({0} pinta mètrica),
						'other' => q({0} pintes mètriques),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintes mètriques),
						'one' => q({0} pinta mètrica),
						'other' => q({0} pintes mètriques),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(quarts imperials),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quarts imperials),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cullerades),
						'one' => q({0} cullerada),
						'other' => q({0} cullerades),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cullerades),
						'one' => q({0} cullerada),
						'other' => q({0} cullerades),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(culleradetes),
						'one' => q({0} culleradeta),
						'other' => q({0} culleradetes),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(culleradetes),
						'one' => q({0} culleradeta),
						'other' => q({0} culleradetes),
					},
				},
				'narrow' => {
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
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
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
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre),
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
						'name' => q(hectàrea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectàrea),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metres²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metres²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(quirat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quirat),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mM/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mM/l),
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
						'name' => q(dia),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dia),
						'one' => q({0} d),
						'other' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
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
						'name' => q(mes),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mes),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nit),
						'one' => q({0}/nit),
						'other' => q({0}/nit),
						'per' => q({0}/nit),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nit),
						'one' => q({0}/nit),
						'other' => q({0}/nit),
						'per' => q({0}/nit),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/any),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/any),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm),
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
						'name' => q(píxel),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(píxel),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mpx),
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
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} a. ll.),
						'other' => q({0} a. ll.),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} a. ll.),
						'other' => q({0} a. ll.),
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
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(t),
						'one' => q({0} t m),
						'other' => q({0} t m),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(t),
						'one' => q({0} t m),
						'other' => q({0} t m),
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
					'speed-light-speed' => {
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
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
					'volume-bushel' => {
						'name' => q(bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bu),
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
					'volume-dessert-spoon' => {
						'name' => q(c. postres),
						'one' => q({0} c. postr.),
						'other' => q({0} c. postr.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(c. postres),
						'one' => q({0} c. postr.),
						'other' => q({0} c. postr.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(mes.),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(mes.),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt imp),
						'one' => q({0} qt imp),
						'other' => q({0} qt imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt imp),
						'one' => q({0} qt imp),
						'other' => q({0} qt imp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punt),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punt),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} arcmin),
						'other' => q({0} arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} arcsec),
						'other' => q({0} arcsec),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graus),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graus),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiants),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiants),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(r),
						'one' => q({0} r),
						'other' => q({0} r),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(r),
						'one' => q({0} r),
						'other' => q({0} r),
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
						'name' => q(hectàrees),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectàrees),
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
						'name' => q(quirats),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(quirats),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mil·limols/litre),
						'one' => q({0} mM/l),
						'other' => q({0} mM/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mil·limols/litre),
						'one' => q({0} mM/l),
						'other' => q({0} mM/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(per cent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(per cent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(per mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(per mil),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(parts/milió),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(parts/milió),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(per deu mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(per deu mil),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(part/mil milions),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(part/mil milions),
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
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
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
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(segles),
						'one' => q({0} segle),
						'other' => q({0} segles),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(segles),
						'one' => q({0} segle),
						'other' => q({0} segles),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(dies),
						'one' => q({0} dia),
						'other' => q({0} dies),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(dies),
						'one' => q({0} dia),
						'other' => q({0} dies),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dèc.),
						'one' => q({0} dèc.),
						'other' => q({0} dèc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dèc.),
						'one' => q({0} dèc.),
						'other' => q({0} dèc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hores),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hores),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mil·lisegons),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mil·lisegons),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mesos),
						'one' => q({0} mes),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mesos),
						'one' => q({0} mes),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nits),
						'one' => q({0} nit),
						'other' => q({0} nits),
						'per' => q({0}/nit),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nits),
						'one' => q({0} nit),
						'other' => q({0} nits),
						'per' => q({0}/nit),
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
						'name' => q(setm.),
						'one' => q({0} setm.),
						'other' => q({0} setm.),
						'per' => q({0}/setm.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(setm.),
						'one' => q({0} setm.),
						'other' => q({0} setm.),
						'per' => q({0}/setm.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anys),
						'one' => q({0} any),
						'other' => q({0} anys),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anys),
						'one' => q({0} any),
						'other' => q({0} anys),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
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
						'name' => q(J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(unitat tèrmica americana),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(unitat tèrmica americana),
						'one' => q({0} thm),
						'other' => q({0} thm),
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
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lliures-força),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lliures-força),
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
					'graphics-megapixel' => {
						'name' => q(megapíxels),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapíxels),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(píxels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(píxels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(píxels per cm),
						'one' => q({0} píxel per cm),
						'other' => q({0} píxels per cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(píxels per cm),
						'one' => q({0} píxel per cm),
						'other' => q({0} píxels per cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(PPI),
						'one' => q({0} PPI),
						'other' => q({0} PPI),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(PPI),
						'one' => q({0} PPI),
						'other' => q({0} PPI),
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
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(peus),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(peus),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(polzades),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(polzades),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anys llum),
						'one' => q({0} any ll.),
						'other' => q({0} anys ll.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anys llum),
						'one' => q({0} any ll.),
						'other' => q({0} anys ll.),
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
						'name' => q(milles),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milles),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
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
						'name' => q(punts),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punts),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iardes),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iardes),
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
						'name' => q(lluminositats solars),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(lluminositats solars),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(quirat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(quirat),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gra),
						'one' => q({0} gra),
						'other' => q({0} grans),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gra),
						'one' => q({0} gra),
						'other' => q({0} grans),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grams),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grams),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(t mètr.),
						'one' => q({0} t m),
						'other' => q({0} t mètr.),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(t mètr.),
						'one' => q({0} t m),
						'other' => q({0} t mètr.),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
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
					'speed-light-speed' => {
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(llum),
						'one' => q({0} llum),
						'other' => q({0} llum),
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
					'volume-cup' => {
						'name' => q(tassa),
						'one' => q({0} tassa),
						'other' => q({0} tasses),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tassa),
						'one' => q({0} tassa),
						'other' => q({0} tasses),
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
						'name' => q(culleradeta postres),
						'one' => q({0} culleradeta postres),
						'other' => q({0} culleradetes postres),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(culleradeta postres),
						'one' => q({0} culleradeta postres),
						'other' => q({0} culleradetes postres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(cull. postres imp.),
						'one' => q({0} cull. postres imp.),
						'other' => q({0} cull. postres imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(cull. postres imp.),
						'one' => q({0} cull. postres imp.),
						'other' => q({0} cull. postres imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dracma fluid),
						'one' => q({0} dracma fluid),
						'other' => q({0} dracmes fluids),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dracma fluid),
						'one' => q({0} dracma fluid),
						'other' => q({0} dracmes fluids),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotes),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'one' => q({0} gota),
						'other' => q({0} gotes),
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
						'name' => q(mesurador),
						'one' => q({0} mesurador),
						'other' => q({0} mesuradors),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(mesurador),
						'one' => q({0} mesurador),
						'other' => q({0} mesuradors),
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
						'name' => q(pessic),
						'one' => q({0} pessic),
						'other' => q({0} pessics),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pessic),
						'one' => q({0} pessic),
						'other' => q({0} pessics),
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
					'volume-quart-imperial' => {
						'name' => q(quart imperial),
						'one' => q({0} quart imperial),
						'other' => q({0} quarts imperials),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(quart imperial),
						'one' => q({0} quart imperial),
						'other' => q({0} quarts imperials),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cull.),
						'one' => q({0} cull.),
						'other' => q({0} cull.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cull.),
						'one' => q({0} cull.),
						'other' => q({0} cull.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cdta.),
						'one' => q({0} cdta.),
						'other' => q({0} cdta.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cdta.),
						'one' => q({0} cdta.),
						'other' => q({0} cdta.),
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
	default		=> sub { qr'^(?i:|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} i {1}),
				2 => q({0} i {1}),
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
					'one' => '0 miler',
					'other' => '0 milers',
				},
				'10000' => {
					'one' => '00 milers',
					'other' => '00 milers',
				},
				'100000' => {
					'one' => '000 milers',
					'other' => '000 milers',
				},
				'1000000' => {
					'one' => '0 milió',
					'other' => '0 milions',
				},
				'10000000' => {
					'one' => '00 milions',
					'other' => '00 milions',
				},
				'100000000' => {
					'one' => '000 milions',
					'other' => '000 milions',
				},
				'1000000000' => {
					'one' => '0 miler de milions',
					'other' => '0 milers de milions',
				},
				'10000000000' => {
					'one' => '00 milers de milions',
					'other' => '00 milers de milions',
				},
				'100000000000' => {
					'one' => '000 milers de milions',
					'other' => '000 milers de milions',
				},
				'1000000000000' => {
					'one' => '0 bilió',
					'other' => '0 bilions',
				},
				'10000000000000' => {
					'one' => '00 bilions',
					'other' => '00 bilions',
				},
				'100000000000000' => {
					'one' => '000 bilions',
					'other' => '000 bilions',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 k',
					'other' => '0 k',
				},
				'10000' => {
					'one' => '00 k',
					'other' => '00 k',
				},
				'100000' => {
					'one' => '000 k',
					'other' => '000 k',
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
					'one' => '00 kM',
					'other' => '00 kM',
				},
				'100000000000' => {
					'one' => '000 kM',
					'other' => '000 kM',
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
		'ADP' => {
			display_name => {
				'currency' => q(pesseta andorrana),
				'one' => q(pesseta andorrana),
				'other' => q(pessetes andorranes),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dírham dels Emirats Àrabs Units),
				'one' => q(dírham dels Emirats Àrabs Units),
				'other' => q(dírhams dels Emirats Àrabs Units),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgani afganès \(1927–2002\)),
				'one' => q(afgani afganès \(1927–2002\)),
				'other' => q(afganis afganesos \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgani afganès),
				'one' => q(afgani afganès),
				'other' => q(afganis afganesos),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanès \(1946–1965\)),
				'one' => q(lek albanès \(1946–1965\)),
				'other' => q(lekë albanesos \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek),
				'one' => q(lek),
				'other' => q(lekë),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram),
				'one' => q(dram),
				'other' => q(drams),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florí de les Antilles Neerlandeses),
				'one' => q(florí de les Antilles Neerlandeses),
				'other' => q(florins de les Antilles Neerlandeses),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolès),
				'one' => q(kwanza angolès),
				'other' => q(kwanzas angolesos),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolès \(1977–1991\)),
				'one' => q(kwanza angolès \(1977–1991\)),
				'other' => q(kwanzas angolesos \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nou kwanza angolès \(1990–2000\)),
				'one' => q(nou kwanza angolès \(1990–2000\)),
				'other' => q(nous kwanzas angolesos \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolès reajustat \(1995–1999\)),
				'one' => q(kwanza angolès reajustat \(1995–1999\)),
				'other' => q(kwanzas angolesos \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentí),
				'one' => q(austral argentí),
				'other' => q(australs argentins),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(peso ley argentí \(1970–1983\)),
				'one' => q(peso ley argentí \(1970–1983\)),
				'other' => q(pesos ley argentins \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso argentí \(1981–1970\)),
				'one' => q(peso argentí moneda nacional),
				'other' => q(pesos argentins moneda nacional),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentí \(1983–1985\)),
				'one' => q(peso argentí \(1983–1985\)),
				'other' => q(pesos argentins \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentí),
				'one' => q(peso argentí),
				'other' => q(pesos argentins),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(xíling austríac),
				'one' => q(xíling austríac),
				'other' => q(xílings austríacs),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(dòlar australià),
				'one' => q(dòlar australià),
				'other' => q(dòlars australians),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florí d’Aruba),
				'one' => q(florí d’Aruba),
				'other' => q(florins d’Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azerbaidjanès \(1993–2006\)),
				'one' => q(manat azerbaidjanès \(1993–2006\)),
				'other' => q(manats azerbaidjanesos \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azerbaidjanès),
				'one' => q(manat azerbaidjanès),
				'other' => q(manats azerbaidjanesos),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar de Bòsnia i Hercegovina \(1992–1994\)),
				'one' => q(dinar de Bòsnia i Hercegovina \(1992–1994\)),
				'other' => q(dinars de Bòsnia i Hercegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marc convertible de Bòsnia i Hercegovina),
				'one' => q(marc convertible de Bòsnia i Hercegovina),
				'other' => q(marcs convertibles de Bòsnia i Hercegovina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nou dinar de Bòsnia i Hercegovina \(1994–1997\)),
				'one' => q(nou dinar de Bòsnia i Hercegovina \(1994–1997\)),
				'other' => q(nous dinars de Bòsnia i Hercegovina \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dòlar de Barbados),
				'one' => q(dòlar de Barbados),
				'other' => q(dòlars de Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franc belga \(convertible\)),
				'one' => q(franc belga \(convertible\)),
				'other' => q(francs belgues \(convertibles\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franc belga),
				'one' => q(franc belga),
				'other' => q(francs belgues),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franc belga \(financer\)),
				'one' => q(franc belga \(financer\)),
				'other' => q(francs belgues \(financers\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev fort búlgar),
				'one' => q(lev fort búlgar),
				'other' => q(leva forts búlgars),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev socialista búlgar),
				'one' => q(lev socialista búlgar),
				'other' => q(leva socialistes búlgars),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev),
				'one' => q(lev),
				'other' => q(leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(lev búlgar \(1879–1952\)),
				'one' => q(lev búlgar \(1879–1952\)),
				'other' => q(leva búlgars \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar de Bahrain),
				'one' => q(dinar de Bahrain),
				'other' => q(dinars de Bahrain),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc de Burundi),
				'one' => q(franc de Burundi),
				'other' => q(francs de Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dòlar de les Bermudes),
				'one' => q(dòlar de les Bermudes),
				'other' => q(dòlars de les Bermudes),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dòlar de Brunei),
				'one' => q(dòlar de Brunei),
				'other' => q(dòlars de Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivià),
				'one' => q(bolivià),
				'other' => q(bolivians),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviano bolivià \(1863–1963\)),
				'one' => q(boliviano bolivià \(1863–1963\)),
				'other' => q(bolivianos bolivians \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso bolivià),
				'one' => q(peso bolivià),
				'other' => q(pesos bolivians),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(MVDOL bolivià),
				'one' => q(MVDOL bolivià),
				'other' => q(MVDOL bolivians),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(cruzeiro novo brasiler \(1967–1986\)),
				'one' => q(cruzeiro novo brasiler \(1967–1986\)),
				'other' => q(cruzeiros novos brasilers \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brasiler),
				'one' => q(cruzado brasiler),
				'other' => q(cruzados brasilers),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brasiler \(1990–1993\)),
				'one' => q(cruzeiro brasiler \(1990–1993\)),
				'other' => q(cruzeiros brasilers \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real brasiler),
				'one' => q(real brasiler),
				'other' => q(reals brasilers),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(cruzado novo brasiler),
				'one' => q(cruzado novo brasiler),
				'other' => q(cruzados novos brasilers),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brasiler),
				'one' => q(cruzeiro brasiler),
				'other' => q(cruzeiros brasilers),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(antic cruzeiro brasiler),
				'one' => q(antic cruzeiro brasiler),
				'other' => q(antics cruzeiros brasilers),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dòlar de les Bahames),
				'one' => q(dòlar de les Bahames),
				'other' => q(dòlars de les Bahames),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum de Bhutan),
				'one' => q(ngultrum de Bhutan),
				'other' => q(ngultrums de Bhutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birmà),
				'one' => q(kyat birmà),
				'other' => q(kyats birmans),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula de Botswana),
				'one' => q(pula de Botswana),
				'other' => q(pules de Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nou ruble bielorús \(1994–1999\)),
				'one' => q(nou ruble bielorús \(1994–1999\)),
				'other' => q(nous rubles bielorussos \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(ruble belarús),
				'one' => q(ruble belarús),
				'other' => q(rubles belarussos),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(ruble bielorús \(2000–2016\)),
				'one' => q(ruble bielorús \(2000–2016\)),
				'other' => q(rubles bielorussos \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dòlar de Belize),
				'one' => q(dòlar de Belize),
				'other' => q(dòlars de Belize),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(dòlar canadenc),
				'one' => q(dòlar canadenc),
				'other' => q(dòlars canadencs),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolès),
				'one' => q(franc congolès),
				'other' => q(francs congolesos),
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
			display_name => {
				'currency' => q(franc suís),
				'one' => q(franc suís),
				'other' => q(francs suïssos),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(franc WIR),
				'one' => q(franc WIR),
				'other' => q(francs WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(escut xilè),
				'one' => q(escudo xilè),
				'other' => q(escudos xilens),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unidad de fomento xilena),
				'one' => q(unidad de fomento xilena),
				'other' => q(unidades de fomento xilenes),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso xilè),
				'one' => q(peso xilè),
				'other' => q(pesos xilens),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(iuan xinès extracontinental),
				'one' => q(iuan xinès extracontinental),
				'other' => q(iuans xinesos extracontinentals),
			},
		},
		'CNX' => {
			display_name => {
				'one' => q(dòlar del Banc Popular Xinès),
				'other' => q(dòlars del Banc Popular Xinès),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(iuan),
				'one' => q(iuan),
				'other' => q(iuans),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombià),
				'one' => q(peso colombià),
				'other' => q(pesos colombians),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unidad de valor real colombiana),
				'one' => q(unidad de valor real colombiana),
				'other' => q(unidades de valor real colombianes),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colon costa-riqueny),
				'one' => q(colon costa-riqueny),
				'other' => q(colons costa-riquenys),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar serbi antic),
				'one' => q(dinar serbi antic),
				'other' => q(dinars serbis antics),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(corona forta txecoslovaca),
				'one' => q(corona forta txecoslovaca),
				'other' => q(corones fortes txecoslovaques),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso convertible cubà),
				'one' => q(peso convertible cubà),
				'other' => q(pesos convertibles cubans),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubà),
				'one' => q(peso cubà),
				'other' => q(pesos cubans),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escut de Cap Verd),
				'one' => q(escut de Cap Verd),
				'other' => q(escuts de Cap Verd),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(lliura xipriota),
				'one' => q(lliura xipriota),
				'other' => q(lliures xipriotes),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona txeca),
				'one' => q(corona txeca),
				'other' => q(corones txeques),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(marc de l’Alemanya Oriental),
				'one' => q(marc de l’Alemanya Oriental),
				'other' => q(marcs de l’Alemanya Oriental),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marc alemany),
				'one' => q(marc alemany),
				'other' => q(marcs alemanys),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc de Djibouti),
				'one' => q(franc de Djibouti),
				'other' => q(francs de Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona danesa),
				'one' => q(corona danesa),
				'other' => q(corones daneses),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominicà),
				'one' => q(peso dominicà),
				'other' => q(pesos dominicans),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algerià),
				'one' => q(dinar algerià),
				'other' => q(dinars algerians),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre equatorià),
				'one' => q(sucre equatorià),
				'other' => q(sucres equatorians),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unidad de valor constante \(UVC\) equatoriana),
				'one' => q(unidad de valor constante \(UVC\) equatoriana),
				'other' => q(unidades de valor constante \(UVC\) equatorianes),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(corona estoniana),
				'one' => q(corona estoniana),
				'other' => q(corones estonianes),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(lliura egípcia),
				'one' => q(lliura egípcia),
				'other' => q(lliures egípcies),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreu),
				'one' => q(nakfa eritreu),
				'other' => q(nakfes eritreus),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(pesseta espanyola \(compte A\)),
				'one' => q(pesseta espanyola \(compte A\)),
				'other' => q(pessetes espanyoles \(compte A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(pesseta espanyola \(compte convertible\)),
				'one' => q(pesseta espanyola \(compte convertible\)),
				'other' => q(pessetes espanyoles \(compte convertible\)),
			},
		},
		'ESP' => {
			symbol => '₧',
			display_name => {
				'currency' => q(pesseta espanyola),
				'one' => q(pesseta espanyola),
				'other' => q(pessetes espanyoles),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etíop),
				'one' => q(birr etíop),
				'other' => q(birrs etíops),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(marc finlandès),
				'one' => q(marc finlandès),
				'other' => q(marcs finlandesos),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dòlar fijià),
				'one' => q(dòlar fijià),
				'other' => q(dòlars fijians),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(lliura de les illes Malvines),
				'one' => q(lliura de les illes Malvines),
				'other' => q(lliures de les illes Malvines),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franc francès),
				'one' => q(franc francès),
				'other' => q(francs francesos),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(lliura esterlina),
				'one' => q(lliura esterlina),
				'other' => q(lliures esterlines),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(cupó de lari georgià),
				'one' => q(cupó de lari georgià),
				'other' => q(cupons de lari georgians),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari),
				'one' => q(lari),
				'other' => q(laris),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanès \(1979–2007\)),
				'one' => q(cedi ghanès \(1979–2007\)),
				'other' => q(cedis ghanesos \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanès),
				'one' => q(cedi ghanès),
				'other' => q(cedis ghanesos),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(lliura de Gibraltar),
				'one' => q(lliura de Gibraltar),
				'other' => q(lliures de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambià),
				'one' => q(dalasi gambià),
				'other' => q(dalasis gambians),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc guineà),
				'one' => q(franc guineà),
				'other' => q(francs guineans),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli guineà),
				'one' => q(syli guineà),
				'other' => q(sylis guineans),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele de Guinea Equatorial),
				'one' => q(ekwele de Guinea Equatorial),
				'other' => q(bipkwele de Guinea Equatorial),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(dracma grega),
				'one' => q(dracma grega),
				'other' => q(dracmes gregues),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal),
				'one' => q(quetzal),
				'other' => q(quetzals),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escut de la Guinea Portuguesa),
				'one' => q(escut de la Guinea Portuguesa),
				'other' => q(escuts de la Guinea Portuguesa),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso de Guinea Bissau),
				'one' => q(peso de Guinea Bissau),
				'other' => q(pesos de Guinea Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dòlar de Guyana),
				'one' => q(dòlar de Guyana),
				'other' => q(dòlars de Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dòlar de Hong Kong),
				'one' => q(dòlar de Hong Kong),
				'other' => q(dòlars de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira),
				'one' => q(lempira),
				'other' => q(lempires),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croat),
				'one' => q(dinar croat),
				'other' => q(dinars croats),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna),
				'one' => q(kuna),
				'other' => q(kunes),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde),
				'one' => q(gourde),
				'other' => q(gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fòrint),
				'one' => q(fòrint),
				'other' => q(fòrints),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonèsia),
				'one' => q(rupia indonèsia),
				'other' => q(rupies indonèsies),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(lliura irlandesa),
				'one' => q(lliura irlandesa),
				'other' => q(lliures irlandeses),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(lliura israeliana),
				'one' => q(lliura israeliana),
				'other' => q(lliures israelianes),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(xéquel israelià),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nou xéquel israelià),
				'one' => q(nou xéquel israelià),
				'other' => q(nous xéquels israelians),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(rupia índia),
				'one' => q(rupia índia),
				'other' => q(rupies índies),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar iraquià),
				'one' => q(dinar iraquià),
				'other' => q(dinars iraquians),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranià),
				'one' => q(rial iranià),
				'other' => q(rials iranians),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(corona islandesa antiga),
				'one' => q(corona islandesa antiga),
				'other' => q(corones islandeses antigues),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona islandesa),
				'one' => q(corona islandesa),
				'other' => q(corones islandeses),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiana),
				'one' => q(lira italiana),
				'other' => q(lires italianes),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dòlar jamaicà),
				'one' => q(dòlar jamaicà),
				'other' => q(dòlars jamaicans),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordà),
				'one' => q(dinar jordà),
				'other' => q(dinars jordans),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(ien),
				'one' => q(ien),
				'other' => q(iens),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(xíling kenyà),
				'one' => q(xíling kenyà),
				'other' => q(xílings kenyans),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirguís),
				'one' => q(som kirguís),
				'other' => q(soms kirguisos),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambodjà),
				'one' => q(riel cambodjà),
				'other' => q(riels cambodjans),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franc de les Comores),
				'one' => q(franc de les Comores),
				'other' => q(francs de les Comores),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nord-coreà),
				'one' => q(won nord-coreà),
				'other' => q(wons nord-coreans),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan sud-coreà \(1953–1962\)),
				'one' => q(hwan sud-coreà),
				'other' => q(hwans sud-coreans),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(antic won sud-coreà),
				'one' => q(antic won sud-coreà),
				'other' => q(antics wons sud-coreans),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won sud-coreà),
				'one' => q(won sud-coreà),
				'other' => q(wons sud-coreans),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuwaitià),
				'one' => q(dinar kuwaitià),
				'other' => q(dinars kuwaitians),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòlar de les illes Caiman),
				'one' => q(dòlar de les illes Caiman),
				'other' => q(dòlars de les illes Caiman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge),
				'one' => q(tenge),
				'other' => q(tenges),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laosià),
				'one' => q(kip laosià),
				'other' => q(kips laosians),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(lliura libanesa),
				'one' => q(lliura libanesa),
				'other' => q(lliures libaneses),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia de Sri Lanka),
				'one' => q(rupia de Sri Lanka),
				'other' => q(rupies de Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dòlar liberià),
				'one' => q(dòlar liberià),
				'other' => q(dòlars liberians),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti),
				'one' => q(loti),
				'other' => q(lotis),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituà),
				'one' => q(litas lituà),
				'other' => q(litai lituans),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituà),
				'one' => q(talonas lituà),
				'other' => q(talonai lituans),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertible luxemburguès),
				'one' => q(franc convertible luxemburguès),
				'other' => q(francs convertibles luxemburguesos),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxemburguès),
				'one' => q(franc luxemburguès),
				'other' => q(francs luxemburguesos),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc financer luxemburguès),
				'one' => q(franc financer luxemburguès),
				'other' => q(francs financers luxemburguesos),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats letó),
				'one' => q(lats letó),
				'other' => q(lati letons),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(ruble letó),
				'one' => q(ruble letó),
				'other' => q(rubles letons),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libi),
				'one' => q(dinar libi),
				'other' => q(dinars libis),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dírham marroquí),
				'one' => q(dírham marroquí),
				'other' => q(dírhams marroquins),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franc marroquí),
				'one' => q(franc marroquí),
				'other' => q(francs marroquins),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(franc monegasc),
				'one' => q(franc monegasc),
				'other' => q(francs monegascos),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(cupó moldau),
				'one' => q(cupó moldau),
				'other' => q(cupons moldaus),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldau),
				'one' => q(leu moldau),
				'other' => q(lei moldaus),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgaix),
				'one' => q(ariary malgaix),
				'other' => q(ariarys malgaixos),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franc malgaix),
				'one' => q(franc malgaix),
				'other' => q(francs malgaixos),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinar macedoni),
				'one' => q(dinar macedoni),
				'other' => q(dinars macedonis),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(denar macedoni \(1992–1993\)),
				'one' => q(denar macedoni \(1992–1993\)),
				'other' => q(denari macedonis \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franc malià),
				'one' => q(franc malià),
				'other' => q(francs malians),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat de Myanmar),
				'one' => q(kyat de Myanmar),
				'other' => q(kyats de Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tögrög mongol),
				'one' => q(tögrög mongol),
				'other' => q(tögrögs mongols),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca de Macau),
				'one' => q(pataca de Macau),
				'other' => q(pataques de Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya maurità \(1973–2017\)),
				'one' => q(ouguiya maurità \(1973–2017\)),
				'other' => q(ouguiyas mauritans \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya maurità),
				'one' => q(ouguiya maurità),
				'other' => q(ouguiyas mauritans),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltesa),
				'one' => q(lira maltesa),
				'other' => q(lires malteses),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(lliura maltesa),
				'one' => q(lliura maltesa),
				'other' => q(lliures malteses),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupies mauricianes),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rupia de les Maldives),
				'one' => q(rupia de les Maldives),
				'other' => q(rupies de les Maldives),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawià),
				'one' => q(kwacha malawià),
				'other' => q(kwacha malawians),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(peso mexicà),
				'one' => q(peso mexicà),
				'other' => q(pesos mexicans),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso de plata mexicà \(1861–1992\)),
				'one' => q(peso de plata mexicà \(1861–1992\)),
				'other' => q(pesos de plata mexicans \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unidad de inversión \(UDI\) mexicana),
				'one' => q(unidad de inversión \(UDI\) mexicana),
				'other' => q(unidades de inversión \(UDI\) mexicanes),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit),
				'one' => q(ringgit),
				'other' => q(ringgits),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escut moçambiquès),
				'one' => q(escut moçambiquès),
				'other' => q(escuts moçambiquesos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(antic metical moçambiquès),
				'one' => q(antic metical moçambiquès),
				'other' => q(antics meticals moçambiquesos),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical moçambiquès),
				'one' => q(metical moçambiquès),
				'other' => q(meticals moçambiquesos),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dòlar namibià),
				'one' => q(dòlar namibià),
				'other' => q(dòlars namibians),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigerià),
				'one' => q(naira nigerià),
				'other' => q(naires nigerians),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(córdoba nicaragüenca),
				'one' => q(córdoba nicaragüenca),
				'other' => q(córdobas nicaragüenques),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaragüenc),
				'one' => q(córdoba nicaragüenc),
				'other' => q(córdobas nicaragüencs),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(florí neerlandès),
				'one' => q(florí neerlandès),
				'other' => q(florins neerlandesos),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corona noruega),
				'one' => q(corona noruega),
				'other' => q(corones noruegues),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupies nepaleses),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dòlar neozelandès),
				'one' => q(dòlar neozelandès),
				'other' => q(dòlars neozelandesos),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanita),
				'one' => q(rial omanita),
				'other' => q(rials omanites),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa),
				'one' => q(balboa),
				'other' => q(balboes),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruà),
				'one' => q(inti peruà),
				'other' => q(intis peruans),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol),
				'one' => q(sol),
				'other' => q(sols),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruà \(1863–1965\)),
				'one' => q(sol peruà \(1863–1965\)),
				'other' => q(sols peruans \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina),
				'one' => q(kina),
				'other' => q(kines),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipí),
				'one' => q(peso filipí),
				'other' => q(pesos filipins),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistanesa),
				'one' => q(rupia pakistanesa),
				'other' => q(rupies pakistaneses),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty),
				'one' => q(zloty),
				'other' => q(zlote),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty polonès \(1950–1995\)),
				'one' => q(zloty polonès \(1950–1995\)),
				'other' => q(zlote polonesos \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escut portuguès),
				'one' => q(escut portuguès),
				'other' => q(escuts portuguesos),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní),
				'one' => q(guaraní),
				'other' => q(guaranís),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial de Qatar),
				'one' => q(rial de Qatar),
				'other' => q(rials de Qatar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dòlar rhodesià),
				'one' => q(dòlar rhodesià),
				'other' => q(dòlars rhodesians),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(antic leu romanès),
				'one' => q(antic leu romanès),
				'other' => q(antics lei romanesos),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu romanès),
				'one' => q(leu romanès),
				'other' => q(lei romanesos),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbi),
				'one' => q(dinar serbi),
				'other' => q(dinars serbis),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruble),
				'one' => q(ruble),
				'other' => q(rubles),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(ruble rus \(1991–1998\)),
				'one' => q(ruble rus \(1991–1998\)),
				'other' => q(rubles russos \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franc de Ruanda),
				'one' => q(franc de Ruanda),
				'other' => q(francs de Ruanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudita),
				'one' => q(rial saudita),
				'other' => q(rials saudites),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dòlar de les illes Salomó),
				'one' => q(dòlar de les illes Salomó),
				'other' => q(dòlars de les illes Salomó),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia de les Seychelles),
				'one' => q(rupia de les Seychelles),
				'other' => q(rupies de les Seychelles),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudanès),
				'one' => q(dinar sudanès),
				'other' => q(dinars sudanesos),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(lliura sudanesa),
				'one' => q(lliura sudanesa),
				'other' => q(lliures sudaneses),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(antiga lliura sudanesa),
				'one' => q(antiga lliura sudanesa),
				'other' => q(antigues lliures sudaneses),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona sueca),
				'one' => q(corona sueca),
				'other' => q(corones sueques),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dòlar de Singapur),
				'one' => q(dòlar de Singapur),
				'other' => q(dòlars de Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(lliura de Santa Helena),
				'one' => q(lliura de Santa Helena),
				'other' => q(lliures de Santa Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar eslovè),
				'one' => q(tolar eslovè),
				'other' => q(tolars eslovens),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(corona eslovaca),
				'one' => q(corona eslovaca),
				'other' => q(corones eslovaques),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone de Sierra Leone),
				'one' => q(leone de Sierra Leone),
				'other' => q(leones de Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone de Sierra Leone \(1964—2022\)),
				'one' => q(leone de Sierra Leone \(1964—2022\)),
				'other' => q(leones de Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(xíling somali),
				'one' => q(xíling somali),
				'other' => q(xílings somalis),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dòlar de Surinam),
				'one' => q(dòlar de Surinam),
				'other' => q(dòlars de Surinam),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(florí de Surinam),
				'one' => q(florí de Surinam),
				'other' => q(florins de Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(lliura del Sudan del Sud),
				'one' => q(lliura del Sudan del Sud),
				'other' => q(lliures del Sudan del Sud),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra de São Tomé i Príncipe \(1977–2017\)),
				'one' => q(dobra de São Tomé i Príncipe \(1977–2017\)),
				'other' => q(dobras de São Tomé i Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de São Tomé i Príncipe),
				'one' => q(dobra de São Tomé i Príncipe),
				'other' => q(dobras de São Tomé i Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(ruble soviètic),
				'one' => q(ruble soviètic),
				'other' => q(rubles soviètics),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colon salvadorenc),
				'one' => q(colón salvadorenc),
				'other' => q(colones salvadorencs),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(lliura siriana),
				'one' => q(lliura siriana),
				'other' => q(lliures sirianes),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni swazi),
				'one' => q(lilangeni swazi),
				'other' => q(emalangeni swazis),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(baht),
				'one' => q(baht),
				'other' => q(bahts),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(ruble tadjik),
				'one' => q(ruble tadjik),
				'other' => q(rubles tadjiks),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tadjik),
				'one' => q(somoni tadjik),
				'other' => q(somonis tadjiks),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turcman \(1993–2009\)),
				'one' => q(manat turcman \(1993–2009\)),
				'other' => q(manats turcmans \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turcman),
				'one' => q(manat turcman),
				'other' => q(manats turcmans),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisià),
				'one' => q(dinar tunisià),
				'other' => q(dinars tunisians),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(pa‘anga tongà),
				'one' => q(pa‘anga tongà),
				'other' => q(pa‘angas tongans),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escut de Timor),
				'one' => q(escut de Timor),
				'other' => q(escuts de Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira turca \(1922–2005\)),
				'one' => q(lira turca \(1922–2005\)),
				'other' => q(lires turques \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(lires turques),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dòlar de Trinitat i Tobago),
				'one' => q(dòlar de Trinitat i Tobago),
				'other' => q(dòlars de Trinitat i Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(nou dòlar de Taiwan),
				'one' => q(nou dòlar de Taiwan),
				'other' => q(nous dòlars de Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(xíling tanzà),
				'one' => q(xíling tanzà),
				'other' => q(xílings tanzans),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hrívnia),
				'one' => q(hrívnia),
				'other' => q(hrívnies),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbóvanets ucraïnès),
				'one' => q(karbóvanets ucraïnès),
				'other' => q(karbóvantsiv ucraïnesos),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(xíling ugandès \(1966–1987\)),
				'one' => q(xíling ugandès \(1966–1987\)),
				'other' => q(xílings ugandesos \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(xíling ugandès),
				'one' => q(xíling ugandès),
				'other' => q(xílings ugandesos),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(dòlar dels Estats Units),
				'one' => q(dòlar dels Estats Units),
				'other' => q(dòlars dels Estats Units),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dòlar dels Estats Units \(dia següent\)),
				'one' => q(dòlar dels Estats Units \(dia següent\)),
				'other' => q(dòlars dels Estats Units \(dia següent\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dòlar dels Estats Units \(mateix dia\)),
				'one' => q(dòlar dels Estats Units \(mateix dia\)),
				'other' => q(dòlars dels Estats Units \(mateix dia\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguaià en unitats indexades),
				'one' => q(peso uruguaià en unitats indexades),
				'other' => q(pesos uruguaians en unitats indexades),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguaià \(1975–1993\)),
				'one' => q(peso uruguaià \(1975–1993\)),
				'other' => q(pesos uruguaians \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguaià),
				'one' => q(peso uruguaià),
				'other' => q(pesos uruguaians),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som uzbek),
				'one' => q(som uzbek),
				'other' => q(soms uzbeks),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolívar veneçolà \(1871–2008\)),
				'one' => q(bolívar veneçolà \(1871–2008\)),
				'other' => q(bolívars veneçolans \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'Bs F',
			display_name => {
				'currency' => q(bolívar veneçolà \(2008–2018\)),
				'one' => q(bolívar veneçolà \(2008–2018\)),
				'other' => q(bolívars veneçolans \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar veneçolà),
				'one' => q(bolívar veneçolà),
				'other' => q(bolívars veneçolans),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dongs vietnamites),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong vietnamita \(1978–1985\)),
				'one' => q(dong vietnamita \(1978–1985\)),
				'other' => q(dongs vietnamites \(1978–1985\)),
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
				'currency' => q(tala samoà),
				'one' => q(tala samoà),
				'other' => q(tales samoans),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA BEAC),
				'one' => q(franc CFA BEAC),
				'other' => q(francs CFA BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(plata),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(or),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unitat compensatòria europea),
				'one' => q(unitat compensatòria europea),
				'other' => q(unitats compensatòries europees),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unitat monetària europea),
				'one' => q(unitat monetària europea),
				'other' => q(unitats monetàries europees),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unitat de compte europea \(XBC\)),
				'one' => q(unitat de compte europea \(XBC\)),
				'other' => q(unitats de compte europees \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unitat de compte europea \(XBD\)),
				'one' => q(unitat de compte europea \(XBD\)),
				'other' => q(unitats de compte europees \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dòlar del Carib Oriental),
				'one' => q(dòlar del Carib Oriental),
				'other' => q(dòlars del Carib Oriental),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(drets especials de gir),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unitat de moneda europea),
				'one' => q(unitat de moneda europea),
				'other' => q(unitats de moneda europees),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc or francès),
				'one' => q(franc or francès),
				'other' => q(francs or francesos),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC francès),
				'one' => q(franc UIC francès),
				'other' => q(francs UIC francesos),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA BCEAO),
				'one' => q(franc CFA BCEAO),
				'other' => q(francs CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(pal·ladi),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franc CFP),
				'one' => q(franc CFP),
				'other' => q(francs CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platí),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fons RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(codi reservat per a proves),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(moneda desconeguda),
				'one' => q(\(unitat monetària desconeguda\)),
				'other' => q(\(moneda desconeguda\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar iemenita),
				'one' => q(dinar iemenita),
				'other' => q(dinars iemenites),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial iemenita),
				'one' => q(rial iemenita),
				'other' => q(rials iemenites),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar fort iugoslau),
				'one' => q(dinar fort iugoslau),
				'other' => q(dinars forts iugoslaus),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(nou dinar iugoslau),
				'one' => q(nou dinar iugoslau),
				'other' => q(nous dinars iugoslaus),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar convertible iugoslau),
				'one' => q(dinar convertible iugoslau),
				'other' => q(dinars convertibles iugoslaus),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar iugoslau reformat \(1992–1993\)),
				'one' => q(dinar reformat iugoslau),
				'other' => q(dinars reformats iugoslaus),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sud-africà \(financer\)),
				'one' => q(rand sud-africà \(financer\)),
				'other' => q(rands sud-africans \(financers\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sud-africà),
				'one' => q(rand sud-africà),
				'other' => q(rands sud-africans),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zambià \(1968–2012\)),
				'one' => q(kwacha zambià \(1968–2012\)),
				'other' => q(kwacha zambians \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambià),
				'one' => q(kwacha zambià),
				'other' => q(kwacha zambians),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nou zaire zairès),
				'one' => q(nou zaire zairès),
				'other' => q(nous zaires zairesos),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire zairès),
				'one' => q(zaire zairès),
				'other' => q(zaires zairesos),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dòlar zimbabuès \(1980–2008\)),
				'one' => q(dòlar zimbabuès \(1980–2008\)),
				'other' => q(dòlars zimbabuesos \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dòlar zimbabuès \(2009\)),
				'one' => q(dòlar zimbabuès \(2009\)),
				'other' => q(dòlars zimbabuesos \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dòlar zimbabuès \(2008\)),
				'one' => q(dòlar zimbabuès \(2008\)),
				'other' => q(dòlars zimbabuesos \(2008\)),
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
				},
			},
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'de gen.',
							'de febr.',
							'de març',
							'd’abr.',
							'de maig',
							'de juny',
							'de jul.',
							'd’ag.',
							'de set.',
							'd’oct.',
							'de nov.',
							'de des.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de gener',
							'de febrer',
							'de març',
							'd’abril',
							'de maig',
							'de juny',
							'de juliol',
							'd’agost',
							'de setembre',
							'd’octubre',
							'de novembre',
							'de desembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'gen.',
							'febr.',
							'març',
							'abr.',
							'maig',
							'juny',
							'jul.',
							'ag.',
							'set.',
							'oct.',
							'nov.',
							'des.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'GN',
							'FB',
							'MÇ',
							'AB',
							'MG',
							'JN',
							'JL',
							'AG',
							'ST',
							'OC',
							'NV',
							'DS'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'gener',
							'febrer',
							'març',
							'abril',
							'maig',
							'juny',
							'juliol',
							'agost',
							'setembre',
							'octubre',
							'novembre',
							'desembre'
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
						mon => 'dl.',
						tue => 'dt.',
						wed => 'dc.',
						thu => 'dj.',
						fri => 'dv.',
						sat => 'ds.',
						sun => 'dg.'
					},
					wide => {
						mon => 'dilluns',
						tue => 'dimarts',
						wed => 'dimecres',
						thu => 'dijous',
						fri => 'divendres',
						sat => 'dissabte',
						sun => 'diumenge'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'dl.',
						tue => 'dt.',
						wed => 'dc.',
						thu => 'dj.',
						fri => 'dv.',
						sat => 'ds.',
						sun => 'dg.'
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
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					wide => {0 => '1r trimestre',
						1 => '2n trimestre',
						2 => '3r trimestre',
						3 => '4t trimestre'
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
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
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
					'afternoon1' => q{migdia},
					'afternoon2' => q{tarda},
					'am' => q{a. m.},
					'evening1' => q{vespre},
					'midnight' => q{mitjanit},
					'morning1' => q{matinada},
					'morning2' => q{matí},
					'night1' => q{nit},
					'pm' => q{p. m.},
				},
				'wide' => {
					'am' => q{a. m.},
					'pm' => q{p. m.},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{a. m.},
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
				'0' => 'eB'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'aC',
				'1' => 'dC'
			},
			wide => {
				'0' => 'abans de Crist',
				'1' => 'després de Crist'
			},
		},
		'roc' => {
			wide => {
				'0' => 'Abans de ROC',
				'1' => 'ROC'
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
			'full' => q{EEEE, dd MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'chinese' => {
			'full' => q{EEEE, dd MMMM UU},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{d/M/y},
		},
		'generic' => {
			'full' => q{EEEE, d MMMM 'del' y G},
			'long' => q{d MMMM 'del' y G},
			'medium' => q{d/M/y G},
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM 'del' y},
			'long' => q{d MMMM 'del' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'roc' => {
			'full' => q{EEEE d MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{dd/MM/y G},
			'short' => q{dd/MM/y GGGGG},
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
			'full' => q{H:mm:ss (zzzz)},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'chinese' => {
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
			'short' => q{{1} {0}},
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
		'buddhist' => {
			MMMEd => q{E d MMM},
		},
		'generic' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMM => q{LLLL 'del' y G},
			GyMMMMEd => q{E, d MMMM 'del' y G},
			GyMMMMd => q{d MMMM 'del' y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd-MM-y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y G},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{LLLL 'del' y G},
			yyyyMMMMEd => q{E, d MMMM 'del' y G},
			yyyyMMMMd => q{d MMMM 'del' y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM 'del' y G},
			GyMMMM => q{LLLL 'del' y G},
			GyMMMMEd => q{E, d MMMM 'del' y G},
			GyMMMMd => q{d MMMM 'del' y G},
			GyMMMd => q{d MMM 'del' y G},
			GyMd => q{dd-MM-y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmsvvvv => q{H:mm:ss (vvvv)},
			Hmv => q{H:mm v},
			Hmvvvv => q{H:mm (vvvv)},
			MEd => q{E d/M},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'setmana' W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmsvvvv => q{h:mm:ss a (vvvv)},
			hmv => q{h:mm a v},
			hmvvvv => q{h:mm a (vvvv)},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{LLL 'del' y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL 'del' y},
			yMMMMEd => q{E, d MMMM 'del' y},
			yMMMMd => q{d MMMM 'del' y},
			yMMMd => q{d MMM 'del' y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'del' y},
			yw => q{'setmana' w 'del' Y},
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
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM, y – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y – d MMM, y G},
				M => q{d MMM, y – d MMM, y G},
				d => q{d – d MMM, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{H–H},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			hm => {
				a => q{h:mm a –h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM 'del' y – MMM 'del' y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM 'del' y G},
				d => q{E, d MMM – E, d MMM 'del' y G},
				y => q{E, d MMM 'del' y – E, d MMM 'del' y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM 'del' y G},
				y => q{MMMM 'del' y – MMMM 'del' y G},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM 'del' y G},
				d => q{E, d MMMM – E, d MMMM 'del' y G},
				y => q{E, d MMMM 'del' y – E, d MMMM 'del' y G},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM 'del' y G},
				d => q{d–d MMMM 'del' y G},
				y => q{d MMMM 'del' y – d MMMM 'del' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'del' y G},
				d => q{d–d MMM 'del' y G},
				y => q{d MMM 'del' y – d MMM 'del' y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			GyMMMEd => {
				G => q{E, d MMM, y G – E, d MMM, y G},
				M => q{E, d MMM – E, d MMM, y G},
				d => q{E, d MMM – E, d MMM, y G},
				y => q{E, d MMM, y – E, d MMM, y G},
			},
			GyMMMd => {
				G => q{d MMM, y G – d MMM, y G},
				M => q{d MMM – d MMM, y G},
				d => q{d–d LLL, y G},
				y => q{d MMM, y – d MMM, y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
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
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{LLL–LLL 'del' y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL 'del' y},
				y => q{LLLL 'del' y – LLLL 'del' y},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM 'del' y},
				d => q{E, d – E, d MMMM 'del' y},
				y => q{E, d MMMM 'del' y – E, d MMMM 'del' y},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM 'del' y},
				d => q{d–d MMMM 'del' y},
				y => q{d MMMM 'del' y – d MMMM 'del' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Hora de: {0}),
		regionFormat => q(Hora d’estiu, {0}),
		regionFormat => q(Hora estàndard, {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Hora de l’Afganistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Caire, el#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#al-Aaiun#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monròvia#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Hora de l’Àfrica central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Hora de l’Àfrica oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Hora estàndard de l’Àfrica meridional#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Àfrica occidental#,
				'generic' => q#Hora de l’Àfrica occidental#,
				'standard' => q#Hora estàndard de l’Àfrica occidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Hora d’estiu d’Alaska#,
				'generic' => q#Hora d’Alaska#,
				'standard' => q#Hora estàndard d’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Amazones#,
				'generic' => q#Hora de l’Amazones#,
				'standard' => q#Hora estàndard de l’Amazones#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc Sablon#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotà#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caiena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciutat de Mèxic#,
		},
		'America/New_York' => {
			exemplarCity => q#Nova York#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota del Nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota del Nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota del Nord#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamà#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Scoresbysund#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Hora d’estiu central d’Amèrica del Nord#,
				'generic' => q#Hora central d’Amèrica del Nord#,
				'standard' => q#Hora estàndard central d’Amèrica del Nord#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora d’estiu oriental d’Amèrica del Nord#,
				'generic' => q#Hora oriental d’Amèrica del Nord#,
				'standard' => q#Hora estàndard oriental d’Amèrica del Nord#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora d’estiu de muntanya d’Amèrica del Nord#,
				'generic' => q#Hora de muntanya d’Amèrica del Nord#,
				'standard' => q#Hora estàndard de muntanya d’Amèrica del Nord#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora d’estiu del Pacífic d’Amèrica del Nord#,
				'generic' => q#Hora del Pacífic d’Amèrica del Nord#,
				'standard' => q#Hora estàndard del Pacífic d’Amèrica del Nord#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Horari d’estiu d’Anadyr#,
				'generic' => q#Hora d’Anàdir#,
				'standard' => q#Hora estàndard d’Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Hora d’estiu d’Apia#,
				'generic' => q#Hora d’Apia#,
				'standard' => q#Hora estàndard d’Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Hora d’estiu àrab#,
				'generic' => q#Hora àrab#,
				'standard' => q#Hora estàndard àrab#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Argentina#,
				'generic' => q#Hora de l’Argentina#,
				'standard' => q#Hora estàndard de l’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Hora d’estiu de l’oest de l’Argentina#,
				'generic' => q#Hora de l’oest de l’Argentina#,
				'standard' => q#Hora estàndard de l’oest de l’Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Hora d’estiu d’Armènia#,
				'generic' => q#Hora d’Armènia#,
				'standard' => q#Hora estàndard d’Armènia#,
			},
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anàdir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtaý#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtóbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyraý#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaül#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Txità#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasc#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duixanbé#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Khovd#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jaipur#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtxatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoiarsk#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Masqat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicòsia#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novossibirsk#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Qostanai#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hồ Chí Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalín#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seül#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taixkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tòquio#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümchi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust’-Nera#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Iakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Iekaterinburg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Atlàntic#,
				'generic' => q#Hora de l’Atlàntic#,
				'standard' => q#Hora estàndard de l’Atlàntic#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Açores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudes#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Illes Canàries#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cap Verd#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Illes Fèroe#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geòrgia del Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Hora d’estiu d’Austràlia central#,
				'generic' => q#Hora d’Austràlia central#,
				'standard' => q#Hora estàndard d’Austràlia central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Hora d’estiu d’Austràlia centre-occidental#,
				'generic' => q#Hora d’Austràlia centre-occidental#,
				'standard' => q#Hora estàndard d’Austràlia centre-occidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Hora d’estiu d’Austràlia oriental#,
				'generic' => q#Hora d’Austràlia oriental#,
				'standard' => q#Hora estàndard d’Austràlia oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Hora d’estiu d’Austràlia occidental#,
				'generic' => q#Hora d’Austràlia occidental#,
				'standard' => q#Hora estàndard d’Austràlia occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Azerbaidjan#,
				'generic' => q#Hora de l’Azerbaidjan#,
				'standard' => q#Hora estàndard de l’Azerbaidjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Hora d’estiu de les Açores#,
				'generic' => q#Hora de les Açores#,
				'standard' => q#Hora estàndard de les Açores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Hora d’estiu de Bangladesh#,
				'generic' => q#Hora de Bangladesh#,
				'standard' => q#Hora estàndard de Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Hora de Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Hora de Bolívia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Hora d’estiu de Brasília#,
				'generic' => q#Hora de Brasília#,
				'standard' => q#Hora estàndard de Brasília#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Hora de Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Hora d’estiu de Cap Verd#,
				'generic' => q#Hora de Cap Verd#,
				'standard' => q#Hora estàndard de Cap Verd#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Hora estàndard de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Hora d’estiu de Chatham#,
				'generic' => q#Hora de Chatham#,
				'standard' => q#Hora estàndard de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Hora d’estiu de Xile#,
				'generic' => q#Hora de Xile#,
				'standard' => q#Hora estàndard de Xile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hora d’estiu de la Xina#,
				'generic' => q#Hora de la Xina#,
				'standard' => q#Hora estàndard de la Xina#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Hora de Kiritimati#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Hora de les illes Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Hora d’estiu de Colòmbia#,
				'generic' => q#Hora de Colòmbia#,
				'standard' => q#Hora estàndard de Colòmbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hora de mig estiu de les illes Cook#,
				'generic' => q#Hora de les illes Cook#,
				'standard' => q#Hora estàndard de les illes Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Hora d’estiu de Cuba#,
				'generic' => q#Hora de Cuba#,
				'standard' => q#Hora estàndard de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Hora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Hora de Dumont d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Hora de Timor Oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Hora d’estiu de l’illa de Pasqua#,
				'generic' => q#Hora de l’illa de Pasqua#,
				'standard' => q#Hora estàndard de l’illa de Pasqua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Hora de l’Equador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Temps universal coordinat#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ciutat desconeguda#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astracan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenes#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel·les#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhaguen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublín#,
			long => {
				'daylight' => q#Hora estàndard d’Irlanda#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hèlsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kíiv#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kírov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Hora d’estiu britànica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mònaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscou#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saràtov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferòpol#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolm#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uliànovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vaticà#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vílnius#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsòvia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zúric#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Hora d’estiu d’Europa central#,
				'generic' => q#Hora d’Europa central#,
				'standard' => q#Hora estàndard d’Europa central#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Hora d’estiu d’Europa oriental#,
				'generic' => q#Hora d’Europa oriental#,
				'standard' => q#Hora estàndard d’Europa oriental#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Hora de l’extrem oriental d’Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Hora d’estiu d’Europa occidental#,
				'generic' => q#Hora d’Europa occidental#,
				'standard' => q#Hora estàndard d’Europa occidental#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Hora d’estiu de les illes Malvines#,
				'generic' => q#Hora de les illes Malvines#,
				'standard' => q#Hora estàndard de les illes Malvines#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Hora d’estiu de Fiji#,
				'generic' => q#Hora de Fiji#,
				'standard' => q#Hora estàndard de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Hora de la Guaiana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Hora d’Antàrtida i de les Terres Australs Antàrtiques Franceses#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Hora del meridià de Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Hora de Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Hora d’estiu de Geòrgia#,
				'generic' => q#Hora de Geòrgia#,
				'standard' => q#Hora estàndard de Geòrgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Hora de les illes Gilbert#,
			},
		},
		'Greenland' => {
			long => {
				'daylight' => q#Hora d’estiu de Groenlàndia#,
				'generic' => q#Hora de Groenlàndia#,
				'standard' => q#Hora estàndard de Groenlàndia#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Est de Groenlàndia#,
				'generic' => q#Hora de l’Est de Groenlàndia#,
				'standard' => q#Hora estàndard de l’Est de Groenlàndia#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Oest de Groenlàndia#,
				'generic' => q#Hora de l’Oest de Groenlàndia#,
				'standard' => q#Hora estàndard de l’Oest de Groenlàndia#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Hora estàndard del Golf#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Hora de Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hora d’estiu de Hawaii-Aleutianes#,
				'generic' => q#Hora de Hawaii-Aleutianes#,
				'standard' => q#Hora estàndard de Hawaii-Aleutianes#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hora d’estiu de Hong Kong#,
				'generic' => q#Hora de Hong Kong#,
				'standard' => q#Hora estàndard de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hora d’estiu de Khovd#,
				'generic' => q#Hora de Khovd#,
				'standard' => q#Hora estàndard de Khovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hora de l’Índia#,
			},
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurici#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunió#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hora de l’oceà Índic#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hora de l’Indoxina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Hora central d’Indonèsia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Hora de l’est d’Indonèsia#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Hora de l’oest d’Indonèsia#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Iran#,
				'generic' => q#Hora de l’Iran#,
				'standard' => q#Hora estàndard de l’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Hora d’estiu d’Irkutsk#,
				'generic' => q#Hora d’Irkutsk#,
				'standard' => q#Hora estàndard d’Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Hora d’estiu d’Israel#,
				'generic' => q#Hora d’Israel#,
				'standard' => q#Hora estàndard d’Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Hora d’estiu del Japó#,
				'generic' => q#Hora del Japó#,
				'standard' => q#Hora estàndard del Japó#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Horari d’estiu de Petropavlovsk de Kamtxatka#,
				'generic' => q#Hora de Kamtxatka#,
				'standard' => q#Hora estàndard de Petropavlovsk de Kamtxatka#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Hora del Kazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Hora de l’est del Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Hora de l’oest del Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Hora d’estiu de Corea#,
				'generic' => q#Hora de Corea#,
				'standard' => q#Hora estàndard de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Hora d’estiu de Krasnoiarsk#,
				'generic' => q#Hora de Krasnoiarsk#,
				'standard' => q#Hora estàndard de Krasnoiarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Hora del Kirguizstan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Hora de les illes Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Horari d’estiu de Lord Howe#,
				'generic' => q#Hora de Lord Howe#,
				'standard' => q#Hora estàndard de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Hora d’estiu de Macau#,
				'generic' => q#Hora de Macau#,
				'standard' => q#Hora estàndard de Macau#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Hora d’estiu de Magadan#,
				'generic' => q#Hora de Magadan#,
				'standard' => q#Hora estàndard de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Hora de Malàisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Hora de les Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Hora de les Marqueses#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Hora de les illes Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Hora d’estiu de Maurici#,
				'generic' => q#Hora de Maurici#,
				'standard' => q#Hora estàndard de Maurici#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Hora de Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Hora d’estiu del Pacífic de Mèxic#,
				'generic' => q#Hora del Pacífic de Mèxic#,
				'standard' => q#Hora estàndard del Pacífic de Mèxic#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Hora d’estiu d’Ulaanbaatar#,
				'generic' => q#Hora d’Ulaanbaatar#,
				'standard' => q#Hora estàndard d’Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Hora d’estiu de Moscou#,
				'generic' => q#Hora de Moscou#,
				'standard' => q#Hora estàndard de Moscou#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Hora de Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Hora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Hora del Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Hora d’estiu de Nova Caledònia#,
				'generic' => q#Hora de Nova Caledònia#,
				'standard' => q#Hora estàndard de Nova Caledònia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Hora d’estiu de Nova Zelanda#,
				'generic' => q#Hora de Nova Zelanda#,
				'standard' => q#Hora estàndard de Nova Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Hora d’estiu de Terranova#,
				'generic' => q#Hora de Terranova#,
				'standard' => q#Hora estàndard de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Hora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Hora d’estiu de l’illa Norfolk#,
				'generic' => q#Hora de l’illa Norfolk#,
				'standard' => q#Hora estàndard de l’illa Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Hora d’estiu de Fernando de Noronha#,
				'generic' => q#Hora de Fernando de Noronha#,
				'standard' => q#Hora estàndard de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Hora d’estiu de Novossibirsk#,
				'generic' => q#Hora de Novossibirsk#,
				'standard' => q#Hora estàndard de Novossibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Hora d’estiu d’Omsk#,
				'generic' => q#Hora d’Omsk#,
				'standard' => q#Hora estàndard d’Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Illa de Pasqua#,
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
		'Pacific/Kanton' => {
			exemplarCity => q#Canton#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marqueses#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahití#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Hora d’estiu del Pakistan#,
				'generic' => q#Hora del Pakistan#,
				'standard' => q#Hora estàndard del Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Hora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Hora de Papua Nova Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Hora d’estiu del Paraguai#,
				'generic' => q#Hora del Paraguai#,
				'standard' => q#Hora estàndard del Paraguai#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Hora d’estiu del Perú#,
				'generic' => q#Hora del Perú#,
				'standard' => q#Hora estàndard del Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Hora d’estiu de les Filipines#,
				'generic' => q#Hora de les Filipines#,
				'standard' => q#Hora estàndard de les Filipines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Hora de les illes Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Hora d’estiu de Saint-Pierre-et-Miquelon#,
				'generic' => q#Hora de Saint-Pierre-et-Miquelon#,
				'standard' => q#Hora estàndard de Saint-Pierre-et-Miquelon#,
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
		'Reunion' => {
			long => {
				'standard' => q#Hora de Reunió#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Hora d’estiu de Sakhalín#,
				'generic' => q#Hora de Sakhalín#,
				'standard' => q#Hora estàndard de Sakhalín#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Hora d’estiu de Samara#,
				'generic' => q#Hora de Samara#,
				'standard' => q#Hora estàndard de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Hora d’estiu de Samoa#,
				'generic' => q#Hora de Samoa#,
				'standard' => q#Hora estàndard de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Hora de les Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Hora de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Hora de les illes Salomó#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hora de Geòrgia del Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Hora de Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Hora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Hora de Tahití#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Hora d’estiu de Taipei#,
				'generic' => q#Hora de Taipei#,
				'standard' => q#Hora estàndard de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Hora del Tadjikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Hora d’estiu de Tonga#,
				'generic' => q#Hora de Tonga#,
				'standard' => q#Hora estàndard de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Hora d’estiu del Turkmenistan#,
				'generic' => q#Hora del Turkmenistan#,
				'standard' => q#Hora estàndard del Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Uruguai#,
				'generic' => q#Hora de l’Uruguai#,
				'standard' => q#Hora estàndard de l’Uruguai#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Hora d’estiu de l’Uzbekistan#,
				'generic' => q#Hora de l’Uzbekistan#,
				'standard' => q#Hora estàndard de l’Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Hora d’estiu de Vanatu#,
				'generic' => q#Hora de Vanatu#,
				'standard' => q#Hora estàndard de Vanatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Hora de Veneçuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Hora d’estiu de Vladivostok#,
				'generic' => q#Hora de Vladivostok#,
				'standard' => q#Hora estàndard de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Hora d’estiu de Volgograd#,
				'generic' => q#Hora de Volgograd#,
				'standard' => q#Hora estàndard de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Hora de les illes Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Hora de Wallis i Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Hora d’estiu de Iakutsk#,
				'generic' => q#Hora de Iakutsk#,
				'standard' => q#Hora estàndard de Iakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Hora d’estiu de Iekaterinburg#,
				'generic' => q#Hora de Iekaterinburg#,
				'standard' => q#Hora estàndard de Iekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Hora de Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
