=encoding utf8

=head1 NAME

Locale::CLDR::Locales::It - Package for language Italian

=cut

package Locale::CLDR::Locales::It;
# This file auto generated from Data\common\main\it.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-masculine-plural','spellout-ordinal-feminine-plural','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
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
					rule => q(=#,##0==%%dord-femabbrev=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-femabbrev=),
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
					rule => q(=#,##0==%%dord-mascabbrev=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%dord-mascabbrev=),
				},
			},
		},
		'dord-femabbrev' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ª),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ª),
				},
			},
		},
		'dord-mascabbrev' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(º),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(º),
				},
			},
		},
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
					rule => q(­una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
				'max' => {
					base_value => q(2),
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
					rule => q(­una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
				'max' => {
					base_value => q(2),
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
					rule => q(o­una),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-o=),
				},
				'max' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-o=),
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
					rule => q(vent→%%msc-with-i-nofinal→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msc-with-a-nofinal→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%msc-with-a-nofinal→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%msc-with-a-nofinal→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%msc-with-a-nofinal→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%msc-with-a-nofinal→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%msc-with-a-nofinal→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msc-with-a-nofinal→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%msc-with-o-nofinal→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­cent→%%msc-with-o-nofinal→),
				},
				'max' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­cent→%%msc-with-o-nofinal→),
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
					rule => q(­un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-a=),
				},
				'max' => {
					base_value => q(2),
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
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­tre),
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
					rule => q(­un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%msco-with-i=),
				},
				'max' => {
					base_value => q(2),
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
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­tre),
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
					rule => q(o­uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­due),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­tré),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(­=%spellout-numbering=),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(o­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(90),
					divisor => q(10),
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
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­tre),
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
					rule => q(­uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­due),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­tré),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­=%spellout-numbering=),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­nove),
				},
				'max' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­nove),
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
					rule => q(­uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­due),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­tré),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­=%spellout-numbering=),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­nove),
				},
				'max' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­nove),
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
					rule => q(o­uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­due),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­tré),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­otto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­=%spellout-numbering=),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(­=%spellout-numbering=),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(o­=%spellout-numbering=),
				},
				'max' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(o­=%spellout-numbering=),
				},
			},
		},
		'ordinal-esima' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sima),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesima),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­duesima),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treesima),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­quattresima),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­cinquesima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­seiesima),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­settesima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesima),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novesima),
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
		'ordinal-esima-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esima),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesima),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­duesima),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treesima),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­quattresima),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­cinquesima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­seiesima),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­settesima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesima),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novesima),
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
		'ordinal-esima-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esima),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesima),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­duesima),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treesima),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­quattresima),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­cinquesima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­seiesima),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­settesima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesima),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novesima),
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
		'ordinal-esima-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esima),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesima),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­duesima),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treesima),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­quattresima),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­cinquesima),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­seiesima),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­settesima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesima),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novesima),
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
		'ordinal-esime' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sime),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesime),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­duesime),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treesime),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­quattresime),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­cinquesime),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­seiesime),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­settesime),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesime),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novesime),
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
		'ordinal-esime-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esime),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesime),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­duesime),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treesime),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­quattresime),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­cinquesime),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­seiesime),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­settesime),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesime),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novesime),
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
		'ordinal-esime-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esime),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesime),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­duesime),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treesime),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­quattresime),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­cinquesime),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­seiesime),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­settesime),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesime),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novesime),
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
		'ordinal-esime-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esime),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesime),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­duesime),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treesime),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­quattresime),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­cinquesime),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­seiesime),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­settesime),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesime),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novesime),
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
		'ordinal-esimi' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(simi),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­duesimi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treesimi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­quattresimi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­cinquesimi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­seiesimi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­settesimi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novesimi),
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
		'ordinal-esimi-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimi),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­duesimi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treesimi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­quattresimi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­cinquesimi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­seiesimi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­settesimi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novesimi),
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
		'ordinal-esimi-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimi),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­duesimi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treesimi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­quattresimi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­cinquesimi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­seiesimi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­settesimi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novesimi),
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
		'ordinal-esimi-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimi),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­duesimi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treesimi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­quattresimi),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­cinquesimi),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­seiesimi),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­settesimi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novesimi),
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
		'ordinal-esimo' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(simo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(­duesimo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(­treesimo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(­quattresimo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(­cinquesimo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(­seiesimo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(­settesimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(­novesimo),
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
		'ordinal-esimo-with-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a­duesimo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a­treesimo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a­quattresimo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a­cinquesimo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a­seiesimo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a­settesimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a­novesimo),
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
		'ordinal-esimo-with-i' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(i­duesimo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(i­treesimo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(i­quattresimo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(i­cinquesimo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(i­seiesimo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(i­settesimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(i­novesimo),
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
		'ordinal-esimo-with-o' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(esimo),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­unesimo),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(o­duesimo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(o­treesimo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(o­quattresimo),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(o­cinquesimo),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(o­seiesimo),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(o­settesimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(­ottesimo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(o­novesimo),
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
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgola →→),
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
					rule => q(quarant→%%fem-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%fem-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%fem-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%fem-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%fem-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%fem-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%fem-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­cent→%%fem-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­mila[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un milione[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardi[ →→]),
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
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgola →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(un),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%msc-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msc-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%msc-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%msc-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%msc-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%msc-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%msc-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msc-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%msc-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­cent→%%msc-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­mila[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un milione[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardi[ →→]),
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
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zero),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← virgola →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(uno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(due),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quattro),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cinque),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sei),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sette),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(otto),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nove),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(dieci),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undici),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodici),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredici),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quattordici),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quindici),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedici),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(diciassette),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(diciotto),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diciannove),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%msco-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%msco-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%msco-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%msco-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%msco-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%msco-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%msco-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%msco-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%msco-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←←­cent→%%msco-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille[­→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%%msc-no-final←­mila[­→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(un milione[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milioni[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(un miliardo[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardi[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(un bilione[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilioni[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(un biliardo[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardi[ →→]),
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
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zeresima),
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
					rule => q(seconda),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terza),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarta),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinta),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sesta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(settima),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ottava),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nona),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(decima),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undicesima),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodicesima),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredicesima),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quattordicesima),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quindicesima),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedicesima),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(diciassettesima),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(diciottesima),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diciannovesima),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-esima-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-esima-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%ordinal-esima-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%ordinal-esima-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%ordinal-esima-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%ordinal-esima-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%ordinal-esima-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-esima-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%ordinal-esima-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­cent→%%ordinal-esima-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille­→%%ordinal-esima→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­mille­→%%ordinal-esima→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­mila­→%%ordinal-esima→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(milione­→%%ordinal-esima→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine←milione­→%%ordinal-esima→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliard­→%%ordinal-esima-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine←miliard­→%%ordinal-esima-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(bilione­→%%ordinal-esima→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine←bilion­→%%ordinal-esima→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliard­→%%ordinal-esima-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine←biliard­→%%ordinal-esima-with-o→),
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
		'spellout-ordinal-feminine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zeresime),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(prime),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(seconde),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terze),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarte),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seste),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(settime),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ottave),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(none),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(decime),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undicesime),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodicesime),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredicesime),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quattordicesime),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quindicesime),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedicesime),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(diciassettesime),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(diciottesime),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diciannovesime),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-esime-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-esime-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%ordinal-esime-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%ordinal-esime-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%ordinal-esime-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%ordinal-esime-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%ordinal-esime-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-esime-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%ordinal-esime-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­cent→%%ordinal-esime-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille­→%%ordinal-esime→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­mille­→%%ordinal-esime→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine←­mila­→%%ordinal-esime→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(milione­→%%ordinal-esime→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine←milione­→%%ordinal-esime→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliard­→%%ordinal-esime-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine←miliard­→%%ordinal-esime-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(bilione­→%%ordinal-esime→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine←bilion­→%%ordinal-esime→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliard­→%%ordinal-esime-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine←biliard­→%%ordinal-esime-with-o→),
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
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zeresimo),
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
					rule => q(secondo),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terzo),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarto),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinto),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sesto),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(settimo),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ottavo),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(nono),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(decimo),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undicesimo),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodicesimo),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredicesimo),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quattordicesimo),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quindicesimo),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedicesimo),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(diciassettesimo),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(diciottesimo),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diciannovesimo),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-esimo-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-esimo-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%ordinal-esimo-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%ordinal-esimo-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%ordinal-esimo-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%ordinal-esimo-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%ordinal-esimo-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-esimo-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%ordinal-esimo-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­cent→%%ordinal-esimo-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille­→%%ordinal-esimo→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­mille­→%%ordinal-esimo→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­mila­→%%ordinal-esimo→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(milione­→%%ordinal-esimo→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine←milione­→%%ordinal-esimo→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliard­→%%ordinal-esimo-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine←miliard­→%%ordinal-esimo-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(bilione­→%%ordinal-esimo→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine←bilion­→%%ordinal-esimo→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliard­→%%ordinal-esimo-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine←biliard­→%%ordinal-esimo-with-o→),
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
		'spellout-ordinal-masculine-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(meno →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(zeresimi),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(primi),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(secondi),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(terzi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(quarti),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(quinti),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sesti),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(settimi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ottavi),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(noni),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(decimi),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(undicesimi),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dodicesimi),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tredicesimi),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(quattordicesimi),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(quindicesimi),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(sedicesimi),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(diciassettesimi),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(diciottesimi),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(diciannovesimi),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(vent→%%ordinal-esimi-with-i→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trent→%%ordinal-esimi-with-a→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(quarant→%%ordinal-esimi-with-a→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(cinquant→%%ordinal-esimi-with-a→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(sessant→%%ordinal-esimi-with-a→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(settant→%%ordinal-esimi-with-a→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ottant→%%ordinal-esimi-with-a→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(novant→%%ordinal-esimi-with-a→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(cent→%%ordinal-esimi-with-o→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­cent→%%ordinal-esimi-with-o→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(mille­→%%ordinal-esimi→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­mille­→%%ordinal-esimi→),
				},
				'2001' => {
					base_value => q(2001),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­mila­→%%ordinal-esimi→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(milione­→%%ordinal-esimi→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine←milione­→%%ordinal-esimi→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(miliard­→%%ordinal-esimi-with-o→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine←miliard­→%%ordinal-esimi-with-o→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(bilione­→%%ordinal-esimi→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine←bilion­→%%ordinal-esimi→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(biliard­→%%ordinal-esimi-with-o→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine←biliard­→%%ordinal-esimi-with-o→),
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
				'aa' => 'afar',
 				'ab' => 'abcaso',
 				'ace' => 'accinese',
 				'ach' => 'acioli',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'ae' => 'avestan',
 				'aeb' => 'arabo tunisino',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'accado',
 				'akz' => 'alabama',
 				'ale' => 'aleuto',
 				'aln' => 'albanese ghego',
 				'alt' => 'altai meridionale',
 				'am' => 'amarico',
 				'an' => 'aragonese',
 				'ang' => 'inglese antico',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabo',
 				'ar_001' => 'arabo moderno standard',
 				'arc' => 'aramaico',
 				'arn' => 'mapudungun',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'arabo algerino',
 				'ars' => 'arabo najd',
 				'arw' => 'aruaco',
 				'ary' => 'arabo marocchino',
 				'arz' => 'arabo egiziano',
 				'as' => 'assamese',
 				'asa' => 'asu',
 				'ase' => 'lingua dei segni americana',
 				'ast' => 'asturiano',
 				'atj' => 'atikamekw',
 				'av' => 'avaro',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaigiano',
 				'az@alt=short' => 'azero',
 				'ba' => 'baschiro',
 				'bal' => 'beluci',
 				'ban' => 'balinese',
 				'bar' => 'bavarese',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bbc' => 'batak toba',
 				'bbj' => 'ghomala',
 				'be' => 'bielorusso',
 				'bej' => 'begia',
 				'bem' => 'wemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'bulgaro',
 				'bgc' => 'haryanvi',
 				'bgn' => 'beluci occidentale',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bicol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bengalese',
 				'bo' => 'tibetano',
 				'bpy' => 'bishnupriya',
 				'bqi' => 'bakhtiari',
 				'br' => 'bretone',
 				'bra' => 'braj',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosniaco',
 				'bss' => 'akoose',
 				'bua' => 'buriat',
 				'bug' => 'bugi',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalano',
 				'cad' => 'caddo',
 				'car' => 'caribico',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'ceceno',
 				'ceb' => 'cebuano',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'ciagataico',
 				'chk' => 'chuukese',
 				'chm' => 'mari',
 				'chn' => 'gergo chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'curdo centrale',
 				'ckb@alt=menu' => 'curdo (centrale)',
 				'ckb@alt=variant' => 'curdo (sorani)',
 				'clc' => 'chilcotin',
 				'co' => 'corso',
 				'cop' => 'copto',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crg' => 'métchif',
 				'crh' => 'turco crimeo',
 				'crj' => 'cree sud-orientale',
 				'crk' => 'cree delle pianure',
 				'crl' => 'cree nord-orientale',
 				'crm' => 'cree moose',
 				'crr' => 'algonchino della Carolina',
 				'crs' => 'creolo delle Seychelles',
 				'cs' => 'ceco',
 				'csb' => 'kashubian',
 				'csw' => 'cree delle paludi',
 				'cu' => 'slavo ecclesiastico',
 				'cv' => 'ciuvascio',
 				'cy' => 'gallese',
 				'da' => 'danese',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tedesco',
 				'de_AT' => 'tedesco austriaco',
 				'de_CH' => 'alto tedesco svizzero',
 				'del' => 'delaware',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinca',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'basso sorabo',
 				'dtp' => 'dusun centrale',
 				'dua' => 'duala',
 				'dum' => 'olandese medio',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fony',
 				'dyu' => 'diula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emiliano',
 				'egy' => 'egiziano antico',
 				'eka' => 'ekajuka',
 				'el' => 'greco',
 				'elx' => 'elamitico',
 				'en' => 'inglese',
 				'en_AU' => 'inglese australiano',
 				'en_CA' => 'inglese canadese',
 				'en_GB' => 'inglese britannico',
 				'en_GB@alt=short' => 'inglese (GB)',
 				'en_US' => 'inglese americano',
 				'en_US@alt=short' => 'inglese (USA)',
 				'enm' => 'inglese medio',
 				'eo' => 'esperanto',
 				'es' => 'spagnolo',
 				'es_419' => 'spagnolo latinoamericano',
 				'es_ES' => 'spagnolo europeo',
 				'es_MX' => 'spagnolo messicano',
 				'esu' => 'yupik centrale',
 				'et' => 'estone',
 				'eu' => 'basco',
 				'ewo' => 'ewondo',
 				'ext' => 'estremegno',
 				'fa' => 'persiano',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandese',
 				'fil' => 'filippino',
 				'fit' => 'finlandese del Tornedalen',
 				'fj' => 'figiano',
 				'fo' => 'faroese',
 				'fon' => 'fon',
 				'fr' => 'francese',
 				'fr_CA' => 'francese canadese',
 				'fr_CH' => 'francese svizzero',
 				'frc' => 'francese cajun',
 				'frm' => 'francese medio',
 				'fro' => 'francese antico',
 				'frp' => 'francoprovenzale',
 				'frr' => 'frisone settentrionale',
 				'frs' => 'frisone orientale',
 				'fur' => 'friulano',
 				'fy' => 'frisone occidentale',
 				'ga' => 'irlandese',
 				'gaa' => 'ga',
 				'gag' => 'gagauzo',
 				'gan' => 'gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gbz' => 'dari zoroastriano',
 				'gd' => 'gaelico scozzese',
 				'gez' => 'geez',
 				'gil' => 'gilbertese',
 				'gl' => 'galiziano',
 				'glk' => 'gilaki',
 				'gmh' => 'tedesco medio alto',
 				'gn' => 'guaraní',
 				'goh' => 'tedesco antico alto',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotico',
 				'grb' => 'grebo',
 				'grc' => 'greco antico',
 				'gsw' => 'tedesco svizzero',
 				'gu' => 'gujarati',
 				'guc' => 'wayuu',
 				'guz' => 'gusii',
 				'gv' => 'mannese',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka',
 				'haw' => 'hawaiano',
 				'hax' => 'haida meridionale',
 				'he' => 'ebraico',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'hindi figiano',
 				'hil' => 'ilongo',
 				'hit' => 'hittite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croato',
 				'hsb' => 'alto sorabo',
 				'hsn' => 'xiang',
 				'ht' => 'creolo haitiano',
 				'hu' => 'ungherese',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armeno',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesiano',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiak',
 				'ikt' => 'inuktitut canadese occidentale',
 				'ilo' => 'ilocano',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandese',
 				'it' => 'italiano',
 				'iu' => 'inuktitut',
 				'izh' => 'ingrico',
 				'ja' => 'giapponese',
 				'jam' => 'creolo giamaicano',
 				'jbo' => 'lojban',
 				'jgo' => 'ngamambo',
 				'jmc' => 'machame',
 				'jpr' => 'giudeo persiano',
 				'jrb' => 'giudeo arabo',
 				'jut' => 'jutlandico',
 				'jv' => 'giavanese',
 				'ka' => 'georgiano',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'cabilo',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'cabardino',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'capoverdiano',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotanese',
 				'khq' => 'koyra chiini',
 				'khw' => 'khowar',
 				'ki' => 'kikuyu',
 				'kiu' => 'kirmanjki',
 				'kj' => 'kuanyama',
 				'kk' => 'kazako',
 				'kkj' => 'kako',
 				'kl' => 'groenlandese',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'coreano',
 				'koi' => 'permiaco',
 				'kok' => 'konkani',
 				'kos' => 'kosraean',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-Balkar',
 				'krl' => 'careliano',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'coloniese',
 				'ku' => 'curdo',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'cornico',
 				'kwk' => 'kwakʼwala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirghiso',
 				'la' => 'latino',
 				'lad' => 'giudeo-spagnolo',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'lussemburghese',
 				'lez' => 'lesgo',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'ganda',
 				'li' => 'limburghese',
 				'lij' => 'ligure',
 				'lil' => 'lillooet',
 				'liv' => 'livone',
 				'lkt' => 'lakota',
 				'lld' => 'ladino',
 				'lmo' => 'lombardo',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'lolo bantu',
 				'lou' => 'creolo della Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri settentrionale',
 				'lsm' => 'samia',
 				'lt' => 'lituano',
 				'ltg' => 'letgallo',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'lettone',
 				'lzh' => 'cinese classico',
 				'lzz' => 'laz',
 				'mad' => 'madurese',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'creolo mauriziano',
 				'mg' => 'malgascio',
 				'mga' => 'irlandese medio',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallese',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'menangkabau',
 				'mk' => 'macedone',
 				'ml' => 'malayalam',
 				'mn' => 'mongolo',
 				'mnc' => 'manchu',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'mrj' => 'mari occidentale',
 				'ms' => 'malese',
 				'mt' => 'maltese',
 				'mua' => 'mundang',
 				'mul' => 'multilingua',
 				'mus' => 'creek',
 				'mwl' => 'mirandese',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'my' => 'birmano',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazandarani',
 				'na' => 'nauru',
 				'nan' => 'min nan',
 				'nap' => 'napoletano',
 				'naq' => 'nama',
 				'nb' => 'norvegese bokmål',
 				'nd' => 'ndebele del nord',
 				'nds' => 'basso tedesco',
 				'nds_NL' => 'basso tedesco olandese',
 				'ne' => 'nepalese',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'njo' => 'ao',
 				'nl' => 'olandese',
 				'nl_BE' => 'fiammingo',
 				'nmg' => 'kwasio',
 				'nn' => 'norvegese nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegese',
 				'nog' => 'nogai',
 				'non' => 'norse antico',
 				'nov' => 'novial',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele del sud',
 				'nso' => 'sotho del nord',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari classico',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitano',
 				'oj' => 'ojibwa',
 				'ojb' => 'ojibwe nord-occidentale',
 				'ojc' => 'ojibwe centrale',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwe occidentale',
 				'oka' => 'okanagan',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossetico',
 				'osa' => 'osage',
 				'ota' => 'turco ottomano',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcd' => 'piccardo',
 				'pcm' => 'pidgin nigeriano',
 				'pdc' => 'tedesco della Pennsylvania',
 				'peo' => 'persiano antico',
 				'pfl' => 'tedesco palatino',
 				'phn' => 'fenicio',
 				'pi' => 'pali',
 				'pis' => 'pijin',
 				'pl' => 'polacco',
 				'pms' => 'piemontese',
 				'pnt' => 'pontico',
 				'pon' => 'ponape',
 				'pqm' => 'malecite-passamaquoddy',
 				'prg' => 'prussiano',
 				'pro' => 'provenzale antico',
 				'ps' => 'pashto',
 				'pt' => 'portoghese',
 				'pt_BR' => 'portoghese brasiliano',
 				'pt_PT' => 'portoghese europeo',
 				'qu' => 'quechua',
 				'quc' => 'k’iche’',
 				'qug' => 'quechua dell’altopiano del Chimborazo',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rgn' => 'romagnolo',
 				'rhg' => 'rohingya',
 				'rif' => 'tarifit',
 				'rm' => 'romancio',
 				'rn' => 'rundi',
 				'ro' => 'rumeno',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'rtm' => 'rotumano',
 				'ru' => 'russo',
 				'rue' => 'ruteno',
 				'rug' => 'roviana',
 				'rup' => 'arumeno',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrito',
 				'sad' => 'sandawe',
 				'sah' => 'sacha',
 				'sam' => 'aramaico samaritano',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'saurashtra',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardo',
 				'scn' => 'siciliano',
 				'sco' => 'scozzese',
 				'sd' => 'sindhi',
 				'sdc' => 'sassarese',
 				'sdh' => 'curdo meridionale',
 				'se' => 'sami del nord',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'irlandese antico',
 				'sgs' => 'samogitico',
 				'sh' => 'serbo-croato',
 				'shi' => 'tashelhit',
 				'shn' => 'shan',
 				'shu' => 'arabo ciadiano',
 				'si' => 'singalese',
 				'sid' => 'sidamo',
 				'sk' => 'slovacco',
 				'sl' => 'sloveno',
 				'slh' => 'lushootseed meridionale',
 				'sli' => 'tedesco slesiano',
 				'sly' => 'selayar',
 				'sm' => 'samoano',
 				'sma' => 'sami del sud',
 				'smj' => 'sami di Lule',
 				'smn' => 'sami di Inari',
 				'sms' => 'sami skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalo',
 				'sog' => 'sogdiano',
 				'sq' => 'albanese',
 				'sr' => 'serbo',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sotho del sud',
 				'stq' => 'saterfriesisch',
 				'str' => 'salish straits',
 				'su' => 'sundanese',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumero',
 				'sv' => 'svedese',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili del Congo',
 				'swb' => 'comoriano',
 				'syc' => 'siriaco classico',
 				'syr' => 'siriaco',
 				'szl' => 'slesiano',
 				'ta' => 'tamil',
 				'tce' => 'tutchone meridionale',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tagico',
 				'tgx' => 'tagish',
 				'th' => 'thailandese',
 				'tht' => 'tahltan',
 				'ti' => 'tigrino',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turcomanno',
 				'tkl' => 'tokelau',
 				'tkr' => 'tsakhur',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tly' => 'taliscio',
 				'tmh' => 'tamashek',
 				'tn' => 'tswana',
 				'to' => 'tongano',
 				'tog' => 'nyasa del Tonga',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'zaconico',
 				'tsi' => 'tsimshian',
 				'tt' => 'tataro',
 				'ttm' => 'tutchone settentrionale',
 				'ttt' => 'tat islamico',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'ci',
 				'twq' => 'tasawaq',
 				'ty' => 'taitiano',
 				'tyv' => 'tuvinian',
 				'tzm' => 'tamazight',
 				'udm' => 'udmurt',
 				'ug' => 'uiguro',
 				'uga' => 'ugaritico',
 				'uk' => 'ucraino',
 				'umb' => 'mbundu',
 				'und' => 'lingua imprecisata',
 				'ur' => 'urdu',
 				'uz' => 'uzbeco',
 				've' => 'venda',
 				'vec' => 'veneto',
 				'vep' => 'vepso',
 				'vi' => 'vietnamita',
 				'vls' => 'fiammingo occidentale',
 				'vmw' => 'macua',
 				'vo' => 'volapük',
 				'vot' => 'voto',
 				'vro' => 'võro',
 				'vun' => 'vunjo',
 				'wa' => 'vallone',
 				'wae' => 'walser',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'kalmyk',
 				'xh' => 'xhosa',
 				'xmf' => 'mengrelio',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'yao (bantu)',
 				'yap' => 'yapese',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantonese',
 				'yue@alt=menu' => 'cinese (cantonese)',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymbol',
 				'zea' => 'zelandese',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight del Marocco standard',
 				'zh' => 'cinese',
 				'zh@alt=menu' => 'cinese (mandarino)',
 				'zh_Hans' => 'cinese semplificato',
 				'zh_Hans@alt=long' => 'cinese mandarino semplificato',
 				'zh_Hant' => 'cinese tradizionale',
 				'zh_Hant@alt=long' => 'cinese mandarino tradizionale',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'nessun contenuto linguistico',
 				'zza' => 'zaza',

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
 			'Aghb' => 'albanese caucasico',
 			'Arab' => 'arabo',
 			'Arab@alt=variant' => 'arabo-persiano',
 			'Aran' => 'nastaliq',
 			'Armi' => 'aramaico imperiale',
 			'Armn' => 'armeno',
 			'Avst' => 'avestico',
 			'Bali' => 'balinese',
 			'Bamu' => 'bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalese',
 			'Blis' => 'simboli bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'buginese',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'sillabario aborigeno canadese unificato',
 			'Cari' => 'carian',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'copto',
 			'Cprt' => 'cipriota',
 			'Cyrl' => 'cirillico',
 			'Cyrs' => 'cirillico antica chiesa slavonica',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'stenografia duployan',
 			'Egyd' => 'egiziano demotico',
 			'Egyh' => 'ieratico egiziano',
 			'Egyp' => 'geroglifici egiziani',
 			'Ethi' => 'etiope',
 			'Geok' => 'kutsuri',
 			'Geor' => 'georgiano',
 			'Glag' => 'glagolitico',
 			'Goth' => 'gotico',
 			'Gran' => 'grantha',
 			'Grek' => 'greco',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han, bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'semplificato',
 			'Hans@alt=stand-alone' => 'han semplificato',
 			'Hant' => 'tradizionale',
 			'Hant@alt=stand-alone' => 'han tradizionale',
 			'Hebr' => 'ebraico',
 			'Hira' => 'hiragana',
 			'Hluw' => 'geroglifici anatolici',
 			'Hmng' => 'pahawn hmong',
 			'Hrkt' => 'katanaka o hiragana',
 			'Hung' => 'antico ungherese',
 			'Inds' => 'indu',
 			'Ital' => 'italico antico',
 			'Jamo' => 'jamo',
 			'Java' => 'javanese',
 			'Jpan' => 'giapponese',
 			'Jurc' => 'jurchen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khojki',
 			'Knda' => 'kannada',
 			'Kore' => 'coreano',
 			'Kpel' => 'Kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'variante fraktur del latino',
 			'Latg' => 'variante gaelica del latino',
 			'Latn' => 'latino',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineare A',
 			'Linb' => 'lineare B',
 			'Lisu' => 'lisu',
 			'Loma' => 'loma',
 			'Lyci' => 'lyci',
 			'Lydi' => 'lydi',
 			'Mand' => 'mandaico',
 			'Mani' => 'manicheo',
 			'Maya' => 'geroglifici maya',
 			'Mend' => 'mende',
 			'Merc' => 'corsivo meroitico',
 			'Mero' => 'meroitico',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolo',
 			'Moon' => 'moon',
 			'Mroo' => 'mro',
 			'Mtei' => 'meetei mayek',
 			'Mymr' => 'birmano',
 			'Narb' => 'arabo settentrionale antico',
 			'Nbat' => 'nabateo',
 			'Nkgb' => 'geba naxi',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nushu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osma' => 'osmanya',
 			'Palm' => 'palmireno',
 			'Perm' => 'permico antico',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi delle iscrizioni',
 			'Phlp' => 'pahlavi psalter',
 			'Phlv' => 'pahlavi book',
 			'Phnx' => 'fenicio',
 			'Plrd' => 'fonetica di pollard',
 			'Prti' => 'partico delle iscrizioni',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runico',
 			'Samr' => 'samaritano',
 			'Sara' => 'sarati',
 			'Sarb' => 'arabo meridionale antico',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'linguaggio dei segni',
 			'Shaw' => 'shaviano',
 			'Shrd' => 'sharada',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'singalese',
 			'Sora' => 'sora sompeng',
 			'Sund' => 'sundanese',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siriaco',
 			'Syre' => 'siriaco estrangelo',
 			'Syrj' => 'siriaco occidentale',
 			'Syrn' => 'siriaco orientale',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue',
 			'Taml' => 'tamil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandese',
 			'Tibt' => 'tibetano',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugarita',
 			'Vaii' => 'vai',
 			'Visp' => 'alfabeto visivo',
 			'Wara' => 'varang kshiti',
 			'Wole' => 'woleai',
 			'Xpeo' => 'persiano antico',
 			'Xsux' => 'sumero-accadiano cuneiforme',
 			'Yiii' => 'yi',
 			'Zinh' => 'ereditato',
 			'Zmth' => 'notazione matematica',
 			'Zsye' => 'emoji',
 			'Zsym' => 'simboli',
 			'Zxxx' => 'non scritto',
 			'Zyyy' => 'comune',
 			'Zzzz' => 'scrittura sconosciuta',

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
			'001' => 'Mondo',
 			'002' => 'Africa',
 			'003' => 'Nord America',
 			'005' => 'America del Sud',
 			'009' => 'Oceania',
 			'011' => 'Africa occidentale',
 			'013' => 'America Centrale',
 			'014' => 'Africa orientale',
 			'015' => 'Nordafrica',
 			'017' => 'Africa centrale',
 			'018' => 'Africa del Sud',
 			'019' => 'Americhe',
 			'021' => 'America del Nord',
 			'029' => 'Caraibi',
 			'030' => 'Asia orientale',
 			'034' => 'Asia del Sud',
 			'035' => 'Sud-est asiatico',
 			'039' => 'Europa meridionale',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Regione micronesiana',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia centrale',
 			'145' => 'Asia occidentale',
 			'150' => 'Europa',
 			'151' => 'Europa orientale',
 			'154' => 'Europa settentrionale',
 			'155' => 'Europa occidentale',
 			'202' => 'Africa subsahariana',
 			'419' => 'America Latina',
 			'AC' => 'Isola Ascensione',
 			'AD' => 'Andorra',
 			'AE' => 'Emirati Arabi Uniti',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua e Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartide',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americane',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Isole Åland',
 			'AZ' => 'Azerbaigian',
 			'BA' => 'Bosnia ed Erzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgio',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caraibi Olandesi',
 			'BR' => 'Brasile',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Isola Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorussia',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Isole Cocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'Congo (RDC)',
 			'CF' => 'Repubblica Centrafricana',
 			'CG' => 'Congo-Brazzaville',
 			'CG@alt=variant' => 'Congo (Repubblica)',
 			'CH' => 'Svizzera',
 			'CI' => 'Costa d’Avorio',
 			'CI@alt=variant' => 'Côte d’Ivoire',
 			'CK' => 'Isole Cook',
 			'CL' => 'Cile',
 			'CM' => 'Camerun',
 			'CN' => 'Cina',
 			'CO' => 'Colombia',
 			'CP' => 'Isola di Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Capo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Isola Christmas',
 			'CY' => 'Cipro',
 			'CZ' => 'Cechia',
 			'CZ@alt=variant' => 'Repubblica Ceca',
 			'DE' => 'Germania',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Gibuti',
 			'DK' => 'Danimarca',
 			'DM' => 'Dominica',
 			'DO' => 'Repubblica Dominicana',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta e Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egitto',
 			'EH' => 'Sahara Occidentale',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Unione europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Figi',
 			'FK' => 'Isole Falkland',
 			'FK@alt=variant' => 'Isole Falkland (Isole Malvine)',
 			'FM' => 'Micronesia',
 			'FO' => 'Isole Fær Øer',
 			'FR' => 'Francia',
 			'GA' => 'Gabon',
 			'GB' => 'Regno Unito',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana Francese',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibilterra',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinea Equatoriale',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia del Sud e Sandwich Australi',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'RAS di Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Isole Heard e McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croazia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungheria',
 			'IC' => 'Isole Canarie',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israele',
 			'IM' => 'Isola di Man',
 			'IN' => 'India',
 			'IO' => 'Territorio Britannico dell’Oceano Indiano',
 			'IO@alt=chagos' => 'Arcipelago Chagos',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Islanda',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Giamaica',
 			'JO' => 'Giordania',
 			'JP' => 'Giappone',
 			'KE' => 'Kenya',
 			'KG' => 'Kirghizistan',
 			'KH' => 'Cambogia',
 			'KI' => 'Kiribati',
 			'KM' => 'Comore',
 			'KN' => 'Saint Kitts e Nevis',
 			'KP' => 'Corea del Nord',
 			'KR' => 'Corea del Sud',
 			'KW' => 'Kuwait',
 			'KY' => 'Isole Cayman',
 			'KZ' => 'Kazakistan',
 			'LA' => 'Laos',
 			'LB' => 'Libano',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Lussemburgo',
 			'LV' => 'Lettonia',
 			'LY' => 'Libia',
 			'MA' => 'Marocco',
 			'MC' => 'Monaco',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Isole Marshall',
 			'MK' => 'Macedonia del Nord',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'RAS di Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isole Marianne Settentrionali',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldive',
 			'MW' => 'Malawi',
 			'MX' => 'Messico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambico',
 			'NA' => 'Namibia',
 			'NC' => 'Nuova Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Isola Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Paesi Bassi',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nuova Zelanda',
 			'NZ@alt=variant' => 'Nuova Zelanda (Aotearoa)',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Perù',
 			'PF' => 'Polinesia Francese',
 			'PG' => 'Papua Nuova Guinea',
 			'PH' => 'Filippine',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'Saint-Pierre e Miquelon',
 			'PN' => 'Isole Pitcairn',
 			'PR' => 'Portorico',
 			'PS' => 'Territori Palestinesi',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portogallo',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceania lontana',
 			'RE' => 'Riunione',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Isole Salomone',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudan',
 			'SE' => 'Svezia',
 			'SG' => 'Singapore',
 			'SH' => 'Sant’Elena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard e Jan Mayen',
 			'SK' => 'Slovacchia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Sud Sudan',
 			'ST' => 'São Tomé e Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Regno di Eswatini',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Isole Turks e Caicos',
 			'TD' => 'Ciad',
 			'TF' => 'Terre Australi Francesi',
 			'TG' => 'Togo',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tagikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Est',
 			'TL@alt=variant' => 'Timor Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TR@alt=variant' => 'Türkiye',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Isole Minori Esterne degli Stati Uniti',
 			'UN' => 'Nazioni Unite',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Stati Uniti',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Città del Vaticano',
 			'VC' => 'Saint Vincent e Grenadine',
 			'VE' => 'Venezuela',
 			'VG' => 'Isole Vergini Britanniche',
 			'VI' => 'Isole Vergini Americane',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis e Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Pseudo-accenti',
 			'XB' => 'Pseudo-bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudafrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Regione sconosciuta',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia tradizionale tedesca',
 			'1994' => 'ortografia resiana standard',
 			'1996' => 'ortografia tedesca del 1996',
 			'1606NICT' => 'francese medio-tardo fino al 1606',
 			'1694ACAD' => 'primo francese moderno',
 			'1959ACAD' => 'accademico',
 			'ALALC97' => 'romanizzazione di ALA-LC, versione 1997',
 			'ALUKU' => 'dialetto aluku',
 			'AREVELA' => 'armeno orientale',
 			'AREVMDA' => 'armeno occidentale',
 			'BAKU1926' => 'alfabeto latino altaico unificato',
 			'BISKE' => 'dialetto San Giorgio/Bila',
 			'BOHORIC' => 'alfabeto bohorič',
 			'BOONT' => 'boontling',
 			'DAJNKO' => 'alfabeto Dajnko',
 			'EMODENG' => 'primo inglese moderno',
 			'FONIPA' => 'alfabeto fonetico internazionale IPA',
 			'FONUPA' => 'alfabeto fonetico uralico UPA',
 			'HEPBURN' => 'romanizzazione Hepburn',
 			'KKCOR' => 'ortografia comune',
 			'KSCOR' => 'ortografia standard',
 			'LIPAW' => 'dialetto resiano di Lipovaz',
 			'METELKO' => 'alfabeto Metelko',
 			'MONOTON' => 'monotonico',
 			'NDYUKA' => 'dialetto Ndyuka',
 			'NEDIS' => 'dialetto del Natisone',
 			'NJIVA' => 'dialetto Gniva/Njiva',
 			'NULIK' => 'volapük moderno',
 			'OSOJS' => 'dialetto Oseacco/Osojane',
 			'PAMAKA' => 'dialetto Pamaka',
 			'PINYIN' => 'romanizzazione Pinyin',
 			'POLYTON' => 'politonico',
 			'POSIX' => 'computer',
 			'REVISED' => 'ortografia revisionata',
 			'RIGIK' => 'Volapük classico',
 			'ROZAJ' => 'resiano',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'inglese scozzese standard',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'dialetto Stolvizza/Solbica',
 			'TARASK' => 'ortografia taraskievica',
 			'UCCOR' => 'ortografia unificata',
 			'UCRCOR' => 'ortografia rivista unificata',
 			'VALENCIA' => 'valenziano',
 			'WADEGILE' => 'romanizzazione Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Calendario',
 			'cf' => 'Formato valuta',
 			'colalternate' => 'Ordinamento Ignora simboli',
 			'colbackwards' => 'Ordinamento Accento capovolto',
 			'colcasefirst' => 'Ordinamento Maiuscole/Minuscole',
 			'colcaselevel' => 'Ordinamento Distinzione fra maiuscole e minuscole',
 			'collation' => 'Ordinamento',
 			'colnormalization' => 'Ordinamento normalizzato',
 			'colnumeric' => 'Ordinamento numerico',
 			'colstrength' => 'Sicurezza ordinamento',
 			'currency' => 'Valuta',
 			'hc' => 'Sistema orario (12 o 24 ore)',
 			'lb' => 'Tipo di interruzione di riga',
 			'ms' => 'Sistema di misurazione',
 			'numbers' => 'Numeri',
 			'timezone' => 'Fuso orario',
 			'va' => 'Variante lingua',
 			'x' => 'Uso privato',

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
 				'buddhist' => q{Calendario buddista},
 				'chinese' => q{Calendario cinese},
 				'coptic' => q{Calendario copto},
 				'dangi' => q{Calendario dangi},
 				'ethiopic' => q{Calendario etiope},
 				'ethiopic-amete-alem' => q{Calendario etiope Amete Alem},
 				'gregorian' => q{Calendario gregoriano},
 				'hebrew' => q{Calendario ebraico},
 				'indian' => q{calendario nazionale indiano},
 				'islamic' => q{Calendario Hijri},
 				'islamic-civil' => q{Calendario Hijri (tabulare, epoca civile)},
 				'islamic-rgsa' => q{Calendario islamico (Arabia Saudita, osservazione)},
 				'islamic-tbla' => q{Calendario islamico (tabulare, era astronomica)},
 				'islamic-umalqura' => q{Calendario Hijri (Umm al-Qura)},
 				'iso8601' => q{Calendario ISO-8601},
 				'japanese' => q{Calendario giapponese},
 				'persian' => q{Calendario persiano},
 				'roc' => q{Calendario minguo},
 			},
 			'cf' => {
 				'account' => q{Formato valuta contabile},
 				'standard' => q{Formato valuta standard},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordina simboli},
 				'shifted' => q{Ordina ignorando i simboli},
 			},
 			'colbackwards' => {
 				'no' => q{Ordina accenti normalmente},
 				'yes' => q{Ordina accenti capovolti},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ordina prima lettere minuscole},
 				'no' => q{Ordina lettere maiuscole/minuscole normalmente},
 				'upper' => q{Ordina prima lettere minuscole},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordina senza distinzione tra maiuscole e minuscole},
 				'yes' => q{Ordina distinzione tra maiuscole e minuscole},
 			},
 			'collation' => {
 				'big5han' => q{Ordinamento Cinese tradizionale - Big5},
 				'compat' => q{Ordinamento precedente, per compatibilità},
 				'dictionary' => q{Ordinamento dizionario},
 				'ducet' => q{Ordinamento Unicode predefinito},
 				'gb2312han' => q{Ordinamento Cinese semplificato - GB2312},
 				'phonebook' => q{Ordinamento Elenco telefonico},
 				'phonetic' => q{Ordinamento fonetico},
 				'pinyin' => q{Ordinamento pinyin},
 				'search' => q{Ricerca generica},
 				'searchjl' => q{Cerca per consonante hangul iniziale},
 				'standard' => q{Ordinamento standard},
 				'stroke' => q{Ordinamento tratti},
 				'traditional' => q{Ordinamento tradizionale},
 				'unihan' => q{Ordinamento tratti radicali},
 				'zhuyin' => q{Ordinamento Zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Ordina senza normalizzazione},
 				'yes' => q{Ordina Unicode normalizzato},
 			},
 			'colnumeric' => {
 				'no' => q{Ordina cifre individualmente},
 				'yes' => q{Ordina cifre numericamente},
 			},
 			'colstrength' => {
 				'identical' => q{Ordina tutto},
 				'primary' => q{Ordina solo lettere di base},
 				'quaternary' => q{Ordina accenti/lettere/larghezza/Kana},
 				'secondary' => q{Ordina accenti},
 				'tertiary' => q{Ordina accenti/lettere/larghezza},
 			},
 			'd0' => {
 				'fwidth' => q{Larghezza intera},
 				'hwidth' => q{Metà larghezza},
 				'npinyin' => q{Numerica},
 			},
 			'hc' => {
 				'h11' => q{Sistema orario a 12 ore (0–11)},
 				'h12' => q{Sistema orario a 12 ore (1–12)},
 				'h23' => q{Sistema orario a 24 ore (0–23)},
 				'h24' => q{Sistema orario a 24 ore (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Interruzione di riga facoltativa},
 				'normal' => q{Interruzione di riga normale},
 				'strict' => q{Interruzione di riga forzata},
 			},
 			'm0' => {
 				'bgn' => q{BGN},
 				'ungegn' => q{UNGEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistema metrico},
 				'uksystem' => q{Sistema imperiale britannico},
 				'ussystem' => q{Sistema consuetudinario statunitense},
 			},
 			'numbers' => {
 				'arab' => q{Cifre indo-arabe},
 				'arabext' => q{Cifre indo-arabe estese},
 				'armn' => q{Numeri armeni},
 				'armnlow' => q{Numeri armeni minuscoli},
 				'bali' => q{Cifre balinesi},
 				'beng' => q{Cifre bengalesi},
 				'brah' => q{Cifre brahmi},
 				'cakm' => q{Cifre chakma},
 				'cham' => q{Cifre cham},
 				'deva' => q{Cifre devanagari},
 				'ethi' => q{Numeri etiopi},
 				'finance' => q{Numeri finanziari},
 				'fullwide' => q{Cifre a larghezza intera},
 				'geor' => q{Numeri georgiani},
 				'grek' => q{Numeri greci},
 				'greklow' => q{Numeri greci minuscoli},
 				'gujr' => q{Cifre gujarati},
 				'guru' => q{Cifre gurmukhi},
 				'hanidec' => q{Numeri decimali cinesi},
 				'hans' => q{Numeri in cinese semplificato},
 				'hansfin' => q{Numeri finanziari in cinese semplificato},
 				'hant' => q{Numeri in cinese tradizionale},
 				'hantfin' => q{Numeri finanziari in cinese tradizionale},
 				'hebr' => q{Numeri ebraici},
 				'java' => q{Cifre giavanesi},
 				'jpan' => q{Numeri giapponesi},
 				'jpanfin' => q{Numeri finanziari giapponesi},
 				'kali' => q{Cifre Kayah Li},
 				'khmr' => q{Cifre khmer},
 				'knda' => q{Cifre kannada},
 				'lana' => q{Cifre tai tham hora},
 				'lanatham' => q{Cifre tai tham tham},
 				'laoo' => q{Cifre lao},
 				'latn' => q{Cifre occidentali},
 				'lepc' => q{Cifre lepcha},
 				'limb' => q{Cifre limbu},
 				'mathmono' => q{Cifre matematiche a spaziatura fissa},
 				'mlym' => q{Cifre malayalam},
 				'mong' => q{Numeri mongoli},
 				'mtei' => q{Cifre Meetei Mayek},
 				'mymr' => q{Cifre birmane},
 				'mymrshan' => q{Cifre shan birmane},
 				'native' => q{Cifre native},
 				'nkoo' => q{Cifre N’Ko},
 				'olck' => q{Cifre Ol Chiki},
 				'orya' => q{Cifre oriya},
 				'osma' => q{Cifre osmanya},
 				'roman' => q{Numeri romani},
 				'romanlow' => q{Numeri romani minuscoli},
 				'saur' => q{Cifre saurashtra},
 				'shrd' => q{Cifre sharada},
 				'sora' => q{Cifre Sora Sompeng},
 				'sund' => q{Cifre sundanesi},
 				'takr' => q{Cifre takri},
 				'talu' => q{Cifre nuovo Tai Lue},
 				'taml' => q{Numeri tamil tradizionali},
 				'tamldec' => q{Cifre tamil},
 				'telu' => q{Cifre telugu},
 				'thai' => q{Cifre thailandesi},
 				'tibt' => q{Cifre tibetane},
 				'traditional' => q{Numeri tradizionali},
 				'vaii' => q{Cifre Vai},
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
			'metric' => q{metrico},
 			'UK' => q{britannico},
 			'US' => q{USA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lingua: {0}',
 			'script' => 'Scrittura: {0}',
 			'region' => 'Regione: {0}',

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
			auxiliary => qr{[ªáâåäã æ ç êë íîï ñ ºóôöõø œ ß úûü ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aà b c d eéè f g h iì j k l m n oò p q r s t uù v w x y z]},
			punctuation => qr{[\- ‑ — , ; \: ! ? . … '’ "“” « » ( ) \[ \] \{ \} @ /]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
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
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punti cardinali),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punti cardinali),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deca{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(etto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(etto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(ronna{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(chilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(chilo{0}),
					},
					# Long Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mega{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'1' => q(feminine),
						'one' => q({0} forza g),
						'other' => q({0} forza g),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'one' => q({0} forza g),
						'other' => q({0} forza g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metri al secondo quadrato),
						'one' => q({0} metro al secondo quadrato),
						'other' => q({0} metri al secondo quadrato),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(metri al secondo quadrato),
						'one' => q({0} metro al secondo quadrato),
						'other' => q({0} metri al secondo quadrato),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(masculine),
						'name' => q(primi d’arco),
						'one' => q({0} primo d’arco),
						'other' => q({0} primi d’arco),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(masculine),
						'name' => q(primi d’arco),
						'one' => q({0} primo d’arco),
						'other' => q({0} primi d’arco),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(masculine),
						'name' => q(secondi d’arco),
						'one' => q({0} secondo d’arco),
						'other' => q({0} secondi d’arco),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(masculine),
						'name' => q(secondi d’arco),
						'one' => q({0} secondo d’arco),
						'other' => q({0} secondi d’arco),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(masculine),
						'name' => q(gradi),
						'one' => q({0} grado),
						'other' => q({0} gradi),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'name' => q(gradi),
						'one' => q({0} grado),
						'other' => q({0} gradi),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'name' => q(radianti),
						'one' => q({0} radiante),
						'other' => q({0} radianti),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'name' => q(radianti),
						'one' => q({0} radiante),
						'other' => q({0} radianti),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'name' => q(rivoluzioni),
						'one' => q({0} rivoluzione),
						'other' => q({0} rivoluzioni),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'name' => q(rivoluzioni),
						'one' => q({0} rivoluzione),
						'other' => q({0} rivoluzioni),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(masculine),
						'one' => q({0} acro),
						'other' => q({0} acri),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(masculine),
						'one' => q({0} acro),
						'other' => q({0} acri),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(masculine),
						'one' => q({0} ettaro),
						'other' => q({0} ettari),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(masculine),
						'one' => q({0} ettaro),
						'other' => q({0} ettari),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri quadrati),
						'one' => q({0} centimetro quadrato),
						'other' => q({0} centimetri quadrati),
						'per' => q({0} per centimetro quadrato),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri quadrati),
						'one' => q({0} centimetro quadrato),
						'other' => q({0} centimetri quadrati),
						'per' => q({0} per centimetro quadrato),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'one' => q({0} piede quadrato),
						'other' => q({0} piedi quadrati),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'one' => q({0} piede quadrato),
						'other' => q({0} piedi quadrati),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pollici quadrati),
						'one' => q({0} pollice quadrato),
						'other' => q({0} pollici quadrati),
						'per' => q({0} per pollice quadrato),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pollici quadrati),
						'one' => q({0} pollice quadrato),
						'other' => q({0} pollici quadrati),
						'per' => q({0} per pollice quadrato),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri quadrati),
						'one' => q({0} chilometro quadrato),
						'other' => q({0} chilometri quadrati),
						'per' => q({0} per chilometro quadrato),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri quadrati),
						'one' => q({0} chilometro quadrato),
						'other' => q({0} chilometri quadrati),
						'per' => q({0} per chilometro quadrato),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(metri quadrati),
						'one' => q({0} metro quadrato),
						'other' => q({0} metri quadrati),
						'per' => q({0} per metro quadrato),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(metri quadrati),
						'one' => q({0} metro quadrato),
						'other' => q({0} metri quadrati),
						'per' => q({0} per metro quadrato),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(feminine),
						'name' => q(miglia quadrate),
						'one' => q({0} miglio quadrato),
						'other' => q({0} miglia quadrate),
						'per' => q({0} per miglio quadrato),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(feminine),
						'name' => q(miglia quadrate),
						'one' => q({0} miglio quadrato),
						'other' => q({0} miglia quadrate),
						'per' => q({0} per miglio quadrato),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iarde quadrate),
						'one' => q({0} iarda quadrata),
						'other' => q({0} iarde quadrate),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iarde quadrate),
						'one' => q({0} iarda quadrata),
						'other' => q({0} iarde quadrate),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(masculine),
						'name' => q(elementi),
						'one' => q({0} elemento),
						'other' => q({0} elementi),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(masculine),
						'name' => q(elementi),
						'one' => q({0} elemento),
						'other' => q({0} elementi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'name' => q(carati),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'name' => q(carati),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(milligrammi per decilitro),
						'one' => q({0} milligrammo per decilitro),
						'other' => q({0} milligrammi per decilitro),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(masculine),
						'name' => q(milligrammi per decilitro),
						'one' => q({0} milligrammo per decilitro),
						'other' => q({0} milligrammi per decilitro),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(feminine),
						'name' => q(millimoli per litro),
						'one' => q({0} millimole per litro),
						'other' => q({0} millimoli per litro),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(feminine),
						'name' => q(millimoli per litro),
						'one' => q({0} millimole per litro),
						'other' => q({0} millimoli per litro),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(feminine),
						'name' => q(moli),
						'one' => q({0} mole),
						'other' => q({0} moli),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(feminine),
						'name' => q(moli),
						'one' => q({0} mole),
						'other' => q({0} moli),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'name' => q(percentuale),
						'one' => q({0} percento),
						'other' => q({0} percento),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'name' => q(percentuale),
						'one' => q({0} percento),
						'other' => q({0} percento),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'name' => q(per mille),
						'one' => q({0} per mille),
						'other' => q({0} per mille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'name' => q(parti per milione),
						'one' => q({0} parte per milione),
						'other' => q({0} parti per milione),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'name' => q(parti per milione),
						'one' => q({0} parte per milione),
						'other' => q({0} parti per milione),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'name' => q(punto base),
						'one' => q({0} punto base),
						'other' => q({0} punti base),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'name' => q(punto base),
						'one' => q({0} punto base),
						'other' => q({0} punti base),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(feminine),
						'name' => q(parti per miliardo),
						'one' => q({0} parte per miliardo),
						'other' => q({0} parti per miliardo),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(feminine),
						'name' => q(parti per miliardo),
						'one' => q({0} parte per miliardo),
						'other' => q({0} parti per miliardo),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri per 100 chilometri),
						'one' => q({0} litro per 100 chilometri),
						'other' => q({0} litri per 100 chilometri),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri per 100 chilometri),
						'one' => q({0} litro per 100 chilometri),
						'other' => q({0} litri per 100 chilometri),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri per chilometro),
						'one' => q({0} litro per chilometro),
						'other' => q({0} litri per chilometro),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(litri per chilometro),
						'one' => q({0} litro per chilometro),
						'other' => q({0} litri per chilometro),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(miglia per gallone),
						'one' => q({0} miglio per gallone),
						'other' => q({0} miglia per gallone),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(feminine),
						'name' => q(miglia per gallone),
						'one' => q({0} miglio per gallone),
						'other' => q({0} miglia per gallone),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(miglia per gallone imperiale),
						'one' => q({0} miglio per gallone imperiale),
						'other' => q({0} miglia per gallone imperiale),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(feminine),
						'name' => q(miglia per gallone imperiale),
						'one' => q({0} miglio per gallone imperiale),
						'other' => q({0} miglia per gallone imperiale),
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
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(masculine),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(masculine),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(masculine),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(masculine),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(masculine),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(masculine),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(masculine),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(masculine),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(masculine),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(masculine),
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(masculine),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(masculine),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(masculine),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(masculine),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(masculine),
						'name' => q(secoli),
						'one' => q({0} secolo),
						'other' => q({0} secoli),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(masculine),
						'name' => q(secoli),
						'one' => q({0} secolo),
						'other' => q({0} secoli),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(masculine),
						'per' => q({0} al giorno),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(masculine),
						'per' => q({0} al giorno),
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
						'1' => q(feminine),
						'name' => q(decadi),
						'one' => q({0} decade),
						'other' => q({0} decadi),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(feminine),
						'name' => q(decadi),
						'one' => q({0} decade),
						'other' => q({0} decadi),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'name' => q(ore),
						'one' => q({0} ora),
						'other' => q({0} ore),
						'per' => q({0} all’ora),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'name' => q(ore),
						'one' => q({0} ora),
						'other' => q({0} ore),
						'per' => q({0} all’ora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(masculine),
						'name' => q(microsecondi),
						'one' => q({0} microsecondo),
						'other' => q({0} microsecondi),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(masculine),
						'name' => q(microsecondi),
						'one' => q({0} microsecondo),
						'other' => q({0} microsecondi),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(masculine),
						'name' => q(millisecondi),
						'one' => q({0} millisecondo),
						'other' => q({0} millisecondi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(masculine),
						'name' => q(millisecondi),
						'one' => q({0} millisecondo),
						'other' => q({0} millisecondi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(masculine),
						'name' => q(minuti),
						'one' => q({0} minuto),
						'other' => q({0} minuti),
						'per' => q({0} al minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(masculine),
						'name' => q(minuti),
						'one' => q({0} minuto),
						'other' => q({0} minuti),
						'per' => q({0} al minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'per' => q({0} al mese),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'per' => q({0} al mese),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanosecondi),
						'one' => q({0} nanosecondo),
						'other' => q({0} nanosecondi),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(masculine),
						'name' => q(nanosecondi),
						'one' => q({0} nanosecondo),
						'other' => q({0} nanosecondi),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(feminine),
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0} a notte),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(feminine),
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0} a notte),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(masculine),
						'name' => q(trimestri),
						'one' => q({0} trimestre),
						'other' => q({0} trimestri),
						'per' => q({0} al trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(masculine),
						'name' => q(trimestri),
						'one' => q({0} trimestre),
						'other' => q({0} trimestri),
						'per' => q({0} al trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(masculine),
						'name' => q(secondi),
						'one' => q({0} secondo),
						'other' => q({0} secondi),
						'per' => q({0} al secondo),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(masculine),
						'name' => q(secondi),
						'one' => q({0} secondo),
						'other' => q({0} secondi),
						'per' => q({0} al secondo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(feminine),
						'one' => q({0} settimana),
						'other' => q({0} settimane),
						'per' => q({0} alla settimana),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(feminine),
						'one' => q({0} settimana),
						'other' => q({0} settimane),
						'per' => q({0} alla settimana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(masculine),
						'per' => q({0} all’anno),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(masculine),
						'per' => q({0} all’anno),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'name' => q(milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'name' => q(milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(unità termiche britanniche),
						'one' => q({0} unità termica britannica),
						'other' => q({0} unità termiche britanniche),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(unità termiche britanniche),
						'one' => q({0} unità termica britannica),
						'other' => q({0} unità termiche britanniche),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'name' => q(calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'name' => q(calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elettronvolt),
						'one' => q({0} elettronvolt),
						'other' => q({0} elettronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elettronvolt),
						'one' => q({0} elettronvolt),
						'other' => q({0} elettronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(feminine),
						'name' => q(Calorie),
						'one' => q({0} Caloria),
						'other' => q({0} Calorie),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(feminine),
						'name' => q(Calorie),
						'one' => q({0} Caloria),
						'other' => q({0} Calorie),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(feminine),
						'name' => q(chilocalorie),
						'one' => q({0} chilocaloria),
						'other' => q({0} chilocalorie),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(feminine),
						'name' => q(chilocalorie),
						'one' => q({0} chilocaloria),
						'other' => q({0} chilocalorie),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(chilowattora),
						'one' => q({0} chilowattora),
						'other' => q({0} chilowattora),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(chilowattora),
						'one' => q({0} chilowattora),
						'other' => q({0} chilowattora),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilowattora per 100 chilometri),
						'one' => q({0} chilowattora per 100 chilometri),
						'other' => q({0} chilowattora per 100 chilometri),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilowattora per 100 chilometri),
						'one' => q({0} chilowattora per 100 chilometri),
						'other' => q({0} chilowattora per 100 chilometri),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libbre-forza),
						'one' => q({0} libbra-forza),
						'other' => q({0} libbre-forza),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libbre-forza),
						'one' => q({0} libbra-forza),
						'other' => q({0} libbre-forza),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(masculine),
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(masculine),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(masculine),
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(masculine),
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'one' => q({0} punto),
						'other' => q({0} punti),
					},
					# Core Unit Identifier
					'dot' => {
						'one' => q({0} punto),
						'other' => q({0} punti),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punti per centimetro),
						'one' => q({0} punto per centimetro),
						'other' => q({0} punti per centimetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punti per centimetro),
						'one' => q({0} punto per centimetro),
						'other' => q({0} punti per centimetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punti per pollice),
						'one' => q({0} punto per pollice),
						'other' => q({0} punti per pollice),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punti per pollice),
						'one' => q({0} punto per pollice),
						'other' => q({0} punti per pollice),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(feminine),
						'name' => q(em tipografica),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(feminine),
						'name' => q(em tipografica),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'name' => q(megapixel),
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'name' => q(megapixel),
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'name' => q(pixel),
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'name' => q(pixel),
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixel per centimetro),
						'one' => q({0} pixel per centimetro),
						'other' => q({0} pixel per centimetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(pixel per centimetro),
						'one' => q({0} pixel per centimetro),
						'other' => q({0} pixel per centimetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel per pollice),
						'one' => q({0} pixel per pollice),
						'other' => q({0} pixel per pollice),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel per pollice),
						'one' => q({0} pixel per pollice),
						'other' => q({0} pixel per pollice),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unità astronomiche),
						'one' => q({0} unità astronomica),
						'other' => q({0} unità astronomiche),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unità astronomiche),
						'one' => q({0} unità astronomica),
						'other' => q({0} unità astronomiche),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri),
						'one' => q({0} centimetro),
						'other' => q({0} centimetri),
						'per' => q({0} per centimetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri),
						'one' => q({0} centimetro),
						'other' => q({0} centimetri),
						'per' => q({0} per centimetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(decimetri),
						'one' => q({0} decimetro),
						'other' => q({0} decimetri),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(decimetri),
						'one' => q({0} decimetro),
						'other' => q({0} decimetri),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(raggi terrestri),
						'one' => q({0} raggio terrestre),
						'other' => q({0} raggi terrestri),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(raggi terrestri),
						'one' => q({0} raggio terrestre),
						'other' => q({0} raggi terrestri),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(braccia),
						'one' => q({0} braccio),
						'other' => q({0} braccia),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(braccia),
						'one' => q({0} braccio),
						'other' => q({0} braccia),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'name' => q(piedi),
						'one' => q({0} piede),
						'other' => q({0} piedi),
						'per' => q({0} per piede),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'name' => q(piedi),
						'one' => q({0} piede),
						'other' => q({0} piedi),
						'per' => q({0} per piede),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(masculine),
						'name' => q(pollici),
						'one' => q({0} pollice),
						'other' => q({0} pollici),
						'per' => q({0} per pollice),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(masculine),
						'name' => q(pollici),
						'one' => q({0} pollice),
						'other' => q({0} pollici),
						'per' => q({0} per pollice),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri),
						'one' => q({0} chilometro),
						'other' => q({0} chilometri),
						'per' => q({0} per chilometro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri),
						'one' => q({0} chilometro),
						'other' => q({0} chilometri),
						'per' => q({0} per chilometro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(anni luce),
						'one' => q({0} anno luce),
						'other' => q({0} anni luce),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(anni luce),
						'one' => q({0} anno luce),
						'other' => q({0} anni luce),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'name' => q(metri),
						'one' => q({0} metro),
						'other' => q({0} metri),
						'per' => q({0} per metro),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'name' => q(metri),
						'one' => q({0} metro),
						'other' => q({0} metri),
						'per' => q({0} per metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(micrometri),
						'one' => q({0} micrometro),
						'other' => q({0} micrometri),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(micrometri),
						'one' => q({0} micrometro),
						'other' => q({0} micrometri),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(feminine),
						'one' => q({0} miglio),
						'other' => q({0} miglia),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(feminine),
						'one' => q({0} miglio),
						'other' => q({0} miglia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(miglia scandinave),
						'one' => q({0} miglio scandinavo),
						'other' => q({0} miglia scandinave),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'name' => q(miglia scandinave),
						'one' => q({0} miglio scandinavo),
						'other' => q({0} miglia scandinave),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(millimetri),
						'one' => q({0} millimetro),
						'other' => q({0} millimetri),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(millimetri),
						'one' => q({0} millimetro),
						'other' => q({0} millimetri),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometri),
						'one' => q({0} nanometro),
						'other' => q({0} nanometri),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometri),
						'one' => q({0} nanometro),
						'other' => q({0} nanometri),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(miglia nautiche),
						'one' => q({0} miglio nautico),
						'other' => q({0} miglia nautiche),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(miglia nautiche),
						'one' => q({0} miglio nautico),
						'other' => q({0} miglia nautiche),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(masculine),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(masculine),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(picometri),
						'one' => q({0} picometro),
						'other' => q({0} picometri),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(picometri),
						'one' => q({0} picometro),
						'other' => q({0} picometri),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(masculine),
						'name' => q(punti tipografici),
						'one' => q({0} punto tipografico),
						'other' => q({0} punti tipografici),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(masculine),
						'name' => q(punti tipografici),
						'one' => q({0} punto tipografico),
						'other' => q({0} punti tipografici),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'name' => q(raggi solari),
						'one' => q({0} raggio solare),
						'other' => q({0} raggi solari),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'name' => q(raggi solari),
						'one' => q({0} raggio solare),
						'other' => q({0} raggi solari),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(feminine),
						'one' => q({0} iarda),
						'other' => q({0} iarde),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(feminine),
						'one' => q({0} iarda),
						'other' => q({0} iarde),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'name' => q(candele),
						'one' => q({0} candela),
						'other' => q({0} candele),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'name' => q(candele),
						'one' => q({0} candela),
						'other' => q({0} candele),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(masculine),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(masculine),
						'name' => q(lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(masculine),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosità solari),
						'one' => q({0} luminosità solare),
						'other' => q({0} luminosità solari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(feminine),
						'name' => q(luminosità solari),
						'one' => q({0} luminosità solare),
						'other' => q({0} luminosità solari),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(masculine),
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(masculine),
						'name' => q(dalton),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(feminine),
						'name' => q(masse terrestri),
						'one' => q({0} massa terrestre),
						'other' => q({0} masse terrestri),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(feminine),
						'name' => q(masse terrestri),
						'one' => q({0} massa terrestre),
						'other' => q({0} masse terrestri),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(masculine),
						'name' => q(grani),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(masculine),
						'name' => q(grani),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(masculine),
						'one' => q({0} grammo),
						'other' => q({0} grammi),
						'per' => q({0} per grammo),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(masculine),
						'one' => q({0} grammo),
						'other' => q({0} grammi),
						'per' => q({0} per grammo),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(masculine),
						'name' => q(chilogrammi),
						'one' => q({0} chilogrammo),
						'other' => q({0} chilogrammi),
						'per' => q({0} per chilogrammo),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(masculine),
						'name' => q(chilogrammi),
						'one' => q({0} chilogrammo),
						'other' => q({0} chilogrammi),
						'per' => q({0} per chilogrammo),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(masculine),
						'name' => q(microgrammi),
						'one' => q({0} microgrammo),
						'other' => q({0} microgrammi),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(masculine),
						'name' => q(microgrammi),
						'one' => q({0} microgrammo),
						'other' => q({0} microgrammi),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(masculine),
						'name' => q(milligrammi),
						'one' => q({0} milligrammo),
						'other' => q({0} milligrammi),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(masculine),
						'name' => q(milligrammi),
						'one' => q({0} milligrammo),
						'other' => q({0} milligrammi),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(feminine),
						'name' => q(once),
						'one' => q({0} oncia),
						'other' => q({0} once),
						'per' => q({0} per oncia),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(feminine),
						'name' => q(once),
						'one' => q({0} oncia),
						'other' => q({0} once),
						'per' => q({0} per oncia),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(once troy),
						'one' => q({0} oncia troy),
						'other' => q({0} once troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(once troy),
						'one' => q({0} oncia troy),
						'other' => q({0} once troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(feminine),
						'name' => q(libbre),
						'one' => q({0} libbra),
						'other' => q({0} libbre),
						'per' => q({0} per libbra),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(feminine),
						'name' => q(libbre),
						'one' => q({0} libbra),
						'other' => q({0} libbre),
						'per' => q({0} per libbra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(feminine),
						'name' => q(masse solari),
						'one' => q({0} massa solare),
						'other' => q({0} masse solari),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(feminine),
						'name' => q(masse solari),
						'one' => q({0} massa solare),
						'other' => q({0} masse solari),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonnellate),
						'one' => q({0} tonnellata),
						'other' => q({0} tonnellate),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonnellate),
						'one' => q({0} tonnellata),
						'other' => q({0} tonnellate),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'name' => q(tonnellate metriche),
						'one' => q({0} tonnellata metrica),
						'other' => q({0} tonnellate metriche),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'name' => q(tonnellate metriche),
						'one' => q({0} tonnellata metrica),
						'other' => q({0} tonnellate metriche),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} al {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} al {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(masculine),
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cavalli vapore),
						'one' => q({0} cavallo vapore),
						'other' => q({0} cavalli vapore),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cavalli vapore),
						'one' => q({0} cavallo vapore),
						'other' => q({0} cavalli vapore),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(masculine),
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(masculine),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(masculine),
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(masculine),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(masculine),
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(masculine),
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} quadri),
						'one' => q({0} quadrato),
						'other' => q({0} quadrati),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} quadri),
						'one' => q({0} quadrato),
						'other' => q({0} quadrati),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} cubi),
						'one' => q({0} cubo),
						'other' => q({0} cubi),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} cubi),
						'one' => q({0} cubo),
						'other' => q({0} cubi),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfere),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfere),
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
						'name' => q(ettopascal),
						'one' => q({0} ettopascal),
						'other' => q({0} ettopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(ettopascal),
						'one' => q({0} ettopascal),
						'other' => q({0} ettopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pollici di mercurio),
						'one' => q({0} pollice di mercurio),
						'other' => q({0} pollici di mercurio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pollici di mercurio),
						'one' => q({0} pollice di mercurio),
						'other' => q({0} pollici di mercurio),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(chilopascal),
						'one' => q({0} chilopascal),
						'other' => q({0} chilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(chilopascal),
						'one' => q({0} chilopascal),
						'other' => q({0} chilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(masculine),
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(masculine),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(masculine),
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(millimetri di mercurio),
						'one' => q({0} millimetro di mercurio),
						'other' => q({0} millimetri di mercurio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(millimetri di mercurio),
						'one' => q({0} millimetro di mercurio),
						'other' => q({0} millimetri di mercurio),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(masculine),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(masculine),
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libbre per pollice quadrato),
						'one' => q({0} libbra per pollice quadrato),
						'other' => q({0} libbre per pollice quadrato),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libbre per pollice quadrato),
						'one' => q({0} libbra per pollice quadrato),
						'other' => q({0} libbre per pollice quadrato),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(chilometri orari),
						'one' => q({0} chilometro orario),
						'other' => q({0} chilometri orari),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(chilometri orari),
						'one' => q({0} chilometro orario),
						'other' => q({0} chilometri orari),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(nodi),
						'one' => q({0} nodo),
						'other' => q({0} nodi),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(nodi),
						'one' => q({0} nodo),
						'other' => q({0} nodi),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'1' => q(feminine),
						'one' => q({0} alla velocità della luce),
						'other' => q({0} alla velocità della luce),
					},
					# Core Unit Identifier
					'light-speed' => {
						'1' => q(feminine),
						'one' => q({0} alla velocità della luce),
						'other' => q({0} alla velocità della luce),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metri al secondo),
						'one' => q({0} metro al secondo),
						'other' => q({0} metri al secondo),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(metri al secondo),
						'one' => q({0} metro al secondo),
						'other' => q({0} metri al secondo),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(miglia all’ora),
						'one' => q({0} miglio all’ora),
						'other' => q({0} miglia all’ora),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(feminine),
						'name' => q(miglia all’ora),
						'one' => q({0} miglio all’ora),
						'other' => q({0} miglia all’ora),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(gradi Celsius),
						'one' => q({0} grado Celsius),
						'other' => q({0} gradi Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(gradi Celsius),
						'one' => q({0} grado Celsius),
						'other' => q({0} gradi Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(masculine),
						'name' => q(gradi Fahrenheit),
						'one' => q({0} grado Fahrenheit),
						'other' => q({0} gradi Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(masculine),
						'name' => q(gradi Fahrenheit),
						'one' => q({0} grado Fahrenheit),
						'other' => q({0} gradi Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'name' => q(gradi),
						'one' => q({0} grado),
						'other' => q({0} gradi),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'name' => q(gradi),
						'one' => q({0} grado),
						'other' => q({0} gradi),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(newton metri),
						'one' => q({0} newton metro),
						'other' => q({0} newton metri),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(newton metri),
						'one' => q({0} newton metro),
						'other' => q({0} newton metri),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libbre-forza piede),
						'one' => q({0} libbra-forza piede),
						'other' => q({0} libbre-forza piede),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libbre-forza piede),
						'one' => q({0} libbra-forza piede),
						'other' => q({0} libbre-forza piede),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'1' => q(masculine),
						'name' => q(piedi acro),
						'one' => q({0} piede acro),
						'other' => q({0} piedi acro),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'1' => q(masculine),
						'name' => q(piedi acro),
						'one' => q({0} piede acro),
						'other' => q({0} piedi acro),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'1' => q(masculine),
						'name' => q(barili),
						'one' => q({0} barile),
						'other' => q({0} barili),
					},
					# Core Unit Identifier
					'barrel' => {
						'1' => q(masculine),
						'name' => q(barili),
						'one' => q({0} barile),
						'other' => q({0} barili),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} staio),
						'other' => q({0} staia),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} staio),
						'other' => q({0} staia),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitri),
						'one' => q({0} centilitro),
						'other' => q({0} centilitri),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(centilitri),
						'one' => q({0} centilitro),
						'other' => q({0} centilitri),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri cubi),
						'one' => q({0} centimetro cubo),
						'other' => q({0} centimetri cubi),
						'per' => q({0} per centimetro cubo),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimetri cubi),
						'one' => q({0} centimetro cubo),
						'other' => q({0} centimetri cubi),
						'per' => q({0} per centimetro cubo),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(masculine),
						'name' => q(piedi cubi),
						'one' => q({0} piede cubo),
						'other' => q({0} piedi cubi),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(piedi cubi),
						'one' => q({0} piede cubo),
						'other' => q({0} piedi cubi),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'1' => q(masculine),
						'name' => q(pollici cubi),
						'one' => q({0} pollice cubo),
						'other' => q({0} pollici cubi),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'1' => q(masculine),
						'name' => q(pollici cubi),
						'one' => q({0} pollice cubo),
						'other' => q({0} pollici cubi),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri cubi),
						'one' => q({0} chilometro cubo),
						'other' => q({0} chilometri cubi),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(chilometri cubi),
						'one' => q({0} chilometro cubo),
						'other' => q({0} chilometri cubi),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metri cubi),
						'one' => q({0} metro cubo),
						'other' => q({0} metri cubi),
						'per' => q({0} per metro cubo),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(metri cubi),
						'one' => q({0} metro cubo),
						'other' => q({0} metri cubi),
						'per' => q({0} per metro cubo),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(feminine),
						'name' => q(miglia cubiche),
						'one' => q({0} miglio cubo),
						'other' => q({0} miglia cubiche),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(feminine),
						'name' => q(miglia cubiche),
						'one' => q({0} miglio cubo),
						'other' => q({0} miglia cubiche),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iarde cubiche),
						'one' => q({0} iarda cubica),
						'other' => q({0} iarde cubiche),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iarde cubiche),
						'one' => q({0} iarda cubica),
						'other' => q({0} iarde cubiche),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(feminine),
						'name' => q(tazze),
						'one' => q({0} tazza),
						'other' => q({0} tazze),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(feminine),
						'name' => q(tazze),
						'one' => q({0} tazza),
						'other' => q({0} tazze),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(feminine),
						'name' => q(tazze metriche),
						'one' => q({0} tazza metrica),
						'other' => q({0} tazze metriche),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(feminine),
						'name' => q(tazze metriche),
						'one' => q({0} tazza metrica),
						'other' => q({0} tazze metriche),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitri),
						'one' => q({0} decilitro),
						'other' => q({0} decilitri),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(decilitri),
						'one' => q({0} decilitro),
						'other' => q({0} decilitri),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(cucchiaini da dessert),
						'one' => q({0} cucchiaino da dessert),
						'other' => q({0} cucchiaini da dessert),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(cucchiaini da dessert),
						'one' => q({0} cucchiaino da dessert),
						'other' => q({0} cucchiaini da dessert),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(cucchiaini da dessert imperiali),
						'one' => q({0} cucchiaino da dessert imperiale),
						'other' => q({0} cucchiaini da dessert imperiali),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(cucchiaini da dessert imperiali),
						'one' => q({0} cucchiaino da dessert imperiale),
						'other' => q({0} cucchiaini da dessert imperiali),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(feminine),
						'name' => q(dramme),
						'one' => q({0} dramma),
						'other' => q({0} dramme),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(feminine),
						'name' => q(dramme),
						'one' => q({0} dramma),
						'other' => q({0} dramme),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(feminine),
						'name' => q(gocce),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(feminine),
						'name' => q(gocce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(once liquide),
						'one' => q({0} oncia liquida),
						'other' => q({0} once liquide),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(feminine),
						'name' => q(once liquide),
						'one' => q({0} oncia liquida),
						'other' => q({0} once liquide),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(once liquide imperiali),
						'one' => q({0} oncia liquida imperiale),
						'other' => q({0} once liquide imperiali),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(feminine),
						'name' => q(once liquide imperiali),
						'one' => q({0} oncia liquida imperiale),
						'other' => q({0} once liquide imperiali),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(masculine),
						'name' => q(galloni),
						'one' => q({0} gallone),
						'other' => q({0} galloni),
						'per' => q({0} per gallone),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(masculine),
						'name' => q(galloni),
						'one' => q({0} gallone),
						'other' => q({0} galloni),
						'per' => q({0} per gallone),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galloni imperiali),
						'one' => q({0} gallone imperiale),
						'other' => q({0} galloni imperiali),
						'per' => q({0} per gallone imperiale),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(galloni imperiali),
						'one' => q({0} gallone imperiale),
						'other' => q({0} galloni imperiali),
						'per' => q({0} per gallone imperiale),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(ettolitri),
						'one' => q({0} ettolitro),
						'other' => q({0} ettolitri),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(ettolitri),
						'one' => q({0} ettolitro),
						'other' => q({0} ettolitri),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'jigger' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(masculine),
						'name' => q(litri),
						'one' => q({0} litro),
						'other' => q({0} litri),
						'per' => q({0} per litro),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'name' => q(litri),
						'one' => q({0} litro),
						'other' => q({0} litri),
						'per' => q({0} per litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitri),
						'one' => q({0} megalitro),
						'other' => q({0} megalitri),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(megalitri),
						'one' => q({0} megalitro),
						'other' => q({0} megalitri),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(millilitri),
						'one' => q({0} millilitro),
						'other' => q({0} millilitri),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(millilitri),
						'one' => q({0} millilitro),
						'other' => q({0} millilitri),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(masculine),
						'name' => q(pizzichi),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(masculine),
						'name' => q(pizzichi),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(feminine),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinte),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(feminine),
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinte),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'name' => q(pinte metriche),
						'one' => q({0} pinta metrica),
						'other' => q({0} pinte metriche),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'name' => q(pinte metriche),
						'one' => q({0} pinta metrica),
						'other' => q({0} pinte metriche),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(masculine),
						'name' => q(quarti),
						'one' => q({0} quarto),
						'other' => q({0} quarti),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(masculine),
						'name' => q(quarti),
						'one' => q({0} quarto),
						'other' => q({0} quarti),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarti imperiali),
						'one' => q({0} quarto imperiale),
						'other' => q({0} quarti imperiali),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(masculine),
						'name' => q(quarti imperiali),
						'one' => q({0} quarto imperiale),
						'other' => q({0} quarti imperiali),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(masculine),
						'name' => q(cucchiai da tavola),
						'one' => q({0} cucchiaio da tavola),
						'other' => q({0} cucchiai da tavola),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(masculine),
						'name' => q(cucchiai da tavola),
						'one' => q({0} cucchiaio da tavola),
						'other' => q({0} cucchiai da tavola),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(masculine),
						'name' => q(cucchiai da tè),
						'one' => q({0} cucchiaio da tè),
						'other' => q({0} cucchiai da tè),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(masculine),
						'name' => q(cucchiai da tè),
						'one' => q({0} cucchiaio da tè),
						'other' => q({0} cucchiai da tè),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0}riv),
						'other' => q({0}riv),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0}riv),
						'other' => q({0}riv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0}dunum),
						'other' => q({0}dunum),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0}dunum),
						'other' => q({0}dunum),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'one' => q({0}elem.),
						'other' => q({0}elem.),
					},
					# Core Unit Identifier
					'item' => {
						'one' => q({0}elem.),
						'other' => q({0}elem.),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'one' => q({0}mol),
						'other' => q({0}mol),
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
					'concentr-permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'one' => q({0}ppb),
						'other' => q({0}ppb),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'one' => q({0}ppb),
						'other' => q({0}ppb),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0}mi/Imp gal),
						'other' => q({0}mi/Imp gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mi/Imp gal),
						'other' => q({0}mi/Imp gal),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}bit),
						'other' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}sec.),
						'other' => q({0}secc.),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}sec.),
						'other' => q({0}secc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(giorno),
						'one' => q({0}g),
						'other' => q({0}gg),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(giorno),
						'one' => q({0}g),
						'other' => q({0}gg),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}dec.),
						'other' => q({0}dec.),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}dec.),
						'other' => q({0}dec.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ora),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ora),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mese),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mese),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0}/notte),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0}/notte),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'per' => q({0}/trim.),
					},
					# Core Unit Identifier
					'quarter' => {
						'per' => q({0}/trim.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sett.),
						'one' => q({0}sett.),
						'other' => q({0}sett.),
						'per' => q({0}/sett.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sett.),
						'one' => q({0}sett.),
						'other' => q({0}sett.),
						'per' => q({0}/sett.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anno),
						'one' => q({0}anno),
						'other' => q({0}anni),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anno),
						'one' => q({0}anno),
						'other' => q({0}anni),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}BTU),
						'other' => q({0}BTU),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}therm US),
						'other' => q({0}therm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}therm US),
						'other' => q({0}therm US),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punto),
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punto),
						'one' => q({0}p),
						'other' => q({0}p),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fm),
						'other' => q({0}fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}al),
						'other' => q({0}al),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'one' => q({0}grano),
						'other' => q({0}grani),
					},
					# Core Unit Identifier
					'grain' => {
						'one' => q({0}grano),
						'other' => q({0}grani),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0}ozt),
						'other' => q({0}ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0}ozt),
						'other' => q({0}ozt),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}bar),
						'other' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(Bft{0}),
						'other' => q(Bft{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(Bft{0}),
						'other' => q(Bft{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'light-speed' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}Nm),
						'other' => q({0}Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lb-ft),
						'other' => q({0}lb-ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lb-ft),
						'other' => q({0}lb-ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cl),
						'other' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dl),
						'other' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0}dstspn),
						'other' => q({0}dstspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}dstspn),
						'other' => q({0}dstspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dstspn im),
						'one' => q({0}dstspn im),
						'other' => q({0}dstspn im),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dstspn im),
						'one' => q({0}dstspn im),
						'other' => q({0}dstspn im),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dr liq),
						'one' => q({0}dr liq),
						'other' => q({0}dr liq),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dr liq),
						'one' => q({0}dr liq),
						'other' => q({0}dr liq),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'one' => q({0}goccia),
						'other' => q({0}gocce),
					},
					# Core Unit Identifier
					'drop' => {
						'one' => q({0}goccia),
						'other' => q({0}gocce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz im),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz im),
						'one' => q({0}fl oz im),
						'other' => q({0}fl oz im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0}gal),
						'other' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal im),
						'one' => q({0}gal im),
						'other' => q({0}gal im),
						'per' => q({0}/gal im),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal im),
						'one' => q({0}gal im),
						'other' => q({0}gal im),
						'per' => q({0}/gal im),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hl),
						'other' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0}jigger),
						'other' => q({0}jigger),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}jigger),
						'other' => q({0}jigger),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}Ml),
						'other' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}ml),
						'other' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'one' => q({0}pizzico),
						'other' => q({0}pizzichi),
					},
					# Core Unit Identifier
					'pinch' => {
						'one' => q({0}pizzico),
						'other' => q({0}pizzichi),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}imp qt),
						'other' => q({0}imp qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}imp qt),
						'other' => q({0}imp qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(punto),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forza g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forza g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
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
						'name' => q(riv),
						'one' => q({0} riv),
						'other' => q({0} riv),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(riv),
						'one' => q({0} riv),
						'other' => q({0} riv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acri),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acri),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunum),
						'one' => q({0} dunum),
						'other' => q({0} dunum),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunum),
						'one' => q({0} dunum),
						'other' => q({0} dunum),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ettari),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ettari),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(piedi quadrati),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(piedi quadrati),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elem.),
						'one' => q({0} elem.),
						'other' => q({0} elem.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(percento),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(percento),
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
						'name' => q(mi/Imp gal),
						'one' => q({0} mi/Imp gal),
						'other' => q({0} mi/Imp gal),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/Imp gal),
						'one' => q({0} mi/Imp gal),
						'other' => q({0} mi/Imp gal),
					},
					# Long Unit Identifier
					'coordinate' => {
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'west' => q({0}O),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Gbyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Gbyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kbyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kbyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mbyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mbyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Pbyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Pbyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(Tbyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(Tbyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} secc.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} secc.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0}/giorno),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0}/giorno),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dec.),
						'one' => q({0} dec.),
						'other' => q({0} dec.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mesi),
						'one' => q({0} mese),
						'other' => q({0} mesi),
						'per' => q({0}/mese),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mesi),
						'one' => q({0} mese),
						'other' => q({0} mesi),
						'per' => q({0}/mese),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0}/notte),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(notti),
						'one' => q({0} notte),
						'other' => q({0} notti),
						'per' => q({0}/notte),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trimestre),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trimestre),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(settimane),
						'one' => q({0} sett.),
						'other' => q({0} sett.),
						'per' => q({0}/settimana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(settimane),
						'one' => q({0} sett.),
						'other' => q({0} sett.),
						'per' => q({0}/settimana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0}/anno),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0}/anno),
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
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
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
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therm US),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm US),
						'one' => q({0} therm US),
						'other' => q({0} therm US),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punti),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punti),
						'one' => q({0} p),
						'other' => q({0} p),
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
					'length-fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
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
					'length-mile' => {
						'name' => q(miglia),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miglia),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iarde),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iarde),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carati),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carati),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(grano),
						'one' => q({0} grano),
						'other' => q({0} grani),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grano),
						'one' => q({0} grano),
						'other' => q({0} grani),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grammi),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grammi),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
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
					'speed-beaufort' => {
						'one' => q(Bft {0}),
						'other' => q(Bft {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(Bft {0}),
						'other' => q(Bft {0}),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'one' => q({0} luce),
						'other' => q({0} luce),
					},
					# Core Unit Identifier
					'light-speed' => {
						'one' => q({0} luce),
						'other' => q({0} luce),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
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
					'torque-newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lb-ft),
						'one' => q({0} lb-ft),
						'other' => q({0} lb-ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lb-ft),
						'one' => q({0} lb-ft),
						'other' => q({0} lb-ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barile),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barile),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(staia),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(staia),
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
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
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
					'volume-dram' => {
						'name' => q(dramma liquida),
						'one' => q({0} dr liq),
						'other' => q({0} dr liq),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dramma liquida),
						'one' => q({0} dr liq),
						'other' => q({0} dr liq),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(goccia),
						'one' => q({0} goccia),
						'other' => q({0} gocce),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(goccia),
						'one' => q({0} goccia),
						'other' => q({0} gocce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
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
						'name' => q(pizzico),
						'one' => q({0} pizzico),
						'other' => q({0} pizzichi),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pizzico),
						'one' => q({0} pizzico),
						'other' => q({0} pizzichi),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(imp qt),
						'one' => q({0} imp qt),
						'other' => q({0} imp qt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(imp qt),
						'one' => q({0} imp qt),
						'other' => q({0} imp qt),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sì|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:|no|n)$' }
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
			'group' => q(.),
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
					'one' => 'mille',
					'other' => '0 mila',
				},
				'10000' => {
					'one' => '00 mila',
					'other' => '00 mila',
				},
				'100000' => {
					'one' => '000 mila',
					'other' => '000 mila',
				},
				'1000000' => {
					'one' => '0 milione',
					'other' => '0 milioni',
				},
				'10000000' => {
					'one' => '00 milioni',
					'other' => '00 milioni',
				},
				'100000000' => {
					'one' => '000 milioni',
					'other' => '000 milioni',
				},
				'1000000000' => {
					'one' => '0 miliardo',
					'other' => '0 miliardi',
				},
				'10000000000' => {
					'one' => '00 miliardi',
					'other' => '00 miliardi',
				},
				'100000000000' => {
					'one' => '000 miliardi',
					'other' => '000 miliardi',
				},
				'1000000000000' => {
					'one' => '0 mille miliardi',
					'other' => '0 mila miliardi',
				},
				'10000000000000' => {
					'one' => '00 mila miliardi',
					'other' => '00 mila miliardi',
				},
				'100000000000000' => {
					'one' => '000 mila miliardi',
					'other' => '000 mila miliardi',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 Mln',
					'other' => '0 Mln',
				},
				'10000000' => {
					'one' => '00 Mln',
					'other' => '00 Mln',
				},
				'100000000' => {
					'one' => '000 Mln',
					'other' => '000 Mln',
				},
				'1000000000' => {
					'one' => '0 Mld',
					'other' => '0 Mld',
				},
				'10000000000' => {
					'one' => '00 Mld',
					'other' => '00 Mld',
				},
				'100000000000' => {
					'one' => '000 Mld',
					'other' => '000 Mld',
				},
				'1000000000000' => {
					'one' => '0 Bln',
					'other' => '0 Bln',
				},
				'10000000000000' => {
					'one' => '00 Bln',
					'other' => '00 Bln',
				},
				'100000000000000' => {
					'one' => '000 Bln',
					'other' => '000 Bln',
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
				'currency' => q(peseta andorrana),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham degli Emirati Arabi Uniti),
				'one' => q(dirham degli EAU),
				'other' => q(dirham degli EAU),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek albanese),
				'one' => q(lek albanese),
				'other' => q(lekë albanesi),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armeno),
				'one' => q(dram armeno),
				'other' => q(dram armeni),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(fiorino delle Antille olandesi),
				'one' => q(fiorino delle Antille olandesi),
				'other' => q(fiorini delle Antille olandesi),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza angolano),
				'one' => q(kwanza angolano),
				'other' => q(kwanzas angolani),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolano \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(nuovo kwanza angolano \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza reajustado angolano \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(austral argentino),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentino \(vecchio Cod.\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso argentino),
				'one' => q(peso argentino),
				'other' => q(pesos argentini),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(scellino austriaco),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(dollaro australiano),
				'one' => q(dollaro australiano),
				'other' => q(dollari australiani),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(fiorino di Aruba),
				'one' => q(fiorino di Aruba),
				'other' => q(fiorini di Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azero \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat azero),
				'one' => q(manat azero),
				'other' => q(manat azeri),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar Bosnia-Herzegovina),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(marco convertibile della Bosnia-Herzegovina),
				'one' => q(marco convertibile della Bosnia-Herzegovina),
				'other' => q(marchi convertibili della Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollaro di Barbados),
				'one' => q(dollaro di Barbados),
				'other' => q(dollari di Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka bangladese),
				'one' => q(taka bengalese),
				'other' => q(taka bengalesi),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franco belga \(convertibile\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franco belga),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franco belga \(finanziario\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(lev bulgaro \(1962–1999\)),
				'one' => q(lev bulgaro \(1962–1999\)),
				'other' => q(leva bulgari \(1962–1999\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev bulgaro),
				'one' => q(lev bulgaro),
				'other' => q(leva bulgari),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinaro del Bahrein),
				'one' => q(dinaro del Bahrein),
				'other' => q(dinari del Bahrein),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franco del Burundi),
				'one' => q(franco del Burundi),
				'other' => q(franchi del Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dollaro delle Bermuda),
				'one' => q(dollaro delle Bermuda),
				'other' => q(dollari delle Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dollaro del Brunei),
				'one' => q(dollaro del Brunei),
				'other' => q(dollari del Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano),
				'one' => q(boliviano),
				'other' => q(boliviani),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso boliviano),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol boliviano),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(cruzeiro novo brasiliano \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brasiliano),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brasiliano \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real brasiliano),
				'one' => q(real brasiliano),
				'other' => q(real brasiliani),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(cruzado novo brasiliano),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brasiliano),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dollaro delle Bahamas),
				'one' => q(dollaro delle Bahamas),
				'other' => q(dollari delle Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum bhutanese),
				'one' => q(ngultrum bhutanese),
				'other' => q(ngultrum bhutanesi),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birmano),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula del Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nuovo rublo bielorusso \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'Br',
			display_name => {
				'currency' => q(rublo bielorusso),
				'one' => q(rublo bielorusso),
				'other' => q(rubli bielorussi),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(rublo bielorusso \(2000–2016\)),
				'one' => q(rublo bielorusso \(2000–2016\)),
				'other' => q(rubli bielorussi \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dollaro del Belize),
				'one' => q(dollaro del Belize),
				'other' => q(dollari del Belize),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dollaro canadese),
				'one' => q(dollaro canadese),
				'other' => q(dollari canadesi),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(franco congolese),
				'one' => q(franco congolese),
				'other' => q(franchi congolesi),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(franco svizzero),
				'one' => q(franco svizzero),
				'other' => q(franchi svizzeri),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unidades de fomento chilene),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso cileno),
				'one' => q(peso cileno),
				'other' => q(pesos cileni),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(renmimbi cinese offshore),
				'one' => q(renmimbi cinese offshore),
				'other' => q(renmimbi cinesi offshore),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(yuan cinese),
				'one' => q(yuan cinese),
				'other' => q(yuan cinesi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombiani),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón costaricano),
				'one' => q(colón costaricano),
				'other' => q(colón costaricani),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(antico dinaro serbo),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(corona forte cecoslovacca),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso cubano convertibile),
				'one' => q(peso cubano convertibile),
				'other' => q(pesos cubani convertibili),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubani),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo capoverdiano),
				'one' => q(escudo capoverdiano),
				'other' => q(escudos capoverdiani),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(sterlina cipriota),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(corona ceca),
				'one' => q(corona ceca),
				'other' => q(corone ceche),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(ostmark della Germania Orientale),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marco tedesco),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(franco di Gibuti),
				'one' => q(franco di Gibuti),
				'other' => q(franchi di Gibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(corona danese),
				'one' => q(corona danese),
				'other' => q(corone danesi),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicani),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinaro algerino),
				'one' => q(dinaro algerino),
				'other' => q(dinari algerini),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sucre dell’Ecuador),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(unidad de valor constante \(UVC\) dell’Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(corona dell’Estonia),
			},
		},
		'EGP' => {
			symbol => '£E',
			display_name => {
				'currency' => q(sterlina egiziana),
				'one' => q(sterlina egiziana),
				'other' => q(sterline egiziane),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa eritreo),
				'one' => q(nakfa eritreo),
				'other' => q(nakfa eritrei),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(peseta spagnola account),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta spagnola account convertibile),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta spagnola),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr etiope),
				'one' => q(birr etiope),
				'other' => q(birr etiopi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(markka finlandese),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dollaro delle Figi),
				'one' => q(dollaro delle Figi),
				'other' => q(dollari delle Figi),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(sterlina delle Falkland),
				'one' => q(sterlina delle Falkland),
				'other' => q(sterline delle Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franco francese),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(sterlina britannica),
				'one' => q(sterlina britannica),
				'other' => q(sterline britanniche),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgiano),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari georgiano),
				'one' => q(lari georgiano),
				'other' => q(lari georgiani),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi del Ghana),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi ghanese),
				'one' => q(cedi ghanese),
				'other' => q(cedi ghanesi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(sterlina di Gibilterra),
				'one' => q(sterlina di Gibilterra),
				'other' => q(sterline di Gibilterra),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambiano),
				'one' => q(dalasi gambiano),
				'other' => q(dalasi gambiani),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(franco della Guinea),
				'one' => q(franco della Guinea),
				'other' => q(franchi della Guinea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli della Guinea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele della Guinea Equatoriale),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(dracma greca),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal guatemalteco),
				'one' => q(quetzal guatemalteco),
				'other' => q(quetzal guatemaltechi),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(escudo della Guinea portoghese),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso della Guinea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollaro della Guyana),
				'one' => q(dollaro della Guyana),
				'other' => q(dollari della Guyana),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(dollaro di Hong Kong),
				'one' => q(dollaro di Hong Kong),
				'other' => q(dollari di Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira honduregna),
				'one' => q(lempira honduregna),
				'other' => q(lempire honduregne),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinaro croato),
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
				'currency' => q(gourde haitiano),
				'one' => q(gourde haitiano),
				'other' => q(gourde haitiani),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(fiorino ungherese),
				'one' => q(fiorino ungherese),
				'other' => q(fiorini ungheresi),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(rupia indonesiana),
				'one' => q(rupia indonesiana),
				'other' => q(rupie indonesiane),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(sterlina irlandese),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(sterlina israeliana),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(nuovo siclo israeliano),
				'one' => q(nuovo siclo israeliano),
				'other' => q(nuovi sicli israeliani),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(rupia indiana),
				'one' => q(rupia indiana),
				'other' => q(rupie indiane),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinaro iracheno),
				'one' => q(dinaro iracheno),
				'other' => q(dinari iracheni),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial iraniano),
				'one' => q(rial iraniano),
				'other' => q(rial iraniani),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(corona islandese),
				'one' => q(corona islandese),
				'other' => q(corone islandesi),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiana),
				'one' => q(lire italiane),
				'other' => q(lire italiane),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dollaro giamaicano),
				'one' => q(dollaro giamaicano),
				'other' => q(dollari giamaicani),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinaro giordano),
				'one' => q(dinaro giordano),
				'other' => q(dinari giordani),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen giapponese),
				'one' => q(yen giapponese),
				'other' => q(yen giapponesi),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(scellino keniota),
				'one' => q(scellino keniota),
				'other' => q(scellini kenioti),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirghiso),
				'one' => q(som kirghiso),
				'other' => q(som kirghisi),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel cambogiano),
				'one' => q(riel cambogiano),
				'other' => q(riel cambogiani),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franco comoriano),
				'one' => q(franco comoriano),
				'other' => q(franchi comoriani),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won nordcoreano),
				'one' => q(won nordcoreano),
				'other' => q(won nordcoreani),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won sudcoreano),
				'one' => q(won sudcoreano),
				'other' => q(won sudcoreani),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinaro kuwaitiano),
				'one' => q(dinaro kuwaitiano),
				'other' => q(dinari kuwaitiani),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dollaro delle Isole Cayman),
				'one' => q(dollaro delle Isole Cayman),
				'other' => q(dollari delle Isole Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazako),
				'one' => q(tenge kazako),
				'other' => q(tenge kazaki),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laotiano),
				'one' => q(kip laotiano),
				'other' => q(kip laotiani),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(lira libanese),
				'one' => q(lira libanese),
				'other' => q(lire libanesi),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(rupia di Sri Lanka),
				'one' => q(rupia di Sri Lanka),
				'other' => q(rupie di Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollaro liberiano),
				'one' => q(dollaro liberiano),
				'other' => q(dollari liberiani),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti del Lesotho),
				'one' => q(loti del Lesotho),
				'other' => q(maloti del Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas lituano),
				'one' => q(litas lituano),
				'other' => q(litas lituani),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas lituani),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(franco convertibile del Lussemburgo),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(franco del Lussemburgo),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(franco finanziario del Lussemburgo),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats lettone),
				'one' => q(lats lettone),
				'other' => q(lati lettoni),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(rublo lettone),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinaro libico),
				'one' => q(dinaro libico),
				'other' => q(dinari libici),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham marocchino),
				'one' => q(dirham marocchino),
				'other' => q(dirham marocchini),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franco marocchino),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(lei moldavi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary malgascio),
				'one' => q(ariary malgascio),
				'other' => q(ariary malgasci),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franco malgascio),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(dinaro macedone),
				'one' => q(dinaro macedone),
				'other' => q(dinari macedoni),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(dinaro macedone \(1992–1993\)),
				'one' => q(dinaro macedone \(1992–1993\)),
				'other' => q(dinari macedoni \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franco di Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat di Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongolo),
				'one' => q(tugrik mongolo),
				'other' => q(tugrik mongoli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca di Macao),
				'one' => q(pataca di Macao),
				'other' => q(patacas di Macao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya della Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya della Mauritania),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltese),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(sterlina maltese),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(rupia mauriziana),
				'one' => q(rupia mauriziana),
				'other' => q(rupie mauriziane),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa delle Maldive),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawiano),
				'one' => q(kwacha malawiano),
				'other' => q(kwacha malawiani),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(peso messicano),
				'one' => q(peso messicano),
				'other' => q(pesos messicani),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso messicano d’argento \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(unidad de inversion \(UDI\) messicana),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit malese),
				'one' => q(ringgit malese),
				'other' => q(ringgit malesi),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo del Mozambico),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical mozambicano),
				'one' => q(metical mozambicano),
				'other' => q(metical mozambicani),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dollaro namibiano),
				'one' => q(dollaro namibiano),
				'other' => q(dollari namibiani),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(naire nigeriane),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba nicaraguense),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(córdoba nicaraguense),
				'one' => q(córdoba nicaraguense),
				'other' => q(córdoba nicaraguensi),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(fiorino olandese),
			},
		},
		'NOK' => {
			symbol => 'NKr',
			display_name => {
				'currency' => q(corona norvegese),
				'one' => q(corona norvegese),
				'other' => q(corone norvegesi),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(rupia nepalese),
				'one' => q(rupia nepalese),
				'other' => q(rupie nepalesi),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dollaro neozelandese),
				'one' => q(dollaro neozelandese),
				'other' => q(dollari neozelandesi),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omanita),
				'one' => q(rial omanita),
				'other' => q(rial omaniti),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panamense),
				'one' => q(balboa panamense),
				'other' => q(balboa panamensi),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti peruviano),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol peruviano),
				'one' => q(sol peruviano),
				'other' => q(sol peruviani),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol peruviano \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina papuana),
				'one' => q(kina papuana),
				'other' => q(kina papuane),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(peso filippino),
				'one' => q(peso filippino),
				'other' => q(pesos filippini),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(rupia pakistana),
				'one' => q(rupia pakistana),
				'other' => q(rupie pakistane),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty polacco),
				'one' => q(zloty polacco),
				'other' => q(zloty polacchi),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(złoty Polacco \(1950–1995\)),
				'one' => q(złoty polacco \(1950–1995\)),
				'other' => q(złoty polacchi \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo portoghese),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guaraní paraguayano),
				'one' => q(guaraní paraguayano),
				'other' => q(guaraní paraguayani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial qatariano),
				'one' => q(rial qatariano),
				'other' => q(rial qatariani),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dollaro della Rhodesia),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu della Romania),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu rumeno),
				'one' => q(leu rumeno),
				'other' => q(lei rumeni),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinaro serbo),
				'one' => q(dinaro serbo),
				'other' => q(dinara serbi),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(rublo russo),
				'one' => q(rublo russo),
				'other' => q(rubli russi),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(rublo della CSI),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(franco ruandese),
				'one' => q(franco ruandese),
				'other' => q(franchi ruandesi),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal saudita),
				'one' => q(riyal saudita),
				'other' => q(riyal sauditi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollaro delle Isole Salomone),
				'one' => q(dollaro delle Isole Salomone),
				'other' => q(dollari delle Isole Salomone),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(rupia delle Seychelles),
				'one' => q(rupia delle Seychelles),
				'other' => q(rupie delle Seychelles),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinaro sudanese),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sterlina sudanese),
				'one' => q(sterlina sudanese),
				'other' => q(sterline sudanesi),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(corona svedese),
				'one' => q(corona svedese),
				'other' => q(corone svedesi),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dollaro di Singapore),
				'one' => q(dollaro di Singapore),
				'other' => q(dollari di Singapore),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sterlina di Sant’Elena),
				'one' => q(sterlina di Sant’Elena),
				'other' => q(sterline di Sant’Elena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tallero sloveno),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(corona slovacca),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone della Sierra Leone),
				'one' => q(leone della Sierra Leone),
				'other' => q(leoni della Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone della Sierra Leone \(1964–2022\)),
				'one' => q(leone della Sierra Leone \(1964–2022\)),
				'other' => q(leoni della Sierra Leone \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(scellino somalo),
				'one' => q(scellino somalo),
				'other' => q(scellini somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dollaro del Suriname),
				'one' => q(dollaro del Suriname),
				'other' => q(dollari del Suriname),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(fiorino del Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sterlina sud-sudanese),
				'one' => q(sterlina sud-sudanese),
				'other' => q(sterline sud-sudanesi),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra di Sao Tomé e Principe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra di Sao Tomé e Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(rublo sovietico),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colón salvadoregno),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(lira siriana),
				'one' => q(lira siriana),
				'other' => q(lire siriane),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni),
				'one' => q(lilangeni),
				'other' => q(emalangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(baht thailandese),
				'one' => q(baht thailandese),
				'other' => q(baht thailandesi),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(rublo del Tajikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni tagiko),
				'one' => q(somoni tagiko),
				'other' => q(somoni tagiki),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmeno \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat turkmeno),
				'one' => q(manat turkmeno),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinaro tunisino),
				'one' => q(dinaro tunisino),
				'other' => q(dinari tunisini),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(paʻanga tongano),
				'one' => q(paʻanga tongano),
				'other' => q(paʻanga tongani),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo di Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira turca \(1922–2005\)),
				'one' => q(lira turca \(1922–2005\)),
				'other' => q(lire turche \(1922–2005\)),
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
				'currency' => q(dollaro di Trinidad e Tobago),
				'one' => q(dollaro di Trinidad e Tobago),
				'other' => q(dollari di Trinidad e Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nuovo dollaro taiwanese),
				'one' => q(nuovo dollaro taiwanese),
				'other' => q(nuovi dollari taiwanesi),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(scellino della Tanzania),
				'one' => q(scellino della Tanzania),
				'other' => q(scellini della Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(grivnia ucraina),
				'one' => q(grivnia ucraina),
				'other' => q(grivnie ucraine),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanetz ucraino),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(scellino ugandese \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(scellino ugandese),
				'one' => q(scellino ugandese),
				'other' => q(scellini ugandesi),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(dollaro statunitense),
				'one' => q(dollaro statunitense),
				'other' => q(dollari statunitensi),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dollaro statunitense \(next day\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dollaro statunitense \(same day\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguaiano in unità indicizzate),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguaiano \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguayano),
				'one' => q(peso uruguayano),
				'other' => q(pesos uruguayani),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum uzbeco),
				'one' => q(sum uzbeco),
				'other' => q(sum uzbechi),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar venezuelano \(1871–2008\)),
				'one' => q(bolivar venezuelano \(1871–2008\)),
				'other' => q(bolivares venezuelani \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolívar venezuelano \(2008–2018\)),
				'one' => q(bolívar venezuelano \(2008–2018\)),
				'other' => q(bolívares venezuelani \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar venezuelano),
				'one' => q(bolívar venezuelano),
				'other' => q(bolívares venezuelani),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dong vietnamiti),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu di Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoano),
				'one' => q(tala samoano),
				'other' => q(tala samoani),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(franco CFA BEAC),
				'one' => q(franco CFA BEAC),
				'other' => q(franchi CFA BEAC),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(argento),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(oro),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unità composita europea),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unità monetaria europea),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unità di acconto europea \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unità di acconto europea \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(dollaro dei Caraibi orientali),
				'one' => q(dollaro dei Caraibi orientali),
				'other' => q(dollari dei Caraibi orientali),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(diritti speciali di incasso),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franco oro francese),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franco UIC francese),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(franco CFA BCEAO),
				'one' => q(franco CFA BCEAO),
				'other' => q(franchi CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladio),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(franco CFP),
				'one' => q(franco CFP),
				'other' => q(franchi CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platino),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fondi RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(codice di verifica della valuta),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(valuta sconosciuta),
				'one' => q(\(valuta sconosciuta\)),
				'other' => q(\(valute sconosciute\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinaro dello Yemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(riyal yemenita),
				'one' => q(rial yemenita),
				'other' => q(rial yemeniti),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinaro forte yugoslavo),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinaro noviy yugoslavo),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinaro convertibile yugoslavo),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand sudafricano \(finanziario\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand sudafricano),
				'one' => q(rand sudafricano),
				'other' => q(rand sudafricani),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha dello Zambia \(1968–2012\)),
				'one' => q(kwacha zambiano \(1968–2012\)),
				'other' => q(kwacha zambiani \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha zambiano),
				'one' => q(kwacha zambiano),
				'other' => q(kwacha zambiani),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(nuovo zaire dello Zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire dello Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dollaro dello Zimbabwe),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dollaro zimbabwiano \(2009\)),
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
							'gen',
							'feb',
							'mar',
							'apr',
							'mag',
							'giu',
							'lug',
							'ago',
							'set',
							'ott',
							'nov',
							'dic'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'gennaio',
							'febbraio',
							'marzo',
							'aprile',
							'maggio',
							'giugno',
							'luglio',
							'agosto',
							'settembre',
							'ottobre',
							'novembre',
							'dicembre'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'G',
							'F',
							'M',
							'A',
							'M',
							'G',
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
						thu => 'gio',
						fri => 'ven',
						sat => 'sab',
						sun => 'dom'
					},
					wide => {
						mon => 'lunedì',
						tue => 'martedì',
						wed => 'mercoledì',
						thu => 'giovedì',
						fri => 'venerdì',
						sat => 'sabato',
						sun => 'domenica'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'G',
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
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					'afternoon1' => q{di pomeriggio},
					'evening1' => q{di sera},
					'midnight' => q{mezzanotte},
					'morning1' => q{di mattina},
					'night1' => q{di notte},
					'noon' => q{mezzogiorno},
				},
				'narrow' => {
					'am' => q{m.},
					'pm' => q{p.},
				},
				'wide' => {
					'afternoon1' => q{del pomeriggio},
					'evening1' => q{di sera},
					'midnight' => q{mezzanotte},
					'morning1' => q{di mattina},
					'night1' => q{di notte},
					'noon' => q{mezzogiorno},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{pomeriggio},
					'evening1' => q{sera},
					'morning1' => q{mattina},
					'night1' => q{notte},
				},
				'narrow' => {
					'am' => q{m.},
					'pm' => q{p.},
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
				'0' => 'EB'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a.C.',
				'1' => 'd.C.'
			},
			narrow => {
				'0' => 'aC',
				'1' => 'dC'
			},
			wide => {
				'0' => 'avanti Cristo',
				'1' => 'dopo Cristo'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Prima di R.O.C.',
				'1' => 'Minguo'
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
			'full' => q{EEEE d MMMM U},
			'long' => q{dd MMMM U},
			'medium' => q{dd MMM U},
			'short' => q{dd/MM/yy},
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'settimana' W 'di' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'settimana' w 'del' Y},
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
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd–dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
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
				G => q{E dd/MM/y – E d/dMM/y GGGGG},
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
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
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
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
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
		regionFormat => q(Ora {0}),
		regionFormat => q(Ora legale: {0}),
		regionFormat => q(Ora standard: {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#Ora dell’Afghanistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algeri#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Il Cairo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Gibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ayun#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Giuba#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunisi#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Ora dell’Africa centrale#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ora dell’Africa orientale#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Ora dell’Africa meridionale#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Ora legale dell’Africa occidentale#,
				'generic' => q#Ora dell’Africa occidentale#,
				'standard' => q#Ora standard dell’Africa occidentale#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Ora legale dell’Alaska#,
				'generic' => q#Ora dell’Alaska#,
				'standard' => q#Ora standard dell’Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ora legale dell’Amazzonia#,
				'generic' => q#Ora dell’Amazzonia#,
				'standard' => q#Ora standard dell’Amazzonia#,
			},
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caienna#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupa#,
		},
		'America/Havana' => {
			exemplarCity => q#L’Avana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Giamaica#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Città del Messico#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Dakota del nord#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota del nord#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Dakota del nord#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portorico#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Paolo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Ora legale centrale USA#,
				'generic' => q#Ora centrale USA#,
				'standard' => q#Ora standard centrale USA#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ora legale orientale USA#,
				'generic' => q#Ora orientale USA#,
				'standard' => q#Ora standard orientale USA#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ora legale Montagne Rocciose USA#,
				'generic' => q#Ora Montagne Rocciose USA#,
				'standard' => q#Ora standard Montagne Rocciose USA#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ora legale del Pacifico USA#,
				'generic' => q#Ora del Pacifico USA#,
				'standard' => q#Ora standard del Pacifico USA#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Ora legale di Anadyr#,
				'generic' => q#Ora di Anadyr#,
				'standard' => q#Ora standard di Anadyr#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Ora legale di Apia#,
				'generic' => q#Ora di Apia#,
				'standard' => q#Ora standard di Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Ora legale araba#,
				'generic' => q#Ora araba#,
				'standard' => q#Ora standard araba#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ora legale dell’Argentina#,
				'generic' => q#Ora dell’Argentina#,
				'standard' => q#Ora standard dell’Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Ora legale dell’Argentina occidentale#,
				'generic' => q#Ora dell’Argentina occidentale#,
				'standard' => q#Ora standard dell’Argentina occidentale#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Ora legale dell’Armenia#,
				'generic' => q#Ora dell’Armenia#,
				'standard' => q#Ora standard dell’Armenia#,
			},
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr’#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagosta#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Gerusalemme#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzneck#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust’-Nera#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ora legale dell’Atlantico#,
				'generic' => q#Ora dell’Atlantico#,
				'standard' => q#Ora standard dell’Atlantico#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azzorre#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarie#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Capo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Isole Fær Øer#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia del Sud#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sant’Elena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ora legale dell’Australia centrale#,
				'generic' => q#Ora dell’Australia centrale#,
				'standard' => q#Ora standard dell’Australia centrale#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ora legale dell’Australia centroccidentale#,
				'generic' => q#Ora dell’Australia centroccidentale#,
				'standard' => q#Ora standard dell’Australia centroccidentale#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ora legale dell’Australia orientale#,
				'generic' => q#Ora dell’Australia orientale#,
				'standard' => q#Ora standard dell’Australia orientale#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ora legale dell’Australia occidentale#,
				'generic' => q#Ora dell’Australia occidentale#,
				'standard' => q#Ora standard dell’Australia occidentale#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Ora legale dell’Azerbaigian#,
				'generic' => q#Ora dell’Azerbaigian#,
				'standard' => q#Ora standard dell’Azerbaigian#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Ora legale delle Azzorre#,
				'generic' => q#Ora delle Azzorre#,
				'standard' => q#Ora standard delle Azzorre#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Ora legale del Bangladesh#,
				'generic' => q#Ora del Bangladesh#,
				'standard' => q#Ora standard del Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Ora del Bhutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Ora della Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Ora legale di Brasilia#,
				'generic' => q#Ora di Brasilia#,
				'standard' => q#Ora standard di Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Ora del Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Ora legale di Capo Verde#,
				'generic' => q#Ora di Capo Verde#,
				'standard' => q#Ora standard di Capo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Ora di Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Ora legale delle Chatham#,
				'generic' => q#Ora delle Chatham#,
				'standard' => q#Ora standard delle Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Ora legale del Cile#,
				'generic' => q#Ora del Cile#,
				'standard' => q#Ora standard del Cile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Ora legale della Cina#,
				'generic' => q#Ora della Cina#,
				'standard' => q#Ora standard della Cina#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Ora dell’Isola Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Ora delle Isole Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Ora legale della Colombia#,
				'generic' => q#Ora della Colombia#,
				'standard' => q#Ora standard della Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Ora legale media delle isole Cook#,
				'generic' => q#Ora delle isole Cook#,
				'standard' => q#Ora standard delle isole Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Ora legale di Cuba#,
				'generic' => q#Ora di Cuba#,
				'standard' => q#Ora standard di Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Ora di Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Ora di Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ora di Timor Est#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ora legale dell’Isola di Pasqua#,
				'generic' => q#Ora dell’Isola di Pasqua#,
				'standard' => q#Ora standard dell’Isola di Pasqua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ora dell’Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Tempo coordinato universale#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Città sconosciuta#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atene#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlino#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
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
			exemplarCity => q#Dublino#,
			long => {
				'daylight' => q#Ora legale dell’Irlanda#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibilterra#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isola di Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisbona#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubiana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londra#,
			long => {
				'daylight' => q#Ora legale del Regno Unito#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lussemburgo#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parigi#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Sinferopoli#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stoccolma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Città del Vaticano#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagabria#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zurigo#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Ora legale dell’Europa centrale#,
				'generic' => q#Ora dell’Europa centrale#,
				'standard' => q#Ora standard dell’Europa centrale#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ora legale dell’Europa orientale#,
				'generic' => q#Ora dell’Europa orientale#,
				'standard' => q#Ora standard dell’Europa orientale#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Ora dell’Europa orientale (Kaliningrad)#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Ora legale dell’Europa occidentale#,
				'generic' => q#Ora dell’Europa occidentale#,
				'standard' => q#Ora standard dell’Europa occidentale#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Ora legale delle Isole Falkland#,
				'generic' => q#Ora delle Isole Falkland#,
				'standard' => q#Ora standard delle Isole Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Ora legale delle Figi#,
				'generic' => q#Ora delle Figi#,
				'standard' => q#Ora standard delle Figi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Ora della Guiana francese#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Ora delle Terre australi e antartiche francesi#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Ora del meridiano di Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Ora delle Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Ora di Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Ora legale della Georgia#,
				'generic' => q#Ora della Georgia#,
				'standard' => q#Ora standard della Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Ora delle isole Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ora legale della Groenlandia orientale#,
				'generic' => q#Ora della Groenlandia orientale#,
				'standard' => q#Ora standard della Groenlandia orientale#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Ora legale della Groenlandia occidentale#,
				'generic' => q#Ora della Groenlandia occidentale#,
				'standard' => q#Ora standard della Groenlandia occidentale#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Ora del Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Ora della Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Ora legale delle Isole Hawaii-Aleutine#,
				'generic' => q#Ora delle isole Hawaii-Aleutine#,
				'standard' => q#Ora standard delle Isole Hawaii-Aleutine#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Ora legale di Hong Kong#,
				'generic' => q#Ora di Hong Kong#,
				'standard' => q#Ora standard di Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Ora legale di Hovd#,
				'generic' => q#Ora di Hovd#,
				'standard' => q#Ora standard di Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ora standard dell’India#,
			},
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comore#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#La Riunione#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Ora dell’Oceano Indiano#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ora dell’Indocina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ora dell’Indonesia centrale#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ora dell’Indonesia orientale#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ora dell’Indonesia occidentale#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Ora legale dell’Iran#,
				'generic' => q#Ora dell’Iran#,
				'standard' => q#Ora standard dell’Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Ora legale di Irkutsk#,
				'generic' => q#Ora di Irkutsk#,
				'standard' => q#Ora standard di Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ora legale di Israele#,
				'generic' => q#Ora di Israele#,
				'standard' => q#Ora standard di Israele#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Ora legale del Giappone#,
				'generic' => q#Ora del Giappone#,
				'standard' => q#Ora standard del Giappone#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Ora legale di Petropavlovsk-Kamchatski#,
				'generic' => q#Ora di Petropavlovsk-Kamchatski#,
				'standard' => q#Ora standard di Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Ora del Kazakistan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ora del Kazakistan orientale#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Ora del Kazakistan occidentale#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Ora legale coreana#,
				'generic' => q#Ora coreana#,
				'standard' => q#Ora standard coreana#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Ora del Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Ora legale di Krasnoyarsk#,
				'generic' => q#Ora di Krasnoyarsk#,
				'standard' => q#Ora standard di Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Ora del Kirghizistan#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Ora delle Sporadi equatoriali#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Ora legale di Lord Howe#,
				'generic' => q#Ora di Lord Howe#,
				'standard' => q#Ora standard di Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Ora legale di Macao#,
				'generic' => q#Ora di Macao#,
				'standard' => q#Ora standard di Macao#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Ora legale di Magadan#,
				'generic' => q#Ora di Magadan#,
				'standard' => q#Ora standard di Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Ora della Malesia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Ora delle Maldive#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Ora delle Marchesi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Ora delle Isole Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Ora legale delle Mauritius#,
				'generic' => q#Ora delle Mauritius#,
				'standard' => q#Ora standard delle Mauritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Ora di Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Ora legale del Pacifico (Messico)#,
				'generic' => q#Ora del Pacifico (Messico)#,
				'standard' => q#Ora standard del Pacifico (Messico)#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ora legale di Ulan Bator#,
				'generic' => q#Ora di Ulan Bator#,
				'standard' => q#Ora standard di Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Ora legale di Mosca#,
				'generic' => q#Ora di Mosca#,
				'standard' => q#Ora standard di Mosca#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Ora della Birmania#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Ora di Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Ora del Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Ora legale della Nuova Caledonia#,
				'generic' => q#Ora della Nuova Caledonia#,
				'standard' => q#Ora standard della Nuova Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Ora legale della Nuova Zelanda#,
				'generic' => q#Ora della Nuova Zelanda#,
				'standard' => q#Ora standard della Nuova Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ora legale di Terranova#,
				'generic' => q#Ora di Terranova#,
				'standard' => q#Ora standard di Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Ora di Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Ora legale delle Isole Norfolk#,
				'generic' => q#Ora delle Isole Norfolk#,
				'standard' => q#Ora standard delle Isole Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Ora legale di Fernando de Noronha#,
				'generic' => q#Ora di Fernando de Noronha#,
				'standard' => q#Ora standard di Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Ora legale di Novosibirsk#,
				'generic' => q#Ora di Novosibirsk#,
				'standard' => q#Ora standard di Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ora legale di Omsk#,
				'generic' => q#Ora di Omsk#,
				'standard' => q#Ora standard di Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasqua#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Figi#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Canton#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marchesi#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Ora legale del Pakistan#,
				'generic' => q#Ora del Pakistan#,
				'standard' => q#Ora standard del Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Ora di Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Ora della Papua Nuova Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Ora legale del Paraguay#,
				'generic' => q#Ora del Paraguay#,
				'standard' => q#Ora standard del Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Ora legale del Perù#,
				'generic' => q#Ora del Perù#,
				'standard' => q#Ora standard del Perù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Ora legale delle Filippine#,
				'generic' => q#Ora delle Filippine#,
				'standard' => q#Ora standard delle Filippine#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Ora delle Isole della Fenice#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Ora legale di Saint-Pierre e Miquelon#,
				'generic' => q#Ora di Saint-Pierre e Miquelon#,
				'standard' => q#Ora standard di Saint-Pierre e Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Ora delle Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ora di Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Ora di Pyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Ora di Riunione#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Ora di Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Ora legale di Sakhalin#,
				'generic' => q#Ora di Sakhalin#,
				'standard' => q#Ora standard di Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Ora legale di Samara#,
				'generic' => q#Ora di Samara#,
				'standard' => q#Ora standard di Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Ora legale di Samoa#,
				'generic' => q#Ora di Samoa#,
				'standard' => q#Ora standard di Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Ora delle Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Ora di Singapore#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Ora delle Isole Salomone#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Ora della Georgia del Sud#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Ora del Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Ora di Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Ora di Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Ora legale di Taipei#,
				'generic' => q#Ora di Taipei#,
				'standard' => q#Ora standard di Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Ora del Tagikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Ora di Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Ora legale di Tonga#,
				'generic' => q#Ora di Tonga#,
				'standard' => q#Ora standard di Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Ora del Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Ora legale del Turkmenistan#,
				'generic' => q#Ora del Turkmenistan#,
				'standard' => q#Ora standard del Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Ora di Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Ora legale dell’Uruguay#,
				'generic' => q#Ora dell’Uruguay#,
				'standard' => q#Ora standard dell’Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Ora legale dell’Uzbekistan#,
				'generic' => q#Ora dell’Uzbekistan#,
				'standard' => q#Ora standard dell’Uzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Ora legale del Vanuatu#,
				'generic' => q#Ora del Vanuatu#,
				'standard' => q#Ora standard del Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Ora del Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Ora legale di Vladivostok#,
				'generic' => q#Ora di Vladivostok#,
				'standard' => q#Ora standard di Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Ora legale di Volgograd#,
				'generic' => q#Ora di Volgograd#,
				'standard' => q#Ora standard di Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Ora di Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Ora dell’Isola di Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Ora di Wallis e Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Ora legale di Yakutsk#,
				'generic' => q#Ora di Yakutsk#,
				'standard' => q#Ora standard di Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ora legale di Ekaterinburg#,
				'generic' => q#Ora di Ekaterinburg#,
				'standard' => q#Ora standard di Ekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Ora dello Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
