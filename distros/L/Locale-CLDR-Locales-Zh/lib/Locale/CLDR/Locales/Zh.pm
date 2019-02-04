=encoding utf8

=head1

Locale::CLDR::Locales::Zh - Package for language Chinese

=cut

package Locale::CLDR::Locales::Zh;
# This file auto generated from Data\common\main\zh.xml
#	on Sun  3 Feb  2:27:20 pm GMT

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
has 'LineBreak_variables' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[
		'$ID' => '[[\p{Line_Break=Ideographic}] [$CJ]]',
		'$NS' => '\p{Line_Break=Nonstarter}',
	]}
);
has 'valid_algorithmic_formats' => (
	is => 'ro',
	isa => ArrayRef,
	init_arg => undef,
	default => sub {[ 'spellout-numbering-year','spellout-numbering-days','spellout-numbering','spellout-cardinal-financial','spellout-cardinal','spellout-cardinal-alternate2','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'cardinal-alternate2-13' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal-alternate2=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-alternate2=),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
			},
		},
		'cardinal-alternate2-2' => {
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
		'cardinal-alternate2-3' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal-alternate2=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-alternate2=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-alternate2=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-alternate2=),
				},
			},
		},
		'cardinal-alternate2-4' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal-alternate2=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-alternate2=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
			},
		},
		'cardinal-alternate2-5' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal-alternate2=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-alternate2=),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
			},
		},
		'cardinal-alternate2-8' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal-alternate2=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal-alternate2=),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
				'max' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal-alternate2=),
				},
			},
		},
		'cardinal13' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal=),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'cardinal2' => {
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
		'cardinal3' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'cardinal4' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal=),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'cardinal5' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal=),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'cardinal8' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(零=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(零一=%spellout-cardinal=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(零=%spellout-cardinal=),
				},
				'10000000' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(10000000),
					divisor => q(10000000),
					rule => q(=%spellout-cardinal=),
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
					rule => q(〇=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(〇一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(〇=%spellout-numbering=),
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
					rule => q(〇=%spellout-numbering=),
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
					rule => q(〇=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(〇一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(〇=%spellout-numbering=),
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
					rule => q(〇=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(〇一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(〇=%spellout-numbering=),
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
					rule => q(〇=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(〇一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(〇=%spellout-numbering=),
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
					rule => q(〇=%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(〇一=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(〇=%spellout-numbering=),
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
		'numbering-days' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(廿→→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←十),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(丗→→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(←←十),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(卌→→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(50),
					divisor => q(10),
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
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←百[→%%cardinal2→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←千[→%%cardinal3→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←万[→%%cardinal4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←亿[→%%cardinal5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←兆[→%%cardinal8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←京[→%%cardinal13→]),
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
					rule => q(=%spellout-numbering=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←←百[→%%cardinal-alternate2-2→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←←千[→%%cardinal-alternate2-3→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(←←万[→%%cardinal-alternate2-4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←亿[→%%cardinal-alternate2-5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←兆[→%%cardinal-alternate2-8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←京[→%%cardinal-alternate2-13→]),
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
					rule => q(←←万[→%%financialnumber4→]),
				},
				'100000000' => {
					base_value => q(100000000),
					divisor => q(100000000),
					rule => q(←←亿[→%%financialnumber5→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←←兆[→%%financialnumber8→]),
				},
				'10000000000000000' => {
					base_value => q(10000000000000000),
					divisor => q(10000000000000000),
					rule => q(←←京[→%%financialnumber13→]),
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
					rule => q(〇),
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
		'spellout-numbering-days' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(负→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(〇),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(初=%spellout-numbering=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%spellout-numbering=),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(=%%numbering-days=),
				},
				'max' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(=%%numbering-days=),
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

	my $display_pattern = '{0}（{1}）';
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
				'aa' => '阿法尔语',
 				'ab' => '阿布哈西亚语',
 				'ace' => '亚齐语',
 				'ach' => '阿乔利语',
 				'ada' => '阿当梅语',
 				'ady' => '阿迪格语',
 				'ae' => '阿维斯塔语',
 				'af' => '南非荷兰语',
 				'afh' => '阿弗里希利语',
 				'agq' => '亚罕语',
 				'ain' => '阿伊努语',
 				'ak' => '阿肯语',
 				'akk' => '阿卡德语',
 				'ale' => '阿留申语',
 				'alt' => '南阿尔泰语',
 				'am' => '阿姆哈拉语',
 				'an' => '阿拉贡语',
 				'ang' => '古英语',
 				'anp' => '昂加语',
 				'ar' => '阿拉伯语',
 				'ar_001' => '现代标准阿拉伯语',
 				'arc' => '阿拉米语',
 				'arn' => '马普切语',
 				'arp' => '阿拉帕霍语',
 				'ars' => '纳吉迪阿拉伯语',
 				'arw' => '阿拉瓦克语',
 				'as' => '阿萨姆语',
 				'asa' => '帕雷语',
 				'ast' => '阿斯图里亚斯语',
 				'av' => '阿瓦尔语',
 				'awa' => '阿瓦德语',
 				'ay' => '艾马拉语',
 				'az' => '阿塞拜疆语',
 				'az@alt=short' => '阿塞语',
 				'az_Arab' => '南阿塞拜疆语',
 				'ba' => '巴什基尔语',
 				'bal' => '俾路支语',
 				'ban' => '巴厘语',
 				'bas' => '巴萨语',
 				'bax' => '巴姆穆语',
 				'bbj' => '戈马拉语',
 				'be' => '白俄罗斯语',
 				'bej' => '贝沙语',
 				'bem' => '本巴语',
 				'bez' => '贝纳语',
 				'bfd' => '巴非特语',
 				'bg' => '保加利亚语',
 				'bgn' => '西俾路支语',
 				'bho' => '博杰普尔语',
 				'bi' => '比斯拉马语',
 				'bik' => '比科尔语',
 				'bin' => '比尼语',
 				'bkm' => '科姆语',
 				'bla' => '西克西卡语',
 				'bm' => '班巴拉语',
 				'bn' => '孟加拉语',
 				'bo' => '藏语',
 				'br' => '布列塔尼语',
 				'bra' => '布拉杰语',
 				'brx' => '博多语',
 				'bs' => '波斯尼亚语',
 				'bss' => '阿库色语',
 				'bua' => '布里亚特语',
 				'bug' => '布吉语',
 				'bum' => '布鲁语',
 				'byn' => '比林语',
 				'byv' => '梅敦巴语',
 				'ca' => '加泰罗尼亚语',
 				'cad' => '卡多语',
 				'car' => '加勒比语',
 				'cay' => '卡尤加语',
 				'cch' => '阿灿语',
 				'ce' => '车臣语',
 				'ceb' => '宿务语',
 				'cgg' => '奇加语',
 				'ch' => '查莫罗语',
 				'chb' => '奇布查语',
 				'chg' => '察合台语',
 				'chk' => '楚克语',
 				'chm' => '马里语',
 				'chn' => '奇努克混合语',
 				'cho' => '乔克托语',
 				'chp' => '奇佩维安语',
 				'chr' => '切罗基语',
 				'chy' => '夏延语',
 				'ckb' => '中库尔德语',
 				'co' => '科西嘉语',
 				'cop' => '科普特语',
 				'cr' => '克里族语',
 				'crh' => '克里米亚土耳其语',
 				'crs' => '塞舌尔克里奥尔语',
 				'cs' => '捷克语',
 				'csb' => '卡舒比语',
 				'cu' => '教会斯拉夫语',
 				'cv' => '楚瓦什语',
 				'cy' => '威尔士语',
 				'da' => '丹麦语',
 				'dak' => '达科他语',
 				'dar' => '达尔格瓦语',
 				'dav' => '台塔语',
 				'de' => '德语',
 				'de_AT' => '奥地利德语',
 				'de_CH' => '瑞士高地德语',
 				'del' => '特拉华语',
 				'den' => '史拉维语',
 				'dgr' => '多格里布语',
 				'din' => '丁卡语',
 				'dje' => '哲尔马语',
 				'doi' => '多格拉语',
 				'dsb' => '下索布语',
 				'dua' => '都阿拉语',
 				'dum' => '中古荷兰语',
 				'dv' => '迪维希语',
 				'dyo' => '朱拉语',
 				'dyu' => '迪尤拉语',
 				'dz' => '宗卡语',
 				'dzg' => '达扎葛语',
 				'ebu' => '恩布语',
 				'ee' => '埃维语',
 				'efi' => '埃菲克语',
 				'egy' => '古埃及语',
 				'eka' => '艾卡朱克语',
 				'el' => '希腊语',
 				'elx' => '埃兰语',
 				'en' => '英语',
 				'en_AU' => '澳大利亚英语',
 				'en_CA' => '加拿大英语',
 				'en_GB' => '英国英语',
 				'en_GB@alt=short' => '英式英语',
 				'en_US' => '美国英语',
 				'en_US@alt=short' => '美式英语',
 				'enm' => '中古英语',
 				'eo' => '世界语',
 				'es' => '西班牙语',
 				'es_419' => '拉丁美洲西班牙语',
 				'es_ES' => '欧洲西班牙语',
 				'es_MX' => '墨西哥西班牙语',
 				'et' => '爱沙尼亚语',
 				'eu' => '巴斯克语',
 				'ewo' => '旺杜语',
 				'fa' => '波斯语',
 				'fan' => '芳格语',
 				'fat' => '芳蒂语',
 				'ff' => '富拉语',
 				'fi' => '芬兰语',
 				'fil' => '菲律宾语',
 				'fj' => '斐济语',
 				'fo' => '法罗语',
 				'fon' => '丰语',
 				'fr' => '法语',
 				'fr_CA' => '加拿大法语',
 				'fr_CH' => '瑞士法语',
 				'frc' => '卡真法语',
 				'frm' => '中古法语',
 				'fro' => '古法语',
 				'frr' => '北弗里西亚语',
 				'frs' => '东弗里西亚语',
 				'fur' => '弗留利语',
 				'fy' => '西弗里西亚语',
 				'ga' => '爱尔兰语',
 				'gaa' => '加族语',
 				'gag' => '加告兹语',
 				'gan' => '赣语',
 				'gay' => '迦约语',
 				'gba' => '格巴亚语',
 				'gd' => '苏格兰盖尔语',
 				'gez' => '吉兹语',
 				'gil' => '吉尔伯特语',
 				'gl' => '加利西亚语',
 				'gmh' => '中古高地德语',
 				'gn' => '瓜拉尼语',
 				'goh' => '古高地德语',
 				'gon' => '冈德语',
 				'gor' => '哥伦打洛语',
 				'got' => '哥特语',
 				'grb' => '格列博语',
 				'grc' => '古希腊语',
 				'gsw' => '瑞士德语',
 				'gu' => '古吉拉特语',
 				'guz' => '古西语',
 				'gv' => '马恩语',
 				'gwi' => '哥威迅语',
 				'ha' => '豪萨语',
 				'hai' => '海达语',
 				'hak' => '客家语',
 				'haw' => '夏威夷语',
 				'he' => '希伯来语',
 				'hi' => '印地语',
 				'hil' => '希利盖农语',
 				'hit' => '赫梯语',
 				'hmn' => '苗语',
 				'ho' => '希里莫图语',
 				'hr' => '克罗地亚语',
 				'hsb' => '上索布语',
 				'hsn' => '湘语',
 				'ht' => '海地克里奥尔语',
 				'hu' => '匈牙利语',
 				'hup' => '胡帕语',
 				'hy' => '亚美尼亚语',
 				'hz' => '赫雷罗语',
 				'ia' => '国际语',
 				'iba' => '伊班语',
 				'ibb' => '伊比比奥语',
 				'id' => '印度尼西亚语',
 				'ie' => '国际文字（E）',
 				'ig' => '伊博语',
 				'ii' => '四川彝语',
 				'ik' => '伊努皮克语',
 				'ilo' => '伊洛卡诺语',
 				'inh' => '印古什语',
 				'io' => '伊多语',
 				'is' => '冰岛语',
 				'it' => '意大利语',
 				'iu' => '因纽特语',
 				'ja' => '日语',
 				'jbo' => '逻辑语',
 				'jgo' => '恩艮巴语',
 				'jmc' => '马切姆语',
 				'jpr' => '犹太波斯语',
 				'jrb' => '犹太阿拉伯语',
 				'jv' => '爪哇语',
 				'ka' => '格鲁吉亚语',
 				'kaa' => '卡拉卡尔帕克语',
 				'kab' => '卡拜尔语',
 				'kac' => '克钦语',
 				'kaj' => '卡捷语',
 				'kam' => '卡姆巴语',
 				'kaw' => '卡威语',
 				'kbd' => '卡巴尔德语',
 				'kbl' => '加涅姆布语',
 				'kcg' => '卡塔布语',
 				'kde' => '马孔德语',
 				'kea' => '卡布佛得鲁语',
 				'kfo' => '克罗语',
 				'kg' => '刚果语',
 				'kha' => '卡西语',
 				'kho' => '和田语',
 				'khq' => '西桑海语',
 				'ki' => '吉库尤语',
 				'kj' => '宽亚玛语',
 				'kk' => '哈萨克语',
 				'kkj' => '卡库语',
 				'kl' => '格陵兰语',
 				'kln' => '卡伦金语',
 				'km' => '高棉语',
 				'kmb' => '金邦杜语',
 				'kn' => '卡纳达语',
 				'ko' => '韩语',
 				'koi' => '科米-彼尔米亚克语',
 				'kok' => '孔卡尼语',
 				'kos' => '科斯拉伊语',
 				'kpe' => '克佩列语',
 				'kr' => '卡努里语',
 				'krc' => '卡拉恰伊巴尔卡尔语',
 				'krl' => '卡累利阿语',
 				'kru' => '库鲁克语',
 				'ks' => '克什米尔语',
 				'ksb' => '香巴拉语',
 				'ksf' => '巴菲亚语',
 				'ksh' => '科隆语',
 				'ku' => '库尔德语',
 				'kum' => '库梅克语',
 				'kut' => '库特奈语',
 				'kv' => '科米语',
 				'kw' => '康沃尔语',
 				'ky' => '柯尔克孜语',
 				'la' => '拉丁语',
 				'lad' => '拉迪诺语',
 				'lag' => '朗吉语',
 				'lah' => '印度-雅利安语',
 				'lam' => '兰巴语',
 				'lb' => '卢森堡语',
 				'lez' => '列兹金语',
 				'lg' => '卢干达语',
 				'li' => '林堡语',
 				'lkt' => '拉科塔语',
 				'ln' => '林加拉语',
 				'lo' => '老挝语',
 				'lol' => '蒙戈语',
 				'lou' => '路易斯安那克里奥尔语',
 				'loz' => '洛齐语',
 				'lrc' => '北卢尔语',
 				'lt' => '立陶宛语',
 				'lu' => '鲁巴加丹加语',
 				'lua' => '卢巴-卢拉语',
 				'lui' => '卢伊塞诺语',
 				'lun' => '隆达语',
 				'luo' => '卢奥语',
 				'lus' => '米佐语',
 				'luy' => '卢雅语',
 				'lv' => '拉脱维亚语',
 				'mad' => '马都拉语',
 				'maf' => '马法语',
 				'mag' => '摩揭陀语',
 				'mai' => '迈蒂利语',
 				'mak' => '望加锡语',
 				'man' => '曼丁哥语',
 				'mas' => '马赛语',
 				'mde' => '马坝语',
 				'mdf' => '莫克沙语',
 				'mdr' => '曼达尔语',
 				'men' => '门德语',
 				'mer' => '梅鲁语',
 				'mfe' => '毛里求斯克里奥尔语',
 				'mg' => '马拉加斯语',
 				'mga' => '中古爱尔兰语',
 				'mgh' => '马库阿语',
 				'mgo' => '梅塔语',
 				'mh' => '马绍尔语',
 				'mi' => '毛利语',
 				'mic' => '密克马克语',
 				'min' => '米南佳保语',
 				'mk' => '马其顿语',
 				'ml' => '马拉雅拉姆语',
 				'mn' => '蒙古语',
 				'mnc' => '满语',
 				'mni' => '曼尼普尔语',
 				'moh' => '摩霍克语',
 				'mos' => '莫西语',
 				'mr' => '马拉地语',
 				'ms' => '马来语',
 				'mt' => '马耳他语',
 				'mua' => '蒙当语',
 				'mul' => '多语种',
 				'mus' => '克里克语',
 				'mwl' => '米兰德斯语',
 				'mwr' => '马尔瓦里语',
 				'my' => '缅甸语',
 				'mye' => '姆耶内语',
 				'myv' => '厄尔兹亚语',
 				'mzn' => '马赞德兰语',
 				'na' => '瑙鲁语',
 				'nan' => '闽南语',
 				'nap' => '那不勒斯语',
 				'naq' => '纳马语',
 				'nb' => '书面挪威语',
 				'nd' => '北恩德贝勒语',
 				'nds' => '低地德语',
 				'nds_NL' => '低萨克森语',
 				'ne' => '尼泊尔语',
 				'new' => '尼瓦尔语',
 				'ng' => '恩东加语',
 				'nia' => '尼亚斯语',
 				'niu' => '纽埃语',
 				'nl' => '荷兰语',
 				'nl_BE' => '弗拉芒语',
 				'nmg' => '夸西奥语',
 				'nn' => '挪威尼诺斯克语',
 				'nnh' => '恩甘澎语',
 				'no' => '挪威语',
 				'nog' => '诺盖语',
 				'non' => '古诺尔斯语',
 				'nqo' => '西非书面文字',
 				'nr' => '南恩德贝勒语',
 				'nso' => '北索托语',
 				'nus' => '努埃尔语',
 				'nv' => '纳瓦霍语',
 				'nwc' => '古典尼瓦尔语',
 				'ny' => '齐切瓦语',
 				'nym' => '尼扬韦齐语',
 				'nyn' => '尼昂科勒语',
 				'nyo' => '尼奥罗语',
 				'nzi' => '恩济马语',
 				'oc' => '奥克语',
 				'oj' => '奥吉布瓦语',
 				'om' => '奥罗莫语',
 				'or' => '奥里亚语',
 				'os' => '奥塞梯语',
 				'osa' => '奥塞治语',
 				'ota' => '奥斯曼土耳其语',
 				'pa' => '旁遮普语',
 				'pag' => '邦阿西南语',
 				'pal' => '巴拉维语',
 				'pam' => '邦板牙语',
 				'pap' => '帕皮阿门托语',
 				'pau' => '帕劳语',
 				'pcm' => '尼日利亚皮钦语',
 				'peo' => '古波斯语',
 				'phn' => '腓尼基语',
 				'pi' => '巴利语',
 				'pl' => '波兰语',
 				'pon' => '波纳佩语',
 				'prg' => '普鲁士语',
 				'pro' => '古普罗文斯语',
 				'ps' => '普什图语',
 				'pt' => '葡萄牙语',
 				'pt_BR' => '巴西葡萄牙语',
 				'pt_PT' => '欧洲葡萄牙语',
 				'qu' => '克丘亚语',
 				'quc' => '基切语',
 				'raj' => '拉贾斯坦语',
 				'rap' => '拉帕努伊语',
 				'rar' => '拉罗汤加语',
 				'rm' => '罗曼什语',
 				'rn' => '隆迪语',
 				'ro' => '罗马尼亚语',
 				'ro_MD' => '摩尔多瓦语',
 				'rof' => '兰博语',
 				'rom' => '吉普赛语',
 				'root' => '根语言',
 				'ru' => '俄语',
 				'rup' => '阿罗马尼亚语',
 				'rw' => '卢旺达语',
 				'rwk' => '罗瓦语',
 				'sa' => '梵语',
 				'sad' => '桑达韦语',
 				'sah' => '萨哈语',
 				'sam' => '萨马利亚阿拉姆语',
 				'saq' => '桑布鲁语',
 				'sas' => '萨萨克文',
 				'sat' => '桑塔利语',
 				'sba' => '甘拜语',
 				'sbp' => '桑古语',
 				'sc' => '萨丁语',
 				'scn' => '西西里语',
 				'sco' => '苏格兰语',
 				'sd' => '信德语',
 				'sdh' => '南库尔德语',
 				'se' => '北方萨米语',
 				'see' => '塞内卡语',
 				'seh' => '塞纳语',
 				'sel' => '塞尔库普语',
 				'ses' => '东桑海语',
 				'sg' => '桑戈语',
 				'sga' => '古爱尔兰语',
 				'sh' => '塞尔维亚-克罗地亚语',
 				'shi' => '希尔哈语',
 				'shn' => '掸语',
 				'shu' => '乍得阿拉伯语',
 				'si' => '僧伽罗语',
 				'sid' => '悉达摩语',
 				'sk' => '斯洛伐克语',
 				'sl' => '斯洛文尼亚语',
 				'sm' => '萨摩亚语',
 				'sma' => '南萨米语',
 				'smj' => '吕勒萨米语',
 				'smn' => '伊纳里萨米语',
 				'sms' => '斯科特萨米语',
 				'sn' => '绍纳语',
 				'snk' => '索宁克语',
 				'so' => '索马里语',
 				'sog' => '粟特语',
 				'sq' => '阿尔巴尼亚语',
 				'sr' => '塞尔维亚语',
 				'srn' => '苏里南汤加语',
 				'srr' => '塞雷尔语',
 				'ss' => '斯瓦蒂语',
 				'ssy' => '萨霍语',
 				'st' => '南索托语',
 				'su' => '巽他语',
 				'suk' => '苏库马语',
 				'sus' => '苏苏语',
 				'sux' => '苏美尔语',
 				'sv' => '瑞典语',
 				'sw' => '斯瓦希里语',
 				'sw_CD' => '刚果斯瓦希里语',
 				'swb' => '科摩罗语',
 				'syc' => '古典叙利亚语',
 				'syr' => '叙利亚语',
 				'ta' => '泰米尔语',
 				'te' => '泰卢固语',
 				'tem' => '泰姆奈语',
 				'teo' => '特索语',
 				'ter' => '特伦诺语',
 				'tet' => '德顿语',
 				'tg' => '塔吉克语',
 				'th' => '泰语',
 				'ti' => '提格利尼亚语',
 				'tig' => '提格雷语',
 				'tiv' => '蒂夫语',
 				'tk' => '土库曼语',
 				'tkl' => '托克劳语',
 				'tl' => '他加禄语',
 				'tlh' => '克林贡语',
 				'tli' => '特林吉特语',
 				'tmh' => '塔马奇克语',
 				'tn' => '茨瓦纳语',
 				'to' => '汤加语',
 				'tog' => '尼亚萨汤加语',
 				'tpi' => '托克皮辛语',
 				'tr' => '土耳其语',
 				'trv' => '赛德克语',
 				'ts' => '聪加语',
 				'tsi' => '钦西安语',
 				'tt' => '鞑靼语',
 				'tum' => '通布卡语',
 				'tvl' => '图瓦卢语',
 				'tw' => '契维语',
 				'twq' => '北桑海语',
 				'ty' => '塔希提语',
 				'tyv' => '图瓦语',
 				'tzm' => '塔马齐格特语',
 				'udm' => '乌德穆尔特语',
 				'ug' => '维吾尔语',
 				'uga' => '乌加里特语',
 				'uk' => '乌克兰语',
 				'umb' => '翁本杜语',
 				'und' => '未知语言',
 				'ur' => '乌尔都语',
 				'uz' => '乌兹别克语',
 				'vai' => '瓦伊语',
 				've' => '文达语',
 				'vep' => '维普森语',
 				'vi' => '越南语',
 				'vo' => '沃拉普克语',
 				'vot' => '沃提克语',
 				'vun' => '温旧语',
 				'wa' => '瓦隆语',
 				'wae' => '瓦尔瑟语',
 				'wal' => '瓦拉莫语',
 				'war' => '瓦瑞语',
 				'was' => '瓦绍语',
 				'wbp' => '瓦尔皮瑞语',
 				'wo' => '沃洛夫语',
 				'wuu' => '吴语',
 				'xal' => '卡尔梅克语',
 				'xh' => '科萨语',
 				'xog' => '索加语',
 				'yao' => '瑶族语',
 				'yap' => '雅浦语',
 				'yav' => '洋卞语',
 				'ybb' => '耶姆巴语',
 				'yi' => '意第绪语',
 				'yo' => '约鲁巴语',
 				'yue' => '粤语',
 				'za' => '壮语',
 				'zap' => '萨波蒂克语',
 				'zbl' => '布里斯符号',
 				'zen' => '泽纳加语',
 				'zgh' => '标准摩洛哥塔马塞特语',
 				'zh' => '中文',
 				'zh_Hans' => '简体中文',
 				'zh_Hant' => '繁体中文',
 				'zu' => '祖鲁语',
 				'zun' => '祖尼语',
 				'zxx' => '无语言内容',
 				'zza' => '扎扎语',

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
 			'Afak' => '阿法卡文',
 			'Aghb' => 'Aghb',
 			'Ahom' => 'Ahom',
 			'Arab' => '阿拉伯文',
 			'Arab@alt=variant' => '波斯阿拉伯文',
 			'Armi' => '皇室亚拉姆文',
 			'Armn' => '亚美尼亚文',
 			'Avst' => '阿维斯陀文',
 			'Bali' => '巴厘文',
 			'Bamu' => '巴姆穆文',
 			'Bass' => '巴萨文',
 			'Batk' => '巴塔克文',
 			'Beng' => '孟加拉文',
 			'Bhks' => '拜克舒克文',
 			'Blis' => '布列斯符号',
 			'Bopo' => '汉语拼音',
 			'Brah' => '婆罗米文字',
 			'Brai' => '布莱叶盲文',
 			'Bugi' => '布吉文',
 			'Buhd' => '布希德文',
 			'Cakm' => '查克马文',
 			'Cans' => '加拿大土著统一音节',
 			'Cari' => '卡里亚文',
 			'Cham' => '占文',
 			'Cher' => '切罗基文',
 			'Cirt' => '色斯文',
 			'Copt' => '克普特文',
 			'Cprt' => '塞浦路斯文',
 			'Cyrl' => '西里尔文',
 			'Cyrs' => '西里尔文字（古教会斯拉夫文的变体）',
 			'Deva' => '天城文',
 			'Dsrt' => '德塞莱特文',
 			'Dupl' => '杜普洛伊速记',
 			'Egyd' => '后期埃及文',
 			'Egyh' => '古埃及僧侣书写体',
 			'Egyp' => '古埃及象形文',
 			'Elba' => '爱尔巴桑文',
 			'Ethi' => '埃塞俄比亚文',
 			'Geok' => '格鲁吉亚文（教堂体）',
 			'Geor' => '格鲁吉亚文',
 			'Glag' => '格拉哥里文',
 			'Gonm' => '马萨拉姆冈德文',
 			'Goth' => '哥特文',
 			'Gran' => '格兰塔文',
 			'Grek' => '希腊文',
 			'Gujr' => '古吉拉特文',
 			'Guru' => '果鲁穆奇文',
 			'Hanb' => '汉语注音',
 			'Hang' => '谚文',
 			'Hani' => '汉字',
 			'Hano' => '汉奴罗文',
 			'Hans' => '简体',
 			'Hans@alt=stand-alone' => '简体中文',
 			'Hant' => '繁体',
 			'Hant@alt=stand-alone' => '繁体中文',
 			'Hatr' => 'Hatr',
 			'Hebr' => '希伯来文',
 			'Hira' => '平假名',
 			'Hluw' => '安那托利亚象形文字',
 			'Hmng' => '杨松录苗文',
 			'Hrkt' => '假名表',
 			'Hung' => '古匈牙利文',
 			'Inds' => '印度河文字',
 			'Ital' => '古意大利文',
 			'Jamo' => '韩文字母',
 			'Java' => '爪哇文',
 			'Jpan' => '日文',
 			'Jurc' => '女真文',
 			'Kali' => '克耶李文字',
 			'Kana' => '片假名',
 			'Khar' => '卡罗须提文',
 			'Khmr' => '高棉文',
 			'Khoj' => '克吉奇文字',
 			'Knda' => '卡纳达文',
 			'Kore' => '韩文',
 			'Kpel' => '克佩列文',
 			'Kthi' => '凯提文',
 			'Lana' => '兰拿文',
 			'Laoo' => '老挝文',
 			'Latf' => '拉丁文（哥特式字体变体）',
 			'Latg' => '拉丁文（盖尔文变体）',
 			'Latn' => '拉丁文',
 			'Lepc' => '雷布查文',
 			'Limb' => '林布文',
 			'Lina' => '线形文字（A）',
 			'Linb' => '线形文字（B）',
 			'Lisu' => '傈僳文',
 			'Loma' => '洛马文',
 			'Lyci' => '利西亚文',
 			'Lydi' => '吕底亚文',
 			'Mahj' => 'Mahj',
 			'Mand' => '阿拉米文',
 			'Mani' => '摩尼教文',
 			'Marc' => '大玛尔文',
 			'Maya' => '玛雅圣符文',
 			'Mend' => '门迪文',
 			'Merc' => '麦罗埃草书',
 			'Mero' => '麦若提克文',
 			'Mlym' => '马拉雅拉姆文',
 			'Modi' => 'Modi',
 			'Mong' => '蒙古文',
 			'Moon' => '韩文语系',
 			'Mroo' => '谬文',
 			'Mtei' => '曼尼普尔文',
 			'Mult' => 'Mult',
 			'Mymr' => '缅甸文',
 			'Narb' => '古北方阿拉伯文',
 			'Nbat' => '纳巴泰文',
 			'Newa' => '尼瓦文',
 			'Nkgb' => '纳西格巴文',
 			'Nkoo' => '西非书面文字（N’Ko）',
 			'Nshu' => '女书',
 			'Ogam' => '欧甘文',
 			'Olck' => '桑塔利文',
 			'Orkh' => '鄂尔浑文',
 			'Orya' => '奥里亚文',
 			'Osge' => '欧塞奇文',
 			'Osma' => '奥斯曼亚文',
 			'Palm' => '帕尔迈拉文',
 			'Pauc' => '包金豪文',
 			'Perm' => '古彼尔姆文',
 			'Phag' => '八思巴文',
 			'Phli' => '巴列维文碑铭体',
 			'Phlp' => '巴列维文（圣诗体）',
 			'Phlv' => '巴列维文（书体）',
 			'Phnx' => '腓尼基文',
 			'Plrd' => '波拉德音标文字',
 			'Prti' => '帕提亚文碑铭体',
 			'Rjng' => '拉让文',
 			'Roro' => '朗格朗格文',
 			'Runr' => '古代北欧文',
 			'Samr' => '撒马利亚文',
 			'Sara' => '沙拉堤文',
 			'Sarb' => '古南阿拉伯文',
 			'Saur' => '索拉什特拉文',
 			'Sgnw' => '书写符号',
 			'Shaw' => '萧伯纳式文',
 			'Shrd' => '夏拉达文',
 			'Sidd' => '悉昙',
 			'Sind' => '信德文',
 			'Sinh' => '僧伽罗文',
 			'Sora' => '索朗桑朋文',
 			'Soyo' => '索永布文',
 			'Sund' => '巽他文',
 			'Sylo' => '锡尔赫特文',
 			'Syrc' => '叙利亚文',
 			'Syre' => '福音体叙利亚文',
 			'Syrj' => '西叙利亚文',
 			'Syrn' => '东叙利亚文',
 			'Tagb' => '塔格班瓦文',
 			'Takr' => '泰克里文',
 			'Tale' => '泰乐文',
 			'Talu' => '新傣文',
 			'Taml' => '泰米尔文',
 			'Tang' => '唐古特文',
 			'Tavt' => '越南傣文',
 			'Telu' => '泰卢固文',
 			'Teng' => '腾格瓦文字',
 			'Tfng' => '提非纳文',
 			'Tglg' => '塔加路文',
 			'Thaa' => '塔安那文',
 			'Thai' => '泰文',
 			'Tibt' => '藏文',
 			'Tirh' => '迈蒂利文',
 			'Ugar' => '乌加里特文',
 			'Vaii' => '瓦依文',
 			'Visp' => '可见语言',
 			'Wara' => '瓦郎奇蒂文字',
 			'Wole' => '沃莱艾文',
 			'Xpeo' => '古波斯文',
 			'Xsux' => '苏美尔-阿卡德楔形文字',
 			'Yiii' => '彝文',
 			'Zanb' => '札那巴札尔方块文字',
 			'Zinh' => '遗传学术语',
 			'Zmth' => '数学符号',
 			'Zsye' => '表情符号',
 			'Zsym' => '符号',
 			'Zxxx' => '非书面文字',
 			'Zyyy' => '通用',
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
 			'013' => '中美洲',
 			'014' => '东非',
 			'015' => '北非',
 			'017' => '中非',
 			'018' => '南部非洲',
 			'019' => '美洲',
 			'021' => '美洲北部',
 			'029' => '加勒比地区',
 			'030' => '东亚',
 			'034' => '南亚',
 			'035' => '东南亚',
 			'039' => '南欧',
 			'053' => '澳大拉西亚',
 			'054' => '美拉尼西亚',
 			'057' => '密克罗尼西亚地区',
 			'061' => '玻利尼西亚',
 			'142' => '亚洲',
 			'143' => '中亚',
 			'145' => '西亚',
 			'150' => '欧洲',
 			'151' => '东欧',
 			'154' => '北欧',
 			'155' => '西欧',
 			'202' => '撒哈拉以南非洲',
 			'419' => '拉丁美洲',
 			'AC' => '阿森松岛',
 			'AD' => '安道尔',
 			'AE' => '阿拉伯联合酋长国',
 			'AF' => '阿富汗',
 			'AG' => '安提瓜和巴布达',
 			'AI' => '安圭拉',
 			'AL' => '阿尔巴尼亚',
 			'AM' => '亚美尼亚',
 			'AO' => '安哥拉',
 			'AQ' => '南极洲',
 			'AR' => '阿根廷',
 			'AS' => '美属萨摩亚',
 			'AT' => '奥地利',
 			'AU' => '澳大利亚',
 			'AW' => '阿鲁巴',
 			'AX' => '奥兰群岛',
 			'AZ' => '阿塞拜疆',
 			'BA' => '波斯尼亚和黑塞哥维那',
 			'BB' => '巴巴多斯',
 			'BD' => '孟加拉国',
 			'BE' => '比利时',
 			'BF' => '布基纳法索',
 			'BG' => '保加利亚',
 			'BH' => '巴林',
 			'BI' => '布隆迪',
 			'BJ' => '贝宁',
 			'BL' => '圣巴泰勒米',
 			'BM' => '百慕大',
 			'BN' => '文莱',
 			'BO' => '玻利维亚',
 			'BQ' => '荷属加勒比区',
 			'BR' => '巴西',
 			'BS' => '巴哈马',
 			'BT' => '不丹',
 			'BV' => '布韦岛',
 			'BW' => '博茨瓦纳',
 			'BY' => '白俄罗斯',
 			'BZ' => '伯利兹',
 			'CA' => '加拿大',
 			'CC' => '科科斯（基林）群岛',
 			'CD' => '刚果（金）',
 			'CD@alt=variant' => '刚果民主共和国',
 			'CF' => '中非共和国',
 			'CG' => '刚果（布）',
 			'CG@alt=variant' => '刚果共和国',
 			'CH' => '瑞士',
 			'CI' => '科特迪瓦',
 			'CI@alt=variant' => '象牙海岸',
 			'CK' => '库克群岛',
 			'CL' => '智利',
 			'CM' => '喀麦隆',
 			'CN' => '中国',
 			'CO' => '哥伦比亚',
 			'CP' => '克利珀顿岛',
 			'CR' => '哥斯达黎加',
 			'CU' => '古巴',
 			'CV' => '佛得角',
 			'CW' => '库拉索',
 			'CX' => '圣诞岛',
 			'CY' => '塞浦路斯',
 			'CZ' => '捷克',
 			'CZ@alt=variant' => '捷克共和国',
 			'DE' => '德国',
 			'DG' => '迪戈加西亚岛',
 			'DJ' => '吉布提',
 			'DK' => '丹麦',
 			'DM' => '多米尼克',
 			'DO' => '多米尼加共和国',
 			'DZ' => '阿尔及利亚',
 			'EA' => '休达及梅利利亚',
 			'EC' => '厄瓜多尔',
 			'EE' => '爱沙尼亚',
 			'EG' => '埃及',
 			'EH' => '西撒哈拉',
 			'ER' => '厄立特里亚',
 			'ES' => '西班牙',
 			'ET' => '埃塞俄比亚',
 			'EU' => '欧盟',
 			'EZ' => '欧元区',
 			'FI' => '芬兰',
 			'FJ' => '斐济',
 			'FK' => '福克兰群岛',
 			'FK@alt=variant' => '福克兰群岛（马尔维纳斯群岛）',
 			'FM' => '密克罗尼西亚',
 			'FO' => '法罗群岛',
 			'FR' => '法国',
 			'GA' => '加蓬',
 			'GB' => '英国',
 			'GB@alt=short' => '英国',
 			'GD' => '格林纳达',
 			'GE' => '格鲁吉亚',
 			'GF' => '法属圭亚那',
 			'GG' => '根西岛',
 			'GH' => '加纳',
 			'GI' => '直布罗陀',
 			'GL' => '格陵兰',
 			'GM' => '冈比亚',
 			'GN' => '几内亚',
 			'GP' => '瓜德罗普',
 			'GQ' => '赤道几内亚',
 			'GR' => '希腊',
 			'GS' => '南乔治亚和南桑威奇群岛',
 			'GT' => '危地马拉',
 			'GU' => '关岛',
 			'GW' => '几内亚比绍',
 			'GY' => '圭亚那',
 			'HK' => '中国香港特别行政区',
 			'HK@alt=short' => '香港',
 			'HM' => '赫德岛和麦克唐纳群岛',
 			'HN' => '洪都拉斯',
 			'HR' => '克罗地亚',
 			'HT' => '海地',
 			'HU' => '匈牙利',
 			'IC' => '加纳利群岛',
 			'ID' => '印度尼西亚',
 			'IE' => '爱尔兰',
 			'IL' => '以色列',
 			'IM' => '马恩岛',
 			'IN' => '印度',
 			'IO' => '英属印度洋领地',
 			'IQ' => '伊拉克',
 			'IR' => '伊朗',
 			'IS' => '冰岛',
 			'IT' => '意大利',
 			'JE' => '泽西岛',
 			'JM' => '牙买加',
 			'JO' => '约旦',
 			'JP' => '日本',
 			'KE' => '肯尼亚',
 			'KG' => '吉尔吉斯斯坦',
 			'KH' => '柬埔寨',
 			'KI' => '基里巴斯',
 			'KM' => '科摩罗',
 			'KN' => '圣基茨和尼维斯',
 			'KP' => '朝鲜',
 			'KR' => '韩国',
 			'KW' => '科威特',
 			'KY' => '开曼群岛',
 			'KZ' => '哈萨克斯坦',
 			'LA' => '老挝',
 			'LB' => '黎巴嫩',
 			'LC' => '圣卢西亚',
 			'LI' => '列支敦士登',
 			'LK' => '斯里兰卡',
 			'LR' => '利比里亚',
 			'LS' => '莱索托',
 			'LT' => '立陶宛',
 			'LU' => '卢森堡',
 			'LV' => '拉脱维亚',
 			'LY' => '利比亚',
 			'MA' => '摩洛哥',
 			'MC' => '摩纳哥',
 			'MD' => '摩尔多瓦',
 			'ME' => '黑山',
 			'MF' => '法属圣马丁',
 			'MG' => '马达加斯加',
 			'MH' => '马绍尔群岛',
 			'MK' => '马其顿',
 			'MK@alt=variant' => '马其顿（前南斯拉夫马其顿共和国）',
 			'ML' => '马里',
 			'MM' => '缅甸',
 			'MN' => '蒙古',
 			'MO' => '中国澳门特别行政区',
 			'MO@alt=short' => '澳门',
 			'MP' => '北马里亚纳群岛',
 			'MQ' => '马提尼克',
 			'MR' => '毛里塔尼亚',
 			'MS' => '蒙特塞拉特',
 			'MT' => '马耳他',
 			'MU' => '毛里求斯',
 			'MV' => '马尔代夫',
 			'MW' => '马拉维',
 			'MX' => '墨西哥',
 			'MY' => '马来西亚',
 			'MZ' => '莫桑比克',
 			'NA' => '纳米比亚',
 			'NC' => '新喀里多尼亚',
 			'NE' => '尼日尔',
 			'NF' => '诺福克岛',
 			'NG' => '尼日利亚',
 			'NI' => '尼加拉瓜',
 			'NL' => '荷兰',
 			'NO' => '挪威',
 			'NP' => '尼泊尔',
 			'NR' => '瑙鲁',
 			'NU' => '纽埃',
 			'NZ' => '新西兰',
 			'OM' => '阿曼',
 			'PA' => '巴拿马',
 			'PE' => '秘鲁',
 			'PF' => '法属波利尼西亚',
 			'PG' => '巴布亚新几内亚',
 			'PH' => '菲律宾',
 			'PK' => '巴基斯坦',
 			'PL' => '波兰',
 			'PM' => '圣皮埃尔和密克隆群岛',
 			'PN' => '皮特凯恩群岛',
 			'PR' => '波多黎各',
 			'PS' => '巴勒斯坦领土',
 			'PS@alt=short' => '巴勒斯坦',
 			'PT' => '葡萄牙',
 			'PW' => '帕劳',
 			'PY' => '巴拉圭',
 			'QA' => '卡塔尔',
 			'QO' => '大洋洲边远群岛',
 			'RE' => '留尼汪',
 			'RO' => '罗马尼亚',
 			'RS' => '塞尔维亚',
 			'RU' => '俄罗斯',
 			'RW' => '卢旺达',
 			'SA' => '沙特阿拉伯',
 			'SB' => '所罗门群岛',
 			'SC' => '塞舌尔',
 			'SD' => '苏丹',
 			'SE' => '瑞典',
 			'SG' => '新加坡',
 			'SH' => '圣赫勒拿',
 			'SI' => '斯洛文尼亚',
 			'SJ' => '斯瓦尔巴和扬马延',
 			'SK' => '斯洛伐克',
 			'SL' => '塞拉利昂',
 			'SM' => '圣马力诺',
 			'SN' => '塞内加尔',
 			'SO' => '索马里',
 			'SR' => '苏里南',
 			'SS' => '南苏丹',
 			'ST' => '圣多美和普林西比',
 			'SV' => '萨尔瓦多',
 			'SX' => '荷属圣马丁',
 			'SY' => '叙利亚',
 			'SZ' => '斯威士兰',
 			'TA' => '特里斯坦-达库尼亚群岛',
 			'TC' => '特克斯和凯科斯群岛',
 			'TD' => '乍得',
 			'TF' => '法属南部领地',
 			'TG' => '多哥',
 			'TH' => '泰国',
 			'TJ' => '塔吉克斯坦',
 			'TK' => '托克劳',
 			'TL' => '东帝汶',
 			'TM' => '土库曼斯坦',
 			'TN' => '突尼斯',
 			'TO' => '汤加',
 			'TR' => '土耳其',
 			'TT' => '特立尼达和多巴哥',
 			'TV' => '图瓦卢',
 			'TW' => '台湾',
 			'TZ' => '坦桑尼亚',
 			'UA' => '乌克兰',
 			'UG' => '乌干达',
 			'UM' => '美国本土外小岛屿',
 			'UN' => '联合国',
 			'UN@alt=short' => '联合国',
 			'US' => '美国',
 			'US@alt=short' => '美国',
 			'UY' => '乌拉圭',
 			'UZ' => '乌兹别克斯坦',
 			'VA' => '梵蒂冈',
 			'VC' => '圣文森特和格林纳丁斯',
 			'VE' => '委内瑞拉',
 			'VG' => '英属维尔京群岛',
 			'VI' => '美属维尔京群岛',
 			'VN' => '越南',
 			'VU' => '瓦努阿图',
 			'WF' => '瓦利斯和富图纳',
 			'WS' => '萨摩亚',
 			'XK' => '科索沃',
 			'YE' => '也门',
 			'YT' => '马约特',
 			'ZA' => '南非',
 			'ZM' => '赞比亚',
 			'ZW' => '津巴布韦',
 			'ZZ' => '未知地区',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => '传统德文拼字',
 			'1994' => '标准雷西亚拼字',
 			'1996' => '1996 年德文拼字',
 			'1606NICT' => '1606 年前中后期法文',
 			'1694ACAD' => '早期现代法文',
 			'1959ACAD' => '学术',
 			'ABL1943' => '1943年正写法构想',
 			'ALALC97' => '1997 版 ALA-LC 罗马字',
 			'ALUKU' => '阿鲁库方言',
 			'AO1990' => '1990年葡萄牙语正写法协议',
 			'AREVELA' => '东亚美尼亚文',
 			'AREVMDA' => '西亚美尼亚文',
 			'BAKU1926' => '统一土耳其拉丁字母',
 			'BALANKA' => '阿尼语Balanka方言',
 			'BASICENG' => '基本英语',
 			'BAUDDHA' => '佛陀梵文',
 			'BISCAYAN' => '比斯开方言',
 			'BISKE' => '圣乔治/比拉方言',
 			'BOONT' => '布恩特林方言',
 			'FONIPA' => '国际音标',
 			'FONUPA' => 'UPA 音标',
 			'FONXSAMP' => 'X-SAMPA 音标',
 			'HEPBURN' => '赫伯恩罗马字',
 			'HOGNORSK' => '高地挪威文',
 			'ITIHASA' => '史诗梵文',
 			'JAUER' => '米施泰尔方言',
 			'JYUTPING' => '粤语拼音',
 			'KKCOR' => '常用拼字',
 			'LAUKIKA' => '传统梵文',
 			'LIPAW' => '雷西亚 Lipovaz 方言',
 			'LUNA1918' => '俄文拼字（1918年起）',
 			'MONOTON' => '单音字母',
 			'NDYUKA' => 'Ndyuka 方言',
 			'NEDIS' => 'Natisone 方言',
 			'NJIVA' => 'Gniva/Njiva 方言',
 			'OSOJS' => 'Oseacco/Osojane 方言',
 			'PAMAKA' => 'Pamaka 方言',
 			'PETR1708' => '俄文拼字（1708年）',
 			'PINYIN' => '拼音罗马字',
 			'POLYTON' => '多音字母',
 			'POSIX' => '电脑',
 			'PUTER' => '瑞士普特尔方言',
 			'REVISED' => '修订的拼字',
 			'ROZAJ' => '雷西亚文',
 			'RUMGR' => '罗曼什文',
 			'SAAHO' => '萨霍文',
 			'SCOTLAND' => '苏格兰标准英文',
 			'SCOUSE' => '利物浦方言',
 			'SOLBA' => 'Stolvizza/Solbica 方言',
 			'SURMIRAN' => '瑞士苏迈拉方言',
 			'SURSILV' => '瑞士苏瑟瓦方言',
 			'SUTSILV' => '瑞士苏希瓦方言',
 			'TARASK' => 'Taraskievica 拼字',
 			'UCCOR' => '统一的拼字',
 			'UCRCOR' => '统一和修订的拼字',
 			'ULSTER' => '阿尔斯特方言',
 			'VAIDIKA' => '吠陀梵文',
 			'VALENCIA' => '瓦伦西亚文',
 			'VALLADER' => '瑞士瓦勒德方言',
 			'WADEGILE' => 'WG 威氏拼音法',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => '日历',
 			'cf' => '货币格式',
 			'colalternate' => '忽略符号排序',
 			'colbackwards' => '对重音进行逆向排序',
 			'colcasefirst' => '大写/小写字母排序',
 			'colcaselevel' => '区分大小写的排序',
 			'collation' => '排序',
 			'colnormalization' => '规范化排序',
 			'colnumeric' => '数字排序',
 			'colstrength' => '排序强度',
 			'currency' => '货币',
 			'hc' => '小时制（12或24）',
 			'lb' => '换行符样式',
 			'ms' => '度量衡制',
 			'numbers' => '数字',
 			'timezone' => '时区',
 			'va' => '语言区域别名',
 			'x' => '专用',

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
 				'ethiopic' => q{埃塞俄比亚历},
 				'ethiopic-amete-alem' => q{埃塞俄比亚阿米特阿莱姆日历},
 				'gregorian' => q{公历},
 				'hebrew' => q{希伯来历},
 				'indian' => q{印度国定历},
 				'islamic' => q{伊斯兰历},
 				'islamic-civil' => q{伊斯兰希吉来日历},
 				'islamic-umalqura' => q{伊斯兰历（乌姆库拉）},
 				'iso8601' => q{国际标准历法},
 				'japanese' => q{和历},
 				'persian' => q{波斯历},
 				'roc' => q{民国纪年},
 			},
 			'cf' => {
 				'account' => q{会计货币格式},
 				'standard' => q{标准货币格式},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{对符号进行排序},
 				'shifted' => q{忽略符号进行排序},
 			},
 			'colbackwards' => {
 				'no' => q{对重音进行正常排序},
 				'yes' => q{对重音进行逆向排序},
 			},
 			'colcasefirst' => {
 				'lower' => q{先对小写字母进行排序},
 				'no' => q{对正常大小写顺序进行排序},
 				'upper' => q{先对大写字母进行排序},
 			},
 			'colcaselevel' => {
 				'no' => q{不区分大小写进行排序},
 				'yes' => q{区分大小写进行排序},
 			},
 			'collation' => {
 				'big5han' => q{繁体中文排序 - Big5},
 				'compat' => q{基于兼容性沿用既往排序},
 				'dictionary' => q{字典排序},
 				'ducet' => q{默认 Unicode 排序},
 				'emoji' => q{表情符号排序},
 				'eor' => q{欧洲排序规则},
 				'gb2312han' => q{简体中文排序 - GB2312},
 				'phonebook' => q{电话簿排序},
 				'phonetic' => q{语音排序},
 				'pinyin' => q{拼音排序},
 				'reformed' => q{改良排序},
 				'search' => q{常规搜索},
 				'searchjl' => q{按韩文字开首辅音来搜索},
 				'standard' => q{标准排序},
 				'stroke' => q{笔画排序},
 				'traditional' => q{传统排序},
 				'unihan' => q{部首笔画排序},
 				'zhuyin' => q{注音排序},
 			},
 			'colnormalization' => {
 				'no' => q{非规范化排序},
 				'yes' => q{对 Unicode 进行规范化排序},
 			},
 			'colnumeric' => {
 				'no' => q{对数字进行单独排序},
 				'yes' => q{按数字顺序对数字进行排序},
 			},
 			'colstrength' => {
 				'identical' => q{对所有内容进行排序},
 				'primary' => q{只对基本字母进行排序},
 				'quaternary' => q{对重音/大小写/长度/假名进行排序},
 				'secondary' => q{对重音进行排序},
 				'tertiary' => q{对重音/大小写/长度进行排序},
 			},
 			'd0' => {
 				'fwidth' => q{全角},
 				'hwidth' => q{半角},
 				'npinyin' => q{数字},
 			},
 			'hc' => {
 				'h11' => q{12小时制（0–11）},
 				'h12' => q{12小时制（1–12）},
 				'h23' => q{24小时制（0–23）},
 				'h24' => q{24小时制（1–24）},
 			},
 			'lb' => {
 				'loose' => q{宽松换行符样式},
 				'normal' => q{正常换行符样式},
 				'strict' => q{严格换行符样式},
 			},
 			'm0' => {
 				'bgn' => q{美国地名委员会 (BGN)},
 				'ungegn' => q{联合国地名专家组 (UNGEGN)},
 			},
 			'ms' => {
 				'metric' => q{公制},
 				'uksystem' => q{英制},
 				'ussystem' => q{美制},
 			},
 			'numbers' => {
 				'ahom' => q{阿霍姆数字},
 				'arab' => q{阿拉伯-印度数字},
 				'arabext' => q{扩展阿拉伯-印度数字},
 				'armn' => q{亚美尼亚数字},
 				'armnlow' => q{亚美尼亚小写数字},
 				'bali' => q{巴厘文数字},
 				'beng' => q{孟加拉数字},
 				'brah' => q{婆罗米数字},
 				'cakm' => q{查克玛数字},
 				'cham' => q{占文数字},
 				'cyrl' => q{斯拉夫数字},
 				'deva' => q{梵文数字},
 				'ethi' => q{埃塞俄比亚数字},
 				'finance' => q{金融数字},
 				'fullwide' => q{全角数字},
 				'geor' => q{格鲁吉亚数字},
 				'gonm' => q{马萨拉姆冈德数字},
 				'grek' => q{希腊数字},
 				'greklow' => q{希腊小写数字},
 				'gujr' => q{古吉拉特数字},
 				'guru' => q{果鲁穆奇数字},
 				'hanidec' => q{中文十进制数字},
 				'hans' => q{简体中文数字},
 				'hansfin' => q{简体中文大写数字},
 				'hant' => q{繁体中文数字},
 				'hantfin' => q{繁体中文大写数字},
 				'hebr' => q{希伯来数字},
 				'hmng' => q{杨松录苗文数字},
 				'java' => q{爪哇文数字},
 				'jpan' => q{日文数字},
 				'jpanfin' => q{日文大写数字},
 				'kali' => q{克耶字母数字},
 				'khmr' => q{高棉数字},
 				'knda' => q{卡纳达数字},
 				'lana' => q{老傣文数字},
 				'lanatham' => q{兰纳文数字},
 				'laoo' => q{老挝数字},
 				'latn' => q{西方数字},
 				'lepc' => q{雷布查文数字},
 				'limb' => q{林布文数字},
 				'mathbold' => q{数学粗体数字},
 				'mlym' => q{马拉雅拉姆数字},
 				'mong' => q{蒙古文数字},
 				'mtei' => q{曼尼普尔数字},
 				'mymr' => q{缅甸数字},
 				'mymrshan' => q{缅甸掸文数字},
 				'native' => q{当地数字},
 				'nkoo' => q{曼德数字},
 				'olck' => q{桑塔利文数字},
 				'orya' => q{奥里亚数字},
 				'roman' => q{罗马数字},
 				'romanlow' => q{罗马小写数字},
 				'saur' => q{索拉什特拉文数字},
 				'sund' => q{苏丹文数字},
 				'takr' => q{泰克里数字},
 				'talu' => q{新傣仂文数字},
 				'taml' => q{传统泰米尔数字},
 				'tamldec' => q{泰米尔数字},
 				'telu' => q{泰卢固数字},
 				'thai' => q{泰文数字},
 				'tibt' => q{藏文数字},
 				'tirh' => q{迈蒂利数字},
 				'traditional' => q{传统数字},
 				'vaii' => q{瓦伊文数字},
 				'wara' => q{瓦郎奇蒂数字},
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
			auxiliary => qr{[乒 乓 仂 仓 伞 侣 傈 傣 僳 冥 凉 刨 匕 卑 卞 厘 厦 厨 吕 呣 唇 啤 啮 喱 嗅 噘 噢 坝 堤 墟 奎 妆 婴 媚 宅 寺 尬 尴 屑 屿 巽 巾 弓 彗 惊 戟 扔 扰 扳 抛 挂 捂 摇 撅 撤 杆 杖 柜 柱 栗 栽 桶 棍 棕 棺 楔 楠 榈 槟 橙 洒 浆 涌 淇 滕 滚 滩 灾 烛 烟 焰 煎 犬 猫 瑚 瓢 甫 皱 盆 盔 盲 眨 眯 瞌 矿 碑 祈 祭 祷 禄 稻 竿 笼 筒 篷 粟 粮 纠 纬 缆 缎 耸 脚 舔 舵 艇 艮 芽 苜 苞 菇 菱 葫 葵 蒸 蓿 蔽 薯 蘑 蚂 蛛 蜗 蜘 蜡 蝎 蝴 螃 裹 谍 谬 豚 账 跤 踪 躬 轴 辐 迹 郁 鄙 酢 钉 钥 钮 钯 铂 铅 铛 锄 锑 锚 锤 镑 闺 阱 隧 雕 霾 靴 靶 鞠 颠 馏 驼 骆 髦 魁 鲤 鲸 鳄 鸽]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[一 丁 七 万-与 丑 专 且 世 丘-业 东 丝 丢 两 严 丧 个 中 丰 串 临 丸-主 丽 举 乃 久 么 义 之-乐 乔 乖 乘 乙 九 也-乡 书 买 乱 乾 了 予 争 事 二 于 亏 云 互 五 井 亚 些 亡 交-亨 享 京 亮 亲 人 亿-仁 仅 仇 今 介 仍 从 仔 他 付 仙 代-以 仪 们 仰 仲 件 价 任 份 仿 企 伊 伍 伏-休 众-会 伟 传 伤 伦 伯 估 伴 伸 似 伽 但 位-佑 体 何 余 佛 作 你 佤 佩 佳 使 例 供 依 侠 侦-侨 侬 侯 侵 便 促 俄 俊 俗 保 信 俩 修 俱 俾 倍 倒 候 倚 借 倦 值 倾 假 偌 偏 做 停 健 偶 偷 储 催 傲 傻 像 僧 儒 儿 允 元-兆 先 光 克 免 兑 兔 党 入 全 八-兮 兰 共 关-兹 养-兽 内 冈 册 再 冒 写 军 农 冠 冬 冰 冲 决 况 冷 准 凌 减 凝 几 凡 凤 凭 凯 凰 出 击 函 刀 分 切 刊 刑 划 列-创 初 判 利 别 到 制-券 刺 刻 剂 前 剑 剧 剩 剪 副 割 力 劝-务 劣 动-劫 励-劳 势 勇 勉 勋 勒 勤 勾 勿 包 匆 匈 化 北 匙 匹-医 十 千 升 午 半 华 协 卒 卓 单-南 博 占-卢 卫 卯-危 即 却 卷 厂 厄-历 厉 压-厍 厚 原 去 县 参 又-反 发 叔 取-叙 口-另 只-叭 可 台 史 右 叶-叹 吃 各 合-吊 同-后 吐 向 吓 吗 君 吝 吟 否 吧 含 听 启 吵 吸 吹 吻 吾 呀 呆 呈 告 呐 员 呜 呢 呦 周 味 呵 呼 命 和 咖 咦-咨 咪 咬 咯 咱 哀 品 哇-哉 响 哎 哟 哥 哦 哩 哪 哭 哲 唉 唐 唤 唬 售 唯 唱 唷 商 啊 啡 啥 啦 啪 喀 喂 善 喇 喊 喏 喔 喜 喝 喵 喷 喻 嗒 嗨 嗯 嘉 嘛 嘴 嘻 嘿 器 四 回 因 团 园 困 围 固 国 图 圆 圈 土 圣 在 圭 地 圳 场 圾 址 均 坎 坐 坑 块 坚-坜 坡 坤 坦 坪 垂 垃 型 垒 埃 埋 城 埔 域 培 基 堂 堆 堕 堡 堪 塑 塔 塞 填 境 增 墨 壁 壤 士 壬 壮 声 处 备 复 夏 夕 外 多 夜 够 夥 大 天-夫 央 失 头 夷-夺 奇-奉 奋 奏 契 奔 奖 套 奥 女 奴 奶 她 好 如 妇 妈 妖 妙 妥 妨 妮 妹 妻 姆 姊 始 姐 姑 姓 委 姿 威 娃 娄 娘 娜 娟 娱 婆 婚 媒 嫁 嫌 嫩 子 孔 孕 字-孙 孜 孝 孟 季 孤 学 孩 宁 它 宇-安 宋 完 宏 宗-实 审-室 宪 害 宴 家 容 宽-宿 寂 寄-寇 富 寒 寝-察 寡 寨 寸 对 寻 导 寿 封 射 将 尊 小 少 尔 尖 尘 尚 尝 尤 就 尺 尼-尾 局-层 居 屋 屏 展 属 屠 山 岁 岂 岗 岘 岚 岛 岳 岸 峡 峰 崇 崩 崴 川 州 巡 工-巨 巫 差 己-巴 巷 币-布 帅 师 希 帐 帕 帖 帝 带 席 帮 常 帽 幅 幕 干-年 并 幸 幻-幽 广 庆 床 序 库-底 店 庙 庚 府 庞 废 度 座 庭 康 庸 廉 廖 延 廷 建 开 异-弄 弊 式 引 弗 弘 弟 张 弥 弦 弯 弱 弹 强 归 当 录 彝 形 彩 彬 彭 彰 影 彷 役 彻 彼 往 征 径 待 很 律 後 徐 徒 得 循 微 徵 德 心 必 忆 忌 忍 志-忙 忠 忧 快 念 忽 怀 态 怎 怒 怕 怖 思 怡 急 性 怨 怪 总 恋 恐 恢 恨 恩 恭 息 恰 恶 恼 悄 悉 悔 悟 悠 患 您 悲 情 惑 惜 惠 惧 惨 惯 想 惹 愁 愈 愉 意 愚 感 愧 慈 慎 慕 慢 慧 慰 憾 懂 懒 戈 戊 戌 戏-戒 或 战 截 戴 户 房-扁 扇 手 才 扎 扑 打 托 扣 执 扩 扫-扯 批 找-技 抄 把 抑 抓 投 抗 折 抢 护 报 披 抬 抱 抵 抹 抽 担 拆 拉 拍 拒 拔 拖 拘 招 拜 拟 拥 拦 拨 择 括 拳 拷 拼 拾 拿 持 指 按 挑 挖 挝 挡 挤 挥 挪 振 挺 捉 捐 捕 损 捡 换 据 捷 授 掉 掌 排 探 接 控-措 掸 描 提 插 握 援 搜 搞 搬 搭 摄 摆 摊 摔 摘 摩 摸 撒 撞 播 操 擎 擦 支 收 改 攻 放 政 故 效 敌 敏 救 教 敝 敢 散 敦 敬 数 敲 整 文 斋 斐 斗 料 斜 斥 断 斯 新 方 於 施 旁 旅 旋 族 旗 无 既 日-早 旭 时 旺 昂 昆 昌 明 昏 易 星 映 春 昨 昭 是 显 晃 晋 晒 晓 晚 晨 普 景 晴 晶 智 暂 暑 暖 暗 暮 暴 曰 曲 更 曹 曼 曾-最 月 有 朋 服 朗 望 朝 期 木 未-札 术 朱 朵 机 杀 杂 权 杉 李 材 村 杜 束 条 来 杨 杯 杰 松 板 极 构 析 林 果 枝 枢 枪 枫 架 柏 某 染 柔 查 柬 柯 柳 柴 标 栋 栏 树 校 样-根 格 桃 框 案 桌 桑 档 桥 梁 梅 梦 梯 械 梵 检 棉 棋 棒 棚 森 椅 植 椰 楚 楼 概 榜 模 樱 檀 欠-欣 欧 欲 欺 款 歉 歌 止-武 歪 死 殊 残 段 毅 母 每 毒 比 毕 毛 毫 氏 民 气 氛 水 永 求 汇 汉 汗 汝 江-污 汤 汪 汶 汽 沃 沈 沉 沙 沟 没 沧 河 油 治 沿 泉 泊 法 泛 泡-泣 泥 注 泰 泳 泽 洋 洗 洛 洞 津 洪 洲 活 洽 派 流 浅 测 济 浏 浑 浓 浙 浦 浩 浪 浮 浴 海 涅 消 涉 涛 涨 涯 液 涵 淋 淑 淘 淡 深 混 添 清 渐 渡 渣 温 港 渴 游 湖 湾 源 溜 溪 滋 滑 满 滥 滨 滴 漂 漏 演 漠 漫 潘 潜 潮 澎 澳 激 灌 火 灭 灯 灰 灵 灿 炉 炎 炮 炸 点 烂 烈 烤 烦 烧 热 焦 然 煌 煞 照 煮 熊 熟 燃 燕 爆 爪 爬 爱 爵-爸 爽 片 版 牌 牙 牛 牡 牢 牧 物 牲 牵 特 牺 犯 状 犹 狂 狐 狗 狠 独 狮 狱 狼 猛 猜 猪 献 猴 玄 率 玉 王 玛 玩 玫 环 现 玲 玻 珀 珊 珍 珠 班 球 理 琊 琪 琳 琴 琼 瑙 瑜 瑞 瑟 瑰 瑶 璃 瓜 瓦 瓶 甘 甚 甜 生 用 田-申 电 男 甸 画 畅 界 留 略 番 疆 疏 疑 疗 疯 疲 疼 疾 病 痕 痛 痴 癸 登 白 百 的 皆 皇 皮 盈 益 监 盒 盖 盘 盛 盟 目 直 相 盼 盾 省 眉 看 真 眠 眼 着 睛 睡 督 瞧 矛 矣 知 短 石 矶 码 砂 砍 研 破 础 硕 硬 确 碍 碎 碗 碟 碧 碰 磁 磅 磨 示 礼 社 祖 祚 祝 神 祥 票 祯 祸 禁 禅 福 离 秀 私 秋 种 科 秒 秘 租 秤 秦 秩 积 称 移 稀 程 稍 税 稣 稳 稿 穆 究 穷 穹 空 穿 突 窗 窝 立 站 竞-章 童 端 竹 笑 笔 笛 符 笨 第 等 筋 筑 答 策 筹 签 简 算 管 箭 箱 篇 篮 簿 籍 米 类 粉 粒 粗 粤 粹 精 糊 糕 糖 糟 系 素 索 紧 紫 累 繁 红 约 级 纪 纯 纲 纳 纵 纷 纸 纽 线 练 组 细-终 绍 经 结 绕 绘 给 络 绝 统 继 绩 绪 续 维 绵 综 绿 缅 缓 编 缘 缠 缩 缴 缶 缸 缺 罐 网 罕 罗 罚 罢 罪 置 署 羊 美 羞 群 羯 羽 翁 翅 翔 翘 翠 翰 翻 翼 耀 老 考 者 而 耍 耐 耗 耳 耶 聊 职 联 聘 聚 聪 肉 肖 肚 股 肤 肥 肩 肯 育 胁 胆 背 胎 胖 胜 胞 胡 胶 胸 能 脆 脑 脱 脸 腊 腐 腓 腰 腹 腾 腿 臂 臣 自 臭 至 致 舌 舍 舒 舞 舟 航 般 舰 船 良 色 艺 艾 节 芒 芝 芦 芬 芭 花 芳 苍 苏 苗 若 苦 英 茂 范 茨 茫 茶 草 荐 荒 荣 药 荷 莉 莎 莪 莫 莱 莲 获 菜 菩 菲 萄 萍 萤 营 萧 萨 落 著 葛 葡 蒂 蒋 蒙 蓉 蓝 蓬 蔑 蔡 薄 薪 藉 藏 藤 虎 虑 虫 虹 虽 虾 蚁 蛇 蛋 蛙 蛮 蜂 蜜 蝶 融 蟹 蠢 血 行 街 衡 衣 补 表 袋 被 袭 裁 裂 装 裕 裤 西 要 覆 见 观 规 视 览 觉 角 解 言 誉 誓 警 计 订 认 讨 让 训-记 讲 讷 许 论 设 访 证 评 识 诉 词 译 试 诗 诚 话 诞 询 该 详 语 误 说 请 诸 诺 读 课 谁 调 谅 谈 谊 谋 谓 谜 谢 谨 谱 谷 豆 象 豪 貌 贝-负 贡-败 货-贪 购 贯 贱 贴 贵 贸-贺 贼 贾 资 赋 赌 赏 赐 赔 赖 赚 赛 赞 赠 赢 赤 赫 走 赵 起 趁 超 越 趋 趣 足 跃 跌 跑 距 跟 路 跳 踏 踢 踩 身 躲 车 轨 轩 转 轮-轰 轻 载 较 辅 辆 辈 辉 辑 输 辛 辞 辨 辩 辰 辱 边 达 迁 迅 过 迈 迎 运 近 返 还 这 进-迟 迦 迪 迫 述 迷 追 退-逃 逆 选 逊 透 逐 递 途 通 逛 逝 速 造 逢 逸 逻 逼 遇 遍 道 遗 遭 遮 遵 避 邀 邓 那 邦 邪 邮 邱 邻 郎 郑 部 郭 都 鄂 酉 酋 配 酒 酷 酸 醉 醒 采 释 里-量 金 针 钓 钟 钢 钦 钱 钻 铁 铃 铜 铢 铭 银 铺 链 销 锁 锅 锋 错 锡 锦 键 锺 镇 镜 镭 长 门 闪 闭 问 闰 闲 间 闷 闹 闻 阁 阅 阐 阔 队 阮 防-阶 阻 阿 陀 附-陆 陈 降 限 院 除 险 陪 陵-陷 隆 随 隐 隔 障 难 雄-集 雉 雨 雪 雯 雳 零 雷 雾 需 震 霍 霖 露 霸 霹 青 靖 静 非 靠 面 革 靼 鞋 鞑 韦 韩 音 页 顶 项-须 顽-顿 预 领 颇 频 颗 题 额 风 飘 飙 飞 食 餐 饭 饮 饰 饱 饼 馆 首 香 馨 马 驱 驶 驻 驾 验 骑 骗 骚 骤 骨 高 鬼 魂 魅 魔 鱼 鲁 鲜 鸟 鸡 鸣 鸭 鸿 鹅 鹤 鹰 鹿 麦 麻 黄 黎 黑 默 鼓 鼠 鼻 齐 齿 龄 龙 龟]},
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
					'' => {
						'name' => q(主方向),
					},
					'acre' => {
						'name' => q(英亩),
						'other' => q({0}英亩),
					},
					'acre-foot' => {
						'name' => q(英亩英尺),
						'other' => q({0}英亩英尺),
					},
					'ampere' => {
						'name' => q(安培),
						'other' => q({0}安培),
					},
					'arc-minute' => {
						'name' => q(弧分),
						'other' => q({0}弧分),
					},
					'arc-second' => {
						'name' => q(弧秒),
						'other' => q({0}弧秒),
					},
					'astronomical-unit' => {
						'name' => q(天文单位),
						'other' => q({0}天文单位),
					},
					'atmosphere' => {
						'name' => q(标准大气压),
						'other' => q({0}个标准大气压),
					},
					'bit' => {
						'name' => q(比特),
						'other' => q({0}比特),
					},
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0}蒲式耳),
					},
					'byte' => {
						'name' => q(字节),
						'other' => q({0}字节),
					},
					'calorie' => {
						'name' => q(卡路里),
						'other' => q({0}卡路里),
					},
					'carat' => {
						'name' => q(克拉),
						'other' => q({0}克拉),
					},
					'celsius' => {
						'name' => q(摄氏度),
						'other' => q({0}摄氏度),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0}厘升),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0}厘米),
						'per' => q(每厘米{0}),
					},
					'century' => {
						'name' => q(个世纪),
						'other' => q({0}个世纪),
					},
					'coordinate' => {
						'east' => q(东经{0}),
						'north' => q(北纬{0}),
						'south' => q(南纬{0}),
						'west' => q(西经{0}),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0}立方厘米),
						'per' => q(每立方厘米{0}),
					},
					'cubic-foot' => {
						'name' => q(立方英尺),
						'other' => q({0}立方英尺),
					},
					'cubic-inch' => {
						'name' => q(立方英寸),
						'other' => q({0}立方英寸),
					},
					'cubic-kilometer' => {
						'name' => q(立方千米),
						'other' => q({0}立方千米),
					},
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0}立方米),
						'per' => q(每立方米{0}),
					},
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0}立方英里),
					},
					'cubic-yard' => {
						'name' => q(立方码),
						'other' => q({0}立方码),
					},
					'cup' => {
						'name' => q(杯),
						'other' => q({0}杯),
					},
					'cup-metric' => {
						'name' => q(公制杯),
						'other' => q({0}公制杯),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0}天),
						'per' => q(每天{0}),
					},
					'deciliter' => {
						'name' => q(分升),
						'other' => q({0}分升),
					},
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0}分米),
					},
					'degree' => {
						'name' => q(度),
						'other' => q({0}度),
					},
					'fahrenheit' => {
						'name' => q(华氏度),
						'other' => q({0}华氏度),
					},
					'fathom' => {
						'name' => q(英寻),
						'other' => q({0}英寻),
					},
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0}液盎司),
					},
					'foodcalorie' => {
						'name' => q(卡路里),
						'other' => q({0}卡路里),
					},
					'foot' => {
						'name' => q(英尺),
						'other' => q({0}英尺),
						'per' => q(每英尺{0}),
					},
					'furlong' => {
						'name' => q(弗隆),
						'other' => q({0}弗隆),
					},
					'g-force' => {
						'name' => q(G力),
						'other' => q({0}G力),
					},
					'gallon' => {
						'name' => q(加仑),
						'other' => q({0}加仑),
						'per' => q(每加仑{0}),
					},
					'gallon-imperial' => {
						'name' => q(英制加仑),
						'other' => q({0}英制加仑),
						'per' => q(每英制加仑{0}),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(吉比特),
						'other' => q({0}吉比特),
					},
					'gigabyte' => {
						'name' => q(吉字节),
						'other' => q({0}吉字节),
					},
					'gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0}吉赫),
					},
					'gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0}吉瓦),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0}克),
						'per' => q(每克{0}),
					},
					'hectare' => {
						'name' => q(公顷),
						'other' => q({0}公顷),
					},
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0}公石),
					},
					'hectopascal' => {
						'name' => q(百帕斯卡),
						'other' => q({0}百帕斯卡),
					},
					'hertz' => {
						'name' => q(赫兹),
						'other' => q({0}赫兹),
					},
					'horsepower' => {
						'name' => q(马力),
						'other' => q({0}马力),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0}小时),
						'per' => q(每小时{0}),
					},
					'inch' => {
						'name' => q(英寸),
						'other' => q({0}英寸),
						'per' => q(每英寸{0}),
					},
					'inch-hg' => {
						'name' => q(英寸汞柱),
						'other' => q({0}英寸汞柱),
					},
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0}焦耳),
					},
					'karat' => {
						'name' => q(克拉),
						'other' => q({0}克拉),
					},
					'kelvin' => {
						'name' => q(开尔文),
						'other' => q({0}开尔文),
					},
					'kilobit' => {
						'name' => q(千比特),
						'other' => q({0}千比特),
					},
					'kilobyte' => {
						'name' => q(千字节),
						'other' => q({0}千字节),
					},
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0}千卡),
					},
					'kilogram' => {
						'name' => q(千克),
						'other' => q({0}千克),
						'per' => q(每千克{0}),
					},
					'kilohertz' => {
						'name' => q(千赫),
						'other' => q({0}千赫),
					},
					'kilojoule' => {
						'name' => q(千焦),
						'other' => q({0}千焦),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0}公里),
						'per' => q(每公里{0}),
					},
					'kilometer-per-hour' => {
						'name' => q(公里/小时),
						'other' => q(每小时{0}公里),
					},
					'kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0}千瓦),
					},
					'kilowatt-hour' => {
						'name' => q(千瓦时),
						'other' => q({0}千瓦时),
					},
					'knot' => {
						'name' => q(节),
						'other' => q({0}节),
					},
					'light-year' => {
						'name' => q(光年),
						'other' => q({0}光年),
					},
					'liter' => {
						'name' => q(升),
						'other' => q({0}升),
						'per' => q(每升{0}),
					},
					'liter-per-100kilometers' => {
						'name' => q(升/100千米),
						'other' => q({0}升/100千米),
					},
					'liter-per-kilometer' => {
						'name' => q(升/公里),
						'other' => q(每公里{0}升),
					},
					'lux' => {
						'name' => q(勒克斯),
						'other' => q({0}勒克斯),
					},
					'megabit' => {
						'name' => q(兆比特),
						'other' => q({0}兆比特),
					},
					'megabyte' => {
						'name' => q(兆字节),
						'other' => q({0}兆字节),
					},
					'megahertz' => {
						'name' => q(兆赫),
						'other' => q({0}兆赫),
					},
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0}兆升),
					},
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0}兆瓦),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0}米),
						'per' => q(每米{0}),
					},
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q(每秒{0}米),
					},
					'meter-per-second-squared' => {
						'name' => q(米/秒²),
						'other' => q(每平方秒{0}米),
					},
					'metric-ton' => {
						'name' => q(公吨),
						'other' => q({0}公吨),
					},
					'microgram' => {
						'name' => q(微克),
						'other' => q({0}微克),
					},
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0}微米),
					},
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0}微秒),
					},
					'mile' => {
						'name' => q(英里),
						'other' => q({0}英里),
					},
					'mile-per-gallon' => {
						'name' => q(英里/加仑),
						'other' => q(每加仑{0}英里),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(英里/英制加仑),
						'other' => q(每英制加仑{0}英里),
					},
					'mile-per-hour' => {
						'name' => q(英里/小时),
						'other' => q(每小时{0}英里),
					},
					'mile-scandinavian' => {
						'name' => q(斯堪的纳维亚英里),
						'other' => q({0}斯堪的纳维亚英里),
					},
					'milliampere' => {
						'name' => q(毫安),
						'other' => q({0}毫安),
					},
					'millibar' => {
						'name' => q(毫巴),
						'other' => q({0}毫巴),
					},
					'milligram' => {
						'name' => q(毫克),
						'other' => q({0}毫克),
					},
					'milligram-per-deciliter' => {
						'name' => q(毫克/分升),
						'other' => q(每分升{0}毫克),
					},
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0}毫升),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0}毫米),
					},
					'millimeter-of-mercury' => {
						'name' => q(毫米汞柱),
						'other' => q({0}毫米汞柱),
					},
					'millimole-per-liter' => {
						'name' => q(毫摩尔/升),
						'other' => q(每升{0}毫摩尔),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0}毫秒),
					},
					'milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0}毫瓦),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0}分钟),
						'per' => q(每分钟{0}),
					},
					'month' => {
						'name' => q(个月),
						'other' => q({0}个月),
						'per' => q(每月{0}),
					},
					'nanometer' => {
						'name' => q(纳米),
						'other' => q({0}纳米),
					},
					'nanosecond' => {
						'name' => q(纳秒),
						'other' => q({0}纳秒),
					},
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0}海里),
					},
					'ohm' => {
						'name' => q(欧姆),
						'other' => q({0}欧姆),
					},
					'ounce' => {
						'name' => q(盎司),
						'other' => q({0}盎司),
						'per' => q(每盎司{0}),
					},
					'ounce-troy' => {
						'name' => q(金衡制盎司),
						'other' => q({0}金衡制盎司),
					},
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0}秒差距),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'other' => q(百万分之{0}),
					},
					'per' => {
						'1' => q(每{1}{0}),
					},
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(拍字节),
						'other' => q({0}拍字节),
					},
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0}皮米),
					},
					'pint' => {
						'name' => q(品脱),
						'other' => q({0}品脱),
					},
					'pint-metric' => {
						'name' => q(公制品脱),
						'other' => q({0}公制品脱),
					},
					'point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(磅),
						'other' => q({0}磅),
						'per' => q(每磅{0}),
					},
					'pound-per-square-inch' => {
						'name' => q(磅/平方英寸),
						'other' => q(每平方英寸{0}磅),
					},
					'quart' => {
						'name' => q(夸脱),
						'other' => q({0}夸脱),
					},
					'radian' => {
						'name' => q(弧度),
						'other' => q({0}弧度),
					},
					'revolution' => {
						'name' => q(转),
						'other' => q({0}转),
					},
					'second' => {
						'name' => q(秒钟),
						'other' => q({0}秒钟),
						'per' => q({0}/秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0}平方厘米),
						'per' => q(每平方厘米{0}),
					},
					'square-foot' => {
						'name' => q(平方英尺),
						'other' => q({0}平方英尺),
					},
					'square-inch' => {
						'name' => q(平方英寸),
						'other' => q({0}平方英寸),
						'per' => q(每平方英寸{0}),
					},
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0}平方公里),
						'per' => q(每平方公里{0}),
					},
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0}平方米),
						'per' => q(每平方米{0}),
					},
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0}平方英里),
						'per' => q(每平方英里{0}),
					},
					'square-yard' => {
						'name' => q(平方码),
						'other' => q({0}平方码),
					},
					'stone' => {
						'name' => q(英石),
						'other' => q({0}英石),
					},
					'tablespoon' => {
						'name' => q(汤匙),
						'other' => q({0}汤匙),
					},
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0}茶匙),
					},
					'terabit' => {
						'name' => q(太比特),
						'other' => q({0}太比特),
					},
					'terabyte' => {
						'name' => q(太字节),
						'other' => q({0}太字节),
					},
					'ton' => {
						'name' => q(吨),
						'other' => q({0}吨),
					},
					'volt' => {
						'name' => q(伏特),
						'other' => q({0}伏特),
					},
					'watt' => {
						'name' => q(瓦特),
						'other' => q({0}瓦特),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0}周),
						'per' => q(每周{0}),
					},
					'yard' => {
						'name' => q(码),
						'other' => q({0}码),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0}年),
						'per' => q(每年{0}),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(方向),
					},
					'acre' => {
						'name' => q(英亩),
						'other' => q({0}ac),
					},
					'acre-foot' => {
						'name' => q(英亩英尺),
						'other' => q({0}英亩英尺),
					},
					'arc-minute' => {
						'other' => q({0}′),
					},
					'arc-second' => {
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(天文单位),
						'other' => q({0}天文单位),
					},
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0}蒲式耳),
					},
					'celsius' => {
						'name' => q(°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0}厘升),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0}厘米),
						'per' => q({0}/厘米),
					},
					'century' => {
						'name' => q(世纪),
						'other' => q({0}个世纪),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0}立方厘米),
						'per' => q({0}/立方厘米),
					},
					'cubic-foot' => {
						'name' => q(立方英尺),
						'other' => q({0}立方英尺),
					},
					'cubic-inch' => {
						'name' => q(立方英寸),
						'other' => q({0}立方英寸),
					},
					'cubic-kilometer' => {
						'name' => q(立方千米),
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0}立方米),
						'per' => q({0}/立方米),
					},
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0}mi³),
					},
					'cubic-yard' => {
						'name' => q(立方码),
						'other' => q({0}立方码),
					},
					'cup' => {
						'name' => q(杯),
						'other' => q({0}杯),
					},
					'cup-metric' => {
						'name' => q(公制杯),
						'other' => q({0}公制杯),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0}天),
						'per' => q({0}/天),
					},
					'deciliter' => {
						'name' => q(分升),
						'other' => q({0}分升),
					},
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0}分米),
					},
					'degree' => {
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(英寻),
						'other' => q({0}英寻),
					},
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0}液盎司),
					},
					'foodcalorie' => {
						'name' => q(卡),
						'other' => q({0}卡),
					},
					'foot' => {
						'name' => q(英尺),
						'other' => q({0}′),
						'per' => q({0}/英尺),
					},
					'furlong' => {
						'name' => q(弗隆),
						'other' => q({0}弗隆),
					},
					'g-force' => {
						'name' => q(G力),
						'other' => q({0}G),
					},
					'gallon' => {
						'name' => q(加仑),
						'other' => q({0}加仑),
						'per' => q({0}/加仑),
					},
					'gallon-imperial' => {
						'name' => q(英制加仑),
						'other' => q({0}英制加仑),
						'per' => q({0}/英制加仑),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0}克),
					},
					'hectare' => {
						'name' => q(公顷),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0}公石),
					},
					'hectopascal' => {
						'other' => q({0}hPa),
					},
					'horsepower' => {
						'other' => q({0}hp),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0}小时),
						'per' => q({0}/小时),
					},
					'inch' => {
						'name' => q(英寸),
						'other' => q({0}″),
						'per' => q({0}/英寸),
					},
					'inch-hg' => {
						'other' => q({0}" Hg),
					},
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0}焦耳),
					},
					'kilogram' => {
						'name' => q(千克),
						'other' => q({0}千克),
					},
					'kilojoule' => {
						'name' => q(千焦),
						'other' => q({0}千焦),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0}公里),
						'per' => q({0}/公里),
					},
					'kilometer-per-hour' => {
						'name' => q(公里/小时),
						'other' => q({0}公里/小时),
					},
					'kilowatt' => {
						'other' => q({0}kW),
					},
					'knot' => {
						'name' => q(节),
						'other' => q({0}节),
					},
					'light-year' => {
						'name' => q(光年),
						'other' => q({0}ly),
					},
					'liter' => {
						'name' => q(升),
						'other' => q({0}升),
						'per' => q({0}/升),
					},
					'liter-per-100kilometers' => {
						'name' => q(升/100千米),
						'other' => q({0}L/100km),
					},
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0}兆升),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0}米),
						'per' => q({0}/米),
					},
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(米/秒²),
						'other' => q({0}米/秒²),
					},
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0}微米),
					},
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0}微秒),
					},
					'mile' => {
						'name' => q(英里),
						'other' => q({0}mi),
					},
					'mile-per-hour' => {
						'name' => q(英里/小时),
						'other' => q({0}mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(斯堪的纳维亚英里),
						'other' => q({0}smi),
					},
					'millibar' => {
						'other' => q({0}mb),
					},
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0}毫升),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0}毫米),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0}毫秒),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0}分钟),
						'per' => q({0}/分钟),
					},
					'month' => {
						'name' => q(个月),
						'other' => q({0}个月),
						'per' => q({0}/月),
					},
					'nanometer' => {
						'name' => q(纳米),
						'other' => q({0}纳米),
					},
					'nanosecond' => {
						'name' => q(纳秒),
						'other' => q({0}纳秒),
					},
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0}海里),
					},
					'ounce' => {
						'other' => q({0}盎司),
					},
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0}秒差距),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0}pm),
					},
					'pint' => {
						'name' => q(品脱),
						'other' => q({0}品脱),
					},
					'pint-metric' => {
						'name' => q(公制品脱),
						'other' => q({0}公制品脱),
					},
					'point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'other' => q({0}磅),
					},
					'quart' => {
						'name' => q(夸脱),
						'other' => q({0}夸脱),
					},
					'second' => {
						'name' => q(秒),
						'other' => q({0}秒),
						'per' => q({0}/秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0}平方厘米),
						'per' => q({0}/平方厘米),
					},
					'square-foot' => {
						'name' => q(平方英尺),
						'other' => q({0}ft²),
					},
					'square-inch' => {
						'name' => q(平方英寸),
						'other' => q({0}平方英寸),
						'per' => q({0}/平方英寸),
					},
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0}km²),
						'per' => q({0}/平方公里),
					},
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0}m²),
						'per' => q({0}/平方米),
					},
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0}mi²),
						'per' => q({0}/平方英里),
					},
					'square-yard' => {
						'name' => q(平方码),
						'other' => q({0}平方码),
					},
					'stone' => {
						'name' => q(英石),
						'other' => q({0}英石),
					},
					'tablespoon' => {
						'name' => q(汤匙),
						'other' => q({0}汤匙),
					},
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0}茶匙),
					},
					'watt' => {
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0}周),
						'per' => q({0}/周),
					},
					'yard' => {
						'name' => q(码),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0}年),
						'per' => q({0}/年),
					},
				},
				'short' => {
					'' => {
						'name' => q(方向),
					},
					'acre' => {
						'name' => q(英亩),
						'other' => q({0}英亩),
					},
					'acre-foot' => {
						'name' => q(英亩英尺),
						'other' => q({0}英亩英尺),
					},
					'ampere' => {
						'name' => q(安培),
						'other' => q({0}安),
					},
					'arc-minute' => {
						'name' => q(弧分),
						'other' => q({0}弧分),
					},
					'arc-second' => {
						'name' => q(弧秒),
						'other' => q({0}弧秒),
					},
					'astronomical-unit' => {
						'name' => q(天文单位),
						'other' => q({0}天文单位),
					},
					'atmosphere' => {
						'name' => q(大气压),
						'other' => q({0}个大气压),
					},
					'bit' => {
						'name' => q(比特),
						'other' => q({0}比特),
					},
					'bushel' => {
						'name' => q(蒲式耳),
						'other' => q({0}蒲式耳),
					},
					'byte' => {
						'name' => q(字节),
						'other' => q({0}字节),
					},
					'calorie' => {
						'name' => q(卡),
						'other' => q({0}卡),
					},
					'carat' => {
						'name' => q(克拉),
						'other' => q({0}克拉),
					},
					'celsius' => {
						'name' => q(摄氏度),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(厘升),
						'other' => q({0}厘升),
					},
					'centimeter' => {
						'name' => q(厘米),
						'other' => q({0}厘米),
						'per' => q({0}/厘米),
					},
					'century' => {
						'name' => q(世纪),
						'other' => q({0}个世纪),
					},
					'coordinate' => {
						'east' => q(东经{0}),
						'north' => q(北纬{0}),
						'south' => q(南纬{0}),
						'west' => q(西经{0}),
					},
					'cubic-centimeter' => {
						'name' => q(立方厘米),
						'other' => q({0}立方厘米),
						'per' => q({0}/立方厘米),
					},
					'cubic-foot' => {
						'name' => q(立方英尺),
						'other' => q({0}立方英尺),
					},
					'cubic-inch' => {
						'name' => q(立方英寸),
						'other' => q({0}立方英寸),
					},
					'cubic-kilometer' => {
						'name' => q(立方千米),
						'other' => q({0}立方千米),
					},
					'cubic-meter' => {
						'name' => q(立方米),
						'other' => q({0}立方米),
						'per' => q({0}/立方米),
					},
					'cubic-mile' => {
						'name' => q(立方英里),
						'other' => q({0}立方英里),
					},
					'cubic-yard' => {
						'name' => q(立方码),
						'other' => q({0}立方码),
					},
					'cup' => {
						'name' => q(杯),
						'other' => q({0}杯),
					},
					'cup-metric' => {
						'name' => q(公制杯),
						'other' => q({0}公制杯),
					},
					'day' => {
						'name' => q(天),
						'other' => q({0}天),
						'per' => q({0}/天),
					},
					'deciliter' => {
						'name' => q(分升),
						'other' => q({0}分升),
					},
					'decimeter' => {
						'name' => q(分米),
						'other' => q({0}分米),
					},
					'degree' => {
						'name' => q(度),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(华氏度),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(英寻),
						'other' => q({0}英寻),
					},
					'fluid-ounce' => {
						'name' => q(液盎司),
						'other' => q({0}液盎司),
					},
					'foodcalorie' => {
						'name' => q(卡),
						'other' => q({0}卡),
					},
					'foot' => {
						'name' => q(英尺),
						'other' => q({0}英尺),
						'per' => q({0}/英尺),
					},
					'furlong' => {
						'name' => q(弗隆),
						'other' => q({0}弗隆),
					},
					'g-force' => {
						'name' => q(G力),
						'other' => q({0}G),
					},
					'gallon' => {
						'name' => q(加仑),
						'other' => q({0}加仑),
						'per' => q({0}/加仑),
					},
					'gallon-imperial' => {
						'name' => q(英制加仑),
						'other' => q({0}英制加仑),
						'per' => q({0}/英制加仑),
					},
					'generic' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(吉比特),
						'other' => q({0}吉比特),
					},
					'gigabyte' => {
						'name' => q(吉字节),
						'other' => q({0}吉字节),
					},
					'gigahertz' => {
						'name' => q(吉赫),
						'other' => q({0}吉赫),
					},
					'gigawatt' => {
						'name' => q(吉瓦),
						'other' => q({0}吉瓦),
					},
					'gram' => {
						'name' => q(克),
						'other' => q({0}克),
						'per' => q({0}/克),
					},
					'hectare' => {
						'name' => q(公顷),
						'other' => q({0}公顷),
					},
					'hectoliter' => {
						'name' => q(公石),
						'other' => q({0}公石),
					},
					'hectopascal' => {
						'name' => q(百帕),
						'other' => q({0}百帕),
					},
					'hertz' => {
						'name' => q(赫兹),
						'other' => q({0}赫),
					},
					'horsepower' => {
						'name' => q(马力),
						'other' => q({0}马力),
					},
					'hour' => {
						'name' => q(小时),
						'other' => q({0}小时),
						'per' => q({0}/小时),
					},
					'inch' => {
						'name' => q(英寸),
						'other' => q({0}英寸),
						'per' => q({0}/英寸),
					},
					'inch-hg' => {
						'name' => q(英寸汞柱),
						'other' => q({0}英寸汞柱),
					},
					'joule' => {
						'name' => q(焦耳),
						'other' => q({0}焦耳),
					},
					'karat' => {
						'name' => q(克拉),
						'other' => q({0}克拉),
					},
					'kelvin' => {
						'name' => q(开),
						'other' => q({0}K),
					},
					'kilobit' => {
						'name' => q(千比特),
						'other' => q({0}千比特),
					},
					'kilobyte' => {
						'name' => q(千字节),
						'other' => q({0}千字节),
					},
					'kilocalorie' => {
						'name' => q(千卡),
						'other' => q({0}千卡),
					},
					'kilogram' => {
						'name' => q(千克),
						'other' => q({0}千克),
						'per' => q({0}/千克),
					},
					'kilohertz' => {
						'name' => q(千赫),
						'other' => q({0}千赫),
					},
					'kilojoule' => {
						'name' => q(千焦),
						'other' => q({0}千焦),
					},
					'kilometer' => {
						'name' => q(公里),
						'other' => q({0}公里),
						'per' => q({0}/公里),
					},
					'kilometer-per-hour' => {
						'name' => q(公里/小时),
						'other' => q(每小时{0}公里),
					},
					'kilowatt' => {
						'name' => q(千瓦),
						'other' => q({0}千瓦),
					},
					'kilowatt-hour' => {
						'name' => q(千瓦时),
						'other' => q({0}千瓦时),
					},
					'knot' => {
						'name' => q(节),
						'other' => q({0}节),
					},
					'light-year' => {
						'name' => q(光年),
						'other' => q({0}光年),
					},
					'liter' => {
						'name' => q(升),
						'other' => q({0}升),
						'per' => q({0}/升),
					},
					'liter-per-100kilometers' => {
						'name' => q(升/100千米),
						'other' => q({0}升/100千米),
					},
					'liter-per-kilometer' => {
						'name' => q(升/公里),
						'other' => q({0}升/公里),
					},
					'lux' => {
						'name' => q(勒克斯),
						'other' => q({0}勒克斯),
					},
					'megabit' => {
						'name' => q(兆比特),
						'other' => q({0}兆比特),
					},
					'megabyte' => {
						'name' => q(兆字节),
						'other' => q({0}兆字节),
					},
					'megahertz' => {
						'name' => q(兆赫),
						'other' => q({0}兆赫),
					},
					'megaliter' => {
						'name' => q(兆升),
						'other' => q({0}兆升),
					},
					'megawatt' => {
						'name' => q(兆瓦),
						'other' => q({0}兆瓦),
					},
					'meter' => {
						'name' => q(米),
						'other' => q({0}米),
						'per' => q({0}/米),
					},
					'meter-per-second' => {
						'name' => q(米/秒),
						'other' => q({0}米/秒),
					},
					'meter-per-second-squared' => {
						'name' => q(米/秒²),
						'other' => q({0}米/秒²),
					},
					'metric-ton' => {
						'name' => q(公吨),
						'other' => q({0}公吨),
					},
					'microgram' => {
						'name' => q(微克),
						'other' => q({0}微克),
					},
					'micrometer' => {
						'name' => q(微米),
						'other' => q({0}微米),
					},
					'microsecond' => {
						'name' => q(微秒),
						'other' => q({0}微秒),
					},
					'mile' => {
						'name' => q(英里),
						'other' => q({0}英里),
					},
					'mile-per-gallon' => {
						'name' => q(英里/加仑),
						'other' => q({0}英里/加仑),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(英里/英制加仑),
						'other' => q({0}英里/英制加仑),
					},
					'mile-per-hour' => {
						'name' => q(英里/小时),
						'other' => q({0}英里/小时),
					},
					'mile-scandinavian' => {
						'name' => q(斯堪的纳维亚英里),
						'other' => q({0}斯堪的纳维亚英里),
					},
					'milliampere' => {
						'name' => q(毫安),
						'other' => q({0}毫安),
					},
					'millibar' => {
						'name' => q(毫巴),
						'other' => q({0}毫巴),
					},
					'milligram' => {
						'name' => q(毫克),
						'other' => q({0}毫克),
					},
					'milligram-per-deciliter' => {
						'name' => q(毫克/分升),
						'other' => q({0}毫克/分升),
					},
					'milliliter' => {
						'name' => q(毫升),
						'other' => q({0}毫升),
					},
					'millimeter' => {
						'name' => q(毫米),
						'other' => q({0}毫米),
					},
					'millimeter-of-mercury' => {
						'name' => q(毫米汞柱),
						'other' => q({0}毫米汞柱),
					},
					'millimole-per-liter' => {
						'name' => q(毫摩尔/升),
						'other' => q({0}毫摩尔/升),
					},
					'millisecond' => {
						'name' => q(毫秒),
						'other' => q({0}毫秒),
					},
					'milliwatt' => {
						'name' => q(毫瓦),
						'other' => q({0}毫瓦),
					},
					'minute' => {
						'name' => q(分钟),
						'other' => q({0}分钟),
						'per' => q({0}/分钟),
					},
					'month' => {
						'name' => q(个月),
						'other' => q({0}个月),
						'per' => q({0}/月),
					},
					'nanometer' => {
						'name' => q(纳米),
						'other' => q({0}纳米),
					},
					'nanosecond' => {
						'name' => q(纳秒),
						'other' => q({0}纳秒),
					},
					'nautical-mile' => {
						'name' => q(海里),
						'other' => q({0}海里),
					},
					'ohm' => {
						'name' => q(欧姆),
						'other' => q({0}欧),
					},
					'ounce' => {
						'name' => q(盎司),
						'other' => q({0}盎司),
						'per' => q({0}/盎司),
					},
					'ounce-troy' => {
						'name' => q(金衡盎司),
						'other' => q({0}金衡盎司),
					},
					'parsec' => {
						'name' => q(秒差距),
						'other' => q({0}秒差距),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'other' => q({0}ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(皮米),
						'other' => q({0}皮米),
					},
					'pint' => {
						'name' => q(品脱),
						'other' => q({0}品脱),
					},
					'pint-metric' => {
						'name' => q(公制品脱),
						'other' => q({0}公制品脱),
					},
					'point' => {
						'name' => q(pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(磅),
						'other' => q({0}磅),
						'per' => q({0}/磅),
					},
					'pound-per-square-inch' => {
						'name' => q(磅/平方英寸),
						'other' => q(每平方英寸{0}磅),
					},
					'quart' => {
						'name' => q(夸脱),
						'other' => q({0}夸脱),
					},
					'radian' => {
						'name' => q(弧度),
						'other' => q({0}弧度),
					},
					'revolution' => {
						'name' => q(转),
						'other' => q({0}转),
					},
					'second' => {
						'name' => q(秒),
						'other' => q({0}秒),
						'per' => q({0}/秒),
					},
					'square-centimeter' => {
						'name' => q(平方厘米),
						'other' => q({0}平方厘米),
						'per' => q({0}/平方厘米),
					},
					'square-foot' => {
						'name' => q(平方英尺),
						'other' => q({0}平方英尺),
					},
					'square-inch' => {
						'name' => q(平方英寸),
						'other' => q({0}平方英寸),
						'per' => q({0}/平方英寸),
					},
					'square-kilometer' => {
						'name' => q(平方公里),
						'other' => q({0}平方公里),
						'per' => q({0}/平方公里),
					},
					'square-meter' => {
						'name' => q(平方米),
						'other' => q({0}平方米),
						'per' => q({0}/平方米),
					},
					'square-mile' => {
						'name' => q(平方英里),
						'other' => q({0}平方英里),
						'per' => q({0}/平方英里),
					},
					'square-yard' => {
						'name' => q(平方码),
						'other' => q({0}平方码),
					},
					'stone' => {
						'name' => q(英石),
						'other' => q({0}英石),
					},
					'tablespoon' => {
						'name' => q(汤匙),
						'other' => q({0}汤匙),
					},
					'teaspoon' => {
						'name' => q(茶匙),
						'other' => q({0}茶匙),
					},
					'terabit' => {
						'name' => q(太比特),
						'other' => q({0}太比特),
					},
					'terabyte' => {
						'name' => q(太字节),
						'other' => q({0}太字节),
					},
					'ton' => {
						'name' => q(吨),
						'other' => q({0}吨),
					},
					'volt' => {
						'name' => q(伏特),
						'other' => q({0}伏),
					},
					'watt' => {
						'name' => q(瓦特),
						'other' => q({0}瓦),
					},
					'week' => {
						'name' => q(周),
						'other' => q({0}周),
						'per' => q({0}/周),
					},
					'yard' => {
						'name' => q(码),
						'other' => q({0}码),
					},
					'year' => {
						'name' => q(年),
						'other' => q({0}年),
						'per' => q({0}/年),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:确定|是|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:否定|否|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}{1}),
				middle => q({0}{1}),
				end => q({0}{1}),
				2 => q({0}{1}),
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
		'arab' => {
			'decimal' => q(٫),
			'exponential' => q(اس),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'decimal' => q(٫),
			'exponential' => q(×۱۰^),
			'group' => q(٬),
			'infinity' => q(∞),
			'list' => q(؛),
			'minusSign' => q(‎-‎),
			'nan' => q(NaN),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‎+‎),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(٫),
		},
		'hanidec' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(NaN),
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
		'arab' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
					},
				},
			},
		},
		'arabext' => {
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
		'bali' => {
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
		'beng' => {
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
		'brah' => {
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
		'cakm' => {
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
		'cham' => {
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
		'deva' => {
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
		'fullwide' => {
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
		'gonm' => {
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
		'gujr' => {
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
		'guru' => {
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
		'hanidec' => {
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
		'java' => {
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
		'kali' => {
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
		'khmr' => {
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
		'knda' => {
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
		'lana' => {
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
		'lanatham' => {
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
		'laoo' => {
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
		'lepc' => {
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
		'limb' => {
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
		'mlym' => {
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
		'mong' => {
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
		'mtei' => {
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
		'mymr' => {
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
		'mymrshan' => {
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
		'nkoo' => {
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
		'olck' => {
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
		'orya' => {
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
		'osma' => {
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
		'saur' => {
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
		'shrd' => {
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
		'sora' => {
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
		'sund' => {
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
		'takr' => {
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
		'talu' => {
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
		'tamldec' => {
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
		'telu' => {
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
		'thai' => {
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
		'tibt' => {
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
		'vaii' => {
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
				'currency' => q(安道尔比塞塔),
				'other' => q(安道尔比塞塔),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(阿联酋迪拉姆),
				'other' => q(阿联酋迪拉姆),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(阿富汗尼 \(1927–2002\)),
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
				'currency' => q(阿尔巴尼亚列克\(1946–1965\)),
				'other' => q(阿尔巴尼亚列克\(1946–1965\)),
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
				'currency' => q(荷属安的列斯盾),
				'other' => q(荷属安的列斯盾),
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
				'currency' => q(安哥拉重新调整宽扎 \(1995–1999\)),
				'other' => q(安哥拉重新调整宽扎 \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(阿根廷奥斯特拉尔),
				'other' => q(阿根廷奥斯特拉尔),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(阿根廷法定比索 \(1970–1983\)),
				'other' => q(阿根廷法定比索 \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(阿根廷比索 \(1881–1970\)),
				'other' => q(阿根廷比索 \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(阿根廷比索 \(1983–1985\)),
				'other' => q(阿根廷比索 \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(阿根廷比索),
				'other' => q(阿根廷比索),
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
				'currency' => q(澳大利亚元),
				'other' => q(澳大利亚元),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(阿鲁巴弗罗林),
				'other' => q(阿鲁巴弗罗林),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(阿塞拜疆马纳特 \(1993–2006\)),
				'other' => q(阿塞拜疆马纳特 \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(阿塞拜疆马纳特),
				'other' => q(阿塞拜疆马纳特),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(波士尼亚-赫塞哥维纳第纳尔 \(1992–1994\)),
				'other' => q(波士尼亚-赫塞哥维纳第纳尔 \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(波斯尼亚-黑塞哥维那可兑换马克),
				'other' => q(波斯尼亚-黑塞哥维那可兑换马克),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(波士尼亚-赫塞哥维纳新第纳尔 \(1994–1997\)),
				'other' => q(波士尼亚-赫塞哥维纳新第纳尔 \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(巴巴多斯元),
				'other' => q(巴巴多斯元),
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
				'currency' => q(比利时法郎（可兑换）),
				'other' => q(比利时法郎（可兑换）),
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
				'currency' => q(保加利亚列弗),
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
				'currency' => q(布隆迪法郎),
				'other' => q(布隆迪法郎),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(百慕大元),
				'other' => q(百慕大元),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(文莱元),
				'other' => q(文莱元),
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
				'currency' => q(玻利维亚诺 \(1863–1963\)),
				'other' => q(玻利维亚诺 \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(玻利维亚比索),
				'other' => q(玻利维亚比索),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(玻利维亚 Mvdol（资金）),
				'other' => q(玻利维亚 Mvdol（资金）),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(巴西新克鲁赛罗 \(1967–1986\)),
				'other' => q(巴西新克鲁赛罗 \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(巴西克鲁扎多 \(1986–1989\)),
				'other' => q(巴西克鲁扎多 \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(巴西克鲁塞罗 \(1990–1993\)),
				'other' => q(巴西克鲁塞罗 \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(巴西雷亚尔),
				'other' => q(巴西雷亚尔),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(巴西新克鲁扎多 \(1989–1990\)),
				'other' => q(巴西新克鲁扎多 \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(巴西克鲁塞罗 \(1993–1994\)),
				'other' => q(巴西克鲁塞罗 \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(巴西克鲁塞罗 \(1942–1967\)),
				'other' => q(巴西克鲁塞罗 \(1942–1967\)),
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
				'currency' => q(不丹努尔特鲁姆),
				'other' => q(不丹努尔特鲁姆),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(缅元),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(博茨瓦纳普拉),
				'other' => q(博茨瓦纳普拉),
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
				'currency' => q(伯利兹元),
				'other' => q(伯利兹元),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(加拿大元),
				'other' => q(加拿大元),
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
				'currency' => q(智利（资金）),
				'other' => q(智利（资金）),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(智利比索),
				'other' => q(智利比索),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(人民币（离岸）),
				'other' => q(人民币（离岸）),
			},
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
				'currency' => q(哥伦比亚比索),
				'other' => q(哥伦比亚比索),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(哥伦比亚币),
				'other' => q(哥伦比亚币),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(哥斯达黎加科朗),
				'other' => q(哥斯达黎加科朗),
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
				'currency' => q(捷克硬克朗),
				'other' => q(捷克硬克朗),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(古巴可兑换比索),
				'other' => q(古巴可兑换比索),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(古巴比索),
				'other' => q(古巴比索),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(佛得角埃斯库多),
				'other' => q(佛得角埃斯库多),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(塞浦路斯镑),
				'other' => q(塞浦路斯镑),
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
				'currency' => q(吉布提法郎),
				'other' => q(吉布提法郎),
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
				'currency' => q(多米尼加比索),
				'other' => q(多米尼加比索),
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
				'currency' => q(厄瓜多尔苏克雷),
				'other' => q(厄瓜多尔苏克雷),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(厄瓜多尔 \(UVC\)),
				'other' => q(厄瓜多尔 \(UVC\)),
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
				'currency' => q(西班牙比塞塔（帐户 A）),
				'other' => q(西班牙比塞塔（帐户 A）),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(西班牙比塞塔（兑换帐户）),
				'other' => q(西班牙比塞塔（兑换帐户）),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(西班牙比塞塔),
				'other' => q(西班牙比塞塔),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(埃塞俄比亚比尔),
				'other' => q(埃塞俄比亚比尔),
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
				'currency' => q(乔治亚库蓬拉瑞特),
				'other' => q(乔治亚库蓬拉瑞特),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(格鲁吉亚拉里),
				'other' => q(格鲁吉亚拉里),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(加纳塞第),
				'other' => q(加纳塞第),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(加纳塞地),
				'other' => q(加纳塞地),
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
				'currency' => q(冈比亚达拉西),
				'other' => q(冈比亚达拉西),
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
				'currency' => q(危地马拉格查尔),
				'other' => q(危地马拉格查尔),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(葡萄牙几内亚埃斯库多),
				'other' => q(葡萄牙几内亚埃斯库多),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(几内亚比绍比索),
				'other' => q(几内亚比绍比索),
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
				'currency' => q(港元),
				'other' => q(港元),
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
				'currency' => q(克罗地亚第纳尔),
				'other' => q(克罗地亚第纳尔),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(克罗地亚库纳),
				'other' => q(克罗地亚库纳),
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
				'currency' => q(印度尼西亚盾),
				'other' => q(印度尼西亚盾),
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
			symbol => 'ILS',
			display_name => {
				'currency' => q(以色列谢克尔\(1980–1985\)),
				'other' => q(以色列谢克尔\(1980–1985\)),
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
				'currency' => q(冰岛克朗\(1918–1981\)),
				'other' => q(冰岛克朗\(1918–1981\)),
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
				'currency' => q(意大利里拉),
				'other' => q(意大利里拉),
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
				'currency' => q(日元),
				'other' => q(日元),
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
				'currency' => q(吉尔吉斯斯坦索姆),
				'other' => q(吉尔吉斯斯坦索姆),
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
				'currency' => q(朝鲜元),
				'other' => q(朝鲜元),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(韩元 \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(韩元 \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '￦',
			display_name => {
				'currency' => q(韩元),
				'other' => q(韩元),
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
				'currency' => q(开曼元),
				'other' => q(开曼元),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(哈萨克斯坦坚戈),
				'other' => q(哈萨克斯坦坚戈),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(老挝基普),
				'other' => q(老挝基普),
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
				'currency' => q(利比里亚元),
				'other' => q(利比里亚元),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(莱索托洛蒂),
				'other' => q(莱索托洛蒂),
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
				'currency' => q(立陶宛塔咯呐司),
				'other' => q(立陶宛塔咯呐司),
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
				'currency' => q(拉脱维亚拉特),
				'other' => q(拉脱维亚拉特),
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
				'currency' => q(摩尔多瓦库邦),
				'other' => q(摩尔多瓦库邦),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(摩尔多瓦列伊),
				'other' => q(摩尔多瓦列伊),
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
				'currency' => q(澳门币),
				'other' => q(澳门元),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(毛里塔尼亚乌吉亚 \(1973–2017\)),
				'other' => q(毛里塔尼亚乌吉亚 \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(毛里塔尼亚乌吉亚),
				'other' => q(毛里塔尼亚乌吉亚),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(马耳他里拉),
				'other' => q(马耳他里拉),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(马耳他镑),
				'other' => q(马耳他镑),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(毛里求斯卢比),
				'other' => q(毛里求斯卢比),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(马尔代夫卢比\(1947–1981\)),
				'other' => q(马尔代夫卢比\(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(马尔代夫卢菲亚),
				'other' => q(马尔代夫卢菲亚),
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
				'currency' => q(墨西哥比索),
				'other' => q(墨西哥比索),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(墨西哥银比索 \(1861–1992\)),
				'other' => q(墨西哥银比索 \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(墨西哥（资金）),
				'other' => q(墨西哥（资金）),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(马来西亚林吉特),
				'other' => q(马来西亚林吉特),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(莫桑比克埃斯库多),
				'other' => q(莫桑比克埃斯库多),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(旧莫桑比克美提卡),
				'other' => q(旧莫桑比克美提卡),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(莫桑比克美提卡),
				'other' => q(莫桑比克美提卡),
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
				'currency' => q(尼日利亚奈拉),
				'other' => q(尼日利亚奈拉),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(尼加拉瓜科多巴 \(1988–1991\)),
				'other' => q(尼加拉瓜科多巴 \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(尼加拉瓜科多巴),
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
				'currency' => q(新西兰元),
				'other' => q(新西兰元),
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
				'currency' => q(秘鲁印第),
				'other' => q(秘鲁印第),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(秘鲁索尔),
				'other' => q(秘鲁索尔),
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
				'currency' => q(巴布亚新几内亚基那),
				'other' => q(巴布亚新几内亚基那),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(菲律宾比索),
				'other' => q(菲律宾比索),
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
				'currency' => q(卡塔尔里亚尔),
				'other' => q(卡塔尔里亚尔),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(罗得西亚元),
				'other' => q(罗得西亚元),
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
				'currency' => q(塞尔维亚第纳尔),
				'other' => q(塞尔维亚第纳尔),
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
				'currency' => q(俄国卢布 \(1991–1998\)),
				'other' => q(俄国卢布 \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(卢旺达法郎),
				'other' => q(卢旺达法郎),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(沙特里亚尔),
				'other' => q(沙特里亚尔),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(所罗门群岛元),
				'other' => q(所罗门群岛元),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(塞舌尔卢比),
				'other' => q(塞舌尔卢比),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(苏丹第纳尔 \(1992–2007\)),
				'other' => q(苏丹第纳尔 \(1992–2007\)),
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
				'currency' => q(新加坡元),
				'other' => q(新加坡元),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(圣赫勒拿群岛磅),
				'other' => q(圣赫勒拿群岛磅),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(斯洛文尼亚托拉尔),
				'other' => q(斯洛文尼亚托拉尔),
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
				'currency' => q(塞拉利昂利昂),
				'other' => q(塞拉利昂利昂),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(索马里先令),
				'other' => q(索马里先令),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(苏里南元),
				'other' => q(苏里南元),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(苏里南盾),
				'other' => q(苏里南盾),
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
				'currency' => q(圣多美和普林西比多布拉 \(1977–2017\)),
				'other' => q(圣多美和普林西比多布拉 \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(圣多美和普林西比多布拉),
				'other' => q(圣多美和普林西比多布拉),
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
				'currency' => q(萨尔瓦多科朗),
				'other' => q(萨尔瓦多科朗),
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
				'currency' => q(斯威士兰里兰吉尼),
				'other' => q(斯威士兰里兰吉尼),
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
				'currency' => q(塔吉克斯坦卢布),
				'other' => q(塔吉克斯坦卢布),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(塔吉克斯坦索莫尼),
				'other' => q(塔吉克斯坦索莫尼),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(土库曼斯坦马纳特 \(1993–2009\)),
				'other' => q(土库曼斯坦马纳特 \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(土库曼斯坦马纳特),
				'other' => q(土库曼斯坦马纳特),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(突尼斯第纳尔),
				'other' => q(突尼斯第纳尔),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(汤加潘加),
				'other' => q(汤加潘加),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(帝汶埃斯库多),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(土耳其里拉 \(1922–2005\)),
				'other' => q(土耳其里拉 \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(土耳其里拉),
				'other' => q(土耳其里拉),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(特立尼达和多巴哥元),
				'other' => q(特立尼达和多巴哥元),
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
				'currency' => q(坦桑尼亚先令),
				'other' => q(坦桑尼亚先令),
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
				'currency' => q(乌克兰币),
				'other' => q(乌克兰币),
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
				'currency' => q(乌拉圭比索（索引单位）),
				'other' => q(乌拉圭比索（索引单位）),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(乌拉圭比索 \(1975–1993\)),
				'other' => q(乌拉圭比索 \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(乌拉圭比索),
				'other' => q(乌拉圭比索),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(乌兹别克斯坦苏姆),
				'other' => q(乌兹别克斯坦苏姆),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(委内瑞拉玻利瓦尔 \(1871–2008\)),
				'other' => q(委内瑞拉玻利瓦尔 \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(委内瑞拉玻利瓦尔 \(2008–2018\)),
				'other' => q(委内瑞拉玻利瓦尔 \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(委内瑞拉玻利瓦尔),
				'other' => q(委内瑞拉玻利瓦尔),
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
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(瓦努阿图瓦图),
				'other' => q(瓦努阿图瓦图),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(萨摩亚塔拉),
				'other' => q(萨摩亚塔拉),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(中非法郎),
				'other' => q(中非法郎),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(银),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(黄金),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(欧洲复合单位),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(欧洲货币联盟),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(欧洲计算单位 \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(欧洲计算单位 \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(东加勒比元),
				'other' => q(东加勒比元),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(特别提款权),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(欧洲货币单位),
				'other' => q(欧洲货币单位),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(法国金法郎),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(法国法郎 \(UIC\)),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(西非法郎),
				'other' => q(西非法郎),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(钯),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(太平洋法郎),
				'other' => q(太平洋法郎),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(铂),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(RINET 基金),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(测试货币代码),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(未知货币),
				'other' => q(（未知货币）),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(也门第纳尔),
				'other' => q(也门第纳尔),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(也门里亚尔),
				'other' => q(也门里亚尔),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(南斯拉夫硬第纳尔 \(1966–1990\)),
				'other' => q(南斯拉夫硬第纳尔 \(1966–1990\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(南斯拉夫新第纳尔 \(1994–2002\)),
				'other' => q(南斯拉夫新第纳尔 \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(南斯拉夫可兑换第纳尔 \(1990–1992\)),
				'other' => q(南斯拉夫可兑换第纳尔 \(1990–1992\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(南斯拉夫改良第纳尔 \(1992–1993\)),
				'other' => q(南斯拉夫改良第纳尔 \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(南非兰特 \(金融\)),
				'other' => q(南非兰特 \(金融\)),
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
				'currency' => q(赞比亚克瓦查 \(1968–2012\)),
				'other' => q(赞比亚克瓦查 \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(赞比亚克瓦查),
				'other' => q(赞比亚克瓦查),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(新扎伊尔 \(1993–1998\)),
				'other' => q(新扎伊尔 \(1993–1998\)),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(扎伊尔 \(1971–1993\)),
				'other' => q(扎伊尔 \(1971–1993\)),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(津巴布韦元 \(1980–2008\)),
				'other' => q(津巴布韦元 \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(津巴布韦元 \(2009\)),
				'other' => q(津巴布韦元 \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(津巴布韦元 \(2008\)),
				'other' => q(津巴布韦元 \(2008\)),
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
							'十一月',
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
							'十一',
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
							'十一月',
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
							'十一月',
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
							'十一月',
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
							'十二月',
							'十三月'
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
							'十二月',
							'十三月'
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
							'十二月',
							'十三月'
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
							'十二月',
							'十三月'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'闰7月'
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
							'十二月',
							'十三月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'闰七月'
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
							'',
							'',
							'',
							'',
							'',
							'',
							'闰7月'
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
							'十二月',
							'十三月'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'闰七月'
						],
					},
				},
			},
			'indian' => {
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
			'islamic' => {
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
					abbreviated => {0 => '1季度',
						1 => '2季度',
						2 => '3季度',
						3 => '4季度'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '第一季度',
						1 => '第二季度',
						2 => '第三季度',
						3 => '第四季度'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1季度',
						1 => '2季度',
						2 => '3季度',
						3 => '4季度'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '第一季度',
						1 => '第二季度',
						2 => '第三季度',
						3 => '第四季度'
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
			if ($_ eq 'coptic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'dangi') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
				}
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'night1' if $time >= 0
						&& $time < 500;
					return 'morning2' if $time >= 800
						&& $time < 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'morning1' if $time >= 500
						&& $time < 800;
					return 'afternoon2' if $time >= 1300
						&& $time < 1900;
					return 'evening1' if $time >= 1900
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
					'morning2' => q{上午},
					'night1' => q{凌晨},
					'midnight' => q{午夜},
					'pm' => q{下午},
					'am' => q{上午},
					'afternoon2' => q{下午},
					'afternoon1' => q{中午},
					'evening1' => q{晚上},
					'morning1' => q{早上},
				},
				'wide' => {
					'afternoon2' => q{下午},
					'am' => q{上午},
					'pm' => q{下午},
					'midnight' => q{午夜},
					'morning2' => q{上午},
					'night1' => q{凌晨},
					'morning1' => q{清晨},
					'evening1' => q{晚上},
					'afternoon1' => q{中午},
				},
				'narrow' => {
					'morning2' => q{上午},
					'night1' => q{凌晨},
					'afternoon2' => q{下午},
					'am' => q{上午},
					'pm' => q{下午},
					'midnight' => q{午夜},
					'afternoon1' => q{中午},
					'morning1' => q{早上},
					'evening1' => q{晚上},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'morning2' => q{上午},
					'night1' => q{凌晨},
					'afternoon2' => q{下午},
					'am' => q{上午},
					'pm' => q{下午},
					'midnight' => q{午夜},
					'afternoon1' => q{中午},
					'morning1' => q{早上},
					'evening1' => q{晚上},
				},
				'wide' => {
					'afternoon1' => q{中午},
					'morning1' => q{早上},
					'evening1' => q{晚上},
					'night1' => q{凌晨},
					'morning2' => q{上午},
					'am' => q{上午},
					'afternoon2' => q{下午},
					'midnight' => q{午夜},
					'pm' => q{下午},
				},
				'abbreviated' => {
					'midnight' => q{午夜},
					'pm' => q{下午},
					'am' => q{上午},
					'afternoon2' => q{下午},
					'night1' => q{凌晨},
					'morning2' => q{上午},
					'evening1' => q{晚上},
					'morning1' => q{早上},
					'afternoon1' => q{中午},
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
			narrow => {
				'0' => '佛历'
			},
			wide => {
				'0' => '佛历'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => '科普特历前',
				'1' => '科普特历'
			},
			narrow => {
				'0' => '科普特历前',
				'1' => '科普特历'
			},
			wide => {
				'0' => '科普特历前',
				'1' => '科普特历'
			},
		},
		'dangi' => {
		},
		'ethiopic' => {
			wide => {
				'0' => '埃塞俄比亚历前',
				'1' => '埃塞俄比亚历'
			},
		},
		'ethiopic-amete-alem' => {
			wide => {
				'0' => '埃塞俄比亚阿米特阿莱姆历'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => '公元前',
				'1' => '公元'
			},
			narrow => {
				'0' => '公元前',
				'1' => '公元'
			},
			wide => {
				'0' => '公元前',
				'1' => '公元'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => '希伯来历'
			},
			narrow => {
				'0' => '希伯来历'
			},
			wide => {
				'0' => '希伯来历'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => '印度历'
			},
			narrow => {
				'0' => '印度历'
			},
			wide => {
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
				'0' => '大化 (645–650)',
				'1' => '白雉 (650–671)',
				'2' => '白凤 (672–686)',
				'3' => '朱鸟 (686–701)',
				'4' => '大宝 (701–704)',
				'5' => '庆云 (704–708)',
				'6' => '和铜 (708–715)',
				'7' => '灵龟 (715–717)',
				'8' => '养老 (717–724)',
				'9' => '神龟 (724–729)',
				'10' => '天平 (729–749)',
				'11' => '天平感宝 (749–749)',
				'12' => '天平胜宝 (749–757)',
				'13' => '天平宝字 (757–765)',
				'14' => '天平神护 (765–767)',
				'15' => '神护景云 (767–770)',
				'16' => '宝龟 (770–780)',
				'17' => '天应 (781–782)',
				'18' => '延历 (782–806)',
				'19' => '大同 (806–810)',
				'20' => '弘仁 (810–824)',
				'21' => '天长 (824–834)',
				'22' => '承和 (834–848)',
				'23' => '嘉祥 (848–851)',
				'24' => '仁寿 (851–854)',
				'25' => '齐衡 (854–857)',
				'26' => '天安 (857–859)',
				'27' => '贞观 (859–877)',
				'28' => '元庆 (877–885)',
				'29' => '仁和 (885–889)',
				'30' => '宽平 (889–898)',
				'31' => '昌泰 (898–901)',
				'32' => '延喜 (901–923)',
				'33' => '延长 (923–931)',
				'34' => '承平 (931–938)',
				'35' => '天庆 (938–947)',
				'36' => '天历 (947–957)',
				'37' => '天德 (957–961)',
				'38' => '应和 (961–964)',
				'39' => '康保 (964–968)',
				'40' => '安和 (968–970)',
				'41' => '天禄 (970–973)',
				'42' => '天延 (973–976)',
				'43' => '贞元 (976–978)',
				'44' => '天元 (978–983)',
				'45' => '永观 (983–985)',
				'46' => '宽和 (985–987)',
				'47' => '永延 (987–989)',
				'48' => '永祚 (989–990)',
				'49' => '正历 (990–995)',
				'50' => '长德 (995–999)',
				'51' => '长保 (999–1004)',
				'52' => '宽弘 (1004–1012)',
				'53' => '长和 (1012–1017)',
				'54' => '宽仁 (1017–1021)',
				'55' => '治安 (1021–1024)',
				'56' => '万寿 (1024–1028)',
				'57' => '长元 (1028–1037)',
				'58' => '长历 (1037–1040)',
				'59' => '长久 (1040–1044)',
				'60' => '宽德 (1044–1046)',
				'61' => '永承 (1046–1053)',
				'62' => '天喜 (1053–1058)',
				'63' => '康平 (1058–1065)',
				'64' => '治历 (1065–1069)',
				'65' => '延久 (1069–1074)',
				'66' => '承保 (1074–1077)',
				'67' => '正历 (1077–1081)',
				'68' => '永保 (1081–1084)',
				'69' => '应德 (1084–1087)',
				'70' => '宽治 (1087–1094)',
				'71' => '嘉保 (1094–1096)',
				'72' => '永长 (1096–1097)',
				'73' => '承德 (1097–1099)',
				'74' => '康和 (1099–1104)',
				'75' => '长治 (1104–1106)',
				'76' => '嘉承 (1106–1108)',
				'77' => '天仁 (1108–1110)',
				'78' => '天永 (1110–1113)',
				'79' => '永久 (1113–1118)',
				'80' => '元永 (1118–1120)',
				'81' => '保安 (1120–1124)',
				'82' => '天治 (1124–1126)',
				'83' => '大治 (1126–1131)',
				'84' => '天承 (1131–1132)',
				'85' => '长承 (1132–1135)',
				'86' => '保延 (1135–1141)',
				'87' => '永治 (1141–1142)',
				'88' => '康治 (1142–1144)',
				'89' => '天养 (1144–1145)',
				'90' => '久安 (1145–1151)',
				'91' => '仁平 (1151–1154)',
				'92' => '久寿 (1154–1156)',
				'93' => '保元 (1156–1159)',
				'94' => '平治 (1159–1160)',
				'95' => '永历 (1160–1161)',
				'96' => '应保 (1161–1163)',
				'97' => '长宽 (1163–1165)',
				'98' => '永万 (1165–1166)',
				'99' => '仁安 (1166–1169)',
				'100' => '嘉应 (1169–1171)',
				'101' => '承安 (1171–1175)',
				'102' => '安元 (1175–1177)',
				'103' => '治承 (1177–1181)',
				'104' => '养和 (1181–1182)',
				'105' => '寿永 (1182–1184)',
				'106' => '元历 (1184–1185)',
				'107' => '文治 (1185–1190)',
				'108' => '建久 (1190–1199)',
				'109' => '正治 (1199–1201)',
				'110' => '建仁 (1201–1204)',
				'111' => '元久 (1204–1206)',
				'112' => '建永 (1206–1207)',
				'113' => '承元 (1207–1211)',
				'114' => '建历 (1211–1213)',
				'115' => '建保 (1213–1219)',
				'116' => '承久 (1219–1222)',
				'117' => '贞应 (1222–1224)',
				'118' => '元仁 (1224–1225)',
				'119' => '嘉禄 (1225–1227)',
				'120' => '安贞 (1227–1229)',
				'121' => '宽喜 (1229–1232)',
				'122' => '贞永 (1232–1233)',
				'123' => '天福 (1233–1234)',
				'124' => '文历 (1234–1235)',
				'125' => '嘉祯 (1235–1238)',
				'126' => '历仁 (1238–1239)',
				'127' => '延应 (1239–1240)',
				'128' => '仁治 (1240–1243)',
				'129' => '宽元 (1243–1247)',
				'130' => '宝治 (1247–1249)',
				'131' => '建长 (1249–1256)',
				'132' => '康元 (1256–1257)',
				'133' => '正嘉 (1257–1259)',
				'134' => '正元 (1259–1260)',
				'135' => '文应 (1260–1261)',
				'136' => '弘长 (1261–1264)',
				'137' => '文永 (1264–1275)',
				'138' => '建治 (1275–1278)',
				'139' => '弘安 (1278–1288)',
				'140' => '正应 (1288–1293)',
				'141' => '永仁 (1293–1299)',
				'142' => '正安 (1299–1302)',
				'143' => '干元 (1302–1303)',
				'144' => '嘉元 (1303–1306)',
				'145' => '德治 (1306–1308)',
				'146' => '延庆 (1308–1311)',
				'147' => '应长 (1311–1312)',
				'148' => '正和 (1312–1317)',
				'149' => '文保 (1317–1319)',
				'150' => '元应 (1319–1321)',
				'151' => '元亨 (1321–1324)',
				'152' => '正中 (1324–1326)',
				'153' => '嘉历 (1326–1329)',
				'154' => '元德 (1329–1331)',
				'155' => '元弘 (1331–1334)',
				'156' => '建武 (1334–1336)',
				'157' => '延元 (1336–1340)',
				'158' => '兴国 (1340–1346)',
				'159' => '正平 (1346–1370)',
				'160' => '建德 (1370–1372)',
				'161' => '文中 (1372–1375)',
				'162' => '天授 (1375–1379)',
				'163' => '康历 (1379–1381)',
				'164' => '弘和 (1381–1384)',
				'165' => '元中 (1384–1392)',
				'166' => '至德 (1384–1387)',
				'167' => '嘉庆 (1387–1389)',
				'168' => '康应 (1389–1390)',
				'169' => '明德 (1390–1394)',
				'170' => '应永 (1394–1428)',
				'171' => '正长 (1428–1429)',
				'172' => '永享 (1429–1441)',
				'173' => '嘉吉 (1441–1444)',
				'174' => '文安 (1444–1449)',
				'175' => '宝德 (1449–1452)',
				'176' => '享德 (1452–1455)',
				'177' => '康正 (1455–1457)',
				'178' => '长禄 (1457–1460)',
				'179' => '宽正 (1460–1466)',
				'180' => '文正 (1466–1467)',
				'181' => '应仁 (1467–1469)',
				'182' => '文明 (1469–1487)',
				'183' => '长享 (1487–1489)',
				'184' => '延德 (1489–1492)',
				'185' => '明应 (1492–1501)',
				'186' => '文龟 (1501–1504)',
				'187' => '永正 (1504–1521)',
				'188' => '大永 (1521–1528)',
				'189' => '享禄 (1528–1532)',
				'190' => '天文 (1532–1555)',
				'191' => '弘治 (1555–1558)',
				'192' => '永禄 (1558–1570)',
				'193' => '元龟 (1570–1573)',
				'194' => '天正 (1573–1592)',
				'195' => '文禄 (1592–1596)',
				'196' => '庆长 (1596–1615)',
				'197' => '元和 (1615–1624)',
				'198' => '宽永 (1624–1644)',
				'199' => '正保 (1644–1648)',
				'200' => '庆安 (1648–1652)',
				'201' => '承应 (1652–1655)',
				'202' => '明历 (1655–1658)',
				'203' => '万治 (1658–1661)',
				'204' => '宽文 (1661–1673)',
				'205' => '延宝 (1673–1681)',
				'206' => '天和 (1681–1684)',
				'207' => '贞享 (1684–1688)',
				'208' => '元禄 (1688–1704)',
				'209' => '宝永 (1704–1711)',
				'210' => '正德 (1711–1716)',
				'211' => '享保 (1716–1736)',
				'212' => '元文 (1736–1741)',
				'213' => '宽保 (1741–1744)',
				'214' => '延享 (1744–1748)',
				'215' => '宽延 (1748–1751)',
				'216' => '宝历 (1751–1764)',
				'217' => '明和 (1764–1772)',
				'218' => '安永 (1772–1781)',
				'219' => '天明 (1781–1789)',
				'220' => '宽政 (1789–1801)',
				'221' => '享和 (1801–1804)',
				'222' => '文化 (1804–1818)',
				'223' => '文政 (1818–1830)',
				'224' => '天保 (1830–1844)',
				'225' => '弘化 (1844–1848)',
				'226' => '嘉永 (1848–1854)',
				'227' => '安政 (1854–1860)',
				'228' => '万延 (1860–1861)',
				'229' => '文久 (1861–1864)',
				'230' => '元治 (1864–1865)',
				'231' => '庆应 (1865–1868)',
				'232' => '明治',
				'233' => '大正',
				'234' => '昭和',
				'235' => '平成'
			},
			narrow => {
				'0' => '大化(645–650)',
				'1' => '白雉(650–671)',
				'2' => '白凤(672–686)',
				'3' => '朱鸟(686–701)',
				'4' => '大宝(701–704)',
				'5' => '庆云(704–708)',
				'6' => '和铜(708–715)',
				'7' => '灵龟(715–717)',
				'8' => '养老(717–724)',
				'9' => '神龟(724–729)',
				'10' => '天平(729–749)',
				'11' => '天平感宝(749–749)',
				'12' => '天平胜宝(749–757)',
				'13' => '天平宝字(757–765)',
				'14' => '天平神护(765–767)',
				'15' => '神护景云(767–770)',
				'16' => '宝龟(770–780)',
				'17' => '天应(781–782)',
				'18' => '延历(782–806)',
				'19' => '大同(806–810)',
				'20' => '弘仁(810–824)',
				'21' => '天长(824–834)',
				'22' => '承和(834–848)',
				'23' => '嘉祥(848–851)',
				'24' => '仁寿(851–854)',
				'25' => '齐衡(854–857)',
				'26' => '天安(857–859)',
				'27' => '贞观(859–877)',
				'28' => '元庆(877–885)',
				'29' => '仁和(885–889)',
				'30' => '宽平(889–898)',
				'31' => '昌泰(898–901)',
				'32' => '延喜(901–923)',
				'33' => '延长(923–931)',
				'34' => '承平(931–938)',
				'35' => '天庆(938–947)',
				'36' => '天历(947–957)',
				'37' => '天德(957–961)',
				'38' => '应和(961–964)',
				'39' => '康保(964–968)',
				'40' => '安和(968–970)',
				'41' => '天禄(970–973)',
				'42' => '天延(973–976)',
				'43' => '贞元(976–978)',
				'44' => '天元(978–983)',
				'45' => '永观(983–985)',
				'46' => '宽和(985–987)',
				'47' => '永延(987–989)',
				'48' => '永祚(989–990)',
				'49' => '正历(990–995)',
				'50' => '长德(995–999)',
				'51' => '长保(999–1004)',
				'52' => '宽弘(1004–1012)',
				'53' => '长和(1012–1017)',
				'54' => '宽仁(1017–1021)',
				'55' => '治安(1021–1024)',
				'56' => '万寿(1024–1028)',
				'57' => '长元(1028–1037)',
				'58' => '长历(1037–1040)',
				'59' => '长久(1040–1044)',
				'60' => '宽德(1044–1046)',
				'61' => '永承(1046–1053)',
				'62' => '天喜(1053–1058)',
				'63' => '康平(1058–1065)',
				'64' => '治历(1065–1069)',
				'65' => '延久(1069–1074)',
				'66' => '承保(1074–1077)',
				'67' => '承历(1077–1081)',
				'68' => '永保(1081–1084)',
				'69' => '应德(1084–1087)',
				'70' => '宽治(1087–1094)',
				'71' => '嘉保(1094–1096)',
				'72' => '永长(1096–1097)',
				'73' => '承德(1097–1099)',
				'74' => '康和(1099–1104)',
				'75' => '长治(1104–1106)',
				'76' => '嘉承(1106–1108)',
				'77' => '天仁(1108–1110)',
				'78' => '天永(1110–1113)',
				'79' => '永久(1113–1118)',
				'80' => '元永(1118–1120)',
				'81' => '保安(1120–1124)',
				'82' => '天治(1124–1126)',
				'83' => '大治(1126–1131)',
				'84' => '天承(1131–1132)',
				'85' => '长承(1132–1135)',
				'86' => '保延(1135–1141)',
				'87' => '永治(1141–1142)',
				'88' => '康治(1142–1144)',
				'89' => '天养(1144–1145)',
				'90' => '久安(1145–1151)',
				'91' => '仁平(1151–1154)',
				'92' => '久寿(1154–1156)',
				'93' => '保元(1156–1159)',
				'94' => '平治(1159–1160)',
				'95' => '永历(1160–1161)',
				'96' => '应保(1161–1163)',
				'97' => '长宽(1163–1165)',
				'98' => '永万(1165–1166)',
				'99' => '仁安(1166–1169)',
				'100' => '嘉应(1169–1171)',
				'101' => '承安(1171–1175)',
				'102' => '安元(1175–1177)',
				'103' => '治承(1177–1181)',
				'104' => '养和(1181–1182)',
				'105' => '寿永(1182–1184)',
				'106' => '元历(1184–1185)',
				'107' => '文治(1185–1190)',
				'108' => '建久(1190–1199)',
				'109' => '正治(1199–1201)',
				'110' => '建仁(1201–1204)',
				'111' => '元久(1204–1206)',
				'112' => '建永(1206–1207)',
				'113' => '承元(1207–1211)',
				'114' => '建历(1211–1213)',
				'115' => '建保(1213–1219)',
				'116' => '承久(1219–1222)',
				'117' => '贞应(1222–1224)',
				'118' => '元仁(1224–1225)',
				'119' => '嘉禄(1225–1227)',
				'120' => '安贞(1227–1229)',
				'121' => '宽喜(1229–1232)',
				'122' => '贞永(1232–1233)',
				'123' => '天福(1233–1234)',
				'124' => '文历(1234–1235)',
				'125' => '嘉祯(1235–1238)',
				'126' => '历仁(1238–1239)',
				'127' => '延应(1239–1240)',
				'128' => '仁治(1240–1243)',
				'129' => '宽元(1243–1247)',
				'130' => '宝治(1247–1249)',
				'131' => '建长(1249–1256)',
				'132' => '康元(1256–1257)',
				'133' => '正嘉(1257–1259)',
				'134' => '正元(1259–1260)',
				'135' => '文应(1260–1261)',
				'136' => '弘长(1261–1264)',
				'137' => '文永(1264–1275)',
				'138' => '建治(1275–1278)',
				'139' => '弘安(1278–1288)',
				'140' => '正应(1288–1293)',
				'141' => '永仁(1293–1299)',
				'142' => '正安(1299–1302)',
				'143' => '乾元(1302–1303)',
				'144' => '嘉元(1303–1306)',
				'145' => '德治(1306–1308)',
				'146' => '延庆(1308–1311)',
				'147' => '应长(1311–1312)',
				'148' => '正和(1312–1317)',
				'149' => '文保(1317–1319)',
				'150' => '元应(1319–1321)',
				'151' => '元亨(1321–1324)',
				'152' => '正中(1324–1326)',
				'153' => '嘉历(1326–1329)',
				'154' => '元德(1329–1331)',
				'155' => '元弘(1331–1334)',
				'156' => '建武(1334–1336)',
				'157' => '延元(1336–1340)',
				'158' => '兴国(1340–1346)',
				'159' => '正平(1346–1370)',
				'160' => '建德(1370–1372)',
				'161' => '文中(1372–1375)',
				'162' => '天授(1375–1379)'
			},
			wide => {
				'0' => '大化 (645–650)',
				'1' => '白雉 (650–671)',
				'2' => '白凤 (672–686)',
				'3' => '朱鸟 (686–701)',
				'4' => '大宝 (701–704)',
				'5' => '庆云 (704–708)',
				'6' => '和铜 (708–715)',
				'7' => '灵龟 (715–717)',
				'8' => '养老 (717–724)',
				'9' => '神龟 (724–729)',
				'10' => '天平 (729–749)',
				'11' => '天平感宝 (749–749)',
				'12' => '天平胜宝 (749–757)',
				'13' => '天平宝字 (757–765)',
				'14' => '天平神护 (765–767)',
				'15' => '神护景云 (767–770)',
				'16' => '宝龟 (770–780)',
				'17' => '天应 (781–782)',
				'18' => '延历 (782–806)',
				'19' => '大同 (806–810)',
				'20' => '弘仁 (810–824)',
				'21' => '天长 (824–834)',
				'22' => '承和 (834–848)',
				'23' => '嘉祥 (848–851)',
				'24' => '仁寿 (851–854)',
				'25' => '齐衡 (854–857)',
				'26' => '天安 (857–859)',
				'27' => '贞观 (859–877)',
				'28' => '元庆 (877–885)',
				'29' => '仁和 (885–889)',
				'30' => '宽平 (889–898)',
				'31' => '昌泰 (898–901)',
				'32' => '延喜 (901–923)',
				'33' => '延长 (923–931)',
				'34' => '承平 (931–938)',
				'35' => '天庆 (938–947)',
				'36' => '天历 (947–957)',
				'37' => '天德 (957–961)',
				'38' => '应和 (961–964)',
				'39' => '康保 (964–968)',
				'40' => '安和 (968–970)',
				'41' => '天禄 (970–973)',
				'42' => '天延 (973–976)',
				'43' => '贞元 (976–978)',
				'44' => '天元 (978–983)',
				'45' => '永观 (983–985)',
				'46' => '宽和 (985–987)',
				'47' => '永延 (987–989)',
				'48' => '永祚 (989–990)',
				'49' => '正历 (990–995)',
				'50' => '长德 (995–999)',
				'51' => '长保 (999–1004)',
				'52' => '宽弘 (1004–1012)',
				'53' => '长和 (1012–1017)',
				'54' => '宽仁 (1017–1021)',
				'55' => '治安 (1021–1024)',
				'56' => '万寿 (1024–1028)',
				'57' => '长元 (1028–1037)',
				'58' => '长历 (1037–1040)',
				'59' => '长久 (1040–1044)',
				'60' => '宽德 (1044–1046)',
				'61' => '永承 (1046–1053)',
				'62' => '天喜 (1053–1058)',
				'63' => '康平 (1058–1065)',
				'64' => '治历 (1065–1069)',
				'65' => '延久 (1069–1074)',
				'66' => '承保 (1074–1077)',
				'67' => '正历 (1077–1081)',
				'68' => '永保 (1081–1084)',
				'69' => '应德 (1084–1087)',
				'70' => '宽治 (1087–1094)',
				'71' => '嘉保 (1094–1096)',
				'72' => '永长 (1096–1097)',
				'73' => '承德 (1097–1099)',
				'74' => '康和 (1099–1104)',
				'75' => '长治 (1104–1106)',
				'76' => '嘉承 (1106–1108)',
				'77' => '天仁 (1108–1110)',
				'78' => '天永 (1110–1113)',
				'79' => '永久 (1113–1118)',
				'80' => '元永 (1118–1120)',
				'81' => '保安 (1120–1124)',
				'82' => '天治 (1124–1126)',
				'83' => '大治 (1126–1131)',
				'84' => '天承 (1131–1132)',
				'85' => '长承 (1132–1135)',
				'86' => '保延 (1135–1141)',
				'87' => '永治 (1141–1142)',
				'88' => '康治 (1142–1144)',
				'89' => '天养 (1144–1145)',
				'90' => '久安 (1145–1151)',
				'91' => '仁平 (1151–1154)',
				'92' => '久寿 (1154–1156)',
				'93' => '保元 (1156–1159)',
				'94' => '平治 (1159–1160)',
				'95' => '永历 (1160–1161)',
				'96' => '应保 (1161–1163)',
				'97' => '长宽 (1163–1165)',
				'98' => '永万 (1165–1166)',
				'99' => '仁安 (1166–1169)',
				'100' => '嘉应 (1169–1171)',
				'101' => '承安 (1171–1175)',
				'102' => '安元 (1175–1177)',
				'103' => '治承 (1177–1181)',
				'104' => '养和 (1181–1182)',
				'105' => '寿永 (1182–1184)',
				'106' => '元历 (1184–1185)',
				'107' => '文治 (1185–1190)',
				'108' => '建久 (1190–1199)',
				'109' => '正治 (1199–1201)',
				'110' => '建仁 (1201–1204)',
				'111' => '元久 (1204–1206)',
				'112' => '建永 (1206–1207)',
				'113' => '承元 (1207–1211)',
				'114' => '建历 (1211–1213)',
				'115' => '建保 (1213–1219)',
				'116' => '承久 (1219–1222)',
				'117' => '贞应 (1222–1224)',
				'118' => '元仁 (1224–1225)',
				'119' => '嘉禄 (1225–1227)',
				'120' => '安贞 (1227–1229)',
				'121' => '宽喜 (1229–1232)',
				'122' => '贞永 (1232–1233)',
				'123' => '天福 (1233–1234)',
				'124' => '文历 (1234–1235)',
				'125' => '嘉祯 (1235–1238)',
				'126' => '历仁 (1238–1239)',
				'127' => '延应 (1239–1240)',
				'128' => '仁治 (1240–1243)',
				'129' => '宽元 (1243–1247)',
				'130' => '宝治 (1247–1249)',
				'131' => '建长 (1249–1256)',
				'132' => '康元 (1256–1257)',
				'133' => '正嘉 (1257–1259)',
				'134' => '正元 (1259–1260)',
				'135' => '文应 (1260–1261)',
				'136' => '弘长 (1261–1264)',
				'137' => '文永 (1264–1275)',
				'138' => '建治 (1275–1278)',
				'139' => '弘安 (1278–1288)',
				'140' => '正应 (1288–1293)',
				'141' => '永仁 (1293–1299)',
				'142' => '正安 (1299–1302)',
				'143' => '干元 (1302–1303)',
				'144' => '嘉元 (1303–1306)',
				'145' => '德治 (1306–1308)',
				'146' => '延庆 (1308–1311)',
				'147' => '应长 (1311–1312)',
				'148' => '正和 (1312–1317)',
				'149' => '文保 (1317–1319)',
				'150' => '元应 (1319–1321)',
				'151' => '元亨 (1321–1324)',
				'152' => '正中 (1324–1326)',
				'153' => '嘉历 (1326–1329)',
				'154' => '元德 (1329–1331)',
				'155' => '元弘 (1331–1334)',
				'156' => '建武 (1334–1336)',
				'157' => '延元 (1336–1340)',
				'158' => '兴国 (1340–1346)',
				'159' => '正平 (1346–1370)',
				'160' => '建德 (1370–1372)',
				'161' => '文中 (1372–1375)',
				'162' => '天授 (1375–1379)',
				'163' => '康历 (1379–1381)',
				'164' => '弘和 (1381–1384)',
				'165' => '元中 (1384–1392)',
				'166' => '至德 (1384–1387)',
				'167' => '嘉庆 (1387–1389)',
				'168' => '康应 (1389–1390)',
				'169' => '明德 (1390–1394)',
				'170' => '应永 (1394–1428)',
				'171' => '正长 (1428–1429)',
				'172' => '永享 (1429–1441)',
				'173' => '嘉吉 (1441–1444)',
				'174' => '文安 (1444–1449)',
				'175' => '宝德 (1449–1452)',
				'176' => '享德 (1452–1455)',
				'177' => '康正 (1455–1457)',
				'178' => '长禄 (1457–1460)',
				'179' => '宽正 (1460–1466)',
				'180' => '文正 (1466–1467)',
				'181' => '应仁 (1467–1469)',
				'182' => '文明 (1469–1487)',
				'183' => '长享 (1487–1489)',
				'184' => '延德 (1489–1492)',
				'185' => '明应 (1492–1501)',
				'186' => '文龟 (1501–1504)',
				'187' => '永正 (1504–1521)',
				'188' => '大永 (1521–1528)',
				'189' => '享禄 (1528–1532)',
				'190' => '天文 (1532–1555)',
				'191' => '弘治 (1555–1558)',
				'192' => '永禄 (1558–1570)',
				'193' => '元龟 (1570–1573)',
				'194' => '天正 (1573–1592)',
				'195' => '文禄 (1592–1596)',
				'196' => '庆长 (1596–1615)',
				'197' => '元和 (1615–1624)',
				'198' => '宽永 (1624–1644)',
				'199' => '正保 (1644–1648)',
				'200' => '庆安 (1648–1652)',
				'201' => '承应 (1652–1655)',
				'202' => '明历 (1655–1658)',
				'203' => '万治 (1658–1661)',
				'204' => '宽文 (1661–1673)',
				'205' => '延宝 (1673–1681)',
				'206' => '天和 (1681–1684)',
				'207' => '贞享 (1684–1688)',
				'208' => '元禄 (1688–1704)',
				'209' => '宝永 (1704–1711)',
				'210' => '正德 (1711–1716)',
				'211' => '享保 (1716–1736)',
				'212' => '元文 (1736–1741)',
				'213' => '宽保 (1741–1744)',
				'214' => '延享 (1744–1748)',
				'215' => '宽延 (1748–1751)',
				'216' => '宝历 (1751–1764)',
				'217' => '明和 (1764–1772)',
				'218' => '安永 (1772–1781)',
				'219' => '天明 (1781–1789)',
				'220' => '宽政 (1789–1801)',
				'221' => '享和 (1801–1804)',
				'222' => '文化 (1804–1818)',
				'223' => '文政 (1818–1830)',
				'224' => '天保 (1830–1844)',
				'225' => '弘化 (1844–1848)',
				'226' => '嘉永 (1848–1854)',
				'227' => '安政 (1854–1860)',
				'228' => '万延 (1860–1861)',
				'229' => '文久 (1861–1864)',
				'230' => '元治 (1864–1865)',
				'231' => '庆应 (1865–1868)',
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
			narrow => {
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
			narrow => {
				'0' => '民国前',
				'1' => '民国'
			},
			wide => {
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
			'full' => q{Gy年MM月d日EEEE},
		},
		'dangi' => {
		},
		'ethiopic' => {
			'full' => q{Gy年MM月d日EEEE},
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
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
			'full' => q{Gy年MM月d日EEEE},
			'long' => q{Gy年MM月d日},
			'medium' => q{Gy年MM月d日},
			'short' => q{Gy/M/d},
		},
		'islamic' => {
			'full' => q{Gy年M月d日EEEE},
			'long' => q{Gy年M月d日},
			'medium' => q{Gy年M月d日},
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
		'ethiopic-amete-alem' => {
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'chinese' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'indian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			yyyyQQQ => q{Gy年第Q季度},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'buddhist' => {
			E => q{ccc},
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年MM月},
			GyMMMEd => q{Gy年MM月d日E},
			GyMMMd => q{Gy年MM月d日},
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
			yyyyQQQ => q{Gy年第Q季度},
			yyyyQQQQ => q{Gy年QQQQ},
		},
		'chinese' => {
			Bh => q{Bh时},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			E => q{ccc},
			EBhm => q{EB h:mm},
			EBhms => q{EB h:mm:ss},
			Ed => q{d日E},
			Gy => q{rU年},
			GyMMM => q{rU年MMM},
			GyMMMEd => q{rU年MMMdE},
			GyMMMd => q{r年MMMd},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{MMM},
			MEd => q{M-dE},
			MMM => q{LLL},
			MMMEd => q{MMMd日E},
			MMMMd => q{MMMMd日},
			MMMd => q{MMMd日},
			Md => q{M-d},
			UM => q{U年MMM},
			UMMM => q{U年MMM},
			UMMMd => q{U年MMMd},
			UMd => q{U年MMMd},
			d => q{d日},
			h => q{ah时},
			hm => q{ah:mm},
			hms => q{ah:mm:ss},
			ms => q{mm:ss},
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
		'islamic' => {
			M => q{M月},
			MEd => q{M-dE},
			MMM => q{LLL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M-d},
			d => q{d日},
		},
		'hebrew' => {
			E => q{ccc},
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年MM月},
			GyMMMEd => q{Gy年MM月d日E},
			GyMMMd => q{Gy年MM月d日},
			M => q{L},
			MEd => q{M/dE},
			MMM => q{LL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M/d},
			d => q{d日},
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
		'indian' => {
			E => q{ccc},
			Ed => q{d日E},
			Gy => q{Gy年},
			GyMMM => q{Gy年MM月},
			GyMMMEd => q{Gy年MM月d日E},
			GyMMMd => q{Gy年MM月d日},
			M => q{L},
			MEd => q{M/dE},
			MMM => q{LL},
			MMMEd => q{M月d日E},
			MMMMd => q{M月d日},
			MMMd => q{M月d日},
			Md => q{M/d},
			d => q{d日},
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
		'generic' => {
			Bh => q{Bh时},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			E => q{ccc},
			EBhm => q{EB h:mm},
			EBhms => q{EB h:mm:ss},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d日E},
			Ehm => q{Ea h:mm},
			Ehms => q{Ea h:mm:ss},
			Gy => q{Gy年},
			GyMMM => q{Gy年M月},
			GyMMMEd => q{Gy年M月d日E},
			GyMMMd => q{Gy年M月d日},
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
			yyyyMMM => q{Gy年M月},
			yyyyMMMEd => q{Gy年MM月d日E},
			yyyyMMMM => q{Gy年M月},
			yyyyMMMd => q{Gy年M月d日},
			yyyyMd => q{G y/M/d},
			yyyyQQQ => q{Gy年第Q季度},
			yyyyQQQQ => q{Gy年第Q季度},
		},
		'gregorian' => {
			Bh => q{Bh时},
			Bhm => q{Bh:mm},
			Bhms => q{Bh:mm:ss},
			E => q{ccc},
			EBhm => q{EBh:mm},
			EBhms => q{EBh:mm:ss},
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
			MMMMW => q{MMM第W周},
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
			yQQQ => q{y年第Q季度},
			yQQQQ => q{y年第Q季度},
			yw => q{Y年第w周},
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
		'roc' => {
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
		'buddhist' => {
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
		'chinese' => {
			H => {
				H => q{HH至HH},
			},
			Hm => {
				H => q{HH:mm至HH:mm},
				m => q{HH:mm至HH:mm},
			},
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
		'hebrew' => {
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
		'indian' => {
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
				M => q{M月至M月},
			},
			MMMEd => {
				M => q{M月d日E至M月d日E},
				d => q{M月d日E至d日E},
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
					'narrow' => {
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
					'wide' => {
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
			'days' => {
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
					'narrow' => {
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
					'wide' => {
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
		regionFormat => q({0}夏令时间),
		regionFormat => q({0}标准时间),
		fallbackFormat => q({1}（{0}）),
		'Acre' => {
			long => {
				'daylight' => q#阿克里夏令时间#,
				'generic' => q#阿克里时间#,
				'standard' => q#阿克里标准时间#,
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
			exemplarCity => q#亚的斯亚贝巴#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#阿尔及尔#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#阿斯马拉#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#巴马科#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#班吉#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#班珠尔#,
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
			exemplarCity => q#布琼布拉#,
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
			exemplarCity => q#科纳克里#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#达喀尔#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#达累斯萨拉姆#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#吉布提#,
		},
		'Africa/Douala' => {
			exemplarCity => q#杜阿拉#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#阿尤恩#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#弗里敦#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#哈博罗内#,
		},
		'Africa/Harare' => {
			exemplarCity => q#哈拉雷#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#约翰内斯堡#,
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
			exemplarCity => q#金沙萨#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#拉各斯#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#利伯维尔#,
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
			exemplarCity => q#卢萨卡#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#马拉博#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#马普托#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#马塞卢#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#姆巴巴纳#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#摩加迪沙#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#蒙罗维亚#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#内罗毕#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#恩贾梅纳#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#尼亚美#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#努瓦克肖特#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#瓦加杜古#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#波多诺伏#,
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
				'standard' => q#中部非洲时间#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#东部非洲时间#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#南非标准时间#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#西部非洲夏令时间#,
				'generic' => q#西部非洲时间#,
				'standard' => q#西部非洲标准时间#,
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
			exemplarCity => q#埃达克#,
		},
		'America/Anchorage' => {
			exemplarCity => q#安克雷奇#,
		},
		'America/Anguilla' => {
			exemplarCity => q#安圭拉#,
		},
		'America/Antigua' => {
			exemplarCity => q#安提瓜#,
		},
		'America/Araguaina' => {
			exemplarCity => q#阿拉瓜伊纳#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#拉里奥哈#,
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
			exemplarCity => q#圣路易斯#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#图库曼#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#乌斯怀亚#,
		},
		'America/Aruba' => {
			exemplarCity => q#阿鲁巴#,
		},
		'America/Asuncion' => {
			exemplarCity => q#亚松森#,
		},
		'America/Bahia' => {
			exemplarCity => q#巴伊亚#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#巴伊亚班德拉斯#,
		},
		'America/Barbados' => {
			exemplarCity => q#巴巴多斯#,
		},
		'America/Belem' => {
			exemplarCity => q#贝伦#,
		},
		'America/Belize' => {
			exemplarCity => q#伯利兹#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#布兰克萨布隆#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#博阿维斯塔#,
		},
		'America/Bogota' => {
			exemplarCity => q#波哥大#,
		},
		'America/Boise' => {
			exemplarCity => q#博伊西#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#布宜诺斯艾利斯#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#剑桥湾#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#大坎普#,
		},
		'America/Cancun' => {
			exemplarCity => q#坎昆#,
		},
		'America/Caracas' => {
			exemplarCity => q#加拉加斯#,
		},
		'America/Catamarca' => {
			exemplarCity => q#卡塔马卡#,
		},
		'America/Cayenne' => {
			exemplarCity => q#卡宴#,
		},
		'America/Cayman' => {
			exemplarCity => q#开曼#,
		},
		'America/Chicago' => {
			exemplarCity => q#芝加哥#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#奇瓦瓦#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#阿蒂科肯#,
		},
		'America/Cordoba' => {
			exemplarCity => q#科尔多瓦#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#哥斯达黎加#,
		},
		'America/Creston' => {
			exemplarCity => q#克雷斯顿#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#库亚巴#,
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
			exemplarCity => q#多米尼加#,
		},
		'America/Edmonton' => {
			exemplarCity => q#埃德蒙顿#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#依伦尼贝#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#萨尔瓦多#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#纳尔逊堡#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#福塔雷萨#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#格莱斯贝#,
		},
		'America/Godthab' => {
			exemplarCity => q#努克#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#古斯湾#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#大特克#,
		},
		'America/Grenada' => {
			exemplarCity => q#格林纳达#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#瓜德罗普#,
		},
		'America/Guatemala' => {
			exemplarCity => q#危地马拉#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#瓜亚基尔#,
		},
		'America/Guyana' => {
			exemplarCity => q#圭亚那#,
		},
		'America/Halifax' => {
			exemplarCity => q#哈利法克斯#,
		},
		'America/Havana' => {
			exemplarCity => q#哈瓦那#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#埃莫西约#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#印第安纳州诺克斯#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#印第安纳州马伦戈#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#印第安纳州彼得斯堡#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#印第安纳州特尔城#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#印第安纳州维维市#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#印第安纳州温森斯#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#印第安纳州威纳马克#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#印第安纳波利斯#,
		},
		'America/Inuvik' => {
			exemplarCity => q#伊努维克#,
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
			exemplarCity => q#肯塔基州蒙蒂塞洛#,
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
			exemplarCity => q#马塞约#,
		},
		'America/Managua' => {
			exemplarCity => q#马那瓜#,
		},
		'America/Manaus' => {
			exemplarCity => q#马瑙斯#,
		},
		'America/Marigot' => {
			exemplarCity => q#马里戈特#,
		},
		'America/Martinique' => {
			exemplarCity => q#马提尼克#,
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
			exemplarCity => q#梅诺米尼#,
		},
		'America/Merida' => {
			exemplarCity => q#梅里达#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#梅特拉卡特拉#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#墨西哥城#,
		},
		'America/Miquelon' => {
			exemplarCity => q#密克隆#,
		},
		'America/Moncton' => {
			exemplarCity => q#蒙克顿#,
		},
		'America/Monterrey' => {
			exemplarCity => q#蒙特雷#,
		},
		'America/Montevideo' => {
			exemplarCity => q#蒙得维的亚#,
		},
		'America/Montserrat' => {
			exemplarCity => q#蒙特塞拉特#,
		},
		'America/Nassau' => {
			exemplarCity => q#拿骚#,
		},
		'America/New_York' => {
			exemplarCity => q#纽约#,
		},
		'America/Nipigon' => {
			exemplarCity => q#尼皮贡#,
		},
		'America/Nome' => {
			exemplarCity => q#诺姆#,
		},
		'America/Noronha' => {
			exemplarCity => q#洛罗尼亚#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#北达科他州比尤拉#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#北达科他州申特#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#北达科他州新塞勒姆#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#奥希纳加#,
		},
		'America/Panama' => {
			exemplarCity => q#巴拿马#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#旁涅唐#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#帕拉马里博#,
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
			exemplarCity => q#波多韦柳#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#波多黎各#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#蓬塔阿雷纳斯#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#雷尼河#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#兰今湾#,
		},
		'America/Recife' => {
			exemplarCity => q#累西腓#,
		},
		'America/Regina' => {
			exemplarCity => q#里贾纳#,
		},
		'America/Resolute' => {
			exemplarCity => q#雷索卢特#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#里奥布郎库#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#圣伊萨贝尔#,
		},
		'America/Santarem' => {
			exemplarCity => q#圣塔伦#,
		},
		'America/Santiago' => {
			exemplarCity => q#圣地亚哥#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#圣多明各#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#圣保罗#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#斯科列斯比桑德#,
		},
		'America/Sitka' => {
			exemplarCity => q#锡特卡#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#圣巴泰勒米岛#,
		},
		'America/St_Johns' => {
			exemplarCity => q#圣约翰斯#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#圣基茨#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#圣卢西亚#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#圣托马斯#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#圣文森特#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#斯威夫特卡伦特#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#特古西加尔巴#,
		},
		'America/Thule' => {
			exemplarCity => q#图勒#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#桑德贝#,
		},
		'America/Tijuana' => {
			exemplarCity => q#蒂华纳#,
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
			exemplarCity => q#亚库塔特#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#耶洛奈夫#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#北美中部夏令时间#,
				'generic' => q#北美中部时间#,
				'standard' => q#北美中部标准时间#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#北美东部夏令时间#,
				'generic' => q#北美东部时间#,
				'standard' => q#北美东部标准时间#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#北美山区夏令时间#,
				'generic' => q#北美山区时间#,
				'standard' => q#北美山区标准时间#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#北美太平洋夏令时间#,
				'generic' => q#北美太平洋时间#,
				'standard' => q#北美太平洋标准时间#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#阿纳德尔夏令时间#,
				'generic' => q#阿纳德尔时间#,
				'standard' => q#阿纳德尔标准时间#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#卡塞#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#戴维斯#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#迪蒙迪尔维尔#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#麦格理#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#莫森#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#麦克默多#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#帕默尔#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#罗瑟拉#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#昭和#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#特罗尔#,
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
				'daylight' => q#阿克套夏令时间#,
				'generic' => q#阿克套时间#,
				'standard' => q#阿克套标准时间#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#阿克托别夏令时间#,
				'generic' => q#阿克托别时间#,
				'standard' => q#阿克托别标准时间#,
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
			exemplarCity => q#朗伊尔城#,
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
			exemplarCity => q#阿纳德尔#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#阿克套#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#阿克托别#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#阿什哈巴德#,
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
			exemplarCity => q#文莱#,
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
			exemplarCity => q#科伦坡#,
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
			exemplarCity => q#迪拜#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#杜尚别#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#法马古斯塔#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#加沙#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#希伯伦#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#香港#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#科布多#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#伊尔库茨克#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#雅加达#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#查亚普拉#,
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
			exemplarCity => q#卡拉奇#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#加德满都#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#汉德加#,
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
			exemplarCity => q#澳门#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#马加丹#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#望加锡#,
		},
		'Asia/Manila' => {
			exemplarCity => q#马尼拉#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#马斯喀特#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#尼科西亚#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#新库兹涅茨克#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#诺沃西比尔斯克#,
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
			exemplarCity => q#卡塔尔#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#克孜洛尔达#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#仰光#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#利雅得#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#胡志明市#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#萨哈林#,
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
			exemplarCity => q#万象#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#符拉迪沃斯托克#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#雅库茨克#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#叶卡捷琳堡#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#埃里温#,
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
			exemplarCity => q#百慕大#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#加那利#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#佛得角#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#法罗#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#马德拉#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#雷克雅未克#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#南乔治亚#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#圣赫勒拿#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#斯坦利#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#阿德莱德#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#布里斯班#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#布罗肯希尔#,
		},
		'Australia/Currie' => {
			exemplarCity => q#库利#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#达尔文#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#尤克拉#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#霍巴特#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#林德曼#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#豪勋爵#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#墨尔本#,
		},
		'Australia/Perth' => {
			exemplarCity => q#珀斯#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#悉尼#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#澳大利亚中部夏令时间#,
				'generic' => q#澳大利亚中部时间#,
				'standard' => q#澳大利亚中部标准时间#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#澳大利亚中西部夏令时间#,
				'generic' => q#澳大利亚中西部时间#,
				'standard' => q#澳大利亚中西部标准时间#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#澳大利亚东部夏令时间#,
				'generic' => q#澳大利亚东部时间#,
				'standard' => q#澳大利亚东部标准时间#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#澳大利亚西部夏令时间#,
				'generic' => q#澳大利亚西部时间#,
				'standard' => q#澳大利亚西部标准时间#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#阿塞拜疆夏令时间#,
				'generic' => q#阿塞拜疆时间#,
				'standard' => q#阿塞拜疆标准时间#,
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
				'standard' => q#玻利维亚标准时间#,
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
				'standard' => q#文莱达鲁萨兰时间#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#佛得角夏令时间#,
				'generic' => q#佛得角时间#,
				'standard' => q#佛得角标准时间#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#凯西时间#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#查莫罗时间#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#查坦夏令时间#,
				'generic' => q#查坦时间#,
				'standard' => q#查坦标准时间#,
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
				'daylight' => q#库克群岛仲夏时间#,
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
				'standard' => q#迪蒙迪尔维尔时间#,
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
				'standard' => q#厄瓜多尔标准时间#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#协调世界时#,
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
			exemplarCity => q#贝尔格莱德#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#柏林#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#布拉迪斯拉发#,
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
			exemplarCity => q#基希讷乌#,
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
			exemplarCity => q#根西岛#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#赫尔辛基#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#曼岛#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#伊斯坦布尔#,
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
			exemplarCity => q#卢布尔雅那#,
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
			exemplarCity => q#马耳他#,
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
			exemplarCity => q#波德戈里察#,
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
			exemplarCity => q#萨马拉#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#圣马力诺#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#萨拉热窝#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#萨拉托夫#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#辛菲罗波尔#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#斯科普里#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#索非亚#,
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
			exemplarCity => q#乌日哥罗德#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#瓦杜兹#,
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
			exemplarCity => q#萨格勒布#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#扎波罗热#,
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
				'standard' => q#远东标准时间#,
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
				'standard' => q#法属圭亚那标准时间#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#法属南方和南极领地时间#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#格林尼治标准时间#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#加拉帕戈斯时间#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#甘比尔时间#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#格鲁吉亚夏令时间#,
				'generic' => q#格鲁吉亚时间#,
				'standard' => q#格鲁吉亚标准时间#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#吉尔伯特群岛时间#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#格陵兰岛东部夏令时间#,
				'generic' => q#格陵兰岛东部时间#,
				'standard' => q#格陵兰岛东部标准时间#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#格陵兰岛西部夏令时间#,
				'generic' => q#格陵兰岛西部时间#,
				'standard' => q#格陵兰岛西部标准时间#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#关岛时间#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#海湾标准时间#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#圭亚那时间#,
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
				'standard' => q#印度时间#,
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
			exemplarCity => q#可可斯#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#科摩罗#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#凯尔盖朗#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#马埃岛#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#马尔代夫#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#毛里求斯#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#马约特#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#留尼汪#,
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
				'standard' => q#印度尼西亚中部时间#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#印度尼西亚东部时间#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#印度尼西亚西部时间#,
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
				'daylight' => q#伊尔库茨克夏令时间#,
				'generic' => q#伊尔库茨克时间#,
				'standard' => q#伊尔库茨克标准时间#,
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
				'daylight' => q#彼得罗巴甫洛夫斯克-堪察加夏令时间#,
				'generic' => q#彼得罗巴甫洛夫斯克-堪察加时间#,
				'standard' => q#彼得罗巴甫洛夫斯克-堪察加标准时间#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#哈萨克斯坦东部时间#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#哈萨克斯坦西部时间#,
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
				'standard' => q#科斯雷时间#,
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
				'standard' => q#吉尔吉斯斯坦时间#,
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
				'standard' => q#麦夸里岛时间#,
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
				'standard' => q#马尔代夫时间#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#马克萨斯群岛时间#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#马绍尔群岛时间#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#毛里求斯夏令时间#,
				'generic' => q#毛里求斯时间#,
				'standard' => q#毛里求斯标准时间#,
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
				'standard' => q#瑙鲁时间#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#尼泊尔时间#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#新喀里多尼亚夏令时间#,
				'generic' => q#新喀里多尼亚时间#,
				'standard' => q#新喀里多尼亚标准时间#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#新西兰夏令时间#,
				'generic' => q#新西兰时间#,
				'standard' => q#新西兰标准时间#,
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
				'standard' => q#纽埃时间#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#诺福克岛时间#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#费尔南多-迪诺罗尼亚岛夏令时间#,
				'generic' => q#费尔南多-迪诺罗尼亚岛时间#,
				'standard' => q#费尔南多-迪诺罗尼亚岛标准时间#,
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
			exemplarCity => q#查塔姆#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#复活节岛#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#埃法特#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#恩德伯里#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#法考福#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#斐济#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#富纳富提#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#加拉帕戈斯#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#甘比尔#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#瓜达尔卡纳尔#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#关岛#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#檀香山#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#约翰斯顿#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#基里地马地岛#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#库赛埃#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#夸贾林#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#马朱罗#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#马克萨斯#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#中途岛#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#瑙鲁#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#纽埃#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#诺福克#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#努美阿#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#帕果帕果#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#帕劳#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#皮特凯恩#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#波纳佩岛#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#莫尔兹比港#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#拉罗汤加#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#塞班#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#塔希提#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#塔拉瓦#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#东加塔布#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#特鲁克群岛#,
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
				'standard' => q#帕劳时间#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#巴布亚新几内亚时间#,
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
				'standard' => q#菲尼克斯群岛时间#,
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
				'standard' => q#皮特凯恩时间#,
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
				'daylight' => q#克孜洛尔达夏令时间#,
				'generic' => q#克孜洛尔达时间#,
				'standard' => q#克孜洛尔达标准时间#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#留尼汪时间#,
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
				'standard' => q#塞舌尔时间#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#新加坡标准时间#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#所罗门群岛时间#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#南乔治亚岛时间#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#苏里南时间#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#昭和时间#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#塔希提岛时间#,
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
				'standard' => q#塔吉克斯坦时间#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#托克劳时间#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#汤加夏令时间#,
				'generic' => q#汤加时间#,
				'standard' => q#汤加标准时间#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#楚克时间#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#土库曼斯坦夏令时间#,
				'generic' => q#土库曼斯坦时间#,
				'standard' => q#土库曼斯坦标准时间#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#图瓦卢时间#,
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
				'daylight' => q#乌兹别克斯坦夏令时间#,
				'generic' => q#乌兹别克斯坦时间#,
				'standard' => q#乌兹别克斯坦标准时间#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#瓦努阿图夏令时间#,
				'generic' => q#瓦努阿图时间#,
				'standard' => q#瓦努阿图标准时间#,
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
				'standard' => q#瓦利斯和富图纳时间#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#雅库茨克夏令时间#,
				'generic' => q#雅库茨克时间#,
				'standard' => q#雅库茨克标准时间#,
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
