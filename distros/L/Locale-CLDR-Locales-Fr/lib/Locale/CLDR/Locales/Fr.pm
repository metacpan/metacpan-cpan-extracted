=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fr - Package for language French

=cut

package Locale::CLDR::Locales::Fr;
# This file auto generated from Data\common\main\fr.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine-plural','spellout-ordinal-masculine','spellout-ordinal-feminine-plural','spellout-ordinal-feminine','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal-masculine-plural','digits-ordinal-feminine-plural','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'cents-f' => {
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
		'cents-m' => {
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
		'cents-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ième),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%%et-unieme=),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(' =%%spellout-ordinal=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(-et-onzième),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(' =%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(' =%%spellout-ordinal=),
				},
			},
		},
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
					rule => q(=#,##0=$(ordinal,one{re}other{e})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{re}other{e})$),
				},
			},
		},
		'digits-ordinal-feminine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{res}other{es})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{res}other{es})$),
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
					rule => q(=#,##0=$(ordinal,one{er}other{e})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{er}other{e})$),
				},
			},
		},
		'digits-ordinal-masculine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{ers}other{es})$),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=$(ordinal,one{ers}other{es})$),
				},
			},
		},
		'et-un' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(et-un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(et-onze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine=),
				},
			},
		},
		'et-une' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(et-une),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-feminine=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(et-onze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine=),
				},
			},
		},
		'et-unieme' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(et-unième),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-ordinal=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(et-onzième),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%%spellout-ordinal=),
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
		'mille-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ième),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(e-=%%et-unieme=),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(e =%%spellout-ordinal=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(e-et-onzième),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(e =%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(e =%%spellout-ordinal=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(moins →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zéro),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgule →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(une),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vingt[-→%%et-une→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trente[-→%%et-une→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarante[-→%%et-une→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquante[-→%%et-une→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(20),
					rule => q(soixante[-→%%et-une→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(20),
					rule => q(quatre-vingt→%%subcents-f→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← cent→%%cents-f→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-leading← mille[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-leading← millions[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-leading← milliards[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-leading← billions[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-leading← billiards[ →→]),
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
					rule => q(moins →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zéro),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgule →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(deux),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trois),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quatre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinq),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(six),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sept),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(huit),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(neuf),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dix),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(douze),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(treize),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quatorze),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quinze),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(seize),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dix-→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vingt[-→%%et-un→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trente[-→%%et-un→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarante[-→%%et-un→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquante[-→%%et-un→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(20),
					rule => q(soixante[-→%%et-un→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(20),
					rule => q(quatre-vingt→%%subcents-m→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←← cent→%%cents-m→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-leading← mille[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-leading← millions[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-leading← milliards[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-leading← billions[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-leading← billiards[ →→]),
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
		'spellout-leading' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'80' => {
					base_value => q(80),
					divisor => q(20),
					rule => q(quatre-vingt[-→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←← cent[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-masculine=),
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
				'-x' => {
					divisor => q(1),
					rule => q(moins →→),
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
					rule => q(←%spellout-cardinal-masculine←-cent→%%cents-m→),
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
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(unième),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(deuxième),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(troisième),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quatrième),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinquième),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sixième),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(septième),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(huitième),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(neuvième),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dixième),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(onzième),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(douzième),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(treizième),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quatorzième),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quinzième),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(seizième),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(dix-→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vingtième),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(vingt-→%%et-unieme→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trentième),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(trente-→%%et-unieme→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarantième),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(quarante-→%%et-unieme→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquantième),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(cinquante-→%%et-unieme→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(soixantième),
				},
				'61' => {
					base_value => q(61),
					divisor => q(20),
					rule => q(soixante-→%%et-unieme→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(20),
					rule => q(quatre-vingt→%%subcents-o→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%cents-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine← cent→%%cents-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mill→%%mille-o→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%spellout-leading← mill→%%mille-o→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%spellout-leading← million→%%cents-o→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-leading← milliard→%%cents-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-leading← billion→%%cents-o→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-leading← billiard→%%cents-o→),
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
		'spellout-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(moins →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zéroième),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(première),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-ordinal=),
				},
			},
		},
		'spellout-ordinal-feminine-plural' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=s),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=s),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(moins →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zéroième),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(premier),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-ordinal=),
				},
			},
		},
		'spellout-ordinal-masculine-plural' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=s),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=s),
				},
			},
		},
		'subcents-f' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(s),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%spellout-cardinal-feminine=),
				},
			},
		},
		'subcents-m' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(s),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%spellout-cardinal-masculine=),
				},
			},
		},
		'subcents-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ième),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(-=%%et-unieme=),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(-=%%spellout-ordinal=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(-et-onzième),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(-=%%spellout-ordinal=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(-=%%spellout-ordinal=),
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
 				'ab' => 'abkhaze',
 				'ace' => 'aceh',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adyguéen',
 				'ae' => 'avestique',
 				'aeb' => 'arabe tunisien',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'aïnou',
 				'ak' => 'akan',
 				'akk' => 'akkadien',
 				'akz' => 'alabama',
 				'ale' => 'aléoute',
 				'aln' => 'guègue',
 				'alt' => 'altaï du Sud',
 				'am' => 'amharique',
 				'an' => 'aragonais',
 				'ang' => 'ancien anglais',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabe',
 				'ar_001' => 'arabe standard moderne',
 				'arc' => 'araméen',
 				'arn' => 'mapuche',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'arabe algérien',
 				'ars' => 'arabe najdi',
 				'arw' => 'arawak',
 				'ary' => 'arabe marocain',
 				'arz' => 'arabe égyptien',
 				'as' => 'assamais',
 				'asa' => 'asu',
 				'ase' => 'langue des signes américaine',
 				'ast' => 'asturien',
 				'atj' => 'atikamekw',
 				'av' => 'avar',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaïdjanais',
 				'az@alt=short' => 'azéri',
 				'ba' => 'bachkir',
 				'bal' => 'baloutchi',
 				'ban' => 'balinais',
 				'bar' => 'bavarois',
 				'bas' => 'bassa',
 				'bax' => 'bamoun',
 				'bbc' => 'batak toba',
 				'bbj' => 'ghomalaʼ',
 				'be' => 'biélorusse',
 				'bej' => 'bedja',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'bulgare',
 				'bgc' => 'haryanvi',
 				'bgn' => 'baloutchi occidental',
 				'bho' => 'bhodjpouri',
 				'bi' => 'bichelamar',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibétain',
 				'bpy' => 'bishnupriya',
 				'bqi' => 'bakhtiari',
 				'br' => 'breton',
 				'bra' => 'braj',
 				'brh' => 'brahoui',
 				'brx' => 'bodo',
 				'bs' => 'bosniaque',
 				'bss' => 'akoose',
 				'bua' => 'bouriate',
 				'bug' => 'bugi',
 				'bum' => 'boulou',
 				'byn' => 'blin',
 				'byv' => 'médumba',
 				'ca' => 'catalan',
 				'cad' => 'caddo',
 				'car' => 'caribe',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'changma kodha',
 				'ce' => 'tchétchène',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'tchaghataï',
 				'chk' => 'chuuk',
 				'chm' => 'mari',
 				'chn' => 'jargon chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'sorani',
 				'ckb@alt=menu' => 'kurde sorani',
 				'clc' => 'chilcotin',
 				'co' => 'corse',
 				'cop' => 'copte',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crg' => 'mitchif',
 				'crh' => 'tatar de Crimée',
 				'crj' => 'cri de l’Est (dialecte du Sud)',
 				'crk' => 'cri des plaines',
 				'crl' => 'cri de l’Est (dialecte du Nord)',
 				'crm' => 'cri de Moose',
 				'crr' => 'algonquin de Caroline',
 				'crs' => 'créole seychellois',
 				'cs' => 'tchèque',
 				'csb' => 'kachoube',
 				'csw' => 'cri des marais',
 				'cu' => 'slavon d’église',
 				'cv' => 'tchouvache',
 				'cy' => 'gallois',
 				'da' => 'danois',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'allemand',
 				'de_AT' => 'allemand autrichien',
 				'de_CH' => 'allemand suisse',
 				'del' => 'delaware',
 				'den' => 'esclave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'bas-sorabe',
 				'dtp' => 'dusun central',
 				'dua' => 'douala',
 				'dum' => 'moyen néerlandais',
 				'dv' => 'maldivien',
 				'dyo' => 'diola-fogny',
 				'dyu' => 'dioula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'éwé',
 				'efi' => 'éfik',
 				'egl' => 'émilien',
 				'egy' => 'égyptien ancien',
 				'eka' => 'ékadjouk',
 				'el' => 'grec',
 				'elx' => 'élamite',
 				'en' => 'anglais',
 				'en_AU' => 'anglais australien',
 				'en_CA' => 'anglais canadien',
 				'en_GB' => 'anglais britannique',
 				'en_US' => 'anglais américain',
 				'enm' => 'moyen anglais',
 				'eo' => 'espéranto',
 				'es' => 'espagnol',
 				'es_419' => 'espagnol d’Amérique latine',
 				'es_ES' => 'espagnol d’Espagne',
 				'es_MX' => 'espagnol du Mexique',
 				'esu' => 'youpik central',
 				'et' => 'estonien',
 				'eu' => 'basque',
 				'ewo' => 'éwondo',
 				'ext' => 'estrémègne',
 				'fa' => 'persan',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'peul',
 				'fi' => 'finnois',
 				'fil' => 'filipino',
 				'fit' => 'finnois tornédalien',
 				'fj' => 'fidjien',
 				'fo' => 'féroïen',
 				'fon' => 'fon',
 				'fr' => 'français',
 				'fr_CA' => 'français canadien',
 				'fr_CH' => 'français suisse',
 				'frc' => 'français cadien',
 				'frm' => 'moyen français',
 				'fro' => 'ancien français',
 				'frp' => 'francoprovençal',
 				'frr' => 'frison septentrional',
 				'frs' => 'frison oriental',
 				'fur' => 'frioulan',
 				'fy' => 'frison occidental',
 				'ga' => 'irlandais',
 				'gaa' => 'ga',
 				'gag' => 'gagaouze',
 				'gan' => 'gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gbz' => 'dari zoroastrien',
 				'gd' => 'gaélique écossais',
 				'gez' => 'guèze',
 				'gil' => 'gilbertin',
 				'gl' => 'galicien',
 				'glk' => 'gilaki',
 				'gmh' => 'moyen haut-allemand',
 				'gn' => 'guarani',
 				'goh' => 'ancien haut allemand',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotique',
 				'grb' => 'grebo',
 				'grc' => 'grec ancien',
 				'gsw' => 'suisse allemand',
 				'gu' => 'goudjarati',
 				'guc' => 'wayuu',
 				'gur' => 'gurenne',
 				'guz' => 'gusii',
 				'gv' => 'mannois',
 				'gwi' => 'gwichʼin',
 				'ha' => 'haoussa',
 				'hai' => 'haïda',
 				'hak' => 'hakka',
 				'haw' => 'hawaïen',
 				'hax' => 'haïda du Sud',
 				'he' => 'hébreu',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'hindi fidjien',
 				'hil' => 'hiligaynon',
 				'hit' => 'hittite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croate',
 				'hsb' => 'haut-sorabe',
 				'hsn' => 'xiang',
 				'ht' => 'créole haïtien',
 				'hu' => 'hongrois',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'arménien',
 				'hz' => 'héréro',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonésien',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi du Sichuan',
 				'ik' => 'inupiaq',
 				'ikt' => 'inuktitut de l’Ouest canadien',
 				'ilo' => 'ilocano',
 				'inh' => 'ingouche',
 				'io' => 'ido',
 				'is' => 'islandais',
 				'it' => 'italien',
 				'iu' => 'inuktitut',
 				'izh' => 'ingrien',
 				'ja' => 'japonais',
 				'jam' => 'créole jamaïcain',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'matchamé',
 				'jpr' => 'judéo-persan',
 				'jrb' => 'judéo-arabe',
 				'jut' => 'jute',
 				'jv' => 'javanais',
 				'ka' => 'géorgien',
 				'kaa' => 'karakalpak',
 				'kab' => 'kabyle',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabarde',
 				'kbl' => 'kanembou',
 				'kcg' => 'tyap',
 				'kde' => 'makondé',
 				'kea' => 'capverdien',
 				'ken' => 'kényang',
 				'kfo' => 'koro',
 				'kg' => 'kikongo',
 				'kgp' => 'caingangue',
 				'kha' => 'khasi',
 				'kho' => 'khotanais',
 				'khq' => 'koyra chiini',
 				'khw' => 'khowar',
 				'ki' => 'kikuyu',
 				'kiu' => 'kirmanjki',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakh',
 				'kkj' => 'kako',
 				'kl' => 'groenlandais',
 				'kln' => 'kalendjin',
 				'km' => 'khmer',
 				'kmb' => 'kimboundou',
 				'kn' => 'kannada',
 				'ko' => 'coréen',
 				'koi' => 'komi-permiak',
 				'kok' => 'konkani',
 				'kos' => 'kosraéen',
 				'kpe' => 'kpellé',
 				'kr' => 'kanouri',
 				'krc' => 'karatchaï balkar',
 				'kri' => 'krio',
 				'krj' => 'kinaray-a',
 				'krl' => 'carélien',
 				'kru' => 'kouroukh',
 				'ks' => 'cachemiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölsch',
 				'ku' => 'kurde',
 				'kum' => 'koumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornique',
 				'kwk' => 'kwak’wala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirghize',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxembourgeois',
 				'lez' => 'lezghien',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'ganda',
 				'li' => 'limbourgeois',
 				'lij' => 'ligure',
 				'lil' => 'lillooet',
 				'liv' => 'livonien',
 				'lkt' => 'lakota',
 				'lmo' => 'lombard',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'créole louisianais',
 				'loz' => 'lozi',
 				'lrc' => 'lori du Nord',
 				'lsm' => 'samia',
 				'lt' => 'lituanien',
 				'ltg' => 'latgalien',
 				'lu' => 'luba-katanga (kiluba)',
 				'lua' => 'luba-kasaï (ciluba)',
 				'lui' => 'luiseño',
 				'lun' => 'lunda',
 				'lus' => 'lushaï',
 				'luy' => 'luyia',
 				'lv' => 'letton',
 				'lzh' => 'chinois littéraire',
 				'lzz' => 'laze',
 				'mad' => 'madurais',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maïthili',
 				'mak' => 'makassar',
 				'man' => 'mandingue',
 				'mas' => 'maasaï',
 				'mde' => 'maba',
 				'mdf' => 'mokcha',
 				'mdr' => 'mandar',
 				'men' => 'mendé',
 				'mer' => 'meru',
 				'mfe' => 'créole mauricien',
 				'mg' => 'malgache',
 				'mga' => 'moyen irlandais',
 				'mgh' => 'makua',
 				'mgo' => 'metaʼ',
 				'mh' => 'marshallais',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macédonien',
 				'ml' => 'malayalam',
 				'mn' => 'mongol',
 				'mnc' => 'mandchou',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'moré',
 				'mr' => 'marathi',
 				'mrj' => 'mari occidental',
 				'ms' => 'malais',
 				'mt' => 'maltais',
 				'mua' => 'moundang',
 				'mul' => 'multilingue',
 				'mus' => 'creek',
 				'mwl' => 'mirandais',
 				'mwr' => 'marwarî',
 				'mwv' => 'mentawaï',
 				'my' => 'birman',
 				'mye' => 'myènè',
 				'myv' => 'erzya',
 				'mzn' => 'mazandérani',
 				'na' => 'nauruan',
 				'nan' => 'minnan',
 				'nap' => 'napolitain',
 				'naq' => 'nama',
 				'nb' => 'norvégien bokmål',
 				'nd' => 'ndébélé du Nord',
 				'nds' => 'bas-allemand',
 				'nds_NL' => 'bas-saxon néerlandais',
 				'ne' => 'népalais',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'niha',
 				'niu' => 'niuéen',
 				'njo' => 'ao',
 				'nl' => 'néerlandais',
 				'nl_BE' => 'flamand',
 				'nmg' => 'ngoumba',
 				'nn' => 'norvégien nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvégien',
 				'nog' => 'nogaï',
 				'non' => 'vieux norrois',
 				'nov' => 'novial',
 				'nqo' => 'n’ko',
 				'nr' => 'ndébélé du Sud',
 				'nso' => 'sotho du Nord',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newarî classique',
 				'ny' => 'chewa',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankolé',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzema',
 				'oc' => 'occitan',
 				'oj' => 'ojibwa',
 				'ojb' => 'ojibwé du Nord-Ouest',
 				'ojc' => 'ojibwé central',
 				'ojs' => 'oji-cri',
 				'ojw' => 'ojibwé occidental',
 				'oka' => 'colville-okanagan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossète',
 				'osa' => 'osage',
 				'ota' => 'turc ottoman',
 				'pa' => 'pendjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampangan',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcd' => 'picard',
 				'pcm' => 'pidgin nigérian',
 				'pdc' => 'pennsilfaanisch',
 				'pdt' => 'bas-prussien',
 				'peo' => 'persan ancien',
 				'pfl' => 'allemand palatin',
 				'phn' => 'phénicien',
 				'pi' => 'pali',
 				'pis' => 'pijin',
 				'pl' => 'polonais',
 				'pms' => 'piémontais',
 				'pnt' => 'pontique',
 				'pon' => 'pohnpei',
 				'pqm' => 'malécite-passamaquoddy',
 				'prg' => 'prussien',
 				'pro' => 'provençal ancien',
 				'ps' => 'pachto',
 				'ps@alt=variant' => 'pashto',
 				'pt' => 'portugais',
 				'pt_BR' => 'portugais brésilien',
 				'pt_PT' => 'portugais européen',
 				'qu' => 'quechua',
 				'quc' => 'quiché',
 				'qug' => 'quichua du Haut-Chimborazo',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongien',
 				'rgn' => 'romagnol',
 				'rhg' => 'rohingya',
 				'rif' => 'rifain',
 				'rm' => 'romanche',
 				'rn' => 'roundi',
 				'ro' => 'roumain',
 				'ro_MD' => 'moldave',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'rtm' => 'rotuman',
 				'ru' => 'russe',
 				'rue' => 'ruthène',
 				'rug' => 'roviana',
 				'rup' => 'aroumain',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'iakoute',
 				'sam' => 'araméen samaritain',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'saurashtra',
 				'sba' => 'ngambay',
 				'sbp' => 'isangu',
 				'sc' => 'sarde',
 				'scn' => 'sicilien',
 				'sco' => 'écossais',
 				'sd' => 'sindhi',
 				'sdc' => 'sarde sassarais',
 				'sdh' => 'kurde du Sud',
 				'se' => 'same du Nord',
 				'see' => 'seneca',
 				'seh' => 'cisena',
 				'sei' => 'séri',
 				'sel' => 'selkoupe',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'ancien irlandais',
 				'sgs' => 'samogitien',
 				'sh' => 'serbo-croate',
 				'shi' => 'chleuh',
 				'shn' => 'shan',
 				'shu' => 'arabe tchadien',
 				'si' => 'cingalais',
 				'sid' => 'sidamo',
 				'sk' => 'slovaque',
 				'sl' => 'slovène',
 				'slh' => 'lushootseed du Sud',
 				'sli' => 'bas-silésien',
 				'sly' => 'sélayar',
 				'sm' => 'samoan',
 				'sma' => 'same du Sud',
 				'smj' => 'same de Lule',
 				'smn' => 'same d’Inari',
 				'sms' => 'same skolt',
 				'sn' => 'shona',
 				'snk' => 'soninké',
 				'so' => 'somali',
 				'sog' => 'sogdien',
 				'sq' => 'albanais',
 				'sr' => 'serbe',
 				'srn' => 'sranan tongo',
 				'srr' => 'sérère',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sotho du Sud',
 				'stq' => 'saterlandais',
 				'str' => 'salish des détroits',
 				'su' => 'soundanais',
 				'suk' => 'soukouma',
 				'sus' => 'soussou',
 				'sux' => 'sumérien',
 				'sv' => 'suédois',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili du Congo',
 				'swb' => 'comorien',
 				'syc' => 'syriaque classique',
 				'syr' => 'syriaque',
 				'szl' => 'silésien',
 				'ta' => 'tamoul',
 				'tce' => 'tutchone du Sud',
 				'tcy' => 'toulou',
 				'te' => 'télougou',
 				'tem' => 'timné',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tétoum',
 				'tg' => 'tadjik',
 				'tgx' => 'tagish',
 				'th' => 'thaï',
 				'tht' => 'tahltan',
 				'ti' => 'tigrigna',
 				'tig' => 'tigré',
 				'tiv' => 'tiv',
 				'tk' => 'turkmène',
 				'tkl' => 'tokelau',
 				'tkr' => 'tsakhour',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tly' => 'talysh',
 				'tmh' => 'tamacheq',
 				'tn' => 'tswana',
 				'to' => 'tongien',
 				'tog' => 'tonga nyasa',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turc',
 				'tru' => 'touroyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonien',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatar',
 				'ttm' => 'tutchone du Nord',
 				'ttt' => 'tati caucasien',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitien',
 				'tyv' => 'touvain',
 				'tzm' => 'amazighe de l’Atlas central',
 				'udm' => 'oudmourte',
 				'ug' => 'ouïghour',
 				'ug@alt=variant' => 'ouïgour',
 				'uga' => 'ougaritique',
 				'uk' => 'ukrainien',
 				'umb' => 'umbundu',
 				'und' => 'langue indéterminée',
 				'ur' => 'ourdou',
 				'uz' => 'ouzbek',
 				'vai' => 'vaï',
 				've' => 'venda',
 				'vec' => 'vénitien',
 				'vep' => 'vepse',
 				'vi' => 'vietnamien',
 				'vls' => 'flamand occidental',
 				'vmf' => 'franconien du Main',
 				'vmw' => 'macua',
 				'vo' => 'volapük',
 				'vot' => 'vote',
 				'vro' => 'võro',
 				'vun' => 'vunjo',
 				'wa' => 'wallon',
 				'wae' => 'walser',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'kalmouk',
 				'xh' => 'xhosa',
 				'xmf' => 'mingrélien',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapois',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatou',
 				'yue' => 'cantonais',
 				'yue@alt=menu' => 'chinois cantonais',
 				'za' => 'zhuang',
 				'zap' => 'zapotèque',
 				'zbl' => 'symboles Bliss',
 				'zea' => 'zélandais',
 				'zen' => 'zenaga',
 				'zgh' => 'amazighe standard marocain',
 				'zh' => 'chinois',
 				'zh@alt=menu' => 'chinois mandarin',
 				'zh_Hans' => 'chinois simplifié',
 				'zh_Hans@alt=long' => 'mandarin simplifié',
 				'zh_Hant' => 'chinois traditionnel',
 				'zh_Hant@alt=long' => 'mandarin traditionnel',
 				'zu' => 'zoulou',
 				'zun' => 'zuñi',
 				'zxx' => 'sans contenu linguistique',
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
 			'Afak' => 'afaka',
 			'Aghb' => 'aghbanien',
 			'Ahom' => 'ahom',
 			'Arab' => 'arabe',
 			'Arab@alt=variant' => 'arabo-persan',
 			'Aran' => 'nastaliq',
 			'Armi' => 'araméen impérial',
 			'Armn' => 'arménien',
 			'Avst' => 'avestique',
 			'Bali' => 'balinais',
 			'Bamu' => 'bamoun',
 			'Bass' => 'bassa',
 			'Batk' => 'batak',
 			'Beng' => 'bengali',
 			'Bhks' => 'bhaïksouki',
 			'Blis' => 'symboles Bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brâhmî',
 			'Brai' => 'braille',
 			'Bugi' => 'bouguis',
 			'Buhd' => 'bouhide',
 			'Cakm' => 'chakma',
 			'Cans' => 'syllabaire autochtone canadien unifié',
 			'Cari' => 'carien',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Chrs' => 'chorasmien',
 			'Cirt' => 'cirth',
 			'Copt' => 'copte',
 			'Cpmn' => 'syllabaire chypro-minoen',
 			'Cprt' => 'syllabaire chypriote',
 			'Cyrl' => 'cyrillique',
 			'Cyrs' => 'cyrillique (variante slavonne)',
 			'Deva' => 'dévanagari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogri',
 			'Dsrt' => 'déséret',
 			'Dupl' => 'sténographie Duployé',
 			'Egyd' => 'démotique égyptien',
 			'Egyh' => 'hiératique égyptien',
 			'Egyp' => 'hiéroglyphes égyptiens',
 			'Elba' => 'elbasan',
 			'Elym' => 'élymaïque',
 			'Ethi' => 'éthiopique',
 			'Gara' => 'garay',
 			'Geok' => 'géorgien khoutsouri',
 			'Geor' => 'géorgien',
 			'Glag' => 'glagolitique',
 			'Gong' => 'gondi de Gundjala',
 			'Gonm' => 'gondi de Masaram',
 			'Goth' => 'gotique',
 			'Gran' => 'grantha',
 			'Grek' => 'grec',
 			'Gujr' => 'goudjarâtî',
 			'Gukh' => 'gurung khema',
 			'Guru' => 'gourmoukhî',
 			'Hanb' => 'han avec bopomofo',
 			'Hang' => 'hangûl',
 			'Hani' => 'sinogrammes',
 			'Hano' => 'hanounóo',
 			'Hans' => 'simplifié',
 			'Hans@alt=stand-alone' => 'sinogrammes simplifiés',
 			'Hant' => 'traditionnel',
 			'Hant@alt=stand-alone' => 'sinogrammes traditionnels',
 			'Hatr' => 'hatrénien',
 			'Hebr' => 'hébreu',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hiéroglyphes hittites',
 			'Hmng' => 'pahawh hmong',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'katakana ou hiragana',
 			'Hung' => 'ancien hongrois',
 			'Inds' => 'indus',
 			'Ital' => 'ancien italique',
 			'Jamo' => 'jamo',
 			'Java' => 'javanais',
 			'Jpan' => 'japonais',
 			'Jurc' => 'jurchen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Kawi' => 'kawi',
 			'Khar' => 'kharochthî',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khodjki',
 			'Kits' => 'petite écriture khitan',
 			'Knda' => 'kannara',
 			'Kore' => 'coréen',
 			'Kpel' => 'kpelle',
 			'Krai' => 'kirat rai',
 			'Kthi' => 'kaithî',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'latin (variante brisée)',
 			'Latg' => 'latin (variante gaélique)',
 			'Latn' => 'latin',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbou',
 			'Lina' => 'linéaire A',
 			'Linb' => 'linéaire B',
 			'Lisu' => 'lisu',
 			'Loma' => 'loma',
 			'Lyci' => 'lycien',
 			'Lydi' => 'lydien',
 			'Mahj' => 'mahadjani',
 			'Maka' => 'makasar',
 			'Mand' => 'mandéen',
 			'Mani' => 'manichéen',
 			'Marc' => 'mar chen',
 			'Maya' => 'hiéroglyphes mayas',
 			'Medf' => 'medefidrin',
 			'Mend' => 'mendé',
 			'Merc' => 'méroïtique cursif',
 			'Mero' => 'méroïtique',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modi',
 			'Mong' => 'mongol',
 			'Moon' => 'moon',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei mayek',
 			'Mult' => 'multani',
 			'Mymr' => 'birman',
 			'Nagm' => 'nag mundari',
 			'Nand' => 'nandinagari',
 			'Narb' => 'nord-arabique',
 			'Nbat' => 'nabatéen',
 			'Newa' => 'néwa',
 			'Nkgb' => 'géba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogam',
 			'Olck' => 'ol-chiki',
 			'Onao' => 'ol onal',
 			'Orkh' => 'orkhon',
 			'Orya' => 'odia',
 			'Osge' => 'osage',
 			'Osma' => 'osmanais',
 			'Ougr' => 'ancien ouïgour',
 			'Palm' => 'palmyrénien',
 			'Pauc' => 'paou chin haou',
 			'Perm' => 'ancien permien',
 			'Phag' => 'phags pa',
 			'Phli' => 'pehlevi des inscriptions',
 			'Phlp' => 'pehlevi des psautiers',
 			'Phlv' => 'pehlevi des livres',
 			'Phnx' => 'phénicien',
 			'Plrd' => 'phonétique de Pollard',
 			'Prti' => 'parthe des inscriptions',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runique',
 			'Samr' => 'samaritain',
 			'Sara' => 'sarati',
 			'Sarb' => 'sudarabique',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'écriture des signes',
 			'Shaw' => 'shavien',
 			'Shrd' => 'charada',
 			'Sidd' => 'siddham',
 			'Sind' => 'sindhi',
 			'Sinh' => 'cingalais',
 			'Sogd' => 'sogdien',
 			'Sogo' => 'sogdien ancien',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyombo',
 			'Sund' => 'sundanais',
 			'Sunu' => 'sunuwar',
 			'Sylo' => 'sylotî nâgrî',
 			'Syrc' => 'syriaque',
 			'Syre' => 'syriaque estranghélo',
 			'Syrj' => 'syriaque occidental',
 			'Syrn' => 'syriaque oriental',
 			'Tagb' => 'tagbanoua',
 			'Takr' => 'takri',
 			'Tale' => 'taï-le',
 			'Talu' => 'nouveau taï-lue',
 			'Taml' => 'tamoul',
 			'Tang' => 'tangoute',
 			'Tavt' => 'taï viêt',
 			'Telu' => 'télougou',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagal',
 			'Thaa' => 'thâna',
 			'Thai' => 'thaï',
 			'Tibt' => 'tibétain',
 			'Tirh' => 'tirhouta',
 			'Tnsa' => 'tangsa',
 			'Todr' => 'todhri',
 			'Toto' => 'toto',
 			'Tutg' => 'tulu-tigalari',
 			'Ugar' => 'ougaritique',
 			'Vaii' => 'vaï',
 			'Visp' => 'parole visible',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'warang citi',
 			'Wcho' => 'wantcho',
 			'Wole' => 'woléaï',
 			'Xpeo' => 'cunéiforme persépolitain',
 			'Xsux' => 'cunéiforme suméro-akkadien',
 			'Yezi' => 'yézidi',
 			'Yiii' => 'yi',
 			'Zanb' => 'zanabazar carré',
 			'Zinh' => 'hérité',
 			'Zmth' => 'notation mathématique',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symboles',
 			'Zxxx' => 'non écrit',
 			'Zyyy' => 'commun',
 			'Zzzz' => 'écriture inconnue',

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
			'001' => 'Monde',
 			'002' => 'Afrique',
 			'003' => 'Amérique du Nord',
 			'005' => 'Amérique du Sud',
 			'009' => 'Océanie',
 			'011' => 'Afrique occidentale',
 			'013' => 'Amérique centrale',
 			'014' => 'Afrique orientale',
 			'015' => 'Afrique septentrionale',
 			'017' => 'Afrique centrale',
 			'018' => 'Afrique australe',
 			'019' => 'Amériques',
 			'021' => 'Amérique septentrionale',
 			'029' => 'Caraïbes',
 			'030' => 'Asie de l’Est',
 			'034' => 'Asie du Sud',
 			'035' => 'Asie du Sud-Est',
 			'039' => 'Europe du Sud',
 			'053' => 'Australasie',
 			'054' => 'Mélanésie',
 			'057' => 'région micronésienne',
 			'061' => 'Polynésie',
 			'142' => 'Asie',
 			'143' => 'Asie centrale',
 			'145' => 'Asie de l’Ouest',
 			'150' => 'Europe',
 			'151' => 'Europe de l’Est',
 			'154' => 'Europe du Nord',
 			'155' => 'Europe de l’Ouest',
 			'202' => 'Afrique subsaharienne',
 			'419' => 'Amérique latine',
 			'AC' => 'Île de l’Ascension',
 			'AD' => 'Andorre',
 			'AE' => 'Émirats arabes unis',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua-et-Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanie',
 			'AM' => 'Arménie',
 			'AO' => 'Angola',
 			'AQ' => 'Antarctique',
 			'AR' => 'Argentine',
 			'AS' => 'Samoa américaines',
 			'AT' => 'Autriche',
 			'AU' => 'Australie',
 			'AW' => 'Aruba',
 			'AX' => 'Îles Åland',
 			'AZ' => 'Azerbaïdjan',
 			'BA' => 'Bosnie-Herzégovine',
 			'BB' => 'Barbade',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgique',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarie',
 			'BH' => 'Bahreïn',
 			'BI' => 'Burundi',
 			'BJ' => 'Bénin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermudes',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivie',
 			'BQ' => 'Pays-Bas caribéens',
 			'BR' => 'Brésil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhoutan',
 			'BV' => 'Île Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Biélorussie',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Îles Cocos',
 			'CD' => 'Congo-Kinshasa',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'République centrafricaine',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'République du Congo',
 			'CH' => 'Suisse',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'République de Côte d’Ivoire',
 			'CK' => 'Îles Cook',
 			'CL' => 'Chili',
 			'CM' => 'Cameroun',
 			'CN' => 'Chine',
 			'CO' => 'Colombie',
 			'CP' => 'Île Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cap-Vert',
 			'CW' => 'Curaçao',
 			'CX' => 'Île Christmas',
 			'CY' => 'Chypre',
 			'CZ' => 'Tchéquie',
 			'CZ@alt=variant' => 'République tchèque',
 			'DE' => 'Allemagne',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danemark',
 			'DM' => 'Dominique',
 			'DO' => 'République dominicaine',
 			'DZ' => 'Algérie',
 			'EA' => 'Ceuta et Melilla',
 			'EC' => 'Équateur',
 			'EE' => 'Estonie',
 			'EG' => 'Égypte',
 			'EH' => 'Sahara occidental',
 			'ER' => 'Érythrée',
 			'ES' => 'Espagne',
 			'ET' => 'Éthiopie',
 			'EU' => 'Union européenne',
 			'EZ' => 'zone euro',
 			'FI' => 'Finlande',
 			'FJ' => 'Fidji',
 			'FK' => 'Îles Malouines',
 			'FK@alt=variant' => 'Îles Malouines (Îles Falkland)',
 			'FM' => 'Micronésie',
 			'FO' => 'Îles Féroé',
 			'FR' => 'France',
 			'GA' => 'Gabon',
 			'GB' => 'Royaume-Uni',
 			'GB@alt=short' => 'R.-U.',
 			'GD' => 'Grenade',
 			'GE' => 'Géorgie',
 			'GF' => 'Guyane française',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenland',
 			'GM' => 'Gambie',
 			'GN' => 'Guinée',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Guinée équatoriale',
 			'GR' => 'Grèce',
 			'GS' => 'Géorgie du Sud-et-les Îles Sandwich du Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinée-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'R.A.S. chinoise de Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Îles Heard-et-MacDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croatie',
 			'HT' => 'Haïti',
 			'HU' => 'Hongrie',
 			'IC' => 'Îles Canaries',
 			'ID' => 'Indonésie',
 			'IE' => 'Irlande',
 			'IL' => 'Israël',
 			'IM' => 'Île de Man',
 			'IN' => 'Inde',
 			'IO' => 'Territoire britannique de l’océan Indien',
 			'IO@alt=chagos' => 'Archipel des Chagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islande',
 			'IT' => 'Italie',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaïque',
 			'JO' => 'Jordanie',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizstan',
 			'KH' => 'Cambodge',
 			'KI' => 'Kiribati',
 			'KM' => 'Comores',
 			'KN' => 'Saint-Christophe-et-Niévès',
 			'KP' => 'Corée du Nord',
 			'KR' => 'Corée du Sud',
 			'KW' => 'Koweït',
 			'KY' => 'Îles Caïmans',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Sainte-Lucie',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituanie',
 			'LU' => 'Luxembourg',
 			'LV' => 'Lettonie',
 			'LY' => 'Libye',
 			'MA' => 'Maroc',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavie',
 			'ME' => 'Monténégro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Îles Marshall',
 			'MK' => 'Macédoine du Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmanie)',
 			'MN' => 'Mongolie',
 			'MO' => 'R.A.S. chinoise de Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Îles Mariannes du Nord',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritanie',
 			'MS' => 'Montserrat',
 			'MT' => 'Malte',
 			'MU' => 'Maurice',
 			'MV' => 'Maldives',
 			'MW' => 'Malawi',
 			'MX' => 'Mexique',
 			'MY' => 'Malaisie',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibie',
 			'NC' => 'Nouvelle-Calédonie',
 			'NE' => 'Niger',
 			'NF' => 'Île Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Pays-Bas',
 			'NO' => 'Norvège',
 			'NP' => 'Népal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nouvelle-Zélande',
 			'NZ@alt=variant' => 'Aotearoa (Nouvelle-Zélande)',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Pérou',
 			'PF' => 'Polynésie française',
 			'PG' => 'Papouasie-Nouvelle-Guinée',
 			'PH' => 'Philippines',
 			'PK' => 'Pakistan',
 			'PL' => 'Pologne',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Îles Pitcairn',
 			'PR' => 'Porto Rico',
 			'PS' => 'Territoires palestiniens',
 			'PS@alt=short' => 'Palestine',
 			'PT' => 'Portugal',
 			'PW' => 'Palaos',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'régions éloignées de l’Océanie',
 			'RE' => 'La Réunion',
 			'RO' => 'Roumanie',
 			'RS' => 'Serbie',
 			'RU' => 'Russie',
 			'RW' => 'Rwanda',
 			'SA' => 'Arabie saoudite',
 			'SB' => 'Îles Salomon',
 			'SC' => 'Seychelles',
 			'SD' => 'Soudan',
 			'SE' => 'Suède',
 			'SG' => 'Singapour',
 			'SH' => 'Sainte-Hélène',
 			'SI' => 'Slovénie',
 			'SJ' => 'Svalbard et Jan Mayen',
 			'SK' => 'Slovaquie',
 			'SL' => 'Sierra Leone',
 			'SM' => 'Saint-Marin',
 			'SN' => 'Sénégal',
 			'SO' => 'Somalie',
 			'SR' => 'Suriname',
 			'SS' => 'Soudan du Sud',
 			'ST' => 'Sao Tomé-et-Principe',
 			'SV' => 'Salvador',
 			'SX' => 'Saint-Martin (partie néerlandaise)',
 			'SY' => 'Syrie',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Îles Turques-et-Caïques',
 			'TD' => 'Tchad',
 			'TF' => 'Terres australes françaises',
 			'TG' => 'Togo',
 			'TH' => 'Thaïlande',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor oriental',
 			'TL@alt=variant' => 'Timor-Oriental',
 			'TM' => 'Turkménistan',
 			'TN' => 'Tunisie',
 			'TO' => 'Tonga',
 			'TR' => 'Turquie',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trinité-et-Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taïwan',
 			'TZ' => 'Tanzanie',
 			'UA' => 'Ukraine',
 			'UG' => 'Ouganda',
 			'UM' => 'Îles mineures éloignées des États-Unis',
 			'UN' => 'Nations Unies',
 			'UN@alt=short' => 'ONU',
 			'US' => 'États-Unis',
 			'US@alt=short' => 'É.-U.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Ouzbékistan',
 			'VA' => 'État de la Cité du Vatican',
 			'VC' => 'Saint-Vincent-et-les Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Îles Vierges britanniques',
 			'VI' => 'Îles Vierges des États-Unis',
 			'VN' => 'Viêt Nam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis-et-Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-accents',
 			'XB' => 'pseudo-bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yémen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afrique du Sud',
 			'ZM' => 'Zambie',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'région indéterminée',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'orthographe allemande traditionnelle',
 			'1994' => 'orthographe normalisée de Resia',
 			'1996' => 'orthographe allemande de 1996',
 			'1606NICT' => 'françoys de 1606',
 			'1694ACAD' => 'françois académique de 1694',
 			'1959ACAD' => 'académique de 1959',
 			'ABL1943' => 'orthographe brésilienne de 1943',
 			'AKUAPEM' => 'akuapem',
 			'ALALC97' => 'romanisation ALA-LC de 1997',
 			'ALUKU' => 'dialecte aluku',
 			'AO1990' => 'orthographe portugaise de 1990',
 			'ARANES' => 'aranais',
 			'AREVELA' => 'arménien oriental',
 			'AREVMDA' => 'arménien occidental',
 			'ASANTE' => 'asante',
 			'AUVERN' => 'auvergnat',
 			'BAKU1926' => 'alphabet latin altaïque unifié',
 			'BALANKA' => 'dialecte balanka d’Anii',
 			'BARLA' => 'groupe dialectal capverdien barlavento',
 			'BASICENG' => 'anglais basic',
 			'BAUDDHA' => 'variante hybride bouddhiste',
 			'BISCAYAN' => 'biscayen',
 			'BISKE' => 'dialecte de San Giorgio / Bila',
 			'BOHORIC' => 'alphabet Bohorič',
 			'BOONT' => 'dialecte boontling',
 			'CISAUP' => 'cisalpin',
 			'COLB1945' => 'orthographe brésilienne de 1945',
 			'CORNU' => 'cornique',
 			'CREISS' => 'parlers du Croissant',
 			'DAJNKO' => 'alphabet Dajnko',
 			'EKAVSK' => 'prononciation serbe ékavienne',
 			'EMODENG' => 'ancien anglais moderne',
 			'FONIPA' => 'alphabet phonétique international',
 			'FONKIRSH' => 'alphabet phonétique de Kirshenbaum',
 			'FONNAPA' => 'alphabet phonétique nord-américain',
 			'FONUPA' => 'alphabet phonétique ouralique',
 			'FONXSAMP' => 'alphabet phonétique X-SAMPA',
 			'GASCON' => 'gascon',
 			'GRCLASS' => 'orthographe occitane classique',
 			'GRITAL' => 'orthographe occitane italisante',
 			'GRMISTR' => 'orthographe occitane mistralienne',
 			'HEPBURN' => 'romanisation Hepburn',
 			'HOGNORSK' => 'dialecte høgnorsk',
 			'HSISTEMO' => 'système orthographique H de l’espéranto',
 			'IJEKAVSK' => 'prononciation serbe ijékavienne',
 			'ITIHASA' => 'variante épique',
 			'IVANCHOV' => 'orthographe bulgare de 1899',
 			'JAUER' => 'dialecte jauer',
 			'JYUTPING' => 'romanisation Jyutping',
 			'KKCOR' => 'orthographe commune',
 			'KOCIEWIE' => 'dialecte polonais kociewiacy',
 			'KSCOR' => 'orthographe standard',
 			'LAUKIKA' => 'variante classique',
 			'LEMOSIN' => 'limousin',
 			'LENGADOC' => 'languedocien',
 			'LIPAW' => 'dialecte lipovaz de Resia',
 			'LUNA1918' => 'orthographe russe réformée de 1918',
 			'METELKO' => 'alphabet Metelko',
 			'MONOTON' => 'monotonique',
 			'NDYUKA' => 'dialecte ndyuka',
 			'NEDIS' => 'dialecte de Natisone',
 			'NEWFOUND' => 'anglais de Terre-Neuve',
 			'NICARD' => 'niçard',
 			'NJIVA' => 'dialecte de Gniva / Njiva',
 			'NULIK' => 'volapük moderne',
 			'OSOJS' => 'dialecte d’Oseacco / Osojane',
 			'OXENDICT' => 'orthographe anglaise du dictionnaire d’Oxford',
 			'PAHAWH2' => 'orthographe réduite pahawh hmong phase 2',
 			'PAHAWH3' => 'orthographe réduite pahawh hmong phase 3',
 			'PAHAWH4' => 'orthographe pahawh hmong version finale',
 			'PAMAKA' => 'dialecte pamaka',
 			'PETR1708' => 'orthographe pétrine de 1708',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonique',
 			'POSIX' => 'informatique',
 			'PROVENC' => 'provençal',
 			'PUTER' => 'idiome puter',
 			'REVISED' => 'orthographe révisée',
 			'RIGIK' => 'volapük classique',
 			'ROZAJ' => 'dialecte de Resia',
 			'RUMGR' => 'standard des Grisons',
 			'SAAHO' => 'dialecte saho',
 			'SCOTLAND' => 'anglais standard écossais',
 			'SCOUSE' => 'dialecte scouse',
 			'SIMPLE' => 'simplifié',
 			'SOLBA' => 'dialecte de Stolvizza / Solbica',
 			'SOTAV' => 'groupe dialectal capverdien sotavento',
 			'SPANGLIS' => 'spanglish',
 			'SURMIRAN' => 'idiome surmiran',
 			'SURSILV' => 'idiome sursilvan',
 			'SUTSILV' => 'idiome sutsilvan',
 			'TARASK' => 'orthographe taraskievica',
 			'UCCOR' => 'orthographe unifiée',
 			'UCRCOR' => 'orthographe révisée unifiée',
 			'ULSTER' => 'orthographe de l’Ulster',
 			'UNIFON' => 'alphabet phonétique Unifon',
 			'VAIDIKA' => 'variante védique',
 			'VALENCIA' => 'valencien',
 			'VALLADER' => 'idiome vallader',
 			'VIVARAUP' => 'vivaro-alpin',
 			'WADEGILE' => 'Wade-Giles',
 			'XSISTEMO' => 'système orthographique X de l’espéranto',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'calendrier',
 			'cf' => 'format de devise',
 			'colalternate' => 'tri ne tenant pas compte des symboles',
 			'colbackwards' => 'tri inversé des caractères accentués',
 			'colcasefirst' => 'classement basé sur les majuscules et les minuscules',
 			'colcaselevel' => 'tri sensible à la casse',
 			'collation' => 'ordre de tri',
 			'colnormalization' => 'tri normalisé',
 			'colnumeric' => 'tri numérique',
 			'colstrength' => 'priorité du tri',
 			'currency' => 'devise',
 			'hc' => 'système horaire (12 ou 24 heures)',
 			'lb' => 'style de saut de ligne',
 			'ms' => 'système de mesure',
 			'numbers' => 'nombres',
 			'timezone' => 'fuseau horaire',
 			'va' => 'variante locale',
 			'x' => 'usage privé',

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
 				'buddhist' => q{calendrier bouddhiste},
 				'chinese' => q{calendrier chinois},
 				'coptic' => q{calendrier copte},
 				'dangi' => q{calendrier dangi},
 				'ethiopic' => q{calendrier éthiopien},
 				'ethiopic-amete-alem' => q{calendrier éthiopien Amete Alem},
 				'gregorian' => q{calendrier grégorien},
 				'hebrew' => q{calendrier hébraïque},
 				'indian' => q{calendrier indien},
 				'islamic' => q{calendrier hégirien},
 				'islamic-civil' => q{calendrier hégirien (tabulaire, époque civile)},
 				'islamic-rgsa' => q{calendrier musulman (observé, Arabie Saoudite)},
 				'islamic-tbla' => q{calendrier hégirien (tabulaire, époque astronomique)},
 				'islamic-umalqura' => q{calendrier hégirien (Umm al-Qura)},
 				'iso8601' => q{calendrier ISO 8601},
 				'japanese' => q{calendrier japonais},
 				'persian' => q{calendrier persan},
 				'roc' => q{calendrier républicain chinois},
 			},
 			'cf' => {
 				'account' => q{format de devise comptable},
 				'standard' => q{format de devise standard},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Trier les symboles},
 				'shifted' => q{Trier en ignorant les symboles},
 			},
 			'colbackwards' => {
 				'no' => q{Trier les caractères accentués normalement},
 				'yes' => q{Trier les caractères accentués dans l’ordre inverse},
 			},
 			'colcasefirst' => {
 				'lower' => q{Trier avec les minuscules d’abord},
 				'no' => q{Trier sans ordre lié à la casse},
 				'upper' => q{Trier avec les majuscules d’abord},
 			},
 			'colcaselevel' => {
 				'no' => q{Trier sans tenir compte de la casse},
 				'yes' => q{Trier en tenant compte de la casse},
 			},
 			'collation' => {
 				'big5han' => q{ordre chinois traditionnel - Big5},
 				'compat' => q{ancien ordre de tri pour compatibilité},
 				'dictionary' => q{ordre du dictionnaire},
 				'ducet' => q{ordre de tri Unicode par défaut},
 				'emoji' => q{ordre des emoji},
 				'eor' => q{règles de classement européen},
 				'gb2312han' => q{ordre chinois simplifié - GB2312},
 				'phonebook' => q{ordre de l’annuaire},
 				'phonetic' => q{ordre de tri phonétique},
 				'pinyin' => q{ordre pinyin},
 				'search' => q{recherche générique},
 				'searchjl' => q{rechercher par consonne initiale en hangeul},
 				'standard' => q{ordre de tri standard},
 				'stroke' => q{ordre des traits},
 				'traditional' => q{ordre traditionnel},
 				'unihan' => q{ordre de tri radical-traits},
 				'zhuyin' => q{ordre zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Trier sans normalisation},
 				'yes' => q{Trier avec normalisation Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Trier les chiffres individuellement},
 				'yes' => q{Trier les chiffres par ordre numérique},
 			},
 			'colstrength' => {
 				'identical' => q{Tout trier},
 				'primary' => q{Ne trier que les lettres de base},
 				'quaternary' => q{Trier en tenant compte des caractères accentués, de la casse, de la largeur et des caractères Kana},
 				'secondary' => q{Trier en tenant compte des caractères accentués},
 				'tertiary' => q{Trier en tenant compte des caractères accentués, de la casse et de la largeur},
 			},
 			'd0' => {
 				'fwidth' => q{en pleine chasse},
 				'hwidth' => q{en demi-chasse},
 				'npinyin' => q{Numérique},
 			},
 			'hc' => {
 				'h11' => q{système horaire de 12 heures (0–11)},
 				'h12' => q{système horaire de 12 heures (1–12)},
 				'h23' => q{système horaire de 24 heures (0–23)},
 				'h24' => q{système horaire de 24 heures (1–24)},
 			},
 			'lb' => {
 				'loose' => q{style de saut de ligne permissif},
 				'normal' => q{style de saut de ligne normal},
 				'strict' => q{style de saut de ligne strict},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{système métrique},
 				'uksystem' => q{système impérial},
 				'ussystem' => q{système américain},
 			},
 			'numbers' => {
 				'ahom' => q{chiffres ahoms},
 				'arab' => q{chiffres arabes},
 				'arabext' => q{chiffres arabes étendus},
 				'armn' => q{chiffres arméniens},
 				'armnlow' => q{chiffres arméniens minuscules},
 				'bali' => q{chiffres balinais},
 				'beng' => q{chiffres bengalis},
 				'brah' => q{chiffres brahmis},
 				'cakm' => q{chiffres chakmas},
 				'cham' => q{chiffres chams},
 				'cyrl' => q{nombres cyrilliques},
 				'deva' => q{chiffres dévanagaris},
 				'diak' => q{chiffres dives akuru},
 				'ethi' => q{chiffres éthiopiens},
 				'finance' => q{Chiffres financiers},
 				'fullwide' => q{chiffres pleine chasse},
 				'gara' => q{chiffres garays},
 				'geor' => q{chiffres géorgiens},
 				'gong' => q{chiffres gondi gunjala},
 				'gonm' => q{chiffres gondi masaram},
 				'grek' => q{chiffres grecs},
 				'greklow' => q{chiffres grecs minuscules},
 				'gujr' => q{chiffres goudjarâtîs},
 				'gukh' => q{chiffres gurung khemas},
 				'guru' => q{chiffres gourmoukhîs},
 				'hanidec' => q{nombres décimaux chinois},
 				'hans' => q{chiffres en chinois simplifié},
 				'hansfin' => q{chiffres financiers en chinois simplifié},
 				'hant' => q{chiffres en chinois traditionnel},
 				'hantfin' => q{chiffres financiers en chinois traditionnel},
 				'hebr' => q{chiffres hébreux},
 				'hmng' => q{chiffres pahawh hmongs},
 				'hmnp' => q{chiffres nyiakeng puachue hmong},
 				'java' => q{chiffres javanais},
 				'jpan' => q{chiffres japonais},
 				'jpanfin' => q{chiffres japonais financiers},
 				'kali' => q{chiffres kayah li},
 				'kawi' => q{chiffres kawis},
 				'khmr' => q{chiffres khmers},
 				'knda' => q{chiffres en kannada},
 				'krai' => q{chiffres kirat rais},
 				'lana' => q{chiffres lannas horas},
 				'lanatham' => q{chiffres lannas thams},
 				'laoo' => q{chiffres laotiens},
 				'latn' => q{chiffres occidentaux},
 				'lepc' => q{chiffres lepchas},
 				'limb' => q{chiffres limbous},
 				'mathbold' => q{chiffres gras mathématiques},
 				'mathdbl' => q{chiffres ajourés mathématiques},
 				'mathmono' => q{chiffres à chasse fixe mathématiques},
 				'mathsanb' => q{chiffres gras linéaux mathématiques},
 				'mathsans' => q{chiffres linéaux mathématiques},
 				'mlym' => q{chiffres malayâlams},
 				'modi' => q{chiffres modis},
 				'mong' => q{chiffres mongols},
 				'mroo' => q{chiffres mros},
 				'mtei' => q{chiffres meitei-mayeks},
 				'mymr' => q{chiffres birmans},
 				'mymrepka' => q{chiffres birmans de pwo karen de l’Est},
 				'mymrpao' => q{chiffres birmans pao},
 				'mymrshan' => q{chiffres birmans shans},
 				'mymrtlng' => q{chiffres birmans tai laings},
 				'nagm' => q{chiffres nag mundaris},
 				'native' => q{chiffres natifs},
 				'nkoo' => q{chiffres n’kos},
 				'olck' => q{chiffres ol-chikis},
 				'onao' => q{chiffres ol onals},
 				'orya' => q{chiffres oriyas},
 				'osma' => q{chiffres osmanyas},
 				'outlined' => q{chiffres entourés},
 				'rohg' => q{chiffres rohingyas hanifis},
 				'roman' => q{chiffres romains},
 				'romanlow' => q{chiffres romains minuscules},
 				'saur' => q{chiffres saurashtras},
 				'shrd' => q{chiffres sharadas},
 				'sind' => q{chiffres khudawadis},
 				'sinh' => q{chiffres cinghalais liths},
 				'sora' => q{chiffres sora-sompengs},
 				'sund' => q{chiffres soundanais},
 				'sunu' => q{chiffres sunuwars},
 				'takr' => q{chiffres takris},
 				'talu' => q{chiffres néo-taï-luës},
 				'taml' => q{chiffres tamouls traditionnels},
 				'tamldec' => q{chiffres tamouls},
 				'telu' => q{chiffres télougous},
 				'thai' => q{chiffres thaïs},
 				'tibt' => q{chiffres tibétains},
 				'tirh' => q{chiffres tirhutas},
 				'tnsa' => q{chiffres tangsas},
 				'traditional' => q{Chiffres traditionnels},
 				'vaii' => q{chiffres en vaï},
 				'wara' => q{chiffres warang-citis},
 				'wcho' => q{chiffres wantcho},
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
			'metric' => q{métrique},
 			'UK' => q{impérial},
 			'US' => q{américain},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'langue : {0}',
 			'script' => 'écriture : {0}',
 			'region' => 'région : {0}',

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
			auxiliary => qr{[áåäãā ć ē íìī ĳ ñ óòöõø ř šſ ß úǔ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aàâ æ b cç d eéèêë f g h iîï j k l m n oô œ p q r s t uùûü v w x yÿ z]},
			numbers => qr{[  \- ‑ , . % ‰ + − 0 1 2² 3³ 4 5 6 7 8 9 ᵈ ᵉ ʳ ˢ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … ’ "“” « » ( ) \[ \] § @ * / \& # † ‡]},
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
			'initial' => '… {0}',
			'medial' => '{0}… {1}',
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
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
						'1' => q(mébi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mébi{0}),
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
						'1' => q(tébi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tébi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pébi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pébi{0}),
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
						'1' => q(zébi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zébi{0}),
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
						'1' => q(déci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(déci{0}),
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
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
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
						'1' => q(déca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(déca{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(téra{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(téra{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(péta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(péta{0}),
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
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
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
						'1' => q(méga{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(méga{0}),
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
						'name' => q(accélération de pesanteur terrestre),
						'one' => q({0} fois l’accélération de pesanteur terrestre),
						'other' => q({0} fois l’accélération de pesanteur terrestre),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'name' => q(accélération de pesanteur terrestre),
						'one' => q({0} fois l’accélération de pesanteur terrestre),
						'other' => q({0} fois l’accélération de pesanteur terrestre),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(mètres par seconde carrée),
						'one' => q({0} mètre par seconde carrée),
						'other' => q({0} mètres par seconde carrée),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(mètres par seconde carrée),
						'one' => q({0} mètre par seconde carrée),
						'other' => q({0} mètres par seconde carrée),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'name' => q(minutes d’arc),
						'one' => q({0} minute d’arc),
						'other' => q({0} minutes d’arc),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'name' => q(minutes d’arc),
						'one' => q({0} minute d’arc),
						'other' => q({0} minutes d’arc),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'name' => q(secondes d’arc),
						'one' => q({0} seconde d’arc),
						'other' => q({0} secondes d’arc),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'name' => q(secondes d’arc),
						'one' => q({0} seconde d’arc),
						'other' => q({0} secondes d’arc),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(masculine),
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'name' => q(radians),
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'name' => q(radians),
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(masculine),
						'name' => q(tours),
						'one' => q({0} tour),
						'other' => q({0} tours),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(masculine),
						'name' => q(tours),
						'one' => q({0} tour),
						'other' => q({0} tours),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(feminine),
						'name' => q(acres anglo-saxonnes),
						'one' => q({0} acre anglo-saxonne),
						'other' => q({0} acres anglo-saxonnes),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(feminine),
						'name' => q(acres anglo-saxonnes),
						'one' => q({0} acre anglo-saxonne),
						'other' => q({0} acres anglo-saxonnes),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dounams),
						'one' => q({0} dounam),
						'other' => q({0} dounams),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dounams),
						'one' => q({0} dounam),
						'other' => q({0} dounams),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimètres carrés),
						'one' => q({0} centimètre carré),
						'other' => q({0} centimètres carrés),
						'per' => q({0} par centimètre carré),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimètres carrés),
						'one' => q({0} centimètre carré),
						'other' => q({0} centimètres carrés),
						'per' => q({0} par centimètre carré),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'name' => q(pieds carrés),
						'one' => q({0} pied carré),
						'other' => q({0} pieds carrés),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'name' => q(pieds carrés),
						'one' => q({0} pied carré),
						'other' => q({0} pieds carrés),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pouces carrés),
						'one' => q({0} pouce carré),
						'other' => q({0} pouces carrés),
						'per' => q({0} par pouce carré),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pouces carrés),
						'one' => q({0} pouce carré),
						'other' => q({0} pouces carrés),
						'per' => q({0} par pouce carré),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres carrés),
						'one' => q({0} kilomètre carré),
						'other' => q({0} kilomètres carrés),
						'per' => q({0} par kilomètre carré),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres carrés),
						'one' => q({0} kilomètre carré),
						'other' => q({0} kilomètres carrés),
						'per' => q({0} par kilomètre carré),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(mètres carrés),
						'one' => q({0} mètre carré),
						'other' => q({0} mètres carrés),
						'per' => q({0} par mètre carré),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(mètres carrés),
						'one' => q({0} mètre carré),
						'other' => q({0} mètres carrés),
						'per' => q({0} par mètre carré),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(masculine),
						'name' => q(milles carrés),
						'one' => q({0} mille carré),
						'other' => q({0} milles carrés),
						'per' => q({0} par mille carré),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(masculine),
						'name' => q(milles carrés),
						'one' => q({0} mille carré),
						'other' => q({0} milles carrés),
						'per' => q({0} par mille carré),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yards carrés),
						'one' => q({0} yard carré),
						'other' => q({0} yards carrés),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yards carrés),
						'one' => q({0} yard carré),
						'other' => q({0} yards carrés),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'name' => q(items),
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'name' => q(items),
						'one' => q({0} item),
						'other' => q({0} items),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(milligrammes par décilitre),
						'one' => q({0} milligramme par décilitre),
						'other' => q({0} milligrammes par décilitre),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(milligrammes par décilitre),
						'one' => q({0} milligramme par décilitre),
						'other' => q({0} milligrammes par décilitre),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(feminine),
						'name' => q(millimoles par litre),
						'one' => q({0} millimole par litre),
						'other' => q({0} millimoles par litre),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(feminine),
						'name' => q(millimoles par litre),
						'one' => q({0} millimole par litre),
						'other' => q({0} millimoles par litre),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(feminine),
						'name' => q(moles),
						'one' => q({0} mole),
						'other' => q({0} moles),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(feminine),
						'name' => q(moles),
						'one' => q({0} mole),
						'other' => q({0} moles),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'name' => q(pour cent),
						'one' => q({0} pour cent),
						'other' => q({0} pour cent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'name' => q(pour cent),
						'one' => q({0} pour cent),
						'other' => q({0} pour cent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'name' => q(pour mille),
						'one' => q({0} pour mille),
						'other' => q({0} pour mille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'name' => q(pour mille),
						'one' => q({0} pour mille),
						'other' => q({0} pour mille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'name' => q(parts par million),
						'one' => q({0} part par million),
						'other' => q({0} parts par million),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'name' => q(parts par million),
						'one' => q({0} part par million),
						'other' => q({0} parts par million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'name' => q(pour dix mille),
						'one' => q({0} pour dix mille),
						'other' => q({0} pour dix mille),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'name' => q(pour dix mille),
						'one' => q({0} pour dix mille),
						'other' => q({0} pour dix mille),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(feminine),
						'name' => q(parts par milliard),
						'one' => q({0} part par milliard),
						'other' => q({0} parts par milliard),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(feminine),
						'name' => q(parts par milliard),
						'one' => q({0} part par milliard),
						'other' => q({0} parts par milliard),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres aux 100 km),
						'one' => q({0} litre aux 100 km),
						'other' => q({0} litres aux 100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres aux 100 km),
						'one' => q({0} litre aux 100 km),
						'other' => q({0} litres aux 100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres au kilomètre),
						'one' => q({0} litre au kilomètre),
						'other' => q({0} litres au kilomètre),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litres au kilomètre),
						'one' => q({0} litre au kilomètre),
						'other' => q({0} litres au kilomètre),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(masculine),
						'name' => q(miles par gallon),
						'one' => q({0} mile par gallon),
						'other' => q({0} miles par gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(masculine),
						'name' => q(miles par gallon),
						'one' => q({0} mile par gallon),
						'other' => q({0} miles par gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(miles par gallon impérial),
						'one' => q({0} mile par gallon impérial),
						'other' => q({0} miles par gallon impérial),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(miles par gallon impérial),
						'one' => q({0} mile par gallon impérial),
						'other' => q({0} miles par gallon impérial),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ouest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ouest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'name' => q(octets),
						'one' => q({0} octet),
						'other' => q({0} octets),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'name' => q(octets),
						'one' => q({0} octet),
						'other' => q({0} octets),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigaoctets),
						'one' => q({0} gigaoctet),
						'other' => q({0} gigaoctets),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigaoctets),
						'one' => q({0} gigaoctet),
						'other' => q({0} gigaoctets),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilooctets),
						'one' => q({0} kilooctet),
						'other' => q({0} kilooctets),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilooctets),
						'one' => q({0} kilooctet),
						'other' => q({0} kilooctets),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'name' => q(mégabits),
						'one' => q({0} mégabit),
						'other' => q({0} mégabits),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'name' => q(mégabits),
						'one' => q({0} mégabit),
						'other' => q({0} mégabits),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'name' => q(mégaoctets),
						'one' => q({0} mégaoctet),
						'other' => q({0} mégaoctets),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'name' => q(mégaoctets),
						'one' => q({0} mégaoctet),
						'other' => q({0} mégaoctets),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
						'name' => q(pétaoctets),
						'one' => q({0} pétaoctet),
						'other' => q({0} pétaoctets),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'name' => q(pétaoctets),
						'one' => q({0} pétaoctet),
						'other' => q({0} pétaoctets),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'name' => q(térabits),
						'one' => q({0} térabit),
						'other' => q({0} térabits),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'name' => q(térabits),
						'one' => q({0} térabit),
						'other' => q({0} térabits),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'name' => q(téraoctets),
						'one' => q({0} téraoctet),
						'other' => q({0} téraoctets),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'name' => q(téraoctets),
						'one' => q({0} téraoctet),
						'other' => q({0} téraoctets),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(masculine),
						'name' => q(siècles),
						'one' => q({0} siècle),
						'other' => q({0} siècles),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(siècles),
						'one' => q({0} siècle),
						'other' => q({0} siècles),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'name' => q(jours),
						'one' => q({0} jour),
						'other' => q({0} jours),
						'per' => q({0} par jour),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'name' => q(jours),
						'one' => q({0} jour),
						'other' => q({0} jours),
						'per' => q({0} par jour),
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
						'one' => q({0} décennie),
						'other' => q({0} décennies),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'one' => q({0} décennie),
						'other' => q({0} décennies),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'name' => q(heures),
						'one' => q({0} heure),
						'other' => q({0} heures),
						'per' => q({0} par heure),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'name' => q(heures),
						'one' => q({0} heure),
						'other' => q({0} heures),
						'per' => q({0} par heure),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'name' => q(microsecondes),
						'one' => q({0} microseconde),
						'other' => q({0} microsecondes),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'name' => q(microsecondes),
						'one' => q({0} microseconde),
						'other' => q({0} microsecondes),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'name' => q(millisecondes),
						'one' => q({0} milliseconde),
						'other' => q({0} millisecondes),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'name' => q(millisecondes),
						'one' => q({0} milliseconde),
						'other' => q({0} millisecondes),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'name' => q(minutes),
						'one' => q({0} minute),
						'other' => q({0} minutes),
						'per' => q({0} par minute),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'name' => q(minutes),
						'one' => q({0} minute),
						'other' => q({0} minutes),
						'per' => q({0} par minute),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'name' => q(mois),
						'one' => q({0} mois),
						'other' => q({0} mois),
						'per' => q({0} par mois),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'name' => q(mois),
						'one' => q({0} mois),
						'other' => q({0} mois),
						'per' => q({0} par mois),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanosecondes),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanosecondes),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'name' => q(nanosecondes),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanosecondes),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(feminine),
						'name' => q(nuits),
						'one' => q({0} nuit),
						'other' => q({0} nuits),
						'per' => q({0} par nuit),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(feminine),
						'name' => q(nuits),
						'one' => q({0} nuit),
						'other' => q({0} nuits),
						'per' => q({0} par nuit),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(trimestres),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0}/trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(trimestres),
						'one' => q({0} trimestre),
						'other' => q({0} trimestres),
						'per' => q({0}/trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'name' => q(secondes),
						'one' => q({0} seconde),
						'other' => q({0} secondes),
						'per' => q({0} par seconde),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'name' => q(secondes),
						'one' => q({0} seconde),
						'other' => q({0} secondes),
						'per' => q({0} par seconde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'name' => q(semaines),
						'one' => q({0} semaine),
						'other' => q({0} semaines),
						'per' => q({0} par semaine),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'name' => q(semaines),
						'one' => q({0} semaine),
						'other' => q({0} semaines),
						'per' => q({0} par semaine),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0} par an),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0} par an),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'name' => q(ampères),
						'one' => q({0} ampère),
						'other' => q({0} ampères),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'name' => q(ampères),
						'one' => q({0} ampère),
						'other' => q({0} ampères),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'name' => q(milliampères),
						'one' => q({0} milliampère),
						'other' => q({0} milliampères),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'name' => q(milliampères),
						'one' => q({0} milliampère),
						'other' => q({0} milliampères),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British Thermal Units),
						'one' => q({0} British Thermal Unit),
						'other' => q({0} British Thermal Units),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British Thermal Units),
						'one' => q({0} British Thermal Unit),
						'other' => q({0} British Thermal Units),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(électronvolts),
						'one' => q({0} électronvolt),
						'other' => q({0} électronvolts),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(électronvolts),
						'one' => q({0} électronvolt),
						'other' => q({0} électronvolts),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(kilowatt-heures),
						'one' => q({0} kilowatt-heure),
						'other' => q({0} kilowatt-heures),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(kilowatt-heures),
						'one' => q({0} kilowatt-heure),
						'other' => q({0} kilowatt-heures),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therms US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therms US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilowatt-heures pour 100 kilomètres),
						'one' => q({0} kilowatt-heure pour 100 kilomètres),
						'other' => q({0} kilowatt-heures pour 100 kilomètres),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilowatt-heures pour 100 kilomètres),
						'one' => q({0} kilowatt-heure pour 100 kilomètres),
						'other' => q({0} kilowatt-heures pour 100 kilomètres),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'name' => q(newtons),
						'one' => q({0} newton),
						'other' => q({0} newtons),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(livres-force),
						'one' => q({0} livre-force),
						'other' => q({0} livres-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(livres-force),
						'one' => q({0} livre-force),
						'other' => q({0} livres-force),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'name' => q(mégahertz),
						'one' => q({0} mégahertz),
						'other' => q({0} mégahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'name' => q(mégahertz),
						'one' => q({0} mégahertz),
						'other' => q({0} mégahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(points),
						'one' => q({0} point),
						'other' => q({0} points),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(points),
						'one' => q({0} point),
						'other' => q({0} points),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(points par centimètre),
						'one' => q({0} point par centimètre),
						'other' => q({0} points par centimètre),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(points par centimètre),
						'one' => q({0} point par centimètre),
						'other' => q({0} points par centimètre),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(points par pouce),
						'one' => q({0} point par pouce),
						'other' => q({0} points par pouce),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(points par pouce),
						'one' => q({0} point par pouce),
						'other' => q({0} points par pouce),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(cadratin),
						'one' => q({0} cadratin),
						'other' => q({0} cadratins),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(cadratin),
						'one' => q({0} cadratin),
						'other' => q({0} cadratins),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'name' => q(mégapixels),
						'one' => q({0} mégapixel),
						'other' => q({0} mégapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'name' => q(mégapixels),
						'one' => q({0} mégapixel),
						'other' => q({0} mégapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'name' => q(pixels),
						'one' => q({0} pixel),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixels par centimètre),
						'one' => q({0} pixel par centimètre),
						'other' => q({0} pixels par centimètre),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixels par centimètre),
						'one' => q({0} pixel par centimètre),
						'other' => q({0} pixels par centimètre),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels par pouce),
						'one' => q({0} pixel par pouce),
						'other' => q({0} pixels par pouce),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels par pouce),
						'one' => q({0} pixel par pouce),
						'other' => q({0} pixels par pouce),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unités astronomiques),
						'one' => q({0} unité astronomique),
						'other' => q({0} unités astronomiques),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unités astronomiques),
						'one' => q({0} unité astronomique),
						'other' => q({0} unités astronomiques),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimètres),
						'one' => q({0} centimètre),
						'other' => q({0} centimètres),
						'per' => q({0} par centimètre),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centimètres),
						'one' => q({0} centimètre),
						'other' => q({0} centimètres),
						'per' => q({0} par centimètre),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(décimètres),
						'one' => q({0} décimètre),
						'other' => q({0} décimètres),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(décimètres),
						'one' => q({0} décimètre),
						'other' => q({0} décimètres),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(rayon terrestre),
						'one' => q({0} rayon terrestre),
						'other' => q({0} rayons terrestres),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(rayon terrestre),
						'one' => q({0} rayon terrestre),
						'other' => q({0} rayons terrestres),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(brasses),
						'one' => q({0} brasse),
						'other' => q({0} brasses),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(brasses),
						'one' => q({0} brasse),
						'other' => q({0} brasses),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'name' => q(pieds),
						'one' => q({0} pied),
						'other' => q({0} pieds),
						'per' => q({0} par pied),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'name' => q(pieds),
						'one' => q({0} pied),
						'other' => q({0} pieds),
						'per' => q({0} par pied),
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
						'1' => q(masculine),
						'name' => q(pouces),
						'one' => q({0} pouce),
						'other' => q({0} pouces),
						'per' => q({0} par pouce),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(masculine),
						'name' => q(pouces),
						'one' => q({0} pouce),
						'other' => q({0} pouces),
						'per' => q({0} par pouce),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres),
						'one' => q({0} kilomètre),
						'other' => q({0} kilomètres),
						'per' => q({0} par kilomètre),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres),
						'one' => q({0} kilomètre),
						'other' => q({0} kilomètres),
						'per' => q({0} par kilomètre),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(années-lumière),
						'one' => q({0} année-lumière),
						'other' => q({0} années-lumière),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(années-lumière),
						'one' => q({0} année-lumière),
						'other' => q({0} années-lumière),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(mètres),
						'one' => q({0} mètre),
						'other' => q({0} mètres),
						'per' => q({0} par mètre),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(mètres),
						'one' => q({0} mètre),
						'other' => q({0} mètres),
						'per' => q({0} par mètre),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(micromètres),
						'one' => q({0} micromètre),
						'other' => q({0} micromètres),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(micromètres),
						'one' => q({0} micromètre),
						'other' => q({0} micromètres),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(masculine),
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(masculine),
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(masculine),
						'name' => q(milles scandinaves),
						'one' => q({0} mille scandinave),
						'other' => q({0} milles scandinaves),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(masculine),
						'name' => q(milles scandinaves),
						'one' => q({0} mille scandinave),
						'other' => q({0} milles scandinaves),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(millimètres),
						'one' => q({0} millimètre),
						'other' => q({0} millimètres),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(millimètres),
						'one' => q({0} millimètre),
						'other' => q({0} millimètres),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanomètres),
						'one' => q({0} nanomètre),
						'other' => q({0} nanomètres),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanomètres),
						'one' => q({0} nanomètre),
						'other' => q({0} nanomètres),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milles marins),
						'one' => q({0} mille marin),
						'other' => q({0} milles marins),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milles marins),
						'one' => q({0} mille marin),
						'other' => q({0} milles marins),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(masculine),
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(masculine),
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(picomètres),
						'one' => q({0} picomètre),
						'other' => q({0} picomètres),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(picomètres),
						'one' => q({0} picomètre),
						'other' => q({0} picomètres),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(masculine),
						'one' => q({0} point typographique),
						'other' => q({0} points typographiques),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(masculine),
						'one' => q({0} point typographique),
						'other' => q({0} points typographiques),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'name' => q(rayons solaires),
						'one' => q({0} rayon solaire),
						'other' => q({0} rayons solaires),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'name' => q(rayons solaires),
						'one' => q({0} rayon solaire),
						'other' => q({0} rayons solaires),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(masculine),
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(masculine),
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
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
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosités solaires),
						'one' => q({0} luminosité solaire),
						'other' => q({0} luminosités solaires),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosités solaires),
						'one' => q({0} luminosité solaire),
						'other' => q({0} luminosités solaires),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(masculine),
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(masculine),
						'name' => q(daltons),
						'one' => q({0} dalton),
						'other' => q({0} daltons),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(feminine),
						'name' => q(masses terrestres),
						'one' => q({0} masse terrestre),
						'other' => q({0} masses terrestres),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(feminine),
						'name' => q(masses terrestres),
						'one' => q({0} masse terrestre),
						'other' => q({0} masses terrestres),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(masculine),
						'name' => q(grains),
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(masculine),
						'name' => q(grains),
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'name' => q(grammes),
						'one' => q({0} gramme),
						'other' => q({0} grammes),
						'per' => q({0} par gramme),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'name' => q(grammes),
						'one' => q({0} gramme),
						'other' => q({0} grammes),
						'per' => q({0} par gramme),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogrammes),
						'one' => q({0} kilogramme),
						'other' => q({0} kilogrammes),
						'per' => q({0} par kilogramme),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(kilogrammes),
						'one' => q({0} kilogramme),
						'other' => q({0} kilogrammes),
						'per' => q({0} par kilogramme),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'name' => q(microgrammes),
						'one' => q({0} microgramme),
						'other' => q({0} microgrammes),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'name' => q(microgrammes),
						'one' => q({0} microgramme),
						'other' => q({0} microgrammes),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(milligrammes),
						'one' => q({0} milligramme),
						'other' => q({0} milligrammes),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(milligrammes),
						'one' => q({0} milligramme),
						'other' => q({0} milligrammes),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
						'name' => q(onces),
						'one' => q({0} once),
						'other' => q({0} onces),
						'per' => q({0} par once),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
						'name' => q(onces),
						'one' => q({0} once),
						'other' => q({0} onces),
						'per' => q({0} par once),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(onces troy),
						'one' => q({0} once troy),
						'other' => q({0} onces troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(onces troy),
						'one' => q({0} once troy),
						'other' => q({0} onces troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(feminine),
						'name' => q(livres),
						'one' => q({0} livre),
						'other' => q({0} livres),
						'per' => q({0} par livre),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(feminine),
						'name' => q(livres),
						'one' => q({0} livre),
						'other' => q({0} livres),
						'per' => q({0} par livre),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(feminine),
						'name' => q(masses solaires),
						'one' => q({0} masse solaire),
						'other' => q({0} masses solaires),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(feminine),
						'name' => q(masses solaires),
						'one' => q({0} masse solaire),
						'other' => q({0} masses solaires),
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
						'name' => q(tonnes courtes),
						'one' => q({0} tonne courte),
						'other' => q({0} tonnes courtes),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonnes courtes),
						'one' => q({0} tonne courte),
						'other' => q({0} tonnes courtes),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(tonnes),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(tonnes),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} par {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} par {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(chevaux-vapeur),
						'one' => q({0} cheval-vapeur),
						'other' => q({0} chevaux-vapeur),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(chevaux-vapeur),
						'one' => q({0} cheval-vapeur),
						'other' => q({0} chevaux-vapeur),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'name' => q(mégawatts),
						'one' => q({0} mégawatt),
						'other' => q({0} mégawatts),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'name' => q(mégawatts),
						'one' => q({0} mégawatt),
						'other' => q({0} mégawatts),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					# Long Unit Identifier
					'power2' => {
						'one' => q({0} carré),
						'other' => q({0} carrés),
					},
					# Core Unit Identifier
					'power2' => {
						'one' => q({0} carré),
						'other' => q({0} carrés),
					},
					# Long Unit Identifier
					'power3' => {
						'one' => q({0} cube),
						'other' => q({0} cubes),
					},
					# Core Unit Identifier
					'power3' => {
						'one' => q({0} cube),
						'other' => q({0} cubes),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosphères),
						'one' => q({0} atmosphère),
						'other' => q({0} atmosphères),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosphères),
						'one' => q({0} atmosphère),
						'other' => q({0} atmosphères),
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
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pouces de mercure),
						'one' => q({0} pouce de mercure),
						'other' => q({0} pouces de mercure),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pouces de mercure),
						'one' => q({0} pouce de mercure),
						'other' => q({0} pouces de mercure),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascals),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascals),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascals),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascals),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'name' => q(mégapascals),
						'one' => q({0} mégapascal),
						'other' => q({0} mégapascals),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'name' => q(mégapascals),
						'one' => q({0} mégapascal),
						'other' => q({0} mégapascals),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'name' => q(millibars),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'name' => q(millibars),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(millimètres de mercure),
						'one' => q({0} millimètre de mercure),
						'other' => q({0} millimètres de mercure),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(millimètres de mercure),
						'one' => q({0} millimètre de mercure),
						'other' => q({0} millimètres de mercure),
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
						'name' => q(livres-force par pouce carré),
						'one' => q({0} livre-force par pouce carré),
						'other' => q({0} livres-force par pouce carré),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(livres-force par pouce carré),
						'one' => q({0} livre-force par pouce carré),
						'other' => q({0} livres-force par pouce carré),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} degré Beaufort),
						'other' => q({0} degrés Beaufort),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q({0} degré Beaufort),
						'other' => q({0} degrés Beaufort),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilomètres par heure),
						'one' => q({0} kilomètre par heure),
						'other' => q({0} kilomètres par heure),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilomètres par heure),
						'one' => q({0} kilomètre par heure),
						'other' => q({0} kilomètres par heure),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nœuds),
						'one' => q({0} nœud),
						'other' => q({0} nœuds),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nœuds),
						'one' => q({0} nœud),
						'other' => q({0} nœuds),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'1' => q(feminine),
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Core Unit Identifier
					'light-speed' => {
						'1' => q(feminine),
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(mètres par seconde),
						'one' => q({0} mètre par seconde),
						'other' => q({0} mètres par seconde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(mètres par seconde),
						'one' => q({0} mètre par seconde),
						'other' => q({0} mètres par seconde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(masculine),
						'name' => q(miles par heure),
						'one' => q({0} mile par heure),
						'other' => q({0} miles par heure),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(masculine),
						'name' => q(miles par heure),
						'one' => q({0} mile par heure),
						'other' => q({0} miles par heure),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(degrés Celsius),
						'one' => q({0} degré Celsius),
						'other' => q({0} degrés Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(degrés Celsius),
						'one' => q({0} degré Celsius),
						'other' => q({0} degrés Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(masculine),
						'name' => q(degrés Fahrenheit),
						'one' => q({0} degré Fahrenheit),
						'other' => q({0} degrés Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(masculine),
						'name' => q(degrés Fahrenheit),
						'one' => q({0} degré Fahrenheit),
						'other' => q({0} degrés Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtons-mètres),
						'one' => q({0} newton-mètre),
						'other' => q({0} newtons-mètres),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtons-mètres),
						'one' => q({0} newton-mètre),
						'other' => q({0} newtons-mètres),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(livres-force-pieds),
						'one' => q({0} livre-force-pied),
						'other' => q({0} livres-force-pieds),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(livres-force-pieds),
						'one' => q({0} livre-force-pied),
						'other' => q({0} livres-force-pieds),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acres-pieds),
						'one' => q({0} acre-pied),
						'other' => q({0} acres-pieds),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acres-pieds),
						'one' => q({0} acre-pied),
						'other' => q({0} acres-pieds),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barils),
						'one' => q({0} baril),
						'other' => q({0} barils),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barils),
						'one' => q({0} baril),
						'other' => q({0} barils),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(boisseaux),
						'one' => q({0} boisseau),
						'other' => q({0} boisseaux),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(boisseaux),
						'one' => q({0} boisseau),
						'other' => q({0} boisseaux),
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
						'name' => q(centimètres cubes),
						'one' => q({0} centimètre cube),
						'other' => q({0} centimètres cubes),
						'per' => q({0} par centimètre cube),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimètres cubes),
						'one' => q({0} centimètre cube),
						'other' => q({0} centimètres cubes),
						'per' => q({0} par centimètre cube),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(masculine),
						'name' => q(pieds cubes),
						'one' => q({0} pied cube),
						'other' => q({0} pieds cubes),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(pieds cubes),
						'one' => q({0} pied cube),
						'other' => q({0} pieds cubes),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pouces cubes),
						'one' => q({0} pouce cube),
						'other' => q({0} pouces cubes),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pouces cubes),
						'one' => q({0} pouce cube),
						'other' => q({0} pouces cubes),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres cubes),
						'one' => q({0} kilomètre cube),
						'other' => q({0} kilomètres cubes),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilomètres cubes),
						'one' => q({0} kilomètre cube),
						'other' => q({0} kilomètres cubes),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(mètres cubes),
						'one' => q({0} mètre cube),
						'other' => q({0} mètres cubes),
						'per' => q({0} par mètre cube),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(mètres cubes),
						'one' => q({0} mètre cube),
						'other' => q({0} mètres cubes),
						'per' => q({0} par mètre cube),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(masculine),
						'name' => q(milles cubes),
						'one' => q({0} mille cube),
						'other' => q({0} milles cubes),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(masculine),
						'name' => q(milles cubes),
						'one' => q({0} mille cube),
						'other' => q({0} milles cubes),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yards cubes),
						'one' => q({0} yard cube),
						'other' => q({0} yards cubes),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yards cubes),
						'one' => q({0} yard cube),
						'other' => q({0} yards cubes),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(tasses métriques),
						'one' => q({0} tasse métrique),
						'other' => q({0} tasses métriques),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(tasses métriques),
						'one' => q({0} tasse métrique),
						'other' => q({0} tasses métriques),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(décilitres),
						'one' => q({0} décilitre),
						'other' => q({0} décilitres),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(décilitres),
						'one' => q({0} décilitre),
						'other' => q({0} décilitres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à dessert),
						'one' => q({0} cuillère à dessert),
						'other' => q({0} cuillères à dessert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à dessert),
						'one' => q({0} cuillère à dessert),
						'other' => q({0} cuillères à dessert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(cuillères à dessert impériales),
						'one' => q({0} cuillère à dessert impériale),
						'other' => q({0} cuillères à dessert impériales),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(feminine),
						'name' => q(cuillères à dessert impériales),
						'one' => q({0} cuillère à dessert impériale),
						'other' => q({0} cuillères à dessert impériales),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(feminine),
						'name' => q(drachmes),
						'one' => q({0} drachme),
						'other' => q({0} drachmes),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(feminine),
						'name' => q(drachmes),
						'one' => q({0} drachme),
						'other' => q({0} drachmes),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(feminine),
						'name' => q(gouttes),
						'one' => q({0} goutte),
						'other' => q({0} gouttes),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(feminine),
						'name' => q(gouttes),
						'one' => q({0} goutte),
						'other' => q({0} gouttes),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onces liquides),
						'one' => q({0} once liquide),
						'other' => q({0} onces liquides),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(onces liquides),
						'one' => q({0} once liquide),
						'other' => q({0} onces liquides),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onces liquides impériales),
						'one' => q({0} once liquide impériale),
						'other' => q({0} onces liquides impériales),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(onces liquides impériales),
						'one' => q({0} once liquide impériale),
						'other' => q({0} onces liquides impériales),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(masculine),
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} par gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(masculine),
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} par gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(gallons impériaux),
						'one' => q({0} gallon impérial),
						'other' => q({0} gallons impériaux),
						'per' => q({0} par gallon impérial),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(gallons impériaux),
						'one' => q({0} gallon impérial),
						'other' => q({0} gallons impériaux),
						'per' => q({0} par gallon impérial),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(masculine),
						'name' => q(jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(masculine),
						'name' => q(jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} par litre),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} par litre),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(mégalitres),
						'one' => q({0} mégalitre),
						'other' => q({0} mégalitres),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(mégalitres),
						'one' => q({0} mégalitre),
						'other' => q({0} mégalitres),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(feminine),
						'name' => q(pincées),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(feminine),
						'name' => q(pincées),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(feminine),
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(feminine),
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintes métriques),
						'one' => q({0} pinte métrique),
						'other' => q({0} pintes métriques),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'name' => q(pintes métriques),
						'one' => q({0} pinte métrique),
						'other' => q({0} pintes métriques),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(masculine),
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(masculine),
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarts impériaux),
						'one' => q({0} quart impérial),
						'other' => q({0} quarts impériaux),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarts impériaux),
						'one' => q({0} quart impérial),
						'other' => q({0} quarts impériaux),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à soupe),
						'one' => q({0} cuillère à soupe),
						'other' => q({0} cuillères à soupe),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à soupe),
						'one' => q({0} cuillère à soupe),
						'other' => q({0} cuillères à soupe),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à café),
						'one' => q({0} cuillère à café),
						'other' => q({0} cuillères à café),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(feminine),
						'name' => q(cuillères à café),
						'one' => q({0} cuillère à café),
						'other' => q({0} cuillères à café),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
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
					'angle-revolution' => {
						'one' => q({0}tr),
						'other' => q({0}tr),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}tr),
						'other' => q({0}tr),
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
						'one' => q({0}dounam),
						'other' => q({0}dounams),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0}dounam),
						'other' => q({0}dounams),
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
						'one' => q({0}pi²),
						'other' => q({0}pi²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0}pi²),
						'other' => q({0}pi²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}po²),
						'other' => q({0}po²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}po²),
						'other' => q({0}po²),
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
						'one' => q({0}item),
						'other' => q({0}items),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0}item),
						'other' => q({0}items),
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
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
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
					'concentr-portion-per-1e9' => {
						'one' => q({0}ppb),
						'other' => q({0}ppb),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'one' => q({0}ppb),
						'other' => q({0}ppb),
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
						'one' => q({0}mi/gal imp.),
						'other' => q({0}mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mi/gal imp.),
						'other' => q({0}mi/gal imp.),
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
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(o),
						'one' => q({0}o),
						'other' => q({0}o),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(o),
						'one' => q({0}o),
						'other' => q({0}o),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'one' => q({0}Gbit),
						'other' => q({0}Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'one' => q({0}Gbit),
						'other' => q({0}Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'one' => q({0}Go),
						'other' => q({0}Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'one' => q({0}Go),
						'other' => q({0}Go),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'one' => q({0}kbit),
						'other' => q({0}kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'one' => q({0}kbit),
						'other' => q({0}kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'one' => q({0}ko),
						'other' => q({0}ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'one' => q({0}ko),
						'other' => q({0}ko),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'one' => q({0}Mbit),
						'other' => q({0}Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'one' => q({0}Mbit),
						'other' => q({0}Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0}Mo),
						'other' => q({0}Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}Mo),
						'other' => q({0}Mo),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}Po),
						'other' => q({0}Po),
					},
					# Core Unit Identifier
					'petabyte' => {
						'one' => q({0}Po),
						'other' => q({0}Po),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'one' => q({0}Tbit),
						'other' => q({0}Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'one' => q({0}Tbit),
						'other' => q({0}Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'one' => q({0}To),
						'other' => q({0}To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}To),
						'other' => q({0}To),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}s.),
						'other' => q({0}s.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}j),
						'other' => q({0}j),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}j),
						'other' => q({0}j),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(déc.),
						'one' => q({0}déc.),
						'other' => q({0}déc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(déc.),
						'one' => q({0}déc.),
						'other' => q({0}déc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nuits),
						'one' => q({0}nuit),
						'other' => q({0}nuits),
						'per' => q({0}/nuit),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nuits),
						'one' => q({0}nuit),
						'other' => q({0}nuits),
						'per' => q({0}/nuit),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(T),
						'one' => q({0} T),
						'other' => q({0} T),
						'per' => q({0}/T),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(T),
						'one' => q({0} T),
						'other' => q({0} T),
						'per' => q({0}/T),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0}sem.),
						'other' => q({0}sem.),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0}sem.),
						'other' => q({0}sem.),
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
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
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
						'name' => q(thm US),
						'one' => q({0}thm US),
						'other' => q({0}thm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm US),
						'one' => q({0}thm US),
						'other' => q({0}thm US),
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
						'one' => q({0}pt/cm),
						'other' => q({0}pt/cm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}pt/cm),
						'other' => q({0}pt/cm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}pt/po),
						'other' => q({0}pt/po),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}pt/po),
						'other' => q({0}pt/po),
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
						'one' => q({0}px/po),
						'other' => q({0}px/po),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}px/po),
						'other' => q({0}px/po),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}ua),
						'other' => q({0}ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}ua),
						'other' => q({0}ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
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
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
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
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
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
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} grain),
						'other' => q({0} grains),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
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
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
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
					'mass-ton' => {
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
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
						'one' => q({0}ch),
						'other' => q({0}ch),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}ch),
						'other' => q({0}ch),
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
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
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
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
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
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0}Bft),
						'other' => q({0}Bft),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0}Bft),
						'other' => q({0}Bft),
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
					'speed-knot' => {
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0}m/s),
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
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
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
						'name' => q(acpi),
						'one' => q({0}acpi),
						'other' => q({0}acpi),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acpi),
						'one' => q({0}acpi),
						'other' => q({0}acpi),
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
						'one' => q({0}pi³),
						'other' => q({0}pi³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}pi³),
						'other' => q({0}pi³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}po³),
						'other' => q({0}po³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}po³),
						'other' => q({0}po³),
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
						'name' => q(ta),
						'one' => q({0}ta),
						'other' => q({0}ta),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ta),
						'one' => q({0}ta),
						'other' => q({0}ta),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}tm),
						'other' => q({0}tm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}tm),
						'other' => q({0}tm),
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
						'name' => q(CàD),
						'one' => q({0}CàD),
						'other' => q({0}CàD),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(CàD),
						'one' => q({0}CàD),
						'other' => q({0}CàD),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(CàD imp.),
						'one' => q({0}CàD imp.),
						'other' => q({0}CàD imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(CàD imp.),
						'one' => q({0}CàD imp.),
						'other' => q({0}CàD imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0}gte),
						'other' => q({0}gte),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0}gte),
						'other' => q({0}gte),
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
						'one' => q({0}fl oz imp),
						'other' => q({0}fl oz imp),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz imp),
						'other' => q({0}fl oz imp),
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
						'one' => q({0}gal imp.),
						'other' => q({0}gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'one' => q({0}gal imp.),
						'other' => q({0}gal imp.),
						'per' => q({0}/gal imp.),
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
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
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
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}pte),
						'other' => q({0}pte),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}pte),
						'other' => q({0}pte),
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
						'one' => q({0}qt imp.),
						'other' => q({0}qt imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qt imp.),
						'other' => q({0}qt imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(CàS),
						'one' => q({0}CàS),
						'other' => q({0}CàS),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(CàS),
						'one' => q({0}CàS),
						'other' => q({0}CàS),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(CàC),
						'one' => q({0}CàC),
						'other' => q({0}CàC),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(CàC),
						'one' => q({0}CàC),
						'other' => q({0}CàC),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(force g),
						'one' => q({0} force g),
						'other' => q({0} force g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(force g),
						'one' => q({0} force g),
						'other' => q({0} force g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
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
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dounam),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dounam),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pi²),
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pi²),
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(po²),
						'one' => q({0} po²),
						'other' => q({0} po²),
						'per' => q({0}/po²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(po²),
						'one' => q({0} po²),
						'other' => q({0} po²),
						'per' => q({0}/po²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0} items),
						'other' => q({0} items),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0} items),
						'other' => q({0} items),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0} mol),
						'other' => q({0} mol),
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
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(octet),
						'one' => q({0} o),
						'other' => q({0} o),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(octet),
						'one' => q({0} o),
						'other' => q({0} o),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Go),
						'one' => q({0} Go),
						'other' => q({0} Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Go),
						'one' => q({0} Go),
						'other' => q({0} Go),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ko),
						'one' => q({0} ko),
						'other' => q({0} ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ko),
						'one' => q({0} ko),
						'other' => q({0} ko),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mo),
						'one' => q({0} Mo),
						'other' => q({0} Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mo),
						'one' => q({0} Mo),
						'other' => q({0} Mo),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Po),
						'one' => q({0} Po),
						'other' => q({0} Po),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Po),
						'one' => q({0} Po),
						'other' => q({0} Po),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(To),
						'one' => q({0} To),
						'other' => q({0} To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(To),
						'one' => q({0} To),
						'other' => q({0} To),
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
						'name' => q(j),
						'one' => q({0} j),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(j),
						'one' => q({0} j),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(décennies),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(décennies),
						'one' => q({0} déc.),
						'other' => q({0} déc.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(nuits),
						'one' => q({0} nuit),
						'other' => q({0} nuits),
						'per' => q({0}/nuit),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(nuits),
						'one' => q({0} nuit),
						'other' => q({0} nuits),
						'per' => q({0}/nuit),
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
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ans),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0}/an),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ans),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0}/an),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} Btu),
						'other' => q({0} Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} Btu),
						'other' => q({0} Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} eV),
						'other' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} eV),
						'other' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therms US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therms US),
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
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} lbf),
						'other' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} lbf),
						'other' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pt/cm),
						'one' => q({0} pt/cm),
						'other' => q({0} pt/cm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pt/cm),
						'one' => q({0} pt/cm),
						'other' => q({0} pt/cm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pt/po),
						'one' => q({0} pt/po),
						'other' => q({0} pt/po),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pt/po),
						'one' => q({0} pt/po),
						'other' => q({0} pt/po),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} px),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} px),
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
						'name' => q(px/po),
						'one' => q({0} px/po),
						'other' => q({0} px/po),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(px/po),
						'one' => q({0} px/po),
						'other' => q({0} px/po),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pi),
						'one' => q({0} pi),
						'other' => q({0} pi),
						'per' => q({0}/pi),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pi),
						'one' => q({0} pi),
						'other' => q({0} pi),
						'per' => q({0}/pi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(po),
						'one' => q({0} po),
						'other' => q({0} po),
						'per' => q({0}/po),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(po),
						'one' => q({0} po),
						'other' => q({0} po),
						'per' => q({0}/po),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt typog.),
						'one' => q({0} pt typog.),
						'other' => q({0} pts typog.),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt typog.),
						'one' => q({0} pt typog.),
						'other' => q({0} pts typog.),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} R☉),
						'other' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} R☉),
						'other' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} Da),
						'other' => q({0} Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} Da),
						'other' => q({0} Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0} grains),
						'other' => q({0} grains),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0} grains),
						'other' => q({0} grains),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ch),
						'one' => q({0} ch),
						'other' => q({0} ch),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ch),
						'one' => q({0} ch),
						'other' => q({0} ch),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0} atm),
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
					'pressure-hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0} kPa),
						'other' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0} kPa),
						'other' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0} MPa),
						'other' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0} MPa),
						'other' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(lb/po²),
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(lb/po²),
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0} Bft),
						'other' => q({0} Bft),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0} Bft),
						'other' => q({0} Bft),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(lumière),
						'one' => q({0} lumière),
						'other' => q({0} lumière),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
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
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac pi),
						'one' => q({0} ac pi),
						'other' => q({0} ac pi),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac pi),
						'one' => q({0} ac pi),
						'other' => q({0} ac pi),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} bbl),
						'other' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} bbl),
						'other' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bu),
						'other' => q({0} bu),
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
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pi³),
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pi³),
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(po³),
						'one' => q({0} po³),
						'other' => q({0} po³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(po³),
						'one' => q({0} po³),
						'other' => q({0} po³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(tasses),
						'one' => q({0} tasse),
						'other' => q({0} tasses),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(tasses),
						'one' => q({0} tasse),
						'other' => q({0} tasses),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
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
						'name' => q(c. à d.),
						'one' => q({0} c. à d.),
						'other' => q({0} c. à d.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(c. à d.),
						'one' => q({0} c. à d.),
						'other' => q({0} c. à d.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(c. à d. imp.),
						'one' => q({0} c. à d. imp.),
						'other' => q({0} c. à d. imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(c. à d. imp.),
						'one' => q({0} c. à d. imp.),
						'other' => q({0} c. à d. imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(drachme fluide),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(drachme fluide),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gte),
						'one' => q({0} gte),
						'other' => q({0} gte),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gte),
						'one' => q({0} gte),
						'other' => q({0} gte),
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
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
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
						'per' => q({0} gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0} jigger),
						'other' => q({0} jiggers),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
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
						'name' => q(pincée),
						'one' => q({0} pincée),
						'other' => q({0} pincées),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pincée),
						'one' => q({0} pincée),
						'other' => q({0} pincées),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
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
						'name' => q(c. à s.),
						'one' => q({0} c. à s.),
						'other' => q({0} c. à s.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(c. à s.),
						'one' => q({0} c. à s.),
						'other' => q({0} c. à s.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(c. à c.),
						'one' => q({0} c. à c.),
						'other' => q({0} c. à c.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(c. à c.),
						'one' => q({0} c. à c.),
						'other' => q({0} c. à c.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:oui|o|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:non|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} et {1}),
				2 => q({0} et {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'minusSign' => q(‏−),
			'percentSign' => q(٪),
			'plusSign' => q(‏+),
		},
		'arabext' => {
			'minusSign' => q(‎−),
			'plusSign' => q(‎+),
		},
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
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
					'1' => 'mille',
					'one' => '0 millier',
					'other' => '0 mille',
				},
				'10000' => {
					'one' => '00 mille',
					'other' => '00 mille',
				},
				'100000' => {
					'one' => '000 mille',
					'other' => '000 mille',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 millions',
				},
				'10000000' => {
					'one' => '00 million',
					'other' => '00 millions',
				},
				'100000000' => {
					'one' => '000 million',
					'other' => '000 millions',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliards',
				},
				'10000000000' => {
					'one' => '00 milliard',
					'other' => '00 milliards',
				},
				'100000000000' => {
					'one' => '000 milliard',
					'other' => '000 milliards',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billions',
				},
				'10000000000000' => {
					'one' => '00 billion',
					'other' => '00 billions',
				},
				'100000000000000' => {
					'one' => '000 billion',
					'other' => '000 billions',
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
					'one' => '0 Md',
					'other' => '0 Md',
				},
				'10000000000' => {
					'one' => '00 Md',
					'other' => '00 Md',
				},
				'100000000000' => {
					'one' => '000 Md',
					'other' => '000 Md',
				},
				'1000000000000' => {
					'one' => '0 Bn',
					'other' => '0 Bn',
				},
				'10000000000000' => {
					'one' => '00 Bn',
					'other' => '00 Bn',
				},
				'100000000000000' => {
					'one' => '000 Bn',
					'other' => '000 Bn',
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
				'currency' => q(peseta andorrane),
				'one' => q(peseta andorrane),
				'other' => q(pesetas andorranes),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham des Émirats arabes unis),
				'one' => q(dirham des Émirats arabes unis),
				'other' => q(dirhams des Émirats arabes unis),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
				'one' => q(afghani \(1927–2002\)),
				'other' => q(afghanis \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani afghan),
				'one' => q(afghani afghan),
				'other' => q(afghanis afghan),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albanais \(1947–1961\)),
				'one' => q(lek albanais \(1947–1961\)),
				'other' => q(leks albanais \(1947–1961\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanais),
				'one' => q(lek albanais),
				'other' => q(leks albanais),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram arménien),
				'one' => q(dram arménien),
				'other' => q(drams arméniens),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florin antillais),
				'one' => q(florin antillais),
				'other' => q(florins antillais),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolais),
				'one' => q(kwanza angolais),
				'other' => q(kwanzas angolais),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolais \(1977–1990\)),
				'one' => q(kwanza angolais \(1977–1990\)),
				'other' => q(kwanzas angolais \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nouveau kwanza angolais \(1990–2000\)),
				'one' => q(nouveau kwanza angolais \(1990–2000\)),
				'other' => q(nouveaux kwanzas angolais \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolais réajusté \(1995–1999\)),
				'one' => q(kwanza angolais réajusté \(1995–1999\)),
				'other' => q(kwanzas angolais réajustés \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentin),
				'one' => q(austral argentin),
				'other' => q(australs argentins),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(peso lourd argentin \(1970–1983\)),
				'one' => q(peso lourd argentin \(1970–1983\)),
				'other' => q(pesos lourds argentins \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso argentin \(1881–1970\)),
				'one' => q(peso argentin \(1881–1970\)),
				'other' => q(pesos argentins \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentin \(1983–1985\)),
				'one' => q(peso argentin \(1983–1985\)),
				'other' => q(pesos argentins \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => '$AR',
			display_name => {
				'currency' => q(peso argentin),
				'one' => q(peso argentin),
				'other' => q(pesos argentins),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(schilling autrichien),
				'one' => q(schilling autrichien),
				'other' => q(schillings autrichiens),
			},
		},
		'AUD' => {
			symbol => '$AU',
			display_name => {
				'currency' => q(dollar australien),
				'one' => q(dollar australien),
				'other' => q(dollars australiens),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florin arubais),
				'one' => q(florin arubais),
				'other' => q(florins arubais),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azéri \(1993–2006\)),
				'one' => q(manat azéri \(1993–2006\)),
				'other' => q(manats azéris \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azéri),
				'one' => q(manat azéri),
				'other' => q(manats azéris),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar bosniaque),
				'one' => q(dinar bosniaque),
				'other' => q(dinars bosniaques),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(mark convertible bosniaque),
				'one' => q(mark convertible bosniaque),
				'other' => q(marks convertibles bosniaques),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nouveau dinar bosniaque \(1994–1997\)),
				'one' => q(nouveau dinar bosniaque \(1994–1997\)),
				'other' => q(nouveaux dinars bosniaques \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollar barbadien),
				'one' => q(dollar barbadien),
				'other' => q(dollars barbadiens),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladeshi),
				'one' => q(taka bangladeshi),
				'other' => q(takas bangladeshis),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franc belge \(convertible\)),
				'one' => q(franc belge \(convertible\)),
				'other' => q(francs belges \(convertibles\)),
			},
		},
		'BEF' => {
			symbol => 'FB',
			display_name => {
				'currency' => q(franc belge),
				'one' => q(franc belge),
				'other' => q(francs belges),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franc belge \(financier\)),
				'one' => q(franc belge \(financier\)),
				'other' => q(francs belges \(financiers\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev bulgare \(1962–1999\)),
				'one' => q(lev bulgare \(1962–1999\)),
				'other' => q(levs bulgares \(1962–1999\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev socialiste bulgare),
				'one' => q(lev socialiste bulgare),
				'other' => q(levs socialistes bulgares),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bulgare),
				'one' => q(lev bulgare),
				'other' => q(levs bulgares),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(lev bulgare \(1879–1952\)),
				'one' => q(lev bulgare \(1879–1952\)),
				'other' => q(levs bulgares \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar bahreïni),
				'one' => q(dinar bahreïni),
				'other' => q(dinars bahreïnis),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franc burundais),
				'one' => q(franc burundais),
				'other' => q(francs burundais),
			},
		},
		'BMD' => {
			symbol => '$BM',
			display_name => {
				'currency' => q(dollar bermudien),
				'one' => q(dollar bermudien),
				'other' => q(dollars bermudiens),
			},
		},
		'BND' => {
			symbol => '$BN',
			display_name => {
				'currency' => q(dollar brunéien),
				'one' => q(dollar brunéien),
				'other' => q(dollars brunéiens),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano bolivien),
				'one' => q(boliviano bolivien),
				'other' => q(bolivianos boliviens),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviano bolivien \(1863–1963\)),
				'one' => q(boliviano bolivien \(1863–1963\)),
				'other' => q(bolivianos boliviens \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso bolivien),
				'one' => q(peso bolivien),
				'other' => q(pesos boliviens),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol bolivien),
				'one' => q(mvdol bolivien),
				'other' => q(mvdols boliviens),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(nouveau cruzeiro brésilien \(1967–1986\)),
				'one' => q(nouveau cruzeiro brésilien \(1967–1986\)),
				'other' => q(nouveaux cruzeiros brésiliens \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brésilien \(1986–1989\)),
				'one' => q(cruzado brésilien \(1986–1989\)),
				'other' => q(cruzados brésiliens \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brésilien \(1990–1993\)),
				'one' => q(cruzeiro brésilien \(1990–1993\)),
				'other' => q(cruzeiros brésiliens \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(réal brésilien),
				'one' => q(réal brésilien),
				'other' => q(réals brésiliens),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(nouveau cruzado),
				'one' => q(nouveau cruzado brésilien \(1989–1990\)),
				'other' => q(nouveaux cruzados brésiliens \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro),
				'one' => q(cruzeiro réal brésilien \(1993–1994\)),
				'other' => q(cruzeiros réals brésiliens \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(cruzeiro brésilien \(1942–1967\)),
				'one' => q(cruzeiro brésilien \(1942–1967\)),
				'other' => q(cruzeiros brésiliens \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dollar bahaméen),
				'one' => q(dollar bahaméen),
				'other' => q(dollars bahaméens),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum bouthanais),
				'one' => q(ngultrum bouthanais),
				'other' => q(ngultrums bouthanais),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birman),
				'one' => q(kyat birman),
				'other' => q(kyats birmans),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula botswanais),
				'one' => q(pula botswanais),
				'other' => q(pulas botswanais),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nouveau rouble biélorusse \(1994–1999\)),
				'one' => q(nouveau rouble biélorusse \(1994–1999\)),
				'other' => q(nouveaux roubles biélorusses \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(rouble biélorusse),
				'one' => q(rouble biélorusse),
				'other' => q(roubles biélorusses),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rouble biélorusse \(2000–2016\)),
				'one' => q(rouble biélorusse \(2000–2016\)),
				'other' => q(roubles biélorusses \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => '$BZ',
			display_name => {
				'currency' => q(dollar bélizéen),
				'one' => q(dollar bélizéen),
				'other' => q(dollars bélizéens),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(dollar canadien),
				'one' => q(dollar canadien),
				'other' => q(dollars canadiens),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franc congolais),
				'one' => q(franc congolais),
				'other' => q(francs congolais),
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
				'currency' => q(franc suisse),
				'one' => q(franc suisse),
				'other' => q(francs suisses),
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
				'currency' => q(escudo chilien),
				'one' => q(escudo chilien),
				'other' => q(escudos chiliens),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unité d’investissement chilienne),
				'one' => q(unité d’investissement chilienne),
				'other' => q(unités d’investissement chiliennes),
			},
		},
		'CLP' => {
			symbol => '$CL',
			display_name => {
				'currency' => q(peso chilien),
				'one' => q(peso chilien),
				'other' => q(pesos chiliens),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan chinois \(zone extracôtière\)),
				'one' => q(yuan chinois \(zone extracôtière\)),
				'other' => q(yuans chinois \(zone extracôtière\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dollar de la Banque populaire chinoise),
				'one' => q(dollar de la Banque populaire chinoise),
				'other' => q(dollars de la Banque populaire chinoise),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(yuan renminbi chinois),
				'one' => q(yuan renminbi chinois),
				'other' => q(yuans renminbi chinois),
			},
		},
		'COP' => {
			symbol => '$CO',
			display_name => {
				'currency' => q(peso colombien),
				'one' => q(peso colombien),
				'other' => q(pesos colombiens),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(unité de valeur réelle colombienne),
				'one' => q(unité de valeur réelle colombienne),
				'other' => q(unités de valeur réelle colombiennes),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón costaricain),
				'one' => q(colón costaricain),
				'other' => q(colóns costaricains),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar serbo-monténégrin),
				'one' => q(dinar serbo-monténégrin),
				'other' => q(dinars serbo-monténégrins),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(couronne forte tchécoslovaque),
				'one' => q(couronne forte tchécoslovaque),
				'other' => q(couronnes fortes tchécoslovaques),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cubain convertible),
				'one' => q(peso cubain convertible),
				'other' => q(pesos cubains convertibles),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubain),
				'one' => q(peso cubain),
				'other' => q(pesos cubains),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo capverdien),
				'one' => q(escudo capverdien),
				'other' => q(escudos capverdiens),
			},
		},
		'CYP' => {
			symbol => '£CY',
			display_name => {
				'currency' => q(livre chypriote),
				'one' => q(livre chypriote),
				'other' => q(livres chypriotes),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(couronne tchèque),
				'one' => q(couronne tchèque),
				'other' => q(couronnes tchèques),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(mark est-allemand),
				'one' => q(mark est-allemand),
				'other' => q(marks est-allemands),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(mark allemand),
				'one' => q(mark allemand),
				'other' => q(marks allemands),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franc djiboutien),
				'one' => q(franc djiboutien),
				'other' => q(francs djiboutiens),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(couronne danoise),
				'one' => q(couronne danoise),
				'other' => q(couronnes danoises),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominicain),
				'one' => q(peso dominicain),
				'other' => q(pesos dominicains),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar algérien),
				'one' => q(dinar algérien),
				'other' => q(dinars algériens),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre équatorien),
				'one' => q(sucre équatorien),
				'other' => q(sucres équatoriens),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unité de valeur constante équatoriale \(UVC\)),
				'one' => q(unité de valeur constante équatorienne \(UVC\)),
				'other' => q(unités de valeur constante équatoriennes \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(couronne estonienne),
				'one' => q(couronne estonienne),
				'other' => q(couronnes estoniennes),
			},
		},
		'EGP' => {
			symbol => '£E',
			display_name => {
				'currency' => q(livre égyptienne),
				'one' => q(livre égyptienne),
				'other' => q(livres égyptiennes),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nafka érythréen),
				'one' => q(nafka érythréen),
				'other' => q(nafkas érythréens),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta espagnole \(compte A\)),
				'one' => q(peseta espagnole \(compte A\)),
				'other' => q(pesetas espagnoles \(compte A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta espagnole \(compte convertible\)),
				'one' => q(peseta espagnole \(compte convertible\)),
				'other' => q(pesetas espagnoles \(compte convertible\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta espagnole),
				'one' => q(peseta espagnole),
				'other' => q(pesetas espagnoles),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr éthiopien),
				'one' => q(birr éthiopien),
				'other' => q(birrs éthiopiens),
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
				'currency' => q(mark finlandais),
				'one' => q(mark finlandais),
				'other' => q(marks finlandais),
			},
		},
		'FJD' => {
			symbol => '$FJ',
			display_name => {
				'currency' => q(dollar fidjien),
				'one' => q(dollar fidjien),
				'other' => q(dollars fidjiens),
			},
		},
		'FKP' => {
			symbol => '£FK',
			display_name => {
				'currency' => q(livre des îles Malouines),
				'one' => q(livre des îles Malouines),
				'other' => q(livres des îles Malouines),
			},
		},
		'FRF' => {
			symbol => 'F',
			display_name => {
				'currency' => q(franc français),
				'one' => q(franc français),
				'other' => q(francs français),
			},
		},
		'GBP' => {
			symbol => '£GB',
			display_name => {
				'currency' => q(livre sterling),
				'one' => q(livre sterling),
				'other' => q(livres sterling),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(coupon de lari géorgien),
				'one' => q(coupon de lari géorgien),
				'other' => q(coupons de lari géorgiens),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari géorgien),
				'one' => q(lari géorgien),
				'other' => q(lari géorgiens),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cédi),
				'one' => q(cédi ghanéen \(1967–2007\)),
				'other' => q(cédis ghanéens \(1967–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cédi ghanéen),
				'one' => q(cédi ghanéen),
				'other' => q(cédis ghanéens),
			},
		},
		'GIP' => {
			symbol => '£GI',
			display_name => {
				'currency' => q(livre de Gibraltar),
				'one' => q(livre de Gibraltar),
				'other' => q(livres de Gibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambien),
				'one' => q(dalasi gambien),
				'other' => q(dalasis gambiens),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franc guinéen),
				'one' => q(franc guinéen),
				'other' => q(francs guinéens),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli guinéen),
				'one' => q(syli guinéen),
				'other' => q(sylis guinéens),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwélé équatoguinéen),
				'one' => q(ekwélé équatoguinéen),
				'other' => q(ekwélés équatoguinéens),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drachme grecque),
				'one' => q(drachme grecque),
				'other' => q(drachmes grecques),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatémaltèque),
				'one' => q(quetzal guatémaltèque),
				'other' => q(quetzals guatémaltèques),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escudo de Guinée portugaise),
				'one' => q(escudo de Guinée portugaise),
				'other' => q(escudos de Guinée portugaise),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso bissau-guinéen),
				'one' => q(peso bissau-guinéen),
				'other' => q(pesos bissau-guinéens),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollar du Guyana),
				'one' => q(dollar du Guyana),
				'other' => q(dollars du Guyana),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dollar de Hong Kong),
				'one' => q(dollar de Hong Kong),
				'other' => q(dollars de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira hondurien),
				'one' => q(lempira hondurien),
				'other' => q(lempiras honduriens),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar croate),
				'one' => q(dinar croate),
				'other' => q(dinars croates),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croate),
				'one' => q(kuna croate),
				'other' => q(kunas croates),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haïtienne),
				'one' => q(gourde haïtienne),
				'other' => q(gourdes haïtiennes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint hongrois),
				'one' => q(forint hongrois),
				'other' => q(forints hongrois),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(roupie indonésienne),
				'one' => q(roupie indonésienne),
				'other' => q(roupies indonésiennes),
			},
		},
		'IEP' => {
			symbol => '£IE',
			display_name => {
				'currency' => q(livre irlandaise),
				'one' => q(livre irlandaise),
				'other' => q(livres irlandaises),
			},
		},
		'ILP' => {
			symbol => '£IL',
			display_name => {
				'currency' => q(livre israélienne),
				'one' => q(livre israélienne),
				'other' => q(livres israéliennes),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(shekel israélien \(1980–1985\)),
				'one' => q(shekel israélien \(1980–1985\)),
				'other' => q(shekels israéliens \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nouveau shekel israélien),
				'one' => q(nouveau shekel israélien),
				'other' => q(nouveaux shekels israéliens),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(roupie indienne),
				'one' => q(roupie indienne),
				'other' => q(roupies indiennes),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar irakien),
				'one' => q(dinar irakien),
				'other' => q(dinars irakiens),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(riyal iranien),
				'one' => q(riyal iranien),
				'other' => q(riyals iraniens),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(couronne islandaise \(1918–1981\)),
				'one' => q(couronne islandaise \(1918–1981\)),
				'other' => q(couronnes islandaises \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(couronne islandaise),
				'one' => q(couronne islandaise),
				'other' => q(couronnes islandaises),
			},
		},
		'ITL' => {
			symbol => '₤IT',
			display_name => {
				'currency' => q(lire italienne),
				'one' => q(lire italienne),
				'other' => q(lires italiennes),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dollar jamaïcain),
				'one' => q(dollar jamaïcain),
				'other' => q(dollars jamaïcains),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordanien),
				'one' => q(dinar jordanien),
				'other' => q(dinars jordaniens),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen japonais),
				'one' => q(yen japonais),
				'other' => q(yens japonais),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shilling kényan),
				'one' => q(shilling kényan),
				'other' => q(shillings kényans),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghize),
				'one' => q(som kirghize),
				'other' => q(soms kirghizes),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambodgien),
				'one' => q(riel cambodgien),
				'other' => q(riels cambodgiens),
			},
		},
		'KMF' => {
			symbol => 'FC',
			display_name => {
				'currency' => q(franc comorien),
				'one' => q(franc comorien),
				'other' => q(francs comoriens),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nord-coréen),
				'one' => q(won nord-coréen),
				'other' => q(wons nord-coréens),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan sud-coréen \(1953–1962\)),
				'one' => q(hwan sud-coréen \(1953–1962\)),
				'other' => q(hwans sud-coréens \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(won sud-coréen \(1945–1953\)),
				'one' => q(won sud-coréen \(1945–1953\)),
				'other' => q(wons sud-coréens \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(won sud-coréen),
				'one' => q(won sud-coréen),
				'other' => q(wons sud-coréens),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar koweïtien),
				'one' => q(dinar koweïtien),
				'other' => q(dinar koweïtiens),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dollar des îles Caïmans),
				'one' => q(dollar des îles Caïmans),
				'other' => q(dollars des îles Caïmans),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazakh),
				'one' => q(tenge kazakh),
				'other' => q(tenges kazakhs),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laotien),
				'one' => q(kip laotien),
				'other' => q(kips laotiens),
			},
		},
		'LBP' => {
			symbol => '£LB',
			display_name => {
				'currency' => q(livre libanaise),
				'one' => q(livre libanaise),
				'other' => q(livres libanaises),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(roupie srilankaise),
				'one' => q(roupie srilankaise),
				'other' => q(roupies srilankaises),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollar libérien),
				'one' => q(dollar libérien),
				'other' => q(dollars libériens),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesothan),
				'one' => q(loti lesothan),
				'other' => q(maloti lesothans),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituanien),
				'one' => q(litas lituanien),
				'other' => q(litas lituaniens),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituanien),
				'one' => q(talonas lituanien),
				'other' => q(talonas lituaniens),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franc convertible luxembourgeois),
				'one' => q(franc convertible luxembourgeois),
				'other' => q(francs convertibles luxembourgeois),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franc luxembourgeois),
				'one' => q(franc luxembourgeois),
				'other' => q(francs luxembourgeois),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franc financier luxembourgeois),
				'one' => q(franc financier luxembourgeois),
				'other' => q(francs financiers luxembourgeois),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats letton),
				'one' => q(lats letton),
				'other' => q(lats lettons),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rouble letton),
				'one' => q(rouble letton),
				'other' => q(roubles lettons),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar libyen),
				'one' => q(dinar libyen),
				'other' => q(dinars libyens),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocain),
				'one' => q(dirham marocain),
				'other' => q(dirhams marocains),
			},
		},
		'MAF' => {
			symbol => 'fMA',
			display_name => {
				'currency' => q(franc marocain),
				'one' => q(franc marocain),
				'other' => q(francs marocains),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(franc monégasque),
				'one' => q(franc monégasque),
				'other' => q(francs monégasques),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(cupon moldave),
				'one' => q(cupon moldave),
				'other' => q(cupons moldaves),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldave),
				'one' => q(leu moldave),
				'other' => q(leus moldaves),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgache),
				'one' => q(ariary malgache),
				'other' => q(ariarys malgaches),
			},
		},
		'MGF' => {
			symbol => 'Fmg',
			display_name => {
				'currency' => q(franc malgache),
				'one' => q(franc malgache),
				'other' => q(francs malgaches),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(denar macédonien),
				'one' => q(denar macédonien),
				'other' => q(denars macédoniens),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(denar macédonien \(1992–1993\)),
				'one' => q(denar macédonien \(1992–1993\)),
				'other' => q(denars macédoniens \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franc malien),
				'one' => q(franc malien),
				'other' => q(francs maliens),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat myanmarais),
				'one' => q(kyat myanmarais),
				'other' => q(kyats myanmarais),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongols),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca macanaise),
				'one' => q(pataca macanaise),
				'other' => q(patacas macanaises),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya mauritanien \(1973–2017\)),
				'one' => q(ouguiya mauritanien \(1973–2017\)),
				'other' => q(ouguiyas mauritaniens \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritanien),
				'one' => q(ouguiya mauritanien),
				'other' => q(ouguiyas mauritaniens),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lire maltaise),
				'one' => q(lire maltaise),
				'other' => q(lires maltaises),
			},
		},
		'MTP' => {
			symbol => '£MT',
			display_name => {
				'currency' => q(livre maltaise),
				'one' => q(livre maltaise),
				'other' => q(livres maltaises),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(roupie mauricienne),
				'one' => q(roupie mauricienne),
				'other' => q(roupies mauriciennes),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(roupie maldivienne \(1947–1981\)),
				'one' => q(roupie maldivienne \(1947–1981\)),
				'other' => q(roupies maldiviennes \(1947–1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa maldivienne),
				'one' => q(rufiyaa maldivienne),
				'other' => q(rufiyaas maldiviennes),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawite),
				'one' => q(kwacha malawite),
				'other' => q(kwachas malawites),
			},
		},
		'MXN' => {
			symbol => '$MX',
			display_name => {
				'currency' => q(peso mexicain),
				'one' => q(peso mexicain),
				'other' => q(pesos mexicains),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso d’argent mexicain \(1861–1992\)),
				'one' => q(peso d’argent mexicain \(1861–1992\)),
				'other' => q(pesos d’argent mexicains \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unité de conversion mexicaine \(UDI\)),
				'one' => q(unité de conversion mexicaine \(UDI\)),
				'other' => q(unités de conversion mexicaines \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malais),
				'one' => q(ringgit malais),
				'other' => q(ringgits malais),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo mozambicain),
				'one' => q(escudo mozambicain),
				'other' => q(escudos mozambicains),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(métical),
				'one' => q(metical mozambicain \(1980–2006\)),
				'other' => q(meticais mozambicains \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambicain),
				'one' => q(metical mozambicain),
				'other' => q(meticais mozambicains),
			},
		},
		'NAD' => {
			symbol => '$NA',
			display_name => {
				'currency' => q(dollar namibien),
				'one' => q(dollar namibien),
				'other' => q(dollars namibiens),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigérian),
				'one' => q(naira nigérian),
				'other' => q(nairas nigérians),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba),
				'one' => q(córdoba nicaraguayen \(1912–1988\)),
				'other' => q(córdobas nicaraguayens \(1912–1988\)),
			},
		},
		'NIO' => {
			symbol => '$C',
			display_name => {
				'currency' => q(córdoba oro nicaraguayen),
				'one' => q(córdoba oro nicaraguayen),
				'other' => q(córdobas oro nicaraguayens),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(florin néerlandais),
				'one' => q(florin néerlandais),
				'other' => q(florins néerlandais),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(couronne norvégienne),
				'one' => q(couronne norvégienne),
				'other' => q(couronnes norvégiennes),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(roupie népalaise),
				'one' => q(roupie népalaise),
				'other' => q(roupies népalaises),
			},
		},
		'NZD' => {
			symbol => '$NZ',
			display_name => {
				'currency' => q(dollar néo-zélandais),
				'one' => q(dollar néo-zélandais),
				'other' => q(dollars néo-zélandais),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(riyal omanais),
				'one' => q(riyal omanais),
				'other' => q(riyals omanis),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panaméen),
				'one' => q(balboa panaméen),
				'other' => q(balboas panaméens),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti péruvien),
				'one' => q(inti péruvien),
				'other' => q(intis péruviens),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol péruvien),
				'one' => q(sol péruvien),
				'other' => q(sols péruviens),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol péruvien \(1863–1985\)),
				'one' => q(sol péruvien \(1863–1985\)),
				'other' => q(sols péruviens \(1863–1985\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papouan-néo-guinéen),
				'one' => q(kina papouan-néo-guinéen),
				'other' => q(kinas papouan-néo-guinéens),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso philippin),
				'one' => q(peso philippin),
				'other' => q(pesos philippins),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(roupie pakistanaise),
				'one' => q(roupie pakistanaise),
				'other' => q(roupies pakistanaises),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polonais),
				'one' => q(zloty polonais),
				'other' => q(zlotys polonais),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty \(1950–1995\)),
				'one' => q(zloty polonais \(1950–1995\)),
				'other' => q(zlotys polonais \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo portugais),
				'one' => q(escudo portugais),
				'other' => q(escudos portugais),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní paraguayen),
				'one' => q(guaraní paraguayen),
				'other' => q(guaranís paraguayens),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(riyal qatari),
				'one' => q(riyal qatari),
				'other' => q(riyals qataris),
			},
		},
		'RHD' => {
			symbol => '$RH',
			display_name => {
				'currency' => q(dollar rhodésien),
				'one' => q(dollar rhodésien),
				'other' => q(dollars rhodésiens),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(ancien leu roumain),
				'one' => q(leu roumain \(1952–2005\)),
				'other' => q(lei roumains \(1952–2005\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(leu roumain),
				'one' => q(leu roumain),
				'other' => q(lei roumains),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbe),
				'one' => q(dinar serbe),
				'other' => q(dinars serbes),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rouble russe),
				'one' => q(rouble russe),
				'other' => q(roubles russes),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(rouble russe \(1991–1998\)),
				'one' => q(rouble russe \(1991–1998\)),
				'other' => q(roubles russes \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'FR',
			display_name => {
				'currency' => q(franc rwandais),
				'one' => q(franc rwandais),
				'other' => q(francs rwandais),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal saoudien),
				'one' => q(riyal saoudien),
				'other' => q(riyals saoudiens),
			},
		},
		'SBD' => {
			symbol => '$SB',
			display_name => {
				'currency' => q(dollar des îles Salomon),
				'one' => q(dollar des îles Salomon),
				'other' => q(dollars des îles Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(roupie des Seychelles),
				'one' => q(roupie des Seychelles),
				'other' => q(roupies des Seychelles),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar soudanais),
				'one' => q(dinar soudanais \(1992–2007\)),
				'other' => q(dinars soudanais \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(livre soudanaise),
				'one' => q(livre soudanaise),
				'other' => q(livres soudanaises),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(livre soudanaise \(1956–2007\)),
				'one' => q(livre soudanaise \(1956–2007\)),
				'other' => q(livres soudanaises \(1956–2007\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(couronne suédoise),
				'one' => q(couronne suédoise),
				'other' => q(couronnes suédoises),
			},
		},
		'SGD' => {
			symbol => '$SG',
			display_name => {
				'currency' => q(dollar de Singapour),
				'one' => q(dollar de Singapour),
				'other' => q(dollars de Singapour),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(livre de Sainte-Hélène),
				'one' => q(livre de Sainte-Hélène),
				'other' => q(livres de Sainte-Hélène),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar slovène),
				'one' => q(tolar slovène),
				'other' => q(tolars slovènes),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(couronne slovaque),
				'one' => q(couronne slovaque),
				'other' => q(couronnes slovaques),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone sierra-léonais),
				'one' => q(leone sierra-léonais),
				'other' => q(leones sierra-léonais),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone sierra-léonais \(1964—2022\)),
				'one' => q(leone sierra-léonais \(1964—2022\)),
				'other' => q(leones sierra-léonais \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilling somalien),
				'one' => q(shilling somalien),
				'other' => q(shillings somaliens),
			},
		},
		'SRD' => {
			symbol => '$SR',
			display_name => {
				'currency' => q(dollar surinamais),
				'one' => q(dollar surinamais),
				'other' => q(dollars surinamais),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(florin surinamais),
				'one' => q(florin surinamais),
				'other' => q(florins surinamais),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(livre sud-soudanaise),
				'one' => q(livre sud-soudanaise),
				'other' => q(livres sud-soudanaises),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra santoméen \(1977–2017\)),
				'one' => q(dobra santoméen \(1977–2017\)),
				'other' => q(dobras santoméens \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra santoméen),
				'one' => q(dobra santoméen),
				'other' => q(dobras santoméens),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rouble soviétique),
				'one' => q(rouble soviétique),
				'other' => q(roubles soviétiques),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colón salvadorien),
				'one' => q(colón salvadorien),
				'other' => q(colóns salvadoriens),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(livre syrienne),
				'one' => q(livre syrienne),
				'other' => q(livres syriennes),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni swazi),
				'one' => q(lilangeni swazi),
				'other' => q(lilangenis swazis),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht thaïlandais),
				'one' => q(baht thaïlandais),
				'other' => q(bahts thaïlandais),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rouble tadjik),
				'one' => q(rouble tadjik),
				'other' => q(roubles tadjiks),
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
				'currency' => q(manat turkmène),
				'one' => q(manat turkmène),
				'other' => q(manats turkmènes),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(nouveau manat turkmène),
				'one' => q(nouveau manat turkmène),
				'other' => q(nouveaux manats turkmènes),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisien),
				'one' => q(dinar tunisien),
				'other' => q(dinars tunisiens),
			},
		},
		'TOP' => {
			symbol => '$T',
			display_name => {
				'currency' => q(pa’anga tongan),
				'one' => q(pa’anga tongan),
				'other' => q(pa’angas tongans),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo timorais),
				'one' => q(escudo timorais),
				'other' => q(escudos timorais),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(livre turque \(1844–2005\)),
				'one' => q(livre turque \(1844–2005\)),
				'other' => q(livres turques \(1844–2005\)),
			},
		},
		'TRY' => {
			symbol => 'LT',
			display_name => {
				'currency' => q(livre turque),
				'one' => q(livre turque),
				'other' => q(livres turques),
			},
		},
		'TTD' => {
			symbol => '$TT',
			display_name => {
				'currency' => q(dollar de Trinité-et-Tobago),
				'one' => q(dollar de Trinité-et-Tobago),
				'other' => q(dollars de Trinité-et-Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nouveau dollar taïwanais),
				'one' => q(nouveau dollar taïwanais),
				'other' => q(nouveaux dollars taïwanais),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(shilling tanzanien),
				'one' => q(shilling tanzanien),
				'other' => q(shillings tanzaniens),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia ukrainienne),
				'one' => q(hryvnia ukrainienne),
				'other' => q(hryvnias ukrainiennes),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanetz),
				'one' => q(karbovanets ukrainien \(1992–1996\)),
				'other' => q(karbovanets ukrainiens \(1992–1996\)),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(shilling ougandais \(1966–1987\)),
				'one' => q(shilling ougandais \(1966–1987\)),
				'other' => q(shillings ougandais \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shilling ougandais),
				'one' => q(shilling ougandais),
				'other' => q(shillings ougandais),
			},
		},
		'USD' => {
			symbol => '$US',
			display_name => {
				'currency' => q(dollar des États-Unis),
				'one' => q(dollar des États-Unis),
				'other' => q(dollars des États-Unis),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dollar des Etats-Unis \(jour suivant\)),
				'one' => q(dollar des États-Unis \(jour suivant\)),
				'other' => q(dollars des États-Unis \(jour suivant\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dollar des Etats-Unis \(jour même\)),
				'one' => q(dollar des États-Unis \(jour même\)),
				'other' => q(dollars des États-Unis \(jour même\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguayen \(unités indexées\)),
				'one' => q(peso uruguayen \(unités indexées\)),
				'other' => q(pesos uruguayen \(unités indexées\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguayen \(1975–1993\)),
				'one' => q(peso uruguayen \(1975–1993\)),
				'other' => q(pesos uruguayens \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => '$UY',
			display_name => {
				'currency' => q(peso uruguayen),
				'one' => q(peso uruguayen),
				'other' => q(pesos uruguayens),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(unité de salaire nominal uruguayenne),
				'one' => q(unité de salaire nominal uruguayenne),
				'other' => q(unités de salaire nominales uruguayennes),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum ouzbek),
				'one' => q(sum ouzbek),
				'other' => q(sums ouzbeks),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar vénézuélien \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar vénézuélien \(2008–2018\)),
				'one' => q(bolivar vénézuélien \(2008–2018\)),
				'other' => q(bolivars vénézuéliens \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolivar vénézuélien),
				'one' => q(bolivar vénézuélien),
				'other' => q(bolivars vénézuéliens),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dông vietnamien),
				'one' => q(dông vietnamien),
				'other' => q(dôngs vietnamiens),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dông vietnamien \(1978–1985\)),
				'one' => q(dông vietnamien \(1978–1985\)),
				'other' => q(dôngs vietnamiens \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu vanuatuan),
				'one' => q(vatu vanuatuan),
				'other' => q(vatus vanuatuans),
			},
		},
		'WST' => {
			symbol => '$WS',
			display_name => {
				'currency' => q(tala samoan),
				'one' => q(tala samoan),
				'other' => q(talas samoans),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franc CFA \(BEAC\)),
				'one' => q(franc CFA \(BEAC\)),
				'other' => q(francs CFA \(BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(argent),
				'one' => q(once troy d’argent),
				'other' => q(onces troy d’argent),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(or),
				'one' => q(once troy d’or),
				'other' => q(onces troy d’or),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unité européenne composée),
				'one' => q(unité composée européenne \(EURCO\)),
				'other' => q(unités composées européennes \(EURCO\)),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unité monétaire européenne),
				'one' => q(unité monétaire européenne \(UME–6\)),
				'other' => q(unités monétaires européennes \(UME–6\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unité de compte européenne \(XBC\)),
				'one' => q(unité de compte 9 européenne \(UEC–9\)),
				'other' => q(unités de compte 9 européennes \(UEC–9\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unité de compte européenne \(XBD\)),
				'one' => q(unité de compte 17 européenne \(UEC–17\)),
				'other' => q(unités de compte 17 européennes \(UEC–17\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dollar des Caraïbes orientales),
				'one' => q(dollar des Caraïbes orientales),
				'other' => q(dollars des Caraïbes orientales),
			},
		},
		'XCG' => {
			display_name => {
				'currency' => q(florin caribéen),
				'one' => q(florin caribéen),
				'other' => q(florins caribéens),
			},
		},
		'XDR' => {
			symbol => 'DTS',
			display_name => {
				'currency' => q(droit de tirage spécial),
				'one' => q(droit de tirage spécial),
				'other' => q(droits de tirage spéciaux),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unité de compte européenne \(ECU\)),
				'one' => q(unité de compte européenne \(ECU\)),
				'other' => q(unités de compte européennes \(ECU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franc or),
				'one' => q(franc or),
				'other' => q(francs or),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franc UIC),
				'one' => q(franc UIC),
				'other' => q(francs UIC),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franc CFA \(BCEAO\)),
				'one' => q(franc CFA \(BCEAO\)),
				'other' => q(francs CFA \(BCEAO\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'one' => q(once troy de palladium),
				'other' => q(onces troy de palladium),
			},
		},
		'XPF' => {
			symbol => 'FCFP',
			display_name => {
				'currency' => q(franc CFP),
				'one' => q(franc CFP),
				'other' => q(francs CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platine),
				'one' => q(once troy de platine),
				'other' => q(onces troy de platine),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(type de fonds RINET),
				'one' => q(unité de fonds RINET),
				'other' => q(unités de fonds RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucres),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(\(devise de test\)),
				'one' => q(\(devise de test\)),
				'other' => q(\(devises de test\)),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(unité de compte ADB),
				'one' => q(unité de compte ADB),
				'other' => q(unités de compte ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(devise inconnue ou non valide),
				'one' => q(devise inconnue),
				'other' => q(devises inconnues),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar du Yémen),
				'one' => q(dinar nord-yéménite),
				'other' => q(dinars nord-yéménites),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(riyal yéménite),
				'one' => q(riyal yéménite),
				'other' => q(riyals yéménites),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(nouveau dinar yougoslave),
				'one' => q(dinar fort yougoslave \(1966–1989\)),
				'other' => q(dinars forts yougoslaves \(1966–1989\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinar yougoslave Noviy),
				'one' => q(nouveau dinar yougoslave \(1994–2003\)),
				'other' => q(nouveaux dinars yougoslaves \(1994–2003\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar yougoslave convertible),
				'one' => q(dinar convertible yougoslave \(1990–1992\)),
				'other' => q(dinars convertibles yougoslaves \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar réformé yougoslave \(1992–1993\)),
				'one' => q(dinar réformé yougoslave \(1992–1993\)),
				'other' => q(dinars réformés yougoslaves \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sud-africain \(financier\)),
				'one' => q(rand sud-africain \(financier\)),
				'other' => q(rands sud-africains \(financiers\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sud-africain),
				'one' => q(rand sud-africain),
				'other' => q(rands sud-africains),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha zambien \(1968–2012\)),
				'one' => q(kwacha zambien \(1968–2012\)),
				'other' => q(kwachas zambiens \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'Kw',
			display_name => {
				'currency' => q(kwacha zambien),
				'one' => q(kwacha zambien),
				'other' => q(kwachas zambiens),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nouveau zaïre zaïrien),
				'one' => q(nouveau zaïre zaïrien),
				'other' => q(nouveaux zaïres zaïriens),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaïre zaïrois),
				'one' => q(zaïre zaïrois),
				'other' => q(zaïres zaïrois),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dollar zimbabwéen),
				'one' => q(dollar zimbabwéen),
				'other' => q(dollars zimbabwéens),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dollar zimbabwéen \(2009\)),
				'one' => q(dollar zimbabwéen \(2009\)),
				'other' => q(dollars zimbabwéens \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dollar zimbabwéen \(2008\)),
				'one' => q(dollar zimbabwéen \(2008\)),
				'other' => q(dollars zimbabwéens \(2008\)),
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
							'1yuè',
							'2yuè',
							'3yuè',
							'4yuè',
							'5yuè',
							'6yuè',
							'7yuè',
							'8yuè',
							'9yuè',
							'10yuè',
							'11yuè',
							'12yuè'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'zhēngyuè',
							'èryuè',
							'sānyuè',
							'sìyuè',
							'wǔyuè',
							'liùyuè',
							'qīyuè',
							'bāyuè',
							'jiǔyuè',
							'shíyuè',
							'shíyīyuè',
							'shí’èryuè'
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
							'tout',
							'bâb.',
							'hât.',
							'kya.',
							'toub.',
							'amsh.',
							'barma.',
							'barmo.',
							'bash.',
							'ba’o.',
							'abî.',
							'mis.',
							'al-n.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'tout',
							'bâbâ',
							'hâtour',
							'kyahk',
							'toubah',
							'amshîr',
							'barmahât',
							'barmoudah',
							'bashans',
							'ba’ounah',
							'abîb',
							'misra',
							'al-nasi'
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
							'mäs.',
							'teq.',
							'hed.',
							'tah.',
							'ter',
							'yäk.',
							'mäg.',
							'miy.',
							'gue.',
							'sän.',
							'ham.',
							'näh.',
							'pag.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'mäskäräm',
							'teqemt',
							'hedar',
							'tahesas',
							'ter',
							'yäkatit',
							'mägabit',
							'miyazya',
							'guenbot',
							'säné',
							'hamlé',
							'nähasé',
							'pagumén'
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
							'janv.',
							'févr.',
							'mars',
							'avr.',
							'mai',
							'juin',
							'juil.',
							'août',
							'sept.',
							'oct.',
							'nov.',
							'déc.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'janvier',
							'février',
							'mars',
							'avril',
							'mai',
							'juin',
							'juillet',
							'août',
							'septembre',
							'octobre',
							'novembre',
							'décembre'
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
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'tich.',
							'hèch.',
							'kis.',
							'tév.',
							'chev.',
							'ad.I',
							'adar',
							'nis.',
							'iyar',
							'siv.',
							'tam.',
							'av',
							'él.'
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
							'tichri',
							'hèchvan',
							'kislev',
							'téveth',
							'chevat',
							'adar I',
							'adar',
							'nissan',
							'iyar',
							'sivan',
							'tamouz',
							'av',
							'éloul'
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
							'chai.',
							'vai.',
							'jyai.',
							'āsha.',
							'shrā.',
							'bhā.',
							'āshw.',
							'kār.',
							'mār.',
							'pau.',
							'māgh',
							'phāl.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'chaitra',
							'vaishākh',
							'jyaishtha',
							'āshādha',
							'shrāvana',
							'bhādrapad',
							'āshwin',
							'kārtik',
							'mārgashīrsha',
							'paush',
							'māgh',
							'phālgun'
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
							'mouh.',
							'saf.',
							'rab. aw.',
							'rab. th.',
							'joum. oul.',
							'joum. tha.',
							'raj.',
							'chaa.',
							'ram.',
							'chaw.',
							'dhou. q.',
							'dhou. h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'mouharram',
							'safar',
							'rabia al awal',
							'rabia ath-thani',
							'joumada al oula',
							'joumada ath-thania',
							'rajab',
							'chaabane',
							'ramadan',
							'chawwal',
							'dhou al qi`da',
							'dhou al-hijja'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mouh.',
							'saf.',
							'rab. aw.',
							'rab. th.',
							'joum. ou.',
							'joum. th.',
							'raj.',
							'chaa.',
							'ram.',
							'chaw.',
							'dhou. qi.',
							'dhou. hi.'
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
							'far.',
							'ord.',
							'kho.',
							'tir',
							'mor.',
							'šah.',
							'mehr',
							'âbân',
							'âzar',
							'dey',
							'bah.',
							'esf.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'farvardin',
							'ordibehešt',
							'khordâd',
							'tir',
							'mordâd',
							'šahrivar',
							'mehr',
							'âbân',
							'âzar',
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
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mer.',
						thu => 'jeu.',
						fri => 'ven.',
						sat => 'sam.',
						sun => 'dim.'
					},
					short => {
						mon => 'lu',
						tue => 'ma',
						wed => 'me',
						thu => 'je',
						fri => 've',
						sat => 'sa',
						sun => 'di'
					},
					wide => {
						mon => 'lundi',
						tue => 'mardi',
						wed => 'mercredi',
						thu => 'jeudi',
						fri => 'vendredi',
						sat => 'samedi',
						sun => 'dimanche'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
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
					wide => {0 => '1er trimestre',
						1 => '2e trimestre',
						2 => '3e trimestre',
						3 => '4e trimestre'
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
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 400;
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
					'afternoon1' => q{après-midi},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{matin},
					'night1' => q{matin},
					'noon' => q{midi},
				},
				'narrow' => {
					'afternoon1' => q{ap.m.},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{matin},
					'noon' => q{midi},
				},
				'wide' => {
					'afternoon1' => q{de l’après-midi},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'morning1' => q{du matin},
					'night1' => q{du matin},
					'noon' => q{midi},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{ap.m.},
					'evening1' => q{soir},
					'morning1' => q{mat.},
					'night1' => q{matin},
				},
				'wide' => {
					'afternoon1' => q{après-midi},
					'evening1' => q{soir},
					'morning1' => q{matin},
					'night1' => q{matin},
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
				'0' => 'E. B.'
			},
			narrow => {
				'0' => 'EB'
			},
			wide => {
				'0' => 'ère bouddhique'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'av. D.',
				'1' => 'ap. D.'
			},
			wide => {
				'0' => 'avant Dioclétien',
				'1' => 'après Dioclétien'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'av. Inc.',
				'1' => 'ap. Inc.'
			},
			wide => {
				'0' => 'avant l’Incarnation',
				'1' => 'après l’Incarnation'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'av. J.-C.',
				'1' => 'ap. J.-C.'
			},
			wide => {
				'0' => 'avant Jésus-Christ',
				'1' => 'après Jésus-Christ'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'A. M.'
			},
			wide => {
				'0' => 'Anno Mundi'
			},
		},
		'indian' => {
			wide => {
				'0' => 'ère Saka'
			},
		},
		'islamic' => {
			narrow => {
				'0' => 'H'
			},
			wide => {
				'0' => 'ère de l’Hégire'
			},
		},
		'japanese' => {
			abbreviated => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'78' => 'Ten-ei (1110-1113)'
			},
			narrow => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'78' => 'Ten-ei (1110-1113)'
			},
			wide => {
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749-749)',
				'12' => 'Tempyō-shōhō (749-757)',
				'13' => 'Tempyō-hōji (757-765)',
				'14' => 'Temphō-jingo (765-767)',
				'156' => 'Kemmu (1334–1336)',
				'216' => 'Hōryaku (1751–1764)'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'A. P.'
			},
			wide => {
				'0' => 'Anno Persico'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'av. RdC',
				'1' => 'RdC'
			},
			wide => {
				'0' => 'avant RdC'
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
			'full' => q{EEEE d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{d/M/y},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
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
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
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
		'buddhist' => {
			MEd => q{E d/M},
			Md => q{d/M},
		},
		'chinese' => {
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E d MMM U},
			GyMMMd => q{d MMM U},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			y => q{U},
			yMd => q{d/M/y},
			yyyy => q{U},
			yyyyM => q{M/y},
			yyyyMEd => q{E d/M/y},
			yyyyMMM => q{MMM U},
			yyyyMMMEd => q{E d MMM U},
			yyyyMMMM => q{MMMM U},
			yyyyMMMd => q{d MMM U},
			yyyyMd => q{d/M/y},
			yyyyQQQ => q{QQQ U},
			yyyyQQQQ => q{QQQQ U},
		},
		'generic' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{E},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			H => q{HH 'h'},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'semaine' W (MMMM)},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'semaine' w 'de' Y},
		},
		'islamic' => {
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMd => q{d/M/y GGGGG},
		},
		'japanese' => {
			MEd => q{E d/M},
			Md => q{d/M},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMd => q{d/M/y GGGGG},
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
		'buddhist' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{y G – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y G – E dd/MM/y G},
				M => q{E dd/MM – E dd/MM/y G},
				d => q{E dd – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y G – dd/MM/y G},
				M => q{dd/MM – dd/MM/y G},
				d => q{dd–dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
			H => {
				H => q{HH–HH},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			d => {
				d => q{d–d},
			},
			h => {
				h => q{h–h a},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				y => q{MM/y – MM/y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
			},
		},
		'chinese' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'coptic' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'ethiopic' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'generic' => {
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
				G => q{y G 'à' y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y G 'à' M/y G},
				M => q{M–M/y G},
				y => q{M/y 'à' M/y G},
			},
			GyMEd => {
				G => q{E d/M/y G 'à' E d/M/y G},
				M => q{E d/M 'à' E d/M/y G},
				d => q{E d 'à' E d/M/y G},
				y => q{E d/M/y 'à' E d/M/y G},
			},
			GyMMM => {
				G => q{MMM y G 'à' MMM y G},
				M => q{MMM 'à' MMM y G},
				y => q{MMM y 'à' MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G 'à' E d MMM y G},
				M => q{E d MMM 'à' E d MMM y G},
				d => q{E d 'à' E d MMM y G},
				y => q{E d MMM y 'à' E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G 'à' d MMM y G},
				M => q{d MMM 'à' d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y 'à' d MMM y G},
			},
			GyMd => {
				G => q{d/M/y G 'à' d/M/y G},
				M => q{d/M 'à' d/M/y G},
				d => q{d–d/M/y G},
				y => q{d/M/y 'à' d/M/y G},
			},
			H => {
				H => q{HH – HH},
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
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
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
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
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
				G => q{y G 'à' y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM–MM/y G},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E d/MM/y G – E d/MM/y G},
				M => q{E d/MM – E d/MM/y G},
				d => q{E d – E d/MM/y G},
				y => q{E d/MM/y – E d/MM/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/MM/y G – d/MM/y G},
				M => q{d/MM – d/MM/y G},
				d => q{d–d/MM/y G},
				y => q{d/MM/y – d/MM/y G},
			},
			H => {
				H => q{HH – HH},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'hebrew' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'indian' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'islamic' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'japanese' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'persian' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
		'roc' => {
			Bh => {
				h => q{h–h B},
			},
			Bhm => {
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(heure : {0}),
		regionFormat => q({0} (heure d’été)),
		regionFormat => q({0} (heure standard)),
		'Acre' => {
			long => {
				'daylight' => q#heure d’été de l’Acre#,
				'generic' => q#heure de l’Acre#,
				'standard' => q#heure normale de l’Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#heure de l’Afghanistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Le Caire#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Laâyoune#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli (Libye)#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#heure normale d’Afrique centrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#heure normale d’Afrique de l’Est#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#heure normale d’Afrique méridionale#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#heure d’été d’Afrique de l’Ouest#,
				'generic' => q#heure d’Afrique de l’Ouest#,
				'standard' => q#heure normale d’Afrique de l’Ouest#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#heure d’été de l’Alaska#,
				'generic' => q#heure de l’Alaska#,
				'standard' => q#heure normale de l’Alaska#,
			},
			short => {
				'daylight' => q#HEAK#,
				'generic' => q#HAK#,
				'standard' => q#HNAK#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#heure d’été d’Alma Ata#,
				'generic' => q#heure d’Alma Ata#,
				'standard' => q#heure normale d’Alma Ata#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#heure d’été de l’Amazonie#,
				'generic' => q#heure de l’Amazonie#,
				'standard' => q#heure normale de l’Amazonie#,
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
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaïa#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#La Barbade#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caïmans#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Detroit' => {
			exemplarCity => q#Détroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominique#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenade#,
		},
		'America/Havana' => {
			exemplarCity => q#La Havane#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox [Indiana]#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo [Indiana]#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg [Indiana]#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City [Indiana]#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay [Indiana]#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes [Indiana]#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac [Indiana]#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaïque#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello [Kentucky]#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaos#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah (Dakota du Nord)#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center (Dakota du Nord)#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem (Dakota du Nord)#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-d’Espagne#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rico#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Saint-Domingue#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint-Jean de Terre-Neuve#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint-Christophe#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sainte-Lucie#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint-Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint-Vincent#,
		},
		'America/Thule' => {
			exemplarCity => q#Thulé#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#heure d’été du centre nord-américain#,
				'generic' => q#heure du centre nord-américain#,
				'standard' => q#heure normale du centre nord-américain#,
			},
			short => {
				'daylight' => q#HEC#,
				'generic' => q#HC#,
				'standard' => q#HNC#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#heure d’été de l’Est nord-américain#,
				'generic' => q#heure de l’Est nord-américain#,
				'standard' => q#heure normale de l’Est nord-américain#,
			},
			short => {
				'daylight' => q#HEE#,
				'generic' => q#HE#,
				'standard' => q#HNE#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#heure d’été des Rocheuses#,
				'generic' => q#heure des Rocheuses#,
				'standard' => q#heure normale des Rocheuses#,
			},
			short => {
				'daylight' => q#HER#,
				'generic' => q#HR#,
				'standard' => q#HNR#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#heure d’été du Pacifique nord-américain#,
				'generic' => q#heure du Pacifique nord-américain#,
				'standard' => q#heure normale du Pacifique nord-américain#,
			},
			short => {
				'daylight' => q#HEP#,
				'generic' => q#HP#,
				'standard' => q#HNP#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#heure d’été d’Anadyr#,
				'generic' => q#heure d’Anadyr#,
				'standard' => q#heure normale d’Anadyr#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urville#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Showa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#heure d’été d’Apia#,
				'generic' => q#heure d’Apia#,
				'standard' => q#heure normale d’Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#heure d’été d’Aktaou#,
				'generic' => q#heure d’Aktaou#,
				'standard' => q#heure normale d’Aktaou#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#heure d’été d’Aqtöbe#,
				'generic' => q#heure d’Aqtöbe#,
				'standard' => q#heure normale d’Aqtöbe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#heure d’été de l’Arabie#,
				'generic' => q#heure de l’Arabie#,
				'standard' => q#heure normale de l’Arabie#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#heure d’été de l’Argentine#,
				'generic' => q#heure de l’Argentine#,
				'standard' => q#heure normale d’Argentine#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#heure d’été de l’Ouest argentin#,
				'generic' => q#heure de l’Ouest argentin#,
				'standard' => q#heure normale de l’Ouest argentin#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#heure d’été d’Arménie#,
				'generic' => q#heure de l’Arménie#,
				'standard' => q#heure normale de l’Arménie#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma Ata#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktaou#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktioubinsk#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Achgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyraou#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahreïn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakou#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrouth#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bichkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tchita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damas#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaï#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Douchanbé#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagouste#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hébron#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkoutsk#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jérusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kaboul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtchatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandou#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoïarsk#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweït#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manille#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosie#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novossibirsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Ouralsk#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaï#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kzyl Orda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hô-Chi-Minh-Ville#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhaline#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcande#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Séoul#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapour#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tachkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilissi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Téhéran#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Oulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Iakoutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinbourg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#heure d’été de l’Atlantique#,
				'generic' => q#heure de l’Atlantique#,
				'standard' => q#heure normale de l’Atlantique#,
			},
			short => {
				'daylight' => q#HEA#,
				'generic' => q#HA#,
				'standard' => q#HNA#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Açores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudes#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Îles Canaries#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cap-Vert#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Îles Féroé#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madère#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Géorgie du Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sainte-Hélène#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adélaïde#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#heure d’été du centre de l’Australie#,
				'generic' => q#heure du centre de l’Australie#,
				'standard' => q#heure normale du centre de l’Australie#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#heure d’été du centre-ouest de l’Australie#,
				'generic' => q#heure du centre-ouest de l’Australie#,
				'standard' => q#heure normale du centre-ouest de l’Australie#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#heure d’été de l’Est de l’Australie#,
				'generic' => q#heure de l’Est de l’Australie#,
				'standard' => q#heure normale de l’Est de l’Australie#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#heure d’été de l’Ouest de l’Australie#,
				'generic' => q#heure de l’Ouest de l’Australie#,
				'standard' => q#heure normale de l’Ouest de l’Australie#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#heure d’été d’Azerbaïdjan#,
				'generic' => q#heure de l’Azerbaïdjan#,
				'standard' => q#heure normale de l’Azerbaïdjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#heure d’été des Açores#,
				'generic' => q#heure des Açores#,
				'standard' => q#heure normale des Açores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#heure d’été du Bangladesh#,
				'generic' => q#heure du Bangladesh#,
				'standard' => q#heure normale du Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#heure du Bhoutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#heure de Bolivie#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#heure d’été de Brasilia#,
				'generic' => q#heure de Brasilia#,
				'standard' => q#heure normale de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#heure du Brunei#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#heure d’été du Cap-Vert#,
				'generic' => q#heure du Cap-Vert#,
				'standard' => q#heure normale du Cap-Vert#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#heure de Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#heure des Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#heure d’été des îles Chatham#,
				'generic' => q#heure des îles Chatham#,
				'standard' => q#heure normale des îles Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#heure d’été du Chili#,
				'generic' => q#heure du Chili#,
				'standard' => q#heure normale du Chili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#heure d’été de Chine#,
				'generic' => q#heure de la Chine#,
				'standard' => q#heure normale de la Chine#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#heure de l’île Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#heure des îles Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#heure d’été de Colombie#,
				'generic' => q#heure de Colombie#,
				'standard' => q#heure normale de Colombie#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#heure d’été des îles Cook#,
				'generic' => q#heure des îles Cook#,
				'standard' => q#heure normale des îles Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#heure d’été de Cuba#,
				'generic' => q#heure de Cuba#,
				'standard' => q#heure normale de Cuba#,
			},
			short => {
				'daylight' => q#HECU#,
				'generic' => q#HCU#,
				'standard' => q#HNCU#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#heure de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#heure de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#heure du Timor oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#heure d’été de l’île de Pâques#,
				'generic' => q#heure de l’île de Pâques#,
				'standard' => q#heure normale de l’île de Pâques#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#heure de l’Équateur#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#temps universel coordonné#,
			},
			short => {
				'standard' => q#TU#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ville inconnue#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorre#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athènes#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#heure d’été irlandaise#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernesey#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Île de Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbonne#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#heure d’été britannique#,
			},
		},
		'Europe/Malta' => {
			exemplarCity => q#Malte#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscou#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Saint-Marin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Oulianovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Le Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienne#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovie#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#heure d’été d’Europe centrale#,
				'generic' => q#heure d’Europe centrale#,
				'standard' => q#heure normale d’Europe centrale#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#heure d’été d’Europe de l’Est#,
				'generic' => q#heure d’Europe de l’Est#,
				'standard' => q#heure normale d’Europe de l’Est#,
			},
			short => {
				'daylight' => q#EEDT#,
				'generic' => q#EET#,
				'standard' => q#EEST#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#heure de Kaliningrad#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#heure d’été d’Europe de l’Ouest#,
				'generic' => q#heure d’Europe de l’Ouest#,
				'standard' => q#heure normale d’Europe de l’Ouest#,
			},
			short => {
				'daylight' => q#WEDT#,
				'generic' => q#WET#,
				'standard' => q#WEST#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#heure d’été des îles Malouines#,
				'generic' => q#heure des îles Malouines#,
				'standard' => q#heure normale des îles Malouines#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#heure d’été des îles Fidji#,
				'generic' => q#heure des îles Fidji#,
				'standard' => q#heure normale des îles Fidji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#heure de la Guyane française#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#heure des Terres australes et antarctiques françaises#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#heure moyenne de Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#heure des îles Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#heure des îles Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#heure d’été de Géorgie#,
				'generic' => q#heure de la Géorgie#,
				'standard' => q#heure normale de la Géorgie#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#heure des îles Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#heure d’été de l’Est du Groenland#,
				'generic' => q#heure de l’Est du Groenland#,
				'standard' => q#heure normale de l’Est du Groenland#,
			},
			short => {
				'daylight' => q#HEEG#,
				'generic' => q#HEG#,
				'standard' => q#HNEG#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#heure d’été de l’Ouest du Groenland#,
				'generic' => q#heure de l’Ouest du Groenland#,
				'standard' => q#heure normale de l’Ouest du Groenland#,
			},
			short => {
				'daylight' => q#HEOG#,
				'generic' => q#HOG#,
				'standard' => q#HNOG#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#heure de Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#heure du Golfe#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#heure du Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#heure d’été d’Hawaï - Aléoutiennes#,
				'generic' => q#heure d’Hawaï - Aléoutiennes#,
				'standard' => q#heure normale d’Hawaï - Aléoutiennes#,
			},
			short => {
				'daylight' => q#HEHA#,
				'generic' => q#HHA#,
				'standard' => q#HNHA#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#heure d’été de Hong Kong#,
				'generic' => q#heure de Hong Kong#,
				'standard' => q#heure normale de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#heure d’été de Hovd#,
				'generic' => q#heure de Hovd#,
				'standard' => q#heure normale de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#heure de l’Inde#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comores#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurice#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#La Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#heure de l’Océan Indien#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#heure d’Indochine#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#heure du Centre indonésien#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#heure de l’Est indonésien#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#heure de l’Ouest indonésien#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#heure d’été d’Iran#,
				'generic' => q#heure de l’Iran#,
				'standard' => q#heure normale d’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#heure d’été d’Irkoutsk#,
				'generic' => q#heure d’Irkoutsk#,
				'standard' => q#heure normale d’Irkoutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#heure d’été d’Israël#,
				'generic' => q#heure d’Israël#,
				'standard' => q#heure normale d’Israël#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#heure d’été du Japon#,
				'generic' => q#heure du Japon#,
				'standard' => q#heure normale du Japon#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#heure d’été de Petropavlovsk-Kamchatski#,
				'generic' => q#heure de Petropavlovsk-Kamchatski#,
				'standard' => q#heure normale de Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#heure du Kazakhstan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#heure de l’Est du Kazakhstan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#heure de l’Ouest du Kazakhstan#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#heure d’été de Corée#,
				'generic' => q#heure de la Corée#,
				'standard' => q#heure normale de la Corée#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#heure de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#heure d’été de Krasnoïarsk#,
				'generic' => q#heure de Krasnoïarsk#,
				'standard' => q#heure normale de Krasnoïarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#heure du Kirghizistan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#heure de Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#heure des îles de la Ligne#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#heure d’été de Lord Howe#,
				'generic' => q#heure de Lord Howe#,
				'standard' => q#heure normale de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#heure d’été de Macao#,
				'generic' => q#heure de Macao#,
				'standard' => q#heure normale de Macao#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#heure d’été de Magadan#,
				'generic' => q#heure de Magadan#,
				'standard' => q#heure normale de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#heure de la Malaisie#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#heure des Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#heure des îles Marquises#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#heure des îles Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#heure d’été de Maurice#,
				'generic' => q#heure de Maurice#,
				'standard' => q#heure normale de Maurice#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#heure de Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#heure d’été du Pacifique mexicain#,
				'generic' => q#heure du Pacifique mexicain#,
				'standard' => q#heure normale du Pacifique mexicain#,
			},
			short => {
				'daylight' => q#HEPMX#,
				'generic' => q#HPMX#,
				'standard' => q#HNPMX#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#heure d’été d’Oulan-Bator#,
				'generic' => q#heure d’Oulan-Bator#,
				'standard' => q#heure normale d’Oulan-Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#heure d’été de Moscou#,
				'generic' => q#heure de Moscou#,
				'standard' => q#heure normale de Moscou#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#heure du Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#heure de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#heure du Népal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#heure d’été de Nouvelle-Calédonie#,
				'generic' => q#heure de la Nouvelle-Calédonie#,
				'standard' => q#heure normale de la Nouvelle-Calédonie#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#heure d’été de la Nouvelle-Zélande#,
				'generic' => q#heure de la Nouvelle-Zélande#,
				'standard' => q#heure normale de la Nouvelle-Zélande#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#heure d’été de Terre-Neuve#,
				'generic' => q#heure de Terre-Neuve#,
				'standard' => q#heure normale de Terre-Neuve#,
			},
			short => {
				'daylight' => q#HETN#,
				'generic' => q#HTN#,
				'standard' => q#HNTN#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#heure de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#heure d’été de l’île Norfolk#,
				'generic' => q#heure de l’île Norfolk#,
				'standard' => q#heure normale de l’île Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#heure d’été de Fernando de Noronha#,
				'generic' => q#heure de Fernando de Noronha#,
				'standard' => q#heure normale de Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#heure des îles Mariannes du Nord#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#heure d’été de Novossibirsk#,
				'generic' => q#heure de Novossibirsk#,
				'standard' => q#heure normale de Novossibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#heure d’été de Omsk#,
				'generic' => q#heure de Omsk#,
				'standard' => q#heure normale de Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Île de Pâques#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidji#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HT#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Canton#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marquises#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palaos#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#heure d’été du Pakistan#,
				'generic' => q#heure du Pakistan#,
				'standard' => q#heure normale du Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#heure des Palaos#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#heure de la Papouasie-Nouvelle-Guinée#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#heure d’été du Paraguay#,
				'generic' => q#heure du Paraguay#,
				'standard' => q#heure normale du Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#heure d’été du Pérou#,
				'generic' => q#heure du Pérou#,
				'standard' => q#heure normale du Pérou#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#heure d’été des Philippines#,
				'generic' => q#heure des Philippines#,
				'standard' => q#heure normale des Philippines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#heure des îles Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#heure d’été de Saint-Pierre-et-Miquelon#,
				'generic' => q#heure de Saint-Pierre-et-Miquelon#,
				'standard' => q#heure normale de Saint-Pierre-et-Miquelon#,
			},
			short => {
				'daylight' => q#HEPM#,
				'generic' => q#HPM#,
				'standard' => q#HNPM#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#heure des îles Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#heure de l’île de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#heure de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#heure d’été de Kyzylorda#,
				'generic' => q#heure de Kyzylorda#,
				'standard' => q#heure normale de Kyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#heure de La Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#heure de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#heure d’été de Sakhaline#,
				'generic' => q#heure de Sakhaline#,
				'standard' => q#heure normale de Sakhaline#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#heure d’été de Samara#,
				'generic' => q#heure de Samara#,
				'standard' => q#heure normale de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#heure d’été des Samoa#,
				'generic' => q#heure des Samoa#,
				'standard' => q#heure normale des Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#heure des Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#heure de Singapour#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#heure des îles Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#heure de Géorgie du Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#heure du Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#heure de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#heure de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#heure d’été de Taipei#,
				'generic' => q#heure de Taipei#,
				'standard' => q#heure normale de Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#heure du Tadjikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#heure de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#heure d’été de Tonga#,
				'generic' => q#heure des Tonga#,
				'standard' => q#heure normale des Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#heure de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#heure d’été du Turkménistan#,
				'generic' => q#heure du Turkménistan#,
				'standard' => q#heure normale du Turkménistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#heure des Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#heure d’été de l’Uruguay#,
				'generic' => q#heure de l’Uruguay#,
				'standard' => q#heure normale de l’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#heure d’été de l’Ouzbékistan#,
				'generic' => q#heure de l’Ouzbékistan#,
				'standard' => q#heure normale de l’Ouzbékistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#heure d’été de Vanuatu#,
				'generic' => q#heure du Vanuatu#,
				'standard' => q#heure normale du Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#heure du Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#heure d’été de Vladivostok#,
				'generic' => q#heure de Vladivostok#,
				'standard' => q#heure normale de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#heure d’été de Volgograd#,
				'generic' => q#heure de Volgograd#,
				'standard' => q#heure normale de Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#heure de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#heure de l’île Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#heure de Wallis-et-Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#heure d’été de Iakoutsk#,
				'generic' => q#heure de Iakoutsk#,
				'standard' => q#heure normale de Iakoutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#heure d’été d’Ekaterinbourg#,
				'generic' => q#heure d’Ekaterinbourg#,
				'standard' => q#heure normale d’Ekaterinbourg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#heure normale du Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
