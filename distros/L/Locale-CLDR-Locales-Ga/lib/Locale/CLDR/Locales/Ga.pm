=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ga - Package for language Irish

=cut

package Locale::CLDR::Locales::Ga;
# This file auto generated from Data\common\main\ga.xml
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
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'2d-year' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(agus =%spellout-numbering=),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%%spellout-numbering-no-a=),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(=%%spellout-numbering-no-a=),
				},
			},
		},
		'billions' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(billiún),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart= billiún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart= billiún déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart= billiún),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-billions→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-billions→),
				},
			},
		},
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ú),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0=ú),
				},
			},
		},
		'hundreds' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(céad),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dhá chéad),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trí chéad),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ceithre chéad),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cúig chéad),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sé chéad),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seacht gcéad),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ocht gcéad),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naoi gcéad),
				},
				'max' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naoi gcéad),
				},
			},
		},
		'is' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' is),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(→→),
				},
				'max' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(→→),
				},
			},
		},
		'is-billions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' billiún),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' is =%%spellout-cardinal-prefixpart= billiún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(' is =%%billions=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%billions=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%billions=),
				},
			},
		},
		'is-millions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' =%%million=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' is =%%spellout-cardinal-prefixpart= =%%million=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(' is =%%millions=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%millions=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%millions=),
				},
			},
		},
		'is-number' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' is =%spellout-numbering=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-numbering=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-numbering=),
				},
			},
		},
		'is-numberp' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' is =%%numberp=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%%numberp=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%%numberp=),
				},
			},
		},
		'is-quadrillions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' quadrilliún),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' is =%%spellout-cardinal-prefixpart= quadrilliún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(' is =%%quadrillions=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%quadrillions=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%quadrillions=),
				},
			},
		},
		'is-thousands' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' =%%thousand=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' is =%%spellout-cardinal-prefixpart= =%%thousand=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(' is =%%thousands=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%thousands=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%thousands=),
				},
			},
		},
		'is-trillions' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(' =%%trillion=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' is =%%spellout-cardinal-prefixpart= =%%trillion=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(' is =%%trillions=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%trillions=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%is= =%%trillions=),
				},
			},
		},
		'lenient-parse' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(& ' ' , ',' ),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(& ' ' , ',' ),
				},
			},
		},
		'million' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(milliún),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(mhilliún),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(milliún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
				'max' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
			},
		},
		'millions' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(milliún),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart= =%%millionsp=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-millions→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-millions→),
				},
			},
		},
		'millionsp' => {
			'private' => {
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%million=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%%million= déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%million=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%million=),
				},
			},
		},
		'numberp' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart=),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dó dhéag),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart= déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart=),
				},
			},
		},
		'quadrillions' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(quadrilliún),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart= quadrilliún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart= quadrilliún déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%spellout-cardinal-prefixpart= quadrilliún),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-quadrillions→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-quadrillions→),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'spellout-cardinal-prefixpart' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(náid),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(aon),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dhá),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trí),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ceithre),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cúig),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sé),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seacht),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ocht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naoi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deich),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(fiche[ is →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tríocha[ is →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(daichead[ is →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(caoga[ is →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seasca[ is →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(seachtó[ is →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ochtó[ is →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nócha[ is →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←[→%%is-numberp→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%thousands←[, →%%numberp→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%millions←[, →%%numberp→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%billions←[, →%%numberp→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%trillions←[, →%%numberp→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%quadrillions←[, →%%numberp→]),
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
					rule => q(míneas →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(a náid),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← pointe →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(a haon),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(a dó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(a trí),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(a ceathair),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(a cúig),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(a sé),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(a seacht),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(a hocht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(a naoi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(a deich),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→ déag),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ dhéag),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→ déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(fiche[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tríocha[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(daichead[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(caoga[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(seasca[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(seachtó[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ochtó[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(nócha[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←[→%%is-number→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%%thousands←[, →%spellout-numbering→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%%millions←[, →%spellout-numbering→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%%billions←[, →%spellout-numbering→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%%trillions←[, →%spellout-numbering→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%%quadrillions←[, →%spellout-numbering→]),
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
		'spellout-numbering-no-a' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(náid),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(aon),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dó),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(trí),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ceathair),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(cúig),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sé),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(seacht),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ocht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(naoi),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(deich),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→ déag),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(→→ dhéag),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(→→ déag),
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
		'spellout-numbering-year' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(míneas →→),
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
				'1000' => {
					base_value => q(1000),
					divisor => q(100),
					rule => q(←%%spellout-numbering-no-a← →%%2d-year→),
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
		'thousand' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(míle),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(mhíle),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(míle),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
				'max' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
			},
		},
		'thousandp' => {
			'private' => {
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%thousand=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%%thousand= dhéag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%thousand=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%thousand=),
				},
			},
		},
		'thousands' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(míle),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart= =%%thousandp=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-thousands→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-thousands→),
				},
			},
		},
		'trillion' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(dtrilliún),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(thrilliún),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(dtrilliún),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
				'max' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(→→),
				},
			},
		},
		'trillions' => {
			'private' => {
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(thrilliún),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%spellout-cardinal-prefixpart= =%%trillionsp=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-trillions→),
				},
				'max' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%%hundreds←→%%is-trillions→),
				},
			},
		},
		'trillionsp' => {
			'private' => {
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%%trillion=),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(=%%trillion= déag),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%trillion=),
				},
				'max' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%%trillion=),
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
				'aa' => 'Afáiris',
 				'ab' => 'Abcáisis',
 				'ace' => 'Aicinéis',
 				'ada' => 'Daingmis',
 				'ady' => 'Adaigéis',
 				'ae' => 'Aivéistis',
 				'af' => 'Afracáinis',
 				'agq' => 'Aigeimis',
 				'ain' => 'Aidhniúis',
 				'ak' => 'Acáinis',
 				'akk' => 'Acáidis',
 				'ale' => 'Ailiúitis',
 				'alt' => 'Altaeis an Deiscirt',
 				'am' => 'Amáiris',
 				'an' => 'Aragóinis',
 				'ang' => 'Sean-Bhéarla',
 				'ann' => 'Obolo',
 				'anp' => 'Aingícis',
 				'ar' => 'Araibis',
 				'ar_001' => 'Araibis Chaighdeánach',
 				'arc' => 'Aramais',
 				'arn' => 'Mapúitsis',
 				'arp' => 'Arapachóis',
 				'ars' => 'Araibis Najdi',
 				'as' => 'Asaimis',
 				'asa' => 'Asúis',
 				'ast' => 'Astúiris',
 				'atj' => 'Atikamekw',
 				'av' => 'Aváiris',
 				'awa' => 'Avaidis',
 				'ay' => 'Aidhmiris',
 				'az' => 'Asarbaiseáinis',
 				'az@alt=short' => 'Asairis',
 				'ba' => 'Baiscíris',
 				'ban' => 'Bailís',
 				'bar' => 'Baváiris',
 				'bas' => 'Basáis',
 				'be' => 'Bealarúisis',
 				'bem' => 'Beimbis',
 				'bez' => 'Beinis',
 				'bg' => 'Bulgáiris',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Vóispiris',
 				'bi' => 'Bioslaimis',
 				'bin' => 'Binis',
 				'bla' => 'Sicsicis',
 				'blo' => 'Anii',
 				'bm' => 'Bambairis',
 				'bn' => 'Beangáilis',
 				'bo' => 'Tibéidis',
 				'br' => 'Briotáinis',
 				'brx' => 'Bódóis',
 				'bs' => 'Boisnis',
 				'bua' => 'Buiriáitis',
 				'bug' => 'Buiginis',
 				'byn' => 'Blinis',
 				'ca' => 'Catalóinis',
 				'cay' => 'teanga Cayuga',
 				'ccp' => 'Seácmais',
 				'ce' => 'Seisnis',
 				'ceb' => 'Seabúáinis',
 				'cgg' => 'Cígis',
 				'ch' => 'Seamóiris',
 				'chk' => 'Siúicísis',
 				'chm' => 'Mairis',
 				'cho' => 'Seactáis',
 				'chp' => 'Siopúáinis',
 				'chr' => 'Seiricis',
 				'chy' => 'Siáinis',
 				'ckb' => 'Coirdis Lárnach',
 				'ckb@alt=variant' => 'Coirdis, Sóráinis',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsaicis',
 				'cop' => 'Coptais',
 				'cr' => 'Craís',
 				'crg' => 'Michif',
 				'crj' => 'Craís an Deiscirt Thoir',
 				'crk' => 'Plains Cree',
 				'crl' => 'Craís Thoir Thuaidh',
 				'crm' => 'Moose Cree',
 				'crr' => 'teanga Algancach Carolina',
 				'crs' => 'Criól Fraincise Seselwa',
 				'cs' => 'Seicis',
 				'csb' => 'Caisiúibis',
 				'csw' => 'Swampy Cree',
 				'cu' => 'Slavais na hEaglaise',
 				'cv' => 'Suvaisis',
 				'cy' => 'Breatnais',
 				'da' => 'Danmhairgis',
 				'dak' => 'Dacótais',
 				'dar' => 'Dargais',
 				'dav' => 'Taita',
 				'de' => 'Gearmáinis',
 				'de_AT' => 'Gearmáinis na hOstaire',
 				'de_CH' => 'Ard-Ghearmáinis Eilvéiseach',
 				'dgr' => 'Dograibis',
 				'dje' => 'Zarmais',
 				'doi' => 'Dóigris',
 				'dsb' => 'Sorbais Íochtarach',
 				'dua' => 'Duailis',
 				'dum' => 'Meán-Ollainnis',
 				'dv' => 'Divéihis',
 				'dyo' => 'Jóla-Fainis',
 				'dz' => 'Seoinicis',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Ciambúis',
 				'ee' => 'Éabhais',
 				'efi' => 'Eificis',
 				'egy' => 'Sean-Éigiptis',
 				'eka' => 'Acaidiúcais',
 				'el' => 'Gréigis',
 				'en' => 'Béarla',
 				'en_AU' => 'Béarla na hAstráile',
 				'en_CA' => 'Béarla Cheanada',
 				'en_GB' => 'Béarla na Breataine',
 				'en_GB@alt=short' => 'Béarla na R.A.',
 				'en_US' => 'Béarla Mheiriceá',
 				'en_US@alt=short' => 'Béarla S.A.M.',
 				'enm' => 'Meán-Bhéarla',
 				'eo' => 'Esperanto',
 				'es' => 'Spáinnis',
 				'es_419' => 'Spáinnis Mheiriceá Laidinigh',
 				'es_ES' => 'Spáinnis Eorpach',
 				'es_MX' => 'Spáinnis Mheicsiceach',
 				'et' => 'Eastóinis',
 				'eu' => 'Bascais',
 				'ewo' => 'Éabhandóis',
 				'fa' => 'Peirsis',
 				'fa_AF' => 'Dairis',
 				'ff' => 'Fuláinis',
 				'fi' => 'Fionlainnis',
 				'fil' => 'Filipínis',
 				'fj' => 'Fidsis',
 				'fo' => 'Faróis',
 				'fon' => 'Fonais',
 				'fr' => 'Fraincis',
 				'fr_CA' => 'Fraincis Cheanada',
 				'fr_CH' => 'Fraincis na hEilvéise',
 				'frc' => 'Fraincis Cajun',
 				'frm' => 'Meán-Fhraincis',
 				'fro' => 'Sean-Fhraincis',
 				'frr' => 'Freaslainnis an Tuaiscirt',
 				'fur' => 'Friúilis',
 				'fy' => 'Freaslainnis Iartharach',
 				'ga' => 'Gaeilge',
 				'gaa' => 'Geáis',
 				'gan' => 'Sínis Gan',
 				'gd' => 'Gaeilge na hAlban',
 				'gez' => 'Aetóipis',
 				'gil' => 'Gilbeartais',
 				'gl' => 'Gailísis',
 				'gmh' => 'Meán-Ard-Ghearmáinis',
 				'gn' => 'Guaráinis',
 				'goh' => 'Sean-Ard-Ghearmáinis',
 				'gor' => 'Gorantalais',
 				'grc' => 'Sean-Ghréigis',
 				'gsw' => 'Gearmáinis Eilvéiseach',
 				'gu' => 'Gúisearáitis',
 				'guc' => 'Uaúis',
 				'guz' => 'Gúsaís',
 				'gv' => 'Manainnis',
 				'gwi' => 'Goitsinis',
 				'ha' => 'Hásais',
 				'hai' => 'Haídis',
 				'hak' => 'Haicéis',
 				'haw' => 'Haváis',
 				'hax' => 'Haídis an Deiscirt',
 				'he' => 'Eabhrais',
 				'hi' => 'Hiondúis',
 				'hif' => 'Hiondúis Fhidsí',
 				'hil' => 'Hilgeanóinis',
 				'hit' => 'Hitis',
 				'hmn' => 'Hmongais',
 				'ho' => 'Motúis Hírí',
 				'hr' => 'Cróitis',
 				'hsb' => 'Sorbais Uachtarach',
 				'hsn' => 'Sínis Xiang',
 				'ht' => 'Críol Háítí',
 				'hu' => 'Ungáiris',
 				'hup' => 'Húipis',
 				'hur' => 'Halkomelem',
 				'hy' => 'Airméinis',
 				'hz' => 'Heiréiris',
 				'ia' => 'Interlingua',
 				'iba' => 'Ibeainis',
 				'ibb' => 'Ibibis',
 				'id' => 'Indinéisis',
 				'ie' => 'Interlingue',
 				'ig' => 'Íogbóis',
 				'ii' => 'Ís Shichuan',
 				'ik' => 'Iniúipiaicis',
 				'ikt' => 'Ionúitis Iarthar Cheanada',
 				'ilo' => 'Ileacáinis',
 				'inh' => 'Iongúis',
 				'io' => 'Ídis',
 				'is' => 'Íoslainnis',
 				'it' => 'Iodáilis',
 				'iu' => 'Ionúitis',
 				'ja' => 'Seapáinis',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jut' => 'Iútlainnis',
 				'jv' => 'Iáivis',
 				'ka' => 'Seoirsis',
 				'kaa' => 'Cara-Chalpáis',
 				'kab' => 'Caibílis',
 				'kac' => 'Caitsinis',
 				'kaj' => 'Jju',
 				'kam' => 'Cambais',
 				'kbd' => 'Cabairdis',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Criól Cabo Verde',
 				'kfo' => 'Koro',
 				'kg' => 'Congóis',
 				'kgp' => 'Kaingang',
 				'kha' => 'Caisis',
 				'khq' => 'Songais Iartharach',
 				'ki' => 'Ciocúis',
 				'kj' => 'Cuainiáimis',
 				'kk' => 'Casaicis',
 				'kkj' => 'Cacóis',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Ciméiris',
 				'kmb' => 'Ciombundais',
 				'kn' => 'Cannadais',
 				'ko' => 'Cóiréis',
 				'kok' => 'Concáinis',
 				'kpe' => 'Caipeilis',
 				'kr' => 'Canúiris',
 				'krc' => 'Caraicí-Balcáiris',
 				'krl' => 'Cairéilis',
 				'kru' => 'Curúicis',
 				'ks' => 'Caismíris',
 				'ksb' => 'Shambala',
 				'ksf' => 'Baifiais',
 				'ksh' => 'Coilsis',
 				'ku' => 'Coirdis',
 				'kum' => 'Cúimicis',
 				'kv' => 'Coimis',
 				'kw' => 'Coirnis',
 				'kwk' => 'Kwakʼwala',
 				'kxv' => 'Kuvi',
 				'ky' => 'Cirgisis',
 				'la' => 'Laidin',
 				'lad' => 'Laidínis',
 				'lag' => 'Ciolaingis',
 				'lah' => 'Puinseáibis Iartharach',
 				'lb' => 'Lucsambuirgis',
 				'lez' => 'Leisgis',
 				'lg' => 'Lugandais',
 				'li' => 'Liombuirgis',
 				'lij' => 'Liogúiris',
 				'lil' => 'Lillooet',
 				'liv' => 'Liovóinis',
 				'lkt' => 'Lacótais',
 				'lmo' => 'Lombairdis',
 				'ln' => 'Liongáilis',
 				'lo' => 'Laoisis',
 				'lou' => 'Criól Louisiana',
 				'loz' => 'Lóisis',
 				'lrc' => 'Lúiris an Tuaiscirt',
 				'lsm' => 'Saamia',
 				'lt' => 'Liotuáinis',
 				'lu' => 'Lúba-Cataingis',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lundais',
 				'luo' => 'Lúóis',
 				'lus' => 'Míosóis',
 				'luy' => 'Luyia',
 				'lv' => 'Laitvis',
 				'mad' => 'Maidiúiris',
 				'mag' => 'Magaidis',
 				'mai' => 'Maitilis',
 				'mak' => 'Macasairis',
 				'mas' => 'Másais',
 				'mdf' => 'Mocsais',
 				'men' => 'Meindis',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagáisis',
 				'mga' => 'Meán-Ghaeilge',
 				'mgh' => 'Meiteo-Macuais',
 				'mgo' => 'Metaʼ',
 				'mh' => 'Mairsillis',
 				'mi' => 'Maorais',
 				'mic' => 'Micmeaicis',
 				'min' => 'Míneangcababhais',
 				'mk' => 'Macadóinis',
 				'ml' => 'Mailéalaimis',
 				'mn' => 'Mongóilis',
 				'mni' => 'Manapúiris',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Móháicis',
 				'mos' => 'Mosais',
 				'mr' => 'Maraitis',
 				'mrj' => 'Mairis Iartharach',
 				'ms' => 'Malaeis',
 				'mt' => 'Máltais',
 				'mua' => 'Mundang',
 				'mul' => 'Ilteangacha',
 				'mus' => 'Muscogee',
 				'mwl' => 'Mioraindéis',
 				'mwr' => 'Marmhairis',
 				'my' => 'Burmais',
 				'myv' => 'Éirsis',
 				'mzn' => 'Mázandaráinis',
 				'na' => 'Nárúis',
 				'nan' => 'Sínis Min Nan',
 				'nap' => 'Napóilis',
 				'naq' => 'Nama',
 				'nb' => 'Bocmál',
 				'nd' => 'N-deibéilis an Tuaiscirt',
 				'nds' => 'Gearmáinis Íochtarach',
 				'nds_NL' => 'Sacsainis Íochtarach',
 				'ne' => 'Neipeailis',
 				'new' => 'Néamharais',
 				'ng' => 'Ndongais',
 				'nia' => 'Niaisis',
 				'niu' => 'Níobhais',
 				'nl' => 'Ollainnis',
 				'nl_BE' => 'Pléimeannais',
 				'nmg' => 'Cuaiseois',
 				'nn' => 'Nua-Ioruais',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Ioruais',
 				'nog' => 'Nógaeis',
 				'non' => 'Sean-Lochlainnis',
 				'nqo' => 'N-cóis',
 				'nr' => 'Ndeibéilis an Deiscirt',
 				'nso' => 'Sútúis an Tuaiscirt',
 				'nus' => 'Nuairis',
 				'nv' => 'Navachóis',
 				'ny' => 'Siséivis',
 				'nyn' => 'Niancóilis',
 				'oc' => 'Ocsatáinis',
 				'oj' => 'Óisibis',
 				'ojb' => 'Óisibis Iarthuiscirt',
 				'ojc' => 'Óisibis Lárnach',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Óisibis an Iarthar',
 				'oka' => 'Okanagan',
 				'om' => 'Oraimis',
 				'or' => 'Odia',
 				'os' => 'Oiséitis',
 				'pa' => 'Puinseáibis',
 				'pag' => 'Pangasaíneánais',
 				'pam' => 'Pampaingis',
 				'pap' => 'Paipeamaintis',
 				'pau' => 'Palabhais',
 				'pcm' => 'pidsean na Nigéire',
 				'peo' => 'Sean-Pheirsis',
 				'pi' => 'Páilis',
 				'pis' => 'Pijin',
 				'pl' => 'Polainnis',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Prúisis',
 				'ps' => 'Paistis',
 				'pt' => 'Portaingéilis',
 				'pt_BR' => 'Portaingéilis Bhrasaíleach',
 				'pt_PT' => 'Portaingéilis Ibéarach',
 				'qu' => 'Ceatsuais',
 				'quc' => 'Cuitséis',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanúis',
 				'rar' => 'Raratongais',
 				'rhg' => 'Róihinis',
 				'rm' => 'Rómainis',
 				'rn' => 'Rúindis',
 				'ro' => 'Rómáinis',
 				'ro_MD' => 'Moldáivis',
 				'rof' => 'Rombo',
 				'rom' => 'Romainis',
 				'ru' => 'Rúisis',
 				'rup' => 'Arómáinis',
 				'rw' => 'Ciniaruaindis',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanscrait',
 				'sad' => 'Sandabhais',
 				'sah' => 'Sachais',
 				'sam' => 'Aramais Shamárach',
 				'saq' => 'Samburu',
 				'sat' => 'Santáilis',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sairdínis',
 				'scn' => 'Sicilis',
 				'sco' => 'Albainis',
 				'sd' => 'Sindis',
 				'se' => 'Sáimis an Tuaiscirt',
 				'seh' => 'Sena',
 				'ses' => 'Songais Oirthearach',
 				'sg' => 'Sangóis',
 				'sga' => 'Sean-Ghaeilge',
 				'sh' => 'Seirbea-Chróitis',
 				'shi' => 'Tachelhit',
 				'shn' => 'Seánais',
 				'si' => 'Siolóinis',
 				'sk' => 'Slóvaicis',
 				'sl' => 'Slóivéinis',
 				'slh' => 'Lushootseed an Deiscirt',
 				'sm' => 'Samóis',
 				'sma' => 'Sáimis Theas',
 				'smj' => 'Sáimis Lule',
 				'smn' => 'Sáimis Inari',
 				'sms' => 'Sáimis Skolt',
 				'sn' => 'Seoinis',
 				'snk' => 'Soinincéis',
 				'so' => 'Somáilis',
 				'sog' => 'Sogdánais',
 				'sq' => 'Albáinis',
 				'sr' => 'Seirbis',
 				'srn' => 'Suranaimis',
 				'ss' => 'Suaisis',
 				'st' => 'Sútúis an Deiscirt',
 				'str' => 'Straits Salish',
 				'su' => 'Sundais',
 				'suk' => 'Sucúimis',
 				'sux' => 'Suiméiris',
 				'sv' => 'Sualainnis',
 				'sw' => 'Svahaílis',
 				'sw_CD' => 'Svahaílis an Chongó',
 				'swb' => 'teanga na gComórach',
 				'syr' => 'Siricis',
 				'szl' => 'Siléisis',
 				'ta' => 'Tamailis',
 				'tce' => 'Tutchone an Deiscirt',
 				'te' => 'Teileagúis',
 				'tem' => 'Teimnis',
 				'teo' => 'Teso',
 				'tet' => 'Teitimis',
 				'tg' => 'Taidsícis',
 				'tgx' => 'Tagish',
 				'th' => 'Téalainnis',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinis',
 				'tig' => 'Tigréis',
 				'tk' => 'Tuircméinis',
 				'tl' => 'Tagálaigis',
 				'tlh' => 'Klingon',
 				'tli' => 'Clincitis',
 				'tn' => 'Suáinis',
 				'to' => 'Tongais',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Tuircis',
 				'trv' => 'Taroko',
 				'ts' => 'Songais',
 				'tt' => 'Tatairis',
 				'ttm' => 'Northern Tutchone',
 				'tum' => 'Tumbúicis',
 				'tvl' => 'Tuvalu',
 				'tw' => 'Tíbhis',
 				'twq' => 'Tasawaq',
 				'ty' => 'Taihítis',
 				'tyv' => 'Túvainis',
 				'tzm' => 'Tamaisis Atlais Láir',
 				'udm' => 'Udmairtis',
 				'ug' => 'Uigiúiris',
 				'uk' => 'Úcráinis',
 				'umb' => 'Umbundais',
 				'und' => 'Teanga anaithnid',
 				'ur' => 'Urdúis',
 				'uz' => 'Úisbéiceastáinis',
 				'vai' => 'Vadhais',
 				've' => 'Veindis',
 				'vec' => 'Veinéisis',
 				'vi' => 'Vítneaimis',
 				'vls' => 'Pléimeannais Iartharach',
 				'vmw' => 'Macuais',
 				'vo' => 'Volapük',
 				'vun' => 'Vunjo',
 				'wa' => 'Vallúnais',
 				'wae' => 'Walser',
 				'wal' => 'Uailéitis',
 				'war' => 'Uairéis',
 				'wo' => 'Volaifis',
 				'wuu' => 'Sínis Wu',
 				'xal' => 'Cailmícis',
 				'xh' => 'Cóisis',
 				'xnr' => 'Kangri',
 				'xog' => 'Soga',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Giúdais',
 				'yo' => 'Iarúibis',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Cantainis',
 				'yue@alt=menu' => 'Sínis, Cantainis',
 				'za' => 'Siuáingis',
 				'zea' => 'Séalainnis',
 				'zgh' => 'Tamaisis Chaighdeánach Mharacó',
 				'zh' => 'Sínis',
 				'zh@alt=menu' => 'Sínis, Mandairínis',
 				'zh_Hans' => 'Sínis Shimplithe',
 				'zh_Hans@alt=long' => 'Mandairínis Shimplithe',
 				'zh_Hant' => 'Sínis Thraidisiúnta',
 				'zh_Hant@alt=long' => 'Mandairínis Thraidisiúnta',
 				'zu' => 'Súlúis',
 				'zun' => 'Zúinis',
 				'zxx' => 'Gan ábhar teangeolaíoch',
 				'zza' => 'Zázá',

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
			'Adlm' => 'Adlam',
 			'Aghb' => 'Albánach Cugasach',
 			'Arab' => 'Arabach',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Aramach Impiriúil',
 			'Armn' => 'Airméanach',
 			'Avst' => 'Aivéisteach',
 			'Bali' => 'Bailíoch',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batacach',
 			'Beng' => 'Beangálach',
 			'Bhks' => 'Bhaiksuki',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brámais',
 			'Brai' => 'Braille',
 			'Bugi' => 'Buigineach',
 			'Buhd' => 'Buthaideach',
 			'Cakm' => 'Seácmais',
 			'Cans' => 'Siollach Bundúchasach Ceanadach Aontaithe',
 			'Cari' => 'Cló Cairiach',
 			'Cher' => 'Seiricíoch',
 			'Copt' => 'Coptach',
 			'Cprt' => 'Cipireach',
 			'Cyrl' => 'Coireallach',
 			'Deva' => 'Déiveanágrach',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Gearrscríobh Duployan',
 			'Egyd' => 'Éigipteach coiteann',
 			'Egyh' => 'Éigipteach cliarúil',
 			'Egyp' => 'Iairiglifí Éigipteacha',
 			'Elba' => 'Elbasan',
 			'Ethi' => 'Aetóipic',
 			'Geor' => 'Seoirseach',
 			'Glag' => 'Glagalach',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gotach',
 			'Gran' => 'Grantha',
 			'Grek' => 'Gréagach',
 			'Gujr' => 'Gúisearátach',
 			'Guru' => 'Gurmúcach',
 			'Hanb' => 'Han agus Bopomofo',
 			'Hang' => 'Hangalach',
 			'Hani' => 'Han',
 			'Hano' => 'Hananúis',
 			'Hans' => 'Simplithe',
 			'Hans@alt=stand-alone' => 'Han Simplithe',
 			'Hant' => 'Traidisiúnta',
 			'Hant@alt=stand-alone' => 'Han Traidisiúnta',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Eabhrach',
 			'Hira' => 'Hireagánach',
 			'Hluw' => 'Iairiglifí Anatólacha',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Siollabraí Seapánacha',
 			'Hung' => 'Sean-Ungárach',
 			'Ital' => 'Sean-Iodáilic',
 			'Jamo' => 'Seamó',
 			'Java' => 'Iávach',
 			'Jpan' => 'Seapánach',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Catacánach',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Ciméarach',
 			'Khoj' => 'Khojki',
 			'Knda' => 'Cannadach',
 			'Kore' => 'Cóiréach',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laosach',
 			'Latg' => 'Cló Gaelach',
 			'Latn' => 'Laidineach',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Liombúch',
 			'Lina' => 'Líneach A',
 			'Linb' => 'Líneach B',
 			'Lisu' => 'Fraser',
 			'Lyci' => 'Liciach',
 			'Lydi' => 'Lidiach',
 			'Mahj' => 'Mahasánach',
 			'Mand' => 'Mandaean',
 			'Mani' => 'Mainicéasach',
 			'Marc' => 'Marchen',
 			'Maya' => 'Iairiglifí Máigheacha',
 			'Mend' => 'Meindeach',
 			'Merc' => 'Meroitic Cursive',
 			'Mero' => 'Meroitic',
 			'Mlym' => 'Mailéalamach',
 			'Mong' => 'Mongólach',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Maenmarach',
 			'Narb' => 'Sean-Arabach Thuaidh',
 			'Nbat' => 'Nabataean',
 			'Nkoo' => 'N-cóis',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oiríseach',
 			'Osge' => 'Ósáis',
 			'Osma' => 'Osmanya',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Sean-Pheirmeach',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Pachlavais Inscríbhinne',
 			'Phlp' => 'Pachlavais Saltrach',
 			'Phnx' => 'Féiníceach',
 			'Plrd' => 'Pollard Foghrach',
 			'Prti' => 'Pairtiach Inscríbhinniúil',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi',
 			'Runr' => 'Rúnach',
 			'Samr' => 'Samárach',
 			'Sarb' => 'Sean-Arabach Theas',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Litritheoireacht Comharthaí',
 			'Shaw' => 'Shawach',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Siolónach',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sundainéis',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Siriceach',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Deiheoingis',
 			'Talu' => 'Tai Lue Nua',
 			'Taml' => 'Tamalach',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Teileagúch',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagálagach',
 			'Thaa' => 'Tánach',
 			'Thai' => 'Téalannach',
 			'Tibt' => 'Tibéadach',
 			'Tirh' => 'Tirhuta',
 			'Ugar' => 'Úgairíteach',
 			'Vaii' => 'Vadhais',
 			'Wara' => 'Varang Kshiti',
 			'Xpeo' => 'Sean-Pheirseach',
 			'Xsux' => 'Dingchruthach Suiméar-Acádach',
 			'Yiii' => 'Ís',
 			'Zanb' => 'Zanabazar Square',
 			'Zinh' => 'Oidhreacht',
 			'Zmth' => 'Nodaireacht Mhatamaiticiúil',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Siombailí',
 			'Zxxx' => 'Neamhscríofa',
 			'Zyyy' => 'Coitianta',
 			'Zzzz' => 'Script Anaithnid',

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
			'001' => 'an Domhan',
 			'002' => 'an Afraic',
 			'003' => 'Meiriceá Thuaidh',
 			'005' => 'Meiriceá Theas',
 			'009' => 'an Aigéine',
 			'011' => 'Iarthar na hAfraice',
 			'013' => 'Meiriceá Láir',
 			'014' => 'Oirthear na hAfraice',
 			'015' => 'Tuaisceart na hAfraice',
 			'017' => 'an Afraic Láir',
 			'018' => 'Deisceart na hAfraice',
 			'019' => 'Críocha Mheiriceá',
 			'021' => 'Tuaisceart Mheiriceá',
 			'029' => 'an Mhuir Chairib',
 			'030' => 'Oirthear na hÁise',
 			'034' => 'Deisceart na hÁise',
 			'035' => 'an Áise Thoir Theas',
 			'039' => 'Deisceart na hEorpa',
 			'053' => 'an Astraláise',
 			'054' => 'an Mheilinéis',
 			'057' => 'an Réigiún Micrinéiseach',
 			'061' => 'an Pholainéis',
 			'142' => 'an Áise',
 			'143' => 'an Áise Láir',
 			'145' => 'Iarthar na hÁise',
 			'150' => 'an Eoraip',
 			'151' => 'Oirthear na hEorpa',
 			'154' => 'Tuaisceart na hEorpa',
 			'155' => 'Iarthar na hEorpa',
 			'202' => 'an Afraic fho-Shahárach',
 			'419' => 'Meiriceá Laidineach',
 			'AC' => 'Oileán na Deascabhála',
 			'AD' => 'Andóra',
 			'AE' => 'Aontas na nÉimíríochtaí Arabacha',
 			'AF' => 'an Afganastáin',
 			'AG' => 'Antigua agus Barbúda',
 			'AI' => 'Angaíle',
 			'AL' => 'an Albáin',
 			'AM' => 'an Airméin',
 			'AO' => 'Angóla',
 			'AQ' => 'Antartaice',
 			'AR' => 'an Airgintín',
 			'AS' => 'Samó Mheiriceá',
 			'AT' => 'an Ostair',
 			'AU' => 'an Astráil',
 			'AW' => 'Arúba',
 			'AX' => 'Oileáin Åland',
 			'AZ' => 'an Asarbaiseáin',
 			'BA' => 'an Bhoisnia agus an Heirseagaivéin',
 			'BB' => 'Barbadós',
 			'BD' => 'an Bhanglaidéis',
 			'BE' => 'an Bheilg',
 			'BF' => 'Buircíne Fasó',
 			'BG' => 'an Bhulgáir',
 			'BH' => 'Bairéin',
 			'BI' => 'an Bhurúin',
 			'BJ' => 'Beinin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Beirmiúda',
 			'BN' => 'Brúiné',
 			'BO' => 'an Bholaiv',
 			'BQ' => 'an Ísiltír Chairibeach',
 			'BR' => 'an Bhrasaíl',
 			'BS' => 'na Bahámaí',
 			'BT' => 'an Bhútáin',
 			'BV' => 'Oileán Bouvet',
 			'BW' => 'an Bhotsuáin',
 			'BY' => 'an Bhealarúis',
 			'BZ' => 'an Bheilís',
 			'CA' => 'Ceanada',
 			'CC' => 'Oileáin Cocos (Keeling)',
 			'CD' => 'Poblacht Dhaonlathach an Chongó',
 			'CD@alt=variant' => 'an Congó (PDC)',
 			'CF' => 'Poblacht na hAfraice Láir',
 			'CG' => 'Congó-Brazzaville',
 			'CG@alt=variant' => 'Poblacht an Chongó',
 			'CH' => 'an Eilvéis',
 			'CI' => 'An Cósta Eabhair',
 			'CI@alt=variant' => 'an Cósta Eabhair',
 			'CK' => 'Oileáin Cook',
 			'CL' => 'an tSile',
 			'CM' => 'Camarún',
 			'CN' => 'an tSín',
 			'CO' => 'an Cholóim',
 			'CP' => 'Oileán Clipperton',
 			'CR' => 'Cósta Ríce',
 			'CU' => 'Cúba',
 			'CV' => 'Rinn Verde',
 			'CW' => 'Cúrasó',
 			'CX' => 'Oileán na Nollag',
 			'CY' => 'an Chipir',
 			'CZ' => 'an tSeicia',
 			'CZ@alt=variant' => 'Poblacht na Seice',
 			'DE' => 'an Ghearmáin',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'an Danmhairg',
 			'DM' => 'Doiminice',
 			'DO' => 'an Phoblacht Dhoiminiceach',
 			'DZ' => 'An Ailgéir',
 			'EA' => 'Ceuta agus Melilla',
 			'EC' => 'Eacuadór',
 			'EE' => 'an Eastóin',
 			'EG' => 'An Éigipt',
 			'EH' => 'An Sahára Thiar',
 			'ER' => 'an Eiritré',
 			'ES' => 'an Spáinn',
 			'ET' => 'an Aetóip',
 			'EU' => 'an tAontas Eorpach',
 			'EZ' => 'Limistéar an euro',
 			'FI' => 'an Fhionlainn',
 			'FJ' => 'Fidsí',
 			'FK' => 'Oileáin Fháclainne',
 			'FK@alt=variant' => 'Oileáin Fháclainne (Islas Malvinas)',
 			'FM' => 'an Mhicrinéis',
 			'FO' => 'Oileáin Fharó',
 			'FR' => 'an Fhrainc',
 			'GA' => 'an Ghabúin',
 			'GB' => 'an Ríocht Aontaithe',
 			'GD' => 'Greanáda',
 			'GE' => 'an tSeoirsia',
 			'GF' => 'Guáin na Fraince',
 			'GG' => 'Geansaí',
 			'GH' => 'Gána',
 			'GI' => 'Giobráltar',
 			'GL' => 'an Ghraonlainn',
 			'GM' => 'An Ghaimbia',
 			'GN' => 'An Ghuine',
 			'GP' => 'Guadalúip',
 			'GQ' => 'an Ghuine Mheánchiorclach',
 			'GR' => 'an Ghréig',
 			'GS' => 'An tSeoirsia Theas agus Oileáin Sandwich Theas',
 			'GT' => 'Guatamala',
 			'GU' => 'Guam',
 			'GW' => 'Guine Bissau',
 			'GY' => 'An Ghuáin',
 			'HK' => 'Sainréigiún Riaracháin Hong Cong, Daonphoblacht na Síne',
 			'HK@alt=short' => 'Hong Cong',
 			'HM' => 'Oileán Heard agus Oileáin McDonald',
 			'HN' => 'Hondúras',
 			'HR' => 'an Chróit',
 			'HT' => 'Háítí',
 			'HU' => 'an Ungáir',
 			'IC' => 'Na hOileáin Chanáracha',
 			'ID' => 'an Indinéis',
 			'IE' => 'Éire',
 			'IL' => 'Iosrael',
 			'IM' => 'Oileán Mhanann',
 			'IN' => 'an India',
 			'IO' => 'Críoch Aigéan Indiach na Breataine',
 			'IQ' => 'an Iaráic',
 			'IR' => 'an Iaráin',
 			'IS' => 'an Íoslainn',
 			'IT' => 'an Iodáil',
 			'JE' => 'Geirsí',
 			'JM' => 'Iamáice',
 			'JO' => 'an Iordáin',
 			'JP' => 'an tSeapáin',
 			'KE' => 'an Chéinia',
 			'KG' => 'an Chirgeastáin',
 			'KH' => 'an Chambóid',
 			'KI' => 'Ciribeas',
 			'KM' => 'Oileáin Chomóra',
 			'KN' => 'San Críostóir-Nimheas',
 			'KP' => 'an Chóiré Thuaidh',
 			'KR' => 'an Chóiré Theas',
 			'KW' => 'Cuáit',
 			'KY' => 'Oileáin Cayman',
 			'KZ' => 'an Chasacstáin',
 			'LA' => 'Laos',
 			'LB' => 'an Liobáin',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Lichtinstéin',
 			'LK' => 'Srí Lanca',
 			'LR' => 'An Libéir',
 			'LS' => 'Leosóta',
 			'LT' => 'an Liotuáin',
 			'LU' => 'Lucsamburg',
 			'LV' => 'an Laitvia',
 			'LY' => 'An Libia',
 			'MA' => 'Maracó',
 			'MC' => 'Monacó',
 			'MD' => 'an Mholdóiv',
 			'ME' => 'Montainéagró',
 			'MF' => 'Saint-Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Oileáin Marshall',
 			'MK' => 'an Mhacadóin Thuaidh',
 			'ML' => 'Mailí',
 			'MM' => 'Maenmar (Burma)',
 			'MN' => 'an Mhongóil',
 			'MO' => 'Sainréigiún Riaracháin Macao, Daonphoblacht na Síne',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Na hOileáin Mháirianacha Thuaidh',
 			'MQ' => 'Martinique',
 			'MR' => 'An Mháratái',
 			'MS' => 'Montsarat',
 			'MT' => 'Málta',
 			'MU' => 'Oileán Mhuirís',
 			'MV' => 'Oileáin Mhaildíve',
 			'MW' => 'an Mhaláiv',
 			'MX' => 'Meicsiceo',
 			'MY' => 'an Mhalaeisia',
 			'MZ' => 'Mósaimbíc',
 			'NA' => 'an Namaib',
 			'NC' => 'an Nua-Chaladóin',
 			'NE' => 'An Nígir',
 			'NF' => 'Oileán Norfolk',
 			'NG' => 'An Nigéir',
 			'NI' => 'Nicearagua',
 			'NL' => 'an Ísiltír',
 			'NO' => 'an Iorua',
 			'NP' => 'Neipeal',
 			'NR' => 'Nárú',
 			'NU' => 'Niue',
 			'NZ' => 'an Nua-Shéalainn',
 			'OM' => 'Óman',
 			'PA' => 'Panama',
 			'PE' => 'Peiriú',
 			'PF' => 'Polainéis na Fraince',
 			'PG' => 'Nua-Ghuine Phapua',
 			'PH' => 'Na hOileáin Fhilipíneacha',
 			'PK' => 'an Phacastáin',
 			'PL' => 'an Pholainn',
 			'PM' => 'San Pierre agus Miquelon',
 			'PN' => 'Oileáin Pitcairn',
 			'PR' => 'Pórtó Ríce',
 			'PS' => 'na Críocha Palaistíneacha',
 			'PS@alt=short' => 'an Phalaistín',
 			'PT' => 'an Phortaingéil',
 			'PW' => 'Oileáin Palau',
 			'PY' => 'Paragua',
 			'QA' => 'Catar',
 			'QO' => 'an Aigéine Imeallach',
 			'RE' => 'La Réunion',
 			'RO' => 'an Rómáin',
 			'RS' => 'an tSeirbia',
 			'RU' => 'an Rúis',
 			'RW' => 'Ruanda',
 			'SA' => 'an Araib Shádach',
 			'SB' => 'Oileáin Sholaimh',
 			'SC' => 'na Séiséil',
 			'SD' => 'An tSúdáin',
 			'SE' => 'an tSualainn',
 			'SG' => 'Singeapór',
 			'SH' => 'San Héilin',
 			'SI' => 'an tSlóivéin',
 			'SJ' => 'Svalbard agus Jan Mayen',
 			'SK' => 'an tSlóvaic',
 			'SL' => 'Siarra Leon',
 			'SM' => 'San Mairíne',
 			'SN' => 'An tSeineagáil',
 			'SO' => 'an tSomáil',
 			'SR' => 'Suranam',
 			'SS' => 'an tSúdáin Theas',
 			'ST' => 'São Tomé agus Príncipe',
 			'SV' => 'An tSalvadóir',
 			'SX' => 'Sint Maarten',
 			'SY' => 'an tSiria',
 			'SZ' => 'eSuaitíní',
 			'SZ@alt=variant' => 'an tSuasalainn',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Oileáin na dTurcach agus Caicos',
 			'TD' => 'Sead',
 			'TF' => 'Críocha Francacha Dheisceart an Domhain',
 			'TG' => 'Tóga',
 			'TH' => 'an Téalainn',
 			'TJ' => 'an Táidsíceastáin',
 			'TK' => 'Tócalá',
 			'TL' => 'Tíomór Thoir',
 			'TM' => 'an Tuircméanastáin',
 			'TN' => 'An Tuinéis',
 			'TO' => 'Tonga',
 			'TR' => 'an Tuirc',
 			'TT' => 'Oileán na Tríonóide agus Tobága',
 			'TV' => 'Túvalú',
 			'TW' => 'an Téaváin',
 			'TZ' => 'an Tansáin',
 			'UA' => 'an Úcráin',
 			'UG' => 'Uganda',
 			'UM' => 'Oileáin Imeallacha S.A.M.',
 			'UN' => 'na Náisiúin Aontaithe',
 			'UN@alt=short' => 'NA',
 			'US' => 'Stáit Aontaithe Mheiriceá',
 			'US@alt=short' => 'SAM',
 			'UY' => 'Uragua',
 			'UZ' => 'an Úisbéiceastáin',
 			'VA' => 'Cathair na Vatacáine',
 			'VC' => 'San Uinseann agus na Greanáidíní',
 			'VE' => 'Veiniséala',
 			'VG' => 'Oileáin Bhriotanacha na Maighdean',
 			'VI' => 'Oileáin Mheiriceánacha na Maighdean',
 			'VN' => 'Vítneam',
 			'VU' => 'Vanuatú',
 			'WF' => 'Vailís agus Futúna',
 			'WS' => 'Samó',
 			'XA' => 'Bréagaicinn',
 			'XB' => 'Bréag-Bidi',
 			'XK' => 'an Chosaiv',
 			'YE' => 'Éimin',
 			'YT' => 'Mayotte',
 			'ZA' => 'an Afraic Theas',
 			'ZM' => 'an tSaimbia',
 			'ZW' => 'an tSiombáib',
 			'ZZ' => 'Réigiún Anaithnid',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Litriú Traidisiúnta na Gearmáinise',
 			'1994' => 'Ortagrafaíocht Resian Chaighdeánaithe',
 			'1996' => 'Ortagrafaíocht na Gearmáinise in 1996',
 			'1606NICT' => 'Fraincis Dhéanach Mheánach go 1606',
 			'1694ACAD' => 'Nua-Fhraincis Mhoch',
 			'1959ACAD' => 'Acadúil',
 			'ABL1943' => 'Foirmiú ortagrafaíochta in 1943',
 			'ALALC97' => 'Rómhánú ALA-LC, eagrán 1997',
 			'ALUKU' => 'Canúint Aluku',
 			'AO1990' => 'Comhaontú Ortagrafaíochta Theanga na Portaingéilise, 1990',
 			'AREVELA' => 'Airméinis an Oirthir',
 			'AREVMDA' => 'Airméinis an Iarthair',
 			'BAKU1926' => 'Abítir Laidine Tuircice Aontaithe',
 			'BALANKA' => 'Canúint Balanka de Anii',
 			'BARLA' => 'Grúpa canúna Barlavento de Kabuverdianu',
 			'BASICENG' => 'Bun-Bhéarla',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'BIOSCÁNACH',
 			'BISKE' => 'Canúint San Giorgo/Bila',
 			'BOHORIC' => 'Aibítir Bohorič',
 			'BOONT' => 'Boontling',
 			'COLB1945' => 'Coinbhinsiún Ortagrafaíochta na Portaingéilise na Brasaíle, 1945',
 			'CORNU' => 'Béarla an Choirn',
 			'DAJNKO' => 'Aibítir Dajnko',
 			'EKAVSK' => 'Seirbis le fuaimniú Ekavian',
 			'EMODENG' => 'Nua-Bhéarla Moch',
 			'FONIPA' => 'Fogharscríobh IPA',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'Fogharscríobh UPA',
 			'FONXSAMP' => 'Fonxsamp',
 			'HEPBURN' => 'Rómhánú Hepburn',
 			'HOGNORSK' => 'Hognorsk',
 			'HSISTEMO' => 'Hsistemo',
 			'IJEKAVSK' => 'Seirbis le fuaimniú Ijekavach',
 			'ITIHASA' => 'Itihasa',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Gnáth-Litriú',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'Litriú Caighdeánach',
 			'LAUKIKA' => 'Laukika',
 			'LIPAW' => 'Canúint Lipovaz de Resian',
 			'LUNA1918' => 'Luna1918',
 			'METELKO' => 'Aibítir Metelko',
 			'MONOTON' => 'Aontonach',
 			'NDYUKA' => 'Canúint Ndyuka',
 			'NEDIS' => 'Canúint Natisone',
 			'NEWFOUND' => 'Talamh an Éisc',
 			'NJIVA' => 'Canúint Gniva/Njiva',
 			'NULIK' => 'Volapük Nua-Aimseartha',
 			'OSOJS' => 'Canúint Oseacco/Osojane',
 			'OXENDICT' => 'Litriú OED',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'Canúint Pamaka',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Rómhánú Pinyin',
 			'POLYTON' => 'Iltonach',
 			'POSIX' => 'Ríomhaire',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Litriú Athbhreithnithe',
 			'RIGIK' => 'Volapük Clasaiceach',
 			'ROZAJ' => 'Reisiach',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Béarla Caighdeánach na hAlban',
 			'SCOUSE' => 'Béarla Learphoill',
 			'SIMPLE' => 'Simplí',
 			'SOLBA' => 'Canúint Stolvizza/Solbica',
 			'SOTAV' => 'Grúpa canúna Sotavento de Kabuverdianu',
 			'SPANGLIS' => 'Spainglis',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilvan',
 			'SUTSILV' => 'Sutsilv',
 			'TARASK' => 'Ortografaíocht Taraskievica',
 			'UCCOR' => 'Litriú Comhaontaithe',
 			'UCRCOR' => 'Litriú Comhaontaithe Athbhreithnithe',
 			'ULSTER' => 'Cúige Uladh',
 			'UNIFON' => 'Aibítir foghraíochta Unifon',
 			'VAIDIKA' => 'Véideach',
 			'VALENCIA' => 'Vaileinsis',
 			'VALLADER' => 'Vallader',
 			'WADEGILE' => 'Rómhánú Wade-Giles',
 			'XSISTEMO' => 'Xsistemo',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Féilire',
 			'cf' => 'Formáid Airgeadra',
 			'collation' => 'Ord Sórtála',
 			'currency' => 'Airgeadra',
 			'hc' => 'Timthriall Uaire (12 vs 24)',
 			'lb' => 'Stíl Briseadh Líne',
 			'ms' => 'Córas Tomhais',
 			'numbers' => 'Uimhreacha',

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
 				'buddhist' => q{Féilire Búdaíoch},
 				'chinese' => q{Féilire Síneach},
 				'coptic' => q{Féilire Coptach},
 				'dangi' => q{Féilire Dangi},
 				'ethiopic' => q{Féilire Aetóipice},
 				'ethiopic-amete-alem' => q{Féilire Aetóipice Amete Alem},
 				'gregorian' => q{Féilire Ghréagóra},
 				'hebrew' => q{Féilire na nEabhrach},
 				'indian' => q{Féilire Náisiúnta na hIndia},
 				'islamic' => q{Féilire Hijri},
 				'islamic-civil' => q{Féilire Hijiri (táblach, seanré shibhialta)},
 				'islamic-rgsa' => q{Féilire Ioslamach (an Araib Shádach, dearcadh)},
 				'islamic-tbla' => q{Féilire Ioslamach (táblach, seanré réalteolaíoch)},
 				'islamic-umalqura' => q{Féilire Hijiri (Umm al-Qura)},
 				'iso8601' => q{Féilire ISO-8601},
 				'japanese' => q{Féilire Seapánach},
 				'persian' => q{Féilire Peirseach},
 				'roc' => q{Féilire Téavánach},
 			},
 			'cf' => {
 				'account' => q{Formáid Airgeadra don Chuntasaíocht},
 				'standard' => q{Formáid Airgeadra Caighdeánach},
 			},
 			'collation' => {
 				'big5han' => q{Ord sórtála Síneach traidisiúnta - Big5},
 				'compat' => q{Ord Sórtála Roimhe Seo, ar son na comhoiriúnachta},
 				'dictionary' => q{Ord Sórtála Foclóirí},
 				'ducet' => q{Ord Sórtála Réamhshocraithe Unicode},
 				'emoji' => q{Ord Sórtála Emoji},
 				'eor' => q{Rialacha Ordaithe Eorpacha},
 				'gb2312han' => q{Ord sórtála Síneach simplithe - GB 2312},
 				'phonebook' => q{Ord sórtála an eolaire teileafóin},
 				'pinyin' => q{Ord sórtála pinyin},
 				'search' => q{Cuardach Ilfhóinteach},
 				'searchjl' => q{Cuardach de réir Consan Tosaigh Hangul},
 				'standard' => q{Ord Sórtála Caighdeánach},
 				'stroke' => q{Ord sórtála stríce},
 				'traditional' => q{Ord sórtála traidisiúnta},
 				'unihan' => q{Ord Sórtála Stríce Radacaí},
 				'zhuyin' => q{Ord Sórtála Zhuyin},
 			},
 			'hc' => {
 				'h11' => q{Córas 12 Uair (0–11)},
 				'h12' => q{Córas 12 Uair (1–12)},
 				'h23' => q{Córas 24 Uair (0–23)},
 				'h24' => q{Córas 24 Uair (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Stíl Briseadh Líne Scaoilte},
 				'normal' => q{Stíl Gnáthbhriseadh Líne},
 				'strict' => q{Stíl Briseadh Líne Docht},
 			},
 			'ms' => {
 				'metric' => q{Córas Méadrach},
 				'uksystem' => q{Córas Tomhais Reachtúil},
 				'ussystem' => q{Córas Tomhais SAM},
 			},
 			'numbers' => {
 				'ahom' => q{Digití Ahom},
 				'arab' => q{Digití Ind-Arabacha},
 				'arabext' => q{Digití Ind-Arabacha Breisithe},
 				'armn' => q{Uimhreacha Airméanacha},
 				'armnlow' => q{Uimhreacha Cás Íochtair Airméanacha},
 				'bali' => q{Digití Bailíocha},
 				'beng' => q{Digití Beangálacha},
 				'brah' => q{Digití Brahmi},
 				'cakm' => q{Digití Chakma},
 				'cham' => q{Digití Cham},
 				'cyrl' => q{Uimhreacha Coireallacha},
 				'deva' => q{Digití Déiveanágracha},
 				'ethi' => q{Uimhreacha Aetóipice},
 				'fullwide' => q{Digití Lánleithid},
 				'geor' => q{Uimhreacha Seoirseacha},
 				'gonm' => q{Digití Masaram Gondi},
 				'grek' => q{Uimhreacha Gréagacha},
 				'greklow' => q{Uimhreacha Cás Íochtair Gréagacha},
 				'gujr' => q{Digití Gúisearátacha},
 				'guru' => q{Digití Gurmúcacha},
 				'hanidec' => q{Uimhreacha Deachúlacha Síneacha},
 				'hans' => q{Uimhreacha sa tSínis Shimplithe},
 				'hansfin' => q{Uimhreacha Airgeadúla sa tSínis Shimplithe},
 				'hant' => q{Uimhreacha sa tSínis Thraidisiúnta},
 				'hantfin' => q{Uimhreacha Airgeadúla sa tSínis Thraidisiúnta},
 				'hebr' => q{Uimhreacha Eabhracha},
 				'hmng' => q{Digití Pahawh Hmong},
 				'java' => q{Digití Iávacha},
 				'jpan' => q{Uimhreacha Seapánacha},
 				'jpanfin' => q{Uimhreacha Airgeadúla Seapánacha},
 				'kali' => q{Digití Kayah Li},
 				'khmr' => q{Digití Ciméaracha},
 				'knda' => q{Digití Cannadacha},
 				'lana' => q{Digití Tai Tham Hora},
 				'lanatham' => q{Digití Tai Tham Tham},
 				'laoo' => q{Digití Laosacha},
 				'latn' => q{Digití Iartharacha},
 				'lepc' => q{Digití Lepcha},
 				'limb' => q{Digití Limbu},
 				'mathbold' => q{Digití Troma Matamaiticiúla},
 				'mathdbl' => q{Digití Stríce Dúbailte Matamaiticiúla},
 				'mathmono' => q{Digití Aonspáis Matamaiticiúla},
 				'mathsanb' => q{Digití Troma Sans-Serif Matamaiticiúla},
 				'mathsans' => q{Digití Sans-Serif Matamaiticiúla},
 				'mlym' => q{Digití Mailéalamacha},
 				'modi' => q{Digití Modi},
 				'mong' => q{Digití Mongólacha},
 				'mroo' => q{Digití Mro},
 				'mtei' => q{Digití Meetei Mayek},
 				'mymr' => q{Digití Maenmaracha},
 				'mymrshan' => q{Digití Myanmar Shan},
 				'mymrtlng' => q{Digití Myanmar Tai Laing},
 				'nkoo' => q{Digití N’ko},
 				'olck' => q{Digití Ol Chiki},
 				'orya' => q{Digití Oiríseacha},
 				'osma' => q{Digití Osmanya},
 				'roman' => q{Uimhreacha Rómhánacha},
 				'romanlow' => q{Uimhreacha Cás Íochtair Rómhánacha},
 				'saur' => q{Digití Saurashtra},
 				'shrd' => q{Digití Sharada},
 				'sind' => q{Digití Khudawadi},
 				'sinh' => q{Digití Sinhala Lith},
 				'sora' => q{Digití Sora Sompeng},
 				'sund' => q{Digití Sundainéise},
 				'takr' => q{Digití Takri},
 				'talu' => q{Digití Tai Lue Nua},
 				'taml' => q{Uimhreacha Traidisiúnta Tamalacha},
 				'tamldec' => q{Digití Tamalacha},
 				'telu' => q{Digití Teileagúcha},
 				'thai' => q{Digití Téalannacha},
 				'tibt' => q{Digití Tibéadacha},
 				'tirh' => q{Digití Tirhuta},
 				'vaii' => q{Digití Vai},
 				'wara' => q{Digití Warang Citi},
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
			'metric' => q{Méadrach},
 			'UK' => q{RA},
 			'US' => q{SAM},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Teanga: {0}',
 			'script' => 'Script: {0}',
 			'region' => 'Réigiún: {0}',

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
			auxiliary => qr{[å ḃ ċ ḋ ḟ ġ j k ṁ ṗ q ṡ ṫ v w x y z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[aá b c d eé f g h ií l m n oó p r s t uú]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'name' => q(príomhaird),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(príomhaird),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(cibi-{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(cibi-{0}),
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
					'1024p4' => {
						'1' => q(tebi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi{0}),
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deici{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deici{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pici{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pici{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(feimti{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(feimti{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atai{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atai{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ceinti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ceinti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zeipti{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zeipti{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yoctai{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yoctai{0}),
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
					'10p-6' => {
						'1' => q(micri{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micri{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nanai{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nanai{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deacai{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deacai{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(teiri{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(teiri{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peiti{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peiti{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(eicsi{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(eicsi{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(heicti{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(heicti{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zeiti{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeiti{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotai{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotai{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(cili{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(cili{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(meigi{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(meigi{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(gigi{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(gigi{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} g-fhórsa),
						'many' => q({0} g-fhórsa),
						'one' => q({0} g-fhórsa),
						'other' => q({0} g-fhórsa),
						'two' => q({0} g-fhórsa),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} g-fhórsa),
						'many' => q({0} g-fhórsa),
						'one' => q({0} g-fhórsa),
						'other' => q({0} g-fhórsa),
						'two' => q({0} g-fhórsa),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(méadair sa soicind cearnaithe),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(méadair sa soicind cearnaithe),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} nóiméad stua),
						'many' => q({0} nóiméad stua),
						'one' => q({0} nóiméad stua),
						'other' => q({0} nóiméad stua),
						'two' => q({0} nóiméad stua),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} nóiméad stua),
						'many' => q({0} nóiméad stua),
						'one' => q({0} nóiméad stua),
						'other' => q({0} nóiméad stua),
						'two' => q({0} nóiméad stua),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} shoicind stua),
						'many' => q({0} soicind stua),
						'name' => q(soicindí stua),
						'one' => q({0} soicind stua),
						'other' => q({0} soicind stua),
						'two' => q({0} shoicind stua),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} shoicind stua),
						'many' => q({0} soicind stua),
						'name' => q(soicindí stua),
						'one' => q({0} soicind stua),
						'other' => q({0} soicind stua),
						'two' => q({0} shoicind stua),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} chéim),
						'many' => q({0} gcéim),
						'one' => q({0} chéim),
						'other' => q({0} céim),
						'two' => q({0} chéim),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} chéim),
						'many' => q({0} gcéim),
						'one' => q({0} chéim),
						'other' => q({0} céim),
						'two' => q({0} chéim),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} raidian),
						'many' => q({0} raidian),
						'one' => q({0} raidian),
						'other' => q({0} raidian),
						'two' => q({0} raidian),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} raidian),
						'many' => q({0} raidian),
						'one' => q({0} raidian),
						'other' => q({0} raidian),
						'two' => q({0} raidian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} imrothlú),
						'many' => q({0} n-imrothlú),
						'name' => q(imrothlú),
						'one' => q({0} imrothlú),
						'other' => q({0} imrothlú),
						'two' => q({0} imrothlú),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} imrothlú),
						'many' => q({0} n-imrothlú),
						'name' => q(imrothlú),
						'one' => q({0} imrothlú),
						'other' => q({0} imrothlú),
						'two' => q({0} imrothlú),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} acra),
						'many' => q({0} n-acra),
						'one' => q({0} acra),
						'other' => q({0} acra),
						'two' => q({0} acra),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} acra),
						'many' => q({0} n-acra),
						'one' => q({0} acra),
						'other' => q({0} acra),
						'two' => q({0} acra),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dúnaim),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dúnaim),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} heicteár),
						'many' => q({0} heicteár),
						'one' => q({0} heicteár),
						'other' => q({0} heicteár),
						'two' => q({0} heicteár),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} heicteár),
						'many' => q({0} heicteár),
						'one' => q({0} heicteár),
						'other' => q({0} heicteár),
						'two' => q({0} heicteár),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} cheintiméadar chearnacha),
						'many' => q({0} gceintiméadar chearnacha),
						'name' => q(ceintiméadair chearnacha),
						'one' => q({0} cheintiméadar cearnach),
						'other' => q({0} ceintiméadar cearnach),
						'per' => q({0} sa cheintiméadar cearnach),
						'two' => q({0} cheintiméadar chearnacha),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} cheintiméadar chearnacha),
						'many' => q({0} gceintiméadar chearnacha),
						'name' => q(ceintiméadair chearnacha),
						'one' => q({0} cheintiméadar cearnach),
						'other' => q({0} ceintiméadar cearnach),
						'per' => q({0} sa cheintiméadar cearnach),
						'two' => q({0} cheintiméadar chearnacha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} throigh chearnacha),
						'many' => q({0} dtroigh chearnacha),
						'name' => q(troithe cearnacha),
						'one' => q({0} troigh chearnach),
						'other' => q({0} troigh chearnach),
						'two' => q({0} throigh chearnacha),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} throigh chearnacha),
						'many' => q({0} dtroigh chearnacha),
						'name' => q(troithe cearnacha),
						'one' => q({0} troigh chearnach),
						'other' => q({0} troigh chearnach),
						'two' => q({0} throigh chearnacha),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} orlach chearnacha),
						'many' => q({0} orlach chearnacha),
						'name' => q(orlaí cearnacha),
						'one' => q({0} orlach cearnach),
						'other' => q({0} orlach cearnach),
						'per' => q({0} san orlach cearnach),
						'two' => q({0} orlach chearnacha),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} orlach chearnacha),
						'many' => q({0} orlach chearnacha),
						'name' => q(orlaí cearnacha),
						'one' => q({0} orlach cearnach),
						'other' => q({0} orlach cearnach),
						'per' => q({0} san orlach cearnach),
						'two' => q({0} orlach chearnacha),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} chiliméadar chearnacha),
						'many' => q({0} gciliméadar chearnacha),
						'name' => q(ciliméadair chearnacha),
						'one' => q({0} chiliméadar cearnach),
						'other' => q({0} ciliméadar cearnach),
						'per' => q({0} sa chiliméadar cearnach),
						'two' => q({0} chiliméadar chearnacha),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} chiliméadar chearnacha),
						'many' => q({0} gciliméadar chearnacha),
						'name' => q(ciliméadair chearnacha),
						'one' => q({0} chiliméadar cearnach),
						'other' => q({0} ciliméadar cearnach),
						'per' => q({0} sa chiliméadar cearnach),
						'two' => q({0} chiliméadar chearnacha),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} mhéadar chearnacha),
						'many' => q({0} méadar chearnacha),
						'name' => q(méadair chearnacha),
						'one' => q({0} mhéadar cearnach),
						'other' => q({0} méadar cearnach),
						'per' => q({0} sa mhéadar cearnach),
						'two' => q({0} mhéadar chearnacha),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} mhéadar chearnacha),
						'many' => q({0} méadar chearnacha),
						'name' => q(méadair chearnacha),
						'one' => q({0} mhéadar cearnach),
						'other' => q({0} méadar cearnach),
						'per' => q({0} sa mhéadar cearnach),
						'two' => q({0} mhéadar chearnacha),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mhíle chearnacha),
						'many' => q({0} míle chearnacha),
						'name' => q(mílte cearnacha),
						'one' => q({0} mhíle cearnach),
						'other' => q({0} míle cearnach),
						'per' => q({0} sa mhíle cearnach),
						'two' => q({0} mhíle chearnacha),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mhíle chearnacha),
						'many' => q({0} míle chearnacha),
						'name' => q(mílte cearnacha),
						'one' => q({0} mhíle cearnach),
						'other' => q({0} míle cearnach),
						'per' => q({0} sa mhíle cearnach),
						'two' => q({0} mhíle chearnacha),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} shlat chearnacha),
						'many' => q({0} slat chearnacha),
						'name' => q(slata cearnacha),
						'one' => q({0} slat chearnach),
						'other' => q({0} slat chearnach),
						'two' => q({0} shlat chearnacha),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} shlat chearnacha),
						'many' => q({0} slat chearnacha),
						'name' => q(slata cearnacha),
						'one' => q({0} slat chearnach),
						'other' => q({0} slat chearnach),
						'two' => q({0} shlat chearnacha),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} charat),
						'many' => q({0} gcarat óir),
						'name' => q(carait),
						'one' => q({0} charat óir),
						'other' => q({0} carat óir),
						'two' => q({0} charat óir),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} charat),
						'many' => q({0} gcarat óir),
						'name' => q(carait),
						'one' => q({0} charat óir),
						'other' => q({0} carat óir),
						'two' => q({0} charat óir),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mhilleagram sa deicilítear),
						'many' => q({0} milleagram sa deicilítear),
						'name' => q(milleagraim sa deicilítear),
						'one' => q({0} mhilleagram sa deicilítear),
						'other' => q({0} milleagram sa deicilítear),
						'two' => q({0} mhilleagram sa deicilítear),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mhilleagram sa deicilítear),
						'many' => q({0} milleagram sa deicilítear),
						'name' => q(milleagraim sa deicilítear),
						'one' => q({0} mhilleagram sa deicilítear),
						'other' => q({0} milleagram sa deicilítear),
						'two' => q({0} mhilleagram sa deicilítear),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mhilleamól sa lítear),
						'many' => q({0} milleamól sa lítear),
						'name' => q(milleamóil sa lítear),
						'one' => q({0} mhilleamól sa lítear),
						'other' => q({0} milleamól sa lítear),
						'two' => q({0} mhilleamól sa lítear),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mhilleamól sa lítear),
						'many' => q({0} milleamól sa lítear),
						'name' => q(milleamóil sa lítear),
						'one' => q({0} mhilleamól sa lítear),
						'other' => q({0} milleamól sa lítear),
						'two' => q({0} mhilleamól sa lítear),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(móil),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(móil),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0} faoin gcéad),
						'other' => q({0} faoin gcéad),
						'two' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0} faoin gcéad),
						'other' => q({0} faoin gcéad),
						'two' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0} faoin míle),
						'other' => q({0} faoin míle),
						'two' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0} faoin míle),
						'other' => q({0} faoin míle),
						'two' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} chuid sa mhilliún),
						'many' => q({0} gcuid sa mhilliún),
						'name' => q(codanna sa mhilliún),
						'one' => q({0} chuid sa mhilliún),
						'other' => q({0} cuid sa mhilliún),
						'two' => q({0} chuid sa mhilliún),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} chuid sa mhilliún),
						'many' => q({0} gcuid sa mhilliún),
						'name' => q(codanna sa mhilliún),
						'one' => q({0} chuid sa mhilliún),
						'other' => q({0} cuid sa mhilliún),
						'two' => q({0} chuid sa mhilliún),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'name' => q(faoin deich míle),
						'one' => q({0} faoin deich míle),
						'other' => q({0}‱),
						'two' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'name' => q(faoin deich míle),
						'one' => q({0} faoin deich míle),
						'other' => q({0}‱),
						'two' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} lítear sa 100 ciliméadar),
						'many' => q({0} lítear sa 100 ciliméadar),
						'name' => q(lítir sa 100 ciliméadar),
						'one' => q({0} lítear sa 100 ciliméadar),
						'other' => q({0} lítear sa 100 ciliméadar),
						'two' => q({0} lítear sa 100 ciliméadar),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} lítear sa 100 ciliméadar),
						'many' => q({0} lítear sa 100 ciliméadar),
						'name' => q(lítir sa 100 ciliméadar),
						'one' => q({0} lítear sa 100 ciliméadar),
						'other' => q({0} lítear sa 100 ciliméadar),
						'two' => q({0} lítear sa 100 ciliméadar),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} lítear sa chiliméadar),
						'many' => q({0} lítear sa chiliméadar),
						'name' => q(lítir sa chiliméadar),
						'one' => q({0} lítear sa chiliméadar),
						'other' => q({0} lítear sa chiliméadar),
						'two' => q({0} lítear sa chiliméadar),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} lítear sa chiliméadar),
						'many' => q({0} lítear sa chiliméadar),
						'name' => q(lítir sa chiliméadar),
						'one' => q({0} lítear sa chiliméadar),
						'other' => q({0} lítear sa chiliméadar),
						'two' => q({0} lítear sa chiliméadar),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mhíle an galún),
						'many' => q({0} míle an galún),
						'name' => q(mílte an galún),
						'one' => q({0} mhíle an galún),
						'other' => q({0} míle an galún),
						'two' => q({0} mhíle an galún),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mhíle an galún),
						'many' => q({0} míle an galún),
						'name' => q(mílte an galún),
						'one' => q({0} mhíle an galún),
						'other' => q({0} míle an galún),
						'two' => q({0} mhíle an galún),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mhíle sa ghalún impiriúil),
						'many' => q({0} míle sa ghalún impiriúil),
						'name' => q(mílte sa ghalún impiriúil),
						'one' => q({0} mhíle sa ghalún impiriúil),
						'other' => q({0} míle sa ghalún impiriúil),
						'two' => q({0} mhíle sa ghalún impiriúil),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mhíle sa ghalún impiriúil),
						'many' => q({0} míle sa ghalún impiriúil),
						'name' => q(mílte sa ghalún impiriúil),
						'one' => q({0} mhíle sa ghalún impiriúil),
						'other' => q({0} míle sa ghalún impiriúil),
						'two' => q({0} mhíle sa ghalún impiriúil),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} oirthear),
						'north' => q({0} thuaidh),
						'south' => q({0} theas),
						'west' => q({0} iarthar),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} oirthear),
						'north' => q({0} thuaidh),
						'south' => q({0} theas),
						'west' => q({0} iarthar),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(giotáin),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(giotáin),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} ghigighiotán),
						'many' => q({0} ngigighiotán),
						'name' => q(gigighiotáin),
						'one' => q({0} ghigighiotán),
						'other' => q({0} gigighiotán),
						'two' => q({0} ghigighiotán),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} ghigighiotán),
						'many' => q({0} ngigighiotán),
						'name' => q(gigighiotáin),
						'one' => q({0} ghigighiotán),
						'other' => q({0} gigighiotán),
						'two' => q({0} ghigighiotán),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} ghigibheart),
						'many' => q({0} ngigibheart),
						'name' => q(gigibhearta),
						'one' => q({0} ghigibheart),
						'other' => q({0} gigibheart),
						'two' => q({0} ghigibheart),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} ghigibheart),
						'many' => q({0} ngigibheart),
						'name' => q(gigibhearta),
						'one' => q({0} ghigibheart),
						'other' => q({0} gigibheart),
						'two' => q({0} ghigibheart),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} chilighiotán),
						'many' => q({0} gcilighiotán),
						'name' => q(cilighiotáin),
						'one' => q({0} chilighiotán),
						'other' => q({0} cilighiotán),
						'two' => q({0} chilighiotán),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} chilighiotán),
						'many' => q({0} gcilighiotán),
						'name' => q(cilighiotáin),
						'one' => q({0} chilighiotán),
						'other' => q({0} cilighiotán),
						'two' => q({0} chilighiotán),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} chilibheart),
						'many' => q({0} gcilibheart),
						'name' => q(cilibhearta),
						'one' => q({0} chilibheart),
						'other' => q({0} cilibheart),
						'two' => q({0} chilibheart),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} chilibheart),
						'many' => q({0} gcilibheart),
						'name' => q(cilibhearta),
						'one' => q({0} chilibheart),
						'other' => q({0} cilibheart),
						'two' => q({0} chilibheart),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} mheigighiotán),
						'many' => q({0} meigighiotán),
						'name' => q(meigighiotáin),
						'one' => q({0} mheigighiotán),
						'other' => q({0} meigighiotán),
						'two' => q({0} mheigighiotán),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} mheigighiotán),
						'many' => q({0} meigighiotán),
						'name' => q(meigighiotáin),
						'one' => q({0} mheigighiotán),
						'other' => q({0} meigighiotán),
						'two' => q({0} mheigighiotán),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} mheigibheart),
						'many' => q({0} meigibheart),
						'name' => q(meigibhearta),
						'one' => q({0} mheigibheart),
						'other' => q({0} meigibheart),
						'two' => q({0} mheigibheart),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} mheigibheart),
						'many' => q({0} meigibheart),
						'name' => q(meigibhearta),
						'one' => q({0} mheigibheart),
						'other' => q({0} meigibheart),
						'two' => q({0} mheigibheart),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} PB),
						'many' => q({0} PB),
						'name' => q(peitibhearta),
						'one' => q({0} peitibheart),
						'other' => q({0} petabytes),
						'two' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} PB),
						'many' => q({0} PB),
						'name' => q(peitibhearta),
						'one' => q({0} peitibheart),
						'other' => q({0} petabytes),
						'two' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} theirighiotán),
						'many' => q({0} dteirighiotán),
						'name' => q(teirighiotáin),
						'one' => q({0} teirighiotán),
						'other' => q({0} teirighiotán),
						'two' => q({0} theirighiotán),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} theirighiotán),
						'many' => q({0} dteirighiotán),
						'name' => q(teirighiotáin),
						'one' => q({0} teirighiotán),
						'other' => q({0} teirighiotán),
						'two' => q({0} theirighiotán),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} theiribheart),
						'many' => q({0} dteiribheart),
						'name' => q(teiribhearta),
						'one' => q({0} teiribheart),
						'other' => q({0} teiribheart),
						'two' => q({0} theiribheart),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} theiribheart),
						'many' => q({0} dteiribheart),
						'name' => q(teiribhearta),
						'one' => q({0} teiribheart),
						'other' => q({0} teiribheart),
						'two' => q({0} theiribheart),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} chéad bliain),
						'many' => q({0} gcéad bliain),
						'name' => q(na céadta bliain),
						'one' => q(céad bliain),
						'other' => q({0} céad bliain),
						'two' => q({0} chéad bliain),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} chéad bliain),
						'many' => q({0} gcéad bliain),
						'name' => q(na céadta bliain),
						'one' => q(céad bliain),
						'other' => q({0} céad bliain),
						'two' => q({0} chéad bliain),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} sa lá),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} sa lá),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dec),
						'many' => q({0} dec),
						'name' => q(deicheanna blianta),
						'one' => q({0} deich mbliana),
						'other' => q({0} deich mbliana),
						'two' => q({0} dec),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dec),
						'many' => q({0} dec),
						'name' => q(deicheanna blianta),
						'one' => q({0} deich mbliana),
						'other' => q({0} deich mbliana),
						'two' => q({0} dec),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(msoic),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(msoic),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mhí),
						'many' => q({0} mí),
						'one' => q({0} mhí),
						'other' => q({0} mí),
						'two' => q({0} mhí),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mhí),
						'many' => q({0} mí),
						'one' => q({0} mhí),
						'other' => q({0} mí),
						'two' => q({0} mhí),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanashoicind),
						'many' => q({0} nanashoicind),
						'name' => q(nanashoicindí),
						'one' => q({0} nanashoicind),
						'other' => q({0} nanashoicind),
						'two' => q({0} nanashoicind),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanashoicind),
						'many' => q({0} nanashoicind),
						'name' => q(nanashoicindí),
						'one' => q({0} nanashoicind),
						'other' => q({0} nanashoicind),
						'two' => q({0} nanashoicind),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} oíche),
						'many' => q({0} n-oíche),
						'name' => q(oícheanta),
						'one' => q({0} oíche amháin),
						'other' => q({0} oíche),
						'per' => q({0} san oíche),
						'two' => q({0} oíche),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} oíche),
						'many' => q({0} n-oíche),
						'name' => q(oícheanta),
						'one' => q({0} oíche amháin),
						'other' => q({0} oíche),
						'per' => q({0} san oíche),
						'two' => q({0} oíche),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'name' => q(ceathrúna),
						'one' => q({0} ceathrú),
						'other' => q({0} ceathrúna),
						'two' => q({0} cna),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'name' => q(ceathrúna),
						'one' => q({0} ceathrú),
						'other' => q({0} ceathrúna),
						'two' => q({0} cna),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} shoic),
						'many' => q({0} soic),
						'one' => q({0} soic),
						'other' => q({0} soic),
						'two' => q({0} shoic),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} shoic),
						'many' => q({0} soic),
						'one' => q({0} soic),
						'other' => q({0} soic),
						'two' => q({0} shoic),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bl),
						'many' => q({0} mbl),
						'one' => q({0} bhliain),
						'other' => q({0} bl),
						'per' => q({0} sa bhliain),
						'two' => q({0} bhl),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bl),
						'many' => q({0} mbl),
						'one' => q({0} bhliain),
						'other' => q({0} bl),
						'per' => q({0} sa bhliain),
						'two' => q({0} bhl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} aimpéar),
						'many' => q({0} n-aimpéar),
						'one' => q({0} aimpéar),
						'other' => q({0} aimpéar),
						'two' => q({0} aimpéar),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} aimpéar),
						'many' => q({0} n-aimpéar),
						'one' => q({0} aimpéar),
						'other' => q({0} aimpéar),
						'two' => q({0} aimpéar),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mhiollaimpéar),
						'many' => q({0} miollaimpéar),
						'name' => q(miollaimpéir),
						'one' => q({0} mhiollaimpéar),
						'other' => q({0} miollaimpéar),
						'two' => q({0} mhiollaimpéar),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mhiollaimpéar),
						'many' => q({0} miollaimpéar),
						'name' => q(miollaimpéir),
						'one' => q({0} mhiollaimpéar),
						'other' => q({0} miollaimpéar),
						'two' => q({0} mhiollaimpéar),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} óm),
						'many' => q({0} n-óm),
						'one' => q({0} óm),
						'other' => q({0} óm),
						'two' => q({0} óm),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} óm),
						'many' => q({0} n-óm),
						'one' => q({0} óm),
						'other' => q({0} óm),
						'two' => q({0} óm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volta),
						'many' => q({0} volta),
						'one' => q({0} volta),
						'other' => q({0} volta),
						'two' => q({0} volta),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volta),
						'many' => q({0} volta),
						'one' => q({0} volta),
						'other' => q({0} volta),
						'two' => q({0} volta),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} Btu),
						'many' => q({0} Btu),
						'name' => q(teas-aonaid Bhriotanacha),
						'one' => q({0} theas-aonad Briotanach),
						'other' => q({0} aonad teirmeach Briotanach),
						'two' => q({0} Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} Btu),
						'many' => q({0} Btu),
						'name' => q(teas-aonaid Bhriotanacha),
						'one' => q({0} theas-aonad Briotanach),
						'other' => q({0} aonad teirmeach Briotanach),
						'two' => q({0} Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} chalra),
						'many' => q({0} gcalra),
						'name' => q(calraí),
						'one' => q({0} chalra),
						'other' => q({0} calra),
						'two' => q({0} chalra),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} chalra),
						'many' => q({0} gcalra),
						'name' => q(calraí),
						'one' => q({0} chalra),
						'other' => q({0} calra),
						'two' => q({0} chalra),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} eV),
						'many' => q({0} eV),
						'name' => q(leictreonvoltanna),
						'one' => q({0} leictreavolta),
						'other' => q({0} leictreonvolta),
						'two' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} eV),
						'many' => q({0} eV),
						'name' => q(leictreonvoltanna),
						'one' => q({0} leictreavolta),
						'other' => q({0} leictreonvolta),
						'two' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} Chalra),
						'many' => q({0} gCalra),
						'name' => q(Calraí),
						'one' => q({0} Chalra),
						'other' => q({0} Calra),
						'two' => q({0} Chalra),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} Chalra),
						'many' => q({0} gCalra),
						'name' => q(Calraí),
						'one' => q({0} Chalra),
						'other' => q({0} Calra),
						'two' => q({0} Chalra),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} ghiúl),
						'many' => q({0} ngiúl),
						'one' => q({0} ghiúl),
						'other' => q({0} giúl),
						'two' => q({0} ghiúl),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} ghiúl),
						'many' => q({0} ngiúl),
						'one' => q({0} ghiúl),
						'other' => q({0} giúl),
						'two' => q({0} ghiúl),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} chileacalra),
						'many' => q({0} gcileacalra),
						'name' => q(cileacalraí),
						'one' => q({0} chileacalra),
						'other' => q({0} cileacalra),
						'two' => q({0} chileacalra),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} chileacalra),
						'many' => q({0} gcileacalra),
						'name' => q(cileacalraí),
						'one' => q({0} chileacalra),
						'other' => q({0} cileacalra),
						'two' => q({0} chileacalra),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} chiligiúl),
						'many' => q({0} gciligiúl),
						'name' => q(ciligiúil),
						'one' => q({0} chiligiúl),
						'other' => q({0} ciligiúl),
						'two' => q({0} chiligiúl),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} chiligiúl),
						'many' => q({0} gciligiúl),
						'name' => q(ciligiúil),
						'one' => q({0} chiligiúl),
						'other' => q({0} ciligiúl),
						'two' => q({0} chiligiúl),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} chileavatuair),
						'many' => q({0} gcileavatuair),
						'name' => q(cileavatuaireanta),
						'one' => q({0} chileavatuair),
						'other' => q({0} cileavatuair),
						'two' => q({0} chileavatuair),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} chileavatuair),
						'many' => q({0} gcileavatuair),
						'name' => q(cileavatuaireanta),
						'one' => q({0} chileavatuair),
						'other' => q({0} cileavatuair),
						'two' => q({0} chileavatuair),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'name' => q(cileavatuair in aghaidh 100 ciliméadar),
						'one' => q(cileavatuair in aghaidh 100 ciliméadar),
						'other' => q({0} cileavatuair in aghaidh 100 ciliméadar),
						'two' => q({0} cileavatuair in aghaidh 100 cilliméadar),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kWh/100km),
						'many' => q({0} kWh/100km),
						'name' => q(cileavatuair in aghaidh 100 ciliméadar),
						'one' => q(cileavatuair in aghaidh 100 ciliméadar),
						'other' => q({0} cileavatuair in aghaidh 100 ciliméadar),
						'two' => q({0} cileavatuair in aghaidh 100 cilliméadar),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} N),
						'many' => q({0} N),
						'name' => q(niútain),
						'one' => q({0} niútan),
						'other' => q({0} niútan),
						'two' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} N),
						'many' => q({0} N),
						'name' => q(niútain),
						'one' => q({0} niútan),
						'other' => q({0} niútan),
						'two' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(puint fórsa),
						'one' => q({0} punt fórsa),
						'other' => q({0} lbf),
						'two' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} lbf),
						'many' => q({0} lbf),
						'name' => q(puint fórsa),
						'one' => q({0} punt fórsa),
						'other' => q({0} lbf),
						'two' => q({0} lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} ghigiheirts),
						'many' => q({0} ngigiheirts),
						'name' => q(gigiheirts),
						'one' => q({0} ghigiheirts),
						'other' => q({0} gigiheirts),
						'two' => q({0} ghigiheirts),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} ghigiheirts),
						'many' => q({0} ngigiheirts),
						'name' => q(gigiheirts),
						'one' => q({0} ghigiheirts),
						'other' => q({0} gigiheirts),
						'two' => q({0} ghigiheirts),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} heirts),
						'many' => q({0} heirts),
						'name' => q(heirts),
						'one' => q({0} heirts),
						'other' => q({0} heirts),
						'two' => q({0} heirts),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} heirts),
						'many' => q({0} heirts),
						'name' => q(heirts),
						'one' => q({0} heirts),
						'other' => q({0} heirts),
						'two' => q({0} heirts),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} chiliheirts),
						'many' => q({0} gciliheirts),
						'name' => q(ciliheirts),
						'one' => q({0} chiliheirts),
						'other' => q({0} ciliheirts),
						'two' => q({0} chiliheirts),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} chiliheirts),
						'many' => q({0} gciliheirts),
						'name' => q(ciliheirts),
						'one' => q({0} chiliheirts),
						'other' => q({0} ciliheirts),
						'two' => q({0} chiliheirts),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} mheigiheirts),
						'many' => q({0} meigiheirts),
						'name' => q(meigiheirts),
						'one' => q({0} mheigiheirts),
						'other' => q({0} meigiheirts),
						'two' => q({0} mheigiheirts),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} mheigiheirts),
						'many' => q({0} meigiheirts),
						'name' => q(meigiheirts),
						'one' => q({0} mheigiheirts),
						'other' => q({0} meigiheirts),
						'two' => q({0} mheigiheirts),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} eim),
						'many' => q({0} n-eim),
						'one' => q({0} eim),
						'other' => q({0} eim),
						'two' => q({0} eim),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} eim),
						'many' => q({0} n-eim),
						'one' => q({0} eim),
						'other' => q({0} eim),
						'two' => q({0} eim),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} MP),
						'many' => q({0} MP),
						'one' => q({0} mheigiphicteilín),
						'other' => q({0} meigiphicteilín),
						'two' => q({0} MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} MP),
						'many' => q({0} MP),
						'one' => q({0} mheigiphicteilín),
						'other' => q({0} meigiphicteilín),
						'two' => q({0} MP),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(picteilíní san orlach),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(picteilíní san orlach),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} AR),
						'many' => q({0} AR),
						'name' => q(aonaid réalteolaíocha),
						'one' => q({0} aonad réalteolaíoch),
						'other' => q({0} AR),
						'two' => q({0} aonad réalteolaíoch),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} AR),
						'many' => q({0} AR),
						'name' => q(aonaid réalteolaíocha),
						'one' => q({0} aonad réalteolaíoch),
						'other' => q({0} AR),
						'two' => q({0} aonad réalteolaíoch),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} cheintiméadar),
						'many' => q({0} gceintiméadar),
						'name' => q(ceintiméadair),
						'one' => q({0} cheintiméadar),
						'other' => q({0} ceintiméadar),
						'per' => q({0} sa cheintiméadar),
						'two' => q({0} cheintiméadar),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} cheintiméadar),
						'many' => q({0} gceintiméadar),
						'name' => q(ceintiméadair),
						'one' => q({0} cheintiméadar),
						'other' => q({0} ceintiméadar),
						'per' => q({0} sa cheintiméadar),
						'two' => q({0} cheintiméadar),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} dheiciméadar),
						'many' => q({0} ndeiciméadar),
						'name' => q(deiciméadair),
						'one' => q({0} deiciméadar),
						'other' => q({0} deiciméadar),
						'two' => q({0} dheiciméadar),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} dheiciméadar),
						'many' => q({0} ndeiciméadar),
						'name' => q(deiciméadair),
						'one' => q({0} deiciméadar),
						'other' => q({0} deiciméadar),
						'two' => q({0} dheiciméadar),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} gha an domhain),
						'many' => q({0} nga an domhain),
						'name' => q(ga an domhain),
						'one' => q({0} gha an domhain),
						'other' => q({0} ga an domhain),
						'two' => q({0} gha an domhain),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} gha an domhain),
						'many' => q({0} nga an domhain),
						'name' => q(ga an domhain),
						'one' => q({0} gha an domhain),
						'other' => q({0} ga an domhain),
						'two' => q({0} gha an domhain),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} thr.),
						'many' => q({0} dtr.),
						'one' => q({0} troigh),
						'other' => q({0} tr.),
						'per' => q({0} sa troigh),
						'two' => q({0} thr.),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} thr.),
						'many' => q({0} dtr.),
						'one' => q({0} troigh),
						'other' => q({0} tr.),
						'per' => q({0} sa troigh),
						'two' => q({0} thr.),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} orlach),
						'many' => q({0} or.),
						'one' => q({0} orlach),
						'other' => q({0} orlach),
						'two' => q({0} orlach),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} orlach),
						'many' => q({0} or.),
						'one' => q({0} orlach),
						'other' => q({0} orlach),
						'two' => q({0} orlach),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} chiliméadar),
						'many' => q({0} gciliméadar),
						'name' => q(ciliméadair),
						'one' => q({0} chiliméadar),
						'other' => q({0} ciliméadar),
						'per' => q({0} sa chiliméadar),
						'two' => q({0} chiliméadar),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} chiliméadar),
						'many' => q({0} gciliméadar),
						'name' => q(ciliméadair),
						'one' => q({0} chiliméadar),
						'other' => q({0} ciliméadar),
						'per' => q({0} sa chiliméadar),
						'two' => q({0} chiliméadar),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'one' => q({0} solasbhliain),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'one' => q({0} solasbhliain),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} mhéadar),
						'many' => q({0} méadar),
						'one' => q({0} mhéadar),
						'other' => q({0} méadar),
						'per' => q({0} sa mhéadar),
						'two' => q({0} mhéadar),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} mhéadar),
						'many' => q({0} méadar),
						'one' => q({0} mhéadar),
						'other' => q({0} méadar),
						'per' => q({0} sa mhéadar),
						'two' => q({0} mhéadar),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} mhicriméadar),
						'many' => q({0} micriméadar),
						'name' => q(micriméadair),
						'one' => q({0} mhicriméadar),
						'other' => q({0} micriméadar),
						'two' => q({0} mhicriméadar),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} mhicriméadar),
						'many' => q({0} micriméadar),
						'name' => q(micriméadair),
						'one' => q({0} mhicriméadar),
						'other' => q({0} micriméadar),
						'two' => q({0} mhicriméadar),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'one' => q({0} mhíle),
						'other' => q({0} míle),
						'two' => q({0} mhíle),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'one' => q({0} mhíle),
						'other' => q({0} míle),
						'two' => q({0} mhíle),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} mhíle Lochlannacha),
						'many' => q({0} míle Lochlannacha),
						'name' => q(míle Lochlannach),
						'one' => q({0} mhíle Lochlannach),
						'other' => q({0} míle Lochlannach),
						'two' => q({0} mhíle Lochlannacha),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} mhíle Lochlannacha),
						'many' => q({0} míle Lochlannacha),
						'name' => q(míle Lochlannach),
						'one' => q({0} mhíle Lochlannach),
						'other' => q({0} míle Lochlannach),
						'two' => q({0} mhíle Lochlannacha),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} mhilliméadar),
						'many' => q({0} milliméadar),
						'name' => q(milliméadair),
						'one' => q({0} mhilliméadar),
						'other' => q({0} milliméadar),
						'two' => q({0} mhilliméadar),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} mhilliméadar),
						'many' => q({0} milliméadar),
						'name' => q(milliméadair),
						'one' => q({0} mhilliméadar),
						'other' => q({0} milliméadar),
						'two' => q({0} mhilliméadar),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nanaiméadar),
						'many' => q({0} nanaiméadar),
						'name' => q(nanaiméadair),
						'one' => q({0} nanaiméadar),
						'other' => q({0} nanaiméadar),
						'two' => q({0} nanaiméadar),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nanaiméadar),
						'many' => q({0} nanaiméadar),
						'name' => q(nanaiméadair),
						'one' => q({0} nanaiméadar),
						'other' => q({0} nanaiméadar),
						'two' => q({0} nanaiméadar),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} muirmh.),
						'many' => q({0} muirmh.),
						'one' => q({0} mhuirmhíle),
						'other' => q({0} muirmh.),
						'two' => q({0} muirmh.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} muirmh.),
						'many' => q({0} muirmh.),
						'one' => q({0} mhuirmhíle),
						'other' => q({0} muirmh.),
						'two' => q({0} muirmh.),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} pharsoic),
						'many' => q({0} bparsoic),
						'name' => q(parsoiceanna),
						'one' => q({0} pharsoic),
						'other' => q({0} parsoic),
						'two' => q({0} pharsoic),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} pharsoic),
						'many' => q({0} bparsoic),
						'name' => q(parsoiceanna),
						'one' => q({0} pharsoic),
						'other' => q({0} parsoic),
						'two' => q({0} pharsoic),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} phiciméadar),
						'many' => q({0} bpiciméadar),
						'name' => q(piciméadair),
						'one' => q({0} phiciméadar),
						'other' => q({0} piciméadar),
						'two' => q({0} phiciméadar),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} phiciméadar),
						'many' => q({0} bpiciméadar),
						'name' => q(piciméadair),
						'one' => q({0} phiciméadar),
						'other' => q({0} piciméadar),
						'two' => q({0} phiciméadar),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} ghriangha),
						'many' => q({0} R☉),
						'one' => q({0} ghriangha),
						'other' => q({0} griangha),
						'two' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} ghriangha),
						'many' => q({0} R☉),
						'one' => q({0} ghriangha),
						'other' => q({0} griangha),
						'two' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} shlat),
						'many' => q({0} slat),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} shlat),
						'many' => q({0} slat),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} chaindéile),
						'many' => q({0} gcaindéile),
						'name' => q(caindéile),
						'one' => q({0} chaindéile),
						'other' => q({0} caindéile),
						'two' => q({0} chaindéile),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} chaindéile),
						'many' => q({0} gcaindéile),
						'name' => q(caindéile),
						'one' => q({0} chaindéile),
						'other' => q({0} caindéile),
						'two' => q({0} chaindéile),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lúman),
						'many' => q({0} lúman),
						'name' => q(lúman),
						'one' => q({0} lúman),
						'other' => q({0} lúman),
						'two' => q({0} lúman),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lúman),
						'many' => q({0} lúman),
						'name' => q(lúman),
						'one' => q({0} lúman),
						'other' => q({0} lúman),
						'two' => q({0} lúman),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lucsa),
						'many' => q({0} lucsa),
						'one' => q({0} lucsa),
						'other' => q({0} lucsa),
						'two' => q({0} lucsa),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lucsa),
						'many' => q({0} lucsa),
						'one' => q({0} lucsa),
						'other' => q({0} lucsa),
						'two' => q({0} lucsa),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'name' => q(grianlonrachas),
						'one' => q({0} ghrianlonrachas),
						'other' => q({0} grianlonrachas),
						'two' => q({0} ghrianlonrachas),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} L☉),
						'many' => q({0} L☉),
						'name' => q(grianlonrachas),
						'one' => q({0} ghrianlonrachas),
						'other' => q({0} grianlonrachas),
						'two' => q({0} ghrianlonrachas),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} charat),
						'many' => q({0} gcarat),
						'one' => q({0} charat),
						'other' => q({0} carat),
						'two' => q({0} charat),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} charat),
						'many' => q({0} gcarat),
						'one' => q({0} charat),
						'other' => q({0} carat),
						'two' => q({0} charat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} dhaltún),
						'many' => q({0} ndaltún),
						'one' => q({0} daltún),
						'other' => q({0} daltún),
						'two' => q({0} dhaltún),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} dhaltún),
						'many' => q({0} ndaltún),
						'one' => q({0} daltún),
						'other' => q({0} daltún),
						'two' => q({0} dhaltún),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} mhais an Domhain),
						'many' => q({0} mais an Domhain),
						'one' => q(mais an Domhain),
						'other' => q({0} mais an Domhain),
						'two' => q({0} mhais an Domhain),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} mhais an Domhain),
						'many' => q({0} mais an Domhain),
						'one' => q(mais an Domhain),
						'other' => q({0} mais an Domhain),
						'two' => q({0} mhais an Domhain),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} ghráinne),
						'many' => q({0} ngráinne),
						'one' => q({0} ghráinne),
						'other' => q({0} gráinne),
						'two' => q({0} ghráinne),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} ghráinne),
						'many' => q({0} ngráinne),
						'one' => q({0} ghráinne),
						'other' => q({0} gráinne),
						'two' => q({0} ghráinne),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} ghram),
						'many' => q({0} ngram),
						'one' => q({0} ghram),
						'other' => q({0} gram),
						'per' => q({0} sa ghram),
						'two' => q({0} ghram),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} ghram),
						'many' => q({0} ngram),
						'one' => q({0} ghram),
						'other' => q({0} gram),
						'per' => q({0} sa ghram),
						'two' => q({0} ghram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} chileagram),
						'many' => q({0} gcileagram),
						'name' => q(cileagraim),
						'one' => q({0} chileagram),
						'other' => q({0} cileagram),
						'per' => q({0} sa chileagram),
						'two' => q({0} chileagram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} chileagram),
						'many' => q({0} gcileagram),
						'name' => q(cileagraim),
						'one' => q({0} chileagram),
						'other' => q({0} cileagram),
						'per' => q({0} sa chileagram),
						'two' => q({0} chileagram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} mhicreagram),
						'many' => q({0} micreagram),
						'name' => q(micreagraim),
						'one' => q({0} mhicreagram),
						'other' => q({0} micreagram),
						'two' => q({0} mhicreagram),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} mhicreagram),
						'many' => q({0} micreagram),
						'name' => q(micreagraim),
						'one' => q({0} mhicreagram),
						'other' => q({0} micreagram),
						'two' => q({0} mhicreagram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} mhilleagram),
						'many' => q({0} milleagram),
						'name' => q(milleagraim),
						'one' => q({0} mhilleagram),
						'other' => q({0} milleagram),
						'two' => q({0} mhilleagram),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} mhilleagram),
						'many' => q({0} milleagram),
						'name' => q(milleagraim),
						'one' => q({0} mhilleagram),
						'other' => q({0} milleagram),
						'two' => q({0} mhilleagram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(unsaí),
						'per' => q({0} san unsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(unsaí),
						'per' => q({0} san unsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} unsa troí),
						'many' => q({0} n-unsa troí),
						'name' => q(unsaí troí),
						'one' => q({0} unsa troí),
						'other' => q({0} unsa troí),
						'two' => q({0} unsa troí),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} unsa troí),
						'many' => q({0} n-unsa troí),
						'name' => q(unsaí troí),
						'one' => q({0} unsa troí),
						'other' => q({0} unsa troí),
						'two' => q({0} unsa troí),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} sa phunt),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} sa phunt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} mhais ghréine),
						'many' => q({0} mais ghréine),
						'one' => q({0} mhais ghréine),
						'other' => q({0} mais ghréine),
						'two' => q({0} mhais ghréine),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} mhais ghréine),
						'many' => q({0} mais ghréine),
						'one' => q({0} mhais ghréine),
						'other' => q({0} mais ghréine),
						'two' => q({0} mhais ghréine),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} chloch),
						'many' => q({0} gcloch),
						'one' => q({0} chloch),
						'other' => q({0} cloch),
						'two' => q({0} chloch),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} chloch),
						'many' => q({0} gcloch),
						'one' => q({0} chloch),
						'other' => q({0} cloch),
						'two' => q({0} chloch),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} thonna ghearra),
						'many' => q({0} dtonna ghearra),
						'one' => q({0} tonna gearr),
						'other' => q({0} tonna gearr),
						'two' => q({0} thonna ghearra),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} thonna ghearra),
						'many' => q({0} dtonna ghearra),
						'one' => q({0} tonna gearr),
						'other' => q({0} tonna gearr),
						'two' => q({0} thonna ghearra),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} thonna mhéadracha),
						'many' => q({0} dtonna mhéadracha),
						'name' => q(tonnaí méadracha),
						'one' => q({0} tonna méadrach),
						'other' => q({0} tonna méadrach),
						'two' => q({0} thonna mhéadracha),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} thonna mhéadracha),
						'many' => q({0} dtonna mhéadracha),
						'name' => q(tonnaí méadracha),
						'one' => q({0} tonna méadrach),
						'other' => q({0} tonna méadrach),
						'two' => q({0} thonna mhéadracha),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} sa {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} sa {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} ghigeavata),
						'many' => q({0} ngigeavata),
						'name' => q(gigeavatanna),
						'one' => q({0} ghigeavata),
						'other' => q({0} gigeavata),
						'two' => q({0} ghigeavata),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} ghigeavata),
						'many' => q({0} ngigeavata),
						'name' => q(gigeavatanna),
						'one' => q({0} ghigeavata),
						'other' => q({0} gigeavata),
						'two' => q({0} ghigeavata),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} each-chumhacht),
						'many' => q({0} n-each-chumhacht),
						'name' => q(each-chumhacht),
						'one' => q({0} each-chumhacht),
						'other' => q({0} each-chumhacht),
						'two' => q({0} each-chumhacht),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} each-chumhacht),
						'many' => q({0} n-each-chumhacht),
						'name' => q(each-chumhacht),
						'one' => q({0} each-chumhacht),
						'other' => q({0} each-chumhacht),
						'two' => q({0} each-chumhacht),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} chileavata),
						'many' => q({0} gcileavata),
						'name' => q(cileavatanna),
						'one' => q({0} chileavata),
						'other' => q({0} cileavata),
						'two' => q({0} chileavata),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} chileavata),
						'many' => q({0} gcileavata),
						'name' => q(cileavatanna),
						'one' => q({0} chileavata),
						'other' => q({0} cileavata),
						'two' => q({0} chileavata),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} mheigeavata),
						'many' => q({0} meigeavata),
						'name' => q(meigeavatanna),
						'one' => q({0} mheigeavata),
						'other' => q({0} meigeavata),
						'two' => q({0} mheigeavata),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} mheigeavata),
						'many' => q({0} meigeavata),
						'name' => q(meigeavatanna),
						'one' => q({0} mheigeavata),
						'other' => q({0} meigeavata),
						'two' => q({0} mheigeavata),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} mhilleavata),
						'many' => q({0} milleavata),
						'name' => q(milleavatanna),
						'one' => q({0} mhilleavata),
						'other' => q({0} milleavata),
						'two' => q({0} mhilleavata),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} mhilleavata),
						'many' => q({0} milleavata),
						'name' => q(milleavatanna),
						'one' => q({0} mhilleavata),
						'other' => q({0} milleavata),
						'two' => q({0} mhilleavata),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} vata),
						'many' => q({0} vata),
						'name' => q(vatanna),
						'one' => q({0} vata),
						'other' => q({0} vata),
						'two' => q({0} vata),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} vata),
						'many' => q({0} vata),
						'name' => q(vatanna),
						'one' => q({0} vata),
						'other' => q({0} vata),
						'two' => q({0} vata),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0} chearnacha),
						'many' => q({0} chearnacha),
						'one' => q({0} cearnaithe),
						'other' => q({0} chearnaithe),
						'two' => q({0} chearnacha),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0} chearnacha),
						'many' => q({0} chearnacha),
						'one' => q({0} cearnaithe),
						'other' => q({0} chearnaithe),
						'two' => q({0} chearnacha),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0} chiúbacha),
						'many' => q({0} chiúbacha),
						'one' => q({0} ciúbach),
						'other' => q({0} ciúbach),
						'two' => q({0} chiúbacha),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0} chiúbacha),
						'many' => q({0} chiúbacha),
						'one' => q({0} ciúbach),
						'other' => q({0} ciúbach),
						'two' => q({0} chiúbacha),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atmaisféar),
						'many' => q({0} n-atmaisféar),
						'name' => q(atmaisféir),
						'one' => q({0} atmaisféar),
						'other' => q({0} atmaisféar),
						'two' => q({0} atmaisféar),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atmaisféar),
						'many' => q({0} n-atmaisféar),
						'name' => q(atmaisféir),
						'one' => q({0} atmaisféar),
						'other' => q({0} atmaisféar),
						'two' => q({0} atmaisféar),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bair),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bair),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} heicteapascal),
						'many' => q({0} heicteapascal),
						'name' => q(heicteapascail),
						'one' => q({0} heicteapascal),
						'other' => q({0} heicteapascal),
						'two' => q({0} heicteapascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} heicteapascal),
						'many' => q({0} heicteapascal),
						'name' => q(heicteapascail),
						'one' => q({0} heicteapascal),
						'other' => q({0} heicteapascal),
						'two' => q({0} heicteapascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} orlach mearcair),
						'many' => q({0} n-orlach mearcair),
						'name' => q(orlaí mearcair),
						'one' => q({0} orlach mearcair),
						'other' => q({0} orlach mearcair),
						'two' => q({0} orlach mearcair),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} orlach mearcair),
						'many' => q({0} n-orlach mearcair),
						'name' => q(orlaí mearcair),
						'one' => q({0} orlach mearcair),
						'other' => q({0} orlach mearcair),
						'two' => q({0} orlach mearcair),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kPa),
						'many' => q({0} kPa),
						'name' => q(cileapascail),
						'one' => q({0} chileapascal),
						'other' => q({0} kPa),
						'two' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kPa),
						'many' => q({0} kPa),
						'name' => q(cileapascail),
						'one' => q({0} chileapascal),
						'other' => q({0} kPa),
						'two' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} MPa),
						'many' => q({0} MPa),
						'name' => q(meigeapascail),
						'one' => q({0} mheigeapascal),
						'other' => q({0} meigeapascal),
						'two' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} MPa),
						'many' => q({0} MPa),
						'name' => q(meigeapascail),
						'one' => q({0} mheigeapascal),
						'other' => q({0} meigeapascal),
						'two' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mhilleabar),
						'many' => q({0} milleabar),
						'name' => q(milleabair),
						'one' => q({0} mhilleabar),
						'other' => q({0} milleabar),
						'two' => q({0} mhilleabar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mhilleabar),
						'many' => q({0} milleabar),
						'name' => q(milleabair),
						'one' => q({0} mhilleabar),
						'other' => q({0} milleabar),
						'two' => q({0} mhilleabar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mhilliméadar mearcair),
						'many' => q({0} milliméadar mearcair),
						'name' => q(milliméadair mearcair),
						'one' => q({0} mhilliméadar mearcair),
						'other' => q({0} milliméadar mearcair),
						'two' => q({0} mhilliméadar mearcair),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mhilliméadar mearcair),
						'many' => q({0} milliméadar mearcair),
						'name' => q(milliméadair mearcair),
						'one' => q({0} mhilliméadar mearcair),
						'other' => q({0} milliméadar mearcair),
						'two' => q({0} mhilliméadar mearcair),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} phascal),
						'many' => q({0} bpascal),
						'name' => q(Pascail),
						'one' => q({0} phascal),
						'other' => q({0} pascal),
						'two' => q({0} phascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} phascal),
						'many' => q({0} bpascal),
						'name' => q(Pascail),
						'one' => q({0} phascal),
						'other' => q({0} pascal),
						'two' => q({0} phascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} phunt san orlach cearnach),
						'many' => q({0} bpunt san orlach cearnach),
						'name' => q(puint san orlach cearnach),
						'one' => q({0} phunt san orlach cearnach),
						'other' => q({0} punt san orlach cearnach),
						'two' => q({0} phunt san orlach cearnach),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} phunt san orlach cearnach),
						'many' => q({0} bpunt san orlach cearnach),
						'name' => q(puint san orlach cearnach),
						'one' => q({0} phunt san orlach cearnach),
						'other' => q({0} punt san orlach cearnach),
						'two' => q({0} phunt san orlach cearnach),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} mrml/u),
						'many' => q({0} mrml/u),
						'one' => q({0} mhuirmh/u),
						'other' => q({0} mrml/u),
						'two' => q({0} muirmh/u),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} mrml/u),
						'many' => q({0} mrml/u),
						'one' => q({0} mhuirmh/u),
						'other' => q({0} mrml/u),
						'two' => q({0} muirmh/u),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} chéim Celsius),
						'many' => q({0} gcéim Celsius),
						'name' => q(céimeanna Celsius),
						'one' => q({0} chéim Celsius),
						'other' => q({0} céim Celsius),
						'two' => q({0} chéim Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} chéim Celsius),
						'many' => q({0} gcéim Celsius),
						'name' => q(céimeanna Celsius),
						'one' => q({0} chéim Celsius),
						'other' => q({0} céim Celsius),
						'two' => q({0} chéim Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} chéim Fahrenheit),
						'many' => q({0} gcéim Fahrenheit),
						'name' => q(céimeanna Fahrenheit),
						'one' => q({0} chéim Fahrenheit),
						'other' => q({0} céim Fahrenheit),
						'two' => q({0} chéim Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} chéim Fahrenheit),
						'many' => q({0} gcéim Fahrenheit),
						'name' => q(céimeanna Fahrenheit),
						'one' => q({0} chéim Fahrenheit),
						'other' => q({0} céim Fahrenheit),
						'two' => q({0} chéim Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} chéim cheilvin),
						'many' => q({0} gcéim cheilvin),
						'name' => q(céimeanna ceilvin),
						'one' => q({0} chéim cheilvin),
						'other' => q({0} céim cheilvin),
						'two' => q({0} chéim cheilvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} chéim cheilvin),
						'many' => q({0} gcéim cheilvin),
						'name' => q(céimeanna ceilvin),
						'one' => q({0} chéim cheilvin),
						'other' => q({0} céim cheilvin),
						'two' => q({0} chéim cheilvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'name' => q(méadar niútain),
						'one' => q({0} mhéadar niútain),
						'other' => q({0} méadar niútain),
						'two' => q({0} mhéadar niútain),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} N⋅m),
						'many' => q({0} N⋅m),
						'name' => q(méadar niútain),
						'one' => q({0} mhéadar niútain),
						'other' => q({0} méadar niútain),
						'two' => q({0} mhéadar niútain),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'name' => q(punt-troigh),
						'one' => q({0} punt-troigh),
						'other' => q({0} punt-troigh),
						'two' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} lbf⋅ft),
						'many' => q({0} lbf⋅ft),
						'name' => q(punt-troigh),
						'one' => q({0} punt-troigh),
						'other' => q({0} punt-troigh),
						'two' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} acra-troigh),
						'many' => q({0} n-acra-troigh),
						'name' => q(acra-troithe),
						'one' => q({0} acra-troigh),
						'other' => q({0} acra-troigh),
						'two' => q({0} acra-troigh),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} acra-troigh),
						'many' => q({0} n-acra-troigh),
						'name' => q(acra-troithe),
						'one' => q({0} acra-troigh),
						'other' => q({0} acra-troigh),
						'two' => q({0} acra-troigh),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} bbl),
						'many' => q({0} bbl),
						'name' => q(bairillí),
						'one' => q({0} bairille),
						'other' => q({0} bbl),
						'two' => q({0} bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} bbl),
						'many' => q({0} bbl),
						'name' => q(bairillí),
						'one' => q({0} bairille),
						'other' => q({0} bbl),
						'two' => q({0} bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bhuiséal),
						'many' => q({0} mbuiséal),
						'one' => q({0} bhuiséal),
						'other' => q({0} buiséal),
						'two' => q({0} bhuiséal),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bhuiséal),
						'many' => q({0} mbuiséal),
						'one' => q({0} bhuiséal),
						'other' => q({0} buiséal),
						'two' => q({0} bhuiséal),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cheintilítear),
						'many' => q({0} gceintilítear),
						'name' => q(ceintilítir),
						'one' => q({0} cheintilítear),
						'other' => q({0} ceintilítear),
						'two' => q({0} cheintilítear),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cheintilítear),
						'many' => q({0} gceintilítear),
						'name' => q(ceintilítir),
						'one' => q({0} cheintilítear),
						'other' => q({0} ceintilítear),
						'two' => q({0} cheintilítear),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} cheintiméadar chiúbacha),
						'many' => q({0} gceintiméadar chiúbacha),
						'name' => q(ceintiméadair chiúbacha),
						'one' => q({0} cheintiméadar ciúbach),
						'other' => q({0} ceintiméadar ciúbach),
						'per' => q({0} sa cheintiméadar ciúbach),
						'two' => q({0} cheintiméadar chiúbacha),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} cheintiméadar chiúbacha),
						'many' => q({0} gceintiméadar chiúbacha),
						'name' => q(ceintiméadair chiúbacha),
						'one' => q({0} cheintiméadar ciúbach),
						'other' => q({0} ceintiméadar ciúbach),
						'per' => q({0} sa cheintiméadar ciúbach),
						'two' => q({0} cheintiméadar chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} throigh chiúbacha),
						'many' => q({0} dtroigh chiúbacha),
						'name' => q(troithe ciúbacha),
						'one' => q({0} troigh chiúbach),
						'other' => q({0} troigh chiúbach),
						'two' => q({0} throigh chiúbacha),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} throigh chiúbacha),
						'many' => q({0} dtroigh chiúbacha),
						'name' => q(troithe ciúbacha),
						'one' => q({0} troigh chiúbach),
						'other' => q({0} troigh chiúbach),
						'two' => q({0} throigh chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} orlach chiúbacha),
						'many' => q({0} n-orlach chiúbacha),
						'name' => q(orlaí ciúbacha),
						'one' => q({0} orlach ciúbach),
						'other' => q({0} orlach ciúbach),
						'two' => q({0} orlach chiúbacha),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} orlach chiúbacha),
						'many' => q({0} n-orlach chiúbacha),
						'name' => q(orlaí ciúbacha),
						'one' => q({0} orlach ciúbach),
						'other' => q({0} orlach ciúbach),
						'two' => q({0} orlach chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} chiliméadar chiúbacha),
						'many' => q({0} gciliméadar chiúbacha),
						'name' => q(ciliméadair chiúbacha),
						'one' => q({0} chiliméadar ciúbach),
						'other' => q({0} ciliméadar ciúbach),
						'two' => q({0} chiliméadar chiúbacha),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} chiliméadar chiúbacha),
						'many' => q({0} gciliméadar chiúbacha),
						'name' => q(ciliméadair chiúbacha),
						'one' => q({0} chiliméadar ciúbach),
						'other' => q({0} ciliméadar ciúbach),
						'two' => q({0} chiliméadar chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} mhéadar chiúbacha),
						'many' => q({0} méadar chiúbacha),
						'name' => q(méadair chiúbacha),
						'one' => q({0} mhéadar ciúbach),
						'other' => q({0} méadar ciúbach),
						'per' => q({0} sa mhéadar ciúbach),
						'two' => q({0} mhéadar chiúbacha),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} mhéadar chiúbacha),
						'many' => q({0} méadar chiúbacha),
						'name' => q(méadair chiúbacha),
						'one' => q({0} mhéadar ciúbach),
						'other' => q({0} méadar ciúbach),
						'per' => q({0} sa mhéadar ciúbach),
						'two' => q({0} mhéadar chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mhíle chiúbacha),
						'many' => q({0} míle chiúbacha),
						'name' => q(mílte ciúbacha),
						'one' => q({0} mhíle ciúbach),
						'other' => q({0} míle ciúbach),
						'two' => q({0} mhíle chiúbacha),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mhíle chiúbacha),
						'many' => q({0} míle chiúbacha),
						'name' => q(mílte ciúbacha),
						'one' => q({0} mhíle ciúbach),
						'other' => q({0} míle ciúbach),
						'two' => q({0} mhíle chiúbacha),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} shlat chiúbacha),
						'many' => q({0} slat chiúbacha),
						'name' => q(slata ciúbacha),
						'one' => q({0} slat chiúbach),
						'other' => q({0} slat chiúbach),
						'two' => q({0} shlat chiúbacha),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} shlat chiúbacha),
						'many' => q({0} slat chiúbacha),
						'name' => q(slata ciúbacha),
						'one' => q({0} slat chiúbach),
						'other' => q({0} slat chiúbach),
						'two' => q({0} shlat chiúbacha),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'one' => q({0} chupán),
						'other' => q({0} cupán),
						'two' => q({0} c),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'one' => q({0} chupán),
						'other' => q({0} cupán),
						'two' => q({0} c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} chupán mhéadracha),
						'many' => q({0} gcupán mhéadracha),
						'name' => q(cupáin mhéadracha),
						'one' => q({0} chupán méadrach),
						'other' => q({0} cupán méadrach),
						'two' => q({0} chupán mhéadracha),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} chupán mhéadracha),
						'many' => q({0} gcupán mhéadracha),
						'name' => q(cupáin mhéadracha),
						'one' => q({0} chupán méadrach),
						'other' => q({0} cupán méadrach),
						'two' => q({0} chupán mhéadracha),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dheicilítear),
						'many' => q({0} ndeicilítear),
						'name' => q(deicilítir),
						'one' => q({0} deicilítear),
						'other' => q({0} deicilítear),
						'two' => q({0} dheicilítear),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dheicilítear),
						'many' => q({0} ndeicilítear),
						'name' => q(deicilítir),
						'one' => q({0} deicilítear),
						'other' => q({0} deicilítear),
						'two' => q({0} dheicilítear),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} spúnóg mhilseoige),
						'many' => q({0} spúnóg mhilseoige),
						'name' => q(spúnóga milseoige),
						'one' => q({0} spúnóg mhilseoige),
						'other' => q({0} spúnóg mhilseoige),
						'two' => q({0} spúnóg mhilseoige),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} spúnóg mhilseoige),
						'many' => q({0} spúnóg mhilseoige),
						'name' => q(spúnóga milseoige),
						'one' => q({0} spúnóg mhilseoige),
						'other' => q({0} spúnóg mhilseoige),
						'two' => q({0} spúnóg mhilseoige),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} spúnóg mhilseoige impiriúla),
						'many' => q({0} spúnóg mhilseoige impiriúla),
						'name' => q(spúnóga milseoige impiriúla),
						'one' => q({0} spúnóg mhilseoige impiriúil),
						'other' => q({0} spúnóg mhilseoige impiriúol),
						'two' => q({0} spúnóg mhilseoige impiriúla),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} spúnóg mhilseoige impiriúla),
						'many' => q({0} spúnóg mhilseoige impiriúla),
						'name' => q(spúnóga milseoige impiriúla),
						'one' => q({0} spúnóg mhilseoige impiriúil),
						'other' => q({0} spúnóg mhilseoige impiriúol),
						'two' => q({0} spúnóg mhilseoige impiriúla),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dhram leachtacha),
						'many' => q({0} ndram leachtacha),
						'name' => q(dram leachtach),
						'one' => q({0} dram leachtach),
						'other' => q({0} dram leachtach),
						'two' => q({0} dhram leachtacha),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dhram leachtacha),
						'many' => q({0} ndram leachtacha),
						'name' => q(dram leachtach),
						'one' => q({0} dram leachtach),
						'other' => q({0} dram leachtach),
						'two' => q({0} dhram leachtacha),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} unsa leachtacha),
						'many' => q({0} n-unsa leachtacha),
						'name' => q(unsaí leachtacha),
						'one' => q({0} unsa leachtach),
						'other' => q({0} unsa leachtach),
						'two' => q({0} unsa leachtacha),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} unsa leachtacha),
						'many' => q({0} n-unsa leachtacha),
						'name' => q(unsaí leachtacha),
						'one' => q({0} unsa leachtach),
						'other' => q({0} unsa leachtach),
						'two' => q({0} unsa leachtacha),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'name' => q(Unsaí leachtacha impiriúla),
						'one' => q({0} unsa leachtach impiriúil),
						'other' => q({0} fl oz Imp.),
						'two' => q({0} unsa leachtacha impiriúla),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz Imp.),
						'many' => q({0} fl oz Imp.),
						'name' => q(Unsaí leachtacha impiriúla),
						'one' => q({0} unsa leachtach impiriúil),
						'other' => q({0} fl oz Imp.),
						'two' => q({0} unsa leachtacha impiriúla),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} ghalún),
						'many' => q({0} ngalún),
						'one' => q({0} ghalún),
						'other' => q({0} galún),
						'per' => q({0} sa ghalún),
						'two' => q({0} ghalún),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} ghalún),
						'many' => q({0} ngalún),
						'one' => q({0} ghalún),
						'other' => q({0} galún),
						'per' => q({0} sa ghalún),
						'two' => q({0} ghalún),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} ghalún impiriúla),
						'many' => q({0} ngalún impiriúla),
						'name' => q(galúin impiriúla),
						'one' => q({0} ghalún impiriúil),
						'other' => q({0} galún impiriúil),
						'per' => q({0} sa ghalún impiriúil),
						'two' => q({0} ghalún impiriúla),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} ghalún impiriúla),
						'many' => q({0} ngalún impiriúla),
						'name' => q(galúin impiriúla),
						'one' => q({0} ghalún impiriúil),
						'other' => q({0} galún impiriúil),
						'per' => q({0} sa ghalún impiriúil),
						'two' => q({0} ghalún impiriúla),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} heictilítear),
						'many' => q({0} heictilítear),
						'name' => q(heictilítir),
						'one' => q({0} heictilítear),
						'other' => q({0} heictilítear),
						'two' => q({0} heictilítear),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} heictilítear),
						'many' => q({0} heictilítear),
						'name' => q(heictilítir),
						'one' => q({0} heictilítear),
						'other' => q({0} heictilítear),
						'two' => q({0} heictilítear),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} lítear),
						'many' => q({0} lítear),
						'one' => q({0} lítear),
						'other' => q({0} lítear),
						'per' => q({0} sa lítear),
						'two' => q({0} lítear),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} lítear),
						'many' => q({0} lítear),
						'one' => q({0} lítear),
						'other' => q({0} lítear),
						'per' => q({0} sa lítear),
						'two' => q({0} lítear),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} mheigilítear),
						'many' => q({0} meigilítear),
						'name' => q(meigilítir),
						'one' => q({0} mheigilítear),
						'other' => q({0} meigilítear),
						'two' => q({0} mheigilítear),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} mheigilítear),
						'many' => q({0} meigilítear),
						'name' => q(meigilítir),
						'one' => q({0} mheigilítear),
						'other' => q({0} meigilítear),
						'two' => q({0} mheigilítear),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mhillilítear),
						'many' => q({0} millilítear),
						'name' => q(millilítir),
						'one' => q({0} mhillilítear),
						'other' => q({0} millilítear),
						'two' => q({0} mhillilítear),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mhillilítear),
						'many' => q({0} millilítear),
						'name' => q(millilítir),
						'one' => q({0} mhillilítear),
						'other' => q({0} millilítear),
						'two' => q({0} mhillilítear),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'one' => q({0} phionta),
						'other' => q({0} pionta),
						'two' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'one' => q({0} phionta),
						'other' => q({0} pionta),
						'two' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} phionta mhéadracha),
						'many' => q({0} bpionta mhéadracha),
						'name' => q(piontaí méadracha),
						'one' => q({0} phionta méadrach),
						'other' => q({0} pionta méadrach),
						'two' => q({0} phionta mhéadracha),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} phionta mhéadracha),
						'many' => q({0} bpionta mhéadracha),
						'name' => q(piontaí méadracha),
						'one' => q({0} phionta méadrach),
						'other' => q({0} pionta méadrach),
						'two' => q({0} phionta mhéadracha),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(spúnóga boird),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(spúnóga boird),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} thaespúnóg),
						'many' => q({0} dtaespúnóg),
						'name' => q(taespúnóga),
						'one' => q({0} taespúnóg),
						'other' => q({0} taespúnóg),
						'two' => q({0} thaespúnóg),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} thaespúnóg),
						'many' => q({0} dtaespúnóg),
						'name' => q(taespúnóga),
						'one' => q({0} taespúnóg),
						'other' => q({0} taespúnóg),
						'two' => q({0} thaespúnóg),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(nóim. stua),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(nóim. stua),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(céim),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(céim),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0}raid),
						'many' => q({0}raid),
						'name' => q(raid),
						'one' => q({0}raid),
						'other' => q({0}raid),
						'two' => q({0}raid),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0}raid),
						'many' => q({0}raid),
						'name' => q(raid),
						'one' => q({0}raid),
						'other' => q({0}raid),
						'two' => q({0}raid),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0}kt),
						'many' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0}kt),
						'many' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
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
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0}l/100km),
						'many' => q({0}l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
						'two' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0}l/100km),
						'many' => q({0}l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
						'two' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0}l/km),
						'many' => q({0}l/km),
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
						'two' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0}l/km),
						'many' => q({0}l/km),
						'name' => q(l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
						'two' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0}míle/g),
						'many' => q({0}míle/g),
						'one' => q({0}míle/g),
						'other' => q({0}míle/g),
						'two' => q({0}míle/g),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0}míle/g),
						'many' => q({0}míle/g),
						'one' => q({0}míle/g),
						'other' => q({0}míle/g),
						'two' => q({0}míle/g),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0}m/gRA),
						'many' => q({0}m/gRA),
						'one' => q({0}m/gRA),
						'other' => q({0}m/gRA),
						'two' => q({0}m/gRA),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0}m/gRA),
						'many' => q({0}m/gRA),
						'one' => q({0}m/gRA),
						'other' => q({0}m/gRA),
						'two' => q({0}m/gRA),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} ghiot.),
						'many' => q({0} ngiot.),
						'one' => q({0} ghiot.),
						'other' => q({0} giot.),
						'two' => q({0} ghiot.),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} ghiot.),
						'many' => q({0} ngiot.),
						'one' => q({0} ghiot.),
						'other' => q({0} giot.),
						'two' => q({0} ghiot.),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0}B),
						'many' => q({0}B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0}B),
						'many' => q({0}B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0}Gb),
						'many' => q({0}Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0}Gb),
						'many' => q({0}Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0}GB),
						'many' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0}GB),
						'many' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0}kb),
						'many' => q({0}kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0}kb),
						'many' => q({0}kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0}kB),
						'many' => q({0}kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0}kB),
						'many' => q({0}kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0}Mb),
						'many' => q({0}Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
						'two' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0}Mb),
						'many' => q({0}Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
						'two' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0}MB),
						'many' => q({0}MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0}MB),
						'many' => q({0}MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0}Tb),
						'many' => q({0}Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
						'two' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0}Tb),
						'many' => q({0}Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
						'two' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0}TB),
						'many' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0}TB),
						'many' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0}μs),
						'many' => q({0}μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0}μs),
						'many' => q({0}μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} nóim),
						'many' => q({0}n),
						'one' => q({0} nóim),
						'other' => q({0} nóim),
						'two' => q({0} nóim),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} nóim),
						'many' => q({0}n),
						'one' => q({0} nóim),
						'other' => q({0} nóim),
						'two' => q({0} nóim),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0} m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0} m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0}ns),
						'many' => q({0}ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0}ns),
						'many' => q({0}ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0}oí),
						'many' => q({0}oí),
						'name' => q(oí),
						'one' => q({0}oí),
						'other' => q({0}oí),
						'per' => q({0}/oíche),
						'two' => q({0}oí),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0}oí),
						'many' => q({0}oí),
						'name' => q(oí),
						'one' => q({0}oí),
						'other' => q({0}oí),
						'per' => q({0}/oíche),
						'two' => q({0}oí),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'one' => q({0} ctú),
						'other' => q({0} ctú),
						'two' => q({0} cna),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'one' => q({0} ctú),
						'other' => q({0} ctú),
						'two' => q({0} cna),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0}/bl),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0}/bl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'name' => q(Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'name' => q(volta),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'name' => q(volta),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0}Cal),
						'many' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0}Cal),
						'many' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0}kJ),
						'many' => q({0}kJ),
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0}kJ),
						'many' => q({0}kJ),
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0}kWh),
						'many' => q({0}kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0}kWh),
						'many' => q({0}kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} eim),
						'many' => q({0} n-eim),
						'one' => q({0} eim),
						'other' => q({0} eim),
						'two' => q({0} eim),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} eim),
						'many' => q({0} n-eim),
						'one' => q({0} eim),
						'other' => q({0} eim),
						'two' => q({0} eim),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(tr),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(tr),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} or.),
						'many' => q({0} n-or.),
						'one' => q({0} or.),
						'other' => q({0} or.),
						'two' => q({0} or.),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} or.),
						'many' => q({0} n-or.),
						'one' => q({0} or.),
						'other' => q({0} or.),
						'two' => q({0} or.),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'one' => q({0}sbh),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'one' => q({0}sbh),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(méadar),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(méadar),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'one' => q({0} mhíle),
						'other' => q({0} míle),
						'two' => q({0} mhíle),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'one' => q({0} mhíle),
						'other' => q({0} míle),
						'two' => q({0} mhíle),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} m lch),
						'many' => q({0} m lch),
						'one' => q({0} m lch),
						'other' => q({0} m lch),
						'two' => q({0} mh lch),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} m lch),
						'many' => q({0} m lch),
						'one' => q({0} m lch),
						'other' => q({0} m lch),
						'two' => q({0} mh lch),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} mhuirmh.),
						'many' => q({0} muirmh.),
						'one' => q({0} mhuirmh.),
						'other' => q({0} muirmh.),
						'two' => q({0} mhuirmh.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} mhuirmh.),
						'many' => q({0} muirmh.),
						'one' => q({0} mhuirmh.),
						'other' => q({0} muirmh.),
						'two' => q({0} mhuirmh.),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0}sl),
						'many' => q({0}sl),
						'name' => q(sl),
						'one' => q({0}sl),
						'other' => q({0}sl),
						'two' => q({0}sl),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0}sl),
						'many' => q({0}sl),
						'name' => q(sl),
						'one' => q({0}sl),
						'other' => q({0}sl),
						'two' => q({0}sl),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'name' => q(carat),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'name' => q(carat),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} ghráinne),
						'many' => q({0} ngráinne),
						'one' => q({0} ghráinne),
						'other' => q({0} gráinne),
						'two' => q({0} ghráinne),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} ghráinne),
						'many' => q({0} ngráinne),
						'one' => q({0} ghráinne),
						'other' => q({0} gráinne),
						'two' => q({0} ghráinne),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'name' => q(gram),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0}kg),
						'many' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0}kg),
						'many' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} unsa t),
						'many' => q({0} unsa t),
						'one' => q({0} unsa t),
						'other' => q({0} unsa t),
						'two' => q({0} unsa t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} unsa t),
						'many' => q({0} unsa t),
						'one' => q({0} unsa t),
						'other' => q({0} unsa t),
						'two' => q({0} unsa t),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(cloch),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(cloch),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0}ec),
						'many' => q({0}ec),
						'one' => q({0}ec),
						'other' => q({0}ec),
						'two' => q({0}ec),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0}ec),
						'many' => q({0}ec),
						'one' => q({0}ec),
						'other' => q({0}ec),
						'two' => q({0}ec),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}″ Hg),
						'many' => q({0}″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
						'two' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}″ Hg),
						'many' => q({0}″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
						'two' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0}mb),
						'many' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0}mb),
						'many' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0}psoc),
						'many' => q({0}psoc),
						'one' => q({0}psoc),
						'other' => q({0}psoc),
						'two' => q({0}psoc),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0}psoc),
						'many' => q({0}psoc),
						'one' => q({0}psoc),
						'other' => q({0}psoc),
						'two' => q({0}psoc),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0}tr³),
						'many' => q({0}tr³),
						'one' => q({0}tr³),
						'other' => q({0}tr³),
						'two' => q({0}tr³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0}tr³),
						'many' => q({0}tr³),
						'one' => q({0}tr³),
						'other' => q({0}tr³),
						'two' => q({0}tr³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0}or³),
						'many' => q({0}or³),
						'name' => q(or³),
						'one' => q({0}or³),
						'other' => q({0}or³),
						'two' => q({0}or³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0}or³),
						'many' => q({0}or³),
						'name' => q(or³),
						'one' => q({0}or³),
						'other' => q({0}or³),
						'two' => q({0}or³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0}sl³),
						'many' => q({0}sl³),
						'name' => q(sl³),
						'one' => q({0}sl³),
						'other' => q({0}sl³),
						'two' => q({0}sl³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0}sl³),
						'many' => q({0}sl³),
						'name' => q(sl³),
						'one' => q({0}sl³),
						'other' => q({0}sl³),
						'two' => q({0}sl³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cupán),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cupán),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0}dl),
						'many' => q({0}dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
						'two' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0}dl),
						'many' => q({0}dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
						'two' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} unsa l.),
						'many' => q({0} unsa l.),
						'one' => q({0} unsa l.),
						'other' => q({0} unsa l.),
						'two' => q({0} unsa l.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} unsa l.),
						'many' => q({0} unsa l.),
						'one' => q({0} unsa l.),
						'other' => q({0} unsa l.),
						'two' => q({0} unsa l.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} ghalIm),
						'many' => q({0} ngalIm),
						'one' => q({0}ghalIm),
						'other' => q({0}galIm),
						'two' => q({0}ghalIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} ghalIm),
						'many' => q({0} ngalIm),
						'one' => q({0}ghalIm),
						'other' => q({0}galIm),
						'two' => q({0}ghalIm),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0}l),
						'many' => q({0}l),
						'one' => q({0}l),
						'other' => q({0}l),
						'two' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0}l),
						'many' => q({0}l),
						'one' => q({0}l),
						'other' => q({0}l),
						'two' => q({0}l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(treo),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(treo),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-fhórsa),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-fhórsa),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(nóiméid stua),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(nóiméid stua),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(soic. stua),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(soic. stua),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(céimeanna),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(céimeanna),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} raid),
						'many' => q({0} raid),
						'name' => q(raidiain),
						'one' => q({0} raid),
						'other' => q({0} raid),
						'two' => q({0} raid),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} raid),
						'many' => q({0} raid),
						'name' => q(raidiain),
						'one' => q({0} raid),
						'other' => q({0} raid),
						'two' => q({0} raid),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} imr),
						'many' => q({0} imr),
						'name' => q(imr),
						'one' => q({0} imr),
						'other' => q({0} imr),
						'two' => q({0} imr),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} imr),
						'many' => q({0} imr),
						'name' => q(imr),
						'one' => q({0} imr),
						'other' => q({0} imr),
						'two' => q({0} imr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acraí),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acraí),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dhunam),
						'many' => q({0} ndunam),
						'name' => q(dunaim),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
						'two' => q({0} dhunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dhunam),
						'many' => q({0} ndunam),
						'name' => q(dunaim),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
						'two' => q({0} dhunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(heicteáir),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(heicteáir),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} tr²),
						'many' => q({0} tr²),
						'name' => q(tr²),
						'one' => q({0} tr²),
						'other' => q({0} tr²),
						'two' => q({0} tr²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} tr²),
						'many' => q({0} tr²),
						'name' => q(tr²),
						'one' => q({0} tr²),
						'other' => q({0} tr²),
						'two' => q({0} tr²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} or²),
						'many' => q({0} or²),
						'name' => q(or²),
						'one' => q({0} or²),
						'other' => q({0} or²),
						'per' => q({0}/or²),
						'two' => q({0} or²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} or²),
						'many' => q({0} or²),
						'name' => q(or²),
						'one' => q({0} or²),
						'other' => q({0} or²),
						'per' => q({0}/or²),
						'two' => q({0} or²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mhíle²),
						'many' => q({0} míle²),
						'name' => q(mílte²),
						'one' => q({0} mhíle²),
						'other' => q({0} míle²),
						'two' => q({0} mhíle²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mhíle²),
						'many' => q({0} míle²),
						'name' => q(mílte²),
						'one' => q({0} mhíle²),
						'other' => q({0} míle²),
						'two' => q({0} mhíle²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} sl²),
						'many' => q({0} sl²),
						'name' => q(slata²),
						'one' => q({0} sl²),
						'other' => q({0} sl²),
						'two' => q({0} sl²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} sl²),
						'many' => q({0} sl²),
						'name' => q(slata²),
						'one' => q({0} sl²),
						'other' => q({0} sl²),
						'two' => q({0} sl²),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milleamól/lítear),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milleamól/lítear),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mhól),
						'many' => q({0} mól),
						'name' => q(mól),
						'one' => q({0} mhól),
						'other' => q({0} mól),
						'two' => q({0} mhól),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mhól),
						'many' => q({0} mól),
						'name' => q(mól),
						'one' => q({0} mhól),
						'other' => q({0} mól),
						'two' => q({0} mhól),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(faoin gcéad),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(faoin gcéad),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(faoin míle),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(faoin míle),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0}/milliún),
						'many' => q({0}/milliún),
						'name' => q(codanna/milliún),
						'one' => q({0}/milliún),
						'other' => q({0}/milliún),
						'two' => q({0}/milliún),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0}/milliún),
						'many' => q({0}/milliún),
						'name' => q(codanna/milliún),
						'one' => q({0}/milliún),
						'other' => q({0}/milliún),
						'two' => q({0}/milliún),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(permeiriad),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(permeiriad),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(lítir/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(lítir/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mhíle/gal),
						'many' => q({0} míle/gal),
						'name' => q(mílte/gal),
						'one' => q({0} mhíle/gal),
						'other' => q({0} míle/gal),
						'two' => q({0} mhíle/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mhíle/gal),
						'many' => q({0} míle/gal),
						'name' => q(mílte/gal),
						'one' => q({0} mhíle/gal),
						'other' => q({0} míle/gal),
						'two' => q({0} mhíle/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} msg imp),
						'many' => q({0} msg imp),
						'name' => q(mílte/gal. imp.),
						'one' => q({0} msg imp),
						'other' => q({0} msg imp),
						'two' => q({0} msg imp),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} msg imp),
						'many' => q({0} msg imp),
						'name' => q(mílte/gal. imp.),
						'one' => q({0} msg imp),
						'other' => q({0} msg imp),
						'two' => q({0} msg imp),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}T),
						'south' => q({0}D),
						'west' => q({0}I),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}O),
						'north' => q({0}T),
						'south' => q({0}D),
						'west' => q({0}I),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} ghiotán),
						'many' => q({0} ngiotán),
						'name' => q(giotán),
						'one' => q({0} ghiotán),
						'other' => q({0} giotán),
						'two' => q({0} ghiotán),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} ghiotán),
						'many' => q({0} ngiotán),
						'name' => q(giotán),
						'one' => q({0} ghiotán),
						'other' => q({0} giotán),
						'two' => q({0} ghiotán),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bheart),
						'many' => q({0} mbeart),
						'name' => q(bearta),
						'one' => q({0} bheart),
						'other' => q({0} beart),
						'two' => q({0} bheart),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bheart),
						'many' => q({0} mbeart),
						'name' => q(bearta),
						'one' => q({0} bheart),
						'other' => q({0} beart),
						'two' => q({0} bheart),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBheart),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBheart),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(céadta bl),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(céadta bl),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} lá),
						'many' => q({0} lá),
						'name' => q(lá),
						'one' => q({0} lá),
						'other' => q({0} lá),
						'per' => q({0}/lá),
						'two' => q({0} lá),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} lá),
						'many' => q({0} lá),
						'name' => q(lá),
						'one' => q({0} lá),
						'other' => q({0} lá),
						'per' => q({0}/lá),
						'two' => q({0} lá),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} u),
						'many' => q({0} u),
						'name' => q(uair),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
						'two' => q({0} u),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} u),
						'many' => q({0} u),
						'name' => q(uair),
						'one' => q({0} u),
						'other' => q({0} u),
						'per' => q({0}/u),
						'two' => q({0} u),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} nóim),
						'many' => q({0} nóim),
						'name' => q(nóim),
						'one' => q({0} nóim),
						'other' => q({0} nóim),
						'per' => q({0}/nóim),
						'two' => q({0} nóim),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} nóim),
						'many' => q({0} nóim),
						'name' => q(nóim),
						'one' => q({0} nóim),
						'other' => q({0} nóim),
						'per' => q({0}/nóim),
						'two' => q({0} nóim),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mí),
						'many' => q({0} mí),
						'name' => q(míonna),
						'one' => q({0} mí),
						'other' => q({0} m),
						'per' => q({0}/mí),
						'two' => q({0} mí),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mí),
						'many' => q({0} mí),
						'name' => q(míonna),
						'one' => q({0} mí),
						'other' => q({0} m),
						'per' => q({0}/mí),
						'two' => q({0} mí),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} oíche),
						'many' => q({0} n-oíche),
						'name' => q(oícheanta),
						'one' => q({0} oíche),
						'other' => q({0} oíche),
						'per' => q({0}/oíche),
						'two' => q({0} oíche),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} oíche),
						'many' => q({0} n-oíche),
						'name' => q(oícheanta),
						'one' => q({0} oíche),
						'other' => q({0} oíche),
						'per' => q({0}/oíche),
						'two' => q({0} oíche),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'name' => q(ctú),
						'one' => q({0} ctú),
						'other' => q({0} cna),
						'per' => q({0}/c),
						'two' => q({0} cna),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} cna),
						'many' => q({0} cna),
						'name' => q(ctú),
						'one' => q({0} ctú),
						'other' => q({0} cna),
						'per' => q({0}/c),
						'two' => q({0} cna),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} soic),
						'many' => q({0} soic),
						'name' => q(soic),
						'one' => q({0} soic),
						'other' => q({0} soic),
						'two' => q({0} soic),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} soic),
						'many' => q({0} soic),
						'name' => q(soic),
						'one' => q({0} soic),
						'other' => q({0} soic),
						'two' => q({0} soic),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} scht),
						'many' => q({0} scht),
						'name' => q(scht),
						'one' => q({0} scht),
						'other' => q({0} scht),
						'per' => q({0}/scht),
						'two' => q({0} scht),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} scht),
						'many' => q({0} scht),
						'name' => q(scht),
						'one' => q({0} scht),
						'other' => q({0} scht),
						'per' => q({0}/scht),
						'two' => q({0} scht),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bl),
						'many' => q({0} bl),
						'name' => q(blianta),
						'one' => q({0} bl),
						'other' => q({0} bl),
						'two' => q({0} bl),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bl),
						'many' => q({0} bl),
						'name' => q(blianta),
						'one' => q({0} bl),
						'other' => q({0} bl),
						'two' => q({0} bl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(aimpéir),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(aimpéir),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miollaimp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miollaimp),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(óim),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(óim),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voltanna),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voltanna),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(leictravolta),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(leictravolta),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} Cal),
						'many' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} Cal),
						'many' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(giúil),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(giúil),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ciligiúl),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ciligiúl),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-uair),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-uair),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} theirm SAM),
						'many' => q({0} dteirm SAM),
						'name' => q(teirmeacha SAM),
						'one' => q({0} teirm SAM),
						'other' => q({0} teirm SAM),
						'two' => q({0} theirm SAM),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} theirm SAM),
						'many' => q({0} dteirm SAM),
						'name' => q(teirmeacha SAM),
						'one' => q({0} teirm SAM),
						'other' => q({0} teirm SAM),
						'two' => q({0} theirm SAM),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(niútan),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(niútan),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(punt-fhórsa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(punt-fhórsa),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} phonc),
						'many' => q({0} bponc),
						'name' => q(ponc),
						'one' => q({0} phonc),
						'other' => q({0} ponc),
						'two' => q({0} phonc),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} phonc),
						'many' => q({0} bponc),
						'name' => q(ponc),
						'one' => q({0} phonc),
						'other' => q({0} ponc),
						'two' => q({0} phonc),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} eim),
						'many' => q({0} eim),
						'name' => q(eim),
						'one' => q({0} eim),
						'other' => q({0} em),
						'two' => q({0} eim),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} eim),
						'many' => q({0} eim),
						'name' => q(eim),
						'one' => q({0} eim),
						'other' => q({0} em),
						'two' => q({0} eim),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(meigiphicteilíní),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(meigiphicteilíní),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(picteilíní),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(picteilíní),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} AR),
						'many' => q({0} AR),
						'name' => q(AR),
						'one' => q({0} AR),
						'other' => q({0} AR),
						'two' => q({0} AR),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} AR),
						'many' => q({0} AR),
						'name' => q(AR),
						'one' => q({0} AR),
						'other' => q({0} AR),
						'two' => q({0} AR),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(feánna),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(feánna),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} tr.),
						'many' => q({0} tr.),
						'name' => q(troithe),
						'one' => q({0} tr.),
						'other' => q({0} tr.),
						'per' => q({0}/tr.),
						'two' => q({0} tr.),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} tr.),
						'many' => q({0} tr.),
						'name' => q(troithe),
						'one' => q({0} tr.),
						'other' => q({0} tr.),
						'per' => q({0}/tr.),
						'two' => q({0} tr.),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} st),
						'many' => q({0} st),
						'name' => q(staideanna),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} st),
						'many' => q({0} st),
						'name' => q(staideanna),
						'one' => q({0} st),
						'other' => q({0} st),
						'two' => q({0} st),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} or.),
						'many' => q({0} or.),
						'name' => q(orlaí),
						'one' => q({0} or.),
						'other' => q({0} or.),
						'per' => q({0}/or.),
						'two' => q({0} or.),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} or.),
						'many' => q({0} or.),
						'name' => q(orlaí),
						'one' => q({0} or.),
						'other' => q({0} or.),
						'per' => q({0}/or.),
						'two' => q({0} or.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'name' => q(solasbhl.),
						'one' => q({0} sbh),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} sbh),
						'many' => q({0} sbh),
						'name' => q(solasbhl.),
						'one' => q({0} sbh),
						'other' => q({0} sbh),
						'two' => q({0} sbh),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(méadair),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(méadair),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μméadair),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μméadair),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'name' => q(mílte),
						'one' => q({0} mhíle),
						'other' => q({0} mi),
						'two' => q({0} mhíle),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mhíle),
						'many' => q({0} míle),
						'name' => q(mílte),
						'one' => q({0} mhíle),
						'other' => q({0} mi),
						'two' => q({0} mhíle),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} mhíle Lch),
						'many' => q({0} míle Lch),
						'name' => q(míle Lochl.),
						'one' => q({0} míle Lch),
						'other' => q({0} míle Lch),
						'two' => q({0} mhíle Lch),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} mhíle Lch),
						'many' => q({0} míle Lch),
						'name' => q(míle Lochl.),
						'one' => q({0} míle Lch),
						'other' => q({0} míle Lch),
						'two' => q({0} mhíle Lch),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} muirmh.),
						'many' => q({0} muirmh.),
						'name' => q(muirmh.),
						'one' => q({0} muirmh.),
						'other' => q({0} muirmh.),
						'two' => q({0} muirmh.),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} muirmh.),
						'many' => q({0} muirmh.),
						'name' => q(muirmh.),
						'one' => q({0} muirmh.),
						'other' => q({0} muirmh.),
						'two' => q({0} muirmh.),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pointí),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pointí),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(raonta gréine),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(raonta gréine),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} shl.),
						'many' => q({0} sl.),
						'name' => q(slata),
						'one' => q({0} sl.),
						'other' => q({0} sl.),
						'two' => q({0} shl.),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} shl.),
						'many' => q({0} sl.),
						'name' => q(slata),
						'one' => q({0} sl.),
						'other' => q({0} sl.),
						'two' => q({0} shl.),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lucsa),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lucsa),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(lonrachtaí gréine),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(lonrachtaí gréine),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carait),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carait),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(daltúin),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(daltúin),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(maiseanna an Domhain),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(maiseanna an Domhain),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} gráinne),
						'many' => q({0} gráinne),
						'name' => q(gráinne),
						'one' => q({0} gráinne),
						'other' => q({0} gráinne),
						'two' => q({0} gráinne),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gráinne),
						'many' => q({0} gráinne),
						'name' => q(gráinne),
						'one' => q({0} gráinne),
						'other' => q({0} gráinne),
						'two' => q({0} gráinne),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(graim),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(graim),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unsa),
						'many' => q({0} n-unsa),
						'name' => q(unsa),
						'one' => q({0} unsa),
						'other' => q({0} unsa),
						'per' => q({0}/unsa),
						'two' => q({0} unsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unsa),
						'many' => q({0} n-unsa),
						'name' => q(unsa),
						'one' => q({0} unsa),
						'other' => q({0} unsa),
						'per' => q({0}/unsa),
						'two' => q({0} unsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} unsa t),
						'many' => q({0} n-unsa t),
						'name' => q(unsa t),
						'one' => q({0} unsa t),
						'other' => q({0} unsa t),
						'two' => q({0} unsa t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} unsa t),
						'many' => q({0} n-unsa t),
						'name' => q(unsa t),
						'one' => q({0} unsa t),
						'other' => q({0} unsa t),
						'two' => q({0} unsa t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} phunt),
						'many' => q({0} bpunt),
						'name' => q(puint),
						'one' => q({0} phunt),
						'other' => q({0} punt),
						'per' => q({0}/punt),
						'two' => q({0} phunt),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} phunt),
						'many' => q({0} bpunt),
						'name' => q(puint),
						'one' => q({0} phunt),
						'other' => q({0} punt),
						'per' => q({0}/punt),
						'two' => q({0} phunt),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(maiseanna gréine),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(maiseanna gréine),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} chl.),
						'many' => q({0} gcl.),
						'name' => q(clocha),
						'one' => q({0} chl.),
						'other' => q({0} cl.),
						'two' => q({0} chl.),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} chl.),
						'many' => q({0} gcl.),
						'name' => q(clocha),
						'one' => q({0} chl.),
						'other' => q({0} cl.),
						'two' => q({0} chl.),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} t.g.),
						'many' => q({0} t.g.),
						'name' => q(tonnaí gearra),
						'one' => q({0} t.g.),
						'other' => q({0} t.g.),
						'two' => q({0} t.g.),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} t.g.),
						'many' => q({0} t.g.),
						'name' => q(tonnaí gearra),
						'one' => q({0} t.g.),
						'other' => q({0} t.g.),
						'two' => q({0} t.g.),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} ec),
						'many' => q({0} ec),
						'name' => q(ec),
						'one' => q({0} ec),
						'other' => q({0} ec),
						'two' => q({0} ec),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} ec),
						'many' => q({0} ec),
						'name' => q(ec),
						'one' => q({0} ec),
						'other' => q({0} ec),
						'two' => q({0} ec),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(vataí),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(vataí),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bharra),
						'many' => q({0} mbarra),
						'name' => q(barra),
						'one' => q({0} bharra),
						'other' => q({0} barra),
						'two' => q({0} bharra),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bharra),
						'many' => q({0} mbarra),
						'name' => q(barra),
						'one' => q({0} bharra),
						'other' => q({0} barra),
						'two' => q({0} bharra),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} or. Hg),
						'many' => q({0} n-or. Hg),
						'name' => q(orlaí Hg),
						'one' => q({0} or. Hg),
						'other' => q({0} or. Hg),
						'two' => q({0} or. Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} or. Hg),
						'many' => q({0} n-or. Hg),
						'name' => q(orlaí Hg),
						'one' => q({0} or. Hg),
						'other' => q({0} or. Hg),
						'two' => q({0} or. Hg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} psoc),
						'many' => q({0} psoc),
						'name' => q(psoc),
						'one' => q({0} psoc),
						'other' => q({0} psoc),
						'two' => q({0} psoc),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} psoc),
						'many' => q({0} psoc),
						'name' => q(psoc),
						'one' => q({0} psoc),
						'other' => q({0} psoc),
						'two' => q({0} psoc),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} km/u),
						'many' => q({0} km/u),
						'name' => q(km/uair),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
						'two' => q({0} km/u),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} km/u),
						'many' => q({0} km/u),
						'name' => q(km/uair),
						'one' => q({0} km/u),
						'other' => q({0} km/u),
						'two' => q({0} km/u),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} mrml/u),
						'many' => q({0} mrml/u),
						'name' => q(mrml/u),
						'one' => q({0} mrml/u),
						'other' => q({0} mrml/u),
						'two' => q({0} mrml/u),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} mrml/u),
						'many' => q({0} mrml/u),
						'name' => q(mrml/u),
						'one' => q({0} mrml/u),
						'other' => q({0} mrml/u),
						'two' => q({0} mrml/u),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} msu),
						'many' => q({0} msu),
						'name' => q(mílte/uair),
						'one' => q({0} msu),
						'other' => q({0} msu),
						'two' => q({0} msu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} msu),
						'many' => q({0} msu),
						'name' => q(mílte/uair),
						'one' => q({0} msu),
						'other' => q({0} msu),
						'two' => q({0} msu),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} ac tr),
						'many' => q({0} ac tr),
						'name' => q(acra-tr),
						'one' => q({0} ac tr),
						'other' => q({0} ac tr),
						'two' => q({0} ac tr),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} ac tr),
						'many' => q({0} ac tr),
						'name' => q(acra-tr),
						'one' => q({0} ac tr),
						'other' => q({0} ac tr),
						'two' => q({0} ac tr),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bairille),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bairille),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buiséil),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buiséil),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(tr³),
						'one' => q({0} tr³),
						'other' => q({0} tr³),
						'two' => q({0} tr³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} tr³),
						'many' => q({0} tr³),
						'name' => q(tr³),
						'one' => q({0} tr³),
						'other' => q({0} tr³),
						'two' => q({0} tr³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} or³),
						'many' => q({0} or³),
						'name' => q(orlach³),
						'one' => q({0} or³),
						'other' => q({0} or³),
						'two' => q({0} or³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} or³),
						'many' => q({0} or³),
						'name' => q(orlach³),
						'one' => q({0} or³),
						'other' => q({0} or³),
						'two' => q({0} or³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mhíle³),
						'many' => q({0} míle³),
						'name' => q(míle³),
						'one' => q({0} mhíle³),
						'other' => q({0} míle³),
						'two' => q({0} mhíle³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mhíle³),
						'many' => q({0} míle³),
						'name' => q(míle³),
						'one' => q({0} mhíle³),
						'other' => q({0} míle³),
						'two' => q({0} mhíle³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} sl³),
						'many' => q({0} sl³),
						'name' => q(slata³),
						'one' => q({0} sl³),
						'other' => q({0} sl³),
						'two' => q({0} sl³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} sl³),
						'many' => q({0} sl³),
						'name' => q(slata³),
						'one' => q({0} sl³),
						'other' => q({0} sl³),
						'two' => q({0} sl³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cupáin),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cupáin),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cupán méadr.),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cupán méadr.),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} spmhil),
						'many' => q({0} spmhil),
						'name' => q(spmhil),
						'one' => q({0} spmhil),
						'other' => q({0} spmhil),
						'two' => q({0} spmhil),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} spmhil),
						'many' => q({0} spmhil),
						'name' => q(spmhil),
						'one' => q({0} spmhil),
						'other' => q({0} spmhil),
						'two' => q({0} spmhil),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} spmhil imp),
						'many' => q({0} spmhil imp),
						'name' => q(spmhil imp),
						'one' => q({0} spmhil imp),
						'other' => q({0} spmhil imp),
						'two' => q({0} spmhil imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} spmhil imp),
						'many' => q({0} spmhil imp),
						'name' => q(spmhil imp),
						'one' => q({0} spmhil imp),
						'other' => q({0} spmhil imp),
						'two' => q({0} spmhil imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dr l.),
						'many' => q({0} dr l.),
						'name' => q(dr l.),
						'one' => q({0} dr l.),
						'other' => q({0} dr l.),
						'two' => q({0} dr l.),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dr l.),
						'many' => q({0} dr l.),
						'name' => q(dr l.),
						'one' => q({0} dr l.),
						'other' => q({0} dr l.),
						'two' => q({0} dr l.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} bhraon),
						'many' => q({0} mbraon),
						'name' => q(braon),
						'one' => q({0} bhraon),
						'other' => q({0} braon),
						'two' => q({0} bhraon),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} bhraon),
						'many' => q({0} mbraon),
						'name' => q(braon),
						'one' => q({0} bhraon),
						'other' => q({0} braon),
						'two' => q({0} bhraon),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} unsa l.),
						'many' => q({0} n-unsa l.),
						'name' => q(unsaí leacht.),
						'one' => q({0} unsa l.),
						'other' => q({0} unsa l.),
						'two' => q({0} unsa l.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} unsa l.),
						'many' => q({0} n-unsa l.),
						'name' => q(unsaí leacht.),
						'one' => q({0} unsa l.),
						'other' => q({0} unsa l.),
						'two' => q({0} unsa l.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Unsa leachtach impiriúil),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Unsa leachtach impiriúil),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} ghal.),
						'many' => q({0} ngal.),
						'name' => q(galúin),
						'one' => q({0} ghal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
						'two' => q({0} ghal.),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} ghal.),
						'many' => q({0} ngal.),
						'name' => q(galúin),
						'one' => q({0} ghal.),
						'other' => q({0} gal.),
						'per' => q({0}/gal.),
						'two' => q({0} ghal.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} ghal. imp.),
						'many' => q({0} ngal. imp.),
						'name' => q(gal. imp.),
						'one' => q({0} ghal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
						'two' => q({0} ghal. imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} ghal. imp.),
						'many' => q({0} ngal. imp.),
						'name' => q(gal. imp.),
						'one' => q({0} ghal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
						'two' => q({0} ghal. imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} mhiosúr),
						'many' => q({0} miosúr),
						'name' => q(miosúr),
						'one' => q({0} mhiosúr),
						'other' => q({0} miosúr),
						'two' => q({0} mhiosúr),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} mhiosúr),
						'many' => q({0} miosúr),
						'name' => q(miosúr),
						'one' => q({0} mhiosúr),
						'other' => q({0} miosúr),
						'two' => q({0} mhiosúr),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lítir),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lítir),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} phinse),
						'many' => q({0} bpinse),
						'name' => q(pinse),
						'one' => q({0} phinse),
						'other' => q({0} pinse),
						'two' => q({0} phinse),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} phinse),
						'many' => q({0} bpinse),
						'name' => q(pinse),
						'one' => q({0} phinse),
						'other' => q({0} pinse),
						'two' => q({0} phinse),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(piontaí),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(piontaí),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} chárt),
						'many' => q({0} gcárt),
						'name' => q(cáirt),
						'one' => q({0} chárt),
						'other' => q({0} cárt),
						'two' => q({0} chárt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} chárt),
						'many' => q({0} gcárt),
						'name' => q(cáirt),
						'one' => q({0} chárt),
						'other' => q({0} cárt),
						'two' => q({0} chárt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} chárt impiriúla),
						'many' => q({0} gcárt impiriúla),
						'name' => q(cárt impiriúil),
						'one' => q({0} chárt impiriúil),
						'other' => q({0} cárt impiriúil),
						'two' => q({0} chárt impiriúla),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} chárt impiriúla),
						'many' => q({0} gcárt impiriúla),
						'name' => q(cárt impiriúil),
						'one' => q({0} chárt impiriúil),
						'other' => q({0} cárt impiriúil),
						'two' => q({0} chárt impiriúla),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} spbh),
						'many' => q({0} spbh),
						'name' => q(spbh),
						'one' => q({0} spbh),
						'other' => q({0} spbh),
						'two' => q({0} spbh),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} spbh),
						'many' => q({0} spbh),
						'name' => q(spbh),
						'one' => q({0} spbh),
						'other' => q({0} spbh),
						'two' => q({0} spbh),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:tá|t|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:níl|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} agus {1}),
				2 => q({0} agus {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'nan' => q(Nuimh),
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
					'few' => '0 mhíle',
					'many' => '0 míle',
					'one' => '0 mhíle',
					'other' => '0 míle',
					'two' => '0 mhíle',
				},
				'10000' => {
					'few' => '00 míle',
					'many' => '00 míle',
					'one' => '00 míle',
					'other' => '00 míle',
					'two' => '00 míle',
				},
				'100000' => {
					'few' => '000 míle',
					'many' => '000 míle',
					'one' => '000 míle',
					'other' => '000 míle',
					'two' => '000 míle',
				},
				'1000000' => {
					'few' => '0 mhilliún',
					'many' => '0 milliún',
					'one' => '0 mhilliún',
					'other' => '0 milliún',
					'two' => '0 mhilliún',
				},
				'10000000' => {
					'few' => '00 milliún',
					'many' => '00 milliún',
					'one' => '00 milliún',
					'other' => '00 milliún',
					'two' => '00 milliún',
				},
				'100000000' => {
					'few' => '000 milliún',
					'many' => '000 milliún',
					'one' => '000 milliún',
					'other' => '000 milliún',
					'two' => '000 milliún',
				},
				'1000000000' => {
					'few' => '0 bhilliún',
					'many' => '0 mbilliún',
					'one' => '0 bhilliún',
					'other' => '0 billiún',
					'two' => '0 bhilliún',
				},
				'10000000000' => {
					'few' => '00 billiún',
					'many' => '00 mbilliún',
					'one' => '00 billiún',
					'other' => '00 billiún',
					'two' => '00 billiún',
				},
				'100000000000' => {
					'few' => '000 billiún',
					'many' => '000 billiún',
					'one' => '000 billiún',
					'other' => '000 billiún',
					'two' => '000 billiún',
				},
				'1000000000000' => {
					'few' => '0 thrilliún',
					'many' => '0 dtrilliún',
					'one' => '0 trilliún',
					'other' => '0 trilliún',
					'two' => '0 thrilliún',
				},
				'10000000000000' => {
					'few' => '00 trilliún',
					'many' => '00 dtrilliún',
					'one' => '00 trilliún',
					'other' => '00 trilliún',
					'two' => '00 trilliún',
				},
				'100000000000000' => {
					'few' => '000 trilliún',
					'many' => '000 trilliún',
					'one' => '000 trilliún',
					'other' => '000 trilliún',
					'two' => '000 trilliún',
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
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
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
				'currency' => q(Peseta Andóra),
				'few' => q(pheseta Andóra),
				'many' => q(bpeseta Andóra),
				'one' => q(pheseta Andóra),
				'other' => q(peseta Andóra),
				'two' => q(pheseta Andóra),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirham Aontas na nÉimíríochtaí Arabacha),
				'few' => q(dhirham Aontas na nÉimíríochtaí Arabacha),
				'many' => q(ndirham Aontas na nÉimíríochtaí Arabacha),
				'one' => q(dirham Aontas na nÉimíríochtaí Arabacha),
				'other' => q(dirham Aontas na nÉimíríochtaí Arabacha),
				'two' => q(dhirham Aontas na nÉimíríochtaí Arabacha),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afgainí \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani na hAfganastáine),
				'few' => q(afghani na hAfganastáine),
				'many' => q(n-afghani na hAfganastáine),
				'one' => q(afghani na hAfganastáine),
				'other' => q(afghani na hAfganastáine),
				'two' => q(afghani na hAfganastáine),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Lek na hAlbáine \(1946–1965\)),
				'few' => q(lek na hAlbáine \(1946–1965\)),
				'many' => q(lek na hAlbáine \(1946–1965\)),
				'one' => q(lek na hAlbáine \(1946–1965\)),
				'other' => q(lek na hAlbáine \(1946–1965\)),
				'two' => q(lek na hAlbáine \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek na hAlbáine),
				'few' => q(lek na hAlbáine),
				'many' => q(lek na hAlbáine),
				'one' => q(lek na hAlbáine),
				'other' => q(Lek na hAlbáine),
				'two' => q(lek na hAlbáine),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram na hAirméine),
				'few' => q(dhram na hAirméine),
				'many' => q(ndram na hAirméine),
				'one' => q(dram na hAirméine),
				'other' => q(dram na hAirméine),
				'two' => q(dhram na hAirméine),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gildear Aintillí na hÍsiltíre),
				'few' => q(ghildear Aintillí na hÍsiltíre),
				'many' => q(ngildear Aintillí na hÍsiltíre),
				'one' => q(ghildear Aintillí na hÍsiltíre),
				'other' => q(gildear Aintillí na hÍsiltíre),
				'two' => q(ghildear Aintillí na hÍsiltíre),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angóla),
				'few' => q(kwanza Angóla),
				'many' => q(kwanza Angóla),
				'one' => q(kwanza Angóla),
				'other' => q(kwanza Angóla),
				'two' => q(kwanza Angóla),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kwanza Angólach \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Kwanza Nua Angólach \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza Reajustado Angólach \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral Airgintíneach),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Peso Ley na hAirgintíne \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Peso na hAirgintíne \(1881–1970\)),
				'few' => q(pheso na hAirgintíne \(1881–1970\)),
				'many' => q(bpeso na hAirgintíne \(1881–1970\)),
				'one' => q(pheso na hAirgintíne \(1881–1970\)),
				'other' => q(peso na hAirgintíne \(1881–1970\)),
				'two' => q(pheso na hAirgintíne \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso na hAirgintíne \(1983–1985\)),
				'few' => q(pheso na hAirgintíne \(1983–1985\)),
				'many' => q(bpeso na hAirgintíne \(1983–1985\)),
				'one' => q(pheso na hAirgintíne \(1983–1985\)),
				'other' => q(peso na hAirgintíne \(1983–1985\)),
				'two' => q(pheso na hAirgintíne \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso na hAirgintíne),
				'few' => q(pheso na hAirgintíne),
				'many' => q(bpeso na hAirgintíne),
				'one' => q(pheso na hAirgintíne),
				'other' => q(peso na hAirgintíne),
				'two' => q(pheso na hAirgintíne),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Scilling na hOstaire),
				'few' => q(Scilling Ostarach),
				'many' => q(Scilling Ostarach),
				'one' => q(Scilling Ostarach),
				'other' => q(Scilling Ostarach),
				'two' => q(Scilling Ostarach),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dollar na hAstráile),
				'few' => q(dhollar na hAstráile),
				'many' => q(ndollar na hAstráile),
				'one' => q(dollar na hAstráile),
				'other' => q(dollar na hAstráile),
				'two' => q(dhollar na hAstráile),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Flóirín Arúba),
				'few' => q(fhlóirín Arúba),
				'many' => q(bhflóirín Arúba),
				'one' => q(fhlóirín Arúba),
				'other' => q(flóirín Arúba),
				'two' => q(fhlóirín Arúba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manat na hAsarbaiseáine \(1993–2006\)),
				'few' => q(mhanat na hAsarbaiseáine \(1993–2006\)),
				'many' => q(manat na hAsarbaiseáine \(1993–2006\)),
				'one' => q(mhanat na hAsarbaiseáine \(1993–2006\)),
				'other' => q(manat na hAsarbaiseáine \(1993–2006\)),
				'two' => q(mhanat na hAsarbaiseáine \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat na hAsarbaiseáine),
				'few' => q(mhanat na hAsarbaiseáine),
				'many' => q(manat na hAsarbaiseáine),
				'one' => q(mhanat na hAsarbaiseáine),
				'other' => q(manat na hAsarbaiseáine),
				'two' => q(mhanat na hAsarbaiseáine),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dínear Bhoisnia-Heirseagaivéin \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marg Inmhalartaithe na Boisnia-Heirseagaivéine),
				'few' => q(mharg inmhalartaithe na Boisnia-Heirseagaivéine),
				'many' => q(marg inmhalartaithe na Boisnia-Heirseagaivéine),
				'one' => q(mharg inmhalartaithe na Boisnia-Heirseagaivéine),
				'other' => q(marg inmhalartaithe na Boisnia-Heirseagaivéine),
				'two' => q(mharg inmhalartaithe na Boisnia-Heirseagaivéine),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dollar Bharbadós),
				'few' => q(dhollar Bharbadós),
				'many' => q(ndollar Bharbadós),
				'one' => q(dollar Bharbadós),
				'other' => q(dollar Bharbadós),
				'two' => q(dhollar Bharbadós),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka na Banglaidéise),
				'few' => q(thaka na Banglaidéise),
				'many' => q(dtaka na Banglaidéise),
				'one' => q(taka na Banglaidéise),
				'other' => q(taka na Banglaidéise),
				'two' => q(thaka na Banglaidéise),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Franc na Beilge \(inmhalartaithe\)),
				'few' => q(Franc Beilgeach \(inathraithe\)),
				'many' => q(Franc Beilgeach \(inathraithe\)),
				'one' => q(Franc Beilgeach \(inathraithe\)),
				'other' => q(Franc Beilgeach \(inathraithe\)),
				'two' => q(Franc Beilgeach \(inathraithe\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franc Beilgeach),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Franc na Beilge \(airgeadais\)),
				'few' => q(Franc Beilgeach \(airgeadúil\)),
				'many' => q(Franc Beilgeach \(airgeadúil\)),
				'one' => q(Franc Beilgeach \(airgeadúil\)),
				'other' => q(Franc Beilgeach \(airgeadúil\)),
				'two' => q(Franc Beilgeach \(airgeadúil\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lev Crua na Bulgáire),
				'few' => q(lev chrua na Bulgáire),
				'many' => q(lev chrua na Bulgáire),
				'one' => q(lev crua na Bulgáire),
				'other' => q(lev crua na Bulgáire),
				'two' => q(lev chrua na Bulgáire),
			},
		},
		'BGM' => {
			display_name => {
				'few' => q(lev sóisialach na Bulgáire),
				'many' => q(lev sóisialach na Bulgáire),
				'one' => q(lev sóisialach na Bulgáire),
				'other' => q(lev sóisialach na Bulgáire),
				'two' => q(lev sóisialach na Bulgáire),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev na Bulgáire),
				'few' => q(lev na Bulgáire),
				'many' => q(lev na Bulgáire),
				'one' => q(lev na Bulgáire),
				'other' => q(lev na Bulgáire),
				'two' => q(lev na Bulgáire),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev na Bulgáire \(1879–1952\)),
				'few' => q(lev na Bulgáire \(1879–1952\)),
				'many' => q(lev na Bulgáire \(1879–1952\)),
				'one' => q(lev na Bulgáire \(1879–1952\)),
				'other' => q(lev na Bulgáire \(1879–1952\)),
				'two' => q(lev na Bulgáire \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bhairéin),
				'few' => q(dhinar Bhairéin),
				'many' => q(ndinar Bhairéin),
				'one' => q(dinar Bhairéin),
				'other' => q(dinar Bhairéin),
				'two' => q(dhinar Bhairéin),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc na Burúine),
				'few' => q(fhranc na Burúine),
				'many' => q(bhfranc na Burúine),
				'one' => q(fhranc na Burúine),
				'other' => q(franc na Burúine),
				'two' => q(fhranc na Burúine),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dollar Bheirmiúda),
				'few' => q(dhollar Bheirmiúda),
				'many' => q(ndollar Bheirmiúda),
				'one' => q(dollar Bheirmiúda),
				'other' => q(dollar Bheirmiúda),
				'two' => q(dhollar Bheirmiúda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dollar Bhrúiné),
				'few' => q(dhollar Bhrúiné),
				'many' => q(ndollar Bhrúiné),
				'one' => q(dollar Bhrúiné),
				'other' => q(dollar Bhrúiné),
				'two' => q(dhollar Bhrúiné),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano),
				'few' => q(bholiviano),
				'many' => q(mboliviano),
				'one' => q(bholiviano),
				'other' => q(boliviano),
				'two' => q(bholiviano),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso na Bolaive),
				'few' => q(pheso na Bolaive),
				'many' => q(bpeso na Bolaive),
				'one' => q(pheso na Bolaive),
				'other' => q(peso na Bolaive),
				'two' => q(pheso na Bolaive),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol na Bolaive),
				'few' => q(mvdol na Bolaive),
				'many' => q(mvdol na Bolaive),
				'one' => q(mvdol na Bolaive),
				'other' => q(mvdol na Bolaive),
				'two' => q(mvdol na Bolaive),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro Nua na Brasaíle \(1967–1986\)),
				'few' => q(chruzeiro nua na Brasaíle \(1967–1986\)),
				'many' => q(gcruzeiro nua na Brasaíle \(1967–1986\)),
				'one' => q(chruzeiro nua na Brasaíle \(1967–1986\)),
				'other' => q(cruzeiro nua na Brasaíle \(1967–1986\)),
				'two' => q(chruzeiro nua na Brasaíle \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado na Brasaíle \(1986–1989\)),
				'few' => q(chruzado na Brasaíle \(1986–1989\)),
				'many' => q(gcruzado na Brasaíle \(1986–1989\)),
				'one' => q(chruzado na Brasaíle \(1986–1989\)),
				'other' => q(cruzado na Brasaíle \(1986–1989\)),
				'two' => q(chruzado na Brasaíle \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro na Brasaíle \(1990–1993\)),
				'few' => q(chruzeiro na Brasaíle \(1990–1993\)),
				'many' => q(gcruzeiro na Brasaíle \(1990–1993\)),
				'one' => q(chruzeiro na Brasaíle \(1990–1993\)),
				'other' => q(cruzeiro na Brasaíle \(1990–1993\)),
				'two' => q(chruzeiro na Brasaíle \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real na Brasaíle),
				'few' => q(real na Brasaíle),
				'many' => q(real na Brasaíle),
				'one' => q(real na Brasaíle),
				'other' => q(real na Brasaíle),
				'two' => q(real na Brasaíle),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado Nua na Brasaíle \(1989–1990\)),
				'few' => q(chruzado nua na Brasaíle \(1989–1990\)),
				'many' => q(gcruzado nua na Brasaíle \(1989–1990\)),
				'one' => q(chruzado nua na Brasaíle \(1989–1990\)),
				'other' => q(cruzado nua na Brasaíle \(1989–1990\)),
				'two' => q(chruzado nua na Brasaíle \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro na Brasaíle \(1993–1994\)),
				'few' => q(chruzeiro na Brasaíle \(1993–1994\)),
				'many' => q(gcruzeiro na Brasaíle \(1993–1994\)),
				'one' => q(chruzeiro na Brasaíle \(1993–1994\)),
				'other' => q(cruzeiro na Brasaíle \(1993–1994\)),
				'two' => q(chruzeiro na Brasaíle \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Cruzeiro na Brasaíle \(1942–1967\)),
				'few' => q(chruzeiro na Brasaíle \(1942–1967\)),
				'many' => q(gcruzeiro na Brasaíle \(1942–1967\)),
				'one' => q(chruzeiro na Brasaíle \(1942–1967\)),
				'other' => q(cruzeiro na Brasaíle \(1942–1967\)),
				'two' => q(chruzeiro na Brasaíle \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dollar na mBahámaí),
				'few' => q(dhollar na mBahámaí),
				'many' => q(ndollar na mBahámaí),
				'one' => q(dollar na mBahámaí),
				'other' => q(dollar na mBahámaí),
				'two' => q(dhollar na mBahámaí),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum na Bútáine),
				'few' => q(ngultrum na Bútáine),
				'many' => q(ngultrum na Bútáine),
				'one' => q(ngultrum na Bútáine),
				'other' => q(ngultrum na Bútáine),
				'two' => q(ngultrum na Bútáine),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat Bhurma),
				'few' => q(kyat Bhurma),
				'many' => q(kyat Bhurma),
				'one' => q(kyat Bhurma),
				'other' => q(kyat Bhurma),
				'two' => q(kyat Bhurma),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula na Botsuáine),
				'few' => q(phula na Botsuáine),
				'many' => q(bpula na Botsuáine),
				'one' => q(phula na Botsuáine),
				'other' => q(pula na Botsuáine),
				'two' => q(phula na Botsuáine),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Rúbal Nua na Bealarúise \(1994–1999\)),
				'few' => q(rúbal nua na Bealarúise \(1994–1999\)),
				'many' => q(rúbal nua na Bealarúise \(1994–1999\)),
				'one' => q(rúbal nua na Bealarúise \(1994–1999\)),
				'other' => q(rúbal nua na Bealarúise \(1994–1999\)),
				'two' => q(rúbal nua na Bealarúise \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rúbal na Bealarúise),
				'few' => q(rúbal na Bealarúise),
				'many' => q(rúbal na Bealarúise),
				'one' => q(rúbal na Bealarúise),
				'other' => q(rúbal na Bealarúise),
				'two' => q(rúbal na Bealarúise),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rúbal na Bealarúise \(2000–2016\)),
				'few' => q(rúbal na Bealarúise \(2000–2016\)),
				'many' => q(rúbal na Bealarúise \(2000–2016\)),
				'one' => q(rúbal na Bealarúise \(2000–2016\)),
				'other' => q(rúbal na Bealarúise \(2000–2016\)),
				'two' => q(rúbal na Bealarúise \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dollar na Beilíse),
				'few' => q(dhollar na Beilíse),
				'many' => q(ndollar na Beilíse),
				'one' => q(dollar na Beilíse),
				'other' => q(dollar na Beilíse),
				'two' => q(dhollar na Beilíse),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dollar Cheanada),
				'few' => q(dhollar Cheanada),
				'many' => q(ndollar Cheanada),
				'one' => q(dollar Cheanada),
				'other' => q(dollar Cheanada),
				'two' => q(dhollar Cheanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc an Chongó),
				'few' => q(fhranc an Chongó),
				'many' => q(bhfranc an Chongó),
				'one' => q(fhranc an Chongó),
				'other' => q(franc an Chongó),
				'two' => q(fhranc an Chongó),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Euro WIR),
				'few' => q(euro WIR),
				'many' => q(euro WIR),
				'one' => q(WIR euro),
				'other' => q(euro WIR),
				'two' => q(euro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc na hEilvéise),
				'few' => q(fhranc na hEilvéise),
				'many' => q(bhfranc na hEilvéise),
				'one' => q(fhranc na hEilvéise),
				'other' => q(franc na hEilvéise),
				'two' => q(fhranc na hEilvéise),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Franc WIR),
				'few' => q(fhranc WIR),
				'many' => q(bhfranc WIR),
				'one' => q(fhranc WIR amháin),
				'other' => q(franc WIR),
				'two' => q(fhranc WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Escudo na Sile),
				'few' => q(escudo na Sile),
				'many' => q(n-escudo na Sile),
				'one' => q(escudo na Sile),
				'other' => q(escudo na Sile),
				'two' => q(escudo na Sile),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Unidades de Fomento na Sile),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso na Sile),
				'few' => q(pheso na Sile),
				'many' => q(bpeso na Sile),
				'one' => q(pheso na Sile),
				'other' => q(peso na Sile),
				'two' => q(pheso na Sile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan na Síne \(seachairgeadra\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan na Síne),
				'few' => q(yuan na Síne),
				'many' => q(yuan na Síne),
				'one' => q(yuan na Síne),
				'other' => q(yuan na Síne),
				'two' => q(yuan na Síne),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso na Colóime),
				'few' => q(pheso na Colóime),
				'many' => q(bpeso na Colóime),
				'one' => q(pheso na Colóime),
				'other' => q(peso na Colóime),
				'two' => q(pheso na Colóime),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón Chósta Ríce),
				'few' => q(cholón Chósta Ríce),
				'many' => q(gcolón Chósta Ríce),
				'one' => q(cholón Chósta Ríce),
				'other' => q(colón Chósta Ríce),
				'two' => q(cholón Chósta Ríce),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Dinar na Seirbia \(2002–2006\)),
				'few' => q(dhinar na Seirbia \(2002–2006\)),
				'many' => q(ndinar na Seirbia \(2002–2006\)),
				'one' => q(dinar na Seirbia \(2002–2006\)),
				'other' => q(dinar na Seirbia \(2002–2006\)),
				'two' => q(dhinar na Seirbia \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Koruna Crua na Seicslóvaice),
				'few' => q(koruna chrua na Seicslóvaice),
				'many' => q(koruna chrua na Seicslóvaice),
				'one' => q(koruna chrua na Seicslóvaice),
				'other' => q(koruna crua na Seicslóvaice),
				'two' => q(koruna chrua na Seicslóvaice),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Inmhalartaithe Chúba),
				'few' => q(pheso inmhalartaithe Chúba),
				'many' => q(bpeso inmhalartaithe Chúba),
				'one' => q(pheso inmhalartaithe Chúba),
				'other' => q(peso inmhalartaithe Chúba),
				'two' => q(pheso inmhalartaithe Chúba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Chúba),
				'few' => q(pheso Chúba),
				'many' => q(bpeso Chúba),
				'one' => q(pheso Chúba),
				'other' => q(peso Chúba),
				'two' => q(pheso Chúba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Rinn Verde),
				'few' => q(escudo Rinn Verde),
				'many' => q(n-escudo Rinn Verde),
				'one' => q(escudo Rinn Verde),
				'other' => q(escudo Rinn Verde),
				'two' => q(escudo Rinn Verde),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Punt na Cipire),
				'few' => q(phunt na Cipire),
				'many' => q(bpunt na Cipire),
				'one' => q(phunt na Cipire),
				'other' => q(punt na Cipire),
				'two' => q(phunt na Cipire),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Phoblacht na Seice),
				'few' => q(koruna Phoblacht na Seice),
				'many' => q(koruna Phoblacht na Seice),
				'one' => q(koruna Phoblacht na Seice),
				'other' => q(koruna Phoblacht na Seice),
				'two' => q(koruna Phoblacht na Seice),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Marc Ghearmáin an Oirthir),
				'few' => q(Ostmark na hOirGhearmáine),
				'many' => q(Ostmark na hOirGhearmáine),
				'one' => q(Ostmark na hOirGhearmáine),
				'other' => q(Ostmark na hOirGhearmáine),
				'two' => q(Ostmark na hOirGhearmáine),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Deutsche Mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Djibouti),
				'few' => q(fhranc Djibouti),
				'many' => q(bhfranc Djibouti),
				'one' => q(fhranc Djibouti),
				'other' => q(franc Djibouti),
				'two' => q(fhranc Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Coróin na Danmhairge),
				'few' => q(choróin na Danmhairge),
				'many' => q(gcoróin na Danmhairge),
				'one' => q(choróin na Danmhairge),
				'other' => q(coróin na Danmhairge),
				'two' => q(choróin na Danmhairge),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso na Poblachta Doiminicí),
				'few' => q(pheso na Poblachta Doiminicí),
				'many' => q(bpeso na Poblachta Doiminicí),
				'one' => q(pheso na Poblachta Doiminicí),
				'other' => q(peso na Poblachta Doiminicí),
				'two' => q(pheso na Poblachta Doiminicí),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar na hAilgéire),
				'few' => q(dhinar na hAilgéire),
				'many' => q(ndinar na hAilgéire),
				'one' => q(dinar na hAilgéire),
				'other' => q(dinar na hAilgéire),
				'two' => q(dhinar na hAilgéire),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre Eacuadóir),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Unidad de Valor Constante \(UVC\) Eacuadóir),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kroon na hEastóine),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Punt na hÉigipte),
				'few' => q(phunt na hÉigipte),
				'many' => q(bpunt na hÉigipte),
				'one' => q(phunt na hÉigipte),
				'other' => q(punt na hÉigipte),
				'two' => q(phunt na hÉigipte),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa na hEiritré),
				'few' => q(nakfa na hEiritré),
				'many' => q(nakfa na hEiritré),
				'one' => q(nakfa na hEiritré),
				'other' => q(nakfa na hEiritré),
				'two' => q(nakfa na hEiritré),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Peseta na Spáinne),
				'few' => q(pheseta na Spáinne),
				'many' => q(bpeseta na Spáinne),
				'one' => q(pheseta na Spáinne),
				'other' => q(peseta na Spáinne),
				'two' => q(pheseta na Spáinne),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr na hAetóipe),
				'few' => q(bhirr na hAetóipe),
				'many' => q(mbirr na hAetóipe),
				'one' => q(bhirr na hAetóipe),
				'other' => q(birr na hAetóipe),
				'two' => q(bhirr na hAetóipe),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'few' => q(euro),
				'many' => q(euro),
				'one' => q(euro),
				'other' => q(euro),
				'two' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Markka Fionnlannach),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dollar Fhidsí),
				'few' => q(dhollar Fhidsí),
				'many' => q(ndollar Fhidsí),
				'one' => q(dollar Fhidsí),
				'other' => q(dollar Fhidsí),
				'two' => q(dhollar Fhidsí),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Punt Oileáin Fháclainne),
				'few' => q(phunt Oileáin Fháclainne),
				'many' => q(bpunt Oileáin Fháclainne),
				'one' => q(phunt Oileáin Fháclainne),
				'other' => q(punt Oileáin Fháclainne),
				'two' => q(phunt Oileáin Fháclainne),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franc na Fraince),
				'few' => q(Franc Francach),
				'many' => q(Franc Francach),
				'one' => q(Franc Francach),
				'other' => q(Franc Francach),
				'two' => q(Franc Francach),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Punt Steirling),
				'few' => q(phunt steirling),
				'many' => q(bpunt steirling),
				'one' => q(phunt steirling),
				'other' => q(punt steirling),
				'two' => q(phunt steirling),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Kupon Larit na Grúise),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari na Seoirsia),
				'few' => q(lari na Seoirsia),
				'many' => q(lari na Seoirsia),
				'one' => q(lari na Seoirsia),
				'other' => q(lari na Seoirsia),
				'two' => q(lari na Seoirsia),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi Ghána \(1979–2007\)),
				'few' => q(chedi Ghána \(1979–2007\)),
				'many' => q(gcedi Ghána \(1979–2007\)),
				'one' => q(chedi Ghána \(1979–2007\)),
				'other' => q(cedi Ghána \(1979–2007\)),
				'two' => q(chedi Ghána \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Ghána),
				'few' => q(chedi Ghána),
				'many' => q(gcedi Ghána),
				'one' => q(chedi Ghána),
				'other' => q(cedi Ghána),
				'two' => q(chedi Ghána),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Punt Ghiobráltar),
				'few' => q(phunt Ghiobráltar),
				'many' => q(bpunt Ghiobráltar),
				'one' => q(phunt Ghiobráltar),
				'other' => q(punt Ghiobráltar),
				'two' => q(phunt Ghiobráltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi na Gaimbia),
				'few' => q(dhalasi na Gaimbia),
				'many' => q(ndalasi na Gaimbia),
				'one' => q(dalasi na Gaimbia),
				'other' => q(dalasi na Gaimbia),
				'two' => q(dhalasi na Gaimbia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc na Guine),
				'few' => q(fhranc na Guine),
				'many' => q(bhfranc na Guine),
				'one' => q(fhranc na Guine),
				'other' => q(franc na Guine),
				'two' => q(fhranc na Guine),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli Guine),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele Guineana na Guine Meánchiorclaí),
				'few' => q(Ekwele Guineana na Guine Meánchiorclaí),
				'many' => q(Ekwele Guineana na Guine Meánchiorclaí),
				'one' => q(Ekwele Guineana na Guine Meánchiorclaí),
				'other' => q(Ekwele Guineana na Guine Meánchriosaí),
				'two' => q(Ekwele Guineana na Guine Meánchiorclaí),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drachma Gréagach),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Ghuatamala),
				'few' => q(quetzal Ghuatamala),
				'many' => q(quetzal Ghuatamala),
				'one' => q(quetzal Ghuatamala),
				'other' => q(quetzal Ghuatamala),
				'two' => q(quetzal Ghuatamala),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Escudo na Guine Portaingéalaí),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso Guine-Bhissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dollar na Guáine),
				'few' => q(dhollar na Guáine),
				'many' => q(ndollar na Guáine),
				'one' => q(dollar na Guáine),
				'other' => q(dollar na Guáine),
				'two' => q(dhollar na Guáine),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dollar Hong Cong),
				'few' => q(dhollar Hong Cong),
				'many' => q(ndollar Hong Cong),
				'one' => q(dollar Hong Cong),
				'other' => q(dollar Hong Cong),
				'two' => q(dhollar Hong Cong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Hondúras),
				'few' => q(lempira Hondúras),
				'many' => q(lempira Hondúras),
				'one' => q(lempira Hondúras),
				'other' => q(lempira Hondúras),
				'two' => q(lempira Hondúras),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Dínear na Cróite),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna na Cróite),
				'few' => q(kuna na Cróite),
				'many' => q(kuna na Cróite),
				'one' => q(kuna na Cróite),
				'other' => q(kuna na Cróite),
				'two' => q(kuna na Cróite),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Háítí),
				'few' => q(ghourde Háítí),
				'many' => q(ngourde Háítí),
				'one' => q(ghourde Háítí),
				'other' => q(gourde Háítí),
				'two' => q(ghourde Háítí),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint na hUngáire),
				'few' => q(fhorint na hUngáire),
				'many' => q(bhforint na hUngáire),
				'one' => q(fhorint na hUngáire),
				'other' => q(forint na hUngáire),
				'two' => q(fhorint na hUngáire),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah na hIndinéise),
				'few' => q(rupiah na hIndinéise),
				'many' => q(rupiah na hIndinéise),
				'one' => q(rupiah na hIndinéise),
				'other' => q(rupiah na hIndinéise),
				'two' => q(rupiah na hIndinéise),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Punt Éireannach),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Punt Iosraelach),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Seiceal Nua Iosrael),
				'few' => q(sheiceal nua Iosrael),
				'many' => q(seiceal nua Iosrael),
				'one' => q(seiceal nua Iosrael),
				'other' => q(seiceal nua Iosrael),
				'two' => q(sheiceal nua Iosrael),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rúipí na hIndia),
				'few' => q(rúipí na hIndia),
				'many' => q(rúipí na hIndia),
				'one' => q(rúipí na hIndia),
				'other' => q(rúipí na hIndia),
				'two' => q(rúipí na hIndia),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar na hIaráice),
				'few' => q(dhinar na hIaráice),
				'many' => q(ndinar na hIaráice),
				'one' => q(dinar na hIaráice),
				'other' => q(dinar na hIaráice),
				'two' => q(dhinar na hIaráice),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial na hIaráine),
				'few' => q(rial na hIaráine),
				'many' => q(rial na hIaráine),
				'one' => q(rial na hIaráine),
				'other' => q(rial na hIaráine),
				'two' => q(rial na hIaráine),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Króna na hÍoslainne),
				'few' => q(króna na hÍoslainne),
				'many' => q(króna na hÍoslainne),
				'one' => q(króna na hÍoslainne),
				'other' => q(króna na hÍoslainne),
				'two' => q(króna na hÍoslainne),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira na hIodáile),
				'few' => q(lira na hIodáile),
				'many' => q(lira na hIodáile),
				'one' => q(lira na hIodáile),
				'other' => q(lira na hIodáile),
				'two' => q(lira na hIodáile),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dollar na hIamáice),
				'few' => q(dhollar na hIamáice),
				'many' => q(ndollar na hIamáice),
				'one' => q(dollar na hIamáice),
				'other' => q(dollar na hIamáice),
				'two' => q(dhollar na hIamáice),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar na hIordáine),
				'few' => q(dhinar na hIordáine),
				'many' => q(ndinar na hIordáine),
				'one' => q(dinar na hIordáine),
				'other' => q(dinar na hIordáine),
				'two' => q(dhinar na hIordáine),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen na Seapáine),
				'few' => q(yen na Seapáine),
				'many' => q(yen na Seapáine),
				'one' => q(yen na Seapáine),
				'other' => q(yen na Seapáine),
				'two' => q(yen na Seapáine),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Scilling na Céinia),
				'few' => q(scilling na Céinia),
				'many' => q(scilling na Céinia),
				'one' => q(scilling na Céinia),
				'other' => q(scilling na Céinia),
				'two' => q(scilling na Céinia),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som na Cirgeastáine),
				'few' => q(shom na Cirgeastáine),
				'many' => q(som na Cirgeastáine),
				'one' => q(som na Cirgeastáine),
				'other' => q(som na Cirgeastáine),
				'two' => q(shom na Cirgeastáine),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel na Cambóide),
				'few' => q(riel na Cambóide),
				'many' => q(riel na Cambóide),
				'one' => q(riel na Cambóide),
				'other' => q(riel na Cambóide),
				'two' => q(riel na Cambóide),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Oileáin Chomóra),
				'few' => q(fhranc Oileáin Chomóra),
				'many' => q(bhfranc Oileáin Chomóra),
				'one' => q(fhranc Oileáin Chomóra),
				'other' => q(franc Oileáin Chomóra),
				'two' => q(fhranc Oileáin Chomóra),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won na Cóiré Thuaidh),
				'few' => q(won na Cóiré Thuaidh),
				'many' => q(won na Cóiré Thuaidh),
				'one' => q(won na Cóiré Thuaidh),
				'other' => q(won na Cóiré Thuaidh),
				'two' => q(won na Cóiré Thuaidh),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won na Cóiré Theas),
				'few' => q(won na Cóiré Theas),
				'many' => q(won na Cóiré Theas),
				'one' => q(won na Cóiré Theas),
				'other' => q(won na Cóiré Theas),
				'two' => q(won na Cóiré Theas),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Chuáit),
				'few' => q(dhinar Chuáit),
				'many' => q(ndinar Chuáit),
				'one' => q(dinar Chuáit),
				'other' => q(dinar Chuáit),
				'two' => q(dhinar Chuáit),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dollar Oileáin Cayman),
				'few' => q(dhollar Oileáin Cayman),
				'many' => q(ndollar Oileáin Cayman),
				'one' => q(dollar Oileáin Cayman),
				'other' => q(dollar Oileáin Cayman),
				'two' => q(dhollar Oileáin Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge na Casacstáine),
				'few' => q(thenge na Casacstáine),
				'many' => q(dtenge na Casacstáine),
				'one' => q(tenge na Casacstáine),
				'other' => q(tenge na Casacstáine),
				'two' => q(thenge na Casacstáine),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
				'few' => q(kip Laos),
				'many' => q(kip Laos),
				'one' => q(kip Laos),
				'other' => q(kip Laos),
				'two' => q(kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Punt na Liobáine),
				'few' => q(phunt na Liobáine),
				'many' => q(bpunt na Liobáine),
				'one' => q(phunt na Liobáine),
				'other' => q(punt na Liobáine),
				'two' => q(phunt na Liobáine),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rúipí Shrí Lanca),
				'few' => q(rúipí Shrí Lanca),
				'many' => q(rúipí Shrí Lanca),
				'one' => q(rúipí Shrí Lanca),
				'other' => q(rúipí Shrí Lanca),
				'two' => q(rúipí Shrí Lanca),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dollar na Libéire),
				'few' => q(dhollar na Libéire),
				'many' => q(ndollar na Libéire),
				'one' => q(dollar na Libéire),
				'other' => q(dollar na Libéire),
				'two' => q(dhollar na Libéire),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Leosóta),
				'few' => q(loti Leosóta),
				'many' => q(loti Leosóta),
				'one' => q(loti Leosóta),
				'other' => q(loti Leosóta),
				'two' => q(Loti Leosóta),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas na Liotuáine),
				'few' => q(litas na Liotuáine),
				'many' => q(litas na Liotuáine),
				'one' => q(litas na Liotuáine),
				'other' => q(litas na Liotuáine),
				'two' => q(litas na Liotuáine),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Talonas Liotuánach),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Franc Inmhalartach Lucsamburgach),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Franc Lucsamburg),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats na Laitvia),
				'few' => q(lats na Laitvia),
				'many' => q(lats na Laitvia),
				'one' => q(lats na Laitvia),
				'other' => q(lats na Laitvia),
				'two' => q(lats na Laitvia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rúbal na Laitvia),
				'few' => q(Rúbal Laitviach),
				'many' => q(Rúbal Laitviach),
				'one' => q(Rúbal Laitviach),
				'other' => q(Rúbal Laitviach),
				'two' => q(Rúbal Laitviach),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar na Libia),
				'few' => q(dhinar na Libia),
				'many' => q(ndinar na Libia),
				'one' => q(dinar na Libia),
				'other' => q(dinar na Libia),
				'two' => q(dhinar na Libia),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Mharacó),
				'few' => q(dhirham Mharacó),
				'many' => q(ndirham Mharacó),
				'one' => q(dirham Mharacó),
				'other' => q(dirham Mharacó),
				'two' => q(dhirham Mharacó),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Franc Mharacó),
				'few' => q(fhranc Mharacó),
				'many' => q(bhfranc Mharacó),
				'one' => q(fhranc Mharacó),
				'other' => q(franc Mharacó),
				'two' => q(fhranc Mharacó),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu na Moldóive),
				'few' => q(leu na Moldóive),
				'many' => q(leu na Moldóive),
				'one' => q(leu na Moldóive),
				'other' => q(leu na Moldóive),
				'two' => q(leu na Moldóive),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Mhadagascar),
				'few' => q(ariary Mhadagascar),
				'many' => q(n-ariary Mhadagascar),
				'one' => q(ariary Mhadagascar),
				'other' => q(ariary Mhadagascar),
				'two' => q(ariary Mhadagascar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Franc Madagascar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar na Macadóine),
				'few' => q(dhenar na Macadóine),
				'many' => q(ndenar na Macadóine),
				'one' => q(denar na Macadóine),
				'other' => q(denar na Macadóine),
				'two' => q(dhenar na Macadóine),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Franc Mhailí),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Mhaenmar),
				'few' => q(kyat Mhaenmar),
				'many' => q(kyat Mhaenmar),
				'one' => q(kyat Mhaenmar),
				'other' => q(kyat Mhaenmar),
				'two' => q(kyat Mhaenmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik na Mongóile),
				'few' => q(thugrik na Mongóile),
				'many' => q(dtugrik na Mongóile),
				'one' => q(tugrik na Mongóile),
				'other' => q(tugrik na Mongóile),
				'two' => q(thugrik na Mongóile),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Mhacao),
				'few' => q(phataca Mhacao),
				'many' => q(bpataca Mhacao),
				'one' => q(phataca Mhacao),
				'other' => q(pataca Mhacao),
				'two' => q(phataca Mhacao),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya na Máratáine \(1973–2017\)),
				'few' => q(ouguiya na Máratáine \(1973–2017\)),
				'many' => q(n-ouguiya na Máratáine \(1973–2017\)),
				'one' => q(ouguiya na Máratáine \(1973–2017\)),
				'other' => q(ouguiya na Máratáine \(1973–2017\)),
				'two' => q(ouguiya na Máratáine \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya na Máratáine),
				'few' => q(ouguiya na Máratáine),
				'many' => q(n-ouguiya na Máratáine),
				'one' => q(ouguiya na Máratáine),
				'other' => q(ouguiya na Máratáine),
				'two' => q(ouguiya na Máratáine),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lira Mhálta),
				'few' => q(lira Mhálta),
				'many' => q(lira Mhálta),
				'one' => q(lira Mhálta),
				'other' => q(lira Mhálta),
				'two' => q(lira Mhálta),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Punt Mhálta),
				'few' => q(phunt Mhálta),
				'many' => q(bpunt Mhálta),
				'one' => q(phunt Mhálta),
				'other' => q(punt Mhálta),
				'two' => q(phunt Mhálta),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rúipí Oileán Mhuirís),
				'few' => q(rúipí Oileán Mhuirís),
				'many' => q(rúipí Oileán Mhuirís),
				'one' => q(rúipí Oileán Mhuirís),
				'other' => q(rúipí Oileán Mhuirís),
				'two' => q(rúipí Oileán Mhuirís),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rúipí Oileáin Mhaildíve),
				'few' => q(rúipí Oileáin Mhaildíve),
				'many' => q(rúipí Oileáin Mhaildíve),
				'one' => q(rúipí Oileáin Mhaildíve),
				'other' => q(rúipí Oileáin Mhaildíve),
				'two' => q(rúipí Oileáin Mhaildíve),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Oileáin Mhaildíve),
				'few' => q(rufiyaa Oileáin Mhaildíve),
				'many' => q(rufiyaa Oileáin Mhaildíve),
				'one' => q(rufiyaa Oileáin Mhaildíve),
				'other' => q(rufiyaa Oileáin Mhaildíve),
				'two' => q(rufiyaa Oileáin Mhaildíve),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha na Maláive),
				'few' => q(kwacha na Maláive),
				'many' => q(kwacha na Maláive),
				'one' => q(kwacha na Maláive),
				'other' => q(kwacha na Maláive),
				'two' => q(kwacha na Maláive),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mheicsiceo),
				'few' => q(pheso Mheicsiceo),
				'many' => q(bpeso Mheicsiceo),
				'one' => q(pheso Mheicsiceo),
				'other' => q(peso Mheicsiceo),
				'two' => q(pheso Mheicsiceo),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso Airgid Mheicsiceo \(1861–1992\)),
				'few' => q(pheso airgid Mheicsiceo \(1861–1992\)),
				'many' => q(bpeso airgid Mheicsiceo \(1861–1992\)),
				'one' => q(pheso airgid Mheicsiceo \(1861–1992\)),
				'other' => q(peso airgid Mheicsiceo \(1861–1992\)),
				'two' => q(pheso airgid Mheicsiceo \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Aonad Infheistíochta Meicsiceach),
				'few' => q(Unidad de Inversion \(UDI\) Meicsiceo),
				'many' => q(Unidad de Inversion \(UDI\) Meicsiceo),
				'one' => q(Unidad de Inversion \(UDI\) Meicsiceo),
				'other' => q(Unidad de Inversion \(UDI\) Meicsiceo),
				'two' => q(Unidad de Inversion \(UDI\) Meicsiceo),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit na Malaeisia),
				'few' => q(ringgit na Malaeisia),
				'many' => q(ringgit na Malaeisia),
				'one' => q(ringgit na Malaeisia),
				'other' => q(ringgit na Malaeisia),
				'two' => q(ringgit na Malaeisia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mósaimbíce),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical Mósaimbíce),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mhósaimbíc),
				'few' => q(mhetical Mhósaimbíc),
				'many' => q(metical Mhósaimbíc),
				'one' => q(mhetical Mhósaimbíc),
				'other' => q(metical Mhósaimbíc),
				'two' => q(mhetical Mhósaimbíc),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dollar na Namaibe),
				'few' => q(dhollar na Namaibe),
				'many' => q(ndollar na Namaibe),
				'one' => q(dollar na Namaibe),
				'other' => q(dollar na Namaibe),
				'two' => q(dhollar na Namaibe),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira na Nigéire),
				'few' => q(naira na Nigéire),
				'many' => q(naira na Nigéire),
				'one' => q(naira na Nigéire),
				'other' => q(naira na Nigéire),
				'two' => q(naira na Nigéire),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba Nicearagua \(1988–1991\)),
				'few' => q(chórdoba Nicearagua \(1988–1991\)),
				'many' => q(gcórdoba Nicearagua \(1988–1991\)),
				'one' => q(chórdoba Nicearagua \(1988–1991\)),
				'other' => q(córdoba Nicearagua \(1988–1991\)),
				'two' => q(chórdoba Nicearagua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba Nicearagua),
				'few' => q(chórdoba Nicearagua),
				'many' => q(gcórdoba Nicearagua),
				'one' => q(chórdoba Nicearagua),
				'other' => q(córdoba Nicearagua),
				'two' => q(chórdoba Nicearagua),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Guilder Ísiltíreach),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Coróin na hIorua),
				'few' => q(choróin na hIorua),
				'many' => q(gcoróin na hIorua),
				'one' => q(choróin na hIorua),
				'other' => q(coróin na hIorua),
				'two' => q(choróin na hIorua),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rúipí Neipeal),
				'few' => q(rúipí Neipeal),
				'many' => q(rúipí Neipeal),
				'one' => q(rúipí Neipeal),
				'other' => q(rúipí Neipeal),
				'two' => q(rúipí Neipeal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dollar na Nua-Shéalainne),
				'few' => q(dhollar na Nua-Shéalainne),
				'many' => q(ndollar na Nua-Shéalainne),
				'one' => q(dollar na Nua-Shéalainne),
				'other' => q(dollar na Nua-Shéalainne),
				'two' => q(dhollar na Nua-Shéalainne),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Óman),
				'few' => q(rial Óman),
				'many' => q(rial Óman),
				'one' => q(rial Óman),
				'other' => q(rial Óman),
				'two' => q(rial Óman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Phanama),
				'few' => q(bhalboa Phanama),
				'many' => q(mbalboa Phanama),
				'one' => q(bhalboa Phanama),
				'other' => q(balboa Phanama),
				'two' => q(bhalboa Phanama),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Inti Pheiriú),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Pheiriú),
				'few' => q(sol Pheiriú),
				'many' => q(sol Pheiriú),
				'one' => q(sol Pheiriú),
				'other' => q(Sol Pheiriú),
				'two' => q(shol Pheiriú),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol Pheiriú \(1863–1965\)),
				'few' => q(shol Pheiriú \(1863–1965\)),
				'many' => q(sol Pheiriú \(1863–1965\)),
				'one' => q(sol Pheiriú \(1863–1965\)),
				'other' => q(sol Pheiriú \(1863–1965\)),
				'two' => q(shol Pheiriú \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Nua-Ghuine Phapua),
				'few' => q(kina Nua-Ghuine Phapua),
				'many' => q(kina Nua-Ghuine Phapua),
				'one' => q(kina Nua-Ghuine Phapua),
				'other' => q(kina Nua-Ghuine Phapua),
				'two' => q(kina Nua-Ghuine Phapua),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Peso na nOileán Filipíneach),
				'few' => q(pheso na nOileán Filipíneach),
				'many' => q(bpeso na nOileán Filipíneach),
				'one' => q(pheso na nOileán Filipíneach),
				'other' => q(peso na nOileán Filipíneach),
				'two' => q(pheso na nOileán Filipíneach),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rúipí na Pacastáine),
				'few' => q(rúipí na Pacastáine),
				'many' => q(rúipí na Pacastáine),
				'one' => q(rúipí na Pacastáine),
				'other' => q(rúipí na Pacastáine),
				'two' => q(rúipí na Pacastáine),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty na Polainne),
				'few' => q(zloty na Polainne),
				'many' => q(zloty na Polainne),
				'one' => q(zloty na Polainne),
				'other' => q(zloty na Polainne),
				'two' => q(zloty na Polainne),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Zloty Polannach \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Escudo na Portaingéile),
				'few' => q(escudo na Portaingéile),
				'many' => q(n-escudo na Portaingéile),
				'one' => q(escudo na Portaingéile),
				'other' => q(escudo na Portaingéile),
				'two' => q(escudo na Portaingéile),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guaraní Pharagua),
				'few' => q(ghuaraní Pharagua),
				'many' => q(nguaraní Pharagua),
				'one' => q(ghuaraní Pharagua),
				'other' => q(guaraní Pharagua),
				'two' => q(ghuaraní Pharagua),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyal Chatar),
				'few' => q(riyal Chatar),
				'many' => q(riyal Chatar),
				'one' => q(riyal Chatar),
				'other' => q(riyal Chatar),
				'two' => q(riyal Chatar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Leu na Rómáine \(1952–2006\)),
				'few' => q(leu na Rómáine \(1952–2006\)),
				'many' => q(leu na Rómáine \(1952–2006\)),
				'one' => q(leu na Rómáine \(1952–2006\)),
				'other' => q(leu na Rómáine \(1952–2006\)),
				'two' => q(leu na Rómáine \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu na Rómáine),
				'few' => q(leu na Rómáine),
				'many' => q(leu na Rómáine),
				'one' => q(leu na Rómáine),
				'other' => q(leu na Rómáine),
				'two' => q(leu na Rómáine),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar na Seirbia),
				'few' => q(dhinar na Seirbia),
				'many' => q(ndinar na Seirbia),
				'one' => q(dinar na Seirbia),
				'other' => q(dinar na Seirbia),
				'two' => q(dhinar na Seirbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rúbal na Rúise),
				'few' => q(rúbal na Rúise),
				'many' => q(rúbal na Rúise),
				'one' => q(rúbal na Rúise),
				'other' => q(rúbal na Rúise),
				'two' => q(rúbal na Rúise),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rúbal na Rúise \(1991–1998\)),
				'few' => q(rúbal na Rúise \(1991–1998\)),
				'many' => q(rúbal na Rúise \(1991–1998\)),
				'one' => q(rúbal na Rúise \(1991–1998\)),
				'other' => q(rúbal na Rúise \(1991–1998\)),
				'two' => q(rúbal na Rúise \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Ruanda),
				'few' => q(fhranc Ruanda),
				'many' => q(bhfranc Ruanda),
				'one' => q(fhranc Ruanda),
				'other' => q(franc Ruanda),
				'two' => q(fhranc Ruanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal na hAraibe Sádaí),
				'few' => q(riyal na hAraibe Sádaí),
				'many' => q(riyal na hAraibe Sádaí),
				'one' => q(riyal na hAraibe Sádaí),
				'other' => q(riyal na hAraibe Sádaí),
				'two' => q(riyal na hAraibe Sádaí),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dollar Oileáin Sholomón),
				'few' => q(dhollar Oileáin Sholomón),
				'many' => q(ndollar Oileáin Sholomón),
				'one' => q(dollar Oileáin Sholomón),
				'other' => q(dollar Oileáin Sholomón),
				'two' => q(dhollar Oileáin Sholomón),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rúipí na Séiséal),
				'few' => q(rúipí na Séiséal),
				'many' => q(rúipí na Séiséal),
				'one' => q(rúipí na Séiséal),
				'other' => q(rúipí na Séiséal),
				'two' => q(rúipí na Séiséal),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Dinar na Súdáine \(1992–2007\)),
				'few' => q(dhinar na Súdáine \(1992–2007\)),
				'many' => q(ndinar na Súdáine \(1992–2007\)),
				'one' => q(dinar na Súdáine \(1992–2007\)),
				'other' => q(dinar na Súdáine \(1992–2007\)),
				'two' => q(dhinar na Súdáine \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Punt na Súdáine),
				'few' => q(phunt na Súdáine),
				'many' => q(bpunt na Súdáine),
				'one' => q(phunt na Súdáine),
				'other' => q(punt na Súdáine),
				'two' => q(phunt na Súdáine),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Punt na Súdáine \(1957–1998\)),
				'few' => q(phunt na Súdáine \(1957–1998\)),
				'many' => q(bpunt na Súdáine \(1957–1998\)),
				'one' => q(phunt na Súdáine \(1957–1998\)),
				'other' => q(punt na Súdáine \(1957–1998\)),
				'two' => q(phunt na Súdáine \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Coróin na Sualainne),
				'few' => q(choróin na Sualainne),
				'many' => q(gcoróin na Sualainne),
				'one' => q(choróin na Sualainne),
				'other' => q(coróin na Sualainne),
				'two' => q(choróin na Sualainne),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dollar Shingeapór),
				'few' => q(dhollar Shingeapór),
				'many' => q(ndollar Shingeapór),
				'one' => q(dollar Shingeapór),
				'other' => q(dollar Shingeapór),
				'two' => q(dhollar Shingeapór),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Punt San Héilin),
				'few' => q(phunt San Héilin),
				'many' => q(bpunt San Héilin),
				'one' => q(phunt San Héilin),
				'other' => q(punt San Héilin),
				'two' => q(phunt San Héilin),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar na Slóivéine),
				'few' => q(tholar na Slóivéine),
				'many' => q(dtolar na Slóivéine),
				'one' => q(tolar na Slóivéine),
				'other' => q(tolar na Slóivéine),
				'two' => q(tholar na Slóivéine),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Koruna na Slóvaice),
				'few' => q(koruna na Slóvaice),
				'many' => q(koruna na Slóvaice),
				'one' => q(koruna na Slóvaice),
				'other' => q(koruna na Slóvaice),
				'two' => q(koruna na Slóvaice),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Shiarra Leon),
				'few' => q(leone Shiarra Leon),
				'many' => q(leone Shiarra Leon),
				'one' => q(leone Shiarra Leon),
				'other' => q(leone Shiarra Leon),
				'two' => q(leone Shiarra Leon),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Shiarra Leon \(1964—2022\)),
				'few' => q(leone Shiarra Leon \(1964—2022\)),
				'many' => q(leone Shiarra Leon \(1964—2022\)),
				'one' => q(leone Shiarra Leon \(1964—2022\)),
				'other' => q(leone Shiarra Leon \(1964—2022\)),
				'two' => q(leone Shiarra Leon \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Scilling na Somáile),
				'few' => q(scilling na Somáile),
				'many' => q(scilling na Somáile),
				'one' => q(scilling na Somáile),
				'other' => q(scilling na Somáile),
				'two' => q(scilling na Somáile),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dollar Shuranam),
				'few' => q(dhollar Shuranam),
				'many' => q(ndollar Shuranam),
				'one' => q(dollar Shuranam),
				'other' => q(dollar Shuranam),
				'two' => q(dhollar Shuranam),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Gildear Shuranam),
				'few' => q(ghildear Shuranam),
				'many' => q(ngildear Shuranam),
				'one' => q(ghildear Shuranam),
				'other' => q(gildear Shuranam),
				'two' => q(ghildear Shuranam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Punt na Súdáine Theas),
				'few' => q(phunt na Súdáine Theas),
				'many' => q(bpunt na Súdáine Theas),
				'one' => q(phunt na Súdáine Theas),
				'other' => q(punt na Súdáine Theas),
				'two' => q(phunt na Súdáine Theas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra São Tomé agus Príncipe \(1977–2017\)),
				'few' => q(dhobra São Tomé agus Príncipe \(1977–2017\)),
				'many' => q(ndobra São Tomé agus Príncipe \(1977–2017\)),
				'one' => q(dobra São Tomé agus Príncipe \(1977–2017\)),
				'other' => q(dobra São Tomé agus Príncipe \(1977–2017\)),
				'two' => q(dhobra São Tomé agus Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra São Tomé agus Príncipe),
				'few' => q(dhobra São Tomé agus Príncipe),
				'many' => q(ndobra São Tomé agus Príncipe),
				'one' => q(dobra São Tomé agus Príncipe),
				'other' => q(dobra São Tomé agus Príncipe),
				'two' => q(dhobra São Tomé agus Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Rúbal an Aontais Shóivéadaigh),
				'few' => q(rúbal an Aontais Shóivéadaigh),
				'many' => q(rúbal an Aontais Shóivéadaigh),
				'one' => q(rúbal an Aontais Shóivéadaigh),
				'other' => q(rúbal an Aontais Shóivéadaigh),
				'two' => q(rúbal an Aontais Shóivéadaigh),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colón na Salvadóire),
				'few' => q(cholón na Salvadóire),
				'many' => q(gcolón na Salvadóire),
				'one' => q(cholón na Salvadóire),
				'other' => q(colón na Salvadóire),
				'two' => q(cholón na Salvadóire),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Punt na Siria),
				'few' => q(phunt na Siria),
				'many' => q(bpunt na Siria),
				'one' => q(phunt na Siria),
				'other' => q(punt na Siria),
				'two' => q(phunt na Siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni na Suasalainne),
				'few' => q(lilangeni na Suasalainne),
				'many' => q(lilangeni na Suasalainne),
				'one' => q(lilangeni na Suasalainne),
				'other' => q(lilangeni na Suasalainne),
				'two' => q(lilangeni na Suasalainne),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht na Téalainne),
				'few' => q(bhaht na Téalainne),
				'many' => q(mbaht na Téalainne),
				'one' => q(bhaht na Téalainne),
				'other' => q(baht na Téalainne),
				'two' => q(bhaht na Téalainne),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Rúbal na Táidsíceastáine),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni na Táidsíceastáine),
				'few' => q(shomoni na Táidsíceastáine),
				'many' => q(somoni na Táidsíceastáine),
				'one' => q(somoni na Táidsíceastáine),
				'other' => q(somoni na Táidsíceastáine),
				'two' => q(shomoni na Táidsíceastáine),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manat na Tuircméanastáine \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat na Tuircméanastáine),
				'few' => q(mhanat na Tuircméanastáine),
				'many' => q(manat na Tuircméanastáine),
				'one' => q(mhanat na Tuircméanastáine),
				'other' => q(manat na Tuircméanastáine),
				'two' => q(mhanat na Tuircméanastáine),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar na Túinéise),
				'few' => q(dhinar na Túinéise),
				'many' => q(ndinar na Túinéise),
				'one' => q(dinar na Túinéise),
				'other' => q(dinar na Túinéise),
				'two' => q(dhinar na Túinéise),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Thonga),
				'few' => q(phaʻanga Thonga),
				'many' => q(bpaʻanga Thonga),
				'one' => q(phaʻanga Thonga),
				'other' => q(paʻanga Thonga),
				'two' => q(phaʻanga Thonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo Tíomóir),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lira na Tuirce \(1922–2005\)),
				'few' => q(lira na Tuirce \(1922–2005\)),
				'many' => q(lira na Tuirce \(1922–2005\)),
				'one' => q(lira na Tuirce \(1922–2005\)),
				'other' => q(lira na Tuirce \(1922–2005\)),
				'two' => q(lira na Tuirce \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira na Tuirce),
				'few' => q(lira na Tuirce),
				'many' => q(lira na Tuirce),
				'one' => q(lira na Tuirce),
				'other' => q(lira na Tuirce),
				'two' => q(lira na Tuirce),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dollar Oileán na Tríonóide agus Tobága),
				'few' => q(dhollar Oileán na Tríonóide agus Tobága),
				'many' => q(ndollar Oileán na Tríonóide agus Tobága),
				'one' => q(dollar Oileán na Tríonóide agus Tobága),
				'other' => q(dollar Oileán na Tríonóide agus Tobága),
				'two' => q(dhollar Oileán na Tríonóide agus Tobága),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dollar Nua na Téaváine),
				'few' => q(dhollar nua na Téaváine),
				'many' => q(ndollar nua na Téaváine),
				'one' => q(dollar nua na Téaváine),
				'other' => q(dollar nua na Téaváine),
				'two' => q(dhollar nua na Téaváine),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Scilling na Tansáine),
				'few' => q(scilling na Tansáine),
				'many' => q(scilling na Tansáine),
				'one' => q(scilling na Tansáine),
				'other' => q(scilling na Tansáine),
				'two' => q(scilling na Tansáine),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia na hÚcráine),
				'few' => q(hryvnia na hÚcráine),
				'many' => q(hryvnia na hÚcráine),
				'one' => q(hryvnia na hÚcráine),
				'other' => q(hryvnia na hÚcráine),
				'two' => q(hryvnia na hÚcráine),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Karbovanets Úcránach),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Scilling Uganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Scilling Uganda),
				'few' => q(scilling Uganda),
				'many' => q(scilling Uganda),
				'one' => q(scilling Uganda),
				'other' => q(scilling Uganda),
				'two' => q(scilling Uganda),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dollar S.A.M.),
				'few' => q(dhollar S.A.M.),
				'many' => q(ndollar S.A.M.),
				'one' => q(dollar S.A.M.),
				'other' => q(dollar S.A.M.),
				'two' => q(dhollar S.A.M.),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dollar S.A.M. \(an chéad lá eile\)),
				'few' => q(dhollar S.A.M. \(an chéad lá eile\)),
				'many' => q(ndollar S.A.M. \(an chéad lá eile\)),
				'one' => q(dollar S.A.M. \(an chéad lá eile\)),
				'other' => q(dollar S.A.M. \(an chéad lá eile\)),
				'two' => q(dhollar S.A.M. \(an chéad lá eile\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dollar S.A.M. \(an lá céanna\)),
				'few' => q(dhollar S.A.M. \(an lá céanna\)),
				'many' => q(ndollar S.A.M. \(an lá céanna\)),
				'one' => q(dollar S.A.M. \(an lá céanna\)),
				'other' => q(dollar S.A.M. \(an lá céanna\)),
				'two' => q(dhollar S.A.M. \(an lá céanna\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso Uragua \(1975–1993\)),
				'few' => q(pheso Uragua \(1975–1993\)),
				'many' => q(bpeso Uragua \(1975–1993\)),
				'one' => q(pheso Uragua \(1975–1993\)),
				'other' => q(peso Uragua \(1975–1993\)),
				'two' => q(pheso Uragua \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uragua),
				'few' => q(pheso Uragua),
				'many' => q(bpeso Uragua),
				'one' => q(pheso Uragua),
				'other' => q(peso Uragua),
				'two' => q(pheso Uragua),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sum na hÚisbéiceastáine),
				'few' => q(shum na hÚisbéiceastáine),
				'many' => q(sum na hÚisbéiceastáine),
				'one' => q(sum na hÚisbéiceastáine),
				'other' => q(sum na hÚisbéiceastáine),
				'two' => q(shum na hÚisbéiceastáine),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar Veiniséala \(1871–2008\)),
				'few' => q(bholívar Veiniséala \(1871–2008\)),
				'many' => q(mbolívar Veiniséala \(1871–2008\)),
				'one' => q(bholívar Veiniséala \(1871–2008\)),
				'other' => q(bolívar Veiniséala \(1871–2008\)),
				'two' => q(bholívar Veiniséala \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar Veiniséala \(2008–2018\)),
				'few' => q(bholívar Veiniséala \(2008–2018\)),
				'many' => q(mbolívar Veiniséala \(2008–2018\)),
				'one' => q(bholívar Veiniséala \(2008–2018\)),
				'other' => q(bolívar Veiniséala \(2008–2018\)),
				'two' => q(bholívar Veiniséala \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar Veiniséala),
				'few' => q(bholívar Veiniséala),
				'many' => q(mbolívar Veiniséala),
				'one' => q(bholívar Veiniséala),
				'other' => q(bolívar Veiniséala),
				'two' => q(bholívar Veiniséala),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vítneam),
				'few' => q(dhong Vítneam),
				'many' => q(ndong Vítneam),
				'one' => q(dong Vítneam),
				'other' => q(Dong Vítneam),
				'two' => q(dhong Vítneam),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong Vítneam \(1978–1985\)),
				'few' => q(dhong Vítneam \(1978–1985\)),
				'many' => q(ndong Vítneam \(1978–1985\)),
				'one' => q(dong Vítneam \(1978–1985\)),
				'other' => q(dong Vítneam \(1978–1985\)),
				'two' => q(dhong Vítneam \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatú),
				'few' => q(vatu Vanuatú),
				'many' => q(vatu Vanuatú),
				'one' => q(vatu Vanuatú),
				'other' => q(vatu Vanuatú),
				'two' => q(vatu Vanuatú),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Shamó),
				'few' => q(thala Shamó),
				'many' => q(dtala Shamó),
				'one' => q(tala Shamó),
				'other' => q(tala Shamó),
				'two' => q(thala Shamó),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franc CFA na hAfraice Láir),
				'few' => q(fhranc CFA na hAfraice Láir),
				'many' => q(bhfranc CFA na hAfraice Láir),
				'one' => q(fhranc CFA na hAfraice Láir),
				'other' => q(franc CFA na hAfraice Láir),
				'two' => q(fhranc CFA na hAfraice Láir),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Airgead),
				'few' => q(unsaí troí airgid),
				'many' => q(unsaí troí airgid),
				'one' => q(unsa troí airgid),
				'other' => q(unsaí troí airgid),
				'two' => q(unsa troí airgid),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Ór),
				'few' => q(unsaí troí óir),
				'many' => q(unsaí troí óir),
				'one' => q(unsa troí óir),
				'other' => q(unsaí troí óir),
				'two' => q(unsa troí óir),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Aonad Ilchodach Eorpach),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Aonad Airgeadaíochta Eorpach),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Aonad Cuntais Eorpach \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Aonad Cuntais Eorpach \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dollar na Cairibe Thoir),
				'few' => q(dhollar na Cairibe Thoir),
				'many' => q(ndollar na Cairibe Thoir),
				'one' => q(dollar na Cairibe Thoir),
				'other' => q(dollar na Cairibe Thoir),
				'two' => q(dhollar na Cairibe Thoir),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Cearta Speisialta Tarraingthe),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Aonad Airgeadra Eorpach),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franc Ór Francach),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(UIC-Franc Francach),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA Iarthar na hAfraice),
				'few' => q(fhranc CFA Iarthar na hAfraice),
				'many' => q(bhfranc CFA Iarthar na hAfraice),
				'one' => q(fhranc CFA Iarthar na hAfraice),
				'other' => q(franc CFA Iarthar na hAfraice),
				'two' => q(fhranc CFA Iarthar na hAfraice),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Pallaidiam),
				'few' => q(unsaí troí pallaidiam),
				'many' => q(unsaí troí pallaidiam),
				'one' => q(unsa troí pallaidiam),
				'other' => q(unsaí troí pallaidiam),
				'two' => q(unsa troí pallaidiam),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
				'few' => q(fhranc CFP),
				'many' => q(bhfranc CFP),
				'one' => q(fhranc CFP),
				'other' => q(franc CFP),
				'two' => q(fhranc CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platanam),
				'few' => q(unsaí troí platanaim),
				'many' => q(unsaí troí platanaim),
				'one' => q(unsa troí platanaim),
				'other' => q(unsaí troí platanaim),
				'two' => q(unsa troí platanaim),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Airgeadra Anaithnid),
				'few' => q(\(airgeadra anaithnid\)),
				'many' => q(\(airgeadra anaithnid\)),
				'one' => q(\(airgeadra anaithnid\)),
				'other' => q(\(airgeadra anaithnid\)),
				'two' => q(\(airgeadra anaithnid\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Dínear Éimin),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Éimin),
				'few' => q(rial Éimin),
				'many' => q(rial Éimin),
				'one' => q(rial Éimin),
				'other' => q(rial Éimin),
				'two' => q(rial Éimin),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Dínear Crua Iúgslavach \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Dínear Nua Iúgslavach \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinar Inmhalartaithe Iúgslavach \(1990–1992\)),
				'few' => q(Dínear Inathraithe Iúgslavach),
				'many' => q(Dínear Inathraithe Iúgslavach),
				'one' => q(Dínear Inathraithe Iúgslavach),
				'other' => q(Dínear Inathraithe Iúgslavach),
				'two' => q(Dínear Inathraithe Iúgslavach),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Dinar Leasaithe na hIúgsláive \(1992–1993\)),
				'few' => q(Dinar Leasaithe na hIúgsláive \(1992–1993\)),
				'many' => q(Dinar Leasaithe na hIúgsláive \(1992–1993\)),
				'one' => q(Dinar Leasaithe na hIúgsláive \(1992–1993\)),
				'other' => q(Dinars Leasaithe na hIúgsláive \(1992–1993\)),
				'two' => q(Dinar Leasaithe na hIúgsláive \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand na hAfraice Theas \(airgeadúil\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand na hAfraice Theas),
				'few' => q(rand na hAfraice Theas),
				'many' => q(rand na hAfraice Theas),
				'one' => q(rand na hAfraice Theas),
				'other' => q(rand na hAfraice Theas),
				'two' => q(rand na hAfraice Theas),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha Saimbiach \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha na Saimbia),
				'few' => q(kwacha na Saimbia),
				'many' => q(kwacha na Saimbia),
				'one' => q(kwacha na Saimbia),
				'other' => q(kwacha na Saimbia),
				'two' => q(kwacha na Saimbia),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire Nua Sáíreach),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire Sáíreach),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dollar Siombábach \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Dollar na Siombáibe \(2009\)),
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
							'Ean',
							'Feabh',
							'Márta',
							'Aib',
							'Beal',
							'Meith',
							'Iúil',
							'Lún',
							'MFómh',
							'DFómh',
							'Samh',
							'Noll'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Eanáir',
							'Feabhra',
							'Márta',
							'Aibreán',
							'Bealtaine',
							'Meitheamh',
							'Iúil',
							'Lúnasa',
							'Meán Fómhair',
							'Deireadh Fómhair',
							'Samhain',
							'Nollaig'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'E',
							'F',
							'M',
							'A',
							'B',
							'M',
							'I',
							'L',
							'M',
							'D',
							'S',
							'N'
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
						mon => 'Luan',
						tue => 'Máirt',
						wed => 'Céad',
						thu => 'Déar',
						fri => 'Aoine',
						sat => 'Sath',
						sun => 'Domh'
					},
					short => {
						mon => 'Lu',
						tue => 'Má',
						wed => 'Cé',
						thu => 'Dé',
						fri => 'Ao',
						sat => 'Sa',
						sun => 'Do'
					},
					wide => {
						mon => 'Dé Luain',
						tue => 'Dé Máirt',
						wed => 'Dé Céadaoin',
						thu => 'Déardaoin',
						fri => 'Dé hAoine',
						sat => 'Dé Sathairn',
						sun => 'Dé Domhnaigh'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'C',
						thu => 'D',
						fri => 'A',
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
					abbreviated => {0 => 'R1',
						1 => 'R2',
						2 => 'R3',
						3 => 'R4'
					},
					wide => {0 => '1ú ráithe',
						1 => '2ú ráithe',
						2 => '3ú ráithe',
						3 => '4ú ráithe'
					},
				},
			},
	} },
);

has 'day_periods' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			'format' => {
				'abbreviated' => {
					'am' => q{r.n.},
					'pm' => q{i.n.},
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
				'0' => 'RB'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'RC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'Roimh Chríost',
				'1' => 'Anno Domini'
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
			'short' => q{dd/MM/y},
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
		'buddhist' => {
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
			M => q{LL},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
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
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd/MM/y GGGGG},
			M => q{LL},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'seachtain' 'a' W 'i' MMMM},
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
			yw => q{'seachtain' 'a' w 'in' Y},
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
				h => q{h – h a},
			},
		},
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
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
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
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
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
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
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
				M => q{MM – MM},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
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
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
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
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
		gmtFormat => q(MAG{0}),
		gmtZeroFormat => q(MAG),
		'Acre' => {
			long => {
				'daylight' => q#Am Samhraidh Acre#,
				'generic' => q#Am Acre#,
				'standard' => q#Am Caighdeánach Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Am na hAfganastáine#,
			},
		},
		'Africa/Algiers' => {
			exemplarCity => q#Cathair na hAilgéire#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Caireo#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conacraí#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dacár#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dárasalám#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Láúine#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Cartúm#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Mapútó#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogaidisiú#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuacsat#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripilí#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túinis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Am na hAfraice Láir#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Am Oirthear na hAfraice#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Am na hAfraice Theas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Am Samhraidh Iarthar na hAfraice#,
				'generic' => q#Am Iarthar na hAfraice#,
				'standard' => q#Am Caighdeánach Iarthar na hAfraice#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Am Samhraidh Alasca#,
				'generic' => q#Am Alasca#,
				'standard' => q#Am Caighdeánach Alasca#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Am Samhraidh Almaty#,
				'generic' => q#Am Almaty#,
				'standard' => q#Am Caighdeánach Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Am Samhraidh na hAmasóine#,
				'generic' => q#Am na hAmasóine#,
				'standard' => q#Am Caighdeánach na hAmasóine#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Angaíle#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arúba#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbadós#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#an Bheilís#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogatá#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Cósta Ríce#,
		},
		'America/Curacao' => {
			exemplarCity => q#Cúrasó#,
		},
		'America/Dominica' => {
			exemplarCity => q#Doiminice#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#an tSalvadóir#,
		},
		'America/Grenada' => {
			exemplarCity => q#Greanáda#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalúip#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatamala#,
		},
		'America/Guyana' => {
			exemplarCity => q#an Ghuáin#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Iamáice#,
		},
		'America/Lima' => {
			exemplarCity => q#Líoma#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cathair Mheicsiceo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montsarat#,
		},
		'America/New_York' => {
			exemplarCity => q#Nua-Eabhrac#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Pórtó Ríce#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Críostóir#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Uinseann#,
		},
		'America/Thule' => {
			exemplarCity => q#Inis Tuile#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Am Samhraidh Lárnach Mheiriceá Thuaidh#,
				'generic' => q#Am Lárnach Mheiriceá Thuaidh#,
				'standard' => q#Am Caighdeánach Lárnach Mheiriceá Thuaidh#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Am Samhraidh Oirthearach Mheiriceá Thuaidh#,
				'generic' => q#Am Oirthearach Mheiriceá Thuaidh#,
				'standard' => q#Am Caighdeánach Oirthearach Mheiriceá Thuaidh#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Am Samhraidh Sléibhte Mheiriceá Thuaidh#,
				'generic' => q#Am Sléibhte Mheiriceá Thuaidh#,
				'standard' => q#Am Caighdeánach Sléibhte Mheiriceá Thuaidh#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Am Samhraidh an Aigéin Chiúin#,
				'generic' => q#Am an Aigéin Chiúin#,
				'standard' => q#Am Caighdeánach an Aigéin Chiúin#,
			},
			short => {
				'daylight' => q#ASAC#,
				'generic' => q#AAC#,
				'standard' => q#ACAC#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Am Samhraidh Anadyr#,
				'generic' => q#Am Anadyr#,
				'standard' => q#Am Caighdeánach Anadyr#,
			},
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Mac Guaire#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Am Samhraidh Apia#,
				'generic' => q#Am Apia#,
				'standard' => q#Am Caighdeánach Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Am Samhraidh Aqtau#,
				'generic' => q#Am Aqtau#,
				'standard' => q#Am Caighdeánach Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Am Samhraidh Aqtobe#,
				'generic' => q#Am Aqtobe#,
				'standard' => q#Am Caighdeánach Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Am Samhraidh na hAraibe#,
				'generic' => q#Am na hAraibe#,
				'standard' => q#Am Caighdeánach na hAraibe#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Am Samhraidh na hAirgintíne#,
				'generic' => q#Am na hAirgintíne#,
				'standard' => q#Am Caighdeánach na hAirgintíne#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Am Samhraidh Iartharach na hAirgintíne#,
				'generic' => q#Am Iartharach na hAirgintíne#,
				'standard' => q#Am Caighdeánach Iartharach na hAirgintíne#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Am Samhraidh na hAirméine#,
				'generic' => q#Am na hAirméine#,
				'standard' => q#Am Caighdeánach na hAirméine#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Áidin#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bairéin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baki#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Béiriút#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brúiné#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcúta#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#an Damaisc#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Heabrón#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Cong#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Iacárta#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Iarúsailéim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Cabúl#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Cuáit#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Mainile#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#an Niocóis#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Cathair Ho Chi Minh#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Súl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shang-hai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singeapór#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tóiceo#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Iacútsc#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Eireaván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Am Samhraidh an Atlantaigh#,
				'generic' => q#Am an Atlantaigh#,
				'standard' => q#Am Caighdeánach an Atlantaigh#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#na hAsóir#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Beirmiúda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#na hOileáin Chanáracha#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Rinn Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Oileáin Fharó#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Maidéara#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Réicivíc#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#an tSeoirsia Theas#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#San Héilin#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Am Samhraidh Lár na hAstráile#,
				'generic' => q#Am Lár na hAstráile#,
				'standard' => q#Am Caighdeánach Lár na hAstráile#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Am Samhraidh Mheániarthar na hAstráile#,
				'generic' => q#Am Mheániarthar na hAstráile#,
				'standard' => q#Am Caighdeánach Mheániarthar na hAstráile#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Am Samhraidh Oirthear na hAstráile#,
				'generic' => q#Am Oirthear na hAstráile#,
				'standard' => q#Am Caighdeánach Oirthear na hAstráile#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Am Samhraidh Iarthar na hAstráile#,
				'generic' => q#Am Iarthar na hAstráile#,
				'standard' => q#Am Caighdeánach Iarthar na hAstráile#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Am Samhraidh na hAsarbaiseáine#,
				'generic' => q#Am na hAsarbaiseáine#,
				'standard' => q#Am Caighdeánach na hAsarbaiseáine#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Am Samhraidh na nAsór#,
				'generic' => q#Am na nAsór#,
				'standard' => q#Am Caighdeánach na nAsór#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Am Samhraidh na Banglaidéise#,
				'generic' => q#Am na Banglaidéise#,
				'standard' => q#Am Caighdeánach na Banglaidéise#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Am na Bútáine#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Am na Bolaive#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Am Samhraidh Bhrasília#,
				'generic' => q#Am Bhrasília#,
				'standard' => q#Am Caighdeánach Bhrasília#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Am Bhrúiné Darasalám#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Am Samhraidh Rinn Verde#,
				'generic' => q#Am Rinn Verde#,
				'standard' => q#Am Caighdeánach Rinn Verde#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Am Stáisiún Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Am Caighdeánach Seamórach#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Am Samhraidh Chatham#,
				'generic' => q#Am Chatham#,
				'standard' => q#Am Caighdeánach Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Am Samhraidh na Sile#,
				'generic' => q#Am na Sile#,
				'standard' => q#Am Caighdeánach na Sile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Am Samhraidh na Síne#,
				'generic' => q#Am na Síne#,
				'standard' => q#Am Caighdeánach na Síne#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Am Oileán na Nollag#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Am Oileáin Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Am Samhraidh na Colóime#,
				'generic' => q#Am na Colóime#,
				'standard' => q#Am Caighdeánach na Colóime#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Am Leathshamhraidh Oileáin Cook#,
				'generic' => q#Am Oileáin Cook#,
				'standard' => q#Am Caighdeánach Oileáin Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Am Samhraidh Chúba#,
				'generic' => q#Am Chúba#,
				'standard' => q#Am Caighdeánach Chúba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Am Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Am Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Am Thíomór Thoir#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Am Samhraidh Oileán na Cásca#,
				'generic' => q#Am Oileán na Cásca#,
				'standard' => q#Am Caighdeánach Oileán na Cásca#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Am Eacuadór#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Am Uilíoch Lárnach#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Cathair Anaithnid#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amstardam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andóra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#an Astracáin#,
		},
		'Europe/Athens' => {
			exemplarCity => q#an Aithin#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Béalgrád#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Beirlín#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#an Bhratasláiv#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#an Bhruiséil#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Búcairist#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Búdaipeist#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Císineá#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Cóbanhávan#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Baile Átha Cliath#,
			long => {
				'daylight' => q#Am Caighdéanach na hÉireann#,
			},
			short => {
				'daylight' => q#ACÉ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Giobráltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Geansaí#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Heilsincí#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Oileán Mhanann#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Iostanbúl#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Geirsí#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Cív#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Liospóin#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liúibleána#,
		},
		'Europe/London' => {
			exemplarCity => q#Londain#,
			long => {
				'daylight' => q#Am Samhraidh na Breataine#,
			},
			short => {
				'daylight' => q#ASB#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lucsamburg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Maidrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Málta#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mionsc#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monacó#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscó#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Osló#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Páras#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgairítse#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prág#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Ríge#,
		},
		'Europe/Rome' => {
			exemplarCity => q#an Róimh#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Mairíne#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sairéavó#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Scóipé#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sóifia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stócólm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Taillinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiorána#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vadús#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#an Vatacáin#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vín#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnias#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Vársá#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Ságrab#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Am Samhraidh Lár na hEorpa#,
				'generic' => q#Am Lár na hEorpa#,
				'standard' => q#Am Caighdeánach Lár na hEorpa#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Am Samhraidh Oirthear na hEorpa#,
				'generic' => q#Am Oirthear na hEorpa#,
				'standard' => q#Am Caighdeánach Oirthear na hEorpa#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Am Chianoirthear na hEorpa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Am Samhraidh Iarthar na hEorpa#,
				'generic' => q#Am Iarthar na hEorpa#,
				'standard' => q#Am Caighdeánach Iarthar na hEorpa#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Am Samhraidh Oileáin Fháclainne#,
				'generic' => q#Am Oileáin Fháclainne#,
				'standard' => q#Am Caighdeánach Oileáin Fháclainne#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Am Samhraidh Fhidsí#,
				'generic' => q#Am Fhidsí#,
				'standard' => q#Am Caighdeánach Fhidsí#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Am Ghuáin na Fraince#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Am Francach Dheisceart an Domhain agus an Antartaigh#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Meán-Am Greenwich#,
			},
			short => {
				'standard' => q#MAG#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Am Oileáin Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Am Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Am Samhraidh na Seoirsia#,
				'generic' => q#Am na Seoirsia#,
				'standard' => q#Am Caighdeánach na Seoirsia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Am Chireabaití#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Am Samhraidh Oirthear na Graonlainne#,
				'generic' => q#Am Oirthear na Graonlainne#,
				'standard' => q#Am Caighdeánach Oirthear na Graonlainne#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Am Samhraidh Iarthar na Graonlainne#,
				'generic' => q#Am Iarthar na Graonlainne#,
				'standard' => q#Am Caighdeánach Iarthar na Graonlainne#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Am Caighdeánach Ghuam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Am Caighdeánach na Murascaille#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Am na Guáine#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Am Samhraidh Haváí-Ailiúit#,
				'generic' => q#Am Haváí-Ailiúit#,
				'standard' => q#Am Caighdeánach Haváí-Ailiúit#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Am Samhraidh Hong Cong#,
				'generic' => q#Am Hong Cong#,
				'standard' => q#Am Caighdeánach Hong Cong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Am Samhraidh Hovd#,
				'generic' => q#Am Hovd#,
				'standard' => q#Am Caighdeánach Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Am Caighdeánach na hIndia#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananairíveo#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Oileán na Nollag#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Oileán Cocos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Oileáin Chomóra#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Oileáin Mhaildíve#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Oileán Mhuirís#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#La Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Am an Aigéin Indiaigh#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Am na hInd-Síne#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Am Lár na hIndinéise#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Am Oirthear na hIndinéise#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Am Iarthar na hIndinéise#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Am Samhraidh na hIaráine#,
				'generic' => q#Am na hIaráine#,
				'standard' => q#Am Caighdeánach na hIaráine#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Am Samhraidh Irkutsk#,
				'generic' => q#Am Irkutsk#,
				'standard' => q#Am Caighdeánach Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Am Samhraidh Iosrael#,
				'generic' => q#Am Iosrael#,
				'standard' => q#Am Caighdeánach Iosrael#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Am Samhraidh na Seapáine#,
				'generic' => q#Am na Seapáine#,
				'standard' => q#Am Caighdeánach na Seapáine#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Am Samhraidh Phetropavlovsk-Kamchatski#,
				'generic' => q#Am Phetropavlovsk-Kamchatski#,
				'standard' => q#Am Caighdeánach Phetropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Am na Casacstáine#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Am Oirthear na Casacstáine#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Am Iarthar na Casacstáine#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Am Samhraidh na Cóiré#,
				'generic' => q#Am na Cóiré#,
				'standard' => q#Am Caighdeánach na Cóiré#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Am Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Am Samhraidh Krasnoyarsk#,
				'generic' => q#Am Krasnoyarsk#,
				'standard' => q#Am Caighdeánach Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Am na Cirgeastáine#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Am Shrí Lanca#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Am Oileáin na Líne#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Am Samhraidh Lord Howe#,
				'generic' => q#Am Lord Howe#,
				'standard' => q#Am Caighdeánach Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Am Samhraidh Mhacao#,
				'generic' => q#Am Mhacao#,
				'standard' => q#Am Caighdeánach Mhacao#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Am Samhraidh Mhagadan#,
				'generic' => q#Am Mhagadan#,
				'standard' => q#Am Caighdeánach Mhagadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Am na Malaeisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Am Oileáin Mhaildíve#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Am na nOileán Marcasach#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Am Oileáin Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Am Samhraidh Oileán Mhuirís#,
				'generic' => q#Am Oileán Mhuirís#,
				'standard' => q#Am Caighdeánach Oileán Mhuirís#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Am Mawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Am Samhraidh Meicsiceach an Aigéin Chiúin#,
				'generic' => q#Am Meicsiceach an Aigéin Chiúin#,
				'standard' => q#Am Caighdeánach Meicsiceach an Aigéin Chiúin#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Am Samhraidh Ulánbátar#,
				'generic' => q#Am Ulánbátar#,
				'standard' => q#Am Caighdeánach Ulánbátar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Am Samhraidh Mhoscó#,
				'generic' => q#Am Mhoscó#,
				'standard' => q#Am Caighdeánach Mhoscó#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Am Mhaenmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Am Nárú#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Am Neipeal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Am Samhraidh na Nua-Chaladóine#,
				'generic' => q#Am na Nua-Chaladóine#,
				'standard' => q#Am Caighdeánach na Nua-Chaladóine#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Am Samhraidh na Nua-Shéalainne#,
				'generic' => q#Am na Nua-Shéalainne#,
				'standard' => q#Am Caighdeánach na Nua-Shéalainne#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Am Samhraidh Thalamh an Éisc#,
				'generic' => q#Am Thalamh an Éisc#,
				'standard' => q#Am Caighdeánach Thalamh an Éisc#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Am Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Am Samhraidh Oileán Norfolk#,
				'generic' => q#Am Oileán Norfolk#,
				'standard' => q#Am Caighdeánach Oileán Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Am Samhraidh Fernando de Noronha#,
				'generic' => q#Am Fernando de Noronha#,
				'standard' => q#Am Caighdeánach Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Am na nOileán Máirianach Thuaidh#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Am Samhraidh Novosibirsk#,
				'generic' => q#Am Novosibirsk#,
				'standard' => q#Am Caighdeánach Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Am Samhraidh Omsk#,
				'generic' => q#Am Omsk#,
				'standard' => q#Am Caighdeánach Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidsí#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#na hOileáin Mharcasacha#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Oileáin Midway#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nárú#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taihítí#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Vailís#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Am Samhraidh na Pacastáine#,
				'generic' => q#Am na Pacastáine#,
				'standard' => q#Am Caighdeánach na Pacastáine#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Am Oileáin Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Am Nua-Ghuine Phapua#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Am Samhraidh Pharagua#,
				'generic' => q#Am Pharagua#,
				'standard' => q#Am Caighdeánach Pharagua#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Am Samhraidh Pheiriú#,
				'generic' => q#Am Pheiriú#,
				'standard' => q#Am Caighdeánach Pheiriú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Am Samhraidh na nOileán Filipíneach#,
				'generic' => q#Am na nOileán Filipíneach#,
				'standard' => q#Am Caighdeánach na nOileán Filipíneach#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Am Oileáin an Fhéinics#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Am Samhraidh Saint-Pierre-et-Miquelon#,
				'generic' => q#Am Saint-Pierre-et-Miquelon#,
				'standard' => q#Am Caighdeánach Saint-Pierre-et-Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Am Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Am Phohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Am Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Am Samhraidh Qyzylorda#,
				'generic' => q#Am Qyzylorda#,
				'standard' => q#Am Caighdeánach Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Am Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Am Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Am Samhraidh Shacailín#,
				'generic' => q#Am Shacailín#,
				'standard' => q#Am Caighdeánach Shacailín#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Am Samhraidh Shamara#,
				'generic' => q#Am Shamara#,
				'standard' => q#Am Caighdeánach Shamara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Am Samhraidh Shamó#,
				'generic' => q#Am Shamó#,
				'standard' => q#Am Caighdeánach Shamó#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Am na Séiséal#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Am Caighdeánach Shingeapór#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Am Oileáin Sholaimh#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Am na Seoirsia Theas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Am Shuranam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Am Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Am Thaihítí#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Am Samhraidh Taipei#,
				'generic' => q#Am Taipei#,
				'standard' => q#Am Caighdeánach Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Am na Táidsíceastáine#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Am Oileáin Tócalá#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Am Samhraidh Thonga#,
				'generic' => q#Am Thonga#,
				'standard' => q#Am Caighdeánach Thonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Am Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Am Samhraidh na Tuircméanastáine#,
				'generic' => q#Am na Tuircméanastáine#,
				'standard' => q#Am Caighdeánach na Tuircméanastáine#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Am Thúvalú#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Am Samhraidh Uragua#,
				'generic' => q#Am Uragua#,
				'standard' => q#Am Caighdeánach Uragua#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Am Samhraidh na hÚisbéiceastáine#,
				'generic' => q#Am na hÚisbéiceastáine#,
				'standard' => q#Am Caighdeánach na hÚisbéiceastáine#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Am Samhraidh Vanuatú#,
				'generic' => q#Am Vanuatú#,
				'standard' => q#Am Caighdeánach Vanuatú#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Am Veiniséala#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Am Samhraidh Vladivostok#,
				'generic' => q#Am Vladivostok#,
				'standard' => q#Am Caighdeánach Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Am Samhraidh Volgograd#,
				'generic' => q#Am Volgograd#,
				'standard' => q#Am Caighdeánach Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Am Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Am Oileán Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Am Wallis agus Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Am Samhraidh Iacútsc#,
				'generic' => q#Am Iacútsc#,
				'standard' => q#Am Caighdeánach Iacútsc#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Am Samhraidh Yekaterinburg#,
				'generic' => q#Am Yekaterinburg#,
				'standard' => q#Am Caighdeánach Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Am Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
