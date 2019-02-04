=encoding utf8

=head1

Locale::CLDR::Locales::It - Package for language Italian

=cut

package Locale::CLDR::Locales::It;
# This file auto generated from Data\common\main\it.xml
#	on Sun  3 Feb  1:57:46 pm GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-ordinal-masculine','spellout-ordinal-feminine','digits-ordinal-masculine','digits-ordinal-feminine','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
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
					rule => q(a­tre),
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
 				'bgn' => 'beluci occidentale',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bicol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
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
 				'ckb' => 'curdo sorani',
 				'co' => 'corso',
 				'cop' => 'copto',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crh' => 'turco crimeo',
 				'crs' => 'creolo delle Seychelles',
 				'cs' => 'ceco',
 				'csb' => 'kashubian',
 				'cu' => 'slavo della Chiesa',
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
 				'gom' => 'konkani goano',
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
 				'he' => 'ebraico',
 				'hi' => 'hindi',
 				'hif' => 'hindi figiano',
 				'hil' => 'ilongo',
 				'hit' => 'hittite',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croato',
 				'hsb' => 'alto sorabo',
 				'hsn' => 'xiang',
 				'ht' => 'haitiano',
 				'hu' => 'ungherese',
 				'hup' => 'hupa',
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
 				'kaj' => 'kai',
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
 				'liv' => 'livone',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardo',
 				'ln' => 'lingala',
 				'lo' => 'lao',
 				'lol' => 'lolo bantu',
 				'lou' => 'creolo della Louisiana',
 				'loz' => 'lozi',
 				'lrc' => 'luri settentrionale',
 				'lt' => 'lituano',
 				'ltg' => 'letgallo',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
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
 				'pl' => 'polacco',
 				'pms' => 'piemontese',
 				'pnt' => 'pontico',
 				'pon' => 'ponape',
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
 				'rif' => 'tarifit',
 				'rm' => 'romancio',
 				'rn' => 'rundi',
 				'ro' => 'rumeno',
 				'ro_MD' => 'moldavo',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'root' => 'root',
 				'rtm' => 'rotumano',
 				'ru' => 'russo',
 				'rue' => 'ruteno',
 				'rug' => 'roviana',
 				'rup' => 'arumeno',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanscrito',
 				'sad' => 'sandawe',
 				'sah' => 'yakut',
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
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tagico',
 				'th' => 'thai',
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
 				'tpi' => 'tok pisin',
 				'tr' => 'turco',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'zaconico',
 				'tsi' => 'tsimshian',
 				'tt' => 'tataro',
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
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'veneto',
 				'vep' => 'vepso',
 				'vi' => 'vietnamita',
 				'vls' => 'fiammingo occidentale',
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
 				'xog' => 'soga',
 				'yao' => 'yao (bantu)',
 				'yap' => 'yapese',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantonese',
 				'za' => 'zhuang',
 				'zap' => 'zapotec',
 				'zbl' => 'blissymbol',
 				'zea' => 'zelandese',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight del Marocco standard',
 				'zh' => 'cinese',
 				'zh_Hans' => 'cinese semplificato',
 				'zh_Hant' => 'cinese tradizionale',
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
			'Afak' => 'afaka',
 			'Aghb' => 'albanese caucasico',
 			'Arab' => 'arabo',
 			'Arab@alt=variant' => 'arabo-persiano',
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
 			'Cans' => 'simboli aborigeni canadesi unificati',
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
 			'Hanb' => 'hanb',
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
 			'Rjng' => 'rejang',
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
 			'Syrc' => 'siriano',
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
 			'Vaii' => 'vaii',
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
 			'AS' => 'Samoa americane',
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
 			'BQ' => 'Caraibi olandesi',
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
 			'EH' => 'Sahara occidentale',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagna',
 			'ET' => 'Etiopia',
 			'EU' => 'Unione Europea',
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
 			'GF' => 'Guyana francese',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibilterra',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupa',
 			'GQ' => 'Guinea Equatoriale',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia del Sud e Sandwich australi',
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
 			'IO' => 'Territorio britannico dell’Oceano Indiano',
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
 			'MK' => 'Repubblica di Macedonia',
 			'MK@alt=variant' => 'Ex Repubblica Jugoslava di Macedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'RAS di Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Isole Marianne settentrionali',
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
 			'OM' => 'Oman',
 			'PA' => 'Panamá',
 			'PE' => 'Perù',
 			'PF' => 'Polinesia francese',
 			'PG' => 'Papua Nuova Guinea',
 			'PH' => 'Filippine',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'Saint-Pierre e Miquelon',
 			'PN' => 'Isole Pitcairn',
 			'PR' => 'Portorico',
 			'PS' => 'Territori palestinesi',
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
 			'SZ' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Isole Turks e Caicos',
 			'TD' => 'Ciad',
 			'TF' => 'Terre australi francesi',
 			'TG' => 'Togo',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tagikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor Est',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turchia',
 			'TT' => 'Trinidad e Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraina',
 			'UG' => 'Uganda',
 			'UM' => 'Altre isole americane del Pacifico',
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
 			'BAUDDHA' => 'BAUDDHA',
 			'BISCAYAN' => 'BISCAYAN',
 			'BISKE' => 'dialetto San Giorgio/Bila',
 			'BOHORIC' => 'alfabeto bohorič',
 			'BOONT' => 'boontling',
 			'DAJNKO' => 'alfabeto Dajnko',
 			'EMODENG' => 'primo inglese moderno',
 			'FONIPA' => 'alfabeto fonetico internazionale IPA',
 			'FONUPA' => 'alfabeto fonetico uralico UPA',
 			'FONXSAMP' => 'FONXSAMP',
 			'HEPBURN' => 'romanizzazione Hepburn',
 			'HOGNORSK' => 'HOGNORSK',
 			'ITIHASA' => 'ITIHASA',
 			'JAUER' => 'JAUER',
 			'JYUTPING' => 'JYUTPING',
 			'KKCOR' => 'ortografia comune',
 			'KSCOR' => 'ortografia standard',
 			'LAUKIKA' => 'LAUKIKA',
 			'LIPAW' => 'dialetto resiano di Lipovaz',
 			'LUNA1918' => 'LUNA1918',
 			'METELKO' => 'alfabeto Metelko',
 			'MONOTON' => 'monotonico',
 			'NDYUKA' => 'dialetto Ndyuka',
 			'NEDIS' => 'dialetto del Natisone',
 			'NJIVA' => 'dialetto Gniva/Njiva',
 			'NULIK' => 'volapük moderno',
 			'OSOJS' => 'dialetto Oseacco/Osojane',
 			'PAMAKA' => 'dialetto Pamaka',
 			'PETR1708' => 'PETR1708',
 			'PINYIN' => 'romanizzazione Pinyin',
 			'POLYTON' => 'politonico',
 			'POSIX' => 'computer',
 			'PUTER' => 'PUTER',
 			'REVISED' => 'ortografia revisionata',
 			'RIGIK' => 'Volapük classico',
 			'ROZAJ' => 'resiano',
 			'RUMGR' => 'RUMGR',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'inglese scozzese standard',
 			'SCOUSE' => 'scouse',
 			'SOLBA' => 'dialetto Stolvizza/Solbica',
 			'SURMIRAN' => 'SURMIRAN',
 			'SURSILV' => 'SURSILV',
 			'SUTSILV' => 'SUTSILV',
 			'TARASK' => 'ortografia taraskievica',
 			'UCCOR' => 'ortografia unificata',
 			'UCRCOR' => 'ortografia rivista unificata',
 			'ULSTER' => 'ULSTER',
 			'VAIDIKA' => 'VAIDIKA',
 			'VALENCIA' => 'valenziano',
 			'VALLADER' => 'VALLADER',
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
 				'islamic' => q{Calendario islamico},
 				'islamic-civil' => q{calendario civile islamico},
 				'islamic-rgsa' => q{Calendario islamico (Arabia Saudita, osservazione)},
 				'islamic-tbla' => q{Calendario islamico (tabulare, era astronomica)},
 				'islamic-umalqura' => q{Calendario islamico (Umm al-Qura)},
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
 				'big5han' => q{cinese tradizionale},
 				'compat' => q{Ordinamento compatto},
 				'dictionary' => q{Ordinamento dizionario},
 				'ducet' => q{Ordinamento Unicode predefinito},
 				'eor' => q{eor},
 				'gb2312han' => q{cinese semplificato},
 				'phonebook' => q{ordine elenco telefonico},
 				'phonetic' => q{Ordinamento fonetico},
 				'pinyin' => q{ordine pinyin},
 				'reformed' => q{Ordinamento riformato},
 				'search' => q{Ricerca generica},
 				'searchjl' => q{Cerca per consonante hangul iniziale},
 				'standard' => q{Ordinamento standard},
 				'stroke' => q{ordine segni},
 				'traditional' => q{ordine tradizionale},
 				'unihan' => q{Ordinamento in base ai radicali},
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
			auxiliary => qr{[ª á â å ä ã æ ç ê ë í î ï ñ º ô ö õ ø œ ß ú û ü ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a à b c d e é è f g h i ì j k l m n o ó ò p q r s t u ù v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- — , ; \: ! ? . … ' ’ " “ ” « » ( ) \[ \] \{ \} @ /]},
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
	default		=> qq{“},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{”},
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
						'name' => q(punti cardinali),
					},
					'acre' => {
						'name' => q(acri),
						'one' => q({0} acro),
						'other' => q({0} acri),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(ampere),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					'arc-minute' => {
						'name' => q(primi d’arco),
						'one' => q({0} primo d’arco),
						'other' => q({0} primi d’arco),
					},
					'arc-second' => {
						'name' => q(secondi d’arco),
						'one' => q({0} secondo d’arco),
						'other' => q({0} secondi d’arco),
					},
					'astronomical-unit' => {
						'name' => q(unità astronomiche),
						'one' => q({0} unità astronomica),
						'other' => q({0} unità astronomiche),
					},
					'atmosphere' => {
						'name' => q(atmosfere),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfere),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(staia),
						'one' => q({0} staio),
						'other' => q({0} staia),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					'carat' => {
						'name' => q(carati),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					'celsius' => {
						'name' => q(gradi Celsius),
						'one' => q({0} grado Celsius),
						'other' => q({0} gradi Celsius),
					},
					'centiliter' => {
						'name' => q(centilitri),
						'one' => q({0} centilitro),
						'other' => q({0} centilitri),
					},
					'centimeter' => {
						'name' => q(centimetri),
						'one' => q({0} centimetro),
						'other' => q({0} centimetri),
						'per' => q({0} per centimetro),
					},
					'century' => {
						'name' => q(secoli),
						'one' => q({0} secolo),
						'other' => q({0} secoli),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(centimetri cubi),
						'one' => q({0} centimetro cubo),
						'other' => q({0} centimetri cubi),
						'per' => q({0} per centimetro cubo),
					},
					'cubic-foot' => {
						'name' => q(piedi cubi),
						'one' => q({0} piede cubo),
						'other' => q({0} piedi cubi),
					},
					'cubic-inch' => {
						'name' => q(pollici cubi),
						'one' => q({0} pollice cubo),
						'other' => q({0} pollici cubi),
					},
					'cubic-kilometer' => {
						'name' => q(chilometri cubi),
						'one' => q({0} chilometro cubo),
						'other' => q({0} chilometri cubi),
					},
					'cubic-meter' => {
						'name' => q(metri cubi),
						'one' => q({0} metro cubo),
						'other' => q({0} metri cubi),
						'per' => q({0} per metro cubo),
					},
					'cubic-mile' => {
						'name' => q(miglia cube),
						'one' => q({0} miglio cubo),
						'other' => q({0} miglia cube),
					},
					'cubic-yard' => {
						'name' => q(iarde cubiche),
						'one' => q({0} iarda cubica),
						'other' => q({0} iarde cubiche),
					},
					'cup' => {
						'name' => q(tazze),
						'one' => q({0} tazza),
						'other' => q({0} tazze),
					},
					'cup-metric' => {
						'name' => q(tazze metriche),
						'one' => q({0} tazza metrica),
						'other' => q({0} tazze metriche),
					},
					'day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0} al giorno),
					},
					'deciliter' => {
						'name' => q(decilitri),
						'one' => q({0} decilitro),
						'other' => q({0} decilitri),
					},
					'decimeter' => {
						'name' => q(decimetri),
						'one' => q({0} decimetro),
						'other' => q({0} decimetri),
					},
					'degree' => {
						'name' => q(gradi),
						'one' => q({0} grado),
						'other' => q({0} gradi),
					},
					'fahrenheit' => {
						'name' => q(gradi Fahrenheit),
						'one' => q({0} grado Fahrenheit),
						'other' => q({0} gradi Fahrenheit),
					},
					'fluid-ounce' => {
						'name' => q(once fluide),
						'one' => q({0} oncia fluida),
						'other' => q({0} once fluide),
					},
					'foodcalorie' => {
						'name' => q(Calorie),
						'one' => q({0} caloria),
						'other' => q({0} calorie),
					},
					'foot' => {
						'name' => q(piedi),
						'one' => q({0} piede),
						'other' => q({0} piedi),
						'per' => q({0} per piede),
					},
					'g-force' => {
						'name' => q(forza g),
						'one' => q({0} forza g),
						'other' => q({0} forza g),
					},
					'gallon' => {
						'name' => q(galloni),
						'one' => q({0} gallone),
						'other' => q({0} galloni),
						'per' => q({0} per gallone),
					},
					'gallon-imperial' => {
						'name' => q(galloni imperiali),
						'one' => q({0} gallone imperiale),
						'other' => q({0} galloni imperiali),
						'per' => q({0} per gallone imperiale),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					'gigabyte' => {
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					'gigawatt' => {
						'name' => q(gigawatt),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					'gram' => {
						'name' => q(grammi),
						'one' => q({0} grammo),
						'other' => q({0} grammi),
						'per' => q({0} per grammo),
					},
					'hectare' => {
						'name' => q(ettari),
						'one' => q({0} ettaro),
						'other' => q({0} ettari),
					},
					'hectoliter' => {
						'name' => q(ettolitri),
						'one' => q({0} ettolitro),
						'other' => q({0} ettolitri),
					},
					'hectopascal' => {
						'name' => q(ettopascal),
						'one' => q({0} ettopascal),
						'other' => q({0} ettopascal),
					},
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					'horsepower' => {
						'name' => q(cavalli vapore),
						'one' => q({0} cavallo vapore),
						'other' => q({0} cavalli vapore),
					},
					'hour' => {
						'name' => q(ore),
						'one' => q({0} ora),
						'other' => q({0} ore),
						'per' => q({0} all’ora),
					},
					'inch' => {
						'name' => q(pollici),
						'one' => q({0} pollice),
						'other' => q({0} pollici),
						'per' => q({0} per pollice),
					},
					'inch-hg' => {
						'name' => q(pollici di mercurio),
						'one' => q({0} pollice di mercurio),
						'other' => q({0} pollici di mercurio),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					'karat' => {
						'name' => q(carati),
						'one' => q({0} carato),
						'other' => q({0} carati),
					},
					'kelvin' => {
						'name' => q(Kelvin),
						'one' => q({0} Kelvin),
						'other' => q({0} Kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					'kilocalorie' => {
						'name' => q(chilocalorie),
						'one' => q({0} chilocaloria),
						'other' => q({0} chilocalorie),
					},
					'kilogram' => {
						'name' => q(chilogrammi),
						'one' => q({0} chilogrammo),
						'other' => q({0} chilogrammi),
						'per' => q({0} per chilogrammo),
					},
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					'kilojoule' => {
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					'kilometer' => {
						'name' => q(chilometri),
						'one' => q({0} chilometro),
						'other' => q({0} chilometri),
						'per' => q({0} per chilometro),
					},
					'kilometer-per-hour' => {
						'name' => q(chilometri orari),
						'one' => q({0} chilometro orario),
						'other' => q({0} chilometri orari),
					},
					'kilowatt' => {
						'name' => q(kilowatt),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(chilowattora),
						'one' => q({0} chilowattora),
						'other' => q({0} chilowattora),
					},
					'knot' => {
						'name' => q(nodo),
						'one' => q({0} nodo),
						'other' => q({0} nodi),
					},
					'light-year' => {
						'name' => q(anni luce),
						'one' => q({0} anno luce),
						'other' => q({0} anni luce),
					},
					'liter' => {
						'name' => q(litri),
						'one' => q({0} litro),
						'other' => q({0} litri),
						'per' => q({0} per litro),
					},
					'liter-per-100kilometers' => {
						'name' => q(litri per 100 chilometri),
						'one' => q({0} litro per 100 chilometri),
						'other' => q({0} litri per 100 chilometri),
					},
					'liter-per-kilometer' => {
						'name' => q(litri per chilometro),
						'one' => q({0} litro per chilometro),
						'other' => q({0} litri per chilometro),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					'megabit' => {
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					'megabyte' => {
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					'megaliter' => {
						'name' => q(megalitri),
						'one' => q({0} megalitro),
						'other' => q({0} megalitri),
					},
					'megawatt' => {
						'name' => q(megawatt),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					'meter' => {
						'name' => q(metri),
						'one' => q({0} metro),
						'other' => q({0} metri),
						'per' => q({0} per metro),
					},
					'meter-per-second' => {
						'name' => q(metri al secondo),
						'one' => q({0} metro al secondo),
						'other' => q({0} metri al secondo),
					},
					'meter-per-second-squared' => {
						'name' => q(metri al secondo quadrato),
						'one' => q({0} metro al secondo quadrato),
						'other' => q({0} metri al secondo quadrato),
					},
					'metric-ton' => {
						'name' => q(tonnellate metriche),
						'one' => q({0} tonnellata metrica),
						'other' => q({0} tonnellate metriche),
					},
					'microgram' => {
						'name' => q(microgrammi),
						'one' => q({0} microgrammo),
						'other' => q({0} microgrammi),
					},
					'micrometer' => {
						'name' => q(micrometri),
						'one' => q({0} micrometro),
						'other' => q({0} micrometri),
					},
					'microsecond' => {
						'name' => q(microsecondi),
						'one' => q({0} microsecondo),
						'other' => q({0} microsecondi),
					},
					'mile' => {
						'name' => q(miglia),
						'one' => q({0} miglio),
						'other' => q({0} miglia),
					},
					'mile-per-gallon' => {
						'name' => q(miglia per gallone),
						'one' => q({0} miglio per gallone),
						'other' => q({0} miglia per gallone),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(miglia per gallone imperiale),
						'one' => q({0} miglio per gallone imperiale),
						'other' => q({0} miglia per gallone imperiale),
					},
					'mile-per-hour' => {
						'name' => q(miglia all’ora),
						'one' => q({0} miglio all’ora),
						'other' => q({0} miglia all’ora),
					},
					'mile-scandinavian' => {
						'name' => q(miglia scandinave),
						'one' => q({0} miglio scandinavo),
						'other' => q({0} miglia scandinave),
					},
					'milliampere' => {
						'name' => q(milliampere),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milligrammi),
						'one' => q({0} milligrammo),
						'other' => q({0} milligrammi),
					},
					'milligram-per-deciliter' => {
						'name' => q(milligrammi per decilitro),
						'one' => q({0} milligrammo per decilitro),
						'other' => q({0} milligrammi per decilitro),
					},
					'milliliter' => {
						'name' => q(millilitri),
						'one' => q({0} millilitro),
						'other' => q({0} millilitri),
					},
					'millimeter' => {
						'name' => q(millimetri),
						'one' => q({0} millimetro),
						'other' => q({0} millimetri),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimetri di mercurio),
						'one' => q({0} millimetro di mercurio),
						'other' => q({0} millimetri di mercurio),
					},
					'millimole-per-liter' => {
						'name' => q(millimoli per litro),
						'one' => q({0} millimole per litro),
						'other' => q({0} millimoli per litro),
					},
					'millisecond' => {
						'name' => q(millisecondi),
						'one' => q({0} millisecondo),
						'other' => q({0} millisecondi),
					},
					'milliwatt' => {
						'name' => q(milliwatt),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwatt),
					},
					'minute' => {
						'name' => q(minuti),
						'one' => q({0} minuto),
						'other' => q({0} minuti),
						'per' => q({0} al minuto),
					},
					'month' => {
						'name' => q(mesi),
						'one' => q({0} mese),
						'other' => q({0} mesi),
						'per' => q({0} al mese),
					},
					'nanometer' => {
						'name' => q(nanometri),
						'one' => q({0} nanometro),
						'other' => q({0} nanometri),
					},
					'nanosecond' => {
						'name' => q(nanosecondi),
						'one' => q({0} nanosecondo),
						'other' => q({0} nanosecondi),
					},
					'nautical-mile' => {
						'name' => q(miglia nautiche),
						'one' => q({0} miglio nautico),
						'other' => q({0} miglia nautiche),
					},
					'ohm' => {
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					'ounce' => {
						'name' => q(once),
						'one' => q({0} oncia),
						'other' => q({0} once),
						'per' => q({0} per oncia),
					},
					'ounce-troy' => {
						'name' => q(once troy),
						'one' => q({0} oncia troy),
						'other' => q({0} once troy),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					'part-per-million' => {
						'name' => q(parti per milione),
						'one' => q({0} parte per milione),
						'other' => q({0} parti per milione),
					},
					'per' => {
						'1' => q({0} al {1}),
					},
					'percent' => {
						'name' => q(percentuale),
						'one' => q({0} percento),
						'other' => q({0} percento),
					},
					'permille' => {
						'name' => q(permille),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					'picometer' => {
						'name' => q(picometri),
						'one' => q({0} picometro),
						'other' => q({0} picometri),
					},
					'pint' => {
						'name' => q(pinte),
						'one' => q({0} pinta),
						'other' => q({0} pinte),
					},
					'pint-metric' => {
						'name' => q(pinte metriche),
						'one' => q({0} pinta metrica),
						'other' => q({0} pinte metriche),
					},
					'point' => {
						'name' => q(punti),
						'one' => q({0} punto),
						'other' => q({0} punti),
					},
					'pound' => {
						'name' => q(libbre),
						'one' => q({0} libbra),
						'other' => q({0} libbre),
						'per' => q({0} per libbra),
					},
					'pound-per-square-inch' => {
						'name' => q(libbre per pollice quadrato),
						'one' => q({0} libbra per pollice quadrato),
						'other' => q({0} libbre per pollice quadrato),
					},
					'quart' => {
						'name' => q(quarti),
						'one' => q({0} quarto),
						'other' => q({0} quarti),
					},
					'radian' => {
						'name' => q(radianti),
						'one' => q({0} radiante),
						'other' => q({0} radianti),
					},
					'revolution' => {
						'name' => q(rivoluzione),
						'one' => q({0} rivoluzione),
						'other' => q({0} rivoluzioni),
					},
					'second' => {
						'name' => q(secondi),
						'one' => q({0} secondo),
						'other' => q({0} secondi),
						'per' => q({0} al secondo),
					},
					'square-centimeter' => {
						'name' => q(centimetri quadrati),
						'one' => q({0} centimetro quadrato),
						'other' => q({0} centimetri quadrati),
						'per' => q({0} per centimetro quadrato),
					},
					'square-foot' => {
						'name' => q(piedi quadrati),
						'one' => q({0} piede quadrato),
						'other' => q({0} piedi quadrati),
					},
					'square-inch' => {
						'name' => q(pollici quadrati),
						'one' => q({0} pollice quadrato),
						'other' => q({0} pollici quadrati),
						'per' => q({0} per pollice quadrato),
					},
					'square-kilometer' => {
						'name' => q(chilometri quadrati),
						'one' => q({0} chilometro quadrato),
						'other' => q({0} chilometri quadrati),
						'per' => q({0} per chilometro quadrato),
					},
					'square-meter' => {
						'name' => q(metri quadrati),
						'one' => q({0} metro quadrato),
						'other' => q({0} metri quadrati),
						'per' => q({0} per metro quadrato),
					},
					'square-mile' => {
						'name' => q(miglia quadrate),
						'one' => q({0} miglio quadrato),
						'other' => q({0} miglia quadrate),
						'per' => q({0} per miglio quadrato),
					},
					'square-yard' => {
						'name' => q(iarde quadrate),
						'one' => q({0} iarda quadrata),
						'other' => q({0} iarde quadrate),
					},
					'tablespoon' => {
						'name' => q(cucchiai da tavola),
						'one' => q({0} cucchiaio da tavola),
						'other' => q({0} cucchiai da tavola),
					},
					'teaspoon' => {
						'name' => q(cucchiai da tè),
						'one' => q({0} cucchiaio da tè),
						'other' => q({0} cucchiai da tè),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					'ton' => {
						'name' => q(tonnellate),
						'one' => q({0} tonnellata),
						'other' => q({0} tonnellate),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					'week' => {
						'name' => q(settimane),
						'one' => q({0} settimana),
						'other' => q({0} settimane),
						'per' => q({0} alla settimana),
					},
					'yard' => {
						'name' => q(iarde),
						'one' => q({0} iarda),
						'other' => q({0} iarde),
					},
					'year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0} all’anno),
					},
				},
				'narrow' => {
					'' => {
						'name' => q(punto),
					},
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					'arc-minute' => {
						'one' => q({0}min),
						'other' => q({0}min),
					},
					'arc-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					'day' => {
						'name' => q(giorno),
						'one' => q({0} g),
						'other' => q({0}gg),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q({0}ft),
						'other' => q({0}ft),
					},
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					'hour' => {
						'name' => q(ora),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'inch-hg' => {
						'one' => q({0}inHg),
						'other' => q({0}inHg),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0}al),
						'other' => q({0}al),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(metro),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'mile' => {
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					'mile-per-hour' => {
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
					},
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0}min),
						'other' => q({0}min),
					},
					'month' => {
						'name' => q(mese),
						'one' => q({0} mese),
						'other' => q({0} mesi),
					},
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pound' => {
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
					},
					'square-foot' => {
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					'square-mile' => {
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(sett.),
						'one' => q({0}sett.),
						'other' => q({0}sett.),
					},
					'yard' => {
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(anno),
						'one' => q({0}anno),
						'other' => q({0}anni),
					},
				},
				'short' => {
					'' => {
						'name' => q(punto),
					},
					'acre' => {
						'name' => q(acri),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(staia),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(carati),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(sec.),
						'one' => q({0} sec.),
						'other' => q({0} secc.),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(giorni),
						'one' => q({0} giorno),
						'other' => q({0} giorni),
						'per' => q({0}/giorno),
					},
					'deciliter' => {
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(forza g),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(Gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(grammi),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(ettari),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(al),
						'one' => q({0} al),
						'other' => q({0} al),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(miglia),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mi/Imp gal),
						'one' => q({0} mi/Imp gal),
						'other' => q({0} mi/Imp gal),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					'milliliter' => {
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(mesi),
						'one' => q({0} mese),
						'other' => q({0} mesi),
						'per' => q({0}/mese),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(ozt),
						'one' => q({0} ozt),
						'other' => q({0} ozt),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0} ppm),
						'other' => q({0} ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'percent' => {
						'name' => q(percento),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					'permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					'petabyte' => {
						'name' => q(PByte),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'point' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(riv),
						'one' => q({0} riv),
						'other' => q({0} riv),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(piedi quadrati),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(settimane),
						'one' => q({0} settimana),
						'other' => q({0} settimane),
						'per' => q({0}/settimana),
					},
					'yard' => {
						'name' => q(iarde),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(anni),
						'one' => q({0} anno),
						'other' => q({0} anni),
						'per' => q({0}/anno),
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
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} e {1}),
				2 => q({0} e {1}),
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
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
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
					'one' => '0 Mrd',
					'other' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
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
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 mille',
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
					'one' => '0 Mrd',
					'other' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
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
				'currency' => q(peseta andorrana),
			},
		},
		'AED' => {
			symbol => 'AED',
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
			symbol => 'AFN',
			display_name => {
				'currency' => q(afghani),
				'one' => q(afghani),
				'other' => q(afghani),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(lek albanese),
				'one' => q(lek albanese),
				'other' => q(lekë albanesi),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram armeno),
				'one' => q(dram armeno),
				'other' => q(dram armeni),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(fiorino delle Antille olandesi),
				'one' => q(fiorino delle Antille olandesi),
				'other' => q(fiorino delle Antille olandesi),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
			symbol => 'ARS',
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
			symbol => 'A$',
			display_name => {
				'currency' => q(dollaro australiano),
				'one' => q(dollaro australiano),
				'other' => q(dollari australiani),
			},
		},
		'AWG' => {
			symbol => 'AWG',
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
			symbol => 'AZN',
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
			symbol => 'BAM',
			display_name => {
				'currency' => q(marco convertibile della Bosnia-Herzegovina),
				'one' => q(marco convertibile della Bosnia-Herzegovina),
				'other' => q(marchi convertibili della Bosnia-Herzegovina),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dollaro di Barbados),
				'one' => q(dollaro di Barbados),
				'other' => q(dollari di Barbados),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
			symbol => 'BGN',
			display_name => {
				'currency' => q(lev bulgaro),
				'one' => q(lev bulgaro),
				'other' => q(leva bulgari),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinaro del Bahrein),
				'one' => q(dinaro del Bahrein),
				'other' => q(dinari del Bahrein),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(franco del Burundi),
				'one' => q(franco del Burundi),
				'other' => q(franchi del Burundi),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dollaro delle Bermuda),
				'one' => q(dollaro delle Bermuda),
				'other' => q(dollari delle Bermuda),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dollaro del Brunei),
				'one' => q(dollaro del Brunei),
				'other' => q(dollari del Brunei),
			},
		},
		'BOB' => {
			symbol => 'BOB',
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
			symbol => 'BSD',
			display_name => {
				'currency' => q(dollaro delle Bahamas),
				'one' => q(dollaro delle Bahamas),
				'other' => q(dollari delle Bahamas),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula del Botswana),
				'one' => q(pula del Botswana),
				'other' => q(pula del Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(nuovo rublo bielorusso \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(rublo bielorusso),
				'one' => q(rublo bielorusso),
				'other' => q(rubli bielorussi),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(rublo bielorusso \(2000–2016\)),
				'one' => q(rublo bielorusso \(2000–2016\)),
				'other' => q(rubli bielorussi \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(dollaro del Belize),
				'one' => q(dollaro del Belize),
				'other' => q(dollari del Belize),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(dollaro canadese),
				'one' => q(dollaro canadese),
				'other' => q(dollari canadesi),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(franco congolese),
				'one' => q(franco congolese),
				'other' => q(franchi congolesi),
			},
		},
		'CHF' => {
			symbol => 'CHF',
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
			symbol => 'CLP',
			display_name => {
				'currency' => q(peso cileno),
				'one' => q(peso cileno),
				'other' => q(pesos cileni),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(CNH),
				'one' => q(CNH),
				'other' => q(CNH),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(renminbi cinese),
				'one' => q(renmimbi cinese),
				'other' => q(renmimbi cinesi),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(peso colombiano),
				'one' => q(peso colombiano),
				'other' => q(pesos colombiani),
			},
		},
		'CRC' => {
			symbol => 'CRC',
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
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso cubano convertibile),
				'one' => q(peso cubano convertibile),
				'other' => q(pesos cubani convertibili),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso cubano),
				'one' => q(peso cubano),
				'other' => q(pesos cubani),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
			symbol => 'CZK',
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
			symbol => 'DJF',
			display_name => {
				'currency' => q(franco di Gibuti),
				'one' => q(franco di Gibuti),
				'other' => q(franchi di Gibuti),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(corona danese),
				'one' => q(corona danese),
				'other' => q(corone danesi),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominicano),
				'one' => q(peso dominicano),
				'other' => q(pesos dominicani),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
			symbol => 'EGP',
			display_name => {
				'currency' => q(sterlina egiziana),
				'one' => q(sterlina egiziana),
				'other' => q(sterline egiziane),
			},
		},
		'ERN' => {
			symbol => 'ERN',
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
			symbol => 'ETB',
			display_name => {
				'currency' => q(birr etiope),
				'one' => q(birr etiope),
				'other' => q(birr etiopi),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(markka finlandese),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(dollaro delle Figi),
				'one' => q(dollaro delle Figi),
				'other' => q(dollari delle Figi),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
			symbol => '£',
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
			symbol => 'GEL',
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
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi ghanese),
				'one' => q(cedi ghanese),
				'other' => q(cedi ghanesi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(sterlina di Gibilterra),
				'one' => q(sterlina di Gibilterra),
				'other' => q(sterline di Gibilterra),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi gambiano),
				'one' => q(dalasi gambiano),
				'other' => q(dalasi gambiani),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
			symbol => 'GTQ',
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
			symbol => 'GYD',
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
			symbol => 'HNL',
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
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna croata),
				'one' => q(kuna croata),
				'other' => q(kune croate),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gourde haitiano),
				'one' => q(gourde haitiano),
				'other' => q(gourde haitiani),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(fiorino ungherese),
				'one' => q(fiorino ungherese),
				'other' => q(fiorini ungheresi),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
			symbol => '₪',
			display_name => {
				'currency' => q(nuovo siclo israeliano),
				'one' => q(nuovo siclo israeliano),
				'other' => q(nuovi sicli israeliani),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(rupia indiana),
				'one' => q(rupia indiana),
				'other' => q(rupie indiane),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinaro iracheno),
				'one' => q(dinaro iracheno),
				'other' => q(dinari iracheni),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(rial iraniano),
				'one' => q(rial iraniano),
				'other' => q(rial iraniani),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(corona islandese),
				'one' => q(corona islandese),
				'other' => q(corone islandesi),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiana),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(dollaro giamaicano),
				'one' => q(dollaro giamaicano),
				'other' => q(dollari giamaicani),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(scellino keniota),
				'one' => q(scellino keniota),
				'other' => q(scellini keniota),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som kirghiso),
				'one' => q(som kirghiso),
				'other' => q(som kirghisi),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel cambogiano),
				'one' => q(riel cambogiano),
				'other' => q(riel cambogiani),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franco comoriano),
				'one' => q(franco comoriano),
				'other' => q(franchi comoriani),
			},
		},
		'KPW' => {
			symbol => 'KPW',
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
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinaro kuwaitiano),
				'one' => q(dinaro kuwaitiano),
				'other' => q(dinari kuwaitiani),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dollaro delle Isole Cayman),
				'one' => q(dollaro delle Isole Cayman),
				'other' => q(dollari delle Isole Cayman),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tenge kazako),
				'one' => q(tenge kazako),
				'other' => q(tenge kazaki),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip laotiano),
				'one' => q(kip laotiano),
				'other' => q(kip laotiani),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(lira libanese),
				'one' => q(lira libanese),
				'other' => q(lire libanesi),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(rupia di Sri Lanka),
				'one' => q(rupia di Sri Lanka),
				'other' => q(rupie di Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dollaro liberiano),
				'one' => q(dollaro liberiano),
				'other' => q(dollari liberiani),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti del Lesotho),
			},
		},
		'LTL' => {
			symbol => 'LTL',
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
			symbol => 'LVL',
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
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinaro libico),
				'one' => q(dinaro libico),
				'other' => q(dinari libici),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
			symbol => 'MDL',
			display_name => {
				'currency' => q(leu moldavo),
				'one' => q(leu moldavo),
				'other' => q(lei moldavi),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
			symbol => 'MKD',
			display_name => {
				'currency' => q(denar macedone),
				'one' => q(dinaro macedone),
				'other' => q(dinari macedoni),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franco di Mali),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat di Myanmar),
				'one' => q(kyat di Myanmar),
				'other' => q(kyat di Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik mongolo),
				'one' => q(tugrik mongolo),
				'other' => q(tugrik mongoli),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca di Macao),
				'one' => q(pataca di Macao),
				'other' => q(patacas di Macao),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(ouguiya della Mauritania \(1973–2017\)),
				'one' => q(ouguiya della Mauritania \(1973–2017\)),
				'other' => q(ouguiya della Mauritania \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(ouguiya della Mauritania),
				'one' => q(ouguiya della Mauritania),
				'other' => q(ouguiya della Mauritania),
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
			symbol => 'MUR',
			display_name => {
				'currency' => q(rupia mauriziana),
				'one' => q(rupia mauriziana),
				'other' => q(rupie mauriziane),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rufiyaa delle Maldive),
				'one' => q(rufiyaa delle Maldive),
				'other' => q(rufiyaa delle Maldive),
			},
		},
		'MWK' => {
			symbol => 'MWK',
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
			symbol => 'MYR',
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
			symbol => 'MZN',
			display_name => {
				'currency' => q(metical mozambicano),
				'one' => q(metical mozambicano),
				'other' => q(metical mozambicani),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(dollaro namibiano),
				'one' => q(dollaro namibiano),
				'other' => q(dollari namibiani),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira nigeriana),
				'one' => q(naira nigeriana),
				'other' => q(naire nigeriane),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba nicaraguense),
				'one' => q(cordoba nicaraguense),
				'other' => q(cordoba nicaraguense),
			},
		},
		'NIO' => {
			symbol => 'NIO',
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
			symbol => 'NOK',
			display_name => {
				'currency' => q(corona norvegese),
				'one' => q(corona norvegese),
				'other' => q(corone norvegesi),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(rupia nepalese),
				'one' => q(rupia nepalese),
				'other' => q(rupie nepalesi),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(dollaro neozelandese),
				'one' => q(dollaro neozelandese),
				'other' => q(dollari neozelandesi),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(rial omanita),
				'one' => q(rial omanita),
				'other' => q(rial omaniti),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
			symbol => 'PEN',
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
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina papuana),
				'one' => q(kina papuana),
				'other' => q(kina papuane),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filippino),
				'one' => q(peso filippino),
				'other' => q(pesos filippini),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(rupia pakistana),
				'one' => q(rupia pakistana),
				'other' => q(rupie pakistane),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(złoty polacco),
				'one' => q(złoty polacco),
				'other' => q(złoty polacchi),
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
			symbol => 'PYG',
			display_name => {
				'currency' => q(guaraní paraguayano),
				'one' => q(guaraní paraguayano),
				'other' => q(guaraní paraguayani),
			},
		},
		'QAR' => {
			symbol => 'QAR',
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
			symbol => 'RON',
			display_name => {
				'currency' => q(leu rumeno),
				'one' => q(leu rumeno),
				'other' => q(lei rumeni),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinaro serbo),
				'one' => q(dinaro serbo),
				'other' => q(dinara serbi),
			},
		},
		'RUB' => {
			symbol => 'RUB',
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
			symbol => 'RWF',
			display_name => {
				'currency' => q(franco ruandese),
				'one' => q(franco ruandese),
				'other' => q(franchi ruandesi),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(riyal saudita),
				'one' => q(riyal saudita),
				'other' => q(riyal sauditi),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dollaro delle Isole Salomone),
				'one' => q(dollaro delle Isole Salomone),
				'other' => q(dollari delle Isole Salomone),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
			symbol => 'SDG',
			display_name => {
				'currency' => q(sterlina sudanese),
				'one' => q(sterlina sudanese),
				'other' => q(sterline sudanesi),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(corona svedese),
				'one' => q(corona svedese),
				'other' => q(corone svedesi),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dollaro di Singapore),
				'one' => q(dollaro di Singapore),
				'other' => q(dollari di Singapore),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone della Sierra Leone),
				'one' => q(leone della Sierra Leone),
				'other' => q(leoni della Sierra Leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(scellino somalo),
				'one' => q(scellino somalo),
				'other' => q(scellini somali),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
			symbol => 'SSP',
			display_name => {
				'currency' => q(sterlina sud-sudanese),
				'one' => q(sterlina sud-sudanese),
				'other' => q(sterline sud-sudanesi),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra di Sao Tomé e Principe \(1977–2017\)),
				'one' => q(dobra di Sao Tomé e Principe \(1977–2017\)),
				'other' => q(dobra di Sao Tomé e Principe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra di Sao Tomé e Príncipe),
				'one' => q(dobra di Sao Tomé e Príncipe),
				'other' => q(dobra di Sao Tomé e Príncipe),
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
			symbol => 'SYP',
			display_name => {
				'currency' => q(lira siriana),
				'one' => q(lira siriana),
				'other' => q(lire siriane),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni dello Swaziland),
				'one' => q(lilangeni dello Swaziland),
				'other' => q(lilangeni dello Swaziland),
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
			symbol => 'TJS',
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
			symbol => 'TMT',
			display_name => {
				'currency' => q(manat turkmeno),
				'one' => q(manat turkmeno),
				'other' => q(manat turkmeni),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinaro tunisino),
				'one' => q(dinaro tunisino),
				'other' => q(dinari tunisini),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
			symbol => 'TRY',
			display_name => {
				'currency' => q(lira turca),
				'one' => q(lira turca),
				'other' => q(lire turche),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(scellino della Tanzania),
				'one' => q(scellino della Tanzania),
				'other' => q(scellini della Tanzania),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
			symbol => 'UGX',
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
			symbol => 'UYU',
			display_name => {
				'currency' => q(peso uruguayano),
				'one' => q(peso uruguayano),
				'other' => q(pesos uruguayani),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
			symbol => 'VEF',
			display_name => {
				'currency' => q(bolívar venezuelano \(2008–2018\)),
				'one' => q(bolívar venezuelano \(2008–2018\)),
				'other' => q(bolívares venezuelani \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(bolívar venezuelano),
				'one' => q(bolívar venezuelano),
				'other' => q(bolívares venezuelani),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dong vietnamita),
				'one' => q(dong vietnamita),
				'other' => q(dong vietnamiti),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu di Vanuatu),
				'one' => q(vatu di Vanuatu),
				'other' => q(vatu di Vanuatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala samoano),
				'one' => q(tala samoano),
				'other' => q(tala samoani),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
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
			symbol => 'EC$',
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
			symbol => 'CFA',
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
			symbol => 'CFPF',
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
			symbol => 'YER',
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
			symbol => 'ZAR',
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
			symbol => 'ZMW',
			display_name => {
				'currency' => q(kwacha dello Zambia),
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
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'G',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
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
					abbreviated => {
						mon => 'lun',
						tue => 'mar',
						wed => 'mer',
						thu => 'gio',
						fri => 'ven',
						sat => 'sab',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'G',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1º trimestre',
						1 => '2º trimestre',
						2 => '3º trimestre',
						3 => '4º trimestre'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'night1' if $time >= 0
						&& $time < 600;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'morning1' if $time >= 600
						&& $time < 1200;
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

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'night1' => q{di notte},
					'pm' => q{PM},
					'midnight' => q{mezzanotte},
					'am' => q{AM},
					'noon' => q{mezzogiorno},
					'afternoon1' => q{del pomeriggio},
					'evening1' => q{di sera},
					'morning1' => q{di mattina},
				},
				'narrow' => {
					'noon' => q{mezzogiorno},
					'afternoon1' => q{del pomeriggio},
					'evening1' => q{di sera},
					'morning1' => q{di mattina},
					'night1' => q{di notte},
					'pm' => q{p.},
					'midnight' => q{mezzanotte},
					'am' => q{m.},
				},
				'wide' => {
					'night1' => q{di notte},
					'pm' => q{PM},
					'midnight' => q{mezzanotte},
					'am' => q{AM},
					'afternoon1' => q{del pomeriggio},
					'noon' => q{mezzogiorno},
					'evening1' => q{di sera},
					'morning1' => q{di mattina},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'night1' => q{notte},
					'am' => q{AM},
					'pm' => q{PM},
					'midnight' => q{mezzanotte},
					'afternoon1' => q{pomeriggio},
					'noon' => q{mezzogiorno},
					'morning1' => q{mattina},
					'evening1' => q{sera},
				},
				'narrow' => {
					'am' => q{m.},
					'pm' => q{p.},
					'midnight' => q{mezzanotte},
					'night1' => q{notte},
					'morning1' => q{mattina},
					'evening1' => q{sera},
					'noon' => q{mezzogiorno},
					'afternoon1' => q{pomeriggio},
				},
				'wide' => {
					'am' => q{AM},
					'pm' => q{PM},
					'midnight' => q{mezzanotte},
					'night1' => q{notte},
					'morning1' => q{mattina},
					'evening1' => q{sera},
					'noon' => q{mezzogiorno},
					'afternoon1' => q{pomeriggio},
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
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
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
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{dd MMMM y G},
			'medium' => q{dd MMM y G},
			'short' => q{dd/MM/yy GGGGG},
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
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
			'full' => q{{1} 'alle' {0}},
			'long' => q{{1} 'alle' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMW => q{'settimana' W 'di' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'settimana' w 'del' Y},
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
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E d/M},
			MMM => q{LLL},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{hh a},
			hm => q{hh:mm a},
			hms => q{hh:mm:ss a},
			ms => q{mm:ss},
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
				H => q{HH:mm–HH:mm},
				m => q{HH:mm–HH:mm},
			},
			Hmv => {
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y},
				d => q{dd–dd MMM y},
				y => q{dd MMM y – dd MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
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
				H => q{HH:mm–HH:mm v},
				m => q{HH:mm–HH:mm v},
			},
			Hv => {
				H => q{HH–HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E dd MMM – E dd MMM},
				d => q{E dd – E dd MMM},
			},
			MMMd => {
				M => q{dd MMM – dd MMM},
				d => q{dd–dd MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
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
				y => q{y–y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y G},
				d => q{E dd/MM/y – E dd/MM/y G},
				y => q{E dd/MM/y – E dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{dd MMM – dd MMM y G},
				d => q{dd–dd MMM y G},
				y => q{dd MMM y – dd MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
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
		regionFormat => q(Ora {0}),
		regionFormat => q(Ora legale: {0}),
		regionFormat => q(Ora standard: {0}),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Ora dell’Afghanistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algeri#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Il Cairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Gibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Ayun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Giuba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputo#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabane#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunisi#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
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
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Caienna#,
		},
		'America/Cayman' => {
			exemplarCity => q#Cayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Cordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rica#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominica#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Salvador#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fort Nelson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#L’Avana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Giamaica#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceio#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Città del Messico#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
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
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portorico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Paolo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
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
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
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
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syowa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
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
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
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
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr’#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aqtau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ashgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnaul#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Colombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dacca#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagosta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Giacarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Gerusalemme#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karachi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwait#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nicosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzneck#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Oral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Penh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
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
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapore#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tashkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulaanbaatar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust’-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
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
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
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
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
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
		'Choibalsan' => {
			long => {
				'daylight' => q#Ora legale di Choibalsan#,
				'generic' => q#Ora di Choibalsan#,
				'standard' => q#Ora standard di Choibalsan#,
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
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxelles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
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
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isola di Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
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
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monaco#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosca#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parigi#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Sinferopoli#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stoccolma#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Città del Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienna#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsavia#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zagabria#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporozhye#,
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
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Natale#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Comore#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kerguelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldive#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mauritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
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
		'Macquarie' => {
			long => {
				'standard' => q#Ora dell’Isola Macquarie#,
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
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Ora legale del Messico nord-occidentale#,
				'generic' => q#Ora del Messico nord-occidentale#,
				'standard' => q#Ora standard del Messico nord-occidentale#,
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
				'standard' => q#Ora delle Isole Norfolk#,
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
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasqua#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Figi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Marchesi#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nauru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niue#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
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
	 } }
);
no Moo;

1;

# vim: tabstop=4
