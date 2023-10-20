=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Fr - Package for language French

=cut

package Locale::CLDR::Locales::Fr;
# This file auto generated from Data\common\main\fr.xml
#	on Fri 13 Oct  9:16:24 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.2');

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
 				'av' => 'avar',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azéri',
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
 				'bez' => 'béna',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'bulgare',
 				'bgn' => 'baloutchi occidental',
 				'bho' => 'bhodjpouri',
 				'bi' => 'bichelamar',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
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
 				'co' => 'corse',
 				'cop' => 'copte',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crh' => 'turc de Crimée',
 				'crs' => 'créole seychellois',
 				'cs' => 'tchèque',
 				'csb' => 'kachoube',
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
 				'ebu' => 'embou',
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
 				'en_GB@alt=short' => 'anglais (R.-U.)',
 				'en_US' => 'anglais américain',
 				'en_US@alt=short' => 'anglais (É.-U.)',
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
 				'frr' => 'frison du Nord',
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
 				'gom' => 'konkani de Goa',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotique',
 				'grb' => 'grebo',
 				'grc' => 'grec ancien',
 				'gsw' => 'suisse allemand',
 				'gu' => 'goudjerati',
 				'guc' => 'wayuu',
 				'gur' => 'gurenne',
 				'guz' => 'gusii',
 				'gv' => 'mannois',
 				'gwi' => 'gwichʼin',
 				'ha' => 'haoussa',
 				'hai' => 'haida',
 				'hak' => 'hakka',
 				'haw' => 'hawaïen',
 				'he' => 'hébreu',
 				'hi' => 'hindi',
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
 				'ksh' => 'francique ripuaire',
 				'ku' => 'kurde',
 				'kum' => 'koumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornique',
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
 				'liv' => 'livonien',
 				'lkt' => 'lakota',
 				'lmo' => 'lombard',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'mongo',
 				'lou' => 'créole louisianais',
 				'loz' => 'lozi',
 				'lrc' => 'lori du Nord',
 				'lt' => 'lituanien',
 				'ltg' => 'latgalien',
 				'lu' => 'luba-katanga (kiluba)',
 				'lua' => 'luba-kasaï (ciluba)',
 				'lui' => 'luiseño',
 				'lun' => 'lunda',
 				'luo' => 'luo',
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
 				'njo' => 'Ao',
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
 				'pl' => 'polonais',
 				'pms' => 'piémontais',
 				'pnt' => 'pontique',
 				'pon' => 'pohnpei',
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
 				'rif' => 'rifain',
 				'rm' => 'romanche',
 				'rn' => 'roundi',
 				'ro' => 'roumain',
 				'ro_MD' => 'moldave',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'racine',
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
 				'tcy' => 'toulou',
 				'te' => 'télougou',
 				'tem' => 'timné',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tétoum',
 				'tg' => 'tadjik',
 				'th' => 'thaï',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turc',
 				'tru' => 'touroyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonien',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatar',
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
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapois',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatou',
 				'yue' => 'cantonais',
 				'za' => 'zhuang',
 				'zap' => 'zapotèque',
 				'zbl' => 'symboles Bliss',
 				'zea' => 'zélandais',
 				'zen' => 'zenaga',
 				'zgh' => 'amazighe standard marocain',
 				'zh' => 'chinois',
 				'zh_Hans' => 'chinois simplifié',
 				'zh_Hant' => 'chinois traditionnel',
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
 			'Cirt' => 'cirth',
 			'Copt' => 'copte',
 			'Cprt' => 'syllabaire chypriote',
 			'Cyrl' => 'cyrillique',
 			'Cyrs' => 'cyrillique (variante slavonne)',
 			'Deva' => 'dévanagari',
 			'Dogr' => 'dogri',
 			'Dsrt' => 'déséret',
 			'Dupl' => 'sténographie Duployé',
 			'Egyd' => 'démotique égyptien',
 			'Egyh' => 'hiératique égyptien',
 			'Egyp' => 'hiéroglyphes égyptiens',
 			'Elba' => 'elbasan',
 			'Ethi' => 'éthiopique',
 			'Geok' => 'géorgien khoutsouri',
 			'Geor' => 'géorgien',
 			'Glag' => 'glagolitique',
 			'Gong' => 'gondi de Gundjala',
 			'Gonm' => 'gondi de Masaram',
 			'Goth' => 'gotique',
 			'Gran' => 'grantha',
 			'Grek' => 'grec',
 			'Gujr' => 'goudjarâtî',
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
 			'Khar' => 'kharochthî',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khodjki',
 			'Knda' => 'kannara',
 			'Kore' => 'coréen',
 			'Kpel' => 'kpelle',
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
 			'Narb' => 'nord-arabique',
 			'Nbat' => 'nabatéen',
 			'Newa' => 'néwa',
 			'Nkgb' => 'géba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogam',
 			'Olck' => 'ol tchiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'odia',
 			'Osge' => 'osage',
 			'Osma' => 'osmanais',
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
 			'Ugar' => 'ougaritique',
 			'Vaii' => 'vaï',
 			'Visp' => 'parole visible',
 			'Wara' => 'warang citi',
 			'Wole' => 'woléaï',
 			'Xpeo' => 'cunéiforme persépolitain',
 			'Xsux' => 'cunéiforme suméro-akkadien',
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
 			'BN' => 'Brunéi Darussalam',
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
 			'CI@alt=variant' => '​​République de Côte d’Ivoire',
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
 			'FK@alt=variant' => 'Îles Falkland',
 			'FM' => 'États fédérés de Micronésie',
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
 			'GS' => 'Géorgie du Sud et îles Sandwich du Sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinée-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'R.A.S. chinoise de Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Îles Heard et McDonald',
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
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islande',
 			'IT' => 'Italie',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaïque',
 			'JO' => 'Jordanie',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
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
 			'LR' => 'Libéria',
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
 			'MK' => 'Macédoine',
 			'MK@alt=variant' => 'Macédoine (ARYM)',
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
 			'NG' => 'Nigéria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Pays-Bas',
 			'NO' => 'Norvège',
 			'NP' => 'Népal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nouvelle-Zélande',
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
 			'SZ' => 'Swaziland',
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
 			'TT' => 'Trinité-et-Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taïwan',
 			'TZ' => 'Tanzanie',
 			'UA' => 'Ukraine',
 			'UG' => 'Ouganda',
 			'UM' => 'Îles mineures éloignées des États-Unis',
 			'UN' => 'Nations Unies',
 			'UN@alt=short' => 'NU',
 			'US' => 'États-Unis',
 			'US@alt=short' => 'É.-U.',
 			'UY' => 'Uruguay',
 			'UZ' => 'Ouzbékistan',
 			'VA' => 'État de la Cité du Vatican',
 			'VC' => 'Saint-Vincent-et-les-Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Îles Vierges britanniques',
 			'VI' => 'Îles Vierges des États-Unis',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis-et-Futuna',
 			'WS' => 'Samoa',
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
 			'ALALC97' => 'romanisation ALA-LC de 1997',
 			'ALUKU' => 'dialecte aluku',
 			'AREVELA' => 'arménien oriental',
 			'AREVMDA' => 'arménien occidental',
 			'BAKU1926' => 'alphabet latin altaïque unifié',
 			'BALANKA' => 'dialecte balanka d’Anii',
 			'BARLA' => 'groupe dialectal capverdien barlavento',
 			'BAUDDHA' => 'variante hybride bouddhiste',
 			'BISCAYAN' => 'biscayen',
 			'BISKE' => 'dialecte de San Giorgio / Bila',
 			'BOHORIC' => 'alphabet Bohorič',
 			'BOONT' => 'dialecte boontling',
 			'DAJNKO' => 'alphabet Dajnko',
 			'EKAVSK' => 'prononciation serbe ékavienne',
 			'EMODENG' => 'ancien anglais moderne',
 			'FONIPA' => 'alphabet phonétique international',
 			'FONUPA' => 'alphabet phonétique ouralique',
 			'FONXSAMP' => 'alphabet phonétique X-SAMPA',
 			'HEPBURN' => 'romanisation Hepburn',
 			'HOGNORSK' => 'dialecte høgnorsk',
 			'IJEKAVSK' => 'prononciation serbe ijékavienne',
 			'ITIHASA' => 'variante épique',
 			'JAUER' => 'dialecte jauer',
 			'JYUTPING' => 'romanisation Jyutping',
 			'KKCOR' => 'orthographe commune',
 			'KOCIEWIE' => 'dialecte polonais kociewiacy',
 			'KSCOR' => 'orthographe standard',
 			'LAUKIKA' => 'variante classique',
 			'LIPAW' => 'dialecte lipovaz de Resia',
 			'LUNA1918' => 'orthographe russe réformée de 1918',
 			'METELKO' => 'alphabet Metelko',
 			'MONOTON' => 'monotonique',
 			'NDYUKA' => 'dialecte ndyuka',
 			'NEDIS' => 'dialecte de Natisone',
 			'NJIVA' => 'dialecte de Gniva / Njiva',
 			'NULIK' => 'volapük moderne',
 			'OSOJS' => 'dialecte d’Oseacco / Osojane',
 			'PAMAKA' => 'dialecte pamaka',
 			'PETR1708' => 'orthographe pétrine de 1708',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonique',
 			'POSIX' => 'informatique',
 			'PUTER' => 'idiome puter',
 			'REVISED' => 'orthographe révisée',
 			'RIGIK' => 'volapük classique',
 			'ROZAJ' => 'dialecte de Resia',
 			'RUMGR' => 'standard des Grisons',
 			'SAAHO' => 'dialecte saho',
 			'SCOTLAND' => 'anglais standard écossais',
 			'SCOUSE' => 'dialecte scouse',
 			'SOLBA' => 'dialecte de Stolvizza / Solbica',
 			'SOTAV' => 'groupe dialectal capverdien sotavento',
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
			'calendar' => 'calendrier',
 			'cf' => 'format de devise',
 			'colalternate' => 'Tri ne tenant pas compte des symboles',
 			'colbackwards' => 'Tri inversé des caractères accentués',
 			'colcasefirst' => 'Classement basé sur les majuscules et les minuscules',
 			'colcaselevel' => 'Tri sensible à la casse',
 			'collation' => 'ordre de tri',
 			'colnormalization' => 'Tri normalisé',
 			'colnumeric' => 'Tri numérique',
 			'colstrength' => 'Priorité du tri',
 			'currency' => 'devise',
 			'hc' => 'système horaire (12 ou 24 heures)',
 			'lb' => 'style de saut de ligne',
 			'ms' => 'système de mesure',
 			'numbers' => 'nombres',
 			'timezone' => 'Fuseau horaire',
 			'va' => 'Variante locale',
 			'x' => 'Usage privé',

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
 				'islamic' => q{calendrier musulman},
 				'islamic-civil' => q{calendrier musulman (tabulaire, époque civile)},
 				'islamic-rgsa' => q{calendrier musulman (observé, Arabie Saoudite)},
 				'islamic-tbla' => q{calendrier musulman (tabulaire, époque astronomique)},
 				'islamic-umalqura' => q{calendrier musulman (Umm al Qura)},
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
 				'reformed' => q{ordre réformé},
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
 				'ethi' => q{chiffres éthiopiens},
 				'finance' => q{Chiffres financiers},
 				'fullwide' => q{chiffres pleine chasse},
 				'geor' => q{chiffres géorgiens},
 				'gong' => q{chiffres gondi gunjala},
 				'gonm' => q{chiffres gondi masaram},
 				'grek' => q{chiffres grecs},
 				'greklow' => q{chiffres grecs minuscules},
 				'gujr' => q{chiffres goudjarâtîs},
 				'guru' => q{chiffres gourmoukhîs},
 				'hanidec' => q{nombres décimaux chinois},
 				'hans' => q{chiffres en chinois simplifié},
 				'hansfin' => q{chiffres financiers en chinois simplifié},
 				'hant' => q{chiffres en chinois traditionnel},
 				'hantfin' => q{chiffres financiers en chinois traditionnel},
 				'hebr' => q{chiffres hébreux},
 				'hmng' => q{chiffres pahawh hmongs},
 				'java' => q{chiffres javanais},
 				'jpan' => q{chiffres japonais},
 				'jpanfin' => q{chiffres japonais financiers},
 				'kali' => q{chiffres kayah li},
 				'khmr' => q{chiffres khmers},
 				'knda' => q{chiffres en kannada},
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
 				'mymrshan' => q{chiffres birmans shans},
 				'mymrtlng' => q{chiffres birmans tai laings},
 				'native' => q{Chiffres natifs},
 				'nkoo' => q{chiffres n’kos},
 				'olck' => q{chiffres ol-tchikis},
 				'orya' => q{chiffres oriyas},
 				'osma' => q{chiffres osmanyas},
 				'rohg' => q{chiffres rohingyas hanifis},
 				'roman' => q{chiffres romains},
 				'romanlow' => q{chiffres romains minuscules},
 				'saur' => q{chiffres saurashtras},
 				'shrd' => q{chiffres sharadas},
 				'sind' => q{chiffres khudawadis},
 				'sinh' => q{chiffres cinghalais liths},
 				'sora' => q{chiffres sora-sompengs},
 				'sund' => q{chiffres soundanais},
 				'takr' => q{chiffres takris},
 				'talu' => q{chiffres néo-taï-luës},
 				'taml' => q{chiffres tamouls traditionnels},
 				'tamldec' => q{chiffres tamouls},
 				'telu' => q{chiffres télougous},
 				'thai' => q{chiffres thaïs},
 				'tibt' => q{chiffres tibétains},
 				'tirh' => q{chiffres tirhutas},
 				'traditional' => q{Chiffres traditionnels},
 				'vaii' => q{Chiffres en vaï},
 				'wara' => q{chiffres warang-citis},
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
			auxiliary => qr{[á å ä ã ā ć ē í ì ī ĳ ñ ó ò ö õ ø ř š ſ ß ú ǔ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a à â æ b c ç d e é è ê ë f g h i î ï j k l m n o ô œ p q r s t u ù û ü v w x y ÿ z]},
			numbers => qr{[  \- , . % ‰ + − 0 1 2 ² 3 ³ 4 5 6 7 8 9 ᵈ ᵉ ʳ ˢ]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ’ " “ ” « » ( ) \[ \] § @ * / \& # † ‡]},
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
	default		=> qq{«},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{»},
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
					'' => {
						'name' => q(direction),
					},
					'acre' => {
						'name' => q(acres anglo-saxonnes),
						'one' => q({0} acre anglo-saxonne),
						'other' => q({0} acres anglo-saxonnes),
					},
					'acre-foot' => {
						'name' => q(acres-pieds),
						'one' => q({0} acre-pied),
						'other' => q({0} acres-pieds),
					},
					'ampere' => {
						'name' => q(ampères),
						'one' => q({0} ampère),
						'other' => q({0} ampères),
					},
					'arc-minute' => {
						'name' => q(minutes d’arc),
						'one' => q({0} minute d’arc),
						'other' => q({0} minutes d’arc),
					},
					'arc-second' => {
						'name' => q(secondes d’arc),
						'one' => q({0} seconde d’arc),
						'other' => q({0} secondes d’arc),
					},
					'astronomical-unit' => {
						'name' => q(unités astronomiques),
						'one' => q({0} unité astronomique),
						'other' => q({0} unités astronomiques),
					},
					'atmosphere' => {
						'name' => q(atmosphères),
						'one' => q({0} atmosphère),
						'other' => q({0} atmosphères),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(boisseaux),
						'one' => q({0} boisseau),
						'other' => q({0} boisseaux),
					},
					'byte' => {
						'name' => q(octets),
						'one' => q({0} octet),
						'other' => q({0} octets),
					},
					'calorie' => {
						'name' => q(calories),
						'one' => q({0} calorie),
						'other' => q({0} calories),
					},
					'carat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					'celsius' => {
						'name' => q(degrés Celsius),
						'one' => q({0} degré Celsius),
						'other' => q({0} degrés Celsius),
					},
					'centiliter' => {
						'name' => q(centilitres),
						'one' => q({0} centilitre),
						'other' => q({0} centilitres),
					},
					'centimeter' => {
						'name' => q(centimètres),
						'one' => q({0} centimètre),
						'other' => q({0} centimètres),
						'per' => q({0} par centimètre),
					},
					'century' => {
						'name' => q(siècles),
						'one' => q({0} siècle),
						'other' => q({0} siècles),
					},
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ouest),
					},
					'cubic-centimeter' => {
						'name' => q(centimètres cubes),
						'one' => q({0} centimètre cube),
						'other' => q({0} centimètres cubes),
						'per' => q({0} par centimètre cube),
					},
					'cubic-foot' => {
						'name' => q(pieds cubes),
						'one' => q({0} pied cube),
						'other' => q({0} pieds cubes),
					},
					'cubic-inch' => {
						'name' => q(pouces cubes),
						'one' => q({0} pouce cube),
						'other' => q({0} pouces cubes),
					},
					'cubic-kilometer' => {
						'name' => q(kilomètres cubes),
						'one' => q({0} kilomètre cube),
						'other' => q({0} kilomètres cubes),
					},
					'cubic-meter' => {
						'name' => q(mètres cubes),
						'one' => q({0} mètre cube),
						'other' => q({0} mètres cubes),
						'per' => q({0} par mètre cube),
					},
					'cubic-mile' => {
						'name' => q(milles cubes),
						'one' => q({0} mille cube),
						'other' => q({0} milles cubes),
					},
					'cubic-yard' => {
						'name' => q(yards cubes),
						'one' => q({0} yard cube),
						'other' => q({0} yards cubes),
					},
					'cup' => {
						'name' => q(tasses),
						'one' => q({0} tasse),
						'other' => q({0} tasses),
					},
					'cup-metric' => {
						'name' => q(tasses métriques),
						'one' => q({0} tasse métrique),
						'other' => q({0} tasses métriques),
					},
					'day' => {
						'name' => q(jours),
						'one' => q({0} jour),
						'other' => q({0} jours),
						'per' => q({0} par jour),
					},
					'deciliter' => {
						'name' => q(décilitres),
						'one' => q({0} décilitre),
						'other' => q({0} décilitres),
					},
					'decimeter' => {
						'name' => q(décimètres),
						'one' => q({0} décimètre),
						'other' => q({0} décimètres),
					},
					'degree' => {
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					'fahrenheit' => {
						'name' => q(degrés Fahrenheit),
						'one' => q({0} degré Fahrenheit),
						'other' => q({0} degrés Fahrenheit),
					},
					'fathom' => {
						'name' => q(brasses),
						'one' => q({0} brasse),
						'other' => q({0} brasses),
					},
					'fluid-ounce' => {
						'name' => q(onces liquides),
						'one' => q({0} once liquide),
						'other' => q({0} onces liquides),
					},
					'foodcalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					'foot' => {
						'name' => q(pieds),
						'one' => q({0} pied),
						'other' => q({0} pieds),
						'per' => q({0} par pied),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					'g-force' => {
						'name' => q(accélération de pesanteur terrestre),
						'one' => q({0} fois l’accélération de pesanteur terrestre),
						'other' => q({0} fois l’accélération de pesanteur terrestre),
					},
					'gallon' => {
						'name' => q(gallons),
						'one' => q({0} gallon),
						'other' => q({0} gallons),
						'per' => q({0} par gallon),
					},
					'gallon-imperial' => {
						'name' => q(gallons impériaux),
						'one' => q({0} gallon impérial),
						'other' => q({0} gallons impériaux),
						'per' => q({0} par gallon impérial),
					},
					'generic' => {
						'name' => q(degrés),
						'one' => q({0} degré),
						'other' => q({0} degrés),
					},
					'gigabit' => {
						'name' => q(gigabits),
						'one' => q({0} gigabit),
						'other' => q({0} gigabits),
					},
					'gigabyte' => {
						'name' => q(gigaoctets),
						'one' => q({0} gigaoctet),
						'other' => q({0} gigaoctets),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatts),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatts),
					},
					'gram' => {
						'name' => q(grammes),
						'one' => q({0} gramme),
						'other' => q({0} grammes),
						'per' => q({0} par gramme),
					},
					'hectare' => {
						'name' => q(hectares),
						'one' => q({0} hectare),
						'other' => q({0} hectares),
					},
					'hectoliter' => {
						'name' => q(hectolitres),
						'one' => q({0} hectolitre),
						'other' => q({0} hectolitres),
					},
					'hectopascal' => {
						'name' => q(hectopascals),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascals),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(chevaux-vapeur),
						'one' => q({0} cheval-vapeur),
						'other' => q({0} chevaux-vapeur),
					},
					'hour' => {
						'name' => q(heures),
						'one' => q({0} heure),
						'other' => q({0} heures),
						'per' => q({0} par heure),
					},
					'inch' => {
						'name' => q(pouces),
						'one' => q({0} pouce),
						'other' => q({0} pouces),
						'per' => q({0} par pouce),
					},
					'inch-hg' => {
						'name' => q(pouces de mercure),
						'one' => q({0} pouce de mercure),
						'other' => q({0} pouces de mercure),
					},
					'joule' => {
						'name' => q(joules),
						'one' => q({0} joule),
						'other' => q({0} joules),
					},
					'karat' => {
						'name' => q(carats),
						'one' => q({0} carat),
						'other' => q({0} carats),
					},
					'kelvin' => {
						'name' => q(kelvins),
						'one' => q({0} kelvin),
						'other' => q({0} kelvins),
					},
					'kilobit' => {
						'name' => q(kilobits),
						'one' => q({0} kilobit),
						'other' => q({0} kilobits),
					},
					'kilobyte' => {
						'name' => q(kilooctets),
						'one' => q({0} kilooctet),
						'other' => q({0} kilooctets),
					},
					'kilocalorie' => {
						'name' => q(kilocalories),
						'one' => q({0} kilocalorie),
						'other' => q({0} kilocalories),
					},
					'kilogram' => {
						'name' => q(kilogrammes),
						'one' => q({0} kilogramme),
						'other' => q({0} kilogrammes),
						'per' => q({0} par kg),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoules),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoules),
					},
					'kilometer' => {
						'name' => q(kilomètres),
						'one' => q({0} kilomètre),
						'other' => q({0} kilomètres),
						'per' => q({0} par kilomètre),
					},
					'kilometer-per-hour' => {
						'name' => q(kilomètres par heure),
						'one' => q({0} kilomètre par heure),
						'other' => q({0} kilomètres par heure),
					},
					'kilowatt' => {
						'name' => q(kilowatts),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatts),
					},
					'kilowatt-hour' => {
						'name' => q(kilowattheures),
						'one' => q({0} kilowattheure),
						'other' => q({0} kilowattheures),
					},
					'knot' => {
						'name' => q(nœuds),
						'one' => q({0} nœud),
						'other' => q({0} nœuds),
					},
					'light-year' => {
						'name' => q(années-lumière),
						'one' => q({0} année-lumière),
						'other' => q({0} années-lumière),
					},
					'liter' => {
						'name' => q(litres),
						'one' => q({0} litre),
						'other' => q({0} litres),
						'per' => q({0} par litre),
					},
					'liter-per-100kilometers' => {
						'name' => q(litres aux 100 km),
						'one' => q({0} litre aux 100 km),
						'other' => q({0} litres aux 100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(litres au kilomètre),
						'one' => q({0} litre au kilomètre),
						'other' => q({0} litres au kilomètre),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(mégabits),
						'one' => q({0} mégabit),
						'other' => q({0} mégabits),
					},
					'megabyte' => {
						'name' => q(mégaoctets),
						'one' => q({0} mégaoctet),
						'other' => q({0} mégaoctets),
					},
					'megahertz' => {
						'name' => q(mégahertz),
						'one' => q({0} mégahertz),
						'other' => q({0} mégahertz),
					},
					'megaliter' => {
						'name' => q(mégalitres),
						'one' => q({0} mégalitre),
						'other' => q({0} mégalitres),
					},
					'megawatt' => {
						'name' => q(mégawatts),
						'one' => q({0} mégawatt),
						'other' => q({0} mégawatts),
					},
					'meter' => {
						'name' => q(mètres),
						'one' => q({0} mètre),
						'other' => q({0} mètres),
						'per' => q({0} par mètre),
					},
					'meter-per-second' => {
						'name' => q(mètres par seconde),
						'one' => q({0} mètre par seconde),
						'other' => q({0} mètres par seconde),
					},
					'meter-per-second-squared' => {
						'name' => q(mètres par seconde carrée),
						'one' => q({0} mètre par seconde carrée),
						'other' => q({0} mètres par seconde carrée),
					},
					'metric-ton' => {
						'name' => q(tonnes),
						'one' => q({0} tonne),
						'other' => q({0} tonnes),
					},
					'microgram' => {
						'name' => q(microgrammes),
						'one' => q({0} microgramme),
						'other' => q({0} microgrammes),
					},
					'micrometer' => {
						'name' => q(micromètres),
						'one' => q({0} micromètre),
						'other' => q({0} micromètres),
					},
					'microsecond' => {
						'name' => q(microsecondes),
						'one' => q({0} microseconde),
						'other' => q({0} microsecondes),
					},
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					'mile-per-gallon' => {
						'name' => q(miles par gallon),
						'one' => q({0} mile par gallon),
						'other' => q({0} miles par gallon),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miles par gallon impérial),
						'one' => q({0} mile par gallon impérial),
						'other' => q({0} miles par gallon impérial),
					},
					'mile-per-hour' => {
						'name' => q(miles par heure),
						'one' => q({0} mile par heure),
						'other' => q({0} miles par heure),
					},
					'mile-scandinavian' => {
						'name' => q(milles scandinaves),
						'one' => q({0} mille scandinave),
						'other' => q({0} milles scandinaves),
					},
					'milliampere' => {
						'name' => q(milliampères),
						'one' => q({0} milliampère),
						'other' => q({0} milliampères),
					},
					'millibar' => {
						'name' => q(millibars),
						'one' => q({0} millibar),
						'other' => q({0} millibars),
					},
					'milligram' => {
						'name' => q(milligrammes),
						'one' => q({0} milligramme),
						'other' => q({0} milligrammes),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrammes par décilitre),
						'one' => q({0} milligramme par décilitre),
						'other' => q({0} milligrammes par décilitre),
					},
					'milliliter' => {
						'name' => q(millilitres),
						'one' => q({0} millilitre),
						'other' => q({0} millilitres),
					},
					'millimeter' => {
						'name' => q(millimètres),
						'one' => q({0} millimètre),
						'other' => q({0} millimètres),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimètres de mercure),
						'one' => q({0} millimètre de mercure),
						'other' => q({0} millimètres de mercure),
					},
					'millimole-per-liter' => {
						'name' => q(millimoles par litre),
						'one' => q({0} millimole par litre),
						'other' => q({0} millimoles par litre),
					},
					'millisecond' => {
						'name' => q(millisecondes),
						'one' => q({0} milliseconde),
						'other' => q({0} millisecondes),
					},
					'milliwatt' => {
						'name' => q(milliwatts),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatts),
					},
					'minute' => {
						'name' => q(minutes),
						'one' => q({0} minute),
						'other' => q({0} minutes),
						'per' => q({0} par minute),
					},
					'month' => {
						'name' => q(mois),
						'one' => q({0} mois),
						'other' => q({0} mois),
						'per' => q({0} par mois),
					},
					'nanometer' => {
						'name' => q(nanomètres),
						'one' => q({0} nanomètre),
						'other' => q({0} nanomètres),
					},
					'nanosecond' => {
						'name' => q(nanosecondes),
						'one' => q({0} nanoseconde),
						'other' => q({0} nanosecondes),
					},
					'nautical-mile' => {
						'name' => q(milles marins),
						'one' => q({0} mille marin),
						'other' => q({0} milles marins),
					},
					'ohm' => {
						'name' => q(ohms),
						'one' => q({0} ohm),
						'other' => q({0} ohms),
					},
					'ounce' => {
						'name' => q(onces),
						'one' => q({0} once),
						'other' => q({0} onces),
						'per' => q({0} par once),
					},
					'ounce-troy' => {
						'name' => q(onces troy),
						'one' => q({0} once troy),
						'other' => q({0} onces troy),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(parts par million),
						'one' => q({0} part par million),
						'other' => q({0} parts par million),
					},
					'per' => {
						'1' => q({0} par {1}),
					},
					'percent' => {
						'name' => q(pour cent),
						'one' => q({0} pour cent),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(pour mille),
						'one' => q({0} pour mille),
						'other' => q({0} pour mille),
					},
					'petabyte' => {
						'name' => q(pétaoctets),
						'one' => q({0} pétaoctet),
						'other' => q({0} pétaoctets),
					},
					'picometer' => {
						'name' => q(picomètres),
						'one' => q({0} picomètre),
						'other' => q({0} picomètres),
					},
					'pint' => {
						'name' => q(pintes),
						'one' => q({0} pinte),
						'other' => q({0} pintes),
					},
					'pint-metric' => {
						'name' => q(pintes métriques),
						'one' => q({0} pinte métrique),
						'other' => q({0} pintes métriques),
					},
					'point' => {
						'name' => q(points),
						'one' => q({0} point),
						'other' => q({0} points),
					},
					'pound' => {
						'name' => q(livres),
						'one' => q({0} livre),
						'other' => q({0} livres),
						'per' => q({0} par livre),
					},
					'pound-per-square-inch' => {
						'name' => q(livres par pouce carré),
						'one' => q({0} livre par pouce carré),
						'other' => q({0} livres par pouce carré),
					},
					'quart' => {
						'name' => q(quarts),
						'one' => q({0} quart),
						'other' => q({0} quarts),
					},
					'radian' => {
						'name' => q(radians),
						'one' => q({0} radian),
						'other' => q({0} radians),
					},
					'revolution' => {
						'name' => q(tour),
						'one' => q({0} tour),
						'other' => q({0} tours),
					},
					'second' => {
						'name' => q(secondes),
						'one' => q({0} seconde),
						'other' => q({0} secondes),
						'per' => q({0} par seconde),
					},
					'square-centimeter' => {
						'name' => q(centimètres carrés),
						'one' => q({0} centimètre carré),
						'other' => q({0} centimètres carrés),
						'per' => q({0} par centimètre carré),
					},
					'square-foot' => {
						'name' => q(pieds carrés),
						'one' => q({0} pied carré),
						'other' => q({0} pieds carrés),
					},
					'square-inch' => {
						'name' => q(pouces carrés),
						'one' => q({0} pouce carré),
						'other' => q({0} pouces carrés),
						'per' => q({0} par pouce carré),
					},
					'square-kilometer' => {
						'name' => q(kilomètres carrés),
						'one' => q({0} kilomètre carré),
						'other' => q({0} kilomètres carrés),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(mètres carrés),
						'one' => q({0} mètre carré),
						'other' => q({0} mètres carrés),
						'per' => q({0} par mètre carré),
					},
					'square-mile' => {
						'name' => q(milles carrés),
						'one' => q({0} mille carré),
						'other' => q({0} milles carrés),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yards carrés),
						'one' => q({0} yard carré),
						'other' => q({0} yards carrés),
					},
					'stone' => {
						'name' => q(stones),
						'one' => q({0} stone),
						'other' => q({0} stones),
					},
					'tablespoon' => {
						'name' => q(cuillères à soupe),
						'one' => q({0} cuillère à soupe),
						'other' => q({0} cuillères à soupe),
					},
					'teaspoon' => {
						'name' => q(cuillères à café),
						'one' => q({0} cuillère à café),
						'other' => q({0} cuillères à café),
					},
					'terabit' => {
						'name' => q(térabits),
						'one' => q({0} térabit),
						'other' => q({0} térabits),
					},
					'terabyte' => {
						'name' => q(téraoctets),
						'one' => q({0} téraoctet),
						'other' => q({0} téraoctets),
					},
					'ton' => {
						'name' => q(tonnes courtes),
						'one' => q({0} tonne courte),
						'other' => q({0} tonnes courtes),
					},
					'volt' => {
						'name' => q(volts),
						'one' => q({0} volt),
						'other' => q({0} volts),
					},
					'watt' => {
						'name' => q(watts),
						'one' => q({0} watt),
						'other' => q({0} watts),
					},
					'week' => {
						'name' => q(semaines),
						'one' => q({0} semaine),
						'other' => q({0} semaines),
						'per' => q({0} par semaine),
					},
					'yard' => {
						'name' => q(yards),
						'one' => q({0} yard),
						'other' => q({0} yards),
					},
					'year' => {
						'name' => q(ans),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0} par an),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(direction),
					},
					'acre' => {
						'name' => q(ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					'acre-foot' => {
						'name' => q(acpi),
						'one' => q({0}acpi),
						'other' => q({0}acpi),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0}ua),
						'other' => q({0}ua),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					'byte' => {
						'name' => q(o),
						'one' => q({0}o),
						'other' => q({0}o),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(s.),
						'one' => q({0} s.),
						'other' => q({0} s.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(pi³),
						'one' => q({0}pi³),
						'other' => q({0}pi³),
					},
					'cubic-inch' => {
						'name' => q(po³),
						'one' => q({0}po³),
						'other' => q({0}po³),
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
						'name' => q(ta),
						'one' => q({0}ta),
						'other' => q({0}ta),
					},
					'cup-metric' => {
						'name' => q(tm),
						'one' => q({0}tm),
						'other' => q({0}tm),
					},
					'day' => {
						'name' => q(j),
						'one' => q({0}j),
						'other' => q({0}j),
						'per' => q({0}/j),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					'foot' => {
						'name' => q(pi),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/pi),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(galIm),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0}Gbit),
						'other' => q({0}Gbit),
					},
					'gigabyte' => {
						'name' => q(Go),
						'one' => q({0}Go),
						'other' => q({0}Go),
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
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
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
						'name' => q(ch),
						'one' => q({0}ch),
						'other' => q({0}ch),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0}h),
						'other' => q({0}h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(po),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/po),
					},
					'inch-hg' => {
						'name' => q(″Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					'karat' => {
						'name' => q(ct),
						'one' => q({0}ct),
						'other' => q({0}ct),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0}kbit),
						'other' => q({0}kbit),
					},
					'kilobyte' => {
						'name' => q(ko),
						'one' => q({0}ko),
						'other' => q({0}ko),
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
						'per' => q({0}/kg),
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
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
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
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0}a.l.),
						'other' => q({0}a.l.),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0}Mbit),
						'other' => q({0}Mbit),
					},
					'megabyte' => {
						'name' => q(Mo),
						'one' => q({0}Mo),
						'other' => q({0}Mo),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
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
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
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
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gIm),
						'one' => q({0}mi/gIm),
						'other' => q({0}mi/gIm),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
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
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0}m.),
						'other' => q({0}m.),
						'per' => q({0}/m.),
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
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(Po),
						'one' => q({0}Po),
						'other' => q({0}Po),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pint' => {
						'name' => q(pte),
						'one' => q({0}pte),
						'other' => q({0}pte),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(lb/po²),
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(tr),
						'one' => q({0}tr),
						'other' => q({0}tr),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(pi²),
						'one' => q({0}pi²),
						'other' => q({0}pi²),
					},
					'square-inch' => {
						'name' => q(po²),
						'one' => q({0}po²),
						'other' => q({0}po²),
						'per' => q({0}/po²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
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
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(CàS),
						'one' => q({0}CàS),
						'other' => q({0}CàS),
					},
					'teaspoon' => {
						'name' => q(CàC),
						'one' => q({0}CàC),
						'other' => q({0}CàC),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0}Tbit),
						'other' => q({0}Tbit),
					},
					'terabyte' => {
						'name' => q(To),
						'one' => q({0}To),
						'other' => q({0}To),
					},
					'ton' => {
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0}sem.),
						'other' => q({0}sem.),
						'per' => q({0}/sem.),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(a),
						'one' => q({0}a),
						'other' => q({0}a),
						'per' => q({0}/a),
					},
				},
				'short' => {
					'' => {
						'name' => q(direction),
					},
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac pi),
						'one' => q({0} ac pi),
						'other' => q({0} ac pi),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(octet),
						'one' => q({0} o),
						'other' => q({0} o),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(siècles),
						'one' => q({0} siècle),
						'other' => q({0} siècles),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(pi³),
						'one' => q({0} pi³),
						'other' => q({0} pi³),
					},
					'cubic-inch' => {
						'name' => q(po³),
						'one' => q({0} po³),
						'other' => q({0} po³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(tasses),
						'one' => q({0} tasse),
						'other' => q({0} tasses),
					},
					'cup-metric' => {
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
					},
					'day' => {
						'name' => q(j),
						'one' => q({0} j),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fth),
						'other' => q({0} fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'foot' => {
						'name' => q(pi),
						'one' => q({0} pi),
						'other' => q({0} pi),
						'per' => q({0}/pi),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(force g),
						'one' => q({0} force g),
						'other' => q({0} force g),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0} gal imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
					},
					'gigabyte' => {
						'name' => q(Go),
						'one' => q({0} Go),
						'other' => q({0} Go),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(ch),
						'one' => q({0} ch),
						'other' => q({0} ch),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(po),
						'one' => q({0} po),
						'other' => q({0} po),
						'per' => q({0}/po),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
					},
					'kilobyte' => {
						'name' => q(ko),
						'one' => q({0} ko),
						'other' => q({0} ko),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
					},
					'megabyte' => {
						'name' => q(Mo),
						'one' => q({0} Mo),
						'other' => q({0} Mo),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					'petabyte' => {
						'name' => q(Po),
						'one' => q({0} Po),
						'other' => q({0} Po),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pte),
						'one' => q({0} pte),
						'other' => q({0} pte),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(points),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(lb/po²),
						'one' => q({0} lb/po²),
						'other' => q({0} lb/po²),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(pi²),
						'one' => q({0} pi²),
						'other' => q({0} pi²),
					},
					'square-inch' => {
						'name' => q(po²),
						'one' => q({0} po²),
						'other' => q({0} po²),
						'per' => q({0}/po²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(c. à s.),
						'one' => q({0} c. à s.),
						'other' => q({0} c. à s.),
					},
					'teaspoon' => {
						'name' => q(c. à c.),
						'one' => q({0} c. à c.),
						'other' => q({0} c. à c.),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(To),
						'one' => q({0} To),
						'other' => q({0} To),
					},
					'ton' => {
						'name' => q(sh tn),
						'one' => q({0} sh tn),
						'other' => q({0} sh tn),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(sem.),
						'one' => q({0} sem.),
						'other' => q({0} sem.),
						'per' => q({0}/sem.),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(ans),
						'one' => q({0} an),
						'other' => q({0} ans),
						'per' => q({0}/an),
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
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} et {1}),
				2 => q({0} et {1}),
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
		'arab' => {
			'decimal' => q(٫),
			'exponential' => q(اس),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‏−),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‏+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎−),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'bali' => {
			'timeSeparator' => q(:),
		},
		'beng' => {
			'timeSeparator' => q(:),
		},
		'brah' => {
			'timeSeparator' => q(:),
		},
		'cakm' => {
			'timeSeparator' => q(:),
		},
		'cham' => {
			'timeSeparator' => q(:),
		},
		'deva' => {
			'timeSeparator' => q(:),
		},
		'fullwide' => {
			'timeSeparator' => q(:),
		},
		'gong' => {
			'timeSeparator' => q(:),
		},
		'gonm' => {
			'timeSeparator' => q(:),
		},
		'gujr' => {
			'timeSeparator' => q(:),
		},
		'guru' => {
			'timeSeparator' => q(:),
		},
		'hanidec' => {
			'timeSeparator' => q(:),
		},
		'java' => {
			'timeSeparator' => q(:),
		},
		'kali' => {
			'timeSeparator' => q(:),
		},
		'khmr' => {
			'timeSeparator' => q(:),
		},
		'knda' => {
			'timeSeparator' => q(:),
		},
		'lana' => {
			'timeSeparator' => q(:),
		},
		'lanatham' => {
			'timeSeparator' => q(:),
		},
		'laoo' => {
			'timeSeparator' => q(:),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q( ),
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
		'lepc' => {
			'timeSeparator' => q(:),
		},
		'limb' => {
			'timeSeparator' => q(:),
		},
		'mlym' => {
			'timeSeparator' => q(:),
		},
		'mong' => {
			'timeSeparator' => q(:),
		},
		'mtei' => {
			'timeSeparator' => q(:),
		},
		'mymr' => {
			'timeSeparator' => q(:),
		},
		'mymrshan' => {
			'timeSeparator' => q(:),
		},
		'nkoo' => {
			'timeSeparator' => q(:),
		},
		'olck' => {
			'timeSeparator' => q(:),
		},
		'orya' => {
			'timeSeparator' => q(:),
		},
		'osma' => {
			'timeSeparator' => q(:),
		},
		'rohg' => {
			'timeSeparator' => q(:),
		},
		'saur' => {
			'timeSeparator' => q(:),
		},
		'shrd' => {
			'timeSeparator' => q(:),
		},
		'sora' => {
			'timeSeparator' => q(:),
		},
		'sund' => {
			'timeSeparator' => q(:),
		},
		'takr' => {
			'timeSeparator' => q(:),
		},
		'talu' => {
			'timeSeparator' => q(:),
		},
		'tamldec' => {
			'timeSeparator' => q(:),
		},
		'telu' => {
			'timeSeparator' => q(:),
		},
		'thai' => {
			'timeSeparator' => q(:),
		},
		'tibt' => {
			'timeSeparator' => q(:),
		},
		'vaii' => {
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
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
			symbol => 'ADP',
			display_name => {
				'currency' => q(peseta andorrane),
				'one' => q(peseta andorrane),
				'other' => q(pesetas andorranes),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(dirham des Émirats arabes unis),
				'one' => q(dirham des Émirats arabes unis),
				'other' => q(dirhams des Émirats arabes unis),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(afghani \(1927–2002\)),
				'one' => q(afghani \(1927–2002\)),
				'other' => q(afghanis \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afghani afghan),
				'one' => q(afghani afghan),
				'other' => q(afghanis afghan),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(lek albanais \(1947–1961\)),
				'one' => q(lek albanais \(1947–1961\)),
				'other' => q(leks albanais \(1947–1961\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(lek albanais),
				'one' => q(lek albanais),
				'other' => q(leks albanais),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram arménien),
				'one' => q(dram arménien),
				'other' => q(drams arméniens),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(florin antillais),
				'one' => q(florin antillais),
				'other' => q(florins antillais),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(kwanza angolais),
				'one' => q(kwanza angolais),
				'other' => q(kwanzas angolais),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(kwanza angolais \(1977–1990\)),
				'one' => q(kwanza angolais \(1977–1990\)),
				'other' => q(kwanzas angolais \(1977–1990\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(nouveau kwanza angolais \(1990–2000\)),
				'one' => q(nouveau kwanza angolais \(1990–2000\)),
				'other' => q(nouveaux kwanzas angolais \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(kwanza angolais réajusté \(1995–1999\)),
				'one' => q(kwanza angolais réajusté \(1995–1999\)),
				'other' => q(kwanzas angolais réajustés \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(austral argentin),
				'one' => q(austral argentin),
				'other' => q(australs argentins),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(peso lourd argentin \(1970–1983\)),
				'one' => q(peso lourd argentin \(1970–1983\)),
				'other' => q(pesos lourds argentins \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(peso argentin \(1881–1970\)),
				'one' => q(peso argentin \(1881–1970\)),
				'other' => q(pesos argentins \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
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
			symbol => 'ATS',
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
			symbol => 'AWG',
			display_name => {
				'currency' => q(florin arubais),
				'one' => q(florin arubais),
				'other' => q(florins arubais),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(manat azéri \(1993–2006\)),
				'one' => q(manat azéri \(1993–2006\)),
				'other' => q(manats azéris \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(manat azéri),
				'one' => q(manat azéri),
				'other' => q(manats azéris),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(dinar bosniaque),
				'one' => q(dinar bosniaque),
				'other' => q(dinars bosniaques),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(mark convertible bosniaque),
				'one' => q(mark convertible bosniaque),
				'other' => q(marks convertibles bosniaques),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(nouveau dinar bosniaque \(1994–1997\)),
				'one' => q(nouveau dinar bosniaque \(1994–1997\)),
				'other' => q(nouveaux dinars bosniaques \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dollar barbadien),
				'one' => q(dollar barbadien),
				'other' => q(dollars barbadiens),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(taka bangladeshi),
				'one' => q(taka bangladeshi),
				'other' => q(takas bangladeshis),
			},
		},
		'BEC' => {
			symbol => 'BEC',
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
			symbol => 'BEL',
			display_name => {
				'currency' => q(franc belge \(financier\)),
				'one' => q(franc belge \(financier\)),
				'other' => q(francs belges \(financiers\)),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(lev bulgare \(1962–1999\)),
				'one' => q(lev bulgare \(1962–1999\)),
				'other' => q(levs bulgares \(1962–1999\)),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(lev socialiste bulgare),
				'one' => q(lev socialiste bulgare),
				'other' => q(levs socialistes bulgares),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(lev bulgare),
				'one' => q(lev bulgare),
				'other' => q(levs bulgares),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(lev bulgare \(1879–1952\)),
				'one' => q(lev bulgare \(1879–1952\)),
				'other' => q(levs bulgares \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinar bahreïni),
				'one' => q(dinar bahreïni),
				'other' => q(dinars bahreïnis),
			},
		},
		'BIF' => {
			symbol => 'BIF',
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
			symbol => 'BOB',
			display_name => {
				'currency' => q(boliviano bolivien),
				'one' => q(boliviano bolivien),
				'other' => q(bolivianos boliviens),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(boliviano bolivien \(1863–1963\)),
				'one' => q(boliviano bolivien \(1863–1963\)),
				'other' => q(bolivianos boliviens \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(peso bolivien),
				'one' => q(peso bolivien),
				'other' => q(pesos boliviens),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(mvdol bolivien),
				'one' => q(mvdol bolivien),
				'other' => q(mvdols boliviens),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(nouveau cruzeiro brésilien \(1967–1986\)),
				'one' => q(nouveau cruzeiro brésilien \(1967–1986\)),
				'other' => q(nouveaux cruzeiros brésiliens \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(cruzado brésilien \(1986–1989\)),
				'one' => q(cruzado brésilien \(1986–1989\)),
				'other' => q(cruzados brésiliens \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(cruzeiro brésilien \(1990–1993\)),
				'one' => q(cruzeiro brésilien \(1990–1993\)),
				'other' => q(cruzeiros brésiliens \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(réal brésilien),
				'one' => q(réal brésilien),
				'other' => q(réals brésiliens),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(nouveau cruzado),
				'one' => q(nouveau cruzado brésilien \(1989–1990\)),
				'other' => q(nouveaux cruzados brésiliens \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(cruzeiro),
				'one' => q(cruzeiro réal brésilien \(1993–1994\)),
				'other' => q(cruzeiros réals brésiliens \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(cruzeiro brésilien \(1942–1967\)),
				'one' => q(cruzeiro brésilien \(1942–1967\)),
				'other' => q(cruzeiros brésiliens \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(dollar bahaméen),
				'one' => q(dollar bahaméen),
				'other' => q(dollars bahaméens),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(ngultrum bouthanais),
				'one' => q(ngultrum bouthanais),
				'other' => q(ngultrums bouthanais),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(kyat birman),
				'one' => q(kyat birman),
				'other' => q(kyats birmans),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula botswanais),
				'one' => q(pula botswanais),
				'other' => q(pulas botswanais),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(nouveau rouble biélorusse \(1994–1999\)),
				'one' => q(nouveau rouble biélorusse \(1994–1999\)),
				'other' => q(nouveaux roubles biélorusses \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(rouble biélorusse),
				'one' => q(rouble biélorusse),
				'other' => q(roubles biélorusses),
			},
		},
		'BYR' => {
			symbol => 'BYR',
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
			symbol => 'CDF',
			display_name => {
				'currency' => q(franc congolais),
				'one' => q(franc congolais),
				'other' => q(francs congolais),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(euro WIR),
				'one' => q(euro WIR),
				'other' => q(euros WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franc suisse),
				'one' => q(franc suisse),
				'other' => q(francs suisses),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(franc WIR),
				'one' => q(franc WIR),
				'other' => q(francs WIR),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(escudo chilien),
				'one' => q(escudo chilien),
				'other' => q(escudos chiliens),
			},
		},
		'CLF' => {
			symbol => 'CLF',
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
			symbol => 'CNH',
			display_name => {
				'currency' => q(yuan chinois \(zone extracôtière\)),
				'one' => q(yuan chinois \(zone extracôtière\)),
				'other' => q(yuans chinois \(zone extracôtière\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
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
			symbol => 'COU',
			display_name => {
				'currency' => q(unité de valeur réelle colombienne),
				'one' => q(unité de valeur réelle colombienne),
				'other' => q(unités de valeur réelle colombiennes),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(colón costaricain),
				'one' => q(colón costaricain),
				'other' => q(colóns costaricains),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(dinar serbo-monténégrin),
				'one' => q(dinar serbo-monténégrin),
				'other' => q(dinars serbo-monténégrins),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(couronne forte tchécoslovaque),
				'one' => q(couronne forte tchécoslovaque),
				'other' => q(couronnes fortes tchécoslovaques),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso cubain convertible),
				'one' => q(peso cubain convertible),
				'other' => q(pesos cubains convertibles),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso cubain),
				'one' => q(peso cubain),
				'other' => q(pesos cubains),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
			display_name => {
				'currency' => q(couronne tchèque),
				'one' => q(couronne tchèque),
				'other' => q(couronnes tchèques),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(mark est-allemand),
				'one' => q(mark est-allemand),
				'other' => q(marks est-allemands),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(mark allemand),
				'one' => q(mark allemand),
				'other' => q(marks allemands),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(franc djiboutien),
				'one' => q(franc djiboutien),
				'other' => q(francs djiboutiens),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(couronne danoise),
				'one' => q(couronne danoise),
				'other' => q(couronnes danoises),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominicain),
				'one' => q(peso dominicain),
				'other' => q(pesos dominicains),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(dinar algérien),
				'one' => q(dinar algérien),
				'other' => q(dinars algériens),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(sucre équatorien),
				'one' => q(sucre équatorien),
				'other' => q(sucres équatoriens),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(unité de valeur constante équatoriale \(UVC\)),
				'one' => q(unité de valeur constante équatorienne \(UVC\)),
				'other' => q(unités de valeur constante équatoriennes \(UVC\)),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(couronne estonienne),
				'one' => q(couronne estonienne),
				'other' => q(couronnes estoniennes),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(livre égyptienne),
				'one' => q(livre égyptienne),
				'other' => q(livres égyptiennes),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(nafka érythréen),
				'one' => q(nafka érythréen),
				'other' => q(nafkas érythréens),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(peseta espagnole \(compte A\)),
				'one' => q(peseta espagnole \(compte A\)),
				'other' => q(pesetas espagnoles \(compte A\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(peseta espagnole \(compte convertible\)),
				'one' => q(peseta espagnole \(compte convertible\)),
				'other' => q(pesetas espagnoles \(compte convertible\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(peseta espagnole),
				'one' => q(peseta espagnole),
				'other' => q(pesetas espagnoles),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(birr éthiopien),
				'one' => q(birr éthiopien),
				'other' => q(birrs éthiopiens),
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
			symbol => 'FIM',
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
			symbol => 'GEK',
			display_name => {
				'currency' => q(coupon de lari géorgien),
				'one' => q(coupon de lari géorgien),
				'other' => q(coupons de lari géorgiens),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(lari géorgien),
				'one' => q(lari géorgien),
				'other' => q(lari géorgiens),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(cédi),
				'one' => q(cédi ghanéen \(1967–2007\)),
				'other' => q(cédis ghanéens \(1967–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
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
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi gambien),
				'one' => q(dalasi gambien),
				'other' => q(dalasis gambiens),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(franc guinéen),
				'one' => q(franc guinéen),
				'other' => q(francs guinéens),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(syli guinéen),
				'one' => q(syli guinéen),
				'other' => q(sylis guinéens),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(ekwélé équatoguinéen),
				'one' => q(ekwélé équatoguinéen),
				'other' => q(ekwélés équatoguinéens),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(drachme grecque),
				'one' => q(drachme grecque),
				'other' => q(drachmes grecques),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(quetzal guatémaltèque),
				'one' => q(quetzal guatémaltèque),
				'other' => q(quetzals guatémaltèques),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(escudo de Guinée portugaise),
				'one' => q(escudo de Guinée portugaise),
				'other' => q(escudos de Guinée portugaise),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(peso bissau-guinéen),
				'one' => q(peso bissau-guinéen),
				'other' => q(pesos bissau-guinéens),
			},
		},
		'GYD' => {
			symbol => 'GYD',
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
			symbol => 'HNL',
			display_name => {
				'currency' => q(lempira hondurien),
				'one' => q(lempira hondurien),
				'other' => q(lempiras honduriens),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(dinar croate),
				'one' => q(dinar croate),
				'other' => q(dinars croates),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna croate),
				'one' => q(kuna croate),
				'other' => q(kunas croates),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gourde haïtienne),
				'one' => q(gourde haïtienne),
				'other' => q(gourdes haïtiennes),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(forint hongrois),
				'one' => q(forint hongrois),
				'other' => q(forints hongrois),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => 'ILR',
			display_name => {
				'currency' => q(shekel israélien \(1980–1985\)),
				'one' => q(shekel israélien \(1980–1985\)),
				'other' => q(shekels israéliens \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(nouveau shekel israélien),
				'one' => q(nouveau shekel israélien),
				'other' => q(nouveaux shekels israéliens),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(roupie indienne),
				'one' => q(roupie indienne),
				'other' => q(roupies indiennes),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinar irakien),
				'one' => q(dinar irakien),
				'other' => q(dinars irakiens),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(riyal iranien),
				'one' => q(riyal iranien),
				'other' => q(riyals iraniens),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(couronne islandaise \(1918–1981\)),
				'one' => q(couronne islandaise \(1918–1981\)),
				'other' => q(couronnes islandaises \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
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
			symbol => 'JMD',
			display_name => {
				'currency' => q(dollar jamaïcain),
				'one' => q(dollar jamaïcain),
				'other' => q(dollars jamaïcains),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(shilling kényan),
				'one' => q(shilling kényan),
				'other' => q(shillings kényans),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som kirghize),
				'one' => q(som kirghize),
				'other' => q(soms kirghizes),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel cambodgien),
				'one' => q(riel cambodgien),
				'other' => q(riels cambodgiens),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franc comorien),
				'one' => q(franc comorien),
				'other' => q(francs comoriens),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(won nord-coréen),
				'one' => q(won nord-coréen),
				'other' => q(wons nord-coréens),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(hwan sud-coréen \(1953–1962\)),
				'one' => q(hwan sud-coréen \(1953–1962\)),
				'other' => q(hwans sud-coréens \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(won sud-coréen \(1945–1953\)),
				'one' => q(won sud-coréen \(1945–1953\)),
				'other' => q(wons sud-coréens \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(won sud-coréen),
				'one' => q(won sud-coréen),
				'other' => q(wons sud-coréens),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinar koweïtien),
				'one' => q(dinar koweïtien),
				'other' => q(dinar koweïtiens),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dollar des îles Caïmans),
				'one' => q(dollar des îles Caïmans),
				'other' => q(dollars des îles Caïmans),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tenge kazakh),
				'one' => q(tenge kazakh),
				'other' => q(tenges kazakhs),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip loatien),
				'one' => q(kip loatien),
				'other' => q(kips loatiens),
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
			symbol => 'LKR',
			display_name => {
				'currency' => q(roupie srilankaise),
				'one' => q(roupie srilankaise),
				'other' => q(roupies srilankaises),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dollar libérien),
				'one' => q(dollar libérien),
				'other' => q(dollars libériens),
			},
		},
		'LSL' => {
			symbol => 'lLS',
			display_name => {
				'currency' => q(loti lesothan),
				'one' => q(loti lesothan),
				'other' => q(maloti lesothans),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(litas lituanien),
				'one' => q(litas lituanien),
				'other' => q(litas lituaniens),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(talonas lituanien),
				'one' => q(talonas lituanien),
				'other' => q(talonas lituaniens),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(franc convertible luxembourgeois),
				'one' => q(franc convertible luxembourgeois),
				'other' => q(francs convertibles luxembourgeois),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(franc luxembourgeois),
				'one' => q(franc luxembourgeois),
				'other' => q(francs luxembourgeois),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(franc financier luxembourgeois),
				'one' => q(franc financier luxembourgeois),
				'other' => q(francs financiers luxembourgeois),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(lats letton),
				'one' => q(lats letton),
				'other' => q(lats lettons),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(rouble letton),
				'one' => q(rouble letton),
				'other' => q(roubles lettons),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinar libyen),
				'one' => q(dinar libyen),
				'other' => q(dinars libyens),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MCF',
			display_name => {
				'currency' => q(franc monégasque),
				'one' => q(franc monégasque),
				'other' => q(francs monégasques),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(cupon moldave),
				'one' => q(cupon moldave),
				'other' => q(cupons moldaves),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(leu moldave),
				'one' => q(leu moldave),
				'other' => q(leus moldaves),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
			display_name => {
				'currency' => q(denar macédonien),
				'one' => q(denar macédonien),
				'other' => q(denars macédoniens),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(denar macédonien \(1992–1993\)),
				'one' => q(denar macédonien \(1992–1993\)),
				'other' => q(denars macédoniens \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(franc malien),
				'one' => q(franc malien),
				'other' => q(francs maliens),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat myanmarais),
				'one' => q(kyat myanmarais),
				'other' => q(kyats myanmarais),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongols),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca macanaise),
				'one' => q(pataca macanaise),
				'other' => q(patacas macanaises),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(ouguiya mauritanien \(1973–2017\)),
				'one' => q(ouguiya mauritanien \(1973–2017\)),
				'other' => q(ouguiyas mauritaniens \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(ouguiya mauritanien),
				'one' => q(ouguiya mauritanien),
				'other' => q(ouguiyas mauritaniens),
			},
		},
		'MTL' => {
			symbol => 'MTL',
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(roupie mauricienne),
				'one' => q(roupie mauricienne),
				'other' => q(roupies mauriciennes),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(roupie maldivienne \(1947–1981\)),
				'one' => q(roupie maldivienne \(1947–1981\)),
				'other' => q(roupies maldiviennes \(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rufiyaa maldivien),
				'one' => q(rufiyaa maldivienne),
				'other' => q(rufiyaas maldiviennes),
			},
		},
		'MWK' => {
			symbol => 'MWK',
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
			symbol => 'MXP',
			display_name => {
				'currency' => q(peso d’argent mexicain \(1861–1992\)),
				'one' => q(peso d’argent mexicain \(1861–1992\)),
				'other' => q(pesos d’argent mexicains \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(unité de conversion mexicaine \(UDI\)),
				'one' => q(unité de conversion mexicaine \(UDI\)),
				'other' => q(unités de conversion mexicaines \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(ringgit malais),
				'one' => q(ringgit malais),
				'other' => q(ringgits malais),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(escudo mozambicain),
				'one' => q(escudo mozambicain),
				'other' => q(escudos mozambicains),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(métical),
				'one' => q(metical mozambicain \(1980–2006\)),
				'other' => q(meticais mozambicains \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
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
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira nigérian),
				'one' => q(naira nigérian),
				'other' => q(nairas nigérians),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(cordoba),
				'one' => q(córdoba nicaraguayen \(1912–1988\)),
				'other' => q(córdobas nicaraguayens \(1912–1988\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(córdoba oro nicaraguayen),
				'one' => q(córdoba oro nicaraguayen),
				'other' => q(córdobas oro nicaraguayens),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(florin néerlandais),
				'one' => q(florin néerlandais),
				'other' => q(florins néerlandais),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(couronne norvégienne),
				'one' => q(couronne norvégienne),
				'other' => q(couronnes norvégiennes),
			},
		},
		'NPR' => {
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(riyal omanais),
				'one' => q(riyal omanais),
				'other' => q(riyals omanis),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(balboa panaméen),
				'one' => q(balboa panaméen),
				'other' => q(balboas panaméens),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(inti péruvien),
				'one' => q(inti péruvien),
				'other' => q(intis péruviens),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(sol péruvien),
				'one' => q(sol péruvien),
				'other' => q(sols péruviens),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(sol péruvien \(1863–1985\)),
				'one' => q(sol péruvien \(1863–1985\)),
				'other' => q(sols péruviens \(1863–1985\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(roupie pakistanaise),
				'one' => q(roupie pakistanaise),
				'other' => q(roupies pakistanaises),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(zloty polonais),
				'one' => q(zloty polonais),
				'other' => q(zlotys polonais),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(zloty \(1950–1995\)),
				'one' => q(zloty polonais \(1950–1995\)),
				'other' => q(zlotys polonais \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(escudo portugais),
				'one' => q(escudo portugais),
				'other' => q(escudos portugais),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(guaraní paraguayen),
				'one' => q(guaraní paraguayen),
				'other' => q(guaranís paraguayens),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'ROL',
			display_name => {
				'currency' => q(ancien leu roumain),
				'one' => q(leu roumain \(1952–2005\)),
				'other' => q(lei roumains \(1952–2005\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(leu roumain),
				'one' => q(leu roumain),
				'other' => q(lei roumains),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar serbe),
				'one' => q(dinar serbe),
				'other' => q(dinars serbes),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(rouble russe),
				'one' => q(rouble russe),
				'other' => q(roubles russes),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(rouble russe \(1991–1998\)),
				'one' => q(rouble russe \(1991–1998\)),
				'other' => q(roubles russes \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(franc rwandais),
				'one' => q(franc rwandais),
				'other' => q(francs rwandais),
			},
		},
		'SAR' => {
			symbol => 'SAR',
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
			symbol => 'SCR',
			display_name => {
				'currency' => q(roupie des Seychelles),
				'one' => q(roupie des Seychelles),
				'other' => q(roupies des Seychelles),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(dinar soudanais),
				'one' => q(dinar soudanais \(1992–2007\)),
				'other' => q(dinars soudanais \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(livre soudanaise),
				'one' => q(livre soudanaise),
				'other' => q(livres soudanaises),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(livre soudanaise \(1956–2007\)),
				'one' => q(livre soudanaise \(1956–2007\)),
				'other' => q(livres soudanaises \(1956–2007\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
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
			symbol => 'SHP',
			display_name => {
				'currency' => q(livre de Sainte-Hélène),
				'one' => q(livre de Sainte-Hélène),
				'other' => q(livres de Sainte-Hélène),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(tolar slovène),
				'one' => q(tolar slovène),
				'other' => q(tolars slovènes),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(couronne slovaque),
				'one' => q(couronne slovaque),
				'other' => q(couronnes slovaques),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone sierra-léonais),
				'one' => q(leone sierra-léonais),
				'other' => q(leones sierra-léonais),
			},
		},
		'SOS' => {
			symbol => 'SOS',
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
			symbol => 'SRG',
			display_name => {
				'currency' => q(florin surinamais),
				'one' => q(florin surinamais),
				'other' => q(florins surinamais),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(livre sud-soudanaise),
				'one' => q(livre sud-soudanaise),
				'other' => q(livres sud-soudanaises),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra santoméen \(1977–2017\)),
				'one' => q(dobra santoméen \(1977–2017\)),
				'other' => q(dobras santoméens \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra santoméen),
				'one' => q(dobra santoméen),
				'other' => q(dobras santoméens),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(rouble soviétique),
				'one' => q(rouble soviétique),
				'other' => q(roubles soviétiques),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(colón salvadorien),
				'one' => q(colón salvadorien),
				'other' => q(colóns salvadoriens),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(livre syrienne),
				'one' => q(livre syrienne),
				'other' => q(livres syriennes),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni swazi),
				'one' => q(lilangeni swazi),
				'other' => q(lilangenis swazis),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(baht thaïlandais),
				'one' => q(baht thaïlandais),
				'other' => q(bahts thaïlandais),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(rouble tadjik),
				'one' => q(rouble tadjik),
				'other' => q(roubles tadjiks),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(somoni tadjik),
				'one' => q(somoni tadjik),
				'other' => q(somonis tadjiks),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(manat turkmène),
				'one' => q(manat turkmène),
				'other' => q(manats turkmènes),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(nouveau manat turkmène),
				'one' => q(nouveau manat turkmène),
				'other' => q(nouveaux manats turkmènes),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunisien),
				'one' => q(dinar tunisien),
				'other' => q(dinars tunisiens),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(pa’anga tongan),
				'one' => q(pa’anga tongan),
				'other' => q(pa’angas tongans),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(escudo timorais),
				'one' => q(escudo timorais),
				'other' => q(escudos timorais),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(livre turque \(1844–2005\)),
				'one' => q(livre turque \(1844–2005\)),
				'other' => q(livres turques \(1844–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(livre turque),
				'one' => q(livre turque),
				'other' => q(livres turques),
			},
		},
		'TTD' => {
			symbol => '$TT',
			display_name => {
				'currency' => q(dollar trinidadien),
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(shilling tanzanien),
				'one' => q(shilling tanzanien),
				'other' => q(shillings tanzaniens),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(hryvnia ukrainienne),
				'one' => q(hryvnia ukrainienne),
				'other' => q(hryvnias ukrainiennes),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(karbovanetz),
				'one' => q(karbovanets ukrainien \(1992–1996\)),
				'other' => q(karbovanets ukrainiens \(1992–1996\)),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(shilling ougandais \(1966–1987\)),
				'one' => q(shilling ougandais \(1966–1987\)),
				'other' => q(shillings ougandais \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
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
			symbol => 'USN',
			display_name => {
				'currency' => q(dollar des Etats-Unis \(jour suivant\)),
				'one' => q(dollar des États-Unis \(jour suivant\)),
				'other' => q(dollars des États-Unis \(jour suivant\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(dollar des Etats-Unis \(jour même\)),
				'one' => q(dollar des États-Unis \(jour même\)),
				'other' => q(dollars des États-Unis \(jour même\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(peso uruguayen \(unités indexées\)),
				'one' => q(peso uruguayen \(unités indexées\)),
				'other' => q(pesos uruguayen \(unités indexées\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
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
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(sum ouzbek),
				'one' => q(sum ouzbek),
				'other' => q(sums ouzbeks),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(bolivar vénézuélien \(1871–2008\)),
				'one' => q(bolivar vénézuélien \(1871–2008\)),
				'other' => q(bolivar vénézuélien \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(bolivar vénézuélien \(2008–2018\)),
				'one' => q(bolivar vénézuélien \(2008–2018\)),
				'other' => q(bolivars vénézuéliens \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(bolivar vénézuélien),
				'one' => q(bolivar vénézuélien),
				'other' => q(bolivars vénézuéliens),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dông vietnamien),
				'one' => q(dông vietnamien),
				'other' => q(dôngs vietnamiens),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(dông vietnamien \(1978–1985\)),
				'one' => q(dông vietnamien \(1978–1985\)),
				'other' => q(dôngs vietnamiens \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu vanuatuan),
				'one' => q(vatu vanuatuan),
				'other' => q(vatus vanuatuans),
			},
		},
		'WST' => {
			symbol => 'WS$',
			display_name => {
				'currency' => q(tala samoan),
				'one' => q(tala samoan),
				'other' => q(talas samoans),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(franc CFA \(BEAC\)),
				'one' => q(franc CFA \(BEAC\)),
				'other' => q(francs CFA \(BEAC\)),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(argent),
				'one' => q(once troy d’argent),
				'other' => q(onces troy d’argent),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(or),
				'one' => q(once troy d’or),
				'other' => q(onces troy d’or),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(unité européenne composée),
				'one' => q(unité composée européenne \(EURCO\)),
				'other' => q(unités composées européennes \(EURCO\)),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(unité monétaire européenne),
				'one' => q(unité monétaire européenne \(UME–6\)),
				'other' => q(unités monétaires européennes \(UME–6\)),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(unité de compte européenne \(XBC\)),
				'one' => q(unité de compte 9 européenne \(UEC–9\)),
				'other' => q(unités de compte 9 européennes \(UEC–9\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
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
		'XDR' => {
			symbol => 'DTS',
			display_name => {
				'currency' => q(droit de tirage spécial),
				'one' => q(droit de tirage spécial),
				'other' => q(droits de tirage spéciaux),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(unité de compte européenne \(ECU\)),
				'one' => q(unité de compte européenne \(ECU\)),
				'other' => q(unités de compte européennes \(ECU\)),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(franc or),
				'one' => q(franc or),
				'other' => q(francs or),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(franc UIC),
				'one' => q(franc UIC),
				'other' => q(francs UIC),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(franc CFA \(BCEAO\)),
				'one' => q(franc CFA \(BCEAO\)),
				'other' => q(francs CFA \(BCEAO\)),
			},
		},
		'XPD' => {
			symbol => 'XPD',
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
			symbol => 'XPT',
			display_name => {
				'currency' => q(platine),
				'one' => q(once troy de platine),
				'other' => q(onces troy de platine),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(type de fonds RINET),
				'one' => q(unité de fonds RINET),
				'other' => q(unités de fonds RINET),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucres),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(\(devise de test\)),
				'one' => q(\(devise de test\)),
				'other' => q(\(devises de test\)),
			},
		},
		'XUA' => {
			symbol => 'XUA',
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
			symbol => 'YDD',
			display_name => {
				'currency' => q(dinar du Yémen),
				'one' => q(dinar nord-yéménite),
				'other' => q(dinars nord-yéménites),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(riyal yéménite),
				'one' => q(riyal yéménite),
				'other' => q(riyals yéménites),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(nouveau dinar yougoslave),
				'one' => q(dinar fort yougoslave \(1966–1989\)),
				'other' => q(dinars forts yougoslaves \(1966–1989\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(dinar yougoslave Noviy),
				'one' => q(nouveau dinar yougoslave \(1994–2003\)),
				'other' => q(nouveaux dinars yougoslaves \(1994–2003\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(dinar yougoslave convertible),
				'one' => q(dinar convertible yougoslave \(1990–1992\)),
				'other' => q(dinars convertibles yougoslaves \(1990–1992\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(dinar réformé yougoslave \(1992–1993\)),
				'one' => q(dinar réformé yougoslave \(1992–1993\)),
				'other' => q(dinars réformés yougoslaves \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(rand sud-africain \(financier\)),
				'one' => q(rand sud-africain \(financier\)),
				'other' => q(rands sud-africains \(financiers\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(rand sud-africain),
				'one' => q(rand sud-africain),
				'other' => q(rands sud-africains),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(kwacha zambien \(1968–2012\)),
				'one' => q(kwacha zambien \(1968–2012\)),
				'other' => q(kwachas zambiens \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(kwacha zambien),
				'one' => q(kwacha zambien),
				'other' => q(kwachas zambiens),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(nouveau zaïre zaïrien),
				'one' => q(nouveau zaïre zaïrien),
				'other' => q(nouveaux zaïres zaïriens),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(zaïre zaïrois),
				'one' => q(zaïre zaïrois),
				'other' => q(zaïres zaïrois),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(dollar zimbabwéen),
				'one' => q(dollar zimbabwéen),
				'other' => q(dollars zimbabwéens),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(dollar zimbabwéen \(2009\)),
				'one' => q(dollar zimbabwéen \(2009\)),
				'other' => q(dollars zimbabwéens \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
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
				'stand-alone' => {
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
				'stand-alone' => {
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
			'dangi' => {
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
				'stand-alone' => {
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
				'stand-alone' => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'ad.II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
						],
					},
				},
				'stand-alone' => {
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
							'',
							'',
							'',
							'',
							'',
							'',
							'ad.II'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'adar II'
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
				'stand-alone' => {
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
				'stand-alone' => {
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
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					abbreviated => {
						mon => 'lun.',
						tue => 'mar.',
						wed => 'mer.',
						thu => 'jeu.',
						fri => 'ven.',
						sat => 'sam.',
						sun => 'dim.'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					wide => {0 => '1er trimestre',
						1 => '2e trimestre',
						2 => '3e trimestre',
						3 => '4e trimestre'
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
			if ($_ eq 'dangi') {
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
					'afternoon1' => q{ap.m.},
					'am' => q{AM},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{nuit},
					'noon' => q{midi},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{ap.m.},
					'am' => q{AM},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{nuit},
					'noon' => q{midi},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{de l’après-midi},
					'am' => q{AM},
					'evening1' => q{du soir},
					'midnight' => q{minuit},
					'morning1' => q{du matin},
					'night1' => q{du matin},
					'noon' => q{midi},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{ap.m.},
					'am' => q{AM},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{nuit},
					'noon' => q{midi},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{ap.m.},
					'am' => q{AM},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{mat.},
					'night1' => q{nuit},
					'noon' => q{midi},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{après-midi},
					'am' => q{AM},
					'evening1' => q{soir},
					'midnight' => q{minuit},
					'morning1' => q{matin},
					'night1' => q{nuit},
					'noon' => q{midi},
					'pm' => q{PM},
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
			narrow => {
				'0' => 'av. D.',
				'1' => 'ap. D.'
			},
			wide => {
				'0' => 'avant Dioclétien',
				'1' => 'après Dioclétien'
			},
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'av. Inc.',
				'1' => 'ap. Inc.'
			},
			narrow => {
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
			narrow => {
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
			narrow => {
				'0' => 'AM'
			},
			wide => {
				'0' => 'Anno Mundi'
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
				'0' => 'ère Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'H'
			},
			wide => {
				'0' => 'ère de l’Hégire'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
			narrow => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'M',
				'233' => 'T',
				'234' => 'S',
				'235' => 'H'
			},
			wide => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tempyō (729–749)',
				'11' => 'Tempyō-kampō (749-749)',
				'12' => 'Tempyō-shōhō (749-757)',
				'13' => 'Tempyō-hōji (757-765)',
				'14' => 'Temphō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En’ō (1239–1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kemmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōryaku (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'Shōwa',
				'235' => 'Heisei'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'A. P.'
			},
			narrow => {
				'0' => 'AP'
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
			narrow => {
				'0' => 'av. RdC',
				'1' => 'RdC'
			},
			wide => {
				'0' => 'avant RdC',
				'1' => 'RdC'
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'chinese' => {
			'full' => q{EEEE d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{d/M/y},
		},
		'coptic' => {
		},
		'dangi' => {
			'full' => q{EEEE d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{d MMM U},
			'short' => q{d/M/y},
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
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'japanese' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
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
		'dangi' => {
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
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} 'à' {0}},
			'long' => q{{1} 'à' {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'à' {0}},
			'long' => q{{1} 'à' {0}},
			'medium' => q{{1} 'à' {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
		},
		'chinese' => {
			Gy => q{U},
			GyMMM => q{MMM U},
			GyMMMEd => q{E d MMM U},
			GyMMMd => q{d MMM U},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			ms => q{mm:ss},
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
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
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
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{E},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH 'h'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E dd/MM},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMW => q{'semaine' W (MMMM)},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
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
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E dd/MM},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'japanese' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
				M => q{MM/y – MM/y G},
				y => q{M/y – M/y G},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{dd/MM/y – dd/MM/y G},
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
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
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
				y => q{y–y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
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
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
		},
		'dangi' => {
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(jia-zi),
						1 => q(yi-chou),
						2 => q(bing-yin),
						3 => q(ding-mao),
						4 => q(wu-chen),
						5 => q(ji-si),
						6 => q(geng-wu),
						7 => q(xin-wei),
						8 => q(ren-shen),
						9 => q(gui-you),
						10 => q(jia-xu),
						11 => q(yi-hai),
						12 => q(bing-zi),
						13 => q(ding-chou),
						14 => q(wu-yin),
						15 => q(ji-mao),
						16 => q(geng-chen),
						17 => q(xin-si),
						18 => q(ren-wu),
						19 => q(gui-wei),
						20 => q(jia-shen),
						21 => q(yi-you),
						22 => q(bing-xu),
						23 => q(ding-hai),
						24 => q(wu-zi),
						25 => q(ji-chou),
						26 => q(geng-yin),
						27 => q(xin-mao),
						28 => q(ren-chen),
						29 => q(gui-si),
						30 => q(jia-wu),
						31 => q(yi-wei),
						32 => q(bing-shen),
						33 => q(ding-you),
						34 => q(wu-xu),
						35 => q(ji-hai),
						36 => q(geng-zi),
						37 => q(xin-chou),
						38 => q(ren-yin),
						39 => q(gui-mao),
						40 => q(jia-chen),
						41 => q(yi-si),
						42 => q(bing-wu),
						43 => q(ding-wei),
						44 => q(wu-shen),
						45 => q(ji-you),
						46 => q(geng-xu),
						47 => q(xin-hai),
						48 => q(ren-zi),
						49 => q(gui-chou),
						50 => q(jia-yin),
						51 => q(yi-mao),
						52 => q(bing-chen),
						53 => q(ding-si),
						54 => q(wu-wu),
						55 => q(ji-wei),
						56 => q(geng-shen),
						57 => q(xin-you),
						58 => q(ren-xu),
						59 => q(gui-hai),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(zi),
						1 => q(chou),
						2 => q(yin),
						3 => q(mao),
						4 => q(chen),
						5 => q(si),
						6 => q(wu),
						7 => q(wei),
						8 => q(shen),
						9 => q(you),
						10 => q(xu),
						11 => q(hai),
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
		hourFormat => q(+HH:mm;−HH:mm),
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(heure : {0}),
		regionFormat => q({0} (heure d’été)),
		regionFormat => q({0} (heure standard)),
		fallbackFormat => q({1} ({0})),
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
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis-Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
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
			exemplarCity => q#Le Caire#,
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
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibouti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Laâyoune#,
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
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli (Libye)#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
			exemplarCity => q#Ushuaïa#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
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
			exemplarCity => q#Bogota#,
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
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caïmans#,
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
			exemplarCity => q#Détroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominique#,
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
			exemplarCity => q#Grenade#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
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
			exemplarCity => q#La Havane#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
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
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaïque#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello [Kentucky]#,
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
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaos#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinique#,
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
			exemplarCity => q#Mexico#,
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
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
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
			exemplarCity => q#Beulah (Dakota du Nord)#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center (Dakota du Nord)#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem (Dakota du Nord)#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
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
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-d’Espagne#,
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
			exemplarCity => q#Saint-Domingue#,
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
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tégucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thulé#,
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
				'daylight' => q#heure d’été du Centre#,
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
				'daylight' => q#heure d’été de l’Est#,
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
				'daylight' => q#heure d’été du Pacifique#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Alma Ata#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
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
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrouth#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bichkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tchita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Tchoïbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damas#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dhaka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
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
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hébron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkoutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
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
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandou#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoïarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweït#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
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
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novossibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Ouralsk#,
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
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapour#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
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
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Oulan-Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
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
			exemplarCity => q#Féroé#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madère#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Géorgie du Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sainte-Hélène#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adélaïde#,
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
				'standard' => q#heure du Brunéi#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#heure d’été du Cap-Vert#,
				'generic' => q#heure du Cap-Vert#,
				'standard' => q#heure normale du Cap-Vert#,
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
		'Choibalsan' => {
			long => {
				'daylight' => q#heure d’été de Choibalsan#,
				'generic' => q#heure de Choibalsan#,
				'standard' => q#heure normale de Choibalsan#,
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
				'standard' => q#Temps universel coordonné#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ville inconnue#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorre#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athènes#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrade#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
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
				'daylight' => q#heure d’été irlandaise#,
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
			exemplarCity => q#Île de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbonne#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#heure d’été britannique#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembourg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malte#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
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
			exemplarCity => q#Prague#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rome#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Saint-Marin#,
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
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Oulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Oujgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Le Vatican#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienne#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovie#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporojie#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurich#,
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
				'daylight' => q#heure d’été d’Hawaii - Aléoutiennes#,
				'generic' => q#heure d’Hawaii - Aléoutiennes#,
				'standard' => q#heure normale d’Hawaii - Aléoutiennes#,
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
			exemplarCity => q#Maldives#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurice#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
		'Macquarie' => {
			long => {
				'standard' => q#heure de l’île Macquarie#,
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
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#heure d’été du Nord-Ouest du Mexique#,
				'generic' => q#heure du Nord-Ouest du Mexique#,
				'standard' => q#heure normale du Nord-Ouest du Mexique#,
			},
			short => {
				'daylight' => q#HENOMX#,
				'generic' => q#HNOMX#,
				'standard' => q#HNNOMX#,
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
				'standard' => q#heure de Nioué#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#heure de l’île Norfolk#,
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
			exemplarCity => q#Île de Pâques#,
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
			exemplarCity => q#Fidji#,
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
			exemplarCity => q#Marquises#,
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
			exemplarCity => q#Tahiti#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
