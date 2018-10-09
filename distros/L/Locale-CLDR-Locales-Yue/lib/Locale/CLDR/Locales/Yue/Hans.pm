=encoding utf8

=head1

Locale::CLDR::Locales::Yue::Hans - Package for language Cantonese

=cut

package Locale::CLDR::Locales::Yue::Hans;
# This file auto generated from Data\common\main\yue_Hans.xml
#	on Sun  7 Oct 11:07:20 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.1');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
use Types::Standard qw( Str Int HashRef ArrayRef CodeRef RegexpRef );
use Moo;

extends('Locale::CLDR::Locales::Yue');
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-financial','spellout-cardinal','spellout-cardinal-alternate2','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
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
					rule => q(负→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←点→→→),
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
					rule => q(←%spellout-numbering←万[→%%number4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-numbering←亿[→%%number5→]),
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
					rule => q(负→→),
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
					rule => q(两),
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
					rule => q(←%spellout-numbering←万[→%%number4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-numbering←亿[→%%number5→]),
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
		'spellout-cardinal-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(负→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←点→→→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(壹),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(贰),
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
					rule => q(陆),
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
					rule => q(←%spellout-cardinal-financial←万[→%%financialnumber4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←%spellout-cardinal-financial←亿[→%%financialnumber5→]),
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
					rule => q(负→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(零),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←←点→→→),
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
					rule => q(←←万[→%%number4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←亿[→%%number5→]),
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

# Need to add code for Key type pattern
sub display_name_pattern {
	my ($self, $name, $region, $script, $variant) = @_;

	my $display_pattern = '{0} ({1})';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0}，{1}', grep {$_} (
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
				'aa' => '阿法文',
 				'ab' => '阿布哈兹文',
 				'ace' => '亚齐文',
 				'ach' => '阿侨利文',
 				'ada' => '阿当莫文',
 				'ady' => '阿迪各文',
 				'ae' => '阿纬斯陀文',
 				'aeb' => '突尼斯阿拉伯文',
 				'af' => '南非荷兰文',
 				'afh' => '阿弗里希利文',
 				'agq' => '亚罕文',
 				'ain' => '阿伊努文',
 				'ak' => '阿坎文',
 				'akk' => '阿卡德文',
 				'akz' => '阿拉巴马文',
 				'ale' => '阿留申文',
 				'aln' => '盖格阿尔巴尼亚文',
 				'alt' => '南阿尔泰文',
 				'am' => '阿姆哈拉文',
 				'an' => '阿拉贡文',
 				'ang' => '古英文',
 				'anp' => '昂加文',
 				'ar' => '阿拉伯文',
 				'ar_001' => '现代标准阿拉伯文',
 				'arc' => '阿拉米文',
 				'arn' => '马普切文',
 				'aro' => '阿拉奥纳文',
 				'arp' => '阿拉帕霍文',
 				'arq' => '阿尔及利亚阿拉伯文',
 				'arw' => '阿拉瓦克文',
 				'ary' => '摩洛哥阿拉伯文',
 				'arz' => '埃及阿拉伯文',
 				'as' => '阿萨姆文',
 				'asa' => '阿苏文',
 				'ase' => '美国手语',
 				'ast' => '阿斯图里亚文',
 				'av' => '阿瓦尔文',
 				'avk' => '科塔瓦文',
 				'awa' => '阿瓦文',
 				'ay' => '艾马拉文',
 				'az' => '亚塞拜然文',
 				'az@alt=short' => '亚塞拜然文',
 				'ba' => '巴什客尔文',
 				'bal' => '俾路支文',
 				'ban' => '峇里文',
 				'bar' => '巴伐利亚文',
 				'bas' => '巴萨文',
 				'bax' => '巴姆穆文',
 				'bbc' => '巴塔克托巴文',
 				'bbj' => '戈马拉文',
 				'be' => '白俄罗斯文',
 				'bej' => '贝扎文',
 				'bem' => '别姆巴文',
 				'bew' => '贝塔维文',
 				'bez' => '贝纳文',
 				'bfd' => '富特文',
 				'bfq' => '巴达加文',
 				'bg' => '保加利亚文',
 				'bgn' => '西俾路支文',
 				'bho' => '博杰普尔文',
 				'bi' => '比斯拉马文',
 				'bik' => '比科尔文',
 				'bin' => '比尼文',
 				'bjn' => '班亚尔文',
 				'bkm' => '康姆文',
 				'bla' => '锡克锡卡文',
 				'bm' => '班巴拉文',
 				'bn' => '孟加拉文',
 				'bo' => '藏文',
 				'bpy' => '比什奴普莱利亚文',
 				'bqi' => '巴赫蒂亚里文',
 				'br' => '布列塔尼文',
 				'bra' => '布拉杰文',
 				'brh' => '布拉维文',
 				'brx' => '博多文',
 				'bs' => '波士尼亚文',
 				'bss' => '阿库色文',
 				'bua' => '布里阿特文',
 				'bug' => '布吉斯文',
 				'bum' => '布鲁文',
 				'byn' => '比林文',
 				'byv' => '梅敦巴文',
 				'ca' => '加泰罗尼亚文',
 				'cad' => '卡多文',
 				'car' => '加勒比文',
 				'cay' => '卡尤加文',
 				'cch' => '阿灿文',
 				'ce' => '车臣文',
 				'ceb' => '宿雾文',
 				'cgg' => '奇加文',
 				'ch' => '查莫洛文',
 				'chb' => '奇布查文',
 				'chg' => '查加文',
 				'chk' => '处奇斯文',
 				'chm' => '马里文',
 				'chn' => '契奴克文',
 				'cho' => '乔克托文',
 				'chp' => '奇佩瓦扬文',
 				'chr' => '柴罗基文',
 				'chy' => '沙伊安文',
 				'ckb' => '索拉尼库尔德文',
 				'co' => '科西嘉文',
 				'cop' => '科普特文',
 				'cps' => '卡皮兹文',
 				'cr' => '克里文',
 				'crh' => '克里米亚半岛的土耳其文；克里米亚半岛的塔塔尔文',
 				'crs' => '法语克里奥尔混合语',
 				'cs' => '捷克文',
 				'csb' => '卡舒布文',
 				'cu' => '宗教斯拉夫文',
 				'cv' => '楚瓦什文',
 				'cy' => '威尔斯文',
 				'da' => '丹麦文',
 				'dak' => '达科他文',
 				'dar' => '达尔格瓦文',
 				'dav' => '台塔文',
 				'de' => '德文',
 				'de_CH' => '高地德文（瑞士）',
 				'del' => '德拉瓦文',
 				'den' => '斯拉夫',
 				'dgr' => '多格里布文',
 				'din' => '丁卡文',
 				'dje' => '扎尔马文',
 				'doi' => '多格来文',
 				'dsb' => '下索布文',
 				'dtp' => '中部杜顺文',
 				'dua' => '杜亚拉文',
 				'dum' => '中古荷兰文',
 				'dv' => '迪维西文',
 				'dyo' => '朱拉文',
 				'dyu' => '迪尤拉文',
 				'dz' => '宗卡文',
 				'dzg' => '达萨文',
 				'ebu' => '恩布文',
 				'ee' => '埃维文',
 				'efi' => '埃菲克文',
 				'egl' => '埃米利安文',
 				'egy' => '古埃及文',
 				'eka' => '艾卡朱克文',
 				'el' => '希腊文',
 				'elx' => '埃兰文',
 				'en' => '英文',
 				'enm' => '中古英文',
 				'eo' => '世界文',
 				'es' => '西班牙文',
 				'esu' => '中尤皮克文',
 				'et' => '爱沙尼亚文',
 				'eu' => '巴斯克文',
 				'ewo' => '依汪都文',
 				'ext' => '埃斯特雷马杜拉文',
 				'fa' => '波斯文',
 				'fan' => '芳族文',
 				'fat' => '芳蒂文',
 				'ff' => '富拉文',
 				'fi' => '芬兰文',
 				'fil' => '菲律宾文',
 				'fit' => '托尔讷芬兰文',
 				'fj' => '斐济文',
 				'fo' => '法罗文',
 				'fon' => '丰文',
 				'fr' => '法文',
 				'frc' => '卡真法文',
 				'frm' => '中古法文',
 				'fro' => '古法文',
 				'frp' => '法兰克-普罗旺斯文',
 				'frr' => '北弗里西亚文',
 				'frs' => '东弗里西亚文',
 				'fur' => '弗留利文',
 				'fy' => '西弗里西亚文',
 				'ga' => '爱尔兰文',
 				'gaa' => '加族文',
 				'gag' => '加告兹文',
 				'gan' => '赣语',
 				'gay' => '加约文',
 				'gba' => '葛巴亚文',
 				'gbz' => '索罗亚斯德教达里文',
 				'gd' => '苏格兰盖尔文',
 				'gez' => '吉兹文',
 				'gil' => '吉尔伯特群岛文',
 				'gl' => '加利西亚文',
 				'glk' => '吉拉基文',
 				'gmh' => '中古高地德文',
 				'gn' => '瓜拉尼文',
 				'goh' => '古高地日耳曼文',
 				'gom' => '孔卡尼文',
 				'gon' => '冈德文',
 				'gor' => '科隆达罗文',
 				'got' => '哥德文',
 				'grb' => '格列博文',
 				'grc' => '古希腊文',
 				'gsw' => '德文（瑞士）',
 				'gu' => '古吉拉特文',
 				'guc' => '瓦尤文',
 				'gur' => '弗拉弗拉文',
 				'guz' => '古西文',
 				'gv' => '曼岛文',
 				'gwi' => '圭契文',
 				'ha' => '豪撒文',
 				'hai' => '海达文',
 				'hak' => '客家话',
 				'haw' => '夏威夷文',
 				'he' => '希伯来文',
 				'hi' => '北印度文',
 				'hif' => '斐济印地文',
 				'hil' => '希利盖农文',
 				'hit' => '赫梯文',
 				'hmn' => '孟文',
 				'ho' => '西里莫图土文',
 				'hr' => '克罗埃西亚文',
 				'hsb' => '上索布文',
 				'hsn' => '湘语',
 				'ht' => '海地文',
 				'hu' => '匈牙利文',
 				'hup' => '胡帕文',
 				'hy' => '亚美尼亚文',
 				'hz' => '赫雷罗文',
 				'ia' => '国际文',
 				'iba' => '伊班文',
 				'ibb' => '伊比比奥文',
 				'id' => '印尼文',
 				'ie' => '国际文（E）',
 				'ig' => '伊布文',
 				'ii' => '四川彝文',
 				'ik' => '依奴皮维克文',
 				'ilo' => '伊洛阔文',
 				'inh' => '印古什文',
 				'io' => '伊多文',
 				'is' => '冰岛文',
 				'it' => '义大利文',
 				'iu' => '因纽特文',
 				'izh' => '英格里亚文',
 				'ja' => '日文',
 				'jam' => '牙买加克里奥尔英文',
 				'jbo' => '逻辑文',
 				'jgo' => '恩格姆巴文',
 				'jmc' => '马恰美文',
 				'jpr' => '犹太教-波斯文',
 				'jrb' => '犹太阿拉伯文',
 				'jut' => '日德兰文',
 				'jv' => '爪哇文',
 				'ka' => '乔治亚文',
 				'kaa' => '卡拉卡尔帕克文',
 				'kab' => '卡比尔文',
 				'kac' => '卡琴文',
 				'kaj' => '卡捷文',
 				'kam' => '卡姆巴文',
 				'kaw' => '卡威文',
 				'kbd' => '卡巴尔达文',
 				'kbl' => '卡念布文',
 				'kcg' => '卡塔布文',
 				'kde' => '马孔德文',
 				'kea' => '卡布威尔第文',
 				'ken' => '肯扬文',
 				'kfo' => '科罗文',
 				'kg' => '刚果文',
 				'kgp' => '坎刚文',
 				'kha' => '卡西文',
 				'kho' => '和阗文',
 				'khq' => '西桑海文',
 				'khw' => '科瓦文',
 				'ki' => '吉库尤文',
 				'kiu' => '北扎扎其文',
 				'kj' => '广亚马文',
 				'kk' => '哈萨克文',
 				'kkj' => '卡库文',
 				'kl' => '格陵兰文',
 				'kln' => '卡伦金文',
 				'km' => '高棉文',
 				'kmb' => '金邦杜文',
 				'kn' => '坎那达文',
 				'ko' => '韩文',
 				'koi' => '科米-彼尔米亚克文',
 				'kok' => '贡根文',
 				'kos' => '科斯雷恩文',
 				'kpe' => '克佩列文',
 				'kr' => '卡努里文',
 				'krc' => '卡拉柴-包尔卡尔文',
 				'kri' => '塞拉利昂克里奥尔文',
 				'krj' => '基那来阿文',
 				'krl' => '卡累利阿文',
 				'kru' => '库鲁科文',
 				'ks' => '喀什米尔文',
 				'ksb' => '尚巴拉文',
 				'ksf' => '巴菲亚文',
 				'ksh' => '科隆文',
 				'ku' => '库尔德文',
 				'kum' => '库密克文',
 				'kut' => '库特奈文',
 				'kv' => '科米文',
 				'kw' => '康瓦耳文',
 				'ky' => '吉尔吉斯文',
 				'la' => '拉丁文',
 				'lad' => '拉迪诺文',
 				'lag' => '朗吉文',
 				'lah' => '拉亨达文',
 				'lam' => '兰巴文',
 				'lb' => '卢森堡文',
 				'lez' => '列兹干文',
 				'lfn' => '新共同语言',
 				'lg' => '干达文',
 				'li' => '林堡文',
 				'lij' => '利古里亚文',
 				'liv' => '利伏尼亚文',
 				'lkt' => '拉科塔文',
 				'lmo' => '伦巴底文',
 				'ln' => '林加拉文',
 				'lo' => '寮文',
 				'lol' => '芒戈文',
 				'loz' => '洛齐文',
 				'lrc' => '北卢尔文',
 				'lt' => '立陶宛文',
 				'ltg' => '拉特加莱文',
 				'lu' => '鲁巴加丹加文',
 				'lua' => '鲁巴鲁鲁亚文',
 				'lui' => '路易塞诺文',
 				'lun' => '卢恩达文',
 				'luo' => '卢奥文',
 				'lus' => '卢晒文',
 				'luy' => '卢雅文',
 				'lv' => '拉脱维亚文',
 				'lzh' => '文言文',
 				'lzz' => '拉兹文',
 				'mad' => '马都拉文',
 				'maf' => '马法文',
 				'mag' => '马加伊文',
 				'mai' => '迈蒂利文',
 				'mak' => '望加锡文',
 				'man' => '曼丁哥文',
 				'mas' => '马赛文',
 				'mde' => '马巴文',
 				'mdf' => '莫克沙文',
 				'mdr' => '曼达文',
 				'men' => '门德文',
 				'mer' => '梅鲁文',
 				'mfe' => '克里奥文（模里西斯）',
 				'mg' => '马拉加什文',
 				'mga' => '中古爱尔兰文',
 				'mgh' => '马夸文',
 				'mgo' => '美塔文',
 				'mh' => '马绍尔文',
 				'mi' => '毛利文',
 				'mic' => '米克马克文',
 				'min' => '米南卡堡文',
 				'mk' => '马其顿文',
 				'ml' => '马来亚拉姆文',
 				'mn' => '蒙古文',
 				'mnc' => '满族文',
 				'mni' => '曼尼普里文',
 				'moh' => '莫霍克文',
 				'mos' => '莫西文',
 				'mr' => '马拉地文',
 				'mrj' => '西马里文',
 				'ms' => '马来文',
 				'mt' => '马尔他文',
 				'mua' => '蒙当文',
 				'mul' => '多种语言',
 				'mus' => '克里克文',
 				'mwl' => '米兰德斯文',
 				'mwr' => '马尔尼里文',
 				'mwv' => '明打威文',
 				'my' => '缅甸文',
 				'mye' => '姆耶内文',
 				'myv' => '厄尔兹亚文',
 				'mzn' => '马赞德兰文',
 				'na' => '诺鲁文',
 				'nan' => '闽南语',
 				'nap' => '拿波里文',
 				'naq' => '纳马文',
 				'nb' => '巴克摩挪威文',
 				'nd' => '北地毕列文',
 				'nds' => '低地德文',
 				'nds_NL' => '低地萨克逊文',
 				'ne' => '尼泊尔文',
 				'new' => '尼瓦尔文',
 				'ng' => '恩东加文',
 				'nia' => '尼亚斯文',
 				'niu' => '纽埃文',
 				'njo' => '阿沃那加文',
 				'nl' => '荷兰文',
 				'nl_BE' => '佛兰芒文',
 				'nmg' => '夸西奥文',
 				'nn' => '耐诺斯克挪威文',
 				'nnh' => '恩甘澎文',
 				'no' => '挪威文',
 				'nog' => '诺盖文',
 				'non' => '古诺尔斯文',
 				'nov' => '诺维亚文',
 				'nqo' => '曼德文字 (N’Ko)',
 				'nr' => '南地毕列文',
 				'nso' => '北索托文',
 				'nus' => '努埃尔文',
 				'nv' => '纳瓦霍文',
 				'nwc' => '古尼瓦尔文',
 				'ny' => '尼扬贾文',
 				'nym' => '尼扬韦齐文',
 				'nyn' => '尼扬科莱文',
 				'nyo' => '尼奥啰文',
 				'nzi' => '尼兹马文',
 				'oc' => '奥克西坦文',
 				'oj' => '奥杰布瓦文',
 				'om' => '奥罗莫文',
 				'or' => '欧利亚文',
 				'os' => '奥塞提文',
 				'osa' => '欧塞奇文',
 				'ota' => '鄂图曼土耳其文',
 				'pa' => '旁遮普文',
 				'pag' => '潘加辛文',
 				'pal' => '巴列维文',
 				'pam' => '潘帕嘉文',
 				'pap' => '帕皮阿门托文',
 				'pau' => '帛琉文',
 				'pcd' => '庇卡底文',
 				'pcm' => '尼日利亚皮钦语',
 				'pdc' => '宾夕法尼亚德文',
 				'pdt' => '门诺低地德文',
 				'peo' => '古波斯文',
 				'pfl' => '普法尔茨德文',
 				'phn' => '腓尼基文',
 				'pi' => '巴利文',
 				'pl' => '波兰文',
 				'pms' => '皮埃蒙特文',
 				'pnt' => '旁狄希腊文',
 				'pon' => '波那贝文',
 				'prg' => '普鲁士文',
 				'pro' => '古普罗旺斯文',
 				'ps' => '普什图文',
 				'pt' => '葡萄牙文',
 				'qu' => '盖楚瓦文',
 				'quc' => '基切文',
 				'qug' => '钦博拉索海兰盖丘亚文',
 				'raj' => '拉贾斯坦诸文',
 				'rap' => '复活岛文',
 				'rar' => '拉罗通加文',
 				'rgn' => '罗马格诺里文',
 				'rif' => '里菲亚诺文',
 				'rm' => '罗曼斯文',
 				'rn' => '隆迪文',
 				'ro' => '罗马尼亚文',
 				'ro_MD' => '摩尔多瓦文',
 				'rof' => '兰博文',
 				'rom' => '吉普赛文',
 				'root' => '根语言',
 				'rtm' => '罗图马岛文',
 				'ru' => '俄文',
 				'rue' => '卢森尼亚文',
 				'rug' => '罗维阿纳文',
 				'rup' => '罗马尼亚语系',
 				'rw' => '卢安达文',
 				'rwk' => '罗瓦文',
 				'sa' => '梵文',
 				'sad' => '桑达韦文',
 				'sah' => '雅库特文',
 				'sam' => '萨玛利亚阿拉姆文',
 				'saq' => '萨布鲁文',
 				'sas' => '撒撒克文',
 				'sat' => '散塔利文',
 				'saz' => '索拉什特拉文',
 				'sba' => '甘拜文',
 				'sbp' => '桑古文',
 				'sc' => '撒丁文',
 				'scn' => '西西里文',
 				'sco' => '苏格兰文',
 				'sd' => '信德文',
 				'sdc' => '萨丁尼亚-萨萨里文',
 				'sdh' => '南库尔德文',
 				'se' => '北方萨米文',
 				'see' => '塞讷卡文',
 				'seh' => '赛纳文',
 				'sei' => '瑟里文',
 				'sel' => '瑟尔卡普文',
 				'ses' => '东桑海文',
 				'sg' => '桑戈文',
 				'sga' => '古爱尔兰文',
 				'sgs' => '萨莫吉希亚文',
 				'sh' => '塞尔维亚克罗埃西亚文',
 				'shi' => '希尔哈文',
 				'shn' => '掸文',
 				'shu' => '阿拉伯文（查德）',
 				'si' => '僧伽罗文',
 				'sid' => '希达摩文',
 				'sk' => '斯洛伐克文',
 				'sl' => '斯洛维尼亚文',
 				'sli' => '下西利西亚文',
 				'sly' => '塞拉亚文',
 				'sm' => '萨摩亚文',
 				'sma' => '南萨米文',
 				'smj' => '鲁勒萨米文',
 				'smn' => '伊纳里萨米文',
 				'sms' => '斯科特萨米文',
 				'sn' => '塞内加尔文',
 				'snk' => '索尼基文',
 				'so' => '索马利文',
 				'sog' => '索格底亚纳文',
 				'sq' => '阿尔巴尼亚文',
 				'sr' => '塞尔维亚文',
 				'srn' => '苏拉南东墎文',
 				'srr' => '塞雷尔文',
 				'ss' => '斯瓦特文',
 				'ssy' => '萨霍文',
 				'st' => '塞索托文',
 				'stq' => '沙特菲士兰文',
 				'su' => '巽他文',
 				'suk' => '苏库马文',
 				'sus' => '苏苏文',
 				'sux' => '苏美文',
 				'sv' => '瑞典文',
 				'sw' => '史瓦希里文',
 				'sw_CD' => '史瓦希里文（刚果）',
 				'swb' => '葛摩文',
 				'syc' => '古叙利亚文',
 				'syr' => '叙利亚文',
 				'szl' => '西利西亚文',
 				'ta' => '坦米尔文',
 				'tcy' => '图卢文',
 				'te' => '泰卢固文',
 				'tem' => '提姆文',
 				'teo' => '特索文',
 				'ter' => '泰雷诺文',
 				'tet' => '泰顿文',
 				'tg' => '塔吉克文',
 				'th' => '泰文',
 				'ti' => '提格利尼亚文',
 				'tig' => '蒂格雷文',
 				'tiv' => '提夫文',
 				'tk' => '土库曼文',
 				'tkl' => '托克劳文',
 				'tkr' => '查库尔文',
 				'tl' => '塔加路族文',
 				'tlh' => '克林贡文',
 				'tli' => '特林基特文',
 				'tly' => '塔里什文',
 				'tmh' => '塔马奇克文',
 				'tn' => '突尼西亚文',
 				'to' => '东加文',
 				'tog' => '东加文（尼亚萨）',
 				'tpi' => '托比辛文',
 				'tr' => '土耳其文',
 				'tru' => '图罗尤文',
 				'trv' => '太鲁阁文',
 				'ts' => '特松加文',
 				'tsd' => '特萨克尼恩文',
 				'tsi' => '钦西安文',
 				'tt' => '鞑靼文',
 				'ttt' => '穆斯林塔特文',
 				'tum' => '图姆布卡文',
 				'tvl' => '吐瓦鲁文',
 				'tw' => '特威文',
 				'twq' => '北桑海文',
 				'ty' => '大溪地文',
 				'tyv' => '土凡文',
 				'tzm' => '塔马齐格特文',
 				'udm' => '沃蒂艾克文',
 				'ug' => '维吾尔文',
 				'uga' => '乌加列文',
 				'uk' => '乌克兰文',
 				'umb' => '姆本杜文',
 				'und' => '未知语言',
 				'ur' => '乌都文',
 				'uz' => '乌兹别克文',
 				'vai' => '瓦伊文',
 				've' => '温达文',
 				'vec' => '威尼斯文',
 				'vep' => '维普森文',
 				'vi' => '越南文',
 				'vls' => '西佛兰德文',
 				'vmf' => '美茵-法兰克尼亚文',
 				'vo' => '沃拉普克文',
 				'vot' => '沃提克文',
 				'vro' => '佛罗文',
 				'vun' => '温旧文',
 				'wa' => '瓦隆文',
 				'wae' => '瓦瑟文',
 				'wal' => '瓦拉莫文',
 				'war' => '瓦瑞文',
 				'was' => '瓦绍文',
 				'wbp' => '沃皮瑞文',
 				'wo' => '沃洛夫文',
 				'wuu' => '吴语',
 				'xal' => '卡尔梅克文',
 				'xh' => '科萨文',
 				'xmf' => '明格列尔文',
 				'xog' => '索加文',
 				'yao' => '瑶文',
 				'yap' => '雅浦文',
 				'yav' => '洋卞文',
 				'ybb' => '耶姆巴文',
 				'yi' => '意第绪文',
 				'yo' => '约鲁巴文',
 				'yrl' => '奈恩加图文',
 				'yue' => '粤语',
 				'za' => '壮文',
 				'zap' => '萨波特克文',
 				'zbl' => '布列斯符号',
 				'zea' => '西兰文',
 				'zen' => '泽纳加文',
 				'zgh' => '标准摩洛哥塔马塞特文',
 				'zh' => '中文',
 				'zh_Hans' => '简体中文',
 				'zh_Hant' => '繁体中文',
 				'zu' => '祖鲁文',
 				'zun' => '祖尼文',
 				'zxx' => '无语言内容',
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
			'Afak' => '阿法卡文字',
 			'Aghb' => '高加索阿尔巴尼亚文',
 			'Arab' => '阿拉伯文',
 			'Arab@alt=variant' => '波斯阿拉伯文字',
 			'Armi' => '皇室亚美尼亚文',
 			'Armn' => '亚美尼亚文',
 			'Avst' => '阿维斯陀文',
 			'Bali' => '峇里文',
 			'Bamu' => '巴姆穆文',
 			'Bass' => '巴萨文',
 			'Batk' => '巴塔克文',
 			'Beng' => '孟加拉文',
 			'Blis' => '布列斯文',
 			'Bopo' => '注音符号',
 			'Brah' => '婆罗米文',
 			'Brai' => '盲人用点字',
 			'Bugi' => '布吉斯文',
 			'Buhd' => '布希德文',
 			'Cakm' => '查克马文',
 			'Cans' => '加拿大原住民通用字符',
 			'Cari' => '卡里亚文',
 			'Cham' => '占文',
 			'Cher' => '柴罗基文',
 			'Cirt' => '色斯文',
 			'Copt' => '科普特文',
 			'Cprt' => '塞浦路斯文',
 			'Cyrl' => '斯拉夫文',
 			'Cyrs' => '西里尔文（古教会斯拉夫文变体）',
 			'Deva' => '天城文',
 			'Dsrt' => '德瑟雷特文',
 			'Dupl' => '杜普洛伊速记',
 			'Egyd' => '古埃及世俗体',
 			'Egyh' => '古埃及僧侣体',
 			'Egyp' => '古埃及象形文字',
 			'Elba' => '爱尔巴桑文',
 			'Ethi' => '衣索比亚文',
 			'Geok' => '乔治亚语系（阿索他路里和努斯克胡里文）',
 			'Geor' => '乔治亚文',
 			'Glag' => '格拉哥里文',
 			'Goth' => '歌德文',
 			'Gran' => '格兰他文字',
 			'Grek' => '希腊文',
 			'Gujr' => '古吉拉特文',
 			'Guru' => '古鲁穆奇文',
 			'Hanb' => '汉语注音',
 			'Hang' => '韩文字',
 			'Hani' => '汉语',
 			'Hano' => '哈努诺文',
 			'Hans' => '简体',
 			'Hans@alt=stand-alone' => '简体中文',
 			'Hant' => '繁体',
 			'Hant@alt=stand-alone' => '繁体中文',
 			'Hebr' => '希伯来文',
 			'Hira' => '平假名',
 			'Hluw' => '安那托利亚象形文字',
 			'Hmng' => '杨松录苗文',
 			'Hrkt' => '片假名或平假名',
 			'Hung' => '古匈牙利文',
 			'Inds' => '印度河流域（哈拉帕文）',
 			'Ital' => '古意大利文',
 			'Jamo' => '韩文字母',
 			'Java' => '爪哇文',
 			'Jpan' => '日文',
 			'Jurc' => '女真文字',
 			'Kali' => '克耶李文',
 			'Kana' => '片假名',
 			'Khar' => '卡罗须提文',
 			'Khmr' => '高棉文',
 			'Khoj' => '克吉奇文字',
 			'Knda' => '坎那达文',
 			'Kore' => '韩文',
 			'Kpel' => '克培列文',
 			'Kthi' => '凯提文',
 			'Lana' => '蓝拿文',
 			'Laoo' => '寮国文',
 			'Latf' => '拉丁文（尖角体活字变体）',
 			'Latg' => '拉丁文（盖尔语变体）',
 			'Latn' => '拉丁文',
 			'Lepc' => '雷布查文',
 			'Limb' => '林布文',
 			'Lina' => '线性文字（A）',
 			'Linb' => '线性文字（B）',
 			'Lisu' => '栗僳文',
 			'Loma' => '洛马文',
 			'Lyci' => '吕西亚语',
 			'Lydi' => '里底亚语',
 			'Mand' => '曼底安文',
 			'Mani' => '摩尼教文',
 			'Maya' => '玛雅象形文字',
 			'Mend' => '门德文',
 			'Merc' => '麦罗埃文（曲线字体）',
 			'Mero' => '麦罗埃文',
 			'Mlym' => '马来亚拉姆文',
 			'Mong' => '蒙古文',
 			'Moon' => '蒙氏点字',
 			'Mroo' => '谬文',
 			'Mtei' => '曼尼普尔文',
 			'Mymr' => '缅甸文',
 			'Narb' => '古北阿拉伯文',
 			'Nbat' => '纳巴泰文字',
 			'Nkgb' => '纳西格巴文',
 			'Nkoo' => '西非书面语言 (N’Ko)',
 			'Nshu' => '女书文字',
 			'Ogam' => '欧甘文',
 			'Olck' => '桑塔利文',
 			'Orkh' => '鄂尔浑文',
 			'Orya' => '欧利亚文',
 			'Osma' => '欧斯曼亚文',
 			'Palm' => '帕米瑞拉文字',
 			'Perm' => '古彼尔姆诸文',
 			'Phag' => '八思巴文',
 			'Phli' => '巴列维文（碑铭体）',
 			'Phlp' => '巴列维文（圣诗体）',
 			'Phlv' => '巴列维文（书体）',
 			'Phnx' => '腓尼基文',
 			'Plrd' => '柏格理拼音符',
 			'Prti' => '帕提亚文（碑铭体）',
 			'Rjng' => '拉让文',
 			'Roro' => '朗格朗格象形文',
 			'Runr' => '古北欧文字',
 			'Samr' => '撒马利亚文',
 			'Sara' => '沙拉堤文',
 			'Sarb' => '古南阿拉伯文',
 			'Saur' => '索拉什特拉文',
 			'Sgnw' => '手语书写符号',
 			'Shaw' => '箫柏纳字符',
 			'Shrd' => '夏拉达文',
 			'Sidd' => '悉昙文字',
 			'Sind' => '信德文',
 			'Sinh' => '锡兰文',
 			'Sora' => '索朗桑朋文字',
 			'Sund' => '巽他文',
 			'Sylo' => '希洛弟纳格里文',
 			'Syrc' => '敍利亚文',
 			'Syre' => '叙利亚文（福音体文字变体）',
 			'Syrj' => '叙利亚文（西方文字变体）',
 			'Syrn' => '叙利亚文（东方文字变体）',
 			'Tagb' => '南岛文',
 			'Takr' => '塔卡里文字',
 			'Tale' => '傣哪文',
 			'Talu' => '西双版纳新傣文',
 			'Taml' => '坦米尔文',
 			'Tang' => '西夏文',
 			'Tavt' => '傣担文',
 			'Telu' => '泰卢固文',
 			'Teng' => '谈格瓦文',
 			'Tfng' => '提非纳文',
 			'Tglg' => '塔加拉文',
 			'Thaa' => '塔安那文',
 			'Thai' => '泰文',
 			'Tibt' => '西藏文',
 			'Tirh' => '迈蒂利文',
 			'Ugar' => '乌加列文',
 			'Vaii' => '瓦依文',
 			'Visp' => '视觉语音文字',
 			'Wara' => '瓦郎奇蒂文字',
 			'Wole' => '沃雷艾文',
 			'Xpeo' => '古波斯文',
 			'Xsux' => '苏米鲁亚甲文楔形文字',
 			'Yiii' => '彝文',
 			'Zinh' => '继承文字（Unicode）',
 			'Zmth' => '数学符号',
 			'Zsye' => '表情符号',
 			'Zsym' => '符号',
 			'Zxxx' => '非书写语言',
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
 			'014' => '东非',
 			'015' => '北非',
 			'017' => '中非',
 			'018' => '非洲南部',
 			'019' => '美洲',
 			'021' => '北美',
 			'029' => '加勒比海',
 			'030' => '东亚',
 			'034' => '南亚',
 			'035' => '东南亚',
 			'039' => '南欧',
 			'053' => '澳洲同纽西兰',
 			'054' => '美拉尼西亚',
 			'057' => '密克罗尼西亚',
 			'061' => '玻里尼西亚',
 			'142' => '亚洲',
 			'143' => '中亚',
 			'145' => '西亚',
 			'150' => '欧洲',
 			'151' => '东欧',
 			'154' => '北欧',
 			'155' => '西欧',
 			'419' => '拉丁美洲',
 			'AC' => '阿森松岛',
 			'AD' => '安道尔',
 			'AE' => '阿拉伯联合大公国',
 			'AF' => '阿富汗',
 			'AG' => '安提瓜同巴布达',
 			'AI' => '安圭拉',
 			'AL' => '阿尔巴尼亚',
 			'AM' => '亚美尼亚',
 			'AO' => '安哥拉',
 			'AQ' => '南极洲',
 			'AR' => '阿根廷',
 			'AS' => '美属萨摩亚',
 			'AT' => '奥地利',
 			'AU' => '澳洲',
 			'AW' => '荷属阿鲁巴',
 			'AX' => '奥兰群岛',
 			'AZ' => '亚塞拜然',
 			'BA' => '波斯尼亚同黑塞哥维那',
 			'BB' => '巴贝多',
 			'BD' => '孟加拉',
 			'BE' => '比利时',
 			'BF' => '布吉纳法索',
 			'BG' => '保加利亚',
 			'BH' => '巴林',
 			'BI' => '蒲隆地',
 			'BJ' => '贝南',
 			'BL' => '圣巴瑟米',
 			'BM' => '百慕达',
 			'BN' => '汶莱',
 			'BO' => '玻利维亚',
 			'BQ' => '荷兰加勒比区',
 			'BR' => '巴西',
 			'BS' => '巴哈马',
 			'BT' => '不丹',
 			'BV' => '布威岛',
 			'BW' => '波札那',
 			'BY' => '白俄罗斯',
 			'BZ' => '贝里斯',
 			'CA' => '加拿大',
 			'CC' => '科科斯（基林）群岛',
 			'CD' => '刚果（金夏沙）',
 			'CD@alt=variant' => '刚果民主共和国',
 			'CF' => '中非共和国',
 			'CG' => '刚果（布拉萨）',
 			'CG@alt=variant' => '刚果共和国',
 			'CH' => '瑞士',
 			'CI' => '象牙海岸',
 			'CK' => '库克群岛',
 			'CL' => '智利',
 			'CM' => '喀麦隆',
 			'CN' => '中华人民共和国',
 			'CO' => '哥伦比亚',
 			'CP' => '克里派顿岛',
 			'CR' => '哥斯大黎加',
 			'CU' => '古巴',
 			'CV' => '维德角',
 			'CW' => '库拉索',
 			'CX' => '圣诞岛',
 			'CY' => '赛普勒斯',
 			'CZ' => '捷克',
 			'CZ@alt=variant' => '捷克共和国',
 			'DE' => '德国',
 			'DG' => '迪亚哥加西亚岛',
 			'DJ' => '吉布地',
 			'DK' => '丹麦',
 			'DM' => '多米尼克',
 			'DO' => '多明尼加共和国',
 			'DZ' => '阿尔及利亚',
 			'EA' => '休达与梅利利亚',
 			'EC' => '厄瓜多',
 			'EE' => '爱沙尼亚',
 			'EG' => '埃及',
 			'EH' => '西撒哈拉',
 			'ER' => '厄利垂亚',
 			'ES' => '西班牙',
 			'ET' => '衣索比亚',
 			'EU' => '欧盟',
 			'EZ' => '欧元区',
 			'FI' => '芬兰',
 			'FJ' => '斐济',
 			'FK' => '福克兰群岛',
 			'FK@alt=variant' => '福克兰群岛 (马尔维纳斯群岛)',
 			'FM' => '密克罗尼西亚群岛',
 			'FO' => '法罗群岛',
 			'FR' => '法国',
 			'GA' => '加彭',
 			'GB' => '英国',
 			'GB@alt=short' => '英国',
 			'GD' => '格瑞那达',
 			'GE' => '乔治亚共和国',
 			'GF' => '法属圭亚那',
 			'GG' => '根西岛',
 			'GH' => '迦纳',
 			'GI' => '直布罗陀',
 			'GL' => '格陵兰',
 			'GM' => '甘比亚',
 			'GN' => '几内亚',
 			'GP' => '瓜地洛普',
 			'GQ' => '赤道几内亚',
 			'GR' => '希腊',
 			'GS' => '南佐治亚岛同南桑威奇群岛',
 			'GT' => '瓜地马拉',
 			'GU' => '关岛',
 			'GW' => '几内亚比索',
 			'GY' => '盖亚那',
 			'HK' => '中华人民共和国香港特别行政区',
 			'HK@alt=short' => '香港',
 			'HM' => '赫德岛同麦克唐纳群岛',
 			'HN' => '宏都拉斯',
 			'HR' => '克罗埃西亚',
 			'HT' => '海地',
 			'HU' => '匈牙利',
 			'IC' => '加那利群岛',
 			'ID' => '印尼',
 			'IE' => '爱尔兰',
 			'IL' => '以色列',
 			'IM' => '曼岛',
 			'IN' => '印度',
 			'IO' => '英属印度洋领地',
 			'IQ' => '伊拉克',
 			'IR' => '伊朗',
 			'IS' => '冰岛',
 			'IT' => '义大利',
 			'JE' => '泽西岛',
 			'JM' => '牙买加',
 			'JO' => '约旦',
 			'JP' => '日本',
 			'KE' => '肯亚',
 			'KG' => '吉尔吉斯',
 			'KH' => '柬埔寨',
 			'KI' => '吉里巴斯',
 			'KM' => '葛摩',
 			'KN' => '圣基茨同尼维斯',
 			'KP' => '北韩',
 			'KR' => '南韩',
 			'KW' => '科威特',
 			'KY' => '开曼群岛',
 			'KZ' => '哈萨克',
 			'LA' => '寮国',
 			'LB' => '黎巴嫩',
 			'LC' => '圣露西亚',
 			'LI' => '列支敦斯登',
 			'LK' => '斯里兰卡',
 			'LR' => '赖比瑞亚',
 			'LS' => '赖索托',
 			'LT' => '立陶宛',
 			'LU' => '卢森堡',
 			'LV' => '拉脱维亚',
 			'LY' => '利比亚',
 			'MA' => '摩洛哥',
 			'MC' => '摩纳哥',
 			'MD' => '摩尔多瓦',
 			'ME' => '蒙特内哥罗',
 			'MF' => '法属圣马丁',
 			'MG' => '马达加斯加',
 			'MH' => '马绍尔群岛',
 			'MK' => '马其顿',
 			'MK@alt=variant' => '前南斯拉夫马其顿共和国',
 			'ML' => '马利',
 			'MM' => '缅甸',
 			'MN' => '蒙古',
 			'MO' => '中华人民共和国澳门特别行政区',
 			'MO@alt=short' => '澳门',
 			'MP' => '北马里亚纳群岛',
 			'MQ' => '马丁尼克岛',
 			'MR' => '茅利塔尼亚',
 			'MS' => '蒙哲腊',
 			'MT' => '马尔他',
 			'MU' => '模里西斯',
 			'MV' => '马尔地夫',
 			'MW' => '马拉威',
 			'MX' => '墨西哥',
 			'MY' => '马来西亚',
 			'MZ' => '莫三比克',
 			'NA' => '纳米比亚',
 			'NC' => '新喀里多尼亚',
 			'NE' => '尼日',
 			'NF' => '诺福克岛',
 			'NG' => '奈及利亚',
 			'NI' => '尼加拉瓜',
 			'NL' => '荷兰',
 			'NO' => '挪威',
 			'NP' => '尼泊尔',
 			'NR' => '诺鲁',
 			'NU' => '纽埃岛',
 			'NZ' => '纽西兰',
 			'OM' => '阿曼王国',
 			'PA' => '巴拿马',
 			'PE' => '秘鲁',
 			'PF' => '法属玻里尼西亚',
 			'PG' => '巴布亚纽几内亚',
 			'PH' => '菲律宾',
 			'PK' => '巴基斯坦',
 			'PL' => '波兰',
 			'PM' => '圣皮埃尔同密克隆群岛',
 			'PN' => '皮特肯群岛',
 			'PR' => '波多黎各',
 			'PS' => '巴勒斯坦自治区',
 			'PS@alt=short' => '巴勒斯坦',
 			'PT' => '葡萄牙',
 			'PW' => '帛琉',
 			'PY' => '巴拉圭',
 			'QA' => '卡达',
 			'QO' => '大洋洲边疆群岛',
 			'RE' => '留尼旺',
 			'RO' => '罗马尼亚',
 			'RS' => '塞尔维亚',
 			'RU' => '俄罗斯',
 			'RW' => '卢安达',
 			'SA' => '沙乌地阿拉伯',
 			'SB' => '索罗门群岛',
 			'SC' => '塞席尔',
 			'SD' => '苏丹',
 			'SE' => '瑞典',
 			'SG' => '新加坡',
 			'SH' => '圣赫勒拿岛',
 			'SI' => '斯洛维尼亚',
 			'SJ' => '斯瓦尔巴特群岛同扬马延岛',
 			'SK' => '斯洛伐克',
 			'SL' => '狮子山',
 			'SM' => '圣马利诺',
 			'SN' => '塞内加尔',
 			'SO' => '索马利亚',
 			'SR' => '苏利南',
 			'SS' => '南苏丹',
 			'ST' => '圣多美同普林西比',
 			'SV' => '萨尔瓦多',
 			'SX' => '荷属圣马丁',
 			'SY' => '叙利亚',
 			'SZ' => '史瓦济兰',
 			'TA' => '特里斯坦达库尼亚群岛',
 			'TC' => '土克斯及开科斯群岛',
 			'TD' => '查德',
 			'TF' => '法属南方属地',
 			'TG' => '多哥',
 			'TH' => '泰国',
 			'TJ' => '塔吉克',
 			'TK' => '托克劳群岛',
 			'TL' => '东帝汶',
 			'TM' => '土库曼',
 			'TN' => '突尼西亚',
 			'TO' => '东加',
 			'TR' => '土耳其',
 			'TT' => '千里达同多巴哥',
 			'TV' => '吐瓦鲁',
 			'TW' => '台湾',
 			'TZ' => '坦尚尼亚',
 			'UA' => '乌克兰',
 			'UG' => '乌干达',
 			'UM' => '美国本土外小岛屿',
 			'UN' => '联合国',
 			'US' => '美国',
 			'US@alt=short' => '美国',
 			'UY' => '乌拉圭',
 			'UZ' => '乌兹别克',
 			'VA' => '梵蒂冈',
 			'VC' => '圣文森特同格林纳丁斯',
 			'VE' => '委内瑞拉',
 			'VG' => '英属维京群岛',
 			'VI' => '美属维京群岛',
 			'VN' => '越南',
 			'VU' => '万那杜',
 			'WF' => '瓦利斯同富图纳群岛',
 			'WS' => '萨摩亚',
 			'XK' => '科索沃',
 			'YE' => '叶门',
 			'YT' => '马约特',
 			'ZA' => '南非',
 			'ZM' => '尚比亚',
 			'ZW' => '辛巴威',
 			'ZZ' => '未知区域',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => '传统德语拼字学',
 			'1994' => '标准雷西亚拼字',
 			'1996' => '1996 年的德语拼字学',
 			'1606NICT' => '中世纪晚期法文（至1606年）',
 			'1694ACAD' => '早期现代法文',
 			'1959ACAD' => '白俄罗斯文（学术）',
 			'ALALC97' => '美国国会图书馆标准方案罗马化（1997年版）',
 			'ALUKU' => '阿鲁库方言',
 			'AREVELA' => '亚美尼亚东部',
 			'AREVMDA' => '亚美尼亚西部',
 			'BAKU1926' => '统一土耳其拉丁字母',
 			'BAUDDHA' => '佛教混合梵文',
 			'BISCAYAN' => '比斯开方言',
 			'BISKE' => 'San Giorgio/Bila 方言',
 			'BOONT' => '布恩特林方言',
 			'EMODENG' => '早期现代英语',
 			'FONIPA' => 'IPA 拼音',
 			'FONUPA' => 'UPA 拼音',
 			'FONXSAMP' => 'X-SAMPA 音标',
 			'HEPBURN' => '平文式罗马字',
 			'HOGNORSK' => '高地挪威文',
 			'ITIHASA' => '史诗梵文',
 			'JAUER' => '米兹泰尔方言',
 			'JYUTPING' => '香港语言学学会粤语拼音',
 			'KKCOR' => '通用康沃尔文拼字',
 			'LAUKIKA' => '传统梵文',
 			'LIPAW' => '雷西亚利波瓦方言',
 			'LUNA1918' => '俄罗斯文拼字（1917年后）',
 			'MONOTON' => '希腊文单调正字法',
 			'NDYUKA' => '苏利南恩都卡方言',
 			'NEDIS' => '那提松尼方言',
 			'NJIVA' => '雷西亚尼瓦方言',
 			'OSOJS' => '雷西亚欧西亚柯方言',
 			'PAMAKA' => '苏利南帕马卡方言',
 			'PETR1708' => '俄罗斯文拼字（1708 年）',
 			'PINYIN' => '汉语拼音',
 			'POLYTON' => '希腊文多调正字法',
 			'POSIX' => '电脑',
 			'PUTER' => '瑞士普特尔方言',
 			'REVISED' => '已修订的拼字学',
 			'ROZAJ' => '雷西亚方言',
 			'RUMGR' => '罗曼什文',
 			'SAAHO' => '萨霍文',
 			'SCOTLAND' => '苏格兰标准英语',
 			'SCOUSE' => '利物浦方言',
 			'SOLBA' => '雷西亚史托维萨方言',
 			'SURMIRAN' => '瑞士苏迈拉方言',
 			'SURSILV' => '瑞士苏瑟瓦方言',
 			'SUTSILV' => '瑞士苏希瓦方言',
 			'TARASK' => '白俄罗斯文传统拼字',
 			'UCCOR' => '统一康沃尔文拼字',
 			'UCRCOR' => '统一康沃尔文修订拼字',
 			'ULSTER' => '爱尔兰阿尔斯特方言',
 			'VAIDIKA' => '吠陀梵文',
 			'VALENCIA' => '瓦伦西亚文',
 			'VALLADER' => '瑞士瓦勒德方言',
 			'WADEGILE' => '威妥玛式拼音',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => '历法',
 			'cf' => '货币格式',
 			'colalternate' => '略过符号排序',
 			'colbackwards' => '反向重音排序',
 			'colcasefirst' => '大写/小写排列',
 			'colcaselevel' => '区分大小写排序',
 			'collation' => '排序',
 			'colnormalization' => '正规化排序',
 			'colnumeric' => '数字排序',
 			'colstrength' => '排序强度',
 			'currency' => '货币',
 			'hc' => '时间周期（12 小时制与 24 小时制）',
 			'lb' => '换行样式',
 			'ms' => '度量单位系统',
 			'numbers' => '数字',
 			'timezone' => '时区',
 			'va' => '区域变异',
 			'x' => '专用区',

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
 				'buddhist' => q{佛历},
 				'chinese' => q{农历},
 				'coptic' => q{科普特历},
 				'dangi' => q{檀纪历},
 				'ethiopic' => q{衣索比亚历},
 				'ethiopic-amete-alem' => q{衣索比亚历 (Amete Alem)},
 				'gregorian' => q{公历},
 				'hebrew' => q{希伯来历},
 				'indian' => q{印度国历},
 				'islamic' => q{伊斯兰历},
 				'islamic-civil' => q{伊斯兰民用历},
 				'islamic-rgsa' => q{伊斯兰新月历},
 				'islamic-tbla' => q{伊斯兰天文历},
 				'islamic-umalqura' => q{乌姆库拉历},
 				'iso8601' => q{国际标准 ISO 8601},
 				'japanese' => q{日本历},
 				'persian' => q{波斯历},
 				'roc' => q{民国历},
 			},
 			'cf' => {
 				'account' => q{会计货币格式},
 				'standard' => q{标准货币格式},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{排序符号},
 				'shifted' => q{略过符号排序},
 			},
 			'colbackwards' => {
 				'no' => q{正常排序重音},
 				'yes' => q{依反向重音排序},
 			},
 			'colcasefirst' => {
 				'lower' => q{优先排序小写},
 				'no' => q{正常大小写顺序排序},
 				'upper' => q{优先排序大写},
 			},
 			'colcaselevel' => {
 				'no' => q{不分大小写排序},
 				'yes' => q{依大小写排序},
 			},
 			'collation' => {
 				'big5han' => q{繁体中文排序 - Big5},
 				'dictionary' => q{字典排序},
 				'ducet' => q{预设 Unicode 排序},
 				'eor' => q{欧洲排序规则},
 				'gb2312han' => q{简体中文排序 - GB2312},
 				'phonebook' => q{电话簿排序},
 				'phonetic' => q{发音排序},
 				'pinyin' => q{拼音排序},
 				'reformed' => q{改良排序},
 				'search' => q{一般用途搜寻},
 				'searchjl' => q{韩文子音排序},
 				'standard' => q{标准排序},
 				'stroke' => q{笔画排序},
 				'traditional' => q{传统排序},
 				'unihan' => q{部首笔画排序},
 				'zhuyin' => q{注音排序},
 			},
 			'colnormalization' => {
 				'no' => q{非正规化排序},
 				'yes' => q{依正规化排序 Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{个别排序数字},
 				'yes' => q{依数字顺序排序数字},
 			},
 			'colstrength' => {
 				'identical' => q{全部排序},
 				'primary' => q{仅排序基础字母},
 				'quaternary' => q{排序重音/大小写/全半形/假名},
 				'secondary' => q{排序重音},
 				'tertiary' => q{排序重音/大小写/全半形},
 			},
 			'd0' => {
 				'fwidth' => q{全形},
 				'hwidth' => q{半形},
 				'npinyin' => q{数值},
 			},
 			'hc' => {
 				'h11' => q{12 小时制 (0–11)},
 				'h12' => q{12 小时制 (1–12)},
 				'h23' => q{24 小时制 (0–23)},
 				'h24' => q{24 小时制 (1–24)},
 			},
 			'lb' => {
 				'loose' => q{宽松换行样式},
 				'normal' => q{一般换行样式},
 				'strict' => q{强制换行样式},
 			},
 			'm0' => {
 				'bgn' => q{美国地名委员会},
 				'ungegn' => q{联合国地名专家组},
 			},
 			'ms' => {
 				'metric' => q{公制},
 				'uksystem' => q{英制度量单位系统},
 				'ussystem' => q{美制度量单位系统},
 			},
 			'numbers' => {
 				'arab' => q{阿拉伯-印度数字},
 				'arabext' => q{阿拉伯-印度扩充数字},
 				'armn' => q{亚美尼亚数字},
 				'armnlow' => q{小写亚美尼亚数字},
 				'bali' => q{峇里文数字},
 				'beng' => q{孟加拉数字},
 				'brah' => q{婆罗米数字},
 				'cakm' => q{查克马数字},
 				'cham' => q{占文数字},
 				'deva' => q{梵文数字},
 				'ethi' => q{衣索比亚数字},
 				'finance' => q{金融数字},
 				'fullwide' => q{全形数字},
 				'geor' => q{乔治亚数字},
 				'grek' => q{希腊数字},
 				'greklow' => q{小写希腊数字},
 				'gujr' => q{古吉拉特数字},
 				'guru' => q{古尔穆奇数字},
 				'hanidec' => q{中文十进位数字},
 				'hans' => q{小写简体中文数字},
 				'hansfin' => q{大写简体中文数字},
 				'hant' => q{小写繁体中文数字},
 				'hantfin' => q{大写繁体中文数字},
 				'hebr' => q{希伯来数字},
 				'java' => q{爪哇文数字},
 				'jpan' => q{小写日文数字},
 				'jpanfin' => q{大写日文数字},
 				'kali' => q{克耶数字},
 				'khmr' => q{高棉数字},
 				'knda' => q{坎那达数字},
 				'lana' => q{老傣文数字},
 				'lanatham' => q{兰纳文数字},
 				'laoo' => q{寮国数字},
 				'latn' => q{阿拉伯数字},
 				'lepc' => q{西纳文数字},
 				'limb' => q{林布文数字},
 				'mlym' => q{马来亚拉姆数字},
 				'mong' => q{蒙古数字},
 				'mtei' => q{曼尼普尔数字},
 				'mymr' => q{缅甸数字},
 				'mymrshan' => q{缅甸掸文数字},
 				'native' => q{原始数字},
 				'nkoo' => q{曼德数字},
 				'olck' => q{桑塔利文数字},
 				'orya' => q{欧利亚数字},
 				'osma' => q{奥斯曼亚数字},
 				'roman' => q{罗马数字},
 				'romanlow' => q{小写罗马数字},
 				'saur' => q{索拉什特拉文数字},
 				'shrd' => q{夏拉达数字},
 				'sora' => q{索朗桑朋数字},
 				'sund' => q{巽他数字},
 				'takr' => q{塔卡里数字},
 				'talu' => q{新傣仂文数字},
 				'taml' => q{坦米尔数字},
 				'tamldec' => q{坦米尔数字},
 				'telu' => q{泰卢固数字},
 				'thai' => q{泰文数字},
 				'tibt' => q{西藏数字},
 				'traditional' => q{传统数字},
 				'vaii' => q{瓦伊文数字},
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
			'language' => '语言：{0}',
 			'script' => '文字：{0}',
 			'region' => '地区：{0}',

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
			auxiliary => qr{[乍 仂 伏 佐 侣 僳 兆 兑 券 勋 卑 卞 咀 嘅 堤 墎 壤 孜 屿 峇 巽 斜 昙 昼 栗 楔 浑 涅 湘 澎 灿 狄 琳 瑚 甫 碑 礁 绰 芒 苗 茨 茵 蓬 蚩 蛰 蜀 裘 谬 赣 酋 闽 陇 霜]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[一 丁 七 万-与 丑 专 且 世 丘-业 东 丝 丢 两 严 个 中 丰 串 临 丸-主 丽 举 乃 久 么 义 之 乌 乎-乐 乔 乖 乘 乙 九 也-乡 书 买 乱 了 予 争 事 二 于 亏 云 互 五 井 亚 些 亡 交-亨 享 京 亮 亲 人 亿-仁 仅 仇 今 介 仍 从 仑 仔 他 付 仙 代-以 仪 们 仰 仲 件 价 任 份 企 伊 伍 伐 休 众-会 伟 传 伤 伦 伯 估 伴 伸 似 伽 但 佉 位-住 体 何 余 佛 作 你 佩 佳 使 例 供 依 侠 侦-侨 侯 侵 便 促 俄 俊 俗 保 信 修 俾 倍 倒 候 倚 借 值 倾 假 偏 做 停 健 偶 偷 傣 傲 傻 像 僧 儒 儿 允 元-充 先 光 克 免 兔 党 入 全 八-兮 兰 共 关-兹 养-兽 内 冈 册 再 冒 写 军 农 冠 冬 冰 冲 决 况 冷 净 准 凉 凌 减 凝 几 凡 凤 凭 凯 凰 凶 出 击 函 刀 分 切 刊 划 列-创 初 删 判 利 别 到 制 刷 刺 刻 剌 前 剑 剧 剩 剪 副 割 力 劝-务 动-劫 励-劳 势 勇 勉 勒 勤 勿 包 匈 化 北 匹-医 十 千 升 午 半 华 协 卒 卓 单-南 博 卜 占-卢 卧 卫 卯-危 即 却 卷 厂 厄-历 厉 压 厌 厘 厚 原 去 县 参 又 及-反 发 叔 取-叙 口-另 只-叭 可 台 史 右 叶-叹 吃 各 合-吊 同-后 吐 向 吓 吕 吗 君 吝-吠 否 吧 含 听 启 吴 吵 吸 吹 吾 呀 呆 告 员 呜 呢 周 味 呵 呼 命 和 咖 咤 咦 咧 咪 咬 咱 哀 品 哇-哉 响 哎 哥 哦 哩 哪 哭 哲 唉 唐 唔 唬 售 唯 唱 唷 商 啊 啡 啥 啦 啪 啰 喀 喂 善 喇 喊 喔 喜 喝 喵 喷 嗨 嗯 嘉 嘛 嘴 嘻 嘿 器 四 回 因 团 园 困 围 固 国 图 圆 圈 圜 土 圣 在 圭 地 场 圾 址 均 坎-坐 块 坚-坜 坡 坤 坦 坪 垂 垃 型 垒 埃 城 埔 域 培 基 堂 堆 堕 堡 堪 塔 塞 填 境 墙 增 墨 壁 士 壬 壮 声 壳 处 备 复 夏 夕 外 多 夜 够 大 天-夫 央 失 头 夷-夺 奇-奉 奋 奎 奏 契 奔 奖 套 奥 女 奴 奶 她 好 如 妆-妈 妙 妥 妨 妮 妳 妹 妻 姆 始 姐 姑 姓 委 姿 威 娃 娄 娘 娱 婆 婚 媒 嫌 嫩 子 孔 字-孙 孝 孟 季 孤 学 孩 宁 它 宅 宇-安 宋 完 宏 宗-实 宠-室 宪 宫 害 家 容 宽-宿 寂 寄-密 富 寒 寝-察 寨 寮 对 寻 导 寿 封 射 将 尊 小 少 尔 尖 尘 尚 尝 尤 就 尺 尼-尾 局-层 居 届 屋 屏 展 属 屠 山 岁 岂 岚 岛 岩 岭 岸 峡 峰 崇 崴 川 州 巡 工-巨 巫 差 己-巴 巷 币-布 帅 师 希 帐 帕 帖 帛 帝 带 席 帮 常 帽 幅 幕 干-年 并 幸 幻-幽 广 庄 庆 庇 床 序 库-底 店 庚 府 废 度 座 庭 康 庸 廉 廖 延 廷 建 开 异-弄 式 引 弗 弘 弟 张 弥 弦 弯 弱 弹 强 彊 归 当 录 彝 形 彦 彩 彬 彭 彰 影 役 彻 彼 往 征 径 待 很 律 徐 徒 得 微 德 心 必 忆 忌 忍 志-忙 忠 忧 快 念 忽 怀 态 怎 怒 怕 怖 怜 思 怡 急 性 怨 怪 总 恋 恐 恒 恢 恨 恩 恭 息 恰 恶 恼 悉 悔 悟 悠 悦 您 悲 情 惊 惑 惜 惠 惧 惨 惯 想 惹 愁 愈 愉 意 愚 感 愿 慈 慕 慢 慧 慰 憾 懂 懒 戈 戊 戌 戏-戒 或 战 截 戴 户 房-扁 扇 手 才 扎 打 托 扣 扥 执 扩 扫-扭 扯 扰 批 找-技 抄 把 抓 投 抗 折 抛 抢 护 报 披 抬 抱 抵 抹 抽 担 拆 拉 拍 拏 拒 拔 拖 招 拜 拟 拥 拨 择 括 拳 拼 拾 拿 持 挂 指 按 挑 挖 挝 挡 挤 挥 挪 振 挺 捐 捕 损 捡 换 据 捷 授 掉 掌 排 探 接 控 推 措 掸 描 提 插 握 援 搜 搞 搬 搭 摄 摆 摇 摘 摩 摸 撑 撒 撞 播 操 擎 擦 支 收 改 攻 放 政 故 效 敌 敍 敏 救 教 敝 敢 散 敦 敬 数 整 文 斋 斐 斗 料 断 斯 新 方 施 旁 旅 旋 族 旗 无 既 日-旧 早 旭 时 旺 昂 昆 昌 明 昏 易 星 映 春 昨 昭 是 显 晋 晒 晓 晚 晨 普 景 晴 晶 智 暂 暑 暖 暗 暴 曰 曲 更 曼 曾-最 月 有 朋 服 朗 望 朝 期 木 未-札 术 朱 朵 机 杀 杂 权 杉 李 材 村 杜 束 条 来 杨 杯 杰 松 板 极 构 析 林 果 枝 枢 枪 枫 架 柏 某 染 柔 查 柬 柯 柳 柴 标 栏 树 校 样-根 格 桃 案 桌 桑 档 桥 梁 梅 梦 梨 梯 械 梵 检 棉 棋 棒 棚 森 椅 植 椰 楚 楼 概 榜 模 横 檀 次-欣 欧 欲 欺 款 歉 歌 止-武 死 殊 残 段 毁 毅 母 每 毒 比 毕 毛 毫 氏 民 气 水 永 求 汉 汗 汝 江-污 汤 汪 汶 汽 沃 沈 沉 沙 沟 没 沧 河 油 治 沿 泄 泉 泊 法 泡 波 泥 注 泪 泰 泳 泽 泾 洁 洋 洗 洛 洞 洪 洲 活 洽 派 流 浅 测 济 浏 浓 浦 浩 浪 浮 海 涂 消 涉 涛 涨 涯 液 涵 淑 淡 深 混 清 渐 渡 温 港 游 湖 湾 源 溪 滋 滑 滚 满 滥 滨 滴 漂 漏 演 漠 漫 潘 潜 潮 澳 激 灌 火 灭 灯 灰 灵 灾 炉 炎 炮 炸 点 烂 烈 烟 烤 烦 烧 热 焦 然 煞 照 熊 熟 燃 爆 爪 爬 爱 爵-爸 爽 片 版 牌 牙 牛 牠 牧 物 牲 牵 特 牺 犯 状 犹 狂 狐 狗 狠 独 狮 狱 狼 猛 猜 猪 猫 献 猴 玄 率 玉 王 玛 玩 玫 环 现 玲 玻 珊 珍 珠 珥 班 球 理 琉 琪 琴 瑙 瑜 瑞 瑟 瑰 瑶 瓜 瓦 瓶 甘 甚 甜 生 用 田-申 电 男 甸 画 界 留 略 番 疆 疏 疑 疗 疯 疼 病 痕 痛 痴 癸 登 白 百 的 皆 皇 皮 益 监 盖-盘 盛 盟 目 盲 直 相 盼 盾 省 眉 看 真 眠 眼 着 睛 睡 督 瞧 矛 矣 知 短 石 矶 码 砂 砍 研 破 础 硕 硬 确 碍 碎 碗 碟 碧 碰 磁 磨 示 礼 社 祖 祚 祛 祝 神 祥 票 祯 祸 禁 禄 禅 福 离 秀 私 秋 种 科 秒 秘 租 秤 秦 积 称 移 程 稍 税 稣 稳 稿 穆 究 穷 穹 空 穿 突 窗 窝 窭 立 站 竞-章 童 端 竹 笑 笔 笛 符 笨 第 等 筋 筑 答 策 筹 签 简 算 管 箫 箭 箱 篇 篮 簿 籍 米 类 粉 粗 粤 精 糊 糕 糟 系 素 索 紧 紫 累 繁 纠 红 约 级 纪 纬 纯 纲 纳 纵 纷 纸 纽 线 练 组 细-终 绍 经 结 绕 绘 给 络 绝 统 继 绩 绪 续 维 综 绿 缅 缓 编 缘 缚 缩 缪 缴 缸 缺 网 罕 罗 罚 罢 罪 置 署 羊 美 羞 群 羽 翁 翔 翘 翰 翻 翼 耀 老 考 者 而 耍 耐 耗 耳 耶 耻 聊 职 联 聚 聪 肉 肚 股 肥 肩 肯 育 胆 背 胎 胖 胜 胞 胡 胸 能 脆 脑 脚 脱 脸 腊 腓 腔 腰 腿 臣 自 臭 至 致 舌 舍 舒 舞 舟 航 般 舰 船 良 色 艺 艾 节 芝 芦 芬 花 芳 苍 苏 若 苦 英 范 茅 茫 茶 草 荐 荒 荣 药 荷 荼 莉 莎 莫 莱 莲 获 菜 菩 菲 萄 萤 营 萧 萨 落 葛 葡 蒂 蒋 蒙 蒲 蓝 蔕 蔡 薄 薪 藏 藤 虎 虑 虚 虫 虽 蛇 蛋 蛙 蛮 蜂 蜜 蝎 蝶 融 蟹 血 行 街 衡 衣 补 表 袋 被 裁 裂 装 裕 裤 西 要 覆 见 观 规 视 览 觉 角 解 触 言 誉 誓 警 计 订 认 讨 让 训-记 讲 讷 许 论 设 访 证 评 识 诉 词 译 试 诗 诚 话 诞 询 该 详 语 误 说 请 诸 诺 读 课 谁 调 谅 谈 谊 谋 谓 谚 谢 谱 谷 豆 象 豪 貌 贝-负 贡-败 货 质 贪 购 贯 贱 贴 贵 费 贺 贾 资 赋 赌 赏 赐 赖 赚 赛 赞 赠 赢 赤 赫 走 赵-起 超 越 趋 趣 足 跃 跌 跎 跑 距 跟 路 跳 踏 踢 踪 身 躲 车 轨 轩 转 轮-轰 轻 载 较 辅 辆 辈 辉 辑 输 辛 辞 辨 辩 辰 辱 边 达 迁 迅 过 迈 迎 运 近 返 还 这 进-迟 迦 迪 迫 述 迷 迹 追 退-逃 逆 选 逊 透 逐 途 通 逛 逝 速 造 逢 逸 逻 逼 遇 遍 道 遗 遥 遭 遮 避 邀 那 邦 邪 邮 邱 邻 郁 郎 郑 部 郭 都 鄂 酉 配 酒 酷 酸 醉 醒 采 释 里-量 金 鉴 针 钓 钟 钢 钦 钱 钵 铁 铃 铜 铢 铭 银 销 锁 锅 锋 锐 错 锡 锦 键 镇 镑 镜 长 门 闪 闭 问 闰 闲 间 闷 闹 闻 阁 阅 阇 阐 阔 阗 队 防-阶 阻 阿 陀 附-陆 陈 降 限 院 除 险 陪 陵-陷 隆 随 隐 隔 障 难 雄-集 雉 雨 雪 雳 零 雷 雾 需 震 霍 露 霸 霹 青 靖 静 非 靠 面 革 靼 鞋 鞑 韦 韩 音 韵 頞 页 顶 项-须 顽-顿 预 领 颇 频 颗 题 颜 额 风 飘 飞 食 餐 饭 饮 饰 饱 饼 馆 首 香 马 驱 驶 驻 驾 骂 验 骑 骗 骚 骨 高 鬼 魁 魂 魅 魔 鱼 鲁 鲜 鸟 鸡 鸣 鸿 鹅 鹰 鹿 麦 麻 黄 黎 黑 默 鼓 鼠 鼻 齐 齿 龄 龙 龟]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9 〇 一 七 三 九 二 五 八 六 四]},
			punctuation => qr{[﹉﹊﹋﹌ _ ＿ ﹍﹎﹏ ︳︴ \- － ﹣ ‐ – — ︱ ― , ， ﹐ 、 ﹑ ; ； ﹔ \: ： ﹕ ! ！ ﹗ ? ？ ﹖ . ． ﹒ ‥ ︰ … 。 · ＇ ‘ ’ " ＂ “ ” 〝 〞 ( （ ﹙ ︵ ) ） ﹚ ︶ \[ ［ \] ］ \{ ｛ ﹛ ︷ \} ｝ ﹜ ︸ 〈 ︿ 〉 ﹀ 《 ︽ 》 ︾ 「 ﹁ 」 ﹂ 『 ﹃ 』 ﹄ 【 ︻ 】 ︼ 〔 ﹝ ︹ 〕 ﹞ ︺ 〖 〗 ‖ § @ ＠ ﹫ * ＊ ﹡ / ／ \\ ＼ ﹨ \& ＆ ﹠ # ＃ ﹟ % ％ ﹪ ‰ ′ ″ ‵ 〃 ※]},
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
			'medial' => '{0}…{1}',
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}…{1}',
		};
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
						'name' => q(英亩),
						'other' => q({0} 英亩),
					},
					'acre-foot' => {
						'name' => q(英亩英尺),
						'other' => q({0} 英亩英尺),
					},
					'ampere' => {
						'name' => q(安培),
						'other' => q({0} 安培),
					},
					'arc-minute' => {
						'name' => q(角分),
						'other' => q({0} 角分),
					},
					'arc-second' => {
						'name' => q(角秒),
						'other' => q({0} 角秒),
					},
					'astronomical-unit' => {
						'name' => q(天文单位),
						'other' => q({0} 天文单位),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0} 蒲式耳),
					},
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(卡路里),
						'other' => q({0} 卡路里),
					},
					'carat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					'celsius' => {
						'name' => q(摄氏度数),
						'other' => q(摄氏 {0} 度),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					'centimeter' => {
						'name' => q(公分),
						'other' => q({0} 公分),
						'per' => q(每厘米 {0}),
					},
					'century' => {
						'name' => q(世纪),
						'other' => q({0} 个世纪),
					},
					'coordinate' => {
						'east' => q(东经{0}),
						'north' => q(北纬{0}),
						'south' => q(南纬{0}),
						'west' => q(西经{0}),
					},
					'cubic-centimeter' => {
						'name' => q(立方公分),
						'other' => q({0} 立方公分),
						'per' => q(每立方厘米 {0}),
					},
					'cubic-foot' => {
						'name' => q(立方英尺),
						'other' => q({0} 立方英尺),
					},
					'cubic-inch' => {
						'name' => q(立方英寸),
						'other' => q({0} 立方英寸),
					},
					'cubic-kilometer' => {
						'name' => q(立方公里),
						'other' => q({0} 立方公里),
					},
					'cubic-meter' => {
						'name' => q(立方公尺),
						'other' => q({0} 立方公尺),
						'per' => q(每立方米 {0}),
					},
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0} 立方英里),
					},
					'cubic-yard' => {
						'name' => q(立方码),
						'other' => q({0} 立方码),
					},
					'cup' => {
						'name' => q(量杯),
						'other' => q({0} 杯),
					},
					'cup-metric' => {
						'name' => q(公制量杯),
						'other' => q({0} 公制杯),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0} 天),
						'per' => q(每日 {0}),
					},
					'deciliter' => {
						'name' => q(公合),
						'other' => q({0} 公合),
					},
					'decimeter' => {
						'name' => q(公寸),
						'other' => q({0} 公寸),
					},
					'degree' => {
						'name' => q(角度),
						'other' => q({0} 度),
					},
					'fahrenheit' => {
						'name' => q(华氏度数),
						'other' => q(华氏 {0} 度),
					},
					'fathom' => {
						'name' => q(英寻),
						'other' => q({0} 英寻),
					},
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0} 液盎司),
					},
					'foodcalorie' => {
						'name' => q(卡路里),
						'other' => q({0} 大卡),
					},
					'foot' => {
						'name' => q(英尺),
						'other' => q({0} 英尺),
						'per' => q(每呎 {0}),
					},
					'furlong' => {
						'name' => q(化朗),
						'other' => q({0} 化朗),
					},
					'g-force' => {
						'name' => q(G 力),
						'other' => q({0} G 力),
					},
					'gallon' => {
						'name' => q(加仑),
						'other' => q({0} 加仑),
						'per' => q(每加仑 {0}),
					},
					'gallon-imperial' => {
						'name' => q(英制加仑),
						'other' => q({0} 英制加仑),
						'per' => q(每英制加仑 {0}),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0} 吉赫),
					},
					'gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0} 吉瓦),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0} 克),
						'per' => q(每克 {0}),
					},
					'hectare' => {
						'name' => q(公顷),
						'other' => q({0} 公顷),
					},
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0} 公石),
					},
					'hectopascal' => {
						'name' => q(百帕),
						'other' => q({0} 百帕),
					},
					'hertz' => {
						'name' => q(赫兹),
						'other' => q({0} 赫兹),
					},
					'horsepower' => {
						'name' => q(马力),
						'other' => q({0} 匹马力),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0} 小时),
						'per' => q(每小时 {0}),
					},
					'inch' => {
						'name' => q(英寸),
						'other' => q({0} 英寸),
						'per' => q(每吋 {0}),
					},
					'inch-hg' => {
						'name' => q(英寸汞柱),
						'other' => q({0} 英寸汞柱),
					},
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0} 焦耳),
					},
					'karat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					'kelvin' => {
						'name' => q(克耳文),
						'other' => q({0} 克耳文),
					},
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(千卡路里),
						'other' => q({0} 千卡路里),
					},
					'kilogram' => {
						'name' => q(公斤),
						'other' => q({0} 公斤),
						'per' => q(每公斤 {0}),
					},
					'kilohertz' => {
						'name' => q(千赫),
						'other' => q({0} 千赫),
					},
					'kilojoule' => {
						'name' => q(千焦耳),
						'other' => q({0} 千焦耳),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0} 公里),
						'per' => q(每公里 {0}),
					},
					'kilometer-per-hour' => {
						'name' => q(每小时公里),
						'other' => q(每小时 {0} 公里),
					},
					'kilowatt' => {
						'name' => q(千瓦特),
						'other' => q({0} 千瓦特),
					},
					'kilowatt-hour' => {
						'name' => q(千瓦小时),
						'other' => q({0} 千瓦小时),
					},
					'knot' => {
						'name' => q(节),
						'other' => q({0} 节),
					},
					'light-year' => {
						'name' => q(光年),
						'other' => q({0} 光年),
					},
					'liter' => {
						'name' => q(公升),
						'other' => q({0} 公升),
						'per' => q(每公升 {0}),
					},
					'liter-per-100kilometers' => {
						'name' => q(每 100 公里公升),
						'other' => q(每 100 公里 {0} 公升),
					},
					'liter-per-kilometer' => {
						'name' => q(每公里公升),
						'other' => q(每公里 {0} 公升),
					},
					'lux' => {
						'name' => q(勒克斯),
						'other' => q({0} 勒克斯),
					},
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(兆赫),
						'other' => q({0} 兆赫),
					},
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0} 兆升),
					},
					'megawatt' => {
						'name' => q(百万瓦特),
						'other' => q({0} 百万瓦特),
					},
					'meter' => {
						'name' => q(公尺),
						'other' => q({0} 公尺),
						'per' => q(每米 {0}),
					},
					'meter-per-second' => {
						'name' => q(每秒公尺),
						'other' => q(每秒 {0} 米),
					},
					'meter-per-second-squared' => {
						'name' => q(每平方秒公尺),
						'other' => q(每平方秒 {0} 米),
					},
					'metric-ton' => {
						'name' => q(公吨),
						'other' => q({0} 公吨),
					},
					'microgram' => {
						'name' => q(微克),
						'other' => q({0} 微克),
					},
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0} 微米),
					},
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0} 微秒),
					},
					'mile' => {
						'name' => q(英里),
						'other' => q({0} 英里),
					},
					'mile-per-gallon' => {
						'name' => q(每加仑英里),
						'other' => q(每加仑 {0} 英里),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(英里/英制加仑),
						'other' => q({0} 英里/英制加仑),
					},
					'mile-per-hour' => {
						'name' => q(每小时英里),
						'other' => q(每小时 {0} 英里),
					},
					'mile-scandinavian' => {
						'name' => q(斯堪地那维亚英里),
						'other' => q({0} 斯堪地那维亚英里),
					},
					'milliampere' => {
						'name' => q(毫安培),
						'other' => q({0} 毫安培),
					},
					'millibar' => {
						'name' => q(毫巴),
						'other' => q({0} 毫巴),
					},
					'milligram' => {
						'name' => q(毫克),
						'other' => q({0} 毫克),
					},
					'milligram-per-deciliter' => {
						'name' => q(毫克/公合),
						'other' => q({0} 毫克/公合),
					},
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0} 毫升),
					},
					'millimeter' => {
						'name' => q(公厘),
						'other' => q({0} 公厘),
					},
					'millimeter-of-mercury' => {
						'name' => q(毫米汞柱),
						'other' => q({0} 毫米汞柱),
					},
					'millimole-per-liter' => {
						'name' => q(毫摩尔/公升),
						'other' => q({0} 毫摩尔/公升),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0} 毫秒),
					},
					'milliwatt' => {
						'name' => q(毫瓦特),
						'other' => q({0} 毫瓦特),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0} 分钟),
						'per' => q(每分钟 {0}),
					},
					'month' => {
						'name' => q(月),
						'other' => q({0} 个月),
						'per' => q(每月 {0}),
					},
					'nanometer' => {
						'name' => q(奈米),
						'other' => q({0} 奈米),
					},
					'nanosecond' => {
						'name' => q(奈秒),
						'other' => q({0} 奈秒),
					},
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0} 海里),
					},
					'ohm' => {
						'name' => q(欧姆),
						'other' => q({0} 欧姆),
					},
					'ounce' => {
						'name' => q(盎司),
						'other' => q({0} 盎司),
						'per' => q(每安士 {0}),
					},
					'ounce-troy' => {
						'name' => q(金衡盎司),
						'other' => q({0} 金衡盎司),
					},
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0} 秒差距),
					},
					'part-per-million' => {
						'name' => q(百万分率),
						'other' => q({0} 百万分率),
					},
					'per' => {
						'1' => q(每 {1} {0}),
					},
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0} 皮米),
					},
					'pint' => {
						'name' => q(品脱),
						'other' => q({0} 品脱),
					},
					'pint-metric' => {
						'name' => q(公制品脱),
						'other' => q({0} 公制品脱),
					},
					'point' => {
						'name' => q(点),
						'other' => q({0} 点),
					},
					'pound' => {
						'name' => q(磅),
						'other' => q({0} 磅),
						'per' => q(每磅 {0}),
					},
					'pound-per-square-inch' => {
						'name' => q(每平方英寸磅力),
						'other' => q(每平方吋 {0} 磅),
					},
					'quart' => {
						'name' => q(夸脱),
						'other' => q({0} 夸脱),
					},
					'radian' => {
						'name' => q(弧度),
						'other' => q({0} 弧度),
					},
					'revolution' => {
						'name' => q(圈数),
						'other' => q({0} 圈),
					},
					'second' => {
						'name' => q(秒),
						'other' => q({0} 秒),
						'per' => q(每秒 {0}),
					},
					'square-centimeter' => {
						'name' => q(平方公分),
						'other' => q({0} 平方公分),
						'per' => q(每平方厘米 {0}),
					},
					'square-foot' => {
						'name' => q(平方英尺),
						'other' => q({0} 平方英尺),
					},
					'square-inch' => {
						'name' => q(平方英寸),
						'other' => q({0} 平方英寸),
						'per' => q(每平方吋 {0}),
					},
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0} 平方公里),
						'per' => q(每平方公里 {0}),
					},
					'square-meter' => {
						'name' => q(平方公尺),
						'other' => q({0} 平方公尺),
						'per' => q(每平方米 {0}),
					},
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0} 平方英里),
						'per' => q(每平方英里 {0}),
					},
					'square-yard' => {
						'name' => q(平方码),
						'other' => q({0} 平方码),
					},
					'stone' => {
						'name' => q(英石),
						'other' => q({0} 英石),
					},
					'tablespoon' => {
						'name' => q(汤匙),
						'other' => q({0} 汤匙),
					},
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0} 茶匙),
					},
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(英吨),
						'other' => q({0} 英吨),
					},
					'volt' => {
						'name' => q(伏特),
						'other' => q({0} 伏特),
					},
					'watt' => {
						'name' => q(瓦特),
						'other' => q({0} 瓦特),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0} 周),
						'per' => q(每星期 {0}),
					},
					'yard' => {
						'name' => q(码),
						'other' => q({0} 码),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0} 年),
						'per' => q(每年 {0}),
					},
				},
				'narrow' => {
					'acre' => {
						'other' => q({0}英亩),
					},
					'acre-foot' => {
						'other' => q({0}ac-ft),
					},
					'ampere' => {
						'other' => q({0}A),
					},
					'arc-minute' => {
						'other' => q({0}角分),
					},
					'arc-second' => {
						'other' => q({0}角秒),
					},
					'astronomical-unit' => {
						'other' => q({0}au),
					},
					'bit' => {
						'other' => q({0}bit),
					},
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0}bu),
					},
					'byte' => {
						'other' => q({0}byte),
					},
					'calorie' => {
						'other' => q({0}卡),
					},
					'carat' => {
						'other' => q({0}CD),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'other' => q({0}cL),
					},
					'centimeter' => {
						'name' => q(公分),
						'other' => q({0} 公分),
					},
					'coordinate' => {
						'east' => q(东经{0}),
						'north' => q(北纬{0}),
						'south' => q(南纬{0}),
						'west' => q(西经{0}),
					},
					'cubic-centimeter' => {
						'other' => q({0}cm³),
					},
					'cubic-foot' => {
						'other' => q({0}ft³),
					},
					'cubic-inch' => {
						'other' => q({0}in³),
					},
					'cubic-kilometer' => {
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'other' => q({0}m³),
					},
					'cubic-mile' => {
						'other' => q({0}立方英里),
					},
					'cubic-yard' => {
						'other' => q({0}yd³),
					},
					'cup' => {
						'other' => q({0}c),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0} 天),
					},
					'deciliter' => {
						'other' => q({0}dL),
					},
					'decimeter' => {
						'other' => q({0}dm),
					},
					'degree' => {
						'other' => q({0}度),
					},
					'fahrenheit' => {
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(英寻),
						'other' => q({0}fm),
					},
					'fluid-ounce' => {
						'other' => q({0}fl-oz),
					},
					'foodcalorie' => {
						'other' => q({0}大卡),
					},
					'foot' => {
						'other' => q({0}呎),
					},
					'furlong' => {
						'name' => q(化朗),
						'other' => q({0}化朗),
					},
					'g-force' => {
						'other' => q({0}G),
					},
					'gallon' => {
						'other' => q({0}gal),
					},
					'gigabit' => {
						'other' => q({0}Gb),
					},
					'gigabyte' => {
						'other' => q({0}GB),
					},
					'gigahertz' => {
						'other' => q({0}GHz),
					},
					'gigawatt' => {
						'other' => q({0}GW),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0} 克),
					},
					'hectare' => {
						'other' => q({0}公顷),
					},
					'hectoliter' => {
						'other' => q({0}hL),
					},
					'hectopascal' => {
						'other' => q({0}百帕),
					},
					'hertz' => {
						'other' => q({0}Hz),
					},
					'horsepower' => {
						'other' => q({0}匹),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0} 小时),
					},
					'inch' => {
						'other' => q({0}吋),
					},
					'inch-hg' => {
						'other' => q({0}″ Hg),
					},
					'joule' => {
						'other' => q({0}焦),
					},
					'karat' => {
						'other' => q({0}kt),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0}°K),
					},
					'kilobit' => {
						'other' => q({0}kb),
					},
					'kilobyte' => {
						'other' => q({0}kB),
					},
					'kilocalorie' => {
						'other' => q({0}千卡),
					},
					'kilogram' => {
						'name' => q(公斤),
						'other' => q({0} 公斤),
					},
					'kilohertz' => {
						'other' => q({0}kHz),
					},
					'kilojoule' => {
						'other' => q({0}千焦耳),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0} 公里),
					},
					'kilometer-per-hour' => {
						'name' => q(公里/小时),
						'other' => q({0}公里/小时),
					},
					'kilowatt' => {
						'other' => q({0}千瓦),
					},
					'kilowatt-hour' => {
						'other' => q({0}kWh),
					},
					'light-year' => {
						'other' => q({0}光年),
					},
					'liter' => {
						'name' => q(公升),
						'other' => q({0} 升),
					},
					'liter-per-100kilometers' => {
						'name' => q(升/100公里),
						'other' => q(每100公里{0}升),
					},
					'liter-per-kilometer' => {
						'other' => q({0}L/km),
					},
					'lux' => {
						'other' => q({0}lx),
					},
					'megabit' => {
						'other' => q({0}Mb),
					},
					'megabyte' => {
						'other' => q({0}MB),
					},
					'megahertz' => {
						'other' => q({0}MHz),
					},
					'megaliter' => {
						'other' => q({0}ML),
					},
					'megawatt' => {
						'other' => q({0}MW),
					},
					'meter' => {
						'name' => q(公尺),
						'other' => q({0} 公尺),
					},
					'meter-per-second' => {
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'other' => q({0}t),
					},
					'microgram' => {
						'other' => q({0}µg),
					},
					'micrometer' => {
						'other' => q({0}µm),
					},
					'microsecond' => {
						'other' => q({0}μs),
					},
					'mile' => {
						'other' => q({0}英里),
					},
					'mile-per-gallon' => {
						'other' => q({0}mpg),
					},
					'mile-per-hour' => {
						'other' => q({0}英里/小时),
					},
					'milliampere' => {
						'other' => q({0}mA),
					},
					'millibar' => {
						'other' => q({0}毫巴),
					},
					'milligram' => {
						'other' => q({0}mg),
					},
					'milliliter' => {
						'other' => q({0}mL),
					},
					'millimeter' => {
						'name' => q(公厘),
						'other' => q({0} 公厘),
					},
					'millimeter-of-mercury' => {
						'other' => q({0}mmHg),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0} 毫秒),
					},
					'milliwatt' => {
						'other' => q({0}mW),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0} 分钟),
					},
					'month' => {
						'name' => q(月),
						'other' => q({0} 个月),
					},
					'nanometer' => {
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'other' => q({0}nmi),
					},
					'ohm' => {
						'other' => q({0}Ω),
					},
					'ounce' => {
						'other' => q({0}盎司),
					},
					'ounce-troy' => {
						'other' => q({0}oz-t),
					},
					'parsec' => {
						'other' => q({0}pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'other' => q({0}皮米),
					},
					'pint' => {
						'other' => q({0}pt),
					},
					'pound' => {
						'other' => q({0}磅),
					},
					'pound-per-square-inch' => {
						'other' => q({0}psi),
					},
					'quart' => {
						'other' => q({0}qt),
					},
					'radian' => {
						'other' => q({0}弧度),
					},
					'second' => {
						'name' => q(秒),
						'other' => q({0} 秒),
					},
					'square-centimeter' => {
						'other' => q({0}cm²),
					},
					'square-foot' => {
						'other' => q({0}平方英尺),
					},
					'square-inch' => {
						'other' => q({0}in²),
					},
					'square-kilometer' => {
						'other' => q({0}km²),
					},
					'square-meter' => {
						'other' => q({0}m²),
					},
					'square-mile' => {
						'other' => q({0}平方英里),
					},
					'square-yard' => {
						'other' => q({0}yd²),
					},
					'stone' => {
						'name' => q(英石),
						'other' => q({0}st),
					},
					'tablespoon' => {
						'other' => q({0}匙),
					},
					'teaspoon' => {
						'other' => q({0}tsp),
					},
					'terabit' => {
						'other' => q({0}Tb),
					},
					'terabyte' => {
						'other' => q({0}TB),
					},
					'ton' => {
						'other' => q({0}tn),
					},
					'volt' => {
						'other' => q({0}V),
					},
					'watt' => {
						'other' => q({0}瓦特),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0} 周),
					},
					'yard' => {
						'other' => q({0}码),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0} 年),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(英亩),
						'other' => q({0} 英亩),
					},
					'acre-foot' => {
						'name' => q(英亩英尺),
						'other' => q({0} 英亩英尺),
					},
					'ampere' => {
						'name' => q(安培),
						'other' => q({0} 安培),
					},
					'arc-minute' => {
						'name' => q(角分),
						'other' => q({0} 角分),
					},
					'arc-second' => {
						'name' => q(角秒),
						'other' => q({0} 角秒),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'other' => q({0} 天文单位),
					},
					'bit' => {
						'name' => q(bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(bu),
						'other' => q({0} 蒲式耳),
					},
					'byte' => {
						'name' => q(byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(卡路里),
						'other' => q({0} 卡),
					},
					'carat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					'celsius' => {
						'name' => q(摄氏),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0} 厘升),
					},
					'centimeter' => {
						'name' => q(公分),
						'other' => q({0} 公分),
						'per' => q(每厘米{0}),
					},
					'century' => {
						'name' => q(世纪),
						'other' => q({0} 世纪),
					},
					'coordinate' => {
						'east' => q(东经{0}),
						'north' => q(北纬{0}),
						'south' => q(南纬{0}),
						'west' => q(西经{0}),
					},
					'cubic-centimeter' => {
						'name' => q(立方公分),
						'other' => q({0} 立方公分),
						'per' => q(每立方厘米{0}),
					},
					'cubic-foot' => {
						'name' => q(立方英尺),
						'other' => q({0} 立方英尺),
					},
					'cubic-inch' => {
						'name' => q(立方英寸),
						'other' => q({0} 立方英寸),
					},
					'cubic-kilometer' => {
						'name' => q(立方公里),
						'other' => q({0} 立方公里),
					},
					'cubic-meter' => {
						'name' => q(立方公尺),
						'other' => q({0} 立方公尺),
						'per' => q(每立方米{0}),
					},
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0} 立方英里),
					},
					'cubic-yard' => {
						'name' => q(立方码),
						'other' => q({0} 立方码),
					},
					'cup' => {
						'name' => q(量杯),
						'other' => q({0} 杯),
					},
					'cup-metric' => {
						'name' => q(公制量杯),
						'other' => q({0} 公制杯),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0} 天),
						'per' => q(每日{0}),
					},
					'deciliter' => {
						'name' => q(公合),
						'other' => q({0} 公合),
					},
					'decimeter' => {
						'name' => q(公寸),
						'other' => q({0} 公寸),
					},
					'degree' => {
						'name' => q(角度),
						'other' => q({0} 度),
					},
					'fahrenheit' => {
						'name' => q(华氏),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'other' => q({0} 英寻),
					},
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0} 液盎司),
					},
					'foodcalorie' => {
						'name' => q(大卡),
						'other' => q({0} 大卡),
					},
					'foot' => {
						'name' => q(英尺),
						'other' => q({0} 呎),
						'per' => q(每呎{0}),
					},
					'furlong' => {
						'name' => q(化朗),
						'other' => q({0} 化朗),
					},
					'g-force' => {
						'name' => q(G 力),
						'other' => q({0} G 力),
					},
					'gallon' => {
						'name' => q(加仑),
						'other' => q({0} 加仑),
						'per' => q(每加仑{0}),
					},
					'gallon-imperial' => {
						'name' => q(英制加仑),
						'other' => q({0} 英制加仑),
						'per' => q(每英制加仑{0}),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0} 吉赫),
					},
					'gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0} 吉瓦),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0} 克),
						'per' => q(每克{0}),
					},
					'hectare' => {
						'name' => q(公顷),
						'other' => q({0} 公顷),
					},
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0} 公石),
					},
					'hectopascal' => {
						'name' => q(百帕),
						'other' => q({0} 百帕),
					},
					'hertz' => {
						'name' => q(赫兹),
						'other' => q({0} 赫兹),
					},
					'horsepower' => {
						'name' => q(匹),
						'other' => q({0} 匹),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0} 小时),
						'per' => q(每小时{0}),
					},
					'inch' => {
						'name' => q(英寸),
						'other' => q({0} 吋),
						'per' => q(每吋{0}),
					},
					'inch-hg' => {
						'name' => q(英寸汞柱),
						'other' => q({0} 英寸汞柱),
					},
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0} 焦),
					},
					'karat' => {
						'name' => q(克拉),
						'other' => q({0} 克拉),
					},
					'kelvin' => {
						'name' => q(K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0} 千卡),
					},
					'kilogram' => {
						'name' => q(公斤),
						'other' => q({0} 公斤),
						'per' => q(每公斤{0}),
					},
					'kilohertz' => {
						'name' => q(千赫),
						'other' => q({0} 千赫),
					},
					'kilojoule' => {
						'name' => q(千焦耳),
						'other' => q({0} 千焦),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0} 公里),
						'per' => q(每公里{0}),
					},
					'kilometer-per-hour' => {
						'name' => q(公里/小时),
						'other' => q(每小时{0}公里),
					},
					'kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0} 千瓦),
					},
					'kilowatt-hour' => {
						'name' => q(千瓦小时),
						'other' => q({0} 千瓦小时),
					},
					'knot' => {
						'name' => q(节),
						'other' => q({0} 节),
					},
					'light-year' => {
						'name' => q(光年),
						'other' => q({0} 光年),
					},
					'liter' => {
						'name' => q(公升),
						'other' => q({0} 升),
						'per' => q(每升{0}),
					},
					'liter-per-100kilometers' => {
						'name' => q(升/100 公里),
						'other' => q(每100公里 {0} 升),
					},
					'liter-per-kilometer' => {
						'name' => q(公升/公里),
						'other' => q(每公里{0}公升),
					},
					'lux' => {
						'name' => q(勒克斯),
						'other' => q({0} 勒克斯),
					},
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(兆赫),
						'other' => q({0} 兆赫),
					},
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0} 兆升),
					},
					'megawatt' => {
						'name' => q(百万瓦),
						'other' => q({0} 百万瓦),
					},
					'meter' => {
						'name' => q(公尺),
						'other' => q({0} 公尺),
						'per' => q(每米{0}),
					},
					'meter-per-second' => {
						'name' => q(公尺/秒),
						'other' => q(每秒{0}米),
					},
					'meter-per-second-squared' => {
						'name' => q(公尺/平方秒),
						'other' => q(每平方秒{0}米),
					},
					'metric-ton' => {
						'name' => q(公吨),
						'other' => q({0} 公吨),
					},
					'microgram' => {
						'name' => q(微克),
						'other' => q({0} 微克),
					},
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0} 微米),
					},
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0} 微秒),
					},
					'mile' => {
						'name' => q(英里),
						'other' => q({0} 英里),
					},
					'mile-per-gallon' => {
						'name' => q(英里/加仑),
						'other' => q(每加仑{0}英里),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(英里/英制加仑),
						'other' => q({0} 英里/英制加仑),
					},
					'mile-per-hour' => {
						'name' => q(英里/小时),
						'other' => q(每小时{0}英里),
					},
					'mile-scandinavian' => {
						'name' => q(斯堪地那维亚英里),
						'other' => q({0} 斯堪地那维亚英里),
					},
					'milliampere' => {
						'name' => q(毫安培),
						'other' => q({0} 毫安培),
					},
					'millibar' => {
						'name' => q(毫巴),
						'other' => q({0} 毫巴),
					},
					'milligram' => {
						'name' => q(毫克),
						'other' => q({0} 毫克),
					},
					'milligram-per-deciliter' => {
						'name' => q(毫克/公合),
						'other' => q({0} 毫克/公合),
					},
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0} 毫升),
					},
					'millimeter' => {
						'name' => q(公厘),
						'other' => q({0} 公厘),
					},
					'millimeter-of-mercury' => {
						'name' => q(毫米汞柱),
						'other' => q({0} 毫米汞柱),
					},
					'millimole-per-liter' => {
						'name' => q(毫摩尔/公升),
						'other' => q({0} 毫摩尔/公升),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0} 毫秒),
					},
					'milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0} 毫瓦),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0} 分钟),
						'per' => q(每分钟{0}),
					},
					'month' => {
						'name' => q(月),
						'other' => q({0} 个月),
						'per' => q(每月{0}),
					},
					'nanometer' => {
						'name' => q(奈米),
						'other' => q({0} 奈米),
					},
					'nanosecond' => {
						'name' => q(奈秒),
						'other' => q({0} 奈秒),
					},
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0} 海里),
					},
					'ohm' => {
						'name' => q(欧姆),
						'other' => q({0} 欧姆),
					},
					'ounce' => {
						'name' => q(盎司),
						'other' => q({0} 盎司),
						'per' => q(每安士{0}),
					},
					'ounce-troy' => {
						'name' => q(金衡盎司),
						'other' => q({0} 金衡盎司),
					},
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0} 秒差距),
					},
					'part-per-million' => {
						'name' => q(百万分率),
						'other' => q({0} 百万分率),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0} 皮米),
					},
					'pint' => {
						'name' => q(品脱),
						'other' => q({0} 品脱),
					},
					'pint-metric' => {
						'name' => q(公制品脱),
						'other' => q({0} 公制品脱),
					},
					'point' => {
						'name' => q(点),
						'other' => q({0} 点),
					},
					'pound' => {
						'name' => q(磅),
						'other' => q({0} 磅),
						'per' => q(每磅{0}),
					},
					'pound-per-square-inch' => {
						'name' => q(磅力/平方英寸),
						'other' => q(每平方吋{0}磅),
					},
					'quart' => {
						'name' => q(夸脱),
						'other' => q({0} 夸脱),
					},
					'radian' => {
						'name' => q(弧度),
						'other' => q({0} 弧度),
					},
					'revolution' => {
						'name' => q(圈数),
						'other' => q({0} 圈),
					},
					'second' => {
						'name' => q(秒),
						'other' => q({0} 秒),
						'per' => q(每秒{0}),
					},
					'square-centimeter' => {
						'name' => q(平方公分),
						'other' => q({0} 平方公分),
						'per' => q(每平方厘米{0}),
					},
					'square-foot' => {
						'name' => q(平方英尺),
						'other' => q({0} 平方英尺),
					},
					'square-inch' => {
						'name' => q(平方英寸),
						'other' => q({0} 平方英寸),
						'per' => q(每平方吋{0}),
					},
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0} 平方公里),
						'per' => q(每平方公里{0}),
					},
					'square-meter' => {
						'name' => q(平方公尺),
						'other' => q({0} 平方公尺),
						'per' => q(每平方米{0}),
					},
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0} 平方英里),
						'per' => q(每平方英里{0}),
					},
					'square-yard' => {
						'name' => q(平方码),
						'other' => q({0} 平方码),
					},
					'stone' => {
						'name' => q(st),
						'other' => q({0} 英石),
					},
					'tablespoon' => {
						'name' => q(汤匙),
						'other' => q({0} 汤匙),
					},
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0} 茶匙),
					},
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(英吨),
						'other' => q({0} 英吨),
					},
					'volt' => {
						'name' => q(伏特),
						'other' => q({0} 伏),
					},
					'watt' => {
						'name' => q(瓦特),
						'other' => q({0} 瓦),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0} 周),
						'per' => q(每周{0}),
					},
					'yard' => {
						'name' => q(码),
						'other' => q({0} 码),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0} 年),
						'per' => q(每年{0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:系|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:唔系|no|n)$' }
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
	default		=> 'hanidec',
);

has traditional_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hans',
);

has finance_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'hansfin',
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
		'hanidec' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(非数值),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
		},
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(非数值),
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
					'other' => '0',
				},
				'10000' => {
					'other' => '0万',
				},
				'100000' => {
					'other' => '00万',
				},
				'1000000' => {
					'other' => '000万',
				},
				'10000000' => {
					'other' => '0000万',
				},
				'100000000' => {
					'other' => '0亿',
				},
				'1000000000' => {
					'other' => '00亿',
				},
				'10000000000' => {
					'other' => '000亿',
				},
				'100000000000' => {
					'other' => '0000亿',
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'other' => '0',
				},
				'10000' => {
					'other' => '0万',
				},
				'100000' => {
					'other' => '00万',
				},
				'1000000' => {
					'other' => '000万',
				},
				'10000000' => {
					'other' => '0000万',
				},
				'100000000' => {
					'other' => '0亿',
				},
				'1000000000' => {
					'other' => '00亿',
				},
				'10000000000' => {
					'other' => '000亿',
				},
				'100000000000' => {
					'other' => '0000亿',
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
			'short' => {
				'1000' => {
					'other' => '0',
				},
				'10000' => {
					'other' => '0万',
				},
				'100000' => {
					'other' => '00万',
				},
				'1000000' => {
					'other' => '000万',
				},
				'10000000' => {
					'other' => '0000万',
				},
				'100000000' => {
					'other' => '0亿',
				},
				'1000000000' => {
					'other' => '00亿',
				},
				'10000000000' => {
					'other' => '000亿',
				},
				'100000000000' => {
					'other' => '0000亿',
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
		'hanidec' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
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
			symbol => 'ADP',
			display_name => {
				'currency' => q(安道尔陪士特),
				'other' => q(安道尔陪士特),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(阿拉伯联合大公国迪尔汗),
				'other' => q(阿拉伯联合大公国迪尔汗),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(阿富汗尼 \(1927–2002\)),
				'other' => q(阿富汗尼 \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(阿富汗尼),
				'other' => q(阿富汗尼),
			},
		},
		'ALK' => {
			symbol => 'ALK',
			display_name => {
				'currency' => q(阿尔巴尼亚列克 \(1946–1965\)),
				'other' => q(阿尔巴尼亚列克 \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(阿尔巴尼亚列克),
				'other' => q(阿尔巴尼亚列克),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(亚美尼亚德拉姆),
				'other' => q(亚美尼亚德拉姆),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(荷属安地列斯盾),
				'other' => q(荷属安地列斯盾),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(安哥拉宽扎),
				'other' => q(安哥拉宽扎),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(安哥拉宽扎 \(1977–1990\)),
				'other' => q(安哥拉宽扎 \(1977–1990\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(安哥拉新宽扎 \(1990–2000\)),
				'other' => q(安哥拉新宽扎 \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(安哥拉新调宽扎 \(1995–1999\)),
				'other' => q(安哥拉新调宽扎 \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(阿根廷奥斯特纳尔),
				'other' => q(阿根廷奥斯特纳尔),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(阿根廷披索 \(1970–1983\)),
				'other' => q(阿根廷披索 \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(阿根廷披索 \(1881–1970\)),
				'other' => q(阿根廷披索 \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(阿根廷披索 \(1983–1985\)),
				'other' => q(阿根廷披索 \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(阿根廷披索),
				'other' => q(阿根廷披索),
			},
		},
		'ATS' => {
			symbol => 'ATS',
			display_name => {
				'currency' => q(奥地利先令),
				'other' => q(奥地利先令),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(澳币),
				'other' => q(澳币),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(阿路巴盾),
				'other' => q(阿路巴盾),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(亚塞拜然马纳特 \(1993–2006\)),
				'other' => q(亚塞拜然马纳特 \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(亚塞拜然马纳特),
				'other' => q(亚塞拜然马纳特),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(波士尼亚-赫塞哥维纳第纳尔),
				'other' => q(波士尼亚-赫塞哥维纳第纳尔),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(波士尼亚-赫塞哥维纳可转换马克),
				'other' => q(波士尼亚-赫塞哥维纳可转换马克),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(波士尼亚-赫塞哥维纳新第纳尔),
				'other' => q(波士尼亚-赫塞哥维纳新第纳尔),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(巴贝多元),
				'other' => q(巴贝多元),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(孟加拉塔卡),
				'other' => q(孟加拉塔卡),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(比利时法郎（可转换）),
				'other' => q(比利时法郎（可转换）),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(比利时法郎),
				'other' => q(比利时法郎),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(比利时法郎（金融）),
				'other' => q(比利时法郎（金融）),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(保加利亚硬列弗),
				'other' => q(保加利亚硬列弗),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(保加利亚社会党列弗),
				'other' => q(保加利亚社会党列弗),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(保加利亚新列弗),
				'other' => q(保加利亚新列弗),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(保加利亚列弗 \(1879–1952\)),
				'other' => q(保加利亚列弗 \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(巴林第纳尔),
				'other' => q(巴林第纳尔),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(蒲隆地法郎),
				'other' => q(蒲隆地法郎),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(百慕达币),
				'other' => q(百慕达币),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(汶莱元),
				'other' => q(汶莱元),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(玻利维亚诺),
				'other' => q(玻利维亚诺),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(玻利维亚玻利维亚诺 \(1863–1963\)),
				'other' => q(玻利维亚玻利维亚诺 \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(玻利维亚披索),
				'other' => q(玻利维亚披索),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(玻利维亚幕多),
				'other' => q(玻利维亚幕多),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(巴西克鲁萨多农瓦 \(1967–1986\)),
				'other' => q(巴西克鲁萨多农瓦 \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(巴西克鲁赛罗 \(1986–1989\)),
				'other' => q(巴西克鲁赛罗 \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(巴西克鲁赛罗 \(1990–1993\)),
				'other' => q(巴西克鲁赛罗 \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(巴西里拉),
				'other' => q(巴西里拉),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(巴西克如尔达农瓦),
				'other' => q(巴西克如尔达农瓦),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(巴西克鲁赛罗 \(1993–1994\)),
				'other' => q(巴西克鲁赛罗 \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(巴西克鲁赛罗 \(1942 –1967\)),
				'other' => q(巴西克鲁赛罗 \(1942 –1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(巴哈马元),
				'other' => q(巴哈马元),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(不丹那特伦),
				'other' => q(不丹那特伦),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(缅甸基雅特),
				'other' => q(缅甸基雅特),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(波札那普拉),
				'other' => q(波札那普拉),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(白俄罗斯新卢布 \(1994–1999\)),
				'other' => q(白俄罗斯新卢布 \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(白俄罗斯卢布),
				'other' => q(白俄罗斯卢布),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(白俄罗斯卢布 \(2000–2016\)),
				'other' => q(白俄罗斯卢布 \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(贝里斯元),
				'other' => q(贝里斯元),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(加币),
				'other' => q(加币),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(刚果法郎),
				'other' => q(刚果法郎),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(欧元 \(WIR\)),
				'other' => q(欧元 \(WIR\)),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(瑞士法郎),
				'other' => q(瑞士法郎),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(法郎 \(WIR\)),
				'other' => q(法郎 \(WIR\)),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(智利埃斯库多),
				'other' => q(智利埃斯库多),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(卡林油达佛曼跎),
				'other' => q(卡林油达佛曼跎),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(智利披索),
				'other' => q(智利披索),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(人民币 \(离岸\)),
				'other' => q(人民币 \(离岸\)),
			},
		},
		'CNX' => {
			symbol => 'CNX',
		},
		'CNY' => {
			symbol => '￥',
			display_name => {
				'currency' => q(人民币),
				'other' => q(人民币),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(哥伦比亚披索),
				'other' => q(哥伦比亚披索),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(哥伦比亚币 \(COU\)),
				'other' => q(哥伦比亚币 \(COU\)),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(哥斯大黎加科朗),
				'other' => q(哥斯大黎加科朗),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(旧塞尔维亚第纳尔),
				'other' => q(旧塞尔维亚第纳尔),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(捷克斯洛伐克硬克朗),
				'other' => q(捷克斯洛伐克硬克朗),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(古巴可转换披索),
				'other' => q(古巴可转换披索),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(古巴披索),
				'other' => q(古巴披索),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(维德角埃斯库多),
				'other' => q(维德角埃斯库多),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(赛普勒斯镑),
				'other' => q(赛普勒斯镑),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(捷克克朗),
				'other' => q(捷克克朗),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(东德奥斯特马克),
				'other' => q(东德奥斯特马克),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(德国马克),
				'other' => q(德国马克),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(吉布地法郎),
				'other' => q(吉布地法郎),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(丹麦克朗),
				'other' => q(丹麦克朗),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(多明尼加披索),
				'other' => q(多明尼加披索),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(阿尔及利亚第纳尔),
				'other' => q(阿尔及利亚第纳尔),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(厄瓜多苏克雷),
				'other' => q(厄瓜多苏克雷),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(厄瓜多尔由里达瓦康斯坦 \(UVC\)),
				'other' => q(厄瓜多尔由里达瓦康斯坦 \(UVC\)),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(爱沙尼亚克朗),
				'other' => q(爱沙尼亚克朗),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(埃及镑),
				'other' => q(埃及镑),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(厄立特里亚纳克法),
				'other' => q(厄立特里亚纳克法),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(西班牙比塞塔（会计单位）),
				'other' => q(西班牙比塞塔（会计单位）),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(西班牙比塞塔（可转换会计单位）),
				'other' => q(西班牙比塞塔（可转换会计单位）),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(西班牙陪士特),
				'other' => q(西班牙陪士特),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(衣索比亚比尔),
				'other' => q(衣索比亚比尔),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(欧元),
				'other' => q(欧元),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(芬兰马克),
				'other' => q(芬兰马克),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(斐济元),
				'other' => q(斐济元),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(福克兰群岛镑),
				'other' => q(福克兰群岛镑),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(法国法郎),
				'other' => q(法国法郎),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(英镑),
				'other' => q(英镑),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(乔治亚库旁拉里),
				'other' => q(乔治亚库旁拉里),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(乔治亚拉里),
				'other' => q(乔治亚拉里),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(迦纳赛地 \(1979–2007\)),
				'other' => q(迦纳赛地 \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(迦纳塞地),
				'other' => q(迦纳塞地),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(直布罗陀镑),
				'other' => q(直布罗陀镑),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(甘比亚达拉西),
				'other' => q(甘比亚达拉西),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(几内亚法郎),
				'other' => q(几内亚法郎),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(几内亚西里),
				'other' => q(几内亚西里),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(赤道几内亚埃奎勒),
				'other' => q(赤道几内亚埃奎勒),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(希腊德拉克马),
				'other' => q(希腊德拉克马),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(瓜地马拉格查尔),
				'other' => q(瓜地马拉格查尔),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(葡属几内亚埃斯库多),
				'other' => q(葡属几内亚埃斯库多),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(几内亚比索披索),
				'other' => q(几内亚比索披索),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(圭亚那元),
				'other' => q(圭亚那元),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(港币),
				'other' => q(港币),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(洪都拉斯伦皮拉),
				'other' => q(洪都拉斯伦皮拉),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(克罗埃西亚第纳尔),
				'other' => q(克罗埃西亚第纳尔),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(克罗埃西亚库纳),
				'other' => q(克罗埃西亚库纳),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(海地古德),
				'other' => q(海地古德),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(匈牙利福林),
				'other' => q(匈牙利福林),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(印尼盾),
				'other' => q(印尼盾),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(爱尔兰镑),
				'other' => q(爱尔兰镑),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(以色列镑),
				'other' => q(以色列镑),
			},
		},
		'ILR' => {
			symbol => 'ILR',
			display_name => {
				'currency' => q(以色列谢克尔 \(1980–1985\)),
				'other' => q(以色列谢克尔 \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(以色列新谢克尔),
				'other' => q(以色列新谢克尔),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(印度卢比),
				'other' => q(印度卢比),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(伊拉克第纳尔),
				'other' => q(伊拉克第纳尔),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(伊朗里亚尔),
				'other' => q(伊朗里亚尔),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(冰岛克朗 \(1918–1981\)),
				'other' => q(冰岛克朗 \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(冰岛克朗),
				'other' => q(冰岛克朗),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(义大利里拉),
				'other' => q(义大利里拉),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(牙买加元),
				'other' => q(牙买加元),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(约旦第纳尔),
				'other' => q(约旦第纳尔),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(日圆),
				'other' => q(日圆),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(肯尼亚先令),
				'other' => q(肯尼亚先令),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(吉尔吉斯索姆),
				'other' => q(吉尔吉斯索姆),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(柬埔寨瑞尔),
				'other' => q(柬埔寨瑞尔),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(科摩罗法郎),
				'other' => q(科摩罗法郎),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(北韩圆),
				'other' => q(北韩圆),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(南韩圜),
				'other' => q(南韩圜),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(南韩圆),
				'other' => q(南韩圆),
			},
		},
		'KRW' => {
			symbol => '￦',
			display_name => {
				'currency' => q(韩圆),
				'other' => q(韩圆),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(科威特第纳尔),
				'other' => q(科威特第纳尔),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(开曼群岛元),
				'other' => q(开曼群岛元),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(卡扎克斯坦坦吉),
				'other' => q(卡扎克斯坦坦吉),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(寮国基普),
				'other' => q(寮国基普),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(黎巴嫩镑),
				'other' => q(黎巴嫩镑),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(斯里兰卡卢比),
				'other' => q(斯里兰卡卢比),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(赖比瑞亚元),
				'other' => q(赖比瑞亚元),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(赖索托洛蒂),
				'other' => q(赖索托洛蒂),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(立陶宛立特),
				'other' => q(立陶宛立特),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(立陶宛特罗),
				'other' => q(立陶宛特罗),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(卢森堡可兑换法郎),
				'other' => q(卢森堡可兑换法郎),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(卢森堡法郎),
				'other' => q(卢森堡法郎),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(卢森堡金融法郎),
				'other' => q(卢森堡金融法郎),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(拉脱维亚拉特银币),
				'other' => q(拉脱维亚拉特银币),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(拉脱维亚卢布),
				'other' => q(拉脱维亚卢布),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(利比亚第纳尔),
				'other' => q(利比亚第纳尔),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(摩洛哥迪拉姆),
				'other' => q(摩洛哥迪拉姆),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(摩洛哥法郎),
				'other' => q(摩洛哥法郎),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(摩纳哥法郎),
				'other' => q(摩纳哥法郎),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(摩尔多瓦券),
				'other' => q(摩尔多瓦券),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(摩杜云列伊),
				'other' => q(摩杜云列伊),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(马达加斯加阿里亚里),
				'other' => q(马达加斯加阿里亚里),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(马达加斯加法郎),
				'other' => q(马达加斯加法郎),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(马其顿第纳尔),
				'other' => q(马其顿第纳尔),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(马其顿第纳尔 \(1992–1993\)),
				'other' => q(马其顿第纳尔 \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(马里法郎),
				'other' => q(马里法郎),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(缅甸元),
				'other' => q(缅甸元),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(蒙古图格里克),
				'other' => q(蒙古图格里克),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(澳门元),
				'other' => q(澳门元),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(茅利塔尼亚乌吉亚 \(1973–2017\)),
				'other' => q(茅利塔尼亚乌吉亚 \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(茅利塔尼亚乌吉亚),
				'other' => q(茅利塔尼亚乌吉亚),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(马尔他里拉),
				'other' => q(马尔他里拉),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(马尔他镑),
				'other' => q(马尔他镑),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(模里西斯卢比),
				'other' => q(模里西斯卢比),
			},
		},
		'MVP' => {
			symbol => 'MVP',
			display_name => {
				'currency' => q(马尔地夫卢比),
				'other' => q(马尔地夫卢比),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(马尔地夫卢非亚),
				'other' => q(马尔地夫卢非亚),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(马拉维克瓦查),
				'other' => q(马拉维克瓦查),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(墨西哥披索),
				'other' => q(墨西哥披索),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(墨西哥银披索 \(1861–1992\)),
				'other' => q(墨西哥银披索 \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(墨西哥转换单位 \(UDI\)),
				'other' => q(墨西哥转换单位 \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(马来西亚令吉),
				'other' => q(马来西亚令吉),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(莫三比克埃斯库多),
				'other' => q(莫三比克埃斯库多),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(莫三比克梅蒂卡尔 \(1980–2006\)),
				'other' => q(莫三比克梅蒂卡尔 \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(莫三比克梅蒂卡尔),
				'other' => q(莫三比克梅蒂卡尔),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(纳米比亚元),
				'other' => q(纳米比亚元),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(奈及利亚奈拉),
				'other' => q(奈及利亚奈拉),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(尼加拉瓜科多巴),
				'other' => q(尼加拉瓜科多巴),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(尼加拉瓜金科多巴),
				'other' => q(尼加拉瓜金科多巴),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(荷兰盾),
				'other' => q(荷兰盾),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(挪威克朗),
				'other' => q(挪威克朗),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(尼泊尔卢比),
				'other' => q(尼泊尔卢比),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(纽西兰币),
				'other' => q(纽西兰币),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(阿曼里亚尔),
				'other' => q(阿曼里亚尔),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(巴拿马巴波亚),
				'other' => q(巴拿马巴波亚),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(秘鲁因蒂),
				'other' => q(秘鲁因蒂),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(秘鲁太阳币),
				'other' => q(秘鲁太阳币),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(秘鲁索尔 \(1863–1965\)),
				'other' => q(秘鲁索尔 \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(巴布亚纽几内亚基那),
				'other' => q(巴布亚纽几内亚基那),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(菲律宾披索),
				'other' => q(菲律宾披索),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(巴基斯坦卢比),
				'other' => q(巴基斯坦卢比),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(波兰兹罗提),
				'other' => q(波兰兹罗提),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(波兰兹罗提 \(1950–1995\)),
				'other' => q(波兰兹罗提 \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(葡萄牙埃斯库多),
				'other' => q(葡萄牙埃斯库多),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(巴拉圭瓜拉尼),
				'other' => q(巴拉圭瓜拉尼),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(卡达里亚尔),
				'other' => q(卡达里亚尔),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(罗德西亚元),
				'other' => q(罗德西亚元),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(旧罗马尼亚列伊),
				'other' => q(旧罗马尼亚列伊),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(罗马尼亚列伊),
				'other' => q(罗马尼亚列伊),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(塞尔维亚戴纳),
				'other' => q(塞尔维亚戴纳),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(俄罗斯卢布),
				'other' => q(俄罗斯卢布),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(俄罗斯卢布 \(1991–1998\)),
				'other' => q(俄罗斯卢布 \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(卢安达法郎),
				'other' => q(卢安达法郎),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(沙乌地里亚尔),
				'other' => q(沙乌地里亚尔),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(索罗门群岛元),
				'other' => q(索罗门群岛元),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(塞席尔卢比),
				'other' => q(塞席尔卢比),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(苏丹第纳尔),
				'other' => q(苏丹第纳尔),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(苏丹镑),
				'other' => q(苏丹镑),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(旧苏丹镑),
				'other' => q(旧苏丹镑),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(瑞典克朗),
				'other' => q(瑞典克朗),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(新加坡币),
				'other' => q(新加坡币),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(圣赫勒拿镑),
				'other' => q(圣赫勒拿镑),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(斯洛维尼亚托勒),
				'other' => q(斯洛维尼亚托勒),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(斯洛伐克克朗),
				'other' => q(斯洛伐克克朗),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(狮子山利昂),
				'other' => q(狮子山利昂),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(索马利亚先令),
				'other' => q(索马利亚先令),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(苏利南元),
				'other' => q(苏利南元),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(苏利南基尔),
				'other' => q(苏利南基尔),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(南苏丹镑),
				'other' => q(南苏丹镑),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(圣多美岛和普林西比岛多布拉 \(1977–2017\)),
				'other' => q(圣多美岛和普林西比岛多布拉 \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(圣多美岛和普林西比岛多布拉),
				'other' => q(圣多美岛和普林西比岛多布拉),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(苏联卢布),
				'other' => q(苏联卢布),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(萨尔瓦多科郎),
				'other' => q(萨尔瓦多科郎),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(叙利亚镑),
				'other' => q(叙利亚镑),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(史瓦济兰里朗吉尼),
				'other' => q(史瓦济兰里朗吉尼),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(泰铢),
				'other' => q(泰铢),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(塔吉克卢布),
				'other' => q(塔吉克卢布),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(塔吉克索莫尼),
				'other' => q(塔吉克索莫尼),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(土库曼马纳特 \(1993–2009\)),
				'other' => q(土库曼马纳特 \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(土库曼马纳特),
				'other' => q(土库曼马纳特),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(突尼西亚第纳尔),
				'other' => q(突尼西亚第纳尔),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(东加潘加),
				'other' => q(东加潘加),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(帝汶埃斯库多),
				'other' => q(帝汶埃斯库多),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(土耳其里拉),
				'other' => q(土耳其里拉),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(新土耳其里拉),
				'other' => q(新土耳其里拉),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(千里达及托巴哥元),
				'other' => q(千里达及托巴哥元),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(新台币),
				'other' => q(新台币),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(坦尚尼亚先令),
				'other' => q(坦尚尼亚先令),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(乌克兰格里夫纳),
				'other' => q(乌克兰格里夫纳),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(乌克兰卡本瓦那兹),
				'other' => q(乌克兰卡本瓦那兹),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(乌干达先令 \(1966–1987\)),
				'other' => q(乌干达先令 \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(乌干达先令),
				'other' => q(乌干达先令),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(美元),
				'other' => q(美元),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(美元（次日）),
				'other' => q(美元（次日）),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(美元（当日）),
				'other' => q(美元（当日）),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(乌拉圭披索（指数单位）),
				'other' => q(乌拉圭披索（指数单位）),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(乌拉圭披索 \(1975–1993\)),
				'other' => q(乌拉圭披索 \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(乌拉圭披索),
				'other' => q(乌拉圭披索),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(乌兹别克索姆),
				'other' => q(乌兹别克索姆),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(委内瑞拉玻利瓦 \(1871–2008\)),
				'other' => q(委内瑞拉玻利瓦 \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(委内瑞拉玻利瓦),
				'other' => q(委内瑞拉玻利瓦),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(越南盾),
				'other' => q(越南盾),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(越南盾 \(1978–1985\)),
				'other' => q(越南盾 \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(万那杜瓦图),
				'other' => q(万那杜瓦图),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(西萨摩亚塔拉),
				'other' => q(西萨摩亚塔拉),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(法郎 \(CFA–BEAC\)),
				'other' => q(法郎 \(CFA–BEAC\)),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(白银),
				'other' => q(白银),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(黄金),
				'other' => q(黄金),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(欧洲综合单位),
				'other' => q(欧洲综合单位),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(欧洲货币单位 \(XBB\)),
				'other' => q(欧洲货币单位 \(XBB\)),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(欧洲会计单位 \(XBC\)),
				'other' => q(欧洲会计单位 \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(欧洲会计单位 \(XBD\)),
				'other' => q(欧洲会计单位 \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(格瑞那达元),
				'other' => q(格瑞那达元),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(特殊提款权),
				'other' => q(特殊提款权),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(欧洲货币单位 \(XEU\)),
				'other' => q(欧洲货币单位 \(XEU\)),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(法国金法郎),
				'other' => q(法国金法郎),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(法国法郎 \(UIC\)),
				'other' => q(法国法郎 \(UIC\)),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(法郎 \(CFA–BCEAO\)),
				'other' => q(法郎 \(CFA–BCEAO\)),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(帕拉狄昂),
				'other' => q(帕拉狄昂),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(法郎 \(CFP\)),
				'other' => q(法郎 \(CFP\)),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(白金),
				'other' => q(白金),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(RINET 基金),
				'other' => q(RINET 基金),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(苏克雷货币),
				'other' => q(苏克雷货币),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(测试用货币代码),
				'other' => q(测试用货币代码),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(亚洲开发银行计价单位),
				'other' => q(亚洲开发银行计价单位),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(未知货币),
				'other' => q(\(未知货币\)),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(叶门第纳尔),
				'other' => q(叶门第纳尔),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(叶门里亚尔),
				'other' => q(叶门里亚尔),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(南斯拉夫第纳尔硬币),
				'other' => q(南斯拉夫第纳尔硬币),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(南斯拉夫挪威亚第纳尔),
				'other' => q(南斯拉夫挪威亚第纳尔),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(南斯拉夫可转换第纳尔),
				'other' => q(南斯拉夫可转换第纳尔),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(南斯拉夫改革第纳尔 \(1992–1993\)),
				'other' => q(南斯拉夫改革第纳尔 \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(南非兰特（金融）),
				'other' => q(南非兰特（金融）),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(南非兰特),
				'other' => q(南非兰特),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(尚比亚克瓦查 \(1968–2012\)),
				'other' => q(尚比亚克瓦查 \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(尚比亚克瓦查),
				'other' => q(尚比亚克瓦查),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(萨伊新扎伊尔),
				'other' => q(萨伊新扎伊尔),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(萨伊扎伊尔),
				'other' => q(萨伊扎伊尔),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(辛巴威元 \(1980–2008\)),
				'other' => q(辛巴威元 \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(辛巴威元 \(2009\)),
				'other' => q(辛巴威元 \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(辛巴威元 \(2008\)),
				'other' => q(辛巴威元 \(2008\)),
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
							'腊月'
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
							'冬',
							'腊'
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
							'冬月',
							'腊月'
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
							'冬月',
							'腊月'
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
							'冬',
							'腊'
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
							'冬月',
							'腊月'
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
				'stand-alone' => {
					abbreviated => {
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
					abbreviated => {
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
				'stand-alone' => {
					abbreviated => {
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
					abbreviated => {
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
							'一月',
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
							'一月',
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
			'hebrew' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'提斯利月',
							'玛西班月',
							'基斯流月',
							'提别月',
							'细罢特月',
							'亚达月 I',
							'亚达月',
							'尼散月',
							'以珥月',
							'西弯月',
							'搭模斯月',
							'埃波月',
							'以禄月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'亚达月 II'
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
							'提斯利月',
							'玛西班月',
							'基斯流月',
							'提别月',
							'细罢特月',
							'亚达月 I',
							'亚达月',
							'尼散月',
							'以珥月',
							'西弯月',
							'搭模斯月',
							'埃波月',
							'以禄月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'亚达月 II'
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'提斯利月',
							'玛西班月',
							'基斯流月',
							'提别月',
							'细罢特月',
							'亚达月 I',
							'亚达月',
							'尼散月',
							'以珥月',
							'西弯月',
							'搭模斯月',
							'埃波月',
							'以禄月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'亚达月 II'
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
							'提斯利月',
							'玛西班月',
							'基斯流月',
							'提别月',
							'细罢特月',
							'亚达月 I',
							'亚达月',
							'尼散月',
							'以珥月',
							'西弯月',
							'搭模斯月',
							'埃波月',
							'以禄月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'亚达月 II'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'制檀逻月',
							'吠舍佉月',
							'逝瑟咤月',
							'頞沙荼月',
							'室罗伐拏月',
							'婆罗钵陀月',
							'頞泾缚庚阇月',
							'迦剌底迦月',
							'末伽始罗月',
							'报沙月',
							'磨祛月',
							'颇勒窭拏月'
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
							'制檀逻月',
							'吠舍佉月',
							'逝瑟咤月',
							'頞沙荼月',
							'室罗伐拏月',
							'婆罗钵陀月',
							'頞泾缚庚阇月',
							'迦剌底迦月',
							'末伽始罗月',
							'报沙月',
							'磨祛月',
							'颇勒窭拏月'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'制檀逻月',
							'吠舍佉月',
							'逝瑟咤月',
							'頞沙荼月',
							'室罗伐拏月',
							'婆罗钵陀月',
							'頞泾缚庚阇月',
							'迦剌底迦月',
							'末伽始罗月',
							'报沙月',
							'磨祛月',
							'颇勒窭拏月'
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
							'制檀逻月',
							'吠舍佉月',
							'逝瑟咤月',
							'頞沙荼月',
							'室罗伐拏月',
							'婆罗钵陀月',
							'頞泾缚庚阇月',
							'迦剌底迦月',
							'末伽始罗月',
							'报沙月',
							'磨祛月',
							'颇勒窭拏月'
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
							'穆哈兰姆月',
							'色法尔月',
							'赖比月 I',
							'赖比月 II',
							'主马达月 I',
							'主马达月 II',
							'赖哲卜月',
							'舍尔邦月',
							'赖买丹月',
							'闪瓦鲁月',
							'都尔喀尔德月',
							'都尔黑哲月'
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
							'穆哈兰姆月',
							'色法尔月',
							'赖比月 I',
							'赖比月 II',
							'主马达月 I',
							'主马达月 II',
							'赖哲卜月',
							'舍尔邦月',
							'赖买丹月',
							'闪瓦鲁月',
							'都尔喀尔德月',
							'都尔黑哲月'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'穆哈兰姆月',
							'色法尔月',
							'赖比月 I',
							'赖比月 II',
							'主马达月 I',
							'主马达月 II',
							'赖哲卜月',
							'舍尔邦月',
							'赖买丹月',
							'闪瓦鲁月',
							'都尔喀尔德月',
							'都尔黑哲月'
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
							'穆哈兰姆月',
							'色法尔月',
							'赖比月 I',
							'赖比月 II',
							'主马达月 I',
							'主马达月 II',
							'赖哲卜月',
							'舍尔邦月',
							'赖买丹月',
							'闪瓦鲁月',
							'都尔喀尔德月',
							'都尔黑哲月'
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
				'stand-alone' => {
					abbreviated => {
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
					abbreviated => {
						mon => '周一',
						tue => '周二',
						wed => '周三',
						thu => '周四',
						fri => '周五',
						sat => '周六',
						sun => '周日'
					},
					narrow => {
						mon => '一',
						tue => '二',
						wed => '三',
						thu => '四',
						fri => '五',
						sat => '六',
						sun => '日'
					},
					short => {
						mon => '周一',
						tue => '周二',
						wed => '周三',
						thu => '周四',
						fri => '周五',
						sat => '周六',
						sun => '周日'
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
					abbreviated => {
						mon => '周一',
						tue => '周二',
						wed => '周三',
						thu => '周四',
						fri => '周五',
						sat => '周六',
						sun => '周日'
					},
					narrow => {
						mon => '一',
						tue => '二',
						wed => '三',
						thu => '四',
						fri => '五',
						sat => '六',
						sun => '日'
					},
					short => {
						mon => '周一',
						tue => '周二',
						wed => '周三',
						thu => '周四',
						fri => '周五',
						sat => '周六',
						sun => '周日'
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
					abbreviated => {0 => '第1季',
						1 => '第2季',
						2 => '第3季',
						3 => '第4季'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '第1季',
						1 => '第2季',
						2 => '第3季',
						3 => '第4季'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '第1季',
						1 => '第2季',
						2 => '第3季',
						3 => '第4季'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
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
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'night1' if $time >= 0
						&& $time < 500;
				}
				if($day_period_type eq 'selection') {
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning1' if $time >= 500
						&& $time < 800;
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
				'wide' => {
					'pm' => q{下午},
					'midnight' => q{午夜},
					'morning2' => q{朝早},
					'afternoon1' => q{中午},
					'morning1' => q{清晨},
					'night1' => q{凌晨},
					'afternoon2' => q{下昼},
					'evening1' => q{夜晚},
					'am' => q{上午},
				},
				'narrow' => {
					'afternoon1' => q{中午},
					'morning2' => q{朝早},
					'midnight' => q{午夜},
					'pm' => q{下午},
					'evening1' => q{夜晚},
					'am' => q{上午},
					'night1' => q{凌晨},
					'morning1' => q{清晨},
					'afternoon2' => q{下昼},
				},
				'abbreviated' => {
					'afternoon2' => q{下昼},
					'morning1' => q{清晨},
					'night1' => q{凌晨},
					'am' => q{上午},
					'evening1' => q{夜晚},
					'pm' => q{下午},
					'midnight' => q{午夜},
					'afternoon1' => q{中午},
					'morning2' => q{朝早},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'midnight' => q{午夜},
					'afternoon1' => q{中午},
					'morning2' => q{朝早},
					'pm' => q{下午},
					'am' => q{上午},
					'evening1' => q{夜晚},
					'afternoon2' => q{下昼},
					'night1' => q{凌晨},
					'morning1' => q{清晨},
				},
				'wide' => {
					'pm' => q{下午},
					'midnight' => q{午夜},
					'morning2' => q{朝早},
					'afternoon1' => q{中午},
					'morning1' => q{清晨},
					'night1' => q{凌晨},
					'afternoon2' => q{下昼},
					'evening1' => q{夜晚},
					'am' => q{上午},
				},
				'abbreviated' => {
					'midnight' => q{午夜},
					'afternoon1' => q{中午},
					'morning2' => q{朝早},
					'pm' => q{下午},
					'am' => q{上午},
					'evening1' => q{夜晚},
					'afternoon2' => q{下昼},
					'night1' => q{凌晨},
					'morning1' => q{清晨},
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
				'0' => '佛历'
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
			narrow => {
				'0' => '西元前',
				'1' => '西元'
			},
			wide => {
				'0' => '西元前',
				'1' => '西元'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => '创世纪元'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => '印度历'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => '伊斯兰历'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => '大化',
				'1' => '白雉',
				'2' => '白凤',
				'3' => '朱鸟',
				'4' => '大宝',
				'5' => '庆云',
				'6' => '和铜',
				'7' => '灵龟',
				'8' => '养老',
				'9' => '神龟',
				'10' => '天平',
				'11' => '天平感宝',
				'12' => '天平胜宝',
				'13' => '天平宝字',
				'14' => '天平神护',
				'15' => '神护景云',
				'16' => '宝龟',
				'17' => '天应',
				'18' => '延历',
				'19' => '大同',
				'20' => '弘仁',
				'21' => '天长',
				'22' => '承和',
				'23' => '嘉祥',
				'24' => '仁寿',
				'25' => '齐衡',
				'26' => '天安',
				'27' => '贞观',
				'28' => '元庆',
				'29' => '仁和',
				'30' => '宽平',
				'31' => '昌泰',
				'32' => '延喜',
				'33' => '延长',
				'34' => '承平',
				'35' => '天庆',
				'36' => '天历',
				'37' => '天德',
				'38' => '应和',
				'39' => '康保',
				'40' => '安和',
				'41' => '天禄',
				'42' => '天延',
				'43' => '贞元',
				'44' => '天元',
				'45' => '永观',
				'46' => '宽和',
				'47' => '永延',
				'48' => '永祚',
				'49' => '正历',
				'50' => '长德',
				'51' => '长保',
				'52' => '宽弘',
				'53' => '长和',
				'54' => '宽仁',
				'55' => '治安',
				'56' => '万寿',
				'57' => '长元',
				'58' => '长历',
				'59' => '长久',
				'60' => '宽德',
				'61' => '永承',
				'62' => '天喜',
				'63' => '康平',
				'64' => '治历',
				'65' => '延久',
				'66' => '承保',
				'67' => '承历',
				'68' => '永保',
				'69' => '应德',
				'70' => '宽治',
				'71' => '嘉保',
				'72' => '永长',
				'73' => '承德',
				'74' => '康和',
				'75' => '长治',
				'76' => '嘉承',
				'77' => '天仁',
				'78' => '天永',
				'79' => '永久',
				'80' => '元永',
				'81' => '保安',
				'82' => '天治',
				'83' => '大治',
				'84' => '天承',
				'85' => '长承',
				'86' => '保延',
				'87' => '永治',
				'88' => '康治',
				'89' => '天养',
				'90' => '久安',
				'91' => '仁平',
				'92' => '久寿',
				'93' => '保元',
				'94' => '平治',
				'95' => '永历',
				'96' => '应保',
				'97' => '长宽',
				'98' => '永万',
				'99' => '仁安',
				'100' => '嘉应',
				'101' => '承安',
				'102' => '安元',
				'103' => '治承',
				'104' => '养和',
				'105' => '寿永',
				'106' => '元历',
				'107' => '文治',
				'108' => '建久',
				'109' => '正治',
				'110' => '建仁',
				'111' => '元久',
				'112' => '建永',
				'113' => '承元',
				'114' => '建历',
				'115' => '建保',
				'116' => '承久',
				'117' => '贞应',
				'118' => '元仁',
				'119' => '嘉禄',
				'120' => '安贞',
				'121' => '宽喜',
				'122' => '贞永',
				'123' => '天福',
				'124' => '文历',
				'125' => '嘉祯',
				'126' => '历仁',
				'127' => '延应',
				'128' => '仁治',
				'129' => '宽元',
				'130' => '宝治',
				'131' => '建长',
				'132' => '康元',
				'133' => '正嘉',
				'134' => '正元',
				'135' => '文应',
				'136' => '弘长',
				'137' => '文永',
				'138' => '建治',
				'139' => '弘安',
				'140' => '正应',
				'141' => '永仁',
				'142' => '正安',
				'143' => '干元',
				'144' => '嘉元',
				'145' => '德治',
				'146' => '延庆',
				'147' => '应长',
				'148' => '正和',
				'149' => '文保',
				'150' => '元应',
				'151' => '元亨',
				'152' => '正中',
				'153' => '嘉历',
				'154' => '元德',
				'155' => '元弘',
				'156' => '建武',
				'157' => '延元',
				'158' => '兴国',
				'159' => '正平',
				'160' => '建德',
				'161' => '文中',
				'162' => '天授',
				'163' => '康历',
				'164' => '弘和',
				'165' => '元中',
				'166' => '至德',
				'167' => '嘉庆',
				'168' => '康应',
				'169' => '明德',
				'170' => '应永',
				'171' => '正长',
				'172' => '永享',
				'173' => '嘉吉',
				'174' => '文安',
				'175' => '宝德',
				'176' => '享德',
				'177' => '康正',
				'178' => '长禄',
				'179' => '宽正',
				'180' => '文正',
				'181' => '应仁',
				'182' => '文明',
				'183' => '长享',
				'184' => '延德',
				'185' => '明应',
				'186' => '文龟',
				'187' => '永正',
				'188' => '大永',
				'189' => '享禄',
				'190' => '天文',
				'191' => '弘治',
				'192' => '永禄',
				'193' => '元龟',
				'194' => '天正',
				'195' => '文禄',
				'196' => '庆长',
				'197' => '元和',
				'198' => '宽永',
				'199' => '正保',
				'200' => '庆安',
				'201' => '承应',
				'202' => '明历',
				'203' => '万治',
				'204' => '宽文',
				'205' => '延宝',
				'206' => '天和',
				'207' => '贞享',
				'208' => '元禄',
				'209' => '宝永',
				'210' => '正德',
				'211' => '享保',
				'212' => '元文',
				'213' => '宽保',
				'214' => '延享',
				'215' => '宽延',
				'216' => '宝历',
				'217' => '明和',
				'218' => '安永',
				'219' => '天明',
				'220' => '宽政',
				'221' => '享和',
				'222' => '文化',
				'223' => '文政',
				'224' => '天保',
				'225' => '弘化',
				'226' => '嘉永',
				'227' => '安政',
				'228' => '万延',
				'229' => '文久',
				'230' => '元治',
				'231' => '庆应',
				'232' => '明治',
				'233' => '大正',
				'234' => '昭和',
				'235' => '平成'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => '波斯历'
			},
			wide => {
				'0' => '波斯历'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => '民国前',
				'1' => '民国'
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
			'short' => q{Gy-M-d},
		},
		'chinese' => {
			'full' => q{rU年MMMdEEEE},
			'long' => q{rU年MMMd},
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
			'full' => q{Gy年MM月d日EEEE},
			'long' => q{Gy年MM月d日},
			'medium' => q{Gy年MM月d日},
			'short' => q{Gy/M/d},
		},
		'gregorian' => {
			'full' => q{y年M月d日EEEE},
			'long' => q{y年M月d日},
			'medium' => q{y年M月d日},
			'short' => q{y/M/d},
		},
		'hebrew' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gy-M-d},
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
			'short' => q{Gyy-MM-dd},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
			'short' => q{Gyy/M/d},
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
			'full' => q{zzzz ah:mm:ss},
			'long' => q{z ah:mm:ss},
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
		'roc' => {
			E => q{ccc},
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			M => q{M月},
			MEd => q{M/dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M/d},
			d => q{d日},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy年M月},
			yyyyMEd => q{Gy/M/dE},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy/M/d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'islamic' => {
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			M => q{M月},
			MEd => q{M-dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M-d},
			d => q{d日},
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
		'buddhist' => {
			Ed => q{d日（E）},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			M => q{M月},
			MEd => q{M-dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M-d},
			d => q{d日},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy-M},
			yyyyMEd => q{Gy-M-d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy-M-d},
			yyyyQQQ => q{Gy年QQQ},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'gregorian' => {
			Bh => q{Bh时},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			E => q{ccc},
			EBhm => q{E Bh:mm},
			EBhms => q{E Bh:mm:ss},
			EHm => q{EHH:mm},
			EHms => q{EHH:mm:ss},
			Ed => q{d日E},
			Ehm => q{Eah:mm},
			Ehms => q{Eah:mm:ss},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			H => q{H时},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{v HH:mm:ss},
			Hmv => q{v HH:mm},
			M => q{M月},
			MEd => q{M/dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMW => q{M月第W个星期},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			MMdd => q{MM/dd},
			Md => q{M/d},
			d => q{d日},
			h => q{ah时},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			hmsv => q{v ah:mm:ss},
			hmv => q{v ah:mm},
			ms => q{mm:ss},
			y => q{y年},
			yM => q{y年M月},
			yMEd => q{y/M/dE},
			yMM => q{y年M月},
			yMMM => q{y年M月},
			yMMMEd => q{y年M月d日E},
			yMMMM => q{y年M月},
			yMMMd => q{y年M月d日},
			yMd => q{y/M/d},
			yQQQ => q{y年QQQ},
			yQQQQ => q{y年QQQQ},
			yw => q{Y年第w个星期},
		},
		'chinese' => {
			Ed => q{d日E},
			Gy => q{rU年},
			GyMMM => q{rU年MMM},
			GyMMMEd => q{rU年MMMdE},
			GyMMMd => q{r年MMMd},
			M => q{MMM},
			MEd => q{M-dE},
			MMMEd => q{MMMd日E},
			MMMMd => q{MMMMd日},
			MMMd => q{MMMd日},
			Md => q{M-d},
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
			Bh => q{Bh时},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d日E},
			Ehm => q{ah:mmE},
			Ehms => q{ah:mm:ssE},
			Gy => q{Gy年},
			GyMMM => q{Gy年MM月},
			GyMMMEd => q{Gy年MM月d日E},
			GyMMMd => q{Gy年MM月d日},
			H => q{H时},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{M/dE},
			MMM => q{LL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M/d},
			d => q{d日},
			h => q{ah时},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			ms => q{mm:ss},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy年M月},
			yyyyMEd => q{G y/M/dE},
			yyyyMMM => q{Gy年MM月},
			yyyyMMMEd => q{Gy年MM月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年MM月d日},
			yyyyMd => q{G y/M/d},
			yyyyQQQ => q{Gy年第Q季度},
			yyyyQQQQ => q{Gy年第Q季度},
		},
		'japanese' => {
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
			H => q{H时},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{M月},
			MEd => q{M-dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M-d},
			d => q{d日},
			h => q{ah时},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			ms => q{mm:ss},
			y => q{Gy年},
			yyyy => q{Gy年},
			yyyyM => q{Gy-MM},
			yyyyMEd => q{Gy-M-d（E）},
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年M月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{Gy-MM-dd},
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
		'gregorian' => {
			'Timezone' => '{1}{0}',
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
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{v HH:mm–HH:mm},
				m => q{v HH:mm–HH:mm},
			},
			Hv => {
				H => q{v HH–HH},
			},
			M => {
				M => q{M–M月},
			},
			MEd => {
				M => q{M/dE至M/dE},
				d => q{M/dE至M/dE},
			},
			MMM => {
				M => q{MMM – MMM},
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
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d–d日},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{ah时至ah时},
				h => q{ah时至h时},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{vah:mm至ah:mm},
				h => q{vah:mm至h:mm},
				m => q{vah:mm至h:mm},
			},
			hv => {
				a => q{vah时至ah时},
				h => q{vah时至h时},
			},
			y => {
				y => q{y–y年},
			},
			yM => {
				M => q{y年M月至M月},
				y => q{y年M月至y年M月},
			},
			yMEd => {
				M => q{y/M/dE至y/M/dE},
				d => q{y/M/dE至y/M/dE},
				y => q{y/M/dE至y/M/dE},
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
				M => q{y/M/d – y/M/d},
				d => q{y/M/d – y/M/d},
				y => q{y/M/d – y/M/d},
			},
		},
		'chinese' => {
			Hmv => {
				H => q{HH:mm至HH:mm v},
				m => q{HH:mm至HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{L至L},
			},
			MEd => {
				M => q{M-dE至M-dE},
				d => q{M-dE至M-dE},
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
				M => q{M-d至M-d},
				d => q{M-d至M-d},
			},
			d => {
				d => q{d日至d日},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{ah至ah时},
				h => q{ah至h时},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{vah:mm至ah:mm},
				h => q{vah:mm至h:mm},
				m => q{vah:mm至h:mm},
			},
			hv => {
				a => q{vah至ah时},
				h => q{vah至h时},
			},
			y => {
				y => q{rU至rU},
			},
			yM => {
				M => q{r-M至r-M},
				y => q{r-M至r-M},
			},
			yMEd => {
				M => q{r-M-dE至r-M-dE},
				d => q{r-M-dE至r-M-dE},
				y => q{r-M-dE至r-M-dE},
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
				M => q{r-M-d至r-M-d},
				d => q{r-M-d至r-M-d},
				y => q{r-M-d至r-M-d},
			},
		},
		'generic' => {
			H => {
				H => q{HH–HH},
			},
			Hm => {
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{v HH:mm – HH:mm},
				m => q{v HH:mm – HH:mm},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M月},
			},
			MEd => {
				M => q{M/dE至M/dE},
				d => q{M/dE至M/dE},
			},
			MMM => {
				M => q{MMM – MMM},
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
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d至d日},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{ah时至ah时},
				h => q{ah时至h时},
			},
			hm => {
				a => q{ah:mm至ah:mm},
				h => q{ah:mm至h:mm},
				m => q{ah:mm至h:mm},
			},
			hmv => {
				a => q{vah:mm至ah:mm},
				h => q{vah:mm至h:mm},
				m => q{vah:mm至h:mm},
			},
			hv => {
				a => q{vah时至ah时},
				h => q{vah时至h时},
			},
			y => {
				y => q{Gy–y年},
			},
			yM => {
				M => q{Gy年M月至M月},
				y => q{Gy年M月至y年M月},
			},
			yMEd => {
				M => q{Gy/M/dE至y/M/dE},
				d => q{Gy/M/dE至y/M/dE},
				y => q{Gy/M/dE至y/M/dE},
			},
			yMMM => {
				M => q{Gy年M月至M月},
				y => q{Gy年M月至y年M月},
			},
			yMMMEd => {
				M => q{Gy年M月d日E至M月d日E},
				d => q{Gy年M月d日E至d日E},
				y => q{Gy年M月d日E至y年M月d日E},
			},
			yMMMM => {
				M => q{Gy年M月至M月},
				y => q{Gy年M月至y年M月},
			},
			yMMMd => {
				M => q{Gy年M月d日至M月d日},
				d => q{Gy年M月d日至d日},
				y => q{Gy年M月d日至y年M月d日},
			},
			yMd => {
				M => q{Gy/M/d – y/M/d},
				d => q{Gy/M/d – y/M/d},
				y => q{Gy/M/d – y/M/d},
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
					'leap' => q{闰{0}},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{闰{0}},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'leap' => q{闰{0}},
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
						2 => q(惊蛰),
						3 => q(春分),
						4 => q(清明),
						5 => q(谷雨),
						6 => q(立夏),
						7 => q(小满),
						8 => q(芒种),
						9 => q(夏至),
						10 => q(小暑),
						11 => q(大暑),
						12 => q(立秋),
						13 => q(处暑),
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
						4 => q(龙),
						5 => q(蛇),
						6 => q(马),
						7 => q(羊),
						8 => q(猴),
						9 => q(鸡),
						10 => q(狗),
						11 => q(猪),
					},
				},
			},
		},
		'dangi' => {
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
						4 => q(龙),
						5 => q(蛇),
						6 => q(马),
						7 => q(羊),
						8 => q(猴),
						9 => q(鸡),
						10 => q(狗),
						11 => q(猪),
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
		regionFormat => q({0}时间),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#艾克夏令时间#,
				'generic' => q#艾克时间#,
				'standard' => q#艾克标准时间#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#阿富汗时间#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#阿比让#,
		},
		'Africa/Accra' => {
			exemplarCity => q#阿克拉#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#阿迪斯阿贝巴#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#阿尔及尔#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#阿斯玛拉#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#巴马科#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#班吉#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#班竹#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#比绍#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#布兰太尔#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#布拉柴维尔#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#布松布拉#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#开罗#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#卡萨布兰卡#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#休达#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#柯那克里#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#达喀尔#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#沙兰港#,
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
			exemplarCity => q#约翰尼斯堡#,
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
			exemplarCity => q#罗安达#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#卢本巴希#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#路沙卡#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#马拉博#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#马普托#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#马赛鲁#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#墨巴本#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#摩加迪休#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#蒙罗维亚#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#奈洛比#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#恩贾梅纳#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#尼亚美#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#诺克少#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#瓦加杜古#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#波多诺佛#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#圣多美#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#的黎波里#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#突尼斯#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#温得和克#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#中非时间#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#东非时间#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#南非标准时间#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#西非夏令时间#,
				'generic' => q#西非时间#,
				'standard' => q#西非标准时间#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#阿拉斯加夏令时间#,
				'generic' => q#阿拉斯加时间#,
				'standard' => q#阿拉斯加标准时间#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#阿拉木图夏令时间#,
				'generic' => q#阿拉木图时间#,
				'standard' => q#阿拉木图标准时间#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#亚马逊夏令时间#,
				'generic' => q#亚马逊时间#,
				'standard' => q#亚马逊标准时间#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#艾达克#,
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
			exemplarCity => q#里奥加耶戈斯#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#萨尔塔#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#圣胡安#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#圣路易#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#吐库曼#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#乌斯怀亚#,
		},
		'America/Aruba' => {
			exemplarCity => q#阿路巴#,
		},
		'America/Asuncion' => {
			exemplarCity => q#亚松森#,
		},
		'America/Bahia' => {
			exemplarCity => q#巴伊阿#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#巴伊亚班德拉斯#,
		},
		'America/Barbados' => {
			exemplarCity => q#巴贝多#,
		},
		'America/Belem' => {
			exemplarCity => q#贝伦#,
		},
		'America/Belize' => {
			exemplarCity => q#贝里斯#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#白朗萨布隆#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#保维斯塔#,
		},
		'America/Bogota' => {
			exemplarCity => q#波哥大#,
		},
		'America/Boise' => {
			exemplarCity => q#波夕#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#布宜诺斯艾利斯#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#剑桥湾#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#格兰场#,
		},
		'America/Cancun' => {
			exemplarCity => q#坎昆#,
		},
		'America/Caracas' => {
			exemplarCity => q#卡拉卡斯#,
		},
		'America/Catamarca' => {
			exemplarCity => q#卡塔马卡#,
		},
		'America/Cayenne' => {
			exemplarCity => q#开云#,
		},
		'America/Cayman' => {
			exemplarCity => q#开曼群岛#,
		},
		'America/Chicago' => {
			exemplarCity => q#芝加哥#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#奇华华#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#阿蒂科肯#,
		},
		'America/Cordoba' => {
			exemplarCity => q#哥多华#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#哥斯大黎加#,
		},
		'America/Creston' => {
			exemplarCity => q#克雷斯顿#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#古雅巴#,
		},
		'America/Curacao' => {
			exemplarCity => q#库拉索#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#丹马沙文#,
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
			exemplarCity => q#艾鲁内佩#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#萨尔瓦多#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#纳尔逊堡#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#福塔力莎#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#格雷斯贝#,
		},
		'America/Godthab' => {
			exemplarCity => q#努克#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#鹅湾#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#大特克岛#,
		},
		'America/Grenada' => {
			exemplarCity => q#格瑞纳达#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#瓜地洛普#,
		},
		'America/Guatemala' => {
			exemplarCity => q#瓜地马拉#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#瓜亚基尔#,
		},
		'America/Guyana' => {
			exemplarCity => q#盖亚那#,
		},
		'America/Halifax' => {
			exemplarCity => q#哈里法克斯#,
		},
		'America/Havana' => {
			exemplarCity => q#哈瓦那#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#埃莫西约#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#印第安那州诺克斯#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#印第安那州马伦哥#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#印第安那州彼得堡#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#印第安那州泰尔城#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#印第安那州维威#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#印第安那州温森斯#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#印第安那州威纳马克#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#印第安那波里斯#,
		},
		'America/Inuvik' => {
			exemplarCity => q#伊奴维克#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#伊魁特#,
		},
		'America/Jamaica' => {
			exemplarCity => q#牙买加#,
		},
		'America/Jujuy' => {
			exemplarCity => q#胡胡伊#,
		},
		'America/Juneau' => {
			exemplarCity => q#朱诺#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#肯塔基州蒙地却罗#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#克拉伦代克#,
		},
		'America/La_Paz' => {
			exemplarCity => q#拉巴斯#,
		},
		'America/Lima' => {
			exemplarCity => q#利马#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#洛杉矶#,
		},
		'America/Louisville' => {
			exemplarCity => q#路易斯维尔#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#下太子区#,
		},
		'America/Maceio' => {
			exemplarCity => q#马瑟欧#,
		},
		'America/Managua' => {
			exemplarCity => q#马拿瓜#,
		},
		'America/Manaus' => {
			exemplarCity => q#玛瑙斯#,
		},
		'America/Marigot' => {
			exemplarCity => q#马里戈特#,
		},
		'America/Martinique' => {
			exemplarCity => q#马丁尼克#,
		},
		'America/Matamoros' => {
			exemplarCity => q#马塔莫罗斯#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#马萨特兰#,
		},
		'America/Mendoza' => {
			exemplarCity => q#门多萨#,
		},
		'America/Menominee' => {
			exemplarCity => q#美诺米尼#,
		},
		'America/Merida' => {
			exemplarCity => q#梅里达#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#梅特拉卡特拉#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#墨西哥市#,
		},
		'America/Miquelon' => {
			exemplarCity => q#密启仑#,
		},
		'America/Moncton' => {
			exemplarCity => q#蒙克顿#,
		},
		'America/Monterrey' => {
			exemplarCity => q#蒙特瑞#,
		},
		'America/Montevideo' => {
			exemplarCity => q#蒙特维多#,
		},
		'America/Montserrat' => {
			exemplarCity => q#蒙哲腊#,
		},
		'America/Nassau' => {
			exemplarCity => q#拿索#,
		},
		'America/New_York' => {
			exemplarCity => q#纽约#,
		},
		'America/Nipigon' => {
			exemplarCity => q#尼皮冈#,
		},
		'America/Nome' => {
			exemplarCity => q#诺姆#,
		},
		'America/Noronha' => {
			exemplarCity => q#诺伦哈#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#北达科他州布由拉#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#北达科他州中心#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#北达科他州纽沙伦#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#奥希纳加#,
		},
		'America/Panama' => {
			exemplarCity => q#巴拿马#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#潘尼尔东#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#巴拉马利波#,
		},
		'America/Phoenix' => {
			exemplarCity => q#凤凰城#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#太子港#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#西班牙港#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#维留港#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#波多黎各#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#蓬塔阿雷纳斯#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#雨河镇#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#兰今湾#,
		},
		'America/Recife' => {
			exemplarCity => q#雷西非#,
		},
		'America/Regina' => {
			exemplarCity => q#里贾纳#,
		},
		'America/Resolute' => {
			exemplarCity => q#罗斯鲁特#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#里约布兰#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#圣伊萨贝尔#,
		},
		'America/Santarem' => {
			exemplarCity => q#圣塔伦#,
		},
		'America/Santiago' => {
			exemplarCity => q#圣地牙哥#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#圣多明哥#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#圣保罗#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#伊托科尔托米特#,
		},
		'America/Sitka' => {
			exemplarCity => q#锡特卡#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#圣巴托洛缪岛#,
		},
		'America/St_Johns' => {
			exemplarCity => q#圣约翰#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#圣基茨#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#圣露西亚#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#圣托马斯#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#圣文森#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#斯威夫特卡伦特#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#德古斯加巴#,
		},
		'America/Thule' => {
			exemplarCity => q#杜里#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#珊德湾#,
		},
		'America/Tijuana' => {
			exemplarCity => q#提华纳#,
		},
		'America/Toronto' => {
			exemplarCity => q#多伦多#,
		},
		'America/Tortola' => {
			exemplarCity => q#托尔托拉#,
		},
		'America/Vancouver' => {
			exemplarCity => q#温哥华#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#怀特霍斯#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#温尼伯#,
		},
		'America/Yakutat' => {
			exemplarCity => q#雅库塔#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#耶洛奈夫#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#中部夏令时间#,
				'generic' => q#中部时间#,
				'standard' => q#中部标准时间#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#东部夏令时间#,
				'generic' => q#东部时间#,
				'standard' => q#东部标准时间#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#山区夏令时间#,
				'generic' => q#山区时间#,
				'standard' => q#山区标准时间#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#太平洋夏令时间#,
				'generic' => q#太平洋时间#,
				'standard' => q#太平洋标准时间#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#阿那底河夏令时间#,
				'generic' => q#阿纳德尔时间#,
				'standard' => q#阿那底河标准时间#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#凯西#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#戴维斯#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#杜蒙杜比尔#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#麦觉理#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#莫森#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#麦克默多#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#帕麦#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#罗瑟拉#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#昭和基地#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#绰尔#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#沃斯托克#,
		},
		'Apia' => {
			long => {
				'daylight' => q#阿皮亚夏令时间#,
				'generic' => q#阿皮亚时间#,
				'standard' => q#阿皮亚标准时间#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#阿克陶夏令时间#,
				'generic' => q#阿克陶时间#,
				'standard' => q#阿克陶标准时间#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#阿克托比夏令时间#,
				'generic' => q#阿克托比时间#,
				'standard' => q#阿克托比标准时间#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#阿拉伯夏令时间#,
				'generic' => q#阿拉伯时间#,
				'standard' => q#阿拉伯标准时间#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#隆意耳拜恩#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#阿根廷夏令时间#,
				'generic' => q#阿根廷时间#,
				'standard' => q#阿根廷标准时间#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#阿根廷西部夏令时间#,
				'generic' => q#阿根廷西部时间#,
				'standard' => q#阿根廷西部标准时间#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#亚美尼亚夏令时间#,
				'generic' => q#亚美尼亚时间#,
				'standard' => q#亚美尼亚标准时间#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#亚丁#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#阿拉木图#,
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
			exemplarCity => q#阿特劳#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#巴格达#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#巴林#,
		},
		'Asia/Baku' => {
			exemplarCity => q#巴库#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#曼谷#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#巴尔瑙尔#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#贝鲁特#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#比什凯克#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#汶莱#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#加尔各答#,
		},
		'Asia/Chita' => {
			exemplarCity => q#赤塔#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#乔巴山#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#可伦坡#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#大马士革#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#达卡#,
		},
		'Asia/Dili' => {
			exemplarCity => q#帝力#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#杜拜#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#杜桑贝#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#法马古斯塔#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#加萨#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#赫布隆#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#中华人民共和国香港特别行政区#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#科布多#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#伊尔库次克#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#雅加达#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#加亚布拉#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#耶路撒冷#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#喀布尔#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#堪察加#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#喀拉蚩#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#加德满都#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#堪地加#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#克拉斯诺亚尔斯克#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#吉隆坡#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#古晋#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#科威特#,
		},
		'Asia/Macau' => {
			exemplarCity => q#中华人民共和国澳门特别行政区#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#马加丹#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#马卡沙尔#,
		},
		'Asia/Manila' => {
			exemplarCity => q#马尼拉#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#马斯开特#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#尼古西亚#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#新库兹涅茨克#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#新西伯利亚#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#鄂木斯克#,
		},
		'Asia/Oral' => {
			exemplarCity => q#乌拉尔#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#金边#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#坤甸#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#平壤#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#卡达#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#克孜勒奥尔达#,
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
			exemplarCity => q#库页岛#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#撒马尔罕#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#首尔#,
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
			exemplarCity => q#德黑兰#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#廷布#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#东京#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#托木斯克#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#乌兰巴托#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#乌鲁木齐#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#乌斯内拉#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#永珍#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#海参崴#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#雅库次克#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#叶卡捷林堡#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#叶里温#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#大西洋夏令时间#,
				'generic' => q#大西洋时间#,
				'standard' => q#大西洋标准时间#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#亚速尔群岛#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#百慕达#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#加纳利#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#维德角#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#法罗群岛#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#马得拉群岛#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#雷克雅维克#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#南乔治亚#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#圣赫勒拿岛#,
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
			exemplarCity => q#布罗肯希尔#,
		},
		'Australia/Currie' => {
			exemplarCity => q#克黎#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#达尔文#,
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
			exemplarCity => q#豪勋爵岛#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#墨尔本#,
		},
		'Australia/Perth' => {
			exemplarCity => q#伯斯#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#雪梨#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#澳洲中部夏令时间#,
				'generic' => q#澳洲中部时间#,
				'standard' => q#澳洲中部标准时间#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#澳洲中西部夏令时间#,
				'generic' => q#澳洲中西部时间#,
				'standard' => q#澳洲中西部标准时间#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#澳洲东部夏令时间#,
				'generic' => q#澳洲东部时间#,
				'standard' => q#澳洲东部标准时间#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#澳洲西部夏令时间#,
				'generic' => q#澳洲西部时间#,
				'standard' => q#澳洲西部标准时间#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#亚塞拜然夏令时间#,
				'generic' => q#亚塞拜然时间#,
				'standard' => q#亚塞拜然标准时间#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#亚速尔群岛夏令时间#,
				'generic' => q#亚速尔群岛时间#,
				'standard' => q#亚速尔群岛标准时间#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#孟加拉夏令时间#,
				'generic' => q#孟加拉时间#,
				'standard' => q#孟加拉标准时间#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#不丹时间#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#玻利维亚时间#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#巴西利亚夏令时间#,
				'generic' => q#巴西利亚时间#,
				'standard' => q#巴西利亚标准时间#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#汶莱时间#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#维德角夏令时间#,
				'generic' => q#维德角时间#,
				'standard' => q#维德角标准时间#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#凯西站时间#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#查莫洛时间#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#查坦群岛夏令时间#,
				'generic' => q#查坦群岛时间#,
				'standard' => q#查坦群岛标准时间#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#智利夏令时间#,
				'generic' => q#智利时间#,
				'standard' => q#智利标准时间#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#中国夏令时间#,
				'generic' => q#中国时间#,
				'standard' => q#中国标准时间#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#乔巴山夏令时间#,
				'generic' => q#乔巴山时间#,
				'standard' => q#乔巴山标准时间#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#圣诞岛时间#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#科科斯群岛时间#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#哥伦比亚夏令时间#,
				'generic' => q#哥伦比亚时间#,
				'standard' => q#哥伦比亚标准时间#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#库克群岛半夏令时间#,
				'generic' => q#库克群岛时间#,
				'standard' => q#库克群岛标准时间#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#古巴夏令时间#,
				'generic' => q#古巴时间#,
				'standard' => q#古巴标准时间#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#戴维斯时间#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#杜蒙杜比尔时间#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#东帝汶时间#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#复活节岛夏令时间#,
				'generic' => q#复活节岛时间#,
				'standard' => q#复活节岛标准时间#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#厄瓜多时间#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#协调世界时间#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#未知城市#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#阿姆斯特丹#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#安道尔#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#阿斯特拉罕#,
		},
		'Europe/Athens' => {
			exemplarCity => q#雅典#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#贝尔格勒#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#柏林#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#布拉提斯拉瓦#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#布鲁塞尔#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#布加勒斯特#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#布达佩斯#,
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
				'daylight' => q#爱尔兰标准时间#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#直布罗陀#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#根息岛#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#赫尔辛基#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#曼岛#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#伊斯坦堡#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#泽西岛#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#加里宁格勒#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#基辅#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#基洛夫#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#里斯本#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#卢比安纳#,
		},
		'Europe/London' => {
			exemplarCity => q#伦敦#,
			long => {
				'daylight' => q#英国夏令时间#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#卢森堡#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#马德里#,
		},
		'Europe/Malta' => {
			exemplarCity => q#马尔他#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#玛丽港#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#明斯克#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#摩纳哥#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#莫斯科#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#奥斯陆#,
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
			exemplarCity => q#罗马#,
		},
		'Europe/Samara' => {
			exemplarCity => q#沙马拉#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#圣马利诺#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#塞拉耶佛#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#萨拉托夫#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#辛非洛浦#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#史高比耶#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#索菲亚#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#斯德哥尔摩#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#塔林#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#地拉那#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#乌里扬诺夫斯克#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#乌兹哥洛#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#瓦都兹#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#梵蒂冈#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#维也纳#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#维尔纽斯#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#伏尔加格勒#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#华沙#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#札格瑞布#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#札波罗结#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#苏黎世#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#中欧夏令时间#,
				'generic' => q#中欧时间#,
				'standard' => q#中欧标准时间#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#东欧夏令时间#,
				'generic' => q#东欧时间#,
				'standard' => q#东欧标准时间#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#欧洲远东时间#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#西欧夏令时间#,
				'generic' => q#西欧时间#,
				'standard' => q#西欧标准时间#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#福克兰群岛夏令时间#,
				'generic' => q#福克兰群岛时间#,
				'standard' => q#福克兰群岛标准时间#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#斐济夏令时间#,
				'generic' => q#斐济时间#,
				'standard' => q#斐济标准时间#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#法属圭亚那时间#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#法国南方及南极时间#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#格林威治标准时间#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#加拉巴哥群岛时间#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#甘比尔群岛时间#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#乔治亚夏令时间#,
				'generic' => q#乔治亚时间#,
				'standard' => q#乔治亚标准时间#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#吉尔伯特群岛时间#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#格陵兰东部夏令时间#,
				'generic' => q#格陵兰东部时间#,
				'standard' => q#格陵兰东部标准时间#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#格陵兰西部夏令时间#,
				'generic' => q#格陵兰西部时间#,
				'standard' => q#格陵兰西部标准时间#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#关岛标准时间#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#波斯湾海域标准时间#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#盖亚那时间#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#夏威夷-阿留申夏令时间#,
				'generic' => q#夏威夷-阿留申时间#,
				'standard' => q#夏威夷-阿留申标准时间#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#香港夏令时间#,
				'generic' => q#香港时间#,
				'standard' => q#香港标准时间#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#科布多夏令时间#,
				'generic' => q#科布多时间#,
				'standard' => q#科布多标准时间#,
			},
		},
		'India' => {
			long => {
				'standard' => q#印度标准时间#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#安塔那那利佛#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#查戈斯#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#圣诞岛#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#科科斯群岛#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#科摩罗群岛#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#凯尔盖朗岛#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#马埃岛#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#马尔地夫#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#模里西斯#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#马约特岛#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#留尼旺岛#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#印度洋时间#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#印度支那时间#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#印尼中部时间#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#印尼东部时间#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#印尼西部时间#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#伊朗夏令时间#,
				'generic' => q#伊朗时间#,
				'standard' => q#伊朗标准时间#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#伊尔库次克夏令时间#,
				'generic' => q#伊尔库次克时间#,
				'standard' => q#伊尔库次克标准时间#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#以色列夏令时间#,
				'generic' => q#以色列时间#,
				'standard' => q#以色列标准时间#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#日本夏令时间#,
				'generic' => q#日本时间#,
				'standard' => q#日本标准时间#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#彼得罗巴甫洛夫斯克日光节约时间#,
				'generic' => q#彼得罗巴甫洛夫斯克时间#,
				'standard' => q#彼得罗巴甫洛夫斯克标准时间#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#东哈萨克时间#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#西哈萨克时间#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#韩国夏令时间#,
				'generic' => q#韩国时间#,
				'standard' => q#韩国标准时间#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#科斯瑞时间#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#克拉斯诺亚尔斯克夏令时间#,
				'generic' => q#克拉斯诺亚尔斯克时间#,
				'standard' => q#克拉斯诺亚尔斯克标准时间#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#吉尔吉斯时间#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#兰卡时间#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#莱恩群岛时间#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#豪勋爵岛夏令时间#,
				'generic' => q#豪勋爵岛时间#,
				'standard' => q#豪勋爵岛标准时间#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#澳门夏令时间#,
				'generic' => q#澳门时间#,
				'standard' => q#澳门标准时间#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#麦觉理时间#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#马加丹夏令时间#,
				'generic' => q#马加丹时间#,
				'standard' => q#马加丹标准时间#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#马来西亚时间#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#马尔地夫时间#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#马可萨斯时间#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#马绍尔群岛时间#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#模里西斯夏令时间#,
				'generic' => q#模里西斯时间#,
				'standard' => q#模里西斯标准时间#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#莫森时间#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#墨西哥西北部夏令时间#,
				'generic' => q#墨西哥西北部时间#,
				'standard' => q#墨西哥西北部标准时间#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#墨西哥太平洋夏令时间#,
				'generic' => q#墨西哥太平洋时间#,
				'standard' => q#墨西哥太平洋标准时间#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#乌兰巴托夏令时间#,
				'generic' => q#乌兰巴托时间#,
				'standard' => q#乌兰巴托标准时间#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#莫斯科夏令时间#,
				'generic' => q#莫斯科时间#,
				'standard' => q#莫斯科标准时间#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#缅甸时间#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#诺鲁时间#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#尼泊尔时间#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#新喀里多尼亚群岛夏令时间#,
				'generic' => q#新喀里多尼亚时间#,
				'standard' => q#新喀里多尼亚标准时间#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#纽西兰夏令时间#,
				'generic' => q#纽西兰时间#,
				'standard' => q#纽西兰标准时间#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#纽芬兰夏令时间#,
				'generic' => q#纽芬兰时间#,
				'standard' => q#纽芬兰标准时间#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#纽埃岛时间#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#诺福克岛时间#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#费尔南多 - 迪诺罗尼亚夏令时间#,
				'generic' => q#费尔南多 - 迪诺罗尼亚时间#,
				'standard' => q#费尔南多 - 迪诺罗尼亚标准时间#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#北马里亚纳群岛时间#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#新西伯利亚夏令时间#,
				'generic' => q#新西伯利亚时间#,
				'standard' => q#新西伯利亚标准时间#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#鄂木斯克夏令时间#,
				'generic' => q#鄂木斯克时间#,
				'standard' => q#鄂木斯克标准时间#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#阿皮亚#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#奥克兰#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#布干维尔#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#查坦#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#复活岛#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#埃法特#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#恩得伯理岛#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#法考福#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#斐济#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#富那富提#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#加拉巴哥群岛#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#甘比尔群岛#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#瓜达康纳尔岛#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#关岛#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#檀香山#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#强斯顿#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#基里地马地岛#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#科斯瑞#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#瓜加林岛#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#马朱诺#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#马可萨斯岛#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#中途岛#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#诺鲁#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#纽埃岛#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#诺福克#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#诺美亚#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#巴哥巴哥#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#帛琉#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#皮特肯群岛#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#波纳佩#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#莫士比港#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#拉罗汤加#,
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
			exemplarCity => q#东加塔布岛#,
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
				'daylight' => q#巴基斯坦夏令时间#,
				'generic' => q#巴基斯坦时间#,
				'standard' => q#巴基斯坦标准时间#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#帛琉时间#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#巴布亚纽几内亚时间#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#巴拉圭夏令时间#,
				'generic' => q#巴拉圭时间#,
				'standard' => q#巴拉圭标准时间#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#秘鲁夏令时间#,
				'generic' => q#秘鲁时间#,
				'standard' => q#秘鲁标准时间#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#菲律宾夏令时间#,
				'generic' => q#菲律宾时间#,
				'standard' => q#菲律宾标准时间#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#凤凰群岛时间#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#圣皮埃尔和密克隆群岛夏令时间#,
				'generic' => q#圣皮埃尔和密克隆群岛时间#,
				'standard' => q#圣皮埃尔和密克隆群岛标准时间#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#皮特肯时间#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#波纳佩时间#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#平壤时间#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#克孜勒奥尔达夏令时间#,
				'generic' => q#克孜勒奥尔达时间#,
				'standard' => q#克孜勒奥尔达标准时间#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#留尼旺时间#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#罗瑟拉时间#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#库页岛夏令时间#,
				'generic' => q#库页岛时间#,
				'standard' => q#库页岛标准时间#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#萨马拉夏令时间#,
				'generic' => q#萨马拉时间#,
				'standard' => q#萨马拉标准时间#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#萨摩亚夏令时间#,
				'generic' => q#萨摩亚时间#,
				'standard' => q#萨摩亚标准时间#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#塞席尔时间#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#新加坡标准时间#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#索罗门群岛时间#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#南乔治亚时间#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#苏利南时间#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#昭和基地时间#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#大溪地时间#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#台北夏令时间#,
				'generic' => q#台北时间#,
				'standard' => q#台北标准时间#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#塔吉克时间#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#托克劳群岛时间#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#东加夏令时间#,
				'generic' => q#东加时间#,
				'standard' => q#东加标准时间#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#楚克岛时间#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#土库曼夏令时间#,
				'generic' => q#土库曼时间#,
				'standard' => q#土库曼标准时间#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#吐瓦鲁时间#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#乌拉圭夏令时间#,
				'generic' => q#乌拉圭时间#,
				'standard' => q#乌拉圭标准时间#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#乌兹别克夏令时间#,
				'generic' => q#乌兹别克时间#,
				'standard' => q#乌兹别克标准时间#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#万那杜夏令时间#,
				'generic' => q#万那杜时间#,
				'standard' => q#万那杜标准时间#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#委内瑞拉时间#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#海参崴夏令时间#,
				'generic' => q#海参崴时间#,
				'standard' => q#海参崴标准时间#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#伏尔加格勒夏令时间#,
				'generic' => q#伏尔加格勒时间#,
				'standard' => q#伏尔加格勒标准时间#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#沃斯托克时间#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#威克岛时间#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#瓦利斯和富图纳群岛时间#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#雅库次克夏令时间#,
				'generic' => q#雅库次克时间#,
				'standard' => q#雅库次克标准时间#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#叶卡捷琳堡夏令时间#,
				'generic' => q#叶卡捷琳堡时间#,
				'standard' => q#叶卡捷琳堡标准时间#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
