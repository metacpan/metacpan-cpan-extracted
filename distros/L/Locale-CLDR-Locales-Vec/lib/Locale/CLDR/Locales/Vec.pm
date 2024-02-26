=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Vec - Package for language Venetian

=cut

package Locale::CLDR::Locales::Vec;
# This file auto generated from Data\common\main\vec.xml
#	on Sun 25 Feb 10:41:40 am GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.44.0');

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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'fem-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(a),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­auna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(adó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(atrè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
			},
		},
		'fem-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(i),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­iuna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(idó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(itrè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
			},
		},
		'fem-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(o),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­ouna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(odó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(otrè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-o=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-o=),
				},
			},
		},
		'msc-no-final' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint→%%msc-with-i-nofinal→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msc-with-a-nofinal→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%msc-with-a-nofinal→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%msc-with-a-nofinal→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%msc-with-a-nofinal→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setant→%%msc-with-a-nofinal→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%msc-with-a-nofinal→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msc-with-a-nofinal→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%msc-with-o-nofinal→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­zent→%%msc-with-o-nofinal→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←­sent→%%msc-with-o-nofinal→),
				},
				'max' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←­sent→%%msc-with-o-nofinal→),
				},
			},
		},
		'msc-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(a),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­aun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­adù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­atrì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
			},
		},
		'msc-with-a-nofinal' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%msc-with-a=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(aun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­dù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­trì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-a=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-a=),
				},
			},
		},
		'msc-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(i),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­iun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­idù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­itrì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
			},
		},
		'msc-with-i-nofinal' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%msc-with-i=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(iun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­dù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­trì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-i=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-i=),
				},
			},
		},
		'msc-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(o),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(o­un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­dù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­trì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
			},
		},
		'msc-with-o-nofinal' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%msc-with-o=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(oun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­dù),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­trì),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-o=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(=%%msc-with-o=),
				},
			},
		},
		'msco-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(a),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­aun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­dó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­trè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­=%spellout-numbering=),
				},
			},
		},
		'msco-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(i),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­iun),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­dó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­trè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­=%spellout-numbering=),
				},
			},
		},
		'msco-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(o),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(o­un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­dó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­trè),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
			},
		},
		'ordinal-ezema' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzema),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unèzema),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­doèzema),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treèzema),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­cuatrèzema),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­sincuèzema),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­sièzema),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­setèzema),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otèzema),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novèzema),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
			},
		},
		'ordinal-ezema-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzema),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(a­unèzema),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­doèzema),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treèzema),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­cuatrèzema),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­sincuèzema),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­sièzema),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­setèzema),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(a­otèzema),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novèzema),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
			},
		},
		'ordinal-ezema-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzema),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(i­unèzema),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­doèzema),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treèzema),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­cuatrèzema),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­sincuèzema),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­sièzema),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­setèzema),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(i­otèzema),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novèzema),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-feminine=),
				},
			},
		},
		'ordinal-ezema-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzema),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(o­unèzema),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­doèzema),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treèzema),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­cuatrèzema),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­sincuèzema),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­sièzema),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­setèzema),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(o­otèzema),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novèzema),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(o­=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(o­=%spellout-ordinal-feminine=),
				},
			},
		},
		'ordinal-ezemo' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzemo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unèzemo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­duèzemo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treèzemo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­cuatrèzemo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­sincuèzemo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­sièzemo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­setèzemo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otèzemo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novèzemo),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
			},
		},
		'ordinal-ezemo-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzemo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(a­unèzemo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­duèzemo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treèzemo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­cuatrèzemo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­sincuèzemo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­sièzemo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­setèzemo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(a­otèzemo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novèzemo),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
			},
		},
		'ordinal-ezemo-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzemo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(i­unèzemo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­duèzemo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treèzemo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­cuatrèzemo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­sincuèzemo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­sièzemo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­setèzemo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(i­otèzemo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novèzemo),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%spellout-ordinal-masculine=),
				},
			},
		},
		'ordinal-ezemo-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(èzemo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(o­unèzemo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­duèzemo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treèzemo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­cuatrèzemo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­sincuèzemo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­sièzemo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­setèzemo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(o­otèzemo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novèzemo),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(o­=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(o­=%spellout-ordinal-masculine=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(manca →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vìrgoła →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%fem-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%fem-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%fem-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%fem-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%fem-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%fem-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%fem-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%fem-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%fem-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­zent→%%fem-with-o→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←­sent→%%fem-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(miłe[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­miła[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un miłion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miłioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miłiardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biłioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biłiardi[ →→]),
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
					rule => q(manca →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vìrgoła →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(du),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint→%%msc-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msc-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%msc-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%msc-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%msc-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setant→%%msc-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%msc-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msc-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%msc-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←zent→%%msc-with-o→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←­sent→%%msc-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(miłe[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­miła[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un miłion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miłioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miłiardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biłioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biłiardi[ →→]),
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
					rule => q(manca →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← vìrgoła →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(do),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuatro),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(sincue),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sie),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sete),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(oto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nove),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dieze),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ùndeze),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dódeze),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trèdeze),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(cuatòrdeze),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(cuìndeze),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sédeze),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(disete),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(dizdoto),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diznove),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vint→%%msco-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msco-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%msco-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%msco-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%msco-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setant→%%msco-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%msco-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msco-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%msco-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←zent→%%msco-with-o→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←←­sent→%%msco-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(miłe[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­miła[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un miłion[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miłioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miłiardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biłioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biłiardi[ →→]),
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
					rule => q(manca →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zerèzema),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(prima),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segonda),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tersa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuarta),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cuinta),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sesta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sètema),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(otava),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nona),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dèzema),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undezèzema),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodezèzema),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredezèzema),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(cuatordezèzema),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(cuindezèzema),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedezèzema),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(disetèzema),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(dizdotèzema),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diznovèzema),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-ezema-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-ezema-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%ordinal-ezema-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%ordinal-ezema-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%ordinal-ezema-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setant→%%ordinal-ezema-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%ordinal-ezema-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-ezema-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%ordinal-ezema-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­zent→%%ordinal-ezema-with-o→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­sent→%%ordinal-ezema-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(miłe­→%%ordinal-ezema→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­miłe­→%%ordinal-ezema→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­miła­→%%ordinal-ezema→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miłion­→%%ordinal-ezema→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine←miłion­→%%ordinal-ezema→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miłiard­→%%ordinal-ezema-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine←miłiard­→%%ordinal-ezema-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biłione­→%%ordinal-ezema→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine←biłion­→%%ordinal-ezema→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biłiard­→%%ordinal-ezema-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine←biłiard­→%%ordinal-ezema-with-o→),
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
					rule => q(manca →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zerèzemo),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(segondo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terso),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(cuarto),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cuinto),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sesto),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sètemo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(otavo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nono),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dèzemo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undezèzemo),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodezèzemo),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredezèzemo),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(cuatordezèzemo),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(cuindezèzemo),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedezèzemo),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(disetèzemo),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(dizdotèzemo),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diznovèzemo),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-ezemo-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-ezemo-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(cuarant→%%ordinal-ezemo-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(sincuant→%%ordinal-ezemo-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sesant→%%ordinal-ezemo-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(setant→%%ordinal-ezemo-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(otant→%%ordinal-ezemo-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-ezemo-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(sent→%%ordinal-ezemo-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­zent→%%ordinal-ezemo-with-o→),
				},
				'400' => {
					base_value => q(400),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­sent→%%ordinal-ezemo-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(miłe­→%%ordinal-ezemo→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­miłe­→%%ordinal-ezemo→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­miła­→%%ordinal-ezemo→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(miłion­→%%ordinal-ezemo→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine←miłion­→%%ordinal-ezemo→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miłiard­→%%ordinal-ezemo-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine←miłiard­→%%ordinal-ezemo-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(biłion­→%%ordinal-ezemo→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine←biłion­→%%ordinal-ezemo→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biłiard­→%%ordinal-ezemo-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine←biłiard­→%%ordinal-ezemo-with-o→),
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
				'ab' => 'abcazo',
 				'ace' => 'acineze',
 				'ada' => 'adangme',
 				'ady' => 'adighe',
 				'af' => 'afregan',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'ale' => 'aleutian',
 				'alt' => 'altài meridionale',
 				'am' => 'amàrego',
 				'an' => 'aragoneze',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'apc' => 'àrabo levantin',
 				'ar' => 'àrabo',
 				'ar_001' => 'àrabo moderno standard',
 				'arn' => 'mapudungun',
 				'arp' => 'arapào',
 				'ars' => 'àrabo najdi',
 				'as' => 'asameze',
 				'asa' => 'asu',
 				'ast' => 'asturian',
 				'atj' => 'atikamec',
 				'av' => 'avàrego',
 				'awa' => 'awadi',
 				'ay' => 'aimar',
 				'az' => 'azerbaijan',
 				'az@alt=short' => 'azero',
 				'ba' => 'bashkir',
 				'ban' => 'balineze',
 				'bas' => 'basa',
 				'be' => 'beloruso',
 				'bem' => 'benba',
 				'bez' => 'bena',
 				'bg' => 'bùlgaro',
 				'bgc' => 'harianvi',
 				'bho' => 'bojpuri',
 				'bi' => 'bizlama',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'banbara',
 				'bn' => 'bangla',
 				'bo' => 'tibetan',
 				'br' => 'brètone',
 				'brx' => 'bodo',
 				'bs' => 'boznìago',
 				'bug' => 'bugineze',
 				'byn' => 'blin',
 				'ca' => 'catalan',
 				'cay' => 'cayuga',
 				'ccp' => 'ciakma',
 				'ce' => 'cecen',
 				'ceb' => 'sebuan',
 				'cgg' => 'ciga',
 				'ch' => 'ciamoro',
 				'chk' => 'ciukeze',
 				'chm' => 'mari',
 				'cho' => 'ciòctaw',
 				'chp' => 'cìpejan',
 				'chr' => 'cerokee',
 				'chy' => 'ceyen',
 				'ckb' => 'curdo sentrale',
 				'ckb@alt=variant' => 'curdo sorani',
 				'clc' => 'cìlcotin',
 				'co' => 'corso',
 				'crg' => 'mecif',
 				'crj' => 'cree sud orientale',
 				'crk' => 'cree de le pianure',
 				'crl' => 'cree nord orientale',
 				'crm' => 'cree mose',
 				'crr' => 'algonchin de la Carolina',
 				'cs' => 'seco',
 				'csw' => 'cree de le paludi',
 				'cu' => 'zlavo de cieza',
 				'cv' => 'ciuvash',
 				'cy' => 'galeze',
 				'da' => 'daneze',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'todesco',
 				'de_AT' => 'todesco austrìago',
 				'de_CH' => 'alto todesco zvìsaro',
 				'dgr' => 'dogrib',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'baso sorabo',
 				'dua' => 'duala',
 				'dv' => 'maldivian',
 				'dyo' => 'jola foni',
 				'dz' => 'dzongka',
 				'dzg' => 'dazaga',
 				'ebu' => 'enbu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'eka' => 'ekajuk',
 				'el' => 'grego',
 				'en' => 'ingleze',
 				'en_AU' => 'ingleze australian',
 				'en_CA' => 'ingleze canadeze',
 				'en_GB' => 'ingleze britànego',
 				'en_GB@alt=short' => 'ingleze (Regno Unìo)',
 				'en_US' => 'ingleze meregan',
 				'en_US@alt=short' => 'ingleze (Stadi Unìi)',
 				'eo' => 'esperanto',
 				'es' => 'spagnolo',
 				'et' => 'estonian',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'fa' => 'persian',
 				'fa_AF' => 'dari',
 				'ff' => 'fula',
 				'fi' => 'filandeze',
 				'fil' => 'filipin',
 				'fj' => 'fijan',
 				'fo' => 'faroeze',
 				'fon' => 'fon',
 				'fr' => 'franseze',
 				'fr_CA' => 'franseze canadeze',
 				'fr_CH' => 'franseze zvìsaro',
 				'frc' => 'cadian',
 				'frr' => 'frìzone setentrionale',
 				'fur' => 'furlan',
 				'fy' => 'frìzone osidentale',
 				'ga' => 'irlandeze',
 				'gaa' => 'ga',
 				'gd' => 'gaèlego scoseze',
 				'gez' => 'geez',
 				'gil' => 'gilberteze',
 				'gl' => 'galisian',
 				'gn' => 'guaranì',
 				'gor' => 'gorontalo',
 				'gsw' => 'todesco zvìsaro',
 				'gu' => 'gujarati',
 				'guz' => 'gusi',
 				'gv' => 'maneze',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'haw' => 'hawaian',
 				'hax' => 'haida meridionale',
 				'he' => 'ebràego',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hingleze',
 				'hil' => 'hiligheno',
 				'hmn' => 'hmong',
 				'hr' => 'croà',
 				'hsb' => 'alto sorabo',
 				'ht' => 'haitian',
 				'hu' => 'ongareze',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armen',
 				'hz' => 'herero',
 				'ia' => 'interlengua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonezian',
 				'ig' => 'igbo',
 				'ii' => 'yi de Sichuan',
 				'ikt' => 'inuktitut canadeze osidentale',
 				'ilo' => 'ilocan',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'izlandeze',
 				'it' => 'italian',
 				'iu' => 'inuktitut',
 				'ja' => 'japoneze',
 				'jbo' => 'lojban',
 				'jgo' => 'ngonba',
 				'jmc' => 'machame',
 				'jv' => 'javaneze',
 				'ka' => 'jeorjan',
 				'kab' => 'cabil',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kanba',
 				'kbd' => 'cabardian',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'caoverdian',
 				'kfo' => 'koro',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'khq' => 'koyra cini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'kazako',
 				'kkj' => 'kako',
 				'kl' => 'groelandeze',
 				'kln' => 'kalenjin',
 				'km' => 'kmer',
 				'kmb' => 'kinbundu',
 				'kn' => 'canareze',
 				'ko' => 'corean',
 				'kok' => 'konkani',
 				'kpe' => 'kpele',
 				'kr' => 'canuri',
 				'krc' => 'karaciài balkar',
 				'krl' => 'carelian',
 				'kru' => 'kuruk',
 				'ks' => 'cashmiri',
 				'ksb' => 'shanbala',
 				'ksf' => 'bafia',
 				'ksh' => 'colognian',
 				'ku' => 'curdo',
 				'kum' => 'kumyk',
 				'kv' => 'komi',
 				'kw' => 'còrnego',
 				'kwk' => 'Kwakwala',
 				'ky' => 'kirghizo',
 				'la' => 'latin',
 				'lad' => 'ladin',
 				'lag' => 'langi',
 				'lb' => 'lusenburgheze',
 				'lez' => 'lezghian',
 				'lg' => 'ganda',
 				'li' => 'linburgheze',
 				'lij' => 'lìguro',
 				'lil' => 'liluet',
 				'lkt' => 'lacota',
 				'lmo' => 'lonbardo',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lou' => 'crèolo de la Luiziana',
 				'loz' => 'lozi',
 				'lrc' => 'luri setentrionale',
 				'lsm' => 'samia',
 				'lt' => 'lituan',
 				'lu' => 'luba katanga',
 				'lua' => 'luba lulua',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luja',
 				'lv' => 'lètone',
 				'mad' => 'madureze',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masài',
 				'mdf' => 'moksha',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'maurisian',
 				'mg' => 'malgaso',
 				'mgh' => 'makùa',
 				'mgo' => 'meta',
 				'mh' => 'marshaleze',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'masèdone',
 				'ml' => 'malayàlam',
 				'mn' => 'móngolo',
 				'mni' => 'manipur',
 				'moe' => 'inu aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mosi',
 				'mr' => 'marati',
 				'ms' => 'maleze',
 				'mt' => 'malteze',
 				'mua' => 'mundang',
 				'mul' => 'multilengua',
 				'mus' => 'crek',
 				'mwl' => 'mirandeze',
 				'my' => 'birman',
 				'myv' => 'erzyen',
 				'mzn' => 'mazandarani',
 				'na' => 'nauruan',
 				'nap' => 'napoletan',
 				'naq' => 'nama',
 				'nb' => 'norvejeze bokmal',
 				'nd' => 'ndebele de’l nord',
 				'nds' => 'baso todesco',
 				'nds_NL' => 'sàsone baso',
 				'ne' => 'nepaleze',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niuean',
 				'nl' => 'olandeze',
 				'nl_BE' => 'fiamingo',
 				'nmg' => 'kwazio',
 				'nn' => 'norvejeze nynorsk',
 				'nnh' => 'ngienbon',
 				'no' => 'norvejeze',
 				'nog' => 'nogài',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele de’l sud',
 				'nso' => 'soto setentrionale',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'ny' => 'chewa',
 				'nyn' => 'nyankole',
 				'oc' => 'ositan',
 				'ojb' => 'ojibwa nord osidentale',
 				'ojc' => 'ojibwa sentrale',
 				'ojs' => 'oji cree',
 				'ojw' => 'ojibwa osidentale',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'orìa',
 				'os' => 'osètego',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pam' => 'panpanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauan',
 				'pcm' => 'pidgin nijerian',
 				'pis' => 'pijin',
 				'pl' => 'polaco',
 				'pqm' => 'malesita pasamacuody',
 				'prg' => 'prusian',
 				'ps' => 'pashto',
 				'pt' => 'portogheze',
 				'pt_BR' => 'portogheze braziłian',
 				'pt_PT' => 'portogheze europèo',
 				'qu' => 'cuechua',
 				'raj' => 'rajastani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongan',
 				'rhg' => 'roinga',
 				'rif' => 'rifegno',
 				'rm' => 'romancio',
 				'rn' => 'rundi',
 				'ro' => 'romen',
 				'ro_MD' => 'moldavo',
 				'rof' => 'ronbo',
 				'ru' => 'ruso',
 				'rup' => 'aromen',
 				'rw' => 'kiniarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sànscrito',
 				'sad' => 'sandawe',
 				'sah' => 'yakuto',
 				'saq' => 'sanburu',
 				'sat' => 'santali',
 				'sba' => 'nganbay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'sisilian',
 				'sco' => 'scoseze',
 				'sd' => 'sindi',
 				'se' => 'sami setentrionale',
 				'seh' => 'sena',
 				'ses' => 'koyraboro seni',
 				'sg' => 'sango',
 				'shi' => 'tashelit',
 				'shn' => 'shan',
 				'si' => 'singaleze',
 				'sk' => 'zlovaco',
 				'sl' => 'zloven',
 				'slh' => 'lushootseed meridionale',
 				'sm' => 'samoan',
 				'smn' => 'sami inarian',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninké',
 				'so' => 'sòmalo',
 				'sq' => 'albaneze',
 				'sr' => 'serbo',
 				'srn' => 'sranan tongo',
 				'ss' => 'zwati',
 				'st' => 'soto meridionale',
 				'str' => 'salish streto',
 				'su' => 'sundaneze',
 				'suk' => 'sukuma',
 				'sv' => 'zvedeze',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili de’l Congo',
 				'swb' => 'comorian',
 				'syr' => 'sirìago',
 				'ta' => 'tamil',
 				'tce' => 'tutchone meridionale',
 				'te' => 'telugo',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'tet' => 'tétum',
 				'tg' => 'tàjego',
 				'tgx' => 'tagish',
 				'th' => 'tailandeze',
 				'tht' => 'taltan',
 				'ti' => 'tigrigna',
 				'tig' => 'tigré',
 				'tk' => 'turcoman',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tn' => 'tswana',
 				'to' => 'tongan',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tt' => 'tàtaro',
 				'ttm' => 'tutchone setentrionale',
 				'tum' => 'tunbuka',
 				'tvl' => 'tuvaluan',
 				'twq' => 'tasawac',
 				'ty' => 'taitian',
 				'tyv' => 'tuvinian',
 				'tzm' => 'tamazigh de l’Atlante sentrale',
 				'udm' => 'udmurto',
 				'ug' => 'uigur',
 				'uk' => 'ucrain',
 				'umb' => 'unbundu',
 				'und' => 'lengua desconoscùa',
 				'ur' => 'urdu',
 				'uz' => 'uzbego',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'veneto',
 				'vi' => 'vietnameze',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'valon',
 				'wae' => 'walser',
 				'wal' => 'wolaita',
 				'war' => 'waray',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'kalmik',
 				'xh' => 'xhosa',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yenba',
 				'yi' => 'yidish',
 				'yo' => 'yoruba',
 				'yrl' => 'nengatu',
 				'yue' => 'cantoneze',
 				'zgh' => 'tamazight standard de’l Maroco',
 				'zh' => 'sineze',
 				'zh@alt=menu' => 'sineze mandarin',
 				'zh_Hans@alt=long' => 'mandarin (senpio)',
 				'zh_Hant@alt=long' => 'mandarin (tradisionale)',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'gnaun contegnùo lenguìstego',
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
 			'Aghb' => 'albaneze caucàzego',
 			'Ahom' => 'ahom',
 			'Arab' => 'àrabo',
 			'Aran' => 'nastaliq',
 			'Armi' => 'amàrego inperiale',
 			'Armn' => 'armen',
 			'Avst' => 'avèstego',
 			'Bali' => 'balineze',
 			'Bamu' => 'bamun',
 			'Bass' => 'vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengaleze',
 			'Bhks' => 'baiksuki',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'bugineze',
 			'Buhd' => 'buhid',
 			'Cakm' => 'ciakma',
 			'Cans' => 'silabaro aborìjeno canadeze unifegà',
 			'Cari' => 'cario',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Chrs' => 'corazmian',
 			'Copt' => 'copto',
 			'Cpmn' => 'sipro minòego',
 			'Cprt' => 'siprioto',
 			'Cyrl' => 'sirìlego',
 			'Deva' => 'devanàgari',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogri',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'duployan stenografà',
 			'Egyp' => 'jeroglìfeghi ejisiani',
 			'Elba' => 'elbasan',
 			'Elym' => 'elimàego',
 			'Ethi' => 'etiòpego',
 			'Geor' => 'jeorjan',
 			'Glag' => 'glagolìtego',
 			'Gong' => 'gunjala',
 			'Gonm' => 'gondi masaram',
 			'Goth' => 'gòtego',
 			'Gran' => 'granta',
 			'Grek' => 'grego',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmuki',
 			'Hanb' => 'han co bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'senpio',
 			'Hans@alt=stand-alone' => 'han senpio',
 			'Hant' => 'tradisionale',
 			'Hant@alt=stand-alone' => 'han tradisionale',
 			'Hatr' => 'hatran',
 			'Hebr' => 'ebràego',
 			'Hira' => 'hiragana',
 			'Hluw' => 'jeroglìfeghi anatòleghi',
 			'Hmng' => 'pahaw hmong',
 			'Hmnp' => 'niakeng puachu hmong',
 			'Hrkt' => 'silabari japonezi',
 			'Hung' => 'ongareze antigo',
 			'Ital' => 'itàlego antigo',
 			'Jamo' => 'jamo',
 			'Java' => 'javaneze',
 			'Jpan' => 'japoneze',
 			'Kali' => 'kayah li',
 			'Kana' => 'katanaka',
 			'Kawi' => 'kawi',
 			'Khar' => 'karosti',
 			'Khmr' => 'kmer',
 			'Khoj' => 'kojiki',
 			'Kits' => 'kitan celo',
 			'Knda' => 'kanada',
 			'Kore' => 'corean',
 			'Kthi' => 'kaiti',
 			'Lana' => 'lana',
 			'Laoo' => 'lao',
 			'Latn' => 'latin',
 			'Lepc' => 'lepcha',
 			'Limb' => 'linbu',
 			'Lina' => 'linear A',
 			'Linb' => 'linear B',
 			'Lisu' => 'fraser',
 			'Lyci' => 'lisio',
 			'Lydi' => 'lidio',
 			'Mahj' => 'mahajan',
 			'Maka' => 'makasar',
 			'Mand' => 'mandàego',
 			'Mani' => 'manighèo',
 			'Marc' => 'marchen',
 			'Medf' => 'medefaidrin',
 			'Mend' => 'mende',
 			'Merc' => 'meroìtego corsivo',
 			'Mero' => 'meroìtego',
 			'Mlym' => 'malayàlam',
 			'Modi' => 'modi',
 			'Mong' => 'móngolo',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitéi',
 			'Mult' => 'multani',
 			'Mymr' => 'birman',
 			'Nagm' => 'nag mundari',
 			'Nand' => 'nandinagari',
 			'Narb' => 'àrabo antigo de’l nord',
 			'Nbat' => 'nabatèo',
 			'Newa' => 'newa',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nushu',
 			'Ogam' => 'ogam',
 			'Olck' => 'ol ciki',
 			'Orkh' => 'orcon',
 			'Orya' => 'orija',
 			'Osge' => 'osage',
 			'Osma' => 'ozmania',
 			'Ougr' => 'uigur antigo',
 			'Palm' => 'palmiren',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'pèrmego antigo',
 			'Phag' => 'pagspa',
 			'Phli' => 'palavo de le iscrision',
 			'Phlp' => 'palavo saltero',
 			'Phnx' => 'feniso',
 			'Plrd' => 'fonètego de Pollard',
 			'Prti' => 'parto de le iscrision',
 			'Qaag' => 'zovghi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Runr' => 'rùnego',
 			'Samr' => 'samaritan',
 			'Sarb' => 'àrabo antigo de’l sud',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'scritura de i segni',
 			'Shaw' => 'shavian',
 			'Shrd' => 'sharada',
 			'Sidd' => 'sidam',
 			'Sind' => 'kudawadi',
 			'Sinh' => 'singaleze',
 			'Sogd' => 'sogdian',
 			'Sogo' => 'sogdian antigo',
 			'Sora' => 'sora sonpeng',
 			'Soyo' => 'soyonbo',
 			'Sund' => 'sundaneze',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'sirìago',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lu senpio',
 			'Taml' => 'tamil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugo',
 			'Tfng' => 'tifinag',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thana',
 			'Thai' => 'tailandeze',
 			'Tibt' => 'tibetan',
 			'Tirh' => 'tiruta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'toto',
 			'Ugar' => 'ugarìtego',
 			'Vaii' => 'vai',
 			'Vith' => 'beita kukju',
 			'Wara' => 'warang siti',
 			'Wcho' => 'wancho',
 			'Xpeo' => 'persian antigo',
 			'Xsux' => 'cugniforme sumero acadian',
 			'Yezi' => 'yezidi',
 			'Yiii' => 'yi',
 			'Zanb' => 'zanabazar cuadrà',
 			'Zinh' => 'redità',
 			'Zmth' => 'notasion matemàtega',
 			'Zsye' => 'emoji',
 			'Zsym' => 'sìnboli',
 			'Zxxx' => 'miga scrito',
 			'Zyyy' => 'comun',
 			'Zzzz' => 'desconosùo',

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
			'001' => 'mondo',
 			'002' => 'Àfrega',
 			'003' => 'Mèrega de’l nord',
 			'005' => 'Mèrega de’l sud',
 			'009' => 'Oseania',
 			'011' => 'Àfrega osidentale',
 			'013' => 'Mèrega sentrale',
 			'014' => 'Àfrega orientale',
 			'015' => 'Àfrega setentrionale',
 			'017' => 'Àfrega sentrale',
 			'018' => 'Àfrega meridionale',
 			'019' => 'Mèreghe',
 			'021' => 'Mèrega setentrionale',
 			'029' => 'Caràibi',
 			'030' => 'Azia orientale',
 			'034' => 'Azia meridionale',
 			'035' => 'Azia de’l sudest',
 			'039' => 'Europa meridionale',
 			'053' => 'Australazia',
 			'054' => 'Melanezia',
 			'057' => 'Rejon microneziana',
 			'061' => 'Polinezia',
 			'142' => 'Azia',
 			'143' => 'Azia sentrale',
 			'145' => 'Azia osidentale',
 			'150' => 'Europa',
 			'151' => 'Europa orientale',
 			'154' => 'Europa setentrionale',
 			'155' => 'Europa osidentale',
 			'202' => 'Àfrega subsahariana',
 			'419' => 'Mèrega Latina',
 			'AC' => 'Ìzola Asension',
 			'AD' => 'Andora',
 			'AE' => 'Emirài Àrabi Unìi',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antàrtide',
 			'AR' => 'Arjentina',
 			'AS' => 'Samòa meregane',
 			'AT' => 'Àustria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Ìzole Aland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Boznia e Erzegòvina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Beljo',
 			'BF' => 'Burkina Fazo',
 			'BG' => 'Bulgarìa',
 			'BH' => 'Barein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'S. Bartolomèo',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Paezi Basi caraìbeghi',
 			'BR' => 'Brazile',
 			'BS' => 'Bahamas',
 			'BT' => 'Butan',
 			'BV' => 'Ìzola Buvet',
 			'BW' => 'Botzwana',
 			'BY' => 'Belorusia',
 			'BZ' => 'Belize',
 			'CA' => 'Cànada',
 			'CC' => 'Ìzole Cocos (Keeling)',
 			'CD' => 'Repùblega Democràtega de’l Congo',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'Repùblega Sentrafregana',
 			'CG' => 'Repùblega de’l Congo',
 			'CG@alt=variant' => 'Congo (RC)',
 			'CH' => 'Zvìsara',
 			'CI' => 'Costa d’Avorio',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Ìzole Cook',
 			'CL' => 'Cile',
 			'CM' => 'Càmerun',
 			'CN' => 'Sina',
 			'CO' => 'Colonbia',
 			'CP' => 'Ìzola de Clipperton',
 			'CQ' => 'Sarc',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cao Verdo',
 			'CW' => 'Curaçao',
 			'CX' => 'Ìzola de Nadale',
 			'CY' => 'Sipro',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Repùblega Ceca',
 			'DE' => 'Jermania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Danimarca',
 			'DM' => 'Doménega',
 			'DO' => 'Repùblega Domenegana',
 			'DZ' => 'Aljerìa',
 			'EA' => 'Ceuta e Melila',
 			'EC' => 'Ècuador',
 			'EE' => 'Estonia',
 			'EG' => 'Ejito',
 			'EH' => 'Sahara Osidentale',
 			'ER' => 'Eritrèa',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Union europèa',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlanda',
 			'FJ' => 'Fiji',
 			'FK' => 'Ìzole Malvine',
 			'FK@alt=variant' => 'Ìzole Falkland',
 			'FM' => 'Micronezia',
 			'FO' => 'Ìzole Fàroe',
 			'FR' => 'Fransa',
 			'GA' => 'Gabon',
 			'GB' => 'Regno Unìo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Granada',
 			'GE' => 'Jeorja',
 			'GF' => 'Guyana franseze',
 			'GG' => 'Guernsey',
 			'GH' => 'Gana',
 			'GI' => 'Gibiltera',
 			'GL' => 'Groenlanda',
 			'GM' => 'Ganbia',
 			'GN' => 'Guinèa',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinèa Ecuatoriale',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia de’l sud e Sandwich de’l sud',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinèa Bisào',
 			'GY' => 'Guyana',
 			'HK' => 'RAS de Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Ìzole Heard e McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croasia',
 			'HT' => 'Haiti',
 			'HU' => 'Ongarìa',
 			'IC' => 'Ìzole Canarie',
 			'ID' => 'Indonezia',
 			'IE' => 'Irlanda',
 			'IL' => 'Izraele',
 			'IM' => 'Ìzola de Man',
 			'IN' => 'India',
 			'IO' => 'Teritorio britànego de l’Osèano Indian',
 			'IO@alt=chagos' => 'Arsipèlago Ciagos',
 			'IQ' => 'Irac',
 			'IR' => 'Iran',
 			'IS' => 'Izlanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamàega',
 			'JO' => 'Jordania',
 			'JP' => 'Japon',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
 			'KH' => 'Canboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Ìzole Comore',
 			'KN' => 'S. Cristofer e Nevis',
 			'KP' => 'Corèa de’l nord',
 			'KR' => 'Corèa de’l sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Ìzole Caiman',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laos',
 			'LB' => 'Lìbano',
 			'LC' => 'S. Lusìa',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lezoto',
 			'LT' => 'Lituania',
 			'LU' => 'Lusenburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Maroco',
 			'MC' => 'Mònaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'S. Martin (Fransa)',
 			'MG' => 'Madagascar',
 			'MH' => 'Ìzole Marshall',
 			'MK' => 'Masedonia de’l nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'RAS de Macào',
 			'MO@alt=short' => 'Macào',
 			'MP' => 'Ìzole Mariane setentrionali',
 			'MQ' => 'Martiniga',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserat',
 			'MT' => 'Malta',
 			'MU' => 'Ìzole Maurisio',
 			'MV' => 'Maldive',
 			'MW' => 'Malawi',
 			'MX' => 'Mèsego',
 			'MY' => 'Malezia',
 			'MZ' => 'Mozanbigo',
 			'NA' => 'Namibia',
 			'NC' => 'Nova Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Ìzola Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paezi Basi',
 			'NO' => 'Norveja',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nova Zelanda',
 			'NZ@alt=variant' => 'Aotearóa (Nova Zelanda)',
 			'OM' => 'Oman',
 			'PA' => 'Pànama',
 			'PE' => 'Perù',
 			'PF' => 'Polinezia franseze',
 			'PG' => 'Papua Nova Guinèa',
 			'PH' => 'Filipine',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'S. Piero e Michelon',
 			'PN' => 'Ìzole Pitcairn',
 			'PR' => 'Portorico',
 			'PS' => 'Teritori palestinezi',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portogalo',
 			'PW' => 'Palàu',
 			'PY' => 'Paraguài',
 			'QA' => 'Catar',
 			'QO' => 'Oseania perifèrega',
 			'RE' => 'Ìzola Reunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudìa',
 			'SB' => 'Ìzole Salomon',
 			'SC' => 'Ìzole Seisel',
 			'SD' => 'Sudan',
 			'SE' => 'Zvesia',
 			'SG' => 'Singapore',
 			'SH' => 'Ìzola S. Èlena',
 			'SI' => 'Zlovenia',
 			'SJ' => 'Zvàlbard e Jan Mayen',
 			'SK' => 'Zlovachia',
 			'SL' => 'Siera Leon',
 			'SM' => 'San Marin',
 			'SN' => 'Sènegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sud Sudan',
 			'ST' => 'S. Tomazo e Prìnsipe',
 			'SV' => 'El Salvador',
 			'SX' => 'S. Martin (Paezi Basi)',
 			'SY' => 'Siria',
 			'SZ' => 'Esuatini',
 			'SZ@alt=variant' => 'Swazilanda',
 			'TA' => 'Tristan de Cugna',
 			'TC' => 'Turks e Caicos',
 			'TD' => 'Ciad',
 			'TF' => 'Teritori fransezi de’l sud',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelàu',
 			'TL' => 'Timor Est',
 			'TL@alt=variant' => 'Timor Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunizìa',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidà e Tabaco',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ìzołe perifèreghe meregane',
 			'UN' => 'Nasion Unìe',
 			'US' => 'Stadi Unìi',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguài',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vategan',
 			'VC' => 'S. Vincenso e Granadine',
 			'VE' => 'Venesuela',
 			'VG' => 'Ìzole Vèrjini britàneghe',
 			'VI' => 'Ìzole Vèrjini meregane',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samòa',
 			'XA' => 'Pseudo asenti',
 			'XB' => 'Pseudo bidi',
 			'XK' => 'Kòsovo',
 			'YE' => 'Yemen',
 			'YT' => 'Ìzole Maiote',
 			'ZA' => 'Sudàfrega',
 			'ZM' => 'Zanbia',
 			'ZW' => 'Zinbawe',
 			'ZZ' => 'Rejon desconosùa',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1996' => 'ortografìa todesca de’l 1996',
 			'1606NICT' => 'franseze mezo tardivo fin el 1606',
 			'1694ACAD' => 'franseze moderno bonorivo',
 			'1959ACAD' => 'acadèmego',
 			'ALALC97' => 'romanizasion ALA-LC, varsion 1997',
 			'ALUKU' => 'dialeto aluku',
 			'BALANKA' => 'dialeto balanka de l’Anii',
 			'BARLA' => 'dialeto barlavento de’l caoverdian',
 			'BOHORIC' => 'alfabeto bohoric',
 			'BOONT' => 'bontling',
 			'DAJNKO' => 'alfabeto Dajnko',
 			'EMODENG' => 'ingleze moderno bonorivo',
 			'FONIPA' => 'alfabeto fonètego internasionale IPA',
 			'HEPBURN' => 'romanizasion Hepburn',
 			'KKCOR' => 'ortografìa comun',
 			'NJIVA' => 'dialeto Gniva',
 			'POSIX' => 'informàtega',
 			'RIGIK' => 'volapuk clàsego',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'cf' => 'Formà moneda',
 			'currency' => 'Moneda',
 			'hc' => 'Sistema ore (12/24)',
 			'lb' => 'Stile de cao de linea',
 			'ms' => 'Sistema de mezurasion',
 			'numbers' => 'Nùmari',

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
 				'gregorian' => q{calendaro gregorian},
 				'iso8601' => q{calendaro ISO-8601},
 			},
 			'cf' => {
 				'account' => q{Formà moneda contàbile},
 				'standard' => q{Formà moneda standard},
 			},
 			'collation' => {
 				'search' => q{Reserca jenèrega},
 				'standard' => q{òrdane standard},
 			},
 			'hc' => {
 				'h11' => q{Sistema a 12 ore (0–11)},
 				'h12' => q{Sistema a 12 ore (1–12)},
 				'h23' => q{Sistema a 24 ore (0–23)},
 				'h24' => q{Sistema a 12 ore (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Cao de linea opsionale},
 				'normal' => q{Cao de linea normale},
 				'strict' => q{Cao de linea forsà},
 			},
 			'ms' => {
 				'metric' => q{Sistema mètrego},
 				'uksystem' => q{Sistema inperiale},
 				'ussystem' => q{Sistema meregan},
 			},
 			'numbers' => {
 				'arab' => q{Nùmari in indo àrabo},
 				'arabext' => q{Nùmari estendesti in indo àrabo},
 				'armn' => q{Nùmari in armen},
 				'armnlow' => q{Nùmari minùscoli in armen},
 				'beng' => q{Nùmari in bengaleze},
 				'cakm' => q{Nùmari in ciakma},
 				'deva' => q{Nùmari in devanàgari},
 				'ethi' => q{Nùmari in etiòpego},
 				'fullwide' => q{Nùmari a larghesa piena},
 				'geor' => q{Nùmari in jeorjan},
 				'grek' => q{Nùmari in grego},
 				'greklow' => q{Nùmari minùscoli in grego},
 				'gujr' => q{Nùmari in gujarati},
 				'guru' => q{Nùmari in gurmuki},
 				'hanidec' => q{Nùmari desimali in sineze},
 				'hans' => q{Nùmari in sineze senpio},
 				'hansfin' => q{Nùmari finansiari in sineze senpio},
 				'hant' => q{Nùmari in sineze tradisionale},
 				'hantfin' => q{Nùmari finansiari in sineze tradisionale},
 				'hebr' => q{Nùmari in ebràego},
 				'java' => q{Nùmari in javaneze},
 				'jpan' => q{Nùmari in japoneze},
 				'jpanfin' => q{Nùmari finansiari in japoneze},
 				'khmr' => q{Nùmari in kmer},
 				'knda' => q{Nùmari in kanada},
 				'laoo' => q{Nùmari in lao},
 				'latn' => q{Nùmari osidentali},
 				'mlym' => q{Nùmari in malayàlam},
 				'mtei' => q{Nùmari in meitéi},
 				'mymr' => q{Nùmari in birman},
 				'olck' => q{Nùmari in ol ciki},
 				'orya' => q{Nùmari in orija},
 				'roman' => q{Nùmari romani},
 				'romanlow' => q{Nùmari minùscoli romani},
 				'taml' => q{Nùmari in tamil tradisionale},
 				'tamldec' => q{Nùmari in tamil},
 				'telu' => q{Nùmari in telugo},
 				'thai' => q{Nùmari in tailandeze},
 				'tibt' => q{Nùmari tibetani},
 				'vaii' => q{Nùmari in vai},
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
			'metric' => q{mètrego},
 			'UK' => q{britànego},
 			'US' => q{meregan},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lengua: {0}',
 			'script' => 'Scritura: {0}',
 			'region' => 'Rejon: {0}',

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
			auxiliary => qr{[ªá ćç ḑ ʣ ǵ í k ł º q ş ţ ʦ ú w y {z̧}]},
			main => qr{[aà b c d eéè f g h iì j l m n oóò p r s t uù v x z]},
			punctuation => qr{[\- ‐‑ ‒ – — ― ⁓ , ; \: ! ? . … · '‘’ "“” « » ( ) \[ \] \{ \} 〈 〉 @ * / \\ \& # + = ⁄]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ponto cardinale),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ponto cardinale),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ovest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} est),
						'north' => q({0} nord),
						'south' => q({0} sud),
						'west' => q({0} ovest),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} par {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} par {1}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ponto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ponto),
					},
				},
			} }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} e {1}),
				2 => q({0} e {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
		},
	} }
);

has 'number_currency_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'pattern' => {
				'default' => {
					'standard' => {
						'positive' => '#,##0.00 ¤',
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
			display_name => {
				'currency' => q(dirham de i Emirài Àrabi Unìi),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afgan afghanistan),
				'one' => q(afgan afghanistan),
				'other' => q(afgani afghanistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albaneze),
				'one' => q(lek albaneze),
				'other' => q(lek albanezi),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armen),
				'one' => q(dram armen),
				'other' => q(dram armeni),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(fiorin antilan),
				'one' => q(fiorin antilan),
				'other' => q(fiorini antilani),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angoleze),
				'one' => q(kwanza angoleze),
				'other' => q(kwanza angolezi),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(pezos arjentin),
				'one' => q(pezos arjentin),
				'other' => q(pezos arjentini),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(dòlaro australian),
				'one' => q(dòlaro australian),
				'other' => q(dòlari australiani),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(fiorin arubaneze),
				'one' => q(fiorin arubaneze),
				'other' => q(fiorini arubanezi),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azerbaijan),
				'one' => q(manat azerbaijan),
				'other' => q(manat azerbaijani),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marco convertìbile de la Boznia e Erzegòvina),
				'one' => q(marco convertìbile de la Boznia e Erzegòvina),
				'other' => q(marchi convertìbili de la Boznia e Erzegòvina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dòlaro barbadeze),
				'one' => q(dòlaro barbadeze),
				'other' => q(dòlari barbadezi),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladeze),
				'one' => q(taka bangladeze),
				'other' => q(taka bangladezi),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bùlgaro),
				'one' => q(lev bùlgaro),
				'other' => q(lev bùlgari),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dìnaro bareineze),
				'one' => q(dìnaro bareineze),
				'other' => q(dìnari bareinezi),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franco burundeze),
				'one' => q(franco burundeze),
				'other' => q(franchi burundezi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dòlaro bermudeze),
				'one' => q(dòlaro bermudeze),
				'other' => q(dòlari bermudezi),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dòlaro bruneian),
				'one' => q(dòlaro bruneian),
				'other' => q(dòlari bruneiani),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivian),
				'one' => q(bolivian),
				'other' => q(boliviani),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real brazilian),
				'one' => q(real brazilian),
				'other' => q(real braziliani),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dòlaro bahameze),
				'one' => q(dòlaro bahameze),
				'other' => q(dòlari bahamezi),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(gultrum butaneze),
				'one' => q(gultrum butaneze),
				'other' => q(gultrum butanezi),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula botzwaneze),
				'one' => q(pula botzwaneze),
				'other' => q(pula botzwanezi),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(rublo beloruso),
				'one' => q(rublo beloruso),
				'other' => q(rubli belorusi),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dòlaro belizeneze),
				'one' => q(dòlaro belizeneze),
				'other' => q(dòlari belizenezi),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(dòlaro canadeze),
				'one' => q(dòlaro canadeze),
				'other' => q(dòlari canadezi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franco congoleze),
				'one' => q(franco congoleze),
				'other' => q(franchi congolezi),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franco zvìsaro),
				'one' => q(franco zvìsaro),
				'other' => q(franchi zvìsari),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(pezos cilen),
				'one' => q(pezos cilen),
				'other' => q(pezos cileni),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan estrateritoriale),
				'one' => q(yuan estrateritoriale),
				'other' => q(yuan estrateritoriali),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(yuan sineze),
				'one' => q(yuan sineze),
				'other' => q(yuan sinezi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(pezos colonbian),
				'one' => q(pezos colonbian),
				'other' => q(pezos colonbiani),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colonbo costarican),
				'one' => q(colonbo costarican),
				'other' => q(colonbi costaricani),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(pezos cuban convertìbile),
				'one' => q(pezos cuban convertìbile),
				'other' => q(pezos cubani convertìbili),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(pezos cuban),
				'one' => q(pezos cuban),
				'other' => q(pezos cubani),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(scudo caoverdian),
				'one' => q(scudo caoverdian),
				'other' => q(scudi caoverdiani),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona ceca),
				'one' => q(corona ceca),
				'other' => q(corone ceche),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franco jibutian),
				'one' => q(franco jibutian),
				'other' => q(franchi jibutiani),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona daneze),
				'one' => q(corona daneze),
				'other' => q(corone danezi),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(pezos domenegan),
				'one' => q(pezos domenegan),
				'other' => q(pezos domenegani),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dìnaro aljerin),
				'one' => q(dìnaro aljerin),
				'other' => q(dìnari aljerini),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(sterlina ejisiana),
				'one' => q(sterlina ejisiana),
				'other' => q(sterline ejisiane),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritrèo),
				'one' => q(nakfa eritrèo),
				'other' => q(nakfa eritrèi),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(bir etiòpego),
				'one' => q(bir etiòpego),
				'other' => q(bir etiòpeghi),
			},
		},
		'EUR' => {
			symbol => 'EUR',
			display_name => {
				'currency' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dòlaro fijian),
				'one' => q(dòlaro fijian),
				'other' => q(dòlari fijiani),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(sterlina malvineze),
				'one' => q(sterlina malvineze),
				'other' => q(sterline malvinezi),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(sterlina ingleze),
				'one' => q(sterlina ingleze),
				'other' => q(sterline inglezi),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari jeorjan),
				'one' => q(lari jeorjan),
				'other' => q(lari jeorjani),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ganeze),
				'one' => q(cedi ganeze),
				'other' => q(cedi ganezi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(sterlina gibilterana),
				'one' => q(sterlina gibilterana),
				'other' => q(sterline gibilterane),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalaso ganbian),
				'one' => q(dalaso ganbian),
				'other' => q(dalasi ganbiani),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franco guinean),
				'one' => q(franco guinean),
				'other' => q(franchi guineani),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemaleze),
				'one' => q(quetzal guatemaleze),
				'other' => q(quetzal guatemalezi),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dòlaro guyaneze),
				'one' => q(dòlaro guyaneze),
				'other' => q(dòlari guyanezi),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dòlaro hongkongeze),
				'one' => q(dòlaro hongkongeze),
				'other' => q(dòlari hongkongezi),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lenpira hondureze),
				'one' => q(lenpira hondureze),
				'other' => q(lenpira hondurezi),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kune croate),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gordo haitian),
				'one' => q(gordo haitian),
				'other' => q(gordi haitiani),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fiorin ongareze),
				'one' => q(fiorin ongareze),
				'other' => q(fiorini ongarezi),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupìa indoneziana),
				'one' => q(rupìa indoneziana),
				'other' => q(rupìe indoneziane),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(novo siglo izraelian),
				'one' => q(novo siglo izraelian),
				'other' => q(novi sigli izraeliani),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupìa indiana),
				'one' => q(rupìa indiana),
				'other' => q(rupìe indiane),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dìnaro irachen),
				'one' => q(dìnaro irachen),
				'other' => q(dìnari iracheni),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iranian),
				'one' => q(rial iranian),
				'other' => q(rial iraniani),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona izlandeze),
				'one' => q(corona izlandeze),
				'other' => q(corone izlandezi),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dòlaro jamaegan),
				'one' => q(dòlaro jamaegan),
				'other' => q(dòlari jamaegani),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dìnaro jordanian),
				'one' => q(dìnaro jordanian),
				'other' => q(dìnari jordaniani),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen japoneze),
				'one' => q(yen japoneze),
				'other' => q(yen japonezi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(selin kenian),
				'one' => q(selin kenian),
				'other' => q(selini keniani),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghizistan),
				'one' => q(som kirghizistan),
				'other' => q(som kirghizistani),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(rial canbojan),
				'one' => q(rial canbojan),
				'other' => q(rial canbojani),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franco comorian),
				'one' => q(franco comorian),
				'other' => q(franchi comoriani),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nordcorean),
				'one' => q(won nordcorean),
				'other' => q(won nordcoreani),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won sudcorean),
				'one' => q(won sudcorean),
				'other' => q(won sudcoreani),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dìnaro kuwaitian),
				'one' => q(dìnaro kuwaitian),
				'other' => q(dìnari kuwaitiani),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dòlaro caimaneze),
				'one' => q(dòlaro caimaneze),
				'other' => q(dòlari caimanezi),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazakistan),
				'one' => q(tenge kazakistan),
				'other' => q(tenge kazakistani),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laosian),
				'one' => q(kip laosian),
				'other' => q(kip laosiani),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(sterlina libaneze),
				'one' => q(sterlina libaneze),
				'other' => q(sterline libanezi),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupìa srilankeze),
				'one' => q(rupìa srilankeze),
				'other' => q(rupìe srilankezi),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dòlaro liberian),
				'one' => q(dòlaro liberian),
				'other' => q(dòlari liberiani),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lezotian),
				'one' => q(loti lezotian),
				'other' => q(loti lezotiani),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dìnaro lìbego),
				'one' => q(dìnaro lìbego),
				'other' => q(dìnari lìbeghi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marochin),
				'one' => q(dirham marochin),
				'other' => q(dirham marochini),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(leu moldavi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariari malgaso),
				'one' => q(ariari malgaso),
				'other' => q(ariari malgasi),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dìnaro masèdone),
				'one' => q(dìnaro masèdone),
				'other' => q(dìnari masèdoni),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kiat birman),
				'one' => q(kiat birman),
				'other' => q(kiat birmani),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik móngolo),
				'one' => q(tugrik móngolo),
				'other' => q(tugrik móngoli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca macaena),
				'one' => q(pataca macaena),
				'other' => q(patache macaene),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ughija mauritan),
				'one' => q(ughija mauritan),
				'other' => q(ughija mauritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupìa maurisiana),
				'one' => q(rupìa maurisiana),
				'other' => q(rupìe maurisiane),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rupìa maldiviana),
				'one' => q(rupìa maldiviana),
				'other' => q(rupìe maldiviane),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawian),
				'one' => q(kwacha malawian),
				'other' => q(kwacha malawiani),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(pezos mesegan),
				'one' => q(pezos mesegan),
				'other' => q(pezos mesegani),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringit malezian),
				'one' => q(ringit malezian),
				'other' => q(ringit maleziani),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozanbigan),
				'one' => q(metical mozanbigan),
				'other' => q(metical mozanbigani),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dòlaro namibian),
				'one' => q(dòlaro namibian),
				'other' => q(dòlari namibiani),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(naire nigeriane),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(còrdoba nicaragueze),
				'one' => q(còrdoba nicaragueze),
				'other' => q(còrdoba nicaraguezi),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(corona norvejeze),
				'one' => q(corona norvejeze),
				'other' => q(corone norvejezi),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupìa nepaleze),
				'one' => q(rupìa nepaleze),
				'other' => q(rupìe nepalezi),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(dòlaro neozelandeze),
				'one' => q(dòlaro neozelandeze),
				'other' => q(dòlari neozelandezi),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omaneze),
				'one' => q(rial omaneze),
				'other' => q(rial omanezi),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balbòa panameze),
				'one' => q(balbòa panameze),
				'other' => q(balbòa panamezi),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(soles peruvian),
				'one' => q(soles peruvian),
				'other' => q(soles peruviani),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papuaiana),
				'one' => q(kina papuaiana),
				'other' => q(kine papuaiane),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(pezos filipin),
				'one' => q(pezos filipin),
				'other' => q(pezos filipini),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupìa pakistana),
				'one' => q(rupìa pakistana),
				'other' => q(rupìe pakistane),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polaco),
				'one' => q(zloty polaco),
				'other' => q(zloty polachi),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaranì paraguaian),
				'one' => q(guaranì paraguaian),
				'other' => q(guaranì paraguaiani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial catarian),
				'one' => q(rial catarian),
				'other' => q(rial catariani),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(leu romen),
				'one' => q(leu romen),
				'other' => q(leu romeni),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dìnaro serbo),
				'one' => q(dìnaro serbo),
				'other' => q(dìnari serbi),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublo ruso),
				'one' => q(rublo ruso),
				'other' => q(rubli rusi),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franco ruandeze),
				'one' => q(franco ruandeze),
				'other' => q(franchi ruandezi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(rial saudìo),
				'one' => q(rial saudìo),
				'other' => q(rial saudìi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dòlaro salomoneze),
				'one' => q(dòlaro salomoneze),
				'other' => q(dòlari salomonezi),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupìa seiseleze),
				'one' => q(rupìa seiseleze),
				'other' => q(rupìe seiselezi),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sterlina sudaneze),
				'one' => q(sterlina sudaneze),
				'other' => q(sterline sudanezi),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona zvedeze),
				'one' => q(corona zvedeze),
				'other' => q(corone zvedezi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dòlaro singaporian),
				'one' => q(dòlaro singaporian),
				'other' => q(dòlari singaporiani),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sterlina de Sant’Èlena),
				'one' => q(sterlina de Sant’Èlena),
				'other' => q(sterline de Sant’Èlena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leon sierleoneze),
				'one' => q(leon sierleoneze),
				'other' => q(leoni sierleonezi),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leon sierleoneze \(1964—2022\)),
				'one' => q(leon sierleoneze \(1964—2022\)),
				'other' => q(leoni sierleonezi \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(selin sòmalo),
				'one' => q(selin sòmalo),
				'other' => q(selini sòmali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dòlaro surinameze),
				'one' => q(dòlaro surinameze),
				'other' => q(dòlari surinamezi),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sterlina sud sudaneze),
				'one' => q(sterlina sud sudaneze),
				'other' => q(sterline sud sudanezi),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra de S. Tomazo e Prìnsipe),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sterlina siriana),
				'one' => q(sterlina siriana),
				'other' => q(sterline siriane),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni esuatin),
				'one' => q(lilangeni esuatin),
				'other' => q(lilangeni esuatini),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(bat tailandeze),
				'one' => q(bat tailandeze),
				'other' => q(bat tailandezi),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tajikistan),
				'one' => q(somoni tajikistan),
				'other' => q(somoni tajikistani),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmenistan),
				'one' => q(manat turkmenistan),
				'other' => q(manat turkmenistani),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dìnaro tunizin),
				'one' => q(dìnaro tunizin),
				'other' => q(dìnari tunizini),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga tongan),
				'one' => q(paʻanga tongan),
				'other' => q(paʻanga tongani),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(lire turche),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dòlaro de Trinidà e Tabaco),
				'one' => q(dòlaro de Trinidà e Tabaco),
				'other' => q(dòlari de Trinidà e Tabaco),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(novo dòlaro taiwaneze),
				'one' => q(novo dòlaro taiwaneze),
				'other' => q(novi dòlari taiwanezi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(selin tanzaneze),
				'one' => q(selin tanzaneze),
				'other' => q(selini tanzanezi),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grivna ucraina),
				'one' => q(grivna ucraina),
				'other' => q(grivne ucraine),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(selin ugandeze),
				'one' => q(selin ugandeze),
				'other' => q(selini ugandezi),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(dòlaro meregan),
				'one' => q(dòlaro meregan),
				'other' => q(dòlari meregani),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(pezos uruguaian),
				'one' => q(pezos uruguaian),
				'other' => q(pezos uruguaiani),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som uzbekistan),
				'one' => q(som uzbekistan),
				'other' => q(som uzbekistani),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolìvar venesuelan),
				'one' => q(bolìvar venesuelan),
				'other' => q(bolìvar venesuelani),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(dong vietnameze),
				'one' => q(dong vietnameze),
				'other' => q(dong vietnamezi),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu vanuatian),
				'one' => q(vatu vanuatian),
				'other' => q(vatu vanuatiani),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoan),
				'one' => q(tala samoan),
				'other' => q(tala samoani),
			},
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(franco CFA de l’Àfrega sentrale),
				'one' => q(franco CFA de l’Àfrega sentrale),
				'other' => q(franchi CFA de l’Àfrega sentrale),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dòlaro caraìbego),
				'one' => q(dòlaro caraìbego),
				'other' => q(dòlari caraìbeghi),
			},
		},
		'XOF' => {
			symbol => 'XOF',
			display_name => {
				'currency' => q(franco CFA de l’Àfrega osidentale),
				'one' => q(franco CFA de l’Àfrega osidentale),
				'other' => q(franchi CFA de l’Àfrega osidentale),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(franco CFP),
				'other' => q(franchi CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneda desconosùa),
				'one' => q(\(moneda desconosùa\)),
				'other' => q(\(moneda desconosùa\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial yemenida),
				'one' => q(rial yemenida),
				'other' => q(rial yemenìi),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafregan),
				'one' => q(rand sudafregan),
				'other' => q(rand sudafregani),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zanbian),
				'one' => q(kwacha zanbian),
				'other' => q(kwacha zanbiani),
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
							'jen',
							'feb',
							'mar',
							'apr',
							'maj',
							'jug',
							'luj',
							'ago',
							'set',
							'oto',
							'nov',
							'des'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'jenaro',
							'febraro',
							'marso',
							'aprile',
							'majo',
							'jugno',
							'lujo',
							'agosto',
							'setenbre',
							'otobre',
							'novenbre',
							'desenbre'
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
							'L',
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
						mon => 'lun',
						tue => 'mar',
						wed => 'mer',
						thu => 'zob',
						fri => 'vèn',
						sat => 'sab',
						sun => 'dom'
					},
					wide => {
						mon => 'luni',
						tue => 'marti',
						wed => 'mèrcore',
						thu => 'zoba',
						fri => 'vènare',
						sat => 'sabo',
						sun => 'doménega'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'Z',
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
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
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
				'0' => 'v.C.',
				'1' => 'd.C.'
			},
			wide => {
				'0' => 'vanti Cristo',
				'1' => 'daspò Cristo'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
			'short' => q{dd/MM/yy},
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
			'full' => q{HH:mm:ss zzzz},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E d},
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
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y G},
			Hmsv => q{HH:mm:ss (v)},
			Hmv => q{HH:mm (v)},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{W'ª' 'setemana' 'de' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			hmsv => q{h:mm:ss a (v)},
			hmv => q{h:mm a (v)},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w'ª' 'setemana' 'de''l' Y},
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
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			GyMEd => {
				G => q{E dd/MM/y G – E dd/MM/y G},
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
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
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y G – dd/MM/y G},
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y G – dd/MM/y G},
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
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d – E d MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{d – d MMM},
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
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
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
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		gmtFormat => q(UTC{0}),
		gmtZeroFormat => q(UTC),
		regionFormat => q(Ora {0}),
		regionFormat => q(Ora d’istà {0}),
		regionFormat => q(Ora normale {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Ora de l’Afghanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abijan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljeri#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Azmara#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Banghì#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisào#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujunbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#El Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Cazablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Cèuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conacri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ajun#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kanpala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Cartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubunbashi#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Mazeru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Nbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiso#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Jamena#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakchot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugù#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Ìzola S. Tomazo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trìpoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tùnezi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora de l’Àfrega sentrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora de l’Àfrega orientale#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora de l’Àfrega meridionale#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora d’istà de l’Àfrega osidentale#,
				'generic' => q#Ora de l’Àfrega osidentale#,
				'standard' => q#Ora normale de l’Àfrega osidentale#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora d’istà de l’Alaska#,
				'generic' => q#Ora de l’Alaska#,
				'standard' => q#Ora normale de l’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora d’istà de l’Amasonia#,
				'generic' => q#Ora de l’Amasonia#,
				'standard' => q#Ora normale de l’Amasonia#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gàlegos#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Baia de Banderas#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotà#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Canpo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caiman#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#Juárez#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Còrdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabà#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Denver' => {
			exemplarCity => q#Dènver#,
		},
		'America/Dominica' => {
			exemplarCity => q#Doménega#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupa#,
		},
		'America/Havana' => {
			exemplarCity => q#L’Avana#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox (Indiana)#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo (Indiana)#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg (Indiana)#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City (Indiana)#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay (Indiana)#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes (Indiana)#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac (Indiana)#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianàpolis#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamàega#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello (Kentucky)#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Àngeles#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martiniga#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Sità de’l Mèsego#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Michelon#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterey#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserat#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernando de Noronha#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah (Nord Dakota)#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center (Nord Dakota)#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem (Nord Dakota)#,
		},
		'America/Panama' => {
			exemplarCity => q#Pànama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pang#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Porto Prìnsipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Porto de Spagna#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portorico#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Polo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#S. Bartolomèo#,
		},
		'America/St_Johns' => {
			exemplarCity => q#S. Joani#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#S. Cristofer#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#S. Lusìa#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#S. Tomazo#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#S. Vincenso#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tòrtola#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora d’istà de’l nord mèrega sentrale#,
				'generic' => q#Ora de’l nord mèrega sentrale#,
				'standard' => q#Ora normale de’l nord mèrega sentrale#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora d’istà de’l nord mèrega orientale#,
				'generic' => q#Ora de’l nord mèrega orientale#,
				'standard' => q#Ora normale de’l nord mèrega orientale#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora d’istà de’l nord mèrega de le montagne#,
				'generic' => q#Ora de’l nord mèrega de le montagne#,
				'standard' => q#Ora normale de’l nord mèrega de le montagne#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora d’istà de’l nord mèrega de’l Pasìfego#,
				'generic' => q#Ora de’l nord mèrega de’l Pasìfego#,
				'standard' => q#Ora normale de’l nord mèrega de’l Pasìfego#,
			},
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Ìzola Macquarie#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora d’istà de Apia#,
				'generic' => q#Ora de Apia#,
				'standard' => q#Ora normale de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora d’istà de l’Arabia#,
				'generic' => q#Ora de l’Arabia#,
				'standard' => q#Ora normale de l’Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora d’istà de l’Arjentina#,
				'generic' => q#Ora de l’Arjentina#,
				'standard' => q#Ora normale de l’Arjentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora d’istà de l’Arjentina osidentale#,
				'generic' => q#Ora de l’Arjentina osidentale#,
				'standard' => q#Ora normale de l’Arjentina osidentale#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora d’istà de l’Armenia#,
				'generic' => q#Ora de l’Armenia#,
				'standard' => q#Ora normale de l’Armenia#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktàu#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyràu#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barein#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunéi#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colonbo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daca#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubài#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagosta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzaleme#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandù#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lunpur#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macào#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnom Pen#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanài#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kizilorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghài#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipéi#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiblisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Tinpu#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bàtor#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumchi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientian#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jèrevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora d’istà de’l nord mèrega de l’Atlàntego#,
				'generic' => q#Ora de’l nord mèrega de l’Atlàntego#,
				'standard' => q#Ora normale de’l nord mèrega de l’Atlàntego#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Ìzole Azore#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Ìzole Canarie#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cao Verdo#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Ìzole Fàroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Ìzola Madèira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rekiavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia de’l sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Ìzola S. Elena#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelàide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brizbane#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Ìzola Lord Howe#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora d’istà de l’Australia sentrale#,
				'generic' => q#Ora de l’Australia sentrale#,
				'standard' => q#Ora normale de l’Australia sentrale#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora d’istà de l’Australia sentro osidentale#,
				'generic' => q#Ora de l’Australia sentro osidentale#,
				'standard' => q#Ora normale de l’Australia sentro osidentale#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora d’istà de l’Australia orientale#,
				'generic' => q#Ora de l’Australia orientale#,
				'standard' => q#Ora normale de l’Australia orientale#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora d’istà de l’Australia osidentale#,
				'generic' => q#Ora de l’Australia osidentale#,
				'standard' => q#Ora normale de l’Australia osidentale#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora d’istà de l’Azerbaijan#,
				'generic' => q#Ora de l’Azerbaijan#,
				'standard' => q#Ora normale de l’Azerbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora d’istà de le Azore#,
				'generic' => q#Ora de le Azore#,
				'standard' => q#Ora normale de le Azore#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora d’istà de’l Bangladesh#,
				'generic' => q#Ora de’l Bangladesh#,
				'standard' => q#Ora normale de’l Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora de’l Butan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora de la Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora d’istà de Brazilia#,
				'generic' => q#Ora de Brazilia#,
				'standard' => q#Ora normale de Brazilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora de’l Brunéi#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora d’istà de Cao Verdo#,
				'generic' => q#Ora de Cao Verdo#,
				'standard' => q#Ora normale de Cao Verdo#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora de Chamoro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Ciatem#,
				'generic' => q#Ora de le Ìzole Ciatem#,
				'standard' => q#Ora normale de le Ìzole Ciatem#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora d’istà de’l Cile#,
				'generic' => q#Ora de’l Cile#,
				'standard' => q#Ora normale de’l Cile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora d’istà de la Sina#,
				'generic' => q#Ora de la Sina#,
				'standard' => q#Ora normale de la Sina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Ora d’istà de Choibalsan#,
				'generic' => q#Ora de Choibalsan#,
				'standard' => q#Ora normale de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora de l’Ìzola de Nadale#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora de le Ìzole Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora d’istà de la Colonbia#,
				'generic' => q#Ora de la Colonbia#,
				'standard' => q#Ora normale de la Colonbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Cook#,
				'generic' => q#Ora de le Ìzole Cook#,
				'standard' => q#Ora normale de le Ìzole Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora d’istà de Cuba#,
				'generic' => q#Ora de Cuba#,
				'standard' => q#Ora normale de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora de Dumont d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora de’l Timor Est#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora d’istà de l’Ìzola de Pascua#,
				'generic' => q#Ora de l’Ìzola de Pascua#,
				'standard' => q#Ora normale de l’Ìzola de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora de l’Ècuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ora universale coordenada#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Sità desconosùa#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Àmsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratizlava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenaghen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Ora d’istà irlandeze#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jibiltera#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ìzola de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Ìstanbul#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lizbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Ora d’istà britànega#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lusenburgo#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mònaco#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ozlo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariji#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorisa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marin#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Sinferòpoli#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stocolma#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ùzgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vategan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporija#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurigo#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora d’istà de l’Europa sentrale#,
				'generic' => q#Ora de l’Europa sentrale#,
				'standard' => q#Ora normale de l’Europa sentrale#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora d’istà de l’Europa orientale#,
				'generic' => q#Ora de l’Europa orientale#,
				'standard' => q#Ora normale de l’Europa orientale#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora de l’Europa stra orientale#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora d’istà de l’Europa osidentale#,
				'generic' => q#Ora de l’Europa osidentale#,
				'standard' => q#Ora normale de l’Europa osidentale#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Malvine#,
				'generic' => q#Ora de le Ìzole Malvine#,
				'standard' => q#Ora normale de le Ìzole Malvine#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Fiji#,
				'generic' => q#Ora de le Ìzole Fiji#,
				'standard' => q#Ora normale de le Ìzole Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora de la Guyana franseze#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora de le Tere fransezi de’l sud e de l’Antàrtego#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora de’l meridian de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora de le Galàpagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora de le Ìzole Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora d’istà de la Jeorja#,
				'generic' => q#Ora de la Jeorja#,
				'standard' => q#Ora normale de la Jeorja#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora de le Ìzole Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora d’istà de la Groenlanda orientale#,
				'generic' => q#Ora de la Groenlanda orientale#,
				'standard' => q#Ora normale de la Groenlanda orientale#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora d’istà de la Groenlanda osidentale#,
				'generic' => q#Ora de la Groenlanda osidentale#,
				'standard' => q#Ora normale de la Groenlanda osidentale#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora de’l Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora de la Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora d’istà de Hawai e Aleutine#,
				'generic' => q#Ora de Hawai e Aleutine#,
				'standard' => q#Ora normale de Hawai e Aleutine#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora d’istà de Hong Kong#,
				'generic' => q#Ora de Hong Kong#,
				'standard' => q#Ora normale de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora d’istà de Hovd#,
				'generic' => q#Ora de Hovd#,
				'standard' => q#Ora normale de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora de l’India#,
			},
		},
		'Indian/Chagos' => {
			exemplarCity => q#Ciagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Ìzola de Nadale#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Ìzole Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Ìzole Comore#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Ìzole Maldive#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Ìzole Maurisio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Ìzole Maiote#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Ìzola Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora de l’Osèano Indian#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora de l’Indosina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora de l’Indonezia sentrale#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora de l’Indonezia orientale#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora de l’Indonezia osidentale#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora d’istà de l’Iran#,
				'generic' => q#Ora de l’Iran#,
				'standard' => q#Ora normale de l’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora d’istà de Irkutsk#,
				'generic' => q#Ora de Irkutsk#,
				'standard' => q#Ora normale de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora d’istà de Izraele#,
				'generic' => q#Ora de Izraele#,
				'standard' => q#Ora normale de Izraele#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora d’istà de’l Japon#,
				'generic' => q#Ora de’l Japon#,
				'standard' => q#Ora normale de’l Japon#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora de’l Kazakistan orientale#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora de’l Kazakistan osidentale#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora d’istà de la Corèa#,
				'generic' => q#Ora de la Corèa#,
				'standard' => q#Ora normale de la Corèa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora de l’Ìzola Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora d’istà de Krasnoyarsk#,
				'generic' => q#Ora de Krasnoyarsk#,
				'standard' => q#Ora normale de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora de’l Kirghizistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora de le Ìzole Ecuatoriali#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora d’istà de l’Ìzola Lord Howe#,
				'generic' => q#Ora de l’Ìzola Lord Howe#,
				'standard' => q#Ora normale de l’Ìzola Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Ora de l’Ìzola Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora d’istà de Magadan#,
				'generic' => q#Ora de Magadan#,
				'standard' => q#Ora normale de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora de la Malezia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora de le Ìzole Maldive#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora de le Ìzole Marchezi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ora de le Ìzole Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Maurisio#,
				'generic' => q#Ora de le Ìzole Maurisio#,
				'standard' => q#Ora normale de le Ìzole Maurisio#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ora d’istà de’l Mèsego nord osidentale#,
				'generic' => q#Ora de’l Mèsego nord osidentale#,
				'standard' => q#Ora normale de’l Mèsego nord osidentale#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora d’istà de’l Mèsego de’l Pasìfego#,
				'generic' => q#Ora de’l Mèsego de’l Pasìfego#,
				'standard' => q#Ora normale de’l Mèsego de’l Pasìfego#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora d’istà de Ulan Bàtor#,
				'generic' => q#Ora de Ulan Bàtor#,
				'standard' => q#Ora normale de Ulan Bàtor#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora d’istà de Mosca#,
				'generic' => q#Ora de Mosca#,
				'standard' => q#Ora normale de Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora de Myanmar (Birmania)#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora de l’Ìzola Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora de’l Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora d’istà de la Nova Caledonia#,
				'generic' => q#Ora de la Nova Caledonia#,
				'standard' => q#Ora normale de la Nova Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora d’istà de la Nova Zelanda#,
				'generic' => q#Ora de la Nova Zelanda#,
				'standard' => q#Ora normale de la Nova Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora d’istà de Teranova#,
				'generic' => q#Ora de Teranova#,
				'standard' => q#Ora normale de Teranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora de l’Ìzola Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora d’istà de l’Ìzola Norfolk#,
				'generic' => q#Ora de l’Ìzola Norfolk#,
				'standard' => q#Ora normale de l’Ìzola Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora d’istà de Fernando de Noronha#,
				'generic' => q#Ora de Fernando de Noronha#,
				'standard' => q#Ora normale de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora d’istà de Novosibirsk#,
				'generic' => q#Ora de Novosibirsk#,
				'standard' => q#Ora normale de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora d’istà de Omsk#,
				'generic' => q#Ora de Omsk#,
				'standard' => q#Ora normale de Omsk#,
			},
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Ìzola Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Ìzole Ciatem#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ìzola de Pascua#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Ìzola Efate#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Atolo Fakaofo#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Atolo Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galàpagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Ìzole Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Ìzola Guadalcanal#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Atolo Johnston#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Atolo Canton#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Atolo Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Ìzola Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Atolo Kwajalein#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Ìzole Marchezi#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Atolo Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Ìzola Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Ìzola Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Ìzola Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pango Pango#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palàu#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Ìzola Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ìzola Ponpèi#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Porto Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Ìzola Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Ìzola Saipàn#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Ìzola Taiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Atollo Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Ìzola Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Ìzole Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Atolo Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Ìzola Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora d’istà de’l Pakistan#,
				'generic' => q#Ora de’l Pakistan#,
				'standard' => q#Ora normale de’l Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora de le Ìzole Palàu#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora de la Papua Nova Guinèa#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora d’istà de’l Paraguài#,
				'generic' => q#Ora de’l Paraguài#,
				'standard' => q#Ora normale de’l Paraguài#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora d’istà de’l Perù#,
				'generic' => q#Ora de’l Perù#,
				'standard' => q#Ora normale de’l Perù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Filipine#,
				'generic' => q#Ora de le Ìzole Filipine#,
				'standard' => q#Ora normale de le Ìzole Filipine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora de le Ìzole Fenize#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora d’istà de S. Piero e Michelon#,
				'generic' => q#Ora de S. Piero e Michelon#,
				'standard' => q#Ora normale de S. Piero e Michelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora de le Ìzole Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora de l’Ìzola Ponpèi#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora de Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora de l’Ìzola Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora d’istà de Sakalin#,
				'generic' => q#Ora de Sakalin#,
				'standard' => q#Ora normale de Sakalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Samòa#,
				'generic' => q#Ora de le Ìzole Samòa#,
				'standard' => q#Ora normale de le Ìzole Samòa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora d’istà de le Ìzole Seisel#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora de Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora de le Ìzole Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora de la Georgia de’l sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora de’l Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora de l’Ìzola Taiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora d’istà de Taipéi#,
				'generic' => q#Ora de Taipéi#,
				'standard' => q#Ora normale de Taipéi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora de’l Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora de le Ìzole Tokelàu#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Tonga#,
				'generic' => q#Ora de le Ìzole Tonga#,
				'standard' => q#Ora normale de le Ìzole Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora de’l Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora d’istà de’l Turkmenistan#,
				'generic' => q#Ora de’l Turkmenistan#,
				'standard' => q#Ora normale de’l Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora de le Ìzole Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora d’istà de l’Uruguài#,
				'generic' => q#Ora de l’Uruguài#,
				'standard' => q#Ora normale de l’Uruguài#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora d’istà de l’Uzbekistan#,
				'generic' => q#Ora de l’Uzbekistan#,
				'standard' => q#Ora normale de l’Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora d’istà de le Ìzole Vanuatu#,
				'generic' => q#Ora de le Ìzole Vanuatu#,
				'standard' => q#Ora normale de le Ìzole Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora de’l Venesuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora d’istà de Vladivostok#,
				'generic' => q#Ora de Vladivostok#,
				'standard' => q#Ora normale de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora d’istà de Volgogrado#,
				'generic' => q#Ora de Volgogrado#,
				'standard' => q#Ora normale de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora de l’Atolo Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora de le Ìzole Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora d’istà de Yakutsk#,
				'generic' => q#Ora de Yakutsk#,
				'standard' => q#Ora normale de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora d’istà de Ekaterinburgo#,
				'generic' => q#Ora de Ekaterinburgo#,
				'standard' => q#Ora normale de Ekaterinburgo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora de’l Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
