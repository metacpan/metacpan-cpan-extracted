=encoding utf8

=head1 NAME

Locale::CLDR::Locales::No - Package for language Norwegian

=cut

package Locale::CLDR::Locales::No;
# This file auto generated from Data\common\main\no.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-neuter','spellout-ordinal-masculine','spellout-ordinal-neuter','spellout-ordinal-feminine','spellout-ordinal-plural' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'and-small' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(og =%%spellout-cardinal-reale=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%%spellout-cardinal-reale=),
				},
			},
		},
		'and-small-f' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(og =%spellout-cardinal-feminine=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-feminine=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-feminine=),
				},
			},
		},
		'and-small-n' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(og =%spellout-cardinal-neuter=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(=%spellout-cardinal-neuter=),
				},
			},
		},
		'ord-fem-de' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-fem-nde' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ende),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-fem-te' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-fem-teer' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-masc-de' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-masc-nde' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ende),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-masc-te' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-masc-teer' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-neut-de' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-neut-nde' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ende),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-neut-te' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-neut-teer' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-plural-de' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(de),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-plural=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-plural=),
				},
			},
		},
		'ord-plural-nde' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ende),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-plural=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(­=%spellout-ordinal-plural=),
				},
			},
		},
		'ord-plural-te' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-plural=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-plural=),
				},
			},
		},
		'ord-plural-teer' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(te),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-plural=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(er =%spellout-ordinal-plural=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ei),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-reale=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundre[ og →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundre[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusen[ →%%and-small-f→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusen[ →%%and-small-f→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← millioner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billioner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiarder[ →→]),
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ett),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-reale=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundre[ og →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundre[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusen[ →%%and-small-n→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusen[ →%%and-small-n→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← millioner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billioner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiarder[ →→]),
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
		'spellout-cardinal-reale' => {
			'private' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(én),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(to),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tre),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fire),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fem),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(seks),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sju),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åtte),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ni),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ti),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(elleve),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolv),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(tretten),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(fjorten),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(femten),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(seksten),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sytten),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(atten),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nitten),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti[­→→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti[­→→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti[­→→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti[­→→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(hundre[ og →→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-neuter← hundre[ og →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(tusen[ →%%and-small→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-neuter← tusen[ →%%and-small→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←← millioner[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←← milliarder[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←← billioner[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← billiarder[ →→]),
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
					rule => q(=%%spellout-cardinal-reale=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-reale=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1100' => {
					base_value => q(1100),
					divisor => q(100),
					rule => q(←←­hundre[ og →→]),
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
		'spellout-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(første),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(andre),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tredje),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjerde),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(femte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sjette),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjuende),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åttende),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(niende),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tiende),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellevte),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolvte),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue→%%ord-fem-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti→%%ord-fem-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti→%%ord-fem-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti→%%ord-fem-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti→%%ord-fem-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti→%%ord-fem-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti→%%ord-fem-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti→%%ord-fem-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundre→%%ord-fem-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering←­tusen→%%ord-fem-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million→%%ord-fem-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← million→%%ord-fem-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard→%%ord-fem-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliard→%%ord-fem-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion→%%ord-fem-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billion→%%ord-fem-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard→%%ord-fem-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiard→%%ord-fem-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(første),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(andre),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tredje),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjerde),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(femte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sjette),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjuende),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åttende),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(niende),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tiende),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellevte),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolvte),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue→%%ord-masc-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti→%%ord-masc-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti→%%ord-masc-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti→%%ord-masc-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti→%%ord-masc-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti→%%ord-masc-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti→%%ord-masc-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti→%%ord-masc-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundre→%%ord-masc-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering←­tusen→%%ord-masc-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million→%%ord-masc-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← million→%%ord-masc-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard→%%ord-masc-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliard→%%ord-masc-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion→%%ord-masc-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billion→%%ord-masc-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard→%%ord-masc-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiard→%%ord-masc-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(første),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(andre),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tredje),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjerde),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(femte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sjette),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjuende),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åttende),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(niende),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tiende),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellevte),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolvte),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue→%%ord-neut-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti→%%ord-neut-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti→%%ord-neut-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti→%%ord-neut-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti→%%ord-neut-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti→%%ord-neut-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti→%%ord-neut-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti→%%ord-neut-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundre→%%ord-neut-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering←­tusen→%%ord-neut-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million→%%ord-neut-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← million→%%ord-neut-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard→%%ord-neut-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliard→%%ord-neut-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion→%%ord-neut-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billion→%%ord-neut-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard→%%ord-neut-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiard→%%ord-neut-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
			},
		},
		'spellout-ordinal-plural' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullte),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(første),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(andre),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tredje),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(fjerde),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(femte),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sjette),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sjuende),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(åttende),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(niende),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(tiende),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ellevte),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(tolvte),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=de),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(tjue→%%ord-plural-nde→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tretti→%%ord-plural-nde→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(førti→%%ord-plural-nde→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(femti→%%ord-plural-nde→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seksti→%%ord-plural-nde→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(sytti→%%ord-plural-nde→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(åtti→%%ord-plural-nde→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nitti→%%ord-plural-nde→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering←­hundre→%%ord-plural-de→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering←­tusen→%%ord-plural-de→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(én million→%%ord-plural-te→),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%%spellout-cardinal-reale← million→%%ord-plural-teer→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(én milliard→%%ord-plural-te→),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%%spellout-cardinal-reale← milliard→%%ord-plural-teer→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(én billion→%%ord-plural-te→),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%%spellout-cardinal-reale← billion→%%ord-plural-teer→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(én billiard→%%ord-plural-te→),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%spellout-cardinal-reale← billiard→%%ord-plural-teer→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
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
 				'ab' => 'abkhasisk',
 				'ace' => 'achinesisk',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adygeisk',
 				'ae' => 'avestisk',
 				'aeb' => 'tunisisk-arabisk',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'akkadisk',
 				'akz' => 'alabama',
 				'ale' => 'aleutisk',
 				'aln' => 'gegisk-albansk',
 				'alt' => 'søraltaisk',
 				'am' => 'amharisk',
 				'an' => 'aragonsk',
 				'ang' => 'gammelengelsk',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabisk',
 				'ar_001' => 'moderne standardarabisk',
 				'arc' => 'arameisk',
 				'arn' => 'mapudungun',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'algerisk arabisk',
 				'ars' => 'najdi-arabisk',
 				'ars@alt=menu' => 'arabisk (najdi)',
 				'arw' => 'arawak',
 				'ary' => 'marokkansk-arabisk',
 				'arz' => 'egyptisk arabisk',
 				'as' => 'assamesisk',
 				'asa' => 'asu',
 				'ase' => 'amerikansk tegnspråk',
 				'ast' => 'asturisk',
 				'atj' => 'atikamekw',
 				'av' => 'avarisk',
 				'avk' => 'kotava',
 				'awa' => 'avadhi',
 				'ay' => 'aymara',
 				'az' => 'aserbajdsjansk',
 				'az@alt=short' => 'azeri',
 				'ba' => 'basjkirsk',
 				'bal' => 'baluchi',
 				'ban' => 'balinesisk',
 				'bar' => 'bairisk',
 				'bas' => 'basaa',
 				'bax' => 'bamun',
 				'bbc' => 'batak toba',
 				'bbj' => 'ghomala',
 				'be' => 'belarusisk',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'bulgarsk',
 				'bgc' => 'haryanvi',
 				'bgn' => 'vestbalutsji',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'blo' => 'anii',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetansk',
 				'bpy' => 'bishnupriya',
 				'bqi' => 'bakhtiari',
 				'br' => 'bretonsk',
 				'bra' => 'braj',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosnisk',
 				'bss' => 'akose',
 				'bua' => 'burjatisk',
 				'bug' => 'buginesisk',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'katalansk',
 				'cad' => 'caddo',
 				'car' => 'karibisk',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ccp' => 'chakma',
 				'ce' => 'tsjetsjensk',
 				'ceb' => 'cebuano',
 				'cgg' => 'kiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'tsjagatai',
 				'chk' => 'chuukesisk',
 				'chm' => 'mari',
 				'chn' => 'chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewiansk',
 				'chr' => 'cherokesisk',
 				'chy' => 'cheyenne',
 				'ckb' => 'sentralkurdisk',
 				'ckb@alt=menu' => 'kurdisk (sentral)',
 				'ckb@alt=variant' => 'kurdisk (sorani)',
 				'clc' => 'chilcotin',
 				'co' => 'korsikansk',
 				'cop' => 'koptisk',
 				'cps' => 'kapiz',
 				'cr' => 'cree',
 				'crg' => 'michif',
 				'crh' => 'krimtatarisk',
 				'crj' => 'sørlig østcree',
 				'crk' => 'prærie-cree',
 				'crl' => 'nordlig østcree',
 				'crm' => 'moose cree',
 				'crr' => 'carolinsk-algonkinsk',
 				'crs' => 'seselwa',
 				'cs' => 'tsjekkisk',
 				'csb' => 'kasjubisk',
 				'csw' => 'myr-cree',
 				'cu' => 'kirkeslavisk',
 				'cv' => 'tsjuvasjisk',
 				'cy' => 'walisisk',
 				'da' => 'dansk',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'tysk',
 				'del' => 'delaware',
 				'den' => 'slavey',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'lavsorbisk',
 				'dtp' => 'sentraldusun',
 				'dua' => 'duala',
 				'dum' => 'mellomnederlandsk',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'kiembu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emiliansk',
 				'egy' => 'gammelegyptisk',
 				'eka' => 'ekajuk',
 				'el' => 'gresk',
 				'elx' => 'elamittisk',
 				'en' => 'engelsk',
 				'enm' => 'mellomengelsk',
 				'eo' => 'esperanto',
 				'es' => 'spansk',
 				'esu' => 'sentralyupik',
 				'et' => 'estisk',
 				'eu' => 'baskisk',
 				'ewo' => 'ewondo',
 				'ext' => 'ekstremaduransk',
 				'fa' => 'persisk',
 				'fa_AF' => 'dari',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulfulde',
 				'fi' => 'finsk',
 				'fil' => 'filipino',
 				'fit' => 'tornedalsfinsk',
 				'fj' => 'fijiansk',
 				'fo' => 'færøysk',
 				'fon' => 'fon',
 				'fr' => 'fransk',
 				'frc' => 'cajunfransk',
 				'frm' => 'mellomfransk',
 				'fro' => 'gammelfransk',
 				'frp' => 'arpitansk',
 				'frr' => 'nordfrisisk',
 				'frs' => 'østfrisisk',
 				'fur' => 'friuliansk',
 				'fy' => 'vestfrisisk',
 				'ga' => 'irsk',
 				'gaa' => 'ga',
 				'gag' => 'gagausisk',
 				'gan' => 'gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gbz' => 'zoroastrisk dari',
 				'gd' => 'skotsk-gælisk',
 				'gez' => 'geez',
 				'gil' => 'kiribatisk',
 				'gl' => 'galisisk',
 				'glk' => 'gileki',
 				'gmh' => 'mellomhøytysk',
 				'gn' => 'guarani',
 				'goh' => 'gammelhøytysk',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'gotisk',
 				'grb' => 'grebo',
 				'grc' => 'gammelgresk',
 				'gsw' => 'sveitsertysk',
 				'gu' => 'gujarati',
 				'guc' => 'wayuu',
 				'gur' => 'frafra',
 				'guz' => 'gusii',
 				'gv' => 'mansk',
 				'gwi' => 'gwich’in',
 				'ha' => 'hausa',
 				'hai' => 'haida',
 				'hak' => 'hakka',
 				'haw' => 'hawaiisk',
 				'hax' => 'sørlig haida',
 				'he' => 'hebraisk',
 				'hi' => 'hindi',
 				'hi_Latn@alt=variant' => 'hinglish',
 				'hif' => 'fijiansk hindi',
 				'hil' => 'hiligaynon',
 				'hit' => 'hettittisk',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'kroatisk',
 				'hsb' => 'høysorbisk',
 				'hsn' => 'xiang',
 				'ht' => 'haitisk',
 				'hu' => 'ungarsk',
 				'hup' => 'hupa',
 				'hur' => 'halkomelem',
 				'hy' => 'armensk',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesisk',
 				'ie' => 'interlingue',
 				'ig' => 'ibo',
 				'ii' => 'sichuan-yi',
 				'ik' => 'inupiak',
 				'ikt' => 'vestlig kanadisk inuktitut',
 				'ilo' => 'iloko',
 				'inh' => 'ingusjisk',
 				'io' => 'ido',
 				'is' => 'islandsk',
 				'it' => 'italiensk',
 				'iu' => 'inuktitut',
 				'izh' => 'ingrisk',
 				'ja' => 'japansk',
 				'jam' => 'jamaicansk kreolengelsk',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'jødepersisk',
 				'jrb' => 'jødearabisk',
 				'jut' => 'jysk',
 				'jv' => 'javanesisk',
 				'ka' => 'georgisk',
 				'kaa' => 'karakalpakisk',
 				'kab' => 'kabylsk',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardisk',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kappverdisk',
 				'ken' => 'kenyang',
 				'kfo' => 'koro',
 				'kg' => 'kikongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotanesisk',
 				'khq' => 'koyra chiini',
 				'khw' => 'khowar',
 				'ki' => 'kikuyu',
 				'kiu' => 'kirmancki',
 				'kj' => 'kuanyama',
 				'kk' => 'kasakhisk',
 				'kkj' => 'kako',
 				'kl' => 'grønlandsk',
 				'kln' => 'kalenjin',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreansk',
 				'koi' => 'komipermjakisk',
 				'kok' => 'konkani',
 				'kos' => 'kosraeansk',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karatsjajbalkarsk',
 				'kri' => 'krio',
 				'krj' => 'kinaray-a',
 				'krl' => 'karelsk',
 				'kru' => 'kurukh',
 				'ks' => 'kasjmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kølnsk',
 				'ku' => 'kurdisk',
 				'kum' => 'kumykisk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'kornisk',
 				'kwk' => 'kwak̓wala',
 				'kxv' => 'kuvi',
 				'ky' => 'kirgisisk',
 				'la' => 'latin',
 				'lad' => 'ladinsk',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgsk',
 				'lez' => 'lesgisk',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'ganda',
 				'li' => 'limburgsk',
 				'lij' => 'ligurisk',
 				'lil' => 'lillooet',
 				'liv' => 'livisk',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardisk',
 				'ln' => 'lingala',
 				'lo' => 'laotisk',
 				'lol' => 'mongo',
 				'lou' => 'louisianakreolsk',
 				'loz' => 'lozi',
 				'lrc' => 'nord-luri',
 				'lsm' => 'samia',
 				'lt' => 'litauisk',
 				'ltg' => 'latgallisk',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'lus' => 'mizo',
 				'luy' => 'luhya',
 				'lv' => 'latvisk',
 				'lzh' => 'klassisk kinesisk',
 				'lzz' => 'lazisk',
 				'mad' => 'maduresisk',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'moksja',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'mauritisk-kreolsk',
 				'mg' => 'gassisk',
 				'mga' => 'mellomirsk',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallesisk',
 				'mi' => 'maori',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedonsk',
 				'ml' => 'malayalam',
 				'mn' => 'mongolsk',
 				'mnc' => 'mandsju',
 				'mni' => 'manipuri',
 				'moe' => 'innu-aimun',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'mrj' => 'vestmarisk',
 				'ms' => 'malayisk',
 				'mt' => 'maltesisk',
 				'mua' => 'mundang',
 				'mul' => 'flere språk',
 				'mus' => 'creek',
 				'mwl' => 'mirandesisk',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'my' => 'burmesisk',
 				'mye' => 'myene',
 				'myv' => 'erzia',
 				'mzn' => 'mazandarani',
 				'na' => 'nauru',
 				'nan' => 'minnan',
 				'nap' => 'napolitansk',
 				'naq' => 'nama',
 				'nb' => 'norsk bokmål',
 				'nd' => 'nord-ndebele',
 				'nds' => 'nedertysk',
 				'nds_NL' => 'nedersaksisk',
 				'ne' => 'nepali',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueansk',
 				'njo' => 'ao naga',
 				'nl' => 'nederlandsk',
 				'nl_BE' => 'flamsk',
 				'nmg' => 'kwasio',
 				'nn' => 'norsk nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norsk',
 				'nog' => 'nogaisk',
 				'non' => 'gammelnorsk',
 				'nov' => 'novial',
 				'nqo' => 'nʼko',
 				'nr' => 'sør-ndebele',
 				'nso' => 'nord-sotho',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'klassisk newari',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'oksitansk',
 				'oj' => 'ojibwa',
 				'ojb' => 'nordvestlig ojibwa',
 				'ojc' => 'ojibwa (sentral)',
 				'ojs' => 'oji-cree',
 				'ojw' => 'vestlig ojibwa',
 				'oka' => 'okanagansk',
 				'om' => 'oromo',
 				'or' => 'odia',
 				'os' => 'ossetisk',
 				'osa' => 'osage',
 				'ota' => 'ottomansk tyrkisk',
 				'pa' => 'panjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauisk',
 				'pcd' => 'pikardisk',
 				'pcm' => 'nigeriansk pidginspråk',
 				'pdc' => 'pennsylvaniatysk',
 				'pdt' => 'plautdietsch',
 				'peo' => 'gammelpersisk',
 				'pfl' => 'palatintysk',
 				'phn' => 'fønikisk',
 				'pi' => 'pali',
 				'pis' => 'pijin',
 				'pl' => 'polsk',
 				'pms' => 'piemontesisk',
 				'pnt' => 'pontisk',
 				'pon' => 'ponapisk',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'prøyssisk',
 				'pro' => 'gammelprovençalsk',
 				'ps' => 'pashto',
 				'ps@alt=variant' => 'pushto',
 				'pt' => 'portugisisk',
 				'qu' => 'quechua',
 				'quc' => 'k’iche’',
 				'qug' => 'kichwa (Chimborazo-høylandet)',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotongansk',
 				'rgn' => 'romagnolsk',
 				'rhg' => 'rohingya',
 				'rif' => 'riff',
 				'rm' => 'retoromansk',
 				'rn' => 'rundi',
 				'ro' => 'rumensk',
 				'ro_MD' => 'moldovsk',
 				'rof' => 'rombo',
 				'rom' => 'romani',
 				'rtm' => 'rotumansk',
 				'ru' => 'russisk',
 				'rue' => 'rusinsk',
 				'rug' => 'roviana',
 				'rup' => 'aromansk',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'sakha',
 				'sam' => 'samaritansk arameisk',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'saurashtra',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardisk',
 				'scn' => 'siciliansk',
 				'sco' => 'skotsk',
 				'sd' => 'sindhi',
 				'sdc' => 'sassaresisk sardisk',
 				'sdh' => 'sørkurdisk',
 				'se' => 'nordsamisk',
 				'see' => 'seneca',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'selkupisk',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'gammelirsk',
 				'sgs' => 'samogitisk',
 				'sh' => 'serbokroatisk',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'tsjadisk arabisk',
 				'si' => 'singalesisk',
 				'sid' => 'sidamo',
 				'sk' => 'slovakisk',
 				'sl' => 'slovensk',
 				'slh' => 'sørlig lushootseed',
 				'sli' => 'lavschlesisk',
 				'sly' => 'selayar',
 				'sm' => 'samoansk',
 				'sma' => 'sørsamisk',
 				'smj' => 'lulesamisk',
 				'smn' => 'enaresamisk',
 				'sms' => 'skoltesamisk',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdisk',
 				'sq' => 'albansk',
 				'sr' => 'serbisk',
 				'srn' => 'sranan',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sør-sotho',
 				'stq' => 'saterfrisisk',
 				'str' => 'straits-salish',
 				'su' => 'sundanesisk',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerisk',
 				'sv' => 'svensk',
 				'sw' => 'swahili',
 				'sw_CD' => 'kongolesisk swahili',
 				'swb' => 'komorisk',
 				'syc' => 'klassisk syrisk',
 				'syr' => 'syriakisk',
 				'szl' => 'schlesisk',
 				'ta' => 'tamil',
 				'tce' => 'sørlig tutchone',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadsjikisk',
 				'tgx' => 'tagish',
 				'th' => 'thai',
 				'tht' => 'tahltan',
 				'ti' => 'tigrinja',
 				'tig' => 'tigré',
 				'tiv' => 'tiv',
 				'tk' => 'turkmensk',
 				'tkl' => 'tokelauisk',
 				'tkr' => 'tsakhursk',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tly' => 'talysj',
 				'tmh' => 'tamasjek',
 				'tn' => 'setswana',
 				'to' => 'tongansk',
 				'tog' => 'nyasa-tongansk',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'tyrkisk',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakonisk',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatarisk',
 				'ttm' => 'nordlig tutchone',
 				'ttt' => 'muslimsk tat',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalsk',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitisk',
 				'tyv' => 'tuvinsk',
 				'tzm' => 'sentralmarokkansk tamazight',
 				'udm' => 'udmurtisk',
 				'ug' => 'uigurisk',
 				'uga' => 'ugaritisk',
 				'uk' => 'ukrainsk',
 				'umb' => 'umbundu',
 				'und' => 'ukjent språk',
 				'ur' => 'urdu',
 				'uz' => 'usbekisk',
 				've' => 'venda',
 				'vec' => 'venetiansk',
 				'vep' => 'vepsisk',
 				'vi' => 'vietnamesisk',
 				'vls' => 'vestflamsk',
 				'vmf' => 'Main-frankisk',
 				'vmw' => 'makhuwa',
 				'vo' => 'volapyk',
 				'vot' => 'votisk',
 				'vro' => 'sørestisk',
 				'vun' => 'vunjo',
 				'wa' => 'vallonsk',
 				'wae' => 'walsertysk',
 				'wal' => 'wolaytta',
 				'war' => 'waray-waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'wu',
 				'xal' => 'kalmukkisk',
 				'xh' => 'xhosa',
 				'xmf' => 'mingrelsk',
 				'xnr' => 'kangri',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapesisk',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddisk',
 				'yo' => 'joruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantonesisk',
 				'yue@alt=menu' => 'kinesisk, kantonesisk',
 				'za' => 'zhuang',
 				'zap' => 'zapotekisk',
 				'zbl' => 'blissymboler',
 				'zea' => 'zeeuws',
 				'zen' => 'zenaga',
 				'zgh' => 'standard marrokansk tamazight',
 				'zh' => 'kinesisk',
 				'zh@alt=menu' => 'kinesisk, mandarin',
 				'zh_Hans' => 'forenklet kinesisk',
 				'zh_Hans@alt=long' => 'forenklet mandarinkinesisk',
 				'zh_Hant' => 'tradisjonell kinesisk',
 				'zh_Hant@alt=long' => 'tradisjonell mandarinkinesisk',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'uten språklig innhold',
 				'zza' => 'zazaisk',

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
 			'Aghb' => 'kaukasus-albansk',
 			'Ahom' => 'ahom',
 			'Arab' => 'arabisk',
 			'Arab@alt=variant' => 'persisk-arabisk',
 			'Aran' => 'nastaliq',
 			'Armi' => 'arameisk',
 			'Armn' => 'armensk',
 			'Avst' => 'avestisk',
 			'Bali' => 'balinesisk',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalsk',
 			'Blis' => 'blissymbol',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'punktskrift',
 			'Bugi' => 'buginesisk',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'felles kanadiske urspråksstavelser',
 			'Cari' => 'karisk',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Cirt' => 'cirth',
 			'Copt' => 'koptisk',
 			'Cprt' => 'kypriotisk',
 			'Cyrl' => 'kyrillisk',
 			'Cyrs' => 'kirkeslavisk kyrillisk',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'duployan stenografi',
 			'Egyd' => 'egyptisk demotisk',
 			'Egyh' => 'egyptisk hieratisk',
 			'Egyp' => 'egyptiske hieroglyfer',
 			'Elba' => 'elbasisk',
 			'Ethi' => 'etiopisk',
 			'Geok' => 'georgisk khutsuri',
 			'Geor' => 'georgisk',
 			'Glag' => 'glagolittisk',
 			'Goth' => 'gotisk',
 			'Gran' => 'gammeltamilsk',
 			'Grek' => 'gresk',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han-kinesisk med bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunoo',
 			'Hans' => 'forenklet',
 			'Hans@alt=stand-alone' => 'forenklet han',
 			'Hant' => 'tradisjonell',
 			'Hant@alt=stand-alone' => 'tradisjonell han',
 			'Hatr' => 'hatransk armensk',
 			'Hebr' => 'hebraisk',
 			'Hira' => 'hiragana',
 			'Hluw' => 'anatoliske hieroglyfer',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'japanske stavelsesskrifter',
 			'Hung' => 'gammelungarsk',
 			'Inds' => 'indus',
 			'Ital' => 'gammelitalisk',
 			'Jamo' => 'jamo',
 			'Java' => 'javanesisk',
 			'Jpan' => 'japansk',
 			'Jurc' => 'jurchen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmer',
 			'Khoj' => 'khojki',
 			'Knda' => 'kannada',
 			'Kore' => 'koreansk',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithisk',
 			'Lana' => 'lanna',
 			'Laoo' => 'laotisk',
 			'Latf' => 'frakturlatinsk',
 			'Latg' => 'gælisk latinsk',
 			'Latn' => 'latinsk',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'lineær A',
 			'Linb' => 'lineær B',
 			'Lisu' => 'fraser',
 			'Loma' => 'loma',
 			'Lyci' => 'lykisk',
 			'Lydi' => 'lydisk',
 			'Mahj' => 'mahajani',
 			'Mand' => 'mandaisk',
 			'Mani' => 'manikeisk',
 			'Maya' => 'maya-hieroglyfer',
 			'Mend' => 'mende',
 			'Merc' => 'meroitisk kursiv',
 			'Mero' => 'meroitisk',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modi',
 			'Mong' => 'mongolsk',
 			'Moon' => 'moon',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei-mayek',
 			'Mult' => 'multani',
 			'Mymr' => 'burmesisk',
 			'Narb' => 'gammelnordarabisk',
 			'Nbat' => 'nabataeansk',
 			'Nkgb' => 'naxi geba',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol-chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'odia',
 			'Osma' => 'osmanya',
 			'Palm' => 'palmyrensk',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'gammelpermisk',
 			'Phag' => 'phags-pa',
 			'Phli' => 'inskripsjonspahlavi',
 			'Phlp' => 'psalter pahlavi',
 			'Phlv' => 'pahlavi',
 			'Phnx' => 'fønikisk',
 			'Plrd' => 'pollard-fonetisk',
 			'Prti' => 'inskripsjonsparthisk',
 			'Qaag' => 'zawgyi',
 			'Rjng' => 'rejang',
 			'Rohg' => 'hanifi',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runer',
 			'Samr' => 'samaritansk',
 			'Sara' => 'sarati',
 			'Sarb' => 'gammelsørarabisk',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'tegnskrift',
 			'Shaw' => 'shavisk',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'singalesisk',
 			'Sora' => 'sora sompeng',
 			'Sund' => 'sundanesisk',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'syrisk',
 			'Syre' => 'estrangelosyriakisk',
 			'Syrj' => 'vestlig syriakisk',
 			'Syrn' => 'østlig syriakisk',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'ny tai lue',
 			'Taml' => 'tamilsk',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'taana',
 			'Thai' => 'thai',
 			'Tibt' => 'tibetansk',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaritisk',
 			'Vaii' => 'vai',
 			'Visp' => 'synlig tale',
 			'Wara' => 'varang kshiti',
 			'Wole' => 'woleai',
 			'Xpeo' => 'gammelpersisk',
 			'Xsux' => 'sumersk-akkadisk kileskrift',
 			'Yiii' => 'yi',
 			'Zinh' => 'nedarvet',
 			'Zmth' => 'matematisk notasjon',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symboler',
 			'Zxxx' => 'språk uten skrift',
 			'Zyyy' => 'felles',
 			'Zzzz' => 'ukjent skrift',

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
			'001' => 'verden',
 			'002' => 'Afrika',
 			'003' => 'Nord-Amerika',
 			'005' => 'Sør-Amerika',
 			'009' => 'Oseania',
 			'011' => 'Vest-Afrika',
 			'013' => 'Mellom-Amerika',
 			'014' => 'Øst-Afrika',
 			'015' => 'Nord-Afrika',
 			'017' => 'Sentral-Afrika',
 			'018' => 'Sørlige Afrika',
 			'019' => 'Amerika',
 			'021' => 'Nordlige Amerika',
 			'029' => 'Karibia',
 			'030' => 'Øst-Asia',
 			'034' => 'Sør-Asia',
 			'035' => 'Sørøst-Asia',
 			'039' => 'Sør-Europa',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesia',
 			'061' => 'Polynesia',
 			'142' => 'Asia',
 			'143' => 'Sentral-Asia',
 			'145' => 'Vest-Asia',
 			'150' => 'Europa',
 			'151' => 'Øst-Europa',
 			'154' => 'Nord-Europa',
 			'155' => 'Vest-Europa',
 			'202' => 'Afrika sør for Sahara',
 			'419' => 'Latin-Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'De forente arabiske emirater',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua og Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerikansk Samoa',
 			'AT' => 'Østerrike',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Aserbajdsjan',
 			'BA' => 'Bosnia-Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibisk Nederland',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetøya',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Canada',
 			'CC' => 'Kokosøyene',
 			'CD' => 'Kongo',
 			'CD@alt=variant' => 'Den demokratiske republikken Kongo',
 			'CF' => 'Den sentralafrikanske republikk',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Republikken Kongo',
 			'CH' => 'Sveits',
 			'CI' => 'Elfenbenskysten',
 			'CK' => 'Cookøyene',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kina',
 			'CO' => 'Colombia',
 			'CP' => 'Clippertonøya',
 			'CQ' => 'Sark',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Kapp Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmasøya',
 			'CY' => 'Kypros',
 			'CZ' => 'Tsjekkia',
 			'CZ@alt=variant' => 'Den tsjekkiske republikk',
 			'DE' => 'Tyskland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominica',
 			'DO' => 'Den dominikanske republikk',
 			'DZ' => 'Algerie',
 			'EA' => 'Ceuta og Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypt',
 			'EH' => 'Vest-Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spania',
 			'ET' => 'Etiopia',
 			'EU' => 'Den europeiske union',
 			'EZ' => 'eurosonen',
 			'FI' => 'Finland',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandsøyene',
 			'FK@alt=variant' => 'Falklandsøyene (Islas Malvinas)',
 			'FM' => 'Mikronesiaføderasjonen',
 			'FO' => 'Færøyene',
 			'FR' => 'Frankrike',
 			'GA' => 'Gabon',
 			'GB' => 'Storbritannia',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Fransk Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grønland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekvatorial-Guinea',
 			'GR' => 'Hellas',
 			'GS' => 'Sør-Georgia og Sør-Sandwichøyene',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong SAR Kina',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heard- og McDonaldøyene',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanariøyene',
 			'ID' => 'Indonesia',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Man',
 			'IN' => 'India',
 			'IO' => 'Det britiske territoriet i Indiahavet',
 			'IO@alt=chagos' => 'Chagosøyene',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordan',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodsja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorene',
 			'KN' => 'Saint Kitts og Nevis',
 			'KP' => 'Nord-Korea',
 			'KR' => 'Sør-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymanøyene',
 			'KZ' => 'Kasakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Luxemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshalløyene',
 			'MK' => 'Nord-Makedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao SAR Kina',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Nord-Marianene',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldivene',
 			'MW' => 'Malawi',
 			'MX' => 'Mexico',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Ny-Caledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkøya',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Nederland',
 			'NO' => 'Norge',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'New Zealand',
 			'NZ@alt=variant' => 'Aotearoa New Zealand',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransk Polynesia',
 			'PG' => 'Papua Ny-Guinea',
 			'PH' => 'Filippinene',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Saint-Pierre-et-Miquelon',
 			'PN' => 'Pitcairnøyene',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Det palestinske området',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Ytre Oseania',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Russland',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudi-Arabia',
 			'SB' => 'Salomonøyene',
 			'SC' => 'Seychellene',
 			'SD' => 'Sudan',
 			'SE' => 'Sverige',
 			'SG' => 'Singapore',
 			'SH' => 'St. Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard og Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sør-Sudan',
 			'ST' => 'São Tomé og Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- og Caicosøyene',
 			'TD' => 'Tsjad',
 			'TF' => 'De franske sørterritorier',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadsjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Øst-Timor',
 			'TL@alt=variant' => 'Timor-Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Tyrkia',
 			'TT' => 'Trinidad og Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'USAs ytre øyer',
 			'UN' => 'FN',
 			'US' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstaten',
 			'VC' => 'St. Vincent og Grenadinene',
 			'VE' => 'Venezuela',
 			'VG' => 'De britiske jomfruøyene',
 			'VI' => 'De amerikanske jomfruøyene',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis og Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudospråk – aksenter',
 			'XB' => 'pseudospråk – tekst begge veier',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sør-Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'ukjent område',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'tradisjonell tysk ortografi',
 			'1994' => 'standardisert resisk ortografi',
 			'1996' => 'tysk ortografi fra 1996',
 			'1606NICT' => 'nyere mellomfransk til 1606',
 			'1694ACAD' => 'eldre nyfransk',
 			'1959ACAD' => 'akademisk',
 			'ALALC97' => 'ALA-LC-romanisering, 1997-utgaven',
 			'ALUKU' => 'Aluku-dialekt',
 			'AREVELA' => 'øst-armensk',
 			'AREVMDA' => 'vest-armensk',
 			'BAKU1926' => 'samlet tyrkisk-latinsk alfabet',
 			'BALANKA' => 'balankadialekten av anii',
 			'BARLA' => 'barlaventa-dialektgruppen av kappverdiansk',
 			'BAUDDHA' => 'bauddha',
 			'BISCAYAN' => 'biscayan',
 			'BISKE' => 'san giorgio- og biladialekt',
 			'BOHORIC' => 'bohorisk alfabet',
 			'BOONT' => 'boontling',
 			'DAJNKO' => 'dajnkoalfabet',
 			'EKAVSK' => 'serbisk med ekavisk uttale',
 			'EMODENG' => 'tidlig moderne engelsk',
 			'FONIPA' => 'det internasjonale fonetiske alfabet (IPA)',
 			'FONUPA' => 'det uraliske fonetiske alfabet (UPA)',
 			'FONXSAMP' => 'fonxsamp',
 			'HEPBURN' => 'Hepburn-romanisering',
 			'HOGNORSK' => 'høgnorsk',
 			'HSISTEMO' => 'h-systemet',
 			'IJEKAVSK' => 'serbisk med ijekavisk uttale',
 			'ITIHASA' => 'itihasa',
 			'JAUER' => 'jauer',
 			'JYUTPING' => 'jyutping',
 			'KKCOR' => 'felles ortografi',
 			'KOCIEWIE' => 'kociewie',
 			'KSCOR' => 'standard ortografi',
 			'LAUKIKA' => 'laukika',
 			'LIPAW' => 'resia med Lipovaz-dialekt',
 			'METELKO' => 'Metelko-alfabet',
 			'MONOTON' => 'monotonisk rettskriving',
 			'NDYUKA' => 'ndyuka-dialekt',
 			'NEDIS' => 'natisonedialekt',
 			'NJIVA' => 'gniva- og njivadialekt',
 			'NULIK' => 'moderne volapük',
 			'OSOJS' => 'oseacco- og osojanedialekt',
 			'PAMAKA' => 'Pamaka-dialekt',
 			'PINYIN' => 'pinyin',
 			'POLYTON' => 'polytonisk rettskriving',
 			'POSIX' => 'dataspråk',
 			'REVISED' => 'revidert ortografi',
 			'RIGIK' => 'klassisk volapük',
 			'ROZAJ' => 'resisk dialekt',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'skotsk standard engelsk',
 			'SCOUSE' => 'scouse dialekt',
 			'SOLBA' => 'stolvizza- og solbicadialekt',
 			'SOTAV' => 'sotavento-dialektgruppen av kappverdiansk',
 			'SURMIRAN' => 'surmiransk',
 			'SURSILV' => 'sursilvan',
 			'SUTSILV' => 'sutsilvan',
 			'TARASK' => 'taraskievica-ortografi',
 			'UCCOR' => 'harmonisert ortografi',
 			'UCRCOR' => 'harmonisert revidert ortografi',
 			'ULSTER' => 'ulster',
 			'UNIFON' => 'Unifon fonetisk alfabet',
 			'VAIDIKA' => 'vaidika',
 			'VALENCIA' => 'valensiansk',
 			'VALLADER' => 'vallader',
 			'WADEGILE' => 'Wade-Giles-romanisering',
 			'XSISTEMO' => 'x-systemet',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalender',
 			'cf' => 'valutaformat',
 			'colalternate' => 'Ignorer sortering etter symboler',
 			'colbackwards' => 'Omvendt sortering etter aksent',
 			'colcasefirst' => 'Organisering av store og små bokstaver',
 			'colcaselevel' => 'Sortering av store og små bokstaver',
 			'collation' => 'sorteringsrekkefølge',
 			'colnormalization' => 'Normalisert sortering',
 			'colnumeric' => 'Numerisk sortering',
 			'colstrength' => 'Sorteringsstyrke',
 			'currency' => 'valuta',
 			'hc' => 'timesyklus (12 eller 24)',
 			'lb' => 'linjeskiftstil',
 			'ms' => 'målesystem',
 			'numbers' => 'tall',
 			'timezone' => 'tidssone',
 			'va' => 'språkvariant',
 			'x' => 'privat bruk',

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
 				'buddhist' => q{buddhistisk kalender},
 				'chinese' => q{kinesisk kalender},
 				'coptic' => q{koptisk kalender},
 				'dangi' => q{dangisk kalender},
 				'ethiopic' => q{etiopisk kalender},
 				'ethiopic-amete-alem' => q{etiopisk amete-alem-kalender},
 				'gregorian' => q{gregoriansk kalender},
 				'hebrew' => q{hebraisk kalender},
 				'indian' => q{indisk nasjonalkalender},
 				'islamic' => q{hijrikalender},
 				'islamic-civil' => q{hijrikalender (tabell, sivil)},
 				'islamic-rgsa' => q{islamsk kalender (Saudi-Arabia, observasjon)},
 				'islamic-tbla' => q{islamsk kalender (tabell, astronomisk)},
 				'islamic-umalqura' => q{hijrikalender (Umm al-Qura)},
 				'iso8601' => q{ISO 8601-kalender},
 				'japanese' => q{japansk kalender},
 				'persian' => q{persisk kalender},
 				'roc' => q{minguo-kalender},
 			},
 			'cf' => {
 				'account' => q{valutaformat for regnskapsføring},
 				'standard' => q{standard valutaformat},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{sortér symboler},
 				'shifted' => q{Ignorer symboler under sortering},
 			},
 			'colbackwards' => {
 				'no' => q{sortér aksenttegn normalt},
 				'yes' => q{sortér aksenttegn i motsatt rekkefølge},
 			},
 			'colcasefirst' => {
 				'lower' => q{Sortér små bokstaver først},
 				'no' => q{Sortér store og små bokstaver i vanlig rekkefølge},
 				'upper' => q{Sortér store bokstaver først},
 			},
 			'colcaselevel' => {
 				'no' => q{Sortér uavhengig av store og små bokstaver.},
 				'yes' => q{Sortér med skille mellom små og store bokstaver},
 			},
 			'collation' => {
 				'big5han' => q{tradisjonell kinesisk sortering - Big 5},
 				'compat' => q{forrige sorteringsrekkefølge (for kompatibilitet)},
 				'dictionary' => q{ordlistesortering},
 				'ducet' => q{standard Unicode-sorteringsrekkefølge},
 				'emoji' => q{emoji-sorteringsrekkefølge},
 				'eor' => q{sorteringsrekkefølge for flerspråklige europeiske dokumenter},
 				'gb2312han' => q{forenklet kinesisk sortering - GB2312},
 				'phonebook' => q{telefonkatalogsortering},
 				'phonetic' => q{fonetisk sortering},
 				'pinyin' => q{pinyinsortering},
 				'search' => q{generelt søk},
 				'searchjl' => q{Søk etter første konsonant i hangul},
 				'standard' => q{standard sorteringsrekkefølge},
 				'stroke' => q{streksortering},
 				'traditional' => q{tradisjonell sortering},
 				'unihan' => q{radikal-strek-sortering},
 				'zhuyin' => q{zhuyin-sortering},
 			},
 			'colnormalization' => {
 				'no' => q{Sortér uten normalisering},
 				'yes' => q{Sortér Unicode normalisert},
 			},
 			'colnumeric' => {
 				'no' => q{Sortér sifre individuelt},
 				'yes' => q{Sortér sifre numerisk},
 			},
 			'colstrength' => {
 				'identical' => q{Sortér alle},
 				'primary' => q{Sortér bare basisbokstaver},
 				'quaternary' => q{Sortér aksenttegn / små og store bokstaver / bredde / kana},
 				'secondary' => q{Sortér aksenttegn},
 				'tertiary' => q{Sortér aksenttegn / små og store bokstaver / bredde},
 			},
 			'd0' => {
 				'fwidth' => q{full bredde},
 				'hwidth' => q{halv bredde},
 				'npinyin' => q{Numerisk},
 			},
 			'hc' => {
 				'h11' => q{12-timers system (0–11)},
 				'h12' => q{12-timers system (1–12)},
 				'h23' => q{24-timers system (0–23)},
 				'h24' => q{24-timers system (1–24)},
 			},
 			'lb' => {
 				'loose' => q{løs linjeskiftstil},
 				'normal' => q{normal linjeskiftstil},
 				'strict' => q{streng linjeskiftstil},
 			},
 			'm0' => {
 				'bgn' => q{USBGN-translitterasjon},
 				'ungegn' => q{UNGEGN-translitterasjon},
 			},
 			'ms' => {
 				'metric' => q{metrisk system},
 				'uksystem' => q{britisk målesystem},
 				'ussystem' => q{amerikansk målesystem},
 			},
 			'numbers' => {
 				'arab' => q{arabisk-indiske sifre},
 				'arabext' => q{utvidede arabisk-indiske sifre},
 				'armn' => q{armenske tall},
 				'armnlow' => q{små armenske tall},
 				'bali' => q{baliske tall},
 				'beng' => q{bengalske sifre},
 				'brah' => q{brahmiske tall},
 				'cakm' => q{chakma-sifre},
 				'cham' => q{cham-tall},
 				'cyrl' => q{kyrilliske tall},
 				'deva' => q{devanagari-sifre},
 				'ethi' => q{etiopiske tall},
 				'finance' => q{Finansielle tall},
 				'fullwide' => q{sifre med full bredde},
 				'geor' => q{georgiske tall},
 				'grek' => q{greske tall},
 				'greklow' => q{små greske tall},
 				'gujr' => q{gujarati-sifre},
 				'guru' => q{gurmukhi-sifre},
 				'hanidec' => q{kinesiske desimaltall},
 				'hans' => q{forenklet kinesisk-tall},
 				'hansfin' => q{forenklet kinesisk-finanstall},
 				'hant' => q{tradisjonell kinesisk-tall},
 				'hantfin' => q{tradisjonell kinesisk-finanstall},
 				'hebr' => q{hebraiske tall},
 				'java' => q{javanesiske sifre},
 				'jpan' => q{japanske tall},
 				'jpanfin' => q{japanske finanstall},
 				'kali' => q{kayah li-tall},
 				'kawi' => q{kawi-sifre},
 				'khmr' => q{khmer-sifre},
 				'knda' => q{kannada-sifre},
 				'lana' => q{thai tham hora-tall},
 				'lanatham' => q{tai tham tham-tall},
 				'laoo' => q{laotiske sifre},
 				'latn' => q{vestlige sifre},
 				'lepc' => q{lepecha-tall},
 				'limb' => q{limbu-tall},
 				'mlym' => q{malayalam-sifre},
 				'mong' => q{mongolske tall},
 				'mtei' => q{meetei mayek-sifre},
 				'mymr' => q{burmesiske sifre},
 				'mymrshan' => q{myanmar shan-tall},
 				'native' => q{språkspesifikke sifre},
 				'nkoo' => q{n’ko-tall},
 				'olck' => q{ol chiki-sifre},
 				'orya' => q{odia-sifre},
 				'osma' => q{osmanya-tall},
 				'roman' => q{romertall},
 				'romanlow' => q{små romertall},
 				'saur' => q{sarushatra-tall},
 				'shrd' => q{sharada-tall},
 				'sora' => q{sora sompeng-tall},
 				'sund' => q{sundanese-tall},
 				'takr' => q{takri-tall},
 				'talu' => q{ny tai lue-tall},
 				'taml' => q{tamilske tall},
 				'tamldec' => q{tamilske sifre},
 				'telu' => q{telugu-sifre},
 				'thai' => q{thailandske sifre},
 				'tibt' => q{tibetanske sifre},
 				'tirh' => q{tirhuta-sifre},
 				'tnsa' => q{tangsa-sifre},
 				'traditional' => q{Tradisjonelle tall},
 				'vaii' => q{vai-sifre},
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
			'metric' => q{metrisk},
 			'UK' => q{engelsk},
 			'US' => q{amerikansk},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Språk: {0}',
 			'script' => 'Skrift: {0}',
 			'region' => 'Område: {0}',

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
			auxiliary => qr{[áǎã čç đ èê í ńñ ŋ š ŧ ú ü ž ä ö]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'],
			main => qr{[aà b c d eé f g h i j k l m n oóòô p q r s t u v w x y z æ ø å]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‑ – , ; \: ! ? ¿ . … ‘’ “” « » ( ) \[ \] \{ \} § @ * / \\ # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Æ', 'Ø', 'Å'], };
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

has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
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
						'name' => q(himmelretning),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(himmelretning),
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
						'1' => q(desi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(desi{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piko{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piko{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(mikro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(mikro{0}),
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
						'1' => q(deka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deka{0}),
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
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
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
						'1' => q(kilo{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(kilo{0}),
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
						'1' => q(masculine),
						'one' => q({0} g-kraft),
						'other' => q({0} g-kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(masculine),
						'one' => q({0} g-kraft),
						'other' => q({0} g-kraft),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(meter per sekund²),
						'one' => q({0} meter per sekund²),
						'other' => q({0} meter per sekund²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(masculine),
						'name' => q(meter per sekund²),
						'one' => q({0} meter per sekund²),
						'other' => q({0} meter per sekund²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(neuter),
						'one' => q({0} bueminutt),
						'other' => q({0} bueminutter),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(neuter),
						'one' => q({0} bueminutt),
						'other' => q({0} bueminutter),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(neuter),
						'name' => q(buesekunder),
						'one' => q({0} buesekund),
						'other' => q({0} buesekunder),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(neuter),
						'name' => q(buesekunder),
						'one' => q({0} buesekund),
						'other' => q({0} buesekunder),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(masculine),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(masculine),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(masculine),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(masculine),
						'one' => q({0} radian),
						'other' => q({0} radianer),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(masculine),
						'name' => q(omdreininger),
						'one' => q({0} omdreining),
						'other' => q({0} omdreininger),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(masculine),
						'name' => q(omdreininger),
						'one' => q({0} omdreining),
						'other' => q({0} omdreininger),
					},
					# Long Unit Identifier
					'area-acre' => {
						'1' => q(masculine),
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'1' => q(masculine),
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(neuter),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(neuter),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(masculine),
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
						'per' => q({0} per kvadratcentimeter),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(masculine),
						'name' => q(kvadratcentimeter),
						'one' => q({0} kvadratcentimeter),
						'other' => q({0} kvadratcentimeter),
						'per' => q({0} per kvadratcentimeter),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'1' => q(masculine),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					# Core Unit Identifier
					'square-foot' => {
						'1' => q(masculine),
						'one' => q({0} kvadratfot),
						'other' => q({0} kvadratfot),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(kvadrattommer),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommer),
						'per' => q({0} per kvadrattomme),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(kvadrattommer),
						'one' => q({0} kvadrattomme),
						'other' => q({0} kvadrattommer),
						'per' => q({0} per kvadrattomme),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(masculine),
						'name' => q(kvadratkilometer),
						'one' => q({0} kvadratkilometer),
						'other' => q({0} kvadratkilometer),
						'per' => q({0} per kvadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(masculine),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(masculine),
						'name' => q(kvadratmeter),
						'one' => q({0} kvadratmeter),
						'other' => q({0} kvadratmeter),
						'per' => q({0} per kvadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'1' => q(masculine),
						'name' => q(kvadratmile),
						'one' => q({0} kvadratmile),
						'other' => q({0} kvadratmile),
						'per' => q({0} per engelsk kvadratmil),
					},
					# Core Unit Identifier
					'square-mile' => {
						'1' => q(masculine),
						'name' => q(kvadratmile),
						'one' => q({0} kvadratmile),
						'other' => q({0} kvadratmile),
						'per' => q({0} per engelsk kvadratmil),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(kvadratyard),
						'one' => q({0} kvadratyard),
						'other' => q({0} kvadratyard),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(kvadratyard),
						'one' => q({0} kvadratyard),
						'other' => q({0} kvadratyard),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(neuter),
						'one' => q({0} item),
						'other' => q({0} item),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(neuter),
						'one' => q({0} item),
						'other' => q({0} item),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(masculine),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(masculine),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'1' => q(neuter),
						'name' => q(milligram per desiliter),
						'one' => q({0} milligram per desiliter),
						'other' => q({0} milligram per desiliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(masculine),
						'name' => q(millimol per liter),
						'one' => q({0} millimol per liter),
						'other' => q({0} millimol per liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(neuter),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(neuter),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(masculine),
						'one' => q({0} prosent),
						'other' => q({0} prosent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(masculine),
						'one' => q({0} prosent),
						'other' => q({0} prosent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(masculine),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(masculine),
						'one' => q({0} promille),
						'other' => q({0} promille),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(masculine),
						'name' => q(deler per million),
						'one' => q({0} del per million),
						'other' => q({0} deler per million),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(masculine),
						'name' => q(deler per million),
						'one' => q({0} del per million),
						'other' => q({0} deler per million),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(masculine),
						'one' => q({0} promyriade),
						'other' => q({0} promyriade),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(masculine),
						'one' => q({0} promyriade),
						'other' => q({0} promyriade),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'1' => q(masculine),
						'name' => q(deler per milliard),
						'one' => q({0} del per milliard),
						'other' => q({0} deler per milliard),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'1' => q(masculine),
						'name' => q(deler per milliard),
						'one' => q({0} del per milliard),
						'other' => q({0} deler per milliard),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(liter per 100 kilometer),
						'one' => q({0} liter per 100 kilometer),
						'other' => q({0} liter per 100 kilometer),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(masculine),
						'name' => q(liter per kilometer),
						'one' => q({0} liter per kilometer),
						'other' => q({0} liter per kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'1' => q(masculine),
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'1' => q(masculine),
						'name' => q(miles per gallon),
						'one' => q({0} mile per gallon),
						'other' => q({0} miles per gallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(miles per britisk gallon),
						'one' => q({0} mile per britisk gallon),
						'other' => q({0} miles per britisk gallon),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(miles per britisk gallon),
						'one' => q({0} mile per britisk gallon),
						'other' => q({0} miles per britisk gallon),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} øst),
						'north' => q({0} nord),
						'south' => q({0} sør),
						'west' => q({0} vest),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} øst),
						'north' => q({0} nord),
						'south' => q({0} sør),
						'west' => q({0} vest),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(masculine),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(masculine),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(masculine),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(masculine),
						'one' => q({0} byte),
						'other' => q({0} byte),
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
						'1' => q(neuter),
						'name' => q(århundrer),
						'one' => q({0} århundre),
						'other' => q({0} århundrer),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'name' => q(århundrer),
						'one' => q({0} århundre),
						'other' => q({0} århundrer),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(neuter),
						'one' => q({0} døgn),
						'other' => q({0} døgn),
						'per' => q({0} per døgn),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(neuter),
						'one' => q({0} døgn),
						'other' => q({0} døgn),
						'per' => q({0} per døgn),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'one' => q({0} tiår),
						'other' => q({0} tiår),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'one' => q({0} tiår),
						'other' => q({0} tiår),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(masculine),
						'one' => q({0} time),
						'other' => q({0} timer),
						'per' => q({0} per time),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(masculine),
						'one' => q({0} time),
						'other' => q({0} timer),
						'per' => q({0} per time),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(neuter),
						'name' => q(mikrosekunder),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekunder),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(neuter),
						'name' => q(mikrosekunder),
						'one' => q({0} mikrosekund),
						'other' => q({0} mikrosekunder),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(neuter),
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(neuter),
						'name' => q(millisekunder),
						'one' => q({0} millisekund),
						'other' => q({0} millisekunder),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(neuter),
						'name' => q(minutter),
						'one' => q({0} minutt),
						'other' => q({0} minutter),
						'per' => q({0} per minutt),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(neuter),
						'name' => q(minutter),
						'one' => q({0} minutt),
						'other' => q({0} minutter),
						'per' => q({0} per minutt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(masculine),
						'one' => q({0} måned),
						'other' => q({0} måneder),
						'per' => q({0} per måned),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(masculine),
						'one' => q({0} måned),
						'other' => q({0} måneder),
						'per' => q({0} per måned),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(neuter),
						'name' => q(nanosekunder),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekunder),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(neuter),
						'name' => q(nanosekunder),
						'one' => q({0} nanosekund),
						'other' => q({0} nanosekunder),
					},
					# Long Unit Identifier
					'duration-night' => {
						'1' => q(masculine),
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0} per natt),
					},
					# Core Unit Identifier
					'night' => {
						'1' => q(masculine),
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0} per natt),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(neuter),
						'name' => q(kvartal),
						'one' => q({0} kvartal),
						'other' => q({0} kvartaler),
						'per' => q({0}/kvartal),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(neuter),
						'name' => q(kvartal),
						'one' => q({0} kvartal),
						'other' => q({0} kvartaler),
						'per' => q({0}/kvartal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(neuter),
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} per sekund),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(neuter),
						'name' => q(sekunder),
						'one' => q({0} sekund),
						'other' => q({0} sekunder),
						'per' => q({0} per sekund),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(masculine),
						'one' => q({0} uke),
						'other' => q({0} uker),
						'per' => q({0} per uke),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(masculine),
						'one' => q({0} uke),
						'other' => q({0} uker),
						'per' => q({0} per uke),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(neuter),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} per år),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(neuter),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0} per år),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(masculine),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(masculine),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(masculine),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(masculine),
						'one' => q({0} milliampere),
						'other' => q({0} milliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(masculine),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(masculine),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(masculine),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(masculine),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(British thermal unit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(British thermal unit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(masculine),
						'name' => q(kalorier),
						'one' => q({0} kalori),
						'other' => q({0} kalorier),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(masculine),
						'name' => q(kalorier),
						'one' => q({0} kalori),
						'other' => q({0} kalorier),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'1' => q(masculine),
						'name' => q(kalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'1' => q(masculine),
						'name' => q(kalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(masculine),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(masculine),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'1' => q(masculine),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'1' => q(masculine),
						'name' => q(kilokalorier),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalorier),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(masculine),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(masculine),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(kilowattimer),
						'one' => q({0} kilowattime),
						'other' => q({0} kilowattimer),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(masculine),
						'name' => q(kilowattimer),
						'one' => q({0} kilowattime),
						'other' => q({0} kilowattimer),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kWh per 100 km),
						'one' => q({0} kWh per 100 km),
						'other' => q({0} kWh per 100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(masculine),
						'name' => q(kWh per 100 km),
						'one' => q({0} kWh per 100 km),
						'other' => q({0} kWh per 100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(masculine),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(masculine),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} pound-force),
						'other' => q({0} pound-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'one' => q({0} pound-force),
						'other' => q({0} pound-force),
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
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkter),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punkt),
						'one' => q({0} punkt),
						'other' => q({0} punkter),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(punkter per centimeter),
						'one' => q({0} punkt per centimeter),
						'other' => q({0} punkter per centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(punkter per centimeter),
						'one' => q({0} punkt per centimeter),
						'other' => q({0} punkter per centimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(punkter per tomme),
						'one' => q({0} punkt per tomme),
						'other' => q({0} punkter per tomme),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(punkter per tomme),
						'one' => q({0} punkt per tomme),
						'other' => q({0} punkter per tomme),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(masculine),
						'one' => q({0} gefirt),
						'other' => q({0} gefirt),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(masculine),
						'one' => q({0} gefirt),
						'other' => q({0} gefirt),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksler),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(masculine),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksler),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(masculine),
						'one' => q({0} piksel),
						'other' => q({0} piksler),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(masculine),
						'one' => q({0} piksel),
						'other' => q({0} piksler),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(piksler per centimeter),
						'one' => q({0} piksel per centimeter),
						'other' => q({0} piksler per centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(masculine),
						'name' => q(piksler per centimeter),
						'one' => q({0} piksel per centimeter),
						'other' => q({0} piksler per centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksler per tomme),
						'one' => q({0} piksel per tomme),
						'other' => q({0} piksler per tomme),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksler per tomme),
						'one' => q({0} piksel per tomme),
						'other' => q({0} piksler per tomme),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(astronomiske enheter),
						'one' => q({0} astronomisk enhet),
						'other' => q({0} astronomiske enheter),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(astronomiske enheter),
						'one' => q({0} astronomisk enhet),
						'other' => q({0} astronomiske enheter),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(masculine),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(masculine),
						'name' => q(centimeter),
						'one' => q({0} centimeter),
						'other' => q({0} centimeter),
						'per' => q({0} per centimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(masculine),
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(masculine),
						'name' => q(desimeter),
						'one' => q({0} desimeter),
						'other' => q({0} desimeter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(jordradius),
						'one' => q({0} jordradius),
						'other' => q({0} jordradier),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(jordradius),
						'one' => q({0} jordradius),
						'other' => q({0} jordradier),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} favn),
						'other' => q({0} favner),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} favn),
						'other' => q({0} favner),
					},
					# Long Unit Identifier
					'length-foot' => {
						'1' => q(masculine),
						'per' => q({0} per fot),
					},
					# Core Unit Identifier
					'foot' => {
						'1' => q(masculine),
						'per' => q({0} per fot),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'1' => q(masculine),
						'per' => q({0} per tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'1' => q(masculine),
						'per' => q({0} per tomme),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(masculine),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(masculine),
						'name' => q(kilometer),
						'one' => q({0} kilometer),
						'other' => q({0} kilometer),
						'per' => q({0} per kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} lysår),
						'other' => q({0} lysår),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(masculine),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(masculine),
						'one' => q({0} meter),
						'other' => q({0} meter),
						'per' => q({0} per meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(masculine),
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(masculine),
						'name' => q(mikrometer),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometer),
					},
					# Long Unit Identifier
					'length-mile' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'mile' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(masculine),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(masculine),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(masculine),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(masculine),
						'name' => q(millimeter),
						'one' => q({0} millimeter),
						'other' => q({0} millimeter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(masculine),
						'name' => q(nanometer),
						'one' => q({0} nanometer),
						'other' => q({0} nanometer),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nautiske mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiske mil),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nautiske mil),
						'one' => q({0} nautisk mil),
						'other' => q({0} nautiske mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'1' => q(masculine),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'1' => q(masculine),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(masculine),
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(masculine),
						'name' => q(pikometer),
						'one' => q({0} pikometer),
						'other' => q({0} pikometer),
					},
					# Long Unit Identifier
					'length-point' => {
						'1' => q(neuter),
						'name' => q(typografiske punkter),
						'one' => q({0} typografisk punkt),
						'other' => q({0} typografiske punkter),
					},
					# Core Unit Identifier
					'point' => {
						'1' => q(neuter),
						'name' => q(typografiske punkter),
						'one' => q({0} typografisk punkt),
						'other' => q({0} typografiske punkter),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'1' => q(masculine),
						'name' => q(solradier),
						'one' => q({0} solradius),
						'other' => q({0} solradier),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'1' => q(masculine),
						'name' => q(solradier),
						'one' => q({0} solradius),
						'other' => q({0} solradier),
					},
					# Long Unit Identifier
					'length-yard' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'yard' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(masculine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(masculine),
						'name' => q(candela),
						'one' => q({0} candela),
						'other' => q({0} candela),
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
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(masculine),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'1' => q(masculine),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'1' => q(masculine),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(masculine),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(masculine),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'1' => q(masculine),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'1' => q(masculine),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'1' => q(masculine),
						'one' => q({0} jordmasse),
						'other' => q({0} jordmasser),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'1' => q(masculine),
						'one' => q({0} jordmasse),
						'other' => q({0} jordmasser),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'grain' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(neuter),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(neuter),
						'one' => q({0} gram),
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(neuter),
						'name' => q(kilogram),
						'one' => q({0} kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(neuter),
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(neuter),
						'name' => q(mikrogram),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(neuter),
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(neuter),
						'name' => q(milligram),
						'one' => q({0} milligram),
						'other' => q({0} milligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'1' => q(masculine),
						'per' => q({0} per unse),
					},
					# Core Unit Identifier
					'ounce' => {
						'1' => q(masculine),
						'per' => q({0} per unse),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ounce),
						'one' => q({0} troy ounce),
						'other' => q({0} troy ounce),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'1' => q(neuter),
						'per' => q({0} per pund),
					},
					# Core Unit Identifier
					'pound' => {
						'1' => q(neuter),
						'per' => q({0} per pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'1' => q(masculine),
						'one' => q({0} solmasse),
						'other' => q({0} solmasser),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'1' => q(masculine),
						'one' => q({0} solmasse),
						'other' => q({0} solmasser),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(amerikanske tonn),
						'one' => q({0} amerikansk tonn),
						'other' => q({0} amerikanske tonn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(amerikanske tonn),
						'one' => q({0} amerikansk tonn),
						'other' => q({0} amerikanske tonn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(neuter),
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(neuter),
						'name' => q(tonn),
						'one' => q({0} tonn),
						'other' => q({0} tonn),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
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
						'name' => q(hestekrefter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrefter),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hestekrefter),
						'one' => q({0} hestekraft),
						'other' => q({0} hestekrefter),
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
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(masculine),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(kvadrat{0}),
						'one' => q(kvadrat{0}),
						'other' => q(kvadrat{0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(kvadrat{0}),
						'one' => q(kvadrat{0}),
						'other' => q(kvadrat{0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kubikk{0}),
						'one' => q(kubikk{0}),
						'other' => q(kubikk{0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubikk{0}),
						'one' => q(kubikk{0}),
						'other' => q(kubikk{0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(masculine),
						'name' => q(atmosfærer),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfærer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(masculine),
						'name' => q(atmosfærer),
						'one' => q({0} atmosfære),
						'other' => q({0} atmosfærer),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(masculine),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(masculine),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(masculine),
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(masculine),
						'name' => q(hektopascal),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(tommer kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommer kvikksølv),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(tommer kvikksølv),
						'one' => q({0} tomme kvikksølv),
						'other' => q({0} tommer kvikksølv),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(masculine),
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
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
						'name' => q(millimeter kvikksølv),
						'one' => q({0} millimeter kvikksølv),
						'other' => q({0} millimeter kvikksølv),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'1' => q(masculine),
						'name' => q(millimeter kvikksølv),
						'one' => q({0} millimeter kvikksølv),
						'other' => q({0} millimeter kvikksølv),
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
						'name' => q(pund per kvadrattomme),
						'one' => q({0} pund per kvadrattomme),
						'other' => q({0} pund per kvadrattomme),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pund per kvadrattomme),
						'one' => q({0} pund per kvadrattomme),
						'other' => q({0} pund per kvadrattomme),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(beaufort),
						'one' => q(beaufort {0}),
						'other' => q(beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(beaufort),
						'one' => q(beaufort {0}),
						'other' => q(beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilometer per time),
						'one' => q({0} kilometer per time),
						'other' => q({0} kilometer per time),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(masculine),
						'name' => q(kilometer per time),
						'one' => q({0} kilometer per time),
						'other' => q({0} kilometer per time),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(knop),
						'one' => q({0} knop),
						'other' => q({0} knop),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(knop),
						'one' => q({0} knop),
						'other' => q({0} knop),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'1' => q(neuter),
						'name' => q(lys),
						'one' => q({0} lys),
						'other' => q({0} lys),
					},
					# Core Unit Identifier
					'light-speed' => {
						'1' => q(neuter),
						'name' => q(lys),
						'one' => q({0} lys),
						'other' => q({0} lys),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(masculine),
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(masculine),
						'name' => q(meter per sekund),
						'one' => q({0} meter per sekund),
						'other' => q({0} meter per sekund),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'1' => q(masculine),
						'name' => q(mile per time),
						'one' => q({0} engelsk mil per time),
						'other' => q({0} engelske mil per time),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'1' => q(masculine),
						'name' => q(mile per time),
						'one' => q({0} engelsk mil per time),
						'other' => q({0} engelske mil per time),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(masculine),
						'name' => q(grader celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grader celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(masculine),
						'name' => q(grader celsius),
						'one' => q({0} grad celsius),
						'other' => q({0} grader celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'1' => q(masculine),
						'name' => q(grader fahrenheit),
						'one' => q({0} grad fahrenheit),
						'other' => q({0} grader fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'1' => q(masculine),
						'name' => q(grader fahrenheit),
						'one' => q({0} grad fahrenheit),
						'other' => q({0} grader fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(masculine),
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(masculine),
						'name' => q(grader),
						'one' => q({0} grad),
						'other' => q({0} grader),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(masculine),
						'name' => q(kelvin),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(masculine),
						'name' => q(newtonmeter),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmeter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pound-foot),
						'one' => q({0} pound-foot),
						'other' => q({0} pound-foot),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pound-foot),
						'one' => q({0} pound-foot),
						'other' => q({0} pound-foot),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} acre-fot),
						'other' => q({0} acre-fot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} acre-fot),
						'other' => q({0} acre-fot),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'1' => q(neuter),
					},
					# Core Unit Identifier
					'barrel' => {
						'1' => q(neuter),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(masculine),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(masculine),
						'name' => q(centiliter),
						'one' => q({0} centiliter),
						'other' => q({0} centiliter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(kubikkcentimeter),
						'one' => q({0} kubikkcentimeter),
						'other' => q({0} kubikkcentimeter),
						'per' => q({0} per kubikkcentimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(masculine),
						'name' => q(kubikkcentimeter),
						'one' => q({0} kubikkcentimeter),
						'other' => q({0} kubikkcentimeter),
						'per' => q({0} per kubikkcentimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'1' => q(masculine),
						'name' => q(kubikkfot),
						'one' => q({0} kubikkfot),
						'other' => q({0} kubikkfot),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'1' => q(masculine),
						'name' => q(kubikkfot),
						'one' => q({0} kubikkfot),
						'other' => q({0} kubikkfot),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'1' => q(masculine),
						'name' => q(kubikktommer),
						'one' => q({0} kubikktomme),
						'other' => q({0} kubikktommer),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'1' => q(masculine),
						'name' => q(kubikktommer),
						'one' => q({0} kubikktomme),
						'other' => q({0} kubikktommer),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(masculine),
						'name' => q(kubikkilometer),
						'one' => q({0} kubikkilometer),
						'other' => q({0} kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(masculine),
						'name' => q(kubikkmeter),
						'one' => q({0} kubikkmeter),
						'other' => q({0} kubikkmeter),
						'per' => q({0} per kubikkmeter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(masculine),
						'name' => q(kubikkmeter),
						'one' => q({0} kubikkmeter),
						'other' => q({0} kubikkmeter),
						'per' => q({0} per kubikkmeter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'1' => q(masculine),
						'name' => q(kubikkmile),
						'one' => q({0} kubikkmile),
						'other' => q({0} kubikkmile),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'1' => q(masculine),
						'name' => q(kubikkmile),
						'one' => q({0} kubikkmile),
						'other' => q({0} kubikkmile),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(kubikkyard),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyard),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(kubikkyard),
						'one' => q({0} kubikkyard),
						'other' => q({0} kubikkyard),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'1' => q(masculine),
						'one' => q({0} kopp),
						'other' => q({0} kopper),
					},
					# Core Unit Identifier
					'cup' => {
						'1' => q(masculine),
						'one' => q({0} kopp),
						'other' => q({0} kopper),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(masculine),
						'name' => q(metriske kopper),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriske kopper),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(masculine),
						'name' => q(metriske kopper),
						'one' => q({0} metrisk kopp),
						'other' => q({0} metriske kopper),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(masculine),
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(masculine),
						'name' => q(desiliter),
						'one' => q({0} desiliter),
						'other' => q({0} desiliter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(barneskje),
						'one' => q({0} barneskje),
						'other' => q({0} barneskjeer),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'1' => q(masculine),
						'name' => q(barneskje),
						'one' => q({0} barneskje),
						'other' => q({0} barneskjeer),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(britisk barneskje),
						'one' => q({0} britisk barneskje),
						'other' => q({0} britiske barneskjeer),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'1' => q(masculine),
						'name' => q(britisk barneskje),
						'one' => q({0} britisk barneskje),
						'other' => q({0} britiske barneskjeer),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'1' => q(masculine),
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Core Unit Identifier
					'dram' => {
						'1' => q(masculine),
						'name' => q(dram),
						'one' => q({0} dram),
						'other' => q({0} dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'1' => q(masculine),
						'one' => q({0} dråpe),
						'other' => q({0} dråper),
					},
					# Core Unit Identifier
					'drop' => {
						'1' => q(masculine),
						'one' => q({0} dråpe),
						'other' => q({0} dråper),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'1' => q(masculine),
						'name' => q(væskeunser),
						'one' => q({0} væskeunse),
						'other' => q({0} væskeunser),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'1' => q(masculine),
						'name' => q(væskeunser),
						'one' => q({0} væskeunse),
						'other' => q({0} væskeunser),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'1' => q(masculine),
						'name' => q(britiske væskeunser),
						'one' => q({0} britisk væskeunse),
						'other' => q({0} britiske væskeunser),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'1' => q(masculine),
						'name' => q(britiske væskeunser),
						'one' => q({0} britisk væskeunse),
						'other' => q({0} britiske væskeunser),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'1' => q(masculine),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'1' => q(masculine),
						'name' => q(gallon),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} per gallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(britiske gallon),
						'one' => q({0} britisk gallon),
						'other' => q({0} britiske gallon),
						'per' => q({0} per britisk gallon),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'1' => q(masculine),
						'name' => q(britiske gallon),
						'one' => q({0} britisk gallon),
						'other' => q({0} britiske gallon),
						'per' => q({0} per britisk gallon),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(masculine),
						'name' => q(hektoliter),
						'one' => q({0} hektoliter),
						'other' => q({0} hektoliter),
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
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(masculine),
						'one' => q({0} liter),
						'other' => q({0} liter),
						'per' => q({0} per liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(masculine),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(masculine),
						'name' => q(megaliter),
						'one' => q({0} megaliter),
						'other' => q({0} megaliter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(masculine),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(masculine),
						'name' => q(milliliter),
						'one' => q({0} milliliter),
						'other' => q({0} milliliter),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'1' => q(masculine),
						'one' => q({0} klyper),
						'other' => q({0} klyper),
					},
					# Core Unit Identifier
					'pinch' => {
						'1' => q(masculine),
						'one' => q({0} klyper),
						'other' => q({0} klyper),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'1' => q(masculine),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'1' => q(masculine),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(masculine),
						'name' => q(metriske pint),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriske pint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(masculine),
						'name' => q(metriske pint),
						'one' => q({0} metrisk pint),
						'other' => q({0} metriske pint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'1' => q(masculine),
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Core Unit Identifier
					'quart' => {
						'1' => q(masculine),
						'name' => q(quart),
						'one' => q({0} quart),
						'other' => q({0} quart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'1' => q(masculine),
						'name' => q(britisk quart),
						'one' => q({0} britisk quart),
						'other' => q({0} britiske quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'1' => q(masculine),
						'name' => q(britisk quart),
						'one' => q({0} britisk quart),
						'other' => q({0} britiske quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'1' => q(masculine),
						'name' => q(spiseskjeer),
						'one' => q({0} spiseskje),
						'other' => q({0} spiseskjeer),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'1' => q(masculine),
						'name' => q(spiseskjeer),
						'one' => q({0} spiseskje),
						'other' => q({0} spiseskjeer),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'1' => q(masculine),
						'name' => q(teskjeer),
						'one' => q({0} teskje),
						'other' => q({0} teskjeer),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'1' => q(masculine),
						'name' => q(teskjeer),
						'one' => q({0} teskje),
						'other' => q({0} teskjeer),
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
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(buemin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(buemin),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(o),
						'one' => q({0} o),
						'other' => q({0} o),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(o),
						'one' => q({0} o),
						'other' => q({0} o),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
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
						'name' => q(fot²),
						'one' => q({0}fot²),
						'other' => q({0}fot²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fot²),
						'one' => q({0}fot²),
						'other' => q({0}fot²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
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
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
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
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
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
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
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
					'concentr-permyriad' => {
						'name' => q(‱),
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
						'one' => q({0}‱),
						'other' => q({0}‱),
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
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
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
						'one' => q({0}mpg brit.),
						'other' => q({0}mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0}mpg brit.),
						'other' => q({0}mpg brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Ø),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}V),
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
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
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
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
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
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
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
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(time),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(time),
						'one' => q({0}t),
						'other' => q({0}t),
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
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(måned),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(måned),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
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
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0}/natt),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0}/natt),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/kv),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kv),
						'one' => q({0} kv),
						'other' => q({0} kv),
						'per' => q({0}/kv),
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
						'name' => q(uke),
						'one' => q({0}u),
						'other' => q({0}u),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(uke),
						'one' => q({0}u),
						'other' => q({0}u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0}å),
						'other' => q({0}å),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0}å),
						'other' => q({0}å),
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
					'electric-milliampere' => {
						'name' => q(mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
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
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}AU),
						'other' => q({0}AU),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}AU),
						'other' => q({0}AU),
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
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0}ft),
						'other' => q({0}ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/in),
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
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
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
						'one' => q({0}mil),
						'other' => q({0}mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}mil),
						'other' => q({0}mil),
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
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
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
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
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
					'mass-earth-mass' => {
						'name' => q(M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
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
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} am. tn.),
						'other' => q({0} am. tn.),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} am. tn.),
						'other' => q({0} am. tn.),
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
					'power-horsepower' => {
						'one' => q({0}hk),
						'other' => q({0}hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hk),
						'other' => q({0}hk),
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
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
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
						'one' => q(Bf{0}),
						'other' => q(Bf{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(Bf{0}),
						'other' => q(Bf{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0}km/t),
						'other' => q({0}km/t),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/t),
						'one' => q({0}km/t),
						'other' => q({0}km/t),
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
						'name' => q(lys),
						'one' => q({0}lys),
						'other' => q({0}lys),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(lys),
						'one' => q({0}lys),
						'other' => q({0}lys),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/t),
						'one' => q({0}mi/t),
						'other' => q({0}mi/t),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/t),
						'one' => q({0}mi/t),
						'other' => q({0}mi/t),
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
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
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
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
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
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kopp),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kopp),
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
					'volume-dram' => {
						'name' => q(dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} fl oz Im),
						'other' => q({0} fl oz Im),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0}l),
						'other' => q({0}l),
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
						'name' => q(kl.),
						'one' => q({0} kl.),
						'other' => q({0} kl.),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(kl.),
						'one' => q({0} kl.),
						'other' => q({0} kl.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0} qt. Imp.),
						'other' => q({0} qt. Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0} qt. Imp.),
						'other' => q({0} qt. Imp.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(retning),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(retning),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-kraft),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-kraft),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meter/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meter/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(bueminutter),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(bueminutter),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(buesek),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(buesek),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grader),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grader),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianer),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianer),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(omdr.),
						'one' => q({0} omdr.),
						'other' => q({0} omdr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(omdr.),
						'one' => q({0} omdr.),
						'other' => q({0} omdr.),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} fot²),
						'other' => q({0} fot²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kvadratfot),
						'one' => q({0} fot²),
						'other' => q({0} fot²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(tommer²),
						'one' => q({0} tomme²),
						'other' => q({0} tommer²),
						'per' => q({0}/tommer²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(tommer²),
						'one' => q({0} tomme²),
						'other' => q({0} tommer²),
						'per' => q({0}/tommer²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(miles²),
						'one' => q({0} mile²),
						'other' => q({0} miles²),
						'per' => q({0}/mile²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(miles²),
						'one' => q({0} mile²),
						'other' => q({0} miles²),
						'per' => q({0}/mile²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(karat),
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
						'name' => q(mmol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/liter),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(prosent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(prosent),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(promille),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(promille),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(promyriade),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(promyriade),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(deler/milliard),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(deler/milliard),
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
						'name' => q(liter/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liter/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(miles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(miles/brit. gal),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(miles/brit. gal),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ø),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ø),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} V),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'one' => q({0} B),
						'other' => q({0} B),
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
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
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
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(årh.),
						'one' => q({0} årh.),
						'other' => q({0} årh.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(årh.),
						'one' => q({0} årh.),
						'other' => q({0} årh.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(døgn),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(døgn),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(tiår),
						'one' => q({0} tiår),
						'other' => q({0} tiår),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(tiår),
						'one' => q({0} tiår),
						'other' => q({0} tiår),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(timer),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(timer),
						'one' => q({0} t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(måneder),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(måneder),
						'one' => q({0} md.),
						'other' => q({0} md.),
						'per' => q({0}/md.),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0}/natt),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(netter),
						'one' => q({0} natt),
						'other' => q({0} netter),
						'per' => q({0}/natt),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kvt),
						'one' => q({0} kvt),
						'other' => q({0} kvt),
						'per' => q({0}/kvt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kvt),
						'one' => q({0} kvt),
						'other' => q({0} kvt),
						'per' => q({0}/kvt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'one' => q({0} sek),
						'other' => q({0} sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(uker),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(uker),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0}/år),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(år),
						'one' => q({0} år),
						'other' => q({0} år),
						'per' => q({0}/år),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliampere),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elektronvolt),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(therm),
						'one' => q({0} therm),
						'other' => q({0} therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(therm),
						'one' => q({0} therm),
						'other' => q({0} therm),
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
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pound-force),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pound-force),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(pkt),
						'one' => q({0} pkt),
						'other' => q({0} pkt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(pkt),
						'one' => q({0} pkt),
						'other' => q({0} pkt),
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
						'name' => q(gefirt),
						'one' => q({0} gefirt),
						'other' => q({0} gefirt),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(gefirt),
						'one' => q({0} gefirt),
						'other' => q({0} gefirt),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapiksler),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapiksler),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksler),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksler),
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
						'name' => q(favner),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(favner),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/fot),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fot),
						'one' => q({0} fot),
						'other' => q({0} fot),
						'per' => q({0}/fot),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(tommer),
						'one' => q({0} tomme),
						'other' => q({0} tommer),
						'per' => q({0}/tomme),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(lysår),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(lysår),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(miles),
						'one' => q({0} mile),
						'other' => q({0} miles),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(punkter),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(punkter),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(solradius),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(solradius),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(solluminositet),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(solluminositet),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(jordmasser),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(jordmasser),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
						'per' => q({0}/unse),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unser),
						'one' => q({0} unse),
						'other' => q({0} unser),
						'per' => q({0}/unse),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz tr),
						'one' => q({0} oz tr),
						'other' => q({0} oz tr),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz tr),
						'one' => q({0} oz tr),
						'other' => q({0} oz tr),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pund),
						'one' => q({0} pund),
						'other' => q({0} pund),
						'per' => q({0}/pund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(solmasser),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(solmasser),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(am. tonn),
						'one' => q({0} am. tonn),
						'other' => q({0} am. tonn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(am. tonn),
						'one' => q({0} am. tonn),
						'other' => q({0} am. tonn),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hk),
						'one' => q({0} hk),
						'other' => q({0} hk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hk),
						'one' => q({0} hk),
						'other' => q({0} hk),
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
						'name' => q(Bf),
						'one' => q(Bf {0}),
						'other' => q(Bf {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Bf),
						'one' => q(Bf {0}),
						'other' => q(Bf {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/time),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/time),
						'one' => q({0} km/t),
						'other' => q({0} km/t),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(lys),
						'one' => q({0} lys),
						'other' => q({0} lys),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(lys),
						'one' => q({0} lys),
						'other' => q({0} lys),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meter/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meter/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(miles/t),
						'one' => q({0} mile/t),
						'other' => q({0} miles/t),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(miles/t),
						'one' => q({0} mile/t),
						'other' => q({0} miles/t),
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
					'volume-acre-foot' => {
						'name' => q(acre-fot),
						'one' => q({0} ac-fot),
						'other' => q({0} ac-fot),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-fot),
						'one' => q({0} ac-fot),
						'other' => q({0} ac-fot),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(fat),
						'one' => q({0} fat),
						'other' => q({0} fat),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(fat),
						'one' => q({0} fat),
						'other' => q({0} fat),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
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
					'volume-cubic-foot' => {
						'name' => q(fot³),
						'one' => q({0} fot³),
						'other' => q({0} fot³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fot³),
						'one' => q({0} fot³),
						'other' => q({0} fot³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(tommer³),
						'one' => q({0} tomme³),
						'other' => q({0} tommer³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(tommer³),
						'one' => q({0} tomme³),
						'other' => q({0} tommer³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(miles³),
						'one' => q({0} mile³),
						'other' => q({0} miles³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(miles³),
						'one' => q({0} mile³),
						'other' => q({0} miles³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
						'one' => q({0} yard³),
						'other' => q({0} yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(kopper),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(kopper),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(m. kopper),
						'one' => q({0} m. kopp),
						'other' => q({0} m. kopper),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(m. kopper),
						'one' => q({0} m. kopp),
						'other' => q({0} m. kopper),
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
						'name' => q(bs),
						'one' => q({0} bs),
						'other' => q({0} bs),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(bs),
						'one' => q({0} bs),
						'other' => q({0} bs),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(imp. bs),
						'one' => q({0} imp. bs),
						'other' => q({0} imp. bs),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(imp. bs),
						'one' => q({0} imp. bs),
						'other' => q({0} imp. bs),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dråpe),
						'one' => q({0} dråpe),
						'other' => q({0} dråpe),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dråpe),
						'one' => q({0} dråpe),
						'other' => q({0} dråpe),
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
						'name' => q(imp. fl oz),
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(imp. fl oz),
						'one' => q({0} imp. fl oz),
						'other' => q({0} imp. fl oz),
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
						'name' => q(brit. gal),
						'one' => q({0} brit. gal),
						'other' => q({0} brit. gal),
						'per' => q({0}/brit. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(brit. gal),
						'one' => q({0} brit. gal),
						'other' => q({0} brit. gal),
						'per' => q({0}/brit. gal),
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
						'name' => q(shot),
						'one' => q({0} shot),
						'other' => q({0} shot),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(shot),
						'one' => q({0} shot),
						'other' => q({0} shot),
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
						'name' => q(klype),
						'one' => q({0} klyper),
						'other' => q({0} klyper),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(klype),
						'one' => q({0} klyper),
						'other' => q({0} klyper),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(imp. quart),
						'one' => q({0} imp. quart),
						'other' => q({0} imp. quart),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(imp. quart),
						'one' => q({0} imp. quart),
						'other' => q({0} imp. quart),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ss),
						'one' => q({0} ss),
						'other' => q({0} ss),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ts),
						'one' => q({0} ts),
						'other' => q({0} ts),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ts),
						'one' => q({0} ts),
						'other' => q({0} ts),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ja|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nei)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} og {1}),
				2 => q({0} og {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'group' => q( ),
			'minusSign' => q(؜−),
			'timeSeparator' => q(.),
		},
		'arabext' => {
			'decimal' => q(,),
			'group' => q( ),
			'minusSign' => q(‎−‎),
			'timeSeparator' => q(.),
		},
		'latn' => {
			'decimal' => q(,),
			'group' => q( ),
			'minusSign' => q(−),
			'timeSeparator' => q(.),
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
					'one' => '0 tusen',
					'other' => '0 tusen',
				},
				'10000' => {
					'one' => '00 tusen',
					'other' => '00 tusen',
				},
				'100000' => {
					'one' => '000 tusen',
					'other' => '000 tusen',
				},
				'1000000' => {
					'one' => '0 million',
					'other' => '0 millioner',
				},
				'10000000' => {
					'one' => '00 millioner',
					'other' => '00 millioner',
				},
				'100000000' => {
					'one' => '000 millioner',
					'other' => '000 millioner',
				},
				'1000000000' => {
					'one' => '0 milliard',
					'other' => '0 milliarder',
				},
				'10000000000' => {
					'one' => '00 milliarder',
					'other' => '00 milliarder',
				},
				'100000000000' => {
					'one' => '000 milliarder',
					'other' => '000 milliarder',
				},
				'1000000000000' => {
					'one' => '0 billion',
					'other' => '0 billioner',
				},
				'10000000000000' => {
					'one' => '00 billioner',
					'other' => '00 billioner',
				},
				'100000000000000' => {
					'one' => '000 billioner',
					'other' => '000 billioner',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0k',
					'other' => '0k',
				},
				'10000' => {
					'one' => '00k',
					'other' => '00k',
				},
				'100000' => {
					'one' => '000k',
					'other' => '000k',
				},
				'1000000' => {
					'one' => '0 mill'.'',
					'other' => '0 mill'.'',
				},
				'10000000' => {
					'one' => '00 mill'.'',
					'other' => '00 mill'.'',
				},
				'100000000' => {
					'one' => '000 mill'.'',
					'other' => '000 mill'.'',
				},
				'1000000000' => {
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
				},
				'10000000000' => {
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
				},
				'100000000000' => {
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 bill'.'',
					'other' => '0 bill'.'',
				},
				'10000000000000' => {
					'one' => '00 bill'.'',
					'other' => '00 bill'.'',
				},
				'100000000000000' => {
					'one' => '000 bill'.'',
					'other' => '000 bill'.'',
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
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'arabext' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'bali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'beng' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'brah' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'cakm' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'cham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'deva' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'fullwide' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'gujr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'guru' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'hanidec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'java' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'kali' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'khmr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'knda' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'lana' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'lanatham' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'laoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'negative' => '(¤ #,##0.00)',
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'negative' => '-#,##0.00 ¤',
						'positive' => '#,##0.00 ¤',
					},
				},
			},
		},
		'lepc' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'limb' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mlym' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mong' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mtei' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mymr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'mymrshan' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'nkoo' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'olck' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'orya' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'osma' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'saur' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'shrd' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'sora' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'sund' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'takr' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'talu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'tamldec' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'telu' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'thai' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'tibt' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
					},
				},
			},
		},
		'vaii' => {
			'pattern' => {
				'default' => {
					'accounting' => {
						'positive' => '¤ #,##0.00',
					},
					'standard' => {
						'positive' => '¤ #,##0.00',
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
				'currency' => q(andorranske pesetas),
				'one' => q(andorransk pesetas),
				'other' => q(andorranske pesetas),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(emiratarabiske dirham),
				'one' => q(emiratarabisk dirham),
				'other' => q(emiratarabiske dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afgansk afghani \(1927–2002\)),
				'one' => q(afghansk afghani \(1927–2002\)),
				'other' => q(afghanske afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghanske afghani),
				'one' => q(afghansk afghani),
				'other' => q(afghanske afghani),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albanske lek \(1946–1965\)),
				'one' => q(albansk lek \(1946–1965\)),
				'other' => q(albanske lek \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albanske lek),
				'one' => q(albansk lek),
				'other' => q(albanske lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armenske dram),
				'one' => q(armensk dram),
				'other' => q(armenske dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nederlandske antillegylden),
				'one' => q(nederlandsk antillegylden),
				'other' => q(nederlandske antillegylden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolanske kwanza),
				'one' => q(angolansk kwanza),
				'other' => q(angolanske kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolanske kwanza \(1977–1990\)),
				'one' => q(angolansk kwanza \(1977–1990\)),
				'other' => q(angolanske kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolanske nye kwanza \(1990–2000\)),
				'one' => q(angolansk ny kwanza),
				'other' => q(angolanske nye kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolanske omjusterte kwanza \(1995–1999\)),
				'one' => q(angolansk kwanza reajustado \(1995–1999\)),
				'other' => q(angolanske omjusterte kwanza \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinske australer),
				'one' => q(argentinsk austral),
				'other' => q(argentinske australer),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentinske peso ley),
				'one' => q(argentinsk peso ley),
				'other' => q(argentinske peso ley),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentinsk pesos \(1881–1970\)),
				'one' => q(argentinsk pesos \(1881–1970\)),
				'other' => q(argentinske pesos \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinske pesos \(1983–1985\)),
				'one' => q(argentinsk pesos \(1983–1985\)),
				'other' => q(argentinske pesos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinske pesos),
				'one' => q(argentinsk peso),
				'other' => q(argentinske pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(østerrikske shilling),
				'one' => q(østerriksk schilling),
				'other' => q(østerrikske schilling),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(australske dollar),
				'one' => q(australsk dollar),
				'other' => q(australske dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubiske floriner),
				'one' => q(arubisk florin),
				'other' => q(arubiske floriner),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(aserbajdsjanske manat \(1993–2006\)),
				'one' => q(aserbajdsjansk manat \(1993–2006\)),
				'other' => q(aserbajdsjanske manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(aserbajdsjanske manat),
				'one' => q(aserbajdsjansk manat),
				'other' => q(aserbajdsjanske manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinske dinarer \(1992–1994\)),
				'one' => q(bosnisk-hercegovinsk dinar \(1992–1994\)),
				'other' => q(bosnisk-hercegovinske dinarer \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosnisk-hercegovinske konvertible mark),
				'one' => q(bosnisk-hercegovinsk konvertibel mark),
				'other' => q(bosnisk-hercegovinske konvertible mark),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(nye bosnisk-hercegovinske dinarer \(1994–1997\)),
				'one' => q(ny bosnisk-hercegovinsk dinar \(1994–1997\)),
				'other' => q(nye bosnisk-hercegovinske dinarer \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadiske dollar),
				'one' => q(barbadisk dollar),
				'other' => q(barbadiske dollar),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladeshiske taka),
				'one' => q(bangladeshisk taka),
				'other' => q(bangladeshiske taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgiske franc \(konvertible\)),
				'one' => q(belgisk franc \(konvertibel\)),
				'other' => q(belgiske franc \(konvertible\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgiske franc),
				'one' => q(belgisk franc),
				'other' => q(belgiske franc),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiske franc \(finansielle\)),
				'one' => q(belgisk franc \(finansiell\)),
				'other' => q(belgiske franc \(finansielle\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarske lev \(hard\)),
				'one' => q(bulgarsk lev \(hard\)),
				'other' => q(bulgarske lev \(hard\)),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bulgarske lev \(sosialist\)),
				'one' => q(bulgarsk lev \(sosialist\)),
				'other' => q(bulgarske lev \(sosialist\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarske lev),
				'one' => q(bulgarsk lev),
				'other' => q(bulgarske lev),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulgarske lev \(1879–1952\)),
				'one' => q(bulgarsk lev \(1879–1952\)),
				'other' => q(bulgarske lev \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainske dinarer),
				'one' => q(bahrainsk dinar),
				'other' => q(bahrainske dinarer),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiske franc),
				'one' => q(burundisk franc),
				'other' => q(burundiske franc),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudiske dollar),
				'one' => q(bermudisk dollar),
				'other' => q(bermudiske dollar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiske dollar),
				'one' => q(bruneisk dollar),
				'other' => q(bruneiske dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolivianske boliviano),
				'one' => q(boliviansk boliviano),
				'other' => q(bolivianske boliviano),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(bolivianske boliviano \(1863–1963\)),
				'one' => q(boliviansk boliviano \(1863–1963\)),
				'other' => q(bolivianske boliviano \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolivianske pesos),
				'one' => q(boliviansk pesos),
				'other' => q(bolivianske pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolivianske mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro novo \(1967–1986\)),
				'one' => q(brasiliansk cruzeiro novo \(1967–1986\)),
				'other' => q(brasilianske cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brasilianske cruzados \(1986–1989\)),
				'one' => q(brasiliansk cruzado \(1986–1989\)),
				'other' => q(brasilianske cruzado \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro \(1990–1993\)),
				'one' => q(brasiliansk cruzeiro \(1990–1993\)),
				'other' => q(brasilianske cruzeiro \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brasilianske real),
				'one' => q(brasiliansk real),
				'other' => q(brasilianske real),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brasilianske cruzado novo \(1989–1990\)),
				'one' => q(brasiliansk cruzado novo \(1989–1990\)),
				'other' => q(brasilianske cruzado novo \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro \(1993–1994\)),
				'one' => q(brasiliansk cruzeiro \(1993–1994\)),
				'other' => q(brasilianske cruzeiro \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(brasilianske cruzeiro \(1942–1967\)),
				'one' => q(brasiliansk cruzeiro \(1942–1967\)),
				'other' => q(brasilianske cruzeiro \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamanske dollar),
				'one' => q(bahamansk dollar),
				'other' => q(bahamanske dollar),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanske ngultrum),
				'one' => q(bhutansk ngultrum),
				'other' => q(bhutanske ngultrum),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmesiske kyat),
				'one' => q(burmesisk kyat),
				'other' => q(burmesiske kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanske pula),
				'one' => q(botswansk pula),
				'other' => q(botswanske pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(hviterussiske nye rubler \(1994–1999\)),
				'one' => q(hviterussisk ny rubel \(1994–1999\)),
				'other' => q(hviterussiske nye rubler \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(nye belarusiske rubler),
				'one' => q(ny belarusisk rubel),
				'other' => q(nye belarusiske rubler),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(hviterussiske rubler \(2000–2016\)),
				'one' => q(hviterussisk rubel \(2000–2016\)),
				'other' => q(hviterussiske rubler \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(beliziske dollar),
				'one' => q(belizisk dollar),
				'other' => q(beliziske dollar),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadiske dollar),
				'one' => q(kanadisk dollar),
				'other' => q(kanadiske dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongolesiske franc),
				'one' => q(kongolesisk franc),
				'other' => q(kongolesiske franc),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euro),
				'one' => q(WIR-euro),
				'other' => q(WIR-euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(sveitsiske franc),
				'one' => q(sveitsisk franc),
				'other' => q(sveitsiske franc),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR franc),
				'one' => q(WIR-franc),
				'other' => q(WIR-franc),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(chilenske escudo),
				'one' => q(chilensk escudo),
				'other' => q(chilenske escudo),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(chilenske unidades de fomento),
				'one' => q(chilensk unidades de fomento),
				'other' => q(chilenske unidades de fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilenske pesos),
				'one' => q(chilensk peso),
				'other' => q(chilenske pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(kinesiske yuan \(offshore\)),
				'one' => q(kinesisk yuan \(offshore\)),
				'other' => q(kinesiske yuan \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Kinas folkebank dollar),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(kinesiske yuan),
				'one' => q(kinesisk yuan),
				'other' => q(kinesiske yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(colombianske pesos),
				'one' => q(colombiansk peso),
				'other' => q(colombianske pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(colombianske unidad de valor real),
				'one' => q(colombiansk unidad de valor real),
				'other' => q(colombianske unidad de valor real),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(costaricanske colón),
				'one' => q(costaricansk colón),
				'other' => q(costaricanske colón),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(serbiske dinarer \(2002–2006\)),
				'one' => q(serbisk dinar \(2002–2006\)),
				'other' => q(serbiske dinarer \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(tsjekkoslovakiske koruna \(hard\)),
				'one' => q(tsjekkoslovakisk koruna \(hard\)),
				'other' => q(tsjekkoslovakiske koruna \(hard\)),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubanske konvertible pesos),
				'one' => q(kubansk konvertibel peso),
				'other' => q(kubanske konvertible pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubanske pesos),
				'one' => q(kubansk peso),
				'other' => q(kubanske pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kappverdiske escudos),
				'one' => q(kappverdisk escudo),
				'other' => q(kappverdiske escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(kypriotiske pund),
				'one' => q(kypriotisk pund),
				'other' => q(kypriotiske pund),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tsjekkiske koruna),
				'one' => q(tsjekkisk koruna),
				'other' => q(tsjekkiske koruna),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(østtyske mark),
				'one' => q(østtysk mark),
				'other' => q(østtyske mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(tyske mark),
				'one' => q(tysk mark),
				'other' => q(tyske mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(djiboutiske franc),
				'one' => q(djiboutisk franc),
				'other' => q(djiboutiske franc),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(danske kroner),
				'one' => q(dansk krone),
				'other' => q(danske kroner),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikanske pesos),
				'one' => q(dominikansk peso),
				'other' => q(dominikanske pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algeriske dinarer),
				'one' => q(algerisk dinar),
				'other' => q(algeriske dinarer),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ecuadorianske sucre),
				'one' => q(ecuadoriansk sucre),
				'other' => q(ecuadorianske sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ecuadorianske unidad de valor constante \(UVC\)),
				'one' => q(ecuadoriansk unidad de valor constante \(UVC\)),
				'other' => q(ecuadorianske unidad de valor constante \(UVC\)),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estiske kroon),
				'one' => q(estisk kroon),
				'other' => q(estiske kroner),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptiske pund),
				'one' => q(egyptisk pund),
				'other' => q(egyptiske pund),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritreiske nakfa),
				'one' => q(eritreisk nakfa),
				'other' => q(eritreiske nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(spanske peseta \(A–konto\)),
				'one' => q(spansk peseta \(A–konto\)),
				'other' => q(spanske peseta \(A–konto\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(spanske peseta \(konvertibel konto\)),
				'one' => q(spansk peseta \(konvertibel konto\)),
				'other' => q(spanske peseta \(konvertibel konto\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(spanske peseta),
				'one' => q(spansk peseta),
				'other' => q(spanske peseta),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopiske birr),
				'one' => q(etiopisk birr),
				'other' => q(etiopiske birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(finske mark),
				'one' => q(finsk mark),
				'other' => q(finske mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fijianske dollar),
				'one' => q(fijiansk dollar),
				'other' => q(fijianske dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandspund),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(franske franc),
				'one' => q(fransk franc),
				'other' => q(franske franc),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britiske pund),
				'one' => q(britisk pund),
				'other' => q(britiske pund),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(georgiske kupon larit),
				'one' => q(georgisk kupon larit),
				'other' => q(georgiske kupon larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgiske lari),
				'one' => q(georgisk lari),
				'other' => q(georgiske lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanesisk cedi \(1979–2007\)),
				'one' => q(ghanesisk cedi \(1979–2007\)),
				'other' => q(ghanesiske cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanesiske cedi),
				'one' => q(ghanesisk cedi),
				'other' => q(ghanesiske cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltarske pund),
				'one' => q(gibraltarsk pund),
				'other' => q(gibraltarske pund),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiske dalasi),
				'one' => q(gambisk dalasi),
				'other' => q(gambiske dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineanske franc),
				'one' => q(guineansk franc),
				'other' => q(guineanske franc),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guineanske syli),
				'one' => q(guineansk syli),
				'other' => q(guineanske syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekvatorialguineanske ekwele guineana),
				'one' => q(ekvatorialguineansk ekwele guineana),
				'other' => q(ekvatorialguineanske ekwele guineana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(greske drakmer),
				'one' => q(gresk drakme),
				'other' => q(greske drakmer),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalanske quetzal),
				'one' => q(guatemalansk quetzal),
				'other' => q(guatemalanske quetzal),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(portugisiske guinea escudo),
				'one' => q(portugisisk guinea escudo),
				'other' => q(portugisiske guinea escudo),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau-pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanske dollar),
				'one' => q(guyansk dollar),
				'other' => q(guyanske dollar),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(Hongkong-dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduranske lempira),
				'one' => q(honduransk lempira),
				'other' => q(honduranske lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(kroatiske dinarer),
				'one' => q(kroatisk dinar),
				'other' => q(kroatiske dinarer),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kroatiske kuna),
				'one' => q(kroatisk kuna),
				'other' => q(kroatiske kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitiske gourde),
				'one' => q(haitisk gourde),
				'other' => q(haitiske gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ungarske forinter),
				'one' => q(ungarsk forint),
				'other' => q(ungarske forinter),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonesiske rupier),
				'one' => q(indonesisk rupi),
				'other' => q(indonesiske rupier),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(irske pund),
				'one' => q(irsk pund),
				'other' => q(irske pund),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(israelske pund),
				'one' => q(israelsk pund),
				'other' => q(israelske pund),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(israelske shekler \(1980–1985\)),
				'one' => q(israelsk shekel \(1980–1985\)),
				'other' => q(israelske shekler \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(nye israelske shekler),
				'one' => q(ny israelsk shekel),
				'other' => q(nye israelske shekler),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indiske rupier),
				'one' => q(indisk rupi),
				'other' => q(indiske rupier),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakske dinarer),
				'one' => q(iraksk dinar),
				'other' => q(irakske dinarer),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iranske rialer),
				'one' => q(iransk rial),
				'other' => q(iranske rialer),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(islandske kroner \(1918–1981\)),
				'one' => q(islandsk krone \(1918–1981\)),
				'other' => q(islandske kroner \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandske kroner),
				'one' => q(islandsk krone),
				'other' => q(islandske kroner),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(italienske lire),
				'one' => q(italiensk lire),
				'other' => q(italienske lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaikanske dollar),
				'one' => q(jamaikansk dollar),
				'other' => q(jamaikanske dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordanske dinarer),
				'one' => q(jordansk dinar),
				'other' => q(jordanske dinarer),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japanske yen),
				'one' => q(japansk yen),
				'other' => q(japanske yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenyanske shilling),
				'one' => q(kenyansk shilling),
				'other' => q(kenyanske shilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgisiske som),
				'one' => q(kirgisisk som),
				'other' => q(kirgisiske som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodsjanske riel),
				'one' => q(kambodsjansk riel),
				'other' => q(kambodsjanske riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komoriske franc),
				'one' => q(komorisk franc),
				'other' => q(komoriske franc),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(nordkoreanske won),
				'one' => q(nordkoreansk won),
				'other' => q(nordkoreanske won),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(sørkoreanske hwan \(1953–1962\)),
				'one' => q(sørkoreansk hwan \(1953–1962\)),
				'other' => q(sørkoreanske hwan \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(sørkoreanske won \(1945–1953\)),
				'one' => q(sørkoreansk won \(1945–1953\)),
				'other' => q(sørkoreanske won \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(sørkoreanske won),
				'one' => q(sørkoreansk won),
				'other' => q(sørkoreanske won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitiske dinarer),
				'one' => q(kuwaitisk dinar),
				'other' => q(kuwaitiske dinarer),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(caymanske dollar),
				'one' => q(caymansk dollar),
				'other' => q(caymanske dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kasakhstanske tenge),
				'one' => q(kasakhstansk tenge),
				'other' => q(kasakhstanske tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laotiske kip),
				'one' => q(laotisk kip),
				'other' => q(laotiske kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanesiske pund),
				'one' => q(libanesisk pund),
				'other' => q(libanesiske pund),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srilankiske rupier),
				'one' => q(srilankisk rupi),
				'other' => q(srilankiske rupier),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiske dollar),
				'one' => q(liberisk dollar),
				'other' => q(liberiske dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothiske loti),
				'one' => q(lesothisk loti),
				'other' => q(lesothiske loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litauiske litas),
				'one' => q(litauisk lita),
				'other' => q(litauiske lita),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litauiske talonas),
				'one' => q(litauisk talonas),
				'other' => q(litauiske talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburgske konvertible franc),
				'one' => q(luxemburgsk konvertibel franc),
				'other' => q(luxemburgske konvertible franc),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luxemburgske franc),
				'one' => q(luxemburgsk franc),
				'other' => q(luxemburgske franc),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburgske finansielle franc),
				'one' => q(luxemburgsk finansiell franc),
				'other' => q(luxemburgske finansielle franc),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(latviske lats),
				'one' => q(latvisk lats),
				'other' => q(latviske lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(latviske rubler),
				'one' => q(latvisk rubel),
				'other' => q(latviske rubler),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyske dinarer),
				'one' => q(libysk dinar),
				'other' => q(libyske dinarer),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkanske dirham),
				'one' => q(marokkansk dirham),
				'other' => q(marokkanske dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marokkanske franc),
				'one' => q(marokkansk franc),
				'other' => q(marokkanske franc),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monegaskiske franc),
				'one' => q(monegaskisk franc),
				'other' => q(monegaskiske franc),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldovske cupon),
				'one' => q(moldovsk cupon),
				'other' => q(moldovske cupon),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldovske leu),
				'one' => q(moldovsk leu),
				'other' => q(moldovske lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagassiske ariary),
				'one' => q(madagassisk ariary),
				'other' => q(madagassiske ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagassiske franc),
				'one' => q(madagassisk franc),
				'other' => q(madagassiske franc),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedonske denarer),
				'one' => q(makedonsk denar),
				'other' => q(makedonske denarer),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(makedonske denarer \(1992–1993\)),
				'one' => q(makedonsk denar \(1992–1993\)),
				'other' => q(makedonske denarer \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(maliske franc),
				'one' => q(malisk franc),
				'other' => q(maliske franc),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarske kyat),
				'one' => q(myanmarsk kyat),
				'other' => q(myanmarske kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolske tugrik),
				'one' => q(mongolsk tugrik),
				'other' => q(mongolske tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaoiske pataca),
				'one' => q(makaoisk pataca),
				'other' => q(makaoiske pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritanske ouguiya \(1973–2017\)),
				'one' => q(mauritansk ouguiya \(1973–2017\)),
				'other' => q(mauritanske ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritanske ouguiya),
				'one' => q(mauritansk ouguiya),
				'other' => q(mauritanske ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltesiske lira),
				'one' => q(maltesisk lira),
				'other' => q(maltesiske lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltesiske pund),
				'one' => q(maltesisk pund),
				'other' => q(maltesiske pund),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauritiske rupier),
				'one' => q(mauritisk rupi),
				'other' => q(mauritiske rupier),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maldiviske rupier),
				'one' => q(maldivisk rupi),
				'other' => q(maldiviske rupier),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldiviske rufiyaa),
				'one' => q(maldivisk rufiyaa),
				'other' => q(maldiviske rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawiske kwacha),
				'one' => q(malawisk kwacha),
				'other' => q(malawiske kwacha),
			},
		},
		'MXN' => {
			symbol => 'MXN',
			display_name => {
				'currency' => q(meksikanske pesos),
				'one' => q(meksikansk peso),
				'other' => q(meksikanske pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(meksikanske sølvpesos \(1861–1992\)),
				'one' => q(meksikansk sølvpesos \(1860–1992\)),
				'other' => q(meksikanske sølvpesos \(1860–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(meksikanske unidad de inversion \(UDI\)),
				'one' => q(meksikansk unidad de inversion \(UDI\)),
				'other' => q(meksikanske unidad de inversion \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaysiske ringgit),
				'one' => q(malaysisk ringgit),
				'other' => q(malaysiske ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mosambikiske escudo),
				'one' => q(mosambikisk escudo),
				'other' => q(mosambikiske escudo),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(gamle mosambikiske metical),
				'one' => q(gammel mosambikisk metical),
				'other' => q(gamle mosambikiske metical),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mosambikiske metical),
				'one' => q(mosambikisk metical),
				'other' => q(mosambikiske metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiske dollar),
				'one' => q(namibisk dollar),
				'other' => q(namibiske dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigerianske naira),
				'one' => q(nigeriansk naira),
				'other' => q(nigerianske naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nicaraguanske cordoba \(1988–1991\)),
				'one' => q(nicaraguansk cordoba \(1988–1991\)),
				'other' => q(nicaraguanske cordoba \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nicaraguanske córdoba),
				'one' => q(nicaraguansk córdoba),
				'other' => q(nicaraguanske córdoba),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(nederlandske gylden),
				'one' => q(nederlandsk gylden),
				'other' => q(nederlandske gylden),
			},
		},
		'NOK' => {
			symbol => 'kr',
			display_name => {
				'currency' => q(norske kroner),
				'one' => q(norsk krone),
				'other' => q(norske kroner),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalske rupier),
				'one' => q(nepalsk rupi),
				'other' => q(nepalske rupier),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(newzealandske dollar),
				'one' => q(newzealandsk dollar),
				'other' => q(newzealandske dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omanske rialer),
				'one' => q(omansk rial),
				'other' => q(omanske rialer),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamanske balboa),
				'one' => q(panamansk balboa),
				'other' => q(panamanske balboa),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruanske inti),
				'one' => q(peruansk inti),
				'other' => q(peruanske inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruanske sol),
				'one' => q(peruansk sol),
				'other' => q(peruanske sol),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruanske sol \(1863–1965\)),
				'one' => q(peruansk sol \(1863–1965\)),
				'other' => q(peruanske sol \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuanske kina),
				'one' => q(papuansk kina),
				'other' => q(papuanske kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filippinske pesos),
				'one' => q(filippinsk peso),
				'other' => q(filippinske pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanske rupier),
				'one' => q(pakistansk rupi),
				'other' => q(pakistanske rupier),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polske zloty),
				'one' => q(polsk zloty),
				'other' => q(polske zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(polske zloty \(1950–1995\)),
				'one' => q(polsk zloty \(1950–1995\)),
				'other' => q(polske zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugisiske escudo),
				'one' => q(portugisisk escudo),
				'other' => q(portugisiske escudo),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayanske guarani),
				'one' => q(paraguayansk guarani),
				'other' => q(paraguayanske guarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(qatarske rialer),
				'one' => q(qatarsk rial),
				'other' => q(qatarske rialer),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rhodesiske dollar),
				'one' => q(rhodesisk dollar),
				'other' => q(rhodesiske dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(rumenske leu \(1952–2006\)),
				'one' => q(rumensk leu \(1952–2006\)),
				'other' => q(rumenske leu \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(rumenske leu),
				'one' => q(rumensk leu),
				'other' => q(rumenske lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiske dinarer),
				'one' => q(serbisk dinar),
				'other' => q(serbiske dinarer),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russiske rubler),
				'one' => q(russisk rubel),
				'other' => q(russiske rubler),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(russiske rubler \(1991–1998\)),
				'one' => q(russisk rubel \(1991–1998\)),
				'other' => q(russiske rubler \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandiske franc),
				'one' => q(rwandisk franc),
				'other' => q(rwandiske franc),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudiarabiske riyaler),
				'one' => q(saudiarabisk riyal),
				'other' => q(saudiarabiske riyaler),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomonske dollar),
				'one' => q(salomonsk dollar),
				'other' => q(salomonske dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelliske rupier),
				'one' => q(seychellisk rupi),
				'other' => q(seychelliske rupier),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(sudanesiske dinarer \(1992–2007\)),
				'one' => q(sudanesisk dinar \(1992–2007\)),
				'other' => q(sudanesiske dinarer \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudanske pund),
				'one' => q(sudansk pund),
				'other' => q(sudanske pund),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudanesiske pund),
				'one' => q(sudansk pund \(1957–1998\)),
				'other' => q(sudanske pund \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(svenske kroner),
				'one' => q(svensk krone),
				'other' => q(svenske kroner),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singaporske dollar),
				'one' => q(singaporsk dollar),
				'other' => q(singaporske dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(sankthelenske pund),
				'one' => q(sankthelensk pund),
				'other' => q(sankthelenske pund),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovenske tolar),
				'one' => q(slovensk tolar),
				'other' => q(slovenske tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovakiske koruna),
				'one' => q(slovakisk koruna),
				'other' => q(slovakiske koruna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonsk leone),
				'one' => q(sierraleonsk leone),
				'other' => q(sierraleonske leoner),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonsk leone \(1964–2022\)),
				'one' => q(sierraleonsk leone \(1964–2022\)),
				'other' => q(sierraleonske leoner \(1964–2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliske shilling),
				'one' => q(somalisk shilling),
				'other' => q(somaliske shilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamske dollar),
				'one' => q(surinamsk dollar),
				'other' => q(surinamske dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamske gylden),
				'one' => q(surinamsk gylden),
				'other' => q(surinamske gylden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(sørsudanske pund),
				'one' => q(sørsudansk pund),
				'other' => q(sørsudanske pund),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(saotomesiske dobra \(1977–2017\)),
				'one' => q(saotomesisk dobra \(1977–2017\)),
				'other' => q(saotomesiske dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(saotomesiske dobra),
				'one' => q(saotomesisk dobra),
				'other' => q(saotomesiske dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovjetiske rubler),
				'one' => q(sovjetisk rubel),
				'other' => q(sovjetiske rubler),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvadoranske colon),
				'one' => q(salvadoransk colon),
				'other' => q(salvadoranske colon),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriske pund),
				'one' => q(syrisk pund),
				'other' => q(syriske pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swazilandske lilangeni),
				'one' => q(swazilandsk lilangeni),
				'other' => q(swazilandske lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thailandske baht),
				'one' => q(thailandsk baht),
				'other' => q(thailandske baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadsjikiske rubler),
				'one' => q(tadsjikisk rubel),
				'other' => q(tadsjikiske rubler),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadsjikiske somoni),
				'one' => q(tadsjikisk somoni),
				'other' => q(tadsjikiske somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmenske manat \(1993–2009\)),
				'one' => q(turkmensk manat \(1993–2009\)),
				'other' => q(turkmenske manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmenske manat),
				'one' => q(turkmensk manat),
				'other' => q(turkmenske manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tunisiske dinarer),
				'one' => q(tunisisk dinar),
				'other' => q(tunisiske dinarer),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tonganske paʻanga),
				'one' => q(tongansk paʻanga),
				'other' => q(tonganske paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timoresiske escudo),
				'one' => q(timoresisk escudo),
				'other' => q(timoresiske escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(tyrkiske lire \(1922–2005\)),
				'one' => q(tyrkisk lire \(1922–2005\)),
				'other' => q(tyrkiske lire \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(tyrkiske lire),
				'one' => q(tyrkisk lire),
				'other' => q(tyrkiske lire),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidadiske dollar),
				'one' => q(trinidadisk dollar),
				'other' => q(trinidadiske dollar),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nye taiwanske dollar),
				'one' => q(ny taiwansk dollar),
				'other' => q(nye taiwanske dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzanianske shilling),
				'one' => q(tanzaniansk shilling),
				'other' => q(tanzanianske shilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainske hryvnia),
				'one' => q(ukrainsk hryvnia),
				'other' => q(ukrainske hryvnia),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrainske karbovanetz),
				'one' => q(ukrainsk karbovanetz),
				'other' => q(ukrainske karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandiske shilling \(1966–1987\)),
				'one' => q(ugandisk shilling \(1966–1987\)),
				'other' => q(ugandiske shilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandiske shilling),
				'one' => q(ugandisk shilling),
				'other' => q(ugandiske shilling),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(amerikanske dollar),
				'one' => q(amerikansk dollar),
				'other' => q(amerikanske dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(amerikanske dollar \(neste dag\)),
				'one' => q(amerikansk dollar \(neste dag\)),
				'other' => q(amerikanske dollar \(neste dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(amerikanske dollar \(samme dag\)),
				'one' => q(amerikansk dollar \(samme dag\)),
				'other' => q(amerikanske dollar \(samme dag\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguyanske pesos \(indekserte enheter\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguayanske pesos \(1975–1993\)),
				'one' => q(uruguayansk peso \(1975–1993\)),
				'other' => q(uruguayanske pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayanske pesos),
				'one' => q(uruguyansk peso),
				'other' => q(uruguayanske pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekiske som),
				'one' => q(usbekisk som),
				'other' => q(usbekiske som),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelanske bolivar \(1871–2008\)),
				'one' => q(venezuelansk bolivar \(1871–2008\)),
				'other' => q(venezuelanske bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelanske bolivar \(2008–2018\)),
				'one' => q(venezuelansk bolivar \(2008–2018\)),
				'other' => q(venezuelanske bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelanske bolivar),
				'one' => q(venezuelansk bolivar),
				'other' => q(venezuelanske bolivar),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnamesiske dong),
				'one' => q(vietnamesisk dong),
				'other' => q(vietnamesiske dong),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamesiske dong \(1978–1985\)),
				'one' => q(vietnamesisk dong \(1978–1985\)),
				'other' => q(vietnamesiske dong \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatiske vatu),
				'one' => q(vanuatisk vatu),
				'other' => q(vanuatiske vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoanske tala),
				'one' => q(samoansk tala),
				'other' => q(samoanske tala),
			},
		},
		'XAF' => {
			symbol => 'XAF',
			display_name => {
				'currency' => q(sentralafrikanske CFA-franc),
				'one' => q(sentralafrikansk CFA-franc),
				'other' => q(sentralafrikanske CFA-franc),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(sølv),
				'one' => q(unse sølv),
				'other' => q(unser sølv),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(gull),
				'one' => q(unse gull),
				'other' => q(unser gull),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(europeisk sammensatt enhet),
				'one' => q(europeisk sammensatt enhet),
				'other' => q(europeiske sammensatte enheter),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(europeisk monetær enhet),
				'one' => q(europeisk monetær enhet),
				'other' => q(europeiske monetære enheter),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(europeisk kontoenhet \(XBC\)),
				'one' => q(europeisk kontoenhet \(XBC\)),
				'other' => q(europeiske kontoenheter),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(europeisk kontoenhet \(XBD\)),
				'one' => q(europeisk kontoenhet \(XBD\)),
				'other' => q(europeiske kontoenheter \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(østkaribiske dollar),
				'one' => q(østkaribisk dollar),
				'other' => q(østkaribiske dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(spesielle trekkrettigheter),
				'one' => q(spesiell trekkrettighet),
				'other' => q(spesielle trekkrettigheter),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(europeisk valutaenhet),
				'one' => q(europeisk valutaenhet),
				'other' => q(europeiske valutaenheter),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franske gullfranc),
				'one' => q(fransk gullfranc),
				'other' => q(franske gullfranc),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(franske UIC-franc),
				'one' => q(fransk UIC-franc),
				'other' => q(franske UIC-franc),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(vestafrikanske CFA-franc),
				'one' => q(vestafrikansk CFA-franc),
				'other' => q(vestafrikanske CFA-franc),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladium),
				'one' => q(unse palladium),
				'other' => q(unser palladium),
			},
		},
		'XPF' => {
			symbol => 'XPF',
			display_name => {
				'currency' => q(CFP-franc),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'one' => q(unse platina),
				'other' => q(unser platina),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET-fond),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(testvalutakode),
				'one' => q(testvaluta),
				'other' => q(testvaluta),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB-kontoenhet),
				'one' => q(ADB-kontoenhet),
				'other' => q(ADB-kontoenheter),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(ukjent valuta),
				'one' => q(\(ukjent valuta\)),
				'other' => q(\(ukjent valuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenittiske dinarer),
				'one' => q(jemenittisk dinar),
				'other' => q(jemenittiske dinarer),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenittiske rialer),
				'one' => q(jemenittisk rial),
				'other' => q(jemenittiske rialer),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(jugoslaviske dinarer \(hard\)),
				'one' => q(jugoslavisk dinar \(hard\)),
				'other' => q(jugoslaviske dinarer \(hard\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(jugoslaviske noviy-dinarer),
				'one' => q(jugoslavisk noviy-dinar),
				'other' => q(jugoslaviske noviy-dinarer),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(jugoslaviske konvertible dinarer),
				'one' => q(jugoslavisk konvertibel dinar),
				'other' => q(jugoslaviske konvertible dinarer),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(jugoslaviske reformerte dinarer \(1992–1993\)),
				'one' => q(jugoslavisk reformert dinar \(1992–1993\)),
				'other' => q(jugoslaviske reformerte dinarer \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(sørafrikanske rand \(finansielle\)),
				'one' => q(sørafrikansk rand \(finansiell\)),
				'other' => q(sørafrikanske rand \(finansielle\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(sørafrikanske rand),
				'one' => q(sørafrikansk rand),
				'other' => q(sørafrikanske rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambiske kwacha \(1968–2012\)),
				'one' => q(zambisk kwacha \(1968–2012\)),
				'other' => q(zambiske kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambiske kwacha),
				'one' => q(zambisk kwacha),
				'other' => q(zambiske kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairiske nye zaire),
				'one' => q(zairisk ny zaire),
				'other' => q(zairiske nye zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairiske zaire),
				'one' => q(zairisk zaire),
				'other' => q(zairiske zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwiske dollar \(1980–2008\)),
				'one' => q(zimbabwisk dollar \(1980–2008\)),
				'other' => q(zimbabwiske dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabwisk dollar \(2009\)),
				'one' => q(zimbabwisk dollar \(2009\)),
				'other' => q(zimbabwiske dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(zimbabwisk dollar \(2008\)),
				'one' => q(zimbabwisk dollar \(2008\)),
				'other' => q(zimbabwiske dollar \(2008\)),
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
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'paona',
							'epep',
							'mesra',
							'nasie'
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
							'meskerem',
							'tekemt',
							'hedar',
							'tahsas',
							'ter',
							'yekatit',
							'megabit',
							'miazia',
							'genbot',
							'sene',
							'hamle',
							'nehasse',
							'pagumen'
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
							'jan.',
							'feb.',
							'mars',
							'apr.',
							'mai',
							'juni',
							'juli',
							'aug.',
							'sep.',
							'okt.',
							'nov.',
							'des.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'mars',
							'april',
							'mai',
							'juni',
							'juli',
							'august',
							'september',
							'oktober',
							'november',
							'desember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'feb',
							'mar',
							'apr',
							'mai',
							'jun',
							'jul',
							'aug',
							'sep',
							'okt',
							'nov',
							'des'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
							'M',
							'A',
							'M',
							'J',
							'J',
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
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'tishri',
							'heshvan',
							'kislev',
							'tevet',
							'shevat',
							'adar I',
							'adar',
							'nisan',
							'iyar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
							'chaitra',
							'vaisakha',
							'jyaistha',
							'asadha',
							'sravana',
							'bhadra',
							'asvina',
							'kartika',
							'agrahayana',
							'pausa',
							'magha',
							'phalguna'
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
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-q.',
							'dhuʻl-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'muharram',
							'safar',
							'rabiʻ I',
							'rabiʻ II',
							'jumada I',
							'jumada II',
							'rajab',
							'shaʻban',
							'ramadan',
							'shawwal',
							'dhuʻl-qiʻdah',
							'dhuʻl-hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'jum. I',
							'jum. II',
							'raj.',
							'sha.',
							'ram.',
							'shaw.',
							'dhuʻl-q.',
							'Dhuʻl-H.'
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
							'farvardin',
							'ordibehesht',
							'khordad',
							'tir',
							'mordad',
							'shahrivar',
							'mehr',
							'aban',
							'azar',
							'dey',
							'bahman',
							'esfand'
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
						mon => 'man.',
						tue => 'tir.',
						wed => 'ons.',
						thu => 'tor.',
						fri => 'fre.',
						sat => 'lør.',
						sun => 'søn.'
					},
					short => {
						mon => 'ma.',
						tue => 'ti.',
						wed => 'on.',
						thu => 'to.',
						fri => 'fr.',
						sat => 'lø.',
						sun => 'sø.'
					},
					wide => {
						mon => 'mandag',
						tue => 'tirsdag',
						wed => 'onsdag',
						thu => 'torsdag',
						fri => 'fredag',
						sat => 'lørdag',
						sun => 'søndag'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'O',
						thu => 'T',
						fri => 'F',
						sat => 'L',
						sun => 'S'
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => '1. kvartal',
						1 => '2. kvartal',
						2 => '3. kvartal',
						3 => '4. kvartal'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1.',
						1 => '2.',
						2 => '3.',
						3 => '4.'
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
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic-amete-alem') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
						&& $time < 1000;
					return 'morning2' if $time >= 1000
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
					'afternoon1' => q{etterm.},
					'am' => q{a.m.},
					'evening1' => q{kveld},
					'midnight' => q{midn.},
					'morning1' => q{morg.},
					'morning2' => q{form.},
					'night1' => q{natt},
					'pm' => q{p.m.},
				},
				'narrow' => {
					'afternoon1' => q{em.},
					'am' => q{a},
					'evening1' => q{kv.},
					'midnight' => q{mn.},
					'morning1' => q{mg.},
					'morning2' => q{fm.},
					'night1' => q{nt.},
					'pm' => q{p},
				},
				'wide' => {
					'afternoon1' => q{på ettermiddagen},
					'evening1' => q{på kvelden},
					'midnight' => q{midnatt},
					'morning1' => q{på morgenen},
					'morning2' => q{på formiddagen},
					'night1' => q{på natten},
				},
			},
			'stand-alone' => {
				'narrow' => {
					'afternoon1' => q{em.},
					'evening1' => q{kv.},
					'midnight' => q{mn.},
					'morning1' => q{mg.},
					'morning2' => q{fm.},
					'night1' => q{nt.},
				},
				'wide' => {
					'afternoon1' => q{ettermiddag},
					'evening1' => q{kveld},
					'midnight' => q{midnatt},
					'morning1' => q{morgen},
					'morning2' => q{formiddag},
					'night1' => q{natt},
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
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => '0. t.a.',
				'1' => '1. t.a.'
			},
			narrow => {
				'0' => 'TA0',
				'1' => 'TA1'
			},
			wide => {
				'0' => '0. tidsalder',
				'1' => '1. tidsalder'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => '0. t.a.',
				'1' => '1. t.a.'
			},
			narrow => {
				'0' => 'TA0',
				'1' => 'TA1'
			},
			wide => {
				'0' => '0. tidsalder',
				'1' => '1. tidsalder'
			},
		},
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => '0. t.a.'
			},
			narrow => {
				'0' => 'TA0'
			},
			wide => {
				'0' => '0. tidsalder'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'f.Kr.',
				'1' => 'e.Kr.'
			},
			wide => {
				'0' => 'før Kristus',
				'1' => 'etter Kristus'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'saka'
			},
		},
		'islamic' => {
		},
		'japanese' => {
			abbreviated => {
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'17' => 'Ten-ō (781-782)',
				'26' => 'Ten-an (857-859)',
				'78' => 'Ten-ei (1110-1113)'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Før ROC',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'Før R.O.C.'
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
			'full' => q{EEEE d. MMMM r(U)},
			'long' => q{d. MMMM r(U)},
			'medium' => q{d. MMM r},
			'short' => q{d.M.r},
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.M.y G},
		},
		'gregorian' => {
			'full' => q{EEEE d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{dd.MM.y},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM y G},
			'short' => q{d.M y G},
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
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
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
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
		},
		'coptic' => {
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
		'chinese' => {
			Ed => q{E d.},
			Gy => q{r(U)},
			GyMMM => q{MMM r(U)},
			GyMMMEd => q{E d. MMM r(U)},
			GyMMMd => q{d. MMM r},
			M => q{L.},
			MEd => q{E dd.MM.},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{dd.MM},
			UM => q{MM. U},
			UMMM => q{MMM U},
			UMMMd => q{d. MMM U},
			UMd => q{d.MM. U},
			d => q{d.},
			h => q{h a},
			yMd => q{dd.MM.r},
			yyyyM => q{MM.r},
			yyyyMEd => q{E dd.MM.r},
			yyyyMMM => q{MMM r(U)},
			yyyyMMMEd => q{E d. MMM r(U)},
			yyyyMMMM => q{MMMM r(U)},
			yyyyMMMd => q{d. MMM r},
			yyyyMd => q{dd.MM.r},
			yyyyQQQ => q{QQQ r(U)},
			yyyyQQQQ => q{QQQQ r(U)},
		},
		'generic' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{dd.MM.y GGGGG},
			M => q{L.},
			MEd => q{E d.M},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y G},
			yyyyMEd => q{E d.M.y G},
			yyyyMM => q{MM.y G},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d. MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E 'kl'. HH:mm},
			EHms => q{E 'kl'. HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{dd.MM.y GGGGG},
			M => q{L.},
			MEd => q{E d.M.},
			MMMEd => q{E d. MMM},
			MMMMW => q{'den' W. 'uken' 'i' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			MMdd => q{d.M.},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M.y},
			yMEd => q{E d.M.y},
			yMM => q{MM.y},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'uke' w 'i' Y},
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
		'buddhist' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'chinese' => {
			M => {
				M => q{MM.–MM.},
			},
			MEd => {
				M => q{dd.MM.E–dd.MM.E},
				d => q{dd.MM.E–dd.MM.E},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d. MMM–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM.–dd.MM.},
				d => q{dd.MM.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y},
				d => q{E dd.MM.y–E dd.MM.y},
				y => q{E dd.MM.y–E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM U},
				y => q{MMM U–MMM U},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM U},
				d => q{E d. MMM–E d. MMM U},
				y => q{E d. MMM U–E d. MMM U},
			},
			yMMMM => {
				M => q{MMMM–MMMM U},
				y => q{MMMM U–MMMM U},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM U},
				d => q{d.–d. U MMM},
				y => q{d. MMM U–d. MMM U},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y},
				d => q{dd.MM.y–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
		'coptic' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'ethiopic' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'generic' => {
			Bh => {
				B => q{h B–h B},
			},
			Bhm => {
				B => q{h:mm B–h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG–MM.y GGGGG},
				M => q{MM.y–MM.y GGGGG},
				y => q{MM.y–MM.y GGGGG},
			},
			GyMEd => {
				G => q{E dd.MM.y GGGGG–E dd.MM.y GGGGG},
				M => q{E dd.MM.y–E dd.MM.y GGGGG},
				d => q{E dd.MM.y–E dd.MM.y GGGGG},
				y => q{E dd.MM.y–E dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E d. MMM y G–E d. MMM y G},
				M => q{E d. MMM–E d. MMM y G},
				d => q{E d. MMM–E d. MMM y G},
				y => q{E d. MMM y–E d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G–d. MMM y G},
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG–dd.MM.y GGGGG},
				M => q{dd.MM.y–dd.MM.y GGGGG},
				d => q{dd.MM.y–dd.MM.y GGGGG},
				y => q{dd.MM.y–dd.MM.y GGGGG},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E d.M.–E d.M.},
				d => q{E d.M.–E d.M.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d. MMM–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.M.–d.M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}–{1}',
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
				M => q{M.y–M.y G},
				y => q{M.y–M.y G},
			},
			yMEd => {
				M => q{E d.M.y–E d.M.y G},
				d => q{E d.M.y–E d.M.y G},
				y => q{E d.M.y–E d.M.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM y G},
				d => q{E d. MMM–E d. MMM y G},
				y => q{E d. MMM y–E d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y–MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			yMd => {
				M => q{d.M.y–d.M.y G},
				d => q{d.M.y–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B–h B},
			},
			Bhm => {
				B => q{h:mm B–h:mm B},
			},
			Gy => {
				G => q{y G–y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{MM.y GGGGG–MM.y GGGGG},
				M => q{MM.y–MM.y GGGGG},
				y => q{MM.y–MM.y GGGGG},
			},
			GyMEd => {
				G => q{E dd.MM.y GGGGG–E dd.MM.y GGGGG},
				M => q{E dd.MM.y–E dd.MM.y GGGGG},
				d => q{E dd.MM.y–E dd.MM.y GGGGG},
				y => q{E dd.MM.y–E dd.MM.y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G–MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y–MMM y G},
			},
			GyMMMEd => {
				G => q{E d. MMM y G–E d. MMM y G},
				M => q{E d. MMM–E d. MMM y G},
				d => q{E d. MMM–E d. MMM y G},
				y => q{E d. MMM y–E d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G–d. MMM y G},
				M => q{d. MMM–d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y–d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y GGGGG–dd.MM.y GGGGG},
				M => q{dd.MM.y–dd.MM.y GGGGG},
				d => q{dd.MM.y–dd.MM.y GGGGG},
				y => q{dd.MM.y–dd.MM.y GGGGG},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E dd.MM.–E dd.MM.},
				d => q{E dd.MM.–E dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E d. MMM–E d. MMM},
				d => q{E d.–E d. MMM},
			},
			MMMd => {
				M => q{d. MMM–d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM.–dd.MM.},
				d => q{dd.MM.–dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a–h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a–h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			hmv => {
				a => q{h:mm a–h:mm a v},
				h => q{h:mm–h:mm a v},
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a–h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{MM.y–MM.y},
				y => q{MM.y–MM.y},
			},
			yMEd => {
				M => q{E dd.MM.y–E dd.MM.y},
				d => q{E dd.MM.y–E dd.MM.y},
				y => q{E dd.MM.y–E dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y–MMM y},
			},
			yMMMEd => {
				M => q{E d. MMM–E d. MMM y},
				d => q{E d.–E d. MMM y},
				y => q{E d. MMM y–E d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y–MMMM y},
			},
			yMMMd => {
				M => q{d. MMM–d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y–d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y–dd.MM.y},
				d => q{dd.MM.y–dd.MM.y},
				y => q{dd.MM.y–dd.MM.y},
			},
		},
		'hebrew' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'indian' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'islamic' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'japanese' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'persian' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
			},
		},
		'roc' => {
			h => {
				a => q{h a–h a},
			},
			hv => {
				a => q{h a–h a v},
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
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(vårstart),
						1 => q(regnvann),
						2 => q(insekter våkner),
						3 => q(vårjevndøgn),
						4 => q(lyst og klart),
						5 => q(kornregn),
						6 => q(sommerstart),
						7 => q(tidl. korn),
						8 => q(korn i aks),
						9 => q(sommersolverv),
						10 => q(liten varme),
						11 => q(stor varme),
						12 => q(høststart),
						13 => q(varmeslutt),
						14 => q(hvit dugg),
						15 => q(høstjevndøgn),
						16 => q(kalddugg),
						17 => q(første frost),
						18 => q(vinterstart),
						19 => q(litt snø),
						20 => q(mye snø),
						21 => q(vintersolverv),
						22 => q(liten kulde),
						23 => q(stor kulde),
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
		regionFormat => q(tidssone for {0}),
		regionFormat => q(sommertid – {0}),
		regionFormat => q(normaltid – {0}),
		'Acre' => {
			long => {
				'daylight' => q#Acre sommertid#,
				'generic' => q#Acre-tid#,
				'standard' => q#Acre normaltid#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#afghansk tid#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar-es-Salaam#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#sentralafrikansk tid#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#østafrikansk tid#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#sørafrikansk tid#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#vestafrikansk sommertid#,
				'generic' => q#vestafrikansk tid#,
				'standard' => q#vestafrikansk normaltid#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#alaskisk sommertid#,
				'generic' => q#alaskisk tid#,
				'standard' => q#alaskisk normaltid#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty, sommertid#,
				'generic' => q#Almaty-tid#,
				'standard' => q#Almaty, standardtid#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#sommertid for Amazonas#,
				'generic' => q#tidssone for Amazonas#,
				'standard' => q#normaltid for Amazonas#,
			},
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caymanøyene#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexico by#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Nord-Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Nord-Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Nord-Dakota#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#sommertid for det sentrale Nord-Amerika#,
				'generic' => q#tidssone for det sentrale Nord-Amerika#,
				'standard' => q#normaltid for det sentrale Nord-Amerika#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#sommertid for den nordamerikanske østkysten#,
				'generic' => q#tidssone for den nordamerikanske østkysten#,
				'standard' => q#normaltid for den nordamerikanske østkysten#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#sommertid for Rocky Mountains (USA)#,
				'generic' => q#tidssone for Rocky Mountains (USA)#,
				'standard' => q#normaltid for Rocky Mountains (USA)#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#sommertid for den nordamerikanske Stillehavskysten#,
				'generic' => q#tidssone for den nordamerikanske Stillehavskysten#,
				'standard' => q#normaltid for den nordamerikanske Stillehavskysten#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Russisk (Anadyr) sommertid#,
				'generic' => q#Russisk (Anadyr) tid#,
				'standard' => q#Russisk (Anadyr) normaltid#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#sommertid for Apia#,
				'generic' => q#tidssone for Apia#,
				'standard' => q#normaltid for Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aqtau, sommertid#,
				'generic' => q#Aqtau-tid#,
				'standard' => q#Aqtau, standardtid#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aqtobe, sommertid#,
				'generic' => q#Aqtobe-tid#,
				'standard' => q#Aqtobe, standardtid#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabisk sommertid#,
				'generic' => q#arabisk tid#,
				'standard' => q#arabisk standardtid#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentinsk sommertid#,
				'generic' => q#argentinsk tid#,
				'standard' => q#argentinsk normaltid#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#vestargentinsk sommertid#,
				'generic' => q#vestargentinsk tid#,
				'standard' => q#vestargentinsk normaltid#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#armensk sommertid#,
				'generic' => q#armensk tid#,
				'standard' => q#armensk normaltid#,
			},
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjkhabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisjkek#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tsjita#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusjanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jajapura#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtsjatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh-byen#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasjkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimpu#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#sommertid for den nordamerikanske atlanterhavskysten#,
				'generic' => q#tidssone for den nordamerikanske atlanterhavskysten#,
				'standard' => q#normaltid for den nordamerikanske atlanterhavskysten#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asorene#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariøyene#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapp Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Færøyene#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Sør-Georgia#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#sentralaustralsk sommertid#,
				'generic' => q#sentralaustralsk tid#,
				'standard' => q#sentralaustralsk normaltid#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#vest-sentralaustralsk sommertid#,
				'generic' => q#vest-sentralaustralsk tid#,
				'standard' => q#vest-sentralaustralsk normaltid#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#østaustralsk sommertid#,
				'generic' => q#østaustralsk tid#,
				'standard' => q#østaustralsk normaltid#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#vestaustralsk sommertid#,
				'generic' => q#vestaustralsk tid#,
				'standard' => q#vestaustralsk normaltid#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#aserbajdsjansk sommertid#,
				'generic' => q#aserbajdsjansk tid#,
				'standard' => q#aserbajdsjansk normaltid#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#asorisk sommertid#,
				'generic' => q#asorisk tid#,
				'standard' => q#asorisk normaltid#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladeshisk sommertid#,
				'generic' => q#bangladeshisk tid#,
				'standard' => q#bangladeshisk normaltid#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#bhutansk tid#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#boliviansk tid#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#sommertid for Brasilia#,
				'generic' => q#tidssone for Brasilia#,
				'standard' => q#normaltid for Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#tidssone for Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kappverdisk sommertid#,
				'generic' => q#kappverdisk tid#,
				'standard' => q#kappverdisk normaltid#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Casey-tid#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#tidssone for Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#sommertid for Chatham#,
				'generic' => q#tidssone for Chatham#,
				'standard' => q#normaltid for Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#chilensk sommertid#,
				'generic' => q#chilensk tid#,
				'standard' => q#chilensk normaltid#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#kinesisk sommertid#,
				'generic' => q#kinesisk tid#,
				'standard' => q#kinesisk normaltid#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#tidssone for Christmasøya#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#tidssone for Kokosøyene#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#colombiansk sommertid#,
				'generic' => q#colombiansk tid#,
				'standard' => q#colombiansk normaltid#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#halv sommertid for Cookøyene#,
				'generic' => q#tidssone for Cookøyene#,
				'standard' => q#normaltid for Cookøyene#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#cubansk sommertid#,
				'generic' => q#cubansk tid#,
				'standard' => q#cubansk normaltid#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#tidssone for Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#tidssone for Dumont d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#østtimoresisk tid#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#sommertid for Påskeøya#,
				'generic' => q#tidssone for Påskeøya#,
				'standard' => q#normaltid for Påskeøya#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ecuadoriansk tid#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinert universaltid#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ukjent by#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brussel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#București#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#København#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#irsk sommertid#,
			},
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsingfors#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#britisk sommertid#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uljanovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikanstaten#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warszawa#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#sentraleuropeisk sommertid#,
				'generic' => q#sentraleuropeisk tid#,
				'standard' => q#sentraleuropeisk normaltid#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#østeuropeisk sommertid#,
				'generic' => q#østeuropeisk tid#,
				'standard' => q#østeuropeisk normaltid#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#fjern-østeuropeisk tid#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#vesteuropeisk sommertid#,
				'generic' => q#vesteuropeisk tid#,
				'standard' => q#vesteuropeisk normaltid#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#sommertid for Falklandsøyene#,
				'generic' => q#tidssone for Falklandsøyene#,
				'standard' => q#normaltid for Falklandsøyene#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fijiansk sommertid#,
				'generic' => q#fijiansk tid#,
				'standard' => q#fijiansk normaltid#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#tidssone for Fransk Guyana#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#tidssone for De franske sørterritorier#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich middeltid#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#tidssone for Galápagosøyene#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#tidssone for Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#georgisk sommertid#,
				'generic' => q#georgisk tid#,
				'standard' => q#georgisk normaltid#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#tidssone for Gilbertøyene#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#østgrønlandsk sommertid#,
				'generic' => q#østgrønlandsk tid#,
				'standard' => q#østgrønlandsk normaltid#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#vestgrønlandsk sommertid#,
				'generic' => q#vestgrønlandsk tid#,
				'standard' => q#vestgrønlandsk normaltid#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam-tid#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#tidssone for Persiabukta#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyansk tid#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#sommertid for Hawaii og Aleutene#,
				'generic' => q#tidssone for Hawaii og Aleutene#,
				'standard' => q#normaltid for Hawaii og Aleutene#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#sommertid for Hongkong#,
				'generic' => q#tidssone for Hongkong#,
				'standard' => q#normaltid for Hongkong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#sommertid for Khovd#,
				'generic' => q#tidssone for Khovd#,
				'standard' => q#normaltid for Khovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indisk tid#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Christmasøya#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosøyene#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorene#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivene#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#tidssone for Indiahavet#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indokinesisk tid#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#sentralindonesisk tid#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#østindonesisk tid#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#vestindonesisk tid#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iransk sommertid#,
				'generic' => q#iransk tid#,
				'standard' => q#iransk normaltid#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#sommertid for Irkutsk#,
				'generic' => q#tidssone for Irkutsk#,
				'standard' => q#normaltid for Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#israelsk sommertid#,
				'generic' => q#israelsk tid#,
				'standard' => q#israelsk normaltid#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japansk sommertid#,
				'generic' => q#japansk tid#,
				'standard' => q#japansk normaltid#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Russisk (Petropavlovsk-Kamtsjatskij) sommertid#,
				'generic' => q#Russisk (Petropavlovsk-Kamtsjatskij) tid#,
				'standard' => q#Russisk (Petropavlovsk-Kamtsjatskij) normaltid#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#kasakhstansk tid#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#østkasakhstansk tid#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#vestkasakhstansk tid#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#koreansk sommertid#,
				'generic' => q#koreansk tid#,
				'standard' => q#koreansk normaltid#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#tidssone for Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#sommertid for Krasnojarsk#,
				'generic' => q#tidssone for Krasnojarsk#,
				'standard' => q#normaltid for Krasnojarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgisisk tid#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Lanka-tid#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#tidssone for Linjeøyene#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#sommertid for Lord Howe-øya#,
				'generic' => q#tidssone for Lord Howe-øya#,
				'standard' => q#normaltid for Lord Howe-øya#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Macau, sommertid#,
				'generic' => q#Macau-tid#,
				'standard' => q#Macau, standardtid#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#sommertid for Magadan#,
				'generic' => q#tidssone for Magadan#,
				'standard' => q#normaltid for Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malaysisk tid#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldivisk tid#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#tidssone for Marquesasøyene#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#marshallesisk tid#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#mauritisk sommertid#,
				'generic' => q#mauritisk tid#,
				'standard' => q#mauritisk normaltid#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#tidssone for Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#sommertid for den meksikanske Stillehavskysten#,
				'generic' => q#tidssone for den meksikanske Stillehavskysten#,
				'standard' => q#normaltid for den meksikanske Stillehavskysten#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#sommertid for Ulan Bator#,
				'generic' => q#tidssone for Ulan Bator#,
				'standard' => q#normaltid for Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#sommertid for Moskva#,
				'generic' => q#tidssone for Moskva#,
				'standard' => q#normaltid for Moskva#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#myanmarsk tid#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#naurisk tid#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepalsk tid#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#kaledonsk sommertid#,
				'generic' => q#kaledonsk tid#,
				'standard' => q#kaledonsk normaltid#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#newzealandsk sommertid#,
				'generic' => q#newzealandsk tid#,
				'standard' => q#newzealandsk normaltid#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#sommertid for Newfoundland#,
				'generic' => q#tidssone for Newfoundland#,
				'standard' => q#normaltid for Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#tidssone for Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#sommertid for Norfolkøya#,
				'generic' => q#tidssone for Norfolkøya#,
				'standard' => q#normaltid for Norfolkøya#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#sommertid for Fernando de Noronha#,
				'generic' => q#tidssone for Fernando de Noronha#,
				'standard' => q#normaltid for Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Nord-Marianene-tid#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#sommertid for Novosibirsk#,
				'generic' => q#tidssone for Novosibirsk#,
				'standard' => q#normaltid for Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#sommertid for Omsk#,
				'generic' => q#tidssone for Omsk#,
				'standard' => q#normaltid for Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Påskeøya#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagosøyene#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kantonøya#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norfolkøya#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistansk sommertid#,
				'generic' => q#pakistansk tid#,
				'standard' => q#pakistansk normaltid#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palauisk tid#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#papuansk tid#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguayansk sommertid#,
				'generic' => q#paraguayansk tid#,
				'standard' => q#paraguayansk normaltid#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruansk sommertid#,
				'generic' => q#peruansk tid#,
				'standard' => q#peruansk normaltid#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filippinsk sommertid#,
				'generic' => q#filippinsk tid#,
				'standard' => q#filippinsk normaltid#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#tidssone for Phoenixøyene#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#sommertid for Saint-Pierre-et-Miquelon#,
				'generic' => q#tidssone for Saint-Pierre-et-Miquelon#,
				'standard' => q#normaltid for Saint-Pierre-et-Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#tidssone for Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#tidssone for Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#tidssone for Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Qyzylorda, sommertid#,
				'generic' => q#Qyzylorda-tid#,
				'standard' => q#Qyzylorda, standardtid#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#tidssone for Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#tidssone for Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sommertid for Sakhalin#,
				'generic' => q#tidssone for Sakhalin#,
				'standard' => q#normaltid for Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Russisk (Samara) sommertid#,
				'generic' => q#Russisk (Samara) tid#,
				'standard' => q#Russisk (Samara) normaltid#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samoansk sommertid#,
				'generic' => q#samoansk tid#,
				'standard' => q#samoansk normaltid#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychellisk tid#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singaporsk tid#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#salomonsk tid#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#tidssone for Sør-Georgia#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamsk tid#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#tidssone for Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitisk tid#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#sommertid for Taipei#,
				'generic' => q#tidssone for Taipei#,
				'standard' => q#normaltid for Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tadsjikisk tid#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tidssone for Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tongansk sommertid#,
				'generic' => q#tongansk tid#,
				'standard' => q#tongansk normaltid#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#tidssone for Chuukøyene#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkmensk sommertid#,
				'generic' => q#turkmensk tid#,
				'standard' => q#turkmensk normaltid#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvalsk tid#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguayansk sommertid#,
				'generic' => q#uruguayansk tid#,
				'standard' => q#uruguayansk normaltid#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#usbekisk sommertid#,
				'generic' => q#usbekisk tid#,
				'standard' => q#usbekisk normaltid#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatisk sommertid#,
				'generic' => q#vanuatisk tid#,
				'standard' => q#vanuatisk normaltid#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelansk tid#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#sommertid for Vladivostok#,
				'generic' => q#tidssone for Vladivostok#,
				'standard' => q#normaltid for Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#sommertid for Volgograd#,
				'generic' => q#tidssone for Volgograd#,
				'standard' => q#normaltid for Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#tidssone for Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#tidssone for Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#tidssone for Wallis- og Futunaøyene#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#sommertid for Jakutsk#,
				'generic' => q#tidssone for Jakutsk#,
				'standard' => q#normaltid for Jakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#sommertid for Jekaterinburg#,
				'generic' => q#tidssone for Jekaterinburg#,
				'standard' => q#normaltid for Jekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#tidssone for Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
