=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ar - Package for language Arabic

=cut

package Locale::CLDR::Locales::Ar;
# This file auto generated from Data\common\main\ar.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-feminine','spellout-cardinal-masculine','spellout-ordinal-feminine','spellout-ordinal-masculine','digits-ordinal' ]},
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
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=),
				},
			},
		},
		'ordinal-ones-feminine' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(الحادية ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(الحادية عشرة),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
			},
		},
		'ordinal-ones-masculine' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(الحادي ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(الحادي عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(ناقص →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← فاصل →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(واحدة),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(إثنتان),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ثلاثة),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(أربعة),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(خمسة),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ستة),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(سبعة),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ثمانية),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(تسعة),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(عشرة),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(إحدى عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(إثنتا عشرة),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→%spellout-numbering→ عشر),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]عشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]أربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]خمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]سبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]تسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(مائة[ و→%spellout-numbering→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(مائتان[ و→%spellout-numbering→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%spellout-numbering→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ألف[ و→%spellout-numbering→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ألفي[ و→%spellout-numbering→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← آلاف[ و→%spellout-numbering→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-m← ألف[ و→%spellout-numbering→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(مليون[ و→%spellout-numbering→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-numbering-m← مليون[ و→%spellout-numbering→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(مليار[ و→%spellout-numbering→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-numbering-m← مليار[ و→%spellout-numbering→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%spellout-numbering→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-numbering-m← ترليون[ و→%spellout-numbering→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%spellout-numbering→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-numbering-m← كوادرليون[ و→%spellout-numbering→]),
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
					rule => q(ناقص →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←%%spellout-numbering-m← فاصل →→ ),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(واحد),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(إثنان),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ثلاثة),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(أربعة),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(خمسة),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ستة),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(سبعة),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ثمانية),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(تسعة),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(عشرة),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(إحدى عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(إثنا عشر),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→ عشر),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]عشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]أربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]خمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]سبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]تسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(مائة[ و→%%spellout-numbering-m→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(مائتان[ و→%%spellout-numbering-m→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%%spellout-numbering-m→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ألف[ و→%%spellout-numbering-m→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ألفي[ و→%%spellout-numbering-m→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← آلاف[ و→%%spellout-numbering-m→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-m← ألف[ و→%%spellout-numbering-m→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(مليون[ و→%%spellout-numbering-m→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-numbering-m← مليون[ و→%%spellout-numbering-m→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(مليار[ و→%%spellout-numbering-m→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-numbering-m← مليار[ و→%%spellout-numbering-m→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-numbering-m← ترليون[ و→%%spellout-numbering-m→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-numbering-m← كوادرليون[ و→%%spellout-numbering-m→]),
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
					rule => q(ناقص →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← فاصل →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(واحد),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(إثنان),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ثلاثة),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(أربعة),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(خمسة),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ستة),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(سبعة),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ثمانية),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(تسعة),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(عشرة),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(إحدى عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(إثنا عشر),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→%spellout-numbering→ عشر),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]عشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]أربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]خمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]سبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]ثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-numbering→ و]تسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(مائة[ و→%spellout-numbering→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(مائتان[ و→%spellout-numbering→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%spellout-numbering→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ألف[ و→%spellout-numbering→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ألفين[ و→%spellout-numbering→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← آلاف[ و→%spellout-numbering→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-m← ألف[ و→%spellout-numbering→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(مليون[ و→%spellout-numbering→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-numbering-m← مليون[ و→%spellout-numbering→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(مليار[ و→%spellout-numbering→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-numbering-m← مليار[ و→%spellout-numbering→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%spellout-numbering→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-numbering-m← ترليون[ و→%spellout-numbering→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%spellout-numbering→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-numbering-m← كوادرليون[ و→%spellout-numbering→]),
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
		'spellout-numbering-m' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(واحد),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(إثنان),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ثلاثة),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(أربعة),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(خمسة),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ستة),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(سبعة),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ثمانية),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(تسعة),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(عشرة),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(إحدى عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(إثنا عشر),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→ عشر),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]عشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]أربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]خمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]سبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]ثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%%spellout-numbering-m→ و]تسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(مائة[ و→%%spellout-numbering-m→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(مائتان[ و→%%spellout-numbering-m→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%%spellout-numbering-m→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(ألف[ و→%%spellout-numbering-m→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(ألفي[ و→%%spellout-numbering-m→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← آلاف[ و→%%spellout-numbering-m→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-m← ألف[ و→%%spellout-numbering-m→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(مليون[ و→%%spellout-numbering-m→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-numbering-m← مليون[ و→%%spellout-numbering-m→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(مليار[ و→%%spellout-numbering-m→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-numbering-m← مليار[ و→%%spellout-numbering-m→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-numbering-m← ترليون[ و→%%spellout-numbering-m→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-numbering-m← كوادرليون[ و→%%spellout-numbering-m→]),
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
					rule => q(ناقص →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← فاصل →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(الأولى),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(الثانية),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(الثالثة),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(الرابعة),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(الخامسة),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(السادسة),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(السابعة),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(الثامنة),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(التاسعة),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(العاشرة),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(الحادية عشرة),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ عشرة),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(العشرون),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والعشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(الثلاثون),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(الأربعون),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والأربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(الخمسون),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والخمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(الستون),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(السبعون),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والسبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(الثمانون),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(التسعون),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(→%%ordinal-ones-feminine→ والتسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(المائة[ و→%spellout-cardinal-feminine→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(المائتان[ و→%spellout-cardinal-feminine→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%spellout-cardinal-feminine→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(الألف[ و→%spellout-cardinal-feminine→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(الألفي[ و→%spellout-cardinal-feminine→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← آلاف[ و→%spellout-cardinal-feminine→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← ألف[ و→%spellout-cardinal-feminine→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(المليون[ و→%spellout-cardinal-feminine→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← الألف[ و→%spellout-cardinal-feminine→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(المليار[ و→%spellout-cardinal-feminine→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← مليار[ و→%spellout-cardinal-feminine→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%spellout-cardinal-feminine→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← ترليون[ و→%spellout-cardinal-feminine→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%spellout-cardinal-feminine→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← كوادرليون[ و→%spellout-cardinal-feminine→]),
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
					rule => q(ناقص →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(صفر),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← فاصل →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(الأول),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(الثاني),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(الثالث),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(الرابع),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(الخامس),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(السادس),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(السابع),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(الثامن),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(التاسع),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(العاشر),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(الحادي عشر),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ عشر),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(العشرون),
				},
				'21' => {
					base_value => q(21),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والعشرون),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(الثلاثون),
				},
				'31' => {
					base_value => q(31),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والثلاثون),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(الأربعون),
				},
				'41' => {
					base_value => q(41),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والأربعون),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(الخمسون),
				},
				'51' => {
					base_value => q(51),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والخمسون),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(الستون),
				},
				'61' => {
					base_value => q(61),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والستون),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(السبعون),
				},
				'71' => {
					base_value => q(71),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والسبعون),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(الثمانون),
				},
				'81' => {
					base_value => q(81),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والثمانون),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(التسعون),
				},
				'91' => {
					base_value => q(91),
					divisor => q(10),
					rule => q(→%%ordinal-ones-masculine→ والتسعون),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(المائة[ و→%%spellout-numbering-m→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(المائتان[ و→%%spellout-numbering-m→]),
				},
				'300' => {
					base_value => q(300),
					divisor => q(100),
					rule => q(←%spellout-numbering← مائة[ و→%%spellout-numbering-m→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(الألف[ و→%%spellout-numbering-m→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(الألفي[ و→%%spellout-numbering-m→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← آلاف[ و→%%spellout-numbering-m→]),
				},
				'11000' => {
					base_value => q(11000),
					divisor => q(1000),
					rule => q(←%%spellout-numbering-m← ألف[ و→%%spellout-numbering-m→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(المليون[ و→%%spellout-numbering-m→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-numbering-m← الألف[ و→%%spellout-numbering-m→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(المليار[ و→%%spellout-numbering-m→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-numbering-m← مليار[ و→%%spellout-numbering-m→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(ترليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-numbering-m← ترليون[ و→%%spellout-numbering-m→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(كوادرليون[ و→%%spellout-numbering-m→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-numbering-m← كوادرليون[ و→%%spellout-numbering-m→]),
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

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'الأفارية',
 				'ab' => 'الأبخازية',
 				'ace' => 'الأتشينيزية',
 				'ach' => 'الأكولية',
 				'ada' => 'الأدانجمية',
 				'ady' => 'الأديغة',
 				'ae' => 'الأفستية',
 				'af' => 'الأفريقانية',
 				'afh' => 'الأفريهيلية',
 				'agq' => 'الأغم',
 				'ain' => 'الآينوية',
 				'ak' => 'الأكانية',
 				'akk' => 'الأكادية',
 				'ale' => 'الأليوتية',
 				'alt' => 'الألطائية الجنوبية',
 				'am' => 'الأمهرية',
 				'an' => 'الأراغونية',
 				'ang' => 'الإنجليزية القديمة',
 				'ann' => 'أوبلو',
 				'anp' => 'الأنجيكا',
 				'ar' => 'العربية',
 				'ar_001' => 'العربية الفصحى الحديثة',
 				'arc' => 'الآرامية',
 				'arn' => 'المابودونغونية',
 				'arp' => 'الأراباهو',
 				'ars' => 'اللهجة النجدية',
 				'ars@alt=menu' => 'العربية، النجدية',
 				'arw' => 'الأراواكية',
 				'as' => 'الأسامية',
 				'asa' => 'الآسو',
 				'ast' => 'الأسترية',
 				'atj' => 'الأتيكاميكو',
 				'av' => 'الأوارية',
 				'awa' => 'الأوادية',
 				'ay' => 'الأيمارا',
 				'az' => 'الأذربيجانية',
 				'az@alt=short' => 'الأذرية',
 				'ba' => 'الباشكيرية',
 				'bal' => 'البلوشية',
 				'ban' => 'البالينية',
 				'bas' => 'الباسا',
 				'bax' => 'بامن',
 				'bbj' => 'لغة الغومالا',
 				'be' => 'البيلاروسية',
 				'bej' => 'البيجا',
 				'bem' => 'البيمبا',
 				'bez' => 'بينا',
 				'bfd' => 'لغة البافوت',
 				'bg' => 'البلغارية',
 				'bgc' => 'الهارينفية',
 				'bgn' => 'البلوشية الغربية',
 				'bho' => 'البهوجبورية',
 				'bi' => 'البيسلامية',
 				'bik' => 'البيكولية',
 				'bin' => 'البينية',
 				'bkm' => 'لغة الكوم',
 				'bla' => 'السيكسيكية',
 				'bm' => 'البامبارا',
 				'bn' => 'البنغالية',
 				'bo' => 'التبتية',
 				'br' => 'البريتونية',
 				'bra' => 'البراجية',
 				'brx' => 'البودو',
 				'bs' => 'البوسنية',
 				'bss' => 'أكوس',
 				'bua' => 'البرياتية',
 				'bug' => 'البجينيزية',
 				'bum' => 'لغة البولو',
 				'byn' => 'البلينية',
 				'byv' => 'لغة الميدومبا',
 				'ca' => 'الكتالانية',
 				'cad' => 'الكادو',
 				'car' => 'الكاريبية',
 				'cay' => 'الكايوجية',
 				'cch' => 'الأتسام',
 				'ccp' => 'تشاكما',
 				'ce' => 'الشيشانية',
 				'ceb' => 'السيبيوانية',
 				'cgg' => 'تشيغا',
 				'ch' => 'التشامورو',
 				'chb' => 'التشيبشا',
 				'chg' => 'التشاجاتاي',
 				'chk' => 'التشكيزية',
 				'chm' => 'الماري',
 				'chn' => 'الشينوك جارجون',
 				'cho' => 'الشوكتو',
 				'chp' => 'الشيباوايان',
 				'chr' => 'الشيروكي',
 				'chy' => 'الشايان',
 				'ckb' => 'السورانية الكردية',
 				'ckb@alt=menu' => 'الكردية، السورانية',
 				'clc' => 'تسيلكوتين',
 				'co' => 'الكورسيكية',
 				'cop' => 'القبطية',
 				'cr' => 'الكرى',
 				'crg' => 'الميتشيف',
 				'crh' => 'لغة تتار القرم',
 				'crj' => 'الكري الجنوب شرقية',
 				'crk' => 'البلينز-كري',
 				'crl' => 'الكري شمال الشرقية',
 				'crm' => 'الموس-كري',
 				'crr' => 'الألغونكوية كارولينا',
 				'crs' => 'الفرنسية الكريولية السيشيلية',
 				'cs' => 'التشيكية',
 				'csb' => 'الكاشبايان',
 				'csw' => 'السوامبي-كري',
 				'cu' => 'سلافية كنسية',
 				'cv' => 'التشوفاشي',
 				'cy' => 'الويلزية',
 				'da' => 'الدانمركية',
 				'dak' => 'الداكوتا',
 				'dar' => 'الدارجوا',
 				'dav' => 'تيتا',
 				'de' => 'الألمانية',
 				'de_AT' => 'الألمانية النمساوية',
 				'de_CH' => 'الألمانية العليا السويسرية',
 				'del' => 'الديلوير',
 				'den' => 'السلافية',
 				'dgr' => 'الدوجريب',
 				'din' => 'الدنكا',
 				'dje' => 'الزارمية',
 				'doi' => 'الدوجرية',
 				'dsb' => 'صوربيا السفلى',
 				'dua' => 'الديولا',
 				'dum' => 'الهولندية الوسطى',
 				'dv' => 'المالديفية',
 				'dyo' => 'جولا فونيا',
 				'dyu' => 'الدايلا',
 				'dz' => 'دزونكا',
 				'dzg' => 'القرعانية',
 				'ebu' => 'إمبو',
 				'ee' => 'الإيوي',
 				'efi' => 'الإفيك',
 				'egy' => 'المصرية القديمة',
 				'eka' => 'الإكاجك',
 				'el' => 'اليونانية',
 				'elx' => 'الإمايت',
 				'en' => 'الإنجليزية',
 				'en_AU' => 'الإنجليزية الأسترالية',
 				'en_CA' => 'الإنجليزية الكندية',
 				'en_GB' => 'الإنجليزية البريطانية',
 				'en_GB@alt=short' => 'الإنجليزية المملكة المتحدة',
 				'en_US' => 'الإنجليزية الأمريكية',
 				'en_US@alt=short' => 'الإنجليزية الولايات المتحدة',
 				'enm' => 'الإنجليزية الوسطى',
 				'eo' => 'الإسبرانتو',
 				'es' => 'الإسبانية',
 				'es_419' => 'الإسبانية أمريكا اللاتينية',
 				'es_ES' => 'الإسبانية الأوروبية',
 				'es_MX' => 'الإسبانية المكسيكية',
 				'et' => 'الإستونية',
 				'eu' => 'الباسكية',
 				'ewo' => 'الإيوندو',
 				'fa' => 'الفارسية',
 				'fa_AF' => 'الدارية',
 				'fan' => 'الفانج',
 				'fat' => 'الفانتي',
 				'ff' => 'الفولانية',
 				'fi' => 'الفنلندية',
 				'fil' => 'الفلبينية',
 				'fj' => 'الفيجية',
 				'fo' => 'الفاروية',
 				'fon' => 'الفون',
 				'fr' => 'الفرنسية',
 				'fr_CA' => 'الفرنسية الكندية',
 				'fr_CH' => 'الفرنسية السويسرية',
 				'frc' => 'الفرنسية الكاجونية',
 				'frm' => 'الفرنسية الوسطى',
 				'fro' => 'الفرنسية القديمة',
 				'frr' => 'الفريزينية الشمالية',
 				'frs' => 'الفريزينية الشرقية',
 				'fur' => 'الفريلايان',
 				'fy' => 'الفريزيان',
 				'ga' => 'الأيرلندية',
 				'gaa' => 'الجا',
 				'gag' => 'الغاغوز',
 				'gan' => 'الغان الصينية',
 				'gay' => 'الجايو',
 				'gba' => 'الجبيا',
 				'gd' => 'الغيلية الأسكتلندية',
 				'gez' => 'الجعزية',
 				'gil' => 'لغة أهل جبل طارق',
 				'gl' => 'الجاليكية',
 				'gmh' => 'الألمانية العليا الوسطى',
 				'gn' => 'الغوارانية',
 				'goh' => 'الألمانية العليا القديمة',
 				'gon' => 'الجندي',
 				'gor' => 'الجورونتالو',
 				'got' => 'القوطية',
 				'grb' => 'الجريبو',
 				'grc' => 'اليونانية القديمة',
 				'gsw' => 'الألمانية السويسرية',
 				'gu' => 'الغوجاراتية',
 				'guz' => 'الغيزية',
 				'gv' => 'المنكية',
 				'gwi' => 'غوتشن',
 				'ha' => 'الهوسا',
 				'hai' => 'الهيدا',
 				'hak' => 'الهاكا الصينية',
 				'haw' => 'لغة هاواي',
 				'hax' => 'هايدا الجنوبية',
 				'he' => 'العبرية',
 				'hi' => 'الهندية',
 				'hi_Latn@alt=variant' => 'الهنجليزية',
 				'hil' => 'الهيليجينون',
 				'hit' => 'الحثية',
 				'hmn' => 'الهمونجية',
 				'ho' => 'الهيري موتو',
 				'hr' => 'الكرواتية',
 				'hsb' => 'الصوربية العليا',
 				'hsn' => 'شيانغ الصينية',
 				'ht' => 'الكريولية الهايتية',
 				'hu' => 'الهنغارية',
 				'hup' => 'الهبا',
 				'hur' => 'الهالكوميليم',
 				'hy' => 'الأرمنية',
 				'hz' => 'الهيريرو',
 				'ia' => 'اللّغة الوسيطة',
 				'iba' => 'الإيبان',
 				'ibb' => 'الإيبيبيو',
 				'id' => 'الإندونيسية',
 				'ie' => 'الإنترلينج',
 				'ig' => 'الإيجبو',
 				'ii' => 'السيتشيون يي',
 				'ik' => 'الإينبياك',
 				'ikt' => 'الإنكتيتوتية الكندية الغربية',
 				'ilo' => 'الإيلوكو',
 				'inh' => 'الإنجوشية',
 				'io' => 'الإيدو',
 				'is' => 'الأيسلندية',
 				'it' => 'الإيطالية',
 				'iu' => 'الإينكتيتت',
 				'ja' => 'اليابانية',
 				'jbo' => 'اللوجبان',
 				'jgo' => 'نغومبا',
 				'jmc' => 'الماتشامية',
 				'jpr' => 'الفارسية اليهودية',
 				'jrb' => 'العربية اليهودية',
 				'jv' => 'الجاوية',
 				'ka' => 'الجورجية',
 				'kaa' => 'الكارا-كالباك',
 				'kab' => 'القبيلية',
 				'kac' => 'الكاتشين',
 				'kaj' => 'الجو',
 				'kam' => 'الكامبا',
 				'kaw' => 'الكوي',
 				'kbd' => 'الكاباردايان',
 				'kbl' => 'كانمبو',
 				'kcg' => 'التايابية',
 				'kde' => 'ماكونده',
 				'kea' => 'كابوفيرديانو',
 				'kfo' => 'الكورو',
 				'kg' => 'الكونغو',
 				'kgp' => 'الكاينغانغ',
 				'kha' => 'الكازية',
 				'kho' => 'الخوتانيز',
 				'khq' => 'كويرا تشيني',
 				'ki' => 'الكيكيو',
 				'kj' => 'كوانياما',
 				'kk' => 'الكازاخستانية',
 				'kkj' => 'لغة الكاكو',
 				'kl' => 'الكالاليست',
 				'kln' => 'كالينجين',
 				'km' => 'الخميرية',
 				'kmb' => 'الكيمبندو',
 				'kn' => 'الكانادا',
 				'ko' => 'الكورية',
 				'koi' => 'كومي-بيرماياك',
 				'kok' => 'الكونكانية',
 				'kos' => 'الكوسراين',
 				'kpe' => 'الكبيل',
 				'kr' => 'الكانوري',
 				'krc' => 'الكاراتشاي-بالكار',
 				'krl' => 'الكاريلية',
 				'kru' => 'الكوروخ',
 				'ks' => 'الكشميرية',
 				'ksb' => 'شامبالا',
 				'ksf' => 'لغة البافيا',
 				'ksh' => 'لغة الكولونيان',
 				'ku' => 'الكردية',
 				'kum' => 'القموقية',
 				'kut' => 'الكتيناي',
 				'kv' => 'الكومي',
 				'kw' => 'الكورنية',
 				'kwk' => 'الكواكوالا',
 				'ky' => 'القيرغيزية',
 				'la' => 'اللاتينية',
 				'lad' => 'اللادينو',
 				'lag' => 'لانجي',
 				'lah' => 'اللاهندا',
 				'lam' => 'اللامبا',
 				'lb' => 'اللكسمبورغية',
 				'lez' => 'الليزجية',
 				'lg' => 'الغاندا',
 				'li' => 'الليمبورغية',
 				'lil' => 'الليلويتية',
 				'lkt' => 'لاكوتا',
 				'lmo' => 'اللومبردية',
 				'ln' => 'اللينجالا',
 				'lo' => 'اللاوية',
 				'lol' => 'منغولى',
 				'lou' => 'الكريولية اللويزيانية',
 				'loz' => 'اللوزي',
 				'lrc' => 'اللرية الشمالية',
 				'lsm' => 'الساميا',
 				'lt' => 'الليتوانية',
 				'lu' => 'اللوبا كاتانغا',
 				'lua' => 'اللبا-لؤلؤ',
 				'lui' => 'اللوسينو',
 				'lun' => 'اللوندا',
 				'luo' => 'اللو',
 				'lus' => 'الميزو',
 				'luy' => 'لغة اللويا',
 				'lv' => 'اللاتفية',
 				'mad' => 'المادريز',
 				'mag' => 'الماجا',
 				'mai' => 'المايثيلي',
 				'mak' => 'الماكاسار',
 				'man' => 'الماندينغ',
 				'mas' => 'الماساي',
 				'mde' => 'مابا',
 				'mdf' => 'الموكشا',
 				'mdr' => 'الماندار',
 				'men' => 'الميند',
 				'mer' => 'الميرو',
 				'mfe' => 'المورسيانية',
 				'mg' => 'الملغاشي',
 				'mga' => 'الأيرلندية الوسطى',
 				'mgh' => 'ماخاوا-ميتو',
 				'mgo' => 'ميتا',
 				'mh' => 'المارشالية',
 				'mi' => 'الماورية',
 				'mic' => 'الميكماكيونية',
 				'min' => 'المينانجكاباو',
 				'mk' => 'المقدونية',
 				'ml' => 'المالايالامية',
 				'mn' => 'المنغولية',
 				'mnc' => 'المانشو',
 				'mni' => 'المانيبورية',
 				'moe' => 'إينو-ايمون',
 				'moh' => 'الموهوك',
 				'mos' => 'الموسي',
 				'mr' => 'الماراثية',
 				'ms' => 'الماليزية',
 				'mt' => 'المالطية',
 				'mua' => 'مندنج',
 				'mul' => 'لغات متعددة',
 				'mus' => 'الكريك',
 				'mwl' => 'الميرانديز',
 				'mwr' => 'الماروارية',
 				'my' => 'البورمية',
 				'myv' => 'الأرزية',
 				'mzn' => 'المازندرانية',
 				'na' => 'النورو',
 				'nan' => 'مين-نان الصينية',
 				'nap' => 'النابولية',
 				'naq' => 'لغة الناما',
 				'nb' => 'النرويجية بوكمال',
 				'nd' => 'النديبيل الشمالية',
 				'nds' => 'الألمانية السفلى',
 				'nds_NL' => 'السكسونية السفلى',
 				'ne' => 'النيبالية',
 				'new' => 'النوارية',
 				'ng' => 'الندونجا',
 				'nia' => 'النياس',
 				'niu' => 'النيوي',
 				'nl' => 'الهولندية',
 				'nl_BE' => 'الفلمنكية',
 				'nmg' => 'كواسيو',
 				'nn' => 'النرويجية نينورسك',
 				'nnh' => 'لغة النجيمبون',
 				'no' => 'النرويجية',
 				'nog' => 'النوجاي',
 				'non' => 'النورس القديم',
 				'nqo' => 'أنكو',
 				'nr' => 'النديبيل الجنوبي',
 				'nso' => 'السوتو الشمالية',
 				'nus' => 'النوير',
 				'nv' => 'النافاجو',
 				'nwc' => 'النوارية التقليدية',
 				'ny' => 'النيانجا',
 				'nym' => 'النيامويزي',
 				'nyn' => 'النيانكول',
 				'nyo' => 'النيورو',
 				'nzi' => 'النزيما',
 				'oc' => 'الأوكسيتانية',
 				'oj' => 'الأوجيبوا',
 				'ojb' => 'أوجيبوا الشمالية الغربية',
 				'ojc' => 'أوجيبوا الوسطى',
 				'ojs' => 'الأوجي-كري',
 				'ojw' => 'الأوجيبوا الغربية',
 				'oka' => 'الأوكاناغانية',
 				'om' => 'الأورومية',
 				'or' => 'الأورية',
 				'os' => 'الأوسيتيك',
 				'osa' => 'الأوساج',
 				'ota' => 'التركية العثمانية',
 				'pa' => 'البنجابية',
 				'pag' => 'البانجاسينان',
 				'pal' => 'البهلوية',
 				'pam' => 'البامبانجا',
 				'pap' => 'البابيامينتو',
 				'pau' => 'البالوان',
 				'pcm' => 'البدجنية النيجيرية',
 				'peo' => 'الفارسية القديمة',
 				'phn' => 'الفينيقية',
 				'pi' => 'البالية',
 				'pis' => 'بيجين',
 				'pl' => 'البولندية',
 				'pon' => 'البوهنبيايان',
 				'pqm' => 'الماليزيت-باساماكودي',
 				'prg' => 'البروسياوية',
 				'pro' => 'البروفانسية القديمة',
 				'ps' => 'البشتو',
 				'ps@alt=variant' => 'بشتو',
 				'pt' => 'البرتغالية',
 				'pt_BR' => 'البرتغالية البرازيلية',
 				'pt_PT' => 'البرتغالية الأوروبية',
 				'qu' => 'كيشوا',
 				'quc' => 'الكيشية',
 				'raj' => 'الراجاسثانية',
 				'rap' => 'الراباني',
 				'rar' => 'الراروتونجاني',
 				'rhg' => 'الروهينغية',
 				'rm' => 'الرومانشية',
 				'rn' => 'الرندي',
 				'ro' => 'الرومانية',
 				'ro_MD' => 'المولدوفية',
 				'rof' => 'الرومبو',
 				'rom' => 'الغجرية',
 				'ru' => 'الروسية',
 				'rup' => 'الأرومانيان',
 				'rw' => 'الكينيارواندا',
 				'rwk' => 'الروا',
 				'sa' => 'السنسكريتية',
 				'sad' => 'السانداوي',
 				'sah' => 'الساخيّة',
 				'sam' => 'الآرامية السامرية',
 				'saq' => 'سامبورو',
 				'sas' => 'الساساك',
 				'sat' => 'السانتالية',
 				'sba' => 'نامبي',
 				'sbp' => 'سانغو',
 				'sc' => 'السردينية',
 				'scn' => 'الصقلية',
 				'sco' => 'الأسكتلندية',
 				'sd' => 'السندية',
 				'sdh' => 'الكردية الجنوبية',
 				'se' => 'سامي الشمالية',
 				'see' => 'السنيكا',
 				'seh' => 'سينا',
 				'sel' => 'السيلكب',
 				'ses' => 'كويرابورو سيني',
 				'sg' => 'السانجو',
 				'sga' => 'الأيرلندية القديمة',
 				'sh' => 'صربية-كرواتية',
 				'shi' => 'تشلحيت',
 				'shn' => 'الشان',
 				'shu' => 'العربية التشادية',
 				'si' => 'السنهالية',
 				'sid' => 'السيدامو',
 				'sk' => 'السلوفاكية',
 				'sl' => 'السلوفانية',
 				'slh' => 'لوشوتسيد الجنوبية',
 				'sm' => 'الساموائية',
 				'sma' => 'السامي الجنوبي',
 				'smj' => 'اللول سامي',
 				'smn' => 'الإيناري سامي',
 				'sms' => 'السكولت سامي',
 				'sn' => 'الشونا',
 				'snk' => 'السونينك',
 				'so' => 'الصومالية',
 				'sog' => 'السوجدين',
 				'sq' => 'الألبانية',
 				'sr' => 'الصربية',
 				'srn' => 'السرانان تونجو',
 				'srr' => 'السرر',
 				'ss' => 'السواتي',
 				'ssy' => 'لغة الساهو',
 				'st' => 'السوتو الجنوبية',
 				'str' => 'سترايتس ساليش',
 				'su' => 'السوندانية',
 				'suk' => 'السوكوما',
 				'sus' => 'السوسو',
 				'sux' => 'السومارية',
 				'sv' => 'السويدية',
 				'sw' => 'السواحلية',
 				'sw_CD' => 'الكونغو السواحلية',
 				'swb' => 'القمرية',
 				'syc' => 'سريانية تقليدية',
 				'syr' => 'السريانية',
 				'ta' => 'التاميلية',
 				'tce' => 'التوتشون الجنوبية',
 				'te' => 'التيلوغوية',
 				'tem' => 'التيمن',
 				'teo' => 'تيسو',
 				'ter' => 'التيرينو',
 				'tet' => 'التيتم',
 				'tg' => 'الطاجيكية',
 				'tgx' => 'التاغيش',
 				'th' => 'التايلاندية',
 				'tht' => 'التالتان',
 				'ti' => 'التغرينية',
 				'tig' => 'التيغرية',
 				'tiv' => 'التيف',
 				'tk' => 'التركمانية',
 				'tkl' => 'التوكيلاو',
 				'tl' => 'التاغالوغية',
 				'tlh' => 'الكلينجون',
 				'tli' => 'التلينغيتية',
 				'tmh' => 'التاماشيك',
 				'tn' => 'التسوانية',
 				'to' => 'التونغية',
 				'tog' => 'تونجا - نياسا',
 				'tok' => 'التوكي-بونا',
 				'tpi' => 'التوك بيسين',
 				'tr' => 'التركية',
 				'trv' => 'لغة التاروكو',
 				'ts' => 'السونجا',
 				'tsi' => 'التسيمشيان',
 				'tt' => 'التترية',
 				'ttm' => 'التوتشون الشمالية',
 				'tum' => 'التامبوكا',
 				'tvl' => 'التوفالو',
 				'tw' => 'التوي',
 				'twq' => 'تاساواق',
 				'ty' => 'التاهيتية',
 				'tyv' => 'التوفية',
 				'tzm' => 'الأمازيغية وسط الأطلس',
 				'udm' => 'الأدمرت',
 				'ug' => 'الأويغورية',
 				'ug@alt=variant' => 'الأيغورية',
 				'uga' => 'اليجاريتيك',
 				'uk' => 'الأوكرانية',
 				'umb' => 'الأمبندو',
 				'und' => 'لغة غير معروفة',
 				'ur' => 'الأوردية',
 				'uz' => 'الأوزبكية',
 				'vai' => 'الفاي',
 				've' => 'الفيندا',
 				'vi' => 'الفيتنامية',
 				'vo' => 'لغة الفولابوك',
 				'vot' => 'الفوتيك',
 				'vun' => 'الفونجو',
 				'wa' => 'الولونية',
 				'wae' => 'الوالسر',
 				'wal' => 'الولاياتا',
 				'war' => 'الواراي',
 				'was' => 'الواشو',
 				'wbp' => 'وارلبيري',
 				'wo' => 'الولوفية',
 				'wuu' => 'الوو الصينية',
 				'xal' => 'الكالميك',
 				'xh' => 'الخوسا',
 				'xog' => 'السوغا',
 				'yao' => 'الياو',
 				'yap' => 'اليابيز',
 				'yav' => 'يانجبن',
 				'ybb' => 'يمبا',
 				'yi' => 'اليديشية',
 				'yo' => 'اليوروبا',
 				'yrl' => 'النيينجاتو',
 				'yue' => 'الكَنْتُونية',
 				'za' => 'الزهيونج',
 				'zap' => 'الزابوتيك',
 				'zbl' => 'رموز المعايير الأساسية',
 				'zen' => 'الزيناجا',
 				'zgh' => 'التمازيغية المغربية القياسية',
 				'zh' => 'الصينية',
 				'zh_Hans' => 'الصينية المبسطة',
 				'zh_Hant' => 'الصينية التقليدية',
 				'zu' => 'الزولو',
 				'zun' => 'الزونية',
 				'zxx' => 'بدون محتوى لغوي',
 				'zza' => 'زازا',

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
			'Adlm' => 'أدلم',
 			'Arab' => 'العربية',
 			'Arab@alt=variant' => 'العربية الفارسية',
 			'Aran' => 'نستعليق',
 			'Armn' => 'الأرمينية',
 			'Bali' => 'البالية',
 			'Batk' => 'الباتاك',
 			'Beng' => 'البنغالية',
 			'Blis' => 'رموز بليس',
 			'Bopo' => 'البوبوموفو',
 			'Brah' => 'الهندوسية',
 			'Brai' => 'البرايل',
 			'Bugi' => 'البجينيز',
 			'Buhd' => 'البهيدية',
 			'Cakm' => 'شاكما',
 			'Cans' => 'مقاطع كندية أصلية موحدة',
 			'Cari' => 'الكارية',
 			'Cham' => 'التشامية',
 			'Cher' => 'الشيروكي',
 			'Cirt' => 'السيرث',
 			'Copt' => 'القبطية',
 			'Cprt' => 'القبرصية',
 			'Cyrl' => 'السيريلية',
 			'Cyrs' => 'السيريلية السلافية الكنسية القديمة',
 			'Deva' => 'الديفاناجاري',
 			'Dsrt' => 'الديسيريت',
 			'Egyd' => 'الديموطيقية',
 			'Egyh' => 'الهيراطيقية',
 			'Egyp' => 'الهيروغليفية',
 			'Ethi' => 'الأثيوبية',
 			'Geok' => 'الأبجدية الجورجية - أسومتافرلي و نسخري',
 			'Geor' => 'الجورجية',
 			'Glag' => 'الجلاجوليتيك',
 			'Goth' => 'القوطية',
 			'Grek' => 'اليونانية',
 			'Gujr' => 'التاغجراتية',
 			'Guru' => 'الجرمخي',
 			'Hanb' => 'هانب',
 			'Hang' => 'الهانغول',
 			'Hani' => 'الهان',
 			'Hano' => 'الهانونو',
 			'Hans' => 'المبسطة',
 			'Hans@alt=stand-alone' => 'الهان المبسطة',
 			'Hant' => 'التقليدية',
 			'Hant@alt=stand-alone' => 'الهان التقليدية',
 			'Hebr' => 'العبرية',
 			'Hira' => 'الهيراجانا',
 			'Hmng' => 'الباهوه همونج',
 			'Hrkt' => 'أبجدية مقطعية يابانية',
 			'Hung' => 'المجرية القديمة',
 			'Inds' => 'اندس - هارابان',
 			'Ital' => 'الإيطالية القديمة',
 			'Jamo' => 'جامو',
 			'Java' => 'الجاوية',
 			'Jpan' => 'اليابانية',
 			'Kali' => 'الكياه لى',
 			'Kana' => 'الكتكانا',
 			'Khar' => 'الخاروشتى',
 			'Khmr' => 'الخميرية',
 			'Knda' => 'الكانادا',
 			'Kore' => 'الكورية',
 			'Lana' => 'الانا',
 			'Laoo' => 'اللاو',
 			'Latf' => 'اللاتينية - متغير فراكتر',
 			'Latg' => 'اللاتينية - متغير غيلى',
 			'Latn' => 'اللاتينية',
 			'Lepc' => 'الليبتشا - رونج',
 			'Limb' => 'الليمبو',
 			'Lina' => 'الخطية أ',
 			'Linb' => 'الخطية ب',
 			'Lyci' => 'الليسية',
 			'Lydi' => 'الليدية',
 			'Mand' => 'المانداينية',
 			'Maya' => 'المايا الهيروغليفية',
 			'Mero' => 'الميرويتيك',
 			'Mlym' => 'الماليالام',
 			'Mong' => 'المغولية',
 			'Moon' => 'مون',
 			'Mtei' => 'ميتي ماييك',
 			'Mymr' => 'الميانمار',
 			'Narb' => 'العربية الشمالية القديمة',
 			'Nkoo' => 'أنكو',
 			'Ogam' => 'الأوجهام',
 			'Olck' => 'أول تشيكي',
 			'Orkh' => 'الأورخون',
 			'Orya' => 'الأوريا',
 			'Osma' => 'الأوسمانيا',
 			'Perm' => 'البيرميكية القديمة',
 			'Phag' => 'الفاجسبا',
 			'Phnx' => 'الفينيقية',
 			'Plrd' => 'الصوتيات الجماء',
 			'Qaag' => 'زوجيي',
 			'Rohg' => 'الحنيفي',
 			'Roro' => 'رنجورنجو',
 			'Runr' => 'الروني',
 			'Sara' => 'الساراتي',
 			'Sarb' => 'العربية الجنوبية القديمة',
 			'Shaw' => 'الشواني',
 			'Sinh' => 'السينهالا',
 			'Sund' => 'السوندانية',
 			'Sylo' => 'السيلوتي ناغري',
 			'Syrc' => 'السريانية',
 			'Syre' => 'السريانية الأسترنجيلية',
 			'Syrj' => 'السريانية الغربية',
 			'Syrn' => 'السريانية الشرقية',
 			'Tagb' => 'التاجبانوا',
 			'Tale' => 'التاي لي',
 			'Talu' => 'التاى لى الجديد',
 			'Taml' => 'التاميلية',
 			'Telu' => 'التيلجو',
 			'Teng' => 'التينجوار',
 			'Tfng' => 'التيفيناغ',
 			'Tglg' => 'التغالوغية',
 			'Thaa' => 'الثعنة',
 			'Thai' => 'التايلاندية',
 			'Tibt' => 'التبتية',
 			'Ugar' => 'الأجاريتيكية',
 			'Vaii' => 'الفاي',
 			'Visp' => 'الكلام المرئي',
 			'Xpeo' => 'الفارسية القديمة',
 			'Xsux' => 'الكتابة المسمارية الأكدية السومرية',
 			'Yiii' => 'اليي',
 			'Zinh' => 'الموروث',
 			'Zmth' => 'تدوين رياضي',
 			'Zsye' => 'إيموجي',
 			'Zsym' => 'رموز',
 			'Zxxx' => 'غير مكتوب',
 			'Zyyy' => 'عام',
 			'Zzzz' => 'نظام كتابة غير معروف',

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
			'001' => 'العالم',
 			'002' => 'أفريقيا',
 			'003' => 'أمريكا الشمالية',
 			'005' => 'أمريكا الجنوبية',
 			'009' => 'أوقيانوسيا',
 			'011' => 'غرب أفريقيا',
 			'013' => 'أمريكا الوسطى',
 			'014' => 'شرق أفريقيا',
 			'015' => 'شمال أفريقيا',
 			'017' => 'وسط أفريقيا',
 			'018' => 'أفريقيا الجنوبية',
 			'019' => 'الأمريكتان',
 			'021' => 'شمال أمريكا',
 			'029' => 'الكاريبي',
 			'030' => 'شرق آسيا',
 			'034' => 'جنوب آسيا',
 			'035' => 'جنوب شرق آسيا',
 			'039' => 'جنوب أوروبا',
 			'053' => 'أسترالاسيا',
 			'054' => 'ميلانيزيا',
 			'057' => 'الجزر الميكرونيزية',
 			'061' => 'بولينيزيا',
 			'142' => 'آسيا',
 			'143' => 'وسط آسيا',
 			'145' => 'غرب آسيا',
 			'150' => 'أوروبا',
 			'151' => 'شرق أوروبا',
 			'154' => 'شمال أوروبا',
 			'155' => 'غرب أوروبا',
 			'202' => 'أفريقيا جنوب الصحراء الكبرى',
 			'419' => 'أمريكا اللاتينية',
 			'AC' => 'جزيرة أسينشيون',
 			'AD' => 'أندورا',
 			'AE' => 'الإمارات العربية المتحدة',
 			'AF' => 'أفغانستان',
 			'AG' => 'أنتيغوا وبربودا',
 			'AI' => 'أنغويلا',
 			'AL' => 'ألبانيا',
 			'AM' => 'أرمينيا',
 			'AO' => 'أنغولا',
 			'AQ' => 'أنتاركتيكا',
 			'AR' => 'الأرجنتين',
 			'AS' => 'ساموا الأمريكية',
 			'AT' => 'النمسا',
 			'AU' => 'أستراليا',
 			'AW' => 'أروبا',
 			'AX' => 'جزر آلاند',
 			'AZ' => 'أذربيجان',
 			'BA' => 'البوسنة والهرسك',
 			'BB' => 'بربادوس',
 			'BD' => 'بنغلاديش',
 			'BE' => 'بلجيكا',
 			'BF' => 'بوركينا فاسو',
 			'BG' => 'بلغاريا',
 			'BH' => 'البحرين',
 			'BI' => 'بوروندي',
 			'BJ' => 'بنين',
 			'BL' => 'سان بارتليمي',
 			'BM' => 'برمودا',
 			'BN' => 'بروناي',
 			'BO' => 'بوليفيا',
 			'BQ' => 'هولندا الكاريبية',
 			'BR' => 'البرازيل',
 			'BS' => 'جزر البهاما',
 			'BT' => 'بوتان',
 			'BV' => 'جزيرة بوفيه',
 			'BW' => 'بوتسوانا',
 			'BY' => 'بيلاروس',
 			'BZ' => 'بليز',
 			'CA' => 'كندا',
 			'CC' => 'جزر كوكوس (كيلينغ)',
 			'CD' => 'الكونغو - كينشاسا',
 			'CD@alt=variant' => 'جمهورية الكونغو الديمقراطية',
 			'CF' => 'جمهورية أفريقيا الوسطى',
 			'CG' => 'الكونغو - برازافيل',
 			'CG@alt=variant' => 'جمهورية الكونغو',
 			'CH' => 'سويسرا',
 			'CI' => 'ساحل العاج',
 			'CI@alt=variant' => 'كوت ديفوار',
 			'CK' => 'جزر كوك',
 			'CL' => 'تشيلي',
 			'CM' => 'الكاميرون',
 			'CN' => 'الصين',
 			'CO' => 'كولومبيا',
 			'CP' => 'جزيرة كليبيرتون',
 			'CR' => 'كوستاريكا',
 			'CU' => 'كوبا',
 			'CV' => 'الرأس الأخضر',
 			'CW' => 'كوراساو',
 			'CX' => 'جزيرة كريسماس',
 			'CY' => 'قبرص',
 			'CZ' => 'التشيك',
 			'CZ@alt=variant' => 'جمهورية التشيك',
 			'DE' => 'ألمانيا',
 			'DG' => 'دييغو غارسيا',
 			'DJ' => 'جيبوتي',
 			'DK' => 'الدانمرك',
 			'DM' => 'دومينيكا',
 			'DO' => 'جمهورية الدومينيكان',
 			'DZ' => 'الجزائر',
 			'EA' => 'سيوتا وميليلا',
 			'EC' => 'الإكوادور',
 			'EE' => 'إستونيا',
 			'EG' => 'مصر',
 			'EH' => 'الصحراء الغربية',
 			'ER' => 'إريتريا',
 			'ES' => 'إسبانيا',
 			'ET' => 'إثيوبيا',
 			'EU' => 'الاتحاد الأوروبي',
 			'EZ' => 'منطقة اليورو',
 			'FI' => 'فنلندا',
 			'FJ' => 'فيجي',
 			'FK' => 'جزر فوكلاند',
 			'FK@alt=variant' => 'جزر فوكلاند - جزر مالفيناس',
 			'FM' => 'ميكرونيزيا',
 			'FO' => 'جزر فارو',
 			'FR' => 'فرنسا',
 			'GA' => 'الغابون',
 			'GB' => 'المملكة المتحدة',
 			'GD' => 'غرينادا',
 			'GE' => 'جورجيا',
 			'GF' => 'غويانا الفرنسية',
 			'GG' => 'غيرنزي',
 			'GH' => 'غانا',
 			'GI' => 'جبل طارق',
 			'GL' => 'غرينلاند',
 			'GM' => 'غامبيا',
 			'GN' => 'غينيا',
 			'GP' => 'غوادلوب',
 			'GQ' => 'غينيا الاستوائية',
 			'GR' => 'اليونان',
 			'GS' => 'جورجيا الجنوبية وجزر ساندويتش الجنوبية',
 			'GT' => 'غواتيمالا',
 			'GU' => 'غوام',
 			'GW' => 'غينيا بيساو',
 			'GY' => 'غيانا',
 			'HK' => 'هونغ كونغ الصينية (منطقة إدارية خاصة)',
 			'HK@alt=short' => 'هونغ كونغ',
 			'HM' => 'جزيرة هيرد وجزر ماكدونالد',
 			'HN' => 'هندوراس',
 			'HR' => 'كرواتيا',
 			'HT' => 'هايتي',
 			'HU' => 'هنغاريا',
 			'IC' => 'جزر الكناري',
 			'ID' => 'إندونيسيا',
 			'IE' => 'أيرلندا',
 			'IL' => 'إسرائيل',
 			'IM' => 'جزيرة مان',
 			'IN' => 'الهند',
 			'IO' => 'الإقليم البريطاني في المحيط الهندي',
 			'IO@alt=chagos' => 'أرخبيل تشاغوس',
 			'IQ' => 'العراق',
 			'IR' => 'إيران',
 			'IS' => 'آيسلندا',
 			'IT' => 'إيطاليا',
 			'JE' => 'جيرسي',
 			'JM' => 'جامايكا',
 			'JO' => 'الأردن',
 			'JP' => 'اليابان',
 			'KE' => 'كينيا',
 			'KG' => 'قيرغيزستان',
 			'KH' => 'كمبوديا',
 			'KI' => 'كيريباتي',
 			'KM' => 'جزر القمر',
 			'KN' => 'سانت كيتس ونيفيس',
 			'KP' => 'كوريا الشمالية',
 			'KR' => 'كوريا الجنوبية',
 			'KW' => 'الكويت',
 			'KY' => 'جزر كايمان',
 			'KZ' => 'كازاخستان',
 			'LA' => 'لاوس',
 			'LB' => 'لبنان',
 			'LC' => 'سانت لوسيا',
 			'LI' => 'ليختنشتاين',
 			'LK' => 'سريلانكا',
 			'LR' => 'ليبيريا',
 			'LS' => 'ليسوتو',
 			'LT' => 'ليتوانيا',
 			'LU' => 'لوكسمبورغ',
 			'LV' => 'لاتفيا',
 			'LY' => 'ليبيا',
 			'MA' => 'المغرب',
 			'MC' => 'موناكو',
 			'MD' => 'مولدوفا',
 			'ME' => 'الجبل الأسود',
 			'MF' => 'سان مارتن',
 			'MG' => 'مدغشقر',
 			'MH' => 'جزر مارشال',
 			'MK' => 'مقدونيا الشمالية',
 			'ML' => 'مالي',
 			'MM' => 'ميانمار (بورما)',
 			'MN' => 'منغوليا',
 			'MO' => 'منطقة ماكاو الإدارية الخاصة',
 			'MO@alt=short' => 'مكاو',
 			'MP' => 'جزر ماريانا الشمالية',
 			'MQ' => 'جزر المارتينيك',
 			'MR' => 'موريتانيا',
 			'MS' => 'مونتسرات',
 			'MT' => 'مالطا',
 			'MU' => 'موريشيوس',
 			'MV' => 'جزر المالديف',
 			'MW' => 'ملاوي',
 			'MX' => 'المكسيك',
 			'MY' => 'ماليزيا',
 			'MZ' => 'موزمبيق',
 			'NA' => 'ناميبيا',
 			'NC' => 'كاليدونيا الجديدة',
 			'NE' => 'النيجر',
 			'NF' => 'جزيرة نورفولك',
 			'NG' => 'نيجيريا',
 			'NI' => 'نيكاراغوا',
 			'NL' => 'هولندا',
 			'NO' => 'النرويج',
 			'NP' => 'نيبال',
 			'NR' => 'ناورو',
 			'NU' => 'نيوي',
 			'NZ' => 'نيوزيلندا',
 			'OM' => 'عُمان',
 			'PA' => 'بنما',
 			'PE' => 'بيرو',
 			'PF' => 'بولينيزيا الفرنسية',
 			'PG' => 'بابوا غينيا الجديدة',
 			'PH' => 'الفلبين',
 			'PK' => 'باكستان',
 			'PL' => 'بولندا',
 			'PM' => 'سان بيير ومكويلون',
 			'PN' => 'جزر بيتكيرن',
 			'PR' => 'بورتوريكو',
 			'PS' => 'الأراضي الفلسطينية',
 			'PS@alt=short' => 'فلسطين',
 			'PT' => 'البرتغال',
 			'PW' => 'بالاو',
 			'PY' => 'باراغواي',
 			'QA' => 'قطر',
 			'QO' => 'أوقيانوسيا النائية',
 			'RE' => 'روينيون',
 			'RO' => 'رومانيا',
 			'RS' => 'صربيا',
 			'RU' => 'روسيا',
 			'RW' => 'رواندا',
 			'SA' => 'المملكة العربية السعودية',
 			'SB' => 'جزر سليمان',
 			'SC' => 'سيشل',
 			'SD' => 'السودان',
 			'SE' => 'السويد',
 			'SG' => 'سنغافورة',
 			'SH' => 'سانت هيلينا',
 			'SI' => 'سلوفينيا',
 			'SJ' => 'سفالبارد وجان ماين',
 			'SK' => 'سلوفاكيا',
 			'SL' => 'سيراليون',
 			'SM' => 'سان مارينو',
 			'SN' => 'السنغال',
 			'SO' => 'الصومال',
 			'SR' => 'سورينام',
 			'SS' => 'جنوب السودان',
 			'ST' => 'ساو تومي وبرينسيبي',
 			'SV' => 'السلفادور',
 			'SX' => 'سانت مارتن',
 			'SY' => 'سوريا',
 			'SZ' => 'إسواتيني',
 			'SZ@alt=variant' => 'سوازيلاند',
 			'TA' => 'تريستان دا كونا',
 			'TC' => 'جزر توركس وكايكوس',
 			'TD' => 'تشاد',
 			'TF' => 'الأقاليم الجنوبية الفرنسية',
 			'TG' => 'توغو',
 			'TH' => 'تايلاند',
 			'TJ' => 'طاجيكستان',
 			'TK' => 'توكيلاو',
 			'TL' => 'تيمور - ليشتي',
 			'TL@alt=variant' => 'تيمور الشرقية',
 			'TM' => 'تركمانستان',
 			'TN' => 'تونس',
 			'TO' => 'تونغا',
 			'TR' => 'تركيا',
 			'TT' => 'ترينيداد وتوباغو',
 			'TV' => 'توفالو',
 			'TW' => 'تايوان',
 			'TZ' => 'تنزانيا',
 			'UA' => 'أوكرانيا',
 			'UG' => 'أوغندا',
 			'UM' => 'جزر الولايات المتحدة النائية',
 			'UN' => 'الأمم المتحدة',
 			'US' => 'الولايات المتحدة',
 			'UY' => 'أورغواي',
 			'UZ' => 'أوزبكستان',
 			'VA' => 'الفاتيكان',
 			'VC' => 'سانت فنسنت وجزر غرينادين',
 			'VE' => 'فنزويلا',
 			'VG' => 'جزر فيرجن البريطانية',
 			'VI' => 'جزر فيرجن الأمريكية',
 			'VN' => 'فيتنام',
 			'VU' => 'فانواتو',
 			'WF' => 'جزر والس وفوتونا',
 			'WS' => 'ساموا',
 			'XA' => 'لكنات تجريبية غير أصلية',
 			'XB' => 'لكنات تجريبية ثنائية الاتجاه',
 			'XK' => 'كوسوفو',
 			'YE' => 'اليمن',
 			'YT' => 'مايوت',
 			'ZA' => 'جنوب أفريقيا',
 			'ZM' => 'زامبيا',
 			'ZW' => 'زيمبابوي',
 			'ZZ' => 'منطقة غير معروفة',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'التهجئة الألمانية التقليدية',
 			'1996' => 'التهجئة الألمانية لعام 1996',
 			'1959ACAD' => 'أكاديمي',
 			'AREVELA' => 'أرمنية شرقية',
 			'AREVMDA' => 'أرمنية غربية',
 			'BAKU1926' => 'الأبجدية التركية اللاتينية الموحدة',
 			'KKCOR' => 'التهجئة العامة',
 			'MONOTON' => 'أحادي النغمة',
 			'NEDIS' => 'لهجة ناتيسون',
 			'PINYIN' => 'بينيين باللاتينية',
 			'POLYTON' => 'متعدد النغمات',
 			'POSIX' => 'حاسوب',
 			'REVISED' => 'تهجئة تمت مراجعتها',
 			'SCOTLAND' => 'الإنجليزية الأسكتلندنية الرسمية',
 			'UCCOR' => 'التهجئة الموحدة',
 			'UCRCOR' => 'التهجئة المراجعة الموحدة',
 			'VALENCIA' => 'بلنسية',
 			'WADEGILE' => 'المندرين باللاتينية - ويد–جيلز',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'التقويم',
 			'cf' => 'تنسيق العملة',
 			'colalternate' => 'الفرز بحسب تجاهل الرموز',
 			'colbackwards' => 'الفرز بحسب اللكنة المعكوسة',
 			'colcasefirst' => 'الترتيب بحسب الأحرف الكبيرة/الصغيرة',
 			'colcaselevel' => 'الفرز بحسب حساسية حالة الأحرف',
 			'collation' => 'ترتيب الفرز',
 			'colnormalization' => 'الفرز الموحد',
 			'colnumeric' => 'الفرز الرقمي',
 			'colstrength' => 'قوة الفرز',
 			'currency' => 'العملة',
 			'hc' => 'نظام التوقيت (12 مقابل 24)',
 			'lb' => 'نمط فصل السطور',
 			'ms' => 'نظام القياس',
 			'numbers' => 'الأرقام',
 			'timezone' => 'المنطقة الزمنية',
 			'va' => 'متغيرات اللغة',
 			'x' => 'استخدام خاص',

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
 				'buddhist' => q{التقويم البوذي},
 				'chinese' => q{التقويم الصيني},
 				'coptic' => q{التقويم القبطي},
 				'dangi' => q{تقويم دانجي},
 				'ethiopic' => q{التقويم الإثيوبي},
 				'ethiopic-amete-alem' => q{تقويم أميتي أليم الإثيوبي},
 				'gregorian' => q{التقويم الميلادي},
 				'hebrew' => q{التقويم العبري},
 				'indian' => q{التقويم القومي الهندي},
 				'islamic' => q{التقويم الهجري},
 				'islamic-civil' => q{التقويم الهجري المدني},
 				'islamic-rgsa' => q{التقويم الهجري (السعودية - الرؤية)},
 				'islamic-tbla' => q{التقويم الهجري (الحسابات الفلكية)},
 				'islamic-umalqura' => q{التقويم الهجري (أم القرى)},
 				'iso8601' => q{تقويم ISO-8601},
 				'japanese' => q{التقويم الياباني},
 				'persian' => q{التقويم الفارسي},
 				'roc' => q{تقويم مينجو},
 			},
 			'cf' => {
 				'account' => q{تنسيق العملة للحسابات},
 				'standard' => q{تنسيق العملة القياسي},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{تصنيف الرموز},
 				'shifted' => q{تصنيف تجاهل الرموز},
 			},
 			'colbackwards' => {
 				'no' => q{تصنيف اللكنات بشكل عادي},
 				'yes' => q{تصنيف اللكنات معكوسة},
 			},
 			'colcasefirst' => {
 				'lower' => q{تصنيف الأحرف الصغيرة أولاً},
 				'no' => q{ترتيب تصنيف حالة الأحرف الطبيعية},
 				'upper' => q{تصنيف الأحرف الكبيرة أولاً},
 			},
 			'colcaselevel' => {
 				'no' => q{تصنيف بحسب الأحرف غير الحساسة لحالة الأحرف},
 				'yes' => q{تصنيف بحسب حساسية الأحرف},
 			},
 			'collation' => {
 				'big5han' => q{الترتيب حسب اللغة الصينية التقليدية (Big5)},
 				'compat' => q{ترتيب الفرز السابق: للتوافق},
 				'dictionary' => q{الترتيب حسب القاموس},
 				'ducet' => q{ترتيب فرز Unicode الافتراضي},
 				'gb2312han' => q{الترتيب حسب اللغة الصينية المبسّطة (GB2312)},
 				'phonebook' => q{الترتيب حسب دليل الهاتف},
 				'phonetic' => q{الترتيب حسب اللفظ},
 				'pinyin' => q{الترتيب حسب نظام بنيين الصيني},
 				'reformed' => q{الترتيب المحسَّن},
 				'search' => q{بحث لأغراض عامة},
 				'searchjl' => q{بحث باستخدام حرف الهانغول الساكن الأول},
 				'standard' => q{ترتيب الفرز القياسي},
 				'stroke' => q{الترتيب حسب نظام كتابة المجموع الصيني},
 				'traditional' => q{ترتيب تقليدي},
 				'unihan' => q{الترتيب حسب نظام الكتابة بالجذر والمجموع},
 				'zhuyin' => q{الترتيب حسب نظام بوبوموفو},
 			},
 			'colnormalization' => {
 				'no' => q{التصفية بدون تسوية},
 				'yes' => q{تصنيف Unicode طبيعي},
 			},
 			'colnumeric' => {
 				'no' => q{تصنيف الأرقام على حدة},
 				'yes' => q{تصنيف الأرقام بالعدد},
 			},
 			'colstrength' => {
 				'identical' => q{تصنيف الكل},
 				'primary' => q{تصنيف الحروف الأساسية فقط},
 				'quaternary' => q{تصنيف اللكنات/الحالة/العرض/الكانا},
 				'secondary' => q{تصنيف اللكنات},
 				'tertiary' => q{تصنيف اللكنات/الحالة/العرض},
 			},
 			'd0' => {
 				'fwidth' => q{عرض كامل},
 				'hwidth' => q{نصف العرض},
 				'npinyin' => q{رقمي},
 			},
 			'hc' => {
 				'h11' => q{نظام 12 ساعة (0–11)},
 				'h12' => q{نظام 12 ساعة (1–12)},
 				'h23' => q{نظام 24 ساعة (0–23)},
 				'h24' => q{نظام 24 ساعة (1–24)},
 			},
 			'lb' => {
 				'loose' => q{نمط فصل السطور: متباعد},
 				'normal' => q{نمط فصل السطور: عادي},
 				'strict' => q{نمط فصل السطور: متقارب},
 			},
 			'm0' => {
 				'bgn' => q{بي جي إن},
 				'ungegn' => q{يو إن جي إي جي إن},
 			},
 			'ms' => {
 				'metric' => q{النظام المتري},
 				'uksystem' => q{نظام القياس البريطاني},
 				'ussystem' => q{نظام القياس الأمريكي},
 			},
 			'numbers' => {
 				'arab' => q{الأرقام العربية الهندية},
 				'arabext' => q{الأرقام العربية الهندية الممتدة},
 				'armn' => q{الأرقام الأرمينية},
 				'armnlow' => q{الأرقام الأرمينية الصغيرة},
 				'beng' => q{الأرقام البنغالية},
 				'cakm' => q{أرقام تشاكما},
 				'deva' => q{الأرقام الديفانغارية},
 				'ethi' => q{الأرقام الإثيوبية},
 				'finance' => q{الأرقام المالية},
 				'fullwide' => q{أرقام كاملة العرض},
 				'geor' => q{الأرقام الجورجية},
 				'grek' => q{الأرقام اليونانية},
 				'greklow' => q{الأرقام اليونانية الصغيرة},
 				'gujr' => q{الأرقام الغوجاراتية},
 				'guru' => q{الأرقام الغورموخية},
 				'hanidec' => q{الأرقام العشرية الصينية},
 				'hans' => q{الأرقام الصينية المبسطة},
 				'hansfin' => q{الأرقام المالية الصينية المبسطة},
 				'hant' => q{الأرقام الصينية التقليدية},
 				'hantfin' => q{الأرقام المالية الصينية التقليدية},
 				'hebr' => q{الأرقام العبرية},
 				'java' => q{الأرقام الجاوية},
 				'jpan' => q{الأرقام اليابانية},
 				'jpanfin' => q{الأرقام المالية اليابانية},
 				'khmr' => q{الأرقام الخيمرية},
 				'knda' => q{أرقام الكانادا},
 				'laoo' => q{الأرقام اللاوية},
 				'latn' => q{الأرقام الغربية},
 				'mlym' => q{الأرقام الملايلامية},
 				'mong' => q{الأرقام المغولية},
 				'mtei' => q{أرقام ميتي},
 				'mymr' => q{أرقام ميانمار},
 				'native' => q{الأرقام الأصلية},
 				'olck' => q{أرقام أُول تشيكي},
 				'orya' => q{أرقام الأوريا},
 				'roman' => q{الأرقام الرومانية},
 				'romanlow' => q{الأرقام الرومانية الصغيرة},
 				'taml' => q{الأرقام التاميلية التقليدية},
 				'tamldec' => q{الأرقام التاميلية},
 				'telu' => q{الأرقام التيلوغوية},
 				'thai' => q{الأرقام التايلاندية},
 				'tibt' => q{الأرقام التبتية},
 				'traditional' => q{أرقام تقليدية},
 				'vaii' => q{أرقام فاي},
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
			'metric' => q{النظام المتري},
 			'UK' => q{النظام البريطاني},
 			'US' => q{النظام الأمريكي},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'اللغة: {0}',
 			'script' => 'نظام الكتابة: {0}',
 			'region' => 'المنطقة: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => '',
			characters => 'right-to-left',
		}}
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
			auxiliary => qr{[ـ‌‍‎‏ پ چ ژ ڜ ڢ ڤ ڥ ٯ ڧ ڨ ک گ ی]},
			index => ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'],
			main => qr{[ً ٌ ٍ َ ُ ِ ّ ْ ٰ ءأؤإئا آ ب ةت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ىي]},
			numbers => qr{[؜‎ \- ‑ , ٫ ٬ . % ٪ ‰ ؉ + 0٠ 1١ 2٢ 3٣ 4٤ 5٥ 6٦ 7٧ 8٨ 9٩]},
			punctuation => qr{[\- ‐‑ – — ، ؛ \: ! ؟ . … ' " « » ( ) \[ \]]},
		};
	},
EOT
: sub {
		return { index => ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'], };
},
);


has 'more_information' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{؟},
);

has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
	default		=> qq{’},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(اتجاه أساسي),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(اتجاه أساسي),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(كيبي{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(كيبي{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ميبي{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ميبي{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(غيبي{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(غيبي{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(تيبي{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(تيبي{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(بيبي{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(بيبي{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(إكسبي{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(إكسبي{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(زيبي{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(زيبي{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(يوبي{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(يوبي{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(ديسي{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(ديسي{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(بيكو{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(بيكو{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(فيمتو{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(فيمتو{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(أتو{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(أتو{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(سنتي{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(سنتي{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(زيبتو{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(زيبتو{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(يوكتو{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(يوكتو{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(ملّي{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(ملّي{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(ميكرو{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(ميكرو{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(نانو{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(نانو{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(ديكا{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ديكا{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(تيرا{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(تيرا{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(بيتا{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(بيتا{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(إكسا{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(إكسا{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(هكتو{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(هكتو{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(زيتا{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(زيتا{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(يوتا{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(يوتا{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(كويتا{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(كويتا{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(ميغا{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(ميغا{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(غيغا{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(غيغا{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} متر في الثانية المربعة),
						'many' => q({0} متر في الثانية المربعة),
						'name' => q(متر في الثانية المربعة),
						'one' => q({0} متر في الثانية المربعة),
						'other' => q({0} متر في الثانية المربعة),
						'two' => q({0} متر في الثانية المربعة),
						'zero' => q({0} متر في الثانية المربعة),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'few' => q({0} متر في الثانية المربعة),
						'many' => q({0} متر في الثانية المربعة),
						'name' => q(متر في الثانية المربعة),
						'one' => q({0} متر في الثانية المربعة),
						'other' => q({0} متر في الثانية المربعة),
						'two' => q({0} متر في الثانية المربعة),
						'zero' => q({0} متر في الثانية المربعة),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'few' => q({0} دورات),
						'many' => q({0} دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q(دورتان),
						'zero' => q({0} دورة),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'few' => q({0} دورات),
						'many' => q({0} دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q(دورتان),
						'zero' => q({0} دورة),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} دونم),
						'many' => q({0} دونم),
						'one' => q({0} دونم),
						'other' => q({0} دونم),
						'two' => q({0} دونم),
						'zero' => q(دونم),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} دونم),
						'many' => q({0} دونم),
						'one' => q({0} دونم),
						'other' => q({0} دونم),
						'two' => q({0} دونم),
						'zero' => q(دونم),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر مربع),
						'many' => q({0} سنتيمتر مربع),
						'name' => q(سنتيمتر مربع),
						'one' => q({0} سنتيمتر مربع),
						'other' => q({0} سنتيمتر مربع),
						'per' => q({0}/سنتيمتر مربع),
						'two' => q({0} سنتيمتر مربع),
						'zero' => q({0} سنتيمتر مربع),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر مربع),
						'many' => q({0} سنتيمتر مربع),
						'name' => q(سنتيمتر مربع),
						'one' => q({0} سنتيمتر مربع),
						'other' => q({0} سنتيمتر مربع),
						'per' => q({0}/سنتيمتر مربع),
						'two' => q({0} سنتيمتر مربع),
						'zero' => q({0} سنتيمتر مربع),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} قدم مربعة),
						'many' => q({0} قدم مربعة),
						'name' => q(قدم مربعة),
						'one' => q(قدم مربعة),
						'other' => q({0} قدم مربعة),
						'two' => q({0} قدم مربعة),
						'zero' => q({0} قدم مربعة),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} قدم مربعة),
						'many' => q({0} قدم مربعة),
						'name' => q(قدم مربعة),
						'one' => q(قدم مربعة),
						'other' => q({0} قدم مربعة),
						'two' => q({0} قدم مربعة),
						'zero' => q({0} قدم مربعة),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} بوصة مربعة),
						'many' => q({0} بوصة مربعة),
						'name' => q(بوصة مربعة),
						'one' => q({0} بوصة مربعة),
						'other' => q({0} بوصة مربعة),
						'per' => q({0} لكل بوصة مربعة),
						'two' => q({0} بوصة مربعة),
						'zero' => q({0} بوصة مربعة),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} بوصة مربعة),
						'many' => q({0} بوصة مربعة),
						'name' => q(بوصة مربعة),
						'one' => q({0} بوصة مربعة),
						'other' => q({0} بوصة مربعة),
						'per' => q({0} لكل بوصة مربعة),
						'two' => q({0} بوصة مربعة),
						'zero' => q({0} بوصة مربعة),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر مربع),
						'many' => q({0} كيلومتر مربع),
						'name' => q(كيلومتر مربع),
						'one' => q({0} كيلومتر مربع),
						'other' => q({0} كيلومتر مربع),
						'per' => q({0}/كيلومتر مربع),
						'two' => q({0} كيلومتر مربع),
						'zero' => q({0} كيلومتر مربع),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر مربع),
						'many' => q({0} كيلومتر مربع),
						'name' => q(كيلومتر مربع),
						'one' => q({0} كيلومتر مربع),
						'other' => q({0} كيلومتر مربع),
						'per' => q({0}/كيلومتر مربع),
						'two' => q({0} كيلومتر مربع),
						'zero' => q({0} كيلومتر مربع),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'few' => q({0} متر مربع),
						'many' => q({0} متر مربع),
						'name' => q(متر مربع),
						'one' => q({0} متر مربع),
						'other' => q({0} متر مربع),
						'per' => q({0} لكل متر مربع),
						'two' => q({0} متر مربع),
						'zero' => q({0} متر مربع),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'few' => q({0} متر مربع),
						'many' => q({0} متر مربع),
						'name' => q(متر مربع),
						'one' => q({0} متر مربع),
						'other' => q({0} متر مربع),
						'per' => q({0} لكل متر مربع),
						'two' => q({0} متر مربع),
						'zero' => q({0} متر مربع),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} ميل مربع),
						'many' => q({0} ميل مربع),
						'name' => q(ميل مربع),
						'one' => q({0} ميل مربع),
						'other' => q({0} ميل مربع),
						'per' => q({0} لكل ميل مربع),
						'two' => q({0} ميل مربع),
						'zero' => q({0} ميل مربع),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} ميل مربع),
						'many' => q({0} ميل مربع),
						'name' => q(ميل مربع),
						'one' => q({0} ميل مربع),
						'other' => q({0} ميل مربع),
						'per' => q({0} لكل ميل مربع),
						'two' => q({0} ميل مربع),
						'zero' => q({0} ميل مربع),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} ياردة مربعة),
						'many' => q({0} ياردة مربعة),
						'name' => q(ياردة مربعة),
						'one' => q({0} ياردة مربعة),
						'other' => q({0} ياردة مربعة),
						'two' => q({0} ياردة مربعة),
						'zero' => q({0} ياردة مربعة),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} ياردة مربعة),
						'many' => q({0} ياردة مربعة),
						'name' => q(ياردة مربعة),
						'one' => q({0} ياردة مربعة),
						'other' => q({0} ياردة مربعة),
						'two' => q({0} ياردة مربعة),
						'zero' => q({0} ياردة مربعة),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'few' => q({0} عناصر),
						'many' => q({0} عنصرًا),
						'one' => q(عنصر واحد),
						'other' => q({0} عنصر),
						'two' => q(عنصران),
						'zero' => q({0} عنصر),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'few' => q({0} عناصر),
						'many' => q({0} عنصرًا),
						'one' => q(عنصر واحد),
						'other' => q({0} عنصر),
						'two' => q(عنصران),
						'zero' => q({0} عنصر),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغم/ديسيبل),
						'many' => q({0} مغم/ديسيبل),
						'name' => q(مغم/ديسيبل),
						'one' => q({0} مغم/ديسيبل),
						'other' => q({0} مغم/ديسيبل),
						'two' => q({0} مغم/ديسيبل),
						'zero' => q({0} مغم/ديسيبل),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغم/ديسيبل),
						'many' => q({0} مغم/ديسيبل),
						'name' => q(مغم/ديسيبل),
						'one' => q({0} مغم/ديسيبل),
						'other' => q({0} مغم/ديسيبل),
						'two' => q({0} مغم/ديسيبل),
						'zero' => q({0} مغم/ديسيبل),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} ملي مول/لتر),
						'many' => q({0} ملي مول/لتر),
						'name' => q(ملي مول/لتر),
						'one' => q({0} ملي مول/لتر),
						'other' => q({0} ملي مول/لتر),
						'two' => q({0} ملي مول/لتر),
						'zero' => q({0} ملي مول/لتر),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'few' => q({0} ملي مول/لتر),
						'many' => q({0} ملي مول/لتر),
						'name' => q(ملي مول/لتر),
						'one' => q({0} ملي مول/لتر),
						'other' => q({0} ملي مول/لتر),
						'two' => q({0} ملي مول/لتر),
						'zero' => q({0} ملي مول/لتر),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(feminine),
						'few' => q({0}٪),
						'many' => q({0}٪),
						'one' => q({0} بالمائة),
						'other' => q({0} بالمائة),
						'two' => q({0}٪),
						'zero' => q({0}٪),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(feminine),
						'few' => q({0}٪),
						'many' => q({0}٪),
						'one' => q({0} بالمائة),
						'other' => q({0} بالمائة),
						'two' => q({0}٪),
						'zero' => q({0}٪),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'few' => q({0} في الألف),
						'many' => q({0} في الألف),
						'one' => q({0} في الألف),
						'other' => q({0} في الألف),
						'two' => q({0} في الألف),
						'zero' => q({0} في الألف),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'few' => q({0} في الألف),
						'many' => q({0} في الألف),
						'one' => q({0} في الألف),
						'other' => q({0} في الألف),
						'two' => q({0} في الألف),
						'zero' => q({0} في الألف),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(masculine),
						'few' => q({0} أجزاء في المليون),
						'many' => q({0} جزءًا في المليون),
						'name' => q(جزء في المليون),
						'one' => q({0} جزء في المليون),
						'other' => q({0} جزء في المليون),
						'two' => q(جزآن في المليون),
						'zero' => q({0} جزء في المليون),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(masculine),
						'few' => q({0} أجزاء في المليون),
						'many' => q({0} جزءًا في المليون),
						'name' => q(جزء في المليون),
						'one' => q({0} جزء في المليون),
						'other' => q({0} جزء في المليون),
						'two' => q(جزآن في المليون),
						'zero' => q({0} جزء في المليون),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} لترات لكل ١٠٠ كيلومتر),
						'many' => q({0} لترًا لكل ١٠٠ كيلومتر),
						'name' => q(لتر لكل ١٠٠ كيلومتر),
						'one' => q({0} لتر لكل ١٠٠ كيلومتر),
						'other' => q({0} لتر لكل ١٠٠ كيلومتر),
						'two' => q(لتران لكل ١٠٠ كيلومتر),
						'zero' => q({0} لتر لكل ١٠٠ كيلومتر),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} لترات لكل ١٠٠ كيلومتر),
						'many' => q({0} لترًا لكل ١٠٠ كيلومتر),
						'name' => q(لتر لكل ١٠٠ كيلومتر),
						'one' => q({0} لتر لكل ١٠٠ كيلومتر),
						'other' => q({0} لتر لكل ١٠٠ كيلومتر),
						'two' => q(لتران لكل ١٠٠ كيلومتر),
						'zero' => q({0} لتر لكل ١٠٠ كيلومتر),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} لترات لكل كيلومتر),
						'many' => q({0} لترًا لكل كيلومتر),
						'name' => q(لتر لكل كيلومتر),
						'one' => q({0} لتر لكل كيلومتر),
						'other' => q({0} لتر لكل كيلومتر),
						'two' => q(لتران لكل كيلومتر),
						'zero' => q({0} لتر لكل كيلومتر),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} لترات لكل كيلومتر),
						'many' => q({0} لترًا لكل كيلومتر),
						'name' => q(لتر لكل كيلومتر),
						'one' => q({0} لتر لكل كيلومتر),
						'other' => q({0} لتر لكل كيلومتر),
						'two' => q(لتران لكل كيلومتر),
						'zero' => q({0} لتر لكل كيلومتر),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} أميال لكل غالون),
						'many' => q({0} ميلًا لكل غالون),
						'name' => q(ميل لكل غالون),
						'one' => q({0} ميل لكل غالون),
						'other' => q({0} ميل لكل غالون),
						'two' => q(ميلان لكل غالون),
						'zero' => q({0} ميل لكل غالون),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} أميال لكل غالون),
						'many' => q({0} ميلًا لكل غالون),
						'name' => q(ميل لكل غالون),
						'one' => q({0} ميل لكل غالون),
						'other' => q({0} ميل لكل غالون),
						'two' => q(ميلان لكل غالون),
						'zero' => q({0} ميل لكل غالون),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} أميال لكل غالون إمبراطوري),
						'many' => q({0} ميلًا لكل غالون إمبراطوري),
						'name' => q(ميل لكل غالون إمبراطوري),
						'one' => q({0} ميل لكل غالون إمبراطوري),
						'other' => q({0} ميل لكل غالون إمبراطوري),
						'two' => q(ميلان لكل غالون إمبراطوري),
						'zero' => q({0} ميل لكل غالون إمبراطوري),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} أميال لكل غالون إمبراطوري),
						'many' => q({0} ميلًا لكل غالون إمبراطوري),
						'name' => q(ميل لكل غالون إمبراطوري),
						'one' => q({0} ميل لكل غالون إمبراطوري),
						'other' => q({0} ميل لكل غالون إمبراطوري),
						'two' => q(ميلان لكل غالون إمبراطوري),
						'zero' => q({0} ميل لكل غالون إمبراطوري),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} شرقًا),
						'north' => q({0} شمالاً),
						'south' => q({0} جنوبًا),
						'west' => q({0} غربًا),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} شرقًا),
						'north' => q({0} شمالاً),
						'south' => q({0} جنوبًا),
						'west' => q({0} غربًا),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} غيغابايت),
						'many' => q({0} غيغابايت),
						'name' => q(غيغابايت),
						'one' => q({0} غيغابايت),
						'other' => q({0} غيغابايت),
						'two' => q({0} غيغابايت),
						'zero' => q({0} غيغابايت),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'few' => q({0} غيغابايت),
						'many' => q({0} غيغابايت),
						'name' => q(غيغابايت),
						'one' => q({0} غيغابايت),
						'other' => q({0} غيغابايت),
						'two' => q({0} غيغابايت),
						'zero' => q({0} غيغابايت),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'few' => q({0} ميغابايت),
						'many' => q({0} ميغابايت),
						'one' => q({0} ميغابايت),
						'other' => q({0} ميغابايت),
						'two' => q({0} ميغابايت),
						'zero' => q({0} ميغابايت),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'few' => q({0} ميغابايت),
						'many' => q({0} ميغابايت),
						'one' => q({0} ميغابايت),
						'other' => q({0} ميغابايت),
						'two' => q({0} ميغابايت),
						'zero' => q({0} ميغابايت),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(masculine),
						'name' => q(قرون),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(قرون),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'per' => q({0} في اليوم),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'per' => q({0} في اليوم),
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
						'1' => q(masculine),
						'name' => q(عقود),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(masculine),
						'name' => q(عقود),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'few' => q({0} ساعات),
						'many' => q({0} ساعة),
						'name' => q(ساعات),
						'one' => q(ساعة),
						'other' => q({0} ساعة),
						'per' => q({0} في الساعة),
						'two' => q(ساعتان),
						'zero' => q({0} ساعة),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'few' => q({0} ساعات),
						'many' => q({0} ساعة),
						'name' => q(ساعات),
						'one' => q(ساعة),
						'other' => q({0} ساعة),
						'per' => q({0} في الساعة),
						'two' => q(ساعتان),
						'zero' => q({0} ساعة),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} ميكروثانية),
						'many' => q({0} ميكروثانية),
						'name' => q(ميكروثانية),
						'one' => q({0} ميكروثانية),
						'other' => q({0} ميكروثانية),
						'two' => q({0} ميكروثانية),
						'zero' => q({0} ميكروثانية),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} ميكروثانية),
						'many' => q({0} ميكروثانية),
						'name' => q(ميكروثانية),
						'one' => q({0} ميكروثانية),
						'other' => q({0} ميكروثانية),
						'two' => q({0} ميكروثانية),
						'zero' => q({0} ميكروثانية),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} ملي ثانية),
						'many' => q({0} ملي ثانية),
						'one' => q({0} ملي ثانية),
						'other' => q({0} ملي ثانية),
						'two' => q({0} ملي ثانية),
						'zero' => q({0} ملي ثانية),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} ملي ثانية),
						'many' => q({0} ملي ثانية),
						'one' => q({0} ملي ثانية),
						'other' => q({0} ملي ثانية),
						'two' => q({0} ملي ثانية),
						'zero' => q({0} ملي ثانية),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'few' => q({0} دقائق),
						'many' => q({0} دقيقة),
						'name' => q(دقيقة),
						'one' => q(دقيقة),
						'other' => q({0} دقيقة),
						'per' => q({0} كل دقيقة),
						'two' => q(دقيقتان),
						'zero' => q({0} دقيقة),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'few' => q({0} دقائق),
						'many' => q({0} دقيقة),
						'name' => q(دقيقة),
						'one' => q(دقيقة),
						'other' => q({0} دقيقة),
						'per' => q({0} كل دقيقة),
						'two' => q(دقيقتان),
						'zero' => q({0} دقيقة),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'per' => q({0} في الشهر),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'per' => q({0} في الشهر),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} نانو ثانية),
						'many' => q({0} نانو ثانية),
						'name' => q(نانو ثانية),
						'one' => q({0} نانو ثانية),
						'other' => q({0} نانو ثانية),
						'two' => q({0} نانو ثانية),
						'zero' => q({0} نانو ثانية),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} نانو ثانية),
						'many' => q({0} نانو ثانية),
						'name' => q(نانو ثانية),
						'one' => q({0} نانو ثانية),
						'other' => q({0} نانو ثانية),
						'two' => q({0} نانو ثانية),
						'zero' => q({0} نانو ثانية),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'few' => q({0} أرباع سنوية),
						'many' => q({0} ربعًا سنويًا),
						'name' => q(أرباع),
						'one' => q(ربع سنوي),
						'other' => q({0} ربع سنوي),
						'per' => q({0} في الربع السنوي),
						'two' => q(ربعان سنويان),
						'zero' => q({0} ربع سنوي),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'few' => q({0} أرباع سنوية),
						'many' => q({0} ربعًا سنويًا),
						'name' => q(أرباع),
						'one' => q(ربع سنوي),
						'other' => q({0} ربع سنوي),
						'per' => q({0} في الربع السنوي),
						'two' => q(ربعان سنويان),
						'zero' => q({0} ربع سنوي),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} ثوان),
						'many' => q({0} ثانية),
						'one' => q(ثانية),
						'other' => q({0} ثانية),
						'per' => q({0} في الثانية),
						'two' => q(ثانيتان),
						'zero' => q({0} ثانية),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} ثوان),
						'many' => q({0} ثانية),
						'one' => q(ثانية),
						'other' => q({0} ثانية),
						'per' => q({0} في الثانية),
						'two' => q(ثانيتان),
						'zero' => q({0} ثانية),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(masculine),
						'name' => q(أسابيع),
						'per' => q({0} في الأسبوع),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(masculine),
						'name' => q(أسابيع),
						'per' => q({0} في الأسبوع),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(feminine),
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنوات),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'per' => q({0} في السنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(feminine),
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنوات),
						'one' => q(سنة),
						'other' => q({0} سنة),
						'per' => q({0} في السنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'few' => q({0} ملي أمبير),
						'many' => q({0} ملي أمبير),
						'name' => q(ملي أمبير),
						'one' => q({0} ملي أمبير),
						'other' => q({0} ملي أمبير),
						'two' => q({0} ملي أمبير),
						'zero' => q({0} ملي أمبير),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'few' => q({0} ملي أمبير),
						'many' => q({0} ملي أمبير),
						'name' => q(ملي أمبير),
						'one' => q({0} ملي أمبير),
						'other' => q({0} ملي أمبير),
						'two' => q({0} ملي أمبير),
						'zero' => q({0} ملي أمبير),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} وحدات حرارية بريطانية),
						'many' => q({0} وحدة حرارية بريطانية),
						'one' => q({0} وحدة حرارية بريطانية),
						'other' => q({0} وحدة حرارية بريطانية),
						'two' => q(وحدتان حراريتان بريطانيتان),
						'zero' => q({0} وحدة حرارية بريطانية),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} وحدات حرارية بريطانية),
						'many' => q({0} وحدة حرارية بريطانية),
						'one' => q({0} وحدة حرارية بريطانية),
						'other' => q({0} وحدة حرارية بريطانية),
						'two' => q(وحدتان حراريتان بريطانيتان),
						'zero' => q({0} وحدة حرارية بريطانية),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} سعرة),
						'many' => q({0} سعرة),
						'name' => q(سعرة),
						'one' => q({0} سعرة),
						'other' => q({0} سعرة),
						'two' => q({0} سعرة),
						'zero' => q({0} سعرة),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} سعرة),
						'many' => q({0} سعرة),
						'name' => q(سعرة),
						'one' => q({0} سعرة),
						'other' => q({0} سعرة),
						'two' => q({0} سعرة),
						'zero' => q({0} سعرة),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} سعرة),
						'many' => q({0} سعرة),
						'name' => q(سعرة),
						'one' => q({0} سعرة),
						'other' => q({0} سعرة),
						'two' => q({0} سعرة),
						'zero' => q({0} سعرة),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} سعرة),
						'many' => q({0} سعرة),
						'name' => q(سعرة),
						'one' => q({0} سعرة),
						'other' => q({0} سعرة),
						'two' => q({0} سعرة),
						'zero' => q({0} سعرة),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} كيلو سعرة),
						'many' => q({0} كيلو سعرة),
						'name' => q(كيلو سعرة),
						'one' => q({0} كيلو سعرة),
						'other' => q({0} كيلو سعرة),
						'two' => q({0} كيلو سعرة),
						'zero' => q({0} كيلو سعرة),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} كيلو سعرة),
						'many' => q({0} كيلو سعرة),
						'name' => q(كيلو سعرة),
						'one' => q({0} كيلو سعرة),
						'other' => q({0} كيلو سعرة),
						'two' => q({0} كيلو سعرة),
						'zero' => q({0} كيلو سعرة),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} كيلو جول),
						'many' => q({0} كيلو جول),
						'name' => q(كيلو جول),
						'one' => q({0} كيلو جول),
						'other' => q({0} كيلو جول),
						'two' => q({0} كيلو جول),
						'zero' => q({0} كيلو جول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'few' => q({0} كيلو جول),
						'many' => q({0} كيلو جول),
						'name' => q(كيلو جول),
						'one' => q({0} كيلو جول),
						'other' => q({0} كيلو جول),
						'two' => q({0} كيلو جول),
						'zero' => q({0} كيلو جول),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'few' => q({0} كيلو واط/ساعة),
						'many' => q({0} كيلو واط/ساعة),
						'name' => q(كيلو واط/ساعة),
						'one' => q({0} كيلو واط/ساعة),
						'other' => q({0} كيلو واط/ساعة),
						'two' => q({0} كيلو واط/ساعة),
						'zero' => q({0} كيلو واط/ساعة),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'few' => q({0} كيلو واط/ساعة),
						'many' => q({0} كيلو واط/ساعة),
						'name' => q(كيلو واط/ساعة),
						'one' => q({0} كيلو واط/ساعة),
						'other' => q({0} كيلو واط/ساعة),
						'two' => q({0} كيلو واط/ساعة),
						'zero' => q({0} كيلو واط/ساعة),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} وحدات حرارية أمريكية),
						'many' => q({0} وحدة حرارية أمريكية),
						'one' => q({0} وحدة حرارية أمريكية),
						'other' => q({0} وحدة حرارية أمريكية),
						'two' => q(وحدتان حراريتان أمريكيتان),
						'zero' => q({0} وحدة حرارية أمريكية),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} وحدات حرارية أمريكية),
						'many' => q({0} وحدة حرارية أمريكية),
						'one' => q({0} وحدة حرارية أمريكية),
						'other' => q({0} وحدة حرارية أمريكية),
						'two' => q(وحدتان حراريتان أمريكيتان),
						'zero' => q({0} وحدة حرارية أمريكية),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'many' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'name' => q(كيلوواط ساعة لكل 100 كيلومتر),
						'one' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'other' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'two' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'zero' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'many' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'name' => q(كيلوواط ساعة لكل 100 كيلومتر),
						'one' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'other' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'two' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
						'zero' => q({0} كيلوواط ساعة لكل 100 كيلومتر),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} غيغا هرتز),
						'many' => q({0} غيغا هرتز),
						'name' => q(غيغا هرتز),
						'one' => q({0} غيغا هرتز),
						'other' => q({0} غيغا هرتز),
						'two' => q({0} غيغا هرتز),
						'zero' => q({0} غيغا هرتز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'few' => q({0} غيغا هرتز),
						'many' => q({0} غيغا هرتز),
						'name' => q(غيغا هرتز),
						'one' => q({0} غيغا هرتز),
						'other' => q({0} غيغا هرتز),
						'two' => q({0} غيغا هرتز),
						'zero' => q({0} غيغا هرتز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} كيلو هرتز),
						'many' => q({0} كيلو هرتز),
						'name' => q(كيلو هرتز),
						'one' => q({0} كيلو هرتز),
						'other' => q({0} كيلو هرتز),
						'two' => q({0} كيلو هرتز),
						'zero' => q({0} كيلو هرتز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'few' => q({0} كيلو هرتز),
						'many' => q({0} كيلو هرتز),
						'name' => q(كيلو هرتز),
						'one' => q({0} كيلو هرتز),
						'other' => q({0} كيلو هرتز),
						'two' => q({0} كيلو هرتز),
						'zero' => q({0} كيلو هرتز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'few' => q({0} ميغا هرتز),
						'many' => q({0} ميغا هرتز),
						'name' => q(ميغا هرتز),
						'one' => q({0} ميغا هرتز),
						'other' => q({0} ميغا هرتز),
						'two' => q({0} ميغا هرتز),
						'zero' => q({0} ميغا هرتز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'few' => q({0} ميغا هرتز),
						'many' => q({0} ميغا هرتز),
						'name' => q(ميغا هرتز),
						'one' => q({0} ميغا هرتز),
						'other' => q({0} ميغا هرتز),
						'two' => q({0} ميغا هرتز),
						'zero' => q({0} ميغا هرتز),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} نقاط لكل سنتيمتر),
						'many' => q({0} نقطة لكل سنتيمتر),
						'name' => q(نقطة لكل سنتيمتر),
						'one' => q({0} نقطة لكل سنتيمتر),
						'other' => q({0} نقطة لكل سنتيمتر),
						'two' => q(نقطتان لكل سنتيمتر),
						'zero' => q({0} نقطة لكل سنتيمتر),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} نقاط لكل سنتيمتر),
						'many' => q({0} نقطة لكل سنتيمتر),
						'name' => q(نقطة لكل سنتيمتر),
						'one' => q({0} نقطة لكل سنتيمتر),
						'other' => q({0} نقطة لكل سنتيمتر),
						'two' => q(نقطتان لكل سنتيمتر),
						'zero' => q({0} نقطة لكل سنتيمتر),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} نقاط لكل بوصة),
						'many' => q({0} نقطة لكل بوصة),
						'one' => q({0} نقطة لكل بوصة),
						'other' => q({0} نقطة لكل بوصة),
						'two' => q(نقطتان لكل بوصة),
						'zero' => q({0} نقطة لكل بوصة),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} نقاط لكل بوصة),
						'many' => q({0} نقطة لكل بوصة),
						'one' => q({0} نقطة لكل بوصة),
						'other' => q({0} نقطة لكل بوصة),
						'two' => q(نقطتان لكل بوصة),
						'zero' => q({0} نقطة لكل بوصة),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'name' => q(إم مطبعي),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'name' => q(إم مطبعي),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'few' => q({0} ميغابكسل),
						'many' => q({0} ميغابكسل),
						'name' => q(ميغابكسل),
						'one' => q({0} ميغابكسل),
						'other' => q({0} ميغابكسل),
						'two' => q({0} ميغابكسل),
						'zero' => q({0} ميغابكسل),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'few' => q({0} ميغابكسل),
						'many' => q({0} ميغابكسل),
						'name' => q(ميغابكسل),
						'one' => q({0} ميغابكسل),
						'other' => q({0} ميغابكسل),
						'two' => q({0} ميغابكسل),
						'zero' => q({0} ميغابكسل),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} بكسل لكل سنتيمتر),
						'many' => q({0} بكسل لكل سنتيمتر),
						'one' => q({0} بكسل لكل سنتيمتر),
						'other' => q({0} بكسل لكل سنتيمتر),
						'two' => q({0} بكسل لكل سنتيمتر),
						'zero' => q({0} بكسل لكل سنتيمتر),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} بكسل لكل سنتيمتر),
						'many' => q({0} بكسل لكل سنتيمتر),
						'one' => q({0} بكسل لكل سنتيمتر),
						'other' => q({0} بكسل لكل سنتيمتر),
						'two' => q({0} بكسل لكل سنتيمتر),
						'zero' => q({0} بكسل لكل سنتيمتر),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} بكسل لكل بوصة),
						'many' => q({0} بكسل لكل بوصة),
						'one' => q({0} بكسل لكل بوصة),
						'other' => q({0} بكسل لكل بوصة),
						'two' => q({0} بكسل لكل بوصة),
						'zero' => q({0} بكسل لكل بوصة),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} بكسل لكل بوصة),
						'many' => q({0} بكسل لكل بوصة),
						'one' => q({0} بكسل لكل بوصة),
						'other' => q({0} بكسل لكل بوصة),
						'two' => q({0} بكسل لكل بوصة),
						'zero' => q({0} بكسل لكل بوصة),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} وحدة فلكية),
						'many' => q({0} وحدة فلكية),
						'name' => q(وحدة فلكية),
						'one' => q(وحدة فلكية),
						'other' => q({0} وحدة فلكية),
						'two' => q({0} وحدة فلكية),
						'zero' => q({0} وحدة فلكية),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} وحدة فلكية),
						'many' => q({0} وحدة فلكية),
						'name' => q(وحدة فلكية),
						'one' => q(وحدة فلكية),
						'other' => q({0} وحدة فلكية),
						'two' => q({0} وحدة فلكية),
						'zero' => q({0} وحدة فلكية),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر),
						'many' => q({0} سنتيمتر),
						'name' => q(سنتيمتر),
						'one' => q({0} سنتيمتر),
						'other' => q({0} سنتيمتر),
						'per' => q({0}/سنتيمتر),
						'two' => q({0} سنتيمتر),
						'zero' => q({0} سنتيمتر),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر),
						'many' => q({0} سنتيمتر),
						'name' => q(سنتيمتر),
						'one' => q({0} سنتيمتر),
						'other' => q({0} سنتيمتر),
						'per' => q({0}/سنتيمتر),
						'two' => q({0} سنتيمتر),
						'zero' => q({0} سنتيمتر),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'few' => q({0} ديسيمتر),
						'many' => q({0} ديسيمتر),
						'name' => q(ديسيمتر),
						'one' => q({0} ديسيمتر),
						'other' => q({0} ديسيمتر),
						'two' => q({0} ديسيمتر),
						'zero' => q({0} ديسيمتر),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'few' => q({0} ديسيمتر),
						'many' => q({0} ديسيمتر),
						'name' => q(ديسيمتر),
						'one' => q({0} ديسيمتر),
						'other' => q({0} ديسيمتر),
						'two' => q({0} ديسيمتر),
						'zero' => q({0} ديسيمتر),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} نصف قطر أرضي),
						'many' => q({0} نصف قطر أرضي),
						'name' => q(نصف قطر أرضي),
						'one' => q({0} نصف قطر أرضي),
						'other' => q({0} نصف قطر أرضي),
						'two' => q({0} نصف قطر أرضي),
						'zero' => q({0} نصف قطر أرضي),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} نصف قطر أرضي),
						'many' => q({0} نصف قطر أرضي),
						'name' => q(نصف قطر أرضي),
						'one' => q({0} نصف قطر أرضي),
						'other' => q({0} نصف قطر أرضي),
						'two' => q({0} نصف قطر أرضي),
						'zero' => q({0} نصف قطر أرضي),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} لكل قدم),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} لكل قدم),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومترات),
						'many' => q({0} كيلومترًا),
						'name' => q(كيلومتر),
						'one' => q({0} كيلومتر),
						'other' => q({0} كيلومتر),
						'per' => q({0}/كيلومتر),
						'two' => q({0} كيلومتر),
						'zero' => q({0} كيلومتر),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومترات),
						'many' => q({0} كيلومترًا),
						'name' => q(كيلومتر),
						'one' => q({0} كيلومتر),
						'other' => q({0} كيلومتر),
						'per' => q({0}/كيلومتر),
						'two' => q({0} كيلومتر),
						'zero' => q({0} كيلومتر),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'name' => q(متر),
						'one' => q(متر),
						'other' => q({0} متر),
						'per' => q({0} لكل متر),
						'two' => q({0} متر),
						'zero' => q({0} متر),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'name' => q(متر),
						'one' => q(متر),
						'other' => q({0} متر),
						'per' => q({0} لكل متر),
						'two' => q({0} متر),
						'zero' => q({0} متر),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميلاً),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q(ميلان),
						'zero' => q({0} ميل),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميلاً),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q(ميلان),
						'zero' => q({0} ميل),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'few' => q({0} مليمتر),
						'many' => q({0} مليمتر),
						'one' => q({0} مليمتر),
						'other' => q({0} مليمتر),
						'two' => q({0} مليمتر),
						'zero' => q({0} مليمتر),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'few' => q({0} مليمتر),
						'many' => q({0} مليمتر),
						'one' => q({0} مليمتر),
						'other' => q({0} مليمتر),
						'two' => q({0} مليمتر),
						'zero' => q({0} مليمتر),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} نصف قطر شمسي),
						'many' => q({0} نصف قطر شمسي),
						'name' => q(نصف قطر شمسي),
						'one' => q({0} نصف قطر شمسي),
						'other' => q({0} نصف قطر شمسي),
						'two' => q({0} نصف قطر شمسي),
						'zero' => q({0} نصف قطر شمسي),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} نصف قطر شمسي),
						'many' => q({0} نصف قطر شمسي),
						'name' => q(نصف قطر شمسي),
						'one' => q({0} نصف قطر شمسي),
						'other' => q({0} نصف قطر شمسي),
						'two' => q({0} نصف قطر شمسي),
						'zero' => q({0} نصف قطر شمسي),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'few' => q({0} قراريط),
						'many' => q({0} قيراطًا),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q(قيراطان),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'few' => q({0} غرامات),
						'many' => q({0} غرامًا),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'two' => q(غرامان),
						'zero' => q({0} غرام),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'few' => q({0} غرامات),
						'many' => q({0} غرامًا),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'two' => q(غرامان),
						'zero' => q({0} غرام),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'few' => q({0} كيلوغرام),
						'many' => q({0} كيلوغرام),
						'name' => q(كيلوغرام),
						'one' => q({0} كيلوغرام),
						'other' => q({0} كيلوغرام),
						'per' => q({0}/كيلوغرام),
						'two' => q({0} كيلوغرام),
						'zero' => q({0} كيلوغرام),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'few' => q({0} كيلوغرام),
						'many' => q({0} كيلوغرام),
						'name' => q(كيلوغرام),
						'one' => q({0} كيلوغرام),
						'other' => q({0} كيلوغرام),
						'per' => q({0}/كيلوغرام),
						'two' => q({0} كيلوغرام),
						'zero' => q({0} كيلوغرام),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'few' => q({0} ميكروغرام),
						'many' => q({0} ميكروغرام),
						'name' => q(ميكروغرام),
						'one' => q({0} ميكروغرام),
						'other' => q({0} ميكروغرام),
						'two' => q({0} ميكروغرام),
						'zero' => q({0} ميكروغرام),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'few' => q({0} ميكروغرام),
						'many' => q({0} ميكروغرام),
						'name' => q(ميكروغرام),
						'one' => q({0} ميكروغرام),
						'other' => q({0} ميكروغرام),
						'two' => q({0} ميكروغرام),
						'zero' => q({0} ميكروغرام),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'few' => q({0} مليغرام),
						'many' => q({0} مليغرام),
						'name' => q(مليغرام),
						'one' => q({0} مليغرام),
						'other' => q({0} مليغرام),
						'two' => q({0} مليغرام),
						'zero' => q({0} مليغرام),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'few' => q({0} مليغرام),
						'many' => q({0} مليغرام),
						'name' => q(مليغرام),
						'one' => q({0} مليغرام),
						'other' => q({0} مليغرام),
						'two' => q({0} مليغرام),
						'zero' => q({0} مليغرام),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} أونصة),
						'many' => q({0} أونصة),
						'one' => q({0} أونصة),
						'other' => q({0} أونصة),
						'two' => q({0} أونصة),
						'zero' => q({0} أونصة),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} أونصة),
						'many' => q({0} أونصة),
						'one' => q({0} أونصة),
						'other' => q({0} أونصة),
						'two' => q({0} أونصة),
						'zero' => q({0} أونصة),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} رطل),
						'many' => q({0} رطلًا),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'two' => q(رطلان),
						'zero' => q({0} رطل),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} رطل),
						'many' => q({0} رطلًا),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'two' => q(رطلان),
						'zero' => q({0} رطل),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} أطنان),
						'many' => q({0} طنًا),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q(طنان),
						'zero' => q({0} طن),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} أطنان),
						'many' => q({0} طنًا),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q(طنان),
						'zero' => q({0} طن),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(masculine),
						'few' => q({0} طن متري),
						'many' => q({0} طن متري),
						'name' => q(طن متري),
						'one' => q({0} طن متري),
						'other' => q({0} طن متري),
						'two' => q({0} طن متري),
						'zero' => q({0} طن متري),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(masculine),
						'few' => q({0} طن متري),
						'many' => q({0} طن متري),
						'name' => q(طن متري),
						'one' => q({0} طن متري),
						'other' => q({0} طن متري),
						'two' => q({0} طن متري),
						'zero' => q({0} طن متري),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} لكل {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} لكل {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} غيغا واط),
						'many' => q({0} غيغا واط),
						'name' => q(غيغا واط),
						'one' => q({0} غيغا واط),
						'other' => q({0} غيغا واط),
						'two' => q({0} غيغا واط),
						'zero' => q({0} غيغا واط),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'few' => q({0} غيغا واط),
						'many' => q({0} غيغا واط),
						'name' => q(غيغا واط),
						'one' => q({0} غيغا واط),
						'other' => q({0} غيغا واط),
						'two' => q({0} غيغا واط),
						'zero' => q({0} غيغا واط),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} قوة حصان),
						'many' => q({0} قوة حصان),
						'name' => q(قوة حصان),
						'one' => q({0} قوة حصان),
						'other' => q({0} قوة حصان),
						'two' => q({0} قوة حصان),
						'zero' => q({0} قوة حصان),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} قوة حصان),
						'many' => q({0} قوة حصان),
						'name' => q(قوة حصان),
						'one' => q({0} قوة حصان),
						'other' => q({0} قوة حصان),
						'two' => q({0} قوة حصان),
						'zero' => q({0} قوة حصان),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(كيلوواط),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(كيلوواط),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'few' => q({0} ميغا واط),
						'many' => q({0} ميغا واط),
						'name' => q(ميغا واط),
						'one' => q({0} ميغا واط),
						'other' => q({0} ميغا واط),
						'two' => q({0} ميغا واط),
						'zero' => q({0} ميغا واط),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'few' => q({0} ميغا واط),
						'many' => q({0} ميغا واط),
						'name' => q(ميغا واط),
						'one' => q({0} ميغا واط),
						'other' => q({0} ميغا واط),
						'two' => q({0} ميغا واط),
						'zero' => q({0} ميغا واط),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0} مربّعة),
						'many' => q({0} مربّعًا),
						'one' => q({0} مربّع),
						'other' => q({0} مربّع),
						'two' => q({0} مربّعان),
						'zero' => q({0} مربّع),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0} مربّعة),
						'many' => q({0} مربّعًا),
						'one' => q({0} مربّع),
						'other' => q({0} مربّع),
						'two' => q({0} مربّعان),
						'zero' => q({0} مربّع),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0} مكعّبة),
						'many' => q({0} مكعبًا),
						'one' => q({0} مكعّب),
						'other' => q({0} مكعّب),
						'two' => q({0} مكعّبان),
						'zero' => q({0} مكعّب),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0} مكعّبة),
						'many' => q({0} مكعبًا),
						'one' => q({0} مكعّب),
						'other' => q({0} مكعّب),
						'two' => q({0} مكعّبان),
						'zero' => q({0} مكعّب),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(masculine),
						'few' => q({0} ض.ج),
						'many' => q({0} ض.ج),
						'name' => q(وحدة الضغط الجوي),
						'one' => q({0} ضغط جوي),
						'other' => q({0} ضغط جوي),
						'two' => q({0} ض.ج),
						'zero' => q({0} ض.ج),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(masculine),
						'few' => q({0} ض.ج),
						'many' => q({0} ض.ج),
						'name' => q(وحدة الضغط الجوي),
						'one' => q({0} ضغط جوي),
						'other' => q({0} ضغط جوي),
						'two' => q({0} ض.ج),
						'zero' => q({0} ض.ج),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} بوصة زئبقية),
						'many' => q({0} بوصة زئبقية),
						'name' => q(بوصة زئبقية),
						'one' => q({0} بوصة زئبقية),
						'other' => q({0} بوصة زئبقية),
						'two' => q({0} بوصة زئبقية),
						'zero' => q({0} بوصة زئبقية),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} بوصة زئبقية),
						'many' => q({0} بوصة زئبقية),
						'name' => q(بوصة زئبقية),
						'one' => q({0} بوصة زئبقية),
						'other' => q({0} بوصة زئبقية),
						'two' => q({0} بوصة زئبقية),
						'zero' => q({0} بوصة زئبقية),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} كيلوباسكال),
						'many' => q({0} كيلوباسكال),
						'name' => q(كيلوباسكال),
						'one' => q({0} كيلوباسكال),
						'other' => q({0} كيلوباسكال),
						'two' => q({0} كيلوباسكال),
						'zero' => q({0} كيلوباسكال),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'few' => q({0} كيلوباسكال),
						'many' => q({0} كيلوباسكال),
						'name' => q(كيلوباسكال),
						'one' => q({0} كيلوباسكال),
						'other' => q({0} كيلوباسكال),
						'two' => q({0} كيلوباسكال),
						'zero' => q({0} كيلوباسكال),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'few' => q({0} ميغاباسكال),
						'many' => q({0} ميغاباسكال),
						'name' => q(ميغاباسكال),
						'one' => q({0} ميغاباسكال),
						'other' => q({0} ميغاباسكال),
						'two' => q({0} ميغاباسكال),
						'zero' => q({0} ميغاباسكال),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'few' => q({0} ميغاباسكال),
						'many' => q({0} ميغاباسكال),
						'name' => q(ميغاباسكال),
						'one' => q({0} ميغاباسكال),
						'other' => q({0} ميغاباسكال),
						'two' => q({0} ميغاباسكال),
						'zero' => q({0} ميغاباسكال),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'few' => q({0} ملي بار),
						'many' => q({0} ملي بار),
						'name' => q(ملي بار),
						'one' => q({0} ملي بار),
						'other' => q({0} ملي بار),
						'two' => q({0} ملي بار),
						'zero' => q({0} ملي بار),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'few' => q({0} ملي بار),
						'many' => q({0} ملي بار),
						'name' => q(ملي بار),
						'one' => q({0} ملي بار),
						'other' => q({0} ملي بار),
						'two' => q({0} ملي بار),
						'zero' => q({0} ملي بار),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} مليمتر زئبقي),
						'many' => q({0} مليمتر زئبقي),
						'name' => q(مليمتر زئبقي),
						'one' => q({0} مليمتر زئبقي),
						'other' => q({0} مليمتر زئبقي),
						'two' => q({0} مليمتر زئبقي),
						'zero' => q({0} مليمتر زئبقي),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} مليمتر زئبقي),
						'many' => q({0} مليمتر زئبقي),
						'name' => q(مليمتر زئبقي),
						'one' => q({0} مليمتر زئبقي),
						'other' => q({0} مليمتر زئبقي),
						'two' => q({0} مليمتر زئبقي),
						'zero' => q({0} مليمتر زئبقي),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} رطل لكل بوصة مربعة),
						'many' => q({0} رطل لكل بوصة مربعة),
						'name' => q(رطل لكل بوصة مربعة),
						'one' => q({0} رطل لكل بوصة مربعة),
						'other' => q({0} رطل لكل بوصة مربعة),
						'two' => q({0} رطل لكل بوصة مربعة),
						'zero' => q({0} رطل لكل بوصة مربعة),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} رطل لكل بوصة مربعة),
						'many' => q({0} رطل لكل بوصة مربعة),
						'name' => q(رطل لكل بوصة مربعة),
						'one' => q({0} رطل لكل بوصة مربعة),
						'other' => q({0} رطل لكل بوصة مربعة),
						'two' => q({0} رطل لكل بوصة مربعة),
						'zero' => q({0} رطل لكل بوصة مربعة),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر في الساعة),
						'many' => q({0} كيلومتر في الساعة),
						'name' => q(كيلومتر في الساعة),
						'one' => q({0} كيلومتر في الساعة),
						'other' => q({0} كيلومتر في الساعة),
						'two' => q({0} كيلومتر في الساعة),
						'zero' => q({0} كيلومتر في الساعة),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر في الساعة),
						'many' => q({0} كيلومتر في الساعة),
						'name' => q(كيلومتر في الساعة),
						'one' => q({0} كيلومتر في الساعة),
						'other' => q({0} كيلومتر في الساعة),
						'two' => q({0} كيلومتر في الساعة),
						'zero' => q({0} كيلومتر في الساعة),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} متر في الثانية),
						'many' => q({0} متر في الثانية),
						'name' => q(متر في الثانية),
						'one' => q({0} متر في الثانية),
						'other' => q({0} متر في الثانية),
						'two' => q({0} متر في الثانية),
						'zero' => q({0} متر في الثانية),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'few' => q({0} متر في الثانية),
						'many' => q({0} متر في الثانية),
						'name' => q(متر في الثانية),
						'one' => q({0} متر في الثانية),
						'other' => q({0} متر في الثانية),
						'two' => q({0} متر في الثانية),
						'zero' => q({0} متر في الثانية),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} ميل في الساعة),
						'many' => q({0} ميل في الساعة),
						'name' => q(ميل في الساعة),
						'one' => q({0} ميل في الساعة),
						'other' => q({0} ميل في الساعة),
						'two' => q({0} ميل في الساعة),
						'zero' => q({0} ميل في الساعة),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} ميل في الساعة),
						'many' => q({0} ميل في الساعة),
						'name' => q(ميل في الساعة),
						'one' => q({0} ميل في الساعة),
						'other' => q({0} ميل في الساعة),
						'two' => q({0} ميل في الساعة),
						'zero' => q({0} ميل في الساعة),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(feminine),
						'few' => q({0} درجة مئوية),
						'many' => q({0} درجة مئوية),
						'one' => q({0} درجة مئوية),
						'other' => q({0} درجة مئوية),
						'two' => q({0} درجة مئوية),
						'zero' => q({0} درجة مئوية),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(feminine),
						'few' => q({0} درجة مئوية),
						'many' => q({0} درجة مئوية),
						'one' => q({0} درجة مئوية),
						'other' => q({0} درجة مئوية),
						'two' => q({0} درجة مئوية),
						'zero' => q({0} درجة مئوية),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} درجة فهرنهايت),
						'many' => q({0} درجة فهرنهايت),
						'one' => q({0} درجة فهرنهايت),
						'other' => q({0} درجة فهرنهايت),
						'two' => q({0} درجة فهرنهايت),
						'zero' => q({0} درجة فهرنهايت),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} درجة فهرنهايت),
						'many' => q({0} درجة فهرنهايت),
						'one' => q({0} درجة فهرنهايت),
						'other' => q({0} درجة فهرنهايت),
						'two' => q({0} درجة فهرنهايت),
						'zero' => q({0} درجة فهرنهايت),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(feminine),
						'few' => q({0} درجة كلفن),
						'many' => q({0} درجة كلفن),
						'name' => q(درجة كلفن),
						'one' => q({0} درجة كلفن),
						'other' => q({0} درجة كلفن),
						'two' => q({0} درجة كلفن),
						'zero' => q({0} درجة كلفن),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(feminine),
						'few' => q({0} درجة كلفن),
						'many' => q({0} درجة كلفن),
						'name' => q(درجة كلفن),
						'one' => q({0} درجة كلفن),
						'other' => q({0} درجة كلفن),
						'two' => q({0} درجة كلفن),
						'zero' => q({0} درجة كلفن),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر مكعب),
						'many' => q({0} سنتيمتر مكعب),
						'name' => q(سنتيمتر مكعب),
						'one' => q({0} سنتيمتر مكعب),
						'other' => q({0} سنتيمتر مكعب),
						'per' => q({0}/سنتيمتر مكعب),
						'two' => q({0} سنتيمتر مكعب),
						'zero' => q({0} سنتيمتر مكعب),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'few' => q({0} سنتيمتر مكعب),
						'many' => q({0} سنتيمتر مكعب),
						'name' => q(سنتيمتر مكعب),
						'one' => q({0} سنتيمتر مكعب),
						'other' => q({0} سنتيمتر مكعب),
						'per' => q({0}/سنتيمتر مكعب),
						'two' => q({0} سنتيمتر مكعب),
						'zero' => q({0} سنتيمتر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} قدم مكعبة),
						'many' => q({0} قدم مكعبة),
						'name' => q(قدم مكعبة),
						'one' => q(قدم مكعبة),
						'other' => q({0} قدم مكعبة),
						'two' => q({0} قدم مكعبة),
						'zero' => q({0} قدم مكعبة),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} قدم مكعبة),
						'many' => q({0} قدم مكعبة),
						'name' => q(قدم مكعبة),
						'one' => q(قدم مكعبة),
						'other' => q({0} قدم مكعبة),
						'two' => q({0} قدم مكعبة),
						'zero' => q({0} قدم مكعبة),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر مكعب),
						'many' => q({0} كيلومتر مكعب),
						'name' => q(كيلومتر مكعب),
						'one' => q({0} كيلومتر مكعب),
						'other' => q({0} كيلومتر مكعب),
						'two' => q({0} كيلومتر مكعب),
						'zero' => q({0} كيلومتر مكعب),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'few' => q({0} كيلومتر مكعب),
						'many' => q({0} كيلومتر مكعب),
						'name' => q(كيلومتر مكعب),
						'one' => q({0} كيلومتر مكعب),
						'other' => q({0} كيلومتر مكعب),
						'two' => q({0} كيلومتر مكعب),
						'zero' => q({0} كيلومتر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} متر مكعب),
						'many' => q({0} متر مكعب),
						'name' => q(متر مكعب),
						'one' => q({0} متر مكعب),
						'other' => q({0} متر مكعب),
						'per' => q({0}/متر مكعب),
						'two' => q({0} متر مكعب),
						'zero' => q({0} متر مكعب),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'few' => q({0} متر مكعب),
						'many' => q({0} متر مكعب),
						'name' => q(متر مكعب),
						'one' => q({0} متر مكعب),
						'other' => q({0} متر مكعب),
						'per' => q({0}/متر مكعب),
						'two' => q({0} متر مكعب),
						'zero' => q({0} متر مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} ميل مكعب),
						'many' => q({0} ميل مكعب),
						'name' => q(ميل مكعب),
						'one' => q({0} ميل مكعب),
						'other' => q({0} ميل مكعب),
						'two' => q({0} ميل مكعب),
						'zero' => q({0} ميل مكعب),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} ميل مكعب),
						'many' => q({0} ميل مكعب),
						'name' => q(ميل مكعب),
						'one' => q({0} ميل مكعب),
						'other' => q({0} ميل مكعب),
						'two' => q({0} ميل مكعب),
						'zero' => q({0} ميل مكعب),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} ياردة مكعبة),
						'many' => q({0} ياردة مكعبة),
						'name' => q(ياردة مكعبة),
						'one' => q({0} ياردة مكعبة),
						'other' => q({0} ياردة مكعبة),
						'two' => q({0} ياردة مكعبة),
						'zero' => q({0} ياردة مكعبة),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} ياردة مكعبة),
						'many' => q({0} ياردة مكعبة),
						'name' => q(ياردة مكعبة),
						'one' => q({0} ياردة مكعبة),
						'other' => q({0} ياردة مكعبة),
						'two' => q({0} ياردة مكعبة),
						'zero' => q({0} ياردة مكعبة),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} أكواب),
						'many' => q({0} كوبًا),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q(كوبان),
						'zero' => q({0} كوب),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} أكواب),
						'many' => q({0} كوبًا),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q(كوبان),
						'zero' => q({0} كوب),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} ملعقة حلو),
						'many' => q({0} ملعقة حلو),
						'name' => q(ملعقة حلو),
						'one' => q({0} ملعقة حلو),
						'other' => q({0} ملعقة حلو),
						'two' => q({0} ملعقة حلو),
						'zero' => q({0} ملعقة حلو),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} ملعقة حلو),
						'many' => q({0} ملعقة حلو),
						'name' => q(ملعقة حلو),
						'one' => q({0} ملعقة حلو),
						'other' => q({0} ملعقة حلو),
						'two' => q({0} ملعقة حلو),
						'zero' => q({0} ملعقة حلو),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} ملعقة حلو إمبراطوري),
						'many' => q({0} ملعقة حلو إمبراطوري),
						'one' => q({0} ملعقة حلو إمبراطوري),
						'other' => q({0} ملعقة حلو إمبراطوري),
						'two' => q({0} ملعقة حلو إمبراطوري),
						'zero' => q({0} ملعقة حلو إمبراطوري),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} ملعقة حلو إمبراطوري),
						'many' => q({0} ملعقة حلو إمبراطوري),
						'one' => q({0} ملعقة حلو إمبراطوري),
						'other' => q({0} ملعقة حلو إمبراطوري),
						'two' => q({0} ملعقة حلو إمبراطوري),
						'zero' => q({0} ملعقة حلو إمبراطوري),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} درهم سائل),
						'many' => q({0} درهم سائل),
						'one' => q({0} درهم),
						'other' => q({0} درهم),
						'two' => q({0} درهم سائل),
						'zero' => q({0} درهم سائل),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} درهم سائل),
						'many' => q({0} درهم سائل),
						'one' => q({0} درهم),
						'other' => q({0} درهم),
						'two' => q({0} درهم سائل),
						'zero' => q({0} درهم سائل),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} قطرات),
						'many' => q({0} قطرة),
						'one' => q({0} قطرة),
						'other' => q({0} قطرة),
						'two' => q(قطرتان),
						'zero' => q({0} قطرة),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} قطرات),
						'many' => q({0} قطرة),
						'one' => q({0} قطرة),
						'other' => q({0} قطرة),
						'two' => q(قطرتان),
						'zero' => q({0} قطرة),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} أونصة سائلة),
						'many' => q({0} أونصة سائلة),
						'one' => q(أونصة سائلة),
						'other' => q({0} أونصة سائلة),
						'two' => q(أونصتان سائلتان),
						'zero' => q({0} أونصة سائلة),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} أونصة سائلة),
						'many' => q({0} أونصة سائلة),
						'one' => q(أونصة سائلة),
						'other' => q({0} أونصة سائلة),
						'two' => q(أونصتان سائلتان),
						'zero' => q({0} أونصة سائلة),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} أونصات سائلة إمبراطورية),
						'many' => q({0} أونصة سائلة إمبراطورية),
						'one' => q({0} أونصة سائلة إمبراطورية),
						'other' => q({0} أونصة سائلة إمبراطورية),
						'two' => q(أونصتان سائلتان إمبراطوريتان),
						'zero' => q({0} أونصة سائلة إمبراطورية),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} أونصات سائلة إمبراطورية),
						'many' => q({0} أونصة سائلة إمبراطورية),
						'one' => q({0} أونصة سائلة إمبراطورية),
						'other' => q({0} أونصة سائلة إمبراطورية),
						'two' => q(أونصتان سائلتان إمبراطوريتان),
						'zero' => q({0} أونصة سائلة إمبراطورية),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} لكل غالون),
					},
					# Core Unit Identifier
					'gallon' => {
						'per' => q({0} لكل غالون),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} غالون إمبراطوري),
						'many' => q({0} غالون إمبراطوري),
						'one' => q(غالون إمبراطوري),
						'other' => q({0} غالون إمبراطوري),
						'per' => q({0} لكل غالون إمبراطوري),
						'two' => q({0} غالون إمبراطوري),
						'zero' => q({0} غالون إمبراطوري),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} غالون إمبراطوري),
						'many' => q({0} غالون إمبراطوري),
						'one' => q(غالون إمبراطوري),
						'other' => q({0} غالون إمبراطوري),
						'per' => q({0} لكل غالون إمبراطوري),
						'two' => q({0} غالون إمبراطوري),
						'zero' => q({0} غالون إمبراطوري),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'per' => q({0} لكل لتر),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'per' => q({0} لكل لتر),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'few' => q({0} مليلتر),
						'many' => q({0} مليلتر),
						'name' => q(مليلتر),
						'one' => q({0} مليلتر),
						'other' => q({0} مليلتر),
						'two' => q({0} مليلتر),
						'zero' => q({0} مليلتر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'few' => q({0} مليلتر),
						'many' => q({0} مليلتر),
						'name' => q(مليلتر),
						'one' => q({0} مليلتر),
						'other' => q({0} مليلتر),
						'two' => q({0} مليلتر),
						'zero' => q({0} مليلتر),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} رشّات),
						'many' => q({0} رشّة),
						'one' => q({0} رشّة),
						'other' => q({0} رشّة),
						'two' => q({0} رشّة),
						'zero' => q({0} رشّة),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} رشّات),
						'many' => q({0} رشّة),
						'one' => q({0} رشّة),
						'other' => q({0} رشّة),
						'two' => q({0} رشّة),
						'zero' => q({0} رشّة),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} ملعقة كبيرة),
						'many' => q({0} ملعقة كبيرة),
						'one' => q(ملعقة كبيرة),
						'other' => q({0} ملعقة كبيرة),
						'two' => q({0} ملعقة كبيرة),
						'zero' => q({0} ملعقة كبيرة),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} ملعقة كبيرة),
						'many' => q({0} ملعقة كبيرة),
						'one' => q(ملعقة كبيرة),
						'other' => q({0} ملعقة كبيرة),
						'two' => q({0} ملعقة كبيرة),
						'zero' => q({0} ملعقة كبيرة),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} ملعقة صغيرة),
						'many' => q({0} ملعقة صغيرة),
						'name' => q(ملعقة صغيرة),
						'one' => q(ملعقة صغيرة),
						'other' => q({0} ملعقة صغيرة),
						'two' => q({0} ملعقة صغيرة),
						'zero' => q({0} ملعقة صغيرة),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} ملعقة صغيرة),
						'many' => q({0} ملعقة صغيرة),
						'name' => q(ملعقة صغيرة),
						'one' => q(ملعقة صغيرة),
						'other' => q({0} ملعقة صغيرة),
						'two' => q({0} ملعقة صغيرة),
						'zero' => q({0} ملعقة صغيرة),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ر{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ر{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(كويكتو.{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(كويكتو.{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(رونا.{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(رونا.{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(ك{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(ك{0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} د قوسية),
						'many' => q({0} د قوسية),
						'name' => q(د قوسية),
						'one' => q({0} د قوسية),
						'other' => q({0} د قوسية),
						'two' => q({0} د قوسية),
						'zero' => q({0} د قوسية),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} د قوسية),
						'many' => q({0} د قوسية),
						'name' => q(د قوسية),
						'one' => q({0} د قوسية),
						'other' => q({0} د قوسية),
						'two' => q({0} د قوسية),
						'zero' => q({0} د قوسية),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} ث قوسية),
						'many' => q({0} ث قوسية),
						'name' => q(ث قوسية),
						'one' => q({0} ث قوسية),
						'other' => q({0} ث قوسية),
						'two' => q({0} ث قوسية),
						'zero' => q({0} ث قوسية),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} ث قوسية),
						'many' => q({0} ث قوسية),
						'name' => q(ث قوسية),
						'one' => q({0} ث قوسية),
						'other' => q({0} ث قوسية),
						'two' => q({0} ث قوسية),
						'zero' => q({0} ث قوسية),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} درجات),
						'many' => q({0} درجة),
						'one' => q({0} درجة),
						'other' => q({0} درجة),
						'two' => q(درجتان),
						'zero' => q({0} درجة),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} درجات),
						'many' => q({0} درجة),
						'one' => q({0} درجة),
						'other' => q({0} درجة),
						'two' => q(درجتان),
						'zero' => q({0} درجة),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} عنصر),
						'many' => q({0} عنصر),
						'one' => q(عنصر),
						'other' => q({0} عنصر),
						'two' => q({0} عنصر),
						'zero' => q({0} عنصر),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} عنصر),
						'many' => q({0} عنصر),
						'one' => q(عنصر),
						'other' => q({0} عنصر),
						'two' => q({0} عنصر),
						'zero' => q({0} عنصر),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغ/ديسبل),
						'many' => q({0} مغ/ديسبل),
						'name' => q(مغ/ديسبل),
						'one' => q({0} مغ/ديسبل),
						'other' => q({0} مغ/ديسبل),
						'two' => q({0} مغ/ديسبل),
						'zero' => q({0} مغ/ديسبل),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغ/ديسبل),
						'many' => q({0} مغ/ديسبل),
						'name' => q(مغ/ديسبل),
						'one' => q({0} مغ/ديسبل),
						'other' => q({0} مغ/ديسبل),
						'two' => q({0} مغ/ديسبل),
						'zero' => q({0} مغ/ديسبل),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(٪),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(٪),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(؉),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(؉),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ؊),
						'many' => q({0} ؊),
						'name' => q(؊),
						'one' => q({0} ؊),
						'other' => q({0} ؊),
						'two' => q({0} ؊),
						'zero' => q({0} ؊),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ؊),
						'many' => q({0} ؊),
						'name' => q(؊),
						'one' => q({0} ؊),
						'other' => q({0} ؊),
						'two' => q({0} ؊),
						'zero' => q({0} ؊),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} ل/١٠٠كم),
						'many' => q({0} ل/١٠٠كم),
						'name' => q(ل/١٠٠كم),
						'one' => q({0} ل/١٠٠كم),
						'other' => q({0} ل/١٠٠كم),
						'two' => q({0} ل/١٠٠كم),
						'zero' => q({0} ل/١٠٠كم),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} ل/١٠٠كم),
						'many' => q({0} ل/١٠٠كم),
						'name' => q(ل/١٠٠كم),
						'one' => q({0} ل/١٠٠كم),
						'other' => q({0} ل/١٠٠كم),
						'two' => q({0} ل/١٠٠كم),
						'zero' => q({0} ل/١٠٠كم),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} ل/كم),
						'many' => q({0} ل/كم),
						'name' => q(ل/كم),
						'one' => q({0} ل/كم),
						'other' => q({0} ل/كم),
						'two' => q({0} ل/كم),
						'zero' => q({0} ل/كم),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} ل/كم),
						'many' => q({0} ل/كم),
						'name' => q(ل/كم),
						'one' => q({0} ل/كم),
						'other' => q({0} ل/كم),
						'two' => q({0} ل/كم),
						'zero' => q({0} ل/كم),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} ب),
						'many' => q({0} ب),
						'name' => q(ب),
						'one' => q({0} ب),
						'other' => q({0} ب),
						'two' => q({0} ب),
						'zero' => q({0} ب),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} ب),
						'many' => q({0} ب),
						'name' => q(ب),
						'one' => q({0} ب),
						'other' => q({0} ب),
						'two' => q({0} ب),
						'zero' => q({0} ب),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} غ.بت),
						'many' => q({0} غ.بت),
						'name' => q(غ.بت),
						'one' => q({0} غ.بت),
						'other' => q({0} غ.بت),
						'two' => q({0} غ.بت),
						'zero' => q({0} غ.بت),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} غ.بت),
						'many' => q({0} غ.بت),
						'name' => q(غ.بت),
						'one' => q({0} غ.بت),
						'other' => q({0} غ.بت),
						'two' => q({0} غ.بت),
						'zero' => q({0} غ.بت),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} ك.بت),
						'many' => q({0} ك.بت),
						'name' => q(ك.بت),
						'one' => q({0} ك.بت),
						'other' => q({0} ك.بت),
						'two' => q({0} ك.بت),
						'zero' => q({0} ك.بت),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} ك.بت),
						'many' => q({0} ك.بت),
						'name' => q(ك.بت),
						'one' => q({0} ك.بت),
						'other' => q({0} ك.بت),
						'two' => q({0} ك.بت),
						'zero' => q({0} ك.بت),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} ك.ب),
						'many' => q({0} ك.ب),
						'name' => q(ك.ب),
						'one' => q({0} ك.ب),
						'other' => q({0} ك.ب),
						'two' => q({0} ك.ب),
						'zero' => q({0} ك.ب),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} ك.ب),
						'many' => q({0} ك.ب),
						'name' => q(ك.ب),
						'one' => q({0} ك.ب),
						'other' => q({0} ك.ب),
						'two' => q({0} ك.ب),
						'zero' => q({0} ك.ب),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} م.بت),
						'many' => q({0} م.بت),
						'name' => q(م.بت),
						'one' => q({0} م.بت),
						'other' => q({0} م.بت),
						'two' => q({0} م.بت),
						'zero' => q({0} م.بت),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} م.بت),
						'many' => q({0} م.بت),
						'name' => q(م.بت),
						'one' => q({0} م.بت),
						'other' => q({0} م.بت),
						'two' => q({0} م.بت),
						'zero' => q({0} م.بت),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(م.ب),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(م.ب),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} ت.بت),
						'many' => q({0} ت.بت),
						'name' => q(ت.بت),
						'one' => q({0} ت.بت),
						'other' => q({0} ت.بت),
						'two' => q({0} ت.بت),
						'zero' => q({0} ت.بت),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} ت.بت),
						'many' => q({0} ت.بت),
						'name' => q(ت.بت),
						'one' => q({0} ت.بت),
						'other' => q({0} ت.بت),
						'two' => q({0} ت.بت),
						'zero' => q({0} ت.بت),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} ت.ب),
						'many' => q({0} ت.ب),
						'name' => q(ت.ب),
						'one' => q({0} ت.ب),
						'other' => q({0} ت.ب),
						'two' => q({0} ت.ب),
						'zero' => q({0} ت.ب),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} ت.ب),
						'many' => q({0} ت.ب),
						'name' => q(ت.ب),
						'one' => q({0} ت.ب),
						'other' => q({0} ت.ب),
						'two' => q({0} ت.ب),
						'zero' => q({0} ت.ب),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} ي),
						'many' => q({0} ي),
						'name' => q(يوم),
						'one' => q({0} ي),
						'other' => q({0} ي),
						'two' => q({0} ي),
						'zero' => q({0} ي),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} ي),
						'many' => q({0} ي),
						'name' => q(يوم),
						'one' => q({0} ي),
						'other' => q({0} ي),
						'two' => q({0} ي),
						'zero' => q({0} ي),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ملي ث.),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ملي ث.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(شهر),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(شهر),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ربع),
						'per' => q({0}/ر),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ربع),
						'per' => q({0}/ر),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ث),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ث),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} أ),
						'many' => q({0} أ),
						'one' => q({0} أ),
						'other' => q({0} أ),
						'two' => q({0} أ),
						'zero' => q({0} أ),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} أ),
						'many' => q({0} أ),
						'one' => q({0} أ),
						'other' => q({0} أ),
						'two' => q({0} أ),
						'zero' => q({0} أ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} سنة),
						'many' => q({0} سنة),
						'one' => q({0} سنة),
						'other' => q({0} سنة),
						'two' => q({0} سنة),
						'zero' => q({0} سنة),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} سنة),
						'many' => q({0} سنة),
						'one' => q({0} سنة),
						'other' => q({0} سنة),
						'two' => q({0} سنة),
						'zero' => q({0} سنة),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} ك سع),
						'many' => q({0} ك سع),
						'name' => q(ك سع),
						'one' => q({0} ك سع),
						'other' => q({0} ك سع),
						'two' => q({0} ك سع),
						'zero' => q({0} ك سع),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} ك سع),
						'many' => q({0} ك سع),
						'name' => q(ك سع),
						'one' => q({0} ك سع),
						'other' => q({0} ك سع),
						'two' => q({0} ك سع),
						'zero' => q({0} ك سع),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} ك.و.س/100 كم),
						'many' => q({0} ك.و.س/100 كم),
						'name' => q(ك.و.س/100 كم),
						'one' => q({0} ك.و.س/100 كم),
						'other' => q({0} ك.و.س/100 كم),
						'two' => q({0} ك.و.س/100 كم),
						'zero' => q({0} ك.و.س/100 كم),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} ك.و.س/100 كم),
						'many' => q({0} ك.و.س/100 كم),
						'name' => q(ك.و.س/100 كم),
						'one' => q({0} ك.و.س/100 كم),
						'other' => q({0} ك.و.س/100 كم),
						'two' => q({0} ك.و.س/100 كم),
						'zero' => q({0} ك.و.س/100 كم),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} ن/سم),
						'many' => q({0} ن/سم),
						'name' => q(ن/سم),
						'one' => q({0} ن/سم),
						'other' => q({0} ن/سم),
						'two' => q({0} ن/سم),
						'zero' => q({0} ن/سم),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} ن/سم),
						'many' => q({0} ن/سم),
						'name' => q(ن/سم),
						'one' => q({0} ن/سم),
						'other' => q({0} ن/سم),
						'two' => q({0} ن/سم),
						'zero' => q({0} ن/سم),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} ن/بوصة),
						'many' => q({0} ن/بوصة),
						'one' => q({0} ن/بوصة),
						'other' => q({0} ن/بوصة),
						'two' => q({0} ن/بوصة),
						'zero' => q({0} ن/بوصة),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} ن/بوصة),
						'many' => q({0} ن/بوصة),
						'one' => q({0} ن/بوصة),
						'other' => q({0} ن/بوصة),
						'two' => q({0} ن/بوصة),
						'zero' => q({0} ن/بوصة),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} م.بك),
						'many' => q({0} م.بك),
						'one' => q({0} م.بك),
						'other' => q({0} م.بك),
						'two' => q({0} م.بك),
						'zero' => q({0} م.بك),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} م.بك),
						'many' => q({0} م.بك),
						'one' => q({0} م.بك),
						'other' => q({0} م.بك),
						'two' => q({0} م.بك),
						'zero' => q({0} م.بك),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} بك/سم),
						'many' => q({0} بك/سم),
						'name' => q(بكسل/سم),
						'one' => q({0} بك/سم),
						'other' => q({0} بك/سم),
						'two' => q({0} بك/سم),
						'zero' => q({0} بك/سم),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} بك/سم),
						'many' => q({0} بك/سم),
						'name' => q(بكسل/سم),
						'one' => q({0} بك/سم),
						'other' => q({0} بك/سم),
						'two' => q({0} بك/سم),
						'zero' => q({0} بك/سم),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} بك/بوصة),
						'many' => q({0} بك/بوصة),
						'name' => q(بكسل/بوصة),
						'one' => q({0} بك/بوصة),
						'other' => q({0} بك/بوصة),
						'two' => q({0} بك/بوصة),
						'zero' => q({0} بك/بوصة),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} بك/بوصة),
						'many' => q({0} بك/بوصة),
						'name' => q(بكسل/بوصة),
						'one' => q({0} بك/بوصة),
						'other' => q({0} بك/بوصة),
						'two' => q({0} بك/بوصة),
						'zero' => q({0} بك/بوصة),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} قدم),
						'many' => q({0} قدمًا),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'two' => q({0} قدم),
						'zero' => q({0} قدم),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} قدم),
						'many' => q({0} قدمًا),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'two' => q({0} قدم),
						'zero' => q({0} قدم),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} س ض),
						'many' => q({0} س ض),
						'one' => q({0} س ض),
						'other' => q({0} س ض),
						'two' => q({0} س ض),
						'zero' => q({0}س ض),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} س ض),
						'many' => q({0} س ض),
						'one' => q({0} س ض),
						'other' => q({0} س ض),
						'two' => q({0} س ض),
						'zero' => q({0}س ض),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} م),
						'many' => q({0} م),
						'one' => q({0} م),
						'other' => q({0} م),
						'two' => q({0} م),
						'zero' => q({0} م),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} م),
						'many' => q({0} م),
						'one' => q({0} م),
						'other' => q({0} م),
						'two' => q({0} م),
						'zero' => q({0} م),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميلاً),
						'one' => q({0} ميل),
						'other' => q({0} ميل),
						'two' => q({0} ميل),
						'zero' => q({0} ميل),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} أميال),
						'many' => q({0} ميلاً),
						'one' => q({0} ميل),
						'other' => q({0} ميل),
						'two' => q({0} ميل),
						'zero' => q({0} ميل),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(مم),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(مم),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} ياردة),
						'many' => q({0} ياردة),
						'one' => q({0} ياردة),
						'other' => q({0} ياردة),
						'two' => q({0} ياردة),
						'zero' => q({0} ياردة),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} ياردة),
						'many' => q({0} ياردة),
						'one' => q({0} ياردة),
						'other' => q({0} ياردة),
						'two' => q({0} ياردة),
						'zero' => q({0} ياردة),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} غ),
						'many' => q({0} غ),
						'name' => q(غ),
						'one' => q({0} غ),
						'other' => q({0} غ),
						'per' => q({0} غ),
						'two' => q({0} غ),
						'zero' => q({0} غ),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} غ),
						'many' => q({0} غ),
						'name' => q(غ),
						'one' => q({0} غ),
						'other' => q({0} غ),
						'per' => q({0} غ),
						'two' => q({0} غ),
						'zero' => q({0} غ),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} كغ),
						'many' => q({0} كغ),
						'name' => q(كغ),
						'one' => q({0} كغ),
						'other' => q({0} كغ),
						'per' => q({0}/كغ),
						'two' => q({0} كغ),
						'zero' => q({0} كغ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} كغ),
						'many' => q({0} كغ),
						'name' => q(كغ),
						'one' => q({0} كغ),
						'other' => q({0} كغ),
						'per' => q({0}/كغ),
						'two' => q({0} كغ),
						'zero' => q({0} كغ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} ك واط),
						'many' => q({0} ك واط),
						'one' => q({0} ك واط),
						'other' => q({0} ك واط),
						'two' => q({0} ك واط),
						'zero' => q({0} ك واط),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} ك واط),
						'many' => q({0} ك واط),
						'one' => q({0} ك واط),
						'other' => q({0} ك واط),
						'two' => q({0} ك واط),
						'zero' => q({0} ك واط),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} ب ز),
						'many' => q({0} ب ز),
						'name' => q(ب ز),
						'one' => q({0} ب ز),
						'other' => q({0} ب ز),
						'two' => q({0} ب ز),
						'zero' => q({0} ب ز),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} ب ز),
						'many' => q({0} ب ز),
						'name' => q(ب ز),
						'one' => q({0} ب ز),
						'other' => q({0} ب ز),
						'two' => q({0} ب ز),
						'zero' => q({0} ب ز),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(رطل/بوصة²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(رطل/بوصة²),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°م),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°م),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°ف),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°ف),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} نيوتن م),
						'many' => q({0} نيوتن م),
						'name' => q(نيوتن م),
						'one' => q({0} نيوتن م),
						'other' => q({0} نيوتن م),
						'two' => q({0} نيوتن م),
						'zero' => q({0} نيوتن م),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} نيوتن م),
						'many' => q({0} نيوتن م),
						'name' => q(نيوتن م),
						'one' => q({0} نيوتن م),
						'other' => q({0} نيوتن م),
						'two' => q({0} نيوتن م),
						'zero' => q({0} نيوتن م),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} برميل),
						'many' => q({0} برميل),
						'one' => q(برميل),
						'other' => q({0} برميل),
						'two' => q({0} برميل),
						'zero' => q({0} برميل),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} برميل),
						'many' => q({0} برميل),
						'one' => q(برميل),
						'other' => q({0} برميل),
						'two' => q({0} برميل),
						'zero' => q({0} برميل),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} بوصة³),
						'many' => q({0} بوصة³),
						'name' => q(بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q({0} بوصة³),
						'zero' => q({0} بوصة³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} بوصة³),
						'many' => q({0} بوصة³),
						'name' => q(بوصة³),
						'one' => q({0} بوصة³),
						'other' => q({0} بوصة³),
						'two' => q({0} بوصة³),
						'zero' => q({0} بوصة³),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} أونصة س),
						'many' => q({0} أونصة س),
						'name' => q(أونصة س),
						'one' => q(أونصة س),
						'other' => q({0} أونصة س),
						'two' => q({0} أونصة س),
						'zero' => q({0} أونصة س),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} أونصة س),
						'many' => q({0} أونصة س),
						'name' => q(أونصة س),
						'one' => q(أونصة س),
						'other' => q({0} أونصة س),
						'two' => q({0} أونصة س),
						'zero' => q({0} أونصة س),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} أونصة س إمبراطورية),
						'many' => q({0} أونصة س إمبراطورية),
						'name' => q(أونصة س إمبراطورية),
						'one' => q(أونصة س إمبراطورية),
						'other' => q({0} أونصة س إمبراطورية),
						'two' => q({0} أونصة س إمبراطورية),
						'zero' => q({0} أونصة س إمبراطورية),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} أونصة س إمبراطورية),
						'many' => q({0} أونصة س إمبراطورية),
						'name' => q(أونصة س إمبراطورية),
						'one' => q(أونصة س إمبراطورية),
						'other' => q({0} أونصة س إمبراطورية),
						'two' => q({0} أونصة س إمبراطورية),
						'zero' => q({0} أونصة س إمبراطورية),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} قدح),
						'many' => q({0} قدح),
						'one' => q(قدح),
						'other' => q({0} قدح),
						'two' => q({0} قدح),
						'zero' => q({0} قدح),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} قدح),
						'many' => q({0} قدح),
						'one' => q(قدح),
						'other' => q({0} قدح),
						'two' => q({0} قدح),
						'zero' => q({0} قدح),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} ل),
						'many' => q({0} ل),
						'one' => q({0} ل),
						'other' => q({0} ل),
						'two' => q({0} ل),
						'zero' => q({0} ل),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} ل),
						'many' => q({0} ل),
						'one' => q({0} ل),
						'other' => q({0} ل),
						'two' => q({0} ل),
						'zero' => q({0} ل),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} ملعقة ك),
						'many' => q({0} ملعقة ك),
						'name' => q(ملعقة ك),
						'one' => q(ملعقة ك),
						'other' => q({0} ملعقة ك),
						'two' => q({0} ملعقة ك),
						'zero' => q({0} ملعقة ك),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} ملعقة ك),
						'many' => q({0} ملعقة ك),
						'name' => q(ملعقة ك),
						'one' => q(ملعقة ك),
						'other' => q({0} ملعقة ك),
						'two' => q({0} ملعقة ك),
						'zero' => q({0} ملعقة ك),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(اتجاه),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(اتجاه),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(كيبي.{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(كيبي.{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(ميبي.{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(ميبي.{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(غيبي.{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(غيبي.{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(تيبي.{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(تيبي.{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(بيبي.{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(بيبي.{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(إكسبي.{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(إكسبي.{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(زيبي.{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(زيبي.{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(يوبي.{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(يوبي.{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(د{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(د{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(ب{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(ب{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(ف{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(ف{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(أ{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(أ{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(س{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(س{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(زيب{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(زيب{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(يك{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(يك{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(رونتو{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(رونتو{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(م{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(م{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(كويكتو{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(كويكتو{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(مك{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(مك{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(ن{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(ن{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(دا{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(دا{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(ت{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(ت{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(بتا{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(بتا{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(إ.{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(إ.{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(ه{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(ه{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(زت{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(زت{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(ي{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(ي{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(رونا{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(رونا{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(كيلو{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(كيلو{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(كويتا.{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(كويتا.{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(مغ{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(مغ{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(غ{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(غ{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} قوة تسارع),
						'many' => q({0} قوة تسارع),
						'name' => q(قوة تسارع),
						'one' => q({0} قوة تسارع),
						'other' => q({0} قوة تسارع),
						'two' => q({0} قوة تسارع),
						'zero' => q({0} قوة تسارع),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} قوة تسارع),
						'many' => q({0} قوة تسارع),
						'name' => q(قوة تسارع),
						'one' => q({0} قوة تسارع),
						'other' => q({0} قوة تسارع),
						'two' => q({0} قوة تسارع),
						'zero' => q({0} قوة تسارع),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} م/ث²),
						'many' => q({0} م/ث²),
						'name' => q(م/ث²),
						'one' => q({0} م/ث²),
						'other' => q({0} م/ث²),
						'two' => q({0} م/ث²),
						'zero' => q({0} م/ث²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} م/ث²),
						'many' => q({0} م/ث²),
						'name' => q(م/ث²),
						'one' => q({0} م/ث²),
						'other' => q({0} م/ث²),
						'two' => q({0} م/ث²),
						'zero' => q({0} م/ث²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} دقائق قوسية),
						'many' => q({0} دقيقة قوسية),
						'name' => q(دقيقة قوسية),
						'one' => q(دقيقة قوسية),
						'other' => q({0} دقيقة قوسية),
						'two' => q(دقيقتان قوسيتان),
						'zero' => q({0} دقيقة قوسية),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} دقائق قوسية),
						'many' => q({0} دقيقة قوسية),
						'name' => q(دقيقة قوسية),
						'one' => q(دقيقة قوسية),
						'other' => q({0} دقيقة قوسية),
						'two' => q(دقيقتان قوسيتان),
						'zero' => q({0} دقيقة قوسية),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} ثوانٍ قوسية),
						'many' => q({0} ثانية قوسية),
						'name' => q(ثانية قوسية),
						'one' => q(ثانية قوسية),
						'other' => q({0} ثانية قوسية),
						'two' => q(ثانيتان قوسيتان),
						'zero' => q({0} ثانية قوسية),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} ثوانٍ قوسية),
						'many' => q({0} ثانية قوسية),
						'name' => q(ثانية قوسية),
						'one' => q(ثانية قوسية),
						'other' => q({0} ثانية قوسية),
						'two' => q(ثانيتان قوسيتان),
						'zero' => q({0} ثانية قوسية),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} درجات),
						'many' => q({0} درجة),
						'name' => q(درجة),
						'one' => q(درجة),
						'other' => q({0} درجة),
						'two' => q(درجتان),
						'zero' => q({0} درجة),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} درجات),
						'many' => q({0} درجة),
						'name' => q(درجة),
						'one' => q(درجة),
						'other' => q({0} درجة),
						'two' => q(درجتان),
						'zero' => q({0} درجة),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} راديان),
						'many' => q({0} راديان),
						'name' => q(راديان),
						'one' => q({0} راديان),
						'other' => q({0} راديان),
						'two' => q({0} راديان),
						'zero' => q({0} راديان),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} راديان),
						'many' => q({0} راديان),
						'name' => q(راديان),
						'one' => q({0} راديان),
						'other' => q({0} راديان),
						'two' => q({0} راديان),
						'zero' => q({0} راديان),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} دورة),
						'many' => q({0} دورة),
						'name' => q(دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q({0} دورة),
						'zero' => q({0} دورة),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} دورة),
						'many' => q({0} دورة),
						'name' => q(دورة),
						'one' => q(دورة),
						'other' => q({0} دورة),
						'two' => q({0} دورة),
						'zero' => q({0} دورة),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} فدان),
						'many' => q({0} فدان),
						'name' => q(فدان),
						'one' => q(فدان),
						'other' => q({0} فدان),
						'two' => q({0} فدان),
						'zero' => q({0} فدان),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} فدان),
						'many' => q({0} فدان),
						'name' => q(فدان),
						'one' => q(فدان),
						'other' => q({0} فدان),
						'two' => q({0} فدان),
						'zero' => q({0} فدان),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} دونم),
						'many' => q({0} دونم),
						'name' => q(دونم),
						'one' => q({0} دونم),
						'other' => q({0} دونم),
						'two' => q({0} دونم),
						'zero' => q({0} دونم),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} دونم),
						'many' => q({0} دونم),
						'name' => q(دونم),
						'one' => q({0} دونم),
						'other' => q({0} دونم),
						'two' => q({0} دونم),
						'zero' => q({0} دونم),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} هكتار),
						'many' => q({0} هكتار),
						'name' => q(هكتار),
						'one' => q({0} هكتار),
						'other' => q({0} هكتار),
						'two' => q({0} هكتار),
						'zero' => q({0} هكتار),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} هكتار),
						'many' => q({0} هكتار),
						'name' => q(هكتار),
						'one' => q({0} هكتار),
						'other' => q({0} هكتار),
						'two' => q({0} هكتار),
						'zero' => q({0} هكتار),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} سم²),
						'many' => q({0} سم²),
						'name' => q(سم ²),
						'one' => q({0} سم²),
						'other' => q({0} سم²),
						'per' => q({0}/سم²),
						'two' => q({0} سم²),
						'zero' => q({0} سم²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} سم²),
						'many' => q({0} سم²),
						'name' => q(سم ²),
						'one' => q({0} سم²),
						'other' => q({0} سم²),
						'per' => q({0}/سم²),
						'two' => q({0} سم²),
						'zero' => q({0} سم²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} قدم²),
						'many' => q({0} قدم²),
						'name' => q(قدم²),
						'one' => q({0} قدم²),
						'other' => q({0} قدم²),
						'two' => q({0} قدم²),
						'zero' => q({0} قدم²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} قدم²),
						'many' => q({0} قدم²),
						'name' => q(قدم²),
						'one' => q({0} قدم²),
						'other' => q({0} قدم²),
						'two' => q({0} قدم²),
						'zero' => q({0} قدم²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} بوصة²),
						'many' => q({0} بوصة²),
						'name' => q(بوصة²),
						'one' => q({0} بوصة²),
						'other' => q({0} بوصة²),
						'per' => q({0}/بوصة²),
						'two' => q({0} بوصة²),
						'zero' => q({0} بوصة²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} بوصة²),
						'many' => q({0} بوصة²),
						'name' => q(بوصة²),
						'one' => q({0} بوصة²),
						'other' => q({0} بوصة²),
						'per' => q({0}/بوصة²),
						'two' => q({0} بوصة²),
						'zero' => q({0} بوصة²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} كم²),
						'many' => q({0} كم²),
						'name' => q(كم²),
						'one' => q({0} كم²),
						'other' => q({0} كم²),
						'per' => q({0}/كم²),
						'two' => q({0} كم²),
						'zero' => q({0} كم²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} كم²),
						'many' => q({0} كم²),
						'name' => q(كم²),
						'one' => q({0} كم²),
						'other' => q({0} كم²),
						'per' => q({0}/كم²),
						'two' => q({0} كم²),
						'zero' => q({0} كم²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} م²),
						'many' => q({0} م²),
						'name' => q(م²),
						'one' => q({0} م²),
						'other' => q({0} م²),
						'per' => q({0}/م²),
						'two' => q({0} م²),
						'zero' => q({0} م²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} م²),
						'many' => q({0} م²),
						'name' => q(م²),
						'one' => q({0} م²),
						'other' => q({0} م²),
						'per' => q({0}/م²),
						'two' => q({0} م²),
						'zero' => q({0} م²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} ميل²),
						'many' => q({0} ميل²),
						'name' => q(ميل²),
						'one' => q({0} ميل²),
						'other' => q({0} ميل²),
						'per' => q({0}/ميل²),
						'two' => q({0} ميل²),
						'zero' => q({0} ميل²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} ميل²),
						'many' => q({0} ميل²),
						'name' => q(ميل²),
						'one' => q({0} ميل²),
						'other' => q({0} ميل²),
						'per' => q({0}/ميل²),
						'two' => q({0} ميل²),
						'zero' => q({0} ميل²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} ياردة²),
						'many' => q({0} ياردة²),
						'name' => q(ياردة²),
						'one' => q({0} ياردة²),
						'other' => q({0} ياردة²),
						'two' => q({0} ياردة²),
						'zero' => q({0} ياردة²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} ياردة²),
						'many' => q({0} ياردة²),
						'name' => q(ياردة²),
						'one' => q({0} ياردة²),
						'other' => q({0} ياردة²),
						'two' => q({0} ياردة²),
						'zero' => q({0} ياردة²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} عناصر),
						'many' => q({0} عنصرًا),
						'name' => q(عنصر),
						'one' => q(عنصر),
						'other' => q({0} عنصر),
						'two' => q(عنصران),
						'zero' => q({0} عنصر),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} عناصر),
						'many' => q({0} عنصرًا),
						'name' => q(عنصر),
						'one' => q(عنصر),
						'other' => q({0} عنصر),
						'two' => q(عنصران),
						'zero' => q({0} عنصر),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} قيراط),
						'many' => q({0} قيراط),
						'name' => q(قيراط),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q({0} قيراط),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} قيراط),
						'many' => q({0} قيراط),
						'name' => q(قيراط),
						'one' => q(قيراط),
						'other' => q({0} قيراط),
						'two' => q({0} قيراط),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغم/ديسبل),
						'many' => q({0} مغم/ديسبل),
						'name' => q(مغم/ديسبل),
						'one' => q({0} مغم/ديسبل),
						'other' => q({0} مغم/ديسبل),
						'two' => q({0} مغم/ديسبل),
						'zero' => q({0} مغم/ديسبل),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} مغم/ديسبل),
						'many' => q({0} مغم/ديسبل),
						'name' => q(مغم/ديسبل),
						'one' => q({0} مغم/ديسبل),
						'other' => q({0} مغم/ديسبل),
						'two' => q({0} مغم/ديسبل),
						'zero' => q({0} مغم/ديسبل),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} م.مول/ل),
						'many' => q({0} م.مول/ل),
						'name' => q(م.مول/ل),
						'one' => q({0} م.مول/ل),
						'other' => q({0} م.مول/ل),
						'two' => q({0} م.مول/ل),
						'zero' => q({0} م.مول/ل),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} م.مول/ل),
						'many' => q({0} م.مول/ل),
						'name' => q(م.مول/ل),
						'one' => q({0} م.مول/ل),
						'other' => q({0} م.مول/ل),
						'two' => q({0} م.مول/ل),
						'zero' => q({0} م.مول/ل),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} مول),
						'many' => q({0} مول),
						'name' => q(مول),
						'one' => q({0} مول),
						'other' => q({0} مول),
						'two' => q({0} مول),
						'zero' => q({0} مول),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} مول),
						'many' => q({0} مول),
						'name' => q(مول),
						'one' => q({0} مول),
						'other' => q({0} مول),
						'two' => q({0} مول),
						'zero' => q({0} مول),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0}٪),
						'many' => q({0}٪),
						'name' => q(بالمائة),
						'one' => q({0}٪),
						'other' => q({0}٪),
						'two' => q({0}٪),
						'zero' => q({0}٪),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0}٪),
						'many' => q({0}٪),
						'name' => q(بالمائة),
						'one' => q({0}٪),
						'other' => q({0}٪),
						'two' => q({0}٪),
						'zero' => q({0}٪),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0}؉),
						'many' => q({0}؉),
						'name' => q(في الألف),
						'one' => q({0}؉),
						'other' => q({0}؉),
						'two' => q({0}؉),
						'zero' => q({0}؉),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0}؉),
						'many' => q({0}؉),
						'name' => q(في الألف),
						'one' => q({0}؉),
						'other' => q({0}؉),
						'two' => q({0}؉),
						'zero' => q({0}؉),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} جزء/مليون),
						'many' => q({0} جزء/مليون),
						'name' => q(جزء/مليون),
						'one' => q({0} جزء/مليون),
						'other' => q({0} جزء/مليون),
						'two' => q({0} جزء/مليون),
						'zero' => q({0} جزء/مليون),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} جزء/مليون),
						'many' => q({0} جزء/مليون),
						'name' => q(جزء/مليون),
						'one' => q({0} جزء/مليون),
						'other' => q({0} جزء/مليون),
						'two' => q({0} جزء/مليون),
						'zero' => q({0} جزء/مليون),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} لتر/١٠٠ كم),
						'many' => q({0} لتر/١٠٠ كم),
						'name' => q(لتر/‏١٠٠ كم),
						'one' => q({0} لتر/١٠٠ كم),
						'other' => q({0} لتر/١٠٠ كم),
						'two' => q({0} لتر/١٠٠ كم),
						'zero' => q({0} لتر/١٠٠ كم),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} لتر/١٠٠ كم),
						'many' => q({0} لتر/١٠٠ كم),
						'name' => q(لتر/‏١٠٠ كم),
						'one' => q({0} لتر/١٠٠ كم),
						'other' => q({0} لتر/١٠٠ كم),
						'two' => q({0} لتر/١٠٠ كم),
						'zero' => q({0} لتر/١٠٠ كم),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} لتر/كم),
						'many' => q({0} لتر/كم),
						'name' => q(لتر/كم),
						'one' => q({0} لتر/كم),
						'other' => q({0} لتر/كم),
						'two' => q({0} لتر/كم),
						'zero' => q({0} لتر/كم),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} لتر/كم),
						'many' => q({0} لتر/كم),
						'name' => q(لتر/كم),
						'one' => q({0} لتر/كم),
						'other' => q({0} لتر/كم),
						'two' => q({0} لتر/كم),
						'zero' => q({0} لتر/كم),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} ميل/غالون),
						'many' => q({0} ميل/غالون),
						'name' => q(ميل/غالون),
						'one' => q({0} ميل/غالون),
						'other' => q({0} ميل/غالون),
						'two' => q({0} ميل/غالون),
						'zero' => q({0} ميل/غالون),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} ميل/غالون),
						'many' => q({0} ميل/غالون),
						'name' => q(ميل/غالون),
						'one' => q({0} ميل/غالون),
						'other' => q({0} ميل/غالون),
						'two' => q({0} ميل/غالون),
						'zero' => q({0} ميل/غالون),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} ميل/غ. إمبراطوري),
						'many' => q({0} ميل/غ. إمبراطوري),
						'name' => q(ميل/غ. إمبراطوري),
						'one' => q({0} ميل/غ. إمبراطوري),
						'other' => q({0} ميل/غ. إمبراطوري),
						'two' => q({0} ميل/غ. إمبراطوري),
						'zero' => q({0} ميل/غ. إمبراطوري),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} ميل/غ. إمبراطوري),
						'many' => q({0} ميل/غ. إمبراطوري),
						'name' => q(ميل/غ. إمبراطوري),
						'one' => q({0} ميل/غ. إمبراطوري),
						'other' => q({0} ميل/غ. إمبراطوري),
						'two' => q({0} ميل/غ. إمبراطوري),
						'zero' => q({0} ميل/غ. إمبراطوري),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} شرق),
						'north' => q({0} شمال),
						'south' => q({0} ج),
						'west' => q({0} غ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} شرق),
						'north' => q({0} شمال),
						'south' => q({0} ج),
						'west' => q({0} غ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} بت),
						'many' => q({0} بت),
						'name' => q(بت),
						'one' => q({0} بت),
						'other' => q({0} بت),
						'two' => q({0} بت),
						'zero' => q({0} بت),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} بت),
						'many' => q({0} بت),
						'name' => q(بت),
						'one' => q({0} بت),
						'other' => q({0} بت),
						'two' => q({0} بت),
						'zero' => q({0} بت),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} بايت),
						'many' => q({0} بايت),
						'name' => q(بايت),
						'one' => q({0} بايت),
						'other' => q({0} بايت),
						'two' => q({0} بايت),
						'zero' => q({0} بايت),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} بايت),
						'many' => q({0} بايت),
						'name' => q(بايت),
						'one' => q({0} بايت),
						'other' => q({0} بايت),
						'two' => q({0} بايت),
						'zero' => q({0} بايت),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} غيغابت),
						'many' => q({0} غيغابت),
						'name' => q(غيغابت),
						'one' => q({0} غيغابت),
						'other' => q({0} غيغابت),
						'two' => q({0} غيغابت),
						'zero' => q({0} غيغابت),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} غيغابت),
						'many' => q({0} غيغابت),
						'name' => q(غيغابت),
						'one' => q({0} غيغابت),
						'other' => q({0} غيغابت),
						'two' => q({0} غيغابت),
						'zero' => q({0} غيغابت),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} غ.ب),
						'many' => q({0} غ.ب),
						'name' => q(غ.ب),
						'one' => q({0} غ.ب),
						'other' => q({0} غ.ب),
						'two' => q({0} غ.ب),
						'zero' => q({0} غ.ب),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} غ.ب),
						'many' => q({0} غ.ب),
						'name' => q(غ.ب),
						'one' => q({0} غ.ب),
						'other' => q({0} غ.ب),
						'two' => q({0} غ.ب),
						'zero' => q({0} غ.ب),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} كيلوبت),
						'many' => q({0} كيلوبت),
						'name' => q(كيلوبت),
						'one' => q({0} كيلوبت),
						'other' => q({0} كيلوبت),
						'two' => q({0} كيلوبت),
						'zero' => q({0} كيلوبت),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} كيلوبت),
						'many' => q({0} كيلوبت),
						'name' => q(كيلوبت),
						'one' => q({0} كيلوبت),
						'other' => q({0} كيلوبت),
						'two' => q({0} كيلوبت),
						'zero' => q({0} كيلوبت),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} كيلوبايت),
						'many' => q({0} كيلوبايت),
						'name' => q(كيلوبايت),
						'one' => q({0} كيلوبايت),
						'other' => q({0} كيلوبايت),
						'two' => q({0} كيلوبايت),
						'zero' => q({0} كيلوبايت),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} كيلوبايت),
						'many' => q({0} كيلوبايت),
						'name' => q(كيلوبايت),
						'one' => q({0} كيلوبايت),
						'other' => q({0} كيلوبايت),
						'two' => q({0} كيلوبايت),
						'zero' => q({0} كيلوبايت),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} ميغابت),
						'many' => q({0} ميغابت),
						'name' => q(ميغابت),
						'one' => q({0} ميغابت),
						'other' => q({0} ميغابت),
						'two' => q({0} ميغابت),
						'zero' => q({0} ميغابت),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} ميغابت),
						'many' => q({0} ميغابت),
						'name' => q(ميغابت),
						'one' => q({0} ميغابت),
						'other' => q({0} ميغابت),
						'two' => q({0} ميغابت),
						'zero' => q({0} ميغابت),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} م.ب),
						'many' => q({0} م.ب),
						'name' => q(ميغابايت),
						'one' => q({0} م.ب),
						'other' => q({0} م.ب),
						'two' => q({0} م.ب),
						'zero' => q({0} م.ب),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} م.ب),
						'many' => q({0} م.ب),
						'name' => q(ميغابايت),
						'one' => q({0} م.ب),
						'other' => q({0} م.ب),
						'two' => q({0} م.ب),
						'zero' => q({0} م.ب),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} بيتابايت),
						'many' => q({0} بيتابايت),
						'name' => q(بيتابايت),
						'one' => q({0} بيتابايت),
						'other' => q({0} بيتابايت),
						'two' => q({0} بيتابايت),
						'zero' => q({0} بيتابايت),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} بيتابايت),
						'many' => q({0} بيتابايت),
						'name' => q(بيتابايت),
						'one' => q({0} بيتابايت),
						'other' => q({0} بيتابايت),
						'two' => q({0} بيتابايت),
						'zero' => q({0} بيتابايت),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} تيرابت),
						'many' => q({0} تيرابت),
						'name' => q(تيرابت),
						'one' => q({0} تيرابت),
						'other' => q({0} تيرابت),
						'two' => q({0} تيرابت),
						'zero' => q({0} تيرابت),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} تيرابت),
						'many' => q({0} تيرابت),
						'name' => q(تيرابت),
						'one' => q({0} تيرابت),
						'other' => q({0} تيرابت),
						'two' => q({0} تيرابت),
						'zero' => q({0} تيرابت),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} تيرابايت),
						'many' => q({0} تيرابايت),
						'name' => q(تيرابايت),
						'one' => q({0} تيرابايت),
						'other' => q({0} تيرابايت),
						'two' => q({0} تيرابايت),
						'zero' => q({0} تيرابايت),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} تيرابايت),
						'many' => q({0} تيرابايت),
						'name' => q(تيرابايت),
						'one' => q({0} تيرابايت),
						'other' => q({0} تيرابايت),
						'two' => q({0} تيرابايت),
						'zero' => q({0} تيرابايت),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} قرون),
						'many' => q({0} قرنًا),
						'name' => q(قرن),
						'one' => q(قرن),
						'other' => q({0} قرن),
						'two' => q(قرنان),
						'zero' => q({0} قرن),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} قرون),
						'many' => q({0} قرنًا),
						'name' => q(قرن),
						'one' => q(قرن),
						'other' => q({0} قرن),
						'two' => q(قرنان),
						'zero' => q({0} قرن),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} أيام),
						'many' => q({0} يومًا),
						'name' => q(أيام),
						'one' => q(يوم),
						'other' => q({0} يوم),
						'per' => q({0}/ي),
						'two' => q(يومان),
						'zero' => q({0} يوم),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} أيام),
						'many' => q({0} يومًا),
						'name' => q(أيام),
						'one' => q(يوم),
						'other' => q({0} يوم),
						'per' => q({0}/ي),
						'two' => q(يومان),
						'zero' => q({0} يوم),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} عقود),
						'many' => q({0} عقدًا),
						'name' => q(عقد),
						'one' => q(عقد),
						'other' => q({0} عقد),
						'two' => q(عقدان),
						'zero' => q({0} عقد),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} عقود),
						'many' => q({0} عقدًا),
						'name' => q(عقد),
						'one' => q(عقد),
						'other' => q({0} عقد),
						'two' => q(عقدان),
						'zero' => q({0} عقد),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} س),
						'many' => q({0} س),
						'name' => q(ساعة),
						'one' => q({0} س),
						'other' => q({0} س),
						'per' => q({0}/س),
						'two' => q({0} س),
						'zero' => q({0} س),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} س),
						'many' => q({0} س),
						'name' => q(ساعة),
						'one' => q({0} س),
						'other' => q({0} س),
						'per' => q({0}/س),
						'two' => q({0} س),
						'zero' => q({0} س),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} م.ث.),
						'many' => q({0} م.ث.),
						'name' => q(م.ث.),
						'one' => q({0} م.ث.),
						'other' => q({0} م.ث.),
						'two' => q({0} م.ث.),
						'zero' => q({0} م.ث.),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} م.ث.),
						'many' => q({0} م.ث.),
						'name' => q(م.ث.),
						'one' => q({0} م.ث.),
						'other' => q({0} م.ث.),
						'two' => q({0} م.ث.),
						'zero' => q({0} م.ث.),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} ملي ث),
						'many' => q({0} ملي ث),
						'name' => q(ملي ثانية),
						'one' => q({0} ملي ث),
						'other' => q({0} ملي ث),
						'two' => q({0} ملي ث),
						'zero' => q({0} ملي ث),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} ملي ث),
						'many' => q({0} ملي ث),
						'name' => q(ملي ثانية),
						'one' => q({0} ملي ث),
						'other' => q({0} ملي ث),
						'two' => q({0} ملي ث),
						'zero' => q({0} ملي ث),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} د),
						'many' => q({0} د),
						'name' => q(د),
						'one' => q({0} د),
						'other' => q({0} د),
						'per' => q({0}/د),
						'two' => q({0} د),
						'zero' => q({0} د),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} د),
						'many' => q({0} د),
						'name' => q(د),
						'one' => q({0} د),
						'other' => q({0} د),
						'per' => q({0}/د),
						'two' => q({0} د),
						'zero' => q({0} د),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} أشهر),
						'many' => q({0} شهرًا),
						'name' => q(شهور),
						'one' => q(شهر),
						'other' => q({0} شهر),
						'per' => q({0}/ش),
						'two' => q(شهران),
						'zero' => q({0} شهر),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} أشهر),
						'many' => q({0} شهرًا),
						'name' => q(شهور),
						'one' => q(شهر),
						'other' => q({0} شهر),
						'per' => q({0}/ش),
						'two' => q(شهران),
						'zero' => q({0} شهر),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} ن.ث.),
						'many' => q({0} ن.ث.),
						'name' => q(ن.ث.),
						'one' => q({0} ن.ث.),
						'other' => q({0} ن.ث.),
						'two' => q({0} ن.ث.),
						'zero' => q({0} ن.ث.),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} ن.ث.),
						'many' => q({0} ن.ث.),
						'name' => q(ن.ث.),
						'one' => q({0} ن.ث.),
						'other' => q({0} ن.ث.),
						'two' => q({0} ن.ث.),
						'zero' => q({0} ن.ث.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} أرباع),
						'many' => q({0} ربعًا),
						'name' => q(ربع سنوي),
						'one' => q(ربع),
						'other' => q({0} ربع),
						'per' => q({0}/ربع سنوي),
						'two' => q(ربعان),
						'zero' => q({0} ربع),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} أرباع),
						'many' => q({0} ربعًا),
						'name' => q(ربع سنوي),
						'one' => q(ربع),
						'other' => q({0} ربع),
						'per' => q({0}/ربع سنوي),
						'two' => q(ربعان),
						'zero' => q({0} ربع),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} ث),
						'many' => q({0} ث),
						'name' => q(ثانية),
						'one' => q({0} ث),
						'other' => q({0} ث),
						'per' => q({0}/ث),
						'two' => q({0} ث),
						'zero' => q({0} ث),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} ث),
						'many' => q({0} ث),
						'name' => q(ثانية),
						'one' => q({0} ث),
						'other' => q({0} ث),
						'per' => q({0}/ث),
						'two' => q({0} ث),
						'zero' => q({0} ث),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} أسابيع),
						'many' => q({0} أسبوعًا),
						'name' => q(أسبوع),
						'one' => q(أسبوع),
						'other' => q({0} أسبوع),
						'per' => q({0}/أ),
						'two' => q(أسبوعان),
						'zero' => q({0} أسبوع),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} أسابيع),
						'many' => q({0} أسبوعًا),
						'name' => q(أسبوع),
						'one' => q(أسبوع),
						'other' => q({0} أسبوع),
						'per' => q({0}/أ),
						'two' => q(أسبوعان),
						'zero' => q({0} أسبوع),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنة),
						'one' => q(سنة واحدة),
						'other' => q({0} سنة),
						'per' => q({0}/سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} سنوات),
						'many' => q({0} سنة),
						'name' => q(سنة),
						'one' => q(سنة واحدة),
						'other' => q({0} سنة),
						'per' => q({0}/سنة),
						'two' => q(سنتان),
						'zero' => q({0} سنة),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} أمبير),
						'many' => q({0} أمبير),
						'name' => q(أمبير),
						'one' => q({0} أمبير),
						'other' => q({0} أمبير),
						'two' => q({0} أمبير),
						'zero' => q({0} أمبير),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} أمبير),
						'many' => q({0} أمبير),
						'name' => q(أمبير),
						'one' => q({0} أمبير),
						'other' => q({0} أمبير),
						'two' => q({0} أمبير),
						'zero' => q({0} أمبير),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} م أمبير),
						'many' => q({0} م أمبير),
						'name' => q(م أمبير),
						'one' => q({0} م أمبير),
						'other' => q({0} م أمبير),
						'two' => q({0} م أمبير),
						'zero' => q({0} م أمبير),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} م أمبير),
						'many' => q({0} م أمبير),
						'name' => q(م أمبير),
						'one' => q({0} م أمبير),
						'other' => q({0} م أمبير),
						'two' => q({0} م أمبير),
						'zero' => q({0} م أمبير),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} أوم),
						'many' => q({0} أوم),
						'name' => q(أوم),
						'one' => q({0} أوم),
						'other' => q({0} أوم),
						'two' => q({0} أوم),
						'zero' => q({0} أوم),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} أوم),
						'many' => q({0} أوم),
						'name' => q(أوم),
						'one' => q({0} أوم),
						'other' => q({0} أوم),
						'two' => q({0} أوم),
						'zero' => q({0} أوم),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} فولت),
						'many' => q({0} فولت),
						'name' => q(فولت),
						'one' => q({0} فولت),
						'other' => q({0} فولت),
						'two' => q({0} فولت),
						'zero' => q({0} فولت),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} فولت),
						'many' => q({0} فولت),
						'name' => q(فولت),
						'one' => q({0} فولت),
						'other' => q({0} فولت),
						'two' => q({0} فولت),
						'zero' => q({0} فولت),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} وحدات حرارية بريطانية),
						'many' => q({0} وحدة حرارية بريطانية),
						'name' => q(وحدة حرارية بريطانية),
						'one' => q({0} وحدة حرارية بريطانية),
						'other' => q({0} وحدة حرارية بريطانية),
						'two' => q({0} وحدة حرارية بريطانية),
						'zero' => q({0} وحدة حرارية بريطانية),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} وحدات حرارية بريطانية),
						'many' => q({0} وحدة حرارية بريطانية),
						'name' => q(وحدة حرارية بريطانية),
						'one' => q({0} وحدة حرارية بريطانية),
						'other' => q({0} وحدة حرارية بريطانية),
						'two' => q({0} وحدة حرارية بريطانية),
						'zero' => q({0} وحدة حرارية بريطانية),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} سع),
						'many' => q({0} سع),
						'name' => q(سع),
						'one' => q({0} سع),
						'other' => q({0} سع),
						'two' => q({0} سع),
						'zero' => q({0} سع),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} سع),
						'many' => q({0} سع),
						'name' => q(سع),
						'one' => q({0} سع),
						'other' => q({0} سع),
						'two' => q({0} سع),
						'zero' => q({0} سع),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} إلكترون فولت),
						'many' => q({0} إلكترون فولت),
						'name' => q(إلكترون فولت),
						'one' => q({0} إلكترون فولت),
						'other' => q({0} إلكترون فولت),
						'two' => q({0} إلكترون فولت),
						'zero' => q({0} إلكترون فولت),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} إلكترون فولت),
						'many' => q({0} إلكترون فولت),
						'name' => q(إلكترون فولت),
						'one' => q({0} إلكترون فولت),
						'other' => q({0} إلكترون فولت),
						'two' => q({0} إلكترون فولت),
						'zero' => q({0} إلكترون فولت),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} سع),
						'many' => q({0} سع),
						'name' => q(سع),
						'one' => q({0} سع),
						'other' => q({0} سع),
						'two' => q({0} سع),
						'zero' => q({0} سع),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} سع),
						'many' => q({0} سع),
						'name' => q(سع),
						'one' => q({0} سع),
						'other' => q({0} سع),
						'two' => q({0} سع),
						'zero' => q({0} سع),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} جول),
						'many' => q({0} جول),
						'name' => q(جول),
						'one' => q({0} جول),
						'other' => q({0} جول),
						'two' => q({0} جول),
						'zero' => q({0} جول),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} جول),
						'many' => q({0} جول),
						'name' => q(جول),
						'one' => q({0} جول),
						'other' => q({0} جول),
						'two' => q({0} جول),
						'zero' => q({0} جول),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} ك سعرة),
						'many' => q({0} ك سعرة),
						'name' => q(ك سعرة),
						'one' => q({0} ك سعرة),
						'other' => q({0} ك سعرة),
						'two' => q({0} ك سعرة),
						'zero' => q({0} ك سعرة),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} ك سعرة),
						'many' => q({0} ك سعرة),
						'name' => q(ك سعرة),
						'one' => q({0} ك سعرة),
						'other' => q({0} ك سعرة),
						'two' => q({0} ك سعرة),
						'zero' => q({0} ك سعرة),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} ك جول),
						'many' => q({0} ك جول),
						'name' => q(ك جول),
						'one' => q({0} ك جول),
						'other' => q({0} ك جول),
						'two' => q({0} ك جول),
						'zero' => q({0} ك جول),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} ك جول),
						'many' => q({0} ك جول),
						'name' => q(ك جول),
						'one' => q({0} ك جول),
						'other' => q({0} ك جول),
						'two' => q({0} ك جول),
						'zero' => q({0} ك جول),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} ك.و.س),
						'many' => q({0} ك.و.س),
						'name' => q(ك.و.س),
						'one' => q({0} ك.و.س),
						'other' => q({0} ك.و.س),
						'two' => q({0} ك.و.س),
						'zero' => q({0} ك.و.س),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} ك.و.س),
						'many' => q({0} ك.و.س),
						'name' => q(ك.و.س),
						'one' => q({0} ك.و.س),
						'other' => q({0} ك.و.س),
						'two' => q({0} ك.و.س),
						'zero' => q({0} ك.و.س),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} وحدات حرارية أمريكية),
						'many' => q({0} وحدة حرارية أمريكية),
						'name' => q(وحدة حرارية أمريكية),
						'one' => q({0} وحدة حرارية أمريكية),
						'other' => q({0} وحدة حرارية أمريكية),
						'two' => q({0} وحدة حرارية أمريكية),
						'zero' => q({0} وحدة حرارية أمريكية),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} وحدات حرارية أمريكية),
						'many' => q({0} وحدة حرارية أمريكية),
						'name' => q(وحدة حرارية أمريكية),
						'one' => q({0} وحدة حرارية أمريكية),
						'other' => q({0} وحدة حرارية أمريكية),
						'two' => q({0} وحدة حرارية أمريكية),
						'zero' => q({0} وحدة حرارية أمريكية),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} ك.و.س لكل 100 كم),
						'many' => q({0} ك.و.س لكل 100 كم),
						'name' => q(ك.و.س لكل 100 كم),
						'one' => q({0} ك.و.س لكل 100 كم),
						'other' => q({0} ك.و.س لكل 100 كم),
						'two' => q({0} ك.و.س لكل 100 كم),
						'zero' => q({0} ك.و.س لكل 100 كم),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} ك.و.س لكل 100 كم),
						'many' => q({0} ك.و.س لكل 100 كم),
						'name' => q(ك.و.س لكل 100 كم),
						'one' => q({0} ك.و.س لكل 100 كم),
						'other' => q({0} ك.و.س لكل 100 كم),
						'two' => q({0} ك.و.س لكل 100 كم),
						'zero' => q({0} ك.و.س لكل 100 كم),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} نيوتن),
						'many' => q({0} نيوتن),
						'name' => q(نيوتن),
						'one' => q({0} نيوتن),
						'other' => q({0} نيوتن),
						'two' => q({0} نيوتن),
						'zero' => q({0} نيوتن),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} نيوتن),
						'many' => q({0} نيوتن),
						'name' => q(نيوتن),
						'one' => q({0} نيوتن),
						'other' => q({0} نيوتن),
						'two' => q({0} نيوتن),
						'zero' => q({0} نيوتن),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} باوند قوة),
						'many' => q({0} باوند قوة),
						'name' => q(باوند قوة),
						'one' => q({0} باوند قوة),
						'other' => q({0} باوند قوة),
						'two' => q({0} باوند قوة),
						'zero' => q({0} باوند قوة),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} باوند قوة),
						'many' => q({0} باوند قوة),
						'name' => q(باوند قوة),
						'one' => q({0} باوند قوة),
						'other' => q({0} باوند قوة),
						'two' => q({0} باوند قوة),
						'zero' => q({0} باوند قوة),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} غ هرتز),
						'many' => q({0} غ هرتز),
						'name' => q(غ هرتز),
						'one' => q({0} غ هرتز),
						'other' => q({0} غ هرتز),
						'two' => q({0} غ هرتز),
						'zero' => q({0} غ هرتز),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} غ هرتز),
						'many' => q({0} غ هرتز),
						'name' => q(غ هرتز),
						'one' => q({0} غ هرتز),
						'other' => q({0} غ هرتز),
						'two' => q({0} غ هرتز),
						'zero' => q({0} غ هرتز),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} هرتز),
						'many' => q({0} هرتز),
						'name' => q(هرتز),
						'one' => q({0} هرتز),
						'other' => q({0} هرتز),
						'two' => q({0} هرتز),
						'zero' => q({0} هرتز),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} هرتز),
						'many' => q({0} هرتز),
						'name' => q(هرتز),
						'one' => q({0} هرتز),
						'other' => q({0} هرتز),
						'two' => q({0} هرتز),
						'zero' => q({0} هرتز),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} ك هرتز),
						'many' => q({0} ك هرتز),
						'name' => q(ك هرتز),
						'one' => q({0} ك هرتز),
						'other' => q({0} ك هرتز),
						'two' => q({0} ك هرتز),
						'zero' => q({0} ك هرتز),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} ك هرتز),
						'many' => q({0} ك هرتز),
						'name' => q(ك هرتز),
						'one' => q({0} ك هرتز),
						'other' => q({0} ك هرتز),
						'two' => q({0} ك هرتز),
						'zero' => q({0} ك هرتز),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} م هرتز),
						'many' => q({0} م هرتز),
						'name' => q(م هرتز),
						'one' => q({0} م هرتز),
						'other' => q({0} م هرتز),
						'two' => q({0} م هرتز),
						'zero' => q({0} م هرتز),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} م هرتز),
						'many' => q({0} م هرتز),
						'name' => q(م هرتز),
						'one' => q({0} م هرتز),
						'other' => q({0} م هرتز),
						'two' => q({0} م هرتز),
						'zero' => q({0} م هرتز),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} نقاط/سم),
						'many' => q({0} نقطة/سم),
						'name' => q(نقطة/سم),
						'one' => q({0} نقطة/سم),
						'other' => q({0} نقطة/سم),
						'two' => q({0} نقطتان/سم),
						'zero' => q({0} نقطة/سم),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} نقاط/سم),
						'many' => q({0} نقطة/سم),
						'name' => q(نقطة/سم),
						'one' => q({0} نقطة/سم),
						'other' => q({0} نقطة/سم),
						'two' => q({0} نقطتان/سم),
						'zero' => q({0} نقطة/سم),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} نقاط/بوصة),
						'many' => q({0} نقطة/بوصة),
						'name' => q(نقطة لكل بوصة),
						'one' => q({0} نقطة/بوصة),
						'other' => q({0} نقطة/بوصة),
						'two' => q(نقطة/بوصة),
						'zero' => q({0} نقطة/بوصة),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} نقاط/بوصة),
						'many' => q({0} نقطة/بوصة),
						'name' => q(نقطة لكل بوصة),
						'one' => q({0} نقطة/بوصة),
						'other' => q({0} نقطة/بوصة),
						'two' => q(نقطة/بوصة),
						'zero' => q({0} نقطة/بوصة),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} إم),
						'many' => q({0} إم),
						'name' => q(إم),
						'one' => q({0} إم),
						'other' => q({0} إم),
						'two' => q({0} إم),
						'zero' => q({0} إم),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} إم),
						'many' => q({0} إم),
						'name' => q(إم),
						'one' => q({0} إم),
						'other' => q({0} إم),
						'two' => q({0} إم),
						'zero' => q({0} إم),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} م.بكسل),
						'many' => q({0} م.بكسل),
						'name' => q(م.بكسل),
						'one' => q({0} م.بكسل),
						'other' => q({0} م.بكسل),
						'two' => q({0} م.بكسل),
						'zero' => q({0} م.بكسل),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} م.بكسل),
						'many' => q({0} م.بكسل),
						'name' => q(م.بكسل),
						'one' => q({0} م.بكسل),
						'other' => q({0} م.بكسل),
						'two' => q({0} م.بكسل),
						'zero' => q({0} م.بكسل),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} بكسل),
						'many' => q({0} بكسل),
						'name' => q(بكسل),
						'one' => q({0} بكسل),
						'other' => q({0} بكسل),
						'two' => q({0} بكسل),
						'zero' => q({0} بكسل),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} بكسل),
						'many' => q({0} بكسل),
						'name' => q(بكسل),
						'one' => q({0} بكسل),
						'other' => q({0} بكسل),
						'two' => q({0} بكسل),
						'zero' => q({0} بكسل),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} بكسل/سم),
						'many' => q({0} بكسل/سم),
						'name' => q(بكسل لكل سنتيمتر),
						'one' => q({0} بكسل/سم),
						'other' => q({0} بكسل/سم),
						'two' => q({0} بكسل/سم),
						'zero' => q({0} بكسل/سم),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} بكسل/سم),
						'many' => q({0} بكسل/سم),
						'name' => q(بكسل لكل سنتيمتر),
						'one' => q({0} بكسل/سم),
						'other' => q({0} بكسل/سم),
						'two' => q({0} بكسل/سم),
						'zero' => q({0} بكسل/سم),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} بكسل/بوصة),
						'many' => q({0} بكسل/بوصة),
						'name' => q(بكسل لكل بوصة),
						'one' => q({0} بكسل/بوصة),
						'other' => q({0} بكسل/بوصة),
						'two' => q({0} بكسل/بوصة),
						'zero' => q({0} بكسل/بوصة),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} بكسل/بوصة),
						'many' => q({0} بكسل/بوصة),
						'name' => q(بكسل لكل بوصة),
						'one' => q({0} بكسل/بوصة),
						'other' => q({0} بكسل/بوصة),
						'two' => q({0} بكسل/بوصة),
						'zero' => q({0} بكسل/بوصة),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} و.ف.),
						'many' => q({0} و.ف.),
						'name' => q(و.ف.),
						'one' => q({0} و.ف.),
						'other' => q({0} و.ف.),
						'two' => q({0} و.ف.),
						'zero' => q({0} و.ف.),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} و.ف.),
						'many' => q({0} و.ف.),
						'name' => q(و.ف.),
						'one' => q({0} و.ف.),
						'other' => q({0} و.ف.),
						'two' => q({0} و.ف.),
						'zero' => q({0} و.ف.),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} سم),
						'many' => q({0} سم),
						'name' => q(سم),
						'one' => q({0} سم),
						'other' => q({0} سم),
						'per' => q({0}/سم),
						'two' => q({0} سم),
						'zero' => q({0} سم),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} سم),
						'many' => q({0} سم),
						'name' => q(سم),
						'one' => q({0} سم),
						'other' => q({0} سم),
						'per' => q({0}/سم),
						'two' => q({0} سم),
						'zero' => q({0} سم),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} دسم),
						'many' => q({0} دسم),
						'name' => q(دسم),
						'one' => q({0} دسم),
						'other' => q({0} دسم),
						'two' => q({0} دسم),
						'zero' => q({0} دسم),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} دسم),
						'many' => q({0} دسم),
						'name' => q(دسم),
						'one' => q({0} دسم),
						'other' => q({0} دسم),
						'two' => q({0} دسم),
						'zero' => q({0} دسم),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} نق أرضي),
						'many' => q({0} نق أرضي),
						'name' => q(نق أرضي),
						'one' => q({0} نق أرضي),
						'other' => q({0} نق أرضي),
						'two' => q({0} نق أرضي),
						'zero' => q({0} نق أرضي),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} نق أرضي),
						'many' => q({0} نق أرضي),
						'name' => q(نق أرضي),
						'one' => q({0} نق أرضي),
						'other' => q({0} نق أرضي),
						'two' => q({0} نق أرضي),
						'zero' => q({0} نق أرضي),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} قامة),
						'many' => q({0} قامة),
						'name' => q(قامة),
						'one' => q({0} قامة),
						'other' => q({0} قامة),
						'two' => q({0} قامة),
						'zero' => q({0} قامة),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} قامة),
						'many' => q({0} قامة),
						'name' => q(قامة),
						'one' => q({0} قامة),
						'other' => q({0} قامة),
						'two' => q({0} قامة),
						'zero' => q({0} قامة),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} قدم),
						'many' => q({0} قدم),
						'name' => q(قدم),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'per' => q({0}/قدم),
						'two' => q({0} قدم),
						'zero' => q({0} قدم),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} قدم),
						'many' => q({0} قدم),
						'name' => q(قدم),
						'one' => q(قدم),
						'other' => q({0} قدم),
						'per' => q({0}/قدم),
						'two' => q({0} قدم),
						'zero' => q({0} قدم),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} فرلنغ),
						'many' => q({0} فرلنغ),
						'name' => q(فرلنغ),
						'one' => q({0} فرلنغ),
						'other' => q({0} فرلنغ),
						'two' => q({0} فرلنغ),
						'zero' => q({0} فرلنغ),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} فرلنغ),
						'many' => q({0} فرلنغ),
						'name' => q(فرلنغ),
						'one' => q({0} فرلنغ),
						'other' => q({0} فرلنغ),
						'two' => q({0} فرلنغ),
						'zero' => q({0} فرلنغ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} بوصة),
						'many' => q({0} بوصة),
						'name' => q(بوصة),
						'one' => q({0} بوصة),
						'other' => q({0} بوصة),
						'per' => q({0}/بوصة),
						'two' => q({0} بوصة),
						'zero' => q({0} بوصة),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} بوصة),
						'many' => q({0} بوصة),
						'name' => q(بوصة),
						'one' => q({0} بوصة),
						'other' => q({0} بوصة),
						'per' => q({0}/بوصة),
						'two' => q({0} بوصة),
						'zero' => q({0} بوصة),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} كم),
						'many' => q({0} كم),
						'name' => q(كم),
						'one' => q({0} كم),
						'other' => q({0} كم),
						'per' => q({0}/كم),
						'two' => q({0} كم),
						'zero' => q({0} كم),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} كم),
						'many' => q({0} كم),
						'name' => q(كم),
						'one' => q({0} كم),
						'other' => q({0} كم),
						'per' => q({0}/كم),
						'two' => q({0} كم),
						'zero' => q({0} كم),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} سنوات ضوئية),
						'many' => q({0} سنة ضوئية),
						'name' => q(سنة ضوئية),
						'one' => q(سنة ضوئية),
						'other' => q({0} سنة ضوئية),
						'two' => q(سنتان ضوئيتان),
						'zero' => q({0} سنة ضوئية),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} سنوات ضوئية),
						'many' => q({0} سنة ضوئية),
						'name' => q(سنة ضوئية),
						'one' => q(سنة ضوئية),
						'other' => q({0} سنة ضوئية),
						'two' => q(سنتان ضوئيتان),
						'zero' => q({0} سنة ضوئية),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'name' => q(م),
						'one' => q(متر),
						'other' => q({0} متر),
						'per' => q({0}/م),
						'two' => q(متران),
						'zero' => q({0} متر),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} أمتار),
						'many' => q({0} مترًا),
						'name' => q(م),
						'one' => q(متر),
						'other' => q({0} متر),
						'per' => q({0}/م),
						'two' => q(متران),
						'zero' => q({0} متر),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} ميكرومتر),
						'many' => q({0} ميكرومتر),
						'name' => q(ميكرومتر),
						'one' => q({0} ميكرومتر),
						'other' => q({0} ميكرومتر),
						'two' => q({0} ميكرومتر),
						'zero' => q({0} ميكرومتر),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} ميكرومتر),
						'many' => q({0} ميكرومتر),
						'name' => q(ميكرومتر),
						'one' => q({0} ميكرومتر),
						'other' => q({0} ميكرومتر),
						'two' => q({0} ميكرومتر),
						'zero' => q({0} ميكرومتر),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} ميل),
						'many' => q({0} ميل),
						'name' => q(ميل),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q({0} ميل),
						'zero' => q({0} ميل),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} ميل),
						'many' => q({0} ميل),
						'name' => q(ميل),
						'one' => q(ميل),
						'other' => q({0} ميل),
						'two' => q({0} ميل),
						'zero' => q({0} ميل),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} ميل اسكندنافي),
						'many' => q({0} ميل اسكندنافي),
						'name' => q(ميل اسكندنافي),
						'one' => q({0} ميل اسكندنافي),
						'other' => q({0} ميل اسكندنافي),
						'two' => q({0} ميل اسكندنافي),
						'zero' => q({0} ميل اسكندنافي),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} ميل اسكندنافي),
						'many' => q({0} ميل اسكندنافي),
						'name' => q(ميل اسكندنافي),
						'one' => q({0} ميل اسكندنافي),
						'other' => q({0} ميل اسكندنافي),
						'two' => q({0} ميل اسكندنافي),
						'zero' => q({0} ميل اسكندنافي),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} مم),
						'many' => q({0} مم),
						'name' => q(مليمتر),
						'one' => q({0} مم),
						'other' => q({0} مم),
						'two' => q({0} مم),
						'zero' => q({0} مم),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} مم),
						'many' => q({0} مم),
						'name' => q(مليمتر),
						'one' => q({0} مم),
						'other' => q({0} مم),
						'two' => q({0} مم),
						'zero' => q({0} مم),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} نانو متر),
						'many' => q({0} نانو متر),
						'name' => q(نانو متر),
						'one' => q({0} نانو متر),
						'other' => q({0} نانو متر),
						'two' => q({0} نانو متر),
						'zero' => q({0} نانو متر),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} نانو متر),
						'many' => q({0} نانو متر),
						'name' => q(نانو متر),
						'one' => q({0} نانو متر),
						'other' => q({0} نانو متر),
						'two' => q({0} نانو متر),
						'zero' => q({0} نانو متر),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} ميل بحري),
						'many' => q({0} ميل بحري),
						'name' => q(ميل بحري),
						'one' => q(ميل بحري),
						'other' => q({0} ميل بحري),
						'two' => q({0} ميل بحري),
						'zero' => q({0} ميل بحري),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} ميل بحري),
						'many' => q({0} ميل بحري),
						'name' => q(ميل بحري),
						'one' => q(ميل بحري),
						'other' => q({0} ميل بحري),
						'two' => q({0} ميل بحري),
						'zero' => q({0} ميل بحري),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} فرسخ فلكي),
						'many' => q({0} فرسخ فلكي),
						'name' => q(فرسخ فلكي),
						'one' => q(فرسخ فلكي),
						'other' => q({0} فرسخ فلكي),
						'two' => q({0} فرسخ فلكي),
						'zero' => q({0} فرسخ فلكي),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} فرسخ فلكي),
						'many' => q({0} فرسخ فلكي),
						'name' => q(فرسخ فلكي),
						'one' => q(فرسخ فلكي),
						'other' => q({0} فرسخ فلكي),
						'two' => q({0} فرسخ فلكي),
						'zero' => q({0} فرسخ فلكي),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} بيكومتر),
						'many' => q({0} بيكومتر),
						'name' => q(بيكومتر),
						'one' => q({0} بيكومتر),
						'other' => q({0} بيكومتر),
						'two' => q({0} بيكومتر),
						'zero' => q({0} بيكومتر),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} بيكومتر),
						'many' => q({0} بيكومتر),
						'name' => q(بيكومتر),
						'one' => q({0} بيكومتر),
						'other' => q({0} بيكومتر),
						'two' => q({0} بيكومتر),
						'zero' => q({0} بيكومتر),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} نقاط),
						'many' => q({0} نقطة),
						'name' => q(نقطة),
						'one' => q(نقطة),
						'other' => q({0} نقطة),
						'two' => q(نقطتان),
						'zero' => q({0} نقطة),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} نقاط),
						'many' => q({0} نقطة),
						'name' => q(نقطة),
						'one' => q(نقطة),
						'other' => q({0} نقطة),
						'two' => q(نقطتان),
						'zero' => q({0} نقطة),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} نق شمسي),
						'many' => q({0} نق شمسي),
						'name' => q(نق شمسي),
						'one' => q({0} نق شمسي),
						'other' => q({0} نق شمسي),
						'two' => q({0} نق شمسي),
						'zero' => q({0} نق شمسي),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} نق شمسي),
						'many' => q({0} نق شمسي),
						'name' => q(نق شمسي),
						'one' => q({0} نق شمسي),
						'other' => q({0} نق شمسي),
						'two' => q({0} نق شمسي),
						'zero' => q({0} نق شمسي),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} ياردة),
						'many' => q({0} ياردة),
						'name' => q(ياردة),
						'one' => q(ياردة),
						'other' => q({0} ياردة),
						'two' => q({0} ياردة),
						'zero' => q({0} ياردة),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} ياردة),
						'many' => q({0} ياردة),
						'name' => q(ياردة),
						'one' => q(ياردة),
						'other' => q({0} ياردة),
						'two' => q({0} ياردة),
						'zero' => q({0} ياردة),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} شمعة),
						'many' => q({0} شمعة),
						'name' => q(شمعة),
						'one' => q({0} شمعة),
						'other' => q({0} شمعة),
						'two' => q({0} شمعة),
						'zero' => q({0} شمعة),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} شمعة),
						'many' => q({0} شمعة),
						'name' => q(شمعة),
						'one' => q({0} شمعة),
						'other' => q({0} شمعة),
						'two' => q({0} شمعة),
						'zero' => q({0} شمعة),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} لومن),
						'many' => q({0} لومن),
						'name' => q(لومن),
						'one' => q({0} لومن),
						'other' => q({0} لومن),
						'two' => q({0} لومن),
						'zero' => q({0} لومن),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} لومن),
						'many' => q({0} لومن),
						'name' => q(لومن),
						'one' => q({0} لومن),
						'other' => q({0} لومن),
						'two' => q({0} لومن),
						'zero' => q({0} لومن),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} لكس),
						'many' => q({0} لكس),
						'name' => q(لكس),
						'one' => q({0} لكس),
						'other' => q({0} لكس),
						'two' => q({0} لكس),
						'zero' => q({0} لكس),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} لكس),
						'many' => q({0} لكس),
						'name' => q(لكس),
						'one' => q({0} لكس),
						'other' => q({0} لكس),
						'two' => q({0} لكس),
						'zero' => q({0} لكس),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} ضياء شمسي),
						'many' => q({0} ضياء شمسي),
						'name' => q(ضياء شمسي),
						'one' => q({0} ضياء شمسي),
						'other' => q({0} ضياء شمسي),
						'two' => q({0} ضياء شمسي),
						'zero' => q({0} ضياء شمسي),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} ضياء شمسي),
						'many' => q({0} ضياء شمسي),
						'name' => q(ضياء شمسي),
						'one' => q({0} ضياء شمسي),
						'other' => q({0} ضياء شمسي),
						'two' => q({0} ضياء شمسي),
						'zero' => q({0} ضياء شمسي),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} قيراط),
						'many' => q({0} قيراط),
						'name' => q(قيراط),
						'one' => q({0} قيراط),
						'other' => q({0} قيراط),
						'two' => q({0} قيراط),
						'zero' => q({0} قيراط),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} قيراط),
						'many' => q({0} قيراط),
						'name' => q(قيراط),
						'one' => q({0} قيراط),
						'other' => q({0} قيراط),
						'two' => q({0} قيراط),
						'zero' => q({0} قيراط),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} دالتون),
						'many' => q({0} دالتون),
						'name' => q(دالتون),
						'one' => q({0} دالتون),
						'other' => q({0} دالتون),
						'two' => q({0} دالتون),
						'zero' => q({0} دالتون),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} دالتون),
						'many' => q({0} دالتون),
						'name' => q(دالتون),
						'one' => q({0} دالتون),
						'other' => q({0} دالتون),
						'two' => q({0} دالتون),
						'zero' => q({0} دالتون),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} كتلة أرضية),
						'many' => q({0} كتلة أرضية),
						'name' => q(كتلة أرضية),
						'one' => q({0} كتلة أرضية),
						'other' => q({0} كتلة أرضية),
						'two' => q({0} كتلة أرضية),
						'zero' => q({0} كتلة أرضية),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} كتلة أرضية),
						'many' => q({0} كتلة أرضية),
						'name' => q(كتلة أرضية),
						'one' => q({0} كتلة أرضية),
						'other' => q({0} كتلة أرضية),
						'two' => q({0} كتلة أرضية),
						'zero' => q({0} كتلة أرضية),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} قمحة),
						'many' => q({0} قمحة),
						'name' => q(قمحة),
						'one' => q({0} قمحة),
						'other' => q({0} قمحة),
						'two' => q({0} قمحة),
						'zero' => q({0} قمحة),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} قمحة),
						'many' => q({0} قمحة),
						'name' => q(قمحة),
						'one' => q({0} قمحة),
						'other' => q({0} قمحة),
						'two' => q({0} قمحة),
						'zero' => q({0} قمحة),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} غرام),
						'many' => q({0} غرام),
						'name' => q(غرام),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'per' => q({0}/غرام),
						'two' => q({0} غرام),
						'zero' => q({0} غرام),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} غرام),
						'many' => q({0} غرام),
						'name' => q(غرام),
						'one' => q(غرام),
						'other' => q({0} غرام),
						'per' => q({0}/غرام),
						'two' => q({0} غرام),
						'zero' => q({0} غرام),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} كغم),
						'many' => q({0} كغم),
						'name' => q(كغم),
						'one' => q({0} كغم),
						'other' => q({0} كغم),
						'per' => q({0}/كغم),
						'two' => q({0} كغم),
						'zero' => q({0} كغم),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} كغم),
						'many' => q({0} كغم),
						'name' => q(كغم),
						'one' => q({0} كغم),
						'other' => q({0} كغم),
						'per' => q({0}/كغم),
						'two' => q({0} كغم),
						'zero' => q({0} كغم),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} مكغم),
						'many' => q({0} مكغم),
						'name' => q(مكغم),
						'one' => q({0} مكغم),
						'other' => q({0} مكغم),
						'two' => q({0} مكغم),
						'zero' => q({0} مكغم),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} مكغم),
						'many' => q({0} مكغم),
						'name' => q(مكغم),
						'one' => q({0} مكغم),
						'other' => q({0} مكغم),
						'two' => q({0} مكغم),
						'zero' => q({0} مكغم),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} مغم),
						'many' => q({0} مغم),
						'name' => q(مغم),
						'one' => q({0} مغم),
						'other' => q({0} مغم),
						'two' => q({0} مغم),
						'zero' => q({0} مغم),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} مغم),
						'many' => q({0} مغم),
						'name' => q(مغم),
						'one' => q({0} مغم),
						'other' => q({0} مغم),
						'two' => q({0} مغم),
						'zero' => q({0} مغم),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} أونصة),
						'many' => q({0} أونصة),
						'name' => q(أونصة),
						'one' => q(أونصة),
						'other' => q({0} أونصة),
						'per' => q({0}/أونصة),
						'two' => q({0} أونصة),
						'zero' => q({0} أونصة),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} أونصة),
						'many' => q({0} أونصة),
						'name' => q(أونصة),
						'one' => q(أونصة),
						'other' => q({0} أونصة),
						'per' => q({0}/أونصة),
						'two' => q({0} أونصة),
						'zero' => q({0} أونصة),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} أونصة ترويسية),
						'many' => q({0} أونصة ترويسية),
						'name' => q(أونصة ترويسية),
						'one' => q({0} أونصة ترويسية),
						'other' => q({0} أونصة ترويسية),
						'two' => q({0} أونصة ترويسية),
						'zero' => q({0} أونصة ترويسية),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} أونصة ترويسية),
						'many' => q({0} أونصة ترويسية),
						'name' => q(أونصة ترويسية),
						'one' => q({0} أونصة ترويسية),
						'other' => q({0} أونصة ترويسية),
						'two' => q({0} أونصة ترويسية),
						'zero' => q({0} أونصة ترويسية),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} رطل),
						'many' => q({0} رطل),
						'name' => q(رطل),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'per' => q({0}/رطل),
						'two' => q({0} رطل),
						'zero' => q({0} رطل),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} رطل),
						'many' => q({0} رطل),
						'name' => q(رطل),
						'one' => q({0} رطل),
						'other' => q({0} رطل),
						'per' => q({0}/رطل),
						'two' => q({0} رطل),
						'zero' => q({0} رطل),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} كتلة شمسية),
						'many' => q({0} كتلة شمسية),
						'name' => q(كتلة شمسية),
						'one' => q({0} كتلة شمسية),
						'other' => q({0} كتلة شمسية),
						'two' => q({0} كتلة شمسية),
						'zero' => q({0} كتلة شمسية),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} كتلة شمسية),
						'many' => q({0} كتلة شمسية),
						'name' => q(كتلة شمسية),
						'one' => q({0} كتلة شمسية),
						'other' => q({0} كتلة شمسية),
						'two' => q({0} كتلة شمسية),
						'zero' => q({0} كتلة شمسية),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} ستون),
						'many' => q({0} ستون),
						'name' => q(ستون),
						'one' => q({0} ستون),
						'other' => q({0} ستون),
						'two' => q({0} ستون),
						'zero' => q({0} ستون),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} ستون),
						'many' => q({0} ستون),
						'name' => q(ستون),
						'one' => q({0} ستون),
						'other' => q({0} ستون),
						'two' => q({0} ستون),
						'zero' => q({0} ستون),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} طن),
						'many' => q({0} طن),
						'name' => q(طن),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q({0} طن),
						'zero' => q({0} طن),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} طن),
						'many' => q({0} طن),
						'name' => q(طن),
						'one' => q({0} طن),
						'other' => q({0} طن),
						'two' => q({0} طن),
						'zero' => q({0} طن),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} ط.م),
						'many' => q({0} ط.م),
						'name' => q(ط.م),
						'one' => q({0} ط.م),
						'other' => q({0} ط.م),
						'two' => q({0} ط.م),
						'zero' => q({0} ط.م),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} ط.م),
						'many' => q({0} ط.م),
						'name' => q(ط.م),
						'one' => q({0} ط.م),
						'other' => q({0} ط.م),
						'two' => q({0} ط.م),
						'zero' => q({0} ط.م),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} غ واط),
						'many' => q({0} غ واط),
						'name' => q(غ واط),
						'one' => q({0} غ واط),
						'other' => q({0} غ واط),
						'two' => q({0} غ واط),
						'zero' => q({0} غ واط),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} غ واط),
						'many' => q({0} غ واط),
						'name' => q(غ واط),
						'one' => q({0} غ واط),
						'other' => q({0} غ واط),
						'two' => q({0} غ واط),
						'zero' => q({0} غ واط),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} حصان),
						'many' => q({0} حصان),
						'name' => q(حصان),
						'one' => q({0} حصان),
						'other' => q({0} حصان),
						'two' => q({0} حصان),
						'zero' => q({0} حصان),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} حصان),
						'many' => q({0} حصان),
						'name' => q(حصان),
						'one' => q({0} حصان),
						'other' => q({0} حصان),
						'two' => q({0} حصان),
						'zero' => q({0} حصان),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} كيلوواط),
						'many' => q({0} كيلوواط),
						'name' => q(ك واط),
						'one' => q({0} كيلوواط),
						'other' => q({0} كيلوواط),
						'two' => q({0} كيلوواط),
						'zero' => q({0} كيلوواط),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} كيلوواط),
						'many' => q({0} كيلوواط),
						'name' => q(ك واط),
						'one' => q({0} كيلوواط),
						'other' => q({0} كيلوواط),
						'two' => q({0} كيلوواط),
						'zero' => q({0} كيلوواط),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} م واط),
						'many' => q({0} م واط),
						'name' => q(م واط),
						'one' => q({0} م واط),
						'other' => q({0} م واط),
						'two' => q({0} م واط),
						'zero' => q({0} م واط),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} م واط),
						'many' => q({0} م واط),
						'name' => q(م واط),
						'one' => q({0} م واط),
						'other' => q({0} م واط),
						'two' => q({0} م واط),
						'zero' => q({0} م واط),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} ملي واط),
						'many' => q({0} ملي واط),
						'name' => q(ملي واط),
						'one' => q({0} ملي واط),
						'other' => q({0} ملي واط),
						'two' => q({0} ملي واط),
						'zero' => q({0} ملي واط),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} ملي واط),
						'many' => q({0} ملي واط),
						'name' => q(ملي واط),
						'one' => q({0} ملي واط),
						'other' => q({0} ملي واط),
						'two' => q({0} ملي واط),
						'zero' => q({0} ملي واط),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} واط),
						'many' => q({0} واط),
						'name' => q(واط),
						'one' => q({0} واط),
						'other' => q({0} واط),
						'two' => q({0} واط),
						'zero' => q({0} واط),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} واط),
						'many' => q({0} واط),
						'name' => q(واط),
						'one' => q({0} واط),
						'other' => q({0} واط),
						'two' => q({0} واط),
						'zero' => q({0} واط),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} ض.ج),
						'many' => q({0} ض.ج),
						'name' => q(ض.ج),
						'one' => q({0} ض.ج),
						'other' => q({0} ض.ج),
						'two' => q({0} ض.ج),
						'zero' => q({0} ض.ج),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} ض.ج),
						'many' => q({0} ض.ج),
						'name' => q(ض.ج),
						'one' => q({0} ض.ج),
						'other' => q({0} ض.ج),
						'two' => q({0} ض.ج),
						'zero' => q({0} ض.ج),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} بار),
						'many' => q({0} بار),
						'name' => q(بار),
						'one' => q({0} بار),
						'other' => q({0} بار),
						'two' => q({0} بار),
						'zero' => q({0} بار),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} بار),
						'many' => q({0} بار),
						'name' => q(بار),
						'one' => q({0} بار),
						'other' => q({0} بار),
						'two' => q({0} بار),
						'zero' => q({0} بار),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} هكتوباسكال),
						'many' => q({0} هكتوباسكال),
						'name' => q(هكتوباسكال),
						'one' => q({0} هكتوباسكال),
						'other' => q({0} هكتوباسكال),
						'two' => q({0} هكتوباسكال),
						'zero' => q({0} هكتوباسكال),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} هكتوباسكال),
						'many' => q({0} هكتوباسكال),
						'name' => q(هكتوباسكال),
						'one' => q({0} هكتوباسكال),
						'other' => q({0} هكتوباسكال),
						'two' => q({0} هكتوباسكال),
						'zero' => q({0} هكتوباسكال),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} ب. زئبقية),
						'many' => q({0} ب. زئبقية),
						'name' => q(ب. زئبقية),
						'one' => q({0} ب. زئبقية),
						'other' => q({0} ب. زئبقية),
						'two' => q({0} ب. زئبقية),
						'zero' => q({0} ب. زئبقية),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} ب. زئبقية),
						'many' => q({0} ب. زئبقية),
						'name' => q(ب. زئبقية),
						'one' => q({0} ب. زئبقية),
						'other' => q({0} ب. زئبقية),
						'two' => q({0} ب. زئبقية),
						'zero' => q({0} ب. زئبقية),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} ك.باسكال),
						'many' => q({0} ك.باسكال),
						'name' => q(ك.باسكال),
						'one' => q({0} ك.باسكال),
						'other' => q({0} ك.باسكال),
						'two' => q({0} ك.باسكال),
						'zero' => q({0} ك.باسكال),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} ك.باسكال),
						'many' => q({0} ك.باسكال),
						'name' => q(ك.باسكال),
						'one' => q({0} ك.باسكال),
						'other' => q({0} ك.باسكال),
						'two' => q({0} ك.باسكال),
						'zero' => q({0} ك.باسكال),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} م.باسكال),
						'many' => q({0} م.باسكال),
						'name' => q(م.باسكال),
						'one' => q({0} م.باسكال),
						'other' => q({0} م.باسكال),
						'two' => q({0} م.باسكال),
						'zero' => q({0} م.باسكال),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} م.باسكال),
						'many' => q({0} م.باسكال),
						'name' => q(م.باسكال),
						'one' => q({0} م.باسكال),
						'other' => q({0} م.باسكال),
						'two' => q({0} م.باسكال),
						'zero' => q({0} م.باسكال),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} م. بار),
						'many' => q({0} م. بار),
						'name' => q(م. بار),
						'one' => q({0} م. بار),
						'other' => q({0} م. بار),
						'two' => q({0} م. بار),
						'zero' => q({0} م. بار),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} م. بار),
						'many' => q({0} م. بار),
						'name' => q(م. بار),
						'one' => q({0} م. بار),
						'other' => q({0} م. بار),
						'two' => q({0} م. بار),
						'zero' => q({0} م. بار),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} ملم زئبقي),
						'many' => q({0} ملم زئبقي),
						'name' => q(ملم زئبقي),
						'one' => q({0} ملم زئبقي),
						'other' => q({0} ملم زئبقي),
						'two' => q({0} ملم زئبقي),
						'zero' => q({0} ملم زئبقي),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} ملم زئبقي),
						'many' => q({0} ملم زئبقي),
						'name' => q(ملم زئبقي),
						'one' => q({0} ملم زئبقي),
						'other' => q({0} ملم زئبقي),
						'two' => q({0} ملم زئبقي),
						'zero' => q({0} ملم زئبقي),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} باسكال),
						'many' => q({0} باسكال),
						'name' => q(باسكال),
						'one' => q({0} باسكال),
						'other' => q({0} باسكال),
						'two' => q({0} باسكال),
						'zero' => q({0} باسكال),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} باسكال),
						'many' => q({0} باسكال),
						'name' => q(باسكال),
						'one' => q({0} باسكال),
						'other' => q({0} باسكال),
						'two' => q({0} باسكال),
						'zero' => q({0} باسكال),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} رطل/بوصة²),
						'many' => q({0} رطل/بوصة²),
						'name' => q(رطل/بوصة مربعة),
						'one' => q({0} رطل/بوصة²),
						'other' => q({0} رطل/بوصة²),
						'two' => q({0} رطل/بوصة²),
						'zero' => q({0} رطل/بوصة²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} رطل/بوصة²),
						'many' => q({0} رطل/بوصة²),
						'name' => q(رطل/بوصة مربعة),
						'one' => q({0} رطل/بوصة²),
						'other' => q({0} رطل/بوصة²),
						'two' => q({0} رطل/بوصة²),
						'zero' => q({0} رطل/بوصة²),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(بوفورت {0}),
						'many' => q(بوفورت {0}),
						'name' => q(بوفورت),
						'one' => q(بوفورت {0}),
						'other' => q(بوفورت {0}),
						'two' => q(بوفورت {0}),
						'zero' => q(بوفورت {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(بوفورت {0}),
						'many' => q(بوفورت {0}),
						'name' => q(بوفورت),
						'one' => q(بوفورت {0}),
						'other' => q(بوفورت {0}),
						'two' => q(بوفورت {0}),
						'zero' => q(بوفورت {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} كم/س),
						'many' => q({0} كم/س),
						'name' => q(كم/س),
						'one' => q({0} كم/س),
						'other' => q({0} كم/س),
						'two' => q({0} كم/س),
						'zero' => q({0} كم/س),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} كم/س),
						'many' => q({0} كم/س),
						'name' => q(كم/س),
						'one' => q({0} كم/س),
						'other' => q({0} كم/س),
						'two' => q({0} كم/س),
						'zero' => q({0} كم/س),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} عقدة),
						'many' => q({0} عقدة),
						'name' => q(عقدة),
						'one' => q({0} عقدة),
						'other' => q({0} عقدة),
						'two' => q({0} عقدة),
						'zero' => q({0} عقدة),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} عقدة),
						'many' => q({0} عقدة),
						'name' => q(عقدة),
						'one' => q({0} عقدة),
						'other' => q({0} عقدة),
						'two' => q({0} عقدة),
						'zero' => q({0} عقدة),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} م/ث),
						'many' => q({0} م/ث),
						'name' => q(م/ث),
						'one' => q({0} م/ث),
						'other' => q({0} م/ث),
						'two' => q({0} م/ث),
						'zero' => q({0} م/ث),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} م/ث),
						'many' => q({0} م/ث),
						'name' => q(م/ث),
						'one' => q({0} م/ث),
						'other' => q({0} م/ث),
						'two' => q({0} م/ث),
						'zero' => q({0} م/ث),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} ميل/س),
						'many' => q({0} ميل/س),
						'name' => q(ميل/س),
						'one' => q({0} ميل/س),
						'other' => q({0} ميل/س),
						'two' => q({0} ميل/س),
						'zero' => q({0} ميل/س),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} ميل/س),
						'many' => q({0} ميل/س),
						'name' => q(ميل/س),
						'one' => q({0} ميل/س),
						'other' => q({0} ميل/س),
						'two' => q({0} ميل/س),
						'zero' => q({0} ميل/س),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0}°م),
						'many' => q({0}°م),
						'name' => q(درجة مئوية),
						'one' => q({0}°م),
						'other' => q({0}°م),
						'two' => q({0}°م),
						'zero' => q({0}°م),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0}°م),
						'many' => q({0}°م),
						'name' => q(درجة مئوية),
						'one' => q({0}°م),
						'other' => q({0}°م),
						'two' => q({0}°م),
						'zero' => q({0}°م),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0}°ف),
						'many' => q({0}°ف),
						'name' => q(درجة فهرنهايت),
						'one' => q({0}°ف),
						'other' => q({0}°ف),
						'two' => q({0}°ف),
						'zero' => q({0}°ف),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0}°ف),
						'many' => q({0}°ف),
						'name' => q(درجة فهرنهايت),
						'one' => q({0}°ف),
						'other' => q({0}°ف),
						'two' => q({0}°ف),
						'zero' => q({0}°ف),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} د كلفن),
						'many' => q({0} د كلفن),
						'name' => q(د كلفن),
						'one' => q({0} د كلفن),
						'other' => q({0} د كلفن),
						'two' => q({0} د كلفن),
						'zero' => q({0} د كلفن),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} د كلفن),
						'many' => q({0} د كلفن),
						'name' => q(د كلفن),
						'one' => q({0} د كلفن),
						'other' => q({0} د كلفن),
						'two' => q({0} د كلفن),
						'zero' => q({0} د كلفن),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} نيوتن متر),
						'many' => q({0} نيوتن متر),
						'name' => q(نيوتن متر),
						'one' => q({0} نيوتن متر),
						'other' => q({0} نيوتن متر),
						'two' => q({0} نيوتن متر),
						'zero' => q({0} نيوتن متر),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} نيوتن متر),
						'many' => q({0} نيوتن متر),
						'name' => q(نيوتن متر),
						'one' => q({0} نيوتن متر),
						'other' => q({0} نيوتن متر),
						'two' => q({0} نيوتن متر),
						'zero' => q({0} نيوتن متر),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} باوند قدم),
						'many' => q({0} باوند قدم),
						'name' => q(باوند قدم),
						'one' => q({0} باوند قدم),
						'other' => q({0} باوند قدم),
						'two' => q({0} باوند قدم),
						'zero' => q({0} باوند قدم),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} باوند قدم),
						'many' => q({0} باوند قدم),
						'name' => q(باوند قدم),
						'one' => q({0} باوند قدم),
						'other' => q({0} باوند قدم),
						'two' => q({0} باوند قدم),
						'zero' => q({0} باوند قدم),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} فدان قدم),
						'many' => q({0} فدان قدم),
						'name' => q(فدان قدم),
						'one' => q({0} فدان قدم),
						'other' => q({0} فدان قدم),
						'two' => q({0} فدان قدم),
						'zero' => q({0} فدان قدم),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} فدان قدم),
						'many' => q({0} فدان قدم),
						'name' => q(فدان قدم),
						'one' => q({0} فدان قدم),
						'other' => q({0} فدان قدم),
						'two' => q({0} فدان قدم),
						'zero' => q({0} فدان قدم),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} براميل),
						'many' => q({0} برميلًا),
						'name' => q(برميل),
						'one' => q(برميل),
						'other' => q({0} برميل),
						'two' => q(برميلان),
						'zero' => q({0} برميل),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} براميل),
						'many' => q({0} برميلًا),
						'name' => q(برميل),
						'one' => q(برميل),
						'other' => q({0} برميل),
						'two' => q(برميلان),
						'zero' => q({0} برميل),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} بوشل),
						'many' => q({0} بوشل),
						'name' => q(بوشل),
						'one' => q({0} بوشل),
						'other' => q({0} بوشل),
						'two' => q({0} بوشل),
						'zero' => q({0} بوشل),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} بوشل),
						'many' => q({0} بوشل),
						'name' => q(بوشل),
						'one' => q({0} بوشل),
						'other' => q({0} بوشل),
						'two' => q({0} بوشل),
						'zero' => q({0} بوشل),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} سنتيلتر),
						'many' => q({0} سنتيلتر),
						'name' => q(سنتيلتر),
						'one' => q({0} سنتيلتر),
						'other' => q({0} سنتيلتر),
						'two' => q({0} سنتيلتر),
						'zero' => q({0} سنتيلتر),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} سنتيلتر),
						'many' => q({0} سنتيلتر),
						'name' => q(سنتيلتر),
						'one' => q({0} سنتيلتر),
						'other' => q({0} سنتيلتر),
						'two' => q({0} سنتيلتر),
						'zero' => q({0} سنتيلتر),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} سم³),
						'many' => q({0} سم³),
						'name' => q(سم³),
						'one' => q({0} سم³),
						'other' => q({0} سم³),
						'per' => q({0}/سم³),
						'two' => q({0} سم³),
						'zero' => q({0} سم³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} سم³),
						'many' => q({0} سم³),
						'name' => q(سم³),
						'one' => q({0} سم³),
						'other' => q({0} سم³),
						'per' => q({0}/سم³),
						'two' => q({0} سم³),
						'zero' => q({0} سم³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} قدم³),
						'many' => q({0} قدم³),
						'name' => q(قدم³),
						'one' => q({0} قدم³),
						'other' => q({0} قدم³),
						'two' => q({0} قدم³),
						'zero' => q({0} قدم³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} قدم³),
						'many' => q({0} قدم³),
						'name' => q(قدم³),
						'one' => q({0} قدم³),
						'other' => q({0} قدم³),
						'two' => q({0} قدم³),
						'zero' => q({0} قدم³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} بوصة مكعبة),
						'many' => q({0} بوصة مكعبة),
						'name' => q(بوصة مكعبة),
						'one' => q({0} بوصة مكعبة),
						'other' => q({0} بوصة مكعبة),
						'two' => q({0} بوصة مكعبة),
						'zero' => q({0} بوصة مكعبة),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} بوصة مكعبة),
						'many' => q({0} بوصة مكعبة),
						'name' => q(بوصة مكعبة),
						'one' => q({0} بوصة مكعبة),
						'other' => q({0} بوصة مكعبة),
						'two' => q({0} بوصة مكعبة),
						'zero' => q({0} بوصة مكعبة),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} كم³),
						'many' => q({0} كم³),
						'name' => q(كم³),
						'one' => q({0} كم³),
						'other' => q({0} كم³),
						'two' => q({0} كم³),
						'zero' => q({0} كم³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} كم³),
						'many' => q({0} كم³),
						'name' => q(كم³),
						'one' => q({0} كم³),
						'other' => q({0} كم³),
						'two' => q({0} كم³),
						'zero' => q({0} كم³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} م³),
						'many' => q({0} م³),
						'name' => q(م³),
						'one' => q({0} م³),
						'other' => q({0} م³),
						'per' => q({0}/م³),
						'two' => q({0} م³),
						'zero' => q({0} م³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} م³),
						'many' => q({0} م³),
						'name' => q(م³),
						'one' => q({0} م³),
						'other' => q({0} م³),
						'per' => q({0}/م³),
						'two' => q({0} م³),
						'zero' => q({0} م³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} ميل³),
						'many' => q({0} ميل³),
						'name' => q(ميل³),
						'one' => q({0} ميل³),
						'other' => q({0} ميل³),
						'two' => q({0} ميل³),
						'zero' => q({0} ميل³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} ميل³),
						'many' => q({0} ميل³),
						'name' => q(ميل³),
						'one' => q({0} ميل³),
						'other' => q({0} ميل³),
						'two' => q({0} ميل³),
						'zero' => q({0} ميل³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} ياردة³),
						'many' => q({0} ياردة³),
						'name' => q(ياردة³),
						'one' => q({0} ياردة³),
						'other' => q({0} ياردة³),
						'two' => q({0} ياردة³),
						'zero' => q({0} ياردة³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} ياردة³),
						'many' => q({0} ياردة³),
						'name' => q(ياردة³),
						'one' => q({0} ياردة³),
						'other' => q({0} ياردة³),
						'two' => q({0} ياردة³),
						'zero' => q({0} ياردة³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} كوب),
						'many' => q({0} كوب),
						'name' => q(كوب),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q({0} كوب),
						'zero' => q({0} كوب),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} كوب),
						'many' => q({0} كوب),
						'name' => q(كوب),
						'one' => q(كوب),
						'other' => q({0} كوب),
						'two' => q({0} كوب),
						'zero' => q({0} كوب),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} كوب متري),
						'many' => q({0} كوب متري),
						'name' => q(كوب متري),
						'one' => q({0} كوب متري),
						'other' => q({0} كوب متري),
						'two' => q({0} كوب متري),
						'zero' => q({0} كوب متري),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} كوب متري),
						'many' => q({0} كوب متري),
						'name' => q(كوب متري),
						'one' => q({0} كوب متري),
						'other' => q({0} كوب متري),
						'two' => q({0} كوب متري),
						'zero' => q({0} كوب متري),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} ديسيلتر),
						'many' => q({0} ديسيلتر),
						'name' => q(ديسيلتر),
						'one' => q({0} ديسيلتر),
						'other' => q({0} ديسيلتر),
						'two' => q({0} ديسيلتر),
						'zero' => q({0} ديسيلتر),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} ديسيلتر),
						'many' => q({0} ديسيلتر),
						'name' => q(ديسيلتر),
						'one' => q({0} ديسيلتر),
						'other' => q({0} ديسيلتر),
						'two' => q({0} ديسيلتر),
						'zero' => q({0} ديسيلتر),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} ملعقة ح.),
						'many' => q({0} ملعقة ح.),
						'name' => q(ملعقة ح.),
						'one' => q({0} ملعقة ح.),
						'other' => q({0} ملعقة ح.),
						'two' => q({0} ملعقة ح.),
						'zero' => q({0} ملعقة ح.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} ملعقة ح.),
						'many' => q({0} ملعقة ح.),
						'name' => q(ملعقة ح.),
						'one' => q({0} ملعقة ح.),
						'other' => q({0} ملعقة ح.),
						'two' => q({0} ملعقة ح.),
						'zero' => q({0} ملعقة ح.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} ملعقة ح. إمبراطوري),
						'many' => q({0} ملعقة ح. إمبراطوري),
						'name' => q(ملعقة حلو إمبراطوري),
						'one' => q({0} ملعقة ح. إمبراطوري),
						'other' => q({0} ملعقة ح. إمبراطوري),
						'two' => q({0} ملعقة ح. إمبراطوري),
						'zero' => q({0} ملعقة ح. إمبراطوري),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} ملعقة ح. إمبراطوري),
						'many' => q({0} ملعقة ح. إمبراطوري),
						'name' => q(ملعقة حلو إمبراطوري),
						'one' => q({0} ملعقة ح. إمبراطوري),
						'other' => q({0} ملعقة ح. إمبراطوري),
						'two' => q({0} ملعقة ح. إمبراطوري),
						'zero' => q({0} ملعقة ح. إمبراطوري),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} درهم سائل),
						'many' => q({0} درهم سائل),
						'name' => q(درهم سائل),
						'one' => q({0} درهم سائل),
						'other' => q({0} درهم سائل),
						'two' => q({0} درهم سائل),
						'zero' => q({0} درهم سائل),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} درهم سائل),
						'many' => q({0} درهم سائل),
						'name' => q(درهم سائل),
						'one' => q({0} درهم سائل),
						'other' => q({0} درهم سائل),
						'two' => q({0} درهم سائل),
						'zero' => q({0} درهم سائل),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} قطرة),
						'many' => q({0} قطرة),
						'name' => q(قطرة),
						'one' => q({0} قطرة),
						'other' => q({0} قطرة),
						'two' => q({0} قطرة),
						'zero' => q({0} قطرة),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} قطرة),
						'many' => q({0} قطرة),
						'name' => q(قطرة),
						'one' => q({0} قطرة),
						'other' => q({0} قطرة),
						'two' => q({0} قطرة),
						'zero' => q({0} قطرة),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} أونصات سائلة),
						'many' => q({0} أونصة س),
						'name' => q(أونصة سائلة),
						'one' => q(أونصة س),
						'other' => q({0} أونصة سائلة),
						'two' => q({0} أونصة س),
						'zero' => q({0} أونصة سائلة),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} أونصات سائلة),
						'many' => q({0} أونصة س),
						'name' => q(أونصة سائلة),
						'one' => q(أونصة س),
						'other' => q({0} أونصة سائلة),
						'two' => q({0} أونصة س),
						'zero' => q({0} أونصة سائلة),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} أونصة سائلة إمبراطورية),
						'many' => q({0} أونصة سائلة إمبراطورية),
						'name' => q(أونصة سائلة إمبراطورية),
						'one' => q(أونصة سائلة إمبراطورية),
						'other' => q({0} أونصة سائلة إمبراطورية),
						'two' => q({0} أونصة سائلة إمبراطورية),
						'zero' => q({0} أونصة سائلة إمبراطورية),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} أونصة سائلة إمبراطورية),
						'many' => q({0} أونصة سائلة إمبراطورية),
						'name' => q(أونصة سائلة إمبراطورية),
						'one' => q(أونصة سائلة إمبراطورية),
						'other' => q({0} أونصة سائلة إمبراطورية),
						'two' => q({0} أونصة سائلة إمبراطورية),
						'zero' => q({0} أونصة سائلة إمبراطورية),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} غالون),
						'many' => q({0} غالون),
						'name' => q(غالون),
						'one' => q(غالون),
						'other' => q({0} غالون),
						'per' => q({0}/غالون),
						'two' => q({0} غالون),
						'zero' => q({0} غالون),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} غالون),
						'many' => q({0} غالون),
						'name' => q(غالون),
						'one' => q(غالون),
						'other' => q({0} غالون),
						'per' => q({0}/غالون),
						'two' => q({0} غالون),
						'zero' => q({0} غالون),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} غالون إمبراطوري),
						'many' => q({0} غالون إمبراطوري),
						'name' => q(غالون إمبراطوري),
						'one' => q({0} غالون إمبراطوري),
						'other' => q({0} غالون إمبراطوري),
						'per' => q({0}/غالون إمبراطوري),
						'two' => q({0} غالون إمبراطوري),
						'zero' => q({0} غالون إمبراطوري),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} غالون إمبراطوري),
						'many' => q({0} غالون إمبراطوري),
						'name' => q(غالون إمبراطوري),
						'one' => q({0} غالون إمبراطوري),
						'other' => q({0} غالون إمبراطوري),
						'per' => q({0}/غالون إمبراطوري),
						'two' => q({0} غالون إمبراطوري),
						'zero' => q({0} غالون إمبراطوري),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} هكتولتر),
						'many' => q({0} هكتولتر),
						'name' => q(هكتولتر),
						'one' => q({0} هكتولتر),
						'other' => q({0} هكتولتر),
						'two' => q({0} هكتولتر),
						'zero' => q({0} هكتولتر),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} هكتولتر),
						'many' => q({0} هكتولتر),
						'name' => q(هكتولتر),
						'one' => q({0} هكتولتر),
						'other' => q({0} هكتولتر),
						'two' => q({0} هكتولتر),
						'zero' => q({0} هكتولتر),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} أقداح),
						'many' => q({0} قدح),
						'name' => q(قدح),
						'one' => q({0} قدح),
						'other' => q({0} قدح),
						'two' => q({0} قدح),
						'zero' => q({0} قدح),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} أقداح),
						'many' => q({0} قدح),
						'name' => q(قدح),
						'one' => q({0} قدح),
						'other' => q({0} قدح),
						'two' => q({0} قدح),
						'zero' => q({0} قدح),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} لتر),
						'many' => q({0} لتر),
						'name' => q(لتر),
						'one' => q(لتر),
						'other' => q({0} لتر),
						'per' => q({0}/ل),
						'two' => q({0} لتر),
						'zero' => q({0} لتر),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} لتر),
						'many' => q({0} لتر),
						'name' => q(لتر),
						'one' => q(لتر),
						'other' => q({0} لتر),
						'per' => q({0}/ل),
						'two' => q({0} لتر),
						'zero' => q({0} لتر),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} ميغالتر),
						'many' => q({0} ميغالتر),
						'name' => q(ميغالتر),
						'one' => q({0} ميغالتر),
						'other' => q({0} ميغالتر),
						'two' => q({0} ميغالتر),
						'zero' => q({0} ميغالتر),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} ميغالتر),
						'many' => q({0} ميغالتر),
						'name' => q(ميغالتر),
						'one' => q({0} ميغالتر),
						'other' => q({0} ميغالتر),
						'two' => q({0} ميغالتر),
						'zero' => q({0} ميغالتر),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ملتر),
						'many' => q({0} ملتر),
						'name' => q(ملتر),
						'one' => q({0} ملتر),
						'other' => q({0} ملتر),
						'two' => q({0} ملتر),
						'zero' => q({0} ملتر),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ملتر),
						'many' => q({0} ملتر),
						'name' => q(ملتر),
						'one' => q({0} ملتر),
						'other' => q({0} ملتر),
						'two' => q({0} ملتر),
						'zero' => q({0} ملتر),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} رشّة),
						'many' => q({0} رشّة),
						'name' => q(رشّة),
						'one' => q({0} رشّة),
						'other' => q({0} رشّة),
						'two' => q({0} رشّة),
						'zero' => q({0} رشّة),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} رشّة),
						'many' => q({0} رشّة),
						'name' => q(رشّة),
						'one' => q({0} رشّة),
						'other' => q({0} رشّة),
						'two' => q({0} رشّة),
						'zero' => q({0} رشّة),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} باينت),
						'many' => q({0} باينت),
						'name' => q(باينت),
						'one' => q({0} باينت),
						'other' => q({0} باينت),
						'two' => q({0} باينت),
						'zero' => q({0} باينت),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} باينت),
						'many' => q({0} باينت),
						'name' => q(باينت),
						'one' => q({0} باينت),
						'other' => q({0} باينت),
						'two' => q({0} باينت),
						'zero' => q({0} باينت),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} مكيال متري),
						'many' => q({0} مكيال متري),
						'name' => q(مكيال متري),
						'one' => q({0} مكيال متري),
						'other' => q({0} مكيال متري),
						'two' => q({0} مكيال متري),
						'zero' => q({0} مكيال متري),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} مكيال متري),
						'many' => q({0} مكيال متري),
						'name' => q(مكيال متري),
						'one' => q({0} مكيال متري),
						'other' => q({0} مكيال متري),
						'two' => q({0} مكيال متري),
						'zero' => q({0} مكيال متري),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} ربع غالون),
						'many' => q({0} ربع غالون),
						'name' => q(ربع غالون),
						'one' => q(ربع غالون),
						'other' => q({0} ربع غالون),
						'two' => q({0} ربع غالون),
						'zero' => q({0} ربع غالون),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} ربع غالون),
						'many' => q({0} ربع غالون),
						'name' => q(ربع غالون),
						'one' => q(ربع غالون),
						'other' => q({0} ربع غالون),
						'two' => q({0} ربع غالون),
						'zero' => q({0} ربع غالون),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} ربع غالون إمبراطوري),
						'many' => q({0} ربع غالون إمبراطوري),
						'name' => q(ربع غالون إمبراطوري),
						'one' => q({0} ربع غالون إمبراطوري),
						'other' => q({0} ربع غالون إمبراطوري),
						'two' => q({0} ربع غالون إمبراطوري),
						'zero' => q({0} ربع غالون إمبراطوري),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} ربع غالون إمبراطوري),
						'many' => q({0} ربع غالون إمبراطوري),
						'name' => q(ربع غالون إمبراطوري),
						'one' => q({0} ربع غالون إمبراطوري),
						'other' => q({0} ربع غالون إمبراطوري),
						'two' => q({0} ربع غالون إمبراطوري),
						'zero' => q({0} ربع غالون إمبراطوري),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} ملعقة ك.),
						'many' => q({0} ملعقة ك.),
						'name' => q(ملعقة كبيرة),
						'one' => q(ملعقة ك.),
						'other' => q({0} ملعقة ك.),
						'two' => q({0} ملعقة ك.),
						'zero' => q({0} ملعقة ك.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} ملعقة ك.),
						'many' => q({0} ملعقة ك.),
						'name' => q(ملعقة كبيرة),
						'one' => q(ملعقة ك.),
						'other' => q({0} ملعقة ك.),
						'two' => q({0} ملعقة ك.),
						'zero' => q({0} ملعقة ك.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} ملعقة ص),
						'many' => q({0} ملعقة ص),
						'name' => q(ملعقة ص),
						'one' => q(ملعقة ص),
						'other' => q({0} ملعقة ص),
						'two' => q({0} ملعقة ص),
						'zero' => q({0} ملعقة ص),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} ملعقة ص),
						'many' => q({0} ملعقة ص),
						'name' => q(ملعقة ص),
						'one' => q(ملعقة ص),
						'other' => q({0} ملعقة ص),
						'two' => q({0} ملعقة ص),
						'zero' => q({0} ملعقة ص),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:نعم|ن|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:لا|ل|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0} و{1}),
				middle => q({0} و{1}),
				end => q({0} و{1}),
				2 => q({0} و{1}),
		} }
);

has 'default_numbering_system' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has native_numbering_system => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> 'arab',
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'exponential' => q(أس),
			'nan' => q(ليس رقم),
		},
		'latn' => {
			'minusSign' => q(‎-),
			'nan' => q(ليس رقمًا),
			'percentSign' => q(‎%‎),
			'plusSign' => q(‎+),
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
					'few' => '0 آلاف',
					'many' => '0 ألف',
					'one' => '0 ألف',
					'other' => '0 ألف',
					'two' => '0 ألف',
					'zero' => '0 ألف',
				},
				'10000' => {
					'few' => '00 ألف',
					'many' => '00 ألف',
					'one' => '00 ألف',
					'other' => '00 ألف',
					'two' => '00 ألف',
					'zero' => '00 ألف',
				},
				'100000' => {
					'few' => '000 ألف',
					'many' => '000 ألف',
					'one' => '000 ألف',
					'other' => '000 ألف',
					'two' => '000 ألف',
					'zero' => '000 ألف',
				},
				'1000000' => {
					'few' => '0 ملايين',
					'many' => '0 مليون',
					'one' => '0 مليون',
					'other' => '0 مليون',
					'two' => '0 مليون',
					'zero' => '0 مليون',
				},
				'10000000' => {
					'few' => '00 ملايين',
					'many' => '00 مليون',
					'one' => '00 مليون',
					'other' => '00 مليون',
					'two' => '00 مليون',
					'zero' => '00 مليون',
				},
				'100000000' => {
					'few' => '000 مليون',
					'many' => '000 مليون',
					'one' => '000 مليون',
					'other' => '000 مليون',
					'two' => '000 مليون',
					'zero' => '000 مليون',
				},
				'1000000000' => {
					'few' => '0 مليار',
					'many' => '0 مليار',
					'one' => '0 مليار',
					'other' => '0 مليار',
					'two' => '0 مليار',
					'zero' => '0 مليار',
				},
				'10000000000' => {
					'few' => '00 مليار',
					'many' => '00 مليار',
					'one' => '00 مليار',
					'other' => '00 مليار',
					'two' => '00 مليار',
					'zero' => '00 مليار',
				},
				'100000000000' => {
					'few' => '000 مليار',
					'many' => '000 مليار',
					'one' => '000 مليار',
					'other' => '000 مليار',
					'two' => '000 مليار',
					'zero' => '000 مليار',
				},
				'1000000000000' => {
					'few' => '0 ترليون',
					'many' => '0 ترليون',
					'one' => '0 ترليون',
					'other' => '0 ترليون',
					'two' => '0 ترليون',
					'zero' => '0 ترليون',
				},
				'10000000000000' => {
					'few' => '00 ترليون',
					'many' => '00 ترليون',
					'one' => '00 ترليون',
					'other' => '00 ترليون',
					'two' => '00 ترليون',
					'zero' => '00 ترليون',
				},
				'100000000000000' => {
					'few' => '000 ترليون',
					'many' => '000 ترليون',
					'one' => '000 ترليون',
					'other' => '000 ترليون',
					'two' => '000 ترليون',
					'zero' => '000 ترليون',
				},
			},
			'short' => {
				'1000' => {
					'few' => '0 آلاف',
					'many' => '0 ألف',
					'one' => '0 ألف',
					'other' => '0 ألف',
					'two' => '0 ألف',
					'zero' => '0 ألف',
				},
				'10000' => {
					'few' => '00 ألف',
					'many' => '00 ألف',
					'one' => '00 ألف',
					'other' => '00 ألف',
					'two' => '00 ألف',
					'zero' => '00 ألف',
				},
				'100000' => {
					'few' => '000 ألف',
					'many' => '000 ألف',
					'one' => '000 ألف',
					'other' => '000 ألف',
					'two' => '000 ألف',
					'zero' => '000 ألف',
				},
				'1000000' => {
					'one' => '0 مليون',
					'other' => '0 مليون',
				},
				'10000000' => {
					'one' => '00 مليون',
					'other' => '00 مليون',
				},
				'100000000' => {
					'one' => '000 مليون',
					'other' => '000 مليون',
				},
				'1000000000' => {
					'one' => '0 مليار',
					'other' => '0 مليار',
				},
				'10000000000' => {
					'one' => '00 مليار',
					'other' => '00 مليار',
				},
				'100000000000' => {
					'one' => '000 مليار',
					'other' => '000 مليار',
				},
				'1000000000000' => {
					'one' => '0 ترليون',
					'other' => '0 ترليون',
				},
				'10000000000000' => {
					'one' => '00 ترليون',
					'other' => '00 ترليون',
				},
				'100000000000000' => {
					'one' => '000 ترليون',
					'other' => '000 ترليون',
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
					'standard' => {
						'positive' => '‏#,##0.00 ¤',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(؜#,##0.00¤)',
						'positive' => '؜#,##0.00¤',
					},
					'standard' => {
						'negative' => '‏-#,##0.00 ¤',
						'positive' => '‏#,##0.00 ¤',
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
				'currency' => q(بيستا أندوري),
			},
		},
		'AED' => {
			symbol => 'د.إ.‏',
			display_name => {
				'currency' => q(درهم إماراتي),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(أفغاني - 1927-2002),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(أفغاني),
				'few' => q(أفغاني أفغانستاني),
				'many' => q(أفغاني أفغانستاني),
				'one' => q(أفغاني أفغانستاني),
				'other' => q(أفغاني أفغانستاني),
				'two' => q(أفغاني أفغانستاني),
				'zero' => q(أفغاني أفغانستاني),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(ليك ألباني),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(درام أرميني),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(غيلدر أنتيلي هولندي),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(كوانزا أنغولي),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(كوانزا أنجولي - 1977-1990),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(كوانزا أنجولي جديدة - 1990-2000),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(كوانزا أنجولي معدلة - 1995 - 1999),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(استرال أرجنتيني),
				'few' => q(أسترال أرجنتيني),
				'many' => q(أسترال أرجنتيني),
				'one' => q(أسترال أرجنتيني),
				'other' => q(أسترال أرجنتيني),
				'two' => q(أسترال أرجنتيني),
				'zero' => q(أسترال أرجنتيني),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(بيزو أرجنتيني - 1983-1985),
			},
		},
		'ARS' => {
			symbol => 'AR$',
			display_name => {
				'currency' => q(بيزو أرجنتيني),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(شلن نمساوي),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(دولار أسترالي),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(فلورن أروبي),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(مانات أذريبجاني),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(مانات أذربيجان),
				'few' => q(مانت أذربيجاني),
				'many' => q(مانت أذربيجاني),
				'one' => q(مانت أذربيجاني),
				'other' => q(مانت أذربيجاني),
				'two' => q(مانت أذربيجاني),
				'zero' => q(مانت أذربيجاني),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(دينار البوسنة والهرسك),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(مارك البوسنة والهرسك قابل للتحويل),
			},
		},
		'BBD' => {
			symbol => 'BB$',
			display_name => {
				'currency' => q(دولار بربادوسي),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(تاكا بنغلاديشي),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(فرنك بلجيكي قابل للتحويل),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(فرنك بلجيكي),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(فرنك بلجيكي مالي),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(ليف بلغاري),
			},
		},
		'BHD' => {
			symbol => 'د.ب.‏',
			display_name => {
				'currency' => q(دينار بحريني),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(فرنك بروندي),
			},
		},
		'BMD' => {
			symbol => 'BM$',
			display_name => {
				'currency' => q(دولار برمودي),
			},
		},
		'BND' => {
			symbol => 'BN$',
			display_name => {
				'currency' => q(دولار بروناي),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(بوليفيانو بوليفي),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(بيزو بوليفي),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(مفدول بوليفي),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(نوفو كروزايرو برازيلي - 1967-1986),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(كروزادو برازيلي),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(كروزايرو برازيلي - 1990-1993),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(ريال برازيلي),
			},
		},
		'BSD' => {
			symbol => 'BS$',
			display_name => {
				'currency' => q(دولار باهامي),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(نولتوم بوتاني),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(كيات بورمي),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(بولا بتسواني),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(روبل بيلاروسي جديد - 1994-1999),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(روبل بيلاروسي),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(روبل بيلاروسي \(٢٠٠٠–٢٠١٦\)),
			},
		},
		'BZD' => {
			symbol => 'BZ$',
			display_name => {
				'currency' => q(دولار بليزي),
				'few' => q(دولار بليزي),
				'many' => q(دولار بليزي),
				'one' => q(دولار بليزي),
				'other' => q(دولار بليزي),
				'two' => q(دولاران بليزيان),
				'zero' => q(دولار بليزي),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(دولار كندي),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(فرنك كونغولي),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(فرنك سويسري),
			},
		},
		'CLP' => {
			symbol => 'CL$',
			display_name => {
				'currency' => q(بيزو تشيلي),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(يوان صيني \(في الخارج\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(يوان صيني),
			},
		},
		'COP' => {
			symbol => 'CO$',
			display_name => {
				'currency' => q(بيزو كولومبي),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(كولن كوستاريكي),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(دينار صربي قديم),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(كرونة تشيكوسلوفاكيا),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(بيزو كوبي قابل للتحويل),
			},
		},
		'CUP' => {
			symbol => 'CU$',
			display_name => {
				'currency' => q(بيزو كوبي),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(اسكودو الرأس الأخضر),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(جنيه قبرصي),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(كرونة تشيكية),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(أوستمارك ألماني شرقي),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(مارك ألماني),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(فرنك جيبوتي),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(كرونة دنماركية),
			},
		},
		'DOP' => {
			symbol => 'DO$',
			display_name => {
				'currency' => q(بيزو الدومنيكان),
			},
		},
		'DZD' => {
			symbol => 'د.ج.‏',
			display_name => {
				'currency' => q(دينار جزائري),
				'few' => q(دينارات جزائرية),
				'many' => q(دينارًا جزائريًا),
				'one' => q(دينار جزائري),
				'other' => q(دينار جزائري),
				'two' => q(ديناران جزائريان),
				'zero' => q(دينار جزائري),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(كرونة استونية),
				'few' => q(كرونة أستونية),
				'many' => q(كرونة أستونية),
				'one' => q(كرونة أستونية),
				'other' => q(كرونة أستونية),
				'two' => q(كرونة أستونية),
				'zero' => q(كرونة أستونية),
			},
		},
		'EGP' => {
			symbol => 'ج.م.‏',
			display_name => {
				'currency' => q(جنيه مصري),
				'few' => q(جنيهات مصرية),
				'many' => q(جنيهًا مصريًا),
				'one' => q(جنيه مصري),
				'other' => q(جنيه مصري),
				'two' => q(جنيهان مصريان),
				'zero' => q(جنيه مصري),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(ناكفا أريتري),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(بيزيتا إسباني),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(بير أثيوبي),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(يورو),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(ماركا فنلندي),
			},
		},
		'FJD' => {
			symbol => 'FJ$',
			display_name => {
				'currency' => q(دولار فيجي),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(جنيه جزر فوكلاند),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(فرنك فرنسي),
			},
		},
		'GBP' => {
			symbol => 'UK£',
			display_name => {
				'currency' => q(جنيه إسترليني),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(لارى جورجي),
				'few' => q(لاري جورجي),
				'many' => q(لاري جورجي),
				'one' => q(لاري جورجي),
				'other' => q(لاري جورجي),
				'two' => q(لاري جورجي),
				'zero' => q(لاري جورجي),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(سيدي غاني),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(سيدي غانا),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(جنيه جبل طارق),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(دلاسي غامبي),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(فرنك غينيا),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(سيلي غينيا),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(اكويل جونينا غينيا الاستوائيّة),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(دراخما يوناني),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(كوتزال غواتيمالا),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(اسكود برتغالي غينيا),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(بيزو غينيا بيساو),
			},
		},
		'GYD' => {
			symbol => 'GY$',
			display_name => {
				'currency' => q(دولار غيانا),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(دولار هونغ كونغ),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(ليمبيرا هنداروس),
				'few' => q(ليمبيرا هندوراس),
				'many' => q(ليمبيرا هندوراس),
				'one' => q(ليمبيرا هندوراس),
				'other' => q(ليمبيرا هندوراس),
				'two' => q(ليمبيرا هندوراس),
				'zero' => q(ليمبيرا هندوراس),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(دينار كرواتي),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(كونا كرواتي),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(جوردى هايتي),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(فورينت هنغاري),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(روبية إندونيسية),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(جنيه إيرلندي),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(جنيه إسرائيلي),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(شيكل إسرائيلي جديد),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(روبية هندي),
			},
		},
		'IQD' => {
			symbol => 'د.ع.‏',
			display_name => {
				'currency' => q(دينار عراقي),
			},
		},
		'IRR' => {
			symbol => 'ر.إ.',
			display_name => {
				'currency' => q(ريال إيراني),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(كرونة أيسلندية),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(ليرة إيطالية),
			},
		},
		'JMD' => {
			symbol => 'JM$',
			display_name => {
				'currency' => q(دولار جامايكي),
			},
		},
		'JOD' => {
			symbol => 'د.أ.‏',
			display_name => {
				'currency' => q(دينار أردني),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(ين ياباني),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(شلن كينيي),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(سوم قيرغستاني),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(رييال كمبودي),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(فرنك جزر القمر),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(وون كوريا الشمالية),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(وون كوريا الجنوبية),
			},
		},
		'KWD' => {
			symbol => 'د.ك.‏',
			display_name => {
				'currency' => q(دينار كويتي),
			},
		},
		'KYD' => {
			symbol => 'KY$',
			display_name => {
				'currency' => q(دولار جزر كيمن),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(تينغ كازاخستاني),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(كيب لاوسي),
			},
		},
		'LBP' => {
			symbol => 'ل.ل.‏',
			display_name => {
				'currency' => q(جنيه لبناني),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(روبية سريلانكية),
			},
		},
		'LRD' => {
			symbol => '$LR',
			display_name => {
				'currency' => q(دولار ليبيري),
				'few' => q(دولارات ليبيرية),
				'many' => q(دولارًا ليبيريًا),
				'one' => q(دولار ليبيري),
				'other' => q(دولار ليبيري),
				'two' => q(دولاران ليبيريان),
				'zero' => q(دولار ليبيري),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(لوتي ليسوتو),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(ليتا ليتوانية),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(تالوناس ليتواني),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(فرنك لوكسمبرج قابل للتحويل),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(فرنك لوكسمبرج),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(فرنك لوكسمبرج المالي),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(لاتس لاتفيا),
				'few' => q(لاتس لاتفي),
				'many' => q(لاتس لاتفي),
				'one' => q(لاتس لاتفي),
				'other' => q(لاتس لاتفي),
				'two' => q(لاتس لاتفي),
				'zero' => q(لاتس لاتفي),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(روبل لاتفيا),
			},
		},
		'LYD' => {
			symbol => 'د.ل.‏',
			display_name => {
				'currency' => q(دينار ليبي),
				'few' => q(دينارات ليبية),
				'many' => q(دينارًا ليبيًا),
				'one' => q(دينار ليبي),
				'other' => q(دينار ليبي),
				'two' => q(ديناران ليبيان),
				'zero' => q(دينار ليبي),
			},
		},
		'MAD' => {
			symbol => 'د.م.‏',
			display_name => {
				'currency' => q(درهم مغربي),
				'few' => q(دراهم مغربية),
				'many' => q(درهمًا مغربيًا),
				'one' => q(درهم مغربي),
				'other' => q(درهم مغربي),
				'two' => q(درهمان مغربيان),
				'zero' => q(درهم مغربي),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(فرنك مغربي),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(ليو مولدوفي),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(أرياري مدغشقر),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(فرنك مدغشقر),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(دينار مقدوني),
				'few' => q(دينارات مقدونية),
				'many' => q(دينارًا مقدونيًا),
				'one' => q(دينار مقدوني),
				'other' => q(دينار مقدوني),
				'two' => q(ديناران مقدونيان),
				'zero' => q(دينار مقدوني),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(فرنك مالي),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(كيات ميانمار),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(توغروغ منغولي),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(باتاكا ماكاوي),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(أوقية موريتانية - 1973-2017),
			},
		},
		'MRU' => {
			symbol => 'أ.م.',
			display_name => {
				'currency' => q(أوقية موريتانية),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(ليرة مالطية),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(جنيه مالطي),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(روبية موريشيوسية),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(روفيه جزر المالديف),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(كواشا مالاوي),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(بيزو مكسيكي),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(بيزو فضي مكسيكي - 1861-1992),
				'few' => q(بيزو فضي مكسيكي),
				'many' => q(بيزو فضي مكسيكي),
				'one' => q(بيزو فضي مكسيكي),
				'other' => q(بيزو فضي مكسيكي),
				'two' => q(بيزو فضي مكسيكي),
				'zero' => q(بيزو فضي مكسيكي),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(رينغيت ماليزي),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(اسكود موزمبيقي),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(متكال موزمبيقي),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(دولار ناميبي),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(نايرا نيجيري),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(كوردوبة نيكاراجوا),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(قرطبة نيكاراغوا),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(جلدر هولندي),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(كرونة نرويجية),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(روبية نيبالي),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(دولار نيوزيلندي),
			},
		},
		'OMR' => {
			symbol => 'ر.ع.‏',
			display_name => {
				'currency' => q(ريال عماني),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(بالبوا بنمي),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(سول بيروفي),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(كينا بابوا غينيا الجديدة),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(بيزو فلبيني),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(روبية باكستاني),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(زلوتي بولندي),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(زلوتي بولندي - 1950-1995),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(اسكود برتغالي),
				'few' => q(أسكود برتغالي),
				'many' => q(أسكود برتغالي),
				'one' => q(أسكود برتغالي),
				'other' => q(أسكود برتغالي),
				'two' => q(أسكود برتغالي),
				'zero' => q(أسكود برتغالي),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(غواراني باراغواي),
			},
		},
		'QAR' => {
			symbol => 'ر.ق.‏',
			display_name => {
				'currency' => q(ريال قطري),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(دولار روديسي),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(ليو روماني قديم),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(ليو روماني),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(دينار صربي),
				'few' => q(دينارات صربية),
				'many' => q(دينارًا صربيًا),
				'one' => q(دينار صربي),
				'other' => q(دينار صربي),
				'two' => q(ديناران صربيان),
				'zero' => q(دينار صربي),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(روبل روسي),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(روبل روسي - 1991-1998),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(فرنك رواندي),
			},
		},
		'SAR' => {
			symbol => 'ر.س.‏',
			display_name => {
				'currency' => q(ريال سعودي),
			},
		},
		'SBD' => {
			symbol => 'SB$',
			display_name => {
				'currency' => q(دولار جزر سليمان),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(روبية سيشيلية),
			},
		},
		'SDD' => {
			symbol => 'د.س.‏',
			display_name => {
				'currency' => q(دينار سوداني),
				'few' => q(دينار سوداني قديم),
				'many' => q(دينار سوداني قديم),
				'one' => q(دينار سوداني قديم),
				'other' => q(دينار سوداني قديم),
				'two' => q(دينار سوداني قديم),
				'zero' => q(دينار سوداني قديم),
			},
		},
		'SDG' => {
			symbol => 'ج.س.',
			display_name => {
				'currency' => q(جنيه سوداني),
				'few' => q(جنيهات سودانية),
				'many' => q(جنيهًا سودانيًا),
				'one' => q(جنيه سوداني),
				'other' => q(جنيه سوداني),
				'two' => q(جنيه سوداني),
				'zero' => q(جنيه سوداني),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(جنيه سوداني قديم),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(كرونة سويدية),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(دولار سنغافوري),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(جنيه سانت هيلين),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(تولار سلوفيني),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(كرونة سلوفاكية),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(ليون سيراليوني),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(ليون سيراليوني - 1964-2022),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(شلن صومالي),
			},
		},
		'SRD' => {
			symbol => 'SR$',
			display_name => {
				'currency' => q(دولار سورينامي),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(جلدر سورينامي),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(جنيه جنوب السودان),
				'few' => q(جنيهات جنوب السودان),
				'many' => q(جنيهًا جنوب السودان),
				'one' => q(جنيه جنوب السودان),
				'other' => q(جنيه جنوب السودان),
				'two' => q(جنيهان جنوب السودان),
				'zero' => q(جنيه جنوب السودان),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(دوبرا ساو تومي وبرينسيبي - 1977-2017),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(دوبرا ساو تومي وبرينسيبي),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(روبل سوفيتي),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(كولون سلفادوري),
			},
		},
		'SYP' => {
			symbol => 'ل.س.‏',
			display_name => {
				'currency' => q(ليرة سورية),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(ليلانجيني سوازيلندي),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(باخت تايلاندي),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(روبل طاجيكستاني),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(سوموني طاجيكستاني),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(مانات تركمنستاني),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(مانات تركمانستان),
			},
		},
		'TND' => {
			symbol => 'د.ت.‏',
			display_name => {
				'currency' => q(دينار تونسي),
				'few' => q(دينارات تونسية),
				'many' => q(دينارًا تونسيًا),
				'one' => q(دينار تونسي),
				'other' => q(دينار تونسي),
				'two' => q(ديناران تونسيان),
				'zero' => q(دينار تونسي),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(بانغا تونغا),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(اسكود تيموري),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(ليرة تركي),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(ليرة تركية),
			},
		},
		'TTD' => {
			symbol => 'TT$',
			display_name => {
				'currency' => q(دولار ترينداد وتوباغو),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(دولار تايواني),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(شلن تنزاني),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(هريفنيا أوكراني),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(شلن أوغندي - 1966-1987),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(شلن أوغندي),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(دولار أمريكي),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(دولار أمريكي \(اليوم التالي\)‏),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(دولار أمريكي \(نفس اليوم\)‏),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(بيزو أوروجواي - 1975-1993),
			},
		},
		'UYU' => {
			symbol => 'UY$',
			display_name => {
				'currency' => q(بيزو اوروغواي),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(سوم أوزبكستاني),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(بوليفار فنزويلي - 1871-2008),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(بوليفار فنزويلي - 2008–2018),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(بوليفار فنزويلي),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(دونج فيتنامي),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(فاتو فانواتو),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(تالا ساموا),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(فرنك وسط أفريقي),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(فضة),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(ذهب),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(الوحدة الأوروبية المركبة),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(الوحدة المالية الأوروبية),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(الوحدة الحسابية الأوروبية),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(\(XBD\)وحدة الحساب الأوروبية),
				'few' => q(وحدة الحساب الأوروبية),
				'many' => q(وحدة الحساب الأوروبية),
				'one' => q(وحدة الحساب الأوروبية),
				'other' => q(وحدة الحساب الأوروبية),
				'two' => q(وحدة الحساب الأوروبية),
				'zero' => q(وحدة الحساب الأوروبية),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(دولار شرق الكاريبي),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(حقوق السحب الخاصة),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(وحدة النقد الأوروبية),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(فرنك فرنسي ذهبي),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(\(UIC\)فرنك فرنسي),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(فرنك غرب أفريقي),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(بالاديوم),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(فرنك سي إف بي),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(البلاتين),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(كود اختبار العملة),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(عملة غير معروفة),
				'few' => q(\(عملة غير معروفة\)),
				'many' => q(\(عملة غير معروفة\)),
				'one' => q(\(عملة غير معروفة\)),
				'other' => q(\(عملة غير معروفة\)),
				'two' => q(\(عملة غير معروفة\)),
				'zero' => q(\(عملة غير معروفة\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(دينار يمني),
			},
		},
		'YER' => {
			symbol => 'ر.ي.‏',
			display_name => {
				'currency' => q(ريال يمني),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(دينار يوغسلافي),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(دينار يوغسلافي قابل للتحويل),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(راند جنوب أفريقيا -مالي),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(راند جنوب أفريقيا),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(كواشا زامبي - 1968-2012),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(كواشا زامبي),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(زائير زائيري جديد),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(زائير زائيري),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(دولار زمبابوي),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(دولار زمبابوي 2009),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'توت',
							'بابه',
							'هاتور',
							'كيهك',
							'طوبة',
							'أمشير',
							'برمهات',
							'برمودة',
							'بشنس',
							'بؤونة',
							'أبيب',
							'مسرى',
							'نسيئ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'١',
							'٢',
							'٣',
							'٤',
							'٥',
							'٦',
							'٧',
							'٨',
							'٩',
							'١٠',
							'١١',
							'١٢',
							'١٣'
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
							'مسكريم',
							'تكمت',
							'هدار',
							'تهساس',
							'تر',
							'يكتت',
							'مجابيت',
							'ميازيا',
							'جنبت',
							'سين',
							'هامل',
							'نهاس',
							'باجمن'
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
							'يناير',
							'فبراير',
							'مارس',
							'أبريل',
							'مايو',
							'يونيو',
							'يوليو',
							'أغسطس',
							'سبتمبر',
							'أكتوبر',
							'نوفمبر',
							'ديسمبر'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'ي',
							'ف',
							'م',
							'أ',
							'و',
							'ن',
							'ل',
							'غ',
							'س',
							'ك',
							'ب',
							'د'
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
							'تشري',
							'مرحشوان',
							'كيسلو',
							'طيفت',
							'شباط',
							'آذار الأول',
							'آذار',
							'نيسان',
							'أيار',
							'سيفان',
							'تموز',
							'آب',
							'أيلول'
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
					abbreviated => {
						nonleap => [
							'محرم',
							'صفر',
							'ربيع الأول',
							'ربيع الآخر',
							'جمادى الأولى',
							'جمادى الآخرة',
							'رجب',
							'شعبان',
							'رمضان',
							'شوال',
							'ذو القعدة',
							'ذو الحجة'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'محرم',
							'صفر',
							'ربيع الأول',
							'ربيع الآخر',
							'جمادى الأولى',
							'جمادى الآخرة',
							'رجب',
							'شعبان',
							'رمضان',
							'شوال',
							'ذو القعدة',
							'ذو الحجة'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'١',
							'٢',
							'٣',
							'٤',
							'٥',
							'٦',
							'٧',
							'٨',
							'٩',
							'١٠',
							'١١',
							'١٢'
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
							'فرفردن',
							'أذربيهشت',
							'خرداد',
							'تار',
							'مرداد',
							'شهرفار',
							'مهر',
							'آيان',
							'آذر',
							'دي',
							'بهمن',
							'اسفندار'
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
						mon => 'إثنين',
						tue => 'ثلاثاء',
						wed => 'أربعاء',
						thu => 'خميس',
						fri => 'جمعة',
						sat => 'سبت',
						sun => 'أحد'
					},
					wide => {
						mon => 'الاثنين',
						tue => 'الثلاثاء',
						wed => 'الأربعاء',
						thu => 'الخميس',
						fri => 'الجمعة',
						sat => 'السبت',
						sun => 'الأحد'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'ن',
						tue => 'ث',
						wed => 'ر',
						thu => 'خ',
						fri => 'ج',
						sat => 'س',
						sun => 'ح'
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
					wide => {0 => 'الربع الأول',
						1 => 'الربع الثاني',
						2 => 'الربع الثالث',
						3 => 'الربع الرابع'
					},
				},
				'stand-alone' => {
					narrow => {0 => '١',
						1 => '٢',
						2 => '٣',
						3 => '٤'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1300;
					return 'afternoon2' if $time >= 1300
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 300
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 100;
					return 'night2' if $time >= 100
						&& $time < 300;
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
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'am' => q{ص},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{ص},
					'night1' => q{في المساء},
					'night2' => q{ليلاً},
					'pm' => q{م},
				},
				'narrow' => {
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{صباحًا},
					'night1' => q{منتصف الليل},
					'night2' => q{ليلاً},
				},
				'wide' => {
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'evening1' => q{مساءً},
					'morning1' => q{في الصباح},
					'morning2' => q{صباحًا},
					'night1' => q{في المساء},
					'night2' => q{ليلاً},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{ص},
					'night1' => q{منتصف الليل},
					'night2' => q{ليلاً},
				},
				'narrow' => {
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{صباحًا},
					'night1' => q{منتصف الليل},
					'night2' => q{ليلاً},
				},
				'wide' => {
					'afternoon1' => q{ظهرًا},
					'afternoon2' => q{بعد الظهر},
					'am' => q{صباحًا},
					'evening1' => q{مساءً},
					'morning1' => q{فجرًا},
					'morning2' => q{صباحًا},
					'night1' => q{منتصف الليل},
					'night2' => q{ليلاً},
					'pm' => q{مساءً},
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
			wide => {
				'0' => 'التقويم البوذي'
			},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'ق.م',
				'1' => 'م'
			},
			wide => {
				'0' => 'قبل الميلاد',
				'1' => 'ميلادي'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'ص'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'هـ'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'تيكا',
				'1' => 'هاكتشي',
				'2' => 'هاكهو',
				'3' => 'شتشو',
				'4' => 'تيهو',
				'5' => 'كيين',
				'6' => 'وادو',
				'7' => 'رييكي',
				'8' => 'يورو',
				'9' => 'جينكي',
				'10' => 'تمبيو',
				'11' => 'تمبيو-كامبو',
				'12' => 'تمبيو-شوهو',
				'13' => 'تمبيو-هوجي',
				'14' => 'تمفو-جينجو',
				'15' => 'جينجو-كيين',
				'16' => 'هوكي',
				'17' => 'تن-أو',
				'18' => 'إنرياكو',
				'19' => 'ديدو',
				'20' => 'كونين',
				'21' => 'تنتشو',
				'22' => 'شووا (٨٣٤–٨٤٨)‏',
				'23' => 'كاجو',
				'24' => 'نينجو',
				'25' => 'سيكو',
				'26' => 'تنان',
				'27' => 'جوجان',
				'28' => 'جينكيي',
				'29' => 'نينا',
				'30' => 'كامبيو',
				'31' => 'شوتاي',
				'32' => 'انجي',
				'33' => 'انتشو',
				'34' => 'شوهيي',
				'35' => 'تنجيو',
				'36' => 'تنرياكو',
				'37' => 'تنتوكو',
				'38' => 'أووا',
				'39' => 'كوهو',
				'40' => 'آنا',
				'41' => 'تينروكو',
				'42' => 'تن-نن',
				'43' => 'جوجن',
				'44' => 'تنجن',
				'45' => 'إيكان',
				'46' => 'كانا',
				'47' => 'اي-ان',
				'48' => 'ايسو',
				'49' => 'شورياكو (٩٩٠–٩٩٥)‏',
				'50' => 'تشوتوكو',
				'51' => 'تشوهو',
				'52' => 'كانكو',
				'53' => 'تشووا',
				'54' => 'كانين',
				'55' => 'جاين',
				'56' => 'مانجو',
				'57' => 'تشوجين',
				'58' => 'تشورياكو',
				'59' => 'تشوكيو (١٠٤٠–١٠٤٤)‏',
				'60' => 'كانتوكو',
				'61' => 'ايشو (١٠٤٦–١٠٥٣)‏',
				'62' => 'تينجي',
				'63' => 'كوهيي',
				'64' => 'جيرياكو',
				'65' => 'انكيو (١٠٦٩–١٠٧٤)‏',
				'66' => 'شوهو (١٠٧٤–١٠٧٧)‏',
				'67' => 'شورياكو (١٠٧٧–١٠٨١)‏',
				'68' => 'ايهو',
				'69' => 'أوتوكو',
				'70' => 'كانجي',
				'71' => 'كاهو',
				'72' => 'ايتشو',
				'73' => 'شوتوكو',
				'74' => 'كووا (١٠٩٩–١١٠٤)‏',
				'75' => 'تشوجي',
				'76' => 'كاشو',
				'77' => 'تنين',
				'78' => 'تن-اي',
				'79' => 'ايكيو (١١١٣–١١١٨)‏',
				'80' => 'جن-اي',
				'81' => 'هوان',
				'82' => 'تنجي',
				'83' => 'ديجي',
				'84' => 'تنشو (١١٣١–١١٣٢)‏',
				'85' => 'تشوشو',
				'86' => 'هوين',
				'87' => 'ايجي',
				'88' => 'كوجي (١١٤٢–١١٤٤)‏',
				'89' => 'تنيو',
				'90' => 'كيوان',
				'91' => 'نينبيي',
				'92' => 'كيوجو',
				'93' => 'هجين',
				'94' => 'هيجي',
				'95' => 'ايرياكو',
				'96' => 'أوهو',
				'97' => 'تشوكان',
				'98' => 'ايمان',
				'99' => 'نين-ان',
				'100' => 'كاو',
				'101' => 'شون',
				'102' => 'أنجين',
				'103' => 'جيشو',
				'104' => 'يووا',
				'105' => 'جيي',
				'106' => 'جنريوكو',
				'107' => 'بنجي',
				'108' => 'كنكيو',
				'109' => 'شوجي',
				'110' => 'كنين',
				'111' => 'جنكيو (١٢٠٤–١٢٠٦)‏',
				'112' => 'كن-اي',
				'113' => 'شوجن (١٢٠٧–١٢١١)‏',
				'114' => 'كنرياكو',
				'115' => 'كنبو (١٢١٣–١٢١٩)‏',
				'116' => 'شوكيو',
				'117' => 'جو',
				'118' => 'جيننين',
				'119' => 'كروكو',
				'120' => 'أنتيي',
				'121' => 'كنكي',
				'122' => 'جويي',
				'123' => 'تمبكو',
				'124' => 'بنرياكو',
				'125' => 'كاتيي',
				'126' => 'رياكنين',
				'127' => 'ان-أو',
				'128' => 'نينجي',
				'129' => 'كنجين',
				'130' => 'هوجي',
				'131' => 'كنتشو',
				'132' => 'كوجن',
				'133' => 'شوكا',
				'134' => 'شوجن (١٢٥٩–١٢٦٠)‏',
				'135' => 'بن-أو',
				'136' => 'كوتشو',
				'137' => 'بن-اي',
				'138' => 'كنجي',
				'139' => 'كوان',
				'140' => 'شوو (١٢٨٨–١٢٩٣)‏',
				'141' => 'اينين',
				'142' => 'شوان',
				'143' => 'كنجن',
				'144' => 'كجن',
				'145' => 'توكجي',
				'146' => 'انكي',
				'147' => 'أوتشو',
				'148' => 'شووا (١٣١٢–١٣١٧)‏',
				'149' => 'بنبو',
				'150' => 'جنو',
				'151' => 'جنكيو (١٣٢١–١٣٢٤)‏',
				'152' => 'شوتشو (١٣٢٤–١٣٢٦)‏',
				'153' => 'كريكي',
				'154' => 'جنتكو',
				'155' => 'جنكو',
				'156' => 'كمو',
				'157' => 'إنجن',
				'158' => 'كوككو',
				'159' => 'شوهي',
				'160' => 'كنتكو',
				'161' => 'بنتشو',
				'162' => 'تنجو',
				'163' => 'كورياكو',
				'164' => 'كووا (١٣٨١–١٣٨٤)‏',
				'165' => 'جنتشو',
				'166' => 'مييتكو (١٣٨٤–١٣٨٧)‏',
				'167' => 'كاكي',
				'168' => 'كو',
				'169' => 'مييتكو (١٣٩٠–١٣٩٤)‏',
				'170' => 'أويي',
				'171' => 'شوتشو (١٤٢٨–١٤٢٩)‏',
				'172' => 'ايكيو (١٤٢٩–١٤٤١)‏',
				'173' => 'ككيتسو',
				'174' => 'بن-أن',
				'175' => 'هوتكو',
				'176' => 'كيوتكو',
				'177' => 'كوشو',
				'178' => 'تشوركو',
				'179' => 'كنشو',
				'180' => 'بنشو',
				'181' => 'أونين',
				'182' => 'بنمي',
				'183' => 'تشوكيو (١٤٨٧–١٤٨٩)‏',
				'184' => 'انتكو',
				'185' => 'ميو',
				'186' => 'بنكي',
				'187' => 'ايشو (١٥٠٤–١٥٢١)‏',
				'188' => 'تييي',
				'189' => 'كيوركو',
				'190' => 'تنمن',
				'191' => 'كوجي (١٥٥٥–١٥٥٨)‏',
				'192' => 'ايركو',
				'193' => 'جنكي',
				'194' => 'تنشو (١٥٧٣–١٥٩٢)‏',
				'195' => 'بنركو',
				'196' => 'كيتشو',
				'197' => 'جنوا',
				'198' => 'كان-اي',
				'199' => 'شوهو (١٦٤٤–١٦٤٨)‏',
				'200' => 'كيان',
				'201' => 'شوو (١٦٥٢–١٦٥٥)‏',
				'202' => 'ميرياكو',
				'203' => 'منجي',
				'204' => 'كنبن',
				'205' => 'انبو',
				'206' => 'تنوا',
				'207' => 'جوكيو',
				'208' => 'جنركو',
				'209' => 'هويي',
				'210' => 'شوتكو',
				'211' => 'كيوهو',
				'212' => 'جنبن',
				'213' => 'كنبو (١٧٤١–١٧٤٤)‏',
				'214' => 'انكيو (١٧٤٤–١٧٤٨)‏',
				'215' => 'كان-ان',
				'216' => 'هورياكو',
				'217' => 'مييوا',
				'218' => 'ان-اي',
				'219' => 'تنمي',
				'220' => 'كنسي',
				'221' => 'كيووا',
				'222' => 'بنكا',
				'223' => 'بنسي',
				'224' => 'تنبو',
				'225' => 'كوكا',
				'226' => 'كاي',
				'227' => 'أنسي',
				'228' => 'من-ان',
				'229' => 'بنكيو',
				'230' => 'جنجي',
				'231' => 'كيو',
				'232' => 'ميجي',
				'233' => 'تيشو',
				'234' => 'شووا',
				'235' => 'هيسي',
				'236' => 'ريوا'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'ه‍.ش'
			},
		},
		'roc' => {
			abbreviated => {
				'1' => 'جمهورية الصي'
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd‏/MM‏/y G},
			'short' => q{d‏/M‏/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE، d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{dd‏/MM‏/y},
			'short' => q{d‏/M‏/y},
		},
		'hebrew' => {
		},
		'islamic' => {
			'full' => q{EEEE، d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d‏/M‏/y GGGGG},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1}، {0}},
			'long' => q{{1}، {0}},
			'medium' => q{{1}، {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}، {0}},
			'long' => q{{1}، {0}},
			'medium' => q{{1}، {0}},
			'short' => q{{1}، {0}},
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
		'generic' => {
			Ed => q{E، d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E، d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d‏/M‏/y G},
			MEd => q{E، d‏/M},
			MMMEd => q{E، d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d‏/M},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M‏/y G},
			yyyyMEd => q{E، d‏/M‏/y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E، d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d‏/M‏/y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E، d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E، d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd-MM-y GGGGG},
			MEd => q{E، d‏/M},
			MMMEd => q{E، d MMM},
			MMMMEd => q{E، d MMMM},
			MMMMW => q{الأسبوع W من MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd‏/MM},
			Md => q{d‏/M},
			yM => q{M‏/y},
			yMEd => q{E، d‏/M‏/y},
			yMM => q{MM‏/y},
			yMMM => q{MMM y},
			yMMMEd => q{E، d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d‏/M‏/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{الأسبوع w من سنة Y},
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
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM-y GGGG – MM-y GGGG},
				M => q{MM-y – MM-y GGGG},
				y => q{MM-y – MM-y GGGG},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGG – E, dd-MM-y GGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGG},
				y => q{E, dd-MM-y – E,dd-MM-y GGGG},
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
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd-MM-y GGGG – dd-MM-y GGGG},
				M => q{dd-MM-y – dd-MM-y GGGG},
				d => q{dd-MM-y – dd-MM-y GGGG},
				y => q{dd-MM-y – dd-MM-y GGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d‏/M – E، d‏/M},
				d => q{E، d‏/M – E، d‏/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d – E، d MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d‏/M – d‏/M},
				d => q{d‏/M – d‏/M},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M‏/y – M‏/y G},
				y => q{M‏/y – M‏/y G},
			},
			yMEd => {
				M => q{E، d‏/M‏/y – E، d‏/M‏/y G},
				d => q{E، dd‏/MM‏/y – E، dd‏/MM‏/y G},
				y => q{E، d‏/M‏/y – E، d‏/M‏/y G},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM، y – MMM y G},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM y G},
				d => q{E، d – E، d MMM y G},
				y => q{E، d MMM y – E، d MMM y G},
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
				M => q{d‏/M‏/y – d‏/M‏/y G},
				d => q{d‏/M‏/y – d‏/M‏/y G},
				y => q{d‏/M‏/y – d‏/M‏/y G},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM-y GGGG – MM-y GGGG},
				M => q{MM-y – MM-y GGGG},
				y => q{MM-y – MM-y GGGG},
			},
			GyMEd => {
				G => q{E, dd-MM-y GGGG – E, dd-MM-y GGGG},
				M => q{E, dd-MM-y – E, dd-MM-y GGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGG},
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
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd-MM-y GGGG – dd-MM-y GGGG},
				M => q{dd-MM-y – dd-MM-y GGGG},
				d => q{d-MM-y – d-MM-y GGGG},
				y => q{dd-MM-y – dd-MM-y GGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E، d‏/M – E، d‏/M},
				d => q{E، d‏/M – E، d‏/M},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E، d MMM – E، d MMM},
				d => q{E، d – E، d MMM},
			},
			MMMM => {
				M => q{LLLL–LLLL},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{d‏/M – d‏/M},
				d => q{d‏/M – d‏/M},
			},
			fallback => '{0} – {1}',
			yM => {
				M => q{M‏/y – M‏/y},
				y => q{M‏/y – M‏/y},
			},
			yMEd => {
				M => q{E، d‏/M‏/y – E، d‏/M‏/y},
				d => q{E، dd‏/MM‏/y – E، dd‏/MM‏/y},
				y => q{E، d‏/M‏/y – E، d‏/M‏/y},
			},
			yMMM => {
				M => q{MMM – MMM، y},
				y => q{MMM، y – MMM، y},
			},
			yMMMEd => {
				M => q{E، d MMM – E، d MMM، y},
				d => q{E، d – E، d MMM، y},
				y => q{E، d MMM، y – E، d MMM، y},
			},
			yMMMM => {
				M => q{MMMM – MMMM، y},
				y => q{MMMM، y – MMMM، y},
			},
			yMMMd => {
				M => q{d MMM – d MMM، y},
				d => q{d–d MMM، y},
				y => q{d MMM، y – d MMM، y},
			},
			yMd => {
				M => q{d‏/M‏/y – d‏/M‏/y},
				d => q{d‏/M‏/y – d‏/M‏/y},
				y => q{d‏/M‏/y – d‏/M‏/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(غرينتش{0}),
		gmtZeroFormat => q(غرينتش),
		regionFormat => q(توقيت {0}),
		regionFormat => q(توقيت {0} الصيفي),
		regionFormat => q(توقيت {0} الرسمي),
		'Afghanistan' => {
			long => {
				'standard' => q#توقيت أفغانستان#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#أبيدجان#,
		},
		'Africa/Accra' => {
			exemplarCity => q#أكرا#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#أديس أبابا#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#الجزائر#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#أسمرة#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#باماكو#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#بانغوي#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#بانجول#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#بيساو#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#بلانتاير#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#برازافيل#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#بوجومبورا#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#القاهرة#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#الدار البيضاء#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#سيتا#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#كوناكري#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#داكار#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#دار السلام#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#جيبوتي#,
		},
		'Africa/Douala' => {
			exemplarCity => q#دوالا#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#العيون#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#فري تاون#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#غابورون#,
		},
		'Africa/Harare' => {
			exemplarCity => q#هراري#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#جوهانسبرغ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#جوبا#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#كامبالا#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#الخرطوم#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#كيغالي#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#كينشاسا#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#لاغوس#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#ليبرفيل#,
		},
		'Africa/Lome' => {
			exemplarCity => q#لومي#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#لواندا#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#لومبباشا#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#لوساكا#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#مالابو#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#مابوتو#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#ماسيرو#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#مباباني#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#مقديشيو#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#مونروفيا#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#نيروبي#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#نجامينا#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#نيامي#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#نواكشوط#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#واغادوغو#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#بورتو نوفو#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ساو تومي#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#طرابلس#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#تونس#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ويندهوك#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#توقيت وسط أفريقيا#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#توقيت شرق أفريقيا#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#توقيت جنوب أفريقيا#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#توقيت غرب أفريقيا الصيفي#,
				'generic' => q#توقيت غرب أفريقيا#,
				'standard' => q#توقيت غرب أفريقيا الرسمي#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#توقيت ألاسكا الصيفي#,
				'generic' => q#توقيت ألاسكا#,
				'standard' => q#التوقيت الرسمي لألاسكا#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#توقيت الأمازون الصيفي#,
				'generic' => q#توقيت الأمازون#,
				'standard' => q#توقيت الأمازون الرسمي#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#أداك#,
		},
		'America/Anchorage' => {
			exemplarCity => q#أنشوراج#,
		},
		'America/Anguilla' => {
			exemplarCity => q#أنغويلا#,
		},
		'America/Antigua' => {
			exemplarCity => q#أنتيغوا#,
		},
		'America/Araguaina' => {
			exemplarCity => q#أروجوانيا#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#لا ريوجا#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ريو جالييوس#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#سالطا#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#سان خوان#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#سان لويس#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#تاكمان#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#أشوا#,
		},
		'America/Aruba' => {
			exemplarCity => q#أروبا#,
		},
		'America/Asuncion' => {
			exemplarCity => q#أسونسيون#,
		},
		'America/Bahia' => {
			exemplarCity => q#باهيا#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#باهيا بانديراس#,
		},
		'America/Barbados' => {
			exemplarCity => q#بربادوس#,
		},
		'America/Belem' => {
			exemplarCity => q#بلم#,
		},
		'America/Belize' => {
			exemplarCity => q#بليز#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#بلانك-سابلون#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#باو فيستا#,
		},
		'America/Bogota' => {
			exemplarCity => q#بوغوتا#,
		},
		'America/Boise' => {
			exemplarCity => q#بويس#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#بوينوس أيرس#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#كامبرديج باي#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#كومبو جراند#,
		},
		'America/Cancun' => {
			exemplarCity => q#كانكون#,
		},
		'America/Caracas' => {
			exemplarCity => q#كاراكاس#,
		},
		'America/Catamarca' => {
			exemplarCity => q#كاتاماركا#,
		},
		'America/Cayenne' => {
			exemplarCity => q#كايين#,
		},
		'America/Cayman' => {
			exemplarCity => q#كايمان#,
		},
		'America/Chicago' => {
			exemplarCity => q#شيكاغو#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#تشيواوا#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#سيوداد خواريز#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#كورال هاربر#,
		},
		'America/Cordoba' => {
			exemplarCity => q#كوردوبا#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#كوستاريكا#,
		},
		'America/Creston' => {
			exemplarCity => q#كريستون#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#كيابا#,
		},
		'America/Curacao' => {
			exemplarCity => q#كوراساو#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#دانمرك شافن#,
		},
		'America/Dawson' => {
			exemplarCity => q#داوسان#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#داوسن كريك#,
		},
		'America/Denver' => {
			exemplarCity => q#دنفر#,
		},
		'America/Detroit' => {
			exemplarCity => q#ديترويت#,
		},
		'America/Dominica' => {
			exemplarCity => q#دومينيكا#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ايدمونتون#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ايرونبي#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#السلفادور#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#فورت نيلسون#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#فورتاليزا#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#جلاس باي#,
		},
		'America/Godthab' => {
			exemplarCity => q#غودثاب#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#جوس باي#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#غراند ترك#,
		},
		'America/Grenada' => {
			exemplarCity => q#غرينادا#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#غوادلوب#,
		},
		'America/Guatemala' => {
			exemplarCity => q#غواتيمالا#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#غواياكويل#,
		},
		'America/Guyana' => {
			exemplarCity => q#غيانا#,
		},
		'America/Halifax' => {
			exemplarCity => q#هاليفاكس#,
		},
		'America/Havana' => {
			exemplarCity => q#هافانا#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#هيرموسيلو#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#كونكس#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#مارنجو#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#بيترسبرغ#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#مدينة تل، إنديانا#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#فيفاي#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#فينسينس#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ويناماك#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#إنديانابوليس#,
		},
		'America/Inuvik' => {
			exemplarCity => q#اينوفيك#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#اكويلت#,
		},
		'America/Jamaica' => {
			exemplarCity => q#جامايكا#,
		},
		'America/Jujuy' => {
			exemplarCity => q#جوجو#,
		},
		'America/Juneau' => {
			exemplarCity => q#جوني#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#مونتيسيلو#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#كرالنديك#,
		},
		'America/La_Paz' => {
			exemplarCity => q#لا باز#,
		},
		'America/Lima' => {
			exemplarCity => q#ليما#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#لوس انجلوس#,
		},
		'America/Louisville' => {
			exemplarCity => q#لويس فيل#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#حي الأمير السفلي#,
		},
		'America/Maceio' => {
			exemplarCity => q#ماشيو#,
		},
		'America/Managua' => {
			exemplarCity => q#ماناغوا#,
		},
		'America/Manaus' => {
			exemplarCity => q#ماناوس#,
		},
		'America/Marigot' => {
			exemplarCity => q#ماريغوت#,
		},
		'America/Martinique' => {
			exemplarCity => q#المارتينيك#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ماتاموروس#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#مازاتلان#,
		},
		'America/Mendoza' => {
			exemplarCity => q#ميندوزا#,
		},
		'America/Menominee' => {
			exemplarCity => q#مينوميني#,
		},
		'America/Merida' => {
			exemplarCity => q#ميريدا#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#ميتلاكاتلا#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#مكسيكو سيتي#,
		},
		'America/Miquelon' => {
			exemplarCity => q#مكويلون#,
		},
		'America/Moncton' => {
			exemplarCity => q#وينكتون#,
		},
		'America/Monterrey' => {
			exemplarCity => q#مونتيري#,
		},
		'America/Montevideo' => {
			exemplarCity => q#مونتفيديو#,
		},
		'America/Montserrat' => {
			exemplarCity => q#مونتسيرات#,
		},
		'America/Nassau' => {
			exemplarCity => q#ناسو#,
		},
		'America/New_York' => {
			exemplarCity => q#نيويورك#,
		},
		'America/Nipigon' => {
			exemplarCity => q#نيبيجون#,
		},
		'America/Nome' => {
			exemplarCity => q#نوم#,
		},
		'America/Noronha' => {
			exemplarCity => q#نوروناه#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#بيولا، داكوتا الشمالية#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#سنتر#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#نيو ساليم#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#أوجيناجا#,
		},
		'America/Panama' => {
			exemplarCity => q#بنما#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#بانجينتينج#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#باراماريبو#,
		},
		'America/Phoenix' => {
			exemplarCity => q#فينكس#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#بورت أو برنس#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#بورت أوف سبين#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#بورتو فيلو#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#بورتوريكو#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#بونتا أريناز#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#راني ريفر#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#رانكن انلت#,
		},
		'America/Recife' => {
			exemplarCity => q#ريسيف#,
		},
		'America/Regina' => {
			exemplarCity => q#ريجينا#,
		},
		'America/Resolute' => {
			exemplarCity => q#ريزولوت#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ريوبرانكو#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#سانتا إيزابيل#,
		},
		'America/Santarem' => {
			exemplarCity => q#سانتاريم#,
		},
		'America/Santiago' => {
			exemplarCity => q#سانتياغو#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#سانتو دومينغو#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ساو باولو#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#سكورسبيسند#,
		},
		'America/Sitka' => {
			exemplarCity => q#سيتكا#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#سانت بارتيليمي#,
		},
		'America/St_Johns' => {
			exemplarCity => q#سانت جونس#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#سانت كيتس#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#سانت لوشيا#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#سانت توماس#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#سانت فنسنت#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#سوفت كارنت#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#تيغوسيغالبا#,
		},
		'America/Thule' => {
			exemplarCity => q#ثيل#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#ثندر باي#,
		},
		'America/Tijuana' => {
			exemplarCity => q#تيخوانا#,
		},
		'America/Toronto' => {
			exemplarCity => q#تورونتو#,
		},
		'America/Tortola' => {
			exemplarCity => q#تورتولا#,
		},
		'America/Vancouver' => {
			exemplarCity => q#فانكوفر#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#وايت هورس#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#وينيبيج#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ياكوتات#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#يلونيف#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#التوقيت الصيفي المركزي لأمريكا الشمالية#,
				'generic' => q#التوقيت المركزي لأمريكا الشمالية#,
				'standard' => q#التوقيت الرسمي المركزي لأمريكا الشمالية#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#التوقيت الصيفي الشرقي لأمريكا الشمالية#,
				'generic' => q#التوقيت الشرقي لأمريكا الشمالية#,
				'standard' => q#التوقيت الرسمي الشرقي لأمريكا الشمالية#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#التوقيت الجبلي الصيفي لأمريكا الشمالية#,
				'generic' => q#التوقيت الجبلي لأمريكا الشمالية#,
				'standard' => q#التوقيت الجبلي الرسمي لأمريكا الشمالية#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#توقيت المحيط الهادي الصيفي#,
				'generic' => q#توقيت المحيط الهادي#,
				'standard' => q#توقيت المحيط الهادي الرسمي#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#التوقيت الصيفي لأنادير#,
				'generic' => q#توقيت أنادير#,
				'standard' => q#توقيت أنادير الرسمي#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#كاساي#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#دافيز#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#دي مونت دو روفيل#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#ماكواري#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ماوسون#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#ماك موردو#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#بالمير#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#روثيرا#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#سايووا#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ترول#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#فوستوك#,
		},
		'Apia' => {
			long => {
				'daylight' => q#التوقيت الصيفي لأبيا#,
				'generic' => q#توقيت آبيا#,
				'standard' => q#التوقيت الرسمي لآبيا#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#التوقيت العربي الصيفي#,
				'generic' => q#التوقيت العربي#,
				'standard' => q#التوقيت العربي الرسمي#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#لونجيربين#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#توقيت الأرجنتين الصيفي#,
				'generic' => q#توقيت الأرجنتين#,
				'standard' => q#توقيت الأرجنتين الرسمي#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#توقيت غرب الأرجنتين الصيفي#,
				'generic' => q#توقيت غرب الأرجنتين#,
				'standard' => q#توقيت غرب الأرجنتين الرسمي#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#توقيت أرمينيا الصيفي#,
				'generic' => q#توقيت أرمينيا#,
				'standard' => q#توقيت أرمينيا الرسمي#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#عدن#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ألماتي#,
		},
		'Asia/Amman' => {
			exemplarCity => q#عمّان#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#أندير#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#أكتاو#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#أكتوب#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#عشق آباد#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#أتيراو#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#بغداد#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#البحرين#,
		},
		'Asia/Baku' => {
			exemplarCity => q#باكو#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#بانكوك#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#بارناول#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#بيروت#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#بشكيك#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#بروناي#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#كالكتا#,
		},
		'Asia/Chita' => {
			exemplarCity => q#تشيتا#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#تشوبالسان#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#كولومبو#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#دمشق#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#دكا#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ديلي#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#دبي#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#دوشانبي#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#فاماغوستا#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#غزة#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#هيبرون (مدينة الخليل)#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#هونغ كونغ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#هوفد#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ايركيتسك#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#جاكرتا#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#جايابيورا#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#القدس#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#كابول#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#كامتشاتكا#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#كراتشي#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#كاتماندو#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#خانديجا#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#كراسنويارسك#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#كوالا لامبور#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#كيشينج#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#الكويت#,
		},
		'Asia/Macau' => {
			exemplarCity => q#ماكاو#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#مجادن#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#ماكسار#,
		},
		'Asia/Manila' => {
			exemplarCity => q#مانيلا#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#مسقط#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#نيقوسيا#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#نوفوكوزنتسك#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#نوفوسبيرسك#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#أومسك#,
		},
		'Asia/Oral' => {
			exemplarCity => q#أورال#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#بنوم بنه#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#بونتيانك#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#بيونغ يانغ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#قطر#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#قوستاناي#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#كيزيلوردا#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#رانغون#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#الرياض#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#مدينة هو تشي منة#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#سكالين#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#سمرقند#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#سول#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#شنغهاي#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#سنغافورة#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#سريدنكوليمسك#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#تايبيه#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#طشقند#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#تبليسي#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#طهران#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#تيمفو#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#طوكيو#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#تومسك#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#آلانباتار#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#أرومكي#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#أوست نيرا#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#فيانتيان#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#فلاديفوستك#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ياكتسك#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#يكاترنبيرج#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#يريفان#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#التوقيت الصيفي الأطلسي#,
				'generic' => q#توقيت الأطلسي#,
				'standard' => q#التوقيت الرسمي الأطلسي#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#أزورس#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#برمودا#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#كناري#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#الرأس الأخضر#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#فارو#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#ماديرا#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ريكيافيك#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#جورجيا الجنوبية#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#سانت هيلينا#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#استانلي#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#أديليد#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#برسيبان#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#بروكن هيل#,
		},
		'Australia/Currie' => {
			exemplarCity => q#كوري#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#دارون#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#أوكلا#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#هوبارت#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#ليندمان#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#لورد هاو#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#ميلبورن#,
		},
		'Australia/Perth' => {
			exemplarCity => q#برثا#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#سيدني#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#توقيت وسط أستراليا الصيفي#,
				'generic' => q#توقيت وسط أستراليا#,
				'standard' => q#توقيت وسط أستراليا الرسمي#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#توقيت غرب وسط أستراليا الصيفي#,
				'generic' => q#توقيت غرب وسط أستراليا#,
				'standard' => q#توقيت غرب وسط أستراليا الرسمي#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#توقيت شرق أستراليا الصيفي#,
				'generic' => q#توقيت شرق أستراليا#,
				'standard' => q#توقيت شرق أستراليا الرسمي#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#توقيت غرب أستراليا الصيفي#,
				'generic' => q#توقيت غرب أستراليا#,
				'standard' => q#توقيت غرب أستراليا الرسمي#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#توقيت أذربيجان الصيفي#,
				'generic' => q#توقيت أذربيجان#,
				'standard' => q#توقيت أذربيجان الرسمي#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#توقيت أزورس الصيفي#,
				'generic' => q#توقيت أزورس#,
				'standard' => q#توقيت أزورس الرسمي#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#توقيت بنغلاديش الصيفي#,
				'generic' => q#توقيت بنغلاديش#,
				'standard' => q#توقيت بنغلاديش الرسمي#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#توقيت بوتان#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#توقيت بوليفيا#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#توقيت برازيليا الصيفي#,
				'generic' => q#توقيت برازيليا#,
				'standard' => q#توقيت برازيليا الرسمي#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#توقيت بروناي#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#توقيت الرأس الأخضر الصيفي#,
				'generic' => q#توقيت الرأس الأخضر#,
				'standard' => q#توقيت الرأس الأخضر الرسمي#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#توقيت تشامورو#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#توقيت تشاتام الصيفي#,
				'generic' => q#توقيت تشاتام#,
				'standard' => q#توقيت تشاتام الرسمي#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#توقيت تشيلي الصيفي#,
				'generic' => q#توقيت تشيلي#,
				'standard' => q#توقيت تشيلي الرسمي#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#توقيت الصين الصيفي#,
				'generic' => q#توقيت الصين#,
				'standard' => q#توقيت الصين الرسمي#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#التوقيت الصيفي لشويبالسان#,
				'generic' => q#توقيت شويبالسان#,
				'standard' => q#توقيت شويبالسان الرسمي#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#توقيت جزر الكريسماس#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#توقيت جزر كوكوس#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#توقيت كولومبيا الصيفي#,
				'generic' => q#توقيت كولومبيا#,
				'standard' => q#توقيت كولومبيا الرسمي#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#توقيت جزر كوك الصيفي#,
				'generic' => q#توقيت جزر كووك#,
				'standard' => q#توقيت جزر كوك الرسمي#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#توقيت كوبا الصيفي#,
				'generic' => q#توقيت كوبا#,
				'standard' => q#توقيت كوبا الرسمي#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#توقيت دافيز#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#توقيت دي مونت دو روفيل#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#توقيت تيمور الشرقية#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#توقيت جزيرة استر الصيفي#,
				'generic' => q#توقيت جزيرة استر#,
				'standard' => q#توقيت جزيرة استر الرسمي#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#توقيت الإكوادور#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#التوقيت العالمي المنسق#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#مدينة غير معروفة#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#أمستردام#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#أندورا#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#أستراخان#,
		},
		'Europe/Athens' => {
			exemplarCity => q#أثينا#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#بلغراد#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#برلين#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#براتيسلافا#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#بروكسل#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#بوخارست#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#بودابست#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#بوسنغن#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#تشيسيناو#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#كوبنهاغن#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#دبلن#,
			long => {
				'daylight' => q#توقيت أيرلندا الرسمي#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#جبل طارق#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#غيرنزي#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#هلسنكي#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#جزيرة مان#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#إسطنبول#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#جيرسي#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#كالينجراد#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#كييف#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#كيروف#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#لشبونة#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ليوبليانا#,
		},
		'Europe/London' => {
			exemplarCity => q#لندن#,
			long => {
				'daylight' => q#توقيت بريطانيا الصيفي#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#لوكسمبورغ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#مدريد#,
		},
		'Europe/Malta' => {
			exemplarCity => q#مالطة#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ماريهامن#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#مينسك#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#موناكو#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#موسكو#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#أوسلو#,
		},
		'Europe/Paris' => {
			exemplarCity => q#باريس#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#بودغوريكا#,
		},
		'Europe/Prague' => {
			exemplarCity => q#براغ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ريغا#,
		},
		'Europe/Rome' => {
			exemplarCity => q#روما#,
		},
		'Europe/Samara' => {
			exemplarCity => q#سمراء#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#سان مارينو#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#سراييفو#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#ساراتوف#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#سيمفروبول#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#سكوبي#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#صوفيا#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#ستوكهولم#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#تالين#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#تيرانا#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#أوليانوفسك#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#أوزجرود#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#فادوز#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#الفاتيكان#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#فيينا#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#فيلنيوس#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#فولوجراد#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#وارسو#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#زغرب#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#زابوروزي#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#زيورخ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#توقيت وسط أوروبا الصيفي#,
				'generic' => q#توقيت وسط أوروبا#,
				'standard' => q#توقيت وسط أوروبا الرسمي#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#توقيت شرق أوروبا الصيفي#,
				'generic' => q#توقيت شرق أوروبا#,
				'standard' => q#توقيت شرق أوروبا الرسمي#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#التوقيت الأوروبي (أكثر شرقًا)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#توقيت غرب أوروبا الصيفي#,
				'generic' => q#توقيت غرب أوروبا#,
				'standard' => q#توقيت غرب أوروبا الرسمي#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#توقيت جزر فوكلاند الصيفي#,
				'generic' => q#توقيت جزر فوكلاند#,
				'standard' => q#توقيت جزر فوكلاند الرسمي#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#توقيت فيجي الصيفي#,
				'generic' => q#توقيت فيجي#,
				'standard' => q#توقيت فيجي الرسمي#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#توقيت غويانا الفرنسية#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#توقيت المقاطعات الفرنسية الجنوبية والأنتارتيكية#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#توقيت غرينتش#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#توقيت غلاباغوس#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#توقيت جامبير#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#توقيت جورجيا الصيفي#,
				'generic' => q#توقيت جورجيا#,
				'standard' => q#توقيت جورجيا الرسمي#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#توقيت جزر جيلبرت#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#توقيت شرق غرينلاند الصيفي#,
				'generic' => q#توقيت شرق غرينلاند#,
				'standard' => q#توقيت شرق غرينلاند الرسمي#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#توقيت غرب غرينلاند الصيفي#,
				'generic' => q#توقيت غرب غرينلاند#,
				'standard' => q#توقيت غرب غرينلاند الرسمي#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#توقيت غوام#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#توقيت الخليج#,
			},
			short => {
				'standard' => q#GST#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#توقيت غيانا#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#توقيت هاواي ألوتيان الصيفي#,
				'generic' => q#توقيت هاواي ألوتيان#,
				'standard' => q#توقيت هاواي ألوتيان الرسمي#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#توقيت هونغ كونغ الصيفي#,
				'generic' => q#توقيت هونغ كونغ#,
				'standard' => q#توقيت هونغ كونغ الرسمي#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#توقيت هوفد الصيفي#,
				'generic' => q#توقيت هوفد#,
				'standard' => q#توقيت هوفد الرسمي#,
			},
		},
		'India' => {
			long => {
				'standard' => q#توقيت الهند#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#أنتاناناريفو#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#تشاغوس#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#كريسماس#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#كوكوس#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#جزر القمر#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#كيرغويلين#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ماهي#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#المالديف#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#موريشيوس#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#مايوت#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ريونيون#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#توقيت المحيط الهندي#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#توقيت الهند الصينية#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#توقيت وسط إندونيسيا#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#توقيت شرق إندونيسيا#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#توقيت غرب إندونيسيا#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#توقيت إيران الصيفي#,
				'generic' => q#توقيت إيران#,
				'standard' => q#توقيت إيران الرسمي#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#توقيت إركوتسك الصيفي#,
				'generic' => q#توقيت إركوتسك#,
				'standard' => q#توقيت إركوتسك الرسمي#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#توقيت إسرائيل الصيفي#,
				'generic' => q#توقيت إسرائيل#,
				'standard' => q#توقيت إسرائيل الرسمي#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#توقيت اليابان الصيفي#,
				'generic' => q#توقيت اليابان#,
				'standard' => q#توقيت اليابان الرسمي#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#توقيت بيتروبافلوفسك-كامتشاتسكي الصيفي#,
				'generic' => q#توقيت كامشاتكا#,
				'standard' => q#توقيت بيتروبافلوفسك-كامتشاتسكي#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#توقيت شرق كازاخستان#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#توقيت غرب كازاخستان#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#توقيت كوريا الصيفي#,
				'generic' => q#توقيت كوريا#,
				'standard' => q#توقيت كوريا الرسمي#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#توقيت كوسرا#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#التوقيت الصيفي لكراسنويارسك#,
				'generic' => q#توقيت كراسنويارسك#,
				'standard' => q#توقيت كراسنويارسك الرسمي#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#توقيت قيرغيزستان#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#توقيت جزر لاين#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#التوقيت الصيفي للورد هاو#,
				'generic' => q#توقيت لورد هاو#,
				'standard' => q#توقيت لورد هاو الرسمي#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#توقيت ماكواري#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#توقيت ماغادان الصيفي#,
				'generic' => q#توقيت ماغادان#,
				'standard' => q#توقيت ماغادان الرسمي#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#توقيت ماليزيا#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#توقيت جزر المالديف#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#توقيت ماركيساس#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#توقيت جزر مارشال#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#توقيت موريشيوس الصيفي#,
				'generic' => q#توقيت موريشيوس#,
				'standard' => q#توقيت موريشيوس الرسمي#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#توقيت ماوسون#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#التوقيت الصيفي لشمال غرب المكسيك#,
				'generic' => q#توقيت شمال غرب المكسيك#,
				'standard' => q#التوقيت الرسمي لشمال غرب المكسيك#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#توقيت المحيط الهادي الصيفي للمكسيك#,
				'generic' => q#توقيت المحيط الهادي للمكسيك#,
				'standard' => q#توقيت المحيط الهادي الرسمي للمكسيك#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#توقيت أولان باتور الصيفي#,
				'generic' => q#توقيت أولان باتور#,
				'standard' => q#توقيت أولان باتور الرسمي#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#توقيت موسكو الصيفي#,
				'generic' => q#توقيت موسكو#,
				'standard' => q#توقيت موسكو الرسمي#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#توقيت ميانمار#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#توقيت ناورو#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#توقيت نيبال#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#توقيت كاليدونيا الجديدة الصيفي#,
				'generic' => q#توقيت كاليدونيا الجديدة#,
				'standard' => q#توقيت كاليدونيا الجديدة الرسمي#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#توقيت نيوزيلندا الصيفي#,
				'generic' => q#توقيت نيوزيلندا#,
				'standard' => q#توقيت نيوزيلندا الرسمي#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#توقيت نيوفاوندلاند الصيفي#,
				'generic' => q#توقيت نيوفاوندلاند#,
				'standard' => q#توقيت نيوفاوندلاند الرسمي#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#توقيت نيوي#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#توقيت جزيرة نورفولك الصيفي#,
				'generic' => q#توقيت جزيرة نورفولك#,
				'standard' => q#توقيت جزيرة نورفولك الرسمي#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#توقيت فرناندو دي نورونها الصيفي#,
				'generic' => q#توقيت فيرناندو دي نورونها#,
				'standard' => q#توقيت فرناندو دي نورونها الرسمي#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#توقيت جزر ماريانا الشمالية#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#توقيت نوفوسيبيرسك الصيفي#,
				'generic' => q#توقيت نوفوسيبيرسك#,
				'standard' => q#توقيت نوفوسيبيرسك الرسمي#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#توقيت أومسك الصيفي#,
				'generic' => q#توقيت أومسك#,
				'standard' => q#توقيت أومسك الرسمي#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#أبيا#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#أوكلاند#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#بوغانفيل#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#تشاثام#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#استر#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#إيفات#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#اندربيرج#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#فاكاوفو#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#فيجي#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#فونافوتي#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#جلاباجوس#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#جامبير#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#غوادالكانال#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#غوام#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#هونولولو#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#جونستون#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#كانتون#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#كيريتي ماتي#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#كوسرا#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#كواجالين#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#ماجورو#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#ماركيساس#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#ميدواي#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ناورو#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#نيوي#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#نورفولك#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#نوميا#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#باغو باغو#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#بالاو#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#بيتكيرن#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#باناب#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#بور مورسبي#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#راروتونغا#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#سايبان#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#تاهيتي#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#تاراوا#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#تونغاتابو#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#ترك#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#واك#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#واليس#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#توقيت باكستان الصيفي#,
				'generic' => q#توقيت باكستان#,
				'standard' => q#توقيت باكستان الرسمي#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#توقيت بالاو#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#توقيت بابوا غينيا الجديدة#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#توقيت باراغواي الصيفي#,
				'generic' => q#توقيت باراغواي#,
				'standard' => q#توقيت باراغواي الرسمي#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#توقيت بيرو الصيفي#,
				'generic' => q#توقيت بيرو#,
				'standard' => q#توقيت بيرو الرسمي#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#توقيت الفيلبين الصيفي#,
				'generic' => q#توقيت الفيلبين#,
				'standard' => q#توقيت الفيلبين الرسمي#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#توقيت جزر فينكس#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#توقيت سانت بيير وميكولون الصيفي#,
				'generic' => q#توقيت سانت بيير وميكولون#,
				'standard' => q#توقيت سانت بيير وميكولون الرسمي#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#توقيت بيتكيرن#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#توقيت بونابي#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#توقيت بيونغ يانغ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#توقيت روينيون#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#توقيت روثيرا#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#توقيت ساخالين الصيفي#,
				'generic' => q#توقيت ساخالين#,
				'standard' => q#توقيت ساخالين الرسمي#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#توقيت سمارا الصيفي#,
				'generic' => q#توقيت سامارا#,
				'standard' => q#توقيت سمارا#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#توقيت ساموا الصيفي#,
				'generic' => q#توقيت ساموا#,
				'standard' => q#توقيت ساموا الرسمي#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#توقيت سيشل#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#توقيت سنغافورة#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#توقيت جزر سليمان#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#توقيت جنوب جورجيا#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#توقيت سورينام#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#توقيت سايووا#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#توقيت تاهيتي#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#توقيت تايبيه الصيفي#,
				'generic' => q#توقيت تايبيه#,
				'standard' => q#توقيت تايبيه الرسمي#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#توقيت طاجكستان#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#توقيت توكيلاو#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#توقيت تونغا الصيفي#,
				'generic' => q#توقيت تونغا#,
				'standard' => q#توقيت تونغا الرسمي#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#توقيت شوك#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#توقيت تركمانستان الصيفي#,
				'generic' => q#توقيت تركمانستان#,
				'standard' => q#توقيت تركمانستان الرسمي#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#توقيت توفالو#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#توقيت أوروغواي الصيفي#,
				'generic' => q#توقيت أوروغواي#,
				'standard' => q#توقيت أوروغواي الرسمي#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#توقيت أوزبكستان الصيفي#,
				'generic' => q#توقيت أوزبكستان#,
				'standard' => q#توقيت أوزبكستان الرسمي#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#توقيت فانواتو الصيفي#,
				'generic' => q#توقيت فانواتو#,
				'standard' => q#توقيت فانواتو الرسمي#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#توقيت فنزويلا#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#توقيت فلاديفوستوك الصيفي#,
				'generic' => q#توقيت فلاديفوستوك#,
				'standard' => q#توقيت فلاديفوستوك الرسمي#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#توقيت فولغوغراد الصيفي#,
				'generic' => q#توقيت فولغوغراد#,
				'standard' => q#توقيت فولغوغراد الرسمي#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#توقيت فوستوك#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#توقيت جزيرة ويك#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#توقيت واليس و فوتونا#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#توقيت ياكوتسك الصيفي#,
				'generic' => q#توقيت ياكوتسك#,
				'standard' => q#توقيت ياكوتسك الرسمي#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#توقيت يكاترينبورغ الصيفي#,
				'generic' => q#توقيت يكاترينبورغ#,
				'standard' => q#توقيت يكاترينبورغ الرسمي#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#توقيت يوكون#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
