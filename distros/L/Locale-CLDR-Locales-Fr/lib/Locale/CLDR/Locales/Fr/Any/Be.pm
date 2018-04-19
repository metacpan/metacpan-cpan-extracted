=head1

Locale::CLDR::Locales::Fr::Any::Be - Package for language French

=cut

package Locale::CLDR::Locales::Fr::Any::Be;
# This file auto generated from Data\common\main\fr_BE.xml
#	on Fri 13 Apr  7:10:50 am GMT

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

extends('Locale::CLDR::Locales::Fr::Any');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine-plural','spellout-ordinal-masculine','spellout-ordinal-feminine-plural','spellout-ordinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
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
					divisor => q(10),
					rule => q(soixante[-→%%et-une→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septante[-→%%et-une→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(quatre-vingt→%%cents-f→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonante[-→%%et-une→]),
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
					divisor => q(10),
					rule => q(soixante[-→%%et-un→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septante[-→%%et-un→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(quatre-vingt→%%cents-m→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonante[-→%%et-un→]),
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
					divisor => q(10),
					rule => q(soixante-→%%et-unieme→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(septantième),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(septante-→%%et-unieme→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(quatre-vingt→%%cents-o→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nonantième),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(nonante-→%%et-unieme→),
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
	} },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub { 
		 sub {
			 my %languages = (
				'frp' => 'franco-provençal',
 				'goh' => 'ancien haut-allemand',
 				'got' => 'gotique',
 				'gu' => 'gujarati',
 				'njo' => 'ao',
 				'se' => 'same du Nord',
 				'sma' => 'same du Sud',
 				'smj' => 'same de Lule',
 				'smn' => 'same d’Inari',
 				'sms' => 'same skolt',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'BN' => 'Brunei',
 			'GS' => 'Îles Géorgie du Sud et Sandwich du Sud',

		}
	},
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 400
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
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

has 'eras' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'short' => q{d/MM/yy GGGGG},
		},
		'gregorian' => {
			'short' => q{d/MM/yy},
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
			'full' => q{H 'h' mm 'min' ss 's' zzzz},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
			H => {
				H => q{HH–HH},
			},
			Hm => {
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			h => {
				h => q{h–h a},
			},
			hm => {
				m => q{h:mm–h:mm a},
			},
			hmv => {
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				h => q{h–h a v},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
