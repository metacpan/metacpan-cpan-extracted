=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ko - Package for language Korean

=cut

package Locale::CLDR::Locales::Ko;
# This file auto generated from Data\common\main\ko.xml
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

extends('Locale::CLDR::Locales::Root');
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-sinokorean','spellout-cardinal-native-attributive','spellout-cardinal-native','spellout-cardinal-financial','spellout-ordinal-sinokorean-count','spellout-ordinal-native-count','spellout-ordinal-sinokorean','spellout-ordinal-native','digits-ordinal' ]},
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
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=번째),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=번째),
				},
			},
		},
		'spellout-cardinal-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(일),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(이),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(삼),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(사),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(오),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(육),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(칠),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(팔),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(구),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(←←십[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←백[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←천[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←만[→→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←억[→→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←조[→→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←경[→→]),
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
		'spellout-cardinal-native' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(하나),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(둘),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(셋),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(넷),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(다섯),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(여섯),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(일곱),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(여덟),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(아홉),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(열[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(스물[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(서른[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(마흔[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(쉰[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(예순[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(일흔[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(여든[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(아흔[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
			},
		},
		'spellout-cardinal-native-attributive' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(한),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(두),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(세),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(네),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(다섯),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(여섯),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(일곱),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(여덟),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(아홉),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(열[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(스무),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(스물[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(서른[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(마흔[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(쉰[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(예순[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(일흔[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(여든[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(아흔[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(백[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-sinokorean←백[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(천[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-sinokorean←천[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(만[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←%spellout-cardinal-sinokorean←만[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-cardinal-sinokorean←억[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-sinokorean←조[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←%spellout-cardinal-sinokorean←경[ →→]),
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
		'spellout-cardinal-sinokorean' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←점→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(일),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(이),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(삼),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(사),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(오),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(육),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(칠),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(팔),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(구),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(십[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←십[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(백[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←백[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(천[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←천[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(만[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←←만[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←억[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←조[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←경[ →→]),
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
					rule => q(공),
				},
				'0.x' => {
					divisor => q(1),
					rule => q(←%spellout-cardinal-sinokorean←점→→→),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←점→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-cardinal-sinokorean=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-cardinal-sinokorean=),
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
		'spellout-ordinal-native' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-priv=째),
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
		'spellout-ordinal-native-count' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-count-smaller= 번째),
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
		'spellout-ordinal-native-count-larger' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(한),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-native-attributive=),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(서른[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(마흔[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(쉰[→%spellout-cardinal-native-attributive→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(예순[→%spellout-cardinal-native-attributive→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(일흔[→%spellout-cardinal-native-attributive→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(여든[→%spellout-cardinal-native-attributive→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(아흔[→%spellout-cardinal-native-attributive→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(백[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-sinokorean←백[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(천[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-sinokorean←천[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(만[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←%spellout-cardinal-sinokorean←만[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-cardinal-sinokorean←억[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-sinokorean←조[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←%spellout-cardinal-sinokorean←경[ →→]),
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
		'spellout-ordinal-native-count-smaller' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(첫),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-native-attributive=),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-native-count-larger=),
				},
				'max' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-native-count-larger=),
				},
			},
		},
		'spellout-ordinal-native-priv' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(첫),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(둘),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-smaller=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-smaller=),
				},
			},
		},
		'spellout-ordinal-native-smaller' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(한),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(두),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(셋),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(넷),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(다섯),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(여섯),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(일곱),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(여덟),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(아홉),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(열[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(스무),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(스물[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(서른[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(마흔[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(쉰[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(예순[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(일흔[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(여든[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(아흔[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(백[→%%spellout-ordinal-native-smaller-x02→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-sinokorean←백[→%%spellout-ordinal-native-smaller-x02→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(천[→%%spellout-ordinal-native-smaller-x02→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-sinokorean←천[→%%spellout-ordinal-native-smaller-x02→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(만[ →%%spellout-ordinal-native-smaller-x02→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←%spellout-cardinal-sinokorean←만[ →%%spellout-ordinal-native-smaller-x02→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-cardinal-sinokorean←억[ →%%spellout-ordinal-native-smaller-x02→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-sinokorean←조[ →%%spellout-ordinal-native-smaller-x02→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←%spellout-cardinal-sinokorean←경[ →%%spellout-ordinal-native-smaller-x02→]),
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
		'spellout-ordinal-native-smaller-x02' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-smaller=),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(둘),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-smaller=),
				},
				'max' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-smaller=),
				},
			},
		},
		'spellout-ordinal-sinokorean' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-ordinal-native=),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%spellout-cardinal-sinokorean=째),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%spellout-ordinal-sinokorean-count-larger=째),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%spellout-ordinal-sinokorean-count-larger=째),
				},
			},
		},
		'spellout-ordinal-sinokorean-count' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(마이너스 →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-ordinal-native-count-smaller= 번째),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-sinokorean-count-smaller= 번째),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-sinokorean-count-smaller= 번째),
				},
			},
		},
		'spellout-ordinal-sinokorean-count-larger' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(일),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(이),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(삼),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(사),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(오),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(육),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(칠),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(팔),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(구),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(십[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←십[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(오십[→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(육십[→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(칠십[→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(팔십[→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(구십[→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(백[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←백[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(천[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←←천[→→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(만[ →→]),
				},
				'20000' => {
					base_value => q(20000),
					divisor => q(10000),
					rule => q(←←만[ →→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←억[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←조[ →→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←경[ →→]),
				},
				'max' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←경[ →→]),
				},
			},
		},
		'spellout-ordinal-sinokorean-count-smaller' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(영),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(한),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(두),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(세),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(네),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(다섯),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(여섯),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(일곱),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(여덟),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(아홉),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(열[→→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(스무),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(스물[→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(서른[→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(마흔[→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-sinokorean-count-larger=),
				},
				'max' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%%spellout-ordinal-sinokorean-count-larger=),
				},
			},
		},
    } },
);

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0}({1})';
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
				'aa' => '아파르어',
 				'ab' => '압카즈어',
 				'ace' => '아체어',
 				'ach' => '아콜리어',
 				'ada' => '아당메어',
 				'ady' => '아디게어',
 				'ae' => '아베스타어',
 				'aeb' => '튀니지 아랍어',
 				'af' => '아프리칸스어',
 				'afh' => '아프리힐리어',
 				'agq' => '아그햄어',
 				'ain' => '아이누어',
 				'ak' => '아칸어',
 				'akk' => '아카드어',
 				'ale' => '알류트어',
 				'alt' => '남부 알타이어',
 				'am' => '암하라어',
 				'an' => '아라곤어',
 				'ang' => '고대 영어',
 				'anp' => '앙가어',
 				'ar' => '아랍어',
 				'ar_001' => '현대 표준 아랍어',
 				'arc' => '아람어',
 				'arn' => '마푸둥군어',
 				'arp' => '아라파호어',
 				'arq' => '알제리 아랍어',
 				'ars' => '아랍어(나즈디)',
 				'arw' => '아라와크어',
 				'ary' => '모로코 아랍어',
 				'arz' => '이집트 아랍어',
 				'as' => '아삼어',
 				'asa' => '아수어',
 				'ast' => '아스투리아어',
 				'av' => '아바릭어',
 				'awa' => '아와히어',
 				'ay' => '아이마라어',
 				'az' => '아제르바이잔어',
 				'az@alt=short' => '아제리어',
 				'ba' => '바슈키르어',
 				'bal' => '발루치어',
 				'ban' => '발리어',
 				'bas' => '바사어',
 				'bax' => '바문어',
 				'bbj' => '고말라어',
 				'be' => '벨라루스어',
 				'bej' => '베자어',
 				'bem' => '벰바어',
 				'bez' => '베나어',
 				'bfd' => '바푸트어',
 				'bg' => '불가리아어',
 				'bgn' => '서부 발로치어',
 				'bho' => '호즈푸리어',
 				'bi' => '비슬라마어',
 				'bik' => '비콜어',
 				'bin' => '비니어',
 				'bkm' => '콤어',
 				'bla' => '식시카어',
 				'bm' => '밤바라어',
 				'bn' => '벵골어',
 				'bo' => '티베트어',
 				'br' => '브르타뉴어',
 				'bra' => '브라지어',
 				'brh' => '브라후이어',
 				'brx' => '보도어',
 				'bs' => '보스니아어',
 				'bss' => '아쿠즈어',
 				'bua' => '부리아타',
 				'bug' => '부기어',
 				'bum' => '불루어',
 				'byn' => '브린어',
 				'byv' => '메둠바어',
 				'ca' => '카탈로니아어',
 				'cad' => '카도어',
 				'car' => '카리브어',
 				'cay' => '카유가어',
 				'cch' => '앗삼어',
 				'ccp' => '차크마어',
 				'ce' => '체첸어',
 				'ceb' => '세부아노어',
 				'cgg' => '치가어',
 				'ch' => '차모로어',
 				'chb' => '치브차어',
 				'chg' => '차가타이어',
 				'chk' => '추크어',
 				'chm' => '마리어',
 				'chn' => '치누크 자곤',
 				'cho' => '촉토어',
 				'chp' => '치페우얀',
 				'chr' => '체로키어',
 				'chy' => '샤이엔어',
 				'ckb' => '소라니 쿠르드어',
 				'ckb@alt=menu' => '쿠르드어(소라니)',
 				'ckb@alt=variant' => '쿠르드어(소라니)',
 				'co' => '코르시카어',
 				'cop' => '콥트어',
 				'cr' => '크리어',
 				'crh' => '크리민 터키어; 크리민 타타르어',
 				'crs' => '세이셸 크리올 프랑스어',
 				'cs' => '체코어',
 				'csb' => '카슈비아어',
 				'cu' => '교회 슬라브어',
 				'cv' => '추바시어',
 				'cy' => '웨일스어',
 				'da' => '덴마크어',
 				'dak' => '다코타어',
 				'dar' => '다르그와어',
 				'dav' => '타이타어',
 				'de' => '독일어',
 				'de_CH' => '고지 독일어(스위스)',
 				'del' => '델라웨어어',
 				'den' => '슬라브어',
 				'dgr' => '도그리브어',
 				'din' => '딩카어',
 				'dje' => '자르마어',
 				'doi' => '도그리어',
 				'dsb' => '저지 소르비아어',
 				'dua' => '두알라어',
 				'dum' => '중세 네덜란드어',
 				'dv' => '디베히어',
 				'dyo' => '졸라 포니어',
 				'dyu' => '드율라어',
 				'dz' => '종카어',
 				'dzg' => '다장가어',
 				'ebu' => '엠부어',
 				'ee' => '에웨어',
 				'efi' => '이픽어',
 				'egy' => '고대 이집트어',
 				'eka' => '이카죽어',
 				'el' => '그리스어',
 				'elx' => '엘람어',
 				'en' => '영어',
 				'enm' => '중세 영어',
 				'eo' => '에스페란토어',
 				'es' => '스페인어',
 				'es_ES' => '스페인어(유럽)',
 				'et' => '에스토니아어',
 				'eu' => '바스크어',
 				'ewo' => '이원도어',
 				'fa' => '페르시아어',
 				'fa_AF' => '다리어',
 				'fan' => '팡그어',
 				'fat' => '판티어',
 				'ff' => '풀라어',
 				'fi' => '핀란드어',
 				'fil' => '필리핀어',
 				'fj' => '피지어',
 				'fo' => '페로어',
 				'fon' => '폰어',
 				'fr' => '프랑스어',
 				'frc' => '케이준 프랑스어',
 				'frm' => '중세 프랑스어',
 				'fro' => '고대 프랑스어',
 				'frr' => '북부 프리지아어',
 				'frs' => '동부 프리슬란드어',
 				'fur' => '프리울리어',
 				'fy' => '서부 프리지아어',
 				'ga' => '아일랜드어',
 				'gaa' => '가어',
 				'gag' => '가가우스어',
 				'gan' => '간어',
 				'gay' => '가요어',
 				'gba' => '그바야어',
 				'gbz' => '조로아스터 다리어',
 				'gd' => '스코틀랜드 게일어',
 				'gez' => '게이즈어',
 				'gil' => '키리바시어',
 				'gl' => '갈리시아어',
 				'glk' => '길라키어',
 				'gmh' => '중세 고지 독일어',
 				'gn' => '과라니어',
 				'goh' => '고대 고지 독일어',
 				'gom' => '고아 콘칸어',
 				'gon' => '곤디어',
 				'gor' => '고론탈로어',
 				'got' => '고트어',
 				'grb' => '게르보어',
 				'grc' => '고대 그리스어',
 				'gsw' => '독일어(스위스)',
 				'gu' => '구자라트어',
 				'guz' => '구시어',
 				'gv' => '맹크스어',
 				'gwi' => '그위친어',
 				'ha' => '하우사어',
 				'hai' => '하이다어',
 				'hak' => '하카어',
 				'haw' => '하와이어',
 				'he' => '히브리어',
 				'hi' => '힌디어',
 				'hif' => '피지 힌디어',
 				'hil' => '헤리가뇬어',
 				'hit' => '하타이트어',
 				'hmn' => '히몸어',
 				'ho' => '히리 모투어',
 				'hr' => '크로아티아어',
 				'hsb' => '고지 소르비아어',
 				'hsn' => '샹어',
 				'ht' => '아이티어',
 				'hu' => '헝가리어',
 				'hup' => '후파어',
 				'hy' => '아르메니아어',
 				'hz' => '헤레로어',
 				'ia' => '인터링구아',
 				'iba' => '이반어',
 				'ibb' => '이비비오어',
 				'id' => '인도네시아어',
 				'ie' => '인테르링구에',
 				'ig' => '이그보어',
 				'ii' => '쓰촨 이어',
 				'ik' => '이누피아크어',
 				'ilo' => '이로코어',
 				'inh' => '인귀시어',
 				'io' => '이도어',
 				'is' => '아이슬란드어',
 				'it' => '이탈리아어',
 				'iu' => '이눅티투트어',
 				'ja' => '일본어',
 				'jbo' => '로반어',
 				'jgo' => '응곰바어',
 				'jmc' => '마차메어',
 				'jpr' => '유대-페르시아어',
 				'jrb' => '유대-아라비아어',
 				'jv' => '자바어',
 				'ka' => '조지아어',
 				'kaa' => '카라칼파크어',
 				'kab' => '커바일어',
 				'kac' => '카친어',
 				'kaj' => '까꼬토끄어',
 				'kam' => '캄바어',
 				'kaw' => '카위어',
 				'kbd' => '카바르디어',
 				'kbl' => '카넴부어',
 				'kcg' => '티얍어',
 				'kde' => '마콘데어',
 				'kea' => '크리올어',
 				'kfo' => '코로어',
 				'kg' => '콩고어',
 				'kha' => '카시어',
 				'kho' => '호탄어',
 				'khq' => '코이라 친니어',
 				'khw' => '코와르어',
 				'ki' => '키쿠유어',
 				'kj' => '쿠안야마어',
 				'kk' => '카자흐어',
 				'kkj' => '카코어',
 				'kl' => '그린란드어',
 				'kln' => '칼렌진어',
 				'km' => '크메르어',
 				'kmb' => '킴분두어',
 				'kn' => '칸나다어',
 				'ko' => '한국어',
 				'koi' => '코미페르먀크어',
 				'kok' => '코카니어',
 				'kos' => '코스라이엔어',
 				'kpe' => '크펠레어',
 				'kr' => '칸누리어',
 				'krc' => '카라챠이-발카르어',
 				'krl' => '카렐리야어',
 				'kru' => '쿠르크어',
 				'ks' => '카슈미르어',
 				'ksb' => '샴발라어',
 				'ksf' => '바피아어',
 				'ksh' => '콜로그니안어',
 				'ku' => '쿠르드어',
 				'kum' => '쿠믹어',
 				'kut' => '쿠테네어',
 				'kv' => '코미어',
 				'kw' => '콘월어',
 				'ky' => '키르기스어',
 				'la' => '라틴어',
 				'lad' => '라디노어',
 				'lag' => '랑기어',
 				'lah' => '라한다어',
 				'lam' => '람바어',
 				'lb' => '룩셈부르크어',
 				'lez' => '레즈기안어',
 				'lfn' => '링구아 프랑카 노바',
 				'lg' => '간다어',
 				'li' => '림버거어',
 				'lkt' => '라코타어',
 				'ln' => '링갈라어',
 				'lo' => '라오어',
 				'lol' => '몽고어',
 				'lou' => '루이지애나 크리올어',
 				'loz' => '로지어',
 				'lrc' => '북부 루리어',
 				'lt' => '리투아니아어',
 				'lu' => '루바-카탄가어',
 				'lua' => '루바-룰루아어',
 				'lui' => '루이세노어',
 				'lun' => '룬다어',
 				'luo' => '루오어',
 				'lus' => '루샤이어',
 				'luy' => '루야어',
 				'lv' => '라트비아어',
 				'mad' => '마두라어',
 				'maf' => '마파어',
 				'mag' => '마가히어',
 				'mai' => '마이틸리어',
 				'mak' => '마카사어',
 				'man' => '만딩고어',
 				'mas' => '마사이어',
 				'mde' => '마바어',
 				'mdf' => '모크샤어',
 				'mdr' => '만다르어',
 				'men' => '멘데어',
 				'mer' => '메루어',
 				'mfe' => '모리스얀어',
 				'mg' => '말라가시어',
 				'mga' => '중세 아일랜드어',
 				'mgh' => '마크후와-메토어',
 				'mgo' => '메타어',
 				'mh' => '마셜어',
 				'mi' => '마오리어',
 				'mic' => '미크맥어',
 				'min' => '미낭카바우어',
 				'mk' => '마케도니아어',
 				'ml' => '말라얄람어',
 				'mn' => '몽골어',
 				'mnc' => '만주어',
 				'mni' => '마니푸리어',
 				'moh' => '모호크어',
 				'mos' => '모시어',
 				'mr' => '마라티어',
 				'mrj' => '서부 마리어',
 				'ms' => '말레이어',
 				'mt' => '몰타어',
 				'mua' => '문당어',
 				'mul' => '다중 언어',
 				'mus' => '크리크어',
 				'mwl' => '미란데어',
 				'mwr' => '마르와리어',
 				'my' => '버마어',
 				'mye' => '미예네어',
 				'myv' => '엘즈야어',
 				'mzn' => '마잔데라니어',
 				'na' => '나우루어',
 				'nan' => '민난어',
 				'nap' => '나폴리어',
 				'naq' => '나마어',
 				'nb' => '노르웨이어(보크말)',
 				'nd' => '북부 은데벨레어',
 				'nds' => '저지 독일어',
 				'nds_NL' => '저지 색슨어',
 				'ne' => '네팔어',
 				'new' => '네와르어',
 				'ng' => '느동가어',
 				'nia' => '니아스어',
 				'niu' => '니웨언어',
 				'nl' => '네덜란드어',
 				'nl_BE' => '플라망어',
 				'nmg' => '크와시오어',
 				'nn' => '노르웨이어(니노르스크)',
 				'nnh' => '느기엠본어',
 				'no' => '노르웨이어',
 				'nog' => '노가이어',
 				'non' => '고대 노르웨이어',
 				'nqo' => '응코어',
 				'nr' => '남부 은데벨레어',
 				'nso' => '북부 소토어',
 				'nus' => '누에르어',
 				'nv' => '나바호어',
 				'nwc' => '고전 네와르어',
 				'ny' => '냔자어',
 				'nym' => '니암웨지어',
 				'nyn' => '니안콜어',
 				'nyo' => '뉴로어',
 				'nzi' => '느지마어',
 				'oc' => '오크어',
 				'oj' => '오지브와어',
 				'om' => '오로모어',
 				'or' => '오리야어',
 				'os' => '오세트어',
 				'osa' => '오세이지어',
 				'ota' => '오스만 터키어',
 				'pa' => '펀잡어',
 				'pag' => '판가시난어',
 				'pal' => '팔레비어',
 				'pam' => '팜팡가어',
 				'pap' => '파피아먼토어',
 				'pau' => '팔라우어',
 				'pcm' => '나이지리아 피진어',
 				'peo' => '고대 페르시아어',
 				'phn' => '페니키아어',
 				'pi' => '팔리어',
 				'pl' => '폴란드어',
 				'pnt' => '폰틱어',
 				'pon' => '폼페이어',
 				'prg' => '프러시아어',
 				'pro' => '고대 프로방스어',
 				'ps' => '파슈토어',
 				'pt' => '포르투갈어',
 				'pt_PT' => '포르투갈어(유럽)',
 				'qu' => '케추아어',
 				'quc' => '키체어',
 				'raj' => '라자스탄어',
 				'rap' => '라파뉴이',
 				'rar' => '라로통가어',
 				'rhg' => '로힝야어',
 				'rm' => '로만시어',
 				'rn' => '룬디어',
 				'ro' => '루마니아어',
 				'ro_MD' => '몰도바어',
 				'rof' => '롬보어',
 				'rom' => '집시어',
 				'ru' => '러시아어',
 				'rue' => '루신어',
 				'rup' => '아로마니아어',
 				'rw' => '르완다어',
 				'rwk' => '르와어',
 				'sa' => '산스크리트어',
 				'sad' => '산다웨어',
 				'sah' => '야쿠트어',
 				'sam' => '사마리아 아랍어',
 				'saq' => '삼부루어',
 				'sas' => '사사크어',
 				'sat' => '산탈리어',
 				'sba' => '느감바이어',
 				'sbp' => '상구어',
 				'sc' => '사르디니아어',
 				'scn' => '시칠리아어',
 				'sco' => '스코틀랜드어',
 				'sd' => '신디어',
 				'sdh' => '남부 쿠르드어',
 				'se' => '북부 사미어',
 				'see' => '세네카어',
 				'seh' => '세나어',
 				'sel' => '셀쿠프어',
 				'ses' => '코이야보로 세니어',
 				'sg' => '산고어',
 				'sga' => '고대 아일랜드어',
 				'sh' => '세르비아-크로아티아어',
 				'shi' => '타셸히트어',
 				'shn' => '샨어',
 				'shu' => '차디언 아라비아어',
 				'si' => '싱할라어',
 				'sid' => '시다모어',
 				'sk' => '슬로바키아어',
 				'sl' => '슬로베니아어',
 				'sm' => '사모아어',
 				'sma' => '남부 사미어',
 				'smj' => '룰레 사미어',
 				'smn' => '이나리 사미어',
 				'sms' => '스콜트 사미어',
 				'sn' => '쇼나어',
 				'snk' => '소닌케어',
 				'so' => '소말리아어',
 				'sog' => '소그디엔어',
 				'sq' => '알바니아어',
 				'sr' => '세르비아어',
 				'srn' => '스라난 통가어',
 				'srr' => '세레르어',
 				'ss' => '시스와티어',
 				'ssy' => '사호어',
 				'st' => '남부 소토어',
 				'su' => '순다어',
 				'suk' => '수쿠마어',
 				'sus' => '수수어',
 				'sux' => '수메르어',
 				'sv' => '스웨덴어',
 				'sw' => '스와힐리어',
 				'sw_CD' => '콩고 스와힐리어',
 				'swb' => '코모로어',
 				'syc' => '고전 시리아어',
 				'syr' => '시리아어',
 				'ta' => '타밀어',
 				'te' => '텔루구어',
 				'tem' => '팀니어',
 				'teo' => '테조어',
 				'ter' => '테레노어',
 				'tet' => '테툼어',
 				'tg' => '타지크어',
 				'th' => '태국어',
 				'ti' => '티그리냐어',
 				'tig' => '티그레어',
 				'tiv' => '티브어',
 				'tk' => '투르크멘어',
 				'tkl' => '토켈라우제도어',
 				'tkr' => '차후르어',
 				'tl' => '타갈로그어',
 				'tlh' => '클링온어',
 				'tli' => '틀링깃족어',
 				'tly' => '탈리쉬어',
 				'tmh' => '타마섹어',
 				'tn' => '츠와나어',
 				'to' => '통가어',
 				'tog' => '니아사 통가어',
 				'tpi' => '토크 피신어',
 				'tr' => '터키어',
 				'trv' => '타로코어',
 				'ts' => '총가어',
 				'tsi' => '트심시안어',
 				'tt' => '타타르어',
 				'tum' => '툼부카어',
 				'tvl' => '투발루어',
 				'tw' => '트위어',
 				'twq' => '타사와크어',
 				'ty' => '타히티어',
 				'tyv' => '투비니안어',
 				'tzm' => '중앙 모로코 타마지트어',
 				'udm' => '우드말트어',
 				'ug' => '위구르어',
 				'uga' => '유가리틱어',
 				'uk' => '우크라이나어',
 				'umb' => '움분두어',
 				'und' => '알 수 없는 언어',
 				'ur' => '우르두어',
 				'uz' => '우즈베크어',
 				'vai' => '바이어',
 				've' => '벤다어',
 				'vi' => '베트남어',
 				'vo' => '볼라퓌크어',
 				'vot' => '보틱어',
 				'vun' => '분조어',
 				'wa' => '왈론어',
 				'wae' => '월저어',
 				'wal' => '월라이타어',
 				'war' => '와라이어',
 				'was' => '와쇼어',
 				'wbp' => '왈피리어',
 				'wo' => '월로프어',
 				'wuu' => '우어',
 				'xal' => '칼미크어',
 				'xh' => '코사어',
 				'xog' => '소가어',
 				'yao' => '야오족어',
 				'yap' => '얍페세어',
 				'yav' => '양본어',
 				'ybb' => '옘바어',
 				'yi' => '이디시어',
 				'yo' => '요루바어',
 				'yue' => '광둥어',
 				'yue@alt=menu' => '중국어(광둥어)',
 				'za' => '주앙어',
 				'zap' => '사포테크어',
 				'zbl' => '블리스 심볼',
 				'zen' => '제나가어',
 				'zgh' => '표준 모로코 타마지트어',
 				'zh' => '중국어',
 				'zh@alt=menu' => '중국어(만다린)',
 				'zh_Hans@alt=long' => '중국어(만다린, 간체)',
 				'zh_Hant@alt=long' => '중국어(만다린, 번체)',
 				'zu' => '줄루어',
 				'zun' => '주니어',
 				'zxx' => '언어 관련 내용 없음',
 				'zza' => '자자어',

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
			'Afak' => '아파카 문자',
 			'Aghb' => '코카시안 알바니아 문자',
 			'Arab' => '아랍 문자',
 			'Arab@alt=variant' => '페르소-아라비아 문자',
 			'Aran' => '나스탈리크체',
 			'Armi' => '아랍제국 문자',
 			'Armn' => '아르메니아 문자',
 			'Avst' => '아베스타 문자',
 			'Bali' => '발리 문자',
 			'Bamu' => '바뭄 문자',
 			'Bass' => '바사바흐 문자',
 			'Batk' => '바타크 문자',
 			'Beng' => '벵골 문자',
 			'Blis' => '블리스기호 문자',
 			'Bopo' => '주음부호',
 			'Brah' => '브라미',
 			'Brai' => '브라유 점자',
 			'Bugi' => '부기 문자',
 			'Buhd' => '부히드 문자',
 			'Cakm' => '차크마 문자',
 			'Cans' => '통합 캐나다 토착어',
 			'Cari' => '카리 문자',
 			'Cham' => '칸 고어',
 			'Cher' => '체로키 문자',
 			'Cirt' => '키르쓰',
 			'Copt' => '콥트 문자',
 			'Cprt' => '키프로스 문자',
 			'Cyrl' => '키릴 문자',
 			'Cyrs' => '고대교회슬라브어 키릴문자',
 			'Deva' => '데바나가리 문자',
 			'Dsrt' => '디저렛 문자',
 			'Dupl' => '듀플로이안 문자',
 			'Egyd' => '고대 이집트 민중문자',
 			'Egyh' => '고대 이집트 신관문자',
 			'Egyp' => '고대 이집트 신성문자',
 			'Elba' => '엘바산 문자',
 			'Ethi' => '에티오피아 문자',
 			'Geok' => '그루지야 쿠츠리 문자',
 			'Geor' => '조지아 문자',
 			'Glag' => '글라골 문자',
 			'Goth' => '고트 문자',
 			'Gran' => '그란타 문자',
 			'Grek' => '그리스 문자',
 			'Gujr' => '구자라트 문자',
 			'Guru' => '구르무키 문자',
 			'Hanb' => '주음 자모',
 			'Hang' => '한글',
 			'Hani' => '한자',
 			'Hano' => '하누누 문자',
 			'Hans' => '간체',
 			'Hans@alt=stand-alone' => '한자 간체',
 			'Hant' => '번체',
 			'Hant@alt=stand-alone' => '한자 번체',
 			'Hebr' => '히브리 문자',
 			'Hira' => '히라가나',
 			'Hluw' => '아나톨리아 상형문자',
 			'Hmng' => '파하우 몽 문자',
 			'Hrkt' => '가나',
 			'Hung' => '고대 헝가리 문자',
 			'Inds' => '인더스 문자',
 			'Ital' => '고대 이탈리아 문자',
 			'Jamo' => '자모',
 			'Java' => '자바 문자',
 			'Jpan' => '일본 문자',
 			'Jurc' => '줄첸 문자',
 			'Kali' => '카야 리 문자',
 			'Kana' => '가타카나',
 			'Khar' => '카로슈티 문자',
 			'Khmr' => '크메르 문자',
 			'Khoj' => '코즈키 문자',
 			'Knda' => '칸나다 문자',
 			'Kore' => '한국 문자',
 			'Kpel' => '크펠레 문자',
 			'Kthi' => '카이시 문자',
 			'Lana' => '란나 문자',
 			'Laoo' => '라오 문자',
 			'Latf' => '독일식 로마자',
 			'Latg' => '아일랜드식 로마자',
 			'Latn' => '로마자',
 			'Lepc' => '렙차 문자',
 			'Limb' => '림부 문자',
 			'Lina' => '선형 문자(A)',
 			'Linb' => '선형 문자(B)',
 			'Lisu' => '프레이저 문자',
 			'Loma' => '로마 문자',
 			'Lyci' => '리키아 문자',
 			'Lydi' => '리디아 문자',
 			'Mahj' => '마하자니 문자',
 			'Mand' => '만다이아 문자',
 			'Mani' => '마니교 문자',
 			'Maya' => '마야 상형 문자',
 			'Mend' => '멘데 문자',
 			'Merc' => '메로에 필기체',
 			'Mero' => '메로에 문자',
 			'Mlym' => '말라얄람 문자',
 			'Mong' => '몽골 문자',
 			'Moon' => '문 문자',
 			'Mroo' => '므로 문자',
 			'Mtei' => '메이테이 마옉 문자',
 			'Mymr' => '미얀마 문자',
 			'Narb' => '옛 북부 아라비아 문자',
 			'Nbat' => '나바테아 문자',
 			'Nkgb' => '나시 게바 문자',
 			'Nkoo' => '응코 문자',
 			'Nshu' => '누슈 문자',
 			'Ogam' => '오검 문자',
 			'Olck' => '올 치키 문자',
 			'Orkh' => '오르혼어',
 			'Orya' => '오리야 문자',
 			'Osma' => '오스마니아 문자',
 			'Palm' => '팔미라 문자',
 			'Perm' => '고대 페름 문자',
 			'Phag' => '파스파 문자',
 			'Phli' => '명문 팔라비 문자',
 			'Phlp' => '솔터 팔라비 문자',
 			'Phlv' => '북 팔라비 문자',
 			'Phnx' => '페니키아 문자',
 			'Plrd' => '폴라드 표음 문자',
 			'Prti' => '명문 파라티아 문자',
 			'Qaag' => '저지 문자',
 			'Rjng' => '레장 문자',
 			'Roro' => '롱고롱고',
 			'Runr' => '룬 문자',
 			'Samr' => '사마리아 문자',
 			'Sara' => '사라티',
 			'Sarb' => '옛 남부 아라비아 문자',
 			'Saur' => '사우라슈트라 문자',
 			'Sgnw' => '수화 문자',
 			'Shaw' => '샤비안 문자',
 			'Shrd' => '사라다 문자',
 			'Sidd' => '실담자',
 			'Sind' => '쿠다와디 문자',
 			'Sinh' => '신할라 문자',
 			'Sora' => '소라 솜펭 문자',
 			'Sund' => '순다 문자',
 			'Sylo' => '실헤티 나가리',
 			'Syrc' => '시리아 문자',
 			'Syre' => '에스트랑겔로식 시리아 문자',
 			'Syrj' => '서부 시리아 문자',
 			'Syrn' => '동부 시리아 문자',
 			'Tagb' => '타그반와 문자',
 			'Takr' => '타크리 문자',
 			'Tale' => '타이 레 문자',
 			'Talu' => '신 타이 루에',
 			'Taml' => '타밀 문자',
 			'Tang' => '탕구트 문자',
 			'Tavt' => '태국 베트남 문자',
 			'Telu' => '텔루구 문자',
 			'Teng' => '텡과르 문자',
 			'Tfng' => '티피나그 문자',
 			'Tglg' => '타갈로그 문자',
 			'Thaa' => '타나 문자',
 			'Thai' => '타이 문자',
 			'Tibt' => '티베트 문자',
 			'Tirh' => '티르후타 문자',
 			'Ugar' => '우가리트 문자',
 			'Vaii' => '바이 문자',
 			'Visp' => '시화법',
 			'Wara' => '바랑 크시티 문자',
 			'Wole' => '울레아이',
 			'Xpeo' => '고대 페르시아 문자',
 			'Xsux' => '수메르-아카드어 설형문자',
 			'Yiii' => '이 문자',
 			'Zinh' => '구전 문자',
 			'Zmth' => '수학 기호',
 			'Zsye' => '이모티콘',
 			'Zsym' => '기호',
 			'Zxxx' => '구전',
 			'Zyyy' => '일반 문자',
 			'Zzzz' => '알 수 없는 문자',

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
			'001' => '세계',
 			'002' => '아프리카',
 			'003' => '북아메리카',
 			'005' => '남아메리카',
 			'009' => '오세아니아',
 			'011' => '서부 아프리카',
 			'013' => '중앙 아메리카',
 			'014' => '동부 아프리카',
 			'015' => '북부 아프리카',
 			'017' => '중부 아프리카',
 			'018' => '남부 아프리카',
 			'019' => '아메리카 대륙',
 			'021' => '북부 아메리카',
 			'029' => '카리브 제도',
 			'030' => '동아시아',
 			'034' => '남아시아',
 			'035' => '동남아시아',
 			'039' => '남유럽',
 			'053' => '오스트랄라시아',
 			'054' => '멜라네시아',
 			'057' => '미크로네시아 지역',
 			'061' => '폴리네시아',
 			'142' => '아시아',
 			'143' => '중앙 아시아',
 			'145' => '서아시아',
 			'150' => '유럽',
 			'151' => '동유럽',
 			'154' => '북유럽',
 			'155' => '서유럽',
 			'202' => '사하라 사막 이남 아프리카',
 			'419' => '라틴 아메리카',
 			'AC' => '어센션섬',
 			'AD' => '안도라',
 			'AE' => '아랍에미리트',
 			'AF' => '아프가니스탄',
 			'AG' => '앤티가 바부다',
 			'AI' => '앵귈라',
 			'AL' => '알바니아',
 			'AM' => '아르메니아',
 			'AO' => '앙골라',
 			'AQ' => '남극 대륙',
 			'AR' => '아르헨티나',
 			'AS' => '아메리칸 사모아',
 			'AT' => '오스트리아',
 			'AU' => '오스트레일리아',
 			'AW' => '아루바',
 			'AX' => '올란드 제도',
 			'AZ' => '아제르바이잔',
 			'BA' => '보스니아 헤르체고비나',
 			'BB' => '바베이도스',
 			'BD' => '방글라데시',
 			'BE' => '벨기에',
 			'BF' => '부르키나파소',
 			'BG' => '불가리아',
 			'BH' => '바레인',
 			'BI' => '부룬디',
 			'BJ' => '베냉',
 			'BL' => '생바르텔레미',
 			'BM' => '버뮤다',
 			'BN' => '브루나이',
 			'BO' => '볼리비아',
 			'BQ' => '네덜란드령 카리브',
 			'BR' => '브라질',
 			'BS' => '바하마',
 			'BT' => '부탄',
 			'BV' => '부베섬',
 			'BW' => '보츠와나',
 			'BY' => '벨라루스',
 			'BZ' => '벨리즈',
 			'CA' => '캐나다',
 			'CC' => '코코스 제도',
 			'CD' => '콩고-킨샤사',
 			'CD@alt=variant' => '콩고민주공화국',
 			'CF' => '중앙 아프리카 공화국',
 			'CG' => '콩고-브라자빌',
 			'CG@alt=variant' => '콩고 공화국',
 			'CH' => '스위스',
 			'CI' => '코트디부아르',
 			'CI@alt=variant' => '아이보리 코스트',
 			'CK' => '쿡 제도',
 			'CL' => '칠레',
 			'CM' => '카메룬',
 			'CN' => '중국',
 			'CO' => '콜롬비아',
 			'CP' => '클리퍼턴섬',
 			'CR' => '코스타리카',
 			'CU' => '쿠바',
 			'CV' => '카보베르데',
 			'CW' => '퀴라소',
 			'CX' => '크리스마스섬',
 			'CY' => '키프로스',
 			'CZ' => '체코',
 			'CZ@alt=variant' => '체코 공화국',
 			'DE' => '독일',
 			'DG' => '디에고 가르시아',
 			'DJ' => '지부티',
 			'DK' => '덴마크',
 			'DM' => '도미니카',
 			'DO' => '도미니카 공화국',
 			'DZ' => '알제리',
 			'EA' => '세우타 및 멜리야',
 			'EC' => '에콰도르',
 			'EE' => '에스토니아',
 			'EG' => '이집트',
 			'EH' => '서사하라',
 			'ER' => '에리트리아',
 			'ES' => '스페인',
 			'ET' => '에티오피아',
 			'EU' => '유럽 연합',
 			'EZ' => '유로존',
 			'FI' => '핀란드',
 			'FJ' => '피지',
 			'FK' => '포클랜드 제도',
 			'FK@alt=variant' => '포클랜드 제도(말비나스 군도)',
 			'FM' => '미크로네시아',
 			'FO' => '페로 제도',
 			'FR' => '프랑스',
 			'GA' => '가봉',
 			'GB' => '영국',
 			'GD' => '그레나다',
 			'GE' => '조지아',
 			'GF' => '프랑스령 기아나',
 			'GG' => '건지',
 			'GH' => '가나',
 			'GI' => '지브롤터',
 			'GL' => '그린란드',
 			'GM' => '감비아',
 			'GN' => '기니',
 			'GP' => '과들루프',
 			'GQ' => '적도 기니',
 			'GR' => '그리스',
 			'GS' => '사우스조지아 사우스샌드위치 제도',
 			'GT' => '과테말라',
 			'GU' => '괌',
 			'GW' => '기니비사우',
 			'GY' => '가이아나',
 			'HK' => '홍콩(중국 특별행정구)',
 			'HK@alt=short' => '홍콩',
 			'HM' => '허드 맥도널드 제도',
 			'HN' => '온두라스',
 			'HR' => '크로아티아',
 			'HT' => '아이티',
 			'HU' => '헝가리',
 			'IC' => '카나리아 제도',
 			'ID' => '인도네시아',
 			'IE' => '아일랜드',
 			'IL' => '이스라엘',
 			'IM' => '맨섬',
 			'IN' => '인도',
 			'IO' => '영국령 인도양 식민지',
 			'IQ' => '이라크',
 			'IR' => '이란',
 			'IS' => '아이슬란드',
 			'IT' => '이탈리아',
 			'JE' => '저지',
 			'JM' => '자메이카',
 			'JO' => '요르단',
 			'JP' => '일본',
 			'KE' => '케냐',
 			'KG' => '키르기스스탄',
 			'KH' => '캄보디아',
 			'KI' => '키리바시',
 			'KM' => '코모로',
 			'KN' => '세인트키츠 네비스',
 			'KP' => '북한',
 			'KR' => '대한민국',
 			'KW' => '쿠웨이트',
 			'KY' => '케이맨 제도',
 			'KZ' => '카자흐스탄',
 			'LA' => '라오스',
 			'LB' => '레바논',
 			'LC' => '세인트루시아',
 			'LI' => '리히텐슈타인',
 			'LK' => '스리랑카',
 			'LR' => '라이베리아',
 			'LS' => '레소토',
 			'LT' => '리투아니아',
 			'LU' => '룩셈부르크',
 			'LV' => '라트비아',
 			'LY' => '리비아',
 			'MA' => '모로코',
 			'MC' => '모나코',
 			'MD' => '몰도바',
 			'ME' => '몬테네그로',
 			'MF' => '생마르탱',
 			'MG' => '마다가스카르',
 			'MH' => '마셜 제도',
 			'MK' => '북마케도니아',
 			'ML' => '말리',
 			'MM' => '미얀마',
 			'MN' => '몽골',
 			'MO' => '마카오(중국 특별행정구)',
 			'MO@alt=short' => '마카오',
 			'MP' => '북마리아나제도',
 			'MQ' => '마르티니크',
 			'MR' => '모리타니',
 			'MS' => '몬트세라트',
 			'MT' => '몰타',
 			'MU' => '모리셔스',
 			'MV' => '몰디브',
 			'MW' => '말라위',
 			'MX' => '멕시코',
 			'MY' => '말레이시아',
 			'MZ' => '모잠비크',
 			'NA' => '나미비아',
 			'NC' => '뉴칼레도니아',
 			'NE' => '니제르',
 			'NF' => '노퍽섬',
 			'NG' => '나이지리아',
 			'NI' => '니카라과',
 			'NL' => '네덜란드',
 			'NO' => '노르웨이',
 			'NP' => '네팔',
 			'NR' => '나우루',
 			'NU' => '니우에',
 			'NZ' => '뉴질랜드',
 			'OM' => '오만',
 			'PA' => '파나마',
 			'PE' => '페루',
 			'PF' => '프랑스령 폴리네시아',
 			'PG' => '파푸아뉴기니',
 			'PH' => '필리핀',
 			'PK' => '파키스탄',
 			'PL' => '폴란드',
 			'PM' => '생피에르 미클롱',
 			'PN' => '핏케언 제도',
 			'PR' => '푸에르토리코',
 			'PS' => '팔레스타인 지구',
 			'PS@alt=short' => '팔레스타인',
 			'PT' => '포르투갈',
 			'PW' => '팔라우',
 			'PY' => '파라과이',
 			'QA' => '카타르',
 			'QO' => '오세아니아 외곽',
 			'RE' => '레위니옹',
 			'RO' => '루마니아',
 			'RS' => '세르비아',
 			'RU' => '러시아',
 			'RW' => '르완다',
 			'SA' => '사우디아라비아',
 			'SB' => '솔로몬 제도',
 			'SC' => '세이셸',
 			'SD' => '수단',
 			'SE' => '스웨덴',
 			'SG' => '싱가포르',
 			'SH' => '세인트헬레나',
 			'SI' => '슬로베니아',
 			'SJ' => '스발바르제도-얀마웬섬',
 			'SK' => '슬로바키아',
 			'SL' => '시에라리온',
 			'SM' => '산마리노',
 			'SN' => '세네갈',
 			'SO' => '소말리아',
 			'SR' => '수리남',
 			'SS' => '남수단',
 			'ST' => '상투메 프린시페',
 			'SV' => '엘살바도르',
 			'SX' => '신트마르턴',
 			'SY' => '시리아',
 			'SZ' => '에스와티니',
 			'SZ@alt=variant' => '스와질란드',
 			'TA' => '트리스탄다쿠나',
 			'TC' => '터크스 케이커스 제도',
 			'TD' => '차드',
 			'TF' => '프랑스 남부 지방',
 			'TG' => '토고',
 			'TH' => '태국',
 			'TJ' => '타지키스탄',
 			'TK' => '토켈라우',
 			'TL' => '동티모르',
 			'TL@alt=variant' => '티모르레스테',
 			'TM' => '투르크메니스탄',
 			'TN' => '튀니지',
 			'TO' => '통가',
 			'TR' => '터키',
 			'TT' => '트리니다드 토바고',
 			'TV' => '투발루',
 			'TW' => '대만',
 			'TZ' => '탄자니아',
 			'UA' => '우크라이나',
 			'UG' => '우간다',
 			'UM' => '미국령 해외 제도',
 			'UN' => '국제연합',
 			'UN@alt=short' => '유엔',
 			'US' => '미국',
 			'UY' => '우루과이',
 			'UZ' => '우즈베키스탄',
 			'VA' => '바티칸 시국',
 			'VC' => '세인트빈센트그레나딘',
 			'VE' => '베네수엘라',
 			'VG' => '영국령 버진아일랜드',
 			'VI' => '미국령 버진아일랜드',
 			'VN' => '베트남',
 			'VU' => '바누아투',
 			'WF' => '왈리스-푸투나 제도',
 			'WS' => '사모아',
 			'XA' => '유사 억양',
 			'XB' => '유사 양방향',
 			'XK' => '코소보',
 			'YE' => '예멘',
 			'YT' => '마요트',
 			'ZA' => '남아프리카',
 			'ZM' => '잠비아',
 			'ZW' => '짐바브웨',
 			'ZZ' => '알려지지 않은 지역',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => '전통 독일어 표기법',
 			'1994' => '표준 레지아어 표기법',
 			'1996' => '독일어 표기법(1996년)',
 			'1606NICT' => '중세 후기 프랑스어(1606년까지)',
 			'1694ACAD' => '근대 초기 프랑스어',
 			'1959ACAD' => '관학식',
 			'ALALC97' => 'ALA-LC 로마자 표기법(1997년 개정)',
 			'ALUKU' => '알루꾸 방언',
 			'AREVELA' => '동아르메니아어',
 			'AREVMDA' => '서아르메니아어',
 			'BAKU1926' => '통합 투르크어 라틴 알파벳',
 			'BAUDDHA' => '바우다',
 			'BISCAYAN' => '비스카얀',
 			'BISKE' => '산조르지오/빌라 방언',
 			'BOONT' => '분틀링어',
 			'FONIPA' => 'IPA 음성학',
 			'FONUPA' => 'UPA 음성학',
 			'HEPBURN' => '헵번식 로마자 표기법',
 			'HOGNORSK' => '호그노르스크',
 			'ITIHASA' => '이띠아사',
 			'JAUER' => '야우어',
 			'KKCOR' => '공통 표기법',
 			'LAUKIKA' => '라우키카',
 			'LIPAW' => '레지아어 리포바치 방언',
 			'LUNA1918' => '루나1918',
 			'MONOTON' => '단음',
 			'NDYUKA' => '느듀카 방언',
 			'NEDIS' => '나티소네 방언',
 			'NJIVA' => '니바 방언',
 			'OSOJS' => '오세아코/오소가네 방언',
 			'PAMAKA' => '파마카 방언',
 			'PINYIN' => '병음 로마자 표기법',
 			'POLYTON' => '복음',
 			'POSIX' => 'Computer',
 			'PUTER' => '퓨터',
 			'REVISED' => '개정',
 			'ROZAJ' => '레지아어',
 			'SAAHO' => '사호어',
 			'SCOTLAND' => '스코틀랜드 표준 영어',
 			'SCOUSE' => '리버풀 방언',
 			'SOLBA' => '스톨비자/솔비카 방언',
 			'SURMIRAN' => '서미안',
 			'TARASK' => '타라쉬키에비샤 표기법',
 			'UCCOR' => '통합 표기법',
 			'UCRCOR' => '통합 개정 표기법',
 			'ULSTER' => '얼스터',
 			'VAIDIKA' => '바이디카',
 			'VALENCIA' => '발렌시아어',
 			'VALLADER' => '발라더',
 			'WADEGILE' => '웨이드-자일스식 로마자 표기법',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => '달력',
 			'cf' => '통화 형식',
 			'colalternate' => '기호 정렬 무시',
 			'colbackwards' => '악센트 역순 정렬',
 			'colcasefirst' => '대문자/소문자 순서',
 			'colcaselevel' => '대/소문자 구분 정렬',
 			'collation' => '정렬 순서',
 			'colnormalization' => '표준 정렬',
 			'colnumeric' => '숫자 정렬',
 			'colstrength' => '정렬 강도',
 			'currency' => '통화',
 			'hc' => '시간표시법(12시, 24시)',
 			'lb' => '줄바꿈 스타일',
 			'ms' => '계량법',
 			'numbers' => '숫자',
 			'timezone' => '시간대',
 			'va' => '방언',
 			'x' => '공개 여부',

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
 				'buddhist' => q{불교력},
 				'chinese' => q{음력},
 				'coptic' => q{콥트력},
 				'dangi' => q{단기력},
 				'ethiopic' => q{에티오피아력},
 				'ethiopic-amete-alem' => q{에티오피아 아메테 알렘력},
 				'gregorian' => q{양력},
 				'hebrew' => q{히브리력},
 				'indian' => q{인도력},
 				'islamic' => q{이슬람력},
 				'islamic-civil' => q{이슬람 상용력},
 				'islamic-umalqura' => q{이슬람력(움 알 쿠라)},
 				'iso8601' => q{ISO-8601 달력},
 				'japanese' => q{일본력},
 				'persian' => q{페르시안력},
 				'roc' => q{대만력},
 			},
 			'cf' => {
 				'account' => q{회계 통화 형식},
 				'standard' => q{표준 통화 형식},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{기호 정렬},
 				'shifted' => q{기호 무시 정렬},
 			},
 			'colbackwards' => {
 				'no' => q{악센트 일반 정렬},
 				'yes' => q{악센트 역순 정렬},
 			},
 			'colcasefirst' => {
 				'lower' => q{첫 소문자 정렬},
 				'no' => q{일반 대/소문자 정렬 순서},
 				'upper' => q{대문자 우선 정렬},
 			},
 			'colcaselevel' => {
 				'no' => q{대/소문자 무시 정렬},
 				'yes' => q{대/소문자 구분 정렬},
 			},
 			'collation' => {
 				'big5han' => q{중국어 번체 정렬 순서 (Big5)},
 				'compat' => q{호환성을 위해 이전 정렬 순서},
 				'dictionary' => q{사전 정렬순},
 				'ducet' => q{기본 유니코드 정렬 순서},
 				'eor' => q{유럽 정렬 규칙},
 				'gb2312han' => q{중국어 간체 정렬 순서 (GB2312)},
 				'phonebook' => q{전화번호부순},
 				'phonetic' => q{소리나는 대로 정렬 순서},
 				'pinyin' => q{병음순},
 				'reformed' => q{개정 정렬순},
 				'search' => q{범용 검색},
 				'searchjl' => q{한글 자음으로 검색},
 				'standard' => q{표준 정렬 순서},
 				'stroke' => q{자획순},
 				'traditional' => q{전통 역법},
 				'unihan' => q{부수순},
 				'zhuyin' => q{주음순},
 			},
 			'colnormalization' => {
 				'no' => q{표준화 없이 정렬},
 				'yes' => q{유니코드 표준화 정렬},
 			},
 			'colnumeric' => {
 				'no' => q{숫자별 정렬},
 				'yes' => q{숫자 정렬},
 			},
 			'colstrength' => {
 				'identical' => q{모두 정렬},
 				'primary' => q{기본 문자만 정렬},
 				'quaternary' => q{악센트/대소문자/전반각/가나 정렬},
 				'secondary' => q{악센트 정렬},
 				'tertiary' => q{악센트/대소문자/전반각 정렬},
 			},
 			'd0' => {
 				'fwidth' => q{전각},
 				'hwidth' => q{반각},
 				'npinyin' => q{숫자},
 			},
 			'hc' => {
 				'h11' => q{12시간제(0–11)},
 				'h12' => q{12시간제(1–12)},
 				'h23' => q{24시간제(0–23)},
 				'h24' => q{24시간제(1–24)},
 			},
 			'lb' => {
 				'loose' => q{줄바꿈 - 넓게},
 				'normal' => q{줄바꿈 - 보통},
 				'strict' => q{줄바꿈 - 좁게},
 			},
 			'm0' => {
 				'bgn' => q{미국 지명위원회(BGN)},
 				'ungegn' => q{유엔 지명전문가 그룹(UNGEGN)},
 			},
 			'ms' => {
 				'metric' => q{미터법},
 				'uksystem' => q{야드파운드법},
 				'ussystem' => q{미국 계량법},
 			},
 			'numbers' => {
 				'arab' => q{아라비아-인도식 숫자},
 				'arabext' => q{확장형 아라비아-인도식 숫자},
 				'armn' => q{아르메니아 숫자},
 				'armnlow' => q{아르메니아 소문자 숫자},
 				'bali' => q{발리 숫자},
 				'beng' => q{뱅골 숫자},
 				'brah' => q{브라미 숫자},
 				'cakm' => q{챠크마 숫자},
 				'cham' => q{참 숫자},
 				'deva' => q{데바나가리 숫자},
 				'ethi' => q{에티오피아 숫자},
 				'finance' => q{재무 숫자},
 				'fullwide' => q{전자 숫자},
 				'geor' => q{조지아 숫자},
 				'grek' => q{그리스 숫자},
 				'greklow' => q{그리스어 소문자 숫자},
 				'gujr' => q{구자라트 숫자},
 				'guru' => q{굴묵키 숫자},
 				'hanidec' => q{중국어 십진 숫자},
 				'hans' => q{중국어 간체 숫자},
 				'hansfin' => q{중국어 간체 재무 숫자},
 				'hant' => q{중국어 번체 숫자},
 				'hantfin' => q{중국어 번체 재무 숫자},
 				'hebr' => q{히브리 숫자},
 				'java' => q{자바 숫자},
 				'jpan' => q{일본 숫자},
 				'jpanfin' => q{일본 재무 숫자},
 				'kali' => q{카야 리식 숫자},
 				'khmr' => q{크메르 숫자},
 				'knda' => q{칸나다 숫자},
 				'lana' => q{타이 탐 호라 숫자},
 				'lanatham' => q{타이 탐탐 숫자},
 				'laoo' => q{라오 숫자},
 				'latn' => q{서양 숫자},
 				'lepc' => q{렙차 숫자},
 				'limb' => q{림부 숫자},
 				'mlym' => q{말라얄람 숫자},
 				'mong' => q{몽골 숫자},
 				'mtei' => q{메이테이 마옉 숫자},
 				'mymr' => q{미얀마 숫자},
 				'mymrshan' => q{미얀마 샨 숫자},
 				'native' => q{기본 숫자},
 				'olck' => q{올치키 숫자},
 				'orya' => q{오리야 숫자},
 				'osma' => q{오스마냐 숫자},
 				'roman' => q{로마 숫자},
 				'romanlow' => q{로마 소문자 숫자},
 				'saur' => q{사우라슈트라 숫자},
 				'shrd' => q{샤라다 숫자},
 				'sund' => q{순다 숫자},
 				'taml' => q{고대 타밀 숫자},
 				'tamldec' => q{타밀 숫자},
 				'telu' => q{텔루구 숫자},
 				'thai' => q{태국 숫자},
 				'tibt' => q{티벳 숫자},
 				'traditional' => q{전통적인 숫자},
 				'vaii' => q{바이 숫자},
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
			'metric' => q{미터법},
 			'UK' => q{영국식},
 			'US' => q{미국식},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => '언어: {0}',
 			'script' => '문자: {0}',
 			'region' => '지역: {0}',

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
			auxiliary => qr{[ᄀ-ᄒ ᅡ-ᅵ ᆨ-ᇂ 丘 串 乃 久 乖 九 乞 乫 乾 亂 亘 交 京 仇 今 介 件 价 企 伋 伎 伽 佳 佶 侃 來 侊 供 係 俓 俱 個 倞 倦 倨 假 偈 健 傀 傑 傾 僅 僑 價 儆 儉 儺 光 克 兢 內 公 共 其 具 兼 冀 冠 凱 刊 刮 券 刻 剋 剛 劇 劍 劒 功 加 劤 劫 勁 勍 勘 勤 勸 勻 勾 匡 匣 區 南 卦 却 卵 卷 卿 厥 去 及 口 句 叩 叫 可 各 吉 君 告 呱 呵 咎 咬 哥 哭 啓 喀 喇 喝 喫 喬 嗜 嘉 嘔 器 囊 困 固 圈 國 圭 圻 均 坎 坑 坤 坰 坵 垢 基 埼 堀 堅 堈 堪 堺 塊 塏 境 墾 壙 壞 夔 奇 奈 奎 契 奸 妓 妗 姑 姜 姦 娘 娜 嫁 嬌 孔 季 孤 宏 官 客 宮 家 寄 寇 寡 寬 尻 局 居 屆 屈 岐 岡 岬 崎 崑 崗 嵌 嵐 嶇 嶠 工 巧 巨 己 巾 干 幹 幾 庚 庫 康 廊 廐 廓 廣 建 弓 强 彊 徑 忌 急 怪 怯 恐 恝 恪 恭 悸 愆 感 愧 愷 愾 慊 慣 慤 慨 慶 慷 憩 憬 憾 懃 懇 懦 懶 懼 戈 戒 戟 戡 扱 技 抉 拉 拏 拐 拒 拘 括 拮 拱 拳 拷 拿 捏 据 捲 捺 掘 掛 控 揀 揆 揭 擊 擎 擒 據 擧 攪 攷 改 攻 故 敎 救 敢 敬 敲 斛 斤 旗 旣 昆 昑 景 晷 暇 暖 暠 暻 曠 曲 更 曷 朗 朞 期 机 杆 杞 杰 枏 果 枯 架 枸 柑 柩 柬 柯 校 根 格 桀 桂 桔 桿 梏 梗 械 梱 棄 棋 棍 棘 棨 棺 楗 楠 極 槁 構 槐 槨 槪 槻 槿 樂 橄 橋 橘 機 檄 檎 檢 櫃 欄 權 欺 款 歌 歐 歸 殼 毆 毬 氣 求 江 汨 汲 決 汽 沂 沽 洛 洸 浪 涇 淃 淇 減 渠 渴 湳 溝 溪 滑 滾 漑 潔 潰 澗 激 濫 灌 灸 炅 炚 炬 烙 烱 煖 爛 牽 犬 狂 狗 狡 狼 獗 玖 玘 珂 珏 珖 珙 珞 珪 球 琦 琨 琪 琯 琴 瑾 璂 璟 璣 璥 瓊 瓘 瓜 甄 甘 甲 男 畇 界 畸 畺 畿 疆 疥 疳 痂 痙 痼 癎 癩 癸 皆 皎 皐 盖 監 看 眷 睾 瞰 瞼 瞿 矜 矩 矯 硅 硬 碁 碣 磎 磬 磯 磵 祁 祇 祈 祛 祺 禁 禽 科 稈 稼 稽 稿 穀 究 穹 空 窘 窟 窮 窺 竅 竟 竭 競 竿 筋 筐 筠 箇 箕 箝 管 簡 粳 糠 系 糾 紀 納 紘 級 紺 絅 結 絞 給 絳 絹 絿 經 綱 綺 緊 繫 繭 繼 缺 罐 罫 羅 羈 羌 羔 群 羹 翹 考 耆 耉 耕 耭 耿 肌 肝 股 肩 肯 肱 胛 胱 脚 脛 腔 腱 膈 膏 膠 臘 臼 舅 舊 舡 艮 艱 芎 芥 芩 芹 苛 苟 苦 苽 茄 莖 菅 菊 菌 菓 菫 菰 落 葛 葵 蓋 蕎 蕨 薑 藁 藍 藿 蘭 蘿 虔 蚣 蛟 蝎 螺 蠟 蠱 街 衢 衲 衾 衿 袈 袞 袴 裙 裸 褐 襁 襟 襤 見 規 覡 覲 覺 觀 角 計 記 訣 訶 詭 誇 誡 誥 課 諫 諾 謙 講 謳 謹 譏 警 譴 谷 谿 豈 貢 貫 貴 賈 購 赳 起 跏 距 跨 踞 蹇 蹶 躬 軀 車 軌 軍 軻 較 輕 轎 轟 辜 近 迦 迲 适 逑 逕 逵 過 遣 遽 邏 那 邯 邱 郊 郎 郡 郭 酪 醵 金 鈐 鈞 鉀 鉅 鉗 鉤 銶 鋸 鋼 錡 錤 錦 錮 鍋 鍵 鎌 鎧 鏡 鑑 鑒 鑛 開 間 閘 閣 閨 闕 關 降 階 隔 隙 雇 難 鞏 鞠 鞨 鞫 頃 頸 顆 顧 飢 餃 館 饉 饋 饑 駒 駕 駱 騎 騏 騫 驅 驕 驚 驥 骨 高 鬼 魁 鮫 鯤 鯨 鱇 鳩 鵑 鵠 鷄 鷗 鸞 麒 麴 黔 鼓 龕 龜]},
			index => ['ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'],
			main => qr{[가-힣]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[‾ _ ＿ \- － ‐ ‑ — ― 〜 ・ , ， 、 ; ； \: ： ! ！ ¡ ? ？ ¿ . ． ‥ … 。 · ＇ ‘ ’ " ＂ “ ” ( （ ) ） \[ ［ \] ］ \N{U+FF5B} ｝ 〈 〉 《 》 「 」 『 』 【 】 〔 〕 § ¶ @ ＠ * ＊ / ／ \\ ＼ \& ＆ # ＃ % ％ ‰ † ‡ ′ ″ 〃 ※]},
		};
	},
EOT
: sub {
		return { index => ['ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'], };
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
					# Long Unit Identifier
					'' => {
						'name' => q(방향),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(방향),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(키비{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(키비{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(메비{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(메비{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(기비{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(기비{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(테비{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(테비{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(페비{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(페비{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(엑스비{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(엑스비{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(제비{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(제비{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(요비{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(요비{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(데시{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(데시{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(피코{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(피코{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(펨토{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(펨토{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(아토{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(아토{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(센티{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(센티{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(젭토{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(젭토{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(욕토{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(욕토{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(밀리{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(밀리{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(마이크로{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(마이크로{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(나노{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(나노{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(데카{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(데카{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(테라{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(테라{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(페타{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(페타{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(엑사{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(엑사{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(헥토{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(헥토{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(제타{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(제타{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(요타{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(요타{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(킬로{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(킬로{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(메가{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(메가{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(기가{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(기가{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(중력가속도),
						'other' => q({0} 중력가속도),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(중력가속도),
						'other' => q({0} 중력가속도),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(미터 매 초 제곱),
						'other' => q(제곱 초당 {0}미터),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(미터 매 초 제곱),
						'other' => q(제곱 초당 {0}미터),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(분각),
						'other' => q({0}분각),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(분각),
						'other' => q({0}분각),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(각초),
						'other' => q({0}각초),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(각초),
						'other' => q({0}각초),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(도),
						'other' => q({0}도),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(도),
						'other' => q({0}도),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(라디안),
						'other' => q({0}라디안),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(라디안),
						'other' => q({0}라디안),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(회전),
						'other' => q({0}회전),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(회전),
						'other' => q({0}회전),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(에이커),
						'other' => q({0}에이커),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(에이커),
						'other' => q({0}에이커),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(두남),
						'other' => q({0}두남),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(두남),
						'other' => q({0}두남),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(헥타르),
						'other' => q({0}헥타르),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(헥타르),
						'other' => q({0}헥타르),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(제곱센티미터),
						'other' => q({0}제곱센티미터),
						'per' => q(제곱센티미터당 {0}),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(제곱센티미터),
						'other' => q({0}제곱센티미터),
						'per' => q(제곱센티미터당 {0}),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(제곱피트),
						'other' => q({0}제곱피트),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(제곱피트),
						'other' => q({0}제곱피트),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(제곱인치),
						'other' => q({0}제곱인치),
						'per' => q(제곱인치당 {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(제곱인치),
						'other' => q({0}제곱인치),
						'per' => q(제곱인치당 {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(제곱킬로미터),
						'other' => q({0}제곱킬로미터),
						'per' => q(제곱킬로미터당 {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(제곱킬로미터),
						'other' => q({0}제곱킬로미터),
						'per' => q(제곱킬로미터당 {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(제곱미터),
						'other' => q({0}제곱미터),
						'per' => q(제곱미터당 {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(제곱미터),
						'other' => q({0}제곱미터),
						'per' => q(제곱미터당 {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(제곱마일),
						'other' => q({0}제곱마일),
						'per' => q(제곱마일당 {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(제곱마일),
						'other' => q({0}제곱마일),
						'per' => q(제곱마일당 {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(제곱야드),
						'other' => q({0}제곱야드),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(제곱야드),
						'other' => q({0}제곱야드),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(항목),
						'other' => q({0}개 항목),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(항목),
						'other' => q({0}개 항목),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(캐럿),
						'other' => q({0}캐럿),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(캐럿),
						'other' => q({0}캐럿),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(데시리터당 밀리그램),
						'other' => q(데시리터당 {0}밀리그램),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(데시리터당 밀리그램),
						'other' => q(데시리터당 {0}밀리그램),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(리터당 밀리몰),
						'other' => q(리터당 {0}밀리몰),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(리터당 밀리몰),
						'other' => q(리터당 {0}밀리몰),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(몰),
						'other' => q({0}몰),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(몰),
						'other' => q({0}몰),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(100킬로미터당 리터),
						'other' => q(100킬로미터당 {0}리터),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(100킬로미터당 리터),
						'other' => q(100킬로미터당 {0}리터),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(킬로미터당 리터),
						'other' => q(킬로미터당 {0}리터),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(킬로미터당 리터),
						'other' => q(킬로미터당 {0}리터),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(갤런당 마일),
						'other' => q(갤런당 {0}마일),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(갤런당 마일),
						'other' => q(갤런당 {0}마일),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(영국식 갤런당 마일),
						'other' => q(영국식 갤런당 {0}마일),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(영국식 갤런당 마일),
						'other' => q(영국식 갤런당 {0}마일),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(동경 {0}),
						'north' => q(북위 {0}),
						'south' => q(남위 {0}),
						'west' => q(서경 {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(동경 {0}),
						'north' => q(북위 {0}),
						'south' => q(남위 {0}),
						'west' => q(서경 {0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(비트),
						'other' => q({0}비트),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(비트),
						'other' => q({0}비트),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(바이트),
						'other' => q({0}바이트),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(바이트),
						'other' => q({0}바이트),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(기가비트),
						'other' => q({0}기가비트),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(기가비트),
						'other' => q({0}기가비트),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(기가바이트),
						'other' => q({0}기가바이트),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(기가바이트),
						'other' => q({0}기가바이트),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(킬로비트),
						'other' => q({0}킬로비트),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(킬로비트),
						'other' => q({0}킬로비트),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(킬로바이트),
						'other' => q({0}킬로바이트),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(킬로바이트),
						'other' => q({0}킬로바이트),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(메가비트),
						'other' => q({0}메가비트),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(메가비트),
						'other' => q({0}메가비트),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(메가바이트),
						'other' => q({0}메가바이트),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(메가바이트),
						'other' => q({0}메가바이트),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(페타바이트),
						'other' => q({0}페타바이트),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(페타바이트),
						'other' => q({0}페타바이트),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(테라비트),
						'other' => q({0}테라비트),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(테라비트),
						'other' => q({0}테라비트),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(테라바이트),
						'other' => q({0}테라바이트),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(테라바이트),
						'other' => q({0}테라바이트),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(세기),
						'other' => q({0}세기),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(세기),
						'other' => q({0}세기),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q(일당 {0}),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q(일당 {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q(시간당 {0}),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q(시간당 {0}),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(마이크로초),
						'other' => q({0}마이크로초),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(마이크로초),
						'other' => q({0}마이크로초),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(밀리초),
						'other' => q({0}밀리초),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(밀리초),
						'other' => q({0}밀리초),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q(분당 {0}),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q(분당 {0}),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q(월당 {0}),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q(월당 {0}),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(나노초),
						'other' => q({0}나노초),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(나노초),
						'other' => q({0}나노초),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q(초당 {0}),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q(초당 {0}),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q(주당 {0}),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q(주당 {0}),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q(연당 {0}),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q(연당 {0}),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(암페어),
						'other' => q({0}암페어),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(암페어),
						'other' => q({0}암페어),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(밀리암페어),
						'other' => q({0}밀리암페어),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(밀리암페어),
						'other' => q({0}밀리암페어),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(옴),
						'other' => q({0}옴),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(옴),
						'other' => q({0}옴),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(볼트),
						'other' => q({0}볼트),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(볼트),
						'other' => q({0}볼트),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(영국 열량 단위),
						'other' => q({0}영국 열량 단위),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(영국 열량 단위),
						'other' => q({0}영국 열량 단위),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(칼로리),
						'other' => q({0}칼로리),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(칼로리),
						'other' => q({0}칼로리),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(전자볼트),
						'other' => q({0}전자볼트),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(전자볼트),
						'other' => q({0}전자볼트),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(칼로리),
						'other' => q({0}칼로리),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(칼로리),
						'other' => q({0}칼로리),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(줄),
						'other' => q({0}줄),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(줄),
						'other' => q({0}줄),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(킬로칼로리),
						'other' => q({0}킬로칼로리),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(킬로칼로리),
						'other' => q({0}킬로칼로리),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(킬로줄),
						'other' => q({0}킬로줄),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(킬로줄),
						'other' => q({0}킬로줄),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(킬로와트시),
						'other' => q({0}킬로와트시),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(킬로와트시),
						'other' => q({0}킬로와트시),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(미국 섬),
						'other' => q({0}섬),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(미국 섬),
						'other' => q({0}섬),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(100킬로미터당 킬로와트시),
						'other' => q(100킬로미터당 {0}킬로와트시),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(100킬로미터당 킬로와트시),
						'other' => q(100킬로미터당 {0}킬로와트시),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(뉴턴),
						'other' => q({0}뉴턴),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(뉴턴),
						'other' => q({0}뉴턴),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(파운드포스),
						'other' => q({0}파운드포스),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(파운드포스),
						'other' => q({0}파운드포스),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(기가헤르츠),
						'other' => q({0}기가헤르츠),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(기가헤르츠),
						'other' => q({0}기가헤르츠),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(헤르츠),
						'other' => q({0}헤르츠),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(헤르츠),
						'other' => q({0}헤르츠),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(킬로헤르츠),
						'other' => q({0}킬로헤르츠),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(킬로헤르츠),
						'other' => q({0}킬로헤르츠),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(메가헤르츠),
						'other' => q({0}메가헤르츠),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(메가헤르츠),
						'other' => q({0}메가헤르츠),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'other' => q({0}dot),
					},
					# Core Unit Identifier
					'dot' => {
						'other' => q({0}dot),
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
					'graphics-em' => {
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
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
					'length-astronomical-unit' => {
						'name' => q(천문 단위),
						'other' => q({0}천문 단위),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(천문 단위),
						'other' => q({0}천문 단위),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(센티미터),
						'other' => q({0}센티미터),
						'per' => q(센티미터당 {0}),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(센티미터),
						'other' => q({0}센티미터),
						'per' => q(센티미터당 {0}),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(데시미터),
						'other' => q({0}데시미터),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(데시미터),
						'other' => q({0}데시미터),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(지구 반경),
						'other' => q({0}지구 반경),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(지구 반경),
						'other' => q({0}지구 반경),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(패덤),
						'other' => q({0}패덤),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(패덤),
						'other' => q({0}패덤),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(피트),
						'other' => q({0}피트),
						'per' => q(피트당 {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(피트),
						'other' => q({0}피트),
						'per' => q(피트당 {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(펄롱),
						'other' => q({0}펄롱),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(펄롱),
						'other' => q({0}펄롱),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(인치),
						'other' => q({0}인치),
						'per' => q(인치당 {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(인치),
						'other' => q({0}인치),
						'per' => q(인치당 {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(킬로미터),
						'other' => q({0}킬로미터),
						'per' => q(킬로미터당 {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(킬로미터),
						'other' => q({0}킬로미터),
						'per' => q(킬로미터당 {0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(광년),
						'other' => q({0}광년),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(광년),
						'other' => q({0}광년),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(미터),
						'other' => q({0}미터),
						'per' => q(미터당 {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(미터),
						'other' => q({0}미터),
						'per' => q(미터당 {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(마이크로미터),
						'other' => q({0}마이크로미터),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(마이크로미터),
						'other' => q({0}마이크로미터),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(마일),
						'other' => q({0}마일),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(마일),
						'other' => q({0}마일),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(스칸디나비아 마일),
						'other' => q({0}스칸디나비아 마일),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(스칸디나비아 마일),
						'other' => q({0}스칸디나비아 마일),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(밀리미터),
						'other' => q({0}밀리미터),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(밀리미터),
						'other' => q({0}밀리미터),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(나노미터),
						'other' => q({0}나노미터),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(나노미터),
						'other' => q({0}나노미터),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(해리),
						'other' => q({0}해리),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(해리),
						'other' => q({0}해리),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(파섹),
						'other' => q({0}파섹),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(파섹),
						'other' => q({0}파섹),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(피코미터),
						'other' => q({0}피코미터),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(피코미터),
						'other' => q({0}피코미터),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(포인트),
						'other' => q({0}포인트),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(포인트),
						'other' => q({0}포인트),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(태양 반경),
						'other' => q({0}태양 반경),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(태양 반경),
						'other' => q({0}태양 반경),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(야드),
						'other' => q({0}야드),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(야드),
						'other' => q({0}야드),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(칸델라),
						'other' => q({0}칸델라),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(칸델라),
						'other' => q({0}칸델라),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(루멘),
						'other' => q({0}루멘),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(루멘),
						'other' => q({0}루멘),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(룩스),
						'other' => q({0}룩스),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(룩스),
						'other' => q({0}룩스),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(태양 광도),
						'other' => q({0}태양 광도),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(태양 광도),
						'other' => q({0}태양 광도),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(캐럿),
						'other' => q({0}캐럿),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(캐럿),
						'other' => q({0}캐럿),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(돌턴),
						'other' => q({0}돌턴),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(돌턴),
						'other' => q({0}돌턴),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(지구 질량),
						'other' => q({0}지구 질량),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(지구 질량),
						'other' => q({0}지구 질량),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(그레인),
						'other' => q({0}그레인),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(그레인),
						'other' => q({0}그레인),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(그램),
						'other' => q({0}그램),
						'per' => q(그램당 {0}),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(그램),
						'other' => q({0}그램),
						'per' => q(그램당 {0}),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(킬로그램),
						'other' => q({0}킬로그램),
						'per' => q(킬로그램당 {0}),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(킬로그램),
						'other' => q({0}킬로그램),
						'per' => q(킬로그램당 {0}),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(메트릭 톤),
						'other' => q({0}메트릭 톤),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(메트릭 톤),
						'other' => q({0}메트릭 톤),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(마이크로그램),
						'other' => q({0}마이크로그램),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(마이크로그램),
						'other' => q({0}마이크로그램),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(밀리그램),
						'other' => q({0}밀리그램),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(밀리그램),
						'other' => q({0}밀리그램),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(온스),
						'other' => q({0}온스),
						'per' => q(온스당 {0}),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(온스),
						'other' => q({0}온스),
						'per' => q(온스당 {0}),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(트로이 온스),
						'other' => q({0}트로이 온스),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(트로이 온스),
						'other' => q({0}트로이 온스),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(파운드),
						'other' => q({0}파운드),
						'per' => q(파운드당 {0}),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(파운드),
						'other' => q({0}파운드),
						'per' => q(파운드당 {0}),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(태양 질량),
						'other' => q({0}태양 질량),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(태양 질량),
						'other' => q({0}태양 질량),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(스톤),
						'other' => q({0}스톤),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(스톤),
						'other' => q({0}스톤),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(톤),
						'other' => q({0}톤),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(톤),
						'other' => q({0}톤),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({1}당 {0}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({1}당 {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(기가와트),
						'other' => q({0}기가와트),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(기가와트),
						'other' => q({0}기가와트),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(마력),
						'other' => q({0}마력),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(마력),
						'other' => q({0}마력),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(킬로와트),
						'other' => q({0}킬로와트),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(킬로와트),
						'other' => q({0}킬로와트),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(메가와트),
						'other' => q({0}메가와트),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(메가와트),
						'other' => q({0}메가와트),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(밀리와트),
						'other' => q({0}밀리와트),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(밀리와트),
						'other' => q({0}밀리와트),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(와트),
						'other' => q({0}와트),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(와트),
						'other' => q({0}와트),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(제곱{0}),
						'other' => q(제곱{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(제곱{0}),
						'other' => q(제곱{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(세제곱{0}),
						'other' => q(세제곱{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(세제곱{0}),
						'other' => q(세제곱{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(바),
						'other' => q({0}바),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(바),
						'other' => q({0}바),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(헥토파스칼),
						'other' => q({0}헥토파스칼),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(헥토파스칼),
						'other' => q({0}헥토파스칼),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(수은주인치),
						'other' => q({0}수은주인치),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(수은주인치),
						'other' => q({0}수은주인치),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(킬로파스칼),
						'other' => q({0}킬로파스칼),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(킬로파스칼),
						'other' => q({0}킬로파스칼),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(메가파스칼),
						'other' => q({0}메가파스칼),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(메가파스칼),
						'other' => q({0}메가파스칼),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(밀리바),
						'other' => q({0}밀리바),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(밀리바),
						'other' => q({0}밀리바),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(수은주밀리미터),
						'other' => q({0}수은주밀리미터),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(수은주밀리미터),
						'other' => q({0}수은주밀리미터),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(파스칼),
						'other' => q({0}파스칼),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(파스칼),
						'other' => q({0}파스칼),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(제곱인치당 파운드),
						'other' => q({0}제곱인치당 파운드),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(제곱인치당 파운드),
						'other' => q({0}제곱인치당 파운드),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(시간당 킬로미터),
						'other' => q(시속 {0}킬로미터),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(시간당 킬로미터),
						'other' => q(시속 {0}킬로미터),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(노트),
						'other' => q({0}노트),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(노트),
						'other' => q({0}노트),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(미터 매 초),
						'other' => q(초속 {0}미터),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(미터 매 초),
						'other' => q(초속 {0}미터),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(시간당 마일),
						'other' => q(시속 {0}마일),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(시간당 마일),
						'other' => q(시속 {0}마일),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(섭씨),
						'other' => q(섭씨 {0}도),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(섭씨),
						'other' => q(섭씨 {0}도),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(화씨),
						'other' => q(화씨 {0}도),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(화씨),
						'other' => q(화씨 {0}도),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(도),
						'other' => q({0}도),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(도),
						'other' => q({0}도),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(켈빈),
						'other' => q({0}켈빈),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(켈빈),
						'other' => q({0}켈빈),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(뉴턴미터),
						'other' => q({0}뉴턴미터),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(뉴턴미터),
						'other' => q({0}뉴턴미터),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(에이커 피트),
						'other' => q({0}에이커 피트),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(에이커 피트),
						'other' => q({0}에이커 피트),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(배럴),
						'other' => q({0}배럴),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(배럴),
						'other' => q({0}배럴),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(부셸),
						'other' => q({0}부셸),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(부셸),
						'other' => q({0}부셸),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(센티리터),
						'other' => q({0}센티리터),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(센티리터),
						'other' => q({0}센티리터),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(세제곱센티미터),
						'other' => q({0}세제곱센티미터),
						'per' => q(세제곱센티미터당 {0}),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(세제곱센티미터),
						'other' => q({0}세제곱센티미터),
						'per' => q(세제곱센티미터당 {0}),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(세제곱피트),
						'other' => q({0}세제곱피트),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(세제곱피트),
						'other' => q({0}세제곱피트),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(세제곱인치),
						'other' => q({0}세제곱인치),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(세제곱인치),
						'other' => q({0}세제곱인치),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(세제곱킬로미터),
						'other' => q({0}세제곱킬로미터),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(세제곱킬로미터),
						'other' => q({0}세제곱킬로미터),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(세제곱미터),
						'other' => q({0}세제곱미터),
						'per' => q(세제곱미터당 {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(세제곱미터),
						'other' => q({0}세제곱미터),
						'per' => q(세제곱미터당 {0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(세제곱마일),
						'other' => q({0}세제곱마일),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(세제곱마일),
						'other' => q({0}세제곱마일),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(세제곱야드),
						'other' => q({0}세제곱야드),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(세제곱야드),
						'other' => q({0}세제곱야드),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(컵),
						'other' => q({0}컵),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(컵),
						'other' => q({0}컵),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(미터식 컵),
						'other' => q({0}미터식 컵),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(미터식 컵),
						'other' => q({0}미터식 컵),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(데시리터),
						'other' => q({0}데시리터),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(데시리터),
						'other' => q({0}데시리터),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(디저트스푼),
						'other' => q({0}디저트스푼),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(디저트스푼),
						'other' => q({0}디저트스푼),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(영국 디저트스푼),
						'other' => q({0}영국 디저트스푼),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(영국 디저트스푼),
						'other' => q({0}영국 디저트스푼),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(영국 액량 드램),
						'other' => q({0}영국 액량 드램),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(영국 액량 드램),
						'other' => q({0}영국 액량 드램),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(방울),
						'other' => q({0}방울),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(방울),
						'other' => q({0}방울),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(액량 온스),
						'other' => q({0}액량 온스),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(액량 온스),
						'other' => q({0}액량 온스),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(영국 액량 온스),
						'other' => q({0}영국 액량 온스),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(영국 액량 온스),
						'other' => q({0}영국 액량 온스),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(갤런),
						'other' => q({0}갤런),
						'per' => q(갤런당 {0}),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(갤런),
						'other' => q({0}갤런),
						'per' => q(갤런당 {0}),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(영국식 갤런),
						'other' => q({0}영국식 갤런),
						'per' => q(영국식 갤런당 {0}),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(영국식 갤런),
						'other' => q({0}영국식 갤런),
						'per' => q(영국식 갤런당 {0}),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(헥토리터),
						'other' => q({0}헥토리터),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(헥토리터),
						'other' => q({0}헥토리터),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(지거),
						'other' => q({0}지거),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(지거),
						'other' => q({0}지거),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(리터),
						'other' => q({0}리터),
						'per' => q(리터당 {0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(리터),
						'other' => q({0}리터),
						'per' => q(리터당 {0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(메가리터),
						'other' => q({0}메가리터),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(메가리터),
						'other' => q({0}메가리터),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(밀리리터),
						'other' => q({0}밀리리터),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(밀리리터),
						'other' => q({0}밀리리터),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(꼬집),
						'other' => q({0}꼬집),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(꼬집),
						'other' => q({0}꼬집),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(파인트),
						'other' => q({0}파인트),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(파인트),
						'other' => q({0}파인트),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(미터식 파인트),
						'other' => q({0}미터식 파인트),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(미터식 파인트),
						'other' => q({0}미터식 파인트),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(쿼트),
						'other' => q({0}쿼트),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(쿼트),
						'other' => q({0}쿼트),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(영국 쿼트),
						'other' => q({0}영국 쿼트),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(영국 쿼트),
						'other' => q({0}영국 쿼트),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(테이블스푼),
						'other' => q({0}테이블스푼),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(테이블스푼),
						'other' => q({0}테이블스푼),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(티스푼),
						'other' => q({0}티스푼),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(티스푼),
						'other' => q({0}티스푼),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(쪽),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(쪽),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-force),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(C),
						'other' => q({0}C),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(C),
						'other' => q({0}C),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q({0}/일),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q({0}/일),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q({0}/시간),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q({0}/시간),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q({0}/분),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q({0}/분),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q({0}/월),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q({0}/월),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q({0}/초),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q({0}/초),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q({0}/주),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q({0}/주),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q({0}/년),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q({0}/년),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'other' => q({0}′),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'other' => q({0}′),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(CD),
						'other' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(CD),
						'other' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn),
						'other' => q({0}tn),
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
					'power-horsepower' => {
						'other' => q({0}HP),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0}HP),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'other' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0}mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ℓ),
						'other' => q({0}ℓ),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ℓ),
						'other' => q({0}ℓ),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(쪽),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(쪽),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-force),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-force),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'other' => q({0}rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(두남),
						'other' => q({0}두남),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(두남),
						'other' => q({0}두남),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'other' => q({0}in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'other' => q({0}in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'other' => q({0}km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'other' => q({0}m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(항목),
						'other' => q({0}개 항목),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(항목),
						'other' => q({0}개 항목),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'other' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'other' => q({0}mpg Imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Imp.),
						'other' => q({0}mpg Imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'other' => q({0}byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'other' => q({0}byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(C),
						'other' => q({0}C),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(C),
						'other' => q({0}C),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q({0}/일),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(일),
						'other' => q({0}일),
						'per' => q({0}/일),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dec),
						'other' => q({0}dec),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dec),
						'other' => q({0}dec),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(시간),
						'other' => q({0}시간),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(밀리초),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(밀리초),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(분),
						'other' => q({0}분),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q({0}/월),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(개월),
						'other' => q({0}개월),
						'per' => q({0}/월),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(초),
						'other' => q({0}초),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q({0}/주),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(주),
						'other' => q({0}주),
						'per' => q({0}/주),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q({0}/년),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(년),
						'other' => q({0}년),
						'per' => q({0}/년),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amp),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amp),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Btu),
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'other' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(줄),
						'other' => q({0}줄),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(줄),
						'other' => q({0}줄),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(미국 섬),
						'other' => q({0}섬),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(미국 섬),
						'other' => q({0}섬),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'other' => q({0}dot),
					},
					# Core Unit Identifier
					'dot' => {
						'other' => q({0}dot),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em),
						'other' => q({0}em),
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
					'graphics-pixel' => {
						'name' => q(px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'other' => q({0}px),
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
						'name' => q(ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'other' => q({0}in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'other' => q({0}in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(CD),
						'other' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(CD),
						'other' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'other' => q({0}grain),
					},
					# Core Unit Identifier
					'grain' => {
						'other' => q({0}grain),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(그램),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(그램),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'other' => q({0}lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tn),
						'other' => q({0}tn),
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
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(w),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(w),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar),
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar),
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'other' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mbar),
						'other' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbar),
						'other' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'other' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bu),
						'other' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cL),
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'other' => q({0}m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'other' => q({0}m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(컵),
						'other' => q({0}컵),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(컵),
						'other' => q({0}컵),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mcup),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mcup),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dL),
						'other' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dL),
						'other' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'other' => q({0}dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'other' => q({0}dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0}dstspn Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0}dstspn Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'other' => q({0}dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'other' => q({0}dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'other' => q({0}drop),
					},
					# Core Unit Identifier
					'drop' => {
						'other' => q({0}drop),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'other' => q({0}fl oz Imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. fl oz),
						'other' => q({0}fl oz Imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0}gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp. gal),
						'other' => q({0}gal Imp.),
						'per' => q({0}/gal Imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'other' => q({0}jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'other' => q({0}jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(리터),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(리터),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mL),
						'other' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mL),
						'other' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'other' => q({0}pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'other' => q({0}pinch),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0}qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0}qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tsp),
						'other' => q({0}tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:예|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:아니요|no|n)$' }
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
	default		=> 1,
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'minusSign' => q(‏-),
			'plusSign' => q(‏+),
		},
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
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
					'other' => '0천',
				},
				'10000' => {
					'other' => '0만',
				},
				'100000' => {
					'other' => '00만',
				},
				'1000000' => {
					'other' => '000만',
				},
				'10000000' => {
					'other' => '0000만',
				},
				'100000000' => {
					'other' => '0억',
				},
				'1000000000' => {
					'other' => '00억',
				},
				'10000000000' => {
					'other' => '000억',
				},
				'100000000000' => {
					'other' => '0000억',
				},
				'1000000000000' => {
					'other' => '0조',
				},
				'10000000000000' => {
					'other' => '00조',
				},
				'100000000000000' => {
					'other' => '000조',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0천',
				},
				'10000' => {
					'other' => '0만',
				},
				'100000' => {
					'other' => '00만',
				},
				'1000000' => {
					'other' => '000만',
				},
				'10000000' => {
					'other' => '0000만',
				},
				'100000000' => {
					'other' => '0억',
				},
				'1000000000' => {
					'other' => '00억',
				},
				'10000000000' => {
					'other' => '000억',
				},
				'100000000000' => {
					'other' => '0000억',
				},
				'1000000000000' => {
					'other' => '0조',
				},
				'10000000000000' => {
					'other' => '00조',
				},
				'100000000000000' => {
					'other' => '000조',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0천',
				},
				'10000' => {
					'other' => '0만',
				},
				'100000' => {
					'other' => '00만',
				},
				'1000000' => {
					'other' => '000만',
				},
				'10000000' => {
					'other' => '0000만',
				},
				'100000000' => {
					'other' => '0억',
				},
				'1000000000' => {
					'other' => '00억',
				},
				'10000000000' => {
					'other' => '000억',
				},
				'100000000000' => {
					'other' => '0000억',
				},
				'1000000000000' => {
					'other' => '0조',
				},
				'10000000000000' => {
					'other' => '00조',
				},
				'100000000000000' => {
					'other' => '000조',
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
				'currency' => q(안도라 페세타),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(아랍에미리트 디르함),
				'other' => q(아랍에미리트 디르함),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(아프가니 \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(아프가니스탄 아프가니),
				'other' => q(아프가니스탄 아프가니),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(알바니아 레크),
				'other' => q(알바니아 레크),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(아르메니아 드람),
				'other' => q(아르메니아 드람),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(네덜란드령 안틸레스 길더),
				'other' => q(네덜란드령 안틸레스 길더),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(앙골라 콴자),
				'other' => q(앙골라 콴자),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(앙골라 콴자 \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(앙골라 신콴자 \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(앙골라 재조정 콴자 \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(아르헨티나 오스트랄),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(아르헨티나 페소 레이 \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(아르헨티나 페소 \(18810–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(아르헨티나 페소 \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(아르헨티나 페소),
				'other' => q(아르헨티나 페소),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(호주 실링),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(호주 달러),
				'other' => q(호주 달러),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(아루바 플로린),
				'other' => q(아루바 플로린),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(아제르바이젠 마나트\(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(아제르바이잔 마나트),
				'other' => q(아제르바이잔 마나트),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(보스니아-헤르체고비나 디나르),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(보스니아-헤르체고비나 태환 마르크),
				'other' => q(보스니아-헤르체고비나 태환 마르크),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(보스니아-헤르체고비나 신디나르 \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(바베이도스 달러),
				'other' => q(바베이도스 달러),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(방글라데시 타카),
				'other' => q(방글라데시 타카),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(벨기에 프랑 \(태환\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(벨기에 프랑),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(벨기에 프랑 \(금융\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(불가리아 동전 렛),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(불가리아 사회주의자 렛),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(불가리아 레프),
				'other' => q(불가리아 레프),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(불가리아 렛 \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(바레인 디나르),
				'other' => q(바레인 디나르),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(부룬디 프랑),
				'other' => q(부룬디 프랑),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(버뮤다 달러),
				'other' => q(버뮤다 달러),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(부루나이 달러),
				'other' => q(부루나이 달러),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(볼리비아노),
				'other' => q(볼리비아노),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(볼리비아 볼리비아노 \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(볼리비아노 페소),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(볼리비아노 Mvdol\(기금\)),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(볼리비아노 크루제이루 노보 \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(브라질 크루자두),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(브라질 크루제이루 \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(브라질 레알),
				'other' => q(브라질 레알),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(브라질 크루자두 노보),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(브라질 크루제이루),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(브라질 크루제이루 \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(바하마 달러),
				'other' => q(바하마 달러),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(부탄 눌투눔),
				'other' => q(부탄 눌투눔),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(버마 차트),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(보츠와나 폴라),
				'other' => q(보츠와나 폴라),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(벨라루스 신권 루블 \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(벨라루스 루블),
				'other' => q(벨라루스 루블),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(벨라루스 루블 \(2000–2016\)),
				'other' => q(벨라루스 루블 \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(벨리즈 달러),
				'other' => q(벨리즈 달러),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(캐나다 달러),
				'other' => q(캐나다 달러),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(콩고 프랑 콩골라스),
				'other' => q(콩고 프랑 콩골라스),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(유로 \(WIR\)),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(스위스 프랑),
				'other' => q(스위스 프랑),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(프랑 \(WIR\)),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(칠레 에스쿠도),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(칠레 \(UF\)),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(칠레 페소),
				'other' => q(칠레 페소),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(중국 위안화\(역외\)),
				'other' => q(중국 위안화\(역외\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(중국 위안화),
				'other' => q(중국 위안화),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(콜롬비아 페소),
				'other' => q(콜롬비아 페소),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(콜롬비아 실가 단위),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(코스타리카 콜론),
				'other' => q(코스타리카 콜론),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(고 세르비아 디나르),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(체코슬로바키아 동전 코루나),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(쿠바 태환 페소),
				'other' => q(쿠바 태환 페소),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(쿠바 페소),
				'other' => q(쿠바 페소),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(카보베르데 에스쿠도),
				'other' => q(카보베르데 에스쿠도),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(싸이프러스 파운드),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(체코 공화국 코루나),
				'other' => q(체코 공화국 코루나),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(동독 오스트마르크),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(독일 마르크),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(지부티 프랑),
				'other' => q(지부티 프랑),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(덴마크 크로네),
				'other' => q(덴마크 크로네),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(도미니카 페소),
				'other' => q(도미니카 페소),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(알제리 디나르),
				'other' => q(알제리 디나르),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(에쿠아도르 수크레),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(에콰도르 \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(에스토니아 크룬),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(이집트 파운드),
				'other' => q(이집트 파운드),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(에리트리아 나크파),
				'other' => q(에리트리아 나크파),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(스페인 페세타\(예금\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(스페인 페세타\(변환 예금\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(스페인 페세타),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(에티오피아 비르),
				'other' => q(에티오피아 비르),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(유로),
				'other' => q(유로),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(핀란드 마르카),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(피지 달러),
				'other' => q(피지 달러),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(포클랜드제도 파운드),
				'other' => q(포클랜드제도 파운드),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(프랑스 프랑),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(영국 파운드),
				'other' => q(영국 파운드),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(그루지야 지폐 라리트),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(조지아 라리),
				'other' => q(조지아 라리),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(가나 시디 \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(가나 시디),
				'other' => q(가나 시디),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(지브롤터 파운드),
				'other' => q(지브롤터 파운드),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(감비아 달라시),
				'other' => q(감비아 달라시),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(기니 프랑),
				'other' => q(기니 프랑),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(기니 시리),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(적도 기니 에쿨 \(Ekwele\)),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(그리스 드라크마),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(과테말라 케트살),
				'other' => q(과테말라 케트살),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(포르투갈령 기니 에스쿠도),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(기네비쏘 페소),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(가이아나 달러),
				'other' => q(가이아나 달러),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(홍콩 달러),
				'other' => q(홍콩 달러),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(온두라스 렘피라),
				'other' => q(온두라스 렘피라),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(크로아티아 디나르),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(크로아티아 쿠나),
				'other' => q(크로아티아 쿠나),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(하이티 구르드),
				'other' => q(하이티 구르드),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(헝가리 포린트),
				'other' => q(헝가리 포린트),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(인도네시아 루피아),
				'other' => q(인도네시아 루피아),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(아일랜드 파운드),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(이스라엘 파운드),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(이스라엘 신권 세켈),
				'other' => q(이스라엘 신권 세켈),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(인도 루피),
				'other' => q(인도 루피),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(이라크 디나르),
				'other' => q(이라크 디나르),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(이란 리얄),
				'other' => q(이란 리얄),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(아이슬란드 크로나),
				'other' => q(아이슬란드 크로나),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(이탈리아 리라),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(자메이카 달러),
				'other' => q(자메이카 달러),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(요르단 디나르),
				'other' => q(요르단 디나르),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(일본 엔화),
				'other' => q(일본 엔화),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(케냐 실링),
				'other' => q(케냐 실링),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(키르기스스탄 솜),
				'other' => q(키르기스스탄 솜),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(캄보디아 리얄),
				'other' => q(캄보디아 리얄),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(코모르 프랑),
				'other' => q(코모르 프랑),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(조선 민주주의 인민 공화국 원),
				'other' => q(조선 민주주의 인민 공화국 원),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(대한민국 환 \(1953–1962\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(대한민국 원),
				'other' => q(대한민국 원),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(쿠웨이트 디나르),
				'other' => q(쿠웨이트 디나르),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(케이맨 제도 달러),
				'other' => q(케이맨 제도 달러),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(카자흐스탄 텐게),
				'other' => q(카자흐스탄 텐게),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(라오스 키프),
				'other' => q(라오스 키프),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(레바논 파운드),
				'other' => q(레바논 파운드),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(스리랑카 루피),
				'other' => q(스리랑카 루피),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(라이베리아 달러),
				'other' => q(라이베리아 달러),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(레소토 로티),
				'other' => q(레소토 로티),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(리투아니아 리타),
				'other' => q(리투아니아 리타),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(룩셈부르크 타로나),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(룩셈부르크 변환 프랑),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(룩셈부르크 프랑),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(룩셈부르크 재정 프랑),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(라트비아 라트),
				'other' => q(라트비아 라트),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(라트비아 루블),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(리비아 디나르),
				'other' => q(리비아 디나르),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(모로코 디렘),
				'other' => q(모로코 디렘),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(모로코 프랑),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(모나코 프랑),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(몰도바 쿠폰),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(몰도바 레이),
				'other' => q(몰도바 레이),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(마다가스카르 아리아리),
				'other' => q(마다가스카르 아리아리),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(마다가스카르 프랑),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(마케도니아 디나르),
				'other' => q(마케도니아 디나르),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(말리 프랑),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(미얀마 키얏),
				'other' => q(미얀마 키얏),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(몽골 투그릭),
				'other' => q(몽골 투그릭),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(마카오 파타카),
				'other' => q(마카오 파타카),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(모리타니 우기야 \(1973–2017\)),
				'other' => q(모리타니 우기야 \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(모리타니 우기야),
				'other' => q(모리타니 우기야),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(몰타 리라),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(몰타 파운드),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(모리셔스 루피),
				'other' => q(모리셔스 루피),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(몰디브 제도 루피아),
				'other' => q(몰디브 제도 루피아),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(말라위 콰쳐),
				'other' => q(말라위 콰쳐),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(멕시코 페소),
				'other' => q(멕시코 페소),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(멕시코 실버 페소 \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(멕시코 \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(말레이시아 링깃),
				'other' => q(말레이시아 링깃),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(모잠비크 에스쿠도),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(고 모잠비크 메티칼),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(모잠비크 메티칼),
				'other' => q(모잠비크 메티칼),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(나미비아 달러),
				'other' => q(나미비아 달러),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(니제르 나이라),
				'other' => q(니제르 나이라),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(니카라과 코르도바),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(니카라과 코르도바 오로),
				'other' => q(니카라과 코르도바 오로),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(네델란드 길더),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(노르웨이 크로네),
				'other' => q(노르웨이 크로네),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(네팔 루피),
				'other' => q(네팔 루피),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(뉴질랜드 달러),
				'other' => q(뉴질랜드 달러),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(오만 리얄),
				'other' => q(오만 리얄),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(파나마 발보아),
				'other' => q(파나마 발보아),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(페루 인티),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(페루 솔),
				'other' => q(페루 솔),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(페루 솔 \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(파푸아뉴기니 키나),
				'other' => q(파푸아뉴기니 키나),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(필리핀 페소),
				'other' => q(필리핀 페소),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(파키스탄 루피),
				'other' => q(파키스탄 루피),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(폴란드 즐로티),
				'other' => q(폴란드 즐로티),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(폴란드 즐로티 \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(포르투갈 에스쿠도),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(파라과이 과라니),
				'other' => q(파라과이 과라니),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(카타르 리얄),
				'other' => q(카타르 리얄),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(로디지아 달러),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(루마니아 레이),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(루마니아 레우),
				'other' => q(루마니아 레우),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(세르비아 디나르),
				'other' => q(세르비아 디나르),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(러시아 루블),
				'other' => q(러시아 루블),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(러시아 루블 \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(르완다 프랑),
				'other' => q(르완다 프랑),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(사우디아라비아 리얄),
				'other' => q(사우디아라비아 리얄),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(솔로몬 제도 달러),
				'other' => q(솔로몬 제도 달러),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(세이셸 루피),
				'other' => q(세이셸 루피),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(수단 디나르),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(수단 파운드),
				'other' => q(수단 파운드),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(고 수단 파운드),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(스웨덴 크로나),
				'other' => q(스웨덴 크로나),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(싱가폴 달러),
				'other' => q(싱가폴 달러),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(세인트헬레나 파운드),
				'other' => q(세인트헬레나 파운드),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(슬로베니아 톨라르),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(슬로바키아 코루나),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(시에라리온 리온),
				'other' => q(시에라리온 리온),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(소말리아 실링),
				'other' => q(소말리아 실링),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(수리남 달러),
				'other' => q(수리남 달러),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(수리남 길더),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(남수단 파운드),
				'other' => q(남수단 파운드),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(상투메 프린시페 도브라 \(1977–2017\)),
				'other' => q(상투메 프린시페 도브라 \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(상투메 프린시페 도브라),
				'other' => q(상투메 프린시페 도브라),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(소련 루블),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(엘살바도르 콜론),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(시리아 파운드),
				'other' => q(시리아 파운드),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(스와질란드 릴랑게니),
				'other' => q(스와질란드 릴랑게니),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(태국 바트),
				'other' => q(태국 바트),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(타지키스탄 루블),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(타지키스탄 소모니),
				'other' => q(타지키스탄 소모니),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(투르크메니스탄 마나트 \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(투르크메니스탄 마나트),
				'other' => q(투르크메니스탄 마나트),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(튀니지 디나르),
				'other' => q(튀니지 디나르),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(통가 파앙가),
				'other' => q(통가 파앙가),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(티모르 에스쿠도),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(터키 리라),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(신 터키 리라),
				'other' => q(신 터키 리라),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(트리니다드 토바고 달러),
				'other' => q(트리니다드 토바고 달러),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(신 타이완 달러),
				'other' => q(신 타이완 달러),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(탄자니아 실링),
				'other' => q(탄자니아 실링),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(우크라이나 그리브나),
				'other' => q(우크라이나 그리브나),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(우크라이나 카보바네츠),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(우간다 실링 \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(우간다 실링),
				'other' => q(우간다 실링),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(미국 달러),
				'other' => q(미국 달러),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(미국 달러\(다음날\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(미국 달러\(당일\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(우루과이 페소 \(UI\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(우루과이 페소 \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(우루과이 페소 우루과요),
				'other' => q(우루과이 페소 우루과요),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(우즈베키스탄 숨),
				'other' => q(우즈베키스탄 숨),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(베네주엘라 볼리바르 \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(베네수엘라 볼리바르 \(2008–2018\)),
				'other' => q(베네수엘라 볼리바르 \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(베네수엘라 볼리바르),
				'other' => q(베네수엘라 볼리바르),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(베트남 동),
				'other' => q(베트남 동),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(베트남 동 \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(바누아투 바투),
				'other' => q(바누아투 바투),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(서 사모아 탈라),
				'other' => q(서 사모아 탈라),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(중앙아프리카 CFA 프랑),
				'other' => q(중앙아프리카 CFA 프랑),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(은화),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(금),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(유르코 \(유럽 회계 단위\)),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(유럽 통화 동맹),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(유럽 계산 단위 \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(유럽 계산 단위 \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(동카리브 달러),
				'other' => q(동카리브 달러),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(특별인출권),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(유럽 환율 단위),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(프랑스 프랑 \(Gold\)),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(프랑스 프랑 \(UIC\)),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(서아프리카 CFA 프랑),
				'other' => q(서아프리카 CFA 프랑),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(팔라듐),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP 프랑),
				'other' => q(CFP 프랑),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(백금),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET 기금),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(테스트 통화 코드),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(알 수 없는 통화 단위),
				'other' => q(\(알 수 없는 통화 단위\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(예멘 디나르),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(예멘 리알),
				'other' => q(예멘 리알),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(유고슬라비아 동전 디나르),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(유고슬라비아 노비 디나르),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(유고슬라비아 전환 디나르),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(남아프리카 랜드 \(금융\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(남아프리카 랜드),
				'other' => q(남아프리카 랜드),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(쟘비아 콰쳐 \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(잠비아 콰쳐),
				'other' => q(잠비아 콰쳐),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(자이르 신권 자이르),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(자이르 자이르),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(짐바브웨 달러),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(짐바브웨 달러 \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(짐바브웨 달러 \(2008\)),
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
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
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
				},
			},
			'coptic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'투트',
							'바바흐',
							'하투르',
							'키야흐크',
							'투바흐',
							'암쉬르',
							'바라마트',
							'바라문다흐',
							'바샨스',
							'바우나흐',
							'아비브',
							'미스라',
							'나시'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'투트',
							'바바흐',
							'하투르',
							'키야흐크',
							'투바흐',
							'암쉬르',
							'바라마트',
							'바라문다흐',
							'바샨스',
							'바우나흐',
							'아비브',
							'미스라',
							'나시'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'투트',
							'바바흐',
							'하투르',
							'키야흐크',
							'투바흐',
							'암쉬르',
							'바라마트',
							'바라문다흐',
							'바샨스',
							'바우나흐',
							'아비브',
							'미스라',
							'나시'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'투트',
							'바바흐',
							'하투르',
							'키야흐크',
							'투바흐',
							'암쉬르',
							'바라마트',
							'바라문다흐',
							'바샨스',
							'바우나흐',
							'아비브',
							'미스라',
							'나시'
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
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
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
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
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
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
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
							'매스캐램',
							'테켐트',
							'헤다르',
							'타흐사스',
							'테르',
							'얘카티트',
							'매가비트',
							'미야지야',
							'겐보트',
							'새네',
							'함레',
							'내하세',
							'파구맨'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'매스캐램',
							'테켐트',
							'헤다르',
							'타흐사스',
							'테르',
							'얘카티트',
							'매가비트',
							'미야지야',
							'겐보트',
							'새네',
							'함레',
							'내하세',
							'파구맨'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'매스캐램',
							'테켐트',
							'헤다르',
							'타흐사스',
							'테르',
							'얘카티트',
							'매가비트',
							'미야지야',
							'겐보트',
							'새네',
							'함레',
							'내하세',
							'파구맨'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'매스캐램',
							'테켐트',
							'헤다르',
							'타흐사스',
							'테르',
							'얘카티트',
							'매가비트',
							'미야지야',
							'겐보트',
							'새네',
							'함레',
							'내하세',
							'파구맨'
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
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1월',
							'2월',
							'3월',
							'4월',
							'5월',
							'6월',
							'7월',
							'8월',
							'9월',
							'10월',
							'11월',
							'12월'
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
							'디스리',
							'말케스',
							'기슬르',
							'데벳',
							'스밧',
							'아달 1',
							'아달',
							'닛산',
							'이야르',
							'시완',
							'담무르',
							'압',
							'엘룰'
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
							'디스리',
							'말케스',
							'기슬르',
							'데벳',
							'스밧',
							'아달 1',
							'아달',
							'닛산',
							'이야르',
							'시완',
							'담무르',
							'압',
							'엘룰'
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
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'디스리월',
							'말케스월',
							'기슬르월',
							'데벳월',
							'스밧월',
							'아달월 1',
							'아달월',
							'닛산월',
							'이야르월',
							'시완월',
							'담무르월',
							'압월',
							'엘룰월'
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
							'디스리월',
							'말케스월',
							'기슬르월',
							'데벳월',
							'스밧월',
							'아달월 1',
							'아달월',
							'닛산월',
							'이야르월',
							'시완월',
							'담무르월',
							'압월',
							'엘룰월'
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
			'islamic' => {
				'format' => {
					wide => {
						nonleap => [
							'무하람',
							'사파르',
							'라비 알 아왈',
							'라비 알 쎄니',
							'주마다 알 아왈',
							'주마다 알 쎄니',
							'라잡',
							'쉐아반',
							'라마단',
							'쉐왈',
							'듀 알 까다',
							'듀 알 히자'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'무하람',
							'사파르',
							'라비 알 아왈',
							'라비 알 쎄니',
							'주마다 알 아왈',
							'주마다 알 쎄니',
							'라잡',
							'쉐아반',
							'라마단',
							'쉐왈',
							'듀 알 까다',
							'듀 알 히자'
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
							'화르바딘',
							'오르디베헤쉬트',
							'호르다드',
							'티르',
							'모르다드',
							'샤흐리바르',
							'메흐르',
							'아반',
							'아자르',
							'다이',
							'바흐만',
							'에스판드'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'화르바딘',
							'오르디베헤쉬트',
							'호르다드',
							'티르',
							'모르다드',
							'샤흐리바르',
							'메흐르',
							'아반',
							'아자르',
							'다이',
							'바흐만',
							'에스판드'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'화르바딘',
							'오르디베헤쉬트',
							'호르다드',
							'티르',
							'모르다드',
							'샤흐리바르',
							'메흐르',
							'아반',
							'아자르',
							'다이',
							'바흐만',
							'에스판드'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'화르바딘',
							'오르디베헤쉬트',
							'호르다드',
							'티르',
							'모르다드',
							'샤흐리바르',
							'메흐르',
							'아반',
							'아자르',
							'다이',
							'바흐만',
							'에스판드'
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
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					narrow => {
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					short => {
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					wide => {
						mon => '월요일',
						tue => '화요일',
						wed => '수요일',
						thu => '목요일',
						fri => '금요일',
						sat => '토요일',
						sun => '일요일'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					narrow => {
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					short => {
						mon => '월',
						tue => '화',
						wed => '수',
						thu => '목',
						fri => '금',
						sat => '토',
						sun => '일'
					},
					wide => {
						mon => '월요일',
						tue => '화요일',
						wed => '수요일',
						thu => '목요일',
						fri => '금요일',
						sat => '토요일',
						sun => '일요일'
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
					abbreviated => {0 => '1분기',
						1 => '2분기',
						2 => '3분기',
						3 => '4분기'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '제 1/4분기',
						1 => '제 2/4분기',
						2 => '제 3/4분기',
						3 => '제 4/4분기'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1분기',
						1 => '2분기',
						2 => '3분기',
						3 => '4분기'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '제 1/4분기',
						1 => '제 2/4분기',
						2 => '제 3/4분기',
						3 => '제 4/4분기'
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2100;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100;
					return 'night1' if $time < 300;
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
					'afternoon1' => q{오후},
					'am' => q{AM},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{오후},
					'am' => q{AM},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{오후},
					'am' => q{오전},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{오후},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{오후},
					'am' => q{AM},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{오후},
					'am' => q{AM},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{오후},
					'am' => q{오전},
					'evening1' => q{저녁},
					'midnight' => q{자정},
					'morning1' => q{새벽},
					'morning2' => q{오전},
					'night1' => q{밤},
					'noon' => q{정오},
					'pm' => q{오후},
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
				'0' => '불기'
			},
			wide => {
				'0' => '불기'
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => '기원전',
				'1' => '서기'
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
				'0' => '유대력'
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
				'0' => '히즈라력'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => '다이카 (645 ~ 650)',
				'1' => '하쿠치 (650 ~ 671)',
				'2' => '하쿠호 (672 ~ 686)',
				'3' => '슈초 (686 ~ 701)',
				'4' => '다이호 (701 ~ 704)',
				'5' => '게이운 (704 ~ 708)',
				'6' => '와도 (708 ~ 715)',
				'7' => '레이키 (715 ~ 717)',
				'8' => '요로 (717 ~ 724)',
				'9' => '진키 (724 ~ 729)',
				'10' => '덴표 (729 ~ 749)',
				'11' => '덴표칸포 (749 ~ 749)',
				'12' => '덴표쇼호 (749 ~ 757)',
				'13' => '덴표호지 (757 ~ 765)',
				'14' => '덴표진고 (765 ~ 767)',
				'15' => '진고케이운 (767 ~ 770)',
				'16' => '호키 (770 ~ 780)',
				'17' => '덴오 (781 ~ 782)',
				'18' => '엔랴쿠 (782 ~ 806)',
				'19' => '다이도 (806 ~ 810)',
				'20' => '고닌 (810 ~ 824)',
				'21' => '덴초 (824 ~ 834)',
				'22' => '조와 (834 ~ 848)',
				'23' => '가쇼 (848 ~ 851)',
				'24' => '닌주 (851 ~ 854)',
				'25' => '사이코 (854 ~ 857)',
				'26' => '덴난 (857 ~ 859)',
				'27' => '조간 (859 ~ 877)',
				'28' => '간교 (877 ~ 885)',
				'29' => '닌나 (885 ~ 889)',
				'30' => '간표 (889 ~ 898)',
				'31' => '쇼타이 (898 ~ 901)',
				'32' => '엔기 (901 ~ 923)',
				'33' => '엔초 (923 ~ 931)',
				'34' => '조헤이 (931 ~ 938)',
				'35' => '덴교 (938 ~ 947)',
				'36' => '덴랴쿠 (947 ~ 957)',
				'37' => '덴토쿠 (957 ~ 961)',
				'38' => '오와 (961 ~ 964)',
				'39' => '고호 (964 ~ 968)',
				'40' => '안나 (968 ~ 970)',
				'41' => '덴로쿠 (970 ~ 973)',
				'42' => '덴엔 (973 ~ 976)',
				'43' => '조겐 (976 ~ 978)',
				'44' => '덴겐 (978 ~ 983)',
				'45' => '에이간 (983 ~ 985)',
				'46' => '간나 (985 ~ 987)',
				'47' => '에이엔 (987 ~ 989)',
				'48' => '에이소 (989 ~ 990)',
				'49' => '쇼랴쿠 (990 ~ 995)',
				'50' => '조토쿠 (995 ~ 999)',
				'51' => '조호 (999 ~ 1004)',
				'52' => '간코 (1004 ~ 1012)',
				'53' => '조와 (1012 ~ 1017)',
				'54' => '간닌 (1017 ~ 1021)',
				'55' => '지안 (1021 ~ 1024)',
				'56' => '만주 (1024 ~ 1028)',
				'57' => '조겐 (1028 ~ 1037)',
				'58' => '조랴쿠 (1037 ~ 1040)',
				'59' => '조큐 (1040 ~ 1044)',
				'60' => '간토쿠 (1044 ~ 1046)',
				'61' => '에이쇼 (1046 ~ 1053)',
				'62' => '덴기 (1053 ~ 1058)',
				'63' => '고헤이 (1058 ~ 1065)',
				'64' => '지랴쿠 (1065 ~ 1069)',
				'65' => '엔큐 (1069 ~ 1074)',
				'66' => '조호 (1074 ~ 1077)',
				'67' => '쇼랴쿠 (1077 ~ 1081)',
				'68' => '에이호 (1081 ~ 1084)',
				'69' => '오토쿠 (1084 ~ 1087)',
				'70' => '간지 (1087 ~ 1094)',
				'71' => '가호 (1094 ~ 1096)',
				'72' => '에이초 (1096 ~ 1097)',
				'73' => '조토쿠 (1097 ~ 1099)',
				'74' => '고와 (1099 ~ 1104)',
				'75' => '조지 (1104 ~ 1106)',
				'76' => '가쇼 (1106 ~ 1108)',
				'77' => '덴닌 (1108 ~ 1110)',
				'78' => '덴에이 (1110 ~ 1113)',
				'79' => '에이큐 (1113 ~ 1118)',
				'80' => '겐에이 (1118 ~ 1120)',
				'81' => '호안 (1120 ~ 1124)',
				'82' => '덴지 (1124 ~ 1126)',
				'83' => '다이지 (1126 ~ 1131)',
				'84' => '덴쇼 (1131 ~ 1132)',
				'85' => '조쇼 (1132 ~ 1135)',
				'86' => '호엔 (1135 ~ 1141)',
				'87' => '에이지 (1141 ~ 1142)',
				'88' => '고지 (1142 ~ 1144)',
				'89' => '덴요 (1144 ~ 1145)',
				'90' => '규안 (1145 ~ 1151)',
				'91' => '닌페이 (1151 ~ 1154)',
				'92' => '규주 (1154 ~ 1156)',
				'93' => '호겐 (1156 ~ 1159)',
				'94' => '헤이지 (1159 ~ 1160)',
				'95' => '에이랴쿠 (1160 ~ 1161)',
				'96' => '오호 (1161 ~ 1163)',
				'97' => '조칸 (1163 ~ 1165)',
				'98' => '에이만 (1165 ~ 1166)',
				'99' => '닌난 (1166 ~ 1169)',
				'100' => '가오 (1169 ~ 1171)',
				'101' => '조안 (1171 ~ 1175)',
				'102' => '안겐 (1175 ~ 1177)',
				'103' => '지쇼 (1177 ~ 1181)',
				'104' => '요와 (1181 ~ 1182)',
				'105' => '주에이 (1182 ~ 1184)',
				'106' => '겐랴쿠 (1184 ~ 1185)',
				'107' => '분지 (1185 ~ 1190)',
				'108' => '겐큐 (1190 ~ 1199)',
				'109' => '쇼지 (1199 ~ 1201)',
				'110' => '겐닌 (1201 ~ 1204)',
				'111' => '겐큐 (1204 ~ 1206)',
				'112' => '겐에이 (1206 ~ 1207)',
				'113' => '조겐 (1207 ~ 1211)',
				'114' => '겐랴쿠 (1211 ~ 1213)',
				'115' => '겐포 (1213 ~ 1219)',
				'116' => '조큐 (1219 ~ 1222)',
				'117' => '조오 (1222 ~ 1224)',
				'118' => '겐닌 (1224 ~ 1225)',
				'119' => '가로쿠 (1225 ~ 1227)',
				'120' => '안테이 (1227 ~ 1229)',
				'121' => '간키 (1229 ~ 1232)',
				'122' => '조에이 (1232 ~ 1233)',
				'123' => '덴푸쿠 (1233 ~ 1234)',
				'124' => '분랴쿠 (1234 ~ 1235)',
				'125' => '가테이 (1235 ~ 1238)',
				'126' => '랴쿠닌 (1238 ~ 1239)',
				'127' => '엔오 (1239 ~ 1240)',
				'128' => '닌지 (1240 ~ 1243)',
				'129' => '간겐 (1243 ~ 1247)',
				'130' => '호지 (1247 ~ 1249)',
				'131' => '겐초 (1249 ~ 1256)',
				'132' => '고겐 (1256 ~ 1257)',
				'133' => '쇼카 (1257 ~ 1259)',
				'134' => '쇼겐 (1259 ~ 1260)',
				'135' => '분오 (1260 ~ 1261)',
				'136' => '고초 (1261 ~ 1264)',
				'137' => '분에이 (1264 ~ 1275)',
				'138' => '겐지 (1275 ~ 1278)',
				'139' => '고안 (1278 ~ 1288)',
				'140' => '쇼오 (1288 ~ 1293)',
				'141' => '에이닌 (1293 ~ 1299)',
				'142' => '쇼안 (1299 ~ 1302)',
				'143' => '겐겐 (1302 ~ 1303)',
				'144' => '가겐 (1303 ~ 1306)',
				'145' => '도쿠지 (1306 ~ 1308)',
				'146' => '엔쿄 (1308 ~ 1311)',
				'147' => '오초 (1311 ~ 1312)',
				'148' => '쇼와 (1312 ~ 1317)',
				'149' => '분포 (1317 ~ 1319)',
				'150' => '겐오 (1319 ~ 1321)',
				'151' => '겐코 (1321 ~ 1324)',
				'152' => '쇼추 (1324 ~ 1326)',
				'153' => '가랴쿠 (1326 ~ 1329)',
				'154' => '겐토쿠 (1329 ~ 1331)',
				'155' => '겐코 (1331 ~ 1334)',
				'156' => '겐무 (1334 ~ 1336)',
				'157' => '엔겐 (1336 ~ 1340)',
				'158' => '고코쿠 (1340 ~ 1346)',
				'159' => '쇼헤이 (1346 ~ 1370)',
				'160' => '겐토쿠 (1370 ~ 1372)',
				'161' => '분추 (1372 ~ 1375)',
				'162' => '덴주 (1375 ~ 1379)',
				'163' => '고랴쿠 (1379 ~ 1381)',
				'164' => '고와 (1381 ~ 1384)',
				'165' => '겐추 (1384 ~ 1392)',
				'166' => '메이토쿠 (1384 ~ 1387)',
				'167' => '가쿄 (1387 ~ 1389)',
				'168' => '고오 (1389 ~ 1390)',
				'169' => '메이토쿠 (1390 ~ 1394)',
				'170' => '오에이 (1394 ~ 1428)',
				'171' => '쇼초 (1428 ~ 1429)',
				'172' => '에이쿄 (1429 ~ 1441)',
				'173' => '가키쓰 (1441 ~ 1444)',
				'174' => '분안 (1444 ~ 1449)',
				'175' => '호토쿠 (1449 ~ 1452)',
				'176' => '교토쿠 (1452 ~ 1455)',
				'177' => '고쇼 (1455 ~ 1457)',
				'178' => '조로쿠 (1457 ~ 1460)',
				'179' => '간쇼 (1460 ~ 1466)',
				'180' => '분쇼 (1466 ~ 1467)',
				'181' => '오닌 (1467 ~ 1469)',
				'182' => '분메이 (1469 ~ 1487)',
				'183' => '조쿄 (1487 ~ 1489)',
				'184' => '엔토쿠 (1489 ~ 1492)',
				'185' => '메이오 (1492 ~ 1501)',
				'186' => '분키 (1501 ~ 1504)',
				'187' => '에이쇼 (1504 ~ 1521)',
				'188' => '다이에이 (1521 ~ 1528)',
				'189' => '교로쿠 (1528 ~ 1532)',
				'190' => '덴분 (1532 ~ 1555)',
				'191' => '고지 (1555 ~ 1558)',
				'192' => '에이로쿠 (1558 ~ 1570)',
				'193' => '겐키 (1570 ~ 1573)',
				'194' => '덴쇼 (1573 ~ 1592)',
				'195' => '분로쿠 (1592 ~ 1596)',
				'196' => '게이초 (1596 ~ 1615)',
				'197' => '겐나 (1615 ~ 1624)',
				'198' => '간에이 (1624 ~ 1644)',
				'199' => '쇼호 (1644 ~ 1648)',
				'200' => '게이안 (1648 ~ 1652)',
				'201' => '조오 (1652 ~ 1655)',
				'202' => '메이레키 (1655 ~ 1658)',
				'203' => '만지 (1658 ~ 1661)',
				'204' => '간분 (1661 ~ 1673)',
				'205' => '엔포 (1673 ~ 1681)',
				'206' => '덴나 (1681 ~ 1684)',
				'207' => '조쿄 (1684 ~ 1688)',
				'208' => '겐로쿠 (1688 ~ 1704)',
				'209' => '호에이 (1704 ~ 1711)',
				'210' => '쇼토쿠 (1711 ~ 1716)',
				'211' => '교호 (1716 ~ 1736)',
				'212' => '겐분 (1736 ~ 1741)',
				'213' => '간포 (1741 ~ 1744)',
				'214' => '엔쿄 (1744 ~ 1748)',
				'215' => '간엔 (1748 ~ 1751)',
				'216' => '호레키 (1751 ~ 1764)',
				'217' => '메이와 (1764 ~ 1772)',
				'218' => '안에이 (1772 ~ 1781)',
				'219' => '덴메이 (1781 ~ 1789)',
				'220' => '간세이 (1789 ~ 1801)',
				'221' => '교와 (1801 ~ 1804)',
				'222' => '분카 (1804 ~ 1818)',
				'223' => '분세이 (1818 ~ 1830)',
				'224' => '덴포 (1830 ~ 1844)',
				'225' => '고카 (1844 ~ 1848)',
				'226' => '가에이 (1848 ~ 1854)',
				'227' => '안세이 (1854 ~ 1860)',
				'228' => '만엔 (1860 ~ 1861)',
				'229' => '분큐 (1861 ~ 1864)',
				'230' => '겐지 (1864 ~ 1865)',
				'231' => '게이오 (1865 ~ 1868)',
				'232' => '메이지',
				'233' => '다이쇼',
				'234' => '쇼와',
				'235' => '헤이세이',
				'236' => '레이와'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => '중화민국전',
				'1' => '중화민국'
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
			'full' => q{U년 MMM d일 EEEE},
			'long' => q{U년 MMM d일},
			'medium' => q{y. M. d.},
			'short' => q{y. M. d.},
		},
		'coptic' => {
		},
		'dangi' => {
			'full' => q{U년 MMM d일 EEEE},
			'long' => q{U년 MMM d일},
			'medium' => q{y. M. d.},
			'short' => q{y. M. d.},
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{G y년 M월 d일 EEEE},
			'long' => q{G y년 M월 d일},
			'medium' => q{G y. M. d.},
			'short' => q{G y. M. d.},
		},
		'gregorian' => {
			'full' => q{y년 M월 d일 EEEE},
			'long' => q{y년 M월 d일},
			'medium' => q{y. M. d.},
			'short' => q{yy. M. d.},
		},
		'hebrew' => {
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
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{a h시 m분 s초 zzzz},
			'long' => q{a h시 m분 s초 z},
			'medium' => q{a h:mm:ss},
			'short' => q{a h:mm},
		},
		'hebrew' => {
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
			GyMMM => q{G y년 MMM},
			GyMMMEEEEd => q{G y년 MMM d일 EEEE},
			GyMMMEd => q{G y년 MMM d일 (E)},
			GyMMMd => q{G y년 MMM d일},
			MMMEEEEd => q{MMM d일 EEEE},
			MMMEd => q{MMM d일 (E)},
			MMMMd => q{MMMM d일},
			MMMd => q{MMM d일},
			yyyyMMM => q{G y년 MMM},
			yyyyMMMEEEEd => q{G y년 MMM d일 EEEE},
			yyyyMMMEd => q{G y년 MMM d일 (E)},
			yyyyMMMM => q{G y년 MMMM},
			yyyyMMMd => q{G y년 MMM d일},
		},
		'chinese' => {
			Bh => q{B h시},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			EEEEd => q{d일 EEEE},
			Ed => q{d일 (E)},
			Gy => q{r년(U년)},
			GyMMM => q{r년(U년) MMM},
			GyMMMEEEEd => q{r년(U년) MMM d일 EEEE},
			GyMMMEd => q{r년(U년) MMM d일 (E)},
			GyMMMM => q{r년(U년) MMMM},
			GyMMMMEd => q{r년(U년) MMMM d일 (E)},
			GyMMMMd => q{r년(U년) MMMM d일},
			GyMMMd => q{r년 MMM d일},
			H => q{H시},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{MMM},
			MEEEEd => q{M. d. EEEE},
			MEd => q{M. d. (E)},
			MMM => q{LLL},
			MMMEEEEd => q{MMM d일 EEEE},
			MMMEd => q{MMM d일 (E)},
			MMMMd => q{MMMM d일},
			MMMd => q{MMM d일},
			Md => q{M. d.},
			UM => q{U년 MMM},
			UMMM => q{U년 MMM},
			UMMMd => q{U년 MMM d일},
			UMd => q{U년 M. d.},
			d => q{d일},
			h => q{a h시},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			ms => q{mm:ss},
			y => q{r년(U년)},
			yMd => q{r. M. d.},
			yyyy => q{r년(U년)},
			yyyyM => q{r. M.},
			yyyyMEEEEd => q{r. M. d. EEEE},
			yyyyMEd => q{r. M. d. (E)},
			yyyyMMM => q{r년(U년) MMM},
			yyyyMMMEEEEd => q{r년(U년) MMM d일 EEEE},
			yyyyMMMEd => q{r년(U년) MMM d일 (E)},
			yyyyMMMM => q{r년(U년) MMMM},
			yyyyMMMMEd => q{r년(U년) MMMM d일(E)},
			yyyyMMMMd => q{r년(U년) MMMM d일},
			yyyyMMMd => q{r년 MMM d일},
			yyyyMd => q{r. M. d.},
			yyyyQQQ => q{r년(U년) QQQ},
			yyyyQQQQ => q{r년(U년) QQQQ},
		},
		'generic' => {
			Bh => q{B h시},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			EEEEd => q{d일 EEEE},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d일 (E)},
			Ehm => q{E a h:mm},
			Ehms => q{E a h:mm:ss},
			Gy => q{G y년},
			GyMMM => q{G y년 M월},
			GyMMMEEEEd => q{G y년 M월 d일 EEEE},
			GyMMMEd => q{G y년 M월 d일 (E)},
			GyMMMd => q{G y년 M월 d일},
			GyMd => q{GGGGG y/M/d},
			H => q{H시},
			HHmmss => q{HH:mm:ss},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{M월},
			MEEEEd => q{M. d. EEEE},
			MEd => q{M. d. (E)},
			MMM => q{LLL},
			MMMEEEEd => q{M월 d일 EEEE},
			MMMEd => q{M월 d일 (E)},
			MMMMd => q{M월 d일},
			MMMd => q{M월 d일},
			Md => q{M. d.},
			d => q{d일},
			h => q{a h시},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			ms => q{mm:ss},
			y => q{G y년},
			yyyy => q{G y년},
			yyyyM => q{G y. M.},
			yyyyMEEEEd => q{G y. M. d. EEEE},
			yyyyMEd => q{G y. M. d. (E)},
			yyyyMMM => q{G y년 M월},
			yyyyMMMEEEEd => q{G y년 M월 d일 EEEE},
			yyyyMMMEd => q{G y년 M월 d일 (E)},
			yyyyMMMM => q{G y년 M월},
			yyyyMMMd => q{G y년 M월 d일},
			yyyyMd => q{G y. M. d.},
			yyyyQQQ => q{G y년 QQQ},
			yyyyQQQQ => q{G y년 QQQQ},
		},
		'gregorian' => {
			Bh => q{B h시},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{(E) B h:mm},
			EBhms => q{(E) B h:mm:ss},
			EEEEd => q{d일 EEEE},
			EHm => q{(E) HH:mm},
			EHms => q{(E) HH:mm:ss},
			Ed => q{d일 (E)},
			Ehm => q{(E) a h:mm},
			Ehms => q{(E) a h:mm:ss},
			Gy => q{G y년},
			GyMMM => q{G y년 MMM},
			GyMMMEEEEd => q{G y년 MMM d일 EEEE},
			GyMMMEd => q{G y년 MMM d일 (E)},
			GyMMMd => q{G y년 MMM d일},
			GyMd => q{GGGGG y/M/d},
			H => q{H시},
			HHmmss => q{HH:mm:ss},
			Hm => q{HH:mm},
			Hms => q{H시 m분 s초},
			Hmsv => q{H시 m분 s초 v},
			Hmv => q{HH:mm v},
			M => q{M월},
			MEEEEd => q{M. d. EEEE},
			MEd => q{M. d. (E)},
			MMM => q{LLL},
			MMMEEEEd => q{MMM d일 EEEE},
			MMMEd => q{MMM d일 (E)},
			MMMMW => q{MMMM W번째 주},
			MMMMd => q{MMMM d일},
			MMMd => q{MMM d일},
			Md => q{M. d.},
			d => q{d일},
			h => q{a h시},
			hm => q{a h:mm},
			hms => q{a h:mm:ss},
			hmsv => q{a h:mm:ss v},
			hmv => q{a h:mm v},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y년},
			yM => q{y. M.},
			yMEEEEd => q{y. M. d. EEEE},
			yMEd => q{y. M. d. (E)},
			yMM => q{y. M.},
			yMMM => q{y년 MMM},
			yMMMEEEEd => q{y년 MMM d일 EEEE},
			yMMMEd => q{y년 MMM d일 (E)},
			yMMMM => q{y년 MMMM},
			yMMMd => q{y년 MMM d일},
			yMd => q{y. M. d.},
			yQQQ => q{y년 QQQ},
			yQQQQ => q{y년 QQQQ},
			yw => q{Y년 w번째 주},
		},
		'islamic' => {
			MMMMd => q{MMMM d일},
			yyyyMMMM => q{G y년 MMMM},
		},
		'japanese' => {
			GyMMM => q{G y년 MMM},
			GyMMMEEEEd => q{G y년 MMM d일 EEEE},
			GyMMMEd => q{G y년 MMM d일 (E)},
			GyMMMd => q{G y년 MMM d일},
			MMMEEEEd => q{MMM d일 EEEE},
			MMMEd => q{MMM d일 (E)},
			MMMMd => q{MMMM d일},
			MMMd => q{MMM d일},
			yyyyMMM => q{G y년 MMM},
			yyyyMMMEEEEd => q{G y년 MMM d일 EEEE},
			yyyyMMMEd => q{G y년 MMM d일 (E)},
			yyyyMMMM => q{G y년 MMMM},
			yyyyMMMd => q{G y년 MMM d일},
		},
		'roc' => {
			GyMMM => q{G y년 MMM},
			GyMMMEEEEd => q{G y년 MMM d일 EEEE},
			GyMMMEd => q{G y년 MMM d일 (E)},
			GyMMMd => q{G y년 MMM d일},
			MMMEEEEd => q{MMM d일 EEEE},
			MMMEd => q{MMM d일 (E)},
			MMMMd => q{MMMM d일},
			MMMd => q{MMM d일},
			yyyyMMM => q{G y년 MMM},
			yyyyMMMEEEEd => q{G y년 MMM d일 EEEE},
			yyyyMMMEd => q{G y년 MMM d일 (E)},
			yyyyMMMM => q{G y년 MMMM},
			yyyyMMMd => q{G y년 MMM d일},
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
			Bh => {
				B => q{B h시 ~ B h시},
				h => q{B h시 ~ h시},
			},
			Bhm => {
				B => q{B h:mm ~ B h:mm},
				h => q{B h:mm ~ h:mm},
				m => q{B h:mm ~ h:mm},
			},
			Gy => {
				G => q{G y년 ~ G y년},
				y => q{G y년~y년},
			},
			GyM => {
				G => q{GGGGG y년 M월 ~ GGGGG y년 M월},
				M => q{GGGGG y년 M월 ~ y년 M월},
				y => q{GGGGG y년 M월 ~ y년 M월},
			},
			GyMEd => {
				G => q{GGGGG y년 M월 d일 E요일 ~ GGGGG y년 M월 d일 E요일},
				M => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
				d => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
				y => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
			},
			GyMMM => {
				G => q{G y년 M월 ~ G y년 M월},
				M => q{G y년 M월 ~ y년 M월},
				y => q{G y년 M월 ~ y년 M월},
			},
			GyMMMEd => {
				G => q{G y년 M월 d일 E요일 ~ G y년 M월 d일 E요일},
				M => q{G y년 M월 d일 E요일 ~ M월 d일 E요일},
				d => q{G y년 M월 d일 e요일 – M월 d일 e요일},
				y => q{G y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
			},
			GyMMMd => {
				G => q{G y년 M월 d일 ~ y년 M월 d일},
				M => q{G y년 M월 d일 ~ M월 d일},
				d => q{G y년 M월 d일 ~ d일},
				y => q{G y년 M월 d일 ~ y년 M월 d일},
			},
			GyMd => {
				G => q{GGGGG y년 M월 d일 ~ GGGGG y년 M월 d일},
				M => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
				d => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
				y => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
			},
			H => {
				H => q{HH ~ HH시},
			},
			Hm => {
				H => q{HH:mm ~ HH:mm},
				m => q{HH:mm ~ HH:mm},
			},
			Hmv => {
				H => q{HH:mm ~ HH:mm v},
				m => q{HH:mm ~ HH:mm v},
			},
			Hv => {
				H => q{HH ~ HH시 v},
			},
			M => {
				M => q{M월 ~ M월},
			},
			MEd => {
				M => q{M. d (E) ~ M. d (E)},
				d => q{M. d (E) ~ M. d (E)},
			},
			MMM => {
				M => q{M월 ~ M월},
			},
			MMMEEEEd => {
				M => q{M월 d일 EEEE ~ M월 d일 EEEE},
				d => q{M월 d일 EEEE ~ d일 EEEE},
			},
			MMMEd => {
				M => q{M월 d일 (E) ~ M월 d일 (E)},
				d => q{M월 d일 (E) ~ d일 (E)},
			},
			MMMM => {
				M => q{LLLL ~ LLLL},
			},
			MMMd => {
				M => q{M월 d일 ~ M월 d일},
				d => q{M월 d일 ~ d일},
			},
			Md => {
				M => q{M. d ~ M. d},
				d => q{M. d ~ M. d},
			},
			d => {
				d => q{d일 ~ d일},
			},
			fallback => '{0} ~ {1}',
			h => {
				a => q{a h시 ~ a h시},
				h => q{a h시 ~ h시},
			},
			hm => {
				a => q{a h:mm ~ a h:mm},
				h => q{a h:mm~h:mm},
				m => q{a h:mm~h:mm},
			},
			hmv => {
				a => q{a h:mm ~ a h:mm v},
				h => q{a h:mm~h:mm v},
				m => q{a h:mm~h:mm v},
			},
			hv => {
				a => q{a h시 ~ a h시(v)},
				h => q{a h시 ~ h시(v)},
			},
			y => {
				y => q{G y년 ~ y년},
			},
			yM => {
				M => q{G y. M ~ y. M},
				y => q{G y. M ~ y. M},
			},
			yMEd => {
				M => q{G y. M. d. (E) ~ y. M. d. (E)},
				d => q{G y. M. d. (E) ~ y. M. d. (E)},
				y => q{G y. M. d. (E) ~ y. M. d. (E)},
			},
			yMMM => {
				M => q{G y년 M월~M월},
				y => q{G y년 M월 ~ y년 M월},
			},
			yMMMEEEEd => {
				M => q{G y년 M월 d일 EEEE ~ M월 d일 EEEE},
				d => q{G y년 M월 d일 EEEE ~ d일 EEEE},
				y => q{G y년 M월 d일 EEEE ~ y년 M월 d일 EEEE},
			},
			yMMMEd => {
				M => q{G y년 M월 d일 (E) ~ M월 d일 (E)},
				d => q{G y년 M월 d일 (E) ~ d일 (E)},
				y => q{G y년 M월 d일 (E) ~ y년 M월 d일 (E)},
			},
			yMMMM => {
				M => q{G y년 MM월 ~ MM월},
				y => q{G y년 MM월 ~ y년 MM월},
			},
			yMMMd => {
				M => q{G y년 M월 d일 ~ M월 d일},
				d => q{G y년 M월 d일~d일},
				y => q{G y년 M월 d일 ~ y년 M월 d일},
			},
			yMd => {
				M => q{G y. M. d. ~ y. M. d.},
				d => q{G y. M. d. ~ y. M. d.},
				y => q{G y. M. d. ~ y. M. d.},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h시 ~ B h시},
				h => q{B h시~h시},
			},
			Bhm => {
				B => q{B h:mm~B h:mm},
				h => q{B h:mm ~ h:mm},
				m => q{B h:mm ~ h:mm},
			},
			Gy => {
				G => q{G y년 ~ G y년},
				y => q{G y년~y년},
			},
			GyM => {
				G => q{GGGGG y년 M월 ~ GGGGG y년 M월},
				M => q{GGGGG y년 M월 ~ GGGGG y년 M월},
				y => q{GGGGG y년 M월 ~ y년 M월},
			},
			GyMEd => {
				G => q{GGGGG y년 M월 d일 E요일 ~ GGGGG y년 M월 d일 E요일},
				M => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
				d => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
				y => q{GGGGG y년 M월 d일 E요일 ~ y년 M월 d일 E요일},
			},
			GyMMM => {
				G => q{G y년 MMM ~ G y년 MMM},
				M => q{G y년 MMM ~ MMM},
				y => q{G y년 MMM ~ y년 MMM},
			},
			GyMMMEd => {
				G => q{G y년 MMM d일 E요일 ~ G y년 MMM d일 E요일},
				M => q{G y년 MMM d일 E요일 ~ MMM d일 E요일},
				d => q{G y년 MMM d일 E요일 ~ MMM d일 E요일},
				y => q{G y년 MMM d일 E요일 ~ y년 MMM d일 E요일},
			},
			GyMMMd => {
				G => q{G y년 MMM d일 ~ G y년 MMM d일},
				M => q{G y년 MMM d일 ~ MMM d일},
				d => q{G y년 MMM d일 ~ d일},
				y => q{G y년 MMM d일 ~ y년 MMM d일},
			},
			GyMd => {
				G => q{GGGGG y년 M월 d일 ~ GGGGG y년 M월 d일},
				M => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
				d => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
				y => q{GGGGG y년 M월 d일 ~ y년 M월 d일},
			},
			H => {
				H => q{H ~ H시},
			},
			Hm => {
				H => q{HH:mm ~ HH:mm},
				m => q{HH:mm ~ HH:mm},
			},
			Hmv => {
				H => q{HH:mm ~ HH:mm v},
				m => q{HH:mm ~ HH:mm v},
			},
			Hv => {
				H => q{HH ~ HH시 v},
			},
			M => {
				M => q{M월~M월},
			},
			MEd => {
				M => q{M. d (E) ~ M. d (E)},
				d => q{M. d (E) ~ M. d (E)},
			},
			MMM => {
				M => q{MMM~MMM},
			},
			MMMEd => {
				M => q{M월 d일 (E) ~ M월 d일 (E)},
				d => q{M월 d일 (E) ~ d일 (E)},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{M월 d일 ~ M월 d일},
				d => q{MMM d일~d일},
			},
			Md => {
				M => q{M. d ~ M. d},
				d => q{M. d ~ M. d},
			},
			d => {
				d => q{d일~d일},
			},
			fallback => '{0} ~ {1}',
			h => {
				a => q{a h시 ~ a h시},
				h => q{a h시 ~ h시},
			},
			hm => {
				a => q{a h:mm ~ a h:mm},
				h => q{a h:mm~h:mm},
				m => q{a h:mm~h:mm},
			},
			hmv => {
				a => q{a h:mm ~ a h:mm v},
				h => q{a h:mm~h:mm v},
				m => q{a h:mm~h:mm v},
			},
			hv => {
				a => q{a h시 ~ a h시(v)},
				h => q{a h시 ~ h시(v)},
			},
			y => {
				y => q{y년 ~ y년},
			},
			yM => {
				M => q{y. M ~ y. M},
				y => q{y. M ~ y. M},
			},
			yMEd => {
				M => q{y. M. d. (E) ~ y. M. d. (E)},
				d => q{y. M. d. (E) ~ y. M. d. (E)},
				y => q{y. M. d. (E) ~ y. M. d. (E)},
			},
			yMMM => {
				M => q{y년 M월~M월},
				y => q{y년 M월 ~ y년 M월},
			},
			yMMMEEEEd => {
				M => q{y년 M월 d일 EEEE ~ M월 d일 EEEE},
				d => q{y년 M월 d일 EEEE ~ d일 EEEE},
				y => q{y년 M월 d일 EEEE ~ y년 M월 d일 EEEE},
			},
			yMMMEd => {
				M => q{y년 M월 d일 (E) ~ M월 d일 (E)},
				d => q{y년 M월 d일 (E) ~ d일 (E)},
				y => q{y년 M월 d일 (E) ~ y년 M월 d일 (E)},
			},
			yMMMM => {
				M => q{y년 MMMM ~ MMMM},
				y => q{y년 MMMM ~ y년 MMMM},
			},
			yMMMd => {
				M => q{y년 M월 d일 ~ M월 d일},
				d => q{y년 M월 d일~d일},
				y => q{y년 M월 d일 ~ y년 M월 d일},
			},
			yMd => {
				M => q{y. M. d. ~ y. M. d.},
				d => q{y. M. d. ~ y. M. d.},
				y => q{y. M. d. ~ y. M. d.},
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
					'leap' => q{윤{0}},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{윤{0}},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'leap' => q{윤{0}},
				},
			},
		},
		'dangi' => {
			'format' => {
				'wide' => {
					'leap' => q{윤{0}},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{윤{0}},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'leap' => q{윤{0}},
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
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
					'narrow' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
					'wide' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(입춘),
						1 => q(우수),
						2 => q(경칩),
						3 => q(춘분),
						4 => q(청명),
						5 => q(곡우),
						6 => q(입하),
						7 => q(소만),
						8 => q(망종),
						9 => q(하지),
						10 => q(소서),
						11 => q(대서),
						12 => q(입추),
						13 => q(처서),
						14 => q(백로),
						15 => q(추분),
						16 => q(한로),
						17 => q(상강),
						18 => q(입동),
						19 => q(소설),
						20 => q(대설),
						21 => q(동지),
						22 => q(소한),
						23 => q(대한),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(갑자),
						1 => q(을축),
						2 => q(병인),
						3 => q(정묘),
						4 => q(무진),
						5 => q(기사),
						6 => q(경오),
						7 => q(신미),
						8 => q(임신),
						9 => q(계유),
						10 => q(갑술),
						11 => q(을해),
						12 => q(병자),
						13 => q(정축),
						14 => q(무인),
						15 => q(기묘),
						16 => q(경진),
						17 => q(신사),
						18 => q(임오),
						19 => q(계미),
						20 => q(갑신),
						21 => q(을유),
						22 => q(병술),
						23 => q(정해),
						24 => q(무자),
						25 => q(기축),
						26 => q(경인),
						27 => q(신묘),
						28 => q(임진),
						29 => q(계사),
						30 => q(갑오),
						31 => q(을미),
						32 => q(병신),
						33 => q(정유),
						34 => q(무술),
						35 => q(기해),
						36 => q(경자),
						37 => q(신축),
						38 => q(임인),
						39 => q(계묘),
						40 => q(갑진),
						41 => q(을사),
						42 => q(병오),
						43 => q(정미),
						44 => q(무신),
						45 => q(기유),
						46 => q(경술),
						47 => q(신해),
						48 => q(임자),
						49 => q(계축),
						50 => q(갑인),
						51 => q(을묘),
						52 => q(병진),
						53 => q(정사),
						54 => q(무오),
						55 => q(기미),
						56 => q(경신),
						57 => q(신유),
						58 => q(임술),
						59 => q(계해),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(쥐),
						1 => q(소),
						2 => q(호랑이),
						3 => q(토끼),
						4 => q(용),
						5 => q(뱀),
						6 => q(말),
						7 => q(양),
						8 => q(원숭이),
						9 => q(닭),
						10 => q(개),
						11 => q(돼지),
					},
				},
			},
		},
		'dangi' => {
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
					'wide' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(입춘),
						1 => q(우수),
						2 => q(경칩),
						3 => q(춘분),
						4 => q(청명),
						5 => q(곡우),
						6 => q(입하),
						7 => q(소만),
						8 => q(망종),
						9 => q(하지),
						10 => q(소서),
						11 => q(대서),
						12 => q(입추),
						13 => q(처서),
						14 => q(백로),
						15 => q(추분),
						16 => q(한로),
						17 => q(상강),
						18 => q(입동),
						19 => q(소설),
						20 => q(대설),
						21 => q(동지),
						22 => q(소한),
						23 => q(대한),
					},
				},
			},
			'years' => {
				'format' => {
					'abbreviated' => {
						0 => q(갑자),
						1 => q(을축),
						2 => q(병인),
						3 => q(정묘),
						4 => q(무진),
						5 => q(기사),
						6 => q(경오),
						7 => q(신미),
						8 => q(임신),
						9 => q(계유),
						10 => q(갑술),
						11 => q(을해),
						12 => q(병자),
						13 => q(정축),
						14 => q(무인),
						15 => q(기묘),
						16 => q(경진),
						17 => q(신사),
						18 => q(임오),
						19 => q(계미),
						20 => q(갑신),
						21 => q(을유),
						22 => q(병술),
						23 => q(정해),
						24 => q(무자),
						25 => q(기축),
						26 => q(경인),
						27 => q(신묘),
						28 => q(임진),
						29 => q(계사),
						30 => q(갑오),
						31 => q(을미),
						32 => q(병신),
						33 => q(정유),
						34 => q(무술),
						35 => q(기해),
						36 => q(경자),
						37 => q(신축),
						38 => q(임인),
						39 => q(계묘),
						40 => q(갑진),
						41 => q(을사),
						42 => q(병오),
						43 => q(정미),
						44 => q(무신),
						45 => q(기유),
						46 => q(경술),
						47 => q(신해),
						48 => q(임자),
						49 => q(계축),
						50 => q(갑인),
						51 => q(을묘),
						52 => q(병진),
						53 => q(정사),
						54 => q(무오),
						55 => q(기미),
						56 => q(경신),
						57 => q(신유),
						58 => q(임술),
						59 => q(계해),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
					},
					'wide' => {
						0 => q(자),
						1 => q(축),
						2 => q(인),
						3 => q(묘),
						4 => q(진),
						5 => q(사),
						6 => q(오),
						7 => q(미),
						8 => q(신),
						9 => q(유),
						10 => q(술),
						11 => q(해),
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} 시간),
		regionFormat => q({0} 하계 표준시),
		regionFormat => q({0} 표준시),
		fallbackFormat => q({1}({0})),
		'Acre' => {
			long => {
				'daylight' => q#아크레 하계 표준시#,
				'generic' => q#아크레 시간#,
				'standard' => q#아크레 표준시#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#아프가니스탄 시간#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#아비장#,
		},
		'Africa/Accra' => {
			exemplarCity => q#아크라#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#아디스아바바#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#알제#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#아스메라#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#바마코#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#방기#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#반줄#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#비사우#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#블랜타이어#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#브라자빌#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#부줌부라#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#카이로#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#카사블랑카#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#세우타#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#코나크리#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#다카르#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#다르에스살람#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#지부티#,
		},
		'Africa/Douala' => {
			exemplarCity => q#두알라#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#엘아이운#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#프리타운#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#가보로네#,
		},
		'Africa/Harare' => {
			exemplarCity => q#하라레#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#요하네스버그#,
		},
		'Africa/Juba' => {
			exemplarCity => q#주바#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#캄팔라#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#카르툼#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#키갈리#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#킨샤사#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#라고스#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#리브르빌#,
		},
		'Africa/Lome' => {
			exemplarCity => q#로메#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#루안다#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#루붐바시#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#루사카#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#말라보#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#마푸토#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#마세루#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#음바바네#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#모가디슈#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#몬로비아#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#나이로비#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#엔자메나#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#니아메#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#누악쇼트#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#와가두구#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#포르토노보#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#상투메#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#트리폴리#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#튀니스#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#빈트후크#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#중앙아프리카 시간#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#동아프리카 시간#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#남아프리카 시간#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#서아프리카 하계 표준시#,
				'generic' => q#서아프리카 시간#,
				'standard' => q#서아프리카 표준시#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#알래스카 하계 표준시#,
				'generic' => q#알래스카 시간#,
				'standard' => q#알래스카 표준시#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#알마티 하계 표준시#,
				'generic' => q#알마티 표준 시간#,
				'standard' => q#알마티 표준 표준시#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#아마존 하계 표준시#,
				'generic' => q#아마존 시간#,
				'standard' => q#아마존 표준시#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#에이닥#,
		},
		'America/Anchorage' => {
			exemplarCity => q#앵커리지#,
		},
		'America/Anguilla' => {
			exemplarCity => q#앙귈라#,
		},
		'America/Antigua' => {
			exemplarCity => q#안티과#,
		},
		'America/Araguaina' => {
			exemplarCity => q#아라과이나#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#라 리오하#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#리오 가예고스#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#살타#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#산후안#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#산루이스#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#투쿠만#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#우수아이아#,
		},
		'America/Aruba' => {
			exemplarCity => q#아루바#,
		},
		'America/Asuncion' => {
			exemplarCity => q#아순시온#,
		},
		'America/Bahia' => {
			exemplarCity => q#바히아#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#바이아 반데라스#,
		},
		'America/Barbados' => {
			exemplarCity => q#바베이도스#,
		},
		'America/Belem' => {
			exemplarCity => q#벨렘#,
		},
		'America/Belize' => {
			exemplarCity => q#벨리즈#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#블랑 사블롱#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#보아 비스타#,
		},
		'America/Bogota' => {
			exemplarCity => q#보고타#,
		},
		'America/Boise' => {
			exemplarCity => q#보이시#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#부에노스 아이레스#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#케임브리지 베이#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#캄포 그란데#,
		},
		'America/Cancun' => {
			exemplarCity => q#칸쿤#,
		},
		'America/Caracas' => {
			exemplarCity => q#카라카스#,
		},
		'America/Catamarca' => {
			exemplarCity => q#카타마르카#,
		},
		'America/Cayenne' => {
			exemplarCity => q#카옌#,
		},
		'America/Cayman' => {
			exemplarCity => q#케이맨#,
		},
		'America/Chicago' => {
			exemplarCity => q#시카고#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#치와와#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#코랄하버#,
		},
		'America/Cordoba' => {
			exemplarCity => q#코르도바#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#코스타리카#,
		},
		'America/Creston' => {
			exemplarCity => q#크레스톤#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#쿠이아바#,
		},
		'America/Curacao' => {
			exemplarCity => q#퀴라소#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#덴마크샤븐#,
		},
		'America/Dawson' => {
			exemplarCity => q#도슨#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#도슨크릭#,
		},
		'America/Denver' => {
			exemplarCity => q#덴버#,
		},
		'America/Detroit' => {
			exemplarCity => q#디트로이트#,
		},
		'America/Dominica' => {
			exemplarCity => q#도미니카#,
		},
		'America/Edmonton' => {
			exemplarCity => q#에드먼턴#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#아이루네페#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#엘살바도르#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#포트 넬슨#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#포르탈레자#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#글라스베이#,
		},
		'America/Godthab' => {
			exemplarCity => q#고드호프#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#구즈베이#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#그랜드 터크#,
		},
		'America/Grenada' => {
			exemplarCity => q#그레나다#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#과들루프#,
		},
		'America/Guatemala' => {
			exemplarCity => q#과테말라#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#과야킬#,
		},
		'America/Guyana' => {
			exemplarCity => q#가이아나#,
		},
		'America/Halifax' => {
			exemplarCity => q#핼리팩스#,
		},
		'America/Havana' => {
			exemplarCity => q#하바나#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#에르모시요#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#인디애나주, 녹스#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#인디애나주, 머렝고#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#인디애나주, 피츠버그#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#인디애나주, 텔시티#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#인디애나주, 비비#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#인디애나주, 빈센스#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#인디애나주, 위너맥#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#인디애나폴리스#,
		},
		'America/Inuvik' => {
			exemplarCity => q#이누빅#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#이칼루이트#,
		},
		'America/Jamaica' => {
			exemplarCity => q#자메이카#,
		},
		'America/Jujuy' => {
			exemplarCity => q#후후이#,
		},
		'America/Juneau' => {
			exemplarCity => q#주노#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#켄터키주, 몬티첼로#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#크라렌디즈크#,
		},
		'America/La_Paz' => {
			exemplarCity => q#라파스#,
		},
		'America/Lima' => {
			exemplarCity => q#리마#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#로스앤젤레스#,
		},
		'America/Louisville' => {
			exemplarCity => q#루이빌#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#로워 프린스 쿼터#,
		},
		'America/Maceio' => {
			exemplarCity => q#마세이오#,
		},
		'America/Managua' => {
			exemplarCity => q#마나과#,
		},
		'America/Manaus' => {
			exemplarCity => q#마나우스#,
		},
		'America/Marigot' => {
			exemplarCity => q#마리곳#,
		},
		'America/Martinique' => {
			exemplarCity => q#마티니크#,
		},
		'America/Matamoros' => {
			exemplarCity => q#마타모로스#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#마사틀란#,
		},
		'America/Mendoza' => {
			exemplarCity => q#멘도사#,
		},
		'America/Menominee' => {
			exemplarCity => q#메노미니#,
		},
		'America/Merida' => {
			exemplarCity => q#메리다#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#메틀라카틀라#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#멕시코 시티#,
		},
		'America/Miquelon' => {
			exemplarCity => q#미클롱#,
		},
		'America/Moncton' => {
			exemplarCity => q#몽턴#,
		},
		'America/Monterrey' => {
			exemplarCity => q#몬테레이#,
		},
		'America/Montevideo' => {
			exemplarCity => q#몬테비데오#,
		},
		'America/Montserrat' => {
			exemplarCity => q#몬세라트#,
		},
		'America/Nassau' => {
			exemplarCity => q#나소#,
		},
		'America/New_York' => {
			exemplarCity => q#뉴욕#,
		},
		'America/Nipigon' => {
			exemplarCity => q#니피곤#,
		},
		'America/Nome' => {
			exemplarCity => q#놈#,
		},
		'America/Noronha' => {
			exemplarCity => q#노롱야#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#노스다코타주, 베라#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#중부, 노스다코타#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#노스다코타주, 뉴살렘#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#오히나가#,
		},
		'America/Panama' => {
			exemplarCity => q#파나마#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#팡니르퉁#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#파라마리보#,
		},
		'America/Phoenix' => {
			exemplarCity => q#피닉스#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#포르토프랭스#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#포트오브스페인#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#포르토벨료#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#푸에르토리코#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#푼타아레나스#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#레이니강#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#랭킹 인렛#,
		},
		'America/Recife' => {
			exemplarCity => q#레시페#,
		},
		'America/Regina' => {
			exemplarCity => q#리자이나#,
		},
		'America/Resolute' => {
			exemplarCity => q#리졸루트#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#히우 브랑쿠#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#산타 이사벨#,
		},
		'America/Santarem' => {
			exemplarCity => q#산타렘#,
		},
		'America/Santiago' => {
			exemplarCity => q#산티아고#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#산토도밍고#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#상파울루#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#스코레스바이선드#,
		},
		'America/Sitka' => {
			exemplarCity => q#싯카#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#생바르텔레미#,
		},
		'America/St_Johns' => {
			exemplarCity => q#세인트존스#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#세인트키츠#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#세인트루시아#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#세인트토마스#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#세인트빈센트#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#스위프트커런트#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#테구시갈파#,
		},
		'America/Thule' => {
			exemplarCity => q#툴레#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#선더베이#,
		},
		'America/Tijuana' => {
			exemplarCity => q#티후아나#,
		},
		'America/Toronto' => {
			exemplarCity => q#토론토#,
		},
		'America/Tortola' => {
			exemplarCity => q#토르톨라#,
		},
		'America/Vancouver' => {
			exemplarCity => q#벤쿠버#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#화이트호스#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#위니펙#,
		},
		'America/Yakutat' => {
			exemplarCity => q#야쿠타트#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#옐로나이프#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#미 중부 하계 표준시#,
				'generic' => q#미 중부 시간#,
				'standard' => q#미 중부 표준시#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#미 동부 하계 표준시#,
				'generic' => q#미 동부 시간#,
				'standard' => q#미 동부 표준시#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#미 산지 하계 표준시#,
				'generic' => q#미 산지 시간#,
				'standard' => q#미 산악 표준시#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#미 태평양 하계 표준시#,
				'generic' => q#미 태평양 시간#,
				'standard' => q#미 태평양 표준시#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#아나디리 하계 표준시#,
				'generic' => q#아나디리 시간#,
				'standard' => q#아나디리 표준시#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#케이시#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#데이비스#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#뒤몽 뒤르빌#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#맥쿼리#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#모슨#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#맥머도#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#파머#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#로데라#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#쇼와#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#트롤#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#보스토크#,
		},
		'Apia' => {
			long => {
				'daylight' => q#아피아 하계 표준시#,
				'generic' => q#아피아 시간#,
				'standard' => q#아피아 표준시#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#악타우 하계 표준시#,
				'generic' => q#악타우 표준 시간#,
				'standard' => q#악타우 표준 표준시#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#악퇴베 하계 표준시#,
				'generic' => q#악퇴베 표준 시간#,
				'standard' => q#악퇴베 표준 표준시#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#아라비아 하계 표준시#,
				'generic' => q#아라비아 시간#,
				'standard' => q#아라비아 표준시#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#롱이어비엔#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#아르헨티나 하계 표준시#,
				'generic' => q#아르헨티나 시간#,
				'standard' => q#아르헨티나 표준시#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#아르헨티나 서부 하계 표준시#,
				'generic' => q#아르헨티나 서부 시간#,
				'standard' => q#아르헨티나 서부 표준시#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#아르메니아 하계 표준시#,
				'generic' => q#아르메니아 시간#,
				'standard' => q#아르메니아 표준시#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#아덴#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#알마티#,
		},
		'Asia/Amman' => {
			exemplarCity => q#암만#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#아나디리#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#아크타우#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#악토브#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#아슈하바트#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#아티라우#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#바그다드#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#바레인#,
		},
		'Asia/Baku' => {
			exemplarCity => q#바쿠#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#방콕#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#바르나울#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#베이루트#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#비슈케크#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#브루나이#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#콜카타#,
		},
		'Asia/Chita' => {
			exemplarCity => q#치타#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#초이발산#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#콜롬보#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#다마스쿠스#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#다카#,
		},
		'Asia/Dili' => {
			exemplarCity => q#딜리#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#두바이#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#두샨베#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#파마구스타#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#가자#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#헤브론#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#홍콩#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#호브드#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#이르쿠츠크#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#자카르타#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#자야푸라#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#예루살렘#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#카불#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#캄차카#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#카라치#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#카트만두#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#한디가#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#크라스노야르스크#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#쿠알라룸푸르#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#쿠칭#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#쿠웨이트#,
		},
		'Asia/Macau' => {
			exemplarCity => q#마카오#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#마가단#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#마카사르#,
		},
		'Asia/Manila' => {
			exemplarCity => q#마닐라#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#무스카트#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#니코시아#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#노보쿠즈네츠크#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#노보시비르스크#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#옴스크#,
		},
		'Asia/Oral' => {
			exemplarCity => q#오랄#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#프놈펜#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#폰티아나크#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#평양#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#카타르#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#코스타나이#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#키질로르다#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#랑군#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#리야드#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#사이공#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#사할린#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#사마르칸트#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#서울#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#상하이#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#싱가포르#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#스레드네콜림스크#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#타이베이#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#타슈켄트#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#트빌리시#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#테헤란#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#팀부#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#도쿄#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#톰스크#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#울란바토르#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#우루무치#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#우스티네라#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#비엔티안#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#블라디보스토크#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#야쿠츠크#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#예카테린부르크#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#예레반#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#대서양 하계 표준시#,
				'generic' => q#대서양 시간#,
				'standard' => q#대서양 표준시#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#아조레스#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#버뮤다#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#카나리아 제도#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#카보 베르데#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#페로 제도#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#마데이라#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#레이캬비크#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#사우스조지아#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#세인트 헬레나#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#스탠리#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#애들레이드#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#브리스베인#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#브로컨힐#,
		},
		'Australia/Currie' => {
			exemplarCity => q#퀴리#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#다윈#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#유클라#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#호바트#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#린데만#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#로드 하우#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#멜버른#,
		},
		'Australia/Perth' => {
			exemplarCity => q#퍼스#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#시드니#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#오스트레일리아 중부 하계 표준시#,
				'generic' => q#오스트레일리아 중부 시간#,
				'standard' => q#오스트레일리아 중부 표준시#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#오스트레일리아 중서부 하계 표준시#,
				'generic' => q#오스트레일리아 중서부 시간#,
				'standard' => q#오스트레일리아 중서부 표준시#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#오스트레일리아 동부 하계 표준시#,
				'generic' => q#오스트레일리아 동부 시간#,
				'standard' => q#오스트레일리아 동부 표준시#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#오스트레일리아 서부 하계 표준시#,
				'generic' => q#오스트레일리아 서부 시간#,
				'standard' => q#오스트레일리아 서부 표준시#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#아제르바이잔 하계 표준시#,
				'generic' => q#아제르바이잔 시간#,
				'standard' => q#아제르바이잔 표준시#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#아조레스 하계 표준시#,
				'generic' => q#아조레스 시간#,
				'standard' => q#아조레스 표준시#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#방글라데시 하계 표준시#,
				'generic' => q#방글라데시 시간#,
				'standard' => q#방글라데시 표준시#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#부탄 시간#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#볼리비아 시간#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#브라질리아 하계 표준시#,
				'generic' => q#브라질리아 시간#,
				'standard' => q#브라질리아 표준시#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#브루나이 시간#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#카보 베르데 하계 표준시#,
				'generic' => q#카보 베르데 시간#,
				'standard' => q#카보 베르데 표준시#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#케이시 시간#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#차모로 시간#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#채텀 하계 표준시#,
				'generic' => q#채텀 시간#,
				'standard' => q#채텀 표준시#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#칠레 하계 표준시#,
				'generic' => q#칠레 시간#,
				'standard' => q#칠레 표준시#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#중국 하계 표준시#,
				'generic' => q#중국 시간#,
				'standard' => q#중국 표준시#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#초이발산 하계 표준시#,
				'generic' => q#초이발산 시간#,
				'standard' => q#초이발산 표준시#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#크리스마스섬 시간#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#코코스 제도 시간#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#콜롬비아 하계 표준시#,
				'generic' => q#콜롬비아 시간#,
				'standard' => q#콜롬비아 표준시#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#쿡 제도 절반 하계 표준시#,
				'generic' => q#쿡 제도 시간#,
				'standard' => q#쿡 제도 표준시#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#쿠바 하계 표준시#,
				'generic' => q#쿠바 시간#,
				'standard' => q#쿠바 표준시#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#데이비스 시간#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#뒤몽뒤르빌 시간#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#동티모르 시간#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#이스터섬 하계 표준시#,
				'generic' => q#이스터섬 시간#,
				'standard' => q#이스터섬 표준시#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#에콰도르 시간#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#협정 세계시#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#알 수 없는 장소#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#암스테르담#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#안도라#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#아스트라한#,
		},
		'Europe/Athens' => {
			exemplarCity => q#아테네#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#베오그라드#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#베를린#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#브라티슬라바#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#브뤼셀#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#부쿠레슈티#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#부다페스트#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#뷔지겐#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#키시나우#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#코펜하겐#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#더블린#,
			long => {
				'daylight' => q#아일랜드 표준시#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#지브롤터#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#건지#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#헬싱키#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#맨섬#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#이스탄불#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#저지#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#칼리닌그라드#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#키예프#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#키로프#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#리스본#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#류블랴나#,
		},
		'Europe/London' => {
			exemplarCity => q#런던#,
			long => {
				'daylight' => q#영국 하계 표준시#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#룩셈부르크#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#마드리드#,
		},
		'Europe/Malta' => {
			exemplarCity => q#몰타#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#마리에함#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#민스크#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#모나코#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#모스크바#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#오슬로#,
		},
		'Europe/Paris' => {
			exemplarCity => q#파리#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#포드고리차#,
		},
		'Europe/Prague' => {
			exemplarCity => q#프라하#,
		},
		'Europe/Riga' => {
			exemplarCity => q#리가#,
		},
		'Europe/Rome' => {
			exemplarCity => q#로마#,
		},
		'Europe/Samara' => {
			exemplarCity => q#사마라#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#산마리노#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#사라예보#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#사라토프#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#심페로폴#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#스코페#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#소피아#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#스톡홀름#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#탈린#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#티라나#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#울리야노프스크#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#우주고로트#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#파두츠#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#바티칸#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#비엔나#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#빌니우스#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#볼고그라트#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#바르샤바#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#자그레브#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#자포로지예#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#취리히#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#중부유럽 하계 표준시#,
				'generic' => q#중부유럽 시간#,
				'standard' => q#중부유럽 표준시#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#동유럽 하계 표준시#,
				'generic' => q#동유럽 시간#,
				'standard' => q#동유럽 표준시#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#극동유럽 표준시#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#서유럽 하계 표준시#,
				'generic' => q#서유럽 시간#,
				'standard' => q#서유럽 표준시#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#포클랜드 제도 하계 표준시#,
				'generic' => q#포클랜드 제도 시간#,
				'standard' => q#포클랜드 제도 표준시#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#피지 하계 표준시#,
				'generic' => q#피지 시간#,
				'standard' => q#피지 표준시#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#프랑스령 가이아나 시간#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#프랑스령 남부 식민지 및 남극 시간#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#그리니치 표준시#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#갈라파고스 시간#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#감비에 시간#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#조지아 하계 표준시#,
				'generic' => q#조지아 시간#,
				'standard' => q#조지아 표준시#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#길버트 제도 시간#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#그린란드 동부 하계 표준시#,
				'generic' => q#그린란드 동부 시간#,
				'standard' => q#그린란드 동부 표준시#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#그린란드 서부 하계 표준시#,
				'generic' => q#그린란드 서부 시간#,
				'standard' => q#그린란드 서부 표준시#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#괌 표준 시간#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#걸프만 표준시#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#가이아나 시간#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#하와이 알류샨 하계 표준시#,
				'generic' => q#하와이 알류샨 시간#,
				'standard' => q#하와이 알류샨 표준시#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#홍콩 하계 표준시#,
				'generic' => q#홍콩 시간#,
				'standard' => q#홍콩 표준시#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#호브드 하계 표준시#,
				'generic' => q#호브드 시간#,
				'standard' => q#호브드 표준시#,
			},
		},
		'India' => {
			long => {
				'standard' => q#인도 표준시#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#안타나나리보#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#차고스#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#크리스마스#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#코코스#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#코모로#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#케르켈렌#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#마헤#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#몰디브#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#모리셔스#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#메요트#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#레위니옹#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#인도양 시간#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#인도차이나 시간#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#중부 인도네시아 시간#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#동부 인도네시아 시간#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#서부 인도네시아 시간#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#이란 하계 표준시#,
				'generic' => q#이란 시간#,
				'standard' => q#이란 표준시#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#이르쿠츠크 하계 표준시#,
				'generic' => q#이르쿠츠크 시간#,
				'standard' => q#이르쿠츠크 표준시#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#이스라엘 하계 표준시#,
				'generic' => q#이스라엘 시간#,
				'standard' => q#이스라엘 표준시#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#일본 하계 표준시#,
				'generic' => q#일본 시간#,
				'standard' => q#일본 표준시#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#페트로파블롭스크-캄차츠키 하계 표준시#,
				'generic' => q#페트로파블롭스크-캄차츠키 시간#,
				'standard' => q#페트로파블롭스크-캄차츠키 표준시#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#동부 카자흐스탄 시간#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#서부 카자흐스탄 시간#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#대한민국 하계 표준시#,
				'generic' => q#대한민국 시간#,
				'standard' => q#대한민국 표준시#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#코스라에섬 시간#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#크라스노야르스크 하계 표준시#,
				'generic' => q#크라스노야르스크 시간#,
				'standard' => q#크라스노야르스크 표준시#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#키르기스스탄 시간#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#랑카 표준 시간#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#라인 제도 시간#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#로드 하우 하계 표준시#,
				'generic' => q#로드 하우 시간#,
				'standard' => q#로드 하우 표준시#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#마카오 하계 표준시#,
				'generic' => q#마카오 시간#,
				'standard' => q#마카오 표준 시간#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#매쿼리섬 시간#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#마가단 하계 표준시#,
				'generic' => q#마가단 시간#,
				'standard' => q#마가단 표준시#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#말레이시아 시간#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#몰디브 시간#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#마르키즈 제도 시간#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#마셜 제도 시간#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#모리셔스 하계 표준시#,
				'generic' => q#모리셔스 시간#,
				'standard' => q#모리셔스 표준시#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#모슨 시간#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#멕시코 북서부 하계 표준시#,
				'generic' => q#멕시코 북서부 시간#,
				'standard' => q#멕시코 북서부 표준시#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#멕시코 태평양 하계 표준시#,
				'generic' => q#멕시코 태평양 시간#,
				'standard' => q#멕시코 태평양 표준시#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#울란바토르 하계 표준시#,
				'generic' => q#울란바토르 시간#,
				'standard' => q#울란바토르 표준시#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#모스크바 하계 표준시#,
				'generic' => q#모스크바 시간#,
				'standard' => q#모스크바 표준시#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#미얀마 시간#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#나우루 시간#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#네팔 시간#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#뉴칼레도니아 하계 표준시#,
				'generic' => q#뉴칼레도니아 시간#,
				'standard' => q#뉴칼레도니아 표준시#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#뉴질랜드 하계 표준시#,
				'generic' => q#뉴질랜드 시간#,
				'standard' => q#뉴질랜드 표준시#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#뉴펀들랜드 하계 표준시#,
				'generic' => q#뉴펀들랜드 시간#,
				'standard' => q#뉴펀들랜드 표준시#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#니우에 시간#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#노퍽섬 하계 표준시#,
				'generic' => q#노퍽섬 시간#,
				'standard' => q#노퍽섬 표준시#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#페르난도 데 노로냐 하계 표준시#,
				'generic' => q#페르난도 데 노로냐 시간#,
				'standard' => q#페르난도 데 노로냐 표준시#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#북마리아나 제도 표준 시간#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#노보시비르스크 하계 표준시#,
				'generic' => q#노보시비르스크 시간#,
				'standard' => q#노보시비르스크 표준시#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#옴스크 하계 표준시#,
				'generic' => q#옴스크 시간#,
				'standard' => q#옴스크 표준시#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#아피아#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#오클랜드#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#부갱빌#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#채텀#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#이스터 섬#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#에파테#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#엔더베리#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#파카오푸#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#피지#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#푸나푸티#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#갈라파고스#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#감비어#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#과달카날#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#괌#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#호놀룰루#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#존스톤#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#키리티마티#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#코스레#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#콰잘렌#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#마주로#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#마퀘사스#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#미드웨이#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#나우루#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#니우에#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#노퍽#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#누메아#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#파고파고#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#팔라우#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#핏케언#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#포나페#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#포트모르즈비#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#라로통가#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#사이판#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#타히티#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#타라와#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#통가타푸#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#트루크#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#웨이크#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#월리스#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#파키스탄 하계 표준시#,
				'generic' => q#파키스탄 시간#,
				'standard' => q#파키스탄 표준시#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#팔라우 시간#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#파푸아뉴기니 시간#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#파라과이 하계 표준시#,
				'generic' => q#파라과이 시간#,
				'standard' => q#파라과이 표준시#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#페루 하계 표준시#,
				'generic' => q#페루 시간#,
				'standard' => q#페루 표준시#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#필리핀 하계 표준시#,
				'generic' => q#필리핀 시간#,
				'standard' => q#필리핀 표준시#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#피닉스 제도 시간#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#세인트피에르 미클롱 하계 표준시#,
				'generic' => q#세인트피에르 미클롱 시간#,
				'standard' => q#세인트피에르 미클롱 표준시#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#핏케언 시간#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#포나페 시간#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#평양 시간#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#키질로르다 하계 표준시#,
				'generic' => q#키질로르다 시간#,
				'standard' => q#키질로르다 표준 시간#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#레위니옹 시간#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#로데라 시간#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#사할린 하계 표준시#,
				'generic' => q#사할린 시간#,
				'standard' => q#사할린 표준시#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#사마라 하계 표준시#,
				'generic' => q#사마라 시간#,
				'standard' => q#사마라 표준시#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#사모아 하계 표준시#,
				'generic' => q#사모아 시간#,
				'standard' => q#사모아 표준시#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#세이셸 시간#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#싱가포르 표준시#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#솔로몬 제도 시간#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#사우스 조지아 시간#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#수리남 시간#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#쇼와 시간#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#타히티 시간#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#대만 하계 표준시#,
				'generic' => q#대만 시간#,
				'standard' => q#대만 표준시#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#타지키스탄 시간#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#토켈라우 시간#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#통가 하계 표준시#,
				'generic' => q#통가 시간#,
				'standard' => q#통가 표준시#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#추크 시간#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#투르크메니스탄 하계 표준시#,
				'generic' => q#투르크메니스탄 시간#,
				'standard' => q#투르크메니스탄 표준시#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#투발루 시간#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#우루과이 하계 표준시#,
				'generic' => q#우루과이 시간#,
				'standard' => q#우루과이 표준시#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#우즈베키스탄 하계 표준시#,
				'generic' => q#우즈베키스탄 시간#,
				'standard' => q#우즈베키스탄 표준시#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#바누아투 하계 표준시#,
				'generic' => q#바누아투 시간#,
				'standard' => q#바누아투 표준시#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#베네수엘라 시간#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#블라디보스토크 하계 표준시#,
				'generic' => q#블라디보스토크 시간#,
				'standard' => q#블라디보스토크 표준시#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#볼고그라드 하계 표준시#,
				'generic' => q#볼고그라드 시간#,
				'standard' => q#볼고그라드 표준시#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#보스톡 시간#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#웨이크섬 시간#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#월리스푸투나 제도 시간#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#야쿠츠크 하계 표준시#,
				'generic' => q#야쿠츠크 시간#,
				'standard' => q#야쿠츠크 표준시#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#예카테린부르크 하계 표준시#,
				'generic' => q#예카테린부르크 시간#,
				'standard' => q#예카테린부르크 표준시#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#유콘 시간#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
