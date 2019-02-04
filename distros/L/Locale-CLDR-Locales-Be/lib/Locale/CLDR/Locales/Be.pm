=encoding utf8

=head1

Locale::CLDR::Locales::Be - Package for language Belarusian

=cut

package Locale::CLDR::Locales::Be;
# This file auto generated from Data\common\main\be.xml
#	on Sun  3 Feb  1:40:05 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-neuter' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нуль),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← коска →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(адна),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(дзве),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцьдзясят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(семсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(васямсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{тысяча}few{тысячы}other{тысяч})$[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільён}few{мільёны}other{мільёнаў})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільярд}few{мільярды}other{мільярдаў})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трыльён}few{трыльёны}other{трылёнаў})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрыльён}few{квадрыльёны}other{квадрыльёнаў})$[ →→]),
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
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нуль),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← коска →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(адзiн),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(два),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(тры),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(чатыры),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пяць),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шэсць),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(сем),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(восем),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(дзевяць),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(дзесяць),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(адзінаццаць),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванаццаць),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(трынаццаць),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(чатырнаццаць),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(пятнаццаць),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(шаснаццаць),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(сямнаццаць),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(васямнаццаць),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(дзевятнаццаць),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцьдзесят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(семсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(восемсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{тысяча}few{тысячы}other{тысяч})$[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільён}few{мільёны}other{мільёнаў})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільярд}few{мільярды}other{мільярдаў})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трыльён}few{трыльёны}other{трылёнаў})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрыльён}few{квадрыльёны}other{квадрыльёнаў})$[ →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нуль),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← коска →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(адно),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(два),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцьдзесят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(сямсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(васямсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{тысяча}few{тысячы}other{тысяч})$[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільён}few{мільёны}other{мільёнаў})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{мільярд}few{мільярды}other{мільярдаў})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трыльён}few{трыльёны}other{трылёнаў})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрыльён}few{квадрыльёны}other{квадрыльёнаў})$[ →→]),
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
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нулявая),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(першая),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(другая),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трэццяя),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(чацьвертая),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пятая),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шостая),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(сёмая),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(восьмая),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(дзявятая),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(дзясятая),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(адзінаццатая),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванаццатая),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(трынаццатая),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(чатырнаццатая),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(пятнаццатая),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(шаснаццатая),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(сямнаццатая),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(васямнаццатая),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(дзевятнаццатая),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццатая),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццатая),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(саракавая),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцідзесятая),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(пяцідзясят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцідзесятая),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(семдзесятая),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(васьмідзясятая),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяностая),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сотая),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвухсотая),
				},
				'201' => {
					base_value => q(201),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трохсотая),
				},
				'301' => {
					base_value => q(301),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырохсотая),
				},
				'401' => {
					base_value => q(401),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцісотая),
				},
				'501' => {
					base_value => q(501),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шасьцісотая),
				},
				'601' => {
					base_value => q(601),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(сямісотая),
				},
				'701' => {
					base_value => q(701),
					divisor => q(100),
					rule => q(семсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(васьмісотая),
				},
				'801' => {
					base_value => q(801),
					divisor => q(100),
					rule => q(васямсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцісотая),
				},
				'901' => {
					base_value => q(901),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячны),
				},
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(дзвух тысячная),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячы[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячная),
				},
				'5001' => {
					base_value => q(5001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяч[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(дзесяці тысячная),
				},
				'10001' => {
					base_value => q(10001),
					divisor => q(1000),
					rule => q(дзесяць тысяч[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(дваццаці тысячная),
				},
				'20001' => {
					base_value => q(20001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'21000' => {
					base_value => q(21000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(сто тысячная),
				},
				'100001' => {
					base_value => q(100001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'110000' => {
					base_value => q(110000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячная[ →→]),
				},
				'200000' => {
					base_value => q(200000),
					divisor => q(100000),
					rule => q(дзвухсот тысячная),
				},
				'200001' => {
					base_value => q(200001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячная[ →→]),
				},
				'300000' => {
					base_value => q(300000),
					divisor => q(100000),
					rule => q(трохсот тысячная),
				},
				'300001' => {
					base_value => q(300001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячная[ →→]),
				},
				'400000' => {
					base_value => q(400000),
					divisor => q(100000),
					rule => q(чатырохсот тысячная),
				},
				'400001' => {
					base_value => q(400001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячная[ →→]),
				},
				'500000' => {
					base_value => q(500000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільён[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёны[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёнаў[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярд[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярды[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярдаў[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльён[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльёны[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трылёнаў[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльён[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёны[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёнаў[ →→]),
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
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нулявы),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(першы),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(другі),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трэйці),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(чацьверты),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пяты),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шосты),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(сёмы),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(восьмы),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(дзявяты),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(дзясяты),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(адзінаццаты),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванаццаты),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(трынаццаты),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(чатырнаццаты),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(пятнаццаты),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(шаснаццаты),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(сямнаццаты),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(васямнаццаты),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(дзевятнаццаты),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццаты),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццаты),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(саракавы),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцідзясяты),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(пяцідзясят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцьдзесяты),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(семдзесяты),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(васьмідзясяты),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяносты),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(соты),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвухсоты),
				},
				'201' => {
					base_value => q(201),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трохсоты),
				},
				'301' => {
					base_value => q(301),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырохсоты),
				},
				'401' => {
					base_value => q(401),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцісоты),
				},
				'501' => {
					base_value => q(501),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шасьцісоты),
				},
				'601' => {
					base_value => q(601),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(сямісоты),
				},
				'701' => {
					base_value => q(701),
					divisor => q(100),
					rule => q(семсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(васьмісоты),
				},
				'801' => {
					base_value => q(801),
					divisor => q(100),
					rule => q(васямсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцісоты),
				},
				'901' => {
					base_value => q(901),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячны),
				},
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(дзвух тысячны),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячы[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячны),
				},
				'5001' => {
					base_value => q(5001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяч[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(дзесяці тысячны),
				},
				'10001' => {
					base_value => q(10001),
					divisor => q(1000),
					rule => q(дзесяць тысяч[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(дваццаці тысячны),
				},
				'20001' => {
					base_value => q(20001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'21000' => {
					base_value => q(21000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(сто тысячны),
				},
				'100001' => {
					base_value => q(100001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'110000' => {
					base_value => q(110000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысячны[ →→]),
				},
				'200000' => {
					base_value => q(200000),
					divisor => q(100000),
					rule => q(дзвухсот тысячны),
				},
				'200001' => {
					base_value => q(200001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысячны[ →→]),
				},
				'300000' => {
					base_value => q(300000),
					divisor => q(100000),
					rule => q(трохсот тысячны),
				},
				'300001' => {
					base_value => q(300001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысячны[ →→]),
				},
				'400000' => {
					base_value => q(400000),
					divisor => q(100000),
					rule => q(чатырохсот тысячны),
				},
				'400001' => {
					base_value => q(400001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысячны[ →→]),
				},
				'500000' => {
					base_value => q(500000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысячнае[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільён[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёны[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёнаў[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярд[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярды[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярдаў[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльён[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльёны[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трылёнаў[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльён[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёны[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёнаў[ →→]),
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
		'spellout-ordinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(мінус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нулявое),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(першае),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(другое),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трэццяе),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(чацьвертае),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пятае),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шостае),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(сёмае),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(восьмае),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(дзявятае),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(дзясятае),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(адзінаццатае),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванаццатае),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(трынаццатае),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(чатырнаццатае),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(пятнаццатае),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(шаснаццатае),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(сямнаццатае),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(васямнаццатае),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(дзевятнаццатае),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(дваццатае),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(дваццаць[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трыццатае),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(трыццаць[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(саракавое),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(сорак[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(пяцьдзесятае),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(пяцідзясят[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шэсцідзясятае),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(шэсцьдзесят[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(сямдзясятае),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(семдзесят[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(васьмідзясятае),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(восемдзесят[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(дзевяностае),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(дзевяноста[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сотае),
				},
				'101' => {
					base_value => q(101),
					divisor => q(100),
					rule => q(сто[ →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(дзвухсотае),
				},
				'201' => {
					base_value => q(201),
					divisor => q(100),
					rule => q(дзвесце[ →→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(трохсотае),
				},
				'301' => {
					base_value => q(301),
					divisor => q(100),
					rule => q(трыста[ →→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(чатырохсотае),
				},
				'401' => {
					base_value => q(401),
					divisor => q(100),
					rule => q(чатырыста[ →→]),
				},
				'500' => {
					base_value => q(500),
					divisor => q(100),
					rule => q(пяцісотае),
				},
				'501' => {
					base_value => q(501),
					divisor => q(100),
					rule => q(пяцьсот[ →→]),
				},
				'600' => {
					base_value => q(600),
					divisor => q(100),
					rule => q(шасьцісотае),
				},
				'601' => {
					base_value => q(601),
					divisor => q(100),
					rule => q(шэсцьсот[ →→]),
				},
				'700' => {
					base_value => q(700),
					divisor => q(100),
					rule => q(сямісотае),
				},
				'701' => {
					base_value => q(701),
					divisor => q(100),
					rule => q(семсот[ →→]),
				},
				'800' => {
					base_value => q(800),
					divisor => q(100),
					rule => q(васьмісотае),
				},
				'801' => {
					base_value => q(801),
					divisor => q(100),
					rule => q(васямсот[ →→]),
				},
				'900' => {
					base_value => q(900),
					divisor => q(100),
					rule => q(дзевяцісотае),
				},
				'901' => {
					base_value => q(901),
					divisor => q(100),
					rule => q(дзевяцьсот[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячны),
				},
				'1001' => {
					base_value => q(1001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(дзвух тысячнае),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячы[ →→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае),
				},
				'5001' => {
					base_value => q(5001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяч[ →→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(дзесяці тысячнае),
				},
				'10001' => {
					base_value => q(10001),
					divisor => q(1000),
					rule => q(дзесяць тысяч[ →→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(дваццаці тысячнае),
				},
				'20001' => {
					base_value => q(20001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'21000' => {
					base_value => q(21000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысяча[ →→]),
				},
				'100000' => {
					base_value => q(100000),
					divisor => q(100000),
					rule => q(сто тысячнае),
				},
				'100001' => {
					base_value => q(100001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine← тысяч[ →→]),
				},
				'110000' => {
					base_value => q(110000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'200000' => {
					base_value => q(200000),
					divisor => q(100000),
					rule => q(дзвухсот тысячнае),
				},
				'200001' => {
					base_value => q(200001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'300000' => {
					base_value => q(300000),
					divisor => q(100000),
					rule => q(трохсот тысячнае),
				},
				'300001' => {
					base_value => q(300001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'400000' => {
					base_value => q(400000),
					divisor => q(100000),
					rule => q(чатырохсот тысячнае),
				},
				'400001' => {
					base_value => q(400001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'500000' => {
					base_value => q(500000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← тысячнае[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільён[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёны[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← мільёнаў[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярд[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярды[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← мільярдаў[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльён[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трыльёны[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трылёнаў[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльён[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёны[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрыльёнаў[ →→]),
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
				'aa' => 'афарская',
 				'ab' => 'абхазская',
 				'ace' => 'ачэх',
 				'ada' => 'адангмэ',
 				'ady' => 'адыгейская',
 				'af' => 'афрыкаанс',
 				'agq' => 'агем',
 				'ain' => 'айнская',
 				'ak' => 'акан',
 				'akk' => 'акадская',
 				'ale' => 'алеуцкая',
 				'alt' => 'паўднёваалтайская',
 				'am' => 'амхарская',
 				'an' => 'арагонская',
 				'ang' => 'стараанглійская',
 				'anp' => 'ангіка',
 				'ar' => 'арабская',
 				'arc' => 'арамейская',
 				'arn' => 'мапудунгун',
 				'arp' => 'арапаха',
 				'as' => 'асамская',
 				'asa' => 'асу',
 				'ast' => 'астурыйская',
 				'av' => 'аварская',
 				'awa' => 'авадхі',
 				'ay' => 'аймара',
 				'az' => 'азербайджанская',
 				'az@alt=short' => 'азербайджанская',
 				'ba' => 'башкірская',
 				'ban' => 'балійская',
 				'bas' => 'басаа',
 				'be' => 'беларуская',
 				'bem' => 'бемба',
 				'bez' => 'бена',
 				'bg' => 'балгарская',
 				'bgn' => 'заходняя белуджская',
 				'bho' => 'бхаджпуры',
 				'bi' => 'біслама',
 				'bin' => 'эда',
 				'bla' => 'блэкфут',
 				'bm' => 'бамбара',
 				'bn' => 'бенгальская',
 				'bo' => 'тыбецкая',
 				'br' => 'брэтонская',
 				'brx' => 'бода',
 				'bs' => 'баснійская',
 				'bua' => 'бурацкая',
 				'bug' => 'бугіс',
 				'byn' => 'білен',
 				'ca' => 'каталанская',
 				'ce' => 'чачэнская',
 				'ceb' => 'себуана',
 				'cgg' => 'чыга',
 				'ch' => 'чамора',
 				'chb' => 'чыбча',
 				'chk' => 'чуук',
 				'chm' => 'мары',
 				'cho' => 'чокта',
 				'chr' => 'чэрокі',
 				'chy' => 'шэйен',
 				'ckb' => 'цэнтральнакурдская',
 				'co' => 'карсіканская',
 				'cop' => 'копцкая',
 				'crs' => 'сэсэльва',
 				'cs' => 'чэшская',
 				'cu' => 'царкоўнаславянская',
 				'cv' => 'чувашская',
 				'cy' => 'валійская',
 				'da' => 'дацкая',
 				'dak' => 'дакота',
 				'dar' => 'даргінская',
 				'dav' => 'таіта',
 				'de' => 'нямецкая',
 				'dgr' => 'догрыб',
 				'dje' => 'зарма',
 				'dsb' => 'ніжнялужыцкая',
 				'dua' => 'дуала',
 				'dv' => 'мальдыўская',
 				'dyo' => 'джола-фоньі',
 				'dz' => 'дзонг-кэ',
 				'dzg' => 'дазага',
 				'ebu' => 'эмбу',
 				'ee' => 'эве',
 				'efi' => 'эфік',
 				'egy' => 'старажытнаегіпецкая',
 				'eka' => 'экаджук',
 				'el' => 'грэчаская',
 				'en' => 'англійская',
 				'en_US@alt=short' => 'англійская (ЗША)',
 				'eo' => 'эсперанта',
 				'es' => 'іспанская',
 				'et' => 'эстонская',
 				'eu' => 'баскская',
 				'ewo' => 'эвонда',
 				'fa' => 'фарсі',
 				'ff' => 'фула',
 				'fi' => 'фінская',
 				'fil' => 'філіпінская',
 				'fj' => 'фіджыйская',
 				'fo' => 'фарэрская',
 				'fon' => 'фон',
 				'fr' => 'французская',
 				'fro' => 'старафранцузская',
 				'fur' => 'фрыульская',
 				'fy' => 'заходняя фрызская',
 				'ga' => 'ірландская',
 				'gaa' => 'га',
 				'gag' => 'гагаузская',
 				'gd' => 'шатландская гэльская',
 				'gez' => 'геэз',
 				'gil' => 'кірыбаці',
 				'gl' => 'галісійская',
 				'gn' => 'гуарані',
 				'gor' => 'гарантала',
 				'grc' => 'старажытнагрэчаская',
 				'gsw' => 'швейцарская нямецкая',
 				'gu' => 'гуджараці',
 				'guz' => 'гусіі',
 				'gv' => 'мэнская',
 				'gwi' => 'гуіч’ін',
 				'ha' => 'хауса',
 				'haw' => 'гавайская',
 				'he' => 'іўрыт',
 				'hi' => 'хіндзі',
 				'hil' => 'хілігайнон',
 				'hmn' => 'хмонг',
 				'hr' => 'харвацкая',
 				'hsb' => 'верхнялужыцкая',
 				'ht' => 'гаіцянская крэольская',
 				'hu' => 'венгерская',
 				'hup' => 'хупа',
 				'hy' => 'армянская',
 				'hz' => 'герэра',
 				'ia' => 'інтэрлінгва',
 				'iba' => 'ібан',
 				'ibb' => 'ібібія',
 				'id' => 'інданезійская',
 				'ie' => 'інтэрлінгвэ',
 				'ig' => 'ігба',
 				'ii' => 'сычуаньская йі',
 				'ilo' => 'ілакана',
 				'inh' => 'інгушская',
 				'io' => 'іда',
 				'is' => 'ісландская',
 				'it' => 'італьянская',
 				'iu' => 'інуктытут',
 				'ja' => 'японская',
 				'jbo' => 'ложбан',
 				'jgo' => 'нгомба',
 				'jmc' => 'мачамбэ',
 				'jv' => 'яванская',
 				'ka' => 'грузінская',
 				'kab' => 'кабільская',
 				'kac' => 'качынская',
 				'kaj' => 'дджу',
 				'kam' => 'камба',
 				'kbd' => 'кабардзінская',
 				'kcg' => 'т’яп',
 				'kde' => 'макондэ',
 				'kea' => 'кабувердыяну',
 				'kfo' => 'кора',
 				'kha' => 'кхасі',
 				'khq' => 'койра чыіні',
 				'ki' => 'кікуйю',
 				'kj' => 'куаньяма',
 				'kk' => 'казахская',
 				'kkj' => 'како',
 				'kl' => 'грэнландская',
 				'kln' => 'календжын',
 				'km' => 'кхмерская',
 				'kmb' => 'кімбунду',
 				'kn' => 'канада',
 				'ko' => 'карэйская',
 				'koi' => 'комі-пярмяцкая',
 				'kok' => 'канкані',
 				'kpe' => 'кпеле',
 				'kr' => 'кануры',
 				'krc' => 'карачай-балкарская',
 				'krl' => 'карэльская',
 				'kru' => 'курух',
 				'ks' => 'кашмірская',
 				'ksb' => 'шамбала',
 				'ksf' => 'бафія',
 				'ksh' => 'кёльнская',
 				'ku' => 'курдская',
 				'kum' => 'кумыцкая',
 				'kv' => 'комі',
 				'kw' => 'корнская',
 				'ky' => 'кіргізская',
 				'la' => 'лацінская',
 				'lad' => 'ладына',
 				'lag' => 'лангі',
 				'lb' => 'люксембургская',
 				'lez' => 'лезгінская',
 				'lg' => 'ганда',
 				'li' => 'лімбургская',
 				'lkt' => 'лакота',
 				'ln' => 'лінгала',
 				'lo' => 'лаоская',
 				'lol' => 'монга',
 				'loz' => 'лозі',
 				'lrc' => 'паўночная луры',
 				'lt' => 'літоўская',
 				'lu' => 'луба-катанга',
 				'lua' => 'луба-касаі',
 				'lun' => 'лунда',
 				'luo' => 'луо',
 				'lus' => 'мізо',
 				'luy' => 'луйя',
 				'lv' => 'латышская',
 				'mad' => 'мадурская',
 				'mag' => 'магахі',
 				'mai' => 'майтхілі',
 				'mak' => 'макасар',
 				'man' => 'мандынг',
 				'mas' => 'маасай',
 				'mdf' => 'макшанская',
 				'men' => 'мендэ',
 				'mer' => 'меру',
 				'mfe' => 'марысьен',
 				'mg' => 'малагасійская',
 				'mgh' => 'макуўа-меета',
 				'mgo' => 'мета',
 				'mh' => 'маршальская',
 				'mi' => 'маары',
 				'mic' => 'мікмак',
 				'min' => 'мінангкабау',
 				'mk' => 'македонская',
 				'ml' => 'малаялам',
 				'mn' => 'мангольская',
 				'mni' => 'мейтэй',
 				'moh' => 'мохак',
 				'mos' => 'мосі',
 				'mr' => 'маратхі',
 				'ms' => 'малайская',
 				'mt' => 'мальтыйская',
 				'mua' => 'мунданг',
 				'mul' => 'некалькі моў',
 				'mus' => 'мускогі',
 				'mwl' => 'мірандыйская',
 				'my' => 'бірманская',
 				'myv' => 'эрзянская',
 				'mzn' => 'мазандэранская',
 				'na' => 'науру',
 				'nap' => 'неапалітанская',
 				'naq' => 'нама',
 				'nb' => 'нарвежская (букмол)',
 				'nd' => 'паўночная ндэбеле',
 				'nds' => 'ніжненямецкая',
 				'nds_NL' => 'ніжнесаксонская',
 				'ne' => 'непальская',
 				'new' => 'неўары',
 				'ng' => 'ндонга',
 				'nia' => 'ніас',
 				'niu' => 'ніўэ',
 				'nl' => 'нідэрландская',
 				'nmg' => 'нгумба',
 				'nn' => 'нарвежская (нюношк)',
 				'nnh' => 'нг’ембон',
 				'no' => 'нарвежская',
 				'nog' => 'нагайская',
 				'non' => 'старанарвежская',
 				'nqo' => 'нко',
 				'nr' => 'паўднёвая ндэбеле',
 				'nso' => 'паўночная сота',
 				'nus' => 'нуэр',
 				'nv' => 'наваха',
 				'ny' => 'ньянджа',
 				'nyn' => 'ньянколе',
 				'oc' => 'аксітанская',
 				'oj' => 'аджыбва',
 				'om' => 'арома',
 				'or' => 'орыя',
 				'os' => 'асецінская',
 				'pa' => 'панджабі',
 				'pag' => 'пангасінан',
 				'pam' => 'пампанга',
 				'pap' => 'пап’яменту',
 				'pau' => 'палау',
 				'pcm' => 'нігерыйскі піджын',
 				'peo' => 'стараперсідская',
 				'phn' => 'фінікійская',
 				'pl' => 'польская',
 				'prg' => 'пруская',
 				'pro' => 'стараправансальская',
 				'ps' => 'пушту',
 				'pt' => 'партугальская',
 				'pt_BR' => 'бразільская партугальская',
 				'pt_PT' => 'еўрапейская партугальская',
 				'qu' => 'кечуа',
 				'quc' => 'кічэ',
 				'raj' => 'раджастханская',
 				'rap' => 'рапануі',
 				'rar' => 'раратонг',
 				'rm' => 'рэтараманская',
 				'rn' => 'рундзі',
 				'ro' => 'румынская',
 				'ro_MD' => 'малдаўская',
 				'rof' => 'ромба',
 				'root' => 'корань',
 				'ru' => 'руская',
 				'rup' => 'арумунская',
 				'rw' => 'руанда',
 				'rwk' => 'руа',
 				'sa' => 'санскрыт',
 				'sad' => 'сандаўэ',
 				'sah' => 'якуцкая',
 				'saq' => 'самбуру',
 				'sat' => 'санталі',
 				'sba' => 'нгамбай',
 				'sbp' => 'сангу',
 				'sc' => 'сардзінская',
 				'scn' => 'сіцылійская',
 				'sco' => 'шатландская',
 				'sd' => 'сіндхі',
 				'sdh' => 'паўднёвакурдская',
 				'se' => 'паўночнасаамская',
 				'seh' => 'сена',
 				'ses' => 'кайрабора сэні',
 				'sg' => 'санга',
 				'sga' => 'стараірландская',
 				'sh' => 'сербскахарвацкая',
 				'shi' => 'ташэльхіт',
 				'shn' => 'шан',
 				'si' => 'сінгальская',
 				'sk' => 'славацкая',
 				'sl' => 'славенская',
 				'sm' => 'самоа',
 				'sma' => 'паўднёвасаамская',
 				'smj' => 'луле-саамская',
 				'smn' => 'інары-саамская',
 				'sms' => 'колта-саамская',
 				'sn' => 'шона',
 				'snk' => 'санінке',
 				'so' => 'самалі',
 				'sq' => 'албанская',
 				'sr' => 'сербская',
 				'srn' => 'сранан-тонга',
 				'ss' => 'суаці',
 				'ssy' => 'саха',
 				'st' => 'сесута',
 				'su' => 'сунда',
 				'suk' => 'сукума',
 				'sux' => 'шумерская',
 				'sv' => 'шведская',
 				'sw' => 'суахілі',
 				'sw_CD' => 'кангалезская суахілі',
 				'swb' => 'каморская',
 				'syr' => 'сірыйская',
 				'ta' => 'тамільская',
 				'te' => 'тэлугу',
 				'tem' => 'тэмнэ',
 				'teo' => 'тэсо',
 				'tet' => 'тэтум',
 				'tg' => 'таджыкская',
 				'th' => 'тайская',
 				'ti' => 'тыгрынья',
 				'tig' => 'тыгрэ',
 				'tk' => 'туркменская',
 				'tlh' => 'клінган',
 				'tn' => 'тсвана',
 				'to' => 'танганская',
 				'tpi' => 'ток-пісін',
 				'tr' => 'турэцкая',
 				'trv' => 'тарока',
 				'ts' => 'тсонга',
 				'tt' => 'татарская',
 				'tum' => 'тумбука',
 				'tvl' => 'тувалу',
 				'twq' => 'тасаўак',
 				'ty' => 'таіці',
 				'tyv' => 'тувінская',
 				'tzm' => 'цэнтральнаатлаская тамазіхт',
 				'udm' => 'удмурцкая',
 				'ug' => 'уйгурская',
 				'uk' => 'украінская',
 				'umb' => 'умбунду',
 				'und' => 'невядомая мова',
 				'ur' => 'урду',
 				'uz' => 'узбекская',
 				'vai' => 'ваі',
 				've' => 'венда',
 				'vi' => 'в’етнамская',
 				'vo' => 'валапюк',
 				'vun' => 'вунджо',
 				'wa' => 'валонская',
 				'wae' => 'вальшская',
 				'wal' => 'волайта',
 				'war' => 'варай',
 				'wbp' => 'варлпіры',
 				'wo' => 'валоф',
 				'xal' => 'калмыцкая',
 				'xh' => 'коса',
 				'xog' => 'сога',
 				'yav' => 'янгбэн',
 				'ybb' => 'йемба',
 				'yi' => 'ідыш',
 				'yo' => 'ёруба',
 				'yue' => 'кантонскі дыялект кітайскай',
 				'zap' => 'сапатэк',
 				'zgh' => 'стандартная мараканская тамазіхт',
 				'zh' => 'кітайская',
 				'zh_Hans' => 'кітайская (спрошчаныя іерогліфы)',
 				'zh_Hant' => 'кітайская (традыцыйныя іерогліфы)',
 				'zu' => 'зулу',
 				'zun' => 'зуні',
 				'zxx' => 'няма моўнага матэрыялу',
 				'zza' => 'зазакі',

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
			'Arab' => 'арабскае',
 			'Armn' => 'армянскае',
 			'Beng' => 'бенгальскае',
 			'Bopo' => 'бапамофа',
 			'Brai' => 'шрыфт Брайля',
 			'Cyrl' => 'кірыліца',
 			'Deva' => 'дэванагары',
 			'Ethi' => 'эфіопскае',
 			'Geor' => 'грузінскае',
 			'Grek' => 'грэчаскае',
 			'Gujr' => 'гуджараці',
 			'Guru' => 'гурмукхі',
 			'Hanb' => 'хан з бапамофа',
 			'Hang' => 'хангыль',
 			'Hani' => 'хан',
 			'Hans' => 'спрошчанае кітайскае',
 			'Hans@alt=stand-alone' => 'спрошчанае хан',
 			'Hant' => 'традыцыйнае кітайскае',
 			'Hant@alt=stand-alone' => 'традыцыйнае хан',
 			'Hebr' => 'яўрэйскае',
 			'Hira' => 'хірагана',
 			'Hrkt' => 'японскія складовыя пісьмы',
 			'Jamo' => 'чамо',
 			'Jpan' => 'японскае',
 			'Kana' => 'катакана',
 			'Khmr' => 'кхмерскае',
 			'Knda' => 'канада',
 			'Kore' => 'карэйскае',
 			'Laoo' => 'лаоскае',
 			'Latn' => 'лацініца',
 			'Mlym' => 'малаялам',
 			'Mong' => 'старамангольскае',
 			'Mymr' => 'м’янмарскае',
 			'Orya' => 'орыя',
 			'Sinh' => 'сінгальскае',
 			'Taml' => 'тамільскае',
 			'Telu' => 'тэлугу',
 			'Thaa' => 'тана',
 			'Thai' => 'тайскае',
 			'Tibt' => 'тыбецкае',
 			'Zmth' => 'матэматычныя знакі',
 			'Zsye' => 'эмодзі',
 			'Zsym' => 'сімвалы',
 			'Zxxx' => 'беспісьменная',
 			'Zyyy' => 'звычайнае',
 			'Zzzz' => 'невядомае пісьмо',

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
			'001' => 'Свет',
 			'002' => 'Афрыка',
 			'003' => 'Паўночная Амерыка',
 			'005' => 'Паўднёвая Амерыка',
 			'009' => 'Акіянія',
 			'011' => 'Заходняя Афрыка',
 			'013' => 'Цэнтральная Амерыка',
 			'014' => 'Усходняя Афрыка',
 			'015' => 'Паўночная Афрыка',
 			'017' => 'Цэнтральная Афрыка',
 			'018' => 'Паўднёвая Афрыка',
 			'019' => 'Паўночная і Паўднёвая Амерыкі',
 			'021' => 'Паўночнаамерыканскі рэгіён',
 			'029' => 'Карыбскія астравы',
 			'030' => 'Усходняя Азія',
 			'034' => 'Паўднёвая Азія',
 			'035' => 'Паўднёва-Усходняя Азія',
 			'039' => 'Паўднёвая Еўропа',
 			'053' => 'Аўстралазія',
 			'054' => 'Меланезія',
 			'057' => 'Мікранезійскі рэгіён',
 			'061' => 'Палінезія',
 			'142' => 'Азія',
 			'143' => 'Цэнтральная Азія',
 			'145' => 'Заходняя Азія',
 			'150' => 'Еўропа',
 			'151' => 'Усходняя Еўропа',
 			'154' => 'Паўночная Еўропа',
 			'155' => 'Заходняя Еўропа',
 			'202' => 'Трапічная Афрыка',
 			'419' => 'Лацінская Амерыка',
 			'AC' => 'Востраў Узнясення',
 			'AD' => 'Андора',
 			'AE' => 'Аб’яднаныя Арабскія Эміраты',
 			'AF' => 'Афганістан',
 			'AG' => 'Антыгуа і Барбуда',
 			'AI' => 'Ангілья',
 			'AL' => 'Албанія',
 			'AM' => 'Арменія',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктыка',
 			'AR' => 'Аргенціна',
 			'AS' => 'Амерыканскае Самоа',
 			'AT' => 'Аўстрыя',
 			'AU' => 'Аўстралія',
 			'AW' => 'Аруба',
 			'AX' => 'Аландскія астравы',
 			'AZ' => 'Азербайджан',
 			'BA' => 'Боснія і Герцагавіна',
 			'BB' => 'Барбадас',
 			'BD' => 'Бангладэш',
 			'BE' => 'Бельгія',
 			'BF' => 'Буркіна-Фасо',
 			'BG' => 'Балгарыя',
 			'BH' => 'Бахрэйн',
 			'BI' => 'Бурундзі',
 			'BJ' => 'Бенін',
 			'BL' => 'Сен-Бартэльмі',
 			'BM' => 'Бермудскія астравы',
 			'BN' => 'Бруней',
 			'BO' => 'Балівія',
 			'BQ' => 'Карыбскія Нідэрланды',
 			'BR' => 'Бразілія',
 			'BS' => 'Багамскія астравы',
 			'BT' => 'Бутан',
 			'BV' => 'Востраў Бувэ',
 			'BW' => 'Батсвана',
 			'BY' => 'Беларусь',
 			'BZ' => 'Беліз',
 			'CA' => 'Канада',
 			'CC' => 'Какосавыя (Кілінг) астравы',
 			'CD' => 'Конга (Кіншаса)',
 			'CD@alt=variant' => 'Конга (ДРК)',
 			'CF' => 'Цэнтральна-Афрыканская Рэспубліка',
 			'CG' => 'Конга - Бразавіль',
 			'CG@alt=variant' => 'Рэспубліка Конга',
 			'CH' => 'Швейцарыя',
 			'CI' => 'Кот-д’Івуар',
 			'CI@alt=variant' => 'Бераг Слановай Косці',
 			'CK' => 'Астравы Кука',
 			'CL' => 'Чылі',
 			'CM' => 'Камерун',
 			'CN' => 'Кітай',
 			'CO' => 'Калумбія',
 			'CP' => 'Востраў Кліпертон',
 			'CR' => 'Коста-Рыка',
 			'CU' => 'Куба',
 			'CV' => 'Каба-Вердэ',
 			'CW' => 'Кюрасаа',
 			'CX' => 'Востраў Каляд',
 			'CY' => 'Кіпр',
 			'CZ' => 'Чэхія',
 			'CZ@alt=variant' => 'Чэшская Рэспубліка',
 			'DE' => 'Германія',
 			'DG' => 'Востраў Дыега-Гарсія',
 			'DJ' => 'Джыбуці',
 			'DK' => 'Данія',
 			'DM' => 'Дамініка',
 			'DO' => 'Дамініканская Рэспубліка',
 			'DZ' => 'Алжыр',
 			'EA' => 'Сеўта і Мелілья',
 			'EC' => 'Эквадор',
 			'EE' => 'Эстонія',
 			'EG' => 'Егіпет',
 			'EH' => 'Заходняя Сахара',
 			'ER' => 'Эрытрэя',
 			'ES' => 'Іспанія',
 			'ET' => 'Эфіопія',
 			'EU' => 'Еўрапейскі саюз',
 			'EZ' => 'Еўразона',
 			'FI' => 'Фінляндыя',
 			'FJ' => 'Фіджы',
 			'FK' => 'Фалклендскія астравы',
 			'FK@alt=variant' => 'Фалклендскія (Мальвінскія) астравы',
 			'FM' => 'Мікранезія',
 			'FO' => 'Фарэрскія астравы',
 			'FR' => 'Францыя',
 			'GA' => 'Габон',
 			'GB' => 'Вялікабрытанія',
 			'GB@alt=short' => 'Вялікабрытанія',
 			'GD' => 'Грэнада',
 			'GE' => 'Грузія',
 			'GF' => 'Французская Гвіяна',
 			'GG' => 'Гернсі',
 			'GH' => 'Гана',
 			'GI' => 'Гібралтар',
 			'GL' => 'Грэнландыя',
 			'GM' => 'Гамбія',
 			'GN' => 'Гвінея',
 			'GP' => 'Гвадэлупа',
 			'GQ' => 'Экватарыяльная Гвінея',
 			'GR' => 'Грэцыя',
 			'GS' => 'Паўднёвая Джорджыя і Паўднёвыя Сандвічавы астравы',
 			'GT' => 'Гватэмала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвінея-Бісау',
 			'GY' => 'Гаяна',
 			'HK' => 'Ганконг, САР (Кітай)',
 			'HK@alt=short' => 'Ганконг',
 			'HM' => 'Астравы Херд і Макдональд',
 			'HN' => 'Гандурас',
 			'HR' => 'Харватыя',
 			'HT' => 'Гаіці',
 			'HU' => 'Венгрыя',
 			'IC' => 'Канарскія астравы',
 			'ID' => 'Інданезія',
 			'IE' => 'Ірландыя',
 			'IL' => 'Ізраіль',
 			'IM' => 'Востраў Мэн',
 			'IN' => 'Індыя',
 			'IO' => 'Брытанская тэрыторыя ў Індыйскім акіяне',
 			'IQ' => 'Ірак',
 			'IR' => 'Іран',
 			'IS' => 'Ісландыя',
 			'IT' => 'Італія',
 			'JE' => 'Джэрсі',
 			'JM' => 'Ямайка',
 			'JO' => 'Іарданія',
 			'JP' => 'Японія',
 			'KE' => 'Кенія',
 			'KG' => 'Кыргызстан',
 			'KH' => 'Камбоджа',
 			'KI' => 'Кірыбаці',
 			'KM' => 'Каморскія астравы',
 			'KN' => 'Сент-Кітс і Невіс',
 			'KP' => 'Паўночная Карэя',
 			'KR' => 'Паўднёвая Карэя',
 			'KW' => 'Кувейт',
 			'KY' => 'Кайманавы астравы',
 			'KZ' => 'Казахстан',
 			'LA' => 'Лаос',
 			'LB' => 'Ліван',
 			'LC' => 'Сент-Люсія',
 			'LI' => 'Ліхтэнштэйн',
 			'LK' => 'Шры-Ланка',
 			'LR' => 'Ліберыя',
 			'LS' => 'Лесота',
 			'LT' => 'Літва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латвія',
 			'LY' => 'Лівія',
 			'MA' => 'Марока',
 			'MC' => 'Манака',
 			'MD' => 'Малдова',
 			'ME' => 'Чарнагорыя',
 			'MF' => 'Сен-Мартэн',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Маршалавы астравы',
 			'MK' => 'Македонія',
 			'MK@alt=variant' => 'Македонія (БЮРМ)',
 			'ML' => 'Малі',
 			'MM' => 'М’янма (Бірма)',
 			'MN' => 'Манголія',
 			'MO' => 'Макаа, САР (Кітай)',
 			'MO@alt=short' => 'Макаа',
 			'MP' => 'Паўночныя Марыянскія астравы',
 			'MQ' => 'Марцініка',
 			'MR' => 'Маўрытанія',
 			'MS' => 'Мантсерат',
 			'MT' => 'Мальта',
 			'MU' => 'Маўрыкій',
 			'MV' => 'Мальдывы',
 			'MW' => 'Малаві',
 			'MX' => 'Мексіка',
 			'MY' => 'Малайзія',
 			'MZ' => 'Мазамбік',
 			'NA' => 'Намібія',
 			'NC' => 'Новая Каледонія',
 			'NE' => 'Нігер',
 			'NF' => 'Востраў Норфалк',
 			'NG' => 'Нігерыя',
 			'NI' => 'Нікарагуа',
 			'NL' => 'Нідэрланды',
 			'NO' => 'Нарвегія',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ніуэ',
 			'NZ' => 'Новая Зеландыя',
 			'OM' => 'Аман',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Французская Палінезія',
 			'PG' => 'Папуа-Новая Гвінея',
 			'PH' => 'Філіпіны',
 			'PK' => 'Пакістан',
 			'PL' => 'Польшча',
 			'PM' => 'Сен-П’ер і Мікелон',
 			'PN' => 'Астравы Піткэрн',
 			'PR' => 'Пуэрта-Рыка',
 			'PS' => 'Палесцінскія Тэрыторыі',
 			'PS@alt=short' => 'Палесціна',
 			'PT' => 'Партугалія',
 			'PW' => 'Палау',
 			'PY' => 'Парагвай',
 			'QA' => 'Катар',
 			'QO' => 'Знешняя Акіянія',
 			'RE' => 'Рэюньён',
 			'RO' => 'Румынія',
 			'RS' => 'Сербія',
 			'RU' => 'Расія',
 			'RW' => 'Руанда',
 			'SA' => 'Саудаўская Аравія',
 			'SB' => 'Саламонавы астравы',
 			'SC' => 'Сейшэльскія астравы',
 			'SD' => 'Судан',
 			'SE' => 'Швецыя',
 			'SG' => 'Сінгапур',
 			'SH' => 'Востраў Святой Алены',
 			'SI' => 'Славенія',
 			'SJ' => 'Шпіцберген і Ян-Маен',
 			'SK' => 'Славакія',
 			'SL' => 'Сьера-Леонэ',
 			'SM' => 'Сан-Марына',
 			'SN' => 'Сенегал',
 			'SO' => 'Самалі',
 			'SR' => 'Сурынам',
 			'SS' => 'Паўднёвы Судан',
 			'ST' => 'Сан-Тамэ і Прынсіпі',
 			'SV' => 'Сальвадор',
 			'SX' => 'Сінт-Мартэн',
 			'SY' => 'Сірыя',
 			'SZ' => 'Свазіленд',
 			'TA' => 'Трыстан-да-Кунья',
 			'TC' => 'Астравы Цёркс і Кайкас',
 			'TD' => 'Чад',
 			'TF' => 'Французскія паўднёвыя тэрыторыі',
 			'TG' => 'Тога',
 			'TH' => 'Тайланд',
 			'TJ' => 'Таджыкістан',
 			'TK' => 'Такелау',
 			'TL' => 'Тымор-Лешці',
 			'TL@alt=variant' => 'Усходні Тымор',
 			'TM' => 'Туркменістан',
 			'TN' => 'Туніс',
 			'TO' => 'Тонга',
 			'TR' => 'Турцыя',
 			'TT' => 'Трынідад і Табага',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайвань',
 			'TZ' => 'Танзанія',
 			'UA' => 'Украіна',
 			'UG' => 'Уганда',
 			'UM' => 'Малыя Аддаленыя астравы ЗША',
 			'UN' => 'ААН',
 			'US' => 'Злучаныя Штаты Амерыкі',
 			'US@alt=short' => 'ЗША',
 			'UY' => 'Уругвай',
 			'UZ' => 'Узбекістан',
 			'VA' => 'Ватыкан',
 			'VC' => 'Сент-Вінсент і Грэнадзіны',
 			'VE' => 'Венесуэла',
 			'VG' => 'Брытанскія Віргінскія астравы',
 			'VI' => 'Амерыканскія Віргінскія астравы',
 			'VN' => 'В’етнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уоліс і Футуна',
 			'WS' => 'Самоа',
 			'XK' => 'Косава',
 			'YE' => 'Емен',
 			'YT' => 'Маёта',
 			'ZA' => 'Паўднёва-Афрыканская Рэспубліка',
 			'ZM' => 'Замбія',
 			'ZW' => 'Зімбабвэ',
 			'ZZ' => 'Невядомы рэгіён',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'каляндар',
 			'cf' => 'фармат валюты',
 			'collation' => 'парадак сартавання',
 			'currency' => 'валюта',
 			'hc' => 'гадзінны цыкл (12 або 24)',
 			'lb' => 'правілы разрыву радка',
 			'ms' => 'сістэма мер',
 			'numbers' => 'лічбы',

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
 				'buddhist' => q{будыйскі каляндар},
 				'chinese' => q{кітайскі каляндар},
 				'dangi' => q{каляндар дангі},
 				'ethiopic' => q{эфіопскі каляндар},
 				'gregorian' => q{грыгарыянскі каляндар},
 				'hebrew' => q{яўрэйскі каляндар},
 				'islamic' => q{мусульманскі каляндар},
 				'islamic-civil' => q{мусульманскі свецкі каляндар},
 				'iso8601' => q{каляндар ISO-8601},
 				'japanese' => q{японскі каляндар},
 				'persian' => q{персідскі каляндар},
 				'roc' => q{каляндар Міньго},
 			},
 			'cf' => {
 				'account' => q{бухгалтарскі фармат валюты},
 				'standard' => q{стандартны фармат валюты},
 			},
 			'collation' => {
 				'ducet' => q{стандартны парадак сартавання Унікод},
 				'search' => q{універсальны пошук},
 				'standard' => q{стандартны парадак сартавання},
 			},
 			'hc' => {
 				'h11' => q{12-гадзінны фармат часу (0-11)},
 				'h12' => q{12-гадзінны фармат часу (1-12)},
 				'h23' => q{24-гадзінны фармат часу (0-23)},
 				'h24' => q{24-гадзінны фармат часу (1-24)},
 			},
 			'lb' => {
 				'loose' => q{нястрогія правілы разрыву радка},
 				'normal' => q{звычайныя правілы разрыву радка},
 				'strict' => q{строгія правілы разрыву радка},
 			},
 			'ms' => {
 				'metric' => q{метрычная сістэма мер},
 				'uksystem' => q{брытанская сістэма мер},
 				'ussystem' => q{амерыканская сістэма мер},
 			},
 			'numbers' => {
 				'arab' => q{арабска-індыйскія лічбы},
 				'arabext' => q{пашыраная сістэма арабска-індыйскіх лічбаў},
 				'armn' => q{армянскія лічбы},
 				'armnlow' => q{армянскія лічбы ў ніжнім рэгістры},
 				'beng' => q{бенгальскія лічбы},
 				'deva' => q{лічбы дэванагары},
 				'ethi' => q{эфіопскія лічбы},
 				'fullwide' => q{поўнашырынныя лічбы},
 				'geor' => q{грузінскія лічбы},
 				'grek' => q{грэчаскія лічбы},
 				'greklow' => q{грэчаскія лічбы ў ніжнім рэгістры},
 				'gujr' => q{лічбы гуджараці},
 				'guru' => q{лічбы гурмукхі},
 				'hanidec' => q{кітайскія дзесятковыя лічбы},
 				'hans' => q{кітайскія спрошчаныя лічбы},
 				'hansfin' => q{кітайскія спрошчаныя лічбы (фінансы)},
 				'hant' => q{кітайскія традыцыйныя лічбы},
 				'hantfin' => q{кітайскія традыцыйныя лічбы (фінансы)},
 				'hebr' => q{яўрэйскія лічбы},
 				'jpan' => q{японскія лічбы},
 				'jpanfin' => q{японскія лічбы (фінансы)},
 				'khmr' => q{кхмерскія лічбы},
 				'knda' => q{лічбы канада},
 				'laoo' => q{лаоскія лічбы},
 				'latn' => q{сучасныя арабскія лічбы},
 				'mlym' => q{лічбы малаялам},
 				'mymr' => q{бірманскія лічбы},
 				'orya' => q{лічбы орыя},
 				'roman' => q{рымскія лічбы},
 				'romanlow' => q{рымскія лічбы ў ніжнім рэгістры},
 				'taml' => q{тамільскія традыцыйныя лічбы},
 				'tamldec' => q{тамільскія лічбы},
 				'telu' => q{лічбы тэлугу},
 				'thai' => q{тайскія лічбы},
 				'tibt' => q{тыбецкія лічбы},
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
			'metric' => q{метрычная},
 			'UK' => q{брытанская},
 			'US' => q{амерыканская},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Мова: {0}',
 			'script' => 'Пісьмо: {0}',
 			'region' => 'Рэгіён: {0}',

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
			auxiliary => qr{[{а́} {е́} {ё́} {і́} {о́} {у́} {ы́} {э́} {ю́} {я́}]},
			index => ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'І', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Ы', 'Э', 'Ю', 'Я'],
			main => qr{[а б в г д {дж} {дз} е ё ж з і й к л м н о п р с т у ў ф х ц ч ш ы ь э ю я]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- , ; \: ! ? . « » ( ) \[ \] \{ \}]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'І', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Ы', 'Э', 'Ю', 'Я'], };
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
			'word-final' => '{0} …',
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
	default		=> qq{„},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'hh:mm',
				hms => 'hh:mm:ss',
				ms => 'mm:ss',
			} }
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'' => {
						'name' => q(кірунак свету),
					},
					'acre' => {
						'few' => q({0} акры),
						'many' => q({0} акраў),
						'name' => q(акры),
						'one' => q({0} акр),
						'other' => q({0} акра),
					},
					'acre-foot' => {
						'few' => q({0} акр-футы),
						'many' => q({0} акр-футаў),
						'name' => q(акр-футы),
						'one' => q({0} акр-фут),
						'other' => q({0} акр-фута),
					},
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(амперы),
						'one' => q({0} A),
						'other' => q({0} ампера),
					},
					'arc-minute' => {
						'few' => q({0} вуглавыя мінуты),
						'many' => q({0} вуглавых мінут),
						'name' => q(вуглавыя мінуты),
						'one' => q({0} вуглавая мінута),
						'other' => q({0} вуглавой мінуты),
					},
					'arc-second' => {
						'few' => q({0} вуглавыя секунды),
						'many' => q({0} вуглавых секунд),
						'name' => q(вуглавыя секунды),
						'one' => q({0} вуглавая секунда),
						'other' => q({0} вуглавой секунды),
					},
					'astronomical-unit' => {
						'few' => q({0} астранамічныя адзінкі),
						'many' => q({0} астранамічных адзінак),
						'name' => q(астранамічныя адзінкі),
						'one' => q({0} астранамічная адзінка),
						'other' => q({0} астранамічнай адзінкі),
					},
					'atmosphere' => {
						'few' => q({0} атм),
						'many' => q({0} атм),
						'name' => q(атмасферы),
						'one' => q({0} атм),
						'other' => q({0} атм),
					},
					'bit' => {
						'few' => q({0} біты),
						'many' => q({0} біт),
						'name' => q(біты),
						'one' => q({0} біт),
						'other' => q({0} біта),
					},
					'byte' => {
						'few' => q({0} байты),
						'many' => q({0} байт),
						'name' => q(байты),
						'one' => q({0} байт),
						'other' => q({0} байта),
					},
					'calorie' => {
						'few' => q({0} кал),
						'many' => q({0} кал),
						'name' => q(калорыі),
						'one' => q({0} кал),
						'other' => q({0} калорыі),
					},
					'carat' => {
						'few' => q({0} караты),
						'many' => q({0} каратаў),
						'name' => q(караты),
						'one' => q({0} карат),
						'other' => q({0} карата),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(градусы Цэльсія),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} сантылітры),
						'many' => q({0} сантылітраў),
						'name' => q(сантылітр),
						'one' => q({0} сантылітр),
						'other' => q({0} сантылітра),
					},
					'centimeter' => {
						'few' => q({0} сантыметры),
						'many' => q({0} сантыметраў),
						'name' => q(сантыметры),
						'one' => q({0} сантыметр),
						'other' => q({0} сантыметра),
						'per' => q({0} на сантыметр),
					},
					'century' => {
						'few' => q({0} стагоддзі),
						'many' => q({0} стагоддзяў),
						'name' => q(стагоддзі),
						'one' => q({0} стагоддзе),
						'other' => q({0} стагоддзя),
					},
					'coordinate' => {
						'east' => q({0} У),
						'north' => q({0} Пн),
						'south' => q({0} Пд),
						'west' => q({0} З),
					},
					'cubic-centimeter' => {
						'few' => q({0} кубічныя сантыметры),
						'many' => q({0} кубічных сантыметраў),
						'name' => q(кубічныя сантыметры),
						'one' => q({0} кубічны сантыметр),
						'other' => q({0} кубічнага сантыметра),
						'per' => q({0} на кубічны сантыметр),
					},
					'cubic-foot' => {
						'few' => q({0} кубічныя футы),
						'many' => q({0} кубічных футаў),
						'name' => q(кубічныя футы),
						'one' => q({0} кубічны фут),
						'other' => q({0} кубічнага фута),
					},
					'cubic-inch' => {
						'few' => q({0} кубічныя цалі),
						'many' => q({0} кубічных цаляў),
						'name' => q(кубічныя цалі),
						'one' => q({0} кубічная цаля),
						'other' => q({0} кубічнай цалі),
					},
					'cubic-kilometer' => {
						'few' => q({0} кубічныя кіламетры),
						'many' => q({0} кубічных кіламетраў),
						'name' => q(кубічныя кіламетры),
						'one' => q({0} кубічны кіламетр),
						'other' => q({0} кубічнага кіламетра),
					},
					'cubic-meter' => {
						'few' => q({0} кубічныя метры),
						'many' => q({0} кубічных метраў),
						'name' => q(кубічныя метры),
						'one' => q({0} кубічны метр),
						'other' => q({0} кубічнага метра),
						'per' => q({0} на кубічны метр),
					},
					'cubic-mile' => {
						'few' => q({0} кубічныя мілі),
						'many' => q({0} кубічных міль),
						'name' => q(кубічныя мілі),
						'one' => q({0} кубічная міля),
						'other' => q({0} кубічнай мілі),
					},
					'cubic-yard' => {
						'few' => q({0} кубічныя ярды),
						'many' => q({0} кубічных ярдаў),
						'name' => q(кубічныя ярды),
						'one' => q({0} кубічны ярд),
						'other' => q({0} кубічнага ярда),
					},
					'cup' => {
						'few' => q({0} кубкі),
						'many' => q({0} кубкаў),
						'name' => q(кубкі),
						'one' => q({0} кубак),
						'other' => q({0} кубка),
					},
					'cup-metric' => {
						'few' => q({0} метрычныя кубкі),
						'many' => q({0} метрычных кубкаў),
						'name' => q(метрычныя кубкі),
						'one' => q({0} метрычны кубак),
						'other' => q({0} метрычнага кубка),
					},
					'day' => {
						'few' => q({0} сутак),
						'many' => q({0} сутак),
						'name' => q(суткі),
						'one' => q({0} суткі),
						'other' => q({0} сутак),
						'per' => q({0} у суткі),
					},
					'deciliter' => {
						'few' => q({0} дэцылітры),
						'many' => q({0} дэцылітраў),
						'name' => q(дэцылітры),
						'one' => q({0} дэцылітр),
						'other' => q({0} дэцылітра),
					},
					'decimeter' => {
						'few' => q({0} дэцыметры),
						'many' => q({0} дэцыметраў),
						'name' => q(дэцыметры),
						'one' => q({0} дэцыметр),
						'other' => q({0} дэцыметра),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(градусы),
						'one' => q({0}°),
						'other' => q({0} градуса),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'name' => q(градусы Фарэнгейта),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'few' => q({0} вадкія унцыі),
						'many' => q({0} вадкіх унцый),
						'name' => q(вадкія унцыі),
						'one' => q({0} вадкая унцыя),
						'other' => q({0} вадкай унцыі),
					},
					'foodcalorie' => {
						'few' => q({0} кал),
						'many' => q({0} кал),
						'name' => q(калорыі),
						'one' => q({0} кал),
						'other' => q({0} кал),
					},
					'foot' => {
						'few' => q({0} футы),
						'many' => q({0} футаў),
						'name' => q(футы),
						'one' => q({0} фут),
						'other' => q({0} фута),
						'per' => q({0} на фут),
					},
					'g-force' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(перагрузка),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'gallon' => {
						'few' => q({0} галоны),
						'many' => q({0} галонаў),
						'name' => q(галоны),
						'one' => q({0} галон),
						'other' => q({0} галона),
						'per' => q({0} на галон),
					},
					'gallon-imperial' => {
						'few' => q({0} імп. галоны),
						'many' => q({0} імп. галонаў),
						'name' => q(імп. галоны),
						'one' => q({0} імп. галон),
						'other' => q({0} імп. галона),
						'per' => q({0}/імп. галон),
					},
					'generic' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Гбіт),
						'many' => q({0} Гбіт),
						'name' => q(гігабіты),
						'one' => q({0} Гбіт),
						'other' => q({0} Гбіт),
					},
					'gigabyte' => {
						'few' => q({0} ГБ),
						'many' => q({0} ГБ),
						'name' => q(гігабайты),
						'one' => q({0} ГБ),
						'other' => q({0} ГБ),
					},
					'gigahertz' => {
						'few' => q({0} ГГц),
						'many' => q({0} ГГц),
						'name' => q(гігагерцы),
						'one' => q({0} ГГц),
						'other' => q({0} ГГц),
					},
					'gigawatt' => {
						'few' => q({0} ГВт),
						'many' => q({0} ГВт),
						'name' => q(гігаваты),
						'one' => q({0} ГВт),
						'other' => q({0} ГВт),
					},
					'gram' => {
						'few' => q({0} г),
						'many' => q({0} г),
						'name' => q(грамы),
						'one' => q({0} г),
						'other' => q({0} г),
						'per' => q({0}/г),
					},
					'hectare' => {
						'few' => q({0} гектары),
						'many' => q({0} гектараў),
						'name' => q(гектары),
						'one' => q({0} гектар),
						'other' => q({0} гектара),
					},
					'hectoliter' => {
						'few' => q({0} гекталітры),
						'many' => q({0} гекталітраў),
						'name' => q(гекталітры),
						'one' => q({0} гекталітр),
						'other' => q({0} гекталітра),
					},
					'hectopascal' => {
						'few' => q({0} гПа),
						'many' => q({0} гПа),
						'name' => q(гектапаскалі),
						'one' => q({0} гПа),
						'other' => q({0} гПа),
					},
					'hertz' => {
						'few' => q({0} Гц),
						'many' => q({0} Гц),
						'name' => q(герцы),
						'one' => q({0} Гц),
						'other' => q({0} Гц),
					},
					'horsepower' => {
						'few' => q({0} к. с.),
						'many' => q({0} к. с.),
						'name' => q(конская сіла),
						'one' => q({0} к. с.),
						'other' => q({0} к. с.),
					},
					'hour' => {
						'few' => q({0} гадзіны),
						'many' => q({0} гадзін),
						'name' => q(гадзіны),
						'one' => q({0} гадзіна),
						'other' => q({0} гадзіны),
						'per' => q({0} у гадзіну),
					},
					'inch' => {
						'few' => q({0} цалі),
						'many' => q({0} цаляў),
						'name' => q(цалі),
						'one' => q({0} цаля),
						'other' => q({0} цалі),
						'per' => q({0} на цалю),
					},
					'inch-hg' => {
						'few' => q({0} цалі рт. сл.),
						'many' => q({0} цаляў рт. сл.),
						'name' => q(цалі ртутнага слупа),
						'one' => q({0} цаля рт. сл.),
						'other' => q({0} цалі рт. сл.),
					},
					'joule' => {
						'few' => q({0} Дж),
						'many' => q({0} Дж),
						'name' => q(джоўлі),
						'one' => q({0} Дж),
						'other' => q({0} Дж),
					},
					'karat' => {
						'few' => q({0} кар зол),
						'many' => q({0} кар зол),
						'name' => q(караты золата),
						'one' => q({0} кар зол),
						'other' => q({0} кар зол),
					},
					'kelvin' => {
						'few' => q({0} К),
						'many' => q({0} К),
						'name' => q(кельвіны),
						'one' => q({0} К),
						'other' => q({0} К),
					},
					'kilobit' => {
						'few' => q({0} кбіт),
						'many' => q({0} кбіт),
						'name' => q(кілабіты),
						'one' => q({0} кбіт),
						'other' => q({0} кбіт),
					},
					'kilobyte' => {
						'few' => q({0} КБ),
						'many' => q({0} КБ),
						'name' => q(кілабайты),
						'one' => q({0} КБ),
						'other' => q({0} КБ),
					},
					'kilocalorie' => {
						'few' => q({0} ккал),
						'many' => q({0} ккал),
						'name' => q(кілакалорыі),
						'one' => q({0} ккал),
						'other' => q({0} ккал),
					},
					'kilogram' => {
						'few' => q({0} кг),
						'many' => q({0} кг),
						'name' => q(кілаграмы),
						'one' => q({0} кг),
						'other' => q({0} кг),
						'per' => q({0}/кг),
					},
					'kilohertz' => {
						'few' => q({0} кГц),
						'many' => q({0} кГц),
						'name' => q(кілагерцы),
						'one' => q({0} кГц),
						'other' => q({0} кГц),
					},
					'kilojoule' => {
						'few' => q({0} кДж),
						'many' => q({0} кДж),
						'name' => q(кіладжоўлі),
						'one' => q({0} кДж),
						'other' => q({0} кДж),
					},
					'kilometer' => {
						'few' => q({0} кіламетры),
						'many' => q({0} кіламетраў),
						'name' => q(кіламетры),
						'one' => q({0} кіламетр),
						'other' => q({0} кіламетра),
						'per' => q({0} на кіламетр),
					},
					'kilometer-per-hour' => {
						'few' => q({0} км/гадз),
						'many' => q({0} км/гадз),
						'name' => q(кіламетры за гадзіну),
						'one' => q({0} км/гадз),
						'other' => q({0} км/гадз),
					},
					'kilowatt' => {
						'few' => q({0} кВт),
						'many' => q({0} кВт),
						'name' => q(кілаваты),
						'one' => q({0} кВт),
						'other' => q({0} кВт),
					},
					'kilowatt-hour' => {
						'few' => q({0} кВт·г),
						'many' => q({0} кВт·г),
						'name' => q(кілават-гадзіны),
						'one' => q({0} кВт·г),
						'other' => q({0} кВт·г),
					},
					'knot' => {
						'few' => q({0} вузлы),
						'many' => q({0} вузлоў),
						'name' => q(вузел),
						'one' => q({0} вузел),
						'other' => q({0} вузла),
					},
					'light-year' => {
						'few' => q({0} светлавыя гады),
						'many' => q({0} светлавых гадоў),
						'name' => q(светлавыя гады),
						'one' => q({0} светлавы год),
						'other' => q({0} светлавога года),
					},
					'liter' => {
						'few' => q({0} літры),
						'many' => q({0} літраў),
						'name' => q(літры),
						'one' => q({0} літр),
						'other' => q({0} літра),
						'per' => q({0} на літр),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} л/100 км),
						'many' => q({0} л/100 км),
						'name' => q(літры на 100 кіламетраў),
						'one' => q({0} л/100 км),
						'other' => q({0} л/100 км),
					},
					'liter-per-kilometer' => {
						'few' => q({0} л/км),
						'many' => q({0} л/км),
						'name' => q(літры на кіламетр),
						'one' => q({0} л/км),
						'other' => q({0} л/км),
					},
					'lux' => {
						'few' => q({0} люксы),
						'many' => q({0} люксаў),
						'name' => q(люкс),
						'one' => q({0} люкс),
						'other' => q({0} люкса),
					},
					'megabit' => {
						'few' => q({0} Мбіт),
						'many' => q({0} Мбіт),
						'name' => q(мегабіты),
						'one' => q({0} Мбіт),
						'other' => q({0} Мбіт),
					},
					'megabyte' => {
						'few' => q({0} МБ),
						'many' => q({0} МБ),
						'name' => q(мегабайты),
						'one' => q({0} МБ),
						'other' => q({0} МБ),
					},
					'megahertz' => {
						'few' => q({0} МГц),
						'many' => q({0} МГц),
						'name' => q(мегагерцы),
						'one' => q({0} МГц),
						'other' => q({0} МГц),
					},
					'megaliter' => {
						'few' => q({0} мегалітры),
						'many' => q({0} мегалітраў),
						'name' => q(мегалітры),
						'one' => q({0} мегалітр),
						'other' => q({0} мегалітра),
					},
					'megawatt' => {
						'few' => q({0} МВт),
						'many' => q({0} МВт),
						'name' => q(мегаваты),
						'one' => q({0} МВт),
						'other' => q({0} МВт),
					},
					'meter' => {
						'few' => q({0} метры),
						'many' => q({0} метраў),
						'name' => q(метры),
						'one' => q({0} метр),
						'other' => q({0} метра),
						'per' => q({0} на метр),
					},
					'meter-per-second' => {
						'few' => q({0} м/с),
						'many' => q({0} м/с),
						'name' => q(метры за секунду),
						'one' => q({0} м/с),
						'other' => q({0} м/с),
					},
					'meter-per-second-squared' => {
						'few' => q({0} м/с²),
						'many' => q({0} м/с²),
						'name' => q(м/с²),
						'one' => q({0} м/с²),
						'other' => q({0} м/с²),
					},
					'metric-ton' => {
						'few' => q({0} метрычныя тоны),
						'many' => q({0} метрычных тон),
						'name' => q(метрычныя тоны),
						'one' => q({0} метрычная тона),
						'other' => q({0} метрычнай тоны),
					},
					'microgram' => {
						'few' => q({0} мкг),
						'many' => q({0} мкг),
						'name' => q(мікраграмы),
						'one' => q({0} мкг),
						'other' => q({0} мкг),
					},
					'micrometer' => {
						'few' => q({0} мікраметры),
						'many' => q({0} мікраметраў),
						'name' => q(мікраметры),
						'one' => q({0} мікраметр),
						'other' => q({0} мікраметра),
					},
					'microsecond' => {
						'few' => q({0} мікрасекунды),
						'many' => q({0} мікрасекунд),
						'name' => q(мікрасекунды),
						'one' => q({0} мікрасекунда),
						'other' => q({0} мікрасекунды),
					},
					'mile' => {
						'few' => q({0} мілі),
						'many' => q({0} міль),
						'name' => q(мілі),
						'one' => q({0} міля),
						'other' => q({0} мілі),
					},
					'mile-per-gallon' => {
						'few' => q({0} мілі/гал.),
						'many' => q({0} міль/гал.),
						'name' => q(мілі на галон),
						'one' => q({0} міля/гал.),
						'other' => q({0} мілі/гал.),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} мілі на імп. галон),
						'many' => q({0} міль/імп. галон),
						'name' => q(міль на імп. галон),
						'one' => q({0} міля на імп. галон),
						'other' => q({0} мілі на імп. галон),
					},
					'mile-per-hour' => {
						'few' => q({0} мілі/гадз),
						'many' => q({0} міль/гадз),
						'name' => q(мілі за гадзіну),
						'one' => q({0} міля/гадз),
						'other' => q({0} мілі/гадз),
					},
					'mile-scandinavian' => {
						'few' => q({0} скандынаўскія мілі),
						'many' => q({0} скандынаўскіх міль),
						'name' => q(скандынаўскія мілі),
						'one' => q({0} скандынаўская міля),
						'other' => q({0} скандынаўскай мілі),
					},
					'milliampere' => {
						'few' => q({0} мА),
						'many' => q({0} мА),
						'name' => q(міліамперы),
						'one' => q({0} мА),
						'other' => q({0} мА),
					},
					'millibar' => {
						'few' => q({0} мбар),
						'many' => q({0} мбар),
						'name' => q(мілібары),
						'one' => q({0} мбар),
						'other' => q({0} мбар),
					},
					'milligram' => {
						'few' => q({0} мг),
						'many' => q({0} мг),
						'name' => q(міліграмы),
						'one' => q({0} мг),
						'other' => q({0} мг),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} мг на дл),
						'many' => q({0} мг на дл),
						'name' => q(міліграм на дэцылітр),
						'one' => q({0} мг на дл),
						'other' => q({0} мг на дл),
					},
					'milliliter' => {
						'few' => q({0} мілілітры),
						'many' => q({0} мілілітраў),
						'name' => q(мілілітры),
						'one' => q({0} мілілітр),
						'other' => q({0} мілілітра),
					},
					'millimeter' => {
						'few' => q({0} міліметры),
						'many' => q({0} міліметраў),
						'name' => q(міліметры),
						'one' => q({0} міліметр),
						'other' => q({0} міліметра),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} мм рт. сл.),
						'many' => q({0} мм рт. сл.),
						'name' => q(міліметры ртутнага слупа),
						'one' => q({0} мм рт. сл.),
						'other' => q({0} мм рт. сл.),
					},
					'millimole-per-liter' => {
						'few' => q({0} ммоль/л),
						'many' => q({0} ммоль/л),
						'name' => q(мілімоляў на літр),
						'one' => q({0} ммоль/л),
						'other' => q({0} ммоль/л),
					},
					'millisecond' => {
						'few' => q({0} мілісекунды),
						'many' => q({0} мілісекунд),
						'name' => q(мілісекунды),
						'one' => q({0} мілісекунда),
						'other' => q({0} мілісекунды),
					},
					'milliwatt' => {
						'few' => q({0} мВт),
						'many' => q({0} мВт),
						'name' => q(міліваты),
						'one' => q({0} мВт),
						'other' => q({0} мВт),
					},
					'minute' => {
						'few' => q({0} хвіліны),
						'many' => q({0} хвілін),
						'name' => q(хвіліны),
						'one' => q({0} хвіліна),
						'other' => q({0} хвіліны),
						'per' => q({0} у хвіліну),
					},
					'month' => {
						'few' => q({0} месяца),
						'many' => q({0} месяцаў),
						'name' => q(месяцы),
						'one' => q({0} месяц),
						'other' => q({0} месяца),
						'per' => q({0} у месяц),
					},
					'nanometer' => {
						'few' => q({0} нанаметры),
						'many' => q({0} нанаметраў),
						'name' => q(нанаметры),
						'one' => q({0} нанаметр),
						'other' => q({0} нанаметра),
					},
					'nanosecond' => {
						'few' => q({0} нанасекунды),
						'many' => q({0} нанасекунд),
						'name' => q(нанасекунды),
						'one' => q({0} нанасекунда),
						'other' => q({0} нанасекунды),
					},
					'nautical-mile' => {
						'few' => q({0} марскія мілі),
						'many' => q({0} марскіх міль),
						'name' => q(марскія мілі),
						'one' => q({0} марская міля),
						'other' => q({0} марской мілі),
					},
					'ohm' => {
						'few' => q({0} Ом),
						'many' => q({0} Ом),
						'name' => q(омы),
						'one' => q({0} Ом),
						'other' => q({0} Ом),
					},
					'ounce' => {
						'few' => q({0} унцыі),
						'many' => q({0} унцый),
						'name' => q(унцыі),
						'one' => q({0} унцыя),
						'other' => q({0} унцыі),
						'per' => q({0} на унцыю),
					},
					'ounce-troy' => {
						'few' => q({0} тройскія унцыі),
						'many' => q({0} тройскіх унцый),
						'name' => q(тройскія унцыі),
						'one' => q({0} тройская унцыя),
						'other' => q({0} тройскай унцыі),
					},
					'parsec' => {
						'few' => q({0} парсекі),
						'many' => q({0} парсекаў),
						'name' => q(парсекі),
						'one' => q({0} парсек),
						'other' => q({0} парсека),
					},
					'part-per-million' => {
						'few' => q({0} часткі на мільён),
						'many' => q({0} частак на мільён),
						'name' => q(частак на мільён),
						'one' => q({0} частка на мільён),
						'other' => q({0} часткі на мільён),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'name' => q(працэнтаў),
						'one' => q({0} працэнт),
						'other' => q({0}%),
					},
					'permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'name' => q(праміле),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'few' => q({0} ПБ),
						'many' => q({0} ПБ),
						'name' => q(петабайты),
						'one' => q({0} ПБ),
						'other' => q({0} ПБ),
					},
					'picometer' => {
						'few' => q({0} пікаметры),
						'many' => q({0} пікаметраў),
						'name' => q(пікаметры),
						'one' => q({0} пікаметр),
						'other' => q({0} пікаметра),
					},
					'pint' => {
						'few' => q({0} пінты),
						'many' => q({0} пінтаў),
						'name' => q(пінты),
						'one' => q({0} пінта),
						'other' => q({0} пінты),
					},
					'pint-metric' => {
						'few' => q({0} метрычныя пінты),
						'many' => q({0} метрычных пінтаў),
						'name' => q(метрычныя пінты),
						'one' => q({0} метрычная пінта),
						'other' => q({0} метрычнай пінты),
					},
					'point' => {
						'few' => q({0} пункты),
						'many' => q({0} пунктаў),
						'name' => q(пункты),
						'one' => q({0} пункт),
						'other' => q({0} пункту),
					},
					'pound' => {
						'few' => q({0} фунты),
						'many' => q({0} фунтаў),
						'name' => q(фунты),
						'one' => q({0} фунт),
						'other' => q({0} фунта),
						'per' => q({0}/фунт),
					},
					'pound-per-square-inch' => {
						'few' => q({0} фунты на кв. цалю),
						'many' => q({0} фунтаў на кв. цалю),
						'name' => q(фунты на квадратную цалю),
						'one' => q({0} фунт на кв. цалю),
						'other' => q({0} фунта на кв. цалю),
					},
					'quart' => {
						'few' => q({0} кварты),
						'many' => q({0} кварт),
						'name' => q(кварты),
						'one' => q({0} кварта),
						'other' => q({0} кварты),
					},
					'radian' => {
						'few' => q({0} рад),
						'many' => q({0} рад),
						'name' => q(радыяны),
						'one' => q({0} рад),
						'other' => q({0} рад),
					},
					'revolution' => {
						'few' => q({0} аб),
						'many' => q({0} аб),
						'name' => q(абарот),
						'one' => q({0} аб),
						'other' => q({0} аб),
					},
					'second' => {
						'few' => q({0} секунды),
						'many' => q({0} секунд),
						'name' => q(секунды),
						'one' => q({0} секунда),
						'other' => q({0} секунды),
						'per' => q({0} у секунду),
					},
					'square-centimeter' => {
						'few' => q({0} квадратныя сантыметры),
						'many' => q({0} квадратных сантыметраў),
						'name' => q(квадратныя сантыметры),
						'one' => q({0} квадратны сантыметр),
						'other' => q({0} квадратнага сантыметра),
						'per' => q({0} на квадратны сантыметр),
					},
					'square-foot' => {
						'few' => q({0} квадратныя футы),
						'many' => q({0} квадратных футаў),
						'name' => q(квадратны фут),
						'one' => q({0} квадратны фут),
						'other' => q({0} квадратнага фута),
					},
					'square-inch' => {
						'few' => q({0} квадратныя цалі),
						'many' => q({0} квадратных цаляў),
						'name' => q(квадратныя цалі),
						'one' => q({0} квадратная цаля),
						'other' => q({0} квадратнай цалі),
						'per' => q({0} на квадратную цалю),
					},
					'square-kilometer' => {
						'few' => q({0} квадратныя кіламетры),
						'many' => q({0} квадратных кіламетраў),
						'name' => q(квадратныя кіламетры),
						'one' => q({0} квадратны кіламетр),
						'other' => q({0} квадратнага кіламетра),
						'per' => q({0} на квадратны кіламетр),
					},
					'square-meter' => {
						'few' => q({0} квадратныя метры),
						'many' => q({0} квадратных метраў),
						'name' => q(квадратныя метры),
						'one' => q({0} квадратны метр),
						'other' => q({0} квадратнага метра),
						'per' => q({0} на квадратны метр),
					},
					'square-mile' => {
						'few' => q({0} квадратныя мілі),
						'many' => q({0} квадратных міль),
						'name' => q(квадратныя мілі),
						'one' => q({0} квадратная міля),
						'other' => q({0} квадратнай мілі),
						'per' => q({0} на квадратную мілю),
					},
					'square-yard' => {
						'few' => q({0} квадратныя ярды),
						'many' => q({0} квадратных ярдаў),
						'name' => q(квадратны ярд),
						'one' => q({0} квадратны ярд),
						'other' => q({0} квадратнага ярда),
					},
					'tablespoon' => {
						'few' => q({0} сталовыя лыжкі),
						'many' => q({0} сталовых лыжак),
						'name' => q(сталовыя лыжкі),
						'one' => q({0} сталовая лыжка),
						'other' => q({0} сталовай лыжкі),
					},
					'teaspoon' => {
						'few' => q({0} чайныя лыжкі),
						'many' => q({0} чайных лыжак),
						'name' => q(чайныя лыжкі),
						'one' => q({0} чайная лыжка),
						'other' => q({0} чайнай лыжкі),
					},
					'terabit' => {
						'few' => q({0} Тбіт),
						'many' => q({0} Тбіт),
						'name' => q(тэрабіты),
						'one' => q({0} Тбіт),
						'other' => q({0} Тбіт),
					},
					'terabyte' => {
						'few' => q({0} ТБ),
						'many' => q({0} ТБ),
						'name' => q(тэрабайты),
						'one' => q({0} ТБ),
						'other' => q({0} ТБ),
					},
					'ton' => {
						'few' => q({0} тоны),
						'many' => q({0} тон),
						'name' => q(тоны),
						'one' => q({0} тона),
						'other' => q({0} тоны),
					},
					'volt' => {
						'few' => q({0} В),
						'many' => q({0} В),
						'name' => q(вольты),
						'one' => q({0} В),
						'other' => q({0} В),
					},
					'watt' => {
						'few' => q({0} Вт),
						'many' => q({0} Вт),
						'name' => q(ваты),
						'one' => q({0} Вт),
						'other' => q({0} Вт),
					},
					'week' => {
						'few' => q({0} тыдні),
						'many' => q({0} тыдняў),
						'name' => q(тыдні),
						'one' => q({0} тыдзень),
						'other' => q({0} тыдня),
						'per' => q({0} у тыдзень),
					},
					'yard' => {
						'few' => q({0} ярды),
						'many' => q({0} ярдаў),
						'name' => q(ярды),
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					'year' => {
						'few' => q({0} гады),
						'many' => q({0} гадоў),
						'name' => q(гады),
						'one' => q({0} год),
						'other' => q({0} года),
						'per' => q({0} у год),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(кірунак),
					},
					'celsius' => {
						'few' => q({0}°C),
						'many' => q({0}°C),
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centimeter' => {
						'few' => q({0} см),
						'many' => q({0} см),
						'name' => q(см),
						'one' => q({0} см),
						'other' => q({0} см),
					},
					'coordinate' => {
						'east' => q({0} У),
						'north' => q({0} Пн),
						'south' => q({0} Пд),
						'west' => q({0} З),
					},
					'day' => {
						'few' => q({0} сут),
						'many' => q({0} сут),
						'name' => q(сут),
						'one' => q({0} сут),
						'other' => q({0} сут),
					},
					'gram' => {
						'few' => q({0} г),
						'many' => q({0} г),
						'name' => q(г),
						'one' => q({0} г),
						'other' => q({0} г),
					},
					'hour' => {
						'few' => q({0} гадз),
						'many' => q({0} гадз),
						'name' => q(гадз),
						'one' => q({0} гадз),
						'other' => q({0} гадз),
					},
					'kilogram' => {
						'few' => q({0} кг),
						'many' => q({0} кг),
						'name' => q(кг),
						'one' => q({0} кг),
						'other' => q({0} кг),
					},
					'kilometer' => {
						'few' => q({0} км),
						'many' => q({0} км),
						'name' => q(км),
						'one' => q({0} км),
						'other' => q({0} км),
					},
					'kilometer-per-hour' => {
						'few' => q({0} км/гадз),
						'many' => q({0} км/гадз),
						'name' => q(км/гадз),
						'one' => q({0} км/гадз),
						'other' => q({0} км/гадз),
					},
					'liter' => {
						'few' => q({0} л),
						'many' => q({0} л),
						'name' => q(л),
						'one' => q({0} л),
						'other' => q({0} л),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} л/100 км),
						'many' => q({0} л/100 км),
						'name' => q(л/100 км),
						'one' => q({0} л/100 км),
						'other' => q({0} л/100 км),
					},
					'meter' => {
						'few' => q({0} м),
						'many' => q({0} м),
						'name' => q(м),
						'one' => q({0} м),
						'other' => q({0} м),
					},
					'millimeter' => {
						'few' => q({0} мм),
						'many' => q({0} мм),
						'name' => q(мм),
						'one' => q({0} мм),
						'other' => q({0} мм),
					},
					'millisecond' => {
						'few' => q({0} мс),
						'many' => q({0} мс),
						'name' => q(мс),
						'one' => q({0} мс),
						'other' => q({0} мс),
					},
					'minute' => {
						'few' => q({0} хв),
						'many' => q({0} хв),
						'name' => q(хв),
						'one' => q({0} хв),
						'other' => q({0} хв),
					},
					'month' => {
						'few' => q({0} мес.),
						'many' => q({0} мес.),
						'name' => q(мес.),
						'one' => q({0} мес.),
						'other' => q({0} мес.),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'second' => {
						'few' => q({0} с),
						'many' => q({0} с),
						'name' => q(с),
						'one' => q({0} с),
						'other' => q({0} с),
					},
					'week' => {
						'few' => q({0} тыдз.),
						'many' => q({0} тыдз.),
						'name' => q(тыдз.),
						'one' => q({0} тыдз.),
						'other' => q({0} тыдз.),
					},
					'year' => {
						'few' => q({0} г.),
						'many' => q({0} г.),
						'name' => q(г.),
						'one' => q({0} г.),
						'other' => q({0} г.),
					},
				},
				'short' => {
					'' => {
						'name' => q(кірунак),
					},
					'acre' => {
						'few' => q({0} акры),
						'many' => q({0} акраў),
						'name' => q(акры),
						'one' => q({0} акр),
						'other' => q({0} акра),
					},
					'acre-foot' => {
						'few' => q({0} акр-футы),
						'many' => q({0} акр-футаў),
						'name' => q(акр-футы),
						'one' => q({0} акр-фут),
						'other' => q({0} акр-фута),
					},
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(А),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(′′),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} а. а.),
						'many' => q({0} а. а.),
						'name' => q(а. а.),
						'one' => q({0} а. а.),
						'other' => q({0} а. а.),
					},
					'atmosphere' => {
						'few' => q({0} атм),
						'many' => q({0} атм),
						'name' => q(атм),
						'one' => q({0} атм),
						'other' => q({0} атм),
					},
					'bit' => {
						'few' => q({0} біты),
						'many' => q({0} біт),
						'name' => q(біты),
						'one' => q({0} біт),
						'other' => q({0} біта),
					},
					'byte' => {
						'few' => q({0} байты),
						'many' => q({0} байт),
						'name' => q(байты),
						'one' => q({0} байт),
						'other' => q({0} байта),
					},
					'calorie' => {
						'few' => q({0} кал),
						'many' => q({0} кал),
						'name' => q(кал),
						'one' => q({0} кал),
						'other' => q({0} кал),
					},
					'carat' => {
						'few' => q({0} кар),
						'many' => q({0} кар),
						'name' => q(кар),
						'one' => q({0} кар),
						'other' => q({0} кар),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} сл),
						'many' => q({0} сл),
						'name' => q(сл),
						'one' => q({0} сл),
						'other' => q({0} сл),
					},
					'centimeter' => {
						'few' => q({0} см),
						'many' => q({0} см),
						'name' => q(см),
						'one' => q({0} см),
						'other' => q({0} см),
						'per' => q({0}/см),
					},
					'century' => {
						'few' => q({0} ст.),
						'many' => q({0} ст.),
						'name' => q(ст.),
						'one' => q({0} ст.),
						'other' => q({0} ст.),
					},
					'coordinate' => {
						'east' => q({0} У),
						'north' => q({0} Пн),
						'south' => q({0} Пд),
						'west' => q({0} З),
					},
					'cubic-centimeter' => {
						'few' => q({0} см³),
						'many' => q({0} см³),
						'name' => q(см³),
						'one' => q({0} см³),
						'other' => q({0} см³),
						'per' => q({0}/см³),
					},
					'cubic-foot' => {
						'few' => q({0} куб. футы),
						'many' => q({0} куб. футаў),
						'name' => q(куб. футы),
						'one' => q({0} куб. фут),
						'other' => q({0} куб. фута),
					},
					'cubic-inch' => {
						'few' => q({0} куб. цалі),
						'many' => q({0} куб. цаляў),
						'name' => q(куб. цалі),
						'one' => q({0} куб. цаля),
						'other' => q({0} куб. цалі),
					},
					'cubic-kilometer' => {
						'few' => q({0} км³),
						'many' => q({0} км³),
						'name' => q(км³),
						'one' => q({0} км³),
						'other' => q({0} км³),
					},
					'cubic-meter' => {
						'few' => q({0} м³),
						'many' => q({0} м³),
						'name' => q(м³),
						'one' => q({0} м³),
						'other' => q({0} м³),
						'per' => q({0}/м³),
					},
					'cubic-mile' => {
						'few' => q({0} куб. мілі),
						'many' => q({0} куб. міль),
						'name' => q(куб. мілі),
						'one' => q({0} куб. міля),
						'other' => q({0} куб. мілі),
					},
					'cubic-yard' => {
						'few' => q({0} куб. ярды),
						'many' => q({0} куб. ярдаў),
						'name' => q(куб. ярды),
						'one' => q({0} куб. ярд),
						'other' => q({0} куб. ярда),
					},
					'cup' => {
						'few' => q({0} кубкі),
						'many' => q({0} кубкаў),
						'name' => q(кубкі),
						'one' => q({0} кубак),
						'other' => q({0} кубка),
					},
					'cup-metric' => {
						'few' => q({0} мет. кубкі),
						'many' => q({0} мет. кубкаў),
						'name' => q(мет. кубак),
						'one' => q({0} мет. кубак),
						'other' => q({0} мет. кубка),
					},
					'day' => {
						'few' => q({0} сут),
						'many' => q({0} сут),
						'name' => q(сут),
						'one' => q({0} сут),
						'other' => q({0} сут),
						'per' => q({0} сут),
					},
					'deciliter' => {
						'few' => q({0} дл),
						'many' => q({0} дл),
						'name' => q(дл),
						'one' => q({0} дл),
						'other' => q({0} дл),
					},
					'decimeter' => {
						'few' => q({0} дм),
						'many' => q({0} дм),
						'name' => q(дм),
						'one' => q({0} дм),
						'other' => q({0} дм),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'few' => q({0} вадк. унц.),
						'many' => q({0} вадк. унц.),
						'name' => q(вадк. унц.),
						'one' => q({0} вадк. унц.),
						'other' => q({0} вадк. унц.),
					},
					'foodcalorie' => {
						'few' => q({0} кал),
						'many' => q({0} кал),
						'name' => q(кал),
						'one' => q({0} кал),
						'other' => q({0} кал),
					},
					'foot' => {
						'few' => q({0} футы),
						'many' => q({0} футаў),
						'name' => q(футы),
						'one' => q({0} фут),
						'other' => q({0} фута),
						'per' => q({0}/фут),
					},
					'g-force' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(перагрузка),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'gallon' => {
						'few' => q({0} гал),
						'many' => q({0} гал),
						'name' => q(гал),
						'one' => q({0} гал),
						'other' => q({0} гал),
						'per' => q({0}/гал),
					},
					'gallon-imperial' => {
						'few' => q({0} імп. гал.),
						'many' => q({0} імп. гал.),
						'name' => q(імп. гал),
						'one' => q({0} імп. гал.),
						'other' => q({0} імп. гал.),
						'per' => q({0}/імп. гал.),
					},
					'generic' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'few' => q({0} Гбіт),
						'many' => q({0} Гбіт),
						'name' => q(Гбіт),
						'one' => q({0} Гбіт),
						'other' => q({0} Гбіт),
					},
					'gigabyte' => {
						'few' => q({0} ГБ),
						'many' => q({0} ГБ),
						'name' => q(ГБ),
						'one' => q({0} ГБ),
						'other' => q({0} ГБ),
					},
					'gigahertz' => {
						'few' => q({0} ГГц),
						'many' => q({0} ГГц),
						'name' => q(ГГц),
						'one' => q({0} ГГц),
						'other' => q({0} ГГц),
					},
					'gigawatt' => {
						'few' => q({0} ГВт),
						'many' => q({0} ГВт),
						'name' => q(ГВт),
						'one' => q({0} ГВт),
						'other' => q({0} ГВт),
					},
					'gram' => {
						'few' => q({0} г),
						'many' => q({0} г),
						'name' => q(г),
						'one' => q({0} г),
						'other' => q({0} г),
						'per' => q({0}/г),
					},
					'hectare' => {
						'few' => q({0} га),
						'many' => q({0} га),
						'name' => q(га),
						'one' => q({0} га),
						'other' => q({0} га),
					},
					'hectoliter' => {
						'few' => q({0} гл),
						'many' => q({0} гл),
						'name' => q(гл),
						'one' => q({0} гл),
						'other' => q({0} гл),
					},
					'hectopascal' => {
						'few' => q({0} гПа),
						'many' => q({0} гПа),
						'name' => q(гПа),
						'one' => q({0} гПа),
						'other' => q({0} гПа),
					},
					'hertz' => {
						'few' => q({0} Гц),
						'many' => q({0} Гц),
						'name' => q(Гц),
						'one' => q({0} Гц),
						'other' => q({0} Гц),
					},
					'horsepower' => {
						'few' => q({0} к. с.),
						'many' => q({0} к. с.),
						'name' => q(к. с.),
						'one' => q({0} к. с.),
						'other' => q({0} к. с.),
					},
					'hour' => {
						'few' => q({0} гадз),
						'many' => q({0} гадз),
						'name' => q(гадз),
						'one' => q({0} гадз),
						'other' => q({0} гадз),
						'per' => q({0}/гадз),
					},
					'inch' => {
						'few' => q({0} цалі),
						'many' => q({0} цаляў),
						'name' => q(цалі),
						'one' => q({0} цаля),
						'other' => q({0} цалі),
						'per' => q({0}/цалю),
					},
					'inch-hg' => {
						'few' => q({0} цалі рт. сл.),
						'many' => q({0} цаляў рт. сл.),
						'name' => q(цалі рт. сл.),
						'one' => q({0} цаля рт. сл.),
						'other' => q({0} цалі рт. сл.),
					},
					'joule' => {
						'few' => q({0} Дж),
						'many' => q({0} Дж),
						'name' => q(Дж),
						'one' => q({0} Дж),
						'other' => q({0} Дж),
					},
					'karat' => {
						'few' => q({0} кар зол),
						'many' => q({0} кар зол),
						'name' => q(кар золата),
						'one' => q({0} кар зол),
						'other' => q({0} кар зол),
					},
					'kelvin' => {
						'few' => q({0} К),
						'many' => q({0} К),
						'name' => q(К),
						'one' => q({0} К),
						'other' => q({0} К),
					},
					'kilobit' => {
						'few' => q({0} кбіт),
						'many' => q({0} кбіт),
						'name' => q(кбіт),
						'one' => q({0} кбіт),
						'other' => q({0} кбіт),
					},
					'kilobyte' => {
						'few' => q({0} КБ),
						'many' => q({0} КБ),
						'name' => q(КБ),
						'one' => q({0} КБ),
						'other' => q({0} КБ),
					},
					'kilocalorie' => {
						'few' => q({0} ккал),
						'many' => q({0} ккал),
						'name' => q(ккал),
						'one' => q({0} ккал),
						'other' => q({0} ккал),
					},
					'kilogram' => {
						'few' => q({0} кг),
						'many' => q({0} кг),
						'name' => q(кг),
						'one' => q({0} кг),
						'other' => q({0} кг),
						'per' => q({0}/кг),
					},
					'kilohertz' => {
						'few' => q({0} кГц),
						'many' => q({0} кГц),
						'name' => q(кГц),
						'one' => q({0} кГц),
						'other' => q({0} кГц),
					},
					'kilojoule' => {
						'few' => q({0} кДж),
						'many' => q({0} кДж),
						'name' => q(кДж),
						'one' => q({0} кДж),
						'other' => q({0} кДж),
					},
					'kilometer' => {
						'few' => q({0} км),
						'many' => q({0} км),
						'name' => q(км),
						'one' => q({0} км),
						'other' => q({0} км),
						'per' => q({0}/км),
					},
					'kilometer-per-hour' => {
						'few' => q({0} км/гадз),
						'many' => q({0} км/гадз),
						'name' => q(км/гадз),
						'one' => q({0} км/гадз),
						'other' => q({0} км/гадз),
					},
					'kilowatt' => {
						'few' => q({0} кВт),
						'many' => q({0} кВт),
						'name' => q(кВт),
						'one' => q({0} кВт),
						'other' => q({0} кВт),
					},
					'kilowatt-hour' => {
						'few' => q({0} кВт·г),
						'many' => q({0} кВт·г),
						'name' => q(кВт·г),
						'one' => q({0} кВт·г),
						'other' => q({0} кВт·г),
					},
					'knot' => {
						'few' => q({0} вуз.),
						'many' => q({0} вуз.),
						'name' => q(вуз.),
						'one' => q({0} вуз.),
						'other' => q({0} вуз.),
					},
					'light-year' => {
						'few' => q({0} св. г.),
						'many' => q({0} св. г.),
						'name' => q(св. г.),
						'one' => q({0} св. г.),
						'other' => q({0} св. г.),
					},
					'liter' => {
						'few' => q({0} л),
						'many' => q({0} л),
						'name' => q(л),
						'one' => q({0} л),
						'other' => q({0} л),
						'per' => q({0}/л),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} л/100 км),
						'many' => q({0} л/100 км),
						'name' => q(л/100 км),
						'one' => q({0} л/100 км),
						'other' => q({0} л/100 км),
					},
					'liter-per-kilometer' => {
						'few' => q({0} л/км),
						'many' => q({0} л/км),
						'name' => q(л/км),
						'one' => q({0} л/км),
						'other' => q({0} л/км),
					},
					'lux' => {
						'few' => q({0} лк),
						'many' => q({0} лк),
						'name' => q(лк),
						'one' => q({0} лк),
						'other' => q({0} лк),
					},
					'megabit' => {
						'few' => q({0} Мбіт),
						'many' => q({0} Мбіт),
						'name' => q(Мбіт),
						'one' => q({0} Мбіт),
						'other' => q({0} Мбіт),
					},
					'megabyte' => {
						'few' => q({0} МБ),
						'many' => q({0} МБ),
						'name' => q(МБ),
						'one' => q({0} МБ),
						'other' => q({0} МБ),
					},
					'megahertz' => {
						'few' => q({0} МГц),
						'many' => q({0} МГц),
						'name' => q(МГц),
						'one' => q({0} МГц),
						'other' => q({0} МГц),
					},
					'megaliter' => {
						'few' => q({0} Мл),
						'many' => q({0} Мл),
						'name' => q(Мл),
						'one' => q({0} Мл),
						'other' => q({0} Мл),
					},
					'megawatt' => {
						'few' => q({0} МВт),
						'many' => q({0} МВт),
						'name' => q(МВт),
						'one' => q({0} МВт),
						'other' => q({0} МВт),
					},
					'meter' => {
						'few' => q({0} м),
						'many' => q({0} м),
						'name' => q(м),
						'one' => q({0} м),
						'other' => q({0} м),
						'per' => q({0}/м),
					},
					'meter-per-second' => {
						'few' => q({0} м/с),
						'many' => q({0} м/с),
						'name' => q(м/с),
						'one' => q({0} м/с),
						'other' => q({0} м/с),
					},
					'meter-per-second-squared' => {
						'few' => q({0} м/с²),
						'many' => q({0} м/с²),
						'name' => q(м/с²),
						'one' => q({0} м/с²),
						'other' => q({0} м/с²),
					},
					'metric-ton' => {
						'few' => q({0} мет. тоны),
						'many' => q({0} мет. тон),
						'name' => q(т),
						'one' => q({0} мет. тона),
						'other' => q({0} мет. тоны),
					},
					'microgram' => {
						'few' => q({0} мкг),
						'many' => q({0} мкг),
						'name' => q(мкг),
						'one' => q({0} мкг),
						'other' => q({0} мкг),
					},
					'micrometer' => {
						'few' => q({0} мкм),
						'many' => q({0} мкм),
						'name' => q(мкм),
						'one' => q({0} мкм),
						'other' => q({0} мкм),
					},
					'microsecond' => {
						'few' => q({0} мкс),
						'many' => q({0} мкс),
						'name' => q(мкс),
						'one' => q({0} мкс),
						'other' => q({0} мкс),
					},
					'mile' => {
						'few' => q({0} мілі),
						'many' => q({0} міль),
						'name' => q(мілі),
						'one' => q({0} міля),
						'other' => q({0} мілі),
					},
					'mile-per-gallon' => {
						'few' => q({0} мілі/гал.),
						'many' => q({0} міль/гал.),
						'name' => q(мілі/гал.),
						'one' => q({0} міля/гал.),
						'other' => q({0} мілі/гал.),
					},
					'mile-per-gallon-imperial' => {
						'few' => q({0} мілі/імп. гал.),
						'many' => q({0} міль/імп. галон),
						'name' => q(міль/імп. гал.),
						'one' => q({0} міля/імп. гал.),
						'other' => q({0} мілі/імп. галон),
					},
					'mile-per-hour' => {
						'few' => q({0} мілі/гадз),
						'many' => q({0} міль/гадз),
						'name' => q(мілі/гадз),
						'one' => q({0} міля/гадз),
						'other' => q({0} мілі/гадз),
					},
					'mile-scandinavian' => {
						'few' => q({0} скан. мілі),
						'many' => q({0} скан. міль),
						'name' => q(сканд. мілі),
						'one' => q({0} скан. мілі),
						'other' => q({0} скан. мілі),
					},
					'milliampere' => {
						'few' => q({0} мА),
						'many' => q({0} мА),
						'name' => q(мА),
						'one' => q({0} мА),
						'other' => q({0} мА),
					},
					'millibar' => {
						'few' => q({0} мбар),
						'many' => q({0} мбар),
						'name' => q(мбар),
						'one' => q({0} мбар),
						'other' => q({0} мбар),
					},
					'milligram' => {
						'few' => q({0} мг),
						'many' => q({0} мг),
						'name' => q(мг),
						'one' => q({0} мг),
						'other' => q({0} мг),
					},
					'milligram-per-deciliter' => {
						'few' => q({0} мг на дл),
						'many' => q({0} мг на дл),
						'name' => q(мг на дл),
						'one' => q({0} мг на дл),
						'other' => q({0} мг на дл),
					},
					'milliliter' => {
						'few' => q({0} мл),
						'many' => q({0} мл),
						'name' => q(мл),
						'one' => q({0} мл),
						'other' => q({0} мл),
					},
					'millimeter' => {
						'few' => q({0} мм),
						'many' => q({0} мм),
						'name' => q(мм),
						'one' => q({0} мм),
						'other' => q({0} мм),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} мм рт. сл.),
						'many' => q({0} мм рт. сл.),
						'name' => q(мм рт. сл.),
						'one' => q({0} мм рт. сл.),
						'other' => q({0} мм рт. сл.),
					},
					'millimole-per-liter' => {
						'few' => q({0} ммоль/л),
						'many' => q({0} ммоль/л),
						'name' => q(ммоль/л),
						'one' => q({0} ммоль/л),
						'other' => q({0} ммоль/л),
					},
					'millisecond' => {
						'few' => q({0} мс),
						'many' => q({0} мс),
						'name' => q(мс),
						'one' => q({0} мс),
						'other' => q({0} мс),
					},
					'milliwatt' => {
						'few' => q({0} мВт),
						'many' => q({0} мВт),
						'name' => q(мВт),
						'one' => q({0} мВт),
						'other' => q({0} мВт),
					},
					'minute' => {
						'few' => q({0} хв),
						'many' => q({0} хв),
						'name' => q(хв),
						'one' => q({0} хв),
						'other' => q({0} хв),
						'per' => q({0}/ хв),
					},
					'month' => {
						'few' => q({0} мес.),
						'many' => q({0} мес.),
						'name' => q(мес.),
						'one' => q({0} мес.),
						'other' => q({0} мес.),
						'per' => q({0} у мес.),
					},
					'nanometer' => {
						'few' => q({0} нм),
						'many' => q({0} нм),
						'name' => q(нм),
						'one' => q({0} нм),
						'other' => q({0} нм),
					},
					'nanosecond' => {
						'few' => q({0} нс),
						'many' => q({0} нс),
						'name' => q(нс),
						'one' => q({0} нс),
						'other' => q({0} нс),
					},
					'nautical-mile' => {
						'few' => q({0} мар. мілі),
						'many' => q({0} мар. міль),
						'name' => q(мар. мілі),
						'one' => q({0} мар. міля),
						'other' => q({0} мар. міль),
					},
					'ohm' => {
						'few' => q({0} Ом),
						'many' => q({0} Ом),
						'name' => q(Ом),
						'one' => q({0} Ом),
						'other' => q({0} Ом),
					},
					'ounce' => {
						'few' => q({0} унц.),
						'many' => q({0} унц.),
						'name' => q(унц.),
						'one' => q({0} унц.),
						'other' => q({0} унц.),
						'per' => q({0}/унц.),
					},
					'ounce-troy' => {
						'few' => q({0} тр. унц.),
						'many' => q({0} тр. унц.),
						'name' => q(тр. унц.),
						'one' => q({0} тр. унц.),
						'other' => q({0} тр. унц.),
					},
					'parsec' => {
						'few' => q({0} пс),
						'many' => q({0} пс),
						'name' => q(пс),
						'one' => q({0} пс),
						'other' => q({0} пс),
					},
					'part-per-million' => {
						'few' => q({0} ppm),
						'many' => q({0} ppm),
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'name' => q(праміле),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'few' => q({0} ПБ),
						'many' => q({0} ПБ),
						'name' => q(ПБайт),
						'one' => q({0} ПБ),
						'other' => q({0} ПБ),
					},
					'picometer' => {
						'few' => q({0} пм),
						'many' => q({0} пм),
						'name' => q(пм),
						'one' => q({0} пм),
						'other' => q({0} пм),
					},
					'pint' => {
						'few' => q({0} пінты),
						'many' => q({0} пінтаў),
						'name' => q(пінты),
						'one' => q({0} пінта),
						'other' => q({0} пінты),
					},
					'pint-metric' => {
						'few' => q({0} мет. пінты),
						'many' => q({0} мет. пінтаў),
						'name' => q(мет. пінты),
						'one' => q({0} мет. пінта),
						'other' => q({0} мет. пінты),
					},
					'point' => {
						'few' => q({0} пт),
						'many' => q({0} пт),
						'name' => q(пт),
						'one' => q({0} пт),
						'other' => q({0} пт),
					},
					'pound' => {
						'few' => q({0} фунты),
						'many' => q({0} фунтаў),
						'name' => q(фунты),
						'one' => q({0} фунт),
						'other' => q({0} фунта),
						'per' => q({0}/фунт),
					},
					'pound-per-square-inch' => {
						'few' => q({0} фунты на кв. цалю),
						'many' => q({0} фунтаў на кв. цалю),
						'name' => q(фунты на кв. цалю),
						'one' => q({0} фунт на кв. цалю),
						'other' => q({0} фунта на кв. цалю),
					},
					'quart' => {
						'few' => q({0} кварты),
						'many' => q({0} кварт),
						'name' => q(кварты),
						'one' => q({0} кварта),
						'other' => q({0} кварты),
					},
					'radian' => {
						'few' => q({0} рад),
						'many' => q({0} рад),
						'name' => q(рад),
						'one' => q({0} рад),
						'other' => q({0} рад),
					},
					'revolution' => {
						'few' => q({0} аб),
						'many' => q({0} аб),
						'name' => q(аб),
						'one' => q({0} аб),
						'other' => q({0} аб),
					},
					'second' => {
						'few' => q({0} с),
						'many' => q({0} с),
						'name' => q(с),
						'one' => q({0} с),
						'other' => q({0} с),
						'per' => q({0}/с),
					},
					'square-centimeter' => {
						'few' => q({0} см²),
						'many' => q({0} см²),
						'name' => q(см²),
						'one' => q({0} см²),
						'other' => q({0} см²),
						'per' => q({0}/см²),
					},
					'square-foot' => {
						'few' => q({0} кв. футы),
						'many' => q({0} кв. футаў),
						'name' => q(кв. футы),
						'one' => q({0} кв. фут),
						'other' => q({0} кв. фута),
					},
					'square-inch' => {
						'few' => q({0} кв. цалі),
						'many' => q({0} кв. цаляў),
						'name' => q(кв. цалі),
						'one' => q({0} кв. цаля),
						'other' => q({0} кв. цалі),
						'per' => q({0}/кв. цалю),
					},
					'square-kilometer' => {
						'few' => q({0} км²),
						'many' => q({0} км²),
						'name' => q(км²),
						'one' => q({0} км²),
						'other' => q({0} км²),
						'per' => q({0}/км²),
					},
					'square-meter' => {
						'few' => q({0} м²),
						'many' => q({0} м²),
						'name' => q(м²),
						'one' => q({0} м²),
						'other' => q({0} м²),
						'per' => q({0}/м²),
					},
					'square-mile' => {
						'few' => q({0} кв. мілі),
						'many' => q({0} кв. міль),
						'name' => q(кв. мілі),
						'one' => q({0} кв. міля),
						'other' => q({0} кв. мілі),
						'per' => q({0}/кв. мілю),
					},
					'square-yard' => {
						'few' => q({0} кв. ярды),
						'many' => q({0} кв. ярдаў),
						'name' => q(кв. ярды),
						'one' => q({0} кв. ярд),
						'other' => q({0} кв. ярда),
					},
					'tablespoon' => {
						'few' => q({0} ст. лыжкі),
						'many' => q({0} ст. лыжак),
						'name' => q(ст. лыжкі),
						'one' => q({0} ст. лыжка),
						'other' => q({0} ст. лыжкі),
					},
					'teaspoon' => {
						'few' => q({0} ч. лыжкі),
						'many' => q({0} ч. лыжак),
						'name' => q(ч. лыжкі),
						'one' => q({0} ч. лыжка),
						'other' => q({0} ч. лыжкі),
					},
					'terabit' => {
						'few' => q({0} Тбіт),
						'many' => q({0} Тбіт),
						'name' => q(Тбіт),
						'one' => q({0} Тбіт),
						'other' => q({0} Тбіт),
					},
					'terabyte' => {
						'few' => q({0} ТБ),
						'many' => q({0} ТБ),
						'name' => q(ТБ),
						'one' => q({0} ТБ),
						'other' => q({0} ТБ),
					},
					'ton' => {
						'few' => q({0} тоны),
						'many' => q({0} тон),
						'name' => q(тоны),
						'one' => q({0} тона),
						'other' => q({0} тоны),
					},
					'volt' => {
						'few' => q({0} В),
						'many' => q({0} В),
						'name' => q(В),
						'one' => q({0} В),
						'other' => q({0} В),
					},
					'watt' => {
						'few' => q({0} Вт),
						'many' => q({0} Вт),
						'name' => q(Вт),
						'one' => q({0} Вт),
						'other' => q({0} Вт),
					},
					'week' => {
						'few' => q({0} тыдз.),
						'many' => q({0} тыдз.),
						'name' => q(тыдз.),
						'one' => q({0} тыдз.),
						'other' => q({0} тыдз.),
						'per' => q({0} у тыдз.),
					},
					'yard' => {
						'few' => q({0} ярды),
						'many' => q({0} ярдаў),
						'name' => q(ярды),
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					'year' => {
						'few' => q({0} г.),
						'many' => q({0} г.),
						'name' => q(г.),
						'one' => q({0} г.),
						'other' => q({0} г.),
						'per' => q({0} у г.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:так|т|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:не|н|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0} {1}),
				middle => q({0} {1}),
				end => q({0} {1}),
				2 => q({0} {1}),
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
			'group' => q( ),
			'infinity' => q(∞),
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
					'few' => '0 тыс'.'',
					'many' => '0 тыс'.'',
					'one' => '0 тыс'.'',
					'other' => '0 тыс'.'',
				},
				'10000' => {
					'few' => '00 тыс'.'',
					'many' => '00 тыс'.'',
					'one' => '00 тыс'.'',
					'other' => '00 тыс'.'',
				},
				'100000' => {
					'few' => '000 тыс'.'',
					'many' => '000 тыс'.'',
					'one' => '000 тыс'.'',
					'other' => '000 тыс'.'',
				},
				'1000000' => {
					'few' => '0 млн',
					'many' => '0 млн',
					'one' => '0 млн',
					'other' => '0 млн',
				},
				'10000000' => {
					'few' => '00 млн',
					'many' => '00 млн',
					'one' => '00 млн',
					'other' => '00 млн',
				},
				'100000000' => {
					'few' => '000 млн',
					'many' => '000 млн',
					'one' => '000 млн',
					'other' => '000 млн',
				},
				'1000000000' => {
					'few' => '0 млрд',
					'many' => '0 млрд',
					'one' => '0 млрд',
					'other' => '0 млрд',
				},
				'10000000000' => {
					'few' => '00 млрд',
					'many' => '00 млрд',
					'one' => '00 млрд',
					'other' => '00 млрд',
				},
				'100000000000' => {
					'few' => '000 млрд',
					'many' => '000 млрд',
					'one' => '000 млрд',
					'other' => '000 млрд',
				},
				'1000000000000' => {
					'few' => '0 трлн',
					'many' => '0 трлн',
					'one' => '0 трлн',
					'other' => '0 трлн',
				},
				'10000000000000' => {
					'few' => '00 трлн',
					'many' => '00 трлн',
					'one' => '00 трлн',
					'other' => '00 трлн',
				},
				'100000000000000' => {
					'few' => '000 трлн',
					'many' => '000 трлн',
					'one' => '000 трлн',
					'other' => '000 трлн',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'few' => '0 тысячы',
					'many' => '0 тысяч',
					'one' => '0 тысяча',
					'other' => '0 тысячы',
				},
				'10000' => {
					'few' => '00 тысячы',
					'many' => '00 тысяч',
					'one' => '00 тысяча',
					'other' => '00 тысячы',
				},
				'100000' => {
					'few' => '000 тысячы',
					'many' => '000 тысяч',
					'one' => '000 тысяча',
					'other' => '000 тысячы',
				},
				'1000000' => {
					'few' => '0 мільёны',
					'many' => '0 мільёнаў',
					'one' => '0 мільён',
					'other' => '0 мільёна',
				},
				'10000000' => {
					'few' => '00 мільёны',
					'many' => '00 мільёнаў',
					'one' => '00 мільён',
					'other' => '00 мільёна',
				},
				'100000000' => {
					'few' => '000 мільёны',
					'many' => '000 мільёнаў',
					'one' => '000 мільён',
					'other' => '000 мільёна',
				},
				'1000000000' => {
					'few' => '0 мільярды',
					'many' => '0 мільярдаў',
					'one' => '0 мільярд',
					'other' => '0 мільярда',
				},
				'10000000000' => {
					'few' => '00 мільярды',
					'many' => '00 мільярдаў',
					'one' => '00 мільярд',
					'other' => '00 мільярда',
				},
				'100000000000' => {
					'few' => '000 мільярды',
					'many' => '000 мільярдаў',
					'one' => '000 мільярд',
					'other' => '000 мільярда',
				},
				'1000000000000' => {
					'few' => '0 трыльёны',
					'many' => '0 трыльёнаў',
					'one' => '0 трыльён',
					'other' => '0 трыльёна',
				},
				'10000000000000' => {
					'few' => '00 трыльёны',
					'many' => '00 трыльёнаў',
					'one' => '00 трыльён',
					'other' => '00 трыльёна',
				},
				'100000000000000' => {
					'few' => '000 трыльёны',
					'many' => '000 трыльёнаў',
					'one' => '000 трыльён',
					'other' => '000 трыльёна',
				},
			},
			'short' => {
				'1000' => {
					'few' => '0 тыс'.'',
					'many' => '0 тыс'.'',
					'one' => '0 тыс'.'',
					'other' => '0 тыс'.'',
				},
				'10000' => {
					'few' => '00 тыс'.'',
					'many' => '00 тыс'.'',
					'one' => '00 тыс'.'',
					'other' => '00 тыс'.'',
				},
				'100000' => {
					'few' => '000 тыс'.'',
					'many' => '000 тыс'.'',
					'one' => '000 тыс'.'',
					'other' => '000 тыс'.'',
				},
				'1000000' => {
					'few' => '0 млн',
					'many' => '0 млн',
					'one' => '0 млн',
					'other' => '0 млн',
				},
				'10000000' => {
					'few' => '00 млн',
					'many' => '00 млн',
					'one' => '00 млн',
					'other' => '00 млн',
				},
				'100000000' => {
					'few' => '000 млн',
					'many' => '000 млн',
					'one' => '000 млн',
					'other' => '000 млн',
				},
				'1000000000' => {
					'few' => '0 млрд',
					'many' => '0 млрд',
					'one' => '0 млрд',
					'other' => '0 млрд',
				},
				'10000000000' => {
					'few' => '00 млрд',
					'many' => '00 млрд',
					'one' => '00 млрд',
					'other' => '00 млрд',
				},
				'100000000000' => {
					'few' => '000 млрд',
					'many' => '000 млрд',
					'one' => '000 млрд',
					'other' => '000 млрд',
				},
				'1000000000000' => {
					'few' => '0 трлн',
					'many' => '0 трлн',
					'one' => '0 трлн',
					'other' => '0 трлн',
				},
				'10000000000000' => {
					'few' => '00 трлн',
					'many' => '00 трлн',
					'one' => '00 трлн',
					'other' => '00 трлн',
				},
				'100000000000000' => {
					'few' => '000 трлн',
					'many' => '000 трлн',
					'one' => '000 трлн',
					'other' => '000 трлн',
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
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(дырхем ААЭ),
				'few' => q(дырхемы ААЭ),
				'many' => q(дырхемаў ААЭ),
				'one' => q(дырхем ААЭ),
				'other' => q(дырхема ААЭ),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(афганскі афгані),
				'few' => q(афганскія афгані),
				'many' => q(афганскіх афгані),
				'one' => q(афганскі афгані),
				'other' => q(афганскага афгані),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(албанскі лек),
				'few' => q(албанскія лекі),
				'many' => q(албанскіх лекаў),
				'one' => q(албанскі лек),
				'other' => q(албанскага лека),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(армянскі драм),
				'few' => q(армянскія драмы),
				'many' => q(армянскіх драмаў),
				'one' => q(армянскі драм),
				'other' => q(армянскага драма),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(нідэрландскі антыльскі гульдэн),
				'few' => q(нідэрландскія антыльскія гульдэны),
				'many' => q(нідэрландскіх антыльскіх гульдэнаў),
				'one' => q(нідэрландскі антыльскі гульдэн),
				'other' => q(нідэрландскага антыльскага гульдэна),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(ангольская кванза),
				'few' => q(ангольскія кванзы),
				'many' => q(ангольскіх кванз),
				'one' => q(ангольская кванза),
				'other' => q(ангольскай кванзы),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(аргенцінскае песа),
				'few' => q(аргенцінскія песа),
				'many' => q(аргенцінскіх песа),
				'one' => q(аргенцінскае песа),
				'other' => q(аргенцінскага песа),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(аўстралійскі долар),
				'few' => q(аўстралійскія долары),
				'many' => q(аўстралійскіх долараў),
				'one' => q(аўстралійскі долар),
				'other' => q(аўстралійскага долара),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(арубанскі фларын),
				'few' => q(арубанскія фларыны),
				'many' => q(арубанскіх фларынаў),
				'one' => q(арубанскі фларын),
				'other' => q(арубанскага фларына),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(азербайджанскі манат),
				'few' => q(азербайджанскія манаты),
				'many' => q(азербайджанскіх манатаў),
				'one' => q(азербайджанскі манат),
				'other' => q(азербайджанскага маната),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(канверсоўная марка Босніі і Герцагавіны),
				'few' => q(канверсоўныя маркі Босніі і Герцагавіны),
				'many' => q(канверсоўных марак Босніі і Герцагавіны),
				'one' => q(канверсоўная марка Босніі і Герцагавіны),
				'other' => q(канверсоўнай маркі Босніі і Герцагавіны),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(барбадоскі долар),
				'few' => q(барбадоскія долары),
				'many' => q(барбадоскіх долараў),
				'one' => q(барбадоскі долар),
				'other' => q(барбадоскага долара),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(бангладэшская така),
				'few' => q(бангладэшскія такі),
				'many' => q(бангладэшскіх так),
				'one' => q(бангладэшская така),
				'other' => q(бангладэшскай такі),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(балгарскі леў),
				'few' => q(балгарскія левы),
				'many' => q(балгарскіх леваў),
				'one' => q(балгарскі леў),
				'other' => q(балгарскага лева),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(бахрэйнскі дынар),
				'few' => q(бахрэйнскія дынары),
				'many' => q(бахрэйнскі дынараў),
				'one' => q(бахрэйнскі дынар),
				'other' => q(бахрэйнскага дынара),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(бурундзійскі франк),
				'few' => q(бурундзійскія франкі),
				'many' => q(бурундзійскіх франкаў),
				'one' => q(бурундзійскі франк),
				'other' => q(бурундзійскага франка),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(бермудскі долар),
				'few' => q(бермудскія долары),
				'many' => q(бермудскіх долараў),
				'one' => q(бермудскі долар),
				'other' => q(бермудскага долара),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(брунейскі долар),
				'few' => q(брунейскія долары),
				'many' => q(брунейскіх долараў),
				'one' => q(брунейскі долар),
				'other' => q(брунейскага долара),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(балівіяна),
				'few' => q(балівіяна),
				'many' => q(балівіяна),
				'one' => q(балівіяна),
				'other' => q(балівіяна),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(бразільскі рэал),
				'few' => q(бразільскія рэалы),
				'many' => q(бразільскіх рэалаў),
				'one' => q(бразільскі рэал),
				'other' => q(бразільскага рэала),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(багамскі долар),
				'few' => q(багамскія долары),
				'many' => q(багамскіх долараў),
				'one' => q(багамскі долар),
				'other' => q(багамскага долара),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(бутанскі нгултрум),
				'few' => q(бутанскія нгултрумы),
				'many' => q(бутанскіх нгултрумаў),
				'one' => q(бутанскі нгултрум),
				'other' => q(бутанскага нгултрума),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(батсванская пула),
				'few' => q(батсванскія пулы),
				'many' => q(батсванскіх пул),
				'one' => q(батсванская пула),
				'other' => q(батсванскай пулы),
			},
		},
		'BYN' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(беларускі рубель),
				'few' => q(беларускія рублі),
				'many' => q(беларускіх рублёў),
				'one' => q(беларускі рубель),
				'other' => q(беларускага рубля),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(беларускі рубель \(2000–2016\)),
				'few' => q(беларускія рублі \(2000–2016\)),
				'many' => q(беларускіх рублёў \(2000–2016\)),
				'one' => q(беларускі рубель \(2000–2016\)),
				'other' => q(беларускага рубля \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(белізскі долар),
				'few' => q(белізскія долары),
				'many' => q(белізскіх долараў),
				'one' => q(белізскі долар),
				'other' => q(белізскага долара),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(канадскі долар),
				'few' => q(канадскія долары),
				'many' => q(канадскіх долараў),
				'one' => q(канадскі долар),
				'other' => q(канадскага долара),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(кангалезскі франк),
				'few' => q(кангалезскія франкі),
				'many' => q(кангалезскіх франкаў),
				'one' => q(кангалезскі франк),
				'other' => q(кангалезскага франка),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(швейцарскі франк),
				'few' => q(швейцарскія франкі),
				'many' => q(швейцарскіх франкаў),
				'one' => q(швейцарскі франк),
				'other' => q(швейцарскага франка),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(чылійскае песа),
				'few' => q(чылійскія песа),
				'many' => q(чылійскіх песа),
				'one' => q(чылійскае песа),
				'other' => q(чылійскага песа),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(афшорны кітайскі юань),
				'few' => q(афшорныя кітайскія юані),
				'many' => q(афшорных кітайскіх юаняў),
				'one' => q(афшорны кітайскі юань),
				'other' => q(афшорнага кітайскага юаня),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(кітайскі юань),
				'few' => q(кітайскія юані),
				'many' => q(кітайскіх юаняў),
				'one' => q(кітайскі юань),
				'other' => q(кітайскага юаня),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(калумбійскае песа),
				'few' => q(калумбійскія песа),
				'many' => q(калумбійскіх песа),
				'one' => q(калумбійскае песа),
				'other' => q(калумбійскага песа),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(коста-рыканскі калон),
				'few' => q(коста-рыканскія калоны),
				'many' => q(коста-рыканскіх калонаў),
				'one' => q(коста-рыканскі калон),
				'other' => q(коста-рыканскага калона),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(кубінскае канверсоўнае песа),
				'few' => q(кубінскія канверсоўныя песа),
				'many' => q(кубінскіх канверсоўных песа),
				'one' => q(кубінскае канверсоўнае песа),
				'other' => q(кубінскага канверсоўнага песа),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(кубінскае песа),
				'few' => q(кубінскія песа),
				'many' => q(кубінскіх песа),
				'one' => q(кубінскае песа),
				'other' => q(кубінскага песа),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(эскуда Каба-Вердэ),
				'few' => q(эскуда Каба-Вердэ),
				'many' => q(эскуда Каба-Вердэ),
				'one' => q(эскуда Каба-Вердэ),
				'other' => q(эскуда Каба-Вердэ),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(чэшская крона),
				'few' => q(чэшскія кроны),
				'many' => q(чэшскіх крон),
				'one' => q(чэшская крона),
				'other' => q(чэшскай кроны),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(джыбуційскі франк),
				'few' => q(джыбуційскія франкі),
				'many' => q(джыбуційскіх франкаў),
				'one' => q(джыбуційскі франк),
				'other' => q(джыбуційскага франка),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(дацкая крона),
				'few' => q(дацкія кроны),
				'many' => q(дацкіх крон),
				'one' => q(дацкая крона),
				'other' => q(дацкай кроны),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(дамініканскае песа),
				'few' => q(дамініканскія песа),
				'many' => q(дамініканскіх песа),
				'one' => q(дамініканскае песа),
				'other' => q(дамініканскага песа),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(алжырскі дынар),
				'few' => q(алжырскія дынары),
				'many' => q(алжырскіх дынараў),
				'one' => q(алжырскі дынар),
				'other' => q(алжырскага дынара),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(егіпецкі фунт),
				'few' => q(егіпецкія фунты),
				'many' => q(егіпецкіх фунтаў),
				'one' => q(егіпецкі фунт),
				'other' => q(егіпецкага фунта),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(эрытрэйская накфа),
				'few' => q(эрытрэйскія накфы),
				'many' => q(эрытрэйскіх накфаў),
				'one' => q(эрытрэйская накфа),
				'other' => q(эрытрэйскай накфы),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(эфіопскі быр),
				'few' => q(эфіопскія быры),
				'many' => q(эфіопскіх быраў),
				'one' => q(эфіопскі быр),
				'other' => q(эфіопскага быра),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(еўра),
				'few' => q(еўра),
				'many' => q(еўра),
				'one' => q(еўра),
				'other' => q(еўра),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(фіджыйскі долар),
				'few' => q(фіджыйскія долары),
				'many' => q(фіджыйскіх долараў),
				'one' => q(фіджыйскі долар),
				'other' => q(фіджыйскага долара),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(фунт Фалклендскіх астравоў),
				'few' => q(фунты Фалклендскіх астравоў),
				'many' => q(фунтаў Фалклендскіх астравоў),
				'one' => q(фунт Фалклендскіх астравоў),
				'other' => q(фунта Фалклендскіх астравоў),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(брытанскі фунт стэрлінгаў),
				'few' => q(брытанскія фунты стэрлінгаў),
				'many' => q(брытанскіх фунтаў стэрлінгаў),
				'one' => q(брытанскі фунт стэрлінгаў),
				'other' => q(брытанскага фунта стэрлінгаў),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(грузінскі лары),
				'few' => q(грузінскія лары),
				'many' => q(грузінскіх лары),
				'one' => q(грузінскі лары),
				'other' => q(грузінскага лары),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ганскі седзі),
				'few' => q(ганскія седзі),
				'many' => q(ганскіх седзі),
				'one' => q(ганскі седзі),
				'other' => q(ганскага седзі),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(гібралтарскі фунт),
				'few' => q(гібралтарскія фунты),
				'many' => q(гібралтарскіх фунтаў),
				'one' => q(гібралтарскі фунт),
				'other' => q(гібралтарскага фунта),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(гамбійскі даласі),
				'few' => q(гамбійскія даласі),
				'many' => q(гамбійскіх даласі),
				'one' => q(гамбійскі даласі),
				'other' => q(гамбійскага даласі),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(гвінейскі франк),
				'few' => q(гвінейскія франкі),
				'many' => q(гвінейскіх франкаў),
				'one' => q(гвінейскі франк),
				'other' => q(гвінейскага франка),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(гватэмальскі кетсаль),
				'few' => q(гватэмальскія кетсалі),
				'many' => q(гватэмальскіх кетсаляў),
				'one' => q(гватэмальскі кетсаль),
				'other' => q(гватэмальскага кетсаля),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(гаянскі долар),
				'few' => q(гаянскія долары),
				'many' => q(гаянскіх долараў),
				'one' => q(гаянскі долар),
				'other' => q(гаянскага долара),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(ганконгскі долар),
				'few' => q(ганконгскія долары),
				'many' => q(ганконгскіх долараў),
				'one' => q(ганконгскі долар),
				'other' => q(ганконгскага долара),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(гандураская лемпіра),
				'few' => q(гандураскія лемпіры),
				'many' => q(гандураскіх лемпір),
				'one' => q(гандураская лемпіра),
				'other' => q(гандураскай лемпіры),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(харвацкая куна),
				'few' => q(харвацкія куны),
				'many' => q(харвацкіх кун),
				'one' => q(харвацкая куна),
				'other' => q(харвацкай куны),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(гаіцянскі гурд),
				'few' => q(гаіцянскія гурды),
				'many' => q(гаіцянскіх гурдаў),
				'one' => q(гаіцянскі гурд),
				'other' => q(гаіцянскага гурда),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(венгерскі форынт),
				'few' => q(венгерскія форынты),
				'many' => q(венгерскіх форынтаў),
				'one' => q(венгерскі форынт),
				'other' => q(венгерскага форынта),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(інданезійская рупія),
				'few' => q(інданезійскія рупіі),
				'many' => q(інданезійскіх рупій),
				'one' => q(інданезійская рупія),
				'other' => q(інданезійскай рупіі),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(новы ізраільскі шэкель),
				'few' => q(новыя ізраільскія шэкелі),
				'many' => q(новых ізраільскіх шэкеляў),
				'one' => q(новы ізраільскі шэкель),
				'other' => q(новага ізраільскага шэкеля),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(індыйская рупія),
				'few' => q(індыйскія рупіі),
				'many' => q(індыйскіх рупій),
				'one' => q(індыйская рупія),
				'other' => q(індыйскай рупіі),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(іракскі дынар),
				'few' => q(іракскія дынары),
				'many' => q(іракскіх дынараў),
				'one' => q(іракскі дынар),
				'other' => q(іракскага дынара),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(іранскі рыал),
				'few' => q(іранскія рыалы),
				'many' => q(іранскіх рыалаў),
				'one' => q(іранскі рыал),
				'other' => q(іранскага рыала),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(ісландская крона),
				'few' => q(ісландскія кроны),
				'many' => q(ісландскіх крон),
				'one' => q(ісландская крона),
				'other' => q(ісландскай кроны),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(ямайскі долар),
				'few' => q(ямайскія долары),
				'many' => q(ямайскіх долараў),
				'one' => q(ямайскі долар),
				'other' => q(ямайскага долара),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(іарданскі дынар),
				'few' => q(іарданскія дынары),
				'many' => q(іарданскіх дынараў),
				'one' => q(іарданскі дынар),
				'other' => q(іарданскага дынара),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(японская іена),
				'few' => q(японскія іены),
				'many' => q(японскіх іен),
				'one' => q(японская іена),
				'other' => q(японскай іены),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(кенійскі шылінг),
				'few' => q(кенійскія шылінгі),
				'many' => q(кенійскіх шылінгаў),
				'one' => q(кенійскі шылінг),
				'other' => q(кенійскага шылінга),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(кіргізскі сом),
				'few' => q(кіргізскія сомы),
				'many' => q(кіргізскіх сомаў),
				'one' => q(кіргізскі сом),
				'other' => q(кіргізскага сома),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(камбаджыйскі рыэль),
				'few' => q(камбаджыйскія рыэлі),
				'many' => q(камбаджыйскіх рыэляў),
				'one' => q(камбаджыйскі рыэль),
				'other' => q(камбаджыйскага рыэля),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(каморскі франк),
				'few' => q(каморскія франкі),
				'many' => q(каморскіх франкаў),
				'one' => q(каморскі франк),
				'other' => q(каморскага франка),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(паўночнакарэйская вона),
				'few' => q(паўночнакарэйскія воны),
				'many' => q(паўночнакарэйскіх вон),
				'one' => q(паўночнакарэйская вона),
				'other' => q(паўночнакарэйскай воны),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(паўднёвакарэйская вона),
				'few' => q(паўднёвакарэйскія воны),
				'many' => q(паўднёвакарэйскіх вон),
				'one' => q(паўднёвакарэйская вона),
				'other' => q(паўднёвакарэйскай воны),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(кувейцкі дынар),
				'few' => q(кувейцкія дынары),
				'many' => q(кувейцкіх дынараў),
				'one' => q(кувейцкі дынар),
				'other' => q(кувейцкага дынара),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(долар Кайманавых астравоў),
				'few' => q(долары Кайманавых астравоў),
				'many' => q(долараў Кайманавых астравоў),
				'one' => q(долар Кайманавых астравоў),
				'other' => q(долара Кайманавых астравоў),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(казахстанскі тэнгэ),
				'few' => q(казахстанскія тэнгэ),
				'many' => q(казахстанскіх тэнгэ),
				'one' => q(казахстанскі тэнгэ),
				'other' => q(казахстанскага тэнгэ),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(лаоскі кіп),
				'few' => q(лаоскія кіпы),
				'many' => q(лаоскіх кіпаў),
				'one' => q(лаоскі кіп),
				'other' => q(лаоскага кіпа),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(ліванскі фунт),
				'few' => q(ліванскія фунты),
				'many' => q(ліванскіх фунтаў),
				'one' => q(ліванскі фунт),
				'other' => q(ліванскага фунта),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(шры-ланкійская рупія),
				'few' => q(шры-ланкійскія рупіі),
				'many' => q(шры-ланкійскіх рупій),
				'one' => q(шры-ланкійская рупія),
				'other' => q(шры-ланкійскай рупіі),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(ліберыйскі долар),
				'few' => q(ліберыйскія долары),
				'many' => q(ліберыйскіх долараў),
				'one' => q(ліберыйскі долар),
				'other' => q(ліберыйскага долара),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(лівійскі дынар),
				'few' => q(лівійскія дынары),
				'many' => q(лівійскіх дынараў),
				'one' => q(лівійскі дынар),
				'other' => q(лівійскага дынара),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(мараканскі дырхам),
				'few' => q(мараканскія дырхамы),
				'many' => q(мараканскіх дырхамаў),
				'one' => q(мараканскі дырхам),
				'other' => q(мараканскага дырхама),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(малдаўскі лей),
				'few' => q(малдаўскія леі),
				'many' => q(малдаўскіх леяў),
				'one' => q(малдаўскі лей),
				'other' => q(малдаўскага лея),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(малагасійскі арыяры),
				'few' => q(малагасійскія арыяры),
				'many' => q(малагасійскіх арыяры),
				'one' => q(малагасійскі арыяры),
				'other' => q(малагасійскага арыяры),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(македонскі дэнар),
				'few' => q(македонскія дэнары),
				'many' => q(македонскіх дэнараў),
				'one' => q(македонскі дэнар),
				'other' => q(македонскага дэнара),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(м’янманскі к’ят),
				'few' => q(м’янманскія к’яты),
				'many' => q(м’янманскіх к’ятаў),
				'one' => q(м’янманскі к’ят),
				'other' => q(м’янманскага к’ята),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(мангольскі тугрык),
				'few' => q(мангольскія тугрыкі),
				'many' => q(мангольскіх тугрыкаў),
				'one' => q(мангольскі тугрык),
				'other' => q(мангольскага тугрыка),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(патака Макаа),
				'few' => q(патакі Макаа),
				'many' => q(патак Макаа),
				'one' => q(патака Макаа),
				'other' => q(патакі Макаа),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(маўрытанская ўгія \(1973–2017\)),
				'few' => q(маўрытанскія ўгіі \(1973–2017\)),
				'many' => q(маўрытанскіх угій \(1973–2017\)),
				'one' => q(маўрытанская ўгія \(1973–2017\)),
				'other' => q(маўрытанскай ўгіі \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(маўрытанская ўгія),
				'few' => q(маўрытанскія ўгіі),
				'many' => q(маўрытанскіх угій),
				'one' => q(маўрытанская ўгія),
				'other' => q(маўрытанскай ўгіі),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(маўрыкійская рупія),
				'few' => q(маўрыкійскія рупіі),
				'many' => q(маўрыкійскіх рупій),
				'one' => q(маўрыкійская рупія),
				'other' => q(маўрыкійскай рупіі),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(мальдыўская руфія),
				'few' => q(мальдыўскія руфіі),
				'many' => q(мальдыўскіх руфій),
				'one' => q(мальдыўская руфія),
				'other' => q(мальдыўскай руфіі),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(малавійская квача),
				'few' => q(малавійскія квачы),
				'many' => q(малавійскіх квач),
				'one' => q(малавійская квача),
				'other' => q(малавійскай квачы),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(мексіканскае песа),
				'few' => q(мексіканскія песа),
				'many' => q(мексіканскіх песа),
				'one' => q(мексіканскае песа),
				'other' => q(мексіканскага песа),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(малайзійскі рынгіт),
				'few' => q(малайзійскія рынгіты),
				'many' => q(малайзійскіх рынгітаў),
				'one' => q(малайзійскі рынгіт),
				'other' => q(малайзійскага рынгіта),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(мазамбікскі метыкал),
				'few' => q(мазамбікскія метыкалы),
				'many' => q(мазамбікскіх метыкалаў),
				'one' => q(мазамбікскі метыкал),
				'other' => q(мазамбікскага метыкала),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(намібійскі долар),
				'few' => q(намібійскія долары),
				'many' => q(намібійскіх долараў),
				'one' => q(намібійскі долар),
				'other' => q(намібійскага долара),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(нігерыйская найра),
				'few' => q(нігерыйскія найры),
				'many' => q(нігерыйскіх найр),
				'one' => q(нігерыйская найра),
				'other' => q(нігерыйскай найры),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(нікарагуанская кордаба),
				'few' => q(нікарагуанскія кордабы),
				'many' => q(нікарагуанскіх кордаб),
				'one' => q(нікарагуанская кордаба),
				'other' => q(нікарагуанскай кордабы),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(нарвежская крона),
				'few' => q(нарвежскія кроны),
				'many' => q(нарвежскіх крон),
				'one' => q(нарвежская крона),
				'other' => q(нарвежскай кроны),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(непальская рупія),
				'few' => q(непальскія рупіі),
				'many' => q(непальскіх рупій),
				'one' => q(непальская рупія),
				'other' => q(непальскай рупіі),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(новазеландскі долар),
				'few' => q(новазеландскія долары),
				'many' => q(новазеландскіх долараў),
				'one' => q(новазеландскі долар),
				'other' => q(новазеландскага долара),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(аманскі рыал),
				'few' => q(аманскія рыалы),
				'many' => q(аманскіх рыалаў),
				'one' => q(аманскі рыал),
				'other' => q(аманска рыала),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(панамскае бальбоа),
				'few' => q(панамскія бальбоа),
				'many' => q(панамскіх бальбоа),
				'one' => q(панамскае бальбоа),
				'other' => q(панамскага бальбоа),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(перуанскі соль),
				'few' => q(перуанскія солі),
				'many' => q(перуанскіх соляў),
				'one' => q(перуанскі соль),
				'other' => q(перуанскага соля),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(кіна),
				'few' => q(кіна),
				'many' => q(кіна),
				'one' => q(кіна),
				'other' => q(кіна),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(філіпінскае песа),
				'few' => q(філіпінскія песа),
				'many' => q(філіпінскіх песа),
				'one' => q(філіпінскае песа),
				'other' => q(філіпінскага песа),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(пакістанская рупія),
				'few' => q(пакістанскія рупіі),
				'many' => q(пакістанскіх рупій),
				'one' => q(пакістанская рупія),
				'other' => q(пакістанскай рупіі),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(польскі злоты),
				'few' => q(польскія злотыя),
				'many' => q(польскіх злотых),
				'one' => q(польскі злоты),
				'other' => q(польскага злотага),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(парагвайскі гуарані),
				'few' => q(парагвайскія гуарані),
				'many' => q(парагвайскіх гуарані),
				'one' => q(парагвайскі гуарані),
				'other' => q(парагвайскага гуарані),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(катарскі рыал),
				'few' => q(катарскія рыалы),
				'many' => q(катарскіх рыалаў),
				'one' => q(катарскі рыал),
				'other' => q(катарскага рыала),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(румынскі лей),
				'few' => q(румынскія леі),
				'many' => q(румынскіх леяў),
				'one' => q(румынскі лей),
				'other' => q(румынскага лея),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(сербскі дынар),
				'few' => q(сербскія дынары),
				'many' => q(сербскіх дынараў),
				'one' => q(сербскі дынар),
				'other' => q(сербскага дынара),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(расійскі рубель),
				'few' => q(расійскія рублі),
				'many' => q(расійскіх рублёў),
				'one' => q(расійскі рубель),
				'other' => q(расійскага рубля),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(руандыйскі франк),
				'few' => q(руандыйскія франкі),
				'many' => q(руандыйскіх франкаў),
				'one' => q(руандыйскі франк),
				'other' => q(руандыйскага франка),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(саудаўскі рыял),
				'few' => q(саудаўскія рыялы),
				'many' => q(саудаўскіх рыялаў),
				'one' => q(саудаўскі рыял),
				'other' => q(саудаўскага рыяла),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(долар Саламонавых астравоў),
				'few' => q(долар Саламонавых астравоў),
				'many' => q(долараў Саламонавых астравоў),
				'one' => q(долар Саламонавых астравоў),
				'other' => q(долара Саламонавых астравоў),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(сейшэльская рупія),
				'few' => q(сейшэльскія рупіі),
				'many' => q(сейшэльскіх рупій),
				'one' => q(сейшэльская рупія),
				'other' => q(сейшэльскай рупіі),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(суданскі фунт),
				'few' => q(суданскія фунты),
				'many' => q(суданскіх фунтаў),
				'one' => q(суданскі фунт),
				'other' => q(суданскага фунта),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(шведская крона),
				'few' => q(шведскія кроны),
				'many' => q(шведскіх крон),
				'one' => q(шведская крона),
				'other' => q(шведскай кроны),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(сінгапурскі долар),
				'few' => q(сінгапурскія долары),
				'many' => q(сінгапурскіх долараў),
				'one' => q(сінгапурскі долар),
				'other' => q(сінгапурскага долара),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(фунт Святой Алены),
				'few' => q(фунты Святой Алены),
				'many' => q(фунтаў Святой Алены),
				'one' => q(фунт Святой Алены),
				'other' => q(фунта Святой Алены),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(леонэ),
				'few' => q(леонэ),
				'many' => q(леонэ),
				'one' => q(леонэ),
				'other' => q(леонэ),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(самалійскі шылінг),
				'few' => q(самалійскія шылінгі),
				'many' => q(самалійскіх шылінгаў),
				'one' => q(самалійскі шылінг),
				'other' => q(самалійскага шылінга),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(сурынамскі долар),
				'few' => q(сурынамскія долары),
				'many' => q(сурынамскіх долараў),
				'one' => q(сурынамскі долар),
				'other' => q(сурынамскага долара),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(паўднёвасуданскі фунт),
				'few' => q(паўднёвасуданскія фунты),
				'many' => q(паўднёвасуданскіх фунтаў),
				'one' => q(паўднёвасуданскі фунт),
				'other' => q(паўднёвасуданскага фунта),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(добра Сан-Тамэ і Прынсіпі \(1977–2017\)),
				'few' => q(добры Сан-Тамэ і Прынсіпі \(1977–2017\)),
				'many' => q(добраў Сан-Тамэ і Прынсіпі \(1977–2017\)),
				'one' => q(добра Сан-Тамэ і Прынсіпі \(1977–2017\)),
				'other' => q(добры Сан-Тамэ і Прынсіпі \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(добра Сан-Тамэ і Прынсіпі),
				'few' => q(добры Сан-Тамэ і Прынсіпі),
				'many' => q(добраў Сан-Тамэ і Прынсіпі),
				'one' => q(добра Сан-Тамэ і Прынсіпі),
				'other' => q(добры Сан-Тамэ і Прынсіпі),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(сірыйскі фунт),
				'few' => q(сірыйскія фунты),
				'many' => q(сірыйскіх фунтаў),
				'one' => q(сірыйскі фунт),
				'other' => q(сірыйскага фунта),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(свазілендскі лілангені),
				'few' => q(свазілендскія лілангені),
				'many' => q(свазілендскіх лілангені),
				'one' => q(свазілендскі лілангені),
				'other' => q(свазілендскага лілангені),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(тайскі бат),
				'few' => q(тайскія баты),
				'many' => q(тайскіх батаў),
				'one' => q(тайскі бат),
				'other' => q(тайскага бата),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(таджыкскі самані),
				'few' => q(таджыкскія самані),
				'many' => q(таджыкскіх самані),
				'one' => q(таджыкскі самані),
				'other' => q(таджыкскага самані),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(туркменскі манат),
				'few' => q(туркменскія манаты),
				'many' => q(туркменскіх манатаў),
				'one' => q(туркменскі манат),
				'other' => q(туркменскага маната),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(туніскі дынар),
				'few' => q(туніскія дынары),
				'many' => q(туніскіх дынараў),
				'one' => q(туніскі дынар),
				'other' => q(туніскага дынара),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(танганская паанга),
				'few' => q(танганскія паангі),
				'many' => q(танганскіх паанг),
				'one' => q(танганская паанга),
				'other' => q(танганскай паангі),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(турэцкая ліра),
				'few' => q(турэцкія ліры),
				'many' => q(турэцкіх лір),
				'one' => q(турэцкая ліра),
				'other' => q(турэцкай ліры),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(долар Трынідада і Табага),
				'few' => q(долары Трынідада і Табага),
				'many' => q(долараў Трынідада і Табага),
				'one' => q(долар Трынідада і Табага),
				'other' => q(долара Трынідада і Табага),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(новы тайваньскі долар),
				'few' => q(новыя тайваньскія долары),
				'many' => q(новых тайваньскіх долараў),
				'one' => q(новы тайваньскі долар),
				'other' => q(новага тайваньскага долара),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(танзанійскі шылінг),
				'few' => q(танзанійскія шылінгі),
				'many' => q(танзанійскіх шылінгаў),
				'one' => q(танзанійскі шылінг),
				'other' => q(танзанійскага шылінга),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(украінская грыўня),
				'few' => q(украінскія грыўні),
				'many' => q(украінскіх грыўняў),
				'one' => q(украінская грыўня),
				'other' => q(украінскай грыўні),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(угандыйскі шылінг),
				'few' => q(угандыйскія шылінгі),
				'many' => q(угандыйскіх шылінгаў),
				'one' => q(угандыйскі шылінг),
				'other' => q(угандыйскага шылінга),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(долар ЗША),
				'few' => q(долары ЗША),
				'many' => q(долараў ЗША),
				'one' => q(долар ЗША),
				'other' => q(долара ЗША),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(уругвайскае песа),
				'few' => q(уругвайскія песа),
				'many' => q(уругвайскіх песа),
				'one' => q(уругвайскае песа),
				'other' => q(уругвайскага песа),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(узбекскі сум),
				'few' => q(узбекскія сумы),
				'many' => q(узбекскіх сумаў),
				'one' => q(узбекскі сум),
				'other' => q(узбекскага сума),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(венесуальскі балівар \(2008–2018\)),
				'few' => q(венесуальскія балівары \(2008–2018\)),
				'many' => q(венесуальскіх балівараў \(2008–2018\)),
				'one' => q(венесуальскі балівар \(2008–2018\)),
				'other' => q(венесуальскага балівара \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(венесуальскі балівар),
				'few' => q(венесуальскія балівары),
				'many' => q(венесуальскіх балівараў),
				'one' => q(венесуальскі балівар),
				'other' => q(венесуальскага балівара),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(в’етнамскі донг),
				'few' => q(в’етнамскія донгі),
				'many' => q(в’етнамскіх донгаў),
				'one' => q(в’етнамскі донг),
				'other' => q(в’етнамскага донга),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(вату),
				'few' => q(вату),
				'many' => q(вату),
				'one' => q(вату),
				'other' => q(вату),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(самаанская тала),
				'few' => q(самаанскія талы),
				'many' => q(самаанскіх тал),
				'one' => q(самаанская тала),
				'other' => q(самаанскай талы),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(цэнтральнаафрыканскі франк КФА),
				'few' => q(цэнтральнаафрыканскія франкі КФА),
				'many' => q(цэнтральнаафрыканскіх франкаў КФА),
				'one' => q(цэнтральнаафрыканскі франк КФА),
				'other' => q(цэнтральнаафрыканскага франка КФА),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(усходнекарыбскі долар),
				'few' => q(усходнекарыбскія долары),
				'many' => q(усходнекарыбскіх долараў),
				'one' => q(усходнекарыбскі долар),
				'other' => q(усходнекарыбскага долара),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(заходнеафрыканскі франк КФА),
				'few' => q(заходнеафрыканскія франкі КФА),
				'many' => q(заходнеафрыканскіх франкаў КФА),
				'one' => q(заходнеафрыканскі франк КФА),
				'other' => q(заходнеафрыканскага франка КФА),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(французскі ціхаакіянскі франк),
				'few' => q(французскія ціхаакіянскія франкі),
				'many' => q(французскіх ціхаакіянскіх франкаў),
				'one' => q(французскі ціхаакіянскі франк),
				'other' => q(французскага ціхаакіянскага франка),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(невядомая валюта),
				'few' => q(невядомай валюты),
				'many' => q(невядомай валюты),
				'one' => q(невядомай валюты),
				'other' => q(невядомай валюты),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(еменскі рыал),
				'few' => q(еменскія рыалы),
				'many' => q(еменскіх рыалаў),
				'one' => q(еменскі рыал),
				'other' => q(еменскага рыала),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(паўднёваафрыканскі ранд),
				'few' => q(паўднёваафрыканскія ранды),
				'many' => q(паўднёваафрыканскіх рандаў),
				'one' => q(паўднёваафрыканскі ранд),
				'other' => q(паўднёваафрыканскага ранда),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(замбійская квача),
				'few' => q(замбійскія квачы),
				'many' => q(замбійскіх квач),
				'one' => q(замбійская квача),
				'other' => q(замбійскай квачы),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'gregorian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'сту',
							'лют',
							'сак',
							'кра',
							'мая',
							'чэр',
							'ліп',
							'жні',
							'вер',
							'кас',
							'ліс',
							'сне'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'с',
							'л',
							'с',
							'к',
							'м',
							'ч',
							'л',
							'ж',
							'в',
							'к',
							'л',
							'с'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'студзеня',
							'лютага',
							'сакавіка',
							'красавіка',
							'мая',
							'чэрвеня',
							'ліпеня',
							'жніўня',
							'верасня',
							'кастрычніка',
							'лістапада',
							'снежня'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'сту',
							'лют',
							'сак',
							'кра',
							'май',
							'чэр',
							'ліп',
							'жні',
							'вер',
							'кас',
							'ліс',
							'сне'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'с',
							'л',
							'с',
							'к',
							'м',
							'ч',
							'л',
							'ж',
							'в',
							'к',
							'л',
							'с'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'студзень',
							'люты',
							'сакавік',
							'красавік',
							'май',
							'чэрвень',
							'ліпень',
							'жнівень',
							'верасень',
							'кастрычнік',
							'лістапад',
							'снежань'
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
						mon => 'пн',
						tue => 'аў',
						wed => 'ср',
						thu => 'чц',
						fri => 'пт',
						sat => 'сб',
						sun => 'нд'
					},
					narrow => {
						mon => 'п',
						tue => 'а',
						wed => 'с',
						thu => 'ч',
						fri => 'п',
						sat => 'с',
						sun => 'н'
					},
					short => {
						mon => 'пн',
						tue => 'аў',
						wed => 'ср',
						thu => 'чц',
						fri => 'пт',
						sat => 'сб',
						sun => 'нд'
					},
					wide => {
						mon => 'панядзелак',
						tue => 'аўторак',
						wed => 'серада',
						thu => 'чацвер',
						fri => 'пятніца',
						sat => 'субота',
						sun => 'нядзеля'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'пн',
						tue => 'аў',
						wed => 'ср',
						thu => 'чц',
						fri => 'пт',
						sat => 'сб',
						sun => 'нд'
					},
					narrow => {
						mon => 'п',
						tue => 'а',
						wed => 'с',
						thu => 'ч',
						fri => 'п',
						sat => 'с',
						sun => 'н'
					},
					short => {
						mon => 'пн',
						tue => 'аў',
						wed => 'ср',
						thu => 'чц',
						fri => 'пт',
						sat => 'сб',
						sun => 'нд'
					},
					wide => {
						mon => 'панядзелак',
						tue => 'аўторак',
						wed => 'серада',
						thu => 'чацвер',
						fri => 'пятніца',
						sat => 'субота',
						sun => 'нядзеля'
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
					abbreviated => {0 => '1-шы кв.',
						1 => '2-гі кв.',
						2 => '3-ці кв.',
						3 => '4-ты кв.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-шы квартал',
						1 => '2-гі квартал',
						2 => '3-ці квартал',
						3 => '4-ты квартал'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1-шы кв.',
						1 => '2-гі кв.',
						2 => '3-ці кв.',
						3 => '4-ты кв.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-шы квартал',
						1 => '2-гі квартал',
						2 => '3-ці квартал',
						3 => '4-ты квартал'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'narrow' => {
					'am' => q{am},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'abbreviated' => {
					'pm' => q{PM},
					'am' => q{AM},
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
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'да н.э.',
				'1' => 'н.э.'
			},
			wide => {
				'0' => 'да нараджэння Хрыстова',
				'1' => 'ад нараджэння Хрыстова'
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
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d.M.yy},
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y 'г'.},
			'long' => q{d MMMM y 'г'.},
			'medium' => q{d.MM.y},
			'short' => q{d.MM.yy},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss, zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'generic' => {
			'full' => q{{1} 'у' {0}},
			'long' => q{{1} 'у' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'у' {0}},
			'long' => q{{1} 'у' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y 'г'. G},
			GyMMM => q{LLL y 'г'. G},
			GyMMMEd => q{E, d MMM y 'г'. G},
			GyMMMd => q{d MMM y 'г'. G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d.M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{W 'тыдзень' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.M},
			d => q{d},
			h => q{hh a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm.ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{LLL y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w 'тыдзень' Y},
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
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			M => q{L},
			MEd => q{E, d.M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d.M},
			d => q{d},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E, d.M.y G},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'buddhist' => {
			Ed => q{E, d},
			Gy => q{G y},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			M => q{L},
			MEd => q{E, d.M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMd => q{d MMM},
			Md => q{d.M},
			d => q{d},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			y => q{G y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y G},
			yMMMEd => q{E, d MMM y G},
			yMMMd => q{d MMM y G},
			yMd => q{d.M.y},
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
		'gregorian' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d.M – E, d.M},
				d => q{E, d.M – E, d.M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
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
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y},
				d => q{E, d.M.y – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{LLL–LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
		'generic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d.M – E, d.M},
				d => q{E, d.M – E, d.M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d.M – d.M},
				d => q{d.M – d.M},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
			h => {
				h => q{h–h a},
			},
			hm => {
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M.y – M.y G},
				y => q{M.y – M.y G},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y G},
				d => q{E, d.M.y – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{LLL–LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{LLLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y G},
				d => q{d.M.y – d.M.y G},
				y => q{d.M.y – d.M.y G},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH.mm;-HH.mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q(Час: {0}),
		regionFormat => q(Летні час: {0}),
		regionFormat => q(Стандартны час: {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Афганістанскі час#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Абіджан#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Акра#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Адыс-Абеба#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Алжыр#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Асмара#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Бамако#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Бангі#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Банжул#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Бісау#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Блантайр#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Бразавіль#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Бужумбура#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Каір#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Касабланка#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Сеўта#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Конакры#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Дакар#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Дар-эс-Салам#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Джыбуці#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Дуала#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Эль-Аюн#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Фрытаўн#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Габаронэ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Харарэ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Яганэсбург#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Джуба#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Кампала#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Хартум#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Кігалі#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Кіншаса#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Лагас#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Лібрэвіль#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Ламэ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Луанда#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Лубумбашы#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Лусака#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Малаба#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Мапуту#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Масеру#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Мбабанэ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Магадыша#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Манровія#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Найробі#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Нджамена#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Ніямей#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Нуакшот#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Уагадугу#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Порта-Нова#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Сан-Тамэ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Трыпалі#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Туніс#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Віндхук#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Цэнтральнаафрыканскі час#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Усходнеафрыканскі час#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Паўднёваафрыканскі час#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Заходнеафрыканскі летні час#,
				'generic' => q#Заходнеафрыканскі час#,
				'standard' => q#Заходнеафрыканскі стандартны час#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Летні час Аляскі#,
				'generic' => q#Час Аляскі#,
				'standard' => q#Стандартны час Аляскі#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Амазонскі летні час#,
				'generic' => q#Амазонскі час#,
				'standard' => q#Амазонскі стандартны час#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Адак#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Анкарыдж#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ангілья#,
		},
		'America/Antigua' => {
			exemplarCity => q#Антыгуа#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Арагуаіна#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ла-Рыёха#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Рыа-Гальегас#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Сальта#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Сан-Хуан#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Сан-Луіс#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Тукуман#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ушуая#,
		},
		'America/Aruba' => {
			exemplarCity => q#Аруба#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Асунсьён#,
		},
		'America/Bahia' => {
			exemplarCity => q#Баія#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Баія-дэ-Бандэрас#,
		},
		'America/Barbados' => {
			exemplarCity => q#Барбадас#,
		},
		'America/Belem' => {
			exemplarCity => q#Белен#,
		},
		'America/Belize' => {
			exemplarCity => q#Беліз#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Бланк-Саблон#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Боа-Віста#,
		},
		'America/Bogota' => {
			exemplarCity => q#Багата#,
		},
		'America/Boise' => {
			exemplarCity => q#Бойсэ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Буэнас-Айрэс#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Кембрыдж-Бей#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Кампу-Гранды#,
		},
		'America/Cancun' => {
			exemplarCity => q#Канкун#,
		},
		'America/Caracas' => {
			exemplarCity => q#Каракас#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Катамарка#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Каена#,
		},
		'America/Cayman' => {
			exemplarCity => q#Кайманавы астравы#,
		},
		'America/Chicago' => {
			exemplarCity => q#Чыкага#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Чыўаўа#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Атыкокан#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Кордава#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Коста-Рыка#,
		},
		'America/Creston' => {
			exemplarCity => q#Крэстан#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Куяба#,
		},
		'America/Curacao' => {
			exemplarCity => q#Кюрасаа#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Данмарксхаўн#,
		},
		'America/Dawson' => {
			exemplarCity => q#Доўсан#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Досан-Крык#,
		},
		'America/Denver' => {
			exemplarCity => q#Дэнвер#,
		},
		'America/Detroit' => {
			exemplarCity => q#Дэтройт#,
		},
		'America/Dominica' => {
			exemplarCity => q#Дамініка#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Эдмантан#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Эйрунэпе#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Сальвадор#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Форт-Нельсан#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Фарталеза#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Глэйс-Бэй#,
		},
		'America/Godthab' => {
			exemplarCity => q#Нук#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Гус-Бэй#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Гранд-Цёрк#,
		},
		'America/Grenada' => {
			exemplarCity => q#Грэнада#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Гвадэлупа#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Гватэмала#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Гуаякіль#,
		},
		'America/Guyana' => {
			exemplarCity => q#Гаяна#,
		},
		'America/Halifax' => {
			exemplarCity => q#Галіфакс#,
		},
		'America/Havana' => {
			exemplarCity => q#Гавана#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Эрмасілья#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Нокс, Індыяна#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Марэнга, Індыяна#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Пітэрсберг, Індыяна#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Тэл Сіці, Індыяна#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Віві, Індыяна#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Вінсенс, Індыяна#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Уінамак, Індыяна#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Індыянапаліс#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Інувік#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ікалуіт#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Ямайка#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Жужуй#,
		},
		'America/Juneau' => {
			exemplarCity => q#Джуна#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Мантысела, Кентукі#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Кралендэйк#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Ла-Пас#,
		},
		'America/Lima' => {
			exemplarCity => q#Ліма#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Лос-Анджэлес#,
		},
		'America/Louisville' => {
			exemplarCity => q#Луісвіл#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Лоўэр Прынсіз Квортэр#,
		},
		'America/Maceio' => {
			exemplarCity => q#Масеё#,
		},
		'America/Managua' => {
			exemplarCity => q#Манагуа#,
		},
		'America/Manaus' => {
			exemplarCity => q#Манаўс#,
		},
		'America/Marigot' => {
			exemplarCity => q#Марыго#,
		},
		'America/Martinique' => {
			exemplarCity => q#Марцініка#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Матаморас#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Масатлан#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Мендоса#,
		},
		'America/Menominee' => {
			exemplarCity => q#Меноміні#,
		},
		'America/Merida' => {
			exemplarCity => q#Мерыда#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Метлакатла#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Мехіка#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Мікелон#,
		},
		'America/Moncton' => {
			exemplarCity => q#Манктан#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Мантэрэй#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Мантэвідэа#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Мантсерат#,
		},
		'America/Nassau' => {
			exemplarCity => q#Насаў#,
		},
		'America/New_York' => {
			exemplarCity => q#Нью-Ёрк#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Ніпіган#,
		},
		'America/Nome' => {
			exemplarCity => q#Ном#,
		},
		'America/Noronha' => {
			exemplarCity => q#Наронья#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Б’юла, Паўночная Дакота#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Сентэр, Паўночная Дакота#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Нью-Сейлем, Паўночная Дакота#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ахінага#,
		},
		'America/Panama' => {
			exemplarCity => q#Панама#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Пангніртунг#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Парамарыба#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Фінікс#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Порт-о-Прэнс#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Порт-оф-Спейн#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Порту-Велью#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Пуэрта-Рыка#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Пунта Арэнас#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Рэйні-Рывер#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Ранкін-Інлет#,
		},
		'America/Recife' => {
			exemplarCity => q#Рэсіфі#,
		},
		'America/Regina' => {
			exemplarCity => q#Рэджайна#,
		},
		'America/Resolute' => {
			exemplarCity => q#Рэзальют#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Рыу-Бранку#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Санта-Ісабель#,
		},
		'America/Santarem' => {
			exemplarCity => q#Сантарэн#,
		},
		'America/Santiago' => {
			exemplarCity => q#Сант’яга#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Санта-Дамінга#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Сан-Паўлу#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ітакортаарміут#,
		},
		'America/Sitka' => {
			exemplarCity => q#Сітка#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Сен-Бартэльмі#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Сент-Джонс#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Сент-Кітс#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Сент-Люсія#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Сент-Томас#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Сент-Вінсент#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Свіфт-Керэнт#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Тэгусігальпа#,
		},
		'America/Thule' => {
			exemplarCity => q#Каанаак#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Тандэр-Бэй#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Тыхуана#,
		},
		'America/Toronto' => {
			exemplarCity => q#Таронта#,
		},
		'America/Tortola' => {
			exemplarCity => q#Тартола#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Ванкувер#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Уайтхорс#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Вініпег#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Якутат#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Йелаўнайф#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Паўночнаамерыканскі цэнтральны летні час#,
				'generic' => q#Паўночнаамерыканскі цэнтральны час#,
				'standard' => q#Паўночнаамерыканскі цэнтральны стандартны час#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Паўночнаамерыканскі ўсходні летні час#,
				'generic' => q#Паўночнаамерыканскі ўсходні час#,
				'standard' => q#Паўночнаамерыканскі ўсходні стандартны час#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Паўночнаамерыканскі горны летні час#,
				'generic' => q#Паўночнаамерыканскі горны час#,
				'standard' => q#Паўночнаамерыканскі горны стандартны час#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ціхаакіянскі летні час#,
				'generic' => q#Ціхаакіянскі час#,
				'standard' => q#Ціхаакіянскі стандартны час#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Кэйсі#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Дэйвіс#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Дзюмон-Дзюрвіль#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Макуоры#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Моўсан#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Мак-Мерда#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Палмер#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Ротэра#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Сёва#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Трол#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Васток#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Летні час Апіі#,
				'generic' => q#Час Апіі#,
				'standard' => q#Стандартны час Апіі#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Летні час Саудаўскай Аравіі#,
				'generic' => q#Час Саудаўскай Аравіі#,
				'standard' => q#Стандартны час Саудаўскай Аравіі#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Лонгйір#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Аргенцінскі летні час#,
				'generic' => q#Аргенцінскі час#,
				'standard' => q#Аргенцінскі стандартны час#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Летні час Заходняй Аргенціны#,
				'generic' => q#Час Заходняй Аргенціны#,
				'standard' => q#Стандартны час Заходняй Аргенціны#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Летні час Арменіі#,
				'generic' => q#Час Арменіі#,
				'standard' => q#Стандартны час Арменіі#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Адэн#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Алматы#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Аман (горад)#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Анадыр#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Актау#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Актабэ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ашгабад#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Атырау#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Багдад#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Бахрэйн#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Баку#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Бангкок#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Барнаул#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Бейрут#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Бішкек#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Бруней#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Калькута#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Чыта#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Чайбалсан#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Каломба#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Дамаск#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Дака#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Дылі#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Дубай#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Душанбэ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Фамагуста#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Газа#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Хеўрон#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Ганконг#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Хоўд#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Іркуцк#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Джакарта#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Джаяпура#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Іерусалім#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Кабул#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Камчатка#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Карачы#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Катманду#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Хандыга#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Краснаярск#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Куала-Лумпур#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Кучынг#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Кувейт#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Макаа#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Магадан#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Макасар#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Маніла#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Маскат#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Нікасія#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Новакузнецк#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Новасібірск#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Омск#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Уральск#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Пнампень#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Пантыянак#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Пхеньян#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Катар#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Кзыларда#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Рангун#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Эр-Рыяд#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Хашымін#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Сахалін#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Самарканд#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Сеул#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Шанхай#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Сінгапур#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Сярэднекалымск#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Тайбэй#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Ташкент#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Тбілісі#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Тэгеран#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Тхімпху#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Токіа#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Томск#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Улан-Батар#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Урумчы#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Вусць-Нера#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#В’енцьян#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Уладзівасток#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Якуцк#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Екацярынбург#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ерэван#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Атлантычны летні час#,
				'generic' => q#Атлантычны час#,
				'standard' => q#Атлантычны стандартны час#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Азорскія астравы#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Бермудскія астравы#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Канарскія астравы#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Каба-Вердэ#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Фарэрскія астравы#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Мадэйра#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Рэйк’явік#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Паўднёвая Джорджыя#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Востраў Святой Алены#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Стэнлі#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Адэлаіда#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Брысбен#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Брокен-Хіл#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Керы#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Дарвін#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Юкла#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Хобарт#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Ліндэман#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Лорд-Хау#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Мельбурн#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Перт#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Сідней#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Летні час цэнтральнай Аўстраліі#,
				'generic' => q#Час цэнтральнай Аўстраліі#,
				'standard' => q#Стандартны час цэнтральнай Аўстраліі#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Летні цэнтральна-заходні час Аўстраліі#,
				'generic' => q#Цэнтральна-заходні час Аўстраліі#,
				'standard' => q#Стандартны цэнтральна-заходні час Аўстраліі#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Летні час усходняй Аўстраліі#,
				'generic' => q#Час усходняй Аўстраліі#,
				'standard' => q#Стандартны час усходняй Аўстраліі#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Летні час заходняй Аўстраліі#,
				'generic' => q#Час заходняй Аўстраліі#,
				'standard' => q#Стандартны час заходняй Аўстраліі#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Летні час Азербайджана#,
				'generic' => q#Час Азербайджана#,
				'standard' => q#Стандартны час Азербайджана#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Летні час Азорскіх астравоў#,
				'generic' => q#Час Азорскіх астравоў#,
				'standard' => q#Стандартны час Азорскіх астравоў#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Летні час Бангладэш#,
				'generic' => q#Час Бангладэш#,
				'standard' => q#Стандартны час Бангладэш#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Час Бутана#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Балівійскі час#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Бразільскі летні час#,
				'generic' => q#Бразільскі час#,
				'standard' => q#Бразільскі стандартны час#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Час Брунея#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Летні час Каба-Вердэ#,
				'generic' => q#Час Каба-Вердэ#,
				'standard' => q#Стандартны час Каба-Вердэ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Час Чамора#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Летні час Чатэма#,
				'generic' => q#Час Чатэма#,
				'standard' => q#Стандартны час Чатэма#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Чылійскі летні час#,
				'generic' => q#Чылійскі час#,
				'standard' => q#Чылійскі стандартны час#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Летні час Кітая#,
				'generic' => q#Час Кітая#,
				'standard' => q#Стандартны час Кітая#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Летні час Чайбалсана#,
				'generic' => q#Час Чайбалсана#,
				'standard' => q#Стандартны час Чайбалсана#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Час вострава Каляд#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Час Какосавых астравоў#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Калумбійскі летні час#,
				'generic' => q#Калумбійскі час#,
				'standard' => q#Калумбійскі стандартны час#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Паўлетні час астравоў Кука#,
				'generic' => q#Час астравоў Кука#,
				'standard' => q#Стандартны час астравоў Кука#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Летні час Кубы#,
				'generic' => q#Час Кубы#,
				'standard' => q#Стандартны час Кубы#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Час станцыі Дэйвіс#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Час станцыі Дзюмон-Дзюрвіль#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Час Усходняга Тымора#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Летні час вострава Пасхі#,
				'generic' => q#Час вострава Пасхі#,
				'standard' => q#Стандартны час вострава Пасхі#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Эквадорскі час#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Універсальны каардынаваны час#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Невядомы горад#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Амстэрдам#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Андора#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Астрахань#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Афіны#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Бялград#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Берлін#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Браціслава#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Брусель#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Бухарэст#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Будапешт#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Бюзінген#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Кішынёў#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Капенгаген#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Дублін#,
			long => {
				'daylight' => q#Ірландскі стандартны час#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Гібралтар#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Гернсі#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Хельсінкі#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Востраў Мэн#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Стамбул#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Джэрсі#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Калінінград#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Кіеў#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Кіраў#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Лісабон#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Любляна#,
		},
		'Europe/London' => {
			exemplarCity => q#Лондан#,
			long => {
				'daylight' => q#Брытанскі летні час#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Люксембург#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Мадрыд#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Мальта#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Марыехамн#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Мінск#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Манака#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Масква#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Осла#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Парыж#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Падгорыца#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Прага#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Рыга#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Рым#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Самара#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Сан-Марына#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Сараева#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Саратаў#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Сімферопаль#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Скоп’е#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Сафія#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Стакгольм#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Талін#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Тырана#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ульянаўск#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ужгарад#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Вадуц#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Ватыкан#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Вена#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Вільнюс#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Валгаград#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Варшава#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Заграб#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Запарожжа#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Цюрых#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Цэнтральнаеўрапейскі летні час#,
				'generic' => q#Цэнтральнаеўрапейскі час#,
				'standard' => q#Цэнтральнаеўрапейскі стандартны час#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Усходнееўрапейскі летні час#,
				'generic' => q#Усходнееўрапейскі час#,
				'standard' => q#Усходнееўрапейскі стандартны час#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Далёкаўсходнееўрапейскі час#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Заходнееўрапейскі летні час#,
				'generic' => q#Заходнееўрапейскі час#,
				'standard' => q#Заходнееўрапейскі стандартны час#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Летні час Фалклендскіх астравоў#,
				'generic' => q#Час Фалклендскіх астравоў#,
				'standard' => q#Стандартны час Фалклендскіх астравоў#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Летні час Фіджы#,
				'generic' => q#Час Фіджы#,
				'standard' => q#Стандартны час Фіджы#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Час Французскай Гвіяны#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Час Французскай паўднёва-антарктычнай тэрыторыі#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Час па Грынвічы#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Стандартны час Галапагоскіх астравоў#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Час астравоў Гамб’е#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Грузінскі летні час#,
				'generic' => q#Грузінскі час#,
				'standard' => q#Грузінскі стандартны час#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Час астравоў Гілберта#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Летні час Усходняй Грэнландыі#,
				'generic' => q#Час Усходняй Грэнландыі#,
				'standard' => q#Стандартны час Усходняй Грэнландыі#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Летні час Заходняй Грэнландыі#,
				'generic' => q#Час Заходняй Грэнландыі#,
				'standard' => q#Стандартны час Заходняй Грэнландыі#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Час Персідскага заліва#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Час Гаяны#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Гавайска-Алеуцкі летні час#,
				'generic' => q#Гавайска-Алеуцкі час#,
				'standard' => q#Гавайска-Алеуцкі стандартны час#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Летні час Ганконга#,
				'generic' => q#Час Ганконга#,
				'standard' => q#Стандартны час Ганконга#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Летні час Хоўда#,
				'generic' => q#Час Хоўда#,
				'standard' => q#Стандартны час Хоўда#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Час Індыі#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Антананарыву#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Чагас#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Востраў Каляд#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Какосавыя астравы#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Камор#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Кергелен#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Маэ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Мальдывы#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Маўрыкій#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Маёта#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Рэюньён#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Час Індыйскага акіяна#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Індакітайскі час#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Цэнтральнаінданезійскі час#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Усходнеінданезійскі час#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Заходнеінданезійскі час#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Іранскі летні час#,
				'generic' => q#Іранскі час#,
				'standard' => q#Іранскі стандартны час#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Іркуцкі летні час#,
				'generic' => q#Іркуцкі час#,
				'standard' => q#Іркуцкі стандартны час#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ізраільскі летні час#,
				'generic' => q#Ізраільскі час#,
				'standard' => q#Ізраільскі стандартны час#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Летні час Японіі#,
				'generic' => q#Час Японіі#,
				'standard' => q#Стандартны час Японіі#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Усходнеказахстанскі час#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Заходнеказахстанскі час#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Летні час Карэі#,
				'generic' => q#Час Карэі#,
				'standard' => q#Стандартны час Карэі#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Час астравоў Кусаіе#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Краснаярскі летні час#,
				'generic' => q#Краснаярскі час#,
				'standard' => q#Краснаярскі стандартны час#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Час Кыргызстана#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Час астравоў Лайн#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Летні час Лорд-Хау#,
				'generic' => q#Час Лорд-Хау#,
				'standard' => q#Стандартны час Лорд-Хау#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Час вострава Макуоры#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Магаданскі летні час#,
				'generic' => q#Магаданскі час#,
				'standard' => q#Магаданскі стандартны час#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Час Малайзіі#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Час Мальдываў#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Час Маркізскіх астравоў#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Час Маршалавых астравоў#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Летні час Маўрыкія#,
				'generic' => q#Час Маўрыкія#,
				'standard' => q#Стандартны час Маўрыкія#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Час станцыі Моўсан#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Паўночна-заходні мексіканскі летні час#,
				'generic' => q#Паўночна-заходні мексіканскі час#,
				'standard' => q#Паўночна-заходні мексіканскі стандартны час#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Мексіканскі ціхаакіянскі летні час#,
				'generic' => q#Мексіканскі ціхаакіянскі час#,
				'standard' => q#Мексіканскі ціхаакіянскі стандатны час#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Летні час Улан-Батара#,
				'generic' => q#Час Улан-Батара#,
				'standard' => q#Стандартны час Улан-Батара#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Маскоўскі летні час#,
				'generic' => q#Маскоўскі час#,
				'standard' => q#Маскоўскі стандартны час#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Час М’янмы#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Час Науру#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Непальскі час#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Летні час Новай Каледоніі#,
				'generic' => q#Час Новай Каледоніі#,
				'standard' => q#Стандартны час Новай Каледоніі#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Летні час Новай Зеландыі#,
				'generic' => q#Час Новай Зеландыі#,
				'standard' => q#Стандартны час Новай Зеландыі#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ньюфаўндлендскі летні час#,
				'generic' => q#Ньюфаўндлендскі час#,
				'standard' => q#Ньюфаўндлендскі стандартны час#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Час Ніуэ#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Час вострава Норфалк#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Летні час Фернанду-ды-Наронья#,
				'generic' => q#Час Фернанду-ды-Наронья#,
				'standard' => q#Стандартны час Фернанду-ды-Наронья#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Новасібірскі летні час#,
				'generic' => q#Новасібірскі час#,
				'standard' => q#Новасібірскі стандартны час#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омскі летні час#,
				'generic' => q#Омскі час#,
				'standard' => q#Омскі стандартны час#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Апія#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Окленд#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Бугенвіль#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Чатэм#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Пасхі востраў#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Эфатэ#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Эндэрберы#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Факаофа#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Фіджы#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Фунафуці#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Галапагас#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Астравы Гамб’е#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Гуадалканал#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Гуам#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Ганалулу#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Джонстан#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Кірыцімаці#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Кусаіе#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Кваджалейн#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Маджура#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Маркізскія астравы#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Мідуэй#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Науру#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Ніуэ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Норфалк#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Нумеа#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Пага-Пага#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Палау#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Піткэрн#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Понпеі#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Порт-Морсбі#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Раратонга#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Сайпан#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Таіці#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Тарава#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Тангатапу#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Чуук#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Уэйк#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Уоліс#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Пакістанскі летні час#,
				'generic' => q#Пакістанскі час#,
				'standard' => q#Пакістанскі стандартны час#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Час Палау#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Час Папуа-Новай Гвінеі#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Летні час Парагвая#,
				'generic' => q#Час Парагвая#,
				'standard' => q#Стандартны час Парагвая#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Перуанскі летні час#,
				'generic' => q#Перуанскі час#,
				'standard' => q#Перуанскі стандартны час#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Філіпінскі летні час#,
				'generic' => q#Філіпінскі час#,
				'standard' => q#Філіпінскі стандартны час#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Час астравоў Фенікс#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Стандартны летні час Сен-П’ер і Мікелон#,
				'generic' => q#Час Сен-П’ер і Мікелон#,
				'standard' => q#Стандартны час Сен-П’ер і Мікелон#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Час вострава Піткэрн#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Час вострава Понпеі#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Пхеньянскі час#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Час Рэюньёна#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Час станцыі Ратэра#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалінскі летні час#,
				'generic' => q#Сахалінскі час#,
				'standard' => q#Сахалінскі стандартны час#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Летні час Самоа#,
				'generic' => q#Час Самоа#,
				'standard' => q#Стандартны час Самоа#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Час Сейшэльскіх астравоў#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Сінгапурскі час#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Час Саламонавых астравоў#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Час Паўднёвай Джорджыі#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Час Сурынама#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Час станцыі Сёва#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Час Таіці#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Летні час Тайбэя#,
				'generic' => q#Час Тайбэя#,
				'standard' => q#Стандартны час Тайбэя#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Час Таджыкістана#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Час Такелау#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Летні час Тонга#,
				'generic' => q#Час Тонга#,
				'standard' => q#Стандартны час Тонга#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Час Чуук#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Летні час Туркменістана#,
				'generic' => q#Час Туркменістана#,
				'standard' => q#Стандартны час Туркменістана#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Час Тувалу#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Уругвайскі летні час#,
				'generic' => q#Уругвайскі час#,
				'standard' => q#Уругвайскі стандартны час#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Летні час Узбекістана#,
				'generic' => q#Час Узбекістана#,
				'standard' => q#Стандартны час Узбекістана#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Летні час Вануату#,
				'generic' => q#Час Вануату#,
				'standard' => q#Стандартны час Вануату#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Венесуэльскі час#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Уладзівастоцкі летні час#,
				'generic' => q#Уладзівастоцкі час#,
				'standard' => q#Уладзівастоцкі стандартны час#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Валгаградскі летні час#,
				'generic' => q#Валгаградскі час#,
				'standard' => q#Валгаградскі стандартны час#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Час станцыі Васток#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Час вострава Уэйк#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Час астравоў Уоліс і Футуна#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Якуцкі летні час#,
				'generic' => q#Якуцкі час#,
				'standard' => q#Якуцкі стандартны час#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Екацярынбургскі летні час#,
				'generic' => q#Екацярынбургскі час#,
				'standard' => q#Екацярынбургскі стандартны час#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
