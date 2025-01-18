=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yue - Package for language Cantonese

=cut

package Locale::CLDR::Locales::Yue;
# This file auto generated from Data\common\main\yue.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-financial','spellout-cardinal','spellout-cardinal-alternate2','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'cardinal-twenties' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(二),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(二),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(第−→#,##0→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(第=#,##0=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(第=#,##0=),
				},
			},
		},
		'financialnumber13' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'financialnumber2' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'financialnumber3' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'financialnumber4' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'financialnumber5' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'financialnumber8' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零壹=%spellout-cardinal-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-financial=),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal-financial=),
				},
				'max' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal-financial=),
				},
			},
		},
		'number13' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-numbering=),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'number2' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'number3' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'number4' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-numbering=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'number5' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-numbering=),
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
		'number8' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-numbering=),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(負→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←點→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(一),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(二),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(三),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(四),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(五),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(六),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(七),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(八),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(九),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(←%%cardinal-twenties←十[→%spellout-numbering→]),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(廿[→%spellout-numbering→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←%spellout-numbering←十[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←百[→%%number2→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering←千[→%%number3→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←%spellout-numbering←萬[→%%number4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-numbering←億[→%%number5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering←兆[→%%number8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←%spellout-numbering←京[→%%number13→]),
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
		'spellout-cardinal-alternate2' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(負→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(一),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(兩),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-cardinal-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(負→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←點→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(壹),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(貳),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(叁),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(肆),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(伍),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(陸),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(柒),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(捌),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(玖),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(拾[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←拾[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←佰[→%%financialnumber2→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←仟[→%%financialnumber3→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←%spellout-cardinal-financial←萬[→%%financialnumber4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-cardinal-financial←億[→%%financialnumber5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-financial←兆[→%%financialnumber8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←%spellout-cardinal-financial←京[→%%financialnumber13→]),
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
					rule => q(負→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←點→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(一),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(二),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(三),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(四),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(五),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(六),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(七),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(八),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(九),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(十[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←十[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←百[→%%number2→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←千[→%%number3→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←萬[→%%number4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←億[→%%number5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←兆[→%%number8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←京[→%%number13→]),
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
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%%spellout-numbering-year-digits=),
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
		'spellout-numbering-year-digits' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(←←→→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←→→→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←→→→),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←→→→),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(第=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
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
				'aa' => '阿法文',
 				'ab' => '阿布哈茲文',
 				'ace' => '亞齊文',
 				'ach' => '阿僑利文',
 				'ada' => '阿當莫文',
 				'ady' => '阿迪各文',
 				'ae' => '阿緯斯陀文',
 				'aeb' => '突尼斯阿拉伯文',
 				'af' => '南非荷蘭文',
 				'afh' => '阿弗里希利文',
 				'agq' => '亞罕文',
 				'ain' => '阿伊努文',
 				'ak' => '阿坎文',
 				'akk' => '阿卡德文',
 				'akz' => '阿拉巴馬文',
 				'ale' => '阿留申文',
 				'aln' => '蓋格阿爾巴尼亞文',
 				'alt' => '南阿爾泰文',
 				'am' => '阿姆哈拉文',
 				'an' => '阿拉貢文',
 				'ang' => '古英文',
 				'ann' => '奧博洛文',
 				'anp' => '昂加文',
 				'ar' => '阿拉伯文',
 				'ar_001' => '現代標準阿拉伯文',
 				'arc' => '阿拉米文',
 				'arn' => '馬普切文',
 				'aro' => '阿拉奧納文',
 				'arp' => '阿拉帕霍文',
 				'arq' => '阿爾及利亞阿拉伯文',
 				'ars' => '納吉迪阿拉伯文',
 				'arw' => '阿拉瓦克文',
 				'ary' => '摩洛哥阿拉伯文',
 				'arz' => '埃及阿拉伯文',
 				'as' => '阿薩姆文',
 				'asa' => '阿蘇文',
 				'ase' => '美國手語',
 				'ast' => '阿斯圖里亞文',
 				'atj' => '阿提卡米克文',
 				'av' => '阿瓦爾文',
 				'avk' => '科塔瓦文',
 				'awa' => '阿瓦文',
 				'ay' => '艾馬拉文',
 				'az' => '亞塞拜然文',
 				'ba' => '巴什客爾文',
 				'bal' => '俾路支文',
 				'ban' => '峇里文',
 				'bar' => '巴伐利亞文',
 				'bas' => '巴薩文',
 				'bax' => '巴姆穆文',
 				'bbc' => '巴塔克托巴文',
 				'bbj' => '戈馬拉文',
 				'be' => '白俄羅斯文',
 				'bej' => '貝扎文',
 				'bem' => '別姆巴文',
 				'bew' => '貝塔維文',
 				'bez' => '貝納文',
 				'bfd' => '富特文',
 				'bfq' => '巴達加文',
 				'bg' => '保加利亞文',
 				'bgc' => '哈里亞納文',
 				'bgn' => '西俾路支文',
 				'bho' => '博傑普爾文',
 				'bi' => '比斯拉馬文',
 				'bik' => '比科爾文',
 				'bin' => '比尼文',
 				'bjn' => '班亞爾文',
 				'bkm' => '康姆文',
 				'bla' => '錫克錫卡文',
 				'blo' => '阿尼文',
 				'bm' => '班巴拉文',
 				'bn' => '孟加拉文',
 				'bo' => '藏文',
 				'bpy' => '比什奴普萊利亞文',
 				'bqi' => '巴赫蒂亞里文',
 				'br' => '布列塔尼文',
 				'bra' => '布拉杰文',
 				'brh' => '布拉維文',
 				'brx' => '博多文',
 				'bs' => '波士尼亞文',
 				'bss' => '阿庫色文',
 				'bua' => '布里阿特文',
 				'bug' => '布吉斯文',
 				'bum' => '布魯文',
 				'byn' => '比林文',
 				'byv' => '梅敦巴文',
 				'ca' => '加泰羅尼亞文',
 				'cad' => '卡多文',
 				'car' => '加勒比文',
 				'cay' => '卡尤加文',
 				'cch' => '阿燦文',
 				'ccp' => '查克馬文',
 				'ce' => '車臣文',
 				'ceb' => '宿霧文',
 				'cgg' => '奇加文',
 				'ch' => '查莫洛文',
 				'chb' => '奇布查文',
 				'chg' => '查加文',
 				'chk' => '處奇斯文',
 				'chm' => '馬里文',
 				'chn' => '契奴克文',
 				'cho' => '喬克托文',
 				'chp' => '奇佩瓦揚文',
 				'chr' => '柴羅基文',
 				'chy' => '沙伊安文',
 				'ckb' => '索拉尼庫爾德文',
 				'clc' => '奇爾科延文',
 				'co' => '科西嘉文',
 				'cop' => '科普特文',
 				'cps' => '卡皮茲文',
 				'cr' => '克裡文',
 				'crg' => '米奇夫文',
 				'crh' => '克里米亞半島的土耳其文；克里米亞半島的塔塔爾文',
 				'crj' => '東南克里文',
 				'crk' => '平原克里文',
 				'crl' => '東北克里文',
 				'crm' => '駝鹿克里文',
 				'crr' => '卡羅來納州阿爾岡昆語',
 				'crs' => '法語克里奧爾混合語',
 				'cs' => '捷克文',
 				'csb' => '卡舒布文',
 				'csw' => '沼澤克里文',
 				'cu' => '宗教斯拉夫文',
 				'cv' => '楚瓦什文',
 				'cy' => '威爾斯文',
 				'da' => '丹麥文',
 				'dak' => '達科他文',
 				'dar' => '達爾格瓦文',
 				'dav' => '台塔文',
 				'de' => '德文',
 				'de_CH' => '高地德文 (瑞士)',
 				'del' => '德拉瓦文',
 				'den' => '斯拉夫',
 				'dgr' => '多格里布文',
 				'din' => '丁卡文',
 				'dje' => '扎爾馬文',
 				'doi' => '多格來文',
 				'dsb' => '下索布文',
 				'dtp' => '中部杜順文',
 				'dua' => '杜亞拉文',
 				'dum' => '中古荷蘭文',
 				'dv' => '迪維西文',
 				'dyo' => '朱拉文',
 				'dyu' => '迪尤拉文',
 				'dz' => '宗卡文',
 				'dzg' => '達薩文',
 				'ebu' => '恩布文',
 				'ee' => '埃維文',
 				'efi' => '埃菲克文',
 				'egl' => '埃米利安文',
 				'egy' => '古埃及文',
 				'eka' => '艾卡朱克文',
 				'el' => '希臘文',
 				'elx' => '埃蘭文',
 				'en' => '英文',
 				'enm' => '中古英文',
 				'eo' => '世界文',
 				'es' => '西班牙文',
 				'esu' => '中尤皮克文',
 				'et' => '愛沙尼亞文',
 				'eu' => '巴斯克文',
 				'ewo' => '依汪都文',
 				'ext' => '埃斯特雷馬杜拉文',
 				'fa' => '波斯文',
 				'fa_AF' => '達里文',
 				'fan' => '芳族文',
 				'fat' => '芳蒂文',
 				'ff' => '富拉文',
 				'fi' => '芬蘭文',
 				'fil' => '菲律賓文',
 				'fit' => '托爾訥芬蘭文',
 				'fj' => '斐濟文',
 				'fo' => '法羅文',
 				'fon' => '豐文',
 				'fr' => '法文',
 				'frc' => '卡真法文',
 				'frm' => '中古法文',
 				'fro' => '古法文',
 				'frp' => '法蘭克-普羅旺斯文',
 				'frr' => '北弗里西亞文',
 				'frs' => '東弗里西亞文',
 				'fur' => '弗留利文',
 				'fy' => '西弗里西亞文',
 				'ga' => '愛爾蘭文',
 				'gaa' => '加族文',
 				'gag' => '加告茲文',
 				'gan' => '贛語',
 				'gay' => '加約文',
 				'gba' => '葛巴亞文',
 				'gbz' => '索羅亞斯德教達里文',
 				'gd' => '蘇格蘭蓋爾文',
 				'gez' => '吉茲文',
 				'gil' => '吉爾伯特群島文',
 				'gl' => '加里西亞文',
 				'glk' => '吉拉基文',
 				'gmh' => '中古高地德文',
 				'gn' => '瓜拉尼文',
 				'goh' => '古高地日耳曼文',
 				'gon' => '岡德文',
 				'gor' => '科隆達羅文',
 				'got' => '哥德文',
 				'grb' => '格列博文',
 				'grc' => '古希臘文',
 				'gsw' => '德文（瑞士）',
 				'gu' => '古吉拉特文',
 				'guc' => '瓦尤文',
 				'gur' => '弗拉弗拉文',
 				'guz' => '古西文',
 				'gv' => '曼島文',
 				'gwi' => '圭契文',
 				'ha' => '豪撒文',
 				'hai' => '海達文',
 				'hak' => '客家話',
 				'haw' => '夏威夷文',
 				'hax' => '南海達文',
 				'he' => '希伯來文',
 				'hi' => '北印度文',
 				'hif' => '斐濟印地文',
 				'hil' => '希利蓋農文',
 				'hit' => '赫梯文',
 				'hmn' => '孟文',
 				'ho' => '西里莫圖土文',
 				'hr' => '克羅埃西亞文',
 				'hsb' => '上索布文',
 				'hsn' => '湘語',
 				'ht' => '海地文',
 				'hu' => '匈牙利文',
 				'hup' => '胡帕文',
 				'hur' => '哈爾魁梅林語',
 				'hy' => '亞美尼亞文',
 				'hz' => '赫雷羅文',
 				'ia' => '國際文',
 				'iba' => '伊班文',
 				'ibb' => '伊比比奧文',
 				'id' => '印尼文',
 				'ie' => '國際文（E）',
 				'ig' => '伊布文',
 				'ii' => '四川彝文',
 				'ik' => '依奴皮維克文',
 				'ikt' => '加拿大西部因紐特文',
 				'ilo' => '伊洛闊文',
 				'inh' => '印古什文',
 				'io' => '伊多文',
 				'is' => '冰島文',
 				'it' => '義大利文',
 				'iu' => '因紐特文',
 				'izh' => '英格裏亞文',
 				'ja' => '日文',
 				'jam' => '牙買加克裏奧爾英文',
 				'jbo' => '邏輯文',
 				'jgo' => '恩格姆巴文',
 				'jmc' => '馬恰美文',
 				'jpr' => '猶太教-波斯文',
 				'jrb' => '猶太阿拉伯文',
 				'jut' => '日德蘭文',
 				'jv' => '爪哇文',
 				'ka' => '喬治亞文',
 				'kaa' => '卡拉卡爾帕克文',
 				'kab' => '卡比爾文',
 				'kac' => '卡琴文',
 				'kaj' => '卡捷文',
 				'kam' => '卡姆巴文',
 				'kaw' => '卡威文',
 				'kbd' => '卡巴爾達文',
 				'kbl' => '卡念布文',
 				'kcg' => '卡塔布文',
 				'kde' => '馬孔德文',
 				'kea' => '卡布威爾第文',
 				'ken' => '肯揚文',
 				'kfo' => '科羅文',
 				'kg' => '剛果文',
 				'kgp' => '坎剛文',
 				'kha' => '卡西文',
 				'kho' => '和闐文',
 				'khq' => '西桑海文',
 				'khw' => '科瓦文',
 				'ki' => '吉庫尤文',
 				'kiu' => '北紮紮其文',
 				'kj' => '廣亞馬文',
 				'kk' => '哈薩克文',
 				'kkj' => '卡庫文',
 				'kl' => '格陵蘭文',
 				'kln' => '卡倫金文',
 				'km' => '高棉文',
 				'kmb' => '金邦杜文',
 				'kn' => '坎那達文',
 				'ko' => '韓文',
 				'koi' => '科米-彼爾米亞克文',
 				'kok' => '貢根文',
 				'kos' => '科斯雷恩文',
 				'kpe' => '克佩列文',
 				'kr' => '卡努裡文',
 				'krc' => '卡拉柴-包爾卡爾文',
 				'kri' => '塞拉利昂克裏奧爾文',
 				'krj' => '基那來阿文',
 				'krl' => '卡累利阿文',
 				'kru' => '庫魯科文',
 				'ks' => '喀什米爾文',
 				'ksb' => '尚巴拉文',
 				'ksf' => '巴菲亞文',
 				'ksh' => '科隆文',
 				'ku' => '庫爾德文',
 				'kum' => '庫密克文',
 				'kut' => '庫特奈文',
 				'kv' => '科米文',
 				'kw' => '康瓦耳文',
 				'kwk' => '誇誇瓦拉文',
 				'kxv' => '庫維文',
 				'ky' => '吉爾吉斯文',
 				'la' => '拉丁文',
 				'lad' => '拉迪諾文',
 				'lag' => '朗吉文',
 				'lah' => '拉亨達文',
 				'lam' => '蘭巴文',
 				'lb' => '盧森堡文',
 				'lez' => '列茲干文',
 				'lfn' => '新共同語言',
 				'lg' => '干達文',
 				'li' => '林堡文',
 				'lij' => '利古里亞文',
 				'lil' => '利盧埃特文',
 				'liv' => '利伏尼亞文',
 				'lkt' => '拉科塔文',
 				'lmo' => '倫巴底文',
 				'ln' => '林加拉文',
 				'lo' => '寮文',
 				'lol' => '芒戈文',
 				'lou' => '路易斯安那克里奧爾文',
 				'loz' => '洛齊文',
 				'lrc' => '北盧爾文',
 				'lsm' => '薩米亞文',
 				'lt' => '立陶宛文',
 				'ltg' => '拉特加萊文',
 				'lu' => '魯巴加丹加文',
 				'lua' => '魯巴魯魯亞文',
 				'lui' => '路易塞諾文',
 				'lun' => '盧恩達文',
 				'luo' => '盧奧文',
 				'lus' => '盧晒文',
 				'luy' => '盧雅文',
 				'lv' => '拉脫維亞文',
 				'lzh' => '文言文',
 				'lzz' => '拉茲文',
 				'mad' => '馬都拉文',
 				'maf' => '馬法文',
 				'mag' => '馬加伊文',
 				'mai' => '邁蒂利文',
 				'mak' => '望加錫文',
 				'man' => '曼丁哥文',
 				'mas' => '馬賽文',
 				'mde' => '馬巴文',
 				'mdf' => '莫克沙文',
 				'mdr' => '曼達文',
 				'men' => '門德文',
 				'mer' => '梅魯文',
 				'mfe' => '克里奧文（模里西斯）',
 				'mg' => '馬拉加什文',
 				'mga' => '中古愛爾蘭文',
 				'mgh' => '馬夸文',
 				'mgo' => '美塔文',
 				'mh' => '馬紹爾文',
 				'mi' => '毛利文',
 				'mic' => '米克馬克文',
 				'min' => '米南卡堡文',
 				'mk' => '馬其頓文',
 				'ml' => '馬來亞拉姆文',
 				'mn' => '蒙古文',
 				'mnc' => '滿族文',
 				'mni' => '曼尼普裡文',
 				'moe' => '因努埃蒙文',
 				'moh' => '莫霍克文',
 				'mos' => '莫西文',
 				'mr' => '馬拉地文',
 				'mrj' => '西馬裏文',
 				'ms' => '馬來文',
 				'mt' => '馬爾他文',
 				'mua' => '蒙當文',
 				'mul' => '多種語言',
 				'mus' => '克里克文',
 				'mwl' => '米蘭德斯文',
 				'mwr' => '馬爾尼裡文',
 				'mwv' => '明打威文',
 				'my' => '緬甸文',
 				'mye' => '姆耶內文',
 				'myv' => '厄爾茲亞文',
 				'mzn' => '馬贊德蘭文',
 				'na' => '諾魯文',
 				'nan' => '閩南語',
 				'nap' => '拿波里文',
 				'naq' => '納馬文',
 				'nb' => '巴克摩挪威文',
 				'nd' => '北地畢列文',
 				'nds' => '低地德文',
 				'nds_NL' => '低地薩克遜文',
 				'ne' => '尼泊爾文',
 				'new' => '尼瓦爾文',
 				'ng' => '恩東加文',
 				'nia' => '尼亞斯文',
 				'niu' => '紐埃文',
 				'njo' => '阿沃那加文',
 				'nl' => '荷蘭文',
 				'nl_BE' => '佛蘭芒文',
 				'nmg' => '夸西奧文',
 				'nn' => '耐諾斯克挪威文',
 				'nnh' => '恩甘澎文',
 				'no' => '挪威文',
 				'nog' => '諾蓋文',
 				'non' => '古諾爾斯文',
 				'nov' => '諾維亞文',
 				'nqo' => '曼德文字 (N’Ko)',
 				'nr' => '南地畢列文',
 				'nso' => '北索托文',
 				'nus' => '努埃爾文',
 				'nv' => '納瓦霍文',
 				'nwc' => '古尼瓦爾文',
 				'ny' => '尼揚賈文',
 				'nym' => '尼揚韋齊文',
 				'nyn' => '尼揚科萊文',
 				'nyo' => '尼奧囉文',
 				'nzi' => '尼茲馬文',
 				'oc' => '奧克西坦文',
 				'oj' => '奧杰布瓦文',
 				'ojb' => '西北奧吉布瓦文',
 				'ojc' => '中奧吉布瓦文',
 				'ojs' => '王子克里文',
 				'ojw' => '西奧吉布瓦文',
 				'oka' => '奧卡納根文',
 				'om' => '奧羅莫文',
 				'or' => '歐利亞文',
 				'os' => '奧塞提文',
 				'osa' => '歐塞奇文',
 				'ota' => '鄂圖曼土耳其文',
 				'pa' => '旁遮普文',
 				'pag' => '潘加辛文',
 				'pal' => '巴列維文',
 				'pam' => '潘帕嘉文',
 				'pap' => '帕皮阿門托文',
 				'pau' => '帛琉文',
 				'pcd' => '庇卡底文',
 				'pcm' => '尼日利亞皮欽語',
 				'pdc' => '賓夕法尼亞德文',
 				'pdt' => '門諾低地德文',
 				'peo' => '古波斯文',
 				'pfl' => '普法爾茨德文',
 				'phn' => '腓尼基文',
 				'pi' => '巴利文',
 				'pis' => '皮京文',
 				'pl' => '波蘭文',
 				'pms' => '皮埃蒙特文',
 				'pnt' => '旁狄希臘文',
 				'pon' => '波那貝文',
 				'pqm' => '馬里塞-帕薩馬誇迪文',
 				'prg' => '普魯士文',
 				'pro' => '古普羅旺斯文',
 				'ps' => '普什圖文',
 				'pt' => '葡萄牙文',
 				'qu' => '蓋楚瓦文',
 				'quc' => '基切文',
 				'qug' => '欽博拉索海蘭蓋丘亞文',
 				'raj' => '拉賈斯坦諸文',
 				'rap' => '復活島文',
 				'rar' => '拉羅通加文',
 				'rgn' => '羅馬格諾里文',
 				'rhg' => '羅興亞文',
 				'rif' => '里菲亞諾文',
 				'rm' => '羅曼斯文',
 				'rn' => '隆迪文',
 				'ro' => '羅馬尼亞文',
 				'ro_MD' => '摩爾多瓦文',
 				'rof' => '蘭博文',
 				'rom' => '吉普賽文',
 				'rtm' => '羅圖馬島文',
 				'ru' => '俄文',
 				'rue' => '盧森尼亞文',
 				'rug' => '羅維阿納文',
 				'rup' => '羅馬尼亞語系',
 				'rw' => '盧安達文',
 				'rwk' => '羅瓦文',
 				'sa' => '梵文',
 				'sad' => '桑達韋文',
 				'sah' => '雅庫特文',
 				'sam' => '薩瑪利亞阿拉姆文',
 				'saq' => '薩布魯文',
 				'sas' => '撒撒克文',
 				'sat' => '散塔利文',
 				'saz' => '索拉什特拉文',
 				'sba' => '甘拜文',
 				'sbp' => '桑古文',
 				'sc' => '撒丁文',
 				'scn' => '西西里文',
 				'sco' => '蘇格蘭文',
 				'sd' => '信德文',
 				'sdc' => '薩丁尼亞-薩薩里文',
 				'sdh' => '南庫爾德文',
 				'se' => '北方薩米文',
 				'see' => '塞訥卡文',
 				'seh' => '賽納文',
 				'sei' => '瑟里文',
 				'sel' => '瑟爾卡普文',
 				'ses' => '東桑海文',
 				'sg' => '桑戈文',
 				'sga' => '古愛爾蘭文',
 				'sgs' => '薩莫吉希亞文',
 				'sh' => '塞爾維亞克羅埃西亞文',
 				'shi' => '希爾哈文',
 				'shn' => '撣文',
 				'shu' => '阿拉伯文（查德）',
 				'si' => '僧伽羅文',
 				'sid' => '希達摩文',
 				'sk' => '斯洛伐克文',
 				'sl' => '斯洛維尼亞文',
 				'slh' => '南盧紹錫德文',
 				'sli' => '下西利西亞文',
 				'sly' => '塞拉亞文',
 				'sm' => '薩摩亞文',
 				'sma' => '南薩米文',
 				'smj' => '魯勒薩米文',
 				'smn' => '伊納裡薩米文',
 				'sms' => '斯科特薩米文',
 				'sn' => '塞內加爾文',
 				'snk' => '索尼基文',
 				'so' => '索馬利文',
 				'sog' => '索格底亞納文',
 				'sq' => '阿爾巴尼亞文',
 				'sr' => '塞爾維亞文',
 				'srn' => '蘇拉南東墎文',
 				'srr' => '塞雷爾文',
 				'ss' => '斯瓦特文',
 				'ssy' => '薩霍文',
 				'st' => '塞索托文',
 				'stq' => '沙特菲士蘭文',
 				'str' => '海峽薩利希文',
 				'su' => '巽他文',
 				'suk' => '蘇庫馬文',
 				'sus' => '蘇蘇文',
 				'sux' => '蘇美文',
 				'sv' => '瑞典文',
 				'sw' => '史瓦希里文',
 				'sw_CD' => '史瓦希里文（剛果）',
 				'swb' => '葛摩文',
 				'syc' => '古敘利亞文',
 				'syr' => '敘利亞文',
 				'szl' => '西利西亞文',
 				'ta' => '坦米爾文',
 				'tce' => '南塔穹文',
 				'tcy' => '圖盧文',
 				'te' => '泰盧固文',
 				'tem' => '提姆文',
 				'teo' => '特索文',
 				'ter' => '泰雷諾文',
 				'tet' => '泰頓文',
 				'tg' => '塔吉克文',
 				'tgx' => '塔吉什文',
 				'th' => '泰文',
 				'tht' => '塔爾坦文',
 				'ti' => '提格利尼亞文',
 				'tig' => '蒂格雷文',
 				'tiv' => '提夫文',
 				'tk' => '土庫曼文',
 				'tkl' => '托克勞文',
 				'tkr' => '查庫爾文',
 				'tl' => '塔加路族文',
 				'tlh' => '克林貢文',
 				'tli' => '特林基特文',
 				'tly' => '塔里什文',
 				'tmh' => '塔馬奇克文',
 				'tn' => '突尼西亞文',
 				'to' => '東加文',
 				'tog' => '東加文（尼亞薩）',
 				'tok' => '托基波納文',
 				'tpi' => '托比辛文',
 				'tr' => '土耳其文',
 				'tru' => '圖羅尤文',
 				'trv' => '太魯閣文',
 				'ts' => '特松加文',
 				'tsd' => '特薩克尼恩文',
 				'tsi' => '欽西安文',
 				'tt' => '韃靼文',
 				'ttm' => '北塔奇訥文',
 				'ttt' => '穆斯林塔特文',
 				'tum' => '圖姆布卡文',
 				'tvl' => '吐瓦魯文',
 				'tw' => '特威文',
 				'twq' => '北桑海文',
 				'ty' => '大溪地文',
 				'tyv' => '土凡文',
 				'tzm' => '塔馬齊格特文',
 				'udm' => '沃蒂艾克文',
 				'ug' => '維吾爾文',
 				'uga' => '烏加列文',
 				'uk' => '烏克蘭文',
 				'umb' => '姆本杜文',
 				'und' => '未知語言',
 				'ur' => '烏都文',
 				'uz' => '烏茲別克文',
 				'vai' => '瓦伊文',
 				've' => '溫達文',
 				'vec' => '威尼斯文',
 				'vep' => '維普森文',
 				'vi' => '越南文',
 				'vls' => '西佛蘭德文',
 				'vmf' => '美茵-法蘭克尼亞文',
 				'vmw' => '馬庫瓦文',
 				'vo' => '沃拉普克文',
 				'vot' => '沃提克文',
 				'vro' => '佛羅文',
 				'vun' => '溫舊文',
 				'wa' => '瓦隆文',
 				'wae' => '瓦瑟文',
 				'wal' => '瓦拉莫文',
 				'war' => '瓦瑞文',
 				'was' => '瓦紹文',
 				'wbp' => '沃皮瑞文',
 				'wo' => '沃洛夫文',
 				'wuu' => '吳語',
 				'xal' => '卡爾梅克文',
 				'xh' => '科薩文',
 				'xmf' => '明格列爾文',
 				'xnr' => '康格里文',
 				'xog' => '索加文',
 				'yao' => '瑤文',
 				'yap' => '雅浦文',
 				'yav' => '洋卞文',
 				'ybb' => '耶姆巴文',
 				'yi' => '意第緒文',
 				'yo' => '約魯巴文',
 				'yrl' => '奈恩加圖文',
 				'yue' => '粵語',
 				'yue@alt=menu' => '中文 (粵語)',
 				'za' => '壯文',
 				'zap' => '薩波特克文',
 				'zbl' => '布列斯符號',
 				'zea' => '西蘭文',
 				'zen' => '澤納加文',
 				'zgh' => '標準摩洛哥塔馬塞特文',
 				'zh' => '中文',
 				'zh@alt=menu' => '中文 (普通話)',
 				'zh_Hans' => '簡體中文',
 				'zh_Hans@alt=long' => '簡體中文 (普通話)',
 				'zh_Hant' => '繁體中文',
 				'zh_Hant@alt=long' => '繁體中文 (普通話)',
 				'zu' => '祖魯文',
 				'zun' => '祖尼文',
 				'zxx' => '無語言內容',
 				'zza' => '扎扎文',

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
			'Adlm' => '阿德拉姆文',
 			'Afak' => '阿法卡文字',
 			'Aghb' => '高加索阿爾巴尼亞文',
 			'Arab' => '阿拉伯文',
 			'Arab@alt=variant' => '波斯阿拉伯文字',
 			'Aran' => '納斯塔利克文',
 			'Armi' => '皇室亞美尼亞文',
 			'Armn' => '亞美尼亞文',
 			'Avst' => '阿維斯陀文',
 			'Bali' => '峇里文',
 			'Bamu' => '巴姆穆文',
 			'Bass' => '巴薩文',
 			'Batk' => '巴塔克文',
 			'Beng' => '孟加拉文',
 			'Blis' => '布列斯文',
 			'Bopo' => '注音符號',
 			'Brah' => '婆羅米文',
 			'Brai' => '盲人用點字',
 			'Bugi' => '布吉斯文',
 			'Buhd' => '布希德文',
 			'Cakm' => '查克馬文',
 			'Cans' => '加拿大原住民通用字符',
 			'Cari' => '卡里亞文',
 			'Cham' => '占文',
 			'Cher' => '柴羅基文',
 			'Cirt' => '色斯文',
 			'Copt' => '科普特文',
 			'Cprt' => '塞浦路斯文',
 			'Cyrl' => '斯拉夫文',
 			'Cyrs' => '西里爾文（古教會斯拉夫文變體）',
 			'Deva' => '天城文',
 			'Dsrt' => '德瑟雷特文',
 			'Dupl' => '杜普洛伊速記',
 			'Egyd' => '古埃及世俗體',
 			'Egyh' => '古埃及僧侶體',
 			'Egyp' => '古埃及象形文字',
 			'Elba' => '愛爾巴桑文',
 			'Ethi' => '衣索比亞文',
 			'Geok' => '喬治亞語系（阿索他路里和努斯克胡里文）',
 			'Geor' => '喬治亞文',
 			'Glag' => '格拉哥里文',
 			'Goth' => '歌德文',
 			'Gran' => '格蘭他文字',
 			'Grek' => '希臘文',
 			'Gujr' => '古吉拉特文',
 			'Guru' => '古魯穆奇文',
 			'Hanb' => '漢語注音',
 			'Hang' => '韓文字',
 			'Hani' => '漢語',
 			'Hano' => '哈努諾文',
 			'Hans' => '簡體',
 			'Hans@alt=stand-alone' => '簡體中文',
 			'Hant' => '繁體',
 			'Hant@alt=stand-alone' => '繁體中文',
 			'Hebr' => '希伯來文',
 			'Hira' => '平假名',
 			'Hluw' => '安那托利亞象形文字',
 			'Hmng' => '楊松錄苗文',
 			'Hrkt' => '片假名或平假名',
 			'Hung' => '古匈牙利文',
 			'Inds' => '印度河流域（哈拉帕文）',
 			'Ital' => '古意大利文',
 			'Jamo' => '韓文字母',
 			'Java' => '爪哇文',
 			'Jpan' => '日文',
 			'Jurc' => '女真文字',
 			'Kali' => '克耶李文',
 			'Kana' => '片假名',
 			'Khar' => '卡羅須提文',
 			'Khmr' => '高棉文',
 			'Khoj' => '克吉奇文字',
 			'Knda' => '坎那達文',
 			'Kore' => '韓文',
 			'Kpel' => '克培列文',
 			'Kthi' => '凱提文',
 			'Lana' => '藍拿文',
 			'Laoo' => '寮國文',
 			'Latf' => '拉丁文（尖角體活字變體）',
 			'Latg' => '拉丁文（蓋爾語變體）',
 			'Latn' => '拉丁文',
 			'Lepc' => '雷布查文',
 			'Limb' => '林佈文',
 			'Lina' => '線性文字（A）',
 			'Linb' => '線性文字（B）',
 			'Lisu' => '栗僳文',
 			'Loma' => '洛馬文',
 			'Lyci' => '呂西亞語',
 			'Lydi' => '里底亞語',
 			'Mand' => '曼底安文',
 			'Mani' => '摩尼教文',
 			'Maya' => '瑪雅象形文字',
 			'Mend' => '門德文',
 			'Merc' => '麥羅埃文（曲線字體）',
 			'Mero' => '麥羅埃文',
 			'Mlym' => '馬來亞拉姆文',
 			'Mong' => '蒙古文',
 			'Moon' => '蒙氏點字',
 			'Mroo' => '謬文',
 			'Mtei' => '曼尼普爾文',
 			'Mymr' => '緬甸文',
 			'Narb' => '古北阿拉伯文',
 			'Nbat' => '納巴泰文字',
 			'Nkgb' => '納西格巴文',
 			'Nkoo' => '西非書面語言 (N’Ko)',
 			'Nshu' => '女書文字',
 			'Ogam' => '歐甘文',
 			'Olck' => '桑塔利文',
 			'Orkh' => '鄂爾渾文',
 			'Orya' => '歐利亞文',
 			'Osma' => '歐斯曼亞文',
 			'Palm' => '帕米瑞拉文字',
 			'Perm' => '古彼爾姆諸文',
 			'Phag' => '八思巴文',
 			'Phli' => '巴列維文（碑銘體）',
 			'Phlp' => '巴列維文（聖詩體）',
 			'Phlv' => '巴列維文（書體）',
 			'Phnx' => '腓尼基文',
 			'Plrd' => '柏格理拼音符',
 			'Prti' => '帕提亞文（碑銘體）',
 			'Rjng' => '拉讓文',
 			'Rohg' => '哈尼菲文',
 			'Roro' => '朗格朗格象形文',
 			'Runr' => '古北歐文字',
 			'Samr' => '撒馬利亞文',
 			'Sara' => '沙拉堤文',
 			'Sarb' => '古南阿拉伯文',
 			'Saur' => '索拉什特拉文',
 			'Sgnw' => '手語書寫符號',
 			'Shaw' => '簫柏納字符',
 			'Shrd' => '夏拉達文',
 			'Sidd' => '悉曇文字',
 			'Sind' => '信德文',
 			'Sinh' => '錫蘭文',
 			'Sora' => '索朗桑朋文字',
 			'Sund' => '巽他文',
 			'Sylo' => '希洛弟納格里文',
 			'Syrc' => '敍利亞文',
 			'Syre' => '敘利亞文（福音體文字變體）',
 			'Syrj' => '敘利亞文（西方文字變體）',
 			'Syrn' => '敘利亞文（東方文字變體）',
 			'Tagb' => '南島文',
 			'Takr' => '塔卡里文字',
 			'Tale' => '傣哪文',
 			'Talu' => '西雙版納新傣文',
 			'Taml' => '坦米爾文',
 			'Tang' => '西夏文',
 			'Tavt' => '傣擔文',
 			'Telu' => '泰盧固文',
 			'Teng' => '談格瓦文',
 			'Tfng' => '提非納文',
 			'Tglg' => '塔加拉文',
 			'Thaa' => '塔安那文',
 			'Thai' => '泰文',
 			'Tibt' => '西藏文',
 			'Tirh' => '邁蒂利文',
 			'Ugar' => '烏加列文',
 			'Vaii' => '瓦依文',
 			'Visp' => '視覺語音文字',
 			'Wara' => '瓦郎奇蒂文字',
 			'Wole' => '沃雷艾文',
 			'Xpeo' => '古波斯文',
 			'Xsux' => '蘇米魯亞甲文楔形文字',
 			'Yiii' => '彞文',
 			'Zinh' => '繼承文字（Unicode）',
 			'Zmth' => '數學符號',
 			'Zsye' => '表情符號',
 			'Zsym' => '符號',
 			'Zxxx' => '非書寫語言',
 			'Zyyy' => '一般文字',
 			'Zzzz' => '未知文字',

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
			'001' => '世界',
 			'002' => '非洲',
 			'003' => '北美洲',
 			'005' => '南美洲',
 			'009' => '大洋洲',
 			'011' => '西非',
 			'013' => '中美',
 			'014' => '東非',
 			'015' => '北非',
 			'017' => '中非',
 			'018' => '非洲南部',
 			'019' => '美洲',
 			'021' => '北美',
 			'029' => '加勒比海',
 			'030' => '東亞',
 			'034' => '南亞',
 			'035' => '東南亞',
 			'039' => '南歐',
 			'053' => '澳洲同紐西蘭',
 			'054' => '美拉尼西亞',
 			'057' => '密克羅尼西亞',
 			'061' => '玻里尼西亞',
 			'142' => '亞洲',
 			'143' => '中亞',
 			'145' => '西亞',
 			'150' => '歐洲',
 			'151' => '東歐',
 			'154' => '北歐',
 			'155' => '西歐',
 			'202' => '撒哈拉以南非洲',
 			'419' => '拉丁美洲',
 			'AC' => '阿森松島',
 			'AD' => '安道爾',
 			'AE' => '阿拉伯聯合大公國',
 			'AF' => '阿富汗',
 			'AG' => '安提瓜同巴布達',
 			'AI' => '安圭拉',
 			'AL' => '阿爾巴尼亞',
 			'AM' => '亞美尼亞',
 			'AO' => '安哥拉',
 			'AQ' => '南極洲',
 			'AR' => '阿根廷',
 			'AS' => '美屬薩摩亞',
 			'AT' => '奧地利',
 			'AU' => '澳洲',
 			'AW' => '荷屬阿魯巴',
 			'AX' => '奧蘭群島',
 			'AZ' => '阿塞拜疆',
 			'BA' => '波斯尼亞同黑塞哥維那',
 			'BB' => '巴貝多',
 			'BD' => '孟加拉',
 			'BE' => '比利時',
 			'BF' => '布吉納法索',
 			'BG' => '保加利亞',
 			'BH' => '巴林',
 			'BI' => '蒲隆地',
 			'BJ' => '貝南',
 			'BL' => '聖巴瑟米',
 			'BM' => '百慕達',
 			'BN' => '汶萊',
 			'BO' => '玻利維亞',
 			'BQ' => '荷蘭加勒比區',
 			'BR' => '巴西',
 			'BS' => '巴哈馬',
 			'BT' => '不丹',
 			'BV' => '布威島',
 			'BW' => '波札那',
 			'BY' => '白俄羅斯',
 			'BZ' => '貝里斯',
 			'CA' => '加拿大',
 			'CC' => '科科斯（基林）群島',
 			'CD' => '剛果（金夏沙）',
 			'CD@alt=variant' => '剛果民主共和國',
 			'CF' => '中非共和國',
 			'CG' => '剛果（布拉薩）',
 			'CG@alt=variant' => '剛果共和國',
 			'CH' => '瑞士',
 			'CI' => '象牙海岸',
 			'CK' => '庫克群島',
 			'CL' => '智利',
 			'CM' => '喀麥隆',
 			'CN' => '中國',
 			'CO' => '哥倫比亞',
 			'CP' => '克里派頓島',
 			'CR' => '哥斯大黎加',
 			'CU' => '古巴',
 			'CV' => '維德角',
 			'CW' => '庫拉索',
 			'CX' => '聖誕島',
 			'CY' => '賽普勒斯',
 			'CZ' => '捷克',
 			'CZ@alt=variant' => '捷克共和國',
 			'DE' => '德國',
 			'DG' => '迪亞哥加西亞島',
 			'DJ' => '吉布地',
 			'DK' => '丹麥',
 			'DM' => '多米尼克',
 			'DO' => '多明尼加共和國',
 			'DZ' => '阿爾及利亞',
 			'EA' => '休達與梅利利亞',
 			'EC' => '厄瓜多',
 			'EE' => '愛沙尼亞',
 			'EG' => '埃及',
 			'EH' => '西撒哈拉',
 			'ER' => '厄利垂亞',
 			'ES' => '西班牙',
 			'ET' => '衣索比亞',
 			'EU' => '歐盟',
 			'EZ' => '歐元區',
 			'FI' => '芬蘭',
 			'FJ' => '斐濟',
 			'FK' => '福克蘭群島',
 			'FK@alt=variant' => '福克蘭群島 (馬爾維納斯群島)',
 			'FM' => '密克羅尼西亞群島',
 			'FO' => '法羅群島',
 			'FR' => '法國',
 			'GA' => '加彭',
 			'GB' => '英國',
 			'GD' => '格瑞那達',
 			'GE' => '格魯吉亞',
 			'GF' => '法屬圭亞那',
 			'GG' => '根西島',
 			'GH' => '迦納',
 			'GI' => '直布羅陀',
 			'GL' => '格陵蘭',
 			'GM' => '甘比亞',
 			'GN' => '幾內亞',
 			'GP' => '瓜地洛普',
 			'GQ' => '赤道幾內亞',
 			'GR' => '希臘',
 			'GS' => '南佐治亞島同南桑威奇群島',
 			'GT' => '瓜地馬拉',
 			'GU' => '關島',
 			'GW' => '幾內亞比索',
 			'GY' => '蓋亞那',
 			'HK' => '中國香港特別行政區',
 			'HK@alt=short' => '香港',
 			'HM' => '赫德島同麥克唐納群島',
 			'HN' => '宏都拉斯',
 			'HR' => '克羅埃西亞',
 			'HT' => '海地',
 			'HU' => '匈牙利',
 			'IC' => '加那利群島',
 			'ID' => '印尼',
 			'IE' => '愛爾蘭',
 			'IL' => '以色列',
 			'IM' => '曼島',
 			'IN' => '印度',
 			'IO' => '英屬印度洋領地',
 			'IO@alt=chagos' => '查哥斯群島',
 			'IQ' => '伊拉克',
 			'IR' => '伊朗',
 			'IS' => '冰島',
 			'IT' => '意大利',
 			'JE' => '澤西島',
 			'JM' => '牙買加',
 			'JO' => '約旦',
 			'JP' => '日本',
 			'KE' => '肯亞',
 			'KG' => '吉爾吉斯',
 			'KH' => '柬埔寨',
 			'KI' => '吉里巴斯',
 			'KM' => '葛摩',
 			'KN' => '聖基茨同尼維斯',
 			'KP' => '北韓',
 			'KR' => '南韓',
 			'KW' => '科威特',
 			'KY' => '開曼群島',
 			'KZ' => '哈薩克',
 			'LA' => '老撾',
 			'LB' => '黎巴嫩',
 			'LC' => '聖露西亞',
 			'LI' => '列支敦斯登',
 			'LK' => '斯里蘭卡',
 			'LR' => '賴比瑞亞',
 			'LS' => '賴索托',
 			'LT' => '立陶宛',
 			'LU' => '盧森堡',
 			'LV' => '拉脫維亞',
 			'LY' => '利比亞',
 			'MA' => '摩洛哥',
 			'MC' => '摩納哥',
 			'MD' => '摩爾多瓦',
 			'ME' => '蒙特內哥羅',
 			'MF' => '法屬聖馬丁',
 			'MG' => '馬達加斯加',
 			'MH' => '馬紹爾群島',
 			'MK' => '北馬其頓',
 			'ML' => '馬利',
 			'MM' => '緬甸',
 			'MN' => '蒙古',
 			'MO' => '中國澳門特別行政區',
 			'MO@alt=short' => '澳門',
 			'MP' => '北馬里亞納群島',
 			'MQ' => '馬丁尼克島',
 			'MR' => '茅利塔尼亞',
 			'MS' => '蒙哲臘',
 			'MT' => '馬爾他',
 			'MU' => '模里西斯',
 			'MV' => '馬爾地夫',
 			'MW' => '馬拉威',
 			'MX' => '墨西哥',
 			'MY' => '馬來西亞',
 			'MZ' => '莫三比克',
 			'NA' => '納米比亞',
 			'NC' => '新喀里多尼亞',
 			'NE' => '尼日',
 			'NF' => '諾福克島',
 			'NG' => '奈及利亞',
 			'NI' => '尼加拉瓜',
 			'NL' => '荷蘭',
 			'NO' => '挪威',
 			'NP' => '尼泊爾',
 			'NR' => '諾魯',
 			'NU' => '紐埃島',
 			'NZ' => '新西蘭',
 			'OM' => '阿曼王國',
 			'PA' => '巴拿馬',
 			'PE' => '秘魯',
 			'PF' => '法屬玻里尼西亞',
 			'PG' => '巴布亞紐幾內亞',
 			'PH' => '菲律賓',
 			'PK' => '巴基斯坦',
 			'PL' => '波蘭',
 			'PM' => '聖皮埃爾同密克隆群島',
 			'PN' => '皮特肯群島',
 			'PR' => '波多黎各',
 			'PS' => '巴勒斯坦自治區',
 			'PS@alt=short' => '巴勒斯坦',
 			'PT' => '葡萄牙',
 			'PW' => '帛琉',
 			'PY' => '巴拉圭',
 			'QA' => '卡達',
 			'QO' => '大洋洲邊疆群島',
 			'RE' => '留尼旺',
 			'RO' => '羅馬尼亞',
 			'RS' => '塞爾維亞',
 			'RU' => '俄羅斯',
 			'RW' => '盧安達',
 			'SA' => '沙特阿拉伯',
 			'SB' => '索羅門群島',
 			'SC' => '塞席爾',
 			'SD' => '蘇丹',
 			'SE' => '瑞典',
 			'SG' => '新加坡',
 			'SH' => '聖赫勒拿島',
 			'SI' => '斯洛維尼亞',
 			'SJ' => '斯瓦爾巴特群島同揚馬延島',
 			'SK' => '斯洛伐克',
 			'SL' => '獅子山',
 			'SM' => '聖馬利諾',
 			'SN' => '塞內加爾',
 			'SO' => '索馬利亞',
 			'SR' => '蘇利南',
 			'SS' => '南蘇丹',
 			'ST' => '聖多美同普林西比',
 			'SV' => '薩爾瓦多',
 			'SX' => '荷屬聖馬丁',
 			'SY' => '敘利亞',
 			'SZ' => '史瓦濟蘭',
 			'SZ@alt=variant' => '斯威士蘭',
 			'TA' => '特里斯坦達庫尼亞群島',
 			'TC' => '土克斯及開科斯群島',
 			'TD' => '查德',
 			'TF' => '法屬南方屬地',
 			'TG' => '多哥',
 			'TH' => '泰國',
 			'TJ' => '塔吉克',
 			'TK' => '托克勞群島',
 			'TL' => '東帝汶',
 			'TM' => '土庫曼',
 			'TN' => '突尼西亞',
 			'TO' => '東加',
 			'TR' => '土耳其',
 			'TT' => '千里達同多巴哥',
 			'TV' => '吐瓦魯',
 			'TW' => '台灣',
 			'TZ' => '坦尚尼亞',
 			'UA' => '烏克蘭',
 			'UG' => '烏干達',
 			'UM' => '美國本土外小島嶼',
 			'UN' => '聯合國',
 			'US' => '美國',
 			'UY' => '烏拉圭',
 			'UZ' => '烏茲別克',
 			'VA' => '梵蒂岡',
 			'VC' => '聖文森特同格林納丁斯',
 			'VE' => '委內瑞拉',
 			'VG' => '英屬維京群島',
 			'VI' => '美屬維京群島',
 			'VN' => '越南',
 			'VU' => '萬那杜',
 			'WF' => '瓦利斯同富圖納群島',
 			'WS' => '薩摩亞',
 			'XA' => '偽口音',
 			'XB' => '偽 Bidi',
 			'XK' => '科索沃',
 			'YE' => '也門',
 			'YT' => '馬約特',
 			'ZA' => '南非',
 			'ZM' => '尚比亞',
 			'ZW' => '辛巴威',
 			'ZZ' => '未知區域',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => '傳統德語拼字學',
 			'1994' => '標準雷西亞拼字',
 			'1996' => '1996 年的德語拼字學',
 			'1606NICT' => '中世紀晚期法文（至1606年）',
 			'1694ACAD' => '早期現代法文',
 			'1959ACAD' => '白俄羅斯文（學術）',
 			'ALALC97' => '美國國會圖書館標準方案羅馬化（1997年版）',
 			'ALUKU' => '阿魯庫方言',
 			'AREVELA' => '亞美尼亞東部',
 			'AREVMDA' => '亞美尼亞西部',
 			'BAKU1926' => '統一土耳其拉丁字母',
 			'BAUDDHA' => '佛教混合梵文',
 			'BISCAYAN' => '比斯開方言',
 			'BISKE' => 'San Giorgio/Bila 方言',
 			'BOONT' => '布恩特林方言',
 			'EMODENG' => '早期現代英語',
 			'FONIPA' => 'IPA 拼音',
 			'FONUPA' => 'UPA 拼音',
 			'FONXSAMP' => 'X-SAMPA 音標',
 			'HEPBURN' => '平文式羅馬字',
 			'HOGNORSK' => '高地挪威文',
 			'ITIHASA' => '史詩梵文',
 			'JAUER' => '米茲泰爾方言',
 			'JYUTPING' => '香港語言學學會粵語拼音',
 			'KKCOR' => '通用康沃爾文拼字',
 			'LAUKIKA' => '傳統梵文',
 			'LIPAW' => '雷西亞利波瓦方言',
 			'LUNA1918' => '俄羅斯文拼字（1917年後）',
 			'MONOTON' => '希臘文單調正字法',
 			'NDYUKA' => '蘇利南恩都卡方言',
 			'NEDIS' => '那提松尼方言',
 			'NJIVA' => '雷西亞尼瓦方言',
 			'OSOJS' => '雷西亞歐西亞柯方言',
 			'PAMAKA' => '蘇利南帕馬卡方言',
 			'PETR1708' => '俄羅斯文拼字（1708 年）',
 			'PINYIN' => '漢語拼音',
 			'POLYTON' => '希臘文多調正字法',
 			'POSIX' => '電腦',
 			'PUTER' => '瑞士普特爾方言',
 			'REVISED' => '已修訂的拼字學',
 			'ROZAJ' => '雷西亞方言',
 			'RUMGR' => '羅曼什文',
 			'SAAHO' => '薩霍文',
 			'SCOTLAND' => '蘇格蘭標準英語',
 			'SCOUSE' => '利物浦方言',
 			'SOLBA' => '雷西亞史托維薩方言',
 			'SURMIRAN' => '瑞士蘇邁拉方言',
 			'SURSILV' => '瑞士蘇瑟瓦方言',
 			'SUTSILV' => '瑞士蘇希瓦方言',
 			'TARASK' => '白俄羅斯文傳統拼字',
 			'UCCOR' => '統一康沃爾文拼字',
 			'UCRCOR' => '統一康沃爾文修訂拼字',
 			'ULSTER' => '愛爾蘭阿爾斯特方言',
 			'VAIDIKA' => '吠陀梵文',
 			'VALENCIA' => '瓦倫西亞文',
 			'VALLADER' => '瑞士瓦勒德方言',
 			'WADEGILE' => '威妥瑪式拼音',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => '曆法',
 			'cf' => '貨幣格式',
 			'colalternate' => '略過符號排序',
 			'colbackwards' => '反向重音排序',
 			'colcasefirst' => '大寫/小寫排列',
 			'colcaselevel' => '區分大小寫排序',
 			'collation' => '排序',
 			'colnormalization' => '正規化排序',
 			'colnumeric' => '數字排序',
 			'colstrength' => '排序強度',
 			'currency' => '貨幣',
 			'hc' => '時間週期（12 小時制與 24 小時制）',
 			'lb' => '換行樣式',
 			'ms' => '度量單位系統',
 			'numbers' => '數字',
 			'timezone' => '時區',
 			'va' => '區域變異',
 			'x' => '專用區',

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
 				'buddhist' => q{佛曆},
 				'chinese' => q{農曆},
 				'coptic' => q{科普特曆},
 				'dangi' => q{檀紀曆},
 				'ethiopic' => q{衣索比亞曆},
 				'ethiopic-amete-alem' => q{衣索比亞曆 (Amete Alem)},
 				'gregorian' => q{公曆},
 				'hebrew' => q{希伯來曆},
 				'indian' => q{印度國曆},
 				'islamic' => q{伊斯蘭曆},
 				'islamic-civil' => q{伊斯蘭民用曆},
 				'islamic-rgsa' => q{伊斯蘭新月曆},
 				'islamic-tbla' => q{伊斯蘭天文曆},
 				'islamic-umalqura' => q{伊斯蘭曆 (烏姆庫拉)},
 				'iso8601' => q{國際標準 ISO 8601},
 				'japanese' => q{日本曆},
 				'persian' => q{波斯曆},
 				'roc' => q{民國曆},
 			},
 			'cf' => {
 				'account' => q{會計貨幣格式},
 				'standard' => q{標準貨幣格式},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{排序符號},
 				'shifted' => q{略過符號排序},
 			},
 			'colbackwards' => {
 				'no' => q{正常排序重音},
 				'yes' => q{依反向重音排序},
 			},
 			'colcasefirst' => {
 				'lower' => q{優先排序小寫},
 				'no' => q{正常大小寫順序排序},
 				'upper' => q{優先排序大寫},
 			},
 			'colcaselevel' => {
 				'no' => q{不分大小寫排序},
 				'yes' => q{依大小寫排序},
 			},
 			'collation' => {
 				'big5han' => q{繁體中文排序 - Big5},
 				'dictionary' => q{字典排序},
 				'ducet' => q{預設 Unicode 排序},
 				'eor' => q{歐洲排序規則},
 				'gb2312han' => q{簡體中文排序 - GB2312},
 				'phonebook' => q{電話簿排序},
 				'phonetic' => q{發音排序},
 				'pinyin' => q{拼音排序},
 				'search' => q{一般用途搜尋},
 				'searchjl' => q{韓文子音排序},
 				'standard' => q{標準排序},
 				'stroke' => q{筆畫排序},
 				'traditional' => q{傳統排序},
 				'unihan' => q{部首筆畫排序},
 				'zhuyin' => q{注音排序},
 			},
 			'colnormalization' => {
 				'no' => q{非正規化排序},
 				'yes' => q{依正規化排序 Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{個別排序數字},
 				'yes' => q{依數字順序排序數字},
 			},
 			'colstrength' => {
 				'identical' => q{全部排序},
 				'primary' => q{僅排序基礎字母},
 				'quaternary' => q{排序重音/大小寫/全半形/假名},
 				'secondary' => q{排序重音},
 				'tertiary' => q{排序重音/大小寫/全半形},
 			},
 			'd0' => {
 				'fwidth' => q{全形},
 				'hwidth' => q{半形},
 				'npinyin' => q{數值},
 			},
 			'hc' => {
 				'h11' => q{12 小時制 (0–11)},
 				'h12' => q{12 小時制 (1–12)},
 				'h23' => q{24 小時制 (0–23)},
 				'h24' => q{24 小時制 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{寬鬆換行樣式},
 				'normal' => q{一般換行樣式},
 				'strict' => q{強制換行樣式},
 			},
 			'm0' => {
 				'bgn' => q{美國地名委員會},
 				'ungegn' => q{聯合國地名專家組},
 			},
 			'ms' => {
 				'metric' => q{公制},
 				'uksystem' => q{英制度量單位系統},
 				'ussystem' => q{美制度量單位系統},
 			},
 			'numbers' => {
 				'arab' => q{阿拉伯-印度數字},
 				'arabext' => q{阿拉伯-印度擴充數字},
 				'armn' => q{亞美尼亞數字},
 				'armnlow' => q{小寫亞美尼亞數字},
 				'bali' => q{峇里文數字},
 				'beng' => q{孟加拉數字},
 				'brah' => q{婆羅米數字},
 				'cakm' => q{查克馬數字},
 				'cham' => q{占文數字},
 				'deva' => q{梵文數字},
 				'ethi' => q{衣索比亞數字},
 				'finance' => q{金融數字},
 				'fullwide' => q{全形數字},
 				'geor' => q{喬治亞數字},
 				'grek' => q{希臘數字},
 				'greklow' => q{小寫希臘數字},
 				'gujr' => q{古吉拉特數字},
 				'guru' => q{古爾穆奇數字},
 				'hanidec' => q{中文十進位數字},
 				'hans' => q{小寫簡體中文數字},
 				'hansfin' => q{大寫簡體中文數字},
 				'hant' => q{小寫繁體中文數字},
 				'hantfin' => q{大寫繁體中文數字},
 				'hebr' => q{希伯來數字},
 				'java' => q{爪哇文數字},
 				'jpan' => q{小寫日文數字},
 				'jpanfin' => q{大寫日文數字},
 				'kali' => q{克耶數字},
 				'khmr' => q{高棉數字},
 				'knda' => q{坎那達數字},
 				'lana' => q{老傣文數字},
 				'lanatham' => q{蘭納文數字},
 				'laoo' => q{寮國數字},
 				'latn' => q{阿拉伯數字},
 				'lepc' => q{西納文數字},
 				'limb' => q{林布文數字},
 				'mlym' => q{馬來亞拉姆數字},
 				'mong' => q{蒙古數字},
 				'mtei' => q{曼尼普爾數字},
 				'mymr' => q{緬甸數字},
 				'mymrshan' => q{緬甸撣文數字},
 				'native' => q{原始數字},
 				'nkoo' => q{曼德數字},
 				'olck' => q{桑塔利文數字},
 				'orya' => q{歐利亞數字},
 				'osma' => q{奧斯曼亞數字},
 				'roman' => q{羅馬數字},
 				'romanlow' => q{小寫羅馬數字},
 				'saur' => q{索拉什特拉文數字},
 				'shrd' => q{夏拉達數字},
 				'sora' => q{索朗桑朋數字},
 				'sund' => q{巽他數字},
 				'takr' => q{塔卡里數字},
 				'talu' => q{新傣仂文數字},
 				'taml' => q{坦米爾數字},
 				'tamldec' => q{坦米爾數字},
 				'telu' => q{泰盧固數字},
 				'thai' => q{泰文數字},
 				'tibt' => q{西藏數字},
 				'traditional' => q{傳統數字},
 				'vaii' => q{瓦伊文數字},
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
			'metric' => q{公制},
 			'UK' => q{英制},
 			'US' => q{美制},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => '語言：{0}',
 			'script' => '文字：{0}',
 			'region' => '地區：{0}',

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
			auxiliary => qr{[乍 仂 伏 佐 侶 僳 兆 兌 兹 凸 别 券 勳 卑 卞 占 叶 嘅 堤 墎 壤 奥 孜 峇 嶼 巽 栗 楔 涅 渾 澎 灘 燦 狄 琳 瑚 甫 碑 礁 纜 艇 芒 苗 茨 蓬 蚩 蜀 裘 謬 酋 隴 雀 髪]},
			index => ['一', '丁', '丈', '不', '且', '丞', '並', '串', '乘', '乾', '亂', '亭', '傀', '僎', '僵', '儐', '償', '儳', '儷', '儻', '叢', '嚴', '囌', '囑', '廳'],
			main => qr{[一 丁 七 丈 三 上 下 丌 不 丑 且 世 丘 丙 丟 並 中 串 丸 丹 主 乃 久 么 之 乎 乏 乖 乘 乙 九 也 乾 亂 了 予 事 二 于 云 互 五 井 些 亞 亡 交 亥 亦 亨 享 京 亮 人 什 仁 仇 今 介 仍 仔 他 付 仙 代 令 以 仰 仲 件 任 份 企 伊 伍 伐 休 伙 伯 估 伴 伸 似 伽 但 佈 佉 位 低 住 佔 何 余 佛 作 你 佩 佳 使 來 例 供 依 侯 侵 便 係 促 俄 俊 俏 俗 保 俠 信 修 俱 俾 倉 個 倍 們 倒 候 倚 借 倫 值 假 偉 偏 做 停 健 側 偵 偶 偷 偽 傅 傑 傘 備 傢 傣 傲 傳 傷 傻 傾 僅 像 僑 僧 價 儀 億 儒 儘 優 允 元 兄 充 兇 先 光 克 免 兒 兔 入 內 全 兩 八 公 六 兮 共 兵 其 具 典 兼 冊 再 冒 冠 冬 冰 冷 准 凋 凌 凍 凝 凡 凰 凱 出 函 刀 分 切 刊 列 初 判 別 刨 利 刪 刮 到 制 刷 刺 刻 剃 則 剌 前 剛 剩 剪 副 割 創 劃 劇 劉 劍 力 功 加 助 努 劫 勁 勇 勉 勒 動 務 勝 勞 勢 勤 勵 勸 勾 勿 包 匈 化 北 匯 匹 區 十 千 升 午 半 卒 卓 協 南 博 卜 卡 卯 印 危 即 卷 卹 卻 厄 厘 厚 原 厭 厲 去 參 又 及 友 反 叔 取 受 口 古 句 另 只 叫 召 叭 可 台 史 右 司 吃 各 合 吉 吊 同 名 后 吐 向 吒 君 吝 吞 吟 吠 否 吧 含 吳 吵 吸 吹 吾 呀 呂 呆 告 呢 周 味 呵 呼 命 和 咖 咦 咧 咪 咬 咱 哀 品 哇 哈 哉 哎 員 哥 哦 哩 哪 哭 哲 唇 唉 唐 唔 唬 售 唯 唱 唵 唷 唸 商 啊 問 啟 啡 啤 啥 啦 啪 喀 喂 善 喇 喊 喔 喜 喝 喪 喬 單 喲 喵 嗎 嗚 嗨 嗯 嘆 嘉 嘗 嘛 嘴 嘻 嘿 噁 噓 器 噴 嚇 嚏 嚴 囉 四 回 因 困 固 圈 國 圍 園 圓 圖 團 圜 土 在 圭 地 圾 址 均 坎 坐 坑 坡 坤 坦 坪 垂 垃 型 埃 城 埔 域 執 培 基 堂 堅 堆 堡 堪 報 場 塊 塔 塗 塞 填 塵 境 墅 墓 增 墟 墨 墮 墳 壁 壇 壓 壘 壞 壢 壩 士 壬 壯 壺 壽 夏 夕 外 多 夜 夠 夢 夥 大 天 太 夫 央 失 夷 夸 夾 奇 奈 奉 奎 奏 契 奔 套 奧 奪 奮 女 奴 奶 她 好 如 妙 妝 妥 妨 妮 妳 妹 妻 姆 姊 始 姐 姑 姓 委 姿 威 娃 娘 娛 婁 婆 婚 婦 媒 媽 嫌 嫩 子 孔 孕 字 存 孝 孟 季 孤 孩 孫 孵 學 它 宅 宇 守 安 宋 完 宏 宗 官 宙 定 宛 宜 客 宣 室 宮 害 家 容 宿 寂 寄 寅 密 富 寒 寞 察 寢 實 寧 寨 審 寫 寬 寮 寵 寶 寺 封 射 將 專 尊 尋 對 導 小 少 尖 尚 尤 就 尺 尼 尾 尿 局 屁 居 屆 屋 屍 屏 屑 展 屠 層 屬 山 岡 岩 岸 峰 島 峽 崇 崙 崴 嵐 嶺 川 州 巡 工 左 巧 巨 巫 差 己 已 巳 巴 巷 市 布 希 帕 帖 帚 帛 帝 帥 師 席 帳 帶 常 帽 幅 幕 幟 幣 幫 干 平 年 幸 幹 幻 幼 幽 幾 庇 床 序 底 店 庚 府 度 座 庫 庭 康 庸 廈 廉 廖 廟 廠 廢 廣 廳 延 廷 建 弄 式 引 弗 弘 弟 弦 弱 張 強 彈 彊 彌 彎 彝 彞 形 彥 彩 彬 彭 彰 影 役 彼 往 征 待 很 律 後 徐 徑 徒 得 從 復 微 徵 德 徹 心 必 忌 忍 志 忘 忙 忠 忡 快 念 忽 怎 怒 怕 怖 思 怡 急 性 怨 怪 恆 恐 恢 恥 恨 恩 恭 息 恰 悅 悉 悔 悟 悠 您 悲 悶 情 惑 惜 惠 惡 惱 想 惹 愁 愈 愉 意 愚 愛 感 慈 態 慕 慘 慢 慣 慧 慮 慰 慶 慾 憂 憊 憐 憑 憲 憶 憾 懂 應 懨 懶 懷 懼 戀 戈 戊 戌 成 我 戒 或 截 戰 戲 戴 戶 房 所 扁 扇 手 才 扎 打 托 扣 扥 扭 扮 扯 批 找 承 技 抄 把 抓 投 抗 折 披 抬 抱 抵 抹 抽 拆 拉 拋 拍 拏 拒 拔 拖 招 拜 括 拳 拼 拾 拿 持 指 按 挑 挖 挪 振 挺 捏 捐 捕 捧 捨 捲 捷 掃 授 掉 掌 排 掛 掠 採 探 接 控 推 措 掰 描 提 插 揚 換 握 揮 援 揹 損 搏 搖 搜 搞 搬 搭 搶 摀 摘 摩 摸 撐 撒 撕 撞 撣 撥 播 撲 撾 撿 擁 擇 擊 擋 操 擎 擔 據 擠 擦 擬 擴 擺 擾 攀 攝 攤 支 收 改 攻 放 政 故 效 敍 敏 救 敗 敘 教 敝 敞 敢 散 敦 敬 整 敵 數 文 斐 斑 斗 料 斜 斧 斯 新 斷 方 於 施 旁 旅 旋 族 旗 既 日 旦 早 旭 旺 昂 昆 昇 昌 明 昏 易 星 映 春 昨 昭 是 時 晉 晒 晚 晨 普 景 晴 晶 智 暑 暖 暗 暫 暮 暴 曆 曇 曉 曬 曰 曲 曳 更 書 曼 曾 替 最 會 月 有 朋 服 朔 朗 望 朝 期 木 未 末 本 札 朱 朵 杉 李 材 村 杖 杜 束 杯 杰 東 松 板 析 林 果 枝 枯 架 柏 某 染 柔 查 柬 柯 柳 柴 栓 校 核 根 格 栽 桃 案 桌 桑 梁 梅 條 梨 梯 械 梵 棄 棉 棋 棍 棒 棕 棚 森 棺 椅 植 椒 椰 楊 楓 楚 業 極 概 榜 榮 構 槌 槍 樂 樓 標 樞 模 樣 樹 橄 橇 橋 橘 橙 機 橫 檀 檔 檢 檬 檸 櫚 櫻 欄 權 欖 欠 次 欣 欲 欺 欽 款 歉 歌 歐 歡 止 正 此 步 武 歲 歷 歸 死 殊 残 殘 殭 段 殺 殼 毀 毅 母 每 毒 比 毛 毫 氏 民 氣 水 永 汁 求 汗 汝 江 池 污 汪 汶 決 汽 沃 沈 沉 沒 沖 沙 沫 沮 河 油 治 沿 況 泉 泊 法 泡 波 泣 泥 注 泰 泳 洋 洗 洛 洞 洩 洪 洲 活 洽 派 流 浣 浦 浩 浪 浮 浴 海 涇 消 涉 涎 涮 涯 液 涵 涼 淇 淋 淑 淚 淡 淨 深 混 淺 清 減 渡 測 港 游 湖 湘 湯 源 準 溜 溝 溪 溫 滄 滅 滋 滑 滴 滾 滿 漂 漏 演 漠 漢 漫 漲 漸 漿 潔 潘 潛 潮 澡 澤 澳 激 濃 濕 濟 濤 濫 濱 瀏 灌 灣 火 灰 災 炎 炮 炸 為 烈 烏 烘 烤 烹 焊 焙 無 焦 焰 然 煙 煞 照 煩 煮 熊 熟 熱 燃 燈 燒 燙 營 爆 爍 爐 爛 爪 爬 爭 爵 父 爸 爺 爽 爾 牆 片 版 牌 牙 牛 牠 牧 物 牲 特 牽 犀 犧 犬 犯 狀 狂 狐 狗 狠 狡 狸 狼 猛 猜 猩 猴 猶 猾 猿 獄 獅 獎 獨 獲 獸 獺 獻 獾 玄 率 玉 王 玩 玫 玲 玻 珊 珍 珠 珥 班 現 球 理 琉 琪 琴 瑙 瑜 瑞 瑟 瑤 瑪 瑰 環 瓜 瓢 瓦 瓶 甕 甘 甚 甜 生 產 用 田 由 甲 申 男 甸 界 留 畢 略 番 畫 異 當 疆 疏 疑 疲 疼 疾 病 痕 痛 痴 瘋 瘦 瘧 療 癡 癸 登 發 白 百 皂 的 皆 皇 皮 皿 盃 盆 盈 益 盔 盛 盜 盟 盡 監 盤 盥 盧 目 盲 直 相 盼 盾 省 眉 看 真 眠 眼 眾 睏 睛 睡 督 瞇 瞌 瞧 瞪 瞭 矛 矣 知 短 石 砂 砍 研 砲 破 硬 碎 碗 碟 碧 碩 碰 確 碼 磁 磚 磨 磯 礎 礙 礫 示 社 祈 祕 祖 祚 祛 祝 神 祥 票 祿 禁 禍 禎 福 禪 禮 禱 禿 秀 私 秋 科 秒 秘 租 秤 秦 移 稅 程 稍 種 稱 稻 稿 穀 穆 穌 積 穩 究 穹 空 穿 突 窄 窗 窩 窮 窶 立 站 竟 章 童 端 競 竹 竿 笑 笛 符 笨 第 筆 等 筋 答 策 筷 箏 箔 算 管 箭 箱 節 範 篇 築 篷 簡 簫 簽 簿 籃 籌 籍 籠 籤 米 粉 粗 粵 精 糊 糕 糖 糟 糥 系 糾 紀 約 紅 紉 納 紐 純 紙 級 紛 素 索 紫 紮 累 細 紳 紹 終 組 結 絕 絡 給 統 絲 經 綜 綠 維 綱 網 綽 綿 緊 緒 線 緣 編 緩 緬 緯 練 縛 縣 縫 縮 縱 總 績 繁 繃 繆 織 繞 繡 繩 繪 繳 繼 續 纖 缸 缺 罈 罐 罕 罩 罪 置 罰 署 罵 罷 羅 羊 美 羞 群 義 羽 翁 習 翔 翰 翹 翻 翼 耀 老 考 者 而 耍 耐 耗 耳 耶 聊 聖 聚 聞 聯 聰 聲 職 聽 聾 肉 肌 肚 股 肥 肩 肯 育 肺 背 胎 胖 胞 胡 胸 能 脆 脈 脖 脫 腐 腓 腔 腦 腰 腳 腹 腿 膚 膠 膽 臂 臉 臘 臟 臣 臥 臨 自 臭 至 致 臺 與 興 舉 舊 舌 舍 舒 舞 舟 航 般 船 艦 良 色 艾 芙 芝 芬 芭 花 芳 芽 苣 若 苦 英 茄 茅 茫 茲 茵 茶 茸 草 荒 荷 荼 莉 莊 莎 莓 莖 莫 菇 菌 菜 菩 華 菲 萄 萊 萎 萬 萵 落 葉 著 葛 葡 葵 蒂 蒙 蒜 蒲 蒸 蒼 蓄 蓉 蓋 蓮 蔔 蔕 蔡 蔣 蔥 蔬 蕉 蕭 蕾 薄 薑 薦 薩 薪 薯 藉 藍 藏 藝 藤 藥 蘆 蘇 蘋 蘑 蘭 蘿 虎 處 虛 號 虧 蚊 蚓 蚯 蛇 蛋 蛙 蜂 蜜 蜥 蜴 蝙 蝟 蝠 蝦 蝶 螂 螃 融 螞 螢 螺 蟀 蟄 蟋 蟑 蟲 蟳 蟹 蟻 蠅 蠍 蠕 蠣 蠻 血 行 術 街 衛 衝 衡 衣 表 衫 袋 袍 被 裁 裂 裏 裕 補 裝 裡 裱 裹 製 複 褐 褲 襪 襯 西 要 覆 見 規 視 親 覺 覽 觀 角 解 觸 言 訂 計 訊 討 訓 託 記 訝 訥 訪 設 許 訴 診 註 証 評 詞 詢 試 詩 話 該 詳 誇 誌 認 誓 誕 語 誠 誤 說 誰 課 誼 調 談 請 諒 論 諸 諺 諾 謀 謂 謎 講 謝 證 識 譜 警 譯 議 護 譽 讀 變 讓 讚 谷 豆 豈 豎 豐 豔 象 豪 豬 豹 貌 貓 貝 貞 負 財 貢 貨 貪 貫 責 貴 買 費 貼 賀 資 賈 賓 賜 賞 賢 賣 賤 賦 質 賭 賴 賺 購 賽 贈 贊 贏 贛 赤 赫 走 起 超 越 趕 趙 趣 趨 足 跆 跌 跎 跑 距 跟 跡 跪 路 跳 踏 踢 踩 蹟 蹤 躍 身 躲 車 軌 軍 軒 軟 軸 較 載 輔 輕 輛 輝 輩 輪 輯 輸 轉 轎 轟 辛 辜 辣 辦 辨 辭 辯 辰 辱 農 迅 迎 近 返 迦 迪 迫 述 迴 迷 追 退 送 逃 逆 透 逐 途 這 通 逛 逝 速 造 逢 連 週 進 逸 逼 遇 遊 運 遍 過 道 達 違 遙 遜 遠 適 遭 遮 遲 遷 選 遺 避 邀 邁 還 邊 邏 那 邦 邪 邱 郎 部 郭 郵 都 鄂 鄉 鄙 鄭 鄰 酉 配 酒 酪 酷 酸 醉 醒 醜 醫 醬 采 釋 里 重 野 量 金 針 釣 鈴 鉅 鉢 鉤 銀 銅 銖 銘 銳 銷 鋁 鋒 鋼 錄 錢 錦 錨 錫 錯 錶 鍊 鍋 鍵 鍾 鎊 鎖 鎮 鏈 鏡 鏢 鐘 鐡 鐵 鑑 鑿 長 門 閃 閉 開 閏 閒 間 閣 閩 閱 闆 闊 闍 闐 關 闡 阱 防 阻 阿 陀 附 降 限 院 陣 除 陪 陰 陳 陵 陶 陷 陸 陽 隆 隊 階 隔 際 障 隨 險 隱 隻 雄 雅 集 雉 雌 雖 雙 雜 雞 離 難 雨 雪 雲 零 雷 電 需 震 霍 霜 霧 露 霸 霹 靂 靈 青 靖 静 靜 非 靠 面 革 靴 靼 鞋 鞭 韃 韋 韓 音 韻 響 頁 頂 項 順 須 頌 預 頑 頓 頗 領 頞 頭 頸 頻 顆 題 額 顏 願 顛 類 顧 顯 風 颱 飄 飆 飛 食 飪 飯 飲 飽 飾 餃 餅 養 餌 餐 餘 餚 館 餾 首 香 馬 駐 駕 駛 駝 駱 騎 騙 騷 驅 驕 驗 驚 骨 體 高 髮 鬆 鬍 鬥 鬧 鬱 鬼 魁 魂 魅 魔 魚 魯 魷 鮑 鮮 鯊 鯨 鱷 鳥 鳩 鳳 鳴 鴨 鴻 鵝 鵡 鶴 鷹 鸚 鹽 鹿 麗 麥 麵 麻 麼 黃 黎 黑 默 黛 點 黨 鼓 鼠 鼬 鼻 齊 齋 齒 齡 龍 龐 龜]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9 〇 一 七 三 九 二 五 八 六 四]},
			punctuation => qr{[‾﹉﹊﹋﹌ _＿﹍﹎﹏︳︴ \-－﹣ ‐‑ –︲ —﹘︱ ,，﹐ 、﹑ ;；﹔ \:：﹕ !！﹗ ?？﹖ .．﹒ ‥︰ … 。 · ＇‘’ "＂“”〝〞 (（﹙︵ )）﹚︶ \[［ \]］ \N{U+FF5B.FE5B.FE37}｝﹜︸ 〈︿ 〉﹀ 《︽ 》︾ 「﹁ 」﹂ 『﹃ 』﹄ 【︻ 】︼ 〔﹝︹ 〕﹞︺ § @＠﹫ *＊﹡ /／ \\＼﹨ \&＆﹠ #＃﹟ %％﹪ ‰ † ‡ ‧ ′ ″ ‵ 〃 ※]},
		};
	},
EOT
: sub {
		return { index => ['一', '丁', '丈', '不', '且', '丞', '並', '串', '乘', '乾', '亂', '亭', '傀', '僎', '僵', '儐', '償', '儳', '儷', '儻', '叢', '嚴', '囌', '囑', '廳'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{？},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{「},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{」},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{『},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{』},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'area-square-centimeter' => {
						'per' => q(每平方厘米 {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'per' => q(每平方厘米 {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'per' => q(每平方英吋 {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'per' => q(每平方英吋 {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'per' => q(每平方公里 {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'per' => q(每平方公里 {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'per' => q(每平方米 {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'per' => q(每平方米 {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'per' => q(每平方英里 {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'per' => q(每平方英里 {0}),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(十億分點濃度),
						'other' => q({0} 十億分點濃度),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(十億分點濃度),
						'other' => q({0} 十億分點濃度),
					},
					# Long Unit Identifier
					'duration-century' => {
						'other' => q({0} 個世紀),
					},
					# Core Unit Identifier
					'century' => {
						'other' => q({0} 個世紀),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q(每天 {0}),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q(每天 {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q(每小時 {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q(每小時 {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'per' => q(每分鐘 {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'per' => q(每分鐘 {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q(每月 {0}),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q(每月 {0}),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(晚),
						'other' => q({0} 晚),
						'per' => q({0}/晚),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(晚),
						'other' => q({0} 晚),
						'per' => q({0}/晚),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'per' => q(每季 {0}),
					},
					# Core Unit Identifier
					'quarter' => {
						'per' => q(每季 {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'per' => q(每秒 {0}),
					},
					# Core Unit Identifier
					'second' => {
						'per' => q(每秒 {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'per' => q(每週 {0}),
					},
					# Core Unit Identifier
					'week' => {
						'per' => q(每週 {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q(每年 {0}),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q(每年 {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} 伏特),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} 伏特),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} 千焦耳),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} 千焦耳),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(每厘米點數),
						'other' => q({0} 點/厘米),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(每厘米點數),
						'other' => q({0} 點/厘米),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(每吋點數),
						'other' => q({0} 點/吋),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(每吋點數),
						'other' => q({0} 點/吋),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(字體 em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(字體 em),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(每吋像素),
						'other' => q({0} 像素/吋),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(每吋像素),
						'other' => q({0} 像素/吋),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'per' => q(每厘米 {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'per' => q(每厘米 {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q(每英呎 {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q(每英呎 {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q(每英吋 {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q(每英吋 {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'per' => q(每公里 {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'per' => q(每公里 {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'per' => q(每米 {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'per' => q(每米 {0}),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'other' => q({0}格令),
					},
					# Core Unit Identifier
					'grain' => {
						'other' => q({0}格令),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'per' => q(每克 {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'per' => q(每克 {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'per' => q(每公斤 {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'per' => q(每公斤 {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q(每安士 {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q(每安士 {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q(每磅 {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q(每磅 {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q(每 {1} {0}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q(每 {1} {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'other' => q(每平方吋 {0} 磅),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'other' => q(每平方吋 {0} 磅),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q(每小時 {0} 公里),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q(每小時 {0} 公里),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(光速),
						'other' => q({0} 光速),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(光速),
						'other' => q({0} 光速),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q(每秒 {0} 米),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q(每秒 {0} 米),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q(每小時 {0} 英里),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q(每小時 {0} 英里),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'other' => q(攝氏 {0} 度),
					},
					# Core Unit Identifier
					'celsius' => {
						'other' => q(攝氏 {0} 度),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q(華氏 {0} 度),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q(華氏 {0} 度),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'per' => q(每立方厘米 {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'per' => q(每立方厘米 {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'per' => q(每立方米 {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'per' => q(每立方米 {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q(英制甜品匙{0}匙),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q(英制甜品匙{0}匙),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q(每加侖 {0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q(每加侖 {0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'per' => q(每英制加侖 {0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'per' => q(每英制加侖 {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'per' => q(每公升 {0}),
					},
					# Core Unit Identifier
					'liter' => {
						'per' => q(每公升 {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'other' => q({0}ppb),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'other' => q({0}ppb),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(晚),
						'other' => q({0}晚),
						'per' => q({0}/晚),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(晚),
						'other' => q({0}晚),
						'per' => q({0}/晚),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q(每英吋 {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q(每英吋 {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'per' => q(每克 {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'per' => q(每克 {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'per' => q(每公斤 {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'per' => q(每公斤 {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q(每安士 {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q(每安士 {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q(每磅 {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q(每磅 {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'other' => q(每平方吋 {0} 磅),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'other' => q(每平方吋 {0} 磅),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q(每小時 {0} 公里),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q(每小時 {0} 公里),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(光速),
						'other' => q({0}光速),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(光速),
						'other' => q({0}光速),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q(每秒 {0} 米),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q(每秒 {0} 米),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q(每小時 {0} 英里),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q(每小時 {0} 英里),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(方向),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(方向),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(二進制千{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(二進制千{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(二進制兆{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(二進制兆{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(二進制吉{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(二進制吉{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(二進制太{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(二進制太{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(二進制拍{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(二進制拍{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(二進制艾{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(二進制艾{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(二進制澤{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(二進制澤{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(二進制堯{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(二進制堯{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(分{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(分{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(皮{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(皮{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(飛{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(飛{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(埃{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(埃{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(厘{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(厘{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(仄{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(仄{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(麼{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(麼{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto {0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto {0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(毫{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(毫{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quecto {0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto {0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(微{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(微{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(納{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(納{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(十{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(十{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(太{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(太{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(拍{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(拍{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(艾{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(艾{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(百{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(百{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(澤{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(澤{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(堯{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(堯{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna {0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna {0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(千{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(千{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quetta {0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta {0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(兆{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(兆{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(吉{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(吉{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G 力),
						'other' => q({0} G 力),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G 力),
						'other' => q({0} G 力),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(米/平方秒),
						'other' => q(每平方秒 {0} 米),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(米/平方秒),
						'other' => q(每平方秒 {0} 米),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(角分),
						'other' => q({0} 角分),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(角分),
						'other' => q({0} 角分),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(角秒),
						'other' => q({0} 角秒),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(角秒),
						'other' => q({0} 角秒),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(角度),
						'other' => q({0} 度),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(角度),
						'other' => q({0} 度),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(弧度),
						'other' => q({0} 弧度),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(弧度),
						'other' => q({0} 弧度),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(圈),
						'other' => q({0} 圈),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(圈),
						'other' => q({0} 圈),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(英畝),
						'other' => q({0} 英畝),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(英畝),
						'other' => q({0} 英畝),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(德南),
						'other' => q({0} 德南),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(德南),
						'other' => q({0} 德南),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(公頃),
						'other' => q({0} 公頃),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(公頃),
						'other' => q({0} 公頃),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q(每平方厘米{0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0} 平方厘米),
						'per' => q(每平方厘米{0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(平方英呎),
						'other' => q({0} 平方英呎),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(平方英呎),
						'other' => q({0} 平方英呎),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(平方英吋),
						'other' => q({0} 平方英吋),
						'per' => q(每平方英吋{0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(平方英吋),
						'other' => q({0} 平方英吋),
						'per' => q(每平方英吋{0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0} 平方公里),
						'per' => q(每平方公里{0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0} 平方公里),
						'per' => q(每平方公里{0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q(每平方米{0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0} 平方米),
						'per' => q(每平方米{0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(平方英里),
						'other' => q({0} 平方英里),
						'per' => q(每平方英里{0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0} 平方英里),
						'per' => q(每平方英里{0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(平方碼),
						'other' => q({0} 平方碼),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(平方碼),
						'other' => q({0} 平方碼),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(項),
						'other' => q({0} 項),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(項),
						'other' => q({0} 項),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(毫克/公合),
						'other' => q({0} 毫克/公合),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(毫克/公合),
						'other' => q({0} 毫克/公合),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(毫摩爾/公升),
						'other' => q({0} 毫摩爾/公升),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(毫摩爾/公升),
						'other' => q({0} 毫摩爾/公升),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(摩爾),
						'other' => q({0} 摩爾),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(摩爾),
						'other' => q({0} 摩爾),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(百萬分率),
						'other' => q({0} 百萬分率),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(百萬分率),
						'other' => q({0} 百萬分率),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(點子),
						'other' => q({0} 點子),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(點子),
						'other' => q({0} 點子),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(濃度/十億),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(濃度/十億),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(公升/100 公里),
						'other' => q({0} 公升/100 公里),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(公升/100 公里),
						'other' => q({0} 公升/100 公里),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q({0} 公升/公里),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q({0} 公升/公里),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(英里/加侖),
						'other' => q({0} 英里/加侖),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(英里/加侖),
						'other' => q({0} 英里/加侖),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(英里/英制加侖),
						'other' => q({0} 英里/英制加侖),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(英里/英制加侖),
						'other' => q({0} 英里/英制加侖),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(東經{0}),
						'north' => q(北緯{0}),
						'south' => q(南緯{0}),
						'west' => q(西經{0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(東經{0}),
						'north' => q(北緯{0}),
						'south' => q(南緯{0}),
						'west' => q(西經{0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(世紀),
						'other' => q({0} 世紀),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(世紀),
						'other' => q({0} 世紀),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(天),
						'other' => q({0} 天),
						'per' => q(每天{0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(天),
						'other' => q({0} 天),
						'per' => q(每天{0}),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(十年),
						'other' => q({0} 個十年),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(十年),
						'other' => q({0} 個十年),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(小時),
						'other' => q({0} 小時),
						'per' => q(每小時{0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(小時),
						'other' => q({0} 小時),
						'per' => q(每小時{0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(微秒),
						'other' => q({0} 微秒),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0} 微秒),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(毫秒),
						'other' => q({0} 毫秒),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0} 毫秒),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(分鐘),
						'other' => q({0} 分鐘),
						'per' => q(每分鐘{0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(分鐘),
						'other' => q({0} 分鐘),
						'per' => q(每分鐘{0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(月),
						'other' => q({0} 個月),
						'per' => q(每月{0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(月),
						'other' => q({0} 個月),
						'per' => q(每月{0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(奈秒),
						'other' => q({0} 奈秒),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(奈秒),
						'other' => q({0} 奈秒),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(晚),
						'other' => q({0} 晚),
						'per' => q({0}/晚),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(晚),
						'other' => q({0} 晚),
						'per' => q({0}/晚),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(季),
						'other' => q({0} 季),
						'per' => q(每季{0}),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(季),
						'other' => q({0} 季),
						'per' => q(每季{0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(秒),
						'other' => q({0} 秒),
						'per' => q(每秒{0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(秒),
						'other' => q({0} 秒),
						'per' => q(每秒{0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(週),
						'other' => q({0} 週),
						'per' => q(每週{0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(週),
						'other' => q({0} 週),
						'per' => q(每週{0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(年),
						'other' => q({0} 年),
						'per' => q(每年{0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(年),
						'other' => q({0} 年),
						'per' => q(每年{0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(安培),
						'other' => q({0} 安培),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(安培),
						'other' => q({0} 安培),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(毫安培),
						'other' => q({0} 毫安培),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(毫安培),
						'other' => q({0} 毫安培),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(歐姆),
						'other' => q({0} 歐姆),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(歐姆),
						'other' => q({0} 歐姆),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(伏特),
						'other' => q({0} 伏),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(伏特),
						'other' => q({0} 伏),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(英制熱量單位),
						'other' => q({0} 英制熱量單位),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(英制熱量單位),
						'other' => q({0} 英制熱量單位),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(卡路里),
						'other' => q({0} 卡路里),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(卡路里),
						'other' => q({0} 卡路里),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(電子伏特),
						'other' => q({0} 電子伏特),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(電子伏特),
						'other' => q({0} 電子伏特),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(大卡),
						'other' => q({0} 大卡),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(大卡),
						'other' => q({0} 大卡),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(焦耳),
						'other' => q({0} 焦耳),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0} 焦耳),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(千焦耳),
						'other' => q({0} 千焦),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(千焦耳),
						'other' => q({0} 千焦),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(千瓦小時),
						'other' => q({0} 千瓦小時),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(千瓦小時),
						'other' => q({0} 千瓦小時),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(美制熱量單位),
						'other' => q({0} 美制熱量單位),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(美制熱量單位),
						'other' => q({0} 美制熱量單位),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(千瓦時/每 100 公里),
						'other' => q({0} 千瓦時/每 100 公里),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(千瓦時/每 100 公里),
						'other' => q({0} 千瓦時/每 100 公里),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(牛頓),
						'other' => q({0} 牛頓),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(牛頓),
						'other' => q({0} 牛頓),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(磅力),
						'other' => q({0} 磅力),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(磅力),
						'other' => q({0} 磅力),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0} 吉赫),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0} 吉赫),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(赫茲),
						'other' => q({0} 赫茲),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(赫茲),
						'other' => q({0} 赫茲),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(千赫),
						'other' => q({0} 千赫),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(千赫),
						'other' => q({0} 千赫),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(兆赫),
						'other' => q({0} 兆赫),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(兆赫),
						'other' => q({0} 兆赫),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(圓點),
						'other' => q({0} 個圓點),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(圓點),
						'other' => q({0} 個圓點),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(百萬像素),
						'other' => q({0} 百萬像素),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(百萬像素),
						'other' => q({0} 百萬像素),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(像素),
						'other' => q({0} 像素),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(像素),
						'other' => q({0} 像素),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(每厘米像素),
						'other' => q({0} 像素/厘米),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(每厘米像素),
						'other' => q({0} 像素/厘米),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(天文單位),
						'other' => q({0} 天文單位),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(天文單位),
						'other' => q({0} 天文單位),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q(每厘米{0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0} 厘米),
						'per' => q(每厘米{0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(公寸),
						'other' => q({0} 公寸),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(公寸),
						'other' => q({0} 公寸),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(地球半徑),
						'other' => q({0} 地球半徑),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(地球半徑),
						'other' => q({0} 地球半徑),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(英尋),
						'other' => q({0} 英尋),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(英尋),
						'other' => q({0} 英尋),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(英呎),
						'other' => q({0} 英呎),
						'per' => q(每英呎{0}),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(英呎),
						'other' => q({0} 英呎),
						'per' => q(每英呎{0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(化朗),
						'other' => q({0} 化朗),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(化朗),
						'other' => q({0} 化朗),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(英吋),
						'other' => q({0} 英吋),
						'per' => q(每英吋{0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(英吋),
						'other' => q({0} 英吋),
						'per' => q(每英吋{0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(公里),
						'other' => q({0} 公里),
						'per' => q(每公里{0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0} 公里),
						'per' => q(每公里{0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(光年),
						'other' => q({0} 光年),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(光年),
						'other' => q({0} 光年),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q(每米{0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(米),
						'other' => q({0} 米),
						'per' => q(每米{0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(微米),
						'other' => q({0} 微米),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0} 微米),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(英里),
						'other' => q({0} 英里),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(英里),
						'other' => q({0} 英里),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(斯堪地那維亞英里),
						'other' => q({0} 斯堪地那維亞英里),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(斯堪地那維亞英里),
						'other' => q({0} 斯堪地那維亞英里),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0} 毫米),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(奈米),
						'other' => q({0} 奈米),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(奈米),
						'other' => q({0} 奈米),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(海里),
						'other' => q({0} 海里),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0} 海里),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(秒差距),
						'other' => q({0} 秒差距),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0} 秒差距),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(皮米),
						'other' => q({0} 皮米),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0} 皮米),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(點),
						'other' => q({0} 點),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(點),
						'other' => q({0} 點),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(太陽半徑),
						'other' => q({0} 太陽半徑),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(太陽半徑),
						'other' => q({0} 太陽半徑),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(碼),
						'other' => q({0} 碼),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(碼),
						'other' => q({0} 碼),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(坎德拉),
						'other' => q({0} 坎德拉),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(坎德拉),
						'other' => q({0} 坎德拉),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(流明),
						'other' => q({0} 流明),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(流明),
						'other' => q({0} 流明),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(勒克斯),
						'other' => q({0} 勒克斯),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(勒克斯),
						'other' => q({0} 勒克斯),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(太陽光度),
						'other' => q({0} 太陽光度),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(太陽光度),
						'other' => q({0} 太陽光度),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(道爾頓),
						'other' => q({0} 道爾頓),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(道爾頓),
						'other' => q({0} 道爾頓),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(地球質量),
						'other' => q({0} 地球質量),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(地球質量),
						'other' => q({0} 地球質量),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(喱),
						'other' => q({0} 喱),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(喱),
						'other' => q({0} 喱),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(克),
						'other' => q({0} 克),
						'per' => q(每克{0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(克),
						'other' => q({0} 克),
						'per' => q(每克{0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(公斤),
						'other' => q({0} 公斤),
						'per' => q(每公斤{0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(公斤),
						'other' => q({0} 公斤),
						'per' => q(每公斤{0}),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(微克),
						'other' => q({0} 微克),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(微克),
						'other' => q({0} 微克),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(毫克),
						'other' => q({0} 毫克),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(毫克),
						'other' => q({0} 毫克),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q(每安士{0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(安士),
						'other' => q({0} 安士),
						'per' => q(每安士{0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(金衡安士),
						'other' => q({0} 金衡安士),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(磅),
						'other' => q({0} 磅),
						'per' => q(每磅{0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(磅),
						'other' => q({0} 磅),
						'per' => q(每磅{0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(太陽質量),
						'other' => q({0} 太陽質量),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(太陽質量),
						'other' => q({0} 太陽質量),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(英石),
						'other' => q({0} 英石),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(英石),
						'other' => q({0} 英石),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(英噸),
						'other' => q({0} 英噸),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(英噸),
						'other' => q({0} 英噸),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(公噸),
						'other' => q({0} 公噸),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(公噸),
						'other' => q({0} 公噸),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0} 吉瓦),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0} 吉瓦),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(千瓦特),
						'other' => q({0} 千瓦特),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(千瓦特),
						'other' => q({0} 千瓦特),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(百萬瓦特),
						'other' => q({0} 百萬瓦特),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(百萬瓦特),
						'other' => q({0} 百萬瓦特),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(毫瓦特),
						'other' => q({0} 毫瓦特),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(毫瓦特),
						'other' => q({0} 毫瓦特),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(瓦特),
						'other' => q({0} 瓦特),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(瓦特),
						'other' => q({0} 瓦特),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(平方{0}),
						'other' => q(平方{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(平方{0}),
						'other' => q(平方{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(立方{0}),
						'other' => q(立方{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(立方{0}),
						'other' => q(立方{0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(巴),
						'other' => q({0} 巴),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(巴),
						'other' => q({0} 巴),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(百帕),
						'other' => q({0} 百帕),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(百帕),
						'other' => q({0} 百帕),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(英吋汞柱),
						'other' => q({0} 英吋汞柱),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(英吋汞柱),
						'other' => q({0} 英吋汞柱),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(千帕),
						'other' => q({0} 千帕),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(千帕),
						'other' => q({0} 千帕),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(兆帕),
						'other' => q({0} 兆帕),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(兆帕),
						'other' => q({0} 兆帕),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(毫巴),
						'other' => q({0} 毫巴),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(毫巴),
						'other' => q({0} 毫巴),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(毫米汞柱),
						'other' => q({0} 毫米汞柱),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(毫米汞柱),
						'other' => q({0} 毫米汞柱),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(帕斯卡),
						'other' => q({0} 帕斯卡),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(帕斯卡),
						'other' => q({0} 帕斯卡),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(磅力/平方英吋),
						'other' => q(每平方吋{0}磅),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(磅力/平方英吋),
						'other' => q(每平方吋{0}磅),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(蒲福氏風級),
						'other' => q(蒲福氏風級 {0} 級),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(公里/小時),
						'other' => q(每小時{0}公里),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(公里/小時),
						'other' => q(每小時{0}公里),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(節),
						'other' => q({0} 節),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(節),
						'other' => q({0} 節),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(光速),
						'other' => q({0} 光速),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(光速),
						'other' => q({0} 光速),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(米/秒),
						'other' => q(每秒{0}米),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q(每秒{0}米),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(英里/小時),
						'other' => q(每小時{0}英里),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(英里/小時),
						'other' => q(每小時{0}英里),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(攝氏),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(攝氏),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(華氏),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(華氏),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(克耳文),
						'other' => q({0} 克耳文),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(克耳文),
						'other' => q({0} 克耳文),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(牛頓米),
						'other' => q({0} 牛頓米),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(牛頓米),
						'other' => q({0} 牛頓米),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(尺磅),
						'other' => q({0} 尺磅),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(尺磅),
						'other' => q({0} 尺磅),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(英畝英呎),
						'other' => q({0} 英畝英呎),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(英畝英呎),
						'other' => q({0} 英畝英呎),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(桶),
						'other' => q({0} 桶),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(桶),
						'other' => q({0} 桶),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0} 蒲式耳),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0} 蒲式耳),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(釐升),
						'other' => q({0} 釐升),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(釐升),
						'other' => q({0} 釐升),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q(每立方厘米{0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0} 立方厘米),
						'per' => q(每立方厘米{0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(立方英呎),
						'other' => q({0} 立方英呎),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(立方英呎),
						'other' => q({0} 立方英呎),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(立方英吋),
						'other' => q({0} 立方英吋),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(立方英吋),
						'other' => q({0} 立方英吋),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(立方公里),
						'other' => q({0} 立方公里),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(立方公里),
						'other' => q({0} 立方公里),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q(每立方米{0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0} 立方米),
						'per' => q(每立方米{0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0} 立方英里),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0} 立方英里),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(立方碼),
						'other' => q({0} 立方碼),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(立方碼),
						'other' => q({0} 立方碼),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(量杯),
						'other' => q({0} 杯),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(量杯),
						'other' => q({0} 杯),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(公制量杯),
						'other' => q({0} 公制杯),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(公制量杯),
						'other' => q({0} 公制杯),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(公合),
						'other' => q({0} 公合),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(公合),
						'other' => q({0} 公合),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(甜品匙),
						'other' => q({0}甜品匙),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(甜品匙),
						'other' => q({0}甜品匙),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(英制甜品匙),
						'other' => q({0}英制甜品匙),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(英制甜品匙),
						'other' => q({0}英制甜品匙),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(英制液量打蘭),
						'other' => q({0}英制液量打蘭),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(英制液量打蘭),
						'other' => q({0}英制液量打蘭),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(滴),
						'other' => q({0}滴),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(滴),
						'other' => q({0}滴),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0} 液盎司),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0} 液盎司),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(英制液盎司),
						'other' => q({0} 英制液盎司),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(英制液盎司),
						'other' => q({0} 英制液盎司),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(加侖),
						'other' => q({0} 加侖),
						'per' => q(每加侖{0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(加侖),
						'other' => q({0} 加侖),
						'per' => q(每加侖{0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(英制加侖),
						'other' => q({0} 英制加侖),
						'per' => q(每英制加侖{0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(英制加侖),
						'other' => q({0} 英制加侖),
						'per' => q(每英制加侖{0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(公石),
						'other' => q({0} 公石),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0} 公石),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(量酒杯),
						'other' => q(量酒器{0}杯),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(量酒杯),
						'other' => q(量酒器{0}杯),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(公升),
						'other' => q({0} 公升),
						'per' => q(每公升{0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(公升),
						'other' => q({0} 公升),
						'per' => q(每公升{0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(兆升),
						'other' => q({0} 兆升),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0} 兆升),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(毫升),
						'other' => q({0} 毫升),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0} 毫升),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(小撮),
						'other' => q({0} 小撮),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(小撮),
						'other' => q({0} 小撮),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(品脫),
						'other' => q({0} 品脫),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(品脫),
						'other' => q({0} 品脫),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(公制品脫),
						'other' => q({0} 公制品脫),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(公制品脫),
						'other' => q({0} 公制品脫),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(夸脫),
						'other' => q({0} 夸脫),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(夸脫),
						'other' => q({0} 夸脫),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(英制夸脫),
						'other' => q({0} 英制夸脫),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(英制夸脫),
						'other' => q({0} 英制夸脫),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(湯匙),
						'other' => q({0} 湯匙),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(湯匙),
						'other' => q({0} 湯匙),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0} 茶匙),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0} 茶匙),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:係|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:唔係|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}、{1}),
				middle => q({0}、{1}),
				end => q({0}同{1}),
				2 => q({0}同{1}),
		} }
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hanidec',
);

has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hant',
);

has finance_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hantfin',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(非數值),
		},
	} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		decimalFormat => {
			'short' => {
				'1000' => {
					'other' => '0千',
				},
				'10000' => {
					'other' => '0萬',
				},
				'100000' => {
					'other' => '00萬',
				},
				'1000000' => {
					'other' => '000萬',
				},
				'10000000' => {
					'other' => '0000萬',
				},
				'100000000' => {
					'other' => '0億',
				},
				'1000000000' => {
					'other' => '00億',
				},
				'10000000000' => {
					'other' => '000億',
				},
				'100000000000' => {
					'other' => '0000億',
				},
				'1000000000000' => {
					'other' => '0兆',
				},
				'10000000000000' => {
					'other' => '00兆',
				},
				'100000000000000' => {
					'other' => '000兆',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(安道爾陪士特),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(阿拉伯聯合大公國迪爾汗),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(阿富汗尼 \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(阿富汗尼),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(阿爾巴尼亞列克 \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(阿爾巴尼亞列克),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(亞美尼亞德拉姆),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(荷屬安地列斯盾),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(安哥拉寬扎),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(安哥拉寬扎 \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(安哥拉新寬扎 \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(安哥拉新調寬扎 \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(阿根廷奧斯特納爾),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(阿根廷披索 \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(阿根廷披索 \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(阿根廷披索 \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(阿根廷披索),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(奧地利先令),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(澳幣),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(阿路巴盾),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(亞塞拜然馬納特 \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(亞塞拜然馬納特),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(波士尼亞-赫塞哥維納第納爾),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(波士尼亞-赫塞哥維納可轉換馬克),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(波士尼亞-赫塞哥維納新第納爾),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(巴貝多元),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(孟加拉塔卡),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(比利時法郎（可轉換）),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(比利時法郎),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(比利時法郎（金融）),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(保加利亞硬列弗),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(保加利亞社會黨列弗),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(保加利亞新列弗),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(保加利亞列弗 \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(巴林第納爾),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(蒲隆地法郎),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(百慕達幣),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(汶萊元),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(玻利維亞諾),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(玻利維亞玻利維亞諾 \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(玻利維亞披索),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(玻利維亞幕多),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(巴西克魯薩多農瓦 \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(巴西克魯賽羅 \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(巴西克魯賽羅 \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(巴西里拉),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(巴西克如爾達農瓦),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(巴西克魯賽羅 \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(巴西克魯賽羅 \(1942 –1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(巴哈馬元),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(不丹那特倫),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(緬甸基雅特),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(波札那普拉),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(白俄羅斯新盧布 \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(白俄羅斯盧布),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(白俄羅斯盧布 \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(貝里斯元),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(加幣),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(剛果法郎),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(歐元 \(WIR\)),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(瑞士法郎),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(法郎 \(WIR\)),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(智利埃斯庫多),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(卡林油達佛曼跎),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(智利披索),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(人民幣 \(離岸\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(人民幣),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(哥倫比亞披索),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(哥倫比亞幣 \(COU\)),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(哥斯大黎加科朗),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(舊塞爾維亞第納爾),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(捷克斯洛伐克硬克朗),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(古巴可轉換披索),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(古巴披索),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(維德角埃斯庫多),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(賽普勒斯鎊),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(捷克克朗),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(東德奧斯特馬克),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(德國馬克),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(吉布地法郎),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(丹麥克朗),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(多明尼加披索),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(阿爾及利亞第納爾),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(厄瓜多蘇克雷),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(厄瓜多爾由里達瓦康斯坦 \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(愛沙尼亞克朗),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(埃及鎊),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(厄立特里亞納克法),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(西班牙比塞塔（會計單位）),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(西班牙比塞塔（可轉換會計單位）),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(西班牙陪士特),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(衣索比亞比爾),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(歐元),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(芬蘭馬克),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(斐濟元),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(福克蘭群島鎊),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(法國法郎),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(英鎊),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(喬治亞庫旁拉里),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(喬治亞拉里),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(迦納賽地 \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(迦納塞地),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(直布羅陀鎊),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(甘比亞達拉西),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(幾內亞法郎),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(幾內亞西里),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(赤道幾內亞埃奎勒),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(希臘德拉克馬),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(瓜地馬拉格查爾),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(葡屬幾內亞埃斯庫多),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(幾內亞比索披索),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(圭亞那元),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(港幣),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(洪都拉斯倫皮拉),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(克羅埃西亞第納爾),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(克羅埃西亞庫納),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(海地古德),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(匈牙利福林),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(印尼盾),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(愛爾蘭鎊),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(以色列鎊),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(以色列謝克爾 \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(以色列新謝克爾),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(印度盧比),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(伊拉克第納爾),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(伊朗里亞爾),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(冰島克朗 \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(冰島克朗),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(義大利里拉),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(牙買加元),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(約旦第納爾),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(日圓),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(肯尼亞先令),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(吉爾吉斯索姆),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(柬埔寨瑞爾),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(科摩羅法郎),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(北韓圓),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(南韓圜),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(南韓圓),
			},
		},
		'KRW' => {
			symbol => '￦',
			display_name => {
				'currency' => q(韓圓),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(科威特第納爾),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(開曼群島元),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(卡扎克斯坦坦吉),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(寮國基普),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(黎巴嫩鎊),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(斯里蘭卡盧比),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(賴比瑞亞元),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(賴索托洛蒂),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(立陶宛立特),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(立陶宛特羅),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(盧森堡可兌換法郎),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(盧森堡法郎),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(盧森堡金融法郎),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(拉脫維亞拉特銀幣),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(拉脫維亞盧布),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(利比亞第納爾),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(摩洛哥迪拉姆),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(摩洛哥法郎),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(摩納哥法郎),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(摩爾多瓦券),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(摩杜雲列伊),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(馬達加斯加阿里亞里),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(馬達加斯加法郎),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(馬其頓第納爾),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(馬其頓第納爾 \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(馬里法郎),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(緬甸元),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(蒙古圖格里克),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(澳門元),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(茅利塔尼亞烏吉亞 \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(茅利塔尼亞烏吉亞),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(馬爾他里拉),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(馬爾他鎊),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(模里西斯盧比),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(馬爾地夫盧比),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(馬爾地夫盧非亞),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(馬拉維克瓦查),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(墨西哥披索),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(墨西哥銀披索 \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(墨西哥轉換單位 \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(馬來西亞令吉),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(莫三比克埃斯庫多),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(莫三比克梅蒂卡爾 \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(莫三比克梅蒂卡爾),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(納米比亞元),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(奈及利亞奈拉),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(尼加拉瓜科多巴),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(尼加拉瓜金科多巴),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(荷蘭盾),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(挪威克朗),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(尼泊爾盧比),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(紐西蘭幣),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(阿曼里亞爾),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(巴拿馬巴波亞),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(祕魯因蒂),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(秘魯太陽幣),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(秘魯索爾 \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(巴布亞紐幾內亞基那),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(菲律賓披索),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(巴基斯坦盧比),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(波蘭茲羅提),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(波蘭茲羅提 \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(葡萄牙埃斯庫多),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(巴拉圭瓜拉尼),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(卡達里亞爾),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(羅德西亞元),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(舊羅馬尼亞列伊),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(羅馬尼亞列伊),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(塞爾維亞戴納),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(俄羅斯盧布),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(俄羅斯盧布 \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(盧安達法郎),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(沙烏地里亞爾),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(索羅門群島元),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(塞席爾盧比),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(蘇丹第納爾),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(蘇丹鎊),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(舊蘇丹鎊),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(瑞典克朗),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(新加坡幣),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(聖赫勒拿鎊),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(斯洛維尼亞托勒),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(斯洛伐克克朗),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(獅子山利昂),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(獅子山利昂 \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(索馬利亞先令),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(蘇利南元),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(蘇利南基爾),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(南蘇丹鎊),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(聖多美島和普林西比島多布拉 \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(聖多美島和普林西比島多布拉),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(蘇聯盧布),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(薩爾瓦多科郎),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(敘利亞鎊),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(史瓦濟蘭里朗吉尼),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(泰銖),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(塔吉克盧布),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(塔吉克索莫尼),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(土庫曼馬納特 \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(土庫曼馬納特),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(突尼西亞第納爾),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(東加潘加),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(帝汶埃斯庫多),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(土耳其里拉),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(新土耳其里拉),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(千里達及托巴哥元),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(新台幣),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(坦尚尼亞先令),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(烏克蘭格里夫納),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(烏克蘭卡本瓦那茲),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(烏干達先令 \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(烏干達先令),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(美元),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(美元（次日）),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(美元（當日）),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(烏拉圭披索（指數單位）),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(烏拉圭披索 \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(烏拉圭披索),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(烏茲別克索姆),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(委內瑞拉玻利瓦 \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(委內瑞拉玻利瓦 \(VEF\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(委內瑞拉玻利瓦),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(越南盾),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(越南盾 \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(萬那杜瓦圖),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(西薩摩亞塔拉),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(法郎 \(CFA–BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(白銀),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(黃金),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(歐洲綜合單位),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(歐洲貨幣單位 \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(歐洲會計單位 \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(歐洲會計單位 \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(格瑞那達元),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(特殊提款權),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(歐洲貨幣單位 \(XEU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(法國金法郎),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(法國法郎 \(UIC\)),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(法郎 \(CFA–BCEAO\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(帕拉狄昂),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(法郎 \(CFP\)),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(白金),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET 基金),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(蘇克雷貨幣),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(測試用貨幣代碼),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(亞洲開發銀行計價單位),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(未知貨幣),
				'other' => q(\(未知貨幣\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(葉門第納爾),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(葉門里亞爾),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(南斯拉夫第納爾硬幣),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(南斯拉夫挪威亞第納爾),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(南斯拉夫可轉換第納爾),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(南斯拉夫改革第納爾 \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(南非蘭特（金融）),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(南非蘭特),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(尚比亞克瓦查 \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(尚比亞克瓦查),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(薩伊新扎伊爾),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(薩伊扎伊爾),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(辛巴威元 \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(辛巴威元 \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(辛巴威元 \(2008\)),
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
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'冬月',
							'臘月'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'正',
							'二',
							'三',
							'四',
							'五',
							'六',
							'七',
							'八',
							'九',
							'十',
							'冬',
							'臘'
						],
						leap => [
							
						],
					},
				},
			},
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'1月',
							'2月',
							'3月',
							'4月',
							'5月',
							'6月',
							'7月',
							'8月',
							'9月',
							'10月',
							'11月',
							'12月',
							'13月'
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
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'正',
							'二',
							'三',
							'四',
							'五',
							'六',
							'七',
							'八',
							'九',
							'十',
							'十一',
							'十二'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'正',
							'二',
							'三',
							'四',
							'五',
							'六',
							'七',
							'八',
							'九',
							'十',
							'十一',
							'十二'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'正月',
							'二月',
							'三月',
							'四月',
							'五月',
							'六月',
							'七月',
							'八月',
							'九月',
							'十月',
							'十一月',
							'十二月'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					wide => {
						nonleap => [
							'1月',
							'2月',
							'3月',
							'4月',
							'5月',
							'6月',
							'7月',
							'8月',
							'9月',
							'10月',
							'11月',
							'12月',
							'13月'
						],
						leap => [
							
						],
					},
				},
			},
			'gregorian' => {
				'format' => {
					wide => {
						nonleap => [
							'1月',
							'2月',
							'3月',
							'4月',
							'5月',
							'6月',
							'7月',
							'8月',
							'9月',
							'10月',
							'11月',
							'12月'
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
							'提斯利月',
							'瑪西班月',
							'基斯流月',
							'提別月',
							'細罷特月',
							'亞達月 I',
							'亞達月',
							'尼散月',
							'以珥月',
							'西彎月',
							'搭模斯月',
							'埃波月',
							'以祿月'
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
					wide => {
						nonleap => [
							'制檀邏月',
							'吠舍佉月',
							'逝瑟吒月',
							'頞沙荼月',
							'室羅伐拏月',
							'婆羅鉢陀月',
							'頞涇縛庚闍月',
							'迦剌底迦月',
							'末伽始羅月',
							'報沙月',
							'磨祛月',
							'頗勒窶拏月'
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
							'穆哈蘭姆月',
							'色法爾月',
							'賴比月 I',
							'賴比月 II',
							'主馬達月 I',
							'主馬達月 II',
							'賴哲卜月',
							'舍爾邦月',
							'賴買丹月',
							'閃瓦魯月',
							'都爾喀爾德月',
							'都爾黑哲月'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'穆哈蘭姆月',
							'色法爾月',
							'賴比月 I',
							'賴比月 II',
							'主馬達月 I',
							'主馬達月 II',
							'賴哲卜月',
							'舍爾邦月',
							'賴買丹月',
							'閃瓦魯月',
							'都爾喀爾德月',
							'都爾黑哲月'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'1月',
							'2月',
							'3月',
							'4月',
							'5月',
							'6月',
							'7月',
							'8月',
							'9月',
							'10月',
							'11月',
							'12月'
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
					short => {
						mon => '一',
						tue => '二',
						wed => '三',
						thu => '四',
						fri => '五',
						sat => '六',
						sun => '日'
					},
					wide => {
						mon => '星期一',
						tue => '星期二',
						wed => '星期三',
						thu => '星期四',
						fri => '星期五',
						sat => '星期六',
						sun => '星期日'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => '一',
						tue => '二',
						wed => '三',
						thu => '四',
						fri => '五',
						sat => '六',
						sun => '日'
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
					wide => {0 => '第1季',
						1 => '第2季',
						2 => '第3季',
						3 => '第4季'
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
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
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
					'afternoon1' => q{中午},
					'afternoon2' => q{下晝},
					'am' => q{上午},
					'evening1' => q{夜晚},
					'midnight' => q{午夜},
					'morning1' => q{清晨},
					'morning2' => q{朝早},
					'night1' => q{凌晨},
					'pm' => q{下午},
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
				'0' => '佛曆'
			},
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
			abbreviated => {
				'0' => '西元前',
				'1' => '西元'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => '創世紀元'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => '印度曆'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => '伊斯蘭曆'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => '大化',
				'1' => '白雉',
				'2' => '白鳳',
				'3' => '朱鳥',
				'4' => '大寶',
				'5' => '慶雲',
				'6' => '和銅',
				'7' => '靈龜',
				'8' => '養老',
				'9' => '神龜',
				'10' => '天平',
				'11' => '天平感寶',
				'12' => '天平勝寶',
				'13' => '天平寶字',
				'14' => '天平神護',
				'15' => '神護景雲',
				'16' => '寶龜',
				'17' => '天應',
				'18' => '延曆',
				'19' => '大同',
				'20' => '弘仁',
				'21' => '天長',
				'22' => '承和',
				'23' => '嘉祥',
				'24' => '仁壽',
				'25' => '齊衡',
				'26' => '天安',
				'27' => '貞觀',
				'28' => '元慶',
				'29' => '仁和',
				'30' => '寬平',
				'31' => '昌泰',
				'32' => '延喜',
				'33' => '延長',
				'34' => '承平',
				'35' => '天慶',
				'36' => '天曆',
				'37' => '天德',
				'38' => '應和',
				'39' => '康保',
				'40' => '安和',
				'41' => '天祿',
				'42' => '天延',
				'43' => '貞元',
				'44' => '天元',
				'45' => '永觀',
				'46' => '寬和',
				'47' => '永延',
				'48' => '永祚',
				'49' => '正曆',
				'50' => '長德',
				'51' => '長保',
				'52' => '寬弘',
				'53' => '長和',
				'54' => '寬仁',
				'55' => '治安',
				'56' => '萬壽',
				'57' => '長元',
				'58' => '長曆',
				'59' => '長久',
				'60' => '寬德',
				'61' => '永承',
				'62' => '天喜',
				'63' => '康平',
				'64' => '治曆',
				'65' => '延久',
				'66' => '承保',
				'67' => '承曆',
				'68' => '永保',
				'69' => '應德',
				'70' => '寬治',
				'71' => '嘉保',
				'72' => '永長',
				'73' => '承德',
				'74' => '康和',
				'75' => '長治',
				'76' => '嘉承',
				'77' => '天仁',
				'78' => '天永',
				'79' => '永久',
				'80' => '元永',
				'81' => '保安',
				'82' => '天治',
				'83' => '大治',
				'84' => '天承',
				'85' => '長承',
				'86' => '保延',
				'87' => '永治',
				'88' => '康治',
				'89' => '天養',
				'90' => '久安',
				'91' => '仁平',
				'92' => '久壽',
				'93' => '保元',
				'94' => '平治',
				'95' => '永曆',
				'96' => '應保',
				'97' => '長寬',
				'98' => '永萬',
				'99' => '仁安',
				'100' => '嘉應',
				'101' => '承安',
				'102' => '安元',
				'103' => '治承',
				'104' => '養和',
				'105' => '壽永',
				'106' => '元曆',
				'107' => '文治',
				'108' => '建久',
				'109' => '正治',
				'110' => '建仁',
				'111' => '元久',
				'112' => '建永',
				'113' => '承元',
				'114' => '建曆',
				'115' => '建保',
				'116' => '承久',
				'117' => '貞應',
				'118' => '元仁',
				'119' => '嘉祿',
				'120' => '安貞',
				'121' => '寬喜',
				'122' => '貞永',
				'123' => '天福',
				'124' => '文曆',
				'125' => '嘉禎',
				'126' => '曆仁',
				'127' => '延應',
				'128' => '仁治',
				'129' => '寬元',
				'130' => '寶治',
				'131' => '建長',
				'132' => '康元',
				'133' => '正嘉',
				'134' => '正元',
				'135' => '文應',
				'136' => '弘長',
				'137' => '文永',
				'138' => '建治',
				'139' => '弘安',
				'140' => '正應',
				'141' => '永仁',
				'142' => '正安',
				'143' => '乾元',
				'144' => '嘉元',
				'145' => '德治',
				'146' => '延慶',
				'147' => '應長',
				'148' => '正和',
				'149' => '文保',
				'150' => '元應',
				'151' => '元亨',
				'152' => '正中',
				'153' => '嘉曆',
				'154' => '元德',
				'155' => '元弘',
				'156' => '建武',
				'157' => '延元',
				'158' => '興國',
				'159' => '正平',
				'160' => '建德',
				'161' => '文中',
				'162' => '天授',
				'163' => '康曆',
				'164' => '弘和',
				'165' => '元中',
				'166' => '至德',
				'167' => '嘉慶',
				'168' => '康應',
				'169' => '明德',
				'170' => '應永',
				'171' => '正長',
				'172' => '永享',
				'173' => '嘉吉',
				'174' => '文安',
				'175' => '寶德',
				'176' => '享德',
				'177' => '康正',
				'178' => '長祿',
				'179' => '寬正',
				'180' => '文正',
				'181' => '應仁',
				'182' => '文明',
				'183' => '長享',
				'184' => '延德',
				'185' => '明應',
				'186' => '文龜',
				'187' => '永正',
				'188' => '大永',
				'189' => '享祿',
				'190' => '天文',
				'191' => '弘治',
				'192' => '永祿',
				'193' => '元龜',
				'194' => '天正',
				'195' => '文祿',
				'196' => '慶長',
				'197' => '元和',
				'198' => '寬永',
				'199' => '正保',
				'200' => '慶安',
				'201' => '承應',
				'202' => '明曆',
				'203' => '萬治',
				'204' => '寬文',
				'205' => '延寶',
				'206' => '天和',
				'207' => '貞享',
				'208' => '元祿',
				'209' => '寶永',
				'210' => '正德',
				'211' => '享保',
				'212' => '元文',
				'213' => '寬保',
				'214' => '延享',
				'215' => '寬延',
				'216' => '寶曆',
				'217' => '明和',
				'218' => '安永',
				'219' => '天明',
				'220' => '寬政',
				'221' => '享和',
				'222' => '文化',
				'223' => '文政',
				'224' => '天保',
				'225' => '弘化',
				'226' => '嘉永',
				'227' => '安政',
				'228' => '萬延',
				'229' => '文久',
				'230' => '元治',
				'231' => '慶應',
				'232' => '明治',
				'233' => '大正',
				'234' => '昭和',
				'235' => '平成',
				'236' => '令和'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => '波斯曆'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => '民國前',
				'1' => '民國'
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
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'chinese' => {
			'full' => q{U (r) 年MMMdEEEE},
			'long' => q{U (r) 年MMMd},
			'medium' => q{r年MMMd},
			'short' => q{r/M/d},
		},
		'coptic' => {
		},
		'dangi' => {
			'full' => q{U年MMMd日EEEE},
			'long' => q{U年MMMd日},
			'medium' => q{U年MMMd日},
			'short' => q{U/M/d},
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{G y年M月d日 EEEE},
			'long' => q{G y年M月d日},
			'medium' => q{G y年M月d日},
			'short' => q{G y/M/d},
		},
		'gregorian' => {
			'full' => q{y年M月d日 EEEE},
			'long' => q{y年M月d日},
			'medium' => q{y年M月d日},
			'short' => q{y/M/d},
		},
		'hebrew' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'indian' => {
		},
		'islamic' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'japanese' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{Gy年M月d日 EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy/M/d},
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
			'full' => q{ah:mm:ss [zzzz]},
			'long' => q{ah:mm:ss [z]},
			'medium' => q{ah:mm:ss},
			'short' => q{ah:mm},
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
			'full' => q{{1}{0}},
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
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			MMMEd => q{M月d日E},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy/M},
			yyyyMEd => q{Gy/M/d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'chinese' => {
			Ed => q{d日E},
			Gy => q{rU年},
			GyMMM => q{rU年MMM},
			GyMMMEd => q{rU年MMMdE},
			GyMMMd => q{r年MMMd},
			M => q{MMM},
			MEd => q{M/dE},
			MMMEd => q{MMMd日E},
			MMMMd => q{MMMMd日},
			MMMd => q{MMMd日},
			Md => q{M/d},
			UM => q{U年MMM},
			UMMM => q{U年MMM},
			UMMMd => q{U年MMMd},
			UMd => q{U年MMMd},
			d => q{d日},
			y => q{rU年},
			yMd => q{r年MMMd},
			yyyy => q{rU年},
			yyyyM => q{rU年MMM},
			yyyyMEd => q{rU年MMMd，E},
			yyyyMMM => q{rU年MMM},
			yyyyMMMEd => q{rU年MMMdE},
			yyyyMMMM => q{rU年MMMM},
			yyyyMMMd => q{r年MMMd},
			yyyyMd => q{r年MMMd},
			yyyyQQQ => q{rU年QQQQ},
			yyyyQQQQ => q{rU年QQQQ},
		},
		'generic' => {
			Bh => q{Bh時},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			Ed => q{d E},
			Ehm => q{ah:mmE},
			Ehms => q{ah:mm:ssE},
			Gy => q{G y年},
			GyMMM => q{G y年M月},
			GyMMMEd => q{G y年M月d日 E},
			GyMMMd => q{G y年M月d日},
			H => q{H時},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{M月},
			MEd => q{M/d（E）},
			MMMEd => q{M月d日 E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M/d},
			d => q{d日},
			h => q{ah時},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			y => q{G y年},
			yyyy => q{G y年},
			yyyyM => q{G y/M},
			yyyyMEd => q{G y/M/d（E）},
			yyyyMMM => q{G y年M月},
			yyyyMMMEd => q{G y年M月d日 E},
			yyyyMMMM => q{G y年M月},
			yyyyMMMd => q{G y年M月d日},
			yyyyMd => q{G y/M/d},
			yyyyQQQ => q{G y年QQQ},
			yyyyQQQQ => q{G y年QQQQ},
		},
		'gregorian' => {
			Bh => q{Bh時},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			EBhm => q{E Bh:mm},
			EBhms => q{E Bh:mm:ss},
			Ed => q{d E},
			Ehm => q{E ah:mm},
			Ehms => q{E ah:mm:ss},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日 E},
			GyMMMd => q{Gy年M月d日},
			H => q{H時},
			Hmsv => q{HH:mm:ss [v]},
			Hmv => q{HH:mm [v]},
			M => q{M月},
			MEd => q{M/d（E）},
			MMMEd => q{M月d日 E},
			MMMMW => q{M月第W個星期},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			MMdd => q{MM/dd},
			Md => q{M/d},
			d => q{d日},
			h => q{ah時},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			hmsv => q{ah:mm:ss [v]},
			hmv => q{ah:mm [v]},
			y => q{y年},
			yM => q{y/M},
			yMEd => q{y/M/d（E）},
			yMM => q{y/MM},
			yMMM => q{y年M月},
			yMMMEd => q{y年M月d日 E},
			yMMMM => q{y年M月},
			yMMMd => q{y年M月d日},
			yMd => q{y/M/d},
			yQQQ => q{y年QQQ},
			yQQQQ => q{y年QQQQ},
			yw => q{Y年第w個星期},
		},
		'islamic' => {
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			MMMEd => q{M月d日E},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy/M},
			yyyyMEd => q{Gy/M/d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'japanese' => {
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			MMMEd => q{M月d日E},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy/M},
			yyyyMEd => q{Gy/M/d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'roc' => {
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			MMMEd => q{M月d日E},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy/M},
			yyyyMEd => q{Gy/M/d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
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
		'chinese' => {
			Hmv => {
				H => q{HH:mm–HH:mm [v]},
				m => q{HH:mm–HH:mm [v]},
			},
			Hv => {
				H => q{HH–HH [v]},
			},
			M => {
				M => q{MMM至MMM},
			},
			MEd => {
				M => q{M/dE至M/dE},
				d => q{M/dE至M/dE},
			},
			MMM => {
				M => q{LLL至LLL},
			},
			MMMEd => {
				M => q{MMMd日E至MMMd日E},
				d => q{MMMd日E至d日E},
			},
			MMMM => {
				M => q{LLLL至LLLL},
			},
			MMMd => {
				M => q{MMMd日至MMMd日},
				d => q{MMMd日至d日},
			},
			Md => {
				M => q{M/d至M/d},
				d => q{M/d至M/d},
			},
			d => {
				d => q{d日至d日},
			},
			fallback => '{0}至{1}',
			h => {
				a => q{ah時至ah時},
				h => q{ah時至h時},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{ah:mm至ah:mm [v]},
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				a => q{ah時至ah時 [v]},
				h => q{ah時至h時 [v]},
			},
			y => {
				y => q{rU至rU},
			},
			yM => {
				M => q{r/M至r/M},
				y => q{r/M至r/M},
			},
			yMEd => {
				M => q{r/M/dE至r/M/dE},
				d => q{r/M/dE至r/M/dE},
				y => q{r/M/dE至r/M/dE},
			},
			yMMM => {
				M => q{rU年MMM至MMM},
				y => q{rU年MMM至rU年MMM},
			},
			yMMMEd => {
				M => q{rU年MMMdE至MMMdE},
				d => q{rU年MMMdE至dE},
				y => q{rU年MMMdE至rU年MMMdE},
			},
			yMMMM => {
				M => q{rU年MMMM至MMMM},
				y => q{rU年MMMM至rU年MMMM},
			},
			yMMMd => {
				M => q{r年MMMd至MMMd},
				d => q{r年MMMd至d},
				y => q{r年MMMd至r年MMMd},
			},
			yMd => {
				M => q{r/M/d至r/M/d},
				d => q{r/M/d至r/M/d},
				y => q{r/M/d至r/M/d},
			},
		},
		'generic' => {
			Bh => {
				B => q{Bh時至Bh時},
				h => q{Bh至h時},
			},
			Bhm => {
				B => q{Bh:mm至Bh:mm},
				h => q{Bh:mm至h:mm},
				m => q{Bh:mm至h:mm},
			},
			Gy => {
				G => q{G y年至G y年},
				y => q{G y至y年},
			},
			GyM => {
				G => q{G y/M至G y/M},
				M => q{G y/M至y/M},
				y => q{G y/M至y/M},
			},
			GyMEd => {
				G => q{G y/M/d（E）至G y/M/d（E）},
				M => q{G y/M/d（E）至y/M/d（E）},
				d => q{G y/M/d（E）至y/M/d（E）},
				y => q{G y/M/d（E）至y/M/d（E）},
			},
			GyMMM => {
				G => q{G y年M月至G y年M月},
				M => q{G y年M月至M月},
				y => q{G y年M月至y年M月},
			},
			GyMMMEd => {
				G => q{G y年M月d日（E）至G y年M月d日（E）},
				M => q{G y年M月d日（E）至M月d日（E）},
				d => q{G y年M月d日（E）至M月d日（E）},
				y => q{G y年M月d日（E）至y年M月d日（E）},
			},
			GyMMMd => {
				G => q{G y年M月d日至G y年M月d日},
				M => q{G y年M月d日至M月d日},
				d => q{G y年M月d日至d日},
				y => q{G y年M月d日至y年M月d日},
			},
			GyMd => {
				G => q{G y/M/d至G y/M/d},
				M => q{G y/M/d至y/M/d},
				d => q{G y/M/d至y/M/d},
				y => q{G y/M/d至y/M/d},
			},
			Hmv => {
				H => q{HH:mm–HH:mm [v]},
				m => q{HH:mm–HH:mm [v]},
			},
			Hv => {
				H => q{HH–HH [v]},
			},
			M => {
				M => q{M月至M月},
			},
			MEd => {
				M => q{d/M (E) 至 d/M (E)},
				d => q{d/M (E) 至 d/M (E)},
			},
			MMM => {
				M => q{LLL至LLL},
			},
			MMMEd => {
				M => q{M月d日E至M月d日E},
				d => q{M月d日E至d日E},
			},
			MMMM => {
				M => q{LLLL至LLLL},
			},
			MMMd => {
				M => q{M月d日至M月d日},
				d => q{M月d日至d日},
			},
			Md => {
				M => q{M/d至M/d},
				d => q{M/d至M/d},
			},
			d => {
				d => q{d日至d日},
			},
			fallback => '{0}至{1}',
			h => {
				a => q{ah時至ah時},
				h => q{ah時至h時},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{ah:mm至ah:mm [v]},
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				a => q{ah時至ah時 [v]},
				h => q{ah時至h時 [v]},
			},
			y => {
				y => q{G y至y},
			},
			yM => {
				M => q{G y/M至y/M},
				y => q{G y/M至y/M},
			},
			yMEd => {
				M => q{G y/M/dE至y/M/dE},
				d => q{G y/M/dE至y/M/dE},
				y => q{G y/M/dE至y/M/dE},
			},
			yMMM => {
				M => q{G y年M月至M月},
				y => q{G y年M月至y年M月},
			},
			yMMMEd => {
				M => q{G y年M月d日E至M月d日E},
				d => q{G y年M月d日E至d日E},
				y => q{G y年M月d日E至y年M月d日E},
			},
			yMMMM => {
				M => q{G y年M月至M月},
				y => q{G y年M月至y年M月},
			},
			yMMMd => {
				M => q{G y年M月d日至M月d日},
				d => q{G y年M月d日至d日},
				y => q{G y年M月d日至y年M月d日},
			},
			yMd => {
				M => q{G y/M/d至y/M/d},
				d => q{G y/M/d至y/M/d},
				y => q{G y/M/d至y/M/d},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{Bh時至Bh時},
				h => q{Bh至h時},
			},
			Bhm => {
				B => q{Bh:mm至Bh:mm},
				h => q{Bh:mm至h:mm},
				m => q{Bh:mm至h:mm},
			},
			Gy => {
				G => q{Gy年至Gy年},
				y => q{Gy年至y年},
			},
			GyM => {
				G => q{GGGGGy年M月至y年M月},
				M => q{GGGGGy年M月至y年M月},
				y => q{GGGGGy年M月至y年M月},
			},
			GyMEd => {
				G => q{GGGGGy年M月dd日E至GGGGGy年M月dd日E},
				M => q{GGGGGy年M月dd日E至y年M月dd日E},
				d => q{GGGGGy年M月dd日E至y年M月dd日E},
				y => q{GGGGGy年M月dd日E至y年M月dd日E},
			},
			GyMMM => {
				G => q{Gy年MMM至Gy年MMM},
				M => q{G y年MMM至MMM},
				y => q{Gy年MMM至y年MMM},
			},
			GyMMMEd => {
				G => q{Gy 年MMMd日E至Gy年MMMd日E},
				M => q{Gy年MMMd日E至MMMd日E},
				d => q{Gy年MMMd日E至MMMd日E},
				y => q{Gy年MMMd日E至y年MMMd日E},
			},
			GyMMMd => {
				G => q{Gy年MMMd日至Gy年MMMd日},
				M => q{Gy年MMMd日至MMMd日},
				d => q{Gy年MMMd至d日},
				y => q{Gy年MMMd日至y年MMMd日},
			},
			GyMd => {
				G => q{GGGGGy年M月dd日y年M月dd日},
				M => q{GGGGGy年M月dd日至y年M月dd日},
				d => q{GGGGGy年M月dd日至y年M月dd日},
				y => q{GGGGGy年M月dd日至y年M月dd日},
			},
			Hm => {
				m => q{HH:mm至HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm [v]},
				m => q{HH:mm–HH:mm [v]},
			},
			Hv => {
				H => q{HH–HH [v]},
			},
			M => {
				M => q{M月至M月},
			},
			MEd => {
				M => q{d/M (E) 至 d/M (E)},
				d => q{d/M (E) 至 d/M (E)},
			},
			MMM => {
				M => q{LLL至LLL},
			},
			MMMEd => {
				M => q{M月d日E至M月d日E},
				d => q{M月d日E至d日E},
			},
			MMMM => {
				M => q{LLLL至LLLL},
			},
			MMMd => {
				M => q{M月d日至M月d日},
				d => q{M月d日至d日},
			},
			Md => {
				M => q{M/d至M/d},
				d => q{M/d至M/d},
			},
			d => {
				d => q{d日至d日},
			},
			fallback => '{0}至{1}',
			h => {
				a => q{ah時至ah時},
				h => q{ah時至h時},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{ah:mm至ah:mm [v]},
				h => q{ah:mm至h:mm [v]},
				m => q{ah:mm至h:mm [v]},
			},
			hv => {
				a => q{ah時至ah時 [v]},
				h => q{ah時至h時 [v]},
			},
			y => {
				y => q{y至y},
			},
			yM => {
				M => q{y/M至y/M},
				y => q{y/M至y/M},
			},
			yMEd => {
				M => q{d/M/y (E) 至 d/M/y (E)},
				d => q{d/M/y (E) 至 d/M/y (E)},
				y => q{d/M/y (E) 至 d/M/y (E)},
			},
			yMMM => {
				M => q{y年M月至M月},
				y => q{y年M月至y年M月},
			},
			yMMMEd => {
				M => q{y年M月d日E至M月d日E},
				d => q{y年M月d日E至d日E},
				y => q{y年M月d日E至y年M月d日E},
			},
			yMMMM => {
				M => q{y年M月至M月},
				y => q{y年M月至y年M月},
			},
			yMMMd => {
				M => q{y年M月d日至M月d日},
				d => q{y年M月d日至d日},
				y => q{y年M月d日至y年M月d日},
			},
			yMd => {
				M => q{y/M/d至y/M/d},
				d => q{y/M/d至y/M/d},
				y => q{y/M/d至y/M/d},
			},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'format' => {
				'wide' => {
					'leap' => q{閏{0}},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{閏{0}},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'leap' => q{閏{0}},
				},
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
						0 => q(子),
						1 => q(丑),
						2 => q(寅),
						3 => q(卯),
						4 => q(辰),
						5 => q(巳),
						6 => q(午),
						7 => q(未),
						8 => q(申),
						9 => q(酉),
						10 => q(戌),
						11 => q(亥),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(立春),
						1 => q(雨水),
						2 => q(驚蟄),
						3 => q(春分),
						4 => q(清明),
						5 => q(穀雨),
						6 => q(立夏),
						7 => q(小滿),
						8 => q(芒種),
						9 => q(夏至),
						10 => q(小暑),
						11 => q(大暑),
						12 => q(立秋),
						13 => q(處暑),
						14 => q(白露),
						15 => q(秋分),
						16 => q(寒露),
						17 => q(霜降),
						18 => q(立冬),
						19 => q(小雪),
						20 => q(大雪),
						21 => q(冬至),
						22 => q(小寒),
						23 => q(大寒),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(甲子),
						1 => q(乙丑),
						2 => q(丙寅),
						3 => q(丁卯),
						4 => q(戊辰),
						5 => q(己巳),
						6 => q(庚午),
						7 => q(辛未),
						8 => q(壬申),
						9 => q(癸酉),
						10 => q(甲戌),
						11 => q(乙亥),
						12 => q(丙子),
						13 => q(丁丑),
						14 => q(戊寅),
						15 => q(己卯),
						16 => q(庚辰),
						17 => q(辛巳),
						18 => q(壬午),
						19 => q(癸未),
						20 => q(甲申),
						21 => q(乙酉),
						22 => q(丙戌),
						23 => q(丁亥),
						24 => q(戊子),
						25 => q(己丑),
						26 => q(庚寅),
						27 => q(辛卯),
						28 => q(壬辰),
						29 => q(癸巳),
						30 => q(甲午),
						31 => q(乙未),
						32 => q(丙申),
						33 => q(丁酉),
						34 => q(戊戌),
						35 => q(己亥),
						36 => q(庚子),
						37 => q(辛丑),
						38 => q(壬寅),
						39 => q(癸卯),
						40 => q(甲辰),
						41 => q(乙巳),
						42 => q(丙午),
						43 => q(丁未),
						44 => q(戊申),
						45 => q(己酉),
						46 => q(庚戌),
						47 => q(辛亥),
						48 => q(壬子),
						49 => q(癸丑),
						50 => q(甲寅),
						51 => q(乙卯),
						52 => q(丙辰),
						53 => q(丁巳),
						54 => q(戊午),
						55 => q(己未),
						56 => q(庚申),
						57 => q(辛酉),
						58 => q(壬戌),
						59 => q(癸亥),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(鼠),
						1 => q(牛),
						2 => q(虎),
						3 => q(兔),
						4 => q(龍),
						5 => q(蛇),
						6 => q(馬),
						7 => q(羊),
						8 => q(猴),
						9 => q(雞),
						10 => q(狗),
						11 => q(豬),
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
		regionFormat => q({0}時間),
		regionFormat => q({0}夏令時間),
		regionFormat => q({0}標準時間),
		'Acre' => {
			long => {
				'daylight' => q#艾克夏令時間#,
				'generic' => q#艾克時間#,
				'standard' => q#艾克標準時間#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#阿富汗時間#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#阿比讓#,
		},
		'Africa/Accra' => {
			exemplarCity => q#阿克拉#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#阿迪斯阿貝巴#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#阿爾及爾#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#阿斯瑪拉#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#巴馬科#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#班吉#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#班竹#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#比紹#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#布蘭太爾#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#布拉柴維爾#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#布松布拉#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#開羅#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#卡薩布蘭卡#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#休達#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#柯那克里#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#達喀爾#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#沙蘭港#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#吉布地#,
		},
		'Africa/Douala' => {
			exemplarCity => q#杜阿拉#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#阿尤恩#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#自由城#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#嘉柏隆里#,
		},
		'Africa/Harare' => {
			exemplarCity => q#哈拉雷#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#約翰尼斯堡#,
		},
		'Africa/Juba' => {
			exemplarCity => q#朱巴#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#坎帕拉#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#喀土穆#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#基加利#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#金夏沙#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#拉哥斯#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#自由市#,
		},
		'Africa/Lome' => {
			exemplarCity => q#洛美#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#羅安達#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#盧本巴希#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#路沙卡#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#馬拉博#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#馬普托#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#馬賽魯#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#墨巴本#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#摩加迪休#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#蒙羅維亞#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#奈洛比#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#恩賈梅納#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#尼亞美#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#諾克少#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#瓦加杜古#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#波多諾佛#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#聖多美#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#的黎波里#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#突尼斯#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#溫得和克#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#中非時間#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#東非時間#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#南非標準時間#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#西非夏令時間#,
				'generic' => q#西非時間#,
				'standard' => q#西非標準時間#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#阿拉斯加夏令時間#,
				'generic' => q#阿拉斯加時間#,
				'standard' => q#阿拉斯加標準時間#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#阿拉木圖夏令時間#,
				'generic' => q#阿拉木圖時間#,
				'standard' => q#阿拉木圖標準時間#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#亞馬遜夏令時間#,
				'generic' => q#亞馬遜時間#,
				'standard' => q#亞馬遜標準時間#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#艾達克#,
		},
		'America/Anchorage' => {
			exemplarCity => q#安克拉治#,
		},
		'America/Anguilla' => {
			exemplarCity => q#安吉拉#,
		},
		'America/Antigua' => {
			exemplarCity => q#安地卡#,
		},
		'America/Araguaina' => {
			exemplarCity => q#阿拉圭那#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#拉略哈#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#里奧加耶戈斯#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#薩爾塔#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#聖胡安#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#聖路易#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#吐庫曼#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#烏斯懷亞#,
		},
		'America/Aruba' => {
			exemplarCity => q#阿路巴#,
		},
		'America/Asuncion' => {
			exemplarCity => q#亞松森#,
		},
		'America/Bahia' => {
			exemplarCity => q#巴伊阿#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#巴伊亞班德拉斯#,
		},
		'America/Barbados' => {
			exemplarCity => q#巴貝多#,
		},
		'America/Belem' => {
			exemplarCity => q#貝倫#,
		},
		'America/Belize' => {
			exemplarCity => q#貝里斯#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#白朗薩布隆#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#保維斯塔#,
		},
		'America/Bogota' => {
			exemplarCity => q#波哥大#,
		},
		'America/Boise' => {
			exemplarCity => q#波夕#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#布宜諾斯艾利斯#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#劍橋灣#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#格蘭場#,
		},
		'America/Cancun' => {
			exemplarCity => q#坎昆#,
		},
		'America/Caracas' => {
			exemplarCity => q#卡拉卡斯#,
		},
		'America/Catamarca' => {
			exemplarCity => q#卡塔馬卡#,
		},
		'America/Cayenne' => {
			exemplarCity => q#開雲#,
		},
		'America/Cayman' => {
			exemplarCity => q#開曼群島#,
		},
		'America/Chicago' => {
			exemplarCity => q#芝加哥#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#奇華華#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#華雷斯城#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#阿蒂科肯#,
		},
		'America/Cordoba' => {
			exemplarCity => q#哥多華#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#哥斯大黎加#,
		},
		'America/Creston' => {
			exemplarCity => q#克雷斯頓#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#古雅巴#,
		},
		'America/Curacao' => {
			exemplarCity => q#庫拉索#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#丹馬沙文#,
		},
		'America/Dawson' => {
			exemplarCity => q#道森#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#道森克里克#,
		},
		'America/Denver' => {
			exemplarCity => q#丹佛#,
		},
		'America/Detroit' => {
			exemplarCity => q#底特律#,
		},
		'America/Dominica' => {
			exemplarCity => q#多明尼加#,
		},
		'America/Edmonton' => {
			exemplarCity => q#艾德蒙吞#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#艾魯內佩#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#薩爾瓦多#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#納爾遜堡#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#福塔力莎#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#格雷斯貝#,
		},
		'America/Godthab' => {
			exemplarCity => q#努克#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#鵝灣#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#大特克島#,
		},
		'America/Grenada' => {
			exemplarCity => q#格瑞納達#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#瓜地洛普#,
		},
		'America/Guatemala' => {
			exemplarCity => q#瓜地馬拉#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#瓜亞基爾#,
		},
		'America/Guyana' => {
			exemplarCity => q#蓋亞那#,
		},
		'America/Halifax' => {
			exemplarCity => q#哈里法克斯#,
		},
		'America/Havana' => {
			exemplarCity => q#哈瓦那#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#埃莫西約#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#印第安那州諾克斯#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#印第安那州馬倫哥#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#印第安那州彼得堡#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#印第安那州泰爾城#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#印第安那州維威#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#印第安那州溫森斯#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#印第安那州威納馬克#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#印第安那波里斯#,
		},
		'America/Inuvik' => {
			exemplarCity => q#伊奴維克#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#伊魁特#,
		},
		'America/Jamaica' => {
			exemplarCity => q#牙買加#,
		},
		'America/Jujuy' => {
			exemplarCity => q#胡胡伊#,
		},
		'America/Juneau' => {
			exemplarCity => q#朱諾#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#肯塔基州蒙地卻羅#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#克拉倫代克#,
		},
		'America/La_Paz' => {
			exemplarCity => q#拉巴斯#,
		},
		'America/Lima' => {
			exemplarCity => q#利馬#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#洛杉磯#,
		},
		'America/Louisville' => {
			exemplarCity => q#路易斯維爾#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#下太子區#,
		},
		'America/Maceio' => {
			exemplarCity => q#馬瑟歐#,
		},
		'America/Managua' => {
			exemplarCity => q#馬拿瓜#,
		},
		'America/Manaus' => {
			exemplarCity => q#瑪瑙斯#,
		},
		'America/Marigot' => {
			exemplarCity => q#馬里戈特#,
		},
		'America/Martinique' => {
			exemplarCity => q#馬丁尼克#,
		},
		'America/Matamoros' => {
			exemplarCity => q#馬塔莫羅斯#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#馬薩特蘭#,
		},
		'America/Mendoza' => {
			exemplarCity => q#門多薩#,
		},
		'America/Menominee' => {
			exemplarCity => q#美諾米尼#,
		},
		'America/Merida' => {
			exemplarCity => q#梅里達#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#梅特拉卡特拉#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#墨西哥市#,
		},
		'America/Miquelon' => {
			exemplarCity => q#密啟崙#,
		},
		'America/Moncton' => {
			exemplarCity => q#蒙克頓#,
		},
		'America/Monterrey' => {
			exemplarCity => q#蒙特瑞#,
		},
		'America/Montevideo' => {
			exemplarCity => q#蒙特維多#,
		},
		'America/Montserrat' => {
			exemplarCity => q#蒙哲臘#,
		},
		'America/Nassau' => {
			exemplarCity => q#拿索#,
		},
		'America/New_York' => {
			exemplarCity => q#紐約#,
		},
		'America/Nome' => {
			exemplarCity => q#諾姆#,
		},
		'America/Noronha' => {
			exemplarCity => q#諾倫哈#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#北達科他州布由拉#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#北達科他州中心#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#北達科他州紐沙倫#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#奧希納加#,
		},
		'America/Panama' => {
			exemplarCity => q#巴拿馬#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#巴拉馬利波#,
		},
		'America/Phoenix' => {
			exemplarCity => q#鳳凰城#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#太子港#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#西班牙港#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#維留港#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#波多黎各#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#蓬塔阿雷納斯#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#蘭今灣#,
		},
		'America/Recife' => {
			exemplarCity => q#雷西非#,
		},
		'America/Regina' => {
			exemplarCity => q#里賈納#,
		},
		'America/Resolute' => {
			exemplarCity => q#羅斯魯特#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#里約布蘭#,
		},
		'America/Santarem' => {
			exemplarCity => q#聖塔倫#,
		},
		'America/Santiago' => {
			exemplarCity => q#聖地牙哥#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#聖多明哥#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#聖保羅#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#伊托科爾托米特#,
		},
		'America/Sitka' => {
			exemplarCity => q#錫特卡#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#聖巴托洛繆島#,
		},
		'America/St_Johns' => {
			exemplarCity => q#聖約翰#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#聖基茨#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#聖露西亞#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#聖托馬斯#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#聖文森#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#斯威夫特卡倫特#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#德古斯加巴#,
		},
		'America/Thule' => {
			exemplarCity => q#杜里#,
		},
		'America/Tijuana' => {
			exemplarCity => q#提華納#,
		},
		'America/Toronto' => {
			exemplarCity => q#多倫多#,
		},
		'America/Tortola' => {
			exemplarCity => q#托爾托拉#,
		},
		'America/Vancouver' => {
			exemplarCity => q#溫哥華#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#懷特霍斯#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#溫尼伯#,
		},
		'America/Yakutat' => {
			exemplarCity => q#雅庫塔#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#中部夏令時間#,
				'generic' => q#中部時間#,
				'standard' => q#中部標準時間#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#東部夏令時間#,
				'generic' => q#東部時間#,
				'standard' => q#東部標準時間#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#山區夏令時間#,
				'generic' => q#山區時間#,
				'standard' => q#山區標準時間#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#太平洋夏令時間#,
				'generic' => q#太平洋時間#,
				'standard' => q#太平洋標準時間#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#阿那底河夏令時間#,
				'generic' => q#阿納德爾時間#,
				'standard' => q#阿那底河標準時間#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#凱西#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#戴維斯#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#杜蒙杜比爾#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#麥覺理#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#莫森#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#麥克默多#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#帕麥#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#羅瑟拉#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#昭和基地#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#綽爾#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#沃斯托克#,
		},
		'Apia' => {
			long => {
				'daylight' => q#阿皮亞夏令時間#,
				'generic' => q#阿皮亞時間#,
				'standard' => q#阿皮亞標準時間#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#阿克陶夏令時間#,
				'generic' => q#阿克陶時間#,
				'standard' => q#阿克陶標準時間#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#阿克托比夏令時間#,
				'generic' => q#阿克托比時間#,
				'standard' => q#阿克托比標準時間#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#阿拉伯夏令時間#,
				'generic' => q#阿拉伯時間#,
				'standard' => q#阿拉伯標準時間#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#隆意耳拜恩#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#阿根廷夏令時間#,
				'generic' => q#阿根廷時間#,
				'standard' => q#阿根廷標準時間#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#阿根廷西部夏令時間#,
				'generic' => q#阿根廷西部時間#,
				'standard' => q#阿根廷西部標準時間#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#亞美尼亞夏令時間#,
				'generic' => q#亞美尼亞時間#,
				'standard' => q#亞美尼亞標準時間#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#亞丁#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#阿拉木圖#,
		},
		'Asia/Amman' => {
			exemplarCity => q#安曼#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#阿那底#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#阿克套#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#阿克托比#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#阿什哈巴特#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#阿特勞#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#巴格達#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#巴林#,
		},
		'Asia/Baku' => {
			exemplarCity => q#巴庫#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#曼谷#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#巴爾瑙爾#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#貝魯特#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#比什凱克#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#汶萊#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#加爾各答#,
		},
		'Asia/Chita' => {
			exemplarCity => q#赤塔#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#可倫坡#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#大馬士革#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#達卡#,
		},
		'Asia/Dili' => {
			exemplarCity => q#帝力#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#杜拜#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#杜桑貝#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#法馬古斯塔#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#加薩#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#赫布隆#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#中華人民共和國香港特別行政區#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#科布多#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#伊爾庫次克#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#雅加達#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#加亞布拉#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#耶路撒冷#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#喀布爾#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#堪察加#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#喀拉蚩#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#加德滿都#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#堪地加#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#克拉斯諾亞爾斯克#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#吉隆坡#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#古晉#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#科威特#,
		},
		'Asia/Macau' => {
			exemplarCity => q#中華人民共和國澳門特別行政區#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#馬加丹#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#馬卡沙爾#,
		},
		'Asia/Manila' => {
			exemplarCity => q#馬尼拉#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#馬斯開特#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#尼古西亞#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#新庫茲涅茨克#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#新西伯利亞#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#鄂木斯克#,
		},
		'Asia/Oral' => {
			exemplarCity => q#烏拉爾#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#金邊#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#坤甸#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#平壤#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#卡達#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#科斯塔奈#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#克孜勒奧爾達#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#仰光#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#利雅德#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#胡志明市#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#庫頁島#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#撒馬爾罕#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#首爾#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#上海#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#新加坡#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#中科雷姆斯克#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#台北#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#塔什干#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#第比利斯#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#德黑蘭#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#廷布#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#東京#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#托木斯克#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#烏蘭巴托#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#烏魯木齊#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#烏斯內拉#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#永珍#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#海參崴#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#雅庫次克#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#葉卡捷林堡#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#葉里溫#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#大西洋夏令時間#,
				'generic' => q#大西洋時間#,
				'standard' => q#大西洋標準時間#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#亞速爾群島#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#百慕達#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#加納利#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#維德角#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#法羅群島#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#馬得拉群島#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#雷克雅維克#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#南喬治亞#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#聖赫勒拿島#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#史坦利#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#阿得雷德#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#布利斯班#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#布羅肯希爾#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#達爾文#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#尤克拉#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#荷巴特#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#林德曼#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#豪勳爵島#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#墨爾本#,
		},
		'Australia/Perth' => {
			exemplarCity => q#伯斯#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#雪梨#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#澳洲中部夏令時間#,
				'generic' => q#澳洲中部時間#,
				'standard' => q#澳洲中部標準時間#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#澳洲中西部夏令時間#,
				'generic' => q#澳洲中西部時間#,
				'standard' => q#澳洲中西部標準時間#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#澳洲東部夏令時間#,
				'generic' => q#澳洲東部時間#,
				'standard' => q#澳洲東部標準時間#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#澳洲西部夏令時間#,
				'generic' => q#澳洲西部時間#,
				'standard' => q#澳洲西部標準時間#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#亞塞拜然夏令時間#,
				'generic' => q#亞塞拜然時間#,
				'standard' => q#亞塞拜然標準時間#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#亞速爾群島夏令時間#,
				'generic' => q#亞速爾群島時間#,
				'standard' => q#亞速爾群島標準時間#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#孟加拉夏令時間#,
				'generic' => q#孟加拉時間#,
				'standard' => q#孟加拉標準時間#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#不丹時間#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#玻利維亞時間#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#巴西利亞夏令時間#,
				'generic' => q#巴西利亞時間#,
				'standard' => q#巴西利亞標準時間#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#汶萊時間#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#維德角夏令時間#,
				'generic' => q#維德角時間#,
				'standard' => q#維德角標準時間#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#凱西站時間#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#查莫洛時間#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#查坦群島夏令時間#,
				'generic' => q#查坦群島時間#,
				'standard' => q#查坦群島標準時間#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#智利夏令時間#,
				'generic' => q#智利時間#,
				'standard' => q#智利標準時間#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#中國夏令時間#,
				'generic' => q#中國時間#,
				'standard' => q#中國標準時間#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#聖誕島時間#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#科科斯群島時間#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#哥倫比亞夏令時間#,
				'generic' => q#哥倫比亞時間#,
				'standard' => q#哥倫比亞標準時間#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#庫克群島半夏令時間#,
				'generic' => q#庫克群島時間#,
				'standard' => q#庫克群島標準時間#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#古巴夏令時間#,
				'generic' => q#古巴時間#,
				'standard' => q#古巴標準時間#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#戴維斯時間#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#杜蒙杜比爾時間#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#東帝汶時間#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#復活節島夏令時間#,
				'generic' => q#復活節島時間#,
				'standard' => q#復活節島標準時間#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#厄瓜多時間#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#協調世界時間#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#未知城市#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#阿姆斯特丹#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#安道爾#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#阿斯特拉罕#,
		},
		'Europe/Athens' => {
			exemplarCity => q#雅典#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#貝爾格勒#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#柏林#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#布拉提斯拉瓦#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#布魯塞爾#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#布加勒斯特#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#布達佩斯#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#布辛根#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#奇西瑙#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#哥本哈根#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#都柏林#,
			long => {
				'daylight' => q#愛爾蘭標準時間#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#直布羅陀#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#根息島#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#赫爾辛基#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#曼島#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#伊斯坦堡#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#澤西島#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#加里寧格勒#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#基輔#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#基洛夫#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#里斯本#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#盧比安納#,
		},
		'Europe/London' => {
			exemplarCity => q#倫敦#,
			long => {
				'daylight' => q#英國夏令時間#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#盧森堡#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#馬德里#,
		},
		'Europe/Malta' => {
			exemplarCity => q#馬爾他#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#瑪麗港#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#明斯克#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#摩納哥#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#莫斯科#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#奧斯陸#,
		},
		'Europe/Paris' => {
			exemplarCity => q#巴黎#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#波多里察#,
		},
		'Europe/Prague' => {
			exemplarCity => q#布拉格#,
		},
		'Europe/Riga' => {
			exemplarCity => q#里加#,
		},
		'Europe/Rome' => {
			exemplarCity => q#羅馬#,
		},
		'Europe/Samara' => {
			exemplarCity => q#沙馬拉#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#聖馬利諾#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#塞拉耶佛#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#薩拉托夫#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#辛非洛浦#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#史高比耶#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#索菲亞#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#斯德哥爾摩#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#塔林#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#地拉那#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#烏里揚諾夫斯克#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#瓦都茲#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#梵蒂岡#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#維也納#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#維爾紐斯#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#伏爾加格勒#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#華沙#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#札格瑞布#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#蘇黎世#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#中歐夏令時間#,
				'generic' => q#中歐時間#,
				'standard' => q#中歐標準時間#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#東歐夏令時間#,
				'generic' => q#東歐時間#,
				'standard' => q#東歐標準時間#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#歐洲遠東時間#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#西歐夏令時間#,
				'generic' => q#西歐時間#,
				'standard' => q#西歐標準時間#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#福克蘭群島夏令時間#,
				'generic' => q#福克蘭群島時間#,
				'standard' => q#福克蘭群島標準時間#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#斐濟夏令時間#,
				'generic' => q#斐濟時間#,
				'standard' => q#斐濟標準時間#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#法屬圭亞那時間#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#法國南方及南極時間#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#格林威治標準時間#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#加拉巴哥群島時間#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#甘比爾群島時間#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#喬治亞夏令時間#,
				'generic' => q#喬治亞時間#,
				'standard' => q#喬治亞標準時間#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#吉爾伯特群島時間#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#格陵蘭東部夏令時間#,
				'generic' => q#格陵蘭東部時間#,
				'standard' => q#格陵蘭東部標準時間#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#格陵蘭西部夏令時間#,
				'generic' => q#格陵蘭西部時間#,
				'standard' => q#格陵蘭西部標準時間#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#關島標準時間#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#波斯灣海域標準時間#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#蓋亞那時間#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#夏威夷-阿留申夏令時間#,
				'generic' => q#夏威夷-阿留申時間#,
				'standard' => q#夏威夷-阿留申標準時間#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#香港夏令時間#,
				'generic' => q#香港時間#,
				'standard' => q#香港標準時間#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#科布多夏令時間#,
				'generic' => q#科布多時間#,
				'standard' => q#科布多標準時間#,
			},
		},
		'India' => {
			long => {
				'standard' => q#印度標準時間#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#安塔那那利佛#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#查戈斯#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#聖誕島#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#科科斯群島#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#科摩羅群島#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#凱爾蓋朗島#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#馬埃島#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#馬爾地夫#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#模里西斯#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#馬約特島#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#留尼旺島#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#印度洋時間#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#印度支那時間#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#印尼中部時間#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#印尼東部時間#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#印尼西部時間#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#伊朗夏令時間#,
				'generic' => q#伊朗時間#,
				'standard' => q#伊朗標準時間#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#伊爾庫次克夏令時間#,
				'generic' => q#伊爾庫次克時間#,
				'standard' => q#伊爾庫次克標準時間#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#以色列夏令時間#,
				'generic' => q#以色列時間#,
				'standard' => q#以色列標準時間#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#日本夏令時間#,
				'generic' => q#日本時間#,
				'standard' => q#日本標準時間#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#彼得羅巴甫洛夫斯克日光節約時間#,
				'generic' => q#彼得羅巴甫洛夫斯克時間#,
				'standard' => q#彼得羅巴甫洛夫斯克標準時間#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#哈薩克時間#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#東哈薩克時間#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#西哈薩克時間#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#韓國夏令時間#,
				'generic' => q#韓國時間#,
				'standard' => q#韓國標準時間#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#科斯瑞時間#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#克拉斯諾亞爾斯克夏令時間#,
				'generic' => q#克拉斯諾亞爾斯克時間#,
				'standard' => q#克拉斯諾亞爾斯克標準時間#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#吉爾吉斯時間#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#蘭卡時間#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#萊恩群島時間#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#豪勳爵島夏令時間#,
				'generic' => q#豪勳爵島時間#,
				'standard' => q#豪勳爵島標準時間#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#澳門夏令時間#,
				'generic' => q#澳門時間#,
				'standard' => q#澳門標準時間#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#馬加丹夏令時間#,
				'generic' => q#馬加丹時間#,
				'standard' => q#馬加丹標準時間#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#馬來西亞時間#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#馬爾地夫時間#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#馬可薩斯時間#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#馬紹爾群島時間#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#模里西斯夏令時間#,
				'generic' => q#模里西斯時間#,
				'standard' => q#模里西斯標準時間#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#莫森時間#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#墨西哥太平洋夏令時間#,
				'generic' => q#墨西哥太平洋時間#,
				'standard' => q#墨西哥太平洋標準時間#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#烏蘭巴托夏令時間#,
				'generic' => q#烏蘭巴托時間#,
				'standard' => q#烏蘭巴托標準時間#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#莫斯科夏令時間#,
				'generic' => q#莫斯科時間#,
				'standard' => q#莫斯科標準時間#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#緬甸時間#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#諾魯時間#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#尼泊爾時間#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#新喀里多尼亞群島夏令時間#,
				'generic' => q#新喀里多尼亞時間#,
				'standard' => q#新喀里多尼亞標準時間#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#紐西蘭夏令時間#,
				'generic' => q#紐西蘭時間#,
				'standard' => q#紐西蘭標準時間#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#紐芬蘭夏令時間#,
				'generic' => q#紐芬蘭時間#,
				'standard' => q#紐芬蘭標準時間#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#紐埃島時間#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#諾福克島夏令時間#,
				'generic' => q#諾福克島時間#,
				'standard' => q#諾福克島標準時間#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#費爾南多 - 迪諾羅尼亞夏令時間#,
				'generic' => q#費爾南多 - 迪諾羅尼亞時間#,
				'standard' => q#費爾南多 - 迪諾羅尼亞標準時間#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#北馬里亞納群島時間#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#新西伯利亞夏令時間#,
				'generic' => q#新西伯利亞時間#,
				'standard' => q#新西伯利亞標準時間#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#鄂木斯克夏令時間#,
				'generic' => q#鄂木斯克時間#,
				'standard' => q#鄂木斯克標準時間#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#阿皮亞#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#奧克蘭#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#布干維爾#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#查坦#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#復活島#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#埃法特#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#恩得伯理島#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#法考福#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#斐濟#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#富那富提#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#加拉巴哥群島#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#甘比爾群島#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#瓜達康納爾島#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#關島#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#檀香山#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#坎頓#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#基里地馬地島#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#科斯瑞#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#瓜加林島#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#馬朱諾#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#馬可薩斯島#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#中途島#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#諾魯#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#紐埃島#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#諾福克#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#諾美亞#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#巴哥巴哥#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#帛琉#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#皮特肯群島#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#波納佩#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#莫士比港#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#拉羅湯加#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#塞班#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#大溪地#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#塔拉瓦#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#東加塔布島#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#楚克#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#威克#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#瓦利斯#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#巴基斯坦夏令時間#,
				'generic' => q#巴基斯坦時間#,
				'standard' => q#巴基斯坦標準時間#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#帛琉時間#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#巴布亞紐幾內亞時間#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#巴拉圭夏令時間#,
				'generic' => q#巴拉圭時間#,
				'standard' => q#巴拉圭標準時間#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#秘魯夏令時間#,
				'generic' => q#秘魯時間#,
				'standard' => q#秘魯標準時間#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#菲律賓夏令時間#,
				'generic' => q#菲律賓時間#,
				'standard' => q#菲律賓標準時間#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#鳳凰群島時間#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#聖皮埃爾和密克隆群島夏令時間#,
				'generic' => q#聖皮埃爾和密克隆群島時間#,
				'standard' => q#聖皮埃爾和密克隆群島標準時間#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#皮特肯時間#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#波納佩時間#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#平壤時間#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#克孜勒奧爾達夏令時間#,
				'generic' => q#克孜勒奧爾達時間#,
				'standard' => q#克孜勒奧爾達標準時間#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#留尼旺時間#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#羅瑟拉時間#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#庫頁島夏令時間#,
				'generic' => q#庫頁島時間#,
				'standard' => q#庫頁島標準時間#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#薩馬拉夏令時間#,
				'generic' => q#薩馬拉時間#,
				'standard' => q#薩馬拉標準時間#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#薩摩亞夏令時間#,
				'generic' => q#薩摩亞時間#,
				'standard' => q#薩摩亞標準時間#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#塞席爾時間#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#新加坡標準時間#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#索羅門群島時間#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#南喬治亞時間#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#蘇利南時間#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#昭和基地時間#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#大溪地時間#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#台北夏令時間#,
				'generic' => q#台北時間#,
				'standard' => q#台北標準時間#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#塔吉克時間#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#托克勞群島時間#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#東加夏令時間#,
				'generic' => q#東加時間#,
				'standard' => q#東加標準時間#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#楚克島時間#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#土庫曼夏令時間#,
				'generic' => q#土庫曼時間#,
				'standard' => q#土庫曼標準時間#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#吐瓦魯時間#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#烏拉圭夏令時間#,
				'generic' => q#烏拉圭時間#,
				'standard' => q#烏拉圭標準時間#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#烏茲別克夏令時間#,
				'generic' => q#烏茲別克時間#,
				'standard' => q#烏茲別克標準時間#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#萬那杜夏令時間#,
				'generic' => q#萬那杜時間#,
				'standard' => q#萬那杜標準時間#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#委內瑞拉時間#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#海參崴夏令時間#,
				'generic' => q#海參崴時間#,
				'standard' => q#海參崴標準時間#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#伏爾加格勒夏令時間#,
				'generic' => q#伏爾加格勒時間#,
				'standard' => q#伏爾加格勒標準時間#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#沃斯托克時間#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#威克島時間#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#瓦利斯和富圖納群島時間#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#雅庫次克夏令時間#,
				'generic' => q#雅庫次克時間#,
				'standard' => q#雅庫次克標準時間#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#葉卡捷琳堡夏令時間#,
				'generic' => q#葉卡捷琳堡時間#,
				'standard' => q#葉卡捷琳堡標準時間#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#育空時間#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
