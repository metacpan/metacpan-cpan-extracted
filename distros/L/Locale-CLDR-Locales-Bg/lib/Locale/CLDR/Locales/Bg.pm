=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bg - Package for language Bulgarian

=cut

package Locale::CLDR::Locales::Bg;
# This file auto generated from Data\common\main\bg.xml
#	on Thu 29 Feb  5:43:51 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.1');

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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-neuter','spellout-cardinal-masculine-personal','spellout-cardinal-masculine-personal-financial','spellout-cardinal-masculine-financial','spellout-cardinal-feminine-financial','spellout-cardinal-neuter-financial','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-neuter','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal-neuter','digits-ordinal' ]},
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
					rule => q(=#,##0=-=%%digits-ordinal-feminine-suffix=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=-=%%digits-ordinal-feminine-suffix=),
				},
			},
		},
		'digits-ordinal-feminine-larger-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тна),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(→%%digits-ordinal-feminine-suffix→),
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
		'digits-ordinal-feminine-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(а),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ва),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ра),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(та),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(а),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%digits-ordinal-feminine-larger-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(→→),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
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
					rule => q(=#,##0=-=%%digits-ordinal-masculine-suffix=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=-=%%digits-ordinal-masculine-suffix=),
				},
			},
		},
		'digits-ordinal-masculine-larger-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тен),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(→%%digits-ordinal-masculine-suffix→),
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
		'digits-ordinal-masculine-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(и),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ви),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ри),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ти),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(и),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%digits-ordinal-masculine-larger-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(→→),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(→→),
				},
			},
		},
		'digits-ordinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=-=%%digits-ordinal-neuter-suffix=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=-=%%digits-ordinal-neuter-suffix=),
				},
			},
		},
		'digits-ordinal-neuter-larger-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тно),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(→%%digits-ordinal-neuter-suffix→),
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
		'digits-ordinal-neuter-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(o),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(вo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(рo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(тo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(→→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(→%%digits-ordinal-neuter-larger-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(→→),
				},
				'max' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(→→),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(една),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(две),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←йсет[ и →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет[ и →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет[ и →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-feminine-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-feminine-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-feminine-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-feminine-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-feminine-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляди[ →%%spellout-cardinal-feminine-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-feminine-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-feminine-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-feminine-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-feminine-and→]),
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
		'spellout-cardinal-feminine-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-feminine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine=),
				},
			},
		},
		'spellout-cardinal-feminine-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(една),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(две),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двадесет[ и →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine-financial← хиляди[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-feminine-financial-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-feminine-financial-and→]),
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
		'spellout-cardinal-feminine-financial-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-feminine-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine-financial=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-feminine-financial=),
				},
			},
		},
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(един),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(два),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(три),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четири),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пет),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шест),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(седем),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(осем),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(девет),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(десет),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(единайсет),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванайсет),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→найсет),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←←йсет[ и →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет[ и →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←←десет[ и →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет[ и →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-masculine-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-masculine-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-masculine-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-masculine-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-masculine-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляди[ →%%spellout-cardinal-masculine-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-masculine-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-masculine-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-masculine-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-masculine-and→]),
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
		'spellout-cardinal-masculine-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-masculine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine=),
				},
			},
		},
		'spellout-cardinal-masculine-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(един),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(два),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(три),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четири),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пет),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шест),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(седем),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(осем),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(девет),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(десет),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(единадесет),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(дванадесет),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→надесет),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двадесет[ и →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine-financial← хиляди[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-masculine-financial-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-masculine-financial-and→]),
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
		'spellout-cardinal-masculine-financial-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-masculine-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-financial=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-financial=),
				},
			},
		},
		'spellout-cardinal-masculine-personal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(един),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(двама),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трима),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четирима),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(петима),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шестима),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←йсет[ и →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет[ и →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет[ и →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←стотин[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляди[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-masculine-personal-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-masculine-personal-and→]),
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
		'spellout-cardinal-masculine-personal-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-masculine-personal=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-personal=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-personal=),
				},
			},
		},
		'spellout-cardinal-masculine-personal-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(един),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(двама),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трима),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четирима),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(петима),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шестима),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine-financial←стотин[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine-financial← хиляди[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-masculine-personal-financial-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-masculine-personal-financial-and→]),
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
		'spellout-cardinal-masculine-personal-financial-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-masculine-personal-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-personal-financial=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-masculine-personal-financial=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(едно),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(две),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←йсет[ и →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет[ и →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет[ и →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-neuter-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-neuter-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-neuter-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-neuter-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-neuter-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляди[ →%%spellout-cardinal-neuter-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-neuter-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-neuter-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-neuter-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-neuter-and→]),
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
		'spellout-cardinal-neuter-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-neuter=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=),
				},
			},
		},
		'spellout-cardinal-neuter-financial' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← цяло и →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(едно),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(две),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine-financial=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двадесет[ и →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(←←десет[ и →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←стотин[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляда[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine-financial← хиляди[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милион}other{милиона})$[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{милиард}other{милиарда})$[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{трилион}other{трилиона})$[ →%%spellout-cardinal-neuter-financial-and→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine-financial← $(cardinal,one{квадрилион}other{квадрилиона})$[ →%%spellout-cardinal-neuter-financial-and→]),
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
		'spellout-cardinal-neuter-financial-and' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q('и =%spellout-cardinal-neuter-financial=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter-financial=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter-financial=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=),
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
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(първа),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(втора),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трета),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четвърта),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пета),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шеста),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(седма),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(осма),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(девета),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(десета),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(единайсета),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→%spellout-cardinal-masculine→найсета),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двайсет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трийсет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(петдесет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет→%%spellout-ordinal-feminine-and-suffix→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто→%%spellout-ordinal-feminine-hundreds-and-suffix→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста→%%spellout-ordinal-feminine-hundreds-and-suffix→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста→%%spellout-ordinal-feminine-hundreds-and-suffix→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←стотин→%%spellout-ordinal-feminine-hundreds-and-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляд→%%spellout-ordinal-feminine-thousand-and-suffix→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляд→%%spellout-ordinal-feminine-thousands-and-suffix→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-feminine-million-and-suffix→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-feminine-thousand-and-suffix→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-feminine-million-and-suffix→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-feminine-thousand-and-suffix→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-feminine-million-and-suffix→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-feminine-thousand-and-suffix→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-feminine-million-and-suffix→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-feminine-thousand-and-suffix→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-а),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-а),
				},
			},
		},
		'spellout-ordinal-feminine-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(а),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-feminine-hundreds-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тна),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-feminine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-feminine-million-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(на),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-feminine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-feminine-thousand-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(на),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('а и =%spellout-ordinal-feminine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-feminine-thousands-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(на),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('и и =%spellout-ordinal-feminine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-feminine=),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(първи),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(втори),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трети),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четвърти),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пети),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шести),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(седми),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(осми),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(девети),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(десети),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(единайсети),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→%spellout-cardinal-masculine→найсети),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двайсет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трийсет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(петдесет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет→%%spellout-ordinal-masculine-and-suffix→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто→%%spellout-ordinal-masculine-hundreds-and-suffix→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста→%%spellout-ordinal-masculine-hundreds-and-suffix→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста→%%spellout-ordinal-masculine-hundreds-and-suffix→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←стотин→%%spellout-ordinal-masculine-hundreds-and-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляд→%%spellout-ordinal-masculine-thousand-and-suffix→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляд→%%spellout-ordinal-masculine-thousands-and-suffix→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-masculine-million-and-suffix→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-masculine-thousand-and-suffix→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-masculine-million-and-suffix→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-masculine-thousand-and-suffix→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-masculine-million-and-suffix→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-masculine-thousand-and-suffix→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-masculine-million-and-suffix→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-masculine-thousand-and-suffix→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-и),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-и),
				},
			},
		},
		'spellout-ordinal-masculine-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(и),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-masculine-hundreds-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тен),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-masculine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-masculine-million-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ен),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-masculine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-masculine-thousand-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ен),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('а и =%spellout-ordinal-masculine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-masculine-thousands-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ен),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('и и =%spellout-ordinal-masculine=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-ordinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(минус →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(нула),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(първо),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(второ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(трето),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(четвърто),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(пето),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(шесто),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(седмо),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(осмо),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(девето),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(десето),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(единайсето),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→%spellout-cardinal-masculine→найсето),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(двайсет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(трийсет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(четиресет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(петдесет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(шейсет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(←%spellout-cardinal-masculine←десет→%%spellout-ordinal-neuter-and-suffix→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(сто→%%spellout-ordinal-neuter-hundreds-and-suffix→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(двеста→%%spellout-ordinal-neuter-hundreds-and-suffix→),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(триста→%%spellout-ordinal-neuter-hundreds-and-suffix→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←стотин→%%spellout-ordinal-neuter-hundreds-and-suffix→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(хиляд→%%spellout-ordinal-neuter-thousand-and-suffix→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← хиляд→%%spellout-ordinal-neuter-thousands-and-suffix→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-neuter-million-and-suffix→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← милион→%%spellout-ordinal-neuter-thousand-and-suffix→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-neuter-million-and-suffix→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← милиард→%%spellout-ordinal-neuter-thousand-and-suffix→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-neuter-million-and-suffix→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← трилион→%%spellout-ordinal-neuter-thousand-and-suffix→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-neuter-million-and-suffix→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← квадрилион→%%spellout-ordinal-neuter-thousand-and-suffix→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-о),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=-о),
				},
			},
		},
		'spellout-ordinal-neuter-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(о),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-neuter=),
				},
			},
		},
		'spellout-ordinal-neuter-hundreds-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(тно),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-neuter=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'spellout-ordinal-neuter-million-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(но),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' и =%spellout-ordinal-neuter=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'spellout-ordinal-neuter-thousand-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(но),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('а и =%spellout-ordinal-neuter=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('а =%spellout-ordinal-neuter=),
				},
			},
		},
		'spellout-ordinal-neuter-thousands-and-suffix' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(но),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q('и и =%spellout-ordinal-neuter=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q('и =%spellout-ordinal-neuter=),
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
				'aa' => 'афарски',
 				'ab' => 'абхазки',
 				'ace' => 'ачешки',
 				'ach' => 'аколи',
 				'ada' => 'адангме',
 				'ady' => 'адигейски',
 				'ae' => 'авестски',
 				'af' => 'африканс',
 				'afh' => 'африхили',
 				'agq' => 'агем',
 				'ain' => 'айну',
 				'ak' => 'акан',
 				'akk' => 'акадски',
 				'ale' => 'алеутски',
 				'alt' => 'южноалтайски',
 				'am' => 'амхарски',
 				'an' => 'арагонски',
 				'ang' => 'староанглийски',
 				'ann' => 'оболо',
 				'anp' => 'ангика',
 				'ar' => 'арабски',
 				'ar_001' => 'съвременен стандартен арабски',
 				'arc' => 'арамейски',
 				'arn' => 'мапуче',
 				'arp' => 'арапахо',
 				'ars' => 'найди арабски',
 				'arw' => 'аравак',
 				'as' => 'асамски',
 				'asa' => 'асу',
 				'ast' => 'астурски',
 				'atj' => 'атикамеку',
 				'av' => 'аварски',
 				'awa' => 'авади',
 				'ay' => 'аймара',
 				'az' => 'азербайджански',
 				'az@alt=short' => 'азерски',
 				'ba' => 'башкирски',
 				'bal' => 'балучи',
 				'ban' => 'балийски',
 				'bas' => 'баса',
 				'be' => 'беларуски',
 				'bej' => 'бея',
 				'bem' => 'бемба',
 				'bez' => 'бена',
 				'bg' => 'български',
 				'bgc' => 'харианви',
 				'bgn' => 'западен балочи',
 				'bho' => 'боджпури',
 				'bi' => 'бислама',
 				'bik' => 'биколски',
 				'bin' => 'бини',
 				'bla' => 'сиксика',
 				'bm' => 'бамбара',
 				'bn' => 'бенгалски',
 				'bo' => 'тибетски',
 				'br' => 'бретонски',
 				'bra' => 'брадж',
 				'brx' => 'бодо',
 				'bs' => 'босненски',
 				'bua' => 'бурятски',
 				'bug' => 'бугински',
 				'byn' => 'биленски',
 				'ca' => 'каталонски',
 				'cad' => 'каддо',
 				'car' => 'карибски',
 				'cay' => 'каюга',
 				'cch' => 'атсам',
 				'ccp' => 'чакма',
 				'ce' => 'чеченски',
 				'ceb' => 'себуански',
 				'cgg' => 'чига',
 				'ch' => 'чаморо',
 				'chb' => 'чибча',
 				'chg' => 'чагатай',
 				'chk' => 'чуук',
 				'chm' => 'марийски',
 				'chn' => 'жаргон чинуук',
 				'cho' => 'чокто',
 				'chp' => 'чипеуански',
 				'chr' => 'черокски',
 				'chy' => 'шайенски',
 				'ckb' => 'кюрдски (централен)',
 				'ckb@alt=variant' => 'кюрдски (Сорани)',
 				'clc' => 'чилкотин',
 				'co' => 'корсикански',
 				'cop' => 'коптски',
 				'cr' => 'крии',
 				'crg' => 'мичиф',
 				'crh' => 'кримскотатарски',
 				'crj' => 'югоизточен крий',
 				'crk' => 'плейнс крий',
 				'crl' => 'североизточен крий',
 				'crm' => 'муус крее',
 				'crr' => 'каролински алгонкин',
 				'crs' => 'сеселва, креолски френски',
 				'cs' => 'чешки',
 				'csb' => 'кашубски',
 				'csw' => 'суампи крий',
 				'cu' => 'църковнославянски',
 				'cv' => 'чувашки',
 				'cy' => 'уелски',
 				'da' => 'датски',
 				'dak' => 'дакотски',
 				'dar' => 'даргински',
 				'dav' => 'таита',
 				'de' => 'немски',
 				'del' => 'делауер',
 				'den' => 'слейви',
 				'dgr' => 'догриб',
 				'din' => 'динка',
 				'dje' => 'зарма',
 				'doi' => 'догри',
 				'dsb' => 'долнолужишки',
 				'dua' => 'дуала',
 				'dum' => 'средновековен холандски',
 				'dv' => 'дивехи',
 				'dyo' => 'диола-фони',
 				'dyu' => 'диула',
 				'dz' => 'дзонгкха',
 				'dzg' => 'дазага',
 				'ebu' => 'ембу',
 				'ee' => 'еве',
 				'efi' => 'ефик',
 				'egy' => 'древноегипетски',
 				'eka' => 'екажук',
 				'el' => 'гръцки',
 				'elx' => 'еламитски',
 				'en' => 'английски',
 				'en_AU' => 'австралийски английски',
 				'en_CA' => 'канадски английски',
 				'en_GB' => 'британски английски',
 				'en_GB@alt=short' => 'английски (UK)',
 				'en_US' => 'американски английски',
 				'en_US@alt=short' => 'английски (US)',
 				'enm' => 'средновековен английски',
 				'eo' => 'есперанто',
 				'es' => 'испански',
 				'et' => 'естонски',
 				'eu' => 'баски',
 				'ewo' => 'евондо',
 				'fa' => 'персийски',
 				'fa_AF' => 'дари',
 				'fan' => 'фанг',
 				'fat' => 'фанти',
 				'ff' => 'фула',
 				'fi' => 'фински',
 				'fil' => 'филипински',
 				'fj' => 'фиджийски',
 				'fo' => 'фарьорски',
 				'fon' => 'фон',
 				'fr' => 'френски',
 				'frc' => 'каджунски френски',
 				'frm' => 'средновековен френски',
 				'fro' => 'старофренски',
 				'frr' => 'северен фризийски',
 				'frs' => 'източнофризийски',
 				'fur' => 'фриулски',
 				'fy' => 'западнофризийски',
 				'ga' => 'ирландски',
 				'gaa' => 'га',
 				'gag' => 'гагаузки',
 				'gay' => 'гайо',
 				'gba' => 'гбая',
 				'gd' => 'шотландски келтски',
 				'gez' => 'гииз',
 				'gil' => 'гилбертски',
 				'gl' => 'галисийски',
 				'gmh' => 'средновисоконемски',
 				'gn' => 'гуарани',
 				'goh' => 'старовисоконемски',
 				'gon' => 'гонди',
 				'gor' => 'горонтало',
 				'got' => 'готически',
 				'grb' => 'гребо',
 				'grc' => 'древногръцки',
 				'gsw' => 'швейцарски немски',
 				'gu' => 'гуджарати',
 				'guz' => 'гусии',
 				'gv' => 'манкски',
 				'gwi' => 'гвичин',
 				'ha' => 'хауса',
 				'hai' => 'хайда',
 				'haw' => 'хавайски',
 				'hax' => 'южен хайда',
 				'he' => 'иврит',
 				'hi' => 'хинди',
 				'hi_Latn@alt=variant' => 'хинглиш',
 				'hil' => 'хилигайнон',
 				'hit' => 'хитски',
 				'hmn' => 'хмонг',
 				'ho' => 'хири моту',
 				'hr' => 'хърватски',
 				'hsb' => 'горнолужишки',
 				'ht' => 'хаитянски креолски',
 				'hu' => 'унгарски',
 				'hup' => 'хупа',
 				'hur' => 'халкомелем',
 				'hy' => 'арменски',
 				'hz' => 'хереро',
 				'ia' => 'интерлингва',
 				'iba' => 'ибан',
 				'ibb' => 'ибибио',
 				'id' => 'индонезийски',
 				'ie' => 'оксидентал',
 				'ig' => 'игбо',
 				'ii' => 'съчуански йи',
 				'ik' => 'инупиак',
 				'ikt' => 'западноканадски инуктитут',
 				'ilo' => 'илоко',
 				'inh' => 'ингушетски',
 				'io' => 'идо',
 				'is' => 'исландски',
 				'it' => 'италиански',
 				'iu' => 'инуктитут',
 				'ja' => 'японски',
 				'jbo' => 'ложбан',
 				'jgo' => 'нгомба',
 				'jmc' => 'мачаме',
 				'jpr' => 'юдео-персийски',
 				'jrb' => 'юдео-арабски',
 				'jv' => 'явански',
 				'ka' => 'грузински',
 				'kaa' => 'каракалпашки',
 				'kab' => 'кабилски',
 				'kac' => 'качински',
 				'kaj' => 'жжу',
 				'kam' => 'камба',
 				'kaw' => 'кави',
 				'kbd' => 'кабардски',
 				'kcg' => 'туап',
 				'kde' => 'маконде',
 				'kea' => 'кабовердиански',
 				'kfo' => 'коро',
 				'kg' => 'конгоански',
 				'kgp' => 'кайнганг',
 				'kha' => 'кхаси',
 				'kho' => 'котски',
 				'khq' => 'койра чиини',
 				'ki' => 'кикую',
 				'kj' => 'кваняма',
 				'kk' => 'казахски',
 				'kkj' => 'како',
 				'kl' => 'гренландски',
 				'kln' => 'календжин',
 				'km' => 'кхмерски',
 				'kmb' => 'кимбунду',
 				'kn' => 'каннада',
 				'ko' => 'корейски',
 				'koi' => 'коми-пермякски',
 				'kok' => 'конкани',
 				'kos' => 'косраен',
 				'kpe' => 'кпеле',
 				'kr' => 'канури',
 				'krc' => 'карачай-балкарски',
 				'krl' => 'карелски',
 				'kru' => 'курук',
 				'ks' => 'кашмирски',
 				'ksb' => 'шамбала',
 				'ksf' => 'бафия',
 				'ksh' => 'кьолнски',
 				'ku' => 'кюрдски',
 				'kum' => 'кумикски',
 				'kut' => 'кутенай',
 				'kv' => 'коми',
 				'kw' => 'корнуолски',
 				'kwk' => 'куак’уала',
 				'ky' => 'киргизки',
 				'la' => 'латински',
 				'lad' => 'ладино',
 				'lag' => 'ланги',
 				'lah' => 'лахнда',
 				'lam' => 'ламба',
 				'lb' => 'люксембургски',
 				'lez' => 'лезгински',
 				'lg' => 'ганда',
 				'li' => 'лимбургски',
 				'lil' => 'лилоует',
 				'lkt' => 'лакота',
 				'lmo' => 'ломбардски',
 				'ln' => 'лингала',
 				'lo' => 'лаоски',
 				'lol' => 'монго',
 				'lou' => 'луизиански креолски',
 				'loz' => 'лози',
 				'lrc' => 'северен лури',
 				'lsm' => 'саамски',
 				'lt' => 'литовски',
 				'lu' => 'луба-катанга',
 				'lua' => 'луба-лулуа',
 				'lui' => 'луисеньо',
 				'lun' => 'лунда',
 				'luo' => 'луо',
 				'lus' => 'мизо',
 				'luy' => 'лухя',
 				'lv' => 'латвийски',
 				'mad' => 'мадурски',
 				'mag' => 'магахи',
 				'mai' => 'майтхили',
 				'mak' => 'макасар',
 				'man' => 'мандинго',
 				'mas' => 'масайски',
 				'mdf' => 'мокша',
 				'mdr' => 'мандар',
 				'men' => 'менде',
 				'mer' => 'меру',
 				'mfe' => 'морисиен',
 				'mg' => 'малгашки',
 				'mga' => 'средновековен ирландски',
 				'mgh' => 'макуа мето',
 				'mgo' => 'мета',
 				'mh' => 'маршалезе',
 				'mi' => 'маорски',
 				'mic' => 'микмак',
 				'min' => 'минангкабау',
 				'mk' => 'македонски',
 				'ml' => 'малаялам',
 				'mn' => 'монголски',
 				'mnc' => 'манджурски',
 				'mni' => 'манипурски',
 				'moe' => 'инну-аймун',
 				'moh' => 'мохоук',
 				'mos' => 'моси',
 				'mr' => 'марати',
 				'ms' => 'малайски',
 				'mt' => 'малтийски',
 				'mua' => 'мунданг',
 				'mul' => 'многоезични',
 				'mus' => 'мускогски',
 				'mwl' => 'мирандийски',
 				'mwr' => 'марвари',
 				'my' => 'бирмански',
 				'myv' => 'ерзиа',
 				'mzn' => 'мазандерански',
 				'na' => 'науру',
 				'nap' => 'неаполитански',
 				'naq' => 'нама',
 				'nb' => 'норвежки (букмол)',
 				'nd' => 'северен ндебеле',
 				'nds' => 'долнонемски',
 				'nds_NL' => 'долносаксонски',
 				'ne' => 'непалски',
 				'new' => 'неварски',
 				'ng' => 'ндонга',
 				'nia' => 'ниас',
 				'niu' => 'ниуеан',
 				'nl' => 'нидерландски',
 				'nl_BE' => 'фламандски',
 				'nmg' => 'квасио',
 				'nn' => 'норвежки (нюношк)',
 				'nnh' => 'нгиембун',
 				'no' => 'норвежки',
 				'nog' => 'ногаи',
 				'non' => 'старонорвежки',
 				'nqo' => 'нко',
 				'nr' => 'южен ндебеле',
 				'nso' => 'северен сото',
 				'nus' => 'нуер',
 				'nv' => 'навахо',
 				'nwc' => 'класически невари',
 				'ny' => 'нянджа',
 				'nym' => 'ниамвези',
 				'nyn' => 'нянколе',
 				'nyo' => 'нуоро',
 				'nzi' => 'нзима',
 				'oc' => 'окситански',
 				'oj' => 'оджибва',
 				'ojb' => 'северозападен оджибве',
 				'ojc' => 'централен оджибва',
 				'ojs' => 'оджи крий',
 				'ojw' => 'западен оджибва',
 				'oka' => 'оканаган',
 				'om' => 'оромо',
 				'or' => 'ория',
 				'os' => 'осетински',
 				'osa' => 'осейджи',
 				'ota' => 'отомански турски',
 				'pa' => 'пенджабски',
 				'pag' => 'пангасинан',
 				'pal' => 'пахлави',
 				'pam' => 'пампанга',
 				'pap' => 'папиаменто',
 				'pau' => 'палауан',
 				'pcm' => 'нигерийски пиджин',
 				'peo' => 'староперсийски',
 				'phn' => 'финикийски',
 				'pi' => 'пали',
 				'pis' => 'пиджин',
 				'pl' => 'полски',
 				'pon' => 'понапеан',
 				'pqm' => 'малисеет-пасамакуоди',
 				'prg' => 'пруски',
 				'pro' => 'старопровансалски',
 				'ps' => 'пущу',
 				'ps@alt=variant' => 'пущунски',
 				'pt' => 'португалски',
 				'qu' => 'кечуа',
 				'quc' => 'киче',
 				'raj' => 'раджастански',
 				'rap' => 'рапа нуи',
 				'rar' => 'раротонга',
 				'rhg' => 'рохинга',
 				'rm' => 'реторомански',
 				'rn' => 'рунди',
 				'ro' => 'румънски',
 				'ro_MD' => 'молдовски',
 				'rof' => 'ромбо',
 				'rom' => 'ромски',
 				'ru' => 'руски',
 				'rup' => 'арумънски',
 				'rw' => 'киняруанда',
 				'rwk' => 'рва',
 				'sa' => 'санскрит',
 				'sad' => 'сандаве',
 				'sah' => 'саха',
 				'sam' => 'самаритански арамейски',
 				'saq' => 'самбуру',
 				'sas' => 'сасак',
 				'sat' => 'сантали',
 				'sba' => 'нгамбай',
 				'sbp' => 'сангу',
 				'sc' => 'сардински',
 				'scn' => 'сицилиански',
 				'sco' => 'шотландски',
 				'sd' => 'синдхи',
 				'sdh' => 'южнокюрдски',
 				'se' => 'северносаамски',
 				'seh' => 'сена',
 				'sel' => 'селкуп',
 				'ses' => 'койраборо сени',
 				'sg' => 'санго',
 				'sga' => 'староирландски',
 				'sh' => 'сърбохърватски',
 				'shi' => 'ташелхит',
 				'shn' => 'шан',
 				'si' => 'синхалски',
 				'sid' => 'сидамо',
 				'sk' => 'словашки',
 				'sl' => 'словенски',
 				'slh' => 'южен лашутсийд',
 				'sm' => 'самоански',
 				'sma' => 'южносаамски',
 				'smj' => 'луле-саамски',
 				'smn' => 'инари-саамски',
 				'sms' => 'сколт-саамски',
 				'sn' => 'шона',
 				'snk' => 'сонинке',
 				'so' => 'сомалийски',
 				'sog' => 'согдийски',
 				'sq' => 'албански',
 				'sr' => 'сръбски',
 				'srn' => 'сранан тонго',
 				'srr' => 'серер',
 				'ss' => 'свати',
 				'ssy' => 'сахо',
 				'st' => 'сото',
 				'str' => 'стрейтс салиш',
 				'su' => 'сундански',
 				'suk' => 'сукума',
 				'sus' => 'сусу',
 				'sux' => 'шумерски',
 				'sv' => 'шведски',
 				'sw' => 'суахили',
 				'sw_CD' => 'конгоански суахили',
 				'swb' => 'коморски',
 				'syc' => 'класически сирийски',
 				'syr' => 'сирийски',
 				'ta' => 'тамилски',
 				'tce' => 'южен тучоне',
 				'te' => 'телугу',
 				'tem' => 'темне',
 				'teo' => 'тесо',
 				'ter' => 'терено',
 				'tet' => 'тетум',
 				'tg' => 'таджикски',
 				'tgx' => 'тагиш',
 				'th' => 'тайски',
 				'tht' => 'талтан',
 				'ti' => 'тигриня',
 				'tig' => 'тигре',
 				'tiv' => 'тив',
 				'tk' => 'туркменски',
 				'tkl' => 'токелайски',
 				'tl' => 'тагалог',
 				'tlh' => 'клингонски',
 				'tli' => 'тлингит',
 				'tmh' => 'тамашек',
 				'tn' => 'тсвана',
 				'to' => 'тонгански',
 				'tog' => 'нианса тонга',
 				'tok' => 'токи пона',
 				'tpi' => 'ток писин',
 				'tr' => 'турски',
 				'trv' => 'тароко',
 				'ts' => 'цонга',
 				'tsi' => 'цимшиански',
 				'tt' => 'татарски',
 				'ttm' => 'северен тучоне',
 				'tum' => 'тумбука',
 				'tvl' => 'тувалуански',
 				'tw' => 'туи',
 				'twq' => 'тасавак',
 				'ty' => 'таитянски',
 				'tyv' => 'тувински',
 				'tzm' => 'централноатласки тамазигт',
 				'udm' => 'удмуртски',
 				'ug' => 'уйгурски',
 				'uga' => 'угаритски',
 				'uk' => 'украински',
 				'umb' => 'умбунду',
 				'und' => 'непознат език',
 				'ur' => 'урду',
 				'uz' => 'узбекски',
 				'vai' => 'ваи',
 				've' => 'венда',
 				'vi' => 'виетнамски',
 				'vo' => 'волапюк',
 				'vot' => 'вотик',
 				'vun' => 'вунджо',
 				'wa' => 'валонски',
 				'wae' => 'валзерски немски',
 				'wal' => 'валамо',
 				'war' => 'варай',
 				'was' => 'уашо',
 				'wbp' => 'валпири',
 				'wo' => 'волоф',
 				'wuu' => 'ву китайски',
 				'xal' => 'калмик',
 				'xh' => 'кхоса',
 				'xog' => 'сога',
 				'yao' => 'яо',
 				'yap' => 'япезе',
 				'yav' => 'янгбен',
 				'ybb' => 'йемба',
 				'yi' => 'идиш',
 				'yo' => 'йоруба',
 				'yrl' => 'ненгату',
 				'yue' => 'кантонски',
 				'yue@alt=menu' => 'китайски, кантонски',
 				'za' => 'зуанг',
 				'zap' => 'запотек',
 				'zbl' => 'блис символи',
 				'zen' => 'зенага',
 				'zgh' => 'стандартен марокански тамазигт',
 				'zh' => 'китайски',
 				'zh@alt=menu' => 'китайски, мандарин',
 				'zh_Hans' => 'китайски (опростен)',
 				'zh_Hans@alt=long' => 'китайски, мандарин (опростен)',
 				'zh_Hant' => 'китайски (традиционен)',
 				'zh_Hant@alt=long' => 'китайски, мандарин (традиционен)',
 				'zu' => 'зулуски',
 				'zun' => 'зуни',
 				'zxx' => 'без лингвистично съдържание',
 				'zza' => 'заза',

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
			'Adlm' => 'адлам',
 			'Arab' => 'арабска',
 			'Arab@alt=variant' => 'персийско-арабска',
 			'Aran' => 'aранска',
 			'Armi' => 'Арамейска',
 			'Armn' => 'арменска',
 			'Avst' => 'Авестанска',
 			'Bali' => 'Балийски',
 			'Batk' => 'Батакска',
 			'Beng' => 'бенгалска',
 			'Blis' => 'Блис символи',
 			'Bopo' => 'бопомофо',
 			'Brah' => 'Брахми',
 			'Brai' => 'брайлова',
 			'Bugi' => 'Бугинска',
 			'Buhd' => 'Бухид',
 			'Cakm' => 'чакма',
 			'Cans' => 'унифицирани символи на канадски аборигени',
 			'Cari' => 'Карийска',
 			'Cham' => 'Хамитска',
 			'Cher' => 'чероки',
 			'Cirt' => 'Кирт',
 			'Copt' => 'Коптска',
 			'Cprt' => 'Кипърска',
 			'Cyrl' => 'кирилица',
 			'Cyrs' => 'Стар църковно-славянски вариант Кирилица',
 			'Deva' => 'деванагари',
 			'Dsrt' => 'Дезерет',
 			'Egyd' => 'Египетско демотично писмо',
 			'Egyh' => 'Египетско йератично писмо',
 			'Egyp' => 'Египетски йероглифи',
 			'Ethi' => 'етиопска',
 			'Geok' => 'Грузинска хуцури',
 			'Geor' => 'грузинска',
 			'Glag' => 'Глаголическа',
 			'Goth' => 'Готическа',
 			'Grek' => 'гръцка',
 			'Gujr' => 'гуджарати',
 			'Guru' => 'гурмукхи',
 			'Hanb' => 'ханб',
 			'Hang' => 'хангъл',
 			'Hani' => 'хан',
 			'Hano' => 'Хануну',
 			'Hans' => 'опростена',
 			'Hans@alt=stand-alone' => 'опростен хан',
 			'Hant' => 'традиционна',
 			'Hant@alt=stand-alone' => 'традиционен хан',
 			'Hebr' => 'иврит',
 			'Hira' => 'хирагана',
 			'Hmng' => 'Пахау хмонг',
 			'Hrkt' => 'японска сричкова',
 			'Hung' => 'Староунгарска',
 			'Inds' => 'Харапска',
 			'Ital' => 'Древно италийска',
 			'Jamo' => 'джамо',
 			'Java' => 'Яванска',
 			'Jpan' => 'японска',
 			'Kali' => 'Кая Ли',
 			'Kana' => 'катакана',
 			'Khar' => 'Кхароштхи',
 			'Khmr' => 'кхмерска',
 			'Knda' => 'каннада',
 			'Kore' => 'корейска',
 			'Kthi' => 'Кайтхи',
 			'Lana' => 'Ланна',
 			'Laoo' => 'лаоска',
 			'Latf' => 'Латинска фрактура',
 			'Latg' => 'Галска латинска',
 			'Latn' => 'латиница',
 			'Lepc' => 'Лепча',
 			'Limb' => 'Лимбу',
 			'Lina' => 'Линейна А',
 			'Linb' => 'Линейна Б',
 			'Lyci' => 'Лицийска',
 			'Lydi' => 'Лидийска',
 			'Mand' => 'Мандаринска',
 			'Mani' => 'Манихейска',
 			'Maya' => 'Йероглифи на Маите',
 			'Mero' => 'Мероитска',
 			'Mlym' => 'малаялам',
 			'Mong' => 'монголска',
 			'Moon' => 'Мун',
 			'Mtei' => 'манипури',
 			'Mymr' => 'бирманска',
 			'Nkoo' => 'Н’Ко',
 			'Ogam' => 'Огамическа',
 			'Olck' => 'Ол Чики',
 			'Orkh' => 'Орхоно-енисейска',
 			'Orya' => 'ория',
 			'Osma' => 'Османска',
 			'Perm' => 'Древно пермска',
 			'Phag' => 'Фагс-па',
 			'Phlv' => 'Пахлавска',
 			'Phnx' => 'Финикийска',
 			'Plrd' => 'Писменост Полард',
 			'Rohg' => 'харифи',
 			'Roro' => 'Ронго-ронго',
 			'Runr' => 'Руническа',
 			'Samr' => 'Самаританска',
 			'Sara' => 'Сарати',
 			'Saur' => 'Саураштра',
 			'Sinh' => 'синхалска',
 			'Sund' => 'сунданска',
 			'Sylo' => 'Силоти Нагри',
 			'Syrc' => 'сирийска',
 			'Syre' => 'Сирийска естрангело',
 			'Syrj' => 'Западна сирийска',
 			'Syrn' => 'Източна сирийска',
 			'Tagb' => 'Тагбанва',
 			'Tale' => 'Тай Ле',
 			'Talu' => 'Нова Тай Ле',
 			'Taml' => 'тамилска',
 			'Telu' => 'телугу',
 			'Tfng' => 'тифинаг',
 			'Tglg' => 'Тагалог',
 			'Thaa' => 'таана',
 			'Thai' => 'тайска',
 			'Tibt' => 'тибетска',
 			'Ugar' => 'Угаритска',
 			'Vaii' => 'вайска',
 			'Visp' => 'Видима реч',
 			'Xpeo' => 'Староперсийска',
 			'Xsux' => 'Шумеро-акадски клинопис',
 			'Yiii' => 'Йи',
 			'Zmth' => 'математически символи',
 			'Zsye' => 'емоджи',
 			'Zsym' => 'символи',
 			'Zxxx' => 'без писменост',
 			'Zyyy' => 'обща',
 			'Zzzz' => 'непозната писменост',

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
			'001' => 'свят',
 			'002' => 'Африка',
 			'003' => 'Северноамерикански континент',
 			'005' => 'Южна Америка',
 			'009' => 'Океания',
 			'011' => 'Западна Афирка',
 			'013' => 'Централна Америка',
 			'014' => 'Източна Африка',
 			'015' => 'Северна Африка',
 			'017' => 'Централна Африка',
 			'018' => 'Южноафрикански регион',
 			'019' => 'Америка',
 			'021' => 'Северна Америка',
 			'029' => 'Карибски регион',
 			'030' => 'Източна Азия',
 			'034' => 'Южна Азия',
 			'035' => 'Югоизточна Азия',
 			'039' => 'Южна Европа',
 			'053' => 'Австралазия',
 			'054' => 'Меланезия',
 			'057' => 'Микронезийски регион',
 			'061' => 'Полинезия',
 			'142' => 'Азия',
 			'143' => 'Централна Азия',
 			'145' => 'Западна Азия',
 			'150' => 'Европа',
 			'151' => 'Източна Европа',
 			'154' => 'Северна Европа',
 			'155' => 'Западна Европа',
 			'202' => 'Субсахарска Африка',
 			'419' => 'Латинска Америка',
 			'AC' => 'остров Възнесение',
 			'AD' => 'Андора',
 			'AE' => 'Обединени арабски емирства',
 			'AF' => 'Афганистан',
 			'AG' => 'Антигуа и Барбуда',
 			'AI' => 'Ангуила',
 			'AL' => 'Албания',
 			'AM' => 'Армения',
 			'AO' => 'Ангола',
 			'AQ' => 'Антарктика',
 			'AR' => 'Аржентина',
 			'AS' => 'Американска Самоа',
 			'AT' => 'Австрия',
 			'AU' => 'Австралия',
 			'AW' => 'Аруба',
 			'AX' => 'Оландски острови',
 			'AZ' => 'Азербайджан',
 			'BA' => 'Босна и Херцеговина',
 			'BB' => 'Барбадос',
 			'BD' => 'Бангладеш',
 			'BE' => 'Белгия',
 			'BF' => 'Буркина Фасо',
 			'BG' => 'България',
 			'BH' => 'Бахрейн',
 			'BI' => 'Бурунди',
 			'BJ' => 'Бенин',
 			'BL' => 'Сен Бартелеми',
 			'BM' => 'Бермудски острови',
 			'BN' => 'Бруней Даруссалам',
 			'BO' => 'Боливия',
 			'BQ' => 'Карибска Нидерландия',
 			'BR' => 'Бразилия',
 			'BS' => 'Бахамски острови',
 			'BT' => 'Бутан',
 			'BV' => 'остров Буве',
 			'BW' => 'Ботсвана',
 			'BY' => 'Беларус',
 			'BZ' => 'Белиз',
 			'CA' => 'Канада',
 			'CC' => 'Кокосови острови (острови Кийлинг)',
 			'CD' => 'Конго (Киншаса)',
 			'CD@alt=variant' => 'Конго (ДРК)',
 			'CF' => 'Централноафриканска република',
 			'CG' => 'Конго (Бразавил)',
 			'CG@alt=variant' => 'Конго (Република)',
 			'CH' => 'Швейцария',
 			'CI' => 'Кот д’Ивоар',
 			'CK' => 'острови Кук',
 			'CL' => 'Чили',
 			'CM' => 'Камерун',
 			'CN' => 'Китай',
 			'CO' => 'Колумбия',
 			'CP' => 'остров Клипертон',
 			'CR' => 'Коста Рика',
 			'CU' => 'Куба',
 			'CV' => 'Кабо Верде',
 			'CW' => 'Кюрасао',
 			'CX' => 'остров Рождество',
 			'CY' => 'Кипър',
 			'CZ' => 'Чехия',
 			'CZ@alt=variant' => 'Чешка република',
 			'DE' => 'Германия',
 			'DG' => 'Диего Гарсия',
 			'DJ' => 'Джибути',
 			'DK' => 'Дания',
 			'DM' => 'Доминика',
 			'DO' => 'Доминиканска република',
 			'DZ' => 'Алжир',
 			'EA' => 'Сеута и Мелия',
 			'EC' => 'Еквадор',
 			'EE' => 'Естония',
 			'EG' => 'Египет',
 			'EH' => 'Западна Сахара',
 			'ER' => 'Еритрея',
 			'ES' => 'Испания',
 			'ET' => 'Етиопия',
 			'EU' => 'Европейски съюз',
 			'EZ' => 'еврозона',
 			'FI' => 'Финландия',
 			'FJ' => 'Фиджи',
 			'FK' => 'Фолкландски острови',
 			'FK@alt=variant' => 'Фолкландски острови (Малвински острови)',
 			'FM' => 'Микронезия',
 			'FO' => 'Фарьорски острови',
 			'FR' => 'Франция',
 			'GA' => 'Габон',
 			'GB' => 'Обединеното кралство',
 			'GD' => 'Гренада',
 			'GE' => 'Грузия',
 			'GF' => 'Френска Гвиана',
 			'GG' => 'Гърнзи',
 			'GH' => 'Гана',
 			'GI' => 'Гибралтар',
 			'GL' => 'Гренландия',
 			'GM' => 'Гамбия',
 			'GN' => 'Гвинея',
 			'GP' => 'Гваделупа',
 			'GQ' => 'Екваториална Гвинея',
 			'GR' => 'Гърция',
 			'GS' => 'Южна Джорджия и Южни Сандвичеви острови',
 			'GT' => 'Гватемала',
 			'GU' => 'Гуам',
 			'GW' => 'Гвинея-Бисау',
 			'GY' => 'Гаяна',
 			'HK' => 'Хонконг, САР на Китай',
 			'HK@alt=short' => 'Хонконг',
 			'HM' => 'острови Хърд и Макдоналд',
 			'HN' => 'Хондурас',
 			'HR' => 'Хърватия',
 			'HT' => 'Хаити',
 			'HU' => 'Унгария',
 			'IC' => 'Канарски острови',
 			'ID' => 'Индонезия',
 			'IE' => 'Ирландия',
 			'IL' => 'Израел',
 			'IM' => 'остров Ман',
 			'IN' => 'Индия',
 			'IO' => 'Британска територия в Индийския океан',
 			'IO@alt=chagos' => 'архипелаг Чагос',
 			'IQ' => 'Ирак',
 			'IR' => 'Иран',
 			'IS' => 'Исландия',
 			'IT' => 'Италия',
 			'JE' => 'Джърси',
 			'JM' => 'Ямайка',
 			'JO' => 'Йордания',
 			'JP' => 'Япония',
 			'KE' => 'Кения',
 			'KG' => 'Киргизстан',
 			'KH' => 'Камбоджа',
 			'KI' => 'Кирибати',
 			'KM' => 'Коморски острови',
 			'KN' => 'Сейнт Китс и Невис',
 			'KP' => 'Северна Корея',
 			'KR' => 'Южна Корея',
 			'KW' => 'Кувейт',
 			'KY' => 'Кайманови острови',
 			'KZ' => 'Казахстан',
 			'LA' => 'Лаос',
 			'LB' => 'Ливан',
 			'LC' => 'Сейнт Лусия',
 			'LI' => 'Лихтенщайн',
 			'LK' => 'Шри Ланка',
 			'LR' => 'Либерия',
 			'LS' => 'Лесото',
 			'LT' => 'Литва',
 			'LU' => 'Люксембург',
 			'LV' => 'Латвия',
 			'LY' => 'Либия',
 			'MA' => 'Мароко',
 			'MC' => 'Монако',
 			'MD' => 'Молдова',
 			'ME' => 'Черна гора',
 			'MF' => 'Сен Мартен',
 			'MG' => 'Мадагаскар',
 			'MH' => 'Маршалови острови',
 			'MK' => 'Северна Македония',
 			'ML' => 'Мали',
 			'MM' => 'Мианмар (Бирма)',
 			'MN' => 'Монголия',
 			'MO' => 'Макао, САР на Китай',
 			'MO@alt=short' => 'Макао',
 			'MP' => 'Северни Мариански острови',
 			'MQ' => 'Мартиника',
 			'MR' => 'Мавритания',
 			'MS' => 'Монтсерат',
 			'MT' => 'Малта',
 			'MU' => 'Мавриций',
 			'MV' => 'Малдиви',
 			'MW' => 'Малави',
 			'MX' => 'Мексико',
 			'MY' => 'Малайзия',
 			'MZ' => 'Мозамбик',
 			'NA' => 'Намибия',
 			'NC' => 'Нова Каледония',
 			'NE' => 'Нигер',
 			'NF' => 'остров Норфолк',
 			'NG' => 'Нигерия',
 			'NI' => 'Никарагуа',
 			'NL' => 'Нидерландия',
 			'NO' => 'Норвегия',
 			'NP' => 'Непал',
 			'NR' => 'Науру',
 			'NU' => 'Ниуе',
 			'NZ' => 'Нова Зеландия',
 			'NZ@alt=variant' => 'Аотеароа Нова Зеландия',
 			'OM' => 'Оман',
 			'PA' => 'Панама',
 			'PE' => 'Перу',
 			'PF' => 'Френска Полинезия',
 			'PG' => 'Папуа-Нова Гвинея',
 			'PH' => 'Филипини',
 			'PK' => 'Пакистан',
 			'PL' => 'Полша',
 			'PM' => 'Сен Пиер и Микелон',
 			'PN' => 'Острови Питкерн',
 			'PR' => 'Пуерто Рико',
 			'PS' => 'Палестински територии',
 			'PS@alt=short' => 'Палестина',
 			'PT' => 'Португалия',
 			'PW' => 'Палау',
 			'PY' => 'Парагвай',
 			'QA' => 'Катар',
 			'QO' => 'Отдалечени острови на Океания',
 			'RE' => 'Реюнион',
 			'RO' => 'Румъния',
 			'RS' => 'Сърбия',
 			'RU' => 'Русия',
 			'RW' => 'Руанда',
 			'SA' => 'Саудитска Арабия',
 			'SB' => 'Соломонови острови',
 			'SC' => 'Сейшели',
 			'SD' => 'Судан',
 			'SE' => 'Швеция',
 			'SG' => 'Сингапур',
 			'SH' => 'Света Елена',
 			'SI' => 'Словения',
 			'SJ' => 'Свалбард и Ян Майен',
 			'SK' => 'Словакия',
 			'SL' => 'Сиера Леоне',
 			'SM' => 'Сан Марино',
 			'SN' => 'Сенегал',
 			'SO' => 'Сомалия',
 			'SR' => 'Суринам',
 			'SS' => 'Южен Судан',
 			'ST' => 'Сао Томе и Принсипи',
 			'SV' => 'Салвадор',
 			'SX' => 'Синт Мартен',
 			'SY' => 'Сирия',
 			'SZ' => 'Есватини',
 			'SZ@alt=variant' => 'Свазиленд',
 			'TA' => 'Тристан да Куня',
 			'TC' => 'острови Търкс и Кайкос',
 			'TD' => 'Чад',
 			'TF' => 'Френски южни територии',
 			'TG' => 'Того',
 			'TH' => 'Тайланд',
 			'TJ' => 'Таджикистан',
 			'TK' => 'Токелау',
 			'TL' => 'Тимор Лесте',
 			'TL@alt=variant' => 'Източен Тимор',
 			'TM' => 'Туркменистан',
 			'TN' => 'Тунис',
 			'TO' => 'Тонга',
 			'TR' => 'Турция',
 			'TT' => 'Тринидад и Тобаго',
 			'TV' => 'Тувалу',
 			'TW' => 'Тайван',
 			'TZ' => 'Танзания',
 			'UA' => 'Украйна',
 			'UG' => 'Уганда',
 			'UM' => 'Отдалечени острови на САЩ',
 			'UN' => 'Организация на обединените нации',
 			'US' => 'Съединени щати',
 			'US@alt=short' => 'САЩ',
 			'UY' => 'Уругвай',
 			'UZ' => 'Узбекистан',
 			'VA' => 'Ватикан',
 			'VC' => 'Сейнт Винсънт и Гренадини',
 			'VE' => 'Венецуела',
 			'VG' => 'Британски Вирджински острови',
 			'VI' => 'Американски Вирджински острови',
 			'VN' => 'Виетнам',
 			'VU' => 'Вануату',
 			'WF' => 'Уолис и Футуна',
 			'WS' => 'Самоа',
 			'XA' => 'Псевдоакценти',
 			'XB' => 'Псевдодвупосочни',
 			'XK' => 'Косово',
 			'YE' => 'Йемен',
 			'YT' => 'Майот',
 			'ZA' => 'Южна Африка',
 			'ZM' => 'Замбия',
 			'ZW' => 'Зимбабве',
 			'ZZ' => 'непознат регион',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Традиционен немски правопис',
 			'1994' => 'Стандартен резиански правопис',
 			'1996' => 'Немски правопис от 1996',
 			'1606NICT' => 'Късен средновековен френски до 1606',
 			'1694ACAD' => 'Ранен съвременен френски',
 			'1959ACAD' => 'Академичен',
 			'AREVELA' => 'Източно арменски',
 			'AREVMDA' => 'Западно арменски',
 			'BAKU1926' => 'Унифицирана тюркска азбука',
 			'BISKE' => 'Диалект Сан Джорджио/Била',
 			'BOONT' => 'Бунтлинг',
 			'FONIPA' => 'Международна фонетична азбука',
 			'FONUPA' => 'Уралска фонетична азбука',
 			'KKCOR' => 'Общ правопис',
 			'LIPAW' => 'Диалект Липовац',
 			'MONOTON' => 'Монотонично',
 			'NEDIS' => 'Диалект Натисоне',
 			'NJIVA' => 'Диалект Нджива',
 			'OSOJS' => 'Диалект Осеако/Осояне',
 			'PINYIN' => 'Пинин романизация',
 			'POLYTON' => 'Политонично',
 			'POSIX' => 'Компютърен',
 			'REVISED' => 'Променен правопис',
 			'ROZAJ' => 'Резиански',
 			'SAAHO' => 'Сахо',
 			'SCOTLAND' => 'Шотландски английски',
 			'SCOUSE' => 'Ливърпулски диалект',
 			'SOLBA' => 'Диалект Столвиза',
 			'TARASK' => 'Тарашкевица',
 			'VALENCIA' => 'Валенсиански',
 			'WADEGILE' => 'Уейд-Джайлс романизация',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'календар',
 			'cf' => 'формат на валута',
 			'colalternate' => 'Пренебрегване на сортирането по символи',
 			'colbackwards' => 'Сортиране по диакритични знаци в обратен ред',
 			'colcasefirst' => 'Подреждане по горен/долен регистър',
 			'colcaselevel' => 'Сортиране с различаване на регистъра на буквите',
 			'collation' => 'ред на сортиране',
 			'colnormalization' => 'Нормализирано сортиране',
 			'colnumeric' => 'Сортиране на цифрите',
 			'colstrength' => 'Сила на сортиране',
 			'currency' => 'валута',
 			'hc' => 'Часови формат (12- или 24-часов)',
 			'lb' => 'Стил за нов ред',
 			'ms' => 'Мерна система',
 			'numbers' => 'цифри',
 			'timezone' => 'Часова зона',
 			'va' => 'Вариант на локала',
 			'x' => 'Собствена употреба',

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
 				'buddhist' => q{будистки календар},
 				'chinese' => q{китайски календар},
 				'coptic' => q{коптски календар},
 				'dangi' => q{корейски календар},
 				'ethiopic' => q{етиопски календар},
 				'ethiopic-amete-alem' => q{етиопски календар Амит Алем},
 				'gregorian' => q{григориански календар},
 				'hebrew' => q{еврейски календар},
 				'indian' => q{Индийски граждански календар},
 				'islamic' => q{ислямски календар},
 				'islamic-civil' => q{ислямски цивилен календар},
 				'islamic-umalqura' => q{ислямски календар (Ум ал-Кура)},
 				'iso8601' => q{календар съгласно ISO 8601},
 				'japanese' => q{японски календар},
 				'persian' => q{персийски календар},
 				'roc' => q{календар на Република Китай},
 			},
 			'cf' => {
 				'account' => q{формат на валута за счетоводни цели},
 				'standard' => q{стандартен формат на валута},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Сортиране по символи},
 				'shifted' => q{Сортиране с пренебрегване на символи},
 			},
 			'colbackwards' => {
 				'no' => q{Нормално сортиране по диакритични знаци},
 				'yes' => q{Обратно сортиране по диакритични знаци},
 			},
 			'colcasefirst' => {
 				'lower' => q{Сортиране първо по долен регистър},
 				'no' => q{Сортиране с нормален ред за регистъра},
 				'upper' => q{Сортиране първо по горен регистър},
 			},
 			'colcaselevel' => {
 				'no' => q{Сортиране без различаване на регистъра на буквите},
 				'yes' => q{Сортиране с различаване на регистъра на буквите},
 			},
 			'collation' => {
 				'big5han' => q{Традиционен китайски (Big5)},
 				'compat' => q{предишен ред на сортиране, за съвместимост},
 				'dictionary' => q{Речников ред на сортиране},
 				'ducet' => q{ред на сортиране в Unicode по подразбиране},
 				'gb2312han' => q{Опростен китайски (GB2312)},
 				'phonebook' => q{Азбучен ред},
 				'phonetic' => q{Фонетичен ред на сортиране},
 				'pinyin' => q{Сортиране Пинин},
 				'reformed' => q{Следреформен ред на сортиране},
 				'search' => q{търсене с общо предназначение},
 				'searchjl' => q{Търсене по първоначални съгласни в хангул},
 				'standard' => q{стандартен ред на сортиране},
 				'stroke' => q{Сортиране по щрих},
 				'traditional' => q{Традиционно сортиране},
 				'unihan' => q{Ред на сортиране по ключове и черти},
 				'zhuyin' => q{ред на сортиране Бопомофо},
 			},
 			'colnormalization' => {
 				'no' => q{Сортиране без нормализиране},
 				'yes' => q{Нормализирано сортиране в Уникод},
 			},
 			'colnumeric' => {
 				'no' => q{Сортиране на цифрите индивидуално},
 				'yes' => q{Сортиране на цифрите по числена стойност},
 			},
 			'colstrength' => {
 				'identical' => q{Сортиране на всички},
 				'primary' => q{Сортиране само по основни букви},
 				'quaternary' => q{Сортиране по диакритични знаци/регистър/ширина/кана},
 				'secondary' => q{Сортиране по диакритични знаци},
 				'tertiary' => q{Сортиране по диакритични знаци/регистър/ширина},
 			},
 			'd0' => {
 				'fwidth' => q{С пълна ширина},
 				'hwidth' => q{С половин ширина},
 				'npinyin' => q{Цифрови},
 			},
 			'hc' => {
 				'h11' => q{12-часова система (0 – 11)},
 				'h12' => q{12-часова система (1 – 12)},
 				'h23' => q{24-часова система (0 – 23)},
 				'h24' => q{24-часова система (1 – 24)},
 			},
 			'lb' => {
 				'loose' => q{Свободен стил за нов ред},
 				'normal' => q{Нормален стил за нов ред},
 				'strict' => q{Строг стил за нов ред},
 			},
 			'm0' => {
 				'bgn' => q{АКГН (BGN)},
 				'ungegn' => q{ГЕСГИ ООН (UNGEGN)},
 			},
 			'ms' => {
 				'metric' => q{Метрична система},
 				'uksystem' => q{Имперска мерна система},
 				'ussystem' => q{Мерна система на САЩ},
 			},
 			'numbers' => {
 				'arab' => q{арабско-индийски цифри},
 				'arabext' => q{разширени арабско-индийски цифри},
 				'armn' => q{арменски цифри},
 				'armnlow' => q{арменски цифри в долен регистър},
 				'beng' => q{бенгалски цифри},
 				'cakm' => q{цифри в чакма},
 				'deva' => q{цифри в деванагари},
 				'ethi' => q{етиопски цифри},
 				'finance' => q{Финансови цифри},
 				'fullwide' => q{цифри с пълна ширина},
 				'geor' => q{грузински цифри},
 				'grek' => q{гръцки цифри},
 				'greklow' => q{гръцки цифри в долен регистър},
 				'gujr' => q{цифри в гуджарати},
 				'guru' => q{цифри в гурмукхи},
 				'hanidec' => q{китайски десетични цифри},
 				'hans' => q{цифри в китайски (опростен)},
 				'hansfin' => q{финансови цифри в китайски (опростен)},
 				'hant' => q{цифри в китайски (традиционен)},
 				'hantfin' => q{финансови цифри в китайски (традиционен)},
 				'hebr' => q{цифри в иврит},
 				'java' => q{явански цифри},
 				'jpan' => q{японски цифри},
 				'jpanfin' => q{японски финансови цифри},
 				'khmr' => q{кхмерски цифри},
 				'knda' => q{цифри в каннада},
 				'laoo' => q{лаоски цифри},
 				'latn' => q{западни цифри},
 				'mlym' => q{цифри в малаялам},
 				'mong' => q{Монголски цифри},
 				'mtei' => q{цифри в меетеи майтек},
 				'mymr' => q{бирмански цифри},
 				'native' => q{Местни цифри},
 				'olck' => q{цифри в ол чики},
 				'orya' => q{цифри в одия},
 				'roman' => q{римски цифри},
 				'romanlow' => q{римски цифри в долен регистър},
 				'taml' => q{традиционни тамилски цифри},
 				'tamldec' => q{тамилски цифри},
 				'telu' => q{цифри в телугу},
 				'thai' => q{тайландски цифри},
 				'tibt' => q{тибетски цифри},
 				'traditional' => q{Традиционни цифри},
 				'vaii' => q{цифри във ваи},
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
			'metric' => q{метрична},
 			'UK' => q{имперска},
 			'US' => q{американска},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Език: {0}',
 			'script' => 'Писменост: {0}',
 			'region' => 'Регион: {0}',

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
			auxiliary => qr{[{а̀} ѐё ѝ {о̀} {у̀} {ъ̀} ы ѣ э {ю̀} {я̀} ѫ]},
			index => ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ю', 'Я'],
			main => qr{[а б в г д е ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ь ю я]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘‚ "“„ ( ) \[ \] § @ * / ″ №]},
		};
	},
EOT
: sub {
		return { index => ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ю', 'Я'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}… {1}',
		};
	},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
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

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(основна посока),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(основна посока),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(киби{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(киби{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(меби{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(меби{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(гиби{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(гиби{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(теби{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(теби{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(пеби{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(пеби{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(ексби{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(ексби{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(зеби{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(зеби{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(йоби{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(йоби{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(деци{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(деци{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(пико{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(пико{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(фемто{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(фемто{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(ато{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ато{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(санти{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(санти{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(зепто{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(зепто{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(йокто{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(йокто{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ронто{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ронто{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(мили{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(мили{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(куекто{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(куекто{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(микро{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(микро{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(нано{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(нано{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(дека{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(дека{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(тера{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(тера{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(пета{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(пета{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(екса{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(екса{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(хекто{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(хекто{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(зета{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(зета{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(йота{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(йота{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(рона{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(рона{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(кило{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(кило{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(куета{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(куета{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(мега{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(мега{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(гига{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(гига{0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(метри за секунда на квадрат),
						'one' => q({0} метър за секунда на квадрат),
						'other' => q({0} метра за секунда на квадрат),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(метри за секунда на квадрат),
						'one' => q({0} метър за секунда на квадрат),
						'other' => q({0} метра за секунда на квадрат),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(дъгови минути),
						'one' => q({0} дъгова минута),
						'other' => q({0} дъгови минути),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(дъгови минути),
						'one' => q({0} дъгова минута),
						'other' => q({0} дъгови минути),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(дъгови секунди),
						'one' => q({0} дъгова секунда),
						'other' => q({0} дъгови секунди),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(дъгови секунди),
						'one' => q({0} дъгова секунда),
						'other' => q({0} дъгови секунди),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(градуси),
						'one' => q({0} градус),
						'other' => q({0} градуса),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(градуси),
						'one' => q({0} градус),
						'other' => q({0} градуса),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(радиани),
						'one' => q({0} радиан),
						'other' => q({0} радиана),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(радиани),
						'one' => q({0} радиан),
						'other' => q({0} радиана),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(оборот),
						'one' => q({0} оборот),
						'other' => q({0} оборота),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(оборот),
						'one' => q({0} оборот),
						'other' => q({0} оборота),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(хектари),
						'one' => q({0} хектар),
						'other' => q({0} хектара),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(хектари),
						'one' => q({0} хектар),
						'other' => q({0} хектара),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(квадратни сантиметри),
						'one' => q({0} квадратен сантиметър),
						'other' => q({0} квадратни сантиметра),
						'per' => q({0} на квадратен сантиметър),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(квадратни сантиметри),
						'one' => q({0} квадратен сантиметър),
						'other' => q({0} квадратни сантиметра),
						'per' => q({0} на квадратен сантиметър),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(квадратни футове),
						'one' => q({0} квадратен фут),
						'other' => q({0} квадратни фута),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(квадратни футове),
						'one' => q({0} квадратен фут),
						'other' => q({0} квадратни фута),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(квадратни инчове),
						'one' => q({0} квадратен инч),
						'other' => q({0} квадратни инча),
						'per' => q({0} на квадратен инч),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(квадратни инчове),
						'one' => q({0} квадратен инч),
						'other' => q({0} квадратни инча),
						'per' => q({0} на квадратен инч),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(квадратни километри),
						'one' => q({0} квадратен километър),
						'other' => q({0} квадратни километра),
						'per' => q({0} на квадратен километър),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(квадратни километри),
						'one' => q({0} квадратен километър),
						'other' => q({0} квадратни километра),
						'per' => q({0} на квадратен километър),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(квадратни метри),
						'one' => q({0} квадратен метър),
						'other' => q({0} квадратни метра),
						'per' => q({0} на квадратен метър),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(квадратни метри),
						'one' => q({0} квадратен метър),
						'other' => q({0} квадратни метра),
						'per' => q({0} на квадратен метър),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(квадратни мили),
						'one' => q({0} квадратна миля),
						'other' => q({0} квадратни мили),
						'per' => q({0} на квадратна миля),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(квадратни мили),
						'one' => q({0} квадратна миля),
						'other' => q({0} квадратни мили),
						'per' => q({0} на квадратна миля),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(квадратни ярдове),
						'one' => q({0} квадратен ярд),
						'other' => q({0} квадратни ярда),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(квадратни ярдове),
						'one' => q({0} квадратен ярд),
						'other' => q({0} квадратни ярда),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(единици),
						'one' => q({0} единица),
						'other' => q({0} единици),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(единици),
						'one' => q({0} единица),
						'other' => q({0} единици),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(карати),
						'one' => q({0} карат),
						'other' => q({0} карата),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(карати),
						'one' => q({0} карат),
						'other' => q({0} карата),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(милиграми на децилитър),
						'one' => q({0} милиграм на децилитър),
						'other' => q({0} милиграма на децилитър),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(милиграми на децилитър),
						'one' => q({0} милиграм на децилитър),
						'other' => q({0} милиграма на децилитър),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(милимоли на литър),
						'one' => q({0} милимол на литър),
						'other' => q({0} милимола на литър),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(милимоли на литър),
						'one' => q({0} милимол на литър),
						'other' => q({0} милимола на литър),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(молове),
						'one' => q({0} мол),
						'other' => q({0} мола),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(молове),
						'one' => q({0} мол),
						'other' => q({0} мола),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} процент),
						'other' => q({0} процента),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} процент),
						'other' => q({0} процента),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(промил),
						'one' => q({0} промил),
						'other' => q({0} промила),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(промил),
						'one' => q({0} промил),
						'other' => q({0} промила),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(части на милион),
						'one' => q({0} част на милион),
						'other' => q({0} части на милион),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(части на милион),
						'one' => q({0} част на милион),
						'other' => q({0} части на милион),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} базисен пункт),
						'other' => q({0} базисни пункта),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} базисен пункт),
						'other' => q({0} базисни пункта),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(литри на 100 километра),
						'one' => q({0} литър на 100 километра),
						'other' => q({0} литра на 100 километра),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(литри на 100 километра),
						'one' => q({0} литър на 100 километра),
						'other' => q({0} литра на 100 километра),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(литри на километър),
						'one' => q({0} литър на километър),
						'other' => q({0} литра на километър),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(литри на километър),
						'one' => q({0} литър на километър),
						'other' => q({0} литра на километър),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(мили на галон),
						'one' => q({0} миля на галон),
						'other' => q({0} мили на галон),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(мили на галон),
						'one' => q({0} миля на галон),
						'other' => q({0} мили на галон),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(мили на имперски галон),
						'one' => q({0} миля на имперски галон),
						'other' => q({0} мили на имперски галон),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(мили на имперски галон),
						'one' => q({0} миля на имперски галон),
						'other' => q({0} мили на имперски галон),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(битове),
						'one' => q({0} бит),
						'other' => q({0} бита),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(битове),
						'one' => q({0} бит),
						'other' => q({0} бита),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(байтове),
						'one' => q({0} байт),
						'other' => q({0} байта),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(байтове),
						'one' => q({0} байт),
						'other' => q({0} байта),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(гигабити),
						'one' => q({0} гигабит),
						'other' => q({0} гигабита),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(гигабити),
						'one' => q({0} гигабит),
						'other' => q({0} гигабита),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(гигабайти),
						'one' => q({0} гигабайт),
						'other' => q({0} гигабайта),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(гигабайти),
						'one' => q({0} гигабайт),
						'other' => q({0} гигабайта),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(килобитове),
						'one' => q({0} килобит),
						'other' => q({0} килобита),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(килобитове),
						'one' => q({0} килобит),
						'other' => q({0} килобита),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(килобайтове),
						'one' => q({0} килобайт),
						'other' => q({0} килобайта),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(килобайтове),
						'one' => q({0} килобайт),
						'other' => q({0} килобайта),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(мегабитове),
						'one' => q({0} мегабит),
						'other' => q({0} мегабита),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(мегабитове),
						'one' => q({0} мегабит),
						'other' => q({0} мегабита),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(мегабайти),
						'one' => q({0} мегабайт),
						'other' => q({0} мегабайта),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(мегабайти),
						'one' => q({0} мегабайт),
						'other' => q({0} мегабайта),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(петабайти),
						'one' => q({0} петабайт),
						'other' => q({0} петабайта),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(петабайти),
						'one' => q({0} петабайт),
						'other' => q({0} петабайта),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(терабитове),
						'one' => q({0} терабит),
						'other' => q({0} терабита),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(терабитове),
						'one' => q({0} терабит),
						'other' => q({0} терабита),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(терабайтове),
						'one' => q({0} терабайт),
						'other' => q({0} терабайта),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(терабайтове),
						'one' => q({0} терабайт),
						'other' => q({0} терабайта),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(векове),
						'one' => q({0} век),
						'other' => q({0} века),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(векове),
						'one' => q({0} век),
						'other' => q({0} века),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} ден),
						'other' => q({0} дни),
						'per' => q({0} на ден),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} ден),
						'other' => q({0} дни),
						'per' => q({0} на ден),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(десетилетия),
						'one' => q({0} десетилетие),
						'other' => q({0} десетилетия),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(десетилетия),
						'one' => q({0} десетилетие),
						'other' => q({0} десетилетия),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} час),
						'other' => q({0} часа),
						'per' => q({0} за час),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} час),
						'other' => q({0} часа),
						'per' => q({0} за час),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(микросекунди),
						'one' => q({0} микросекунда),
						'other' => q({0} микросекунди),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(микросекунди),
						'one' => q({0} микросекунда),
						'other' => q({0} микросекунди),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} милисекунда),
						'other' => q({0} милисекунди),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} милисекунда),
						'other' => q({0} милисекунди),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(минути),
						'one' => q({0} минута),
						'other' => q({0} минути),
						'per' => q({0} на минута),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(минути),
						'one' => q({0} минута),
						'other' => q({0} минути),
						'per' => q({0} на минута),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} месец),
						'other' => q({0} месеца),
						'per' => q({0} на месец),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} месец),
						'other' => q({0} месеца),
						'per' => q({0} на месец),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(наносекунди),
						'one' => q({0} наносекунда),
						'other' => q({0} наносекунди),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(наносекунди),
						'one' => q({0} наносекунда),
						'other' => q({0} наносекунди),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(тримесечия),
						'one' => q({0} тримесечие),
						'other' => q({0} тримесечия),
						'per' => q({0}/тримесечие),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(тримесечия),
						'one' => q({0} тримесечие),
						'other' => q({0} тримесечия),
						'per' => q({0}/тримесечие),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} секунда),
						'other' => q({0} секунди),
						'per' => q({0} за секунда),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} секунда),
						'other' => q({0} секунди),
						'per' => q({0} за секунда),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} седмица),
						'other' => q({0} седмици),
						'per' => q({0} на седмица),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} седмица),
						'other' => q({0} седмици),
						'per' => q({0} на седмица),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} година),
						'other' => q({0} години),
						'per' => q({0} на година),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} година),
						'other' => q({0} години),
						'per' => q({0} на година),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ампери),
						'one' => q({0} ампер),
						'other' => q({0} ампера),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ампери),
						'one' => q({0} ампер),
						'other' => q({0} ампера),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(милиампери),
						'one' => q({0} милиампер),
						'other' => q({0} милиампера),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(милиампери),
						'one' => q({0} милиампер),
						'other' => q({0} милиампера),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(омове),
						'one' => q({0} ом),
						'other' => q({0} ома),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(омове),
						'one' => q({0} ом),
						'other' => q({0} ома),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(волтове),
						'one' => q({0} волт),
						'other' => q({0} волта),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(волтове),
						'one' => q({0} волт),
						'other' => q({0} волта),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(британски термални единици),
						'one' => q({0} британска термална единица),
						'other' => q({0} британски термални единици),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(британски термални единици),
						'one' => q({0} британска термална единица),
						'other' => q({0} британски термални единици),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(калории),
						'one' => q({0} калория),
						'other' => q({0} калории),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(калории),
						'one' => q({0} калория),
						'other' => q({0} калории),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(електронволтове),
						'one' => q({0} електронволт),
						'other' => q({0} електронволта),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(електронволтове),
						'one' => q({0} електронволт),
						'other' => q({0} електронволта),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(калории),
						'one' => q({0} калория),
						'other' => q({0} калории),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(калории),
						'one' => q({0} калория),
						'other' => q({0} калории),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(джаули),
						'one' => q({0} джаул),
						'other' => q({0} джаула),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(джаули),
						'one' => q({0} джаул),
						'other' => q({0} джаула),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(килокалории),
						'one' => q({0} килокалория),
						'other' => q({0} килокалории),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(килокалории),
						'one' => q({0} килокалория),
						'other' => q({0} килокалории),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(килоджаули),
						'one' => q({0} килоджаул),
						'other' => q({0} килоджаула),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(килоджаули),
						'one' => q({0} килоджаул),
						'other' => q({0} килоджаула),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(киловатчасове),
						'one' => q({0} киловатчас),
						'other' => q({0} киловатчаса),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(киловатчасове),
						'one' => q({0} киловатчас),
						'other' => q({0} киловатчаса),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(американски термални единици),
						'one' => q({0} американска термална единица),
						'other' => q({0} американски термални единици),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(американски термални единици),
						'one' => q({0} американска термална единица),
						'other' => q({0} американски термални единици),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(киловатчас на 100 километра),
						'one' => q({0} киловатчас на 100 километра),
						'other' => q({0} киловатчаса на 100 километра),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(киловатчас на 100 километра),
						'one' => q({0} киловатчас на 100 километра),
						'other' => q({0} киловатчаса на 100 километра),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(нютони),
						'one' => q({0} нютон),
						'other' => q({0} нютона),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(нютони),
						'one' => q({0} нютон),
						'other' => q({0} нютона),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(фунтове сила),
						'one' => q({0} фунт сила),
						'other' => q({0} фунта сила),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(фунтове сила),
						'one' => q({0} фунт сила),
						'other' => q({0} фунта сила),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(гигахерци),
						'one' => q({0} гигахерц),
						'other' => q({0} гигахерца),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(гигахерци),
						'one' => q({0} гигахерц),
						'other' => q({0} гигахерца),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(херцове),
						'one' => q({0} херц),
						'other' => q({0} херца),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(херцове),
						'one' => q({0} херц),
						'other' => q({0} херца),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(килохерци),
						'one' => q({0} килохерц),
						'other' => q({0} килохерца),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(килохерци),
						'one' => q({0} килохерц),
						'other' => q({0} килохерца),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(мегахерци),
						'one' => q({0} мегахерц),
						'other' => q({0} мегахерца),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(мегахерци),
						'one' => q({0} мегахерц),
						'other' => q({0} мегахерца),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(точки на сантиметър),
						'one' => q({0} точка на сантиметър),
						'other' => q({0} точки на сантиметър),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(точки на сантиметър),
						'one' => q({0} точка на сантиметър),
						'other' => q({0} точки на сантиметър),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(точки на инч),
						'one' => q({0} точка на инч),
						'other' => q({0} точки на инч),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(точки на инч),
						'one' => q({0} точка на инч),
						'other' => q({0} точки на инч),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(типографски ем),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(типографски ем),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(мегапиксели),
						'one' => q({0} мегапиксел),
						'other' => q({0} мегапиксела),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(мегапиксели),
						'one' => q({0} мегапиксел),
						'other' => q({0} мегапиксела),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(пиксели),
						'one' => q({0} пиксел),
						'other' => q({0} пиксела),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(пиксели),
						'one' => q({0} пиксел),
						'other' => q({0} пиксела),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(пиксели на сантиметър),
						'one' => q({0} пиксел на сантиметър),
						'other' => q({0} пиксела на сантиметър),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(пиксели на сантиметър),
						'one' => q({0} пиксел на сантиметър),
						'other' => q({0} пиксела на сантиметър),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(пиксели на инч),
						'one' => q({0} пиксел на инч),
						'other' => q({0} пиксела на инч),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(пиксели на инч),
						'one' => q({0} пиксел на инч),
						'other' => q({0} пиксела на инч),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(астрономически единици),
						'one' => q({0} астрономическа единица),
						'other' => q({0} астрономически единици),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(астрономически единици),
						'one' => q({0} астрономическа единица),
						'other' => q({0} астрономически единици),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(сантиметри),
						'one' => q({0} сантиметър),
						'other' => q({0} сантиметра),
						'per' => q({0} на сантиметър),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(сантиметри),
						'one' => q({0} сантиметър),
						'other' => q({0} сантиметра),
						'per' => q({0} на сантиметър),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(дециметри),
						'one' => q({0} дециметър),
						'other' => q({0} дециметра),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(дециметри),
						'one' => q({0} дециметър),
						'other' => q({0} дециметра),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(земен радиус),
						'one' => q({0} земен радиус),
						'other' => q({0} земни радиуса),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(земен радиус),
						'one' => q({0} земен радиус),
						'other' => q({0} земни радиуса),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(фатоми),
						'one' => q({0} фатом),
						'other' => q({0} фатома),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(фатоми),
						'one' => q({0} фатом),
						'other' => q({0} фатома),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(футове),
						'one' => q({0} фут),
						'other' => q({0} фута),
						'per' => q({0} на фут),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(футове),
						'one' => q({0} фут),
						'other' => q({0} фута),
						'per' => q({0} на фут),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(фърлонги),
						'one' => q({0} фърлонг),
						'other' => q({0} фърлонга),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(фърлонги),
						'one' => q({0} фърлонг),
						'other' => q({0} фърлонга),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(инчове),
						'one' => q({0} инч),
						'other' => q({0} инча),
						'per' => q({0} на инч),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(инчове),
						'one' => q({0} инч),
						'other' => q({0} инча),
						'per' => q({0} на инч),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(километри),
						'one' => q({0} километър),
						'other' => q({0} километра),
						'per' => q({0} на километър),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(километри),
						'one' => q({0} километър),
						'other' => q({0} километра),
						'per' => q({0} на километър),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(светлинни години),
						'one' => q({0} светлинна година),
						'other' => q({0} светлинни години),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(светлинни години),
						'one' => q({0} светлинна година),
						'other' => q({0} светлинни години),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(метри),
						'one' => q({0} метър),
						'other' => q({0} метра),
						'per' => q({0} на метър),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(метри),
						'one' => q({0} метър),
						'other' => q({0} метра),
						'per' => q({0} на метър),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(микрометри),
						'one' => q({0} микрометър),
						'other' => q({0} микрометра),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(микрометри),
						'one' => q({0} микрометър),
						'other' => q({0} микрометра),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(мили),
						'one' => q({0} миля),
						'other' => q({0} мили),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(мили),
						'one' => q({0} миля),
						'other' => q({0} мили),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(шведска миля),
						'one' => q({0} шведска миля),
						'other' => q({0} шведски мили),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(шведска миля),
						'one' => q({0} шведска миля),
						'other' => q({0} шведски мили),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(милиметри),
						'one' => q({0} милиметър),
						'other' => q({0} милиметра),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(милиметри),
						'one' => q({0} милиметър),
						'other' => q({0} милиметра),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(нанометри),
						'one' => q({0} нанометър),
						'other' => q({0} нанометра),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(нанометри),
						'one' => q({0} нанометър),
						'other' => q({0} нанометра),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(морски мили),
						'one' => q({0} морска миля),
						'other' => q({0} морски мили),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(морски мили),
						'one' => q({0} морска миля),
						'other' => q({0} морски мили),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(парсеци),
						'one' => q({0} парсек),
						'other' => q({0} парсека),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(парсеци),
						'one' => q({0} парсек),
						'other' => q({0} парсека),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(пикометри),
						'one' => q({0} пикометър),
						'other' => q({0} пикометра),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(пикометри),
						'one' => q({0} пикометър),
						'other' => q({0} пикометра),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(пунктове),
						'one' => q({0} пункт),
						'other' => q({0} пункта),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(пунктове),
						'one' => q({0} пункт),
						'other' => q({0} пункта),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(слънчеви радиуси),
						'one' => q({0} слънчев радиус),
						'other' => q({0} слънчеви радиуси),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(слънчеви радиуси),
						'one' => q({0} слънчев радиус),
						'other' => q({0} слънчеви радиуси),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ярдове),
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ярдове),
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(кандела),
						'one' => q({0} кандела),
						'other' => q({0} кандели),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(кандела),
						'one' => q({0} кандела),
						'other' => q({0} кандели),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(лумен),
						'one' => q({0} лумен),
						'other' => q({0} лумена),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(лумен),
						'one' => q({0} лумен),
						'other' => q({0} лумена),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(луксове),
						'one' => q({0} лукс),
						'other' => q({0} лукса),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(луксове),
						'one' => q({0} лукс),
						'other' => q({0} лукса),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(слънчеви светимости),
						'one' => q({0} слънчева светимост),
						'other' => q({0} слънчеви светимости),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(слънчеви светимости),
						'one' => q({0} слънчева светимост),
						'other' => q({0} слънчеви светимости),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(карати),
						'one' => q({0} карат),
						'other' => q({0} карата),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(карати),
						'one' => q({0} карат),
						'other' => q({0} карата),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} далтон),
						'other' => q({0} далтона),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} далтон),
						'other' => q({0} далтона),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(маси на Земята),
						'one' => q({0} маса на Земята),
						'other' => q({0} маси на Земята),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(маси на Земята),
						'one' => q({0} маса на Земята),
						'other' => q({0} маси на Земята),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(грамове),
						'one' => q({0} грам),
						'other' => q({0} грама),
						'per' => q({0} на грам),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(грамове),
						'one' => q({0} грам),
						'other' => q({0} грама),
						'per' => q({0} на грам),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(килограми),
						'one' => q({0} килограм),
						'other' => q({0} килограма),
						'per' => q({0} на килограм),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(килограми),
						'one' => q({0} килограм),
						'other' => q({0} килограма),
						'per' => q({0} на килограм),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(микрограмове),
						'one' => q({0} микрограм),
						'other' => q({0} микрограма),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(микрограмове),
						'one' => q({0} микрограм),
						'other' => q({0} микрограма),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(милиграмове),
						'one' => q({0} милиграм),
						'other' => q({0} милиграма),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(милиграмове),
						'one' => q({0} милиграм),
						'other' => q({0} милиграма),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(унции),
						'one' => q({0} унция),
						'other' => q({0} унции),
						'per' => q({0} на унция),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(унции),
						'one' => q({0} унция),
						'other' => q({0} унции),
						'per' => q({0} на унция),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(тройунции),
						'one' => q({0} тройунция),
						'other' => q({0} тройунции),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(тройунции),
						'one' => q({0} тройунция),
						'other' => q({0} тройунции),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(фунтове),
						'one' => q({0} фунт),
						'other' => q({0} фунта),
						'per' => q({0} на фунт),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(фунтове),
						'one' => q({0} фунт),
						'other' => q({0} фунта),
						'per' => q({0} на фунт),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(слънчеви маси),
						'one' => q({0} слънчева маса),
						'other' => q({0} слънчеви маси),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(слънчеви маси),
						'one' => q({0} слънчева маса),
						'other' => q({0} слънчеви маси),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(стоунове),
						'one' => q({0} стоун),
						'other' => q({0} стоуна),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(стоунове),
						'one' => q({0} стоун),
						'other' => q({0} стоуна),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(къси тонове),
						'one' => q({0} къс тон),
						'other' => q({0} къси тона),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(къси тонове),
						'one' => q({0} къс тон),
						'other' => q({0} къси тона),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(метрични тонове),
						'one' => q({0} метричен тон),
						'other' => q({0} метрични тона),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(метрични тонове),
						'one' => q({0} метричен тон),
						'other' => q({0} метрични тона),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} на {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} на {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(гигавати),
						'one' => q({0} гигават),
						'other' => q({0} гигавата),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(гигавати),
						'one' => q({0} гигават),
						'other' => q({0} гигавата),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(конски сили),
						'one' => q({0} конска сила),
						'other' => q({0} конски сили),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(конски сили),
						'one' => q({0} конска сила),
						'other' => q({0} конски сили),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(киловати),
						'one' => q({0} киловат),
						'other' => q({0} киловата),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(киловати),
						'one' => q({0} киловат),
						'other' => q({0} киловата),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(мегавати),
						'one' => q({0} мегават),
						'other' => q({0} мегавата),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(мегавати),
						'one' => q({0} мегават),
						'other' => q({0} мегавата),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(миливати),
						'one' => q({0} миливат),
						'other' => q({0} миливата),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(миливати),
						'one' => q({0} миливат),
						'other' => q({0} миливата),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ватове),
						'one' => q({0} ват),
						'other' => q({0} вата),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ватове),
						'one' => q({0} ват),
						'other' => q({0} вата),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(квадратни {0}),
						'one' => q(квадратен {0}),
						'other' => q(квадратни {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(квадратни {0}),
						'one' => q(квадратен {0}),
						'other' => q(квадратни {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(кубични {0}),
						'one' => q(кубичен {0}),
						'other' => q(кубични {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(кубични {0}),
						'one' => q(кубичен {0}),
						'other' => q(кубични {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(атмосфери),
						'one' => q({0} атмосфера),
						'other' => q({0} атмосфери),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(атмосфери),
						'one' => q({0} атмосфера),
						'other' => q({0} атмосфери),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(барове),
						'one' => q({0} бар),
						'other' => q({0} бара),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(барове),
						'one' => q({0} бар),
						'other' => q({0} бара),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(хектопаскали),
						'one' => q({0} хектопаскал),
						'other' => q({0} хектопаскала),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(хектопаскали),
						'one' => q({0} хектопаскал),
						'other' => q({0} хектопаскала),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(инчове живачен стълб),
						'one' => q({0} инч живачен стълб),
						'other' => q({0} инча живачен стълб),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(инчове живачен стълб),
						'one' => q({0} инч живачен стълб),
						'other' => q({0} инча живачен стълб),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(килопаскали),
						'one' => q({0} килопаскал),
						'other' => q({0} килопаскала),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(килопаскали),
						'one' => q({0} килопаскал),
						'other' => q({0} килопаскала),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(мегапаскали),
						'one' => q({0} мегапаскал),
						'other' => q({0} мегапаскала),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(мегапаскали),
						'one' => q({0} мегапаскал),
						'other' => q({0} мегапаскала),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(милибари),
						'one' => q({0} милибар),
						'other' => q({0} милибара),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(милибари),
						'one' => q({0} милибар),
						'other' => q({0} милибара),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(милиметри живачен стълб),
						'one' => q({0} милиметър живачен стълб),
						'other' => q({0} милиметра живачен стълб),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(милиметри живачен стълб),
						'one' => q({0} милиметър живачен стълб),
						'other' => q({0} милиметра живачен стълб),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(паскали),
						'one' => q({0} паскал),
						'other' => q({0} паскала),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(паскали),
						'one' => q({0} паскал),
						'other' => q({0} паскала),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(фунтове на квадратен инч),
						'one' => q({0} фунт на квадратен инч),
						'other' => q({0} фунта на квадратен инч),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(фунтове на квадратен инч),
						'one' => q({0} фунт на квадратен инч),
						'other' => q({0} фунта на квадратен инч),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Бофорт),
						'one' => q({0} по Бофорт),
						'other' => q({0} по Бофорт),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Бофорт),
						'one' => q({0} по Бофорт),
						'other' => q({0} по Бофорт),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(километри в час),
						'one' => q({0} километър в час),
						'other' => q({0} километра в час),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(километри в час),
						'one' => q({0} километър в час),
						'other' => q({0} километра в час),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(възел),
						'one' => q({0} възел),
						'other' => q({0} възла),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(възел),
						'one' => q({0} възел),
						'other' => q({0} възла),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(метри за секунда),
						'one' => q({0} метър за секунда),
						'other' => q({0} метра за секунда),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(метри за секунда),
						'one' => q({0} метър за секунда),
						'other' => q({0} метра за секунда),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(мили в час),
						'one' => q({0} миля в час),
						'other' => q({0} мили в час),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(мили в час),
						'one' => q({0} миля в час),
						'other' => q({0} мили в час),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(градуси Целзий),
						'one' => q({0} градус Целзий),
						'other' => q({0} градуса Целзий),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(градуси Целзий),
						'one' => q({0} градус Целзий),
						'other' => q({0} градуса Целзий),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(градуси по Фаренхайт),
						'one' => q({0} градус по Фаренхайт),
						'other' => q({0} градуса по Фаренхайт),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(градуси по Фаренхайт),
						'one' => q({0} градус по Фаренхайт),
						'other' => q({0} градуса по Фаренхайт),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(келвини),
						'one' => q({0} келвин),
						'other' => q({0} келвина),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(келвини),
						'one' => q({0} келвин),
						'other' => q({0} келвина),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(нютон-метър),
						'one' => q({0} нютон-метър),
						'other' => q({0} нютон-метра),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(нютон-метър),
						'one' => q({0} нютон-метър),
						'other' => q({0} нютон-метра),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(паунд-футове сила),
						'one' => q({0} паунд-фут сила),
						'other' => q({0} паунд-фута сила),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(паунд-футове сила),
						'one' => q({0} паунд-фут сила),
						'other' => q({0} паунд-фута сила),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(акър-футове),
						'one' => q({0} акър-фут),
						'other' => q({0} акър-фута),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(акър-футове),
						'one' => q({0} акър-фут),
						'other' => q({0} акър-фута),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(барели),
						'one' => q({0} барел),
						'other' => q({0} барела),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(барели),
						'one' => q({0} барел),
						'other' => q({0} барела),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} бушел),
						'other' => q({0} бушела),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} бушел),
						'other' => q({0} бушела),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(сентилитри),
						'one' => q({0} сентилитър),
						'other' => q({0} сентилитра),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(сентилитри),
						'one' => q({0} сентилитър),
						'other' => q({0} сентилитра),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(кубически сантиметри),
						'one' => q({0} кубически сантиметър),
						'other' => q({0} кубически сантиметра),
						'per' => q({0} на кубичен сантиметър),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(кубически сантиметри),
						'one' => q({0} кубически сантиметър),
						'other' => q({0} кубически сантиметра),
						'per' => q({0} на кубичен сантиметър),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(кубически футове),
						'one' => q({0} кубически фут),
						'other' => q({0} кубически фута),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(кубически футове),
						'one' => q({0} кубически фут),
						'other' => q({0} кубически фута),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(кубически инчове),
						'one' => q({0} кубически инч),
						'other' => q({0} кубически инча),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(кубически инчове),
						'one' => q({0} кубически инч),
						'other' => q({0} кубически инча),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(кубически километри),
						'one' => q({0} кубически километър),
						'other' => q({0} кубически километра),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(кубически километри),
						'one' => q({0} кубически километър),
						'other' => q({0} кубически километра),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(кубически метри),
						'one' => q({0} кубически метър),
						'other' => q({0} кубически метра),
						'per' => q({0} на кубичен метър),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(кубически метри),
						'one' => q({0} кубически метър),
						'other' => q({0} кубически метра),
						'per' => q({0} на кубичен метър),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(кубически мили),
						'one' => q({0} кубическа миля),
						'other' => q({0} кубически мили),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(кубически мили),
						'one' => q({0} кубическа миля),
						'other' => q({0} кубически мили),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(кубически ярдове),
						'one' => q({0} кубически ярд),
						'other' => q({0} кубически ярда),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(кубически ярдове),
						'one' => q({0} кубически ярд),
						'other' => q({0} кубически ярда),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(чаши),
						'one' => q({0} чаша),
						'other' => q({0} чаши),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(чаши),
						'one' => q({0} чаша),
						'other' => q({0} чаши),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(метрични чаши),
						'one' => q({0} метрична чаша),
						'other' => q({0} метрични чаши),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(метрични чаши),
						'one' => q({0} метрична чаша),
						'other' => q({0} метрични чаши),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(децилитри),
						'one' => q({0} децилитър),
						'other' => q({0} децилитра),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(децилитри),
						'one' => q({0} децилитър),
						'other' => q({0} децилитра),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(десертна лъжица),
						'one' => q({0} десертна лъжица),
						'other' => q({0} десертни лъжици),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(десертна лъжица),
						'one' => q({0} десертна лъжица),
						'other' => q({0} десертни лъжици),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(брит. дес. лъжици),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(брит. дес. лъжици),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(драм),
						'one' => q({0} драм),
						'other' => q({0} драма),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(драм),
						'one' => q({0} драм),
						'other' => q({0} драма),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(капки),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(капки),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(течни унции),
						'one' => q({0} течна унция),
						'other' => q({0} течни унции),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(течни унции),
						'one' => q({0} течна унция),
						'other' => q({0} течни унции),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(имперски течни унции),
						'one' => q({0} имперска течна унция),
						'other' => q({0} имперски течни унции),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(имперски течни унции),
						'one' => q({0} имперска течна унция),
						'other' => q({0} имперски течни унции),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(галони),
						'one' => q({0} галон),
						'other' => q({0} галона),
						'per' => q({0} на галон),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(галони),
						'one' => q({0} галон),
						'other' => q({0} галона),
						'per' => q({0} на галон),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(имперски галони),
						'one' => q({0} имперски галон),
						'other' => q({0} имперски галона),
						'per' => q({0} на имперски галон),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(имперски галони),
						'one' => q({0} имперски галон),
						'other' => q({0} имперски галона),
						'per' => q({0} на имперски галон),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(хектолитри),
						'one' => q({0} хектолитър),
						'other' => q({0} хектолитра),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(хектолитри),
						'one' => q({0} хектолитър),
						'other' => q({0} хектолитра),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(литри),
						'one' => q({0} литър),
						'other' => q({0} литра),
						'per' => q({0} на литър),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(литри),
						'one' => q({0} литър),
						'other' => q({0} литра),
						'per' => q({0} на литър),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(мегалитри),
						'one' => q({0} мегалитър),
						'other' => q({0} мегалитра),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(мегалитри),
						'one' => q({0} мегалитър),
						'other' => q({0} мегалитра),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(милилитри),
						'one' => q({0} милилитър),
						'other' => q({0} милилитра),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(милилитри),
						'one' => q({0} милилитър),
						'other' => q({0} милилитра),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(пинти),
						'one' => q({0} пинта),
						'other' => q({0} пинти),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(пинти),
						'one' => q({0} пинта),
						'other' => q({0} пинти),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(метрични пинти),
						'one' => q({0} метрична пинта),
						'other' => q({0} метрични пинти),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(метрични пинти),
						'one' => q({0} метрична пинта),
						'other' => q({0} метрични пинти),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(кварти),
						'one' => q({0} кварта),
						'other' => q({0} кварти),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(кварти),
						'one' => q({0} кварта),
						'other' => q({0} кварти),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(имперски кварти),
						'one' => q({0} имперска кварта),
						'other' => q({0} имперски кварти),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(имперски кварти),
						'one' => q({0} имперска кварта),
						'other' => q({0} имперски кварти),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(супени лъжици),
						'one' => q({0} супена лъжица),
						'other' => q({0} супени лъжици),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(супени лъжици),
						'one' => q({0} супена лъжица),
						'other' => q({0} супени лъжици),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(чаени лъжици),
						'one' => q({0} чаена лъжица),
						'other' => q({0} чаени лъжици),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(чаени лъжици),
						'one' => q({0} чаена лъжица),
						'other' => q({0} чаени лъжици),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(дъг. сек.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(дъг. сек.),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} кв. фут),
						'other' => q({0} кв. фута),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} кв. фут),
						'other' => q({0} кв. фута),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} кв. миля),
						'other' => q({0} кв. мили),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} кв. миля),
						'other' => q({0} кв. мили),
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
					'duration-day' => {
						'name' => q(д),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(д),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ч),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ч),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(мсек),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(мсек),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(мес.),
						'per' => q({0}/мес.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(мес.),
						'per' => q({0}/мес.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0} трим.),
						'other' => q({0} трим.),
						'per' => q({0}/трим.),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0} трим.),
						'other' => q({0} трим.),
						'per' => q({0}/трим.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(сек),
						'one' => q({0} с),
						'other' => q({0} с),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(сек),
						'one' => q({0} с),
						'other' => q({0} с),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(седм.),
						'per' => q({0}/седм.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(седм.),
						'per' => q({0}/седм.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(г.),
						'one' => q({0} г.),
						'other' => q({0} г.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(г.),
						'one' => q({0} г.),
						'other' => q({0} г.),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(точка),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(точка),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} фут),
						'other' => q({0} фута),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} фут),
						'other' => q({0} фута),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}"),
						'other' => q({0}"),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}"),
						'other' => q({0}"),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} миля),
						'other' => q({0} мили),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} миля),
						'other' => q({0} мили),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} ярд),
						'other' => q({0} ярда),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} унц.),
						'other' => q({0} унц.),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} унц.),
						'other' => q({0} унц.),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} фунт),
						'other' => q({0} фунта),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} фунт),
						'other' => q({0} фунта),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} к.с.),
						'other' => q({0} к.с.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} к.с.),
						'other' => q({0} к.с.),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q({0} по Б),
						'other' => q({0} по Б),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0} по Б),
						'other' => q({0} по Б),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} миля/ч),
						'other' => q({0} мили/ч),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} миля/ч),
						'other' => q({0} мили/ч),
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
					'volume-barrel' => {
						'name' => q(bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} куб. миля),
						'other' => q({0} куб. мили),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} куб. миля),
						'other' => q({0} куб. мили),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0} дес. лъж.),
						'other' => q({0} дес. лъж.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0} дес. лъж.),
						'other' => q({0} дес. лъж.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0} брит. дес. лъж.),
						'other' => q({0} брит. дес. лъж.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0} брит. дес. лъж.),
						'other' => q({0} брит. дес. лъж.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(посока),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(посока),
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
						'name' => q(дъгови мин.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(дъгови мин.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(дъгови сек.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(дъгови сек.),
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
					'angle-revolution' => {
						'name' => q(об.),
						'one' => q({0} об.),
						'other' => q({0} об.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(об.),
						'one' => q({0} об.),
						'other' => q({0} об.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(акри),
						'one' => q({0} акър),
						'other' => q({0} акра),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(акри),
						'one' => q({0} акър),
						'other' => q({0} акра),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(дюнюми),
						'one' => q({0} дюнюм),
						'other' => q({0} дюнюма),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(дюнюми),
						'one' => q({0} дюнюм),
						'other' => q({0} дюнюма),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(единица),
						'one' => q({0} ед.),
						'other' => q({0} ед.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(единица),
						'one' => q({0} ед.),
						'other' => q({0} ед.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(мол),
						'one' => q({0} мол),
						'other' => q({0} мол),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(мол),
						'one' => q({0} мол),
						'other' => q({0} мол),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(процент),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(процент),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(базисен пункт),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(базисен пункт),
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
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(мили/имп. гал.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(мили/имп. гал.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}И),
						'north' => q({0}С),
						'south' => q({0}Ю),
						'west' => q({0}З),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}И),
						'north' => q({0}С),
						'south' => q({0}Ю),
						'west' => q({0}З),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
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
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(в.),
						'one' => q({0} в.),
						'other' => q({0} в.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(в.),
						'one' => q({0} в.),
						'other' => q({0} в.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(дни),
						'one' => q({0} д),
						'other' => q({0} д),
						'per' => q({0}/д),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(дни),
						'one' => q({0} д),
						'other' => q({0} д),
						'per' => q({0}/д),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(декада),
						'one' => q({0} декада),
						'other' => q({0} декади),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(декада),
						'one' => q({0} декада),
						'other' => q({0} декади),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(часове),
						'one' => q({0} ч),
						'other' => q({0} ч),
						'per' => q({0}/ч),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(часове),
						'one' => q({0} ч),
						'other' => q({0} ч),
						'per' => q({0}/ч),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(милисекунди),
						'one' => q({0} мсек),
						'other' => q({0} мсек),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(милисекунди),
						'one' => q({0} мсек),
						'other' => q({0} мсек),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(мин),
						'one' => q({0} мин),
						'other' => q({0} мин),
						'per' => q({0}/мин),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(мин),
						'one' => q({0} мин),
						'other' => q({0} мин),
						'per' => q({0}/мин),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(месеци),
						'one' => q({0} мес.),
						'other' => q({0} мес.),
						'per' => q({0}/месец),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(месеци),
						'one' => q({0} мес.),
						'other' => q({0} мес.),
						'per' => q({0}/месец),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(тримес.),
						'one' => q({0} тримес.),
						'other' => q({0} тримес.),
						'per' => q({0}/тримес.),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(тримес.),
						'one' => q({0} тримес.),
						'other' => q({0} тримес.),
						'per' => q({0}/тримес.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(секунди),
						'one' => q({0} сек),
						'other' => q({0} сек),
						'per' => q({0}/сек),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(секунди),
						'one' => q({0} сек),
						'other' => q({0} сек),
						'per' => q({0}/сек),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(седмици),
						'one' => q({0} седм.),
						'other' => q({0} седм.),
						'per' => q({0}/седмица),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(седмици),
						'one' => q({0} седм.),
						'other' => q({0} седм.),
						'per' => q({0}/седмица),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(години),
						'one' => q({0} год.),
						'other' => q({0} год.),
						'per' => q({0}/год.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(години),
						'one' => q({0} год.),
						'other' => q({0} год.),
						'per' => q({0}/год.),
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
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
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
						'name' => q(амер. термални ед.),
						'one' => q({0} амер. терм. ед.),
						'other' => q({0} амер. терм. ед.),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(амер. термални ед.),
						'one' => q({0} амер. терм. ед.),
						'other' => q({0} амер. терм. ед.),
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
					'graphics-dot' => {
						'name' => q(точки),
						'one' => q({0} точка),
						'other' => q({0} точки),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(точки),
						'one' => q({0} точка),
						'other' => q({0} точки),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ем),
						'one' => q({0} ем),
						'other' => q({0} ем),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ем),
						'one' => q({0} ем),
						'other' => q({0} ем),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(AU),
						'one' => q({0} AU),
						'other' => q({0} AU),
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
					'length-light-year' => {
						'name' => q(св. г.),
						'one' => q({0} св.г.),
						'other' => q({0} св.г.),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(св. г.),
						'one' => q({0} св.г.),
						'other' => q({0} св.г.),
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
					'mass-dalton' => {
						'name' => q(далтони),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(далтони),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(гран),
						'one' => q({0} гран),
						'other' => q({0} грана),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(гран),
						'one' => q({0} гран),
						'other' => q({0} грана),
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
					'mass-ounce-troy' => {
						'name' => q(тр. унц.),
						'one' => q({0} тр. унц.),
						'other' => q({0} тр. унц.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(тр. унц.),
						'one' => q({0} тр. унц.),
						'other' => q({0} тр. унц.),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(стоун.),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(стоун.),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(к. с.),
						'one' => q({0} к. с.),
						'other' => q({0} к. с.),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(к. с.),
						'one' => q({0} к. с.),
						'other' => q({0} к. с.),
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
					'speed-beaufort' => {
						'one' => q({0} по Bft),
						'other' => q({0} по Bft),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q({0} по Bft),
						'other' => q({0} по Bft),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(барел),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(барел),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(бушели),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(бушели),
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
						'name' => q(ч.),
						'one' => q({0} ч.),
						'other' => q({0} ч.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ч.),
						'one' => q({0} ч.),
						'other' => q({0} ч.),
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
						'name' => q(дес. лъжица),
						'one' => q({0} дес. лъжица),
						'other' => q({0} дес. лъжици),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(дес. лъжица),
						'one' => q({0} дес. лъжица),
						'other' => q({0} дес. лъжици),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(брит. дес. лъжица),
						'one' => q({0} брит. дес. лъжица),
						'other' => q({0} брит. дес. лъжици),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(брит. дес. лъжица),
						'one' => q({0} брит. дес. лъжица),
						'other' => q({0} брит. дес. лъжици),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(течен драм),
						'one' => q({0} теч. драм),
						'other' => q({0} теч. драма),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(течен драм),
						'one' => q({0} теч. драм),
						'other' => q({0} теч. драма),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(капка),
						'one' => q({0} капка),
						'other' => q({0} капки),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(капка),
						'one' => q({0} капка),
						'other' => q({0} капки),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(имп. галон),
						'one' => q({0} имп. галон),
						'other' => q({0} имп. галона),
						'per' => q({0}/имп. галон),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(имп. галон),
						'one' => q({0} имп. галон),
						'other' => q({0} имп. галона),
						'per' => q({0}/имп. галон),
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
						'name' => q(джигър),
						'one' => q({0} джигър),
						'other' => q({0} джигъра),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(джигър),
						'one' => q({0} джигър),
						'other' => q({0} джигъра),
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
						'name' => q(щипка),
						'one' => q({0} щипка),
						'other' => q({0} щипки),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(щипка),
						'one' => q({0} щипка),
						'other' => q({0} щипки),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(имп. кварта),
						'one' => q({0} имп. кварта),
						'other' => q({0} имп. кварти),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(имп. кварта),
						'one' => q({0} имп. кварта),
						'other' => q({0} имп. кварти),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(с. л.),
						'one' => q({0} с. л.),
						'other' => q({0} с. л.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(с. л.),
						'one' => q({0} с. л.),
						'other' => q({0} с. л.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ч. л.),
						'one' => q({0} ч. л.),
						'other' => q({0} ч. л.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ч. л.),
						'one' => q({0} ч. л.),
						'other' => q({0} ч. л.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:да|д|yes|y)$' }
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
				end => q({0} и {1}),
				2 => q({0} и {1}),
		} }
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
				'1000' => {
					'one' => '0 хил'.'',
					'other' => '0 хиляди',
				},
				'10000' => {
					'one' => '00 хиляди',
					'other' => '00 хиляди',
				},
				'100000' => {
					'one' => '000 хиляди',
					'other' => '000 хиляди',
				},
				'1000000' => {
					'one' => '0 милион',
					'other' => '0 милиона',
				},
				'10000000' => {
					'one' => '00 милиона',
					'other' => '00 милиона',
				},
				'100000000' => {
					'one' => '000 милиона',
					'other' => '000 милиона',
				},
				'1000000000' => {
					'one' => '0 милиард',
					'other' => '0 милиарда',
				},
				'10000000000' => {
					'one' => '00 милиарда',
					'other' => '00 милиарда',
				},
				'100000000000' => {
					'one' => '000 милиарда',
					'other' => '000 милиарда',
				},
				'1000000000000' => {
					'one' => '0 трилион',
					'other' => '0 трилиона',
				},
				'10000000000000' => {
					'one' => '00 трилиона',
					'other' => '00 трилиона',
				},
				'100000000000000' => {
					'one' => '000 трилиона',
					'other' => '000 трилиона',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 хил'.'',
					'other' => '0 хил'.'',
				},
				'10000' => {
					'one' => '00 хил'.'',
					'other' => '00 хил'.'',
				},
				'100000' => {
					'one' => '000 хил'.'',
					'other' => '000 хил'.'',
				},
				'1000000' => {
					'one' => '0 млн'.'',
					'other' => '0 млн'.'',
				},
				'10000000' => {
					'one' => '00 млн'.'',
					'other' => '00 млн'.'',
				},
				'100000000' => {
					'one' => '000 млн'.'',
					'other' => '000 млн'.'',
				},
				'1000000000' => {
					'one' => '0 млрд'.'',
					'other' => '0 млрд'.'',
				},
				'10000000000' => {
					'one' => '00 млрд'.'',
					'other' => '00 млрд'.'',
				},
				'100000000000' => {
					'one' => '000 млрд'.'',
					'other' => '000 млрд'.'',
				},
				'1000000000000' => {
					'one' => '0 трлн'.'',
					'other' => '0 трлн'.'',
				},
				'10000000000000' => {
					'one' => '00 трлн'.'',
					'other' => '00 трлн'.'',
				},
				'100000000000000' => {
					'one' => '000 трлн'.'',
					'other' => '000 трлн'.'',
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
				'currency' => q(Андорска песета),
				'one' => q(андорска песета),
				'other' => q(андорски песети),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Дирхам на Обединените арабски емирства),
				'one' => q(дирхам на Обединените арабски емирства),
				'other' => q(дирхама на Обединените арабски емирства),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Афганистански афган \(1927–2002\)),
				'one' => q(афганистански афган \(1927–2002\)),
				'other' => q(афганистански афгана \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'Af',
			display_name => {
				'currency' => q(Афганистански афган),
				'one' => q(афганистански афган),
				'other' => q(афганистански афгана),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Албански лек),
				'one' => q(албански лек),
				'other' => q(албански лека),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Арменски драм),
				'one' => q(арменски драм),
				'other' => q(арменски драма),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Антилски гулден),
				'one' => q(антилски гулден),
				'other' => q(антилски гулдена),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Анголска кванза),
				'one' => q(анголска кванза),
				'other' => q(анголски кванзи),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Анголска кванца \(1977–1990\)),
				'one' => q(анголска кванца \(1977–1991\)),
				'other' => q(анголски кванци \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Анголска нова кванца \(1990–2000\)),
				'one' => q(анголска нова кванца \(1990–2000\)),
				'other' => q(анголски нови кванци \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Анголска нова кванца \(1995–1999\)),
				'one' => q(анголска нова кванца \(1995–1999\)),
				'other' => q(анголски нови кванци \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Аржентински австрал),
				'one' => q(аржентински австрал),
				'other' => q(аржентински австрала),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Аржентинско песо \(1983–1985\)),
				'one' => q(аржентинско песо \(1983–1985\)),
				'other' => q(аржентински песо \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Аржентинско песо),
				'one' => q(аржентинско песо),
				'other' => q(аржентински песо),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Австрийски шилинг),
				'one' => q(австрийски шилинг),
				'other' => q(австрийски шилинга),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(Австралийски долар),
				'one' => q(австралийски долар),
				'other' => q(австралийски долара),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Арубски флорин),
				'one' => q(арубски флорин),
				'other' => q(арубски флорина),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Азербайджански манат \(1993–2006\)),
				'one' => q(азербайджански манат \(1993–2006\)),
				'other' => q(азербайджански маната \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Азербайджански манат),
				'one' => q(азербайджански манат),
				'other' => q(азербайджански маната),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Босна и Херцеговина-динар),
				'one' => q(Босна и Херцеговина-динар),
				'other' => q(Босна и Херцеговина-динара),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Босненска конвертируема марка),
				'one' => q(босненска конвертируема марка),
				'other' => q(босненски конвертируеми марки),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Барбадоски долар),
				'one' => q(барбадоски долар),
				'other' => q(барбадоски долара),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Бангладешка така),
				'one' => q(бангладешка така),
				'other' => q(бангладешки таки),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Белгийски франк \(конвертируем\)),
				'one' => q(белгийски франк \(конвертируем\)),
				'other' => q(белгийски франка \(конвертируеми\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Белгийски франк),
				'one' => q(белгийски франк),
				'other' => q(белгийски франка),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Белгийски франк \(финансов\)),
				'one' => q(белгийски франк \(финансов\)),
				'other' => q(белгийски франка \(финансови\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Български конвертируем лев \(1962–1999\)),
				'one' => q(български конвертируем лев),
				'other' => q(български конвертируеми лева),
			},
		},
		'BGN' => {
			symbol => 'лв.',
			display_name => {
				'currency' => q(Български лев),
				'one' => q(български лев),
				'other' => q(български лева),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Бахрейнски динар),
				'one' => q(бахрейнски динар),
				'other' => q(бахрейнски динара),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Бурундийски франк),
				'one' => q(бурундийски франк),
				'other' => q(бурундийски франка),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Бермудски долар),
				'one' => q(бермудски долар),
				'other' => q(бермудски долара),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Брунейски долар),
				'one' => q(брунейски долар),
				'other' => q(брунейски долара),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Боливийско боливиано),
				'one' => q(боливийско боливиано),
				'other' => q(боливийски боливиано),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Боливийско песо),
				'one' => q(боливийско песо),
				'other' => q(боливийски песо),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Боливийски мвдол),
				'one' => q(боливийски мвдол),
				'other' => q(боливийски мвдол),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Бразилско ново крузейро \(1967–1986\)),
				'one' => q(бразилско ново крузейро \(1967–1986\)),
				'other' => q(бразилско ново крузейро \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Бразилско крозадо),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Бразилско крузейро \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(Бразилски реал),
				'one' => q(бразилски реал),
				'other' => q(бразилски реала),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Бразилско ново крозадо),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Бразилско крузейро),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Бахамски долар),
				'one' => q(бахамски долар),
				'other' => q(бахамски долара),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Бутански нгултрум),
				'one' => q(бутански нгултрум),
				'other' => q(бутански нгултрума),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Бирмански киат),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Ботсванска пула),
				'one' => q(ботсванска пула),
				'other' => q(ботсвански пули),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Беларуска нова рубла \(1994–1999\)),
				'one' => q(беларуска нова рубла \(1994–1999\)),
				'other' => q(беларуски нови рубли \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Беларуска рубла),
				'one' => q(беларуска рубла),
				'other' => q(беларуски рубли),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Беларуска рубла \(2000–2016\)),
				'one' => q(беларуска рубла \(2000–2016\)),
				'other' => q(беларуски рубли \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Белизийски долар),
				'one' => q(белизийски долар),
				'other' => q(белизийски долара),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(Канадски долар),
				'one' => q(канадски долар),
				'other' => q(канадски долара),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Конгоански франк),
				'one' => q(конгоански франк),
				'other' => q(конгоански франка),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR евро),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Швейцарски франк),
				'one' => q(швейцарски франк),
				'other' => q(швейцарски франка),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR франк),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Условна разчетна единица на Чили),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Чилийско песо),
				'one' => q(чилийско песо),
				'other' => q(чилийски песо),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Китайски юан \(офшорен\)),
				'one' => q(китайски юан \(офшорен\)),
				'other' => q(китайски юана \(офшорни\)),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(Китайски юан),
				'one' => q(китайски юан),
				'other' => q(китайски юана),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Колумбийско песо),
				'one' => q(колумбийско песо),
				'other' => q(колумбийски песо),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Колумбийска единица на реалната стойност),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Костарикански колон),
				'one' => q(костарикански колон),
				'other' => q(костарикански колона),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Стар сръбски динар),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Чехословашка конвертируема крона),
				'one' => q(чехословашка конвертируема крона),
				'other' => q(чехословашки конвертируеми крони),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Кубинско конвертируемо песо),
				'one' => q(кубинско конвертируемо песо),
				'other' => q(кубински конвертируеми песо),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Кубинско песо),
				'one' => q(кубинско песо),
				'other' => q(кубински песо),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Ескудо на Кабо Верде),
				'one' => q(ескудо на Кабо Верде),
				'other' => q(ескудо на Кабо Верде),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Кипърска лира),
				'one' => q(кипърска лира),
				'other' => q(кипърски лири),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Чешка крона),
				'one' => q(чешка крона),
				'other' => q(чешки крони),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Източногерманска марка),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Германска марка),
				'one' => q(германска марка),
				'other' => q(германски марки),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Джибутски франк),
				'one' => q(джибутски франк),
				'other' => q(джибутски франка),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Датска крона),
				'one' => q(датска крона),
				'other' => q(датски крони),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Доминиканско песо),
				'one' => q(доминиканско песо),
				'other' => q(доминикански песо),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Алжирски динар),
				'one' => q(алжирски динар),
				'other' => q(алжирски динара),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Еквадорско сукре),
				'one' => q(еквадорско сукре),
				'other' => q(еквадорско сукре),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Еквадорска банкова единица),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Естонска крона),
				'one' => q(естонска крона),
				'other' => q(естонски крони),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Египетска лира),
				'one' => q(египетска лира),
				'other' => q(египетски лири),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Еритрейска накфа),
				'one' => q(еритрейска накфа),
				'other' => q(еритрейски накфи),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Испанска песета),
				'one' => q(испанска песета),
				'other' => q(испански песети),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Етиопски бир),
				'one' => q(етиопски бир),
				'other' => q(етиопски бира),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Евро),
				'one' => q(евро),
				'other' => q(евро),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Финландска марка),
				'one' => q(финландска марка),
				'other' => q(финландски марки),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Фиджийски долар),
				'one' => q(фиджийски долар),
				'other' => q(фиджийски долара),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Фолкландска лира),
				'one' => q(фолкландска лира),
				'other' => q(фолкландски лири),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Френски франк),
				'one' => q(френски франк),
				'other' => q(френски франка),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(Британска лира),
				'one' => q(британска лира),
				'other' => q(британски лири),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Грузински купон),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Грузински лари),
				'one' => q(грузински лари),
				'other' => q(грузински лари),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ганайско седи \(1979–2007\)),
				'one' => q(ганайско седи \(1979–2007\)),
				'other' => q(ганайски седи \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ганайско седи),
				'one' => q(ганайско седи),
				'other' => q(ганайски седи),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Гибралтарска лира),
				'one' => q(гибралтарска лира),
				'other' => q(гибралтарски лири),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Гамбийско даласи),
				'one' => q(гамбийско даласи),
				'other' => q(гамбийски даласи),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Гвинейски франк),
				'one' => q(гвинейски франк),
				'other' => q(гвинейски франка),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Гвинейска сили),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Екваториално гвинейско еквеле),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Гръцка драхма),
				'one' => q(гръцка драхма),
				'other' => q(гръцки драхми),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Гватемалски кетцал),
				'one' => q(гватемалски кетцал),
				'other' => q(гватемалски кетцала),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Ескудо от Португалска Гвинея),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Гвинея-Бисау песо),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Гаянски долар),
				'one' => q(гаянски долар),
				'other' => q(гаянски долара),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Хонконгски долар),
				'one' => q(хонконгски долар),
				'other' => q(хонконгски долара),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Хондураска лемпира),
				'one' => q(хондураска лемпира),
				'other' => q(хондураски лемпири),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Хърватски динар),
				'one' => q(хърватски динар),
				'other' => q(хърватски динара),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Хърватска куна),
				'one' => q(хърватска куна),
				'other' => q(хърватски куни),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Хаитски гурд),
				'one' => q(хаитски гурд),
				'other' => q(хаитски гурда),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Унгарски форинт),
				'one' => q(унгарски форинт),
				'other' => q(унгарски форинта),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Индонезийска рупия),
				'one' => q(индонезийска рупия),
				'other' => q(индонезийски рупии),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Ирландска лира),
				'one' => q(ирландска лира),
				'other' => q(ирландски лири),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Израелска лира),
				'one' => q(израелска лира),
				'other' => q(израелски лири),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(Израелски нов шекел),
				'one' => q(израелски нов шекел),
				'other' => q(израелски нови шекела),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(Индийска рупия),
				'one' => q(индийска рупия),
				'other' => q(индийски рупии),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Иракски динар),
				'one' => q(иракски динар),
				'other' => q(иракски динара),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Ирански риал),
				'one' => q(ирански риал),
				'other' => q(ирански риала),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Исландска крона),
				'one' => q(исландска крона),
				'other' => q(исландски крони),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Италианска лира),
				'one' => q(италианска лира),
				'other' => q(италиански лири),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Ямайски долар),
				'one' => q(ямайски долар),
				'other' => q(ямайски долара),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Йордански динар),
				'one' => q(йордански динар),
				'other' => q(йордански динара),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(Японска йена),
				'one' => q(японска йена),
				'other' => q(японски йени),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Кенийски шилинг),
				'one' => q(кенийски шилинг),
				'other' => q(кенийски шилинга),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Киргизстански сом),
				'one' => q(киргизстански сом),
				'other' => q(киргизстански сома),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Камбоджански риел),
				'one' => q(камбоджански риел),
				'other' => q(камбоджански риела),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Коморски франк),
				'one' => q(коморски франк),
				'other' => q(коморски франка),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Севернокорейски вон),
				'one' => q(севернокорейски вон),
				'other' => q(севернокорейски вона),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(Южнокорейски вон),
				'one' => q(южнокорейски вон),
				'other' => q(южнокорейски вона),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Кувейтски динар),
				'one' => q(кувейтски динар),
				'other' => q(кувейтски динара),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Кайманов долар),
				'one' => q(кайманов долар),
				'other' => q(кайманови долара),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Казахстанско тенге),
				'one' => q(казахстанско тенге),
				'other' => q(казахстански тенге),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Лаоски кип),
				'one' => q(лаоски кип),
				'other' => q(лаоски кипа),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Ливанска лира),
				'one' => q(ливанска лира),
				'other' => q(ливански лири),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Шриланкска рупия),
				'one' => q(шриланкска рупия),
				'other' => q(шриланкски рупии),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Либерийски долар),
				'one' => q(либерийски долар),
				'other' => q(либерийски долара),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Лесотско лоти),
				'one' => q(лесотско лоти),
				'other' => q(лесотски лоти),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Литовски литас),
				'one' => q(литовски литас),
				'other' => q(литовски литаса),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Литовски талон),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Люксембургски франк),
				'one' => q(люксембургски франк),
				'other' => q(люксембургски франка),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Латвийски лат),
				'one' => q(латвийски лат),
				'other' => q(латвийски лата),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Латвийска рубла),
				'one' => q(латвийска рубла),
				'other' => q(латвийски рубли),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Либийски динар),
				'one' => q(либийски динар),
				'other' => q(либийски динара),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Марокански дирхам),
				'one' => q(марокански дирхам),
				'other' => q(марокански дирхама),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Марокански франк),
				'one' => q(марокански франк),
				'other' => q(марокански франка),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Молдовска лея),
				'one' => q(молдовска лея),
				'other' => q(молдовски леи),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Малгашко ариари),
				'one' => q(малгашко ариари),
				'other' => q(малгашки ариари),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Малгашки франк - Мадагаскар),
				'one' => q(малгашки франк - Мадагаскар),
				'other' => q(малгашки франка - Мадагаскар),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Македонски денар),
				'one' => q(македонски денар),
				'other' => q(македонски денара),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Малийски франк),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Мианмарски киат),
				'one' => q(мианмарски киат),
				'other' => q(мианмарски киата),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Монголски тугрик),
				'one' => q(монголски тугрик),
				'other' => q(монголски тугрика),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Патака на Макао),
				'one' => q(патака на Макао),
				'other' => q(патаки на Макао),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Мавританска угия \(1973–2017\)),
				'one' => q(мавританска угия \(1973–2017\)),
				'other' => q(мавритански угии \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Мавританска угия),
				'one' => q(мавританска угия),
				'other' => q(мавритански угии),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Малтийска лира),
				'one' => q(малтийска лира),
				'other' => q(малтийски лири),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Маврицийска рупия),
				'one' => q(маврицийска рупия),
				'other' => q(маврицийски рупии),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Малдивска руфия),
				'one' => q(малдивска руфия),
				'other' => q(малдивски руфии),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Малавийска куача),
				'one' => q(малавийска куача),
				'other' => q(малавийски куачи),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(Мексиканско песо),
				'one' => q(мексиканско песо),
				'other' => q(мексикански песо),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Мексиканско сребърно песо \(1861–1992\)),
				'one' => q(мексиканско сребърно песо \(1861–1992\)),
				'other' => q(мексикански сребърни песо \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Мексиканска конвертируема единица \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Малайзийски рингит),
				'one' => q(малайзийски рингит),
				'other' => q(малайзийски рингита),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Мозамбикско ескудо),
				'one' => q(мозамбикско ескудо),
				'other' => q(мозамбикски ескудо),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Мозамбикски метикал \(1980–2006\)),
				'one' => q(мозамбикски метикал \(1980–2006\)),
				'other' => q(мозамбикски метикала \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Мозамбикски метикал),
				'one' => q(мозамбикски метикал),
				'other' => q(мозамбикски метикала),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Намибийски долар),
				'one' => q(намибийски долар),
				'other' => q(намибийски долара),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Нигерийска найра),
				'one' => q(нигерийска найра),
				'other' => q(нигерийски найри),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Никарагуанска кордоба \(1988–1991\)),
				'one' => q(никарагуанска кордоба \(1988–1991\)),
				'other' => q(никарагуански кордоби \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Никарагуанска кордоба),
				'one' => q(никарагуанска кордоба),
				'other' => q(никарагуански кордоби),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Холандски гулден),
				'one' => q(холандски гулден),
				'other' => q(холандски гулдена),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Норвежка крона),
				'one' => q(норвежка крона),
				'other' => q(норвежки крони),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Непалска рупия),
				'one' => q(непалска рупия),
				'other' => q(непалски рупии),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(Новозеландски долар),
				'one' => q(новозеландски долар),
				'other' => q(новозеландски долара),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Омански риал),
				'one' => q(омански риал),
				'other' => q(омански риала),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Панамска балбоа),
				'one' => q(панамска балбоа),
				'other' => q(панамски балбоа),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Перуанско инти),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Перуански сол),
				'one' => q(перуански сол),
				'other' => q(перуански сола),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Перуански сол \(1863–1965\)),
				'one' => q(перуански сол \(1863–1965\)),
				'other' => q(перуански сол \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Папуа-новогвинейска кина),
				'one' => q(папуа-новогвинейска кина),
				'other' => q(папуа-новогвинейски кини),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Филипинско песо),
				'one' => q(филипинско песо),
				'other' => q(филипински песо),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Пакистанска рупия),
				'one' => q(пакистанска рупия),
				'other' => q(пакистански рупии),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Полска злота),
				'one' => q(полска злота),
				'other' => q(полски злоти),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Полска злота \(1950–1995\)),
				'one' => q(полска злота \(1950–1995\)),
				'other' => q(полски злоти \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Португалско ескудо),
				'one' => q(португалско ескудо),
				'other' => q(португалски ескудо),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Парагвайско гуарани),
				'one' => q(парагвайско гуарани),
				'other' => q(парагвайски гуарани),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Катарски риал),
				'one' => q(катарски риал),
				'other' => q(катарски риала),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Родезийски долар),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Стара румънска лея),
				'one' => q(стара румънска лея),
				'other' => q(стари румънски леи),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Румънска лея),
				'one' => q(румънска лея),
				'other' => q(румънски леи),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Сръбски динар),
				'one' => q(сръбски динар),
				'other' => q(сръбски динара),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Руска рубла),
				'one' => q(руска рубла),
				'other' => q(руски рубли),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Руска рубла \(1991–1998\)),
				'one' => q(руска рубла \(1991–1998\)),
				'other' => q(руски рубли \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Руандски франк),
				'one' => q(руандски франк),
				'other' => q(руандски франка),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(саудитски риал),
				'one' => q(саудитски риал),
				'other' => q(саудитски риала),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Долар на Соломоновите острови),
				'one' => q(долар на Соломоновите острови),
				'other' => q(долара на Соломоновите острови),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Сейшелска рупия),
				'one' => q(сейшелска рупия),
				'other' => q(сейшелски рупии),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Судански динар),
				'one' => q(судански динар),
				'other' => q(судански динара),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Суданска лира),
				'one' => q(суданска лира),
				'other' => q(судански лири),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Шведска крона),
				'one' => q(шведска крона),
				'other' => q(шведски крони),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Сингапурски долар),
				'one' => q(сингапурски долар),
				'other' => q(сингапурски долара),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Лира на Света Елена),
				'one' => q(лира на Света Елена),
				'other' => q(лири на Света Елена),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Словенски толар),
				'one' => q(словенски толар),
				'other' => q(словенски толара),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Словашка крона),
				'one' => q(словашка крона),
				'other' => q(словашки крони),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Сиералеонско леоне),
				'one' => q(сиералеонско леоне),
				'other' => q(сиералеонски леоне),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Сиералеонско леоне \(1964—2022\)),
				'one' => q(сиералеонско леоне \(1964—2022\)),
				'other' => q(сиералеонски леоне \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Сомалийски шилинг),
				'one' => q(сомалийски шилинг),
				'other' => q(сомалийски шилинга),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Суринамски долар),
				'one' => q(суринамски долар),
				'other' => q(суринамски долара),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Суринамски гилдер),
				'one' => q(суринамски гилдер),
				'other' => q(суринамски гилдера),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Южносуданска лира),
				'one' => q(южносуданска лира),
				'other' => q(южносудански лири),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Добра на Сао Томе и Принсипи \(1977–2017\)),
				'one' => q(добра на Сао Томе и Принсипи \(1977–2017\)),
				'other' => q(добра на Сао Томе и Принсипи \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Добра на Сао Томе и Принсипи),
				'one' => q(добра на Сао Томе и Принсипи),
				'other' => q(добра на Сао Томе и Принсипи),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Съветска рубла),
				'one' => q(съветска рубла),
				'other' => q(съветски рубли),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Салвадорски колон),
				'one' => q(салвадорски колон),
				'other' => q(салвадорски колона),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Сирийска лира),
				'one' => q(сирийска лира),
				'other' => q(сирийски лири),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Свазилендски лилангени),
				'one' => q(свазилендски лилангени),
				'other' => q(свазилендски лилангени),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Тайландски бат),
				'one' => q(тайландски бат),
				'other' => q(тайландски бата),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Таджикистанска рубла),
				'one' => q(таджикистанска рубла),
				'other' => q(таджикистански рубли),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Таджикистански сомони),
				'one' => q(таджикистански сомони),
				'other' => q(таджикистански сомони),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Туркменистански манат),
				'one' => q(туркменистански манат),
				'other' => q(туркменистански маната),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Туркменски манат),
				'one' => q(туркменски манат),
				'other' => q(туркменски маната),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Тунизийски динар),
				'one' => q(тунизийски динар),
				'other' => q(тунизийски динара),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Тонганска паанга),
				'one' => q(тонганска паанга),
				'other' => q(тонгански паанги),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Тиморско ескудо),
				'one' => q(тиморско ескудо),
				'other' => q(тиморски ескудо),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Турска лира \(1922–2005\)),
				'one' => q(турска лира \(1922–2005\)),
				'other' => q(турски лири \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Турска лира),
				'one' => q(турска лира),
				'other' => q(турски лири),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Долар на Тринидад и Тобаго),
				'one' => q(долар на Тринидад и Тобаго),
				'other' => q(долара на Тринидад и Тобаго),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(Тайвански долар),
				'one' => q(тайвански долар),
				'other' => q(тайвански долара),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Танзанийски шилинг),
				'one' => q(танзанийски шилинг),
				'other' => q(танзанийски шилинга),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Украинска гривня),
				'one' => q(украинска гривня),
				'other' => q(украински гривни),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Украински карбованец),
				'one' => q(украински карбованец),
				'other' => q(украински карбованеца),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Угандийски шилинг \(1966–1987\)),
				'one' => q(угандийски шилинг \(1966–1987\)),
				'other' => q(угандийски шилинга \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Угандски шилинг),
				'one' => q(угандски шилинг),
				'other' => q(угандски шилинга),
			},
		},
		'USD' => {
			symbol => 'щ.д.',
			display_name => {
				'currency' => q(Щатски долар),
				'one' => q(щатски долар),
				'other' => q(щатски долара),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Уругвайско песо \(индекс на инфлацията\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Уругвайско песо \(1975–1993\)),
				'one' => q(уругвайско песо \(1975–1993\)),
				'other' => q(уругвайски песо \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Уругвайско песо),
				'one' => q(уругвайско песо),
				'other' => q(уругвайски песо),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Узбекски сум),
				'one' => q(узбекски сум),
				'other' => q(узбекски сума),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Венецуелски боливар \(1871–2008\)),
				'one' => q(венецуелски боливар \(1871–2008\)),
				'other' => q(венецуелски боливара \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Венецуелски боливар),
				'one' => q(венецуелски боливар),
				'other' => q(венецуелски боливара),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Венецуелски боливар \(VES\)),
				'one' => q(венецуелски боливар \(VES\)),
				'other' => q(венецуелски боливара \(VES\)),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(Виетнамски донг),
				'one' => q(виетнамски донг),
				'other' => q(виетнамски донга),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Вануатско вату),
				'one' => q(вануатско вату),
				'other' => q(вануатски вату),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Самоанска тала),
				'one' => q(самоанска тала),
				'other' => q(самоански тали),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Централноафрикански франк),
				'one' => q(централноафрикански франк),
				'other' => q(централноафрикански франка),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Сребро),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Злато),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Европейска съставна единица),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Европейска валутна единица),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Европейска единица по сметка \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Европейска единица по сметка \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(Източнокарибски долар),
				'one' => q(източнокарибски долар),
				'other' => q(източнокарибски долара),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Специални права на тираж),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Еку на ЕИО),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Френски златен франк),
				'one' => q(френски златен франк),
				'other' => q(френски златна франка),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Западноафрикански франк),
				'one' => q(западноафрикански франк),
				'other' => q(западноафрикански франка),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Паладий),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP франк),
				'one' => q(CFP франк),
				'other' => q(CFP франка),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Платина),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Код резервиран за целите на тестване),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Непозната валута),
				'one' => q(\(непозната валута\)),
				'other' => q(\(непозната валута\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Йеменски динар),
				'one' => q(йеменски динар),
				'other' => q(йеменски динара),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Йеменски риал),
				'one' => q(йеменски риал),
				'other' => q(йеменски риала),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Югославски твърд динар),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Югославски динар),
				'one' => q(югославски динар),
				'other' => q(югославски динара),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Югославски конвертируем динар),
				'one' => q(югославски конвертируем динар),
				'other' => q(югославски конвертируеми динара),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Южноафрикански ранд \(финансов\)),
				'one' => q(южноафрикански ранд \(финансов\)),
				'other' => q(южноафрикански ранда \(финансови\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Южноафрикански ранд),
				'one' => q(южноафрикански ранд),
				'other' => q(южноафрикански ранда),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Замбийска квача \(1968–2012\)),
				'one' => q(замбийска квача \(1968–2012\)),
				'other' => q(замбийски квачи \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Замбийска куача),
				'one' => q(замбийска куача),
				'other' => q(замбийски куачи),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Заирско ново зайре),
				'one' => q(заирско ново зайре),
				'other' => q(заирски нови зайре),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Заирско зайре),
				'one' => q(заирско зайре),
				'other' => q(заирски зайре),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Зимбабвийски долар),
				'one' => q(зимбабвийски долар),
				'other' => q(зимбабвийски долара),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Зимбабвийски долар \(2009\)),
				'one' => q(зимбабвийски долар \(2009\)),
				'other' => q(зимбабвийски долара \(2009\)),
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
							'яну',
							'фев',
							'март',
							'апр',
							'май',
							'юни',
							'юли',
							'авг',
							'сеп',
							'окт',
							'ное',
							'дек'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'януари',
							'февруари',
							'март',
							'април',
							'май',
							'юни',
							'юли',
							'август',
							'септември',
							'октомври',
							'ноември',
							'декември'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'я',
							'ф',
							'м',
							'а',
							'м',
							'ю',
							'ю',
							'а',
							'с',
							'о',
							'н',
							'д'
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
							'тишри',
							'хешван',
							'кислев',
							'тебет',
							'шебат',
							'адар I',
							'адар',
							'нисан',
							'иар',
							'сиван',
							'тамуз',
							'ав',
							'елул'
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
							'чайтра',
							'вайсакха',
							'джаинтха',
							'асадха',
							'сравана',
							'бхада',
							'азвина',
							'картика',
							'аграхайана',
							'пауза',
							'магха',
							'пхалгуна'
						],
						leap => [
							
						],
					},
				},
			},
			'islamic' => {
				'format' => {
					wide => {
						nonleap => [
							'мухарам',
							'сафар',
							'раби-1',
							'раби-2',
							'джумада-1',
							'джумада-2',
							'раджаб',
							'шабан',
							'рамазан',
							'Шавал',
							'Дхул-Каада',
							'Дхул-хиджа'
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
						tue => 'вт',
						wed => 'ср',
						thu => 'чт',
						fri => 'пт',
						sat => 'сб',
						sun => 'нд'
					},
					wide => {
						mon => 'понеделник',
						tue => 'вторник',
						wed => 'сряда',
						thu => 'четвъртък',
						fri => 'петък',
						sat => 'събота',
						sun => 'неделя'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'п',
						tue => 'в',
						wed => 'с',
						thu => 'ч',
						fri => 'п',
						sat => 'с',
						sun => 'н'
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
					abbreviated => {0 => '1. трим.',
						1 => '2. трим.',
						2 => '3. трим.',
						3 => '4. трим.'
					},
					wide => {0 => '1. тримесечие',
						1 => '2. тримесечие',
						2 => '3. тримесечие',
						3 => '4. тримесечие'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1400
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 1100;
					return 'morning2' if $time >= 1100
						&& $time < 1400;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
					'afternoon1' => q{следобед},
					'am' => q{am},
					'evening1' => q{вечерта},
					'midnight' => q{полунощ},
					'morning1' => q{сутринта},
					'morning2' => q{на обяд},
					'night1' => q{през нощта},
					'pm' => q{pm},
				},
				'wide' => {
					'am' => q{пр.об.},
					'pm' => q{сл.об.},
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
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'пр.Хр.',
				'1' => 'сл.Хр.'
			},
			wide => {
				'0' => 'преди Христа',
				'1' => 'след Христа'
			},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{EEEE, d MMMM y 'г'. G},
			'long' => q{d MMMM y 'г'. G},
			'medium' => q{d.MM.y 'г'. G},
			'short' => q{d.MM.yy G},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y 'г'.},
			'long' => q{d MMMM y 'г'.},
			'medium' => q{d.MM.y 'г'.},
			'short' => q{d.MM.yy 'г'.},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
			'full' => q{H:mm:ss 'ч'. zzzz},
			'long' => q{H:mm:ss 'ч'. z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{h 'ч'. B},
			Bhm => q{h:mm 'ч'. B},
			Bhms => q{h:mm:ss 'ч'. B},
			EBhm => q{E, h:mm 'ч'. B},
			EBhms => q{E, h:mm:ss 'ч'. B},
			EHm => q{E, HH:mm 'ч'.},
			EHms => q{E, HH:mm:ss 'ч'.},
			Ed => q{E, d},
			Ehm => q{E, h:mm 'ч'. a},
			Ehms => q{E, h:mm:ss 'ч'. a},
			Gy => q{y 'г'. G},
			GyMMM => q{MM.y 'г'. G},
			GyMMMEd => q{E, d.MM.y 'г'. G},
			GyMMMM => q{MMMM y 'г'. G},
			GyMMMMEd => q{E, d MMMM y 'г'. G},
			GyMMMMd => q{d MMMM y 'г'. G},
			GyMMMd => q{d.MM.y 'г'. G},
			GyMd => q{dd.MM.y 'г'. GGGGG},
			H => q{HH 'ч'.},
			Hm => q{HH:mm 'ч'.},
			Hms => q{HH:mm:ss 'ч'.},
			M => q{M},
			MEd => q{E, d.MM},
			MMM => q{MM},
			MMMEd => q{E, d.MM},
			MMMM => q{LLLL},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d.MM},
			Md => q{d.MM},
			h => q{h 'ч'. a},
			hm => q{h:mm 'ч'. a},
			hms => q{h:mm:ss 'ч'. a},
			y => q{y 'г'. G},
			yyyy => q{y 'г'. G},
			yyyyM => q{M.y 'г'. G},
			yyyyMEd => q{E, d.MM.y 'г'. G},
			yyyyMMM => q{MM.y 'г'. G},
			yyyyMMMEd => q{E, d.MM.y 'г'. G},
			yyyyMMMM => q{MMMM y 'г'. G},
			yyyyMMMMEd => q{E, d MMMM y 'г'. G},
			yyyyMMMMd => q{d MMMM y 'г'. G},
			yyyyMMMd => q{d.MM.y 'г'. G},
			yyyyMd => q{d.MM.y 'г'. G},
			yyyyQQQ => q{QQQ y 'г'. G},
			yyyyQQQQ => q{QQQQ y 'г'. G},
		},
		'gregorian' => {
			Bh => q{h 'ч'. B},
			Bhm => q{h:mm 'ч'. B},
			Bhms => q{h:mm:ss 'ч'. B},
			EBhm => q{E, h:mm 'ч'. B},
			EBhms => q{E, h:mm:ss 'ч'. B},
			EHm => q{E, HH:mm 'ч'.},
			EHms => q{E, HH:mm:ss 'ч'.},
			Ed => q{E, d},
			Ehm => q{E, h:mm 'ч'. a},
			Ehms => q{E, h:mm:ss 'ч'. a},
			Gy => q{y 'г'. G},
			GyMMM => q{MM.y 'г'. G},
			GyMMMEd => q{E, d.MM.y 'г'. G},
			GyMMMM => q{MMMM y 'г'. G},
			GyMMMMEd => q{E, d MMMM y 'г'. G},
			GyMMMMd => q{d MMMM y 'г'. G},
			GyMMMd => q{d.MM.y 'г'. G},
			GyMd => q{dd.MM.y 'г'. GGGGG},
			H => q{HH 'ч'.},
			Hm => q{HH:mm 'ч'.},
			Hms => q{HH:mm:ss 'ч'.},
			Hmsv => q{HH:mm:ss 'ч'. v},
			Hmv => q{HH:mm 'ч'. v},
			MEd => q{E, d.MM},
			MMM => q{MM},
			MMMEd => q{E, d.MM},
			MMMM => q{LLLL},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{'седмица' W 'от' MMMM},
			MMMMd => q{d MMMM},
			MMMMdd => q{d MMMM},
			MMMd => q{d.MM},
			Md => q{d.MM},
			h => q{h 'ч'. a},
			hm => q{h:mm 'ч'. a},
			hms => q{h:mm:ss 'ч'. a},
			hmsv => q{h:mm:ss 'ч'. a v},
			hmv => q{h:mm 'ч'. a v},
			ms => q{m:ss},
			y => q{y 'г'.},
			yM => q{MM.y 'г'.},
			yMEd => q{E, d.MM.y 'г'.},
			yMMM => q{MM.y 'г'.},
			yMMMEd => q{E, d.MM.y 'г'.},
			yMMMM => q{MMMM y 'г'.},
			yMMMMEd => q{E, d MMMM y 'г'.},
			yMMMMd => q{d MMMM y 'г'.},
			yMMMd => q{d.MM.y 'г'.},
			yMd => q{d.MM.y 'г'.},
			yQQQ => q{QQQ y 'г'.},
			yQQQQ => q{QQQQ y 'г'.},
			yw => q{'седмица' w 'от' Y 'г'.},
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
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M.y GGGGG – M.y GGGGG},
				M => q{M.y – M.y GGGGG},
				y => q{M.y – M.y GGGGG},
			},
			GyMEd => {
				G => q{E, d.M.y GGGGG – E, d.M.y GGGGG},
				M => q{E, d.M.y – E, d.M.y GGGGG},
				d => q{E, d.M.y – E, d.M.y GGGGG},
				y => q{E, d.M.y – E, d.M.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
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
				G => q{d.M.y GGGGG – d.M.y GGGGG},
				M => q{d.M.y – d.M.y GGGGG},
				d => q{d.M.y – d.M.y GGGGG},
				y => q{d.M.y – d.M.y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d.MM – E, d.MM},
				d => q{E, d.MM – E, d.MM},
			},
			MMM => {
				M => q{MM – MM},
			},
			MMMEd => {
				M => q{E, d.MM – E, d.MM},
				d => q{E, d.MM – E, d.MM},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMMEd => {
				M => q{E, d MMMM – E, d MMMM},
				d => q{E, d MMMM – E, d MMMM},
			},
			MMMMd => {
				M => q{d MMMM – d MMMM},
				d => q{d – d MMMM},
			},
			MMMd => {
				M => q{d.MM – d.MM},
				d => q{d.MM – d.MM},
			},
			Md => {
				M => q{d.MM – d.MM},
				d => q{d.MM – d.MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y – y 'г'.G},
			},
			yM => {
				M => q{MM – MM.y 'г'. G},
				y => q{MM.y 'г'. – MM.y 'г'. G},
			},
			yMEd => {
				M => q{E, d.MM – E, d.MM.y 'г'. G},
				d => q{E, d.MM – E, d.MM.y 'г'. G},
				y => q{E, d.MM.y 'г'. – E, d.MM.y 'г'. G},
			},
			yMMM => {
				M => q{MM – MM.y 'г'. G},
				y => q{MM.y 'г'. – MM.y 'г'. G},
			},
			yMMMEd => {
				M => q{E, d.MM – E, d.MM.y 'г'. G},
				d => q{E, d.MM – E, d.MM.y 'г'. G},
				y => q{E, d.MM.y 'г'. – E, d.MM.y 'г'. G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y 'г'. G},
				y => q{MMMM y 'г'. – MMMM y 'г'. G},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM y 'г'. G},
				d => q{E, d MMMM – E, d MMMM y 'г'. G},
				y => q{E, d MMMM y 'г'. – E, d MMMM y 'г'. G},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM y 'г'. G},
				d => q{d – d MMMM y 'г'. G},
				y => q{d MMMM y 'г'. – d MMMM y 'г'. G},
			},
			yMMMd => {
				M => q{d.MM – d.MM.y 'г'. G},
				d => q{d.MM – d.MM.y 'г'. G},
				y => q{d.MM.y 'г'. – d.MM.y 'г'. G},
			},
			yMd => {
				M => q{d.MM – d.MM.y 'г'. G},
				d => q{d.MM – d.MM.y 'г'. G},
				y => q{d.MM.y 'г'. – d.MM.y 'г'. G},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM.y GGGGG – MM.y GGGGG},
				M => q{MM.y – MM.y GGGGG},
				y => q{MM.y – MM.y GGGGG},
			},
			GyMEd => {
				G => q{E, dd.MM.y GGGGG – E, dd.MM.y GGGGG},
				M => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				d => q{E, dd.MM.y – E, dd.MM.y GGGGG},
				y => q{E, dd.MM.y – E, dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
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
				G => q{dd.MM.y GGGGG – dd.MM.y GGGGG},
				M => q{dd.MM.y – dd.MM.y GGGGG},
				d => q{dd.MM.y – dd.MM.y GGGGG},
				y => q{dd.MM.y – dd.MM.y GGGGG},
			},
			H => {
				H => q{H – H 'ч'.},
			},
			Hm => {
				H => q{H:mm 'ч'. – H:mm 'ч'.},
				m => q{H:mm 'ч'. – H:mm 'ч'.},
			},
			Hmv => {
				H => q{H:mm 'ч'. – H:mm 'ч'. v},
				m => q{H:mm 'ч'. – H:mm 'ч'. v},
			},
			Hv => {
				H => q{H – H 'ч'. v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, d.MM – E, d.MM},
				d => q{E, d.MM – E, d.MM},
			},
			MMM => {
				M => q{MM – MM},
			},
			MMMEd => {
				M => q{E, d.MM – E, d.MM},
				d => q{E, d.MM – E, d.MM},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMMEd => {
				M => q{E, d MMMM – E, d MMMM},
				d => q{E, d MMMM – E, d MMMM},
			},
			MMMMd => {
				M => q{d MMMM – d MMMM},
				d => q{d – d MMMM},
			},
			MMMd => {
				M => q{d.MM – d.MM},
				d => q{d.MM – d.MM},
			},
			Md => {
				M => q{d.MM – d.MM},
				d => q{d.MM – d.MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h 'ч'. a – h 'ч'. a},
				h => q{h 'ч'. – h 'ч'. a},
			},
			hm => {
				a => q{h:mm 'ч'. a – h:mm 'ч'. a},
				h => q{h:mm 'ч'. – h:mm 'ч'. a},
				m => q{h:mm 'ч'. – h:mm 'ч'. a},
			},
			hmv => {
				a => q{h:mm 'ч'. a – h:mm 'ч'. a v},
				h => q{h:mm 'ч'. a – h:mm 'ч'. a v},
				m => q{h:mm 'ч'. a – h:mm 'ч'. a v},
			},
			hv => {
				a => q{h 'ч'. a – h 'ч'. a v},
				h => q{h 'ч'. – h 'ч'. a v},
			},
			y => {
				y => q{y – y 'г'.},
			},
			yM => {
				M => q{MM.y 'г'. – MM.y 'г'.},
				y => q{MM.y 'г'. – MM.y 'г'.},
			},
			yMEd => {
				M => q{E, d.MM – E, d.MM.y 'г'.},
				d => q{E, d.MM – E, d.MM.y 'г'.},
				y => q{E, d.MM.y 'г'. – E, d.MM.y 'г'.},
			},
			yMMM => {
				M => q{MM.y 'г'. – MM.y 'г'.},
				y => q{MM.y 'г'. – MM.y 'г'.},
			},
			yMMMEd => {
				M => q{E, d.MM – E, d.MM.y 'г'.},
				d => q{E, d.MM – E, d.MM.y 'г'.},
				y => q{E, d.MM.y 'г'. – E, d.MM.y 'г'.},
			},
			yMMMM => {
				M => q{MMMM – MMMM y 'г'.},
				y => q{MMMM y 'г'. – MMMM y 'г'.},
			},
			yMMMMEd => {
				M => q{E, d MMMM – E, d MMMM y 'г'.},
				d => q{E, d MMMM – E, d MMMM y 'г'.},
				y => q{E, d MMMM y 'г'. – E, d MMMM y 'г'.},
			},
			yMMMMd => {
				M => q{d MMMM – d MMMM y 'г'.},
				d => q{d – d MMMM y 'г'.},
				y => q{d MMMM y 'г'. – d MMMM y 'г'.},
			},
			yMMMd => {
				M => q{d.MM – d.MM.y 'г'.},
				d => q{d.MM – d.MM.y 'г'.},
				y => q{d.MM.y 'г'. – d.MM.y 'г'.},
			},
			yMd => {
				M => q{d.MM – d.MM.y 'г'.},
				d => q{d.MM – d.MM.y 'г'.},
				y => q{d.MM.y 'г'. – d.MM.y 'г'.},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(Гринуич{0}),
		gmtZeroFormat => q(Гринуич),
		regionFormat => q({0} – лятно часово време),
		regionFormat => q({0} – стандартно време),
		'Afghanistan' => {
			long => {
				'standard' => q#Афганистанско време#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Абиджан#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Акра#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Адис Абеба#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Алжир#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Асмара#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Бамако#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Бангуи#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Банджул#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Бисау#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Блантайър#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Бразавил#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Бужумбура#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Кайро#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Казабланка#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Сеута#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Конакри#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Дакар#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Дар ес Салам#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Джибути#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Дуала#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ел Аюн#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Фрийтаун#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Габороне#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Хараре#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Йоханесбург#,
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
			exemplarCity => q#Кигали#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Киншаса#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Лагос#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Либревил#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Ломе#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Луанда#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Лубумбаши#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Лусака#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Малабо#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Мапуто#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Масеру#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Мбабане#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Могадишу#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Монровия#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Найроби#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Нджамена#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Ниамей#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Нуакшот#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Уагадугу#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Порто Ново#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Сао Томе#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Триполи#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Тунис#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Виндхук#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Централноафриканско време#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Източноафриканско време#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Южноафриканско време#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Западноафриканско лятно часово време#,
				'generic' => q#Западноафриканско време#,
				'standard' => q#Западноафриканско стандартно време#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Аляска – лятно часово време#,
				'generic' => q#Аляска#,
				'standard' => q#Аляска – стандартно време#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Амазонско лятно часово време#,
				'generic' => q#Амазонско време#,
				'standard' => q#Амазонско стандартно време#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Адак#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Анкъридж#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ангуила#,
		},
		'America/Antigua' => {
			exemplarCity => q#Антигуа#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Арагуайна#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ла Риоха#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Рио Галегос#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Салта#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Сан Хуан#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Сан Луис#,
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
			exemplarCity => q#Асунсион#,
		},
		'America/Bahia' => {
			exemplarCity => q#Баия#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Баия де Бандерас#,
		},
		'America/Barbados' => {
			exemplarCity => q#Барбадос#,
		},
		'America/Belem' => {
			exemplarCity => q#Белем#,
		},
		'America/Belize' => {
			exemplarCity => q#Белиз#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Блан-Саблон#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Боа Виста#,
		},
		'America/Bogota' => {
			exemplarCity => q#Богота#,
		},
		'America/Boise' => {
			exemplarCity => q#Бойси#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Буенос Айрес#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Кеймбридж Бей#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Кампо Гранде#,
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
			exemplarCity => q#Кайен#,
		},
		'America/Cayman' => {
			exemplarCity => q#Кайманови острови#,
		},
		'America/Chicago' => {
			exemplarCity => q#Чикаго#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Чиуауа#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Сиудад Хуарес#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Атикокан#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Кордоба#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Коста Рика#,
		},
		'America/Creston' => {
			exemplarCity => q#Крестън#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Чуяба#,
		},
		'America/Curacao' => {
			exemplarCity => q#Кюрасао#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Данмарксхавн#,
		},
		'America/Dawson' => {
			exemplarCity => q#Доусън#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Доусън Крийк#,
		},
		'America/Denver' => {
			exemplarCity => q#Денвър#,
		},
		'America/Detroit' => {
			exemplarCity => q#Детройт#,
		},
		'America/Dominica' => {
			exemplarCity => q#Доминика#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Едмънтън#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Ейрунепе#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Салвадор#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Форт Нелсън#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Форталеза#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Глейс Бей#,
		},
		'America/Godthab' => {
			exemplarCity => q#Нуук#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Гус Бей#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Гранд Търк#,
		},
		'America/Grenada' => {
			exemplarCity => q#Гренада#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Гваделупа#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Гватемала#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Гуаякил#,
		},
		'America/Guyana' => {
			exemplarCity => q#Гаяна#,
		},
		'America/Halifax' => {
			exemplarCity => q#Халифакс#,
		},
		'America/Havana' => {
			exemplarCity => q#Хавана#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Ермосильо#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Нокс#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Маренго#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Питърсбърг#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Тел Сити#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Виви#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Винсенс#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Уинамак#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Индианаполис#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Инувик#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Иквалуит#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Ямайка#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Хухуй#,
		},
		'America/Juneau' => {
			exemplarCity => q#Джуно#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Монтичело#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Кралендейк#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Ла Пас#,
		},
		'America/Lima' => {
			exemplarCity => q#Лима#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Лос Анджелис#,
		},
		'America/Louisville' => {
			exemplarCity => q#Луисвил#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Лоуър принсес куотър#,
		},
		'America/Maceio' => {
			exemplarCity => q#Масейо#,
		},
		'America/Managua' => {
			exemplarCity => q#Манагуа#,
		},
		'America/Manaus' => {
			exemplarCity => q#Манаус#,
		},
		'America/Marigot' => {
			exemplarCity => q#Мариго#,
		},
		'America/Martinique' => {
			exemplarCity => q#Мартиника#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Матаморос#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Масатлан#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Мендоса#,
		},
		'America/Menominee' => {
			exemplarCity => q#Меномини#,
		},
		'America/Merida' => {
			exemplarCity => q#Мерида#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Метлакатла#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Мексико Сити#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Микелон#,
		},
		'America/Moncton' => {
			exemplarCity => q#Монктон#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Монтерей#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Монтевидео#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Монтсерат#,
		},
		'America/Nassau' => {
			exemplarCity => q#Насау#,
		},
		'America/New_York' => {
			exemplarCity => q#Ню Йорк#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Нипигон#,
		},
		'America/Nome' => {
			exemplarCity => q#Ноум#,
		},
		'America/Noronha' => {
			exemplarCity => q#Нороня#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Бюла#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Сентър#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Ню Сейлъм#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Охинага#,
		},
		'America/Panama' => {
			exemplarCity => q#Панама#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Пангниртунг#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Парамарибо#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Финикс#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Порт-о-Пренс#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Порт ъф Спейн#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Порто Вельо#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Пуерто Рико#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Пунта Аренас#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Рейни Ривър#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Ранкин Инлет#,
		},
		'America/Recife' => {
			exemplarCity => q#Ресифе#,
		},
		'America/Regina' => {
			exemplarCity => q#Риджайна#,
		},
		'America/Resolute' => {
			exemplarCity => q#Резолют#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Рио Бранко#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Санта Исабел#,
		},
		'America/Santarem' => {
			exemplarCity => q#Сантарем#,
		},
		'America/Santiago' => {
			exemplarCity => q#Сантяго#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Санто Доминго#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Сао Пауло#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Сгорсбисон#,
		},
		'America/Sitka' => {
			exemplarCity => q#Ситка#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Сен Бартелеми#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Сейнт Джонс#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Сейнт Китс#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Сейнт Лусия#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Сейнт Томас#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Сейнт Винсънт#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Суифт Кърент#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Тегусигалпа#,
		},
		'America/Thule' => {
			exemplarCity => q#Туле#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Тъндър Бей#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Тихуана#,
		},
		'America/Toronto' => {
			exemplarCity => q#Торонто#,
		},
		'America/Tortola' => {
			exemplarCity => q#Тортола#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Ванкувър#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Уайтхорс#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Уинипег#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Якутат#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Йелоунайф#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Северноамериканско централно лятно часово време#,
				'generic' => q#Северноамериканско централно време#,
				'standard' => q#Северноамериканско централно стандартно време#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Северноамериканско източно лятно часово време#,
				'generic' => q#Северноамериканско източно време#,
				'standard' => q#Северноамериканско източно стандартно време#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Северноамериканско планинско лятно часово време#,
				'generic' => q#Северноамериканско планинско време#,
				'standard' => q#Северноамериканско планинско стандартно време#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Северноамериканско тихоокеанско лятно часово време#,
				'generic' => q#Северноамериканско тихоокеанско време#,
				'standard' => q#Северноамериканско тихоокеанско стандартно време#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Анадир – лятно часово време#,
				'generic' => q#Анадир време#,
				'standard' => q#Анадир – стандартно време#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Кейси#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Дейвис#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Дюмон Дюрвил#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Маккуори#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Моусън#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Макмърдо#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Палмър#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Ротера#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Шова#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Трол#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Восток#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Апия – лятно часово време#,
				'generic' => q#Апия#,
				'standard' => q#Апия – стандартно време#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Арабско лятно часово време#,
				'generic' => q#Арабско време#,
				'standard' => q#Арабско стандартно време#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Лонгирбюен#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Аржентинско лятно часово време#,
				'generic' => q#Аржентинско време#,
				'standard' => q#Аржентинско стандартно време#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Западноаржентинско лятно часово време#,
				'generic' => q#Западноаржентинско време#,
				'standard' => q#Западноаржентинско стандартно време#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Арменско лятно часово време#,
				'generic' => q#Арменско време#,
				'standard' => q#Арменско стандартно време#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Аден#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Алмати#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Аман#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Анадир#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Актау#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Актобе#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ашхабад#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Атърау#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Багдад#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Бахрейн#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Баку#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Банкок#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Барнаул#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Бейрут#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Бишкек#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Бруней#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Колката#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Чита#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Чойбалсан#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Коломбо#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Дамаск#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Дака#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Дили#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Дубай#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Душанбе#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Фамагуста#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Газа#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Хеброн#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Хонконг#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Ховд#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Иркутск#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Джакарта#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Джаяпура#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Йерусалим#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Кабул#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Камчатка#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Карачи#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Катманду#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Хандига#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Красноярск#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Куала Лумпур#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Кучин#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Кувейт#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Макао#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Магадан#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Макасар#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Манила#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Мускат#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Никозия#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Новокузнецк#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Новосибирск#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Омск#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Арал#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Пном Пен#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Понтианак#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Пхенян#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Катар#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Костанай#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Къзълорда#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Рангун#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Рияд#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Хошимин#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Сахалин#,
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
			exemplarCity => q#Сингапур#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Среднеколимск#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Тайпе#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Ташкент#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Тбилиси#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Техеран#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Тхимпху#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Токио#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Томск#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Улан Батор#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Урумчи#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Уст-Нера#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Виентян#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Владивосток#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Якутск#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Екатеринбург#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ереван#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Северноамериканско атлантическо лятно часово време#,
				'generic' => q#Северноамериканско атлантическо време#,
				'standard' => q#Северноамериканско атлантическо стандартно време#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Азорски острови#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Бермудски острови#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Канарски острови#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Кабо Верде#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Фарьорски острови#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Мадейра#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Рейкявик#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Южна Джорджия#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Света Елена#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Стенли#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Аделаида#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Бризбейн#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Броукън Хил#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Къри#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Дарвин#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Юкла#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Хобарт#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Линдеман#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Лорд Хау#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Мелбърн#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Пърт#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Сидни#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Централноавстралийско лятно часово време#,
				'generic' => q#Централноавстралийско време#,
				'standard' => q#Централноавстралийско стандартно време#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Австралия – западно централно лятно часово време#,
				'generic' => q#Австралия – западно централно време#,
				'standard' => q#Австралия – западно централно стандартно време#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Източноавстралийско лятно часово време#,
				'generic' => q#Източноавстралийско време#,
				'standard' => q#Източноавстралийско стандартно време#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Западноавстралийско лятно часово време#,
				'generic' => q#Западноавстралийско време#,
				'standard' => q#Западноавстралийско стандартно време#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Азербайджанско лятно часово време#,
				'generic' => q#Азербайджанско време#,
				'standard' => q#Азербайджанско стандартно време#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Азорски острови – лятно часово време#,
				'generic' => q#Азорски острови#,
				'standard' => q#Азорски острови – стандартно време#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Бангладешко лятно часово време#,
				'generic' => q#Бангладешко време#,
				'standard' => q#Бангладешко стандартно време#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Бутанско време#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Боливийско време#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Бразилско лятно часово време#,
				'generic' => q#Бразилско време#,
				'standard' => q#Бразилско стандартно време#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Бруней Даруссалам#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Кабо Верде – лятно часово време#,
				'generic' => q#Кабо Верде#,
				'standard' => q#Кабо Верде – стандартно време#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Чаморско време#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Чатъмско лятно часово време#,
				'generic' => q#Чатъмско време#,
				'standard' => q#Чатъмско стандартно време#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Чилийско лятно часово време#,
				'generic' => q#Чилийско време#,
				'standard' => q#Чилийско стандартно време#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Китайско лятно часово време#,
				'generic' => q#Китайско време#,
				'standard' => q#Китайско стандартно време#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Чойбалсанско лятно часово време#,
				'generic' => q#Чойбалсанско време#,
				'standard' => q#Чойбалсанско стандартно време#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Остров Рождество#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Кокосови острови#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Колумбийско лятно часово време#,
				'generic' => q#Колумбийско време#,
				'standard' => q#Колумбийско стандартно време#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Острови Кук – лятно часово време#,
				'generic' => q#Острови Кук#,
				'standard' => q#Острови Кук – стандартно време#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Кубинско лятно часово време#,
				'generic' => q#Кубинско време#,
				'standard' => q#Кубинско стандартно време#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Дейвис#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Дюмон Дюрвил#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Източнотиморско време#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Великденски остров – лятно часово време#,
				'generic' => q#Великденски остров#,
				'standard' => q#Великденски остров – стандартно време#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Еквадорско време#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Координирано универсално време#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#неизвестен град#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Амстердам#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Андора#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Астрахан#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Атина#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Белград#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Берлин#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Братислава#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Брюксел#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Букурещ#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Будапеща#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Бюзинген#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Кишинев#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Копенхаген#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Дъблин#,
			long => {
				'daylight' => q#Ирландско стандартно време#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Гибралтар#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Гърнзи#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Хелзинки#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#остров Ман#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Истанбул#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Джърси#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Калининград#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Киев#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Киров#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Лисабон#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Любляна#,
		},
		'Europe/London' => {
			exemplarCity => q#Лондон#,
			long => {
				'daylight' => q#Британско лятно часово време#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Люксембург#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Мадрид#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Малта#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Мариехамн#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Минск#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Монако#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Москва#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Осло#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Париж#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Подгорица#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Прага#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Рига#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Рим#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Самара#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Сан Марино#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Сараево#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Саратов#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Симферопол#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Скопие#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#София#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Стокхолм#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Талин#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Тирана#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Уляновск#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ужгород#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Вадуц#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Ватикан#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Виена#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Вилнюс#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Волгоград#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Варшава#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Загреб#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Запорожие#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Цюрих#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Централноевропейско лятно часово време#,
				'generic' => q#Централноевропейско време#,
				'standard' => q#Централноевропейско стандартно време#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Източноевропейско лятно часово време#,
				'generic' => q#Източноевропейско време#,
				'standard' => q#Източноевропейско стандартно време#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Далечно източноевропейско време#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Западноевропейско лятно време#,
				'generic' => q#Западноевропейско време#,
				'standard' => q#Западноевропейско стандартно време#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Фолклендски острови – лятно часово време#,
				'generic' => q#Фолклендски острови#,
				'standard' => q#Фолклендски острови – стандартно време#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Фиджийско лятно часово време#,
				'generic' => q#Фиджийско време#,
				'standard' => q#Фиджийско стандартно време#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Френска Гвиана#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Френски южни и антарктически територии#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Средно гринуичко време#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Галапагоско време#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Гамбие#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Грузинско лятно часово време#,
				'generic' => q#Грузинско време#,
				'standard' => q#Грузинско стандартно време#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Острови Гилбърт#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Източногренландско лятно часово време#,
				'generic' => q#Източногренландско време#,
				'standard' => q#Източногренландско стандартно време#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Западногренландско лятно часово време#,
				'generic' => q#Западногренландско време#,
				'standard' => q#Западногренландско стандартно време#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Персийски залив#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Гаяна#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Хавайско-алеутско лятно часово време#,
				'generic' => q#Хавайско-алеутско време#,
				'standard' => q#Хавайско-алеутско стандартно време#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Хонконгско лятно часово време#,
				'generic' => q#Хонконгско време#,
				'standard' => q#Хонконгско стандартно време#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ховдско лятно часово време#,
				'generic' => q#Ховдско време#,
				'standard' => q#Ховдско стандартно време#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Индийско време#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Антананариво#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Чагос#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Рождество#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Кокосови острови#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Коморски острови#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Кергелен#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Мае#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Малдиви#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Мавриций#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Майот#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Реюнион#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Индийски океан#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Индокитайско време#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Централноиндонезийско време#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Източноиндонезийско време#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Западноиндонезийско време#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Иранско лятно часово време#,
				'generic' => q#Иранско време#,
				'standard' => q#Иранско стандартно време#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Иркутско лятно часово време#,
				'generic' => q#Иркутско време#,
				'standard' => q#Иркутско стандартно време#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Израелско лятно часово време#,
				'generic' => q#Израелско време#,
				'standard' => q#Израелско стандартно време#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Японско лятно часово време#,
				'generic' => q#Японско време#,
				'standard' => q#Японско стандартно време#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Петропавловск-Камчатски – лятно часово време#,
				'generic' => q#Петропавловск-Камчатски време#,
				'standard' => q#Петропавловск-Камчатски стандартно време#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Източноказахстанско време#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Западноказахстанско време#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Корейско лятно часово време#,
				'generic' => q#Корейско време#,
				'standard' => q#Корейско стандартно време#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Кошрай#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Красноярско лятно часово време#,
				'generic' => q#Красноярско време#,
				'standard' => q#Красноярско стандартно време#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Киргизстанско време#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Екваториални острови#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Лорд Хау – лятно часово време#,
				'generic' => q#Лорд Хау#,
				'standard' => q#Лорд Хау – стандартно време#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Маккуори#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Магаданско лятно часово време#,
				'generic' => q#Магаданско време#,
				'standard' => q#Магаданско стандартно време#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Малайзийско време#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Малдивско време#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Маркизки острови#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Маршалови острови#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Мавриций – лятно часово време#,
				'generic' => q#Мавриций#,
				'standard' => q#Мавриций – стандартно време#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Моусън#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Северозападно лятно часово мексиканско време#,
				'generic' => q#Северозападно мексиканско време#,
				'standard' => q#Северозападно стандартно мексиканско време#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Мексиканско тихоокеанско лятно часово време#,
				'generic' => q#Мексиканско тихоокеанско време#,
				'standard' => q#Мексиканско тихоокеанско стандартно време#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Уланбаторско лятно часово време#,
				'generic' => q#Уланбаторско време#,
				'standard' => q#Уланбаторско стандартно време#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Московско лятно часово време#,
				'generic' => q#Московско време#,
				'standard' => q#Московско стандартно време#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Мианмарско време#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Науру#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Непалско време#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Новокаледонско лятно часово време#,
				'generic' => q#Новокаледонско време#,
				'standard' => q#Новокаледонско стандартно време#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Новозеландско лятно часово време#,
				'generic' => q#Новозеландско време#,
				'standard' => q#Новозеландско стандартно време#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Нюфаундлендско лятно часово време#,
				'generic' => q#Нюфаундлендско време#,
				'standard' => q#Нюфаундлендско стандартно време#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ниуе#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Норфолкско лятно часово време#,
				'generic' => q#Норфолкско време#,
				'standard' => q#Норфолкско стандартно време#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Фернандо де Нороня – лятно часово време#,
				'generic' => q#Фернандо де Нороня#,
				'standard' => q#Фернандо де Нороня – стандартно време#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Новосибирско лятно часово време#,
				'generic' => q#Новосибирско време#,
				'standard' => q#Новосибирско стандартно време#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Омско лятно часово време#,
				'generic' => q#Омско време#,
				'standard' => q#Омско стандартно време#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Апия#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Окланд#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Бугенвил#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Чатам#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Великденски остров#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Ефате#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Ендърбъри#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Факаофо#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Фиджи#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Фунафути#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Галапагос#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Гамбие#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Гуадалканал#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Гуам#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Хонолулу#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Джонстън#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Кантон#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Киритимати#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Кошрай#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Куаджалин#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Маджуро#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Маркизки острови#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Мидуей#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Науру#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Ниуе#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Норфолк#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Нумеа#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Паго Паго#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Палау#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Питкерн#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Понпей#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Порт Морсби#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Раротонга#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Сайпан#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Таити#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Тарауа#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Тонгатапу#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Чуюк#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Уейк#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Уолис#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Пакистанско лятно часово време#,
				'generic' => q#Пакистанско време#,
				'standard' => q#Пакистанско стандартно време#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Палау#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Папуа Нова Гвинея#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Парагвайско лятно часово време#,
				'generic' => q#Парагвайско време#,
				'standard' => q#Парагвайско стандартно време#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Перуанско лятно часово време#,
				'generic' => q#Перуанско време#,
				'standard' => q#Перуанско стандартно време#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Филипинско лятно часово време#,
				'generic' => q#Филипинско време#,
				'standard' => q#Филипинско стандартно време#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Острови Феникс#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Сен Пиер и Микелон – лятно часово време#,
				'generic' => q#Сен Пиер и Микелон#,
				'standard' => q#Сен Пиер и Микелон – стандартно време#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Питкерн#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Понапе#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Пхенянско време#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Реюнион#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ротера#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Сахалинско лятно часово време#,
				'generic' => q#Сахалинско време#,
				'standard' => q#Сахалинско стандартно време#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Самара – лятно часово време#,
				'generic' => q#Самара време#,
				'standard' => q#Самара – стандартно време#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Самоанско лятно часово време#,
				'generic' => q#Самоанско време#,
				'standard' => q#Самоанско стандартно време#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Сейшели#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Сингапурско време#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Соломонови острови#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Южна Джорджия#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Суринамско време#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Шова#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Таитянско време#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Тайпе – лятно часово време#,
				'generic' => q#Тайпе#,
				'standard' => q#Тайпе – стандартно време#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Таджикистанско време#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Токелау#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Тонга – лятно часово време#,
				'generic' => q#Тонга#,
				'standard' => q#Тонга – стандартно време#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Чуюк#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Туркменистанско лятно часово време#,
				'generic' => q#Туркменистанско време#,
				'standard' => q#Туркменистанско стандартно време#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Тувалу#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Уругвайско лятно часово време#,
				'generic' => q#Уругвайско време#,
				'standard' => q#Уругвайско стандартно време#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Узбекистанско лятно часово време#,
				'generic' => q#Узбекистанско време#,
				'standard' => q#Узбекистанско стандартно време#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Вануату – лятно часово време#,
				'generic' => q#Вануату#,
				'standard' => q#Вануату – стандартно време#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Венецуелско време#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Владивостокско лятно часово време#,
				'generic' => q#Владивостокско време#,
				'standard' => q#Владивостокско стандартно време#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Волгоградско лятно часово време#,
				'generic' => q#Волгоградско време#,
				'standard' => q#Волгоградско стандартно време#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Восток#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Остров Уейк#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Уолис и Футуна#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Якутскско лятно часово време#,
				'generic' => q#Якутско време#,
				'standard' => q#Якутскско стандартно време#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Екатеринбургско лятно часово време#,
				'generic' => q#Екатеринбургско време#,
				'standard' => q#Екатеринбургско стандартно време#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Юкон#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
